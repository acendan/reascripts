-- @description Horizontal Reorder Color
-- @author Aaron Cendan
-- @version 1.2
-- @metapackage
-- @provides
--   [main] .
-- @link https://ko-fi.com/acendan_
-- @about
--   # Horizontal Reorder Items By Color
-- @changelog
--   # Fix reordering of items on separate tracks

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~ USER CONFIG - EDIT ME ~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Automatically add spacing between consecutive items, in seconds
item_spacing = 0.0

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Get this script's name and directory
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local script_directory = ({reaper.get_action_context()})[2]:sub(1,({reaper.get_action_context()})[2]:find("\\[^\\]*$"))

-- Load lua utilities
acendan_LuaUtils = reaper.GetResourcePath()..'/scripts/ACendan Scripts/Development/acendan_Lua Utilities.lua'
if reaper.file_exists( acendan_LuaUtils ) then dofile( acendan_LuaUtils ); if not acendan or acendan.version() < 5.4 then acendan.msg('This script requires a newer version of ACendan Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"ACendan Lua Utilities"); return end else reaper.ShowConsoleMsg("This script requires ACendan Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'ACendan Lua Utilities'"); return end


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function main()
  local items_tbl = {}
  local items_col_tbl = {}
  local items_trk_tbl = {}
  local used_cols_tbl = {}

  -- Loop through selected items
  local num_sel_items = reaper.CountSelectedMediaItems(0)
  if num_sel_items > 0 then
    -- Select only tracks with selected items
    acendan.selectTracksOfSelectedItems()
    
    -- Populate items, tracks, and items color tables
    for i=1, num_sel_items do
      local item = reaper.GetSelectedMediaItem( 0, i-1 )
      items_tbl[i] = item
      items_trk_tbl[i] = reaper.GetMediaTrackInfo_Value(reaper.GetMediaItem_Track(item), "IP_TRACKNUMBER")
      items_col_tbl[i] = reaper.GetDisplayedMediaItemColor(item)
    end

    -- Loop through tracks w selected items
    local num_sel_tracks = reaper.CountSelectedTracks( 0 )
    if num_sel_tracks > 0 then
      for t = 0, num_sel_tracks-1 do
        local track = reaper.GetSelectedTrack(0,t)
        local track_num = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")
        
        -- Iterate through items on track to set starting pos
        local new_col_start_pos = math.huge
        for i=1, #items_tbl do
          if (items_trk_tbl[i] == track_num) then
            local item_start_pos = reaper.GetMediaItemInfo_Value( items_tbl[i], "D_POSITION" )
            if item_start_pos < new_col_start_pos then new_col_start_pos = item_start_pos end
          end
        end
        
        -- Iterate through items on current track
        for i=1, #items_tbl do
          if (items_trk_tbl[i] == track_num) then
            
            -- New item color!
            if not acendan.tableContainsVal(used_cols_tbl, items_col_tbl[i]) then
              used_cols_tbl[#used_cols_tbl+1] = items_col_tbl[i]
            
              -- Move to new color start position
              reaper.SetMediaItemInfo_Value(items_tbl[i], "D_POSITION", new_col_start_pos)
              new_col_start_pos = new_col_start_pos + reaper.GetMediaItemInfo_Value(items_tbl[i], "D_LENGTH") + item_spacing
            
              -- Iterate through remaining items to move those with same color on same track
              for j=1, #items_tbl do
                if not (i == j) then
                  if (items_col_tbl[i] == items_col_tbl[j]) and (items_trk_tbl[i] == items_trk_tbl[j]) then
                    reaper.SetMediaItemInfo_Value(items_tbl[j], "D_POSITION", new_col_start_pos)
                    new_col_start_pos = new_col_start_pos + reaper.GetMediaItemInfo_Value(items_tbl[j], "D_LENGTH") + item_spacing
                  end
                end
              end
            end
          end
        end
        
        -- Reset used cols for next track
        acendan.clearTable(used_cols_tbl)
      end
    else
      acendan.msg("No tracks selected!")
    end
  else
    acendan.msg("No items selected!")
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

main()

reaper.Undo_EndBlock(script_name,-1)

reaper.PreventUIRefresh(-1)

reaper.UpdateArrange()

