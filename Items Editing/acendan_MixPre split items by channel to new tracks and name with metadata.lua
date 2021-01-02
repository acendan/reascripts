-- @description Sound Devices MixPre Metadata Tools - Split Channels
-- @author Aaron Cendan
-- @version 1.1
-- @metapackage
-- @provides
--   [main] . > acendan_MixPre split selected item by channel to new tracks and name with metadata.lua
-- @link https://aaroncendan.me
-- @about
--   Splits items onto new tracks, renames with BWF sub-field after hyphen (-) in script name to track name.
-- @changelog
--   Selects new items/tracks on completion

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

local bwf_field = "sTRK"
local new_items = {}
local new_tracks = {}


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function appendMetadata()
  local num_sel_items = reaper.CountSelectedMediaItems(0)
  if num_sel_items > 0 then
    local item = reaper.GetSelectedMediaItem( 0, 0 )
    local take = reaper.GetActiveTake( item )
    local track = reaper.GetMediaItemTrack( item )
    local track_idx = reaper.GetMediaTrackInfo_Value( track, "IP_TRACKNUMBER")
    if take ~= nil then 
      local src = reaper.GetMediaItemTake_Source(take)
      local src_parent = reaper.GetMediaSourceParent(src)
      
      if src_parent ~= nil then
        ret, full_desc = reaper.CF_GetMediaSourceMetadata( src_parent, "DESC", "" )
        src_chans = reaper.GetMediaSourceNumChannels( src_parent )
      else
        ret, full_desc = reaper.CF_GetMediaSourceMetadata( src, "DESC", "" )
        src_chans = reaper.GetMediaSourceNumChannels( src )
      end
      
     
      if ret then
        -- Sort out track info. 
        local num_occ = countOccurrences(full_desc,bwf_field)
        
        if not (tonumber(num_occ) == tonumber(src_chans)) then
          local response = reaper.MB("Number of named tracks in metadata does not equal number of track channels! Double check your MixPre settings. Names might be wrong, but channels will still split.\n\nWould you like to proceed?", "MixPre Split", 4)
          if response == 7 then return end
        end
        
        local names = {}
        
        for w in string.gmatch(full_desc, bwf_field .. "..") do
          if not stringEnds(w,"=") then w = w .. "=" end
          names[#names+1] = w
        end
        
        
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

          -- Rename new track
          local start_of_field = string.find( full_desc, names[i+1] ) + string.len( names[i+1] )
          local field_to_end = string.sub( full_desc, start_of_field, string.len( full_desc ))
          local end_of_field = start_of_field + string.find( field_to_end , "\r\n")
          local bwf_field_contents = string.sub( full_desc, start_of_field, end_of_field)
          
          local ret2, new_name = reaper.GetSetMediaTrackInfo_String( new_track, "P_NAME", bwf_field_contents, true )
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
    reaper.MB("No items selected!","MixPre Split", 0)
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

appendMetadata()

reaper.Undo_EndBlock("MixPre Split Items",-1)

reaper.PreventUIRefresh(-1)

reaper.UpdateArrange()

