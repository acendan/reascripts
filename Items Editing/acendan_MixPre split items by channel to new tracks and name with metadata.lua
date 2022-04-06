-- @description Sound Devices MixPre Metadata Tools - Split Channels
-- @author Aaron Cendan
-- @version 1.3
-- @metapackage
-- @provides
--   [main] . > acendan_MixPre split selected item by channel to new tracks and name with metadata.lua
-- @link https://aaroncendan.me
-- @about
--   Splits items onto new tracks, renames with BWF sub-field after hyphen (-) in script name to track name.
-- @changelog
--   # Minor optimization

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

local bwf_field = "sTRK"


local ini_sel_items = {}
local new_items = {}
local new_tracks = {}

-- Load lua utilities
acendan_LuaUtils = reaper.GetResourcePath()..'/scripts/ACendan Scripts/Development/acendan_Lua Utilities.lua'
if reaper.file_exists( acendan_LuaUtils ) then dofile( acendan_LuaUtils ); if not acendan or acendan.version() < 5.7 then acendan.msg('This script requires a newer version of ACendan Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"ACendan Lua Utilities"); return end else reaper.ShowConsoleMsg("This script requires ACendan Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'ACendan Lua Utilities'"); return end
dbg = false

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function appendMetadata()
  local num_sel_items = reaper.CountSelectedMediaItems(0)
  if num_sel_items > 0 then
    
    acendan.saveSelectedItems(ini_sel_items)
    local max_item_channels = 0
    
    for k=0, num_sel_items - 1 do
      local item = reaper.GetSelectedMediaItem( 0, k )
      local take = reaper.GetActiveTake( item )
      local track = reaper.GetMediaItemTrack( item )
      local track_idx = reaper.GetMediaTrackInfo_Value( track, "IP_TRACKNUMBER")
      local is_max_channels = false
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
          local num_occ = acendan.countOccurrences(full_desc,bwf_field)
          
          if not (tonumber(num_occ) == tonumber(src_chans)) then
            local response = reaper.MB("Number of named tracks in metadata does not equal number of track channels! Double check your MixPre settings. Names might be wrong, but channels will still split.\n\nWould you like to proceed?", "MixPre Split", 4)
            if response == 7 then return end
          end
          
          local names = {}
          
          for w in string.gmatch(full_desc, bwf_field .. "..") do
            if not acendan.stringEnds(w,"=") then w = w .. "=" end
            names[#names+1] = w
          end
          
          -- Check max num channels
          if src_chans > max_item_channels then
            max_item_channels = src_chans
            is_max_channels = true
          end
                    
          for i = 0, src_chans - 1 do
            -- Insert new track for each channel if first item 
            -- OR if current item has more channels than number of new tracks already created
            if k == 0 or i > #new_tracks - 1 then
              reaper.InsertTrackAtIndex( track_idx + i, true )
              new_track = reaper.GetTrack( 0, track_idx + i )
              new_tracks[#new_tracks+1]=new_track
            else
              new_track = new_tracks[i+1]
            end
            
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
            local new_item = reaper.GetSelectedMediaItem(0,0)
            new_items[#new_items+1]=new_item
            reaper.SetMediaItemTakeInfo_Value( reaper.GetActiveTake( new_item ) , "I_CHANMODE", 3 + i)
  
            -- Rename new track
            if is_max_channels then
              local start_of_field = string.find( full_desc, names[i+1] ) + string.len( names[i+1] )
              local field_to_end = string.sub( full_desc, start_of_field, string.len( full_desc ))
              local end_of_field = start_of_field + string.find( field_to_end , "\r\n")
              local bwf_field_contents = string.sub( full_desc, start_of_field, end_of_field)
              
              local ret2, new_name = reaper.GetSetMediaTrackInfo_String( new_track, "P_NAME", bwf_field_contents, true )
            end
          end
        end
        
        -- Mute original item
        reaper.SetMediaItemInfo_Value(item, "B_MUTE", 1)
        
        acendan.restoreSelectedItems(ini_sel_items)
      end
    end
    
    -- Set all items and tracks selected
    for _, tbl_itm in pairs(new_items) do ini_sel_items[#ini_sel_items+1] = tbl_itm end
    acendan.restoreSelectedItems(new_items)
    acendan.restoreSelectedTracks(new_tracks)
  else
    reaper.MB("No items selected!","MixPre Split", 0)
  end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ UTILITIES ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock()

appendMetadata()

reaper.Undo_EndBlock("MixPre Split Items",-1)

reaper.PreventUIRefresh(-1)

reaper.UpdateArrange()

