-- @description Clear Saved URL By Track Name
-- @author Aaron Cendan
-- @version 1.1
-- @about
--   By Aaron Cendan - May 2020

function clearURL() -- local (i, j, item, take, track)


	reaper.Undo_BeginBlock() -- Begining of the undo block. Leave it at the top of your main function.

	-- Confirm that a track is selected
	if not reaper.GetSelectedTrack(0, 0) then
		reaper.ShowConsoleMsg("You need to select a track first!")
		return
	end

	-- Save selected track name to local variable (cur_track)
	local ret, cur_track = reaper.GetSetMediaTrackInfo_String(reaper.GetSelectedTrack(0, 0), "P_NAME", "", 0)
	
	-- Check for Stored URL
	local ret, stored_URL =  reaper.GetProjExtState(0, "URL", cur_track)
	
	if ret == 1 then		-- URL ALREADY STORED, CLEAR URL
		
		local areyousure = reaper.MB(cur_track .. " - " .. stored_URL,"Clear Stored URL?", 4)
		
		if areyousure == 6 then
			-- Yes, clear URL
			reaper.SetProjExtState(0, "URL", cur_track, "")
		end
		
	else					-- NO URL STORED
		reaper.ShowConsoleMsg("No URL saved for this track: " .. cur_track)
		reaper.ShowConsoleMsg("\n")
		reaper.ShowConsoleMsg("\n")
		reaper.ShowConsoleMsg('To save a URL, run the script "acendan_Store and Open saved URL by track name.lua"')
		return
	end

	reaper.Undo_EndBlock("Clear Saved URL", -1) -- End of the undo block. Leave it at the bottom of your main function.

end

reaper.PreventUIRefresh(1) -- Prevent UI refreshing. Uncomment it only if the script works.

clearURL() -- Execute your main function

reaper.PreventUIRefresh(-1) -- Restore UI Refresh. Uncomment it only if the script works.

reaper.UpdateArrange() -- Update the arrangement (often needed)