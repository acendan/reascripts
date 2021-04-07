-- @description Insert marker at start of selected items with number
-- @author Aaron Cendan
-- @version 1.1
-- @metapackage
-- @provides
--   [main] . > acendan_Insert marker at start of selected items with sel item number.lua
-- @link https://aaroncendan.me
-- @changelog
--   Added # symbol for compatibility with render window's marker embedding option with #

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function insertMarkers()
  reaper.Undo_BeginBlock()
  
  local num_sel_items = reaper.CountSelectedMediaItems(0)
  if num_sel_items > 0 then
    for i=0, num_sel_items - 1 do
      local item = reaper.GetSelectedMediaItem( 0, i )
      local item_start = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
      local take = reaper.GetActiveTake( item )
      reaper.AddProjectMarker( 0, 0, item_start, item_start, "#" .. tostring(i+1), i )
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
