-- @description Select Tracks w Marquee Selection
-- @author Aaron Cendan
-- @version 1.5
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


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Refresh rate (in seconds)
local refresh_rate = 0.05

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
  -- Timing control
  local start = reaper.time_precise()
  check_time = start
  
  -- Toggle command state on
  reaper.SetToggleCommandState( section, cmdID, 1 )
  reaper.RefreshToolbar2( section, cmdID )
  
  -- Init
  first_loop = true
  first_track = 0
  prev_track = 0
end

-- Main function will run in Reaper's defer loop. EFFICIENCY IS KEY.
function main()
  -- System time in seconds (3600 per hour)
  local now = reaper.time_precise()
  
  -- If the amount of time passed is greater than refresh rate, execute code
  if now - check_time >= refresh_rate then
    -- Confirm project has tracks
    if reaper.CountTracks( 0 ) > 0 then 
      -- Get cursor info
      context = reaper.GetCursorContext()
      window, segment, details = reaper.BR_GetMouseCursorContext()
      --focus = reaper.JS_Window_GetTitle(  reaper.JS_Window_GetFocus())
      track = -1
      if reaper.BR_GetMouseCursorContext_Track() then
        track =  reaper.GetMediaTrackInfo_Value( reaper.BR_GetMouseCursorContext_Track(), "IP_TRACKNUMBER" ) - 1
      end
      mouse = reaper.JS_Mouse_GetState( marquee_preference )
      
      
      -- If right clicking with mouse over the arrange over a valid track...
      if mouse == marquee_preference and window == "arrange" and segment == "track" and track >= 0 then
      
        --[[ reaper.ShowConsoleMsg("\n\ncontext: " .. context .. 
                              "\nwindow: " .. window .. 
                              "\nsegment: " .. segment .. 
                              "\ndetails: " .. details ..
                              "\ntrack: " .. track ..
                              "\nmouse: " .. mouse) ]]--
        
        -- Set current track as only selected track on first loop                      
        if first_loop then 
          reaper.SetOnlyTrackSelected(  reaper.GetTrack( 0, track ) )
          first_track = track
          first_loop = false 
        else 
          -- Compare to first_track and prev_track
          if track > first_track and track > prev_track then
            for i = first_track, track do
              reaper.SetTrackSelected( reaper.GetTrack( 0, i ), true )
            end
          elseif track > first_track and track < prev_track then
            reaper.SetOnlyTrackSelected(  reaper.GetTrack( 0, first_track ) )
            for i = first_track, track do
              reaper.SetTrackSelected( reaper.GetTrack( 0, i ), true )
            end
          elseif track < first_track and track < prev_track then
            for i = track, first_track do
              reaper.SetTrackSelected( reaper.GetTrack( 0, i ), true )
            end
          elseif track < first_track and track > prev_track then
            reaper.SetOnlyTrackSelected(  reaper.GetTrack( 0, first_track ) )
            for i = track, first_track do
              reaper.SetTrackSelected( reaper.GetTrack( 0, i ), true )
            end
          elseif track == first_track then
            reaper.SetOnlyTrackSelected(  reaper.GetTrack( 0, track ) )
          end
        end
    
        -- Set current track as prev track
        prev_track = track
      
      elseif mouse ~= 2 then
        -- No longer right clicking in arrange over track
        first_loop = true
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

setup()
reaper.atexit(Exit)
main()
