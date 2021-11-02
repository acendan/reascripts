-- @description Copy Selected Items to Track
-- @author Aaron Cendan
-- @version 1.1
-- @metapackage
-- @provides
--   [main] . > acendan_Copy selected items to track - prompt for track.lua
-- @link https://aaroncendan.me
-- @about
--   # Lua Utilities
--   By Aaron Cendan - August 2020
--   * Select some items. Select a track. Run the script. Bam.
--   * Adapted from X-Raym's script: Copy selected items and paste at mouse cursor
-- @changelog
--   + Update by X-Raym
--   + last track bug fix
--   + hidden track support   


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Get script name for undo text and extracting numbers/other info, if needed
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function copyPasteSelItems()
  
  local ret_input, user_input = reaper.GetUserInputs( "Copy to Track", 1, "Track Number:", "1" )
  if not ret_input then return end
  
  local track_num = tonumber(user_input)
  local num_tracks_proj = reaper.CountTracks( 0 )
  
  if (type(track_num) == "number") then
    if track_num < num_tracks_proj + 1 then -- +1 is for last track
      if reaper.CountSelectedTracks() > 0 then
        if reaper.CountSelectedMediaItems() > 0 then
          reaper.Main_OnCommand(40297, 0) -- Unselect all tracks (so that it can copy items)
          reaper.Main_OnCommand(40698, 0) -- Copy selected items
          
          -- Place cursor at start of selected items
          local pos = getStartPosSelItems()
          reaper.SetEditCurPos2(0, pos, false, false)
          
          -- Select input track as only selected track
          reaper.SetTrackSelected(  reaper.GetTrack( 0, track_num-1 ), true)
          
          reaper.Main_OnCommand(40914,0) -- Set first selected track as last touched
          reaper.Main_OnCommand(40058,0) -- Paste
        else
          msg("No items selected!")
        end
      else
        msg("No track selected!")
      end
    else
      msg("Track num input must be less than the number of tracks in your project!")
      copyPasteSelItems()
    end
  else
    msg("Track num input must be a number!")
    copyPasteSelItems()
  end
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

-- Get starting position of selected items
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

-- Save initally selected items
init_sel_items = {}
function SaveSelectedItems (table)
  for i = 0, reaper.CountSelectedMediaItems(0)-1 do
    table[i+1] = reaper.GetSelectedMediaItem(0, i)
  end
end

-- Restore initially selected items
function RestoreSelectedItems (table)
  reaper.Main_OnCommand(40289, 0) -- Unselect all items
  for _, item in ipairs(table) do
    reaper.SetMediaItemSelected(item, true)
  end
end

-- Svae initially selected tracks
init_sel_tracks = {}
function SaveSelectedTracks (table)
  for i = 0, reaper.CountSelectedTracks(0)-1 do
    local track = reaper.GetSelectedTrack(0, i)
    table[i+1] = { track = reaper.GetSelectedTrack(0, i), tcp_show = reaper.GetMediaTrackInfo_Value( track, "B_SHOWINTCP") }
  end
end

-- Restore initially selected tracks
function RestoreSelectedTracks (table)
  reaper.Main_OnCommand(40297, 0) -- Unselect all tracks
  for _, track in ipairs(table) do
    reaper.SetTrackSelected(track.track, true)
  end
end

-- Save cursror pos
function SaveCursorPos()
  init_cursor_pos = reaper.GetCursorPosition()
end

-- Restore cursor pos
function RestoreCursorPos()
  reaper.SetEditCurPos(init_cursor_pos, false, false)
end

-- Save view
function SaveView()
  start_time_view, end_time_view = reaper.BR_GetArrangeView(0)
end


-- Restore view
function RestoreView()
  reaper.BR_SetArrangeView(0, start_time_view, end_time_view)
end

function SaveAllTracksAndShow()
  local count_tracks = reaper.CountTracks(0)
  local t = {}
  for i = 0, count_tracks - 1 do
    local track = reaper.GetTrack(0,i)
    t[i+1] = {track = track, tcp_show = reaper.GetMediaTrackInfo_Value( track, "B_SHOWINTCP") }
    reaper.SetMediaTrackInfo_Value( track, "B_SHOWINTCP", 1) 
  end
  return t
end

function RestoreTracksVisibility( t )
  for i, track in ipairs( t ) do
    reaper.SetMediaTrackInfo_Value( track.track, "B_SHOWINTCP", track.tcp_show) 
  end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock()

SaveView()
SaveCursorPos()
SaveSelectedItems(init_sel_items)
SaveSelectedTracks(init_sel_tracks)
all_tracks = SaveAllTracksAndShow()

copyPasteSelItems()

RestoreTracksVisibility( all_tracks )
RestoreCursorPos()
RestoreSelectedItems(init_sel_items)
RestoreSelectedTracks(init_sel_tracks)
RestoreView()

reaper.Undo_EndBlock(script_name,-1)

reaper.PreventUIRefresh(-1)

reaper.UpdateArrange()
