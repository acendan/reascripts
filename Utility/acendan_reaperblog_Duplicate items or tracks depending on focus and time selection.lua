-- @description Reaper Blog Smart Duplicate
-- @author Aaron Cendan
-- @version 1.1
-- @metapackage
-- @provides
--   [main] .
-- @link https://ko-fi.com/acendan_
-- @about
--   # Script request from Jon @ Reaper Blog
-- @changelog
--   # Fix duplication of items exactly at time selection edges (thanks mauro @kytdkut!)
--   # Split up options for scrolling to duped items and moving edit cursor (thanks Jon @reaperblog!)

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~ USER CONFIG - EDIT ME ~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Horizontal scroll to duplicated items
scroll_to_duped_items = true

-- Move edit cursor to start of duplicated items
move_edit_curs_start = false

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Get this script's name and directory
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local script_directory = ({reaper.get_action_context()})[2]:sub(1,({reaper.get_action_context()})[2]:find("\\[^\\]*$"))

-- Load lua utilities
acendan_LuaUtils = reaper.GetResourcePath()..'/scripts/ACendan Scripts/Development/acendan_Lua Utilities.lua'
if reaper.file_exists( acendan_LuaUtils ) then dofile( acendan_LuaUtils ); if not acendan or acendan.version() < 5.6 then acendan.msg('This script requires a newer version of ACendan Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"ACendan Lua Utilities"); return end else reaper.ShowConsoleMsg("This script requires ACendan Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'ACendan Lua Utilities'"); return end


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function main()
  local context = reaper.GetCursorContext()
  
  -- TRACKS
  if context == 0 then
    reaper.Main_OnCommand(40062, 0) -- Track: Duplicate tracks
  
  -- ITEMS
  elseif context == 1 then
    local s, e = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
    
    -- Check items within time sel
    local items_within_sel = false
    local num_sel_items = reaper.CountSelectedMediaItems(0)
    if num_sel_items > 0 then
      local items_start_pos = acendan.getStartPosSelItems()
      local items_end_pos = acendan.getEndPosSelItems()
      if items_start_pos >= s and items_end_pos <= e then items_within_sel = true end
    end
    
    -- Duplicate items
    if s == e or not items_within_sel then
      reaper.Main_OnCommand(41295, 0) -- Item: Duplicate items
    else
      reaper.Main_OnCommand(41296, 0) -- Item: Duplicate selected area of items
    end
    
    -- Post-processing
    if reaper.CountSelectedMediaItems(0) > 0 then
      -- Move edit cursor to start of duplicated items
      if move_edit_curs_start then reaper.SetEditCurPos(acendan.getStartPosSelItems(), false, false) end
      
      -- SWS: Horizontal scroll to put edit cursor at 50%
      if scroll_to_duped_items then reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_HSCROLL50"),0) end
    end
  -- ENVELOPES
  elseif context == 2 then
    reaper.Main_OnCommand(42085, 0) -- Envelope: Duplicate and pool automation items
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

