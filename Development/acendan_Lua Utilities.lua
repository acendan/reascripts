-- @noindex



-- @description Lua Utility Functions and ReaScript Template
-- @author Aaron Cendan
-- @version 1.5
-- @metapackage
-- @provides
--   [main] . > acendan_Lua Utilities.lua
-- @link https://aaroncendan.me
-- @about
--   # Lua Utilities
--   By Aaron Cendan - July 2020
--
--   ### Upper Section - Template
--   * Provides a basic template for lua scripts.
--   * I found myself copy pasting from old scripts so hopefully no more of that.
--
--   ### Lower Section - Utilities
--   * Pretty much just a big pile of helper functions.
--   * Ctrl + F is your friend here.
--   * I wish I kept better documentation of the original script creators, as not all of these are my own original functions.
--   * If you recognize one of your functions in here, I will gladly credit you directly next to that script, reach out at my website above.


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~ USER CONFIG - EDIT ME ~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Get script name for undo text and extracting numbers/other info, if needed
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function main()

end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ UTILITIES ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Deliver messages and add new line in console
function dbg(dbg)
  reaper.ShowConsoleMsg(dbg .. "\n")
end

-- Deliver messages using message box
function msg(msg)
  reaper.MB(msg, script_name, 0)
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock()

main()

reaper.Undo_EndBlock(script_name,-1)

reaper.PreventUIRefresh(-1)

reaper.UpdateArrange()



-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
if false then   -- Don't actually evaluate anything here if this script is run from the actions menu
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~ DEBUG & MESSAGES ~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Deliver messages and add new line in console
function dbg(dbg)
  reaper.ShowConsoleMsg(dbg .. "\n")
end

-- Deliver messages using message box
function msg(msg)
  reaper.MB(msg, script_name, 0)
end

-- Rets to bools // returns Boolean
function retToBool(ret)
  if ret == 1 then return true else return false end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~ GET USER INPUT ~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Single field
local ret_input, user_input = reaper.GetUserInputs( script_name, 1, "Input Field", "Placeholder" )
if not ret_input then return end

-- Multiple fields
local ret_input, user_input = reaper.GetUserInputs( script_name, 2,
                          "Input Field 1,Input Field 2" .. ",extrawidth=100",
                          "Placeholder 1,Placeholder 2" )
if not ret_input then return end
local input_1, input_2 = user_input:match("([^,]+),([^,]+)")


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~ VALUE MANIPULATION ~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Check if an input string starts with another string // returns Boolean
function string.starts(str, start)
   return str:sub(1, #start) == start
end

-- Check if an input string ends with another string // returns Boolean
function string.ends(str, ending)
   return ending == "" or str:sub(-#ending) == ending
end

-- Clamp a value to given range // returns Number
function clampValue(input,min,max)
  return math.min(math.max(input,min),max)
end

-- Scale value from range to range
function scaleBetween(unscaled_val, min_new_range, max_new_range, min_old_range, max_old_range)
  return (max_new_range - min_new_range) * (unscaled_val - min_old_range) / (max_old_range - min_old_range) + min_new_range
end


-- Round the input value // returns Number
function roundValue(input)
  return math.floor(input + 0.5)
end

-- Increment a number formatted as a string // returns Number
function incrementNumStr(num)
  return tostring(tonumber(num) + 1)
end

-- Convert An Input String To Title Case // returns String
-- To use this, add the utility function then insert the line below where needed:
--> input_string = input_string:gsub("(%a)([%w_']*)", toTitleCase)
function toTitleCase(first, rest)
  return first:upper()..rest:lower()
end


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~ TABLES ~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Get length/number of entries in a table // returns Number
-- This is relatively unnecessary, as table length can just be acquired with #table
function tableLength(table)
  local i = 0
  for _ in pairs(table) do i = i + 1 end
  return i
end

-- Check if a table contains a key // returns Boolean
function tableContainsKey(table, key)
    return table[key] ~= nil
end

-- Append new item to end of table
function tableAppend(table, item)
  table[#table+1] = item
end

-- CSV to Table
-- http://lua-users.org/wiki/LuaCsv
function parseCSVLine (line,sep) 
  local res = {}
  local pos = 1
  sep = sep or ','
  while true do 
    local c = string.sub(line,pos,pos)
    if (c == "") then break end
    if (c == '"') then
      -- quoted value (ignore separator within)
      local txt = ""
      repeat
        local startp,endp = string.find(line,'^%b""',pos)
        txt = txt .. string.sub(line,startp+1,endp-1)
        pos = endp + 1
        c = string.sub(line,pos,pos) 
        if (c == '"') then txt = txt..'"' end 
        -- check first char AFTER quoted string, if it is another
        -- quoted string without separator, then append it
        -- this is the way to "escape" the quote char in a quote. example:
        --   value1,"blub""blip""boing",value3  will result in blub"blip"boing  for the middle
      until (c ~= '"')
      table.insert(res,txt)
      assert(c == sep or c == "")
      pos = pos + 1
    else     
      -- no quotes used, just look for the first separator
      local startp,endp = string.find(line,sep,pos)
      if (startp) then 
        table.insert(res,string.sub(line,pos,startp-1))
        pos = endp + 1
      else
        -- no separator found -> use rest of string and terminate
        table.insert(res,string.sub(line,pos))
        break
      end 
    end
  end
  return res
end

-- Useful table statistics functions available at:
-- http://lua-users.org/wiki/SimpleStats

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~ ITEMS ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Loop through all items
local num_items = reaper.CountMediaItems( 0 )
if num_items > 0 then
  for i=0, num_items - 1 do
    local item =  reaper.GetMediaItem( 0, i )
    -- Process item
    
    local take = reaper.GetActiveTake( item )
    if take ~= nil then 
      -- Process active take
    end
  end
else
  msg("Project has no items!")
end

-- Loop through selected items
local num_sel_items = reaper.CountSelectedMediaItems(0)
if num_sel_items > 0 then
  for i=0, num_sel_items - 1 do
    local item = reaper.GetSelectedMediaItem( 0, i )
    -- Process item
    
    local take = reaper.GetActiveTake( item )
    if take ~= nil then 
      -- Process active take
    end
  end
else
  msg("No items selected!")
end

-- Save initially selected items to table
function saveSelectedItems (table)
  for i = 1, reaper.CountSelectedMediaItems(0) do
    table[i] = reaper.GetSelectedMediaItem(0, i-1)
  end
end

-- Restore selected items from table. Requires tableLength() above
function restoreSelectedItems(table)
  for i = 1, tableLength(table) do
    reaper.SetMediaItemSelected( table[i], true )
  end
end

reaper.Main_OnCommand(40289,0) -- Unselect all items

-- Get starting position of selected items // returns Number (position)
function getStartPosSelItems()
  local position = math.huge

  -- Loop through selected items
  local num_sel_items = reaper.CountSelectedMediaItems(0)
  if num_sel_items > 0 then
    for i=0, num_sel_items - 1 do
      local item = reaper.GetSelectedMediaItem( 0, i )
      local item_start_pos = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
      if item_start_pos < position then
        position = item_start_pos
      end
    end
  else
    msg("No items selected!")
  end

  return position
end

-- Get source file name of active take from item input  // returns String
function getFilenameTrackActiveTake(item)
  if item ~= nil then
    local tk = reaper.GetActiveTake(item)
    if tk ~= nil then
      local pcm_source = reaper.GetMediaItemTake_Source(tk)
      local filenamebuf = ""
      filenamebuf = reaper.GetMediaSourceFileName(pcm_source, filenamebuf)
      return filenamebuf
    end
  end
  return nil
end


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ TRACKS ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Loop through all tracks
local num_tracks =  reaper.CountTracks( 0 )
if num_tracks > 0 then
  for i = 0, num_tracks-1 do
    local track = reaper.GetTrack(0,i)
    -- Process track
  end
else
  msg("Project has no tracks!")
end
    
-- Loop through selected tracks
local num_sel_tracks = reaper.CountSelectedTracks( 0 )
if num_sel_tracks > 0 then
  for i = 0, num_sel_tracks-1 do
    local track = reaper.GetSelectedTrack(0,i)
    -- Process track
  end
else
  msg("No tracks selected!")
end

-- Save initially selected tracks to table
function saveSelectedTracks (table)
  for i = 1, reaper.CountSelectedTracks(0) do
    table[i] = reaper.GetSelectedTrack(0, i-1)
  end
end

-- Restore selected tracks from table. Requires tableLength() above
function restoreSelectedTracks(table)
  for i = 1, tableLength(table) do
    reaper.SetTrackSelected( table[i], true )
  end
end


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ REGIONS ~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Loop through all regions
local ret, num_markers, num_regions = reaper.CountProjectMarkers( 0 )
local num_total = num_markers + num_regions
if num_regions > 0 then
  local i = 0
  while i < num_total do
    local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, i )
    if isrgn then
      -- Process region
    end
    i = i + 1
  end
else
  msg("Project has no regions!")
end
    
-- Loop through regions in time selection
local ret, num_markers, num_regions = reaper.CountProjectMarkers( 0 )
local num_total = num_markers + num_regions
local start_time_sel, end_time_sel = reaper.GetSet_LoopTimeRange(0,0,0,0,0);
if start_time_sel ~= end_time_sel then
  local i = 0
  while i < num_total do
    local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, i )
    if isrgn then
      if pos >= start_time_sel and rgnend <= end_time_sel then
        -- Process regions
      end
    end
    i = i + 1
  end
else
  msg("You need to make a time selection!")
end

-- Get selected regions in Rgn Mrkr Manager using JS_Reaper API, requires getRegionManager
-- https://github.com/ReaTeam/ReaScripts-Templates/blob/master/Regions-and-Markers/X-Raym_Get%20selected%20regions%20in%20region%20and%20marker%20manager.lua
--[[ EXAMPLE USAGE

  local sel_rgn_table = getSelectedRegions()
  if sel_rgn_table then 
    for _, rgn_idx in pairs(sel_rgn_table) do 
      dbg(rgn_idx)
    end
  else
    msg("No regions selected!\n\nPlease go to View > Region/Marker Manager to select regions.") 
  end
  
]]--
function getSelectedRegions()
  local hWnd = getRegionManager()
  if hWnd == nil then return end  

  local container = reaper.JS_Window_FindChildByID(hWnd, 1071)

  sel_count, sel_indexes = reaper.JS_ListView_ListAllSelItems(container)
  if sel_count == 0 then return end 

  names = {}
  i = 0
  for index in string.gmatch(sel_indexes, '[^,]+') do 
    i = i+1
    local sel_item = reaper.JS_ListView_GetItemText(container, tonumber(index), 1)
    if sel_item:find("R") ~= nil then
      names[i] = tonumber(sel_item:sub(2))
    end
  end
  
  -- Return table of selected regions
  return names
end

function getRegionManager()
  local title = reaper.JS_Localize("Region/Marker Manager", "common")
  local arr = reaper.new_array({}, 1024)
  reaper.JS_Window_ArrayFind(title, true, arr)
  local adr = arr.table()
  for j = 1, #adr do
    local hwnd = reaper.JS_Window_HandleFromAddress(adr[j])
    -- verify window by checking if it also has a specific child.
    if reaper.JS_Window_FindChildByID(hwnd, 1056) then -- 1045:ID of clear button
      return hwnd
    end 
  end
end


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ MARKERS ~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Loop through all markers
local ret, num_markers, num_regions = reaper.CountProjectMarkers( 0 )
local num_total = num_markers + num_regions
if num_markers > 0 then
  local i = 0
  while i < num_total do
    local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, i )
    if not isrgn then
      -- Process markers
    end
    i = i + 1
  end
else
  msg("Project has no markers!")
end
    
-- Loop through markers in time selection
local ret, num_markers, num_regions = reaper.CountProjectMarkers( 0 )
local num_total = num_markers + num_regions
local start_time_sel, end_time_sel = reaper.GetSet_LoopTimeRange(0,0,0,0,0);
if start_time_sel ~= end_time_sel then
  local i = 0
  while i < num_total do
    local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, i )
    if not isrgn then
      if pos >= start_time_sel and pos <= end_time_sel then
        -- Process markers
      end
    end
    i = i + 1
  end
else
  msg("You need to make a time selection!")
end

-- Get selected markers in Rgn Mrkr Manager using JS_Reaper API, requires getRegionManager
--[[ EXAMPLE USAGE

  local sel_mkr_table = getSelectedMarkers()
  if sel_mkr_table then 
    for _, mkr_idx in pairs(sel_mkr_table) do 
      dbg(mkr_idx)
    end
  else
    msg("No markers selected!\n\nPlease go to View > Region/Marker Manager to select regions.") 
  end
  
]]--
function getSelectedMarkers()
  local hWnd = getRegionManager()
  if hWnd == nil then return end  

  local container = reaper.JS_Window_FindChildByID(hWnd, 1071)

  sel_count, sel_indexes = reaper.JS_ListView_ListAllSelItems(container)
  if sel_count == 0 then return end 

  names = {}
  i = 0
  for index in string.gmatch(sel_indexes, '[^,]+') do 
    i = i+1
    local sel_item = reaper.JS_ListView_GetItemText(container, tonumber(index), 1)
    if sel_item:find("M") ~= nil then
      names[i] = tonumber(sel_item:sub(2))
    end
  end
  
  -- Return table of selected regions
  return names
end

function getRegionManager()
  local title = reaper.JS_Localize("Region/Marker Manager", "common")
  local arr = reaper.new_array({}, 1024)
  reaper.JS_Window_ArrayFind(title, true, arr)
  local adr = arr.table()
  for j = 1, #adr do
    local hwnd = reaper.JS_Window_HandleFromAddress(adr[j])
    -- verify window by checking if it also has a specific child.
    if reaper.JS_Window_FindChildByID(hwnd, 1056) then -- 1045:ID of clear button
      return hwnd
    end 
  end
end



-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ TIME SEL ~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Save original time/loop selection
function saveLoopTimesel()
  init_start_timesel, init_end_timesel = reaper.GetSet_LoopTimeRange(0, 0, 0, 0, 0)
  init_start_loop, init_end_loop = reaper.GetSet_LoopTimeRange(0, 1, 0, 0, 0)
end

-- Restore original time/loop selection
function restoreLoopTimesel()
  reaper.GetSet_LoopTimeRange(1, 0, init_start_timesel, init_end_timesel, 0)
  reaper.GetSet_LoopTimeRange(1, 1, init_start_loop, init_end_loop, 0)
end


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~ SCRIPT NAME ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Get number from anywhere in a script name // returns Number
function extractNumberInScriptName()
  return tonumber(string.match(script_name, "%d+"))
end

-- Get text field from end of script name, formatted like "acendan_Blah blah blah-FIELD.lua" // returns String
function extractFieldScriptName()
  return string.sub( script_name, string.find(script_name, "-") + 1, string.len(script_name))
end


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~ COLORS ~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Convert RGB value to int for Reaper native colors, i.e. region coloring // returns Number
function rgb2int ( R, G, B )
  return (R + 256 * G + 65536 * B)|16777216
end


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FILE MGMT ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Check if a file exists // returns Boolean
function fileExists(filename)
   local f=io.open(filename,"r")
   if f~=nil then io.close(f) return true else return false end
end

-- Check if a directory/folder exists. // returns Boolean
function directoryExists(folder)
  local fileHandle, strError = io.open(folder .. "\\*.*","r")
  if fileHandle ~= nil then
    io.close(fileHandle)
    return true
  else
    if string.match(strError,"No such file or directory") then
      return false
    else
      return true
    end
  end
end

-- Get project directory (folder) // returns String
function getProjDir()
  if reaper.GetOS() == "Win32" or reaper.GetOS() == "Win64" then
    separator = "\\"
  else
    separator = "/"
  end
  retval, project_path_name = reaper.EnumProjects(-1, "")
  if project_path_name ~= "" then
    dir = project_path_name:match("(.*" .. separator ..")")
    return dir
  else
    return ""
  end
end

-- Open a webpage or file directory
function openDirectoryOrURL(path)
  reaper.CF_ShellExecute(path)
end

-- Get 3 character all caps extension from a file path input // returns String
function fileExtension(filename)
  return filename:sub(-3):upper()
end

-- Convert file input to table, each line = new entry // returns Table
function fileToTable(filename)
  local file = io.open(filename)
  io.input(file)
  local t = {}
  for line in io.lines() do
    table.insert(t, line)
  end
  table.insert(t, "")
  io.close(file)
  return t
end


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ RENDERING ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Get/Set render settings to/from table
function getRenderSettings()
  local t = {}
  t.rendersettings   = reaper.GetSetProjectInfo(0, "RENDER_SETTINGS", -1, false)            -- Master mix, stems, etc
  t.boundsflag       = reaper.GetSetProjectInfo(0, "RENDER_BOUNDSFLAG", -1, false)          -- Time selection, project, etc
  t._, t.renderformat    = reaper.GetSetProjectInfo_String(0, 'RENDER_FORMAT', "", false)   -- File format, i.e. "ewav"
  t._, t.renderdirectory = reaper.GetSetProjectInfo_String(0, "RENDER_FILE", "", false)     -- C:\users\aaron\docs\blah
  t._, t.renderfilename  = reaper.GetSetProjectInfo_String(0, "RENDER_PATTERN", "", false)  -- $item_$itemnumber_JU20
  return t
end

function setRenderSettings(t)
  reaper.GetSetProjectInfo(0, "RENDER_SETTINGS", t.rendersettings, true)
  reaper.GetSetProjectInfo(0, "RENDER_BOUNDSFLAG", t.boundsflag, true)
  reaper.GetSetProjectInfo_String(0, 'RENDER_FORMAT', t.renderformat, true)
  reaper.GetSetProjectInfo_String(0, "RENDER_FILE", t.renderdirectory, true)
  reaper.GetSetProjectInfo_String(0, "RENDER_PATTERN", t.renderfilename, true)
end


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~ REAPACK ~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
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


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Notification message when run from actions
else
  -- msg("To view, copy, or edit the Lua Utilities, click 'Edit Action...'")
end
