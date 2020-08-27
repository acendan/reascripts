-- @description Save Render Directory to Slot
-- @author Aaron Cendan
-- @version 1.0
-- @metapackage
-- @provides
--   [main] . > acendan_Save render directory to slot 1.lua
--   [main] . > acendan_Save render directory to slot 2.lua
--   [main] . > acendan_Save render directory to slot 3.lua
--   [main] . > acendan_Save render directory to slot 4.lua
-- @link https://aaroncendan.me
-- @about
--   # Save Render Directory to Slot
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

function saveSlot()

  local slot_num = extractNumberInScriptName()

  if slot_num then
    if reaper.HasExtState( "acendan_RenderDirectorySlots", slot_num ) then
      local cur_dir = reaper.GetExtState( "acendan_RenderDirectorySlots", slot_num )
      local response = reaper.MB("Slot #" .. slot_num .. " already has a saved directory: " .. cur_dir .. "\n\nWould you like to overwrite it?", script_name, 4)
      if response == 6 then
        reaper.DeleteExtState( "acendan_RenderDirectorySlots", slot_num, true )
        saveSlot()
      end
    else
      local ret_input, user_input = reaper.GetUserInputs( script_name, 1, "Render Directory:,extrawidth=100", "Renders" )
      if not ret_input then return end
      
      -- STORE SLOT INFO
      reaper.SetExtState("acendan_RenderDirectorySlots", slot_num, user_input, true )
      
      -- SET RENDER DIRECTORY
      reaper.GetSetProjectInfo_String(0, "RENDER_FILE", user_input, true)
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

saveSlot()

reaper.Undo_EndBlock(script_name,-1)

reaper.PreventUIRefresh(-1)

reaper.UpdateArrange()

