-- @description Split Channels
-- @author Aaron Cendan
-- @version 1.0
-- @metapackage
-- @provides
--   [main] . > acendan_Split selected item by channel to new tracks without render.lua
-- @link https://aaroncendan.me

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

local new_items = {}
local new_tracks = {}


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function splitByChannel()
  local num_sel_items = reaper.CountSelectedMediaItems(0)
  if num_sel_items > 0 then
    local item = reaper.GetSelectedMediaItem( 0, 0 )
    local take = reaper.GetActiveTake( item )
    local ret_name, take_name = reaper.GetSetMediaItemTakeInfo_String( take, "P_NAME", "", false )
    local track = reaper.GetMediaItemTrack( item )
    local track_idx = reaper.GetMediaTrackInfo_Value( track, "IP_TRACKNUMBER")
    if take ~= nil then 
      local src = reaper.GetMediaItemTake_Source(take)
      local src_parent = reaper.GetMediaSourceParent(src)
      
      if src_parent ~= nil then
        src_chans = reaper.GetMediaSourceNumChannels( src_parent )
      else
        src_chans = reaper.GetMediaSourceNumChannels( src )
      end
        
      -- Split by channel
      for i = 0, src_chans - 1 do
        -- Insert new track
        reaper.InsertTrackAtIndex( track_idx + i, true )
        local new_track = reaper.GetTrack( 0, track_idx + i )
        new_tracks[#new_tracks+1]=new_track
        
        -- Copy/Paste item
        reaper.SetOnlyTrackSelected(track)
        reaper.Main_OnCommand(40289, 0) -- Unselect all media items
        reaper.SetMediaItemSelected(item, 1)
        reaper.Main_OnCommand(41173, 0) -- Move cursor at item start
        reaper.Main_OnCommand(40698, 0) -- Copy the item
        reaper.SetOnlyTrackSelected(new_track)
        reaper.Main_OnCommand(40914, 0) -- Set selected track as last touched
        reaper.Main_OnCommand(40058, 0) -- Paste item

        -- Set item channel
        local new_item = reaper.GetTrackMediaItem( new_track, 0 )
        new_items[#new_items+1]=new_item
        reaper.SetMediaItemTakeInfo_Value( reaper.GetActiveTake( new_item ) , "I_CHANMODE", 3 + i)
        
        -- Name track
        if ret_name then
          reaper.GetSetMediaTrackInfo_String( new_track, "P_NAME", take_name, true )
        else
          reaper.GetSetMediaTrackInfo_String( new_track, "P_NAME", "", true )
        end
      end
      
      -- Mute original item
      reaper.Main_OnCommand(40289, 0) -- Unselect all media items
      reaper.SetMediaItemSelected(item, 1)
      reaper.Main_OnCommand(40719, 0) -- Mute selected item
      
      -- Set new items selected
      restoreSelectedItems(new_items)
      restoreSelectedTracks(new_tracks)
    end
  else
    reaper.MB("No items selected!","Channel Split", 0)
  end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ UTILITIES ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Count number of occurrences of a substring in a string // returns Number
function countOccurrences(base, pattern)
    return select(2, string.gsub(base, pattern, ""))
end

-- Check if an input string ends with another string // returns Boolean
function stringEnds(str, ending)
   return ending == "" or str:sub(-#ending) == ending
end

-- Restore selected items
function restoreSelectedItems(table)
  reaper.Main_OnCommand(40289, 0) -- Unselect all media items
  for i = 1, tableLength(table) do
    reaper.SetMediaItemSelected( table[i], true )
  end
end

-- Restore selected tracks from table. Requires tableLength() above
function restoreSelectedTracks(table)
  reaper.Main_OnCommand(40297, 0) -- Unselect all tracks
  for i = 1, tableLength(table) do
    reaper.SetTrackSelected( table[i], true )
  end
end

-- Get length/number of entries in a table // returns Number
-- This is relatively unnecessary, as table length can just be acquired with #table
function tableLength(table)
  local i = 0
  for _ in pairs(table) do i = i + 1 end
  return i
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock()

splitByChannel()

reaper.Undo_EndBlock("Split Items",-1)

reaper.PreventUIRefresh(-1)

reaper.UpdateArrange()

