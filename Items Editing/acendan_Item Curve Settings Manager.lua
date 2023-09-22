-- @description Item Curve Settings Manager (ImGui)
-- @author Aaron Cendan
-- @version 1.2
-- @metapackage
-- @provides
--   [main] .
-- @link https://ko-fi.com/acendan_
-- @about
--   # Item curve settings manager
-- @changelog
--   * Dependency on acendan_LuaUtils 7.1+

local acendan_LuaUtils = reaper.GetResourcePath()..'/Scripts/ACendan Scripts/Development/acendan_Lua Utilities.lua'
if reaper.file_exists( acendan_LuaUtils ) then dofile( acendan_LuaUtils ); if not acendan or acendan.version() < 7.1 then acendan.msg('This script requires a newer version of ACendan Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"ACendan Lua Utilities"); return end else reaper.ShowConsoleMsg("This script requires ACendan Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'ACendan Lua Utilities'"); return end
if not reaper.ImGui_Key_0() then acendan.msg("This script requires the ReaImGui API, which can be installed from:\n\nExtensions > ReaPack > Browse packages...") return end
  
  
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ CONSTANTS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

local SCRIPT_NAME = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local SCRIPT_DIR = ({reaper.get_action_context()})[2]:sub(1,({reaper.get_action_context()})[2]:find("\\[^\\]*$"))

local WINDOW_SIZE = { width = 300, height = 130 }
local WINDOW_FLAGS = reaper.ImGui_WindowFlags_NoCollapse()
local SLIDER_FLAGS = reaper.ImGui_SliderFlags_AlwaysClamp()


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function init()
  ctx = reaper.ImGui_CreateContext(SCRIPT_NAME, reaper.ImGui_ConfigFlags_DockingEnable())
  reaper.ImGui_SetNextWindowSize(ctx, WINDOW_SIZE.width, WINDOW_SIZE.height)
  
  wgt = {
    fade_in = GetPreviousValue("fade_in", 0.0),
    fade_out = GetPreviousValue("fade_out", 0.0),
    continuous = false,
    last_pressed = ""
  }
end

function main()
  local rv, open = reaper.ImGui_Begin(ctx, SCRIPT_NAME, true, WINDOW_FLAGS)
  if not rv then return open end
  
  AddSlider("Fade In", "fade_in")
  acendan.ImGui_HelpMarker("Ctrl+Click to input value.")
  AddSlider("Fade Out", "fade_out")
  reaper.ImGui_Spacing(ctx)
  
  AddButton("Selected Items", UpdateSelItems)
  reaper.ImGui_SameLine(ctx)
  AddButton("All Items", UpdateAllItems)
  acendan.ImGui_HelpMarker("Apply current slider settings.")
  
  rv, wgt.continuous = reaper.ImGui_Checkbox(ctx, "Continuous?", wgt.continuous)
  acendan.ImGui_HelpMarker("Updates items constantly with most recently clicked button.")

  reaper.ImGui_End(ctx)
  if open then reaper.defer(main) else reaper.ImGui_DestroyContext(ctx) end
end


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ UTILITIES ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function AddSlider(name, key)
  rv, wgt[key] = reaper.ImGui_SliderDouble(ctx, name, wgt[key], -1.0, 1.0, "Curve = %.2f", SLIDER_FLAGS)
  if rv then reaper.SetExtState(SCRIPT_NAME, key, wgt[key], true) end
end

function AddButton(name, callback)
  local is_last_pressed = wgt.last_pressed == name
  local enabled = wgt.last_pressed == "" or is_last_pressed or not wgt.continuous
  local enabled_cont = is_last_pressed and wgt.continuous
  
  if enabled_cont then callback() end
  if not enabled then reaper.ImGui_BeginDisabled(ctx) end
  if reaper.ImGui_Button(ctx, name) then
    wgt.last_pressed = name
    callback()
  end
  if not enabled then reaper.ImGui_EndDisabled(ctx) end
end

function UpdateItem(item)
  reaper.SetMediaItemInfo_Value( item, "D_FADEINDIR", wgt.fade_in)
  reaper.SetMediaItemInfo_Value( item, "D_FADEOUTDIR", wgt.fade_out)
end

function UpdateSelItems()
  local num_sel_items = reaper.CountSelectedMediaItems(0)
  if num_sel_items > 0 then
    for i=0, num_sel_items - 1 do
      UpdateItem(reaper.GetSelectedMediaItem( 0, i ))
    end
  end
end

function UpdateAllItems()
  local num_items = reaper.CountMediaItems( 0 )
  if num_items > 0 then
    for i=0, num_items - 1 do
      UpdateItem(reaper.GetMediaItem( 0, i ))
    end
  end
end

function GetPreviousValue(key, default)
  return reaper.HasExtState(SCRIPT_NAME, key) and reaper.GetExtState(SCRIPT_NAME, key) or default
end


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
init()
main()
