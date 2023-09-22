-- @description Item Curve Settings Manager (ImGui)
-- @author Aaron Cendan
-- @version 1.0
-- @metapackage
-- @provides
--   [main] .
-- @link https://ko-fi.com/acendan_
-- @about
--   # Item curve settings manager

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~ USER CONFIG - EDIT ME ~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Get this script's name and directory
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local script_directory = ({reaper.get_action_context()})[2]:sub(1,({reaper.get_action_context()})[2]:find("\\[^\\]*$"))

-- Load lua utilities
acendan_LuaUtils = reaper.GetResourcePath()..'/Scripts/ACendan Scripts/Development/acendan_Lua Utilities.lua'
if reaper.file_exists( acendan_LuaUtils ) then dofile( acendan_LuaUtils ); if not acendan or acendan.version() < 6.6 then acendan.msg('This script requires a newer version of ACendan Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"ACendan Lua Utilities"); return end else reaper.ShowConsoleMsg("This script requires ACendan Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'ACendan Lua Utilities'"); return end

-- Separator for tempo map serialization
local sep = "||"

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function init()
  -- Confirm user has ImGui installed
  if not reaper.ImGui_Key_0() then acendan.msg("This script requires the ReaImGui API, which can be installed from:\n\nExtensions > ReaPack > Browse packages...") return end
    
  ctx = reaper.ImGui_CreateContext(script_name, reaper.ImGui_ConfigFlags_DockingEnable())
  
  widgets = {
    fade_in = reaper.HasExtState(script_name, "fade_in") and reaper.GetExtState(script_name, "fade_in") or 0.0,
    fade_out = reaper.HasExtState(script_name, "fade_out") and reaper.GetExtState(script_name, "fade_out") or 0.0,
    continuous = false,
    last_pressed = ""
  }
  
  WINDOW_FLAGS = reaper.ImGui_WindowFlags_None()
  WINDOW_FLAGS = WINDOW_FLAGS | reaper.ImGui_WindowFlags_NoCollapse()
  WINDOW_SIZE = { width = 300, height = 130 }
  reaper.ImGui_SetNextWindowSize(ctx, WINDOW_SIZE.width, WINDOW_SIZE.height)
  
  SLIDER_FLAGS = reaper.ImGui_SliderFlags_AlwaysClamp()
   
  -- ReaImGui_Demo
  -- Using those as a base value to create width/height that are factor of the size of our font
  TEXT_BASE_WIDTH  = reaper.ImGui_CalcTextSize(ctx, 'A')
  TEXT_BASE_HEIGHT = reaper.ImGui_GetTextLineHeightWithSpacing(ctx)
  FLT_MIN, FLT_MAX = reaper.ImGui_NumericLimits_Float()
  
  main()
end

function main()
  local rv, open = reaper.ImGui_Begin(ctx, script_name, true, WINDOW_FLAGS)
  if not rv then return open end
  
  if reaper.ImGui_BeginChild(ctx, "main") then
    rv, widgets.fade_in = reaper.ImGui_SliderDouble(ctx, "Fade In", widgets.fade_in, -1.0, 1.0, "Curve = %.2f", SLIDER_FLAGS)
    if rv then reaper.SetExtState(script_name, "fade_in", widgets.fade_in, true) end
    HelpMarker("Ctrl+Click to input value.")
    
    rv, widgets.fade_out = reaper.ImGui_SliderDouble(ctx, "Fade Out", widgets.fade_out, -1.0, 1.0, "Curve = %.2f", SLIDER_FLAGS)
    if rv then reaper.SetExtState(script_name, "fade_out", widgets.fade_out, true) end
    
    reaper.ImGui_Spacing(ctx)
    
    local continuous_selected = widgets.continuous and widgets.last_pressed == "Selected Items"
    local continuous_all = widgets.continuous and widgets.last_pressed == "All Items"
    
    -- Selected items
    if continuous_selected then UpdateSelItems() end
    if continuous_all then reaper.ImGui_BeginDisabled(ctx) end
    if reaper.ImGui_Button(ctx, "Selected Items") then
      widgets.last_pressed = "Selected Items"
      UpdateSelItems()
    end
    if continuous_all then reaper.ImGui_EndDisabled(ctx) end

    -- All items
    if continuous_all then UpdateAllItems() end
    if continuous_selected then reaper.ImGui_BeginDisabled(ctx) end
    reaper.ImGui_SameLine(ctx)
    if reaper.ImGui_Button(ctx, "All Items") then
      widgets.last_pressed = "All Items"
      UpdateAllItems()
    end
    if continuous_selected then reaper.ImGui_EndDisabled(ctx) end
    HelpMarker("Apply current slider settings.")
    
    rv, widgets.continuous = reaper.ImGui_Checkbox(ctx, "Continuous?", widgets.continuous)
    if rv and not widgets.continuous then widgets.last_pressed = "" end
    HelpMarker("Updates items constantly with most recently clicked button.")

    reaper.ImGui_EndChild(ctx)
  end

  reaper.ImGui_End(ctx)
  if open then reaper.defer(main) else reaper.ImGui_DestroyContext(ctx) end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ UTILITIES ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function UpdateItem(item)
  reaper.SetMediaItemInfo_Value( item, "D_FADEINDIR", widgets.fade_in)
  reaper.SetMediaItemInfo_Value( item, "D_FADEOUTDIR", widgets.fade_out)
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

function HelpMarker(desc)
  reaper.ImGui_SameLine(ctx)
  reaper.ImGui_TextDisabled(ctx, '(?)')
  if reaper.ImGui_IsItemHovered(ctx) then
    reaper.ImGui_BeginTooltip(ctx)
    reaper.ImGui_PushTextWrapPos(ctx, reaper.ImGui_GetFontSize(ctx) * 35.0)
    reaper.ImGui_Text(ctx, desc)
    reaper.ImGui_PopTextWrapPos(ctx)
    reaper.ImGui_EndTooltip(ctx)
  end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
init()
