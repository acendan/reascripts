-- @description Create Tempo Markers From MIDI Notes
-- @author Aaron Cendan
-- @version 1.1
-- @metapackage
-- @provides
--   [main] .
-- @link https://aaroncendan.me
-- @about
--   # Script request from @SoapyMargherita and @ryksounet!
-- @screenshot
--   https://gifyu.com/image/Sxbqe
-- @changelog
--   # Update LuaUtils path with case sensitivity for Linux

--[[ HOW TO USE THIS SCRIPT
 
 Setup
  1. Insert a piece of music that wasn't recorded at a linear tempo. 
  2. Insert any virtual instrument that has a reasonable click sound
      on another track, and play or click in time with the non-linear music. 

 Script - Select All items on your click track, and run this script, which will:
  1. Save your current project markers
  2. TEMPORARILY remove all project markers
  3. "SWS/BR: Create project markers from notes in selected MIDI items" 
  4. "SWS/BR: Convert project markers to tempo markers"
    4a. Enter the amount of markers per bar (EG, 4 for a quarter note click in 4/4 time signature)
    4b. Make sure to CHECK the box for "Remove Project Markers"
  5. When you close or cancel the window, this script will RESTORE all of your original project markers

]]--

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Refresh rate (in seconds)
local refresh_rate = 0.3

-- Get action context info (needed for toolbar button toggling)
local _, _, section, cmdID = reaper.get_action_context()

-- Get this script's name and directory
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local script_directory = ({reaper.get_action_context()})[2]:sub(1,({reaper.get_action_context()})[2]:find("\\[^\\]*$"))

-- Load lua utilities
acendan_LuaUtils = reaper.GetResourcePath()..'/Scripts/ACendan Scripts/Development/acendan_Lua Utilities.lua'
if reaper.file_exists( acendan_LuaUtils ) then dofile( acendan_LuaUtils ); if not acendan or acendan.version() < 6.2 then acendan.msg('This script requires a newer version of ACendan Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"ACendan Lua Utilities"); return end else reaper.ShowConsoleMsg("This script requires ACendan Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'ACendan Lua Utilities'"); return end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Setup runs once on script startup
function setup()
  -- Timing control
  local start = reaper.time_precise()
  check_time = start
  
  -- Toggle command state on
  reaper.SetToggleCommandState( section, cmdID, 1 )
  reaper.RefreshToolbar2( section, cmdID )
  
  -- Ini marker table
  ini_mkr_tbl = {}
  acendan.saveProjectMarkers(ini_mkr_tbl)
  acendan.deleteAllProjectMarkers()
  
  -- SWS/BR: Create project markers from notes in selected MIDI items
  reaper.Main_OnCommand(reaper.NamedCommandLookup("_BR_MIDI_NOTES_TO_MARKERS"),0)
  
  -- SWS/BR: Convert project markers to tempo markers...
  reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_BRCONVERTMARKERSTOTEMPO"),0)
end

-- Main function will run in Reaper's defer loop. EFFICIENCY IS KEY.
function main()
  -- System time in seconds (3600 per hour)
  local now = reaper.time_precise()
  
  -- If the amount of time passed is greater than refresh rate, execute code
  if now - check_time >= refresh_rate then

    -- Check if still open (SWS/BR: Convert project markers to tempo markers) 
    if not reaper.JS_Window_Find("SWS/BR - Markers to tempo", true) then
      return 
    end
    
    -- Reset last used time
    check_time = now
  end

  reaper.defer(main)
end

-- Exit function will run once when the script is terminated
function Exit()
  -- Restore initial markers
  acendan.restoreProjectMarkers(ini_mkr_tbl)
  
  reaper.UpdateArrange()
  reaper.SetToggleCommandState( section, cmdID, 0 )
  reaper.RefreshToolbar2( section, cmdID )
  return reaper.defer(function() end)
end

setup()
reaper.atexit(Exit)
main()
