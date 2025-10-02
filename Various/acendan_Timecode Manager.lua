-- @description Timecode Manager
-- @author Aaron Cendan
-- @version 1.01
-- @metapackage
-- @provides
--   [main] .
-- @link https://ko-fi.com/acendan_
-- @about
--   # Provides a basic GUI to manage items with embedded LTC timecode.

local acendan_LuaUtils = reaper.GetResourcePath()..'/Scripts/ACendan Scripts/Development/acendan_Lua Utilities.lua'
if reaper.file_exists(acendan_LuaUtils) then dofile(acendan_LuaUtils); if not acendan or acendan.version() < 9.24 then acendan.msg('This script requires a newer version of ACendan Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"ACendan Lua Utilities"); return end else reaper.ShowConsoleMsg("This script requires ACendan Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'ACendan Lua Utilities'"); return end
local VSDEBUG = os.getenv("VSCODE_DBG_UUID") == "df3e118e-8874-49f7-ab62-ceb166401fb9" and dofile('C:/Users/Aaron/.vscode/extensions/antoinebalaine.reascript-docs-0.1.14/debugger/LoadDebug.lua') or nil


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ CONSTANTS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

local SCRIPT_NAME = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local SCRIPT_DIR = ({reaper.get_action_context()})[2]:sub(1,({reaper.get_action_context()})[2]:find("\\[^\\]*$"))
local REAPER_VERSION = tonumber(reaper.GetAppVersion():match("%d+%.%d+"))

local WINDOW_SIZE = { width = 300, height = 210 }
local WINDOW_FLAGS = reaper.ImGui_WindowFlags_NoCollapse()


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function init()
  ctx = reaper.ImGui_CreateContext(SCRIPT_NAME, reaper.ImGui_ConfigFlags_DockingEnable())
  reaper.ImGui_SetNextWindowSize(ctx, WINDOW_SIZE.width, WINDOW_SIZE.height)
  
  wgt = {
    locking = false,
    region = false,
    ruler = false,
    reference = false,
    target = 1, -- 1 = Selected items, 2 = All items
    error = ""
  }
end

function main()
  acendan.ImGui_PushStyles()
  local rv, open = reaper.ImGui_Begin(ctx, SCRIPT_NAME, true, WINDOW_FLAGS)
  if not rv then return open end
  
  rv, wgt.locking = reaper.ImGui_Checkbox(ctx, "Lock item movement", wgt.locking or false)
  acendan.ImGui_HelpMarker("When enabled, item locks will be enabled, preventing left/right movement once snapped to timecode.")

  rv, wgt.region = reaper.ImGui_Checkbox(ctx, "Make region", wgt.region or false)
  acendan.ImGui_HelpMarker("When enabled, a region will be created at the start and end of the items' embedded timecode.")

  rv, wgt.ruler = reaper.ImGui_Checkbox(ctx, "Set ruler to H:M:S:F", wgt.ruler or false)
  acendan.ImGui_HelpMarker("When enabled, the project ruler will be set to Hours:Minutes:Seconds:Frames.")

  rv, wgt.reference = reaper.ImGui_Checkbox(ctx, "Add ruler item", wgt.reference or false)
  acendan.ImGui_HelpMarker("When enabled, a ruler item will be added on a new track to serve as a helper 0:00 reference point from the start of embedded timecode.")

  local ret, idx, target = acendan.ImGui_ComboBox(ctx, "Target##tgt", {"Selected items","All items"}, wgt.target or 1)
  if ret then wgt.target = idx end
  acendan.ImGui_HelpMarker("Choose whether to apply timecode changes to selected items or all items in the project.")

  acendan.ImGui_Button("Move to Timecode", moveToTimecode, 0.42)  -- Green

  if wgt.error ~= "" then
    reaper.ImGui_TextColored(ctx, 0xFFFF00FF, wgt.error)
  end

  reaper.ImGui_End(ctx)
  acendan.ImGui_PopStyles()
  if open then reaper.defer(main) else return end
end

function moveToTimecode()
  -- Item selection check
  if wgt.target == 2 then
    if reaper.CountMediaItems(0) == 0 then
      wgt.error = "No items in project!"
      return
    end
    reaper.Main_OnCommand(40182, 0) -- Item: Select all items
  else
    if reaper.CountSelectedMediaItems(0) == 0 then
      wgt.error = "No items selected!"
      return
    end
  end

  -- Move to timecode
  reaper.Main_OnCommand(40299, 0) -- Item: Move to media source preferred position (BWF start offset)
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

  reaper.UpdateArrange()
  reaper.UpdateTimeline()

  wgt.error = ""
end


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
init()
main()