-- @description Auto Generate Scripts to Open Web Interfaces
-- @author Aaron Cendan
-- @version 1.0
-- @metapackage
-- @provides
--   [main] . > acendan_Auto generate scripts to open web interfaces.lua
-- @link https://aaroncendan.me
-- @about
--   # Auto Generate Scripts to Open Web Interfaces
--   By Aaron Cendan - August 2020
--
--   ### About
--   * Run this script to automatically generate actions that open your currently registered web interfaces.
--   * Re-running this will clear out old actions and rebuild based on current list
--
--   ### Requirements
--   * SWS Extension: https://www.sws-extension.org/

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Get script name for undo text and extracting numbers/other info, if needed
local self_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function generateScripts()
  local ini_file = fileToTable(reaper.get_ini_file())
  
  if #ini_file > 0 then
    local script_names = {}
    local script_ports = {}
    local prompt = "You are about to auto-generate the following scripts:\n~~~\n"
    
    -- Build table of script names and paths
    for _, line in pairs(ini_file) do
      if line ~= "" then 
        local name = getName(line)
        local script_name = "acendan_Open web interface - " .. name .. ".lua"
        table.insert(script_names,script_name)
        prompt = prompt .. script_name .. "\n"
        
        local port = getPort(line)
        local script_port = "reaper.CF_ShellExecute(" .. "'http://localhost:" .. port .. "')"
        table.insert(script_ports,script_port)
      end
    end
    
    -- Prompt user to generate scripts
    prompt = prompt .. "~~~\nWould you like to continue?"
    local response = reaper.MB(prompt,self_name,4)
    if response == 6 then
      local directory = ({reaper.get_action_context()})[2]:sub(1,({reaper.get_action_context()})[2]:find("\\[^\\]*$"))

      -- Remove old scripts from actions list, delete files
      local a = 0
      repeat
        local dir_file = reaper.EnumerateFiles( directory, a )
        if dir_file:find("acendan_Open web interface") then
          reaper.AddRemoveReaScript( false, 0,  directory .. dir_file, false )
          local ok, msg = os.remove (directory .. dir_file)
        end
        a = a + 1
      until not reaper.EnumerateFiles( directory, a )

      -- Generate scripts for opening web interfaces
      for idx, name in pairs(script_names) do
        local filepath = directory .. name
        local file = io.open(filepath,"w")
        file:write("-- This script was automatically generated by acendan_Auto generate scripts to open web interfaces\n")
        file:write("-- Aaron Cendan - August 2020\n")
        file:write(script_ports[idx])
        file:close()
        if idx < #script_names then
          reaper.AddRemoveReaScript( true, 0, filepath, false )
        else
          -- Commit actions list changes on last addition
          reaper.AddRemoveReaScript( true, 0, filepath, true )
        end
      end
      
      -- Filter actions list for new scripts
      filterActionsList("acendan open web interface")
    end
  
  else
    -- NO WEB INTERFACES FOUND
    msg("No web interfaces found in REAPER.ini! Go to Options > Preferences > Control/OSC/Web to set up web interfaces.")
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
  reaper.MB(msg, self_name, 0)
end

-- Filter actions list for scripts or search term
function filterActionsList(search)
  if reaper.APIExists("JS_Window_Find")then;
    reaper.ShowActionList();
    local winHWND = reaper.JS_Window_Find(reaper.JS_Localize("Actions", "common"),true);
    local filter_Act = reaper.JS_Window_FindChildByID(winHWND,1324);
    reaper.JS_Window_SetTitle(filter_Act,search);
  end
end

-- Convert file input to table, each line = new entry // returns Table
function fileToTable(filename)
  local ret, num_webs = reaper.BR_Win32_GetPrivateProfileString( "reaper", "csurf_cnt", "", filename )
  local t = {}
  if ret then
    for i = 0, num_webs do
      local ret, web_int = reaper.BR_Win32_GetPrivateProfileString( "reaper", "csurf_" .. i, "", filename )
      table.insert(t, web_int)
    end
  end
  return t
end

-- Get localhost port from reaper.ini file line
function getPort(line)
  local port = line:sub(line:find(" ")+3,line:find("'")-2)
  return port
end

-- Get localhost port from reaper.ini file line
function getName(line)
  local name = line:sub(1,line:find(".html")-1)
  name = name:sub(name:find("'[^']*$")+1)
  name = name:gsub("acendan_","")
  return name
end


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
reaper.PreventUIRefresh(1)

generateScripts()

reaper.PreventUIRefresh(-1)

reaper.UpdateArrange()
