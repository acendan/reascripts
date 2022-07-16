-- @description Import Region Names Text File
-- @author Aaron Cendan
-- @version 1.1
-- @metapackage
-- @provides
--   [main] .
-- @link https://ko-fi.com/acendan_
-- @about
--   # Imports region names from a text file where each new line is a new region name
-- @changelog
--   # Update LuaUtils path with case sensitivity for Linux

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
acendan_LuaUtils = reaper.GetResourcePath()..'/Scripts/ACendan Scripts/Development/acendan_Lua Utilities.lua'
if reaper.file_exists( acendan_LuaUtils ) then dofile( acendan_LuaUtils ); if not acendan or acendan.version() < 4.4 then acendan.msg('This script requires a newer version of ACendan Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"ACendan Lua Utilities"); return end else reaper.ShowConsoleMsg("This script requires ACendan Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'ACendan Lua Utilities'"); return end


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function main()

  local ret, num_markers, num_regions = reaper.CountProjectMarkers( 0 )
  local num_total = num_markers + num_regions
  if num_regions > 0 then
          
    -- File picker dialog
    retval, file = reaper.JS_Dialog_BrowseForOpenFiles( "Import Names From File", acendan.getProjDir(), "", "", false )
    if retval and file ~= '' then
      -- Init region iterator
      local i = 0
      
      -- Create and loop through names table from each line in file
      local names_table = acendan.fileToTable(file)
      for _, name in pairs(names_table) do
        if name ~= "" then
          -- Break out of while loop if a region is found and named
          local rgn_named = false
          
          -- Loop through remaining regions
          while i < num_total and not rgn_named do
            local _, isrgn, pos, rgnend, _, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, i )
            if isrgn then
              -- Rename
              reaper.SetProjectMarker3(0, markrgnindexnumber, isrgn, pos, rgnend, name, color)
              rgn_named = true
            end
            i = i + 1
          end
        end
      end
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
