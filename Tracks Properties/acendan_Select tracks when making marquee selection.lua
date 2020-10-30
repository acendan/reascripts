-- @description Select Tracks w Marquee Selection
-- @author Aaron Cendan
-- @version 1.0
-- @metapackage
-- @provides
--   [main] . > acendan_Select tracks when making marquee selection.lua
-- @link https://aaroncendan.me
-- @about
--   # This is a background/toggle script!
--   By Aaron Cendan - Oct 2020
--
--   ### Notes
--   * When prompted if you want to terminate instances, click the little checkbox then terminate.

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

    -- Get cursor info
    context = reaper.GetCursorContext()
    window, segment, details = reaper.BR_GetMouseCursorContext()
    track = -1
    if reaper.BR_GetMouseCursorContext_Track() then
      track =  reaper.GetMediaTrackInfo_Value( reaper.BR_GetMouseCursorContext_Track(), "IP_TRACKNUMBER" ) - 1
    end
    mouse = reaper.JS_Mouse_GetState( 2 )
    
    -- If right clicking with mouse over the arrange over a valid track...
    if mouse == 2 and window == "arrange" and segment == "track" and track >= 0 then
    
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
