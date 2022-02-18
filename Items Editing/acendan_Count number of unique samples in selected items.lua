-- @description Count Num Unique Samples in Items
-- @author Aaron Cendan
-- @version 1.0
-- @metapackage
-- @provides
--   [main] .
-- @link https://ko-fi.com/acendan_
-- @about
--  * This requires nvk_WORKFLOW to work!
--  * Sample detection thresholds can be set in: nvk_TAKES - Consolidate takes with take markers SMART.eel

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~ USER CONFIG - EDIT ME ~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Get this script's name and directory
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local script_directory = ({reaper.get_action_context()})[2]:sub(1,({reaper.get_action_context()})[2]:find("\\[^\\]*$"))

-- Load lua utilities
acendan_LuaUtils = reaper.GetResourcePath()..'/scripts/ACendan Scripts/Development/acendan_Lua Utilities.lua'
if reaper.file_exists( acendan_LuaUtils ) then dofile( acendan_LuaUtils ); if not acendan or acendan.version() < 4.4 then acendan.msg('This script requires a newer version of ACendan Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"ACendan Lua Utilities"); return end else reaper.ShowConsoleMsg("This script requires ACendan Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'ACendan Lua Utilities'"); return end


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function main()
  if #init_sel_items > 0 then
    for i=1,#init_sel_items do
      local item = init_sel_items[i]
      local take = reaper.GetActiveTake(item)
      if take ~= nil then
        local _,item_name = reaper.GetSetMediaItemTakeInfo_String(take,"P_NAME","",false)
        acendan.setOnlyItemSelected(item)
        
        -- Consolidate takes, then debug print num samples
        reaper.Undo_BeginBlock()
        reaper.Main_OnCommand(nvk_consolidate_takes,0)
        acendan.dbg(item_name .. " - " .. tostring(reaper.GetNumTakeMarkers(take)))
        reaper.Undo_EndBlock(script_name,-1)
        reaper.Undo_DoUndo2(0)
      end
    end
  else
    acendan.msg("No items selected!")
  end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ UTILITIES ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Script: nvk_TAKES - Consolidate takes with take markers SMART.eel
nvk_consolidate_takes = reaper.NamedCommandLookup("_RSeb359e5ae9360b01d06839005088f24a200a71e4",0)
if nvk_consolidate_takes > 0 then
  reaper.PreventUIRefresh(1)
  init_sel_items = {}
  acendan.saveSelectedItems(init_sel_items)
  main()
  acendan.restoreSelectedItems(init_sel_items)
  reaper.PreventUIRefresh(-1)
  reaper.UpdateArrange()
else
  acendan.dbg("This script requires Nick von Kaenel's nvk_WORKFLOW, available for purchase at:\nhttps://gum.co/nvk_WORKFLOW")
end
