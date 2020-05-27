-- @description View Saved URL By Track Name
-- @author Aaron Cendan
-- @version 1.0
-- @about
--   By Aaron Cendan - May 2020

function viewURLs() -- local (i, j, item, take, track)


	reaper.Undo_BeginBlock() -- Begining of the undo block. Leave it at the top of your main function.

	local track_count = reaper.CountTracks(0)
	local console_header = 0
	local tracks_without_URLs = 0
	
	if track_count > 0 then
		local i = 0
		-- Loop through all tracks
		while i < track_count do
			local ret, track_name = reaper.GetSetMediaTrackInfo_String(reaper.GetTrack(0, i),"P_NAME","",0)
			local track_number = i + 1
			
			-- Check for Stored URL
			local ret, stored_URL =  reaper.GetProjExtState(0, "URL", track_name)		
			if ret == 1 then		-- URL STORED - PRINT TO CONSOLE			
				
				-- Display header message at top of console if there are stored tracks
				if console_header == 0 then
					reaper.ShowConsoleMsg("~~~ STORED URLS ~~~")
					reaper.ShowConsoleMsg("\n")
					console_header = 1
				end
				
				-- Display stored track info
				reaper.ShowConsoleMsg("Track #" .. track_number .. ": " .. track_name .. " - " .. stored_URL)
				reaper.ShowConsoleMsg("\n")
			else 
				-- Increment tracks without URL count (see below)
				tracks_without_URLs = tracks_without_URLs + 1
			end
			
			i = track_number
		end
	end
	
	-- Show message box if no saved URLs for current tracks
	if tracks_without_URLs == track_count then
		reaper.MB('Please select a track and run "Open Saved URL By Track Name.lua" to store a URL!',"No Stored URLs In Project",0)
	end

end

reaper.PreventUIRefresh(1) -- Prevent UI refreshing. Uncomment it only if the script works.

viewURLs() -- Execute your main function

reaper.PreventUIRefresh(-1) -- Restore UI Refresh. Uncomment it only if the script works.

reaper.UpdateArrange() -- Update the arrangement (often needed)