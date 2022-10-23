-- @description Create one region for all items on selected tracks
-- @author Aaron Cendan
-- @version 1.1
-- @metapackage
-- @provides
--   [main] . > acendan_Create one region for all items on selected tracks.lua
-- @link https://aaroncendan.me
-- @changelog
--   * Default to REAPER internal rgn indexing

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Get script name for undo text and extracting numbers/other info, if needed
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")

-- Optional: Add extra space at end of regions (in seconds)
local additional_space = 1

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function addToRRM()

  reaper.Undo_BeginBlock()
  
  -- Loop through selected tracks
  local num_sel_tracks = reaper.CountSelectedTracks( 0 )
  if num_sel_tracks > 0 then
    for i = 0, num_sel_tracks-1 do
      local track = reaper.GetSelectedTrack(0,i)
      local track_items_count = reaper.CountTrackMediaItems( track )
      local track_items_start = math.huge
      local track_items_end = 0
      
      for j = 0, track_items_count - 1 do
        local item = reaper.GetTrackMediaItem( track, j)
        local item_start = reaper.GetMediaItemInfo_Value( item, "D_POSITION")
        local item_len = reaper.GetMediaItemInfo_Value( item, "D_LENGTH")
        local item_end = item_start + item_len
        if item_start < track_items_start then track_items_start = item_start end
        if item_end > track_items_end then track_items_end = item_end end
      end
      
      local track_color =  reaper.GetTrackColor( track )
      
      retval, track_name = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)

      if track_items_start < math.huge then
        if retval then
          regionID = reaper.AddProjectMarker2(0, true, track_items_start, track_items_end + additional_space, track_name, -1, track_color)
          reaper.SetRegionRenderMatrix(0, regionID, track, 1)
        else
          regionID = reaper.AddProjectMarker2(0, true, track_items_start, track_items_end + additional_space, "", -1, track_color)
          reaper.SetRegionRenderMatrix(0, regionID, track, 1)
        end
      end

    end
  else
    msg("No tracks selected!")
  end
  
  reaper.Undo_EndBlock(script_name, -1)
  
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

addToRRM()

reaper.PreventUIRefresh(-1)

reaper.UpdateArrange()
