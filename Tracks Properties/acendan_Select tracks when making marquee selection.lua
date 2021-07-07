-- @description Select Tracks w Marquee Selection
-- @author Aaron Cendan
-- @version 2.0
-- @metapackage
-- @provides
--   [main] . > acendan_Select tracks when making marquee selection.lua
-- @link https://aaroncendan.me
-- @about
--   # This is a background/toggle script!
--   By Aaron Cendan - Oct 2020
--
--   ### Notes
--   * If this script isn't working for you, then it might be because you have marquee bound to something other than right click.
--   * Check out this YouTube video for a tutorial on how to change it! 
--   https://youtu.be/0UlyAehHyN4
-- @changelog
--   # Major update to script efficiency thanks to a suggestion from Anthony Turi
--   # This script will no longer actively highlight your selected tracks during marquee selection, only at the end. Tradeoff for efficiency.
--   # If you tweaked modifiers for this script, you may have to reset them again. YouTube tutorial link in About section of script header.

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Get action context info (needed for toolbar button toggling)
local _, _, section, cmdID = reaper.get_action_context()

-- Get this script's name and directory
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local script_directory = ({reaper.get_action_context()})[2]:sub(1,({reaper.get_action_context()})[2]:find("\\[^\\]*$"))

-- Mouse states and modifiers table
local mouse_states = {}
mouse_states.left_click = 1
mouse_states.right_click = 2
mouse_states.middle_click = 64
mouse_states.ctrl = 4
mouse_states.shift = 8
mouse_states.alt = 16
mouse_states.win_key = 32

-- Set how long to hold down assigned button before action registers (in seconds)
local hold_time = 0.05

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~ USER CONFIG - EDIT ME! ~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- By default, this script assumes you have marquee selection bound to right click and drag
-- Change this setting by referencing the table above! 
-- For example, if you use Alt + Shift + Middle Click as your marquee selection, then replace the variable line below with:
-- > local marquee_preference = mouse_states.alt + mouse_states.shift + mouse_states.middle_click
local marquee_preference = mouse_states.right_click

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Setup runs once on script startup
function setup()
  
  -- Toggle command state on
  reaper.SetToggleCommandState( section, cmdID, 1 )
  reaper.RefreshToolbar2( section, cmdID )
  
  -- Init
  first_loop = true
  prep_action = false
  
  -- Init timer for hold to ignore casual/quick right clicking
  hold_start = 0
  hold_timer = 0
end

-- Main function will run in Reaper's defer loop. EFFICIENCY IS KEY.
function main()

  -- Confirm project has tracks
  if reaper.CountTracks( 0 ) > 0 then 
    -- Get cursor info
    context = reaper.GetCursorContext()
    window, segment, details = reaper.BR_GetMouseCursorContext()
    mouse = reaper.JS_Mouse_GetState( marquee_preference )
    
    -- If right clicking with mouse over the arrange over a valid track...
    if mouse == marquee_preference and window == "arrange" and segment == "track" then
    
      -- Get start time
      if first_loop then
        hold_start = reaper.time_precise()
        first_loop = false
      end
      
      -- Set timer
      hold_timer = reaper.time_precise() - hold_start
      
      -- Prep action to run on mouse release
      prep_action = true
    
    elseif mouse == marquee_preference and prep_action then
      -- Set timer
      hold_timer = reaper.time_precise() - hold_start
    
    elseif mouse ~= marquee_preference then
      -- No longer right clicking in arrange over track
      if prep_action then 
        if hold_timer > hold_time then
          
          -- Track: Unselect all tracks
          reaper.Main_OnCommand(40297,0)
          
          -- SWS: Select only track(s) with selected item(s)
          reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_SELTRKWITEM"),0)
          
          --[[ MANUAL METHOD
          local num_sel_items = reaper.CountSelectedMediaItems(0)
          if num_sel_items > 0 then
            for i=0, num_sel_items - 1 do
              reaper.SetTrackSelected(reaper.GetMediaItem_Track(reaper.GetSelectedMediaItem( 0, i )),true)
            end
          end
          ]]--
        end
      end
      
      first_loop = true
      prep_action = false
    end
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

setup()
reaper.atexit(Exit)
main()
