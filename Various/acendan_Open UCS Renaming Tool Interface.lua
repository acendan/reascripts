-- @description Open UCS Renaming Tool
-- @author Aaron Cendan
-- @version 1.0
-- @metapackage
-- @provides
--   [main] . > acendan_Open UCS Renaming Tool Interface.lua
--   UCS Toolbar Icon/*.png
-- @link https://aaroncendan.me
-- @about
--   # Open UCS Renaming Tool Web Interface
--   By Aaron Cendan - August 2020
--
--   * Will use whichever light/dark UCS interface you have first in the Options > Preferences > Control/OSC/Web menu. 
--   * If you would like to set up the UCS logo as a toolbar icon, go to:
--        REAPER/Scripts/ACendan Scripts/Various/UCS Toolbar Icon
--     then copy the image(s) from that folder into:
--        REAPER/Data/toolbar_icons
--   * It should then show up when you are customizing toolbar icons in Reaper.

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Get script name for undo text and extracting numbers/other info, if needed
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function main()
  local ini_file = fileToTable(reaper.get_ini_file())
  local localhost = "http://localhost:"
  local ucs_path = ""
  
  for _, line in pairs(ini_file) do
    if line:find("acendan_UCS Renaming Tool.html") then
      local port = getPort(line)
      ucs_path = localhost .. port
      break
    
    elseif line:find("acendan_UCS Renaming Tool_Dark.html") then
      local port = getPort(line)
      ucs_path = localhost .. port
      break
    end
  end
  
  if ucs_path ~= "" then
    openURL(ucs_path)
  else
    local response = reaper.MB("UCS Renaming Tool not found in Reaper Web Interface settings!\n\nWould you like to open the installation tutorial video?","Open UCS Renaming Tool",4)
    if response == 6 then openURL("https://youtu.be/fO-2At7eEQ0") end
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

-- Open a webpage or file directory
function openURL(path)
  reaper.CF_ShellExecute(path)
end

-- Convert file input to table, each line = new entry // returns Table
function fileToTable(filename)
  local file = io.open(filename)
  io.input(file)
  local t = {}
  for line in io.lines() do
    if line:find("csurf_") then table.insert(t, line) end
  end
  table.insert(t, "")
  io.close(file)
  return t
end

-- Get localhost port from reaper.ini file line
function getPort(line)
  local port = line:sub(line:find(" ")+3,line:find("'")-2)
  return port
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
reaper.PreventUIRefresh(1)

main()

reaper.PreventUIRefresh(-1)

reaper.UpdateArrange()
