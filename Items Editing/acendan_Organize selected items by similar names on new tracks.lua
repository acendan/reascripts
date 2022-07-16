-- @description Organize Items by Similar Names
-- @author Aaron Cendan
-- @version 1.2
-- @metapackage
-- @provides
--   [main] .
-- @link https://aaroncendan.me
-- @about
--  * Places items with similar names on new tracks
-- @changelog
--   # Update LuaUtils path with case sensitivity for Linux

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

local ini_sel_items = {}
local new_items = {}
local new_tracks = {}
local new_tracks_names = {}

-- Load lua utilities
acendan_LuaUtils = reaper.GetResourcePath()..'/Scripts/ACendan Scripts/Development/acendan_Lua Utilities.lua'
if reaper.file_exists( acendan_LuaUtils ) then dofile( acendan_LuaUtils ); if not acendan or acendan.version() < 6.1 then acendan.msg('This script requires a newer version of ACendan Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"ACendan Lua Utilities"); return end else reaper.ShowConsoleMsg("This script requires ACendan Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'ACendan Lua Utilities'"); return end
dbg = false

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function main()
  local num_sel_items = reaper.CountSelectedMediaItems(0)
  if num_sel_items > 0 then
    --acendan.saveSelectedItems(ini_sel_items)
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
      take_name = acendan.removeEnumeration(take_name)
      if dbg then acendan.dbg(k) end
      local track = reaper.GetMediaItemTrack( item )
      local track_idx = reaper.GetMediaTrackInfo_Value( track, "IP_TRACKNUMBER")

      -- Get new track by name
      if dbg then acendan.dbg(take_name) end
      local tbl_idx = acendan.tableContainsVal(new_tracks_names, take_name)
      if tbl_idx then
        -- Move item to already-created track
        new_track = new_tracks[tbl_idx]
        reaper.MoveMediaItemToTrack(item, new_tracks[tbl_idx])
      
      else
        -- Create new track and move item
        reaper.InsertTrackAtIndex( last_selected_track_idx + num_new_tracks, true )
        new_track = reaper.GetTrack( 0, last_selected_track_idx + num_new_tracks )
        reaper.GetSetMediaTrackInfo_String( new_track, "P_NAME", tostring(take_name), true ) 

        reaper.MoveMediaItemToTrack(item, new_track)
        
        new_tracks[num_new_tracks+1] = new_track
        new_tracks_names[num_new_tracks+1] = take_name
        num_new_tracks = num_new_tracks + 1
      end
    end
  
    acendan.restoreSelectedTracks(new_tracks)
    
    -- Fallthrough just in case
    reaper.Main_OnCommand(mpl_move,0) -- Script: mpl_Move selected items to tracks with same name as items.lua

  else
    reaper.MB("No items selected!","Organize Items by Name", 0)
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

mpl_move = reaper.NamedCommandLookup("_RSae522affae0c8487d338e4c637b6d29a80f95201")
if mpl_move then
  main()
else
  acendan.msg("This script requires the script:\n\nScript: mpl_Move selected items to tracks with same name as items.lua\n\nPlease install it via ReaPack: Extensions > ReaPack > Browse Packages","Missing MPL Script")  
end
    
reaper.Undo_EndBlock("Organize Items By Name",-1)

reaper.PreventUIRefresh(-1)

reaper.UpdateArrange()


