-- @description Export Media Explorer Columns
-- @author Aaron Cendan
-- @version 1.1
-- @metapackage
-- @provides
--   [main=mediaexplorer] .
-- @link https://aaroncendan.me
-- @changelog
--   # Update LuaUtils path with case sensitivity for Linux

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local script_directory = ({reaper.get_action_context()})[2]:sub(1,({reaper.get_action_context()})[2]:find("\\[^\\]*$"))
acendan_LuaUtils = reaper.GetResourcePath()..'/Scripts/ACendan Scripts/Development/acendan_Lua Utilities.lua'
if reaper.file_exists( acendan_LuaUtils ) then dofile( acendan_LuaUtils ); if not acendan or acendan.version() < 4.4 then acendan.msg('This script requires a newer version of ACendan Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"ACendan Lua Utilities"); return end else reaper.ShowConsoleMsg("This script requires ACendan Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'ACendan Lua Utilities'"); return end

local win = string.find(reaper.GetOS(), "Win") ~= nil
local sep = win and '\\' or '/'

local ini_section = "[reaper_explorer]"
local ini_section_tbl = {}
local ini_file_tbl = {}
local import_file = ""

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function main()
  local ini_file = reaper.get_ini_file()
  
  -- Get ini section contents from file
  ini_section_tbl = columnFileToTable(import_file)
  
  -- Create table with 1. first part of ini, 2. imported column data, 3. everything else
  ini_file_tbl = iniFileToTable(ini_file)
  
  -- Overwrite user's ini file
  tableToFile(ini_file_tbl,ini_file)
  
  -- Force refresh the media explorer
  reaper.Main_OnCommand(50124,0) -- Show/hide media explorer
  reaper.Main_OnCommand(50124,0) -- Show/hide media explorer
  reaper.OpenMediaExplorer("",false)
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ UTILITIES ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Convert file input to table, each line = new entry // returns Table
function iniFileToTable(filename)
  local file = io.open(filename)
  io.input(file)
  local t = {}
  local ini_found = false
  for line in io.lines() do
    -- Close ini section
    if ini_found and acendan.stringStarts(line,"[") and acendan.stringEnds(line,"]") then ini_found = false end
    
    -- Save content in ini section
    if not ini_found then table.insert(t, line) end
    
    -- Search for ini section
    if line == ini_section then 
      ini_found = true
      -- Copy over updated ini contents from imported file
      for _, v in pairs(ini_section_tbl) do
        table.insert(t,v)
      end
    end
  end
  table.insert(t, "")
  io.close(file)
  return t
end

-- Convert file input to table, each line = new entry // returns Table
function columnFileToTable(filename)
  local file = io.open(filename)
  io.input(file)
  local t = {}
  local ini_found = false
  for line in io.lines() do
    table.insert(t, line)
  end
  io.close(file)
  return t
end


-- Convert table to file
function tableToFile(  tbl,filename,sep )
  local charS,charE = "","\n"
  local file,err = io.open( filename, "wb" )
  if err then return err end
  
  local sep = sep or ""

  -- This method only works when table keys are index numbers, not strings or other stuffs
  local i = 1
  for k, v in pairs(tbl) do
    if i < #tbl then file:write(v .. "\n") else file:write(v) end
    i = i + 1
  end

  file:close()
end

    
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock()

-- Check for Reaper JS Extension
if reaper.JS_Dialog_BrowseForSaveFile then

  local reaper_directory = reaper.GetResourcePath() .. sep .. "Data" .. sep
  local extension = ".txt"
  
  -- File picker dialog
   retval, import_file = reaper.JS_Dialog_BrowseForOpenFiles( "Import Column Setup", reaper_directory, "Media Explorer Columns" .. extension, "", false )
   if retval and import_file ~= '' then
     reaper.defer(main)
   end
else
  reaper.MB("Please install JS_ReaScript REAPER extension, available in Reapack extension, under ReaTeam Extensions repository.","ERROR: Missing JS API!",0)
end

reaper.Undo_EndBlock(script_name,-1)

reaper.PreventUIRefresh(-1)

reaper.UpdateArrange()

