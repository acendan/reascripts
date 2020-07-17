-- @description Insert Marker Every X Seconds After Edit Cursor
-- @author Aaron Cendan
-- @version 1.1
-- @metapackage
-- @provides
--   [main] . > acendan_Insert markers every x seconds after edit cursor.lua
-- @link https://aaroncendan.me
-- @about Insert Marker Every X Seconds After Edit Cursor

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~ INSERT MARKERS ~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function insertMarkers()
  -- Show message box with two user text inputs
  local ret_input, user_input = reaper.GetUserInputs("Insert Markers Every X Sec",  2,
                          "Seconds Between Markers,Number of Markers,extrawidth=100","1.0,10")
  
  -- Check to see if user cancelled input
  if not ret_input then return end
  
  -- Split user input string
  local num_sec, num_markers = user_input:match("([^,]+),([^,]+)")

  -- Convert to numbers
  num_sec = tonumber(num_sec)
  num_markers = tonumber(num_markers)
  
  -- Safety net
  if not num_sec or not num_sec then reaper.MB("Inputs must be numbers! Please try again.","Insert Markers",0) insertMarkers() return end

  -- Get cursor position
  local cursor_pos = reaper.GetCursorPosition()
  
  -- Loop through num markers
  for i=1,num_markers do
    reaper.Main_OnCommand(  reaper.NamedCommandLookup( "_S&M_INS_MARKER_EDIT" ), 0 ) --Insert marker at edit cursor
    reaper.MoveEditCursor( num_sec, 0 ) --Scoot edit cursor
  end
  
  -- Reset cursor pos
  reaper.SetEditCurPos( cursor_pos, 1, 0 )

end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~~~~~~~~~~  
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
reaper.PreventUIRefresh(1)

insertMarkers()

reaper.PreventUIRefresh(-1)

reaper.UpdateArrange()
