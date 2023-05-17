-- @description Insert marker at start of selected items with number
-- @author Aaron Cendan
-- @version 1.4
-- @metapackage
-- @provides
--   [main] . > acendan_Insert marker at start of selected items with sel item number.lua
-- @link https://aaroncendan.me
-- @changelog
--   # Enumerate w 1-based mkr index

-- Load lua utilities
acendan_LuaUtils = reaper.GetResourcePath()..'/Scripts/ACendan Scripts/Development/acendan_Lua Utilities.lua'
if reaper.file_exists( acendan_LuaUtils ) then dofile( acendan_LuaUtils ); if not acendan or acendan.version() < 6.2 then acendan.msg('This script requires a newer version of ACendan Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"ACendan Lua Utilities"); return end else reaper.ShowConsoleMsg("This script requires ACendan Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'ACendan Lua Utilities'"); return end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function insertMarkers()
  reaper.Undo_BeginBlock()
  local mkr_pos_tbl = {}
  local num_sel_items = reaper.CountSelectedMediaItems(0)
  if num_sel_items > 0 then
    for i=1, num_sel_items do
      local item = reaper.GetSelectedMediaItem( 0, i-1 )
      local item_start = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
      local take = reaper.GetActiveTake( item )
      if not acendan.tableContainsVal(mkr_pos_tbl, item_start) then
        reaper.AddProjectMarker( 0, 0, item_start, item_start, "#" .. tostring(i), i )
        mkr_pos_tbl[#mkr_pos_tbl+1] = item_start
      end
    end
  else
    reaper.MB("No items selected!","Insert Markers", 0)
  end

  reaper.Undo_EndBlock("Shrink Region Edges", -1)
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
reaper.PreventUIRefresh(1)

insertMarkers()

reaper.PreventUIRefresh(-1)

reaper.UpdateArrange()
