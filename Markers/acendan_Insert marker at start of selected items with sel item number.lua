-- @description Insert marker at start of selected items with number
-- @author Aaron Cendan
-- @version 1.2
-- @metapackage
-- @provides
--   [main] . > acendan_Insert marker at start of selected items with sel item number.lua
-- @link https://aaroncendan.me
-- @changelog
--   Aligned enumeration with marker and val

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function insertMarkers()
  reaper.Undo_BeginBlock()
  
  local num_sel_items = reaper.CountSelectedMediaItems(0)
  if num_sel_items > 0 then
    for i=1, num_sel_items do
      local item = reaper.GetSelectedMediaItem( 0, i-1 )
      local item_start = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
      local take = reaper.GetActiveTake( item )
      reaper.AddProjectMarker( 0, 0, item_start, item_start, "#" .. tostring(i), i )
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
