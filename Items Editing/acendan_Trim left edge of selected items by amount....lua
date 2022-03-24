-- @description Trim left edge of selected items by amount
-- @author Aaron Cendan
-- @version 1.1
-- @metapackage
-- @provides
--   [main] . > acendan_Trim or extend left edge of selected items by amount...lua
-- @link https://aaroncendan.me
-- @about
--   By Aaron Cendan - Sept 2020
--
--   ### Credits
--   * Adapted from me2beats: Trim sel items right edges to nearest grid divisions
-- @changelog
--   # Not sure why, but this script no longer works as expected. Fixed by adding start offset 
--      adjustment (lines 27 - 29). Thanks @Austin Boi for the heads up <3

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function nothing() end
function trim_items(trim_len)
  start_pos = reaper.GetMediaItemInfo_Value(it, 'D_POSITION')
  len = reaper.GetMediaItemInfo_Value(it, 'D_LENGTH')
  end_pos = start_pos + len
  reaper.ApplyNudge(0, 1, 2, 1, start_pos+trim_len, false, 0)
  
  local take = reaper.GetActiveTake(it)
  local curr_offset = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
  reaper.SetMediaItemTakeInfo_Value(take,"D_STARTOFFS",curr_offset + trim_len)
end

function main()
  -- Get user input
  local ret_input, trim_len = reaper.GetUserInputs( "Trim/Extend Left Edge", 1, "Length (+/- sec)", "1.0" )
  if not ret_input then return end
  
  items = reaper.CountSelectedMediaItems(0)
  if items > 0 then
    script_title = 'Trim sel items right edges to nearest grid divisions'
    reaper.Undo_BeginBlock()
    reaper.PreventUIRefresh(1)
    if items == 1 then
      it = reaper.GetSelectedMediaItem(0, 0)
      trim_items(trim_len)
    else
  ----  save selected items---------------
      t = {}
      for i = 0, items-1 do
        it = reaper.GetSelectedMediaItem(0,i)
        guid = reaper.BR_GetMediaItemGUID(it)
        table.insert(t, guid)
      end
  ---------------------------------------
      reaper.Main_OnCommand(40289, 0)--  unselect all items
      for i = 1, #t do
        it = reaper.BR_GetMediaItemByGUID(0, t[i])
        reaper.SetMediaItemSelected(it, true)
        trim_items(trim_len)      
        reaper.SetMediaItemSelected(it, false)
      end
  ---- restore sel items-------------------
      for i = 1, #t do
        it = reaper.BR_GetMediaItemByGUID(0, t[i])
        reaper.SetMediaItemSelected(it, true)
      end
  -----------------------------------------
    end
    reaper.Undo_EndBlock(script_title, -1)
    reaper.PreventUIRefresh(-1)
  else
    reaper.defer(nothing)
  end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ UTILITIES ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Deliver messages and add new line in console
function dbg(dbg)
  reaper.ShowConsoleMsg(dbg .. "\n")
end

-- Deliver messages using message box
function msg(msg)
  reaper.MB(msg, script_name, 0)
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock()

main()

reaper.Undo_EndBlock("Trim Right Edge Items",-1)

reaper.PreventUIRefresh(-1)

reaper.UpdateArrange()


