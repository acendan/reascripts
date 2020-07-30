-- @description Set Distance Between Items Track Respective
-- @author Aaron Cendan
-- @version 1.0
-- @metapackage
-- @provides
--   [main] . > acendan_Set distance between selected items to 1 second track respective.lua
--   [main] . > acendan_Set distance between selected items to 2 seconds track respective.lua
--   [main] . > acendan_Set distance between selected items to 3 seconds track respective.lua
--   [main] . > acendan_Set distance between selected items to 4 seconds track respective.lua
--   [main] . > acendan_Set distance between selected items to 5 seconds track respective.lua
-- @link https://aaroncendan.me
-- @about
--   # Set Distance Between Items, Track Respective
--   By Aaron Cendan - July 2020
--
--   * Similar to SWS Reposition items and me2beats set distance between items.
--   * Sets the distance between items relative to other selected items on the same track.

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Get script name for undo text and extracting numbers/other info, if needed
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")

-- Initialize relative items/tracks table
local guid_table = {}

-- Initialize selected items
local init_sel_items = {}

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function main()
  local distance = extractNumberInScriptName()
  
  -- Loop through selected items
  local num_sel_items = reaper.CountSelectedMediaItems(0)
  if num_sel_items > 0 then
    -- Build GUID table for tracks and items
    for i=1, num_sel_items do
      local item = init_sel_items[i]
      local it_guid = reaper.BR_GetMediaItemGUID( item )
      local track = reaper.GetMediaItem_Track( item )
      local tr_guid = reaper.BR_GetMediaTrackGUID( track )
      
      if tableContainsKey(guid_table,tr_guid) then
        guid_table[tr_guid] = guid_table[tr_guid] .. ", " .. it_guid
      else
        tableAppend(guid_table,tr_guid,it_guid)
      end
    end
    
    -- Loop through guid table on a per-track basis
    for track_guid, item_guids in pairs(guid_table) do
      local track_items = {}
      reaper.Main_OnCommand(40289,0) -- Unselect all items
      track_items = parseCSVLine(item_guids,", ")
      for _, item_guid in pairs(track_items) do
        reaper.SetMediaItemSelected( reaper.BR_GetMediaItemByGUID( 0, item_guid ), true )
      end
      separateSelectedItems(distance)
    end
  else
    msg("No items selected!")
  end
end

function separateSelectedItems(d)
  -- Adapted from "me2beats_Set distance between items.lua"
  local items = reaper.CountSelectedMediaItems()
  local t = {}
  
  for i = 1, items-1 do
    local item = reaper.GetSelectedMediaItem(0,i)
    local it_len = reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')
    t[#t+1] = {item,it_len}
  end
  
  local item = reaper.GetSelectedMediaItem(0,0)
  local it_start = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
  local it_len = reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')
  x = it_start + it_len + d
  
  for i = 1, #t do
    reaper.SetMediaItemInfo_Value(t[i][1], 'D_POSITION', x)
    x = x+t[i][2]+d
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

-- Get number from anywhere in a script name // returns Number
function extractNumberInScriptName()
  return tonumber(string.match(script_name, "%d+"))
end

-- Save initially selected items to table
function saveSelectedItems (table)
  for i = 1, reaper.CountSelectedMediaItems(0) do
    table[i] = reaper.GetSelectedMediaItem(0, i-1)
  end
end

-- Restore selected items from table. Requires tableLength() above
function restoreSelectedItems(table)
  for i = 1, tableLength(table) do
    reaper.SetMediaItemSelected( table[i], true )
  end
end

-- Get length/number of entries in a table // returns Number
function tableLength(T)
  local i = 0
  for _ in pairs(T) do i = i + 1 end
  return i
end

-- Check if a table contains a key // returns Boolean
function tableContainsKey(table, key)
    return table[key] ~= nil
end

-- Append new item to end of table
function tableAppend(table, key, value)
  table[key] = value
end

-- CSV to Table
-- http://lua-users.org/wiki/LuaCsv
function parseCSVLine (line,sep) 
  local res = {}
  local pos = 1
  sep = sep or ','
  while true do 
    local c = string.sub(line,pos,pos)
    if (c == "") then break end
    if (c == '"') then
      -- quoted value (ignore separator within)
      local txt = ""
      repeat
        local startp,endp = string.find(line,'^%b""',pos)
        txt = txt..string.sub(line,startp+1,endp-1)
        pos = endp + 1
        c = string.sub(line,pos,pos) 
        if (c == '"') then txt = txt..'"' end 
        -- check first char AFTER quoted string, if it is another
        -- quoted string without separator, then append it
        -- this is the way to "escape" the quote char in a quote. example:
        --   value1,"blub""blip""boing",value3  will result in blub"blip"boing  for the middle
      until (c ~= '"')
      table.insert(res,txt)
      assert(c == sep or c == "")
      pos = pos + 1
    else     
      -- no quotes used, just look for the first separator
      local startp,endp = string.find(line,sep,pos)
      if (startp) then 
        table.insert(res,string.sub(line,pos,startp-1))
        pos = endp + 1
      else
        -- no separator found -> use rest of string and terminate
        table.insert(res,string.sub(line,pos))
        break
      end 
    end
  end
  return res
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock()

saveSelectedItems(init_sel_items)

main()

reaper.Main_OnCommand(40289,0) -- Unselect all items
restoreSelectedItems(init_sel_items)

reaper.Undo_EndBlock(script_name,-1)

reaper.PreventUIRefresh(-1)

reaper.UpdateArrange()
