-- @description Import Selected Item Names Text File
-- @author Aaron Cendan
-- @version 1.2
-- @metapackage
-- @provides
--   [main] .
-- @link https://ko-fi.com/acendan_
-- @about
--   # Imports selected item names from a text file where each new line is a new item name
-- @changelog
--   # Added user config option for 'use_timeline_order'

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~ USER CONFIG - EDIT ME ~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- use_timeline_order = false -> default. this will rename items one-by-one from the top track, down
-- use_timeline_order = true  -> this will order items by project timeline position (irrespective of track)
use_timeline_order = false

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Get this script's name and directory
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local script_directory = ({reaper.get_action_context()})[2]:sub(1,({reaper.get_action_context()})[2]:find("\\[^\\]*$"))

-- Load lua utilities
acendan_LuaUtils = reaper.GetResourcePath()..'/Scripts/ACendan Scripts/Development/acendan_Lua Utilities.lua'
if reaper.file_exists( acendan_LuaUtils ) then dofile( acendan_LuaUtils ); if not acendan or acendan.version() < 6.9 then acendan.msg('This script requires a newer version of ACendan Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"ACendan Lua Utilities"); return end else reaper.ShowConsoleMsg("This script requires ACendan Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'ACendan Lua Utilities'"); return end


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function main()

  local num_sel_items = reaper.CountSelectedMediaItems(0)
  if num_sel_items > 0 then
  
    local items_table = {}
    acendan.saveSelectedItems(items_table)
    
    if use_timeline_order then
      acendan.sortItemTableByPos(items_table)
    end
          
    -- File picker dialog
    retval, file = reaper.JS_Dialog_BrowseForOpenFiles( "Import Names From File", acendan.getProjDir(), "", "", false )
    if retval and file ~= '' then
      -- Init item iterator
      local i = 0
      
      -- Create and loop through names table from each line in file
      local names_table = acendan.fileToTable(file)
      for _, name in ipairs(names_table) do
        if name ~= "" then
          -- Break out of while loop if an item is found and named
          local itm_named = false
          
          -- Loop through remaining items
          while i < num_sel_items and not itm_named do
            -- Rename
            local item = items_table[i+1]
            local take = reaper.GetActiveTake( item )
            if take ~= nil then 
              reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", name, true)
              itm_named = true
            end
            i = i + 1
          end
        end
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
reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock()

main()

reaper.Undo_EndBlock(script_name,-1)

reaper.PreventUIRefresh(-1)

reaper.UpdateArrange()
