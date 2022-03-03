-- @description Playrate - Jump to target value
-- @author Edgemeal, Aaron Cendan
-- @version 1.0
-- @metapackage
-- @provides
--   [main] .
-- @link https://forum.cockos.com/showthread.php?t=262914
-- @about
--   # This script jumps to the target playrate set by: acendan_Playrate - Set target playrate value.lua
--   # This script was written by Edgemeal, on this Reaper forum thread: https://forum.cockos.com/showthread.php?t=262914

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~ USER CONFIG - EDIT ME ~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Get this script's name and directory
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local script_directory = ({reaper.get_action_context()})[2]:sub(1,({reaper.get_action_context()})[2]:find("\\[^\\]*$"))

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function main()
  -- Playrate.lua
  local num = tonumber(reaper.GetExtState("acendan_Playrate", "Value"))
  if num ~= nil then
    reaper.Undo_BeginBlock()
    reaper.Main_OnCommand(40521, 0) -- Transport: Set playrate to 1.0
    if num > 0 then
      -- Increase playrate by semitones
      for i = 1, num do
        reaper.Main_OnCommand(40522, 0) -- Transport: Increase playrate by ~6% (one semitone)
      end
    else
      -- Decrease playrate by semitones
      for i = 1, -num do
        reaper.Main_OnCommand(40523, 0) -- Transport: Decrease playrate by ~6% (one semitone)
      end
    end
    reaper.Undo_EndBlock('Set playrate to ' .. num .. ' semitones', -1)
  else
    reaper.MB('Use the following script to set a target playrate:\n\nacendan_Playrate - Set target playrate value.lua', 'acendan_Playrate', 0)
  
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

