-- @description PT Shuffle Mode ish
-- @author Aaron Cendan
-- @version 1.1
-- @metapackage
-- @provides
--   [main] . > acendan_Shuffle Mode_Move all items left continuously background.lua
-- @link https://aaroncendan.me
-- @about
--   # This is a background/toggle script!
-- @changelog
--   # Update LuaUtils path with case sensitivity for Linux

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Refresh rate (in seconds)
local refresh_rate = 0.3


-- Use first track item as offset, or scoot to start
local scoot_to_start = true


-------------------------------------------

-- Get action context info (needed for toolbar button toggling)
local _, _, section, cmdID = reaper.get_action_context()

-- Get this script's name and directory
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local script_directory = ({reaper.get_action_context()})[2]:sub(1,({reaper.get_action_context()})[2]:find("\\[^\\]*$"))

-- Load lua utilities
acendan_LuaUtils = reaper.GetResourcePath()..'/Scripts/ACendan Scripts/Development/acendan_Lua Utilities.lua'
if reaper.file_exists( acendan_LuaUtils ) then dofile( acendan_LuaUtils ); if not acendan or acendan.version() < 3.0 then acendan.msg('This script requires a newer version of ACendan Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"ACendan Lua Utilities"); return end else reaper.ShowConsoleMsg("This script requires ACendan Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'ACendan Lua Utilities'"); return end


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
end

-- Main function will run in Reaper's defer loop. EFFICIENCY IS KEY.
function main()
  -- System time in seconds (3600 per hour)
  local now = reaper.time_precise()
  
  -- If the amount of time passed is greater than refresh rate, execute code
  if now - check_time >= refresh_rate then


    local num_tracks =  reaper.CountTracks( 0 )
    if num_tracks > 0 then
      for i = 0, num_tracks-1 do
        local track = reaper.GetTrack(0,i)
        local num_items = reaper.GetTrackNumMediaItems(track)
        local t = {}
        
        if num_items == 1 and scoot_to_start then
          local item = reaper.GetTrackMediaItem(track,0)
          reaper.SetMediaItemInfo_Value(item, 'D_POSITION', 0)
        elseif num_items > 0 then 
          for j = 1, num_items-1 do
            local item = reaper.GetTrackMediaItem(track,j)
            local it_len = reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')
            t[#t+1] = {item,it_len}
          end
          
          local item = reaper.GetTrackMediaItem(track,0)
          local it_start = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
          local it_len = reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')
          x = it_start + it_len 
          
          for k = 1, #t do
            reaper.SetMediaItemInfo_Value(t[k][1], 'D_POSITION', x)
            x = x+t[k][2]
          end
        end
      end
    end
    
   
    
    -- Reset last used time
    check_time = now
  end

  reaper.defer(main)
end

-- Exit function will run once when the script is terminated
function Exit()
  reaper.UpdateArrange()
  reaper.SetToggleCommandState( section, cmdID, 0 )
  reaper.RefreshToolbar2( section, cmdID )
  return reaper.defer(function() end)
end


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ UTILITIES ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

setup()
reaper.atexit(Exit)
main()

