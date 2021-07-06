-- @description Import Export Metadata
-- @author Aaron Cendan
-- @version 1.0
-- @metapackage
-- @provides
--   [main] . > acendan_Export project render metadata settings to file.lua
-- @link https://aaroncendan.me

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~ USER CONFIG - EDIT ME ~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Copy path to render metadata file after export?
copy_path = true


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Get this script's name and directory
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local script_directory = ({reaper.get_action_context()})[2]:sub(1,({reaper.get_action_context()})[2]:find("\\[^\\]*$"))

-- Load lua utilities
acendan_LuaUtils = reaper.GetResourcePath()..'/scripts/ACendan Scripts/Development/acendan_Lua Utilities.lua'
if reaper.file_exists( acendan_LuaUtils ) then dofile( acendan_LuaUtils ); if not acendan or acendan.version() < 4.4 then acendan.msg('This script requires a newer version of ACendan Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"ACendan Lua Utilities"); return end else reaper.ShowConsoleMsg("This script requires ACendan Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'ACendan Lua Utilities'"); return end


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function main()
  -- Fetch list of all proj metadata values
  local meta_ret, metadata = reaper.GetSetProjectInfo_String( 0, "RENDER_METADATA", "", false )
  if meta_ret and metadata ~= "" then
    
    -- Open file
    local f = io.open(file, "w")
    
    -- Iterate through list
    for meta in string.gmatch(metadata, '([^;]+)') do
      local ret, meta_val = reaper.GetSetProjectInfo_String( 0, "RENDER_METADATA", meta, false )
      if ret then 
        export(f,meta .. "|" .. meta_val)
      end
    end
    
    -- Close file
    f:close() -- never forget to close the file
  end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ UTILITIES ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Write line to file
function export(f, variable)
  f:write(variable)
  f:write("\n")
end

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
  local project_directory = getProjDir()
  retval, file = reaper.JS_Dialog_BrowseForSaveFile( "Export Render Metadata", project_directory, "Render Metadata.txt", "Text Files (.txt)\0\0" )
  if retval and file ~= '' then
    if not file:find('.txt') then file = file .. ".txt" end
    if copy_path then
      reaper.CF_SetClipboard( file )
    end
    reaper.defer(main)
  end
else
  reaper.MB("Please install JS_ReaScript REAPER extension, available in Reapack extension, under ReaTeam Extensions repository.","ERROR: Missing JS API!",0)
end

reaper.Undo_EndBlock(script_name,-1)

reaper.PreventUIRefresh(-1)

reaper.UpdateArrange()
