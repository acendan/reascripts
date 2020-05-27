-- @description Open Saved URL By Track Name
-- @author Aaron Cendan
-- @version 1.0
-- @about
--   By Aaron Cendan - May 2020

function openURL() -- local (i, j, item, take, track)


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
	
	if ret == 1 then		-- URL ALREADY STORED, OPEN SITE
		--reaper.ShowConsoleMsg("Retrieved Stored URL: " .. stored_URL)
		local OS = reaper.GetOS()
		if OS == "OSX32" or OS == "OSX64" then
			--os.execute('open "" "' .. stored_URL .. '"')
			reaper.CF_ShellExecute(stored_URL)
		else
			--os.execute('start "" "' .. stored_URL .. '"')
			reaper.CF_ShellExecute(stored_URL)
		end
		
	else					-- NO URL STORED, PROMPT USER FOR URL
	
		-- Store URL from input to project based on track name
		local ret,URL = reaper.GetUserInputs( "Save URL For Track: " .. cur_track, 1,
						   "Paste Destination URL, extrawidth=200","")
		if not ret then return end
			
		reaper.SetProjExtState(0, "URL", cur_track, URL)
		--reaper.ShowConsoleMsg("Stored the URL: " .. URL)
		
		if URL then 
			local OS = reaper.GetOS()
			if OS == "OSX32" or OS == "OSX64" then
				--os.execute('open "" "' .. URL .. '"')
				reaper.CF_ShellExecute(URL)
			else
				--os.execute('start "" "' .. URL .. '"')
				reaper.CF_ShellExecute(URL)
			end
		end
	end

	reaper.Undo_EndBlock("Open Saved URL", -1) -- End of the undo block. Leave it at the bottom of your main function.

end

reaper.PreventUIRefresh(1) -- Prevent UI refreshing. Uncomment it only if the script works.

openURL() -- Execute your main function

reaper.PreventUIRefresh(-1) -- Restore UI Refresh. Uncomment it only if the script works.

reaper.UpdateArrange() -- Update the arrangement (often needed)