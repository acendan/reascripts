-- @description Timecode Manager
-- @author Aaron Cendan
-- @version 1.06
-- @metapackage
-- @provides
--   [main] .
-- @link https://ko-fi.com/acendan_
-- @about
--   # Supports: Sound Devices WAVs, Zoom F3 WAVs, GoPro MP4/MOVs
-- @changelog
--   Added button in track offset panel to calculate gap from first item in track's first transient to edit cursor

local acendan_LuaUtils = reaper.GetResourcePath() .. '/Scripts/ACendan Scripts/Development/acendan_Lua Utilities.lua'
if reaper.file_exists(acendan_LuaUtils) then
  dofile(acendan_LuaUtils); if not acendan or acendan.version() < 9.24 then
    acendan.msg(
    'This script requires a newer version of ACendan Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',
      "ACendan Lua Utilities"); return
  end
else
  reaper.ShowConsoleMsg(
  "This script requires ACendan Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'ACendan Lua Utilities'"); return
end
local VSDEBUG = os.getenv("VSCODE_DBG_UUID") == "df3e118e-8874-49f7-ab62-ceb166401fb9" and
dofile('C:/Users/Aaron/.vscode/extensions/antoinebalaine.reascript-docs-0.1.14/debugger/LoadDebug.lua') or nil

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua'
local ImGui = require 'imgui' '0.10'

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ GLOBALS ~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

local wgt, gopro_items, f3_items, tbls, clipper
local FLT_MIN, FLT_MAX = ImGui.NumericLimits_Float()
local DBL_MIN, DBL_MAX = ImGui.NumericLimits_Double()
local IMGUI_VERSION, IMGUI_VERSION_NUM, REAIMGUI_VERSION = ImGui.GetVersion()

local SCRIPT_NAME = ({ reaper.get_action_context() })[2]:match("([^/\\_]+)%.lua$")
local SCRIPT_DIR = ({ reaper.get_action_context() })[2]:sub(1, ({ reaper.get_action_context() })[2]:find("\\[^\\]*$"))
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
    error = REAPER_VERSION >= 7.46 and "" or "Some features require REAPER v7.46+!"
  }

  -- [item, new_pos]
  gopro_items = {}
  f3_items = {}

  tbls = {
    items                   = {},
    flags                   = ImGui.TableFlags_Resizable       |
                              --ImGui.TableFlags_Reorderable     |
                              ImGui.TableFlags_Hideable        |
                              ImGui.TableFlags_Sortable        |
                              ImGui.TableFlags_SortMulti       |
                              ImGui.TableFlags_RowBg           |
                              ImGui.TableFlags_Borders         |
                              -- ImGui.TableFlags_NoBordersInBody |
                              ImGui.TableFlags_ScrollX         |
                              ImGui.TableFlags_ScrollY         |
                              ImGui.TableFlags_SizingFixedFit,
    freeze_cols             = 1,
    freeze_rows             = 1,
    row_min_height          = 0.0, -- Auto
    inner_width_with_scroll = 0.0, -- Auto-extend
    outer_size_enabled      = true,
    show_headers            = true,
    show_wrapped_text       = false,
    items_need_sort         = false,
  }

  clipper = ImGui.CreateListClipper(ctx)
  ImGui.Attach(ctx, clipper)
end

function main()
  acendan.ImGui_PushStyles()
  local rv, open = ImGui.Begin(ctx, SCRIPT_NAME, true, WINDOW_FLAGS)
  if not rv then return open end

  rv, wgt.locking = ImGui.Checkbox(ctx, "Lock item movement", wgt.locking)
  acendan.ImGui_HelpMarker(
  "When enabled, item locks will be enabled, preventing left/right movement once snapped to timecode.\n\nDefault: Enabled.")
  if rv then acendan.ImGui_SetSettingBool("TimecodeManager_Locking", wgt.locking) end

  rv, wgt.region = ImGui.Checkbox(ctx, "Make region", wgt.region)
  acendan.ImGui_HelpMarker(
  "When enabled, a region will be created at the start and end of the items' embedded timecode.\n\nDefault: Enabled.")
  if rv then acendan.ImGui_SetSettingBool("TimecodeManager_Region", wgt.region) end

  rv, wgt.ruler = ImGui.Checkbox(ctx, "Set ruler to H:M:S:F", wgt.ruler)
  acendan.ImGui_HelpMarker("When enabled, the project ruler will be set to Hours:Minutes:Seconds:Frames.\n\nDefault: Enabled.")
  if rv then acendan.ImGui_SetSettingBool("TimecodeManager_Ruler", wgt.ruler) end

  rv, wgt.reference = ImGui.Checkbox(ctx, "Add ruler item", wgt.reference)
  acendan.ImGui_HelpMarker(
  "When enabled, a ruler item will be added on a new track to serve as a helper 0:00 reference point from the start of embedded timecode.\n\nDefault: Disabled.")
  if rv then acendan.ImGui_SetSettingBool("TimecodeManager_Reference", wgt.reference) end

  rv, wgt.gopro_offset = ImGui.Checkbox(ctx, "GoPro hour offset", wgt.gopro_offset)
  acendan.ImGui_HelpMarker(
  "When enabled, GoPro items will have an hour offset applied based on the file creation time.\n\nDefault: Disabled.")
  if rv then acendan.ImGui_SetSettingBool("TimecodeManager_GoProOffset", wgt.gopro_offset) end

  local ret, idx, target = acendan.ImGui_ComboBox(ctx, "Target##tgt", { "Selected items", "All items" }, wgt.target)
  if ret then
    wgt.target = idx
    acendan.ImGui_SetSetting("TimecodeManager_Target", tostring(wgt.target))
  end
  acendan.ImGui_HelpMarker("Choose whether to apply timecode changes to selected items or all items in the project.")

  acendan.ImGui_Button("Move Items to Timecode", moveToTimecode, 0.42) -- Green
  acendan.ImGui_Tooltip("This will attempt to extract embedded timecode data from most WAV files.\n\nAdditional support is included for the following devices:\n- Sound Devices MixPre\n- Zoom F3\n- GoPro (HERO9 and later)\n\nTo request support for a device, shoot me an email with a sample file:\naaron.cendan@gmail.com")

  ImGui.SameLine(ctx)

  -- Track offsets popup
  local popup_w, popup_h = 260, 180
  local ret = ImGui.Button(ctx, "Set Track Offsets...")
  acendan.ImGui_Tooltip("Set custom timecode offsets per track (stored in the project file).\n\nExamples\n00:00:00:15 = Right by 15 frames\n-01:00:00:00 = Left by 1 hr")
  if ret then
    ImGui.SetNextWindowSize(ctx, popup_w, popup_h, ImGui.Cond_Always)
    local main_x, main_y = ImGui.GetWindowPos(ctx)
    local main_w, main_h = ImGui.GetWindowSize(ctx)
    local center_x = main_x + (main_w - popup_w) * 0.5
    local center_y = main_y + (main_h - popup_h) * 0.5
    ImGui.SetNextWindowPos(ctx, center_x, center_y, ImGui.Cond_Always)

    ImGui.OpenPopup(ctx, 'Track Offsets')
  end
  if ImGui.BeginPopupModal(ctx, 'Track Offsets', nil, WINDOW_FLAGS) then
    if reaper.ImGui_BeginTable(ctx, 'TrackOffsetsTbl', 2, tbls.flags & ~ImGui.TableFlags_Sortable, popup_w - 20, popup_h - 70, 0) then
      -- Declare columns
      ImGui.TableSetupColumn(ctx, 'Track Name',
        ImGui.TableColumnFlags_DefaultSort | ImGui.TableColumnFlags_WidthStretch | ImGui.TableColumnFlags_NoHide, 100.0,
        1)
      ImGui.TableSetupColumn(ctx, 'Offset (+/-)', ImGui.TableColumnFlags_WidthStretch, 140.0, 2)
      ImGui.TableSetupScrollFreeze(ctx, tbls.freeze_cols, tbls.freeze_rows)

      -- Show headers
      if tbls.show_headers then
        ImGui.TableHeadersRow(ctx)
      end

      ImGui.ListClipper_Begin(clipper, reaper.CountTracks(0))
      while ImGui.ListClipper_Step(clipper) do
        local display_start, display_end = ImGui.ListClipper_GetDisplayRange(clipper)
        for row_n = display_start, display_end - 1 do
          local track = reaper.GetTrack(0, row_n)

          ImGui.PushID(ctx, 'track' .. row_n)
          ImGui.TableNextRow(ctx, ImGui.TableRowFlags_None, tbls.row_min_height)

          -- Add track name
          ImGui.TableSetColumnIndex(ctx, 0)
          local ret, buf = reaper.GetTrackName(track)
          ImGui.Text(ctx, ret and buf or "Track " .. (row_n + 1))

          -- Add offset input
          ImGui.TableSetColumnIndex(ctx, 1)
          local _, offset = reaper.GetSetMediaTrackInfo_String(track, "P_EXT:TimecodeOffset", "", false)
          ret, buf = ImGui.InputTextWithHint(ctx, "##offset1", "hh:mm:ss:ff", offset, ImGui.InputTextFlags_None, nil)
          if ret then
            local valid = buf:match("^(%-?%d+):(%d+):(%d+)%:?(%d*)$")
            if not valid then buf = offset end -- Revert to previous value if invalid
            reaper.GetSetMediaTrackInfo_String(track, "P_EXT:TimecodeOffset", buf, true)
          end
          -- Reset x button
          ImGui.SameLine(ctx)
          if ImGui.Button(ctx, "x##reset_offset_" .. row_n, 0.0, 0.0) then
            reaper.GetSetMediaTrackInfo_String(track, "P_EXT:TimecodeOffset", "", true)
          end
          acendan.ImGui_Tooltip("Reset to 00:00:00:00")
          -- Snap to cursor
          ImGui.SameLine(ctx)
          if ImGui.Button(ctx, ">##snap_offset_" .. row_n, 0.0, 0.0) then
            reaper.PreventUIRefresh(1)
            local cursor_pos = reaper.GetCursorPosition()
            local item_count = reaper.CountTrackMediaItems(track)
            if item_count > 0 then
              local ini_sel_items = {}
              acendan.saveSelectedItems(ini_sel_items)

              -- Find first transient in first item
              local first_item = reaper.GetTrackMediaItem(track, 0)
              local item_pos = reaper.GetMediaItemInfo_Value(first_item, "D_POSITION")
              reaper.SelectAllMediaItems( 0, false) -- Deselect all items
              reaper.SetMediaItemSelected(first_item, true) -- Select first item
              reaper.SetEditCurPos2( 0, item_pos, false, false) -- Move cursor to item start
              reaper.Main_OnCommand(40375, 0) -- Item navigation: Move cursor to next transient in items
              local first_trans = reaper.GetCursorPosition()

              -- Calculate offset from first transient to edit cursor position
              local fps, dropFrame = reaper.TimeMap_curFrameRate(0)
              local offset_sec = cursor_pos - first_trans
              local pos_or_neg = offset_sec < 0 and "-" or ""
              offset_sec = math.abs(offset_sec)
              local hours = math.floor(offset_sec / 3600)
              local minutes = math.floor((offset_sec % 3600) / 60)
              local seconds = math.floor(offset_sec % 60)
              local frames = math.floor((offset_sec - math.floor(offset_sec)) * fps + 0.5)
              buf = string.format("%s%02d:%02d:%02d:%02d", pos_or_neg, hours, minutes, seconds, frames)
              reaper.GetSetMediaTrackInfo_String(track, "P_EXT:TimecodeOffset", buf, true)

              acendan.restoreSelectedItems(ini_sel_items)
              reaper.SetEditCurPos2(0, cursor_pos, false, false) -- Move cursor back to original pos
            end
            reaper.PreventUIRefresh(-1)
          end
          acendan.ImGui_Tooltip("Set offset to distance from first item on track's first transient to edit cursor position.")

          ImGui.PopID(ctx)
        end
      end

      ImGui.EndTable(ctx)
    end


    if ImGui.Button(ctx, 'Close') then
      ImGui.CloseCurrentPopup(ctx)
    end
    ImGui.EndPopup(ctx)
  end

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
  setGoProF3ItemsSelected(false)               -- Deselect items to avoid BWF warning messages
  if num_items > #gopro_items + #f3_items then -- GoPro & F3 items have already been moved, move the rest
    reaper.Main_OnCommand(40299, 0)            -- Item: Move to media source preferred position (BWF start offset)
  end
  setGoProF3ItemsSelected(true)

  -- Apply offsets
  for i = 0, num_items - 1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    if item then
      local track = reaper.GetMediaItem_Track(item)
      local ret, offset = reaper.GetSetMediaTrackInfo_String(track, "P_EXT:TimecodeOffset", "", false)
      if ret and offset ~= "" then
        local hours, minutes, seconds, frames = offset:match("(%-?%d+):(%d+):(%d+)%:?(%d*)")
        local pos_or_neg = offset:match("^(%-)") and -1 or 1
        if hours and minutes and seconds then
          local fps, dropFrame = reaper.TimeMap_curFrameRate(0)
          local pos = (hours * 3600) + (minutes * 60) + seconds + (tonumber(frames) / fps)
          local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
          reaper.SetMediaItemInfo_Value(item, "D_POSITION", item_pos + (pos * pos_or_neg))
        end
      end
    end
  end

  -- Zoom to items and move cursor
  reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_HZOOMITEMS"), 0) -- SWS: Horizontal zoom to selected items
  reaper.Main_OnCommand(40290, 0)                                        -- Time selection: Set time selection to items
  reaper.Main_OnCommand(41173, 0)                                        -- Item navigation: Move cursor to start of items

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
    reaper.Main_OnCommand(40296, 0)                                           -- Track: Select all tracks
    reaper.Main_OnCommand(40110, 0)                                           -- View: Toggle track zoom to minimum height
    reaper.Main_OnCommand(40111, 0)                                           -- View: Zoom in vertical
    reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_INSRTTRKABOVE"), 0) -- SWS: Insert track above selected tracks
    reaper.Main_OnCommand(42336, 0)                                           -- Track: Lock/unlock track height
    reaper.Main_OnCommand(40000, 0)                                           -- Track: Pin tracks to top of arrange view
    reaper.Main_OnCommand(40142, 0)                                           -- Insert empty item
    reaper.Main_OnCommand(40688, 0)                                           -- Item properties: Lock
    reaper.Main_OnCommand(42314, 0)                                           -- Item properties: Display item time ruler in H:M:S:F format
    reaper.Main_OnCommand(42697, 0)                                           -- View: Toggle track zoom to default height
  end

  reaper.Undo_EndBlock(SCRIPT_NAME, -1)
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
                local created = reaper.ExecProcess('cmd.exe /C "dir /T:c \"' .. fmt .. '\" "', 0):sub(3)
                local c_month, c_day, c_year, c_hour, c_minute, c_ampm = created:match(
                  "(%d+)-(%d+)-(%d+)%s-(%d+):(%d+)%s?(%a?%a?)")
                if c_ampm == "PM" and tonumber(c_hour) < 12 then
                  c_hour = tostring(tonumber(c_hour) + 12)
                elseif c_ampm == "AM" and tonumber(c_hour) == 12 then
                  c_hour = "00"
                end
                hours = tonumber(c_hour)
              end

              -- Convert from H:M:S.FF to seconds
              local fps, dropFrame = reaper.TimeMap_curFrameRate(0)
              local pos = (hours * 3600) + (minutes * 60) + seconds + (tonumber(frames) / fps)

              table.insert(gopro_items, { item, pos })
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
            table.insert(f3_items, { item, pos })
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
