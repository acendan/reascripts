-- @description Stretch overlapping regions edges to time selection
-- @author Aaron Cendan
-- @version 1.1
-- @metapackage
-- @provides
--   [main] . > acendan_Stretch overlapping regions edges to time selection.lua
-- @link https://aaroncendan.me
-- @changelog
--    Cleaned up naming conventions.

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function stretchRegions()
  reaper.Undo_BeginBlock()
  local ret, num_markers, num_regions = reaper.CountProjectMarkers( 0 )
  local num_total = num_markers + num_regions
  if num_regions > 0 then
    start_time, end_time = reaper.GetSet_LoopTimeRange(0,0,0,0,0);
    if start_time ~= end_time then
      local i = 0
      while i < num_total do
        local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, i )
        if isrgn then
          if pos >= start_time and rgnend <= end_time then
            reaper.SetProjectMarkerByIndex( 0, i, isrgn, start_time, end_time, markrgnindexnumber, name, color )
          end
        end
        i = i + 1
      end
    else
      reaper.MB("You haven't made a time selection!","Stretch Region Edges", 0)
    end
  else
    reaper.MB("Your project doesn't have any regions!","Stretch Region Edges", 0)
  end
  reaper.Undo_EndBlock("Stretch Region Edges", -1)
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
reaper.PreventUIRefresh(1)

stretchRegions()

reaper.PreventUIRefresh(-1)

reaper.UpdateArrange()
