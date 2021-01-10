-- @description UCS Renaming Tool Media Explorer Filter
-- @author Aaron Cendan
-- @version 4.2
-- @metapackage
-- @provides
--   [main] . > acendan_UCS Renaming Tool - Media Explorer Filter.lua
-- @link https://aaroncendan.me
-- @about
--   # Universal Category System (UCS) Renaming Tool
--   Developed by Aaron Cendan
--   https://aaroncendan.me
--   aaron.cendan@gmail.com
--
--   ### Notes
--   * This is just a helper script for the UCS Renaming Tool! It doesn't really do anything on it's own :)

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS FROM WEB INTERFACE ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Toggle for debugging UCS input with message box
local debug_UCS_Input = false

-- Retrieve stored projextstate data set by web interface
local ret_srch, ucs_srch = reaper.GetProjExtState( 0, "UCS_WebInterface", "searchMediaExplorer")


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~~~~~~~~~~~  
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~ Search Media Explorer ~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function searchMediaExplorer()

  reaper.Undo_BeginBlock()

  -- Convert rets to booleans for cleaner function-writing down the line
  ucsRetsToBool()
  
  -- Safety-net evaluation if any of category/subcategory/catID are invalid
  -- The web interface should never even trigger this ReaScript anyways if CatID is invalid
  if not ret_srch then do return end end
  
  -- Show message box with form inputs and respective ret bools. Toggle at top of script.
  if debug_UCS_Input then debugUCSInput() end

  -- Process search
  ucs_srch = ucs_srch:gsub(", ", " OR ")

  -- Search media explorer
  if reaper.APIExists("JS_Window_Find")then;
    local IDC_SEARCH = 0x3f7
    local WM_COMMAND = 0x111
    local CBN_EDITCHANGE = 5
    
    local mediaExplorer = reaper.OpenMediaExplorer( "", false )
    local winHWND = reaper.JS_Window_Find(reaper.JS_Localize("Media Explorer", "common"),true)
    local mediaExpFilter =  reaper.JS_Window_FindChildByID( winHWND, 1015 )
    local filtered = reaper.JS_Window_SetTitle(mediaExpFilter,ucs_srch)
    reaper.BR_Win32_SendMessage(mediaExplorer, WM_COMMAND, (CBN_EDITCHANGE<<16) | IDC_SEARCH, 0)
  else
    reaper.MB("This script requires the JS Reascript API. Please install it via ReaPack.\n\nExtensions > ReaPack > Browse Packages > js_ReaScriptAPI: API functions for ReaScripts","Missing JS ReaScript API", 0)  
  end

  reaper.Undo_EndBlock("UCS Search Media Explorer", -1)
end


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~ Rets to Bools ~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
function ucsRetsToBool()
  if ret_srch == 1 then ret_srch = true else ret_srch = false end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~ Debug UCS Input ~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
function debugUCSInput()
  reaper.MB("Search: "      .. ucs_srch .. " (" .. tostring(ret_srch) .. ")", "UCS Renaming Tool", 0)
end


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~ DO IT! ~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
searchMediaExplorer{}
