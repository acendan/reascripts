-- @description Time Selection Cursors
-- @author Aaron Cendan
-- @version 1.0
-- @metapackage
-- @provides
--   [main] . > acendan_Create time selection from edit cursor to mouse cursor.lua
-- @link https://aaroncendan.me

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function main()
  local edit_cursor_pos = reaper.GetCursorPosition()
  local mouse_cursor_pos = reaper.BR_PositionAtMouseCursor( true )
  
  if mouse_cursor_pos > 0 then
    if edit_cursor_pos > mouse_cursor_pos then edit_cursor_pos, mouse_cursor_pos = mouse_cursor_pos, edit_cursor_pos end
    reaper.GetSet_LoopTimeRange( true, false, edit_cursor_pos, mouse_cursor_pos, false )
  else
    reaper.MB("Mouse is not over arrange view or ruler!","",0)
  end
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

