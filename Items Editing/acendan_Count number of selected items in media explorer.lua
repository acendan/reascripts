-- @description Count Selection in Media Explorer
-- @author Aaron Cendan
-- @version 1.1
-- @metapackage
-- @provides
--   [main] . > acendan_Count number of selected items in media explorer.lua
-- @link https://aaroncendan.me
-- @about
--   # Count Selection in Media Explorer
--   By Aaron Cendan - July 2020
--
--   * Requires the JS_ReascriptAPI extension.
--   * Script adapted from: http://forum.cockos.com/showthread.php?p=2071080#post2071080
-- @changelog
--   # Fixed file listview child window handle identification

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Get script name for undo text and extracting numbers/other info, if needed
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function main()
  countSelectedItemsMediaExplorer()
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
  reaper.MB(msg, "# Items", 0)
end

-- Count selected items media explorer
function countSelectedItemsMediaExplorer()
  -- Get media explorer
  local hWnd = reaper.JS_Window_Find(reaper.JS_Localize("Media Explorer","common"), true)
  if hWnd == nil then msg("Unable to find Media Explorer window handle!") return end  
  
  -- Get file listview from child class name
  -- Microsoft Spy++ is amazing
  local file_LV = reaper.JS_Window_FindEx(hWnd, nil, "SysListView32", "")
  if not reaper.JS_Window_IsWindow(file_LV) then msg("Unable to find Media Explorer file list child window!") return end  
  
  -- Get selected item info
  sel_count, sel_indexes = reaper.JS_ListView_ListAllSelItems(file_LV)
  if sel_count == 0 then 
    msg("No items selected in media explorer!")
  elseif sel_count == 1 then
    msg("1 item selected in media explorer.")
  else
    msg(sel_count .. " items selected in media explorer.")
  end 
  
  --[[ ADDITIONAL MEDIA EXPLORER ITEM PARSING
  for ndx in string.gmatch(sel_indexes, '[^,]+') do 
    index = tonumber(ndx)
    local fname = reaper.JS_ListView_GetItemText(file_LV, index, 0)
    local size = reaper.JS_ListView_GetItemText(file_LV, index, 1)
    local date = reaper.JS_ListView_GetItemText(file_LV, index, 2)
    local ftype = reaper.JS_ListView_GetItemText(file_LV, index, 3)
    dbg(fname .. ', ' .. size .. ', ' .. date .. ', ' .. ftype) 
  end
  
  -- get selected path  from edit control inside combobox
  local combo = reaper.JS_Window_FindChildByID(hWnd, 1002)
  local edit = reaper.JS_Window_FindChildByID(combo, 1001)
  local path = reaper.JS_Window_GetTitle(edit, "", 255)
  dbg(path)
  ]]--
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock()

-- Check for JS_ReaScript Extension
if reaper.JS_Dialog_BrowseForSaveFile then
  main()
else
  msg("Please install the JS_ReaScriptAPI REAPER extension, available in ReaPack, under the ReaTeam Extensions repository.\n\nExtensions > ReaPack > Browse Packages\n\nFilter for 'JS_ReascriptAPI'. Right click to install.")
end


reaper.Undo_EndBlock(script_name,-1)

reaper.PreventUIRefresh(-1)

reaper.UpdateArrange()

