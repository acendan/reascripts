-- @description Split Channels
-- @author Aaron Cendan
-- @version 1.3
-- @metapackage
-- @provides
--   [main] . > acendan_Split selected items by channel to new tracks without render.lua
-- @link https://aaroncendan.me
-- @changelog
--   # Update LuaUtils path with case sensitivity for Linux

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Set 'use_channel_order' to true in order to move assorted items with various channel counts to tracks labeled by channel
-- Channel order is based on the selected item with the highest number of channels
-- Feel free to modify the channel_order table below or add new channel_order[x] rows based on higher channel counts
local use_channel_order = false
local channel_order = {}
channel_order[1] = { "C" }                                                    -- Mono
channel_order[2] = { "L", "R" }                                               -- Stereo
channel_order[3] = { "L", "C", "R" }                                          -- LCR
channel_order[4] = { "L", "R", "Ls", "Rs" }                                   -- Quad
channel_order[5] = { "L", "C", "R", "Ls", "Rs" }                              -- 5.0
channel_order[6] = { "L", "C", "R", "Ls", "Rs", "LFE" }                       -- 5.1
channel_order[7] = { "L", "C", "R", "Lss", "Rss", "Lsr", "Rsr" }              -- 7.0
channel_order[8] = { "L", "C", "R", "Lss", "Rss", "Lsr", "Rsr", "LFE" }       -- 7.1


local ini_sel_items = {}
local new_items = {}
local new_items_channels = {}
local new_tracks = {}

-- Load lua utilities
acendan_LuaUtils = reaper.GetResourcePath()..'/Scripts/ACendan Scripts/Development/acendan_Lua Utilities.lua'
if reaper.file_exists( acendan_LuaUtils ) then dofile( acendan_LuaUtils ); if not acendan or acendan.version() < 5.7 then acendan.msg('This script requires a newer version of ACendan Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"ACendan Lua Utilities"); return end else reaper.ShowConsoleMsg("This script requires ACendan Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'ACendan Lua Utilities'"); return end
dbg = false

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function splitByChannel()
  local num_sel_items = reaper.CountSelectedMediaItems(0)
  if num_sel_items > 0 then
    acendan.saveSelectedItems(ini_sel_items)
    
    local max_item_channels = 0
    for k=0, num_sel_items - 1 do
      local item = reaper.GetSelectedMediaItem( 0, k )
      local take = reaper.GetActiveTake( item )
      local ret_name, take_name = reaper.GetSetMediaItemTakeInfo_String( take, "P_NAME", "", false )
      local track = reaper.GetMediaItemTrack( item )
      local track_idx = reaper.GetMediaTrackInfo_Value( track, "IP_TRACKNUMBER")
      local is_max_channels = false
      if take ~= nil then 
        local src = reaper.GetMediaItemTake_Source(take)
        local src_parent = reaper.GetMediaSourceParent(src)
        
        -- Get source num channels
        if src_parent ~= nil then
          src_chans = reaper.GetMediaSourceNumChannels( src_parent )
        else
          src_chans = reaper.GetMediaSourceNumChannels( src )
        end
        
        -- Check max num channels
        if src_chans > max_item_channels then
          max_item_channels = src_chans
          is_max_channels = true
        end
          
        -- Split by channel
        if dbg then acendan.dbg(take_name) end
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
          
          -- Get the channel for the newly created item
          local new_item_chan = channel_order[src_chans][i+1]
          new_items_channels[#new_items_channels+1]=new_item_chan
          if dbg then acendan.dbg(new_item_chan) end
          
          -- Name tracks based on channel order or by channel number
          if is_max_channels and use_channel_order then reaper.GetSetMediaTrackInfo_String( new_track, "P_NAME", new_item_chan, true ) 
          elseif not use_channel_order then reaper.GetSetMediaTrackInfo_String( new_track, "P_NAME", "Channel #" .. tostring(i+1), true ) end
        end
        if dbg then acendan.dbg("\n") end
        
        -- Mute original item
        reaper.SetMediaItemInfo_Value(item, "B_MUTE", 1)
        
        -- Reselect all original items
        acendan.restoreSelectedItems(ini_sel_items)
      end
    end
    
    -- Move items to correct channel
    if use_channel_order then
      for k=1, #new_items do
        local item = new_items[k]
        local channel = new_items_channels[k]
        local track = reaper.GetMediaItem_Track(item)
        local _, track_name = reaper.GetSetMediaTrackInfo_String( track, "P_NAME", "", false)
        
        if channel ~= track_name then
          local new_track_index = acendan.tableContainsVal(channel_order[max_item_channels], channel)
          local target_track = new_tracks[new_track_index]
          if target_track then
            reaper.MoveMediaItemToTrack(item, new_tracks[new_track_index])
            if dbg then acendan.dbg("k: " .. k .. " - New Track Index: " .. new_track_index .. " - Moved? " .. tostring(moved)) end
          end
        end
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

