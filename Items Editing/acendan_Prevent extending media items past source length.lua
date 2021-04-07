-- @noindex
-- @description Prevent Extending Items
-- @author Aaron Cendan
-- @version 1.0
-- @metapackage
-- @provides
--   [main] . > acendan_Prevent extending media items past source length.lua
-- @link https://aaroncendan.me
-- @about
--   # This is a background/toggle script!
--   By Aaron Cendan - Sept 2020
--
--   ### Notes
--   * When prompted if you want to terminate instances, click the little checkbox then terminate.

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Refresh rate (in seconds)
local refresh_rate = 0.3

-- Get action context info (needed for toolbar button toggling)
local _, _, section, cmdID = reaper.get_action_context()

-- Get this script's name and directory
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local script_directory = ({reaper.get_action_context()})[2]:sub(1,({reaper.get_action_context()})[2]:find("\\[^\\]*$"))

-- Load lua utilities
acendan_LuaUtils = reaper.GetResourcePath()..'/scripts/ACendan Scripts/Development/acendan_Lua Utilities.lua'
if reaper.file_exists( acendan_LuaUtils ) then dofile( acendan_LuaUtils ); if not acendan or acendan.version() < 3.0 then acendan.msg('This script requires a newer version of ACendan Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"ACendan Lua Utilities"); return end else reaper.ShowConsoleMsg("This script requires ACendan Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'ACendan Lua Utilities'"); return end

ticker = 0
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Setup runs once on script startup
function setup()
  -- Timing control
  local start = reaper.time_precise()
  check_time = start
  
  -- Toggle command state on
  reaper.SetToggleCommandState( section, cmdID, 1 )
  reaper.RefreshToolbar2( section, cmdID )
  
  -- Set cursor to circle with slash
  -- https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-loadcursora
  circle_slash_cursor = reaper.JS_Mouse_LoadCursor( 32648 )
end

-- Main function will run in Reaper's defer loop. EFFICIENCY IS KEY.
function main()
  -- Validate mouse clicked in arrange window over a track
  local window, segment, details = reaper.BR_GetMouseCursorContext()
  local mouse_clicked = reaper.JS_Mouse_GetState(1)
  
  -- Getting the window, segment, and details can have really spotty results. The only stable factor
  -- seems to be mouse clicked status, so that's what we're using for the main check
  if mouse_clicked == 1 then
  
    -- Get item at cursor
    if not item then item, _ = reaper.BR_ItemAtMouseCursor( ) end
  
    -- If item is valid then evaluate until mouse is released
    if item then
      EvaluateItem()
    
    else
      -- Confirm that mouse is clicked in the arrange window over a track
      if window == "arrange" and segment == "track" then
      
        -- Try to get item at mouse cursor
        item = reaper.BR_GetMouseCursorContext_Item()
          
        -- If item is valid then evaluate
        if item then EvaluateItem() end
      end
    end
    
  else
    -- Clear stored item (TO DO: other stuff like unlock item here)
    item = nil
  end
  
  -- Item still locked but mouse released
  if item_locked and reaper.JS_Mouse_GetState(1) == 0 then
    reaper.SetMediaItemInfo_Value( item_locked, "C_LOCK", 0 )
    item_locked = nil
  end
  
  reaper.defer(main)
end

-- Exit function will run once when the script is terminated
function Exit()
  reaper.UpdateArrange()
  reaper.SetToggleCommandState( section, cmdID, 0 )
  reaper.RefreshToolbar2( section, cmdID )
  return reaper.defer(function() end)
end


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ UTILITIES ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function EvaluateItem()
  -- TO DO: Actually reference start offset or item portioning
  local item_len =  reaper.GetMediaItemInfo_Value( item, "D_LENGTH" )
  
  -- Validate take
  local take = reaper.GetActiveTake( item )
  if take ~= nil then 
    
    -- TO DO: Proper source length for portions
    local pcm_source = reaper.GetMediaItemTake_Source(take)
    local source_len = reaper.GetMediaSourceLength(pcm_source)
    
    -- TO DO: Work with item extending left
    -- Check if item length is greater than source length AND mouse is clicked
    if item_len > source_len then
    
      -- Lock item length at max
      reaper.SetMediaItemLength(item,source_len,true)
      
      -- Lock item
      reaper.SetMediaItemInfo_Value( item, "C_LOCK", 1 )
      item_locked = item
      
      -- Store initial cursor icon
      if not store_cursor then 
        store_cursor =  reaper.JS_Mouse_GetCursor()
      end
    
      -- Set cursor icon to circle slash
      reaper.JS_Mouse_SetCursor( circle_slash_cursor )

    else
      
      -- Unlock item
      if reaper.GetMediaItemInfo_Value(item, "C_LOCK") > 0 then
        reaper.SetMediaItemInfo_Value( item, "C_LOCK", 0 )
        item_locked = nil
      end
      
      -- If mouse is back over the main item, not past edge...
      if store_cursor then
        -- Reset cursor icon
        reaper.JS_Mouse_SetCursor(store_cursor)
        store_cursor = false
      end
    end
  end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

setup()
reaper.atexit(Exit)
main()
