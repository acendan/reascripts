-- @description Trim selected items at last zero crossing
-- @author Aaron Cendan
-- @version 1.0
-- @metapackage
-- @provides
--   [main] . > acendan_Trim selected items at last zero crossing.lua
-- @link https://aaroncendan.me

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

local init_sel_items = {}

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function splitItems()
  local num_sel_items = reaper.CountSelectedMediaItems(0)
  if num_sel_items > 0 then
    local original_edit_cur_pos = reaper.GetCursorPosition()
    
    for i=0, num_sel_items - 1 do
      local item = reaper.GetSelectedMediaItem( 0, i )
     
      reaper.Main_OnCommand(40289,0) -- Unselect all items
      reaper.SetMediaItemSelected(item,1) -- Select current index item
     
      local item_start_pos = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
      local item_len = reaper.GetMediaItemInfo_Value( item, "D_LENGTH" )
      local item_end_pos = item_start_pos + item_len - 0.005 -- Item end pos minus a sample at 192k because split at zero cross is weird
      
      reaper.SetEditCurPos( item_end_pos, 0, 0 )
      
      reaper.Main_OnCommand(40790,0) -- Move edit cursor to previous zero crossing in items
      reaper.Main_OnCommand(40759,0) -- Split items at edit cursor (select right)
      
      reaper.Main_OnCommand(40006,0) -- Delete leftover
      
      restoreSelectedItems( init_sel_items )
      
    end
    
    reaper.SetEditCurPos(original_edit_cur_pos, 0, 0)
  else
    reaper.MB("No items selected!","Trim Items", 0)
  end
end

-- Save item selection
function saveSelectedItems (table)
  for i = 1, reaper.CountSelectedMediaItems(0) do
    table[i] = reaper.GetSelectedMediaItem(0, i-1)
  end
end

-- Restore item selection
function restoreSelectedItems(table)
  for i = 1, tableLength(table) do
    reaper.SetMediaItemSelected( table[i], true )
  end
end

-- Get table length
function tableLength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock()

saveSelectedItems( init_sel_items )

splitItems()

reaper.Undo_EndBlock("Trim items at last zero crossing",-1)

reaper.PreventUIRefresh(-1)

reaper.UpdateArrange()
