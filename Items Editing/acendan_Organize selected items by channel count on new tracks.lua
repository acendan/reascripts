-- @description Organize Items by Channel
-- @author Aaron Cendan
-- @version 1.1
-- @metapackage
-- @provides
--   [main] .
-- @link https://aaroncendan.me
-- @about
--  * Places items with assorted channel counts on new tracks, organized by num of channels per item
-- @changelog
--   # Update LuaUtils path with case sensitivity for Linux

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

local ini_sel_items = {}
local new_items = {}
local new_tracks = {}

-- Load lua utilities
acendan_LuaUtils = reaper.GetResourcePath()..'/Scripts/ACendan Scripts/Development/acendan_Lua Utilities.lua'
if reaper.file_exists( acendan_LuaUtils ) then dofile( acendan_LuaUtils ); if not acendan or acendan.version() < 5.8 then acendan.msg('This script requires a newer version of ACendan Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"ACendan Lua Utilities"); return end else reaper.ShowConsoleMsg("This script requires ACendan Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'ACendan Lua Utilities'"); return end
dbg = false

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function splitByChannel()
  local num_sel_items = reaper.CountSelectedMediaItems(0)
  if num_sel_items > 0 then
    acendan.saveSelectedItems(ini_sel_items)
    acendan.selectTracksOfSelectedItems()
    
    -- Get last track index
    local last_selected_track_idx = 0
    local num_sel_tracks = reaper.CountSelectedTracks( 0 )
    if num_sel_tracks > 0 then
      for i = 0, num_sel_tracks-1 do
        local track = reaper.GetSelectedTrack(0,i)
        local track_idx = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")
        if track_idx > last_selected_track_idx then last_selected_track_idx = track_idx end
      end
    end

    -- Loop through selected items
    local num_new_tracks = 0
    for k=0, num_sel_items - 1 do
      local item = reaper.GetSelectedMediaItem( 0, k )
      local take = reaper.GetActiveTake( item )
      local ret_name, take_name = reaper.GetSetMediaItemTakeInfo_String( take, "P_NAME", "", false )
      local track = reaper.GetMediaItemTrack( item )
      local track_idx = reaper.GetMediaTrackInfo_Value( track, "IP_TRACKNUMBER")
      if take ~= nil then 
        local src = reaper.GetMediaItemTake_Source(take)
        local src_parent = reaper.GetMediaSourceParent(src)
        
        -- Get source num channels
        if src_parent ~= nil then
          src_chans = reaper.GetMediaSourceNumChannels( src_parent )
        else
          src_chans = reaper.GetMediaSourceNumChannels( src )
        end
          
        -- Organize by channel
        if dbg then acendan.dbg(take_name) end
        if new_tracks[src_chans] then
          -- Move item to already-created track
          new_track = new_tracks[src_chans]
          if dbg then acendan.dbg("Already created track with " .. tostring(src_chans) .. " channels!") end
        else
          -- Create new track and move item
          reaper.InsertTrackAtIndex( last_selected_track_idx + num_new_tracks, true )
          new_track = reaper.GetTrack( 0, last_selected_track_idx + num_new_tracks )
          new_tracks[src_chans] = new_track
          num_new_tracks = num_new_tracks + 1
          if dbg then acendan.dbg("Created new track with " .. tostring(src_chans) .. " channels!") end
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

        -- Get new item
        local new_item = reaper.GetSelectedMediaItem(0,0)
        new_items[#new_items+1]=new_item
        
        -- Name tracks based on channel order or by channel number
        reaper.GetSetMediaTrackInfo_String( new_track, "P_NAME", "# Channels: " .. tostring(src_chans), true ) 

        if dbg then acendan.dbg("\n") end
        
        -- Mute original item
        reaper.SetMediaItemInfo_Value(item, "B_MUTE", 1)
        
        -- Reselect all original items
        acendan.restoreSelectedItems(ini_sel_items)
      end
    end
    
    -- Set all items and tracks selected
    for _, tbl_itm in pairs(new_items) do ini_sel_items[#ini_sel_items+1] = tbl_itm end
    acendan.restoreSelectedItems(ini_sel_items)
    
    
    -- Reorder selected tracks by number of channels
    local num_moved_tracks = 1
    for _, new_track in ipairs(new_tracks) do
      reaper.SetOnlyTrackSelected(new_track)
      reaper.ReorderSelectedTracks( last_selected_track_idx + num_moved_tracks, 0 )
      num_moved_tracks = num_moved_tracks + 1
    end
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

