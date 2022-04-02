-- @description Split Channels
-- @author Aaron Cendan
-- @version 1.1
-- @metapackage
-- @provides
--   [main] . > acendan_Split selected items by channel to new tracks without render.lua
-- @link https://aaroncendan.me
-- @changelog
--  # Added support for multiple selected items on track

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

local ini_sel_items = {}
local new_items = {}
local new_tracks = {}

-- Load lua utilities
acendan_LuaUtils = reaper.GetResourcePath()..'/scripts/ACendan Scripts/Development/acendan_Lua Utilities.lua'
if reaper.file_exists( acendan_LuaUtils ) then dofile( acendan_LuaUtils ); if not acendan or acendan.version() < 5.7 then acendan.msg('This script requires a newer version of ACendan Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"ACendan Lua Utilities"); return end else reaper.ShowConsoleMsg("This script requires ACendan Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'ACendan Lua Utilities'"); return end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function splitByChannel()
  local num_sel_items = reaper.CountSelectedMediaItems(0)
  if num_sel_items > 0 then
    acendan.saveSelectedItems(ini_sel_items)
    
    for k=0, num_sel_items - 1 do
      local item = reaper.GetSelectedMediaItem( 0, k )
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
          
          -- Name track
          reaper.GetSetMediaTrackInfo_String( new_track, "P_NAME", "Channel #" .. tostring(i+1), true )
        end
        
        -- Mute original item
        reaper.SetMediaItemInfo_Value(item, "B_MUTE", 1)
        
        -- Reselect all original items
        acendan.restoreSelectedItems(ini_sel_items)
      end
    end
    
    -- Set all items and tracks selected
    for _, tbl_itm in pairs(new_items) do ini_sel_items[#ini_sel_items+1] = tbl_itm end
    acendan.restoreSelectedItems(ini_sel_items)
    acendan.restoreSelectedTracks(new_tracks)
  else
    reaper.MB("No items selected!","Channel Split", 0)
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

splitByChannel()

reaper.Undo_EndBlock("Split Items",-1)

reaper.PreventUIRefresh(-1)

reaper.UpdateArrange()

