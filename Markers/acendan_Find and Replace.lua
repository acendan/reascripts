-- @noindex

-- @description Find and Replace w GUI WORK IN PROGRESS
-- @author Aaron Cendan
-- @version 0.1
-- @changelog
--   Added field for toggling search case-sensitivity.
--   Fixed replacement with /blank; only affects part of matching name(s).
--   Added replacement with /clear; erases entire name of matching markers/regions.
-- @metapackage
-- @provides
--   [main] . > acendan_Find and Replace.lua
-- @link https://aaroncendan.me
-- @about
--   # Find and Replace
--   By Aaron Cendan - August 2020
--
--   ### General Info
--   * Prompts user to replace part of a marker or region's name with new text if that marker/region name contains search criteria.
--   * Uses file name to detect search type.
--
--   ### Search Parameters
--   * Accepts "/blank" as search criteria for finding and replacing blank marker/region names.
--   * Accepts "/clear" as replacement criteria for erasing name of matching markers/regions.
--   * Case-sensitive and case-insensitive searching.

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GUI HEADER ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Script generated by Lokasenna's GUI Builder
local lib_path = reaper.GetExtState("Lokasenna_GUI", "lib_path_v2")
if not lib_path or lib_path == "" then
    reaper.MB("Couldn't load the Lokasenna_GUI library. Please install 'Lokasenna's GUI library v2 for Lua', available on ReaPack, then run the 'Set Lokasenna_GUI v2 library path.lua' script in your Action List.", "Whoops!", 0)
    return
end
loadfile(lib_path .. "Core.lua")()


GUI.req("Classes/Class - Menubar.lua")()
GUI.req("Classes/Class - Button.lua")()
GUI.req("Classes/Class - Options.lua")()
GUI.req("Classes/Class - Textbox.lua")()
GUI.req("Classes/Class - Label.lua")()
GUI.req("Classes/Class - Menubox.lua")()
-- If any of the requested libraries weren't found, abort the script.
if missing_lib then return 0 end

-- GUI Vars
GUI.name = "Find x Replace"
GUI.x, GUI.y, GUI.w, GUI.h = 0, 0, 448, 320
GUI.anchor, GUI.corner = "mouse", "C"


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Get script name for undo text and extracting numbers/other info, if needed
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ MENU FUNCS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

local mnu_help = {
  about = function()
    help()
  end,
  contact = function()
    reaper.CF_ShellExecute("https://www.aaroncendan.me/contact")
  end
}

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~ MENU CONTENTS ~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

local menus = {
    {title = "Help", options = {
        {"Info and Instructions",          mnu_help.about},
        {""},
        {"Contact",                    mnu_help.contact},
    }},
}

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function findReplace()
  reaper.PreventUIRefresh(1)
  reaper.Undo_BeginBlock()

  -- Get/store user input from GUI
  saveStorage()

  if g_item == 1 then mode_name = "Markers" elseif g_item == 2 then mode_name = "Regions" end
  retval, num_markers, num_regions = reaper.CountProjectMarkers( 0 )
  num_total = num_markers + num_regions

  if mode_name == "Regions" then
    num_items = num_regions
  elseif mode_name == "Markers" then
    num_items = num_markers
  end

  if num_items > 0 then
    if g_area == 1 then
      searchFullProject()
    elseif g_area == 2 then
      searchTimeSelection()
    elseif g_area == 3 then
      searchSelectedMarkersRegions()
    end
  else
    msg(string.format("Project has no %s" .. "!", mode_name))
  end

  reaper.Undo_EndBlock(script_name, -1)
  reaper.PreventUIRefresh(-1)
  reaper.UpdateArrange()

  -- Auto-close
  if g_clos then gfx.quit() end

end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ UTILITIES ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function analyzeMarkerRegion(i, isrgn, pos, rgnend, name, markrgnindexnumber, color)
  if g_find ~= "/blank" and g_find ~= "/clear" then
    if g_sens then
      if string.find(name, g_find) then
        if g_replace ~= "/blank" and g_replace ~= "/clear" then
          local new_name = string.gsub( name, g_find, g_replace)
          reaper.SetProjectMarkerByIndex( 0, i, isrgn, pos, rgnend, markrgnindexnumber, new_name, color )
        elseif g_replace == "/blank" then
          local new_name = string.gsub( name, g_find, "")
          reaper.SetProjectMarkerByIndex( 0, i, isrgn, pos, rgnend, markrgnindexnumber, new_name, color )
        elseif g_replace == "/clear" then
          reaper.DeleteProjectMarker( 0, markrgnindexnumber, isrgn )
          reaper.AddProjectMarker2( 0, isrgn, pos, rgnend, '', markrgnindexnumber, color )
        end
      end
    else
      local lower_name = string.lower(name)
      local lower_search_string = string.lower(g_find)
      local j, k = string.find(lower_name, lower_search_string)
      if j and k then
        if g_replace ~= "/blank" and g_replace ~= "/clear" then
          local new_name = string.sub(name,1,j-1) .. g_replace .. string.sub(name,k+1,string.len(name))
          reaper.SetProjectMarkerByIndex( 0, i, isrgn, pos, rgnend, markrgnindexnumber, new_name, color )
        elseif g_replace == "/blank" then
          local new_name = string.sub(name,1,j-1) .. string.sub(name,k+1,string.len(name))
          reaper.SetProjectMarkerByIndex( 0, i, isrgn, pos, rgnend, markrgnindexnumber, new_name, color )
        elseif g_replace == "/clear" then
          reaper.DeleteProjectMarker( 0, markrgnindexnumber, isrgn )
          reaper.AddProjectMarker2( 0, isrgn, pos, rgnend, '', markrgnindexnumber, color )
        end
      end
    end
  else
    if name == "" then
      if g_replace ~= "/blank" and g_replace ~= "/clear" then
        local new_name = g_replace
        reaper.SetProjectMarkerByIndex( 0, i, isrgn, pos, rgnend, markrgnindexnumber, new_name, color )
      end
    end
  end
end

function searchFullProject()
  -- Loop through all markers/regions in project
  if mode_name == "Regions" then
    local i = 0
    while i < num_total do
      local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, i )
      if isrgn then
        analyzeMarkerRegion(i, isrgn, pos, rgnend, name, markrgnindexnumber, color)
      end
      i = i + 1
    end
  elseif mode_name == "Markers" then
    local i = 0
    while i < num_total do
      local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, i )
      if not isrgn then
        analyzeMarkerRegion(i, isrgn, pos, rgnend, name, markrgnindexnumber, color)
      end
      i = i + 1
    end
  end
end

function searchTimeSelection()
  -- Loop through all markers/regions in time selection
  start_time_sel, end_time_sel = reaper.GetSet_LoopTimeRange(0,0,0,0,0);
  -- Confirm valid time selection
  if start_time_sel ~= end_time_sel then
    if mode_name == "Regions" then
      local i = 0
      while i < num_total do
        local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, i )
        if isrgn then
          if pos >= start_time_sel and rgnend <= end_time_sel then
            analyzeMarkerRegion(i, isrgn, pos, rgnend, name, markrgnindexnumber, color)
          end
        end
        i = i + 1
      end
    elseif mode_name == "Markers" then
      local i = 0
      while i < num_total do
        local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, i )
        if not isrgn then
          if pos >= start_time_sel and pos <= end_time_sel then
            analyzeMarkerRegion(i, isrgn, pos, rgnend, name, markrgnindexnumber, color)
          end
        end
        i = i + 1
      end
    end
  else
    reaper.ShowMessageBox("To Find & Replace within a time selection, you are going to need a time selection!","Find/Replace", 0)
  end
end

function searchSelectedMarkersRegions()
  -- Ideally, it would be possible to run this Find/Replace functionality on regions
  -- that are selected in the Region Render Matrix, but unfortunately, that info is not
  -- exposed via the API as of Reaper v6.10.
end

-- Get/Set ext state storage (NOT PROJ EXTSTATE)
function getStorage(key)
  local stored = reaper.GetExtState("acendan_FindReplace", key)
  if stored then return stored else return nil end
end

function setStorage(key,val)
  reaper.SetExtState("acendan_FindReplace", key, val, true)
end

function deleteStorage(key)
  reaper.DeleteExtState( "acendan_FindReplace", key, true )
end

-- Fill out the GUI with stored vals
function loadStorage()

  -- Textboxes
  local prev_find = getStorage("Find")                  -- Find
  if prev_find then GUI.Val("txt_find",prev_find) end
  
  local prev_repl = getStorage("Replace")               -- Replace
  if prev_repl then GUI.Val("txt_replace",prev_repl) end
      
  -- Menus 
  local prev_item = getStorage("Item")                 -- Search Item (Markers, Regions)
  if prev_item then GUI.Val("mnu_itm",prev_item) end
  
  local prev_area = getStorage("Area")                 -- Search Area (Proj, Time Sel, etc.)
  if prev_area then GUI.Val("mnu_area",prev_area) end
  
  -- Toggles
  local prev_clr  = getStorage("ClearMatches")          -- Clear Matches
  if prev_clr == "true" then GUI.Val("chk_clear",true) elseif prev_clr == "false" then GUI.Val("chk_clear",false) end
  
  local prev_sens = getStorage("CaseSens")              -- Case Sensitivity
  if prev_sens == "true" then GUI.Val("chk_case",true) elseif prev_sens == "false" then GUI.Val("chk_case",false) end
  
  local prev_clos = getStorage("AutoClose")             -- Auto Close
  if prev_clos == "true" then GUI.Val("chk_close",true) elseif prev_clos == "false" then GUI.Val("chk_close",false) end
end

-- Save storage on submit
function saveStorage()

  -- Textboxes (g_ vars are STRINGS)
  g_find = GUI.Val("txt_find")
  if #g_find > 0 then setStorage("Find", g_find) else g_find = "/blank"; setStorage("Find", "") end
  
  g_replace = GUI.Val("txt_replace")
  if #g_replace > 0 then setStorage("Replace", g_replace) else g_replace = "/blank"; setStorage("Replace", "") end
      
  -- Menus (g_ vars are NUMBERS, 1-indexed)
  g_item = GUI.Val("mnu_itm")
  if g_item then setStorage("Item",g_item) else g_item = "Region"; setStorage("Item", "Region") end
  
  g_area = GUI.Val("mnu_area")
  if g_area then setStorage("Area",g_area) else g_area = "Project"; setStorage("Area", "Project") end
  
  -- Toggles (g_ variables are BOOLEANS)
  g_clr = GUI.Val("chk_clear")
  if g_clr then g_replace = "/clear"; setStorage("ClearMatches",tostring(g_clr)) else g_clr = false; setStorage("ClearMatches",tostring(g_clr)) end
  
  g_sens = GUI.Val("chk_case")
  if g_sens then setStorage("CaseSens",tostring(g_sens)) else g_sens = false; setStorage("CaseSens",tostring(g_sens)) end
   
  g_clos = GUI.Val("chk_close")
  if g_clos then setStorage("AutoClose",tostring(g_clos)) else g_clos = false; setStorage("AutoClose",tostring(g_clos)) end
end

-- Deliver messages and add new line in console
function dbg(dbg)
  reaper.ShowConsoleMsg(dbg .. "\n")
end

-- Deliver messages using message box
function msg(msg)
  reaper.MB(msg, script_name, 0)
end

-- Open ReaPack About page for this script
function help()
  if not reaper.ReaPack_GetOwner then
    reaper.MB('This feature requires ReaPack v1.2 or newer.', script_name, 0)
    return
  end
  local owner = reaper.ReaPack_GetOwner(({reaper.get_action_context()})[2])
  if not owner then
    reaper.MB(string.format(
      'This feature is unavailable because "%s" was not installed using ReaPack.',
      script_name), script_name, 0)
    return
  end
  reaper.ReaPack_AboutInstalledPackage(owner)
  reaper.ReaPack_FreeEntry(owner)
end


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~ GUI ~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

GUI.New("mnu_itm", "Menubox", {
    z = 11,
    x = 64,
    y = 176,
    w = 192,
    h = 20,
    caption = "Items:  ",
    optarray = {"Markers", "Regions"},
    retval = 1.0,
    font_a = 3,
    font_b = 4,
    col_txt = "txt",
    col_cap = "txt",
    bg = "wnd_bg",
    pad = 4,
    noarrow = false,
    align = 0
})

GUI.New("chk_case", "Checklist", {
    z = 11,
    x = 168,
    y = 256,
    w = 128,
    h = 38,
    caption = "",
    optarray = {"Case Sensitive"},
    dir = "v",
    pad = 6,
    font_a = 2,
    font_b = 3,
    col_txt = "txt",
    col_fill = "elm_fill",
    bg = "wnd_bg",
    frame = false,
    shadow = true,
    swap = nil,
    opt_size = 20
})

GUI.New("btn_submit", "Button", {
    z = 11,
    x = 288,
    y = 176,
    w = 128,
    h = 60,
    caption = "Submit!",
    font = 3,
    col_txt = "txt",
    col_fill = "elm_frame",
    func = findReplace
})

GUI.New("mnu_main", "Menubar", {
    z = 11,
    x = 0,
    y = 0,
    w = 912.0,
    h = 20.0,
    menus = menus,
    font = 2,
    col_txt = "txt",
    col_bg = "elm_frame",
    col_over = "elm_fill",
    fullwidth = true
})

GUI.New("chk_clear", "Checklist", {
    z = 11,
    x = 28,
    y = 256,
    w = 128,
    h = 38,
    caption = "",
    optarray = {"Clear Matches"},
    dir = "v",
    pad = 6,
    font_a = 2,
    font_b = 3,
    col_txt = "txt",
    col_fill = "elm_fill",
    bg = "wnd_bg",
    frame = false,
    shadow = true,
    swap = nil,
    opt_size = 20
})

GUI.New("chk_close", "Checklist", {
    z = 11,
    x = 312,
    y = 256,
    w = 128,
    h = 38,
    caption = "",
    optarray = {"Auto-Close"},
    dir = "v",
    pad = 6,
    font_a = 2,
    font_b = 3,
    col_txt = "txt",
    col_fill = "elm_fill",
    bg = "wnd_bg",
    frame = false,
    shadow = true,
    swap = nil,
    opt_size = 20
})

GUI.New("mnu_area", "Menubox", {
    z = 11,
    x = 64,
    y = 216,
    w = 192,
    h = 20,
    caption = "Area: ",
    optarray = {"Project", "Time Selection", "Region Marker Manager"},
    retval = 1.0,
    font_a = 3,
    font_b = 4,
    col_txt = "txt",
    col_cap = "txt",
    bg = "wnd_bg",
    pad = 4,
    noarrow = false,
    align = 0
})

GUI.New("lbl_title", "Label", {
    z = 11,
    x = 144,
    y = 40,
    caption = "Find & Replace",
    font = 1,
    color = "txt",
    bg = "wnd_bg",
    shadow = false
})

GUI.New("txt_replace", "Textbox", {
    z = 11,
    x = 64,
    y = 136,
    w = 352,
    h = 20,
    caption = "Replace: ",
    cap_pos = "left",
    font_a = 3,
    font_b = "monospace",
    color = "txt",
    bg = "wnd_bg",
    shadow = true,
    pad = 4,
    undo_limit = 20
})

GUI.New("txt_find", "Textbox", {
    z = 11,
    x = 64,
    y = 96,
    w = 352,
    h = 20,
    caption = "Find: ",
    cap_pos = "left",
    font_a = 3,
    font_b = "monospace",
    color = "txt",
    bg = "wnd_bg",
    shadow = true,
    pad = 4,
    undo_limit = 20
})


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~ INIT ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Check for JS_ReaScript Extension
if reaper.JS_Dialog_BrowseForSaveFile then

  GUI.Init()
  GUI.Main()
  
  -- Show "always on top" pin
  local w = reaper.JS_Window_Find("Find x Replace", true)
  if w then reaper.JS_Window_AttachTopmostPin(w) end
  
  loadStorage()
else
  msg("Please install the JS_ReaScript REAPER extension, available in ReaPack, under the ReaTeam Extensions repository.")
end
