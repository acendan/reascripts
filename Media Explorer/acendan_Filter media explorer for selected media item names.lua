-- @description Filter Media Explorer
-- @author Aaron Cendan
-- @version 1.0
-- @metapackage
-- @provides
--   [main] . > acendan_Filter media explorer for selected media items names.lua
-- @link https://aaroncendan.me
-- @about
--  This script requires "Update search only when enter key pressed" to be disabled in the Media Explorer section of the Actions list.
--
--  Shoutouts to cfillion, nofish, and x-raym for the help with getting this script setup!

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Get this script's name and directory
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local script_directory = ({reaper.get_action_context()})[2]:sub(1,({reaper.get_action_context()})[2]:find("\\[^\\]*$"))

-- Init string to search
local search_string = ""


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function main()
  local num_sel_items = reaper.CountSelectedMediaItems(0)
  
  if num_sel_items > 0 then
    for i=0, num_sel_items - 1 do
      local item = reaper.GetSelectedMediaItem( 0, i )
      local take = reaper.GetActiveTake( item )
      if take ~= nil then 
        local ret, name = reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", "", false)
        if ret and name ~= "" then
          if search_string ~= "" then
            search_string = search_string .. " OR " .. tostring(name)
          else
            search_string = tostring(name)
          end
        end
      end
    end
    
    filterMediaExplorer(search_string)

  else
    reaper.MB("No items selected!","Media Explorer Filter",0)
  end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ UTILITIES ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Filter Media Explorer for files
function filterMediaExplorer(search)
  if reaper.APIExists("JS_Window_Find") then
    local IDC_SEARCH = 0x3f7
    local WM_COMMAND = 0x111
    local CBN_EDITCHANGE = 5
    
    local mediaExplorer = reaper.OpenMediaExplorer( "", false )
    local winHWND = reaper.JS_Window_Find(reaper.JS_Localize("Media Explorer", "common"),true)
    local mediaExpFilter =  reaper.JS_Window_FindChildByID( winHWND, 1015 )
    local filtered = reaper.JS_Window_SetTitle(mediaExpFilter,search)
    reaper.BR_Win32_SendMessage(mediaExplorer, WM_COMMAND, (CBN_EDITCHANGE<<16) | IDC_SEARCH, 0)
  else
    reaper.MB("This script requires the JS Reascript API. Please install it via ReaPack.\n\nExtensions > ReaPack > Browse Packages > js_ReaScriptAPI: API functions for ReaScripts","Missing JS ReaScript API", 0)  
  end
end
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock()

main()

reaper.Undo_EndBlock(script_name,-1)

reaper.PreventUIRefresh(-1)

reaper.UpdateArrange()
