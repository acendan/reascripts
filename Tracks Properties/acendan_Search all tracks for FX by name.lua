-- @description Search Tracks for FX
-- @author Aaron Cendan
-- @version 1.0
-- @metapackage
-- @provides
--   [main] . > acendan_Search all tracks for FX by name.lua
-- @link https://aaroncendan.me
-- @about
--   # Search Tracks for FX
--   By Aaron Cendan - July 2020
--
--   * Prompts user for fx name, then searches all tracks for that fx and returns list

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Get script name for undo text and extracting numbers/other info, if needed
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function main()

  local ret_input, user_input = reaper.GetUserInputs( "Search for FX", 1, "FX Name,extrawidth=100", "ReaComp" )
  if not ret_input then return end
  
  local fx_filter = string.lower(user_input)
  local found_fx = false

  for ti=0,reaper.CountTracks()-1 do
    local track = reaper.GetTrack(0, ti)

    for fi=0,reaper.TrackFX_GetCount(track)-1 do
      local _, fx_name = reaper.TrackFX_GetFXName(track, fi, '')
      if fx_name:lower():find(fx_filter) then
        retval, track_name = reaper.GetSetMediaTrackInfo_String( track, "P_NAME", "", false )
        if retval then dbg("Track #" .. ti + 1 .. ": " .. track_name)
        else dbg("Track #" .. ti + 1) end
        found_fx = true
      end
    end
  end
  
  if not found_fx then msg(string.format("No tracks found with '%s' added!",user_input)) end
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



