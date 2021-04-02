-- @description Save Stretch Markers
-- @author Aaron Cendan
-- @version 1.0
-- @metapackage
-- @provides
--   [main] . > acendan_Save stretch markers in selected items as named project markers.lua
-- @link https://aaroncendan.me
-- @about
--   * This script goes hand-in-hand with acendan_Restore stretch markers in selected items from named project markers.lua
--   * Select items with stretch markers then run this to convert them into project markers with a specific naming convention

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Get this script's name and directory
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local script_directory = ({reaper.get_action_context()})[2]:sub(1,({reaper.get_action_context()})[2]:find("\\[^\\]*$"))

-- Load lua utilities
acendan_LuaUtils = reaper.GetResourcePath()..'/scripts/ACendan Scripts/Development/acendan_Lua Utilities.lua'
if reaper.file_exists( acendan_LuaUtils ) then dofile( acendan_LuaUtils ); if not acendan or acendan.version() < 4.5 then acendan.msg('This script requires a newer version of ACendan Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"ACendan Lua Utilities"); return end else reaper.ShowConsoleMsg("This script requires ACendan Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'ACendan Lua Utilities'"); return end

-- Init tables
local proj_markers = {}
local init_items = {}

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function main()

  -- Check item(s) selected
  local num_sel_items = reaper.CountSelectedMediaItems(0)
  if num_sel_items > 0 then
    
    -- Save selected items to table
    acendan.saveSelectedItems(init_items)
    
    -- Create proj markers for stretch markers in items
    for i=1, num_sel_items do
      local item = init_items[i]
      local item_guid = reaper.BR_GetMediaItemGUID(item)
      
      -- Create proj markers for item stretch markers
      local ret, num_markers, num_regions = reaper.CountProjectMarkers( 0 )
      local num_total = num_markers + num_regions
      if num_markers > 0 then
        
        -- Clear marker table, store stretch markers as markers
        if #proj_markers > 0 then acendan.clearTable(proj_markers) end
        proj_markers = acendan.saveProjectMarkersTable()
        acendan.setOnlyItemSelected(item)
        reaper.Main_OnCommand(reaper.NamedCommandLookup("_BR_STRETCH_MARKERS_TO_MARKERS"),0) -- SWS/BR: Create project markers from stretch markers in selected items

        -- Rename new markers
        local ret, num_markers, num_regions = reaper.CountProjectMarkers( 0 )
        local num_total = num_markers + num_regions
        local j = 0
        while j < num_total do
          local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, j )
          if not isrgn then
            -- If project marker not found in saved table of indexes, then rename it and color yellow
            if not acendan.tableContainsVal(proj_markers, markrgnindexnumber) then
              reaper.SetProjectMarkerByIndex( 0, j, isrgn, pos, rgnend, markrgnindexnumber, item_guid .. ";" .. j, 25231359 )
            end
          end
          j = j + 1
        end
      else
        
        -- No markers in project yet
        acendan.setOnlyItemSelected(item)
        reaper.Main_OnCommand(reaper.NamedCommandLookup("_BR_STRETCH_MARKERS_TO_MARKERS"),0) -- SWS/BR: Create project markers from stretch markers in selected items

        -- Rename markers
        local ret, num_markers, num_regions = reaper.CountProjectMarkers( 0 )
        local num_total = num_markers + num_regions
        local j = 0
        while j < num_total do
          local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, j )
          if not isrgn then
            reaper.SetProjectMarkerByIndex( 0, j, isrgn, pos, rgnend, markrgnindexnumber, item_guid .. ";" .. j, 25231359 )
          end
          j = j + 1
        end
      
      end

      -- Remove item's stretch markers
      reaper.Main_OnCommand(41844, 0) -- Item: Remove all stretch markers
    end
  else
    acendan.msg("No items selected!")
  end

end


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock()

main()

if #init_items > 0 then acendan.restoreSelectedItems(init_items) end

reaper.Undo_EndBlock(script_name,-1)

reaper.PreventUIRefresh(-1)

reaper.UpdateArrange()
