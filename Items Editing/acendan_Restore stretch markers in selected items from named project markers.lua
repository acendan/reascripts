-- @description Restore Stretch Markers
-- @author Aaron Cendan
-- @version 1.0
-- @metapackage
-- @provides
--   [main] . > acendan_Restore stretch markers in selected items from named project markers.lua
-- @link https://aaroncendan.me
-- @about
--   * This script goes hand-in-hand with acendan_Save stretch markers in selected items as named project markers.lua
--   * Run it to convert the named markers from that Save script into project markers in their relevant items

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Get this script's name and directory
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local script_directory = ({reaper.get_action_context()})[2]:sub(1,({reaper.get_action_context()})[2]:find("\\[^\\]*$"))

-- Load lua utilities
acendan_LuaUtils = reaper.GetResourcePath()..'/scripts/ACendan Scripts/Development/acendan_Lua Utilities.lua'
if reaper.file_exists( acendan_LuaUtils ) then dofile( acendan_LuaUtils ); if not acendan or acendan.version() < 4.5 then acendan.msg('This script requires a newer version of ACendan Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"ACendan Lua Utilities"); return end else reaper.ShowConsoleMsg("This script requires ACendan Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'ACendan Lua Utilities'"); return end

-- Init table
local marker_table = {}

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function main()

  -- Loop through all markers
  local ret, num_markers, num_regions = reaper.CountProjectMarkers( 0 )
  local num_total = num_markers + num_regions
  if num_markers > 0 then
    local i = 0
    while i < num_total do
      local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, i )
      if not isrgn then
        
        -- If saved stretch marker from acendan_Save stretch markers in selected items as named project markers.lua
        if color == 25231359 and name:find("};") then
          
          -- Get item from marker name GUID
          local item = reaper.BR_GetMediaItemByGUID(0,name:sub(1,name:find("}")))
          if item then
            local take = reaper.GetActiveTake(item)
            if take ~= nil then
  
              -- Insert stretch marker at marker pos in item
              local item_start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
              local stretch_pos = pos - item_start
              reaper.SetTakeStretchMarker(take, -1, stretch_pos)
            end
          end
          
          -- Add marker to table for deletion
          marker_table[#marker_table+1] = markrgnindexnumber
        end
      end
      i = i + 1
    end
    
    -- Delete all the relevant markers
    for _, idx in ipairs(marker_table) do
      reaper.DeleteProjectMarker(0,idx,false)
    end
    
  else
    acendan.msg("Project has no markers!")
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
