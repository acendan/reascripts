-- @description Add regions for selected items to render matrix name from active take
-- @author Aaron Cendan
-- @version 1.1
-- @metapackage
-- @provides
--   [main] . > acendan_Add regions for selected items to render matrix name from active take.lua
-- @link https://aaroncendan.me

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


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

			track =  reaper.GetMediaItemTrack( item )
			retval, trackName = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "test", false)

			regionID = reaper.AddProjectMarker2(0, true, startPos, endPos, take_name, 0, 0)

			reaper.SetRegionRenderMatrix(0, regionID, track, 1)
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
