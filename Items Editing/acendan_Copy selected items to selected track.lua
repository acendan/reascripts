-- @description Copy Selected Items to Selected Track
-- @author Aaron Cendan
-- @version 0.1
-- @metapackage
-- @provides
--   [main] . > acendan_Copy selected items to selected track.lua
-- @link https://aaroncendan.me
-- @about
--   # Lua Utilities
--   By Aaron Cendan - August 2020
--   * Select some items. Select a track. Run the script. Bam.
--   * Adapted from XRaym's script: Copy selected items and paste at mouse cursor


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Get script name for undo text and extracting numbers/other info, if needed
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function copyPasteSelItems()
    
  reaper.Main_OnCommand(40297, 0) -- Unselect all tracks (so that it can copy items)
  reaper.Main_OnCommand(40698, 0) -- Copy selected items
  
  -- Place cursor at start of selected items
  local pos = getStartPosSelItems()
  reaper.SetEditCurPos2(0, pos, false, false)
  
  RestoreSelectedTracks(init_sel_tracks)
  
  reaper.Main_OnCommand(40914,0) -- Set first selected track as last touched
  reaper.Main_OnCommand(40058,0) -- Paste
  
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
    table[i+1] = reaper.GetSelectedTrack(0, i)
  end
end

-- Restore initially selected tracks
function RestoreSelectedTracks (table)
  reaper.Main_OnCommand(40297, 0) -- Unselect all tracks
  for _, track in ipairs(table) do
    reaper.SetTrackSelected(track, true)
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

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock()

SaveView()
SaveCursorPos()
SaveSelectedItems(init_sel_items)
SaveSelectedTracks(init_sel_tracks)

copyPasteSelItems()

RestoreCursorPos()
RestoreSelectedItems(init_sel_items)
RestoreSelectedTracks(init_sel_tracks)
RestoreView()

reaper.Undo_EndBlock(script_name,-1)

reaper.PreventUIRefresh(-1)

reaper.UpdateArrange()
