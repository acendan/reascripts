-- @description Rename Regions Nearest Markers
-- @author Aaron Cendan
-- @version 1.0
-- @metapackage
-- @provides
--   [main] .
-- @link https://ko-fi.com/acendan_

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Get this script's name and directory
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local script_directory = ({reaper.get_action_context()})[2]:sub(1,({reaper.get_action_context()})[2]:find("\\[^\\]*$"))

-- Load lua utilities
acendan_LuaUtils = reaper.GetResourcePath()..'/scripts/ACendan Scripts/Development/acendan_Lua Utilities.lua'
if reaper.file_exists( acendan_LuaUtils ) then dofile( acendan_LuaUtils ); if not acendan or acendan.version() < 4.4 then acendan.msg('This script requires a newer version of ACendan Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"ACendan Lua Utilities"); return end else reaper.ShowConsoleMsg("This script requires ACendan Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'ACendan Lua Utilities'"); return end


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function main()
  -- Loop through all regions
  local ret, num_markers, num_regions = reaper.CountProjectMarkers( 0 ) 
  local num_total = num_markers + num_regions
  if num_regions > 0 then
    local i = 0
    while i < num_total do
	  local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, i )
	  if isrgn then
	    -- Gets the first marker starting from the end of the region. There may be a better way to do this,
	    --    as multiple markers within a region will pick the last marker. Potentially unintuitive for end-users.
	    local nearest_marker_idx = reaper.GetLastMarkerAndCurRegion(0, rgnend)
	    if nearest_marker_idx >= 0 then 
		 local _, _, _, _, nearest_marker_name = reaper.EnumProjectMarkers(nearest_marker_idx)
		 reaper.SetProjectMarker3( 0, markrgnindexnumber, isrgn, pos, rgnend, nearest_marker_name, color )
	    end
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
