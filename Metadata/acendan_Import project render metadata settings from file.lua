-- @description Import Export Metadata
-- @author Aaron Cendan
-- @version 1.2
-- @metapackage
-- @provides
--   [main] . > acendan_Import project render metadata settings from file.lua
-- @link https://aaroncendan.me
-- @changelog
--   # Update LuaUtils path with case sensitivity for Linux

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~ USER CONFIG - EDIT ME ~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Set delimiter. "\t" is tab, "," is comma, etc.
-- NOTE: If changed, this must match your delimiter setting in acendan_Export project render metadata...
delimiter = "\t"



-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Get this script's name and directory
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local script_directory = ({reaper.get_action_context()})[2]:sub(1,({reaper.get_action_context()})[2]:find("\\[^\\]*$"))

-- Load lua utilities
acendan_LuaUtils = reaper.GetResourcePath()..'/Scripts/ACendan Scripts/Development/acendan_Lua Utilities.lua'
if reaper.file_exists( acendan_LuaUtils ) then dofile( acendan_LuaUtils ); if not acendan or acendan.version() < 4.4 then acendan.msg('This script requires a newer version of ACendan Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"ACendan Lua Utilities"); return end else reaper.ShowConsoleMsg("This script requires ACendan Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'ACendan Lua Utilities'"); return end


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function main()
  -- Convert selected file to table and set metadata accordingly
  local metadata =  acendan.fileToTable(file)
  for _, meta in pairs(metadata) do 
    if meta ~= "" then
      reaper.GetSetProjectInfo_String( 0, "RENDER_METADATA", meta:gsub(delimiter,"|"), true )
    end
  end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ UTILITIES ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Get directory of active Reaper project, returns blank if not saved
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

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock()

-- Check Reaper version
local reaper_version = tonumber(reaper.GetAppVersion():sub(1,4))
if reaper_version < 6.3 then
  reaper.MB("This script requires Reaper v6.30 or greater! Please update Reaper.","ERROR: Update Reaper!",0)
  return
end
  
-- Check for Reaper JS Extension
if reaper.JS_Dialog_BrowseForSaveFile then
  
  -- Get project info
  local project_directory = getProjDir()
  local project_name = reaper.GetProjectName(0,""):gsub("%..+","")
  local delimiter_extension = ".txt"
  if delimiter == "\t" then delimiter_extension = "_Tab Delimited.tsv"
  elseif delimiter:find(",") then delimiter_extension = "_Comma Delimited.csv" end
    
  -- File picker dialog
  retval, file = reaper.JS_Dialog_BrowseForOpenFiles( "Import Render Metadata", project_directory,  project_name .. "_Render Metadata" .. delimiter_extension, "", false )
  if retval and file ~= '' then
    reaper.defer(main)
  end
else
  reaper.MB("Please install JS_ReaScript REAPER extension, available in Reapack extension, under ReaTeam Extensions repository.","ERROR: Missing JS API!",0)
end

reaper.Undo_EndBlock(script_name,-1)

reaper.PreventUIRefresh(-1)

reaper.UpdateArrange()
