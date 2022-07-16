-- @description Rename Regions Nearest Markers
-- @author Aaron Cendan
-- @version 1.2
-- @metapackage
-- @provides
--   [main] .
-- @link https://ko-fi.com/acendan_
-- @changelog
--   # Update LuaUtils path with case sensitivity for Linux

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
  local preference = reaper.GetExtState("acendan_RenameRegionsMarkers","AllSelectedPref")
  if preference == "" then preference = "a" end
  
  -- Get user input
  local ret_input, user_input = reaper.GetUserInputs( "Rename Regions from Markers", 1, "All (a) or Selected Rgns (s),extrawidth=100", preference )
  if not ret_input then return end
  reaper.SetExtState("acendan_RenameRegionsMarkers","AllSelectedPref",user_input,true)
  
  
  if user_input == "s" then
	  -- Loop through selected regions
	  local sel_rgn_table = acendan.getSelectedRegions()
	  if sel_rgn_table then 
	    local ret, num_markers, num_regions = reaper.CountProjectMarkers( 0 )
	    local num_total = num_markers + num_regions
	    
	    for _, regionidx in pairs(sel_rgn_table) do 
		 local i = 0
		 while i < num_total do
		   local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, i )
		   if isrgn and markrgnindexnumber == regionidx then
			
			-- Gets the first marker starting from the end of the region. There may be a better way to do this,
			--    as multiple markers within a region will pick the last marker. Potentially unintuitive for end-users.
			local nearest_marker_idx = reaper.GetLastMarkerAndCurRegion(0, rgnend)
			if nearest_marker_idx >= 0 then 
			  local _, _, _, _, nearest_marker_name = reaper.EnumProjectMarkers(nearest_marker_idx)
			  reaper.SetProjectMarkerByIndex( 0, i, isrgn, pos, rgnend, markrgnindexnumber, nearest_marker_name, color )
			end
			break
		   end
		   i = i + 1
		 end
	    end
	  else
	    acendan.msg("No regions selected!\n\nPlease go to View > Region/Marker Manager to select regions.\n\n\nIf you are on Mac... sorry but there is a bug that prevents this script from working. Out of my control :(") 
	  end
  else         
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
