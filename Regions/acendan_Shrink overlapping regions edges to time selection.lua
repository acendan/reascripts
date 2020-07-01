-- @description Shrink overlapping regions edges to time selection
-- @author Aaron Cendan
-- @version 1.1
-- @metapackage
-- @provides
--   [main] . > acendan_Shrink overlapping regions edges to time selection.lua
-- @link https://aaroncendan.me
-- @changelog
--    Fixed shrinking of multiple overlapping arrays

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
  if num_regions > 0 then
    start_time, end_time = reaper.GetSet_LoopTimeRange(0,0,0,0,0);
    local regions_to_move = {}
	if start_time ~= end_time then
      local i = 0
      while i < num_total do
        local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, i )
        if isrgn then
          if pos <= start_time and rgnend >= end_time then
            regions_to_move[markrgnindexnumber] = name
          end
        end
        i = i + 1
      end
	  
	  for rgn_num, rgn_name in pairs(regions_to_move) do
		reaper.SetProjectMarker( rgn_num, 1, start_time, end_time, rgn_name )
	  end
    else
      reaper.MB("You haven't made a time selection!","Shrink Region Edges", 0)
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
