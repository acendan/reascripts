-- @description acendan_Create unique regions for selected items and link to parent track in RRM
-- @author Aaron Cendan
-- @version 1.1
-- @metapackage
-- @provides
--   [main] . > acendan_Create unique regions for selected items and link to parent track in RRM.lua
-- @link https://aaroncendan.me

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
			if not retval or trackName == "" then trackName = take_name end
			
			-- Build region
			regionID = reaper.AddProjectMarker2(0, true, startPos, endPos, trackName, 0, take_color)
			reaper.SetRegionRenderMatrix(0, regionID, item_parent_track, 1)
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
