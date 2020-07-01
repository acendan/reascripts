-- @description Shrink overlapping regions to edges of selected media items
-- @author Aaron Cendan
-- @version 1.0
-- @metapackage
-- @provides
--   [main] . > acendan_Shrink overlapping regions to edges of selected media items.lua
-- @link https://aaroncendan.me

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function shrinkRegions()
  reaper.Undo_BeginBlock()
  local ret, num_markers, num_regions = reaper.CountProjectMarkers( 0 )
  local num_total = num_markers + num_regions
  local start_time = math.huge
  local end_time = 0
  
  if num_regions > 0 then
    
    local num_sel_items = reaper.CountSelectedMediaItems(0)
    if num_sel_items > 0 then
      for i=0, num_sel_items - 1 do
        local item = reaper.GetSelectedMediaItem( 0, i )
        local item_start = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
        local item_end = item_start + reaper.GetMediaItemInfo_Value( item, "D_LENGTH" )
        
        start_time = math.min(start_time,item_start)
        end_time = math.max(end_time,item_end)
      end

      if start_time ~= end_time then
        local i = 0
        while i < num_total do
          local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, i )
          if isrgn then
            if pos <= start_time and rgnend >= end_time then
              reaper.SetProjectMarkerByIndex( 0, i, isrgn, start_time, end_time, markrgnindexnumber, name, color )
            end
          end
          i = i + 1
        end
      else
        reaper.MB("The selected items have no length! How is this even possible?","Shrink Region Edges", 0)
      end
    else
      reaper.MB("No items selected!","Shrink Region Edges", 0)
    end
  else
    reaper.MB("Your project doesn't have any regions!","Shrink Region Edges", 0)
  end
  reaper.Undo_EndBlock("Shrink Region Edges", -1)
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
reaper.PreventUIRefresh(1)

shrinkRegions()

reaper.PreventUIRefresh(-1)

reaper.UpdateArrange()
