-- @description Region Color Edit Cursor
-- @author Aaron Cendan
-- @version 1.1
-- @metapackage
-- @provides
--   [main] . > acendan_Set region color near edit cursor to SWS custom color 1.lua
--   [main] . > acendan_Set region color near edit cursor to SWS custom color 2.lua
--   [main] . > acendan_Set region color near edit cursor to SWS custom color 3.lua
--   [main] . > acendan_Set region color near edit cursor to SWS custom color 4.lua
--   [main] . > acendan_Set region color near edit cursor to SWS custom color 5.lua
--   [main] . > acendan_Set region color near edit cursor to SWS custom color 6.lua
--   [main] . > acendan_Set region color near edit cursor to SWS custom color 7.lua
--   [main] . > acendan_Set region color near edit cursor to SWS custom color 8.lua
--   [main] . > acendan_Set region color near edit cursor to SWS custom color 9.lua
--   [main] . > acendan_Set region color near edit cursor to SWS custom color 10.lua
--   [main] . > acendan_Set region color near edit cursor to SWS custom color 11.lua
--   [main] . > acendan_Set region color near edit cursor to SWS custom color 12.lua
--   [main] . > acendan_Set region color near edit cursor to SWS custom color 13.lua
--   [main] . > acendan_Set region color near edit cursor to SWS custom color 14.lua
--   [main] . > acendan_Set region color near edit cursor to SWS custom color 15.lua
--   [main] . > acendan_Set region color near edit cursor to SWS custom color 16.lua
-- @link https://ko-fi.com/acendan_
-- @about
--   # Set regions at edit cursor to SWS custom color!
-- @changelog
--   # Minor optimization

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~ USER CONFIG - EDIT ME ~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Get this script's name and directory
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local script_directory = ({reaper.get_action_context()})[2]:sub(1,({reaper.get_action_context()})[2]:find("\\[^\\]*$"))

-- Load lua utilities
acendan_LuaUtils = reaper.GetResourcePath()..'/scripts/ACendan Scripts/Development/acendan_Lua Utilities.lua'
if reaper.file_exists( acendan_LuaUtils ) then dofile( acendan_LuaUtils ); if not acendan or acendan.version() < 5.7 then acendan.msg('This script requires a newer version of ACendan Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"ACendan Lua Utilities"); return end else reaper.ShowConsoleMsg("This script requires ACendan Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'ACendan Lua Utilities'"); return end


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function main()
  -- Get SWS custom color from script name
  local sws_color_idx = acendan.extractNumberInScriptName(script_name) or 1
  local sws_color = acendan.getSWSCustomColor(sws_color_idx)
  
  -- Loop through regions at edit cursor
  local ret, num_markers, num_regions = reaper.CountProjectMarkers( 0 )
  local num_total = num_markers + num_regions
  if num_regions > 0 then
    local edit_cur_pos = reaper.GetCursorPosition()
    local i = 0
    while i < num_total do
      local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, i )
      if isrgn and pos <= edit_cur_pos and rgnend >= edit_cur_pos then
        reaper.SetProjectMarker3(0, markrgnindexnumber, isrgn, pos, rgnend, name, sws_color)
      end
      i = i + 1
    end
  else
    acendan.msg("Project has no regions!")
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
