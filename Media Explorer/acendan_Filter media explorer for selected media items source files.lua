-- @description Filter Media Explorer
-- @author Aaron Cendan
-- @version 1.2
-- @metapackage
-- @provides
--   [main] . > acendan_Filter media explorer for selected media items source files.lua
-- @link https://aaroncendan.me
-- @about
--  This script requires "Update search only when enter key pressed" to be disabled in the Media Explorer section of the Actions list.
--
--  Shoutouts to cfillion, nofish, and x-raym for the help with getting this script setup!
-- @changelog
--   # Update LuaUtils path with case sensitivity for Linux

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Get this script's name and directory
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local script_directory = ({reaper.get_action_context()})[2]:sub(1,({reaper.get_action_context()})[2]:find("\\[^\\]*$"))

-- Init string to search
local search_string = ""

-- Load lua utilities
acendan_LuaUtils = reaper.GetResourcePath()..'/Scripts/ACendan Scripts/Development/acendan_Lua Utilities.lua'
if reaper.file_exists( acendan_LuaUtils ) then dofile( acendan_LuaUtils ); if not acendan or acendan.version() < 5.8 then acendan.msg('This script requires a newer version of ACendan Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"ACendan Lua Utilities"); return end else reaper.ShowConsoleMsg("This script requires ACendan Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'ACendan Lua Utilities'"); return end

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
        local pcm_source = reaper.GetMediaItemTake_Source(take)
        local name = ""
        name = reaper.GetMediaSourceFileName(pcm_source, name)
        if name:find("\\") then name = name:match("[^\\]+$") elseif name:find("/") then name = name:match("[^/]+$") end
        if name ~= "" then
          if search_string ~= "" then
            search_string = search_string .. " OR " .. tostring(name)
          else
            search_string = tostring(name)
          end
        end
      end
    end
    
    acendan.filterMediaExplorer(search_string)

  else
    reaper.MB("No items selected!","Media Explorer Filter",0)
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
