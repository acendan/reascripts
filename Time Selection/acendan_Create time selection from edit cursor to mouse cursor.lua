-- @description Time Selection Cursors
-- @author Aaron Cendan
-- @version 1.1
-- @metapackage
-- @provides
--   [main] . > acendan_Create time selection from edit cursor to mouse cursor.lua
-- @link https://aaroncendan.me
-- @changelog
--   Respect snap settings

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function main()
  local edit_cursor_pos = reaper.GetCursorPosition()
  local mouse_cursor_pos = reaper.BR_PositionAtMouseCursor( true )
  
  if mouse_cursor_pos > 0 then
    -- If snap enabled
    if reaper.GetToggleCommandState( 1157 ) then
      mouse_cursor_pos = Arc_GetClosestGridDivision(mouse_cursor_pos)
      if edit_cursor_pos > mouse_cursor_pos then edit_cursor_pos, mouse_cursor_pos = mouse_cursor_pos, edit_cursor_pos end
      reaper.GetSet_LoopTimeRange( true, false, edit_cursor_pos, mouse_cursor_pos, false )
    else
      if edit_cursor_pos > mouse_cursor_pos then edit_cursor_pos, mouse_cursor_pos = mouse_cursor_pos, edit_cursor_pos end
      reaper.GetSet_LoopTimeRange( true, false, edit_cursor_pos, mouse_cursor_pos, false )
    end
  else
    --reaper.MB("Mouse is not over arrange view or ruler!","",0)
  end
end

-- Humbly borrowed from the legendary Archie
function Arc_GetClosestGridDivision(time_pos);
  if not tonumber(time_pos)then return -1 end;
  reaper.PreventUIRefresh(4573);
  local st_tm, en_tm = reaper.GetSet_ArrangeView2(0,0,0,0);
  reaper.GetSet_ArrangeView2(0,1,0,0,st_tm,st_tm+.1);
  local Grid = reaper.SnapToGrid(0,time_pos);
  reaper.GetSet_ArrangeView2(0,1,0,0,st_tm,en_tm);
  reaper.PreventUIRefresh(-4573);
  return Grid
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock()

main()

reaper.Undo_EndBlock("ACendan Time Selection",-1)

reaper.PreventUIRefresh(-1)

reaper.UpdateArrange()

