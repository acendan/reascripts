-- @description Load Render Directory from Slot
-- @author Aaron Cendan
-- @version 1.0
-- @metapackage
-- @provides
--   [main] . > acendan_Load render directory from slot 1.lua
--   [main] . > acendan_Load render directory from slot 2.lua
--   [main] . > acendan_Load render directory from slot 3.lua
--   [main] . > acendan_Load render directory from slot 4.lua
-- @link https://aaroncendan.me
-- @about
--   # Load Render Directory from Slot
--   By Aaron Cendan - August 2020
--
--   ### Requirements
--   * SWS Extension: https://www.sws-extension.org/

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Get script name for undo text and extracting numbers/other info, if needed
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function loadSlot()

  local slot_num = extractNumberInScriptName()

  if slot_num then
    if reaper.HasExtState( "acendan_RenderDirectorySlots", slot_num ) then
      local cur_dir = reaper.GetExtState( "acendan_RenderDirectorySlots", slot_num )
      
      -- SET RENDER DIRECTORY
      reaper.GetSetProjectInfo_String(0, "RENDER_FILE", cur_dir, true)
    else
      msg("No directory saved in Slot #" .. slot_num .. "!\n\nPlease run the action acendan_Save render directory to slot " .. slot_num .. ".lua")
    end
  else
    msg("No slot number found in script name!\n\nPlease edit script name and include a slot number.")
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

-- Get number from script name
function extractNumberInScriptName()
  return string.match(script_name, "%d+")
end


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock()

loadSlot()

reaper.Undo_EndBlock(script_name,-1)

reaper.PreventUIRefresh(-1)

reaper.UpdateArrange()

