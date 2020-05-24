--[[
 * Find Replace in Region Names
 * By Aaron Cendan
 * May 2020
 * Prompts user to replace part of a region's name with
 * new text if region name contains search criteria.
--]]

function findReplace() -- local (i, j, item, take, track)

	reaper.Undo_BeginBlock() -- Begining of the undo block. Leave it at the top of your main function.

	local retval, num_markers, num_regions = reaper.CountProjectMarkers( 0 )
	local num_total = num_markers + num_regions

	if num_regions > 0 then
		
		ret, search_string, replace_string, search_field = getSearchInfo()
		if not ret then return end
		
		-- Confirm is valid search, search info not blank
		if search_string and replace_string and search_field then
		
			if search_field == "/p" then
				searchFullProject(num_total, search_string, replace_string)
				
			elseif search_field == "/t" then
				searchTimeSelection(num_total, search_string, replace_string)
			
			--Ideally it would be possible to find/replace in render matrix, see function below:
			--elseif search_field == "/m" then
				--searchSelectedRegions(num_total, search_string, replace_string)
				
			else
				reaper.ShowMessageBox("Search field must be exactly /p or /t","Find/Replace", 0)
				findReplace()
			end
		else
			reaper.ShowMessageBox("Search fields cannot be empty!" .. "\n" .. "\n" .. "If you want to Find or Replace blank region names, then use:" .. "\n" .. "/blank","Find/Replace", 0)
			findReplace()
		end
	else
		reaper.ShowMessageBox("Project has no regions!","Find/Replace", 0)
		
	end

	reaper.Undo_EndBlock("Find and Replace", -1) -- End of the undo block. Leave it at the bottom of your main function.

end

function getSearchInfo()
	-- Check for previous search field
	local ret, prev_field =  reaper.GetProjExtState(0, "FindReplaceStorage", "PrevSearchField")
	
	if ret == 1 and prev_field == "/p" or prev_field == "/t" then --or prev_field == "/m" then 	-- If valid search field used previously, use as default
		-- Store user input for search and replace strings
		ret,user_input = reaper.GetUserInputs( "Find & Replace in Region Names",  3,
						   "Text to Search For,Text to Replace With,Project /p or Time Selection /t,extrawidth=100",",,"..prev_field)
		search_string, replace_string, search_field = user_input:match("([^,]+),([^,]+),([^,]+)")
		-- Save new search field
		if search_field then
			reaper.SetProjExtState(0, "FindReplaceStorage", "PrevSearchField",search_field)
		end
	else				-- Region search not used yet in this project, use Project (/p) field as default
		ret,user_input = reaper.GetUserInputs( "Find & Replace in Region Names",  3,
						   "Text to Search For,Text to Replace With,Project /p or Time Selection /t,extrawidth=100",",,/p")
		search_string, replace_string, search_field = user_input:match("([^,]+),([^,]+),([^,]+)")
		if search_field then
			reaper.SetProjExtState(0, "FindReplaceStorage", "PrevSearchField",search_field)
		end
	end

	return ret, search_string, replace_string, search_field
end

function searchFullProject(num_total, search_string, replace_string)
	-- Loop through all regions in project
	local i = 0
	while i < num_total do		
		local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, i )
		if isrgn then
			if search_string ~= "/blank" then
				if string.find(name, search_string) then
					if replace_string ~= "/blank" then
						local new_name = string.gsub( name, search_string, replace_string)
						reaper.SetProjectMarkerByIndex( 0, i, isrgn, pos, rgnend, markrgnindexnumber, new_name, color )
					else
						reaper.DeleteProjectMarker( 0, markrgnindexnumber, isrgn )
						reaper.AddProjectMarker2( 0, isrgn, pos, rgnend, '', markrgnindexnumber, color )
					end				
				end
			else
				if name == "" then
					if replace_string ~= "/blank" then
						local new_name = replace_string
						reaper.SetProjectMarkerByIndex( 0, i, isrgn, pos, rgnend, markrgnindexnumber, new_name, color )
					end	
				end
			end
		end
		i = i + 1
	end
end

function searchTimeSelection(num_total, search_string, replace_string)
	-- Loop through all regions in time selection
	StartTimeSel, EndTimeSel = reaper.GetSet_LoopTimeRange(0,0,0,0,0);
	-- Confirm valid time selection
	if StartTimeSel ~= EndTimeSel then
		local i = 0
		while i < num_total do		
			local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, i )
			if isrgn then
				if pos >= StartTimeSel and rgnend <= EndTimeSel then
					if search_string ~= "/blank" then
						if string.find(name, search_string) then
							if replace_string ~= "/blank" then
								local new_name = string.gsub( name, search_string, replace_string)
								reaper.SetProjectMarkerByIndex( 0, i, isrgn, pos, rgnend, markrgnindexnumber, new_name, color )
							else
								reaper.DeleteProjectMarker( 0, markrgnindexnumber, isrgn )
								reaper.AddProjectMarker2( 0, isrgn, pos, rgnend, '', markrgnindexnumber, color )
							end				
						end
					else
						if name == "" then
							if replace_string ~= "/blank" then
								local new_name = replace_string
								reaper.SetProjectMarkerByIndex( 0, i, isrgn, pos, rgnend, markrgnindexnumber, new_name, color )
							end	
						end
					end
				end
			end
			i = i + 1
		end
	else
		reaper.ShowMessageBox("To Find & Replace within a time selection, you are going to need a time selection!","Find/Replace", 0)
	end

end

function searchSelectedRegions(num_total, search_string, replace_string)
	-- Ideally, it would be possible to run this Find/Replace functionality on regions
	-- that are selected in the Region Render Matrix, but unfortunately, that info is not
	-- exposed via the API as of Reaper v6.10.
end

reaper.PreventUIRefresh(1) -- Prevent UI refreshing. Uncomment it only if the script works.

findReplace() -- Execute your main function

reaper.PreventUIRefresh(-1) -- Restore UI Refresh. Uncomment it only if the script works.

reaper.UpdateArrange() -- Update the arrangement (often needed)
