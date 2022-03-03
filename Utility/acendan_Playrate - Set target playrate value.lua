-- @description Playrate - Set target value
-- @author Edgemeal, Aaron Cendan
-- @version 1.0
-- @metapackage
-- @provides
--   [main] .
-- @link https://forum.cockos.com/showthread.php?t=262914
-- @about
--   # This script sets the target playrate used by: acendan_Playrate - Jump to target playrate.lua
--   # This script was written almost entirely by Edgemeal, on this Reaper forum thread: https://forum.cockos.com/showthread.php?t=262914
--   # Added support for negative playrates

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~ USER CONFIG - EDIT ME ~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Menu of target_playrates/value used in pop-up
local target_playrates = { -6, -4, -2, 2, 4, 6 } --< Edit as needed!


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Set playrate script value.lua
local num = tonumber(reaper.GetExtState("acendan_Playrate", "Value")) -- get current saved value

function ChangePlayrate()
 
  -- build menu
  local menu = "# Set target playrate, semitones ||" -- menu header
  for i = 1, #target_playrates do  
    if target_playrates[i] == num then checked = "!" else checked = "" end -- item checked state
    menu = menu .. checked .. target_playrates[i] .. "|" 
  end
  
  -- show menu
  local gfx_title = "hidden " .. reaper.genGuid()
  gfx.init(gfx_title, 0, 0, 0, 0, 0)
  local hwnd = reaper.JS_Window_FindTop(gfx_title, true)
  if hwnd then reaper.JS_Window_Show(hwnd, "HIDE") end
  gfx.x, gfx.y = gfx.mouse_x, gfx.mouse_y
  local selection = gfx.showmenu(menu)-1
  gfx.quit()

  -- update value used by other script
  if selection > 0 then 
    reaper.SetExtState("acendan_Playrate", "Value", tostring(target_playrates[selection]), true)
  end
end

-- begin
if not reaper.APIExists('JS_Window_Show') then
  reaper.MB('js_ReaScriptAPI extension is required for this script.', 'Missing API', 0)
else
  ChangePlayrate()
end
reaper.defer(function () end)

