-- @description Extend Selected Regions by Length
-- @author Aaron Cendan
-- @version 1.1
-- @metapackage
-- @provides
--   [main] . > acendan_Extend selected regions by length.lua
-- @link https://aaroncendan.me
-- @about
--   * Pretty self explanatory, input a number and it will extend your selected regions by that length. 
--   * Negative numbers will shrink regions!

local acendan_LuaUtils = reaper.GetResourcePath()..'/Scripts/ACendan Scripts/Development/acendan_Lua Utilities.lua'
if reaper.file_exists(acendan_LuaUtils) then dofile(acendan_LuaUtils); if not acendan or acendan.version() < 8.0 then acendan.msg('This script requires a newer version of ACendan Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"ACendan Lua Utilities"); return end else reaper.ShowConsoleMsg("This script requires ACendan Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'ACendan Lua Utilities'"); return end
local VSDEBUG = os.getenv("VSCODE_DBG_UUID") == "df3e118e-8874-49f7-ab62-ceb166401fb9" and dofile('C:/Users/Aaron/.vscode/extensions/antoinebalaine.reascript-docs-0.1.15/debugger/LoadDebug.lua') or nil

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
  -- Loop through selected regions
  local sel_rgn_table = acendan.getSelectedRegions()
  if sel_rgn_table then 
    local ret_input, extension = reaper.GetUserInputs( "Extend Regions By Length", 1, "Length (seconds)", "1.0" )
    if not ret_input then return end

    local ret, num_markers, num_regions = reaper.CountProjectMarkers( 0 )
    local num_total = num_markers + num_regions
    
    for _, regionidx in pairs(sel_rgn_table) do 
      local i = 0
      while i < num_total do
        local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, i )
        if isrgn and markrgnindexnumber == regionidx then
          reaper.SetProjectMarkerByIndex( 0, i, isrgn, pos, rgnend + extension, markrgnindexnumber, name, color )
          break
        end
        i = i + 1
      end
    end
  else
    acendan.msg("No regions selected!\n\nPlease go to View > Region/Marker Manager to select regions.\n\n\nIf you are on mac... sorry but there is a bug that prevents this script from working. Out of my control :(") 
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

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock()

main()

reaper.Undo_EndBlock(script_name,-1)

reaper.PreventUIRefresh(-1)

reaper.UpdateArrange()
