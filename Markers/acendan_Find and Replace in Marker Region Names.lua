-- @description Find and Replace in Marker Region Names
-- @author Aaron Cendan
-- @version 2.2
-- @changelog
--   # ImGui Style
-- @metapackage
-- @provides
--   [main] . > acendan_Find and Replace in Region Names v2.lua
--   [main] . > acendan_Find and Replace in Marker Names v2.lua
-- @link https://aaroncendan.me
-- @about
--   # Find and Replace in Marker/Region Names
--   Aaron Cendan - May 2020
--   * Prompts user to replace part of a marker or region's name with new text if that marker/region name contains search criteria.

local acendan_LuaUtils = reaper.GetResourcePath()..'/Scripts/ACendan Scripts/Development/acendan_Lua Utilities.lua'
if reaper.file_exists( acendan_LuaUtils ) then dofile( acendan_LuaUtils ); if not acendan or acendan.version() < 8.0 then acendan.msg('This script requires a newer version of ACendan Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"ACendan Lua Utilities"); return end else reaper.ShowConsoleMsg("This script requires ACendan Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'ACendan Lua Utilities'"); return end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ CONSTANTS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

local SCRIPT_NAME = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local SCRIPT_DIR = ({reaper.get_action_context()})[2]:sub(1,({reaper.get_action_context()})[2]:find("\\[^\\]*$"))

local WINDOW_SIZE = { width = 390, height = 150 }
local WINDOW_FLAGS = reaper.ImGui_WindowFlags_NoCollapse()

local MODES = {
  REGION = "Region",
  MARKER = "Marker"
}
local MODE = SCRIPT_NAME:match('Region') and MODES.REGION or MODES.MARKER

local CASE_SENS = {
  INSENSITIVE = 0,
  SENSITIVE = 1
}

local PROJ_BOUNDS = {
  FULL_PROJECT = 0,
  TIME_SELECTION = 1,
  
  _COMBO_STR ="Full Project\0Time Selection\0"
}

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function init()
  ctx = reaper.ImGui_CreateContext(SCRIPT_NAME, reaper.ImGui_ConfigFlags_DockingEnable())
  reaper.ImGui_SetNextWindowSize(ctx, WINDOW_SIZE.width, WINDOW_SIZE.height)
  
  wgt = {
    find_str = GetPreviousValue("find_str", ""),
    repl_str = GetPreviousValue("repl_str", ""),
    case_sens = tonumber(GetPreviousValue("case_sens", CASE_SENS.INSENSITIVE)),
    proj_bounds = GetPreviousValue("proj_bounds", PROJ_BOUNDS.FULL_PROJECT)
  }
end

function main()
  acendan.ImGui_PushStyles()
  local rv, open = reaper.ImGui_Begin(ctx, "Find & Replace - " .. MODE .. " Names", true, WINDOW_FLAGS)
  if not rv then return open end
  
  rv, wgt.find_str = reaper.ImGui_InputTextWithHint(ctx, "Find", "Text to search for...", wgt.find_str)
  if rv then SetCurrentValue("find_str", wgt.find_str) end
  acendan.ImGui_HelpMarker("Leave blank to match\nentire name")
  
  rv, wgt.repl_str = reaper.ImGui_InputTextWithHint(ctx, "Replace", "Text to replace with...", wgt.repl_str)
  if rv then SetCurrentValue("repl_str", wgt.repl_str) end
  acendan.ImGui_HelpMarker("Leave blank to clear\nfound text")
  
  rv, wgt.proj_bounds = reaper.ImGui_Combo(ctx, "Project Bounds", wgt.proj_bounds, PROJ_BOUNDS._COMBO_STR)
  if rv then SetCurrentValue("proj_bounds", wgt.proj_bounds) end

  rv, wgt.case_sens = reaper.ImGui_Checkbox(ctx, "Case Sensitive", wgt.case_sens)
  if rv then SetCurrentValue("case_sens", wgt.case_sens and CASE_SENS.SENSITIVE or CASE_SENS.INSENSITIVE) end
  
  if reaper.ImGui_Button(ctx, "Submit") then FindReplace() end
	
  reaper.ImGui_End(ctx)
  acendan.ImGui_PopStyles()
  if open then reaper.defer(main) else return end
end

function FindReplace()
  reaper.PreventUIRefresh(1)
  reaper.Undo_BeginBlock()

  _, num_markers, num_regions = reaper.CountProjectMarkers( 0 )
  num_total = num_markers + num_regions

  if MODE == MODES.REGION then
    num_items = num_regions
  elseif MODE == MODES.MARKER then
    num_items = num_markers
  end

  if num_items > 0 then
    if wgt.proj_bounds == PROJ_BOUNDS.FULL_PROJECT then
	 SearchFullProject()
    elseif wgt.proj_bounds == PROJ_BOUNDS.TIME_SELECTION then
	 SearchTimeSel()
    end
  else
    acendan.msg(string.format("Project has no %ss!", MODE:lower()), "Find & Replace")
  end

  reaper.Undo_EndBlock(SCRIPT_NAME, -1)
  reaper.PreventUIRefresh(-1)
  reaper.UpdateArrange()
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ UTILITIES ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function AnalyzeMarkerRegion(i, isrgn, pos, rgnend, name, markrgnindexnumber, color)
  if wgt.find_str ~= "" then
    if wgt.case_sens then
	 if string.find(name, wgt.find_str) then
	   local new_name = string.gsub( name, wgt.find_str, wgt.repl_str)
	   reaper.SetProjectMarkerByIndex( 0, i, isrgn, pos, rgnend, markrgnindexnumber, new_name, color )
	 end
    else
	 local lower_name = string.lower(name)
	 local lower_search_string = string.lower(wgt.find_str)
	 local j, k = string.find(lower_name, lower_search_string)
	 if j and k then
	   local new_name = string.sub(name,1,j-1) .. wgt.repl_str .. string.sub(name,k+1,string.len(name))
	   reaper.SetProjectMarkerByIndex( 0, i, isrgn, pos, rgnend, markrgnindexnumber, new_name, color )
	 end
    end
  else
    -- Match entire string
    if wgt.repl_str ~= "" then
	 local new_name = wgt.repl_str
	 reaper.SetProjectMarkerByIndex( 0, i, isrgn, pos, rgnend, markrgnindexnumber, new_name, color )
    else
	 reaper.DeleteProjectMarker( 0, markrgnindexnumber, isrgn )
	 reaper.AddProjectMarker2( 0, isrgn, pos, rgnend, "", markrgnindexnumber, color )
    end
  end
end

function SearchFullProject()
  -- Loop through all markers/regions in project
  local i = 0
  while i < num_total do
    local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, i )
    if (MODE == MODES.REGION and isrgn) or (MODE == MODES.MARKER and not isrgn) then
	 AnalyzeMarkerRegion(i, isrgn, pos, rgnend, name, markrgnindexnumber, color)
    end
    i = i + 1
  end
end

function SearchTimeSel()
  -- Loop through all markers/regions in time selection
  start_time_sel, end_time_sel = reaper.GetSet_LoopTimeRange(0,0,0,0,0);
  if start_time_sel ~= end_time_sel then
    local i = 0
    while i < num_total do
	 local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, i )
	 if (MODE == MODES.REGION and isrgn) or (MODE == MODES.MARKER and not isrgn) then
	   if pos >= start_time_sel and rgnend <= end_time_sel then
		AnalyzeMarkerRegion(i, isrgn, pos, rgnend, name, markrgnindexnumber, color)
	   end
	 end
	 i = i + 1
    end
  else
    acendan.msg("Please make a time selection!","Find & Replace")
  end
end

function SetCurrentValue(key, value)
  reaper.SetExtState(SCRIPT_NAME, key, value, true) 
end

function GetPreviousValue(key, default)
  return reaper.HasExtState(SCRIPT_NAME, key) and reaper.GetExtState(SCRIPT_NAME, key) or default
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
init()
main()
