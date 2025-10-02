-- @description Timecode Manager
-- @author Aaron Cendan
-- @version 1.04
-- @metapackage
-- @provides
--   [main] .
-- @link https://ko-fi.com/acendan_
-- @about
--   # Supports: Sound Devices WAVs, GoPro MP4/MOVs
-- @changelog
--   Added Zoom F3 support

-- TODO
-- - Add support for user customizable offsets per track

local acendan_LuaUtils = reaper.GetResourcePath()..'/Scripts/ACendan Scripts/Development/acendan_Lua Utilities.lua'
if reaper.file_exists(acendan_LuaUtils) then dofile(acendan_LuaUtils); if not acendan or acendan.version() < 9.24 then acendan.msg('This script requires a newer version of ACendan Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"ACendan Lua Utilities"); return end else reaper.ShowConsoleMsg("This script requires ACendan Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'ACendan Lua Utilities'"); return end
local VSDEBUG = os.getenv("VSCODE_DBG_UUID") == "df3e118e-8874-49f7-ab62-ceb166401fb9" and dofile('C:/Users/Aaron/.vscode/extensions/antoinebalaine.reascript-docs-0.1.14/debugger/LoadDebug.lua') or nil

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua'
local ImGui = require 'imgui' '0.10'

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ GLOBALS ~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

local wgt, gopro_items, f3_items
local FLT_MIN, FLT_MAX = ImGui.NumericLimits_Float()
local DBL_MIN, DBL_MAX = ImGui.NumericLimits_Double()
local IMGUI_VERSION, IMGUI_VERSION_NUM, REAIMGUI_VERSION = ImGui.GetVersion()

local SCRIPT_NAME = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local SCRIPT_DIR = ({reaper.get_action_context()})[2]:sub(1,({reaper.get_action_context()})[2]:find("\\[^\\]*$"))
local REAPER_VERSION = tonumber(reaper.GetAppVersion():match("%d+%.%d+"))

local WINDOW_SIZE = { width = 300, height = 235 }
local WINDOW_FLAGS = ImGui.WindowFlags_NoCollapse


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function init()
  ctx = ImGui.CreateContext(SCRIPT_NAME, ImGui.ConfigFlags_DockingEnable)
  ImGui.SetNextWindowSize(ctx, WINDOW_SIZE.width, WINDOW_SIZE.height)
  
  wgt = {
    locking = acendan.ImGui_GetSettingBool("TimecodeManager_Locking", true),
    region = acendan.ImGui_GetSettingBool("TimecodeManager_Region", true),
    ruler = acendan.ImGui_GetSettingBool("TimecodeManager_Ruler", true),
    reference = acendan.ImGui_GetSettingBool("TimecodeManager_Reference", false),
    gopro_offset = acendan.ImGui_GetSettingBool("TimecodeManager_GoProOffset", false),
    target = tonumber(acendan.ImGui_GetSetting("TimecodeManager_Target", "1")), -- 1 = Selected items, 2 = All items
    error = ""
  }

  -- [item, new_pos]
  gopro_items = {}
  f3_items = {}
end

function main()
  acendan.ImGui_PushStyles()
  local rv, open = ImGui.Begin(ctx, SCRIPT_NAME, true, WINDOW_FLAGS)
  if not rv then return open end
  
  rv, wgt.locking = ImGui.Checkbox(ctx, "Lock item movement", wgt.locking)
  acendan.ImGui_HelpMarker("When enabled, item locks will be enabled, preventing left/right movement once snapped to timecode.")
  if rv then acendan.ImGui_SetSettingBool("TimecodeManager_Locking", wgt.locking) end

  rv, wgt.region = ImGui.Checkbox(ctx, "Make region", wgt.region)
  acendan.ImGui_HelpMarker("When enabled, a region will be created at the start and end of the items' embedded timecode.")
  if rv then acendan.ImGui_SetSettingBool("TimecodeManager_Region", wgt.region) end

  rv, wgt.ruler = ImGui.Checkbox(ctx, "Set ruler to H:M:S:F", wgt.ruler)
  acendan.ImGui_HelpMarker("When enabled, the project ruler will be set to Hours:Minutes:Seconds:Frames.")
  if rv then acendan.ImGui_SetSettingBool("TimecodeManager_Ruler", wgt.ruler) end

  rv, wgt.reference = ImGui.Checkbox(ctx, "Add ruler item", wgt.reference)
  acendan.ImGui_HelpMarker("When enabled, a ruler item will be added on a new track to serve as a helper 0:00 reference point from the start of embedded timecode.")
  if rv then acendan.ImGui_SetSettingBool("TimecodeManager_Reference", wgt.reference) end

  rv, wgt.gopro_offset = ImGui.Checkbox(ctx, "GoPro hour offset", wgt.gopro_offset)
  acendan.ImGui_HelpMarker("When enabled, GoPro items will have an hour offset applied based on the file creation time. Typically unnecessary.")
  if rv then acendan.ImGui_SetSettingBool("TimecodeManager_GoProOffset", wgt.gopro_offset) end

  local ret, idx, target = acendan.ImGui_ComboBox(ctx, "Target##tgt", {"Selected items","All items"}, wgt.target)
  if ret then 
    wgt.target = idx
    acendan.ImGui_SetSetting("TimecodeManager_Target", tostring(wgt.target))
  end
  acendan.ImGui_HelpMarker("Choose whether to apply timecode changes to selected items or all items in the project.")

  acendan.ImGui_Button("Move to Timecode", moveToTimecode, 0.42)  -- Green

  if wgt.error ~= "" then
    ImGui.TextColored(ctx, 0xFFFF00FF, wgt.error)
  end

  ImGui.End(ctx)
  acendan.ImGui_PopStyles()
  if open then reaper.defer(main) else return end
end

function moveToTimecode()
  -- Item selection check
  local num_items = 0
  if wgt.target == 2 then
    num_items = reaper.CountMediaItems(0)
    if num_items == 0 then
      wgt.error = "No items in project!"
      return
    end
    reaper.Main_OnCommand(40182, 0) -- Item: Select all items
  else
    num_items = reaper.CountSelectedMediaItems(0)
    if num_items == 0 then
      wgt.error = "No items selected!"
      return
    end
  end

  reaper.PreventUIRefresh(1)
  reaper.Undo_BeginBlock()

  -- GoPro (or other MP4s/MOVs that use Media Created) timecode setup
  setupGoProTimecode()

  -- F3 timecode setup
  setupF3Timecode()

  -- Move to timecode
  setGoProF3ItemsSelected(false) -- Deselect items to avoid BWF warning messages
  if num_items > #gopro_items + #f3_items then -- GoPro & F3 items have already been moved, move the rest
    reaper.Main_OnCommand(40299, 0) -- Item: Move to media source preferred position (BWF start offset)
  end
  setGoProF3ItemsSelected(true)

  -- Zoom to items and move cursor
  reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_HZOOMITEMS"), 0) -- SWS: Horizontal zoom to selected items
  reaper.Main_OnCommand(40290, 0) -- Time selection: Set time selection to items
  reaper.Main_OnCommand(41173, 0) -- Item navigation: Move cursor to start of items

  -- Locking
  if wgt.locking then
    reaper.Main_OnCommand(40577, 0) -- Locking: Set left/right item locking mode
    reaper.Main_OnCommand(40688, 0) -- Item properties: Lock
  end

  -- Region
  if wgt.region then
    reaper.Main_OnCommand(40348, 0) -- Markers: Insert region from selected items
  end

  -- Ruler
  if wgt.ruler then
    reaper.Main_OnCommand(40370, 0) -- View: Time unit for ruler: Hours:Minutes:Seconds:Frames
    reaper.Main_OnCommand(42365, 0) -- View: Secondary time unit for ruler: Absolute frames
  end

  -- Reference
  if wgt.reference then
    reaper.Main_OnCommand(40296, 0) -- Track: Select all tracks
    reaper.Main_OnCommand(40110, 0) -- View: Toggle track zoom to minimum height
    reaper.Main_OnCommand(40111, 0) -- View: Zoom in vertical
    reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_INSRTTRKABOVE"), 0) -- SWS: Insert track above selected tracks
    reaper.Main_OnCommand(42336, 0) -- Track: Lock/unlock track height
    reaper.Main_OnCommand(40000, 0) -- Track: Pin tracks to top of arrange view
    reaper.Main_OnCommand(40142, 0) -- Insert empty item
    reaper.Main_OnCommand(40688, 0) -- Item properties: Lock
    reaper.Main_OnCommand(42314, 0) -- Item properties: Display item time ruler in H:M:S:F format
    reaper.Main_OnCommand(42697, 0) -- View: Toggle track zoom to default height
  end

  reaper.Undo_EndBlock(SCRIPT_NAME,-1)
  reaper.PreventUIRefresh(-1)
  reaper.UpdateArrange()
  reaper.UpdateTimeline()

  wgt.error = ""
end

function setupGoProTimecode()
  gopro_items = {}

  local function processGoProItem(item)
    local take = reaper.GetActiveTake(item)
    if take and reaper.TakeIsMIDI(take) == false then
      local src = reaper.GetMediaItemTake_Source(take)
      local fmt = reaper.GetMediaSourceFileName(src, "")
      if fmt:match("%.MP4") or fmt:match("%.MOV") then
        local ret, meta_created = reaper.GetMediaFileMetadata(src, "Media created")
        if ret then
          -- Strip date from 2025/10/01:19:27:39.000 format
          local timecode = meta_created:match("(%d+:%d+:%d+%.%d+)")

          -- Move item to timecode position
          if timecode then
            local hours, minutes, seconds, frames = timecode:match("(%d+):(%d+):(%d+)%.(%d+)")
            if hours and minutes and seconds and frames then
              -- Compensate for GoPro hour offset based on file creation time
              if wgt.gopro_offset then
                local created = reaper.ExecProcess( 'cmd.exe /C "dir /T:c \"' .. fmt .. '\" "', 0 ):sub(3)
                local c_month, c_day, c_year, c_hour, c_minute, c_ampm = created:match("(%d+)-(%d+)-(%d+)%s-(%d+):(%d+)%s?(%a?%a?)")
                if c_ampm == "PM" and tonumber(c_hour) < 12 then
                  c_hour = tostring(tonumber(c_hour) + 12)
                elseif c_ampm == "AM" and tonumber(c_hour) == 12 then
                  c_hour = "00"
                end
                hours = tonumber(c_hour)
              end

              -- Convert from H:S:M:F to seconds
              local fps = reaper.TimeMap2_QNToTime(1, 1) -- Get project FPS
              local frame_time = (frames / fps)
              local pos = (hours * 3600) + (minutes * 60) + seconds + frame_time

              table.insert(gopro_items, {item, pos})
            end
          end
        end
      end
    end
  end

  if wgt.target == 2 then
    local item_count = reaper.CountMediaItems(0)
    for i = 0, item_count - 1 do
      local item = reaper.GetMediaItem(0, i)
      if item then
        processGoProItem(item)
      end
    end
  else
    local item_count = reaper.CountSelectedMediaItems(0)
    for i = 0, item_count - 1 do
      local item = reaper.GetSelectedMediaItem(0, i)
      if item then
        processGoProItem(item)
      end
    end
  end

  -- Move GoPro items to new positions
  for _, tbl in ipairs(gopro_items) do
    local item, new_pos = table.unpack(tbl)
    reaper.SetMediaItemInfo_Value(item, "D_POSITION", new_pos)
  end
end

function setupF3Timecode()
  f3_items = {}

  local function processF3Item(item)
    local take = reaper.GetActiveTake(item)
    if take and reaper.TakeIsMIDI(take) == false then
      local src = reaper.GetMediaItemTake_Source(take)
      local fmt = reaper.GetMediaSourceFileName(src, "")
      if fmt:match("%.WAV") then
        local ret, bwf_originator = reaper.GetMediaFileMetadata(src, "BWF:Originator")
        if ret and bwf_originator:match("ZOOM F3") then
          local ret2, bwf_time = reaper.GetMediaFileMetadata(src, "BWF:OriginationTime")
          -- Strip date from HH::MM::SS format
          if ret2 and bwf_time:match("(%d+:%d+:%d+)") then
            local hours, minutes, seconds = bwf_time:match("(%d+):(%d+):(%d+)")
            local pos = (hours * 3600) + (minutes * 60) + seconds
            table.insert(f3_items, {item, pos})
          end
        end
      end
    end
  end

  if wgt.target == 2 then
    local item_count = reaper.CountMediaItems(0)
    for i = 0, item_count - 1 do
      local item = reaper.GetMediaItem(0, i)
      if item then
        processF3Item(item)
      end
    end
  else
    local item_count = reaper.CountSelectedMediaItems(0)
    for i = 0, item_count - 1 do
      local item = reaper.GetSelectedMediaItem(0, i)
      if item then
        processF3Item(item)
      end
    end
  end

  -- Move F3 items to new positions
  for _, tbl in ipairs(f3_items) do
    local item, new_pos = table.unpack(tbl)
    reaper.SetMediaItemInfo_Value(item, "D_POSITION", new_pos)
  end
end

function setGoProF3ItemsSelected(selected)
  for _, tbl in ipairs(gopro_items) do
    local item = table.unpack(tbl)
    reaper.SetMediaItemSelected(item, selected)
  end
  for _, tbl in ipairs(f3_items) do
    local item = table.unpack(tbl)
    reaper.SetMediaItemSelected(item, selected)
  end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
init()
main()