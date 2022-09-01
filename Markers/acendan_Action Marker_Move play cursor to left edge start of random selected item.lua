-- @version 1.0
-- @metapackage
-- @provides
--   [main] .
-- @link https://ko-fi.com/acendan_
-- @about
--   # Action Marker - Move Play Cursor to Random Sel Item
--    - To use this script, run it once while playback is stopped
--        to place an action marker on the timeline.
--    - After placement on the timeline, the action marker will 
--        trigger this script whenever the playhead crosses the marker. 
--    - Simply select the items that you would like to jump between,
--        then press space (play/stop) repeately to jump randomly between
--        the selected items! 

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~ USER CONFIG - EDIT ME ~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

local act_mkr_text = "Rand Sel Item ->"
local act_mkr_color = 33356916

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

local act_mkr_cmd = "!_RSeceefbefe37df7ca6b248f2a97c0e6bc024c6e31"

-- Get this script's name and directory
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local script_directory = ({reaper.get_action_context()})[2]:sub(1,({reaper.get_action_context()})[2]:find("\\[^\\]*$"))

-- Load lua utilities
acendan_LuaUtils = reaper.GetResourcePath()..'/Scripts/ACendan Scripts/Development/acendan_Lua Utilities.lua'
if reaper.file_exists( acendan_LuaUtils ) then dofile( acendan_LuaUtils ); if not acendan or acendan.version() < 6.8 then acendan.msg('This script requires a newer version of ACendan Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"ACendan Lua Utilities"); return end else reaper.ShowConsoleMsg("This script requires ACendan Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'ACendan Lua Utilities'"); return end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function main()
  local edit_cur_pos = reaper.GetCursorPosition()
  
  if reaper.GetPlayState() == 0 then
    -- Playback stopped, remove old and insert new action marker
    acendan.deleteActionMarker(act_mkr_cmd, act_mkr_text)
    acendan.addActionMarker(act_mkr_cmd, act_mkr_text, act_mkr_color, edit_cur_pos)

  else
    local num_sel_items = reaper.CountSelectedMediaItems(0)
    if num_sel_items > 0 then
    local rand_item_idx = math.random(reaper.CountSelectedMediaItems(num_sel_items)) - 1
    local rand_item = reaper.GetSelectedMediaItem(0, rand_item_idx)
    local rand_item_pos = reaper.GetMediaItemInfo_Value(rand_item, "D_POSITION")
    
    -- Move to item position w/ playhead, then return to original position without seeking play
    reaper.SetEditCurPos(rand_item_pos, true, true)
    reaper.SetEditCurPos(edit_cur_pos, false, false)
    end
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
