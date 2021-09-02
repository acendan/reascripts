-- @description acendan_Create unique regions for selected items and link to parent track in RRM
-- @author Aaron Cendan
-- @version 1.3
-- @metapackage
-- @provides
--   [main] . > acendan_Create unique regions for selected items and link to parent track in RRM.lua
-- @link https://aaroncendan.me
-- @changelog
--   # Fixed naming w folder tracks extra underscore

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~ USER CONFIG - EDIT ME ~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Name region with folder track structure. If true, then separator will be used between parent tracks when naming regions.
local name_w_folders = true
local separator = "_"

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function addToRRM()

	reaper.Undo_BeginBlock()

	selected_items_count = reaper.CountSelectedMediaItems(0)
	
	for i = 0, selected_items_count-1  do
		item = reaper.GetSelectedMediaItem(0, i)
		take = reaper.GetActiveTake(item)

		if take ~= nil then
			take_name = reaper.GetTakeName(take)
			
			local startPos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
			local endPos = reaper.GetMediaItemInfo_Value(item, "D_LENGTH") + startPos
			local take_color = reaper.GetDisplayedMediaItemColor2( item, take )
			
			-- Get parent track
			local item_parent_track = reaper.GetParentTrack(reaper.GetMediaItem_Track(item))
			if not item_parent_track then item_parent_track =  reaper.GetMasterTrack( 0 ) end
			
			-- Get track name from item
			track =  reaper.GetMediaItemTrack( item )
			retval, trackName = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "test", false)
			
			-- Build region
			if name_w_folders and item_parent_track then
			  local name_incl_folders = ""
			  local ret_prnt, parent_track_name = reaper.GetSetMediaTrackInfo_String(item_parent_track, "P_NAME", "", false)
			  
			  if parent_track_name ~= "" and trackName ~= "" then
				name_incl_folders = parent_track_name .. separator .. trackName
			  elseif parent_track_name == "" and trackName ~= "" then
				name_incl_folders = trackName
			  elseif parent_track_name ~= "" and trackName == "" then  
				name_incl_folders = parent_track_name
			  end
			  
			  -- While loop through parents
			  local cur_parent = item_parent_track
			  while reaper.GetParentTrack(cur_parent) do
			    cur_parent = reaper.GetParentTrack(cur_parent)
			    local ret_curr_prnt, curr_prnt_trck_name = reaper.GetSetMediaTrackInfo_String(cur_parent, "P_NAME", "", false)
			    if ret_curr_prnt and curr_prnt_trck_name ~= "" then
				 name_incl_folders = curr_prnt_trck_name .. separator .. name_incl_folders
			    end
			  end
			  
			  regionID = reaper.AddProjectMarker2(0, true, startPos, endPos, name_incl_folders, 0, take_color)
			  reaper.SetRegionRenderMatrix(0, regionID, item_parent_track, 1)
			  
			else
				if not retval or trackName == "" then trackName = take_name end
				
				regionID = reaper.AddProjectMarker2(0, true, startPos, endPos, trackName, 0, take_color)
				reaper.SetRegionRenderMatrix(0, regionID, item_parent_track, 1)
			end
		end
	end
	
	reaper.Undo_EndBlock("Add Selected Items to RRM", -1) -- End of the undo block. Leave it at the bottom of your main function.

end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
reaper.PreventUIRefresh(1)

addToRRM()

reaper.PreventUIRefresh(-1)

reaper.UpdateArrange()
