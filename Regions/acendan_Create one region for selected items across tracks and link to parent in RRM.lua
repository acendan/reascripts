-- @description Create Region for Selected Items Across Tracks
-- @author Aaron Cendan
-- @version 1.0
-- @metapackage
-- @provides
--   [main] . > acendan_Create one region for selected items across tracks and link to parent in RRM.lua
-- @link https://aaroncendan.me
-- @about
--   # Create Region for Selected Items Across Tracks
--   By Aaron Cendan - July 2020
--
--   ### About this script...
--   * Select some items in a folder then run the script. 
--   * A region will be created and linked to the parent track of the folder.

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~ USER CONFIG - EDIT ME ~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Optional: Add extra space at end of regions (in seconds)
local additional_space = 0



-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Get script name for undo text and extracting numbers/other info, if needed
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")

-- Init region bounds
local sel_items_start = math.huge
local sel_items_end = 0
      
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function main()
  -- Loop through selected items
  local num_sel_items = reaper.CountSelectedMediaItems(0)
  if num_sel_items > 0 then
    local shared_parent_guid
    local shared_parent = true
    local parent_is_master = false
    
    for i=0, num_sel_items - 1 do
      -- Get item info
      local item = reaper.GetSelectedMediaItem( 0, i )
      local item_start = reaper.GetMediaItemInfo_Value( item, "D_POSITION")
      local item_len = reaper.GetMediaItemInfo_Value( item, "D_LENGTH")
      local item_end = item_start + item_len
      
      -- Adjust region bounds if necessary
      if item_start < sel_items_start then sel_items_start = item_start end
      if item_end > sel_items_end then sel_items_end = item_end end
      
      -- Check if items share a parent folder track
      local item_parent_track = reaper.GetParentTrack(reaper.GetMediaItem_Track(item))
      if not item_parent_track then item_parent_track =  reaper.GetMasterTrack( 0 ); parent_is_master = true end
      
      local item_parent_track_guid = reaper.GetTrackGUID(item_parent_track)
      if i == 0 then 
        shared_parent_guid = item_parent_track_guid 
      else
        if item_parent_track_guid ~= shared_parent_guid then shared_parent = false end
      end
    end
    
    -- If items share parent
    if shared_parent then
      if not parent_is_master then
        local parent_track = reaper.BR_GetMediaTrackByGUID( 0, shared_parent_guid )
        local parent_track_color =  reaper.GetTrackColor( parent_track )
        local retval, parent_track_name = reaper.GetSetMediaTrackInfo_String(parent_track, "P_NAME", "", false)
              
        if sel_items_start < math.huge then
          if retval then
            regionID = reaper.AddProjectMarker2(0, true, sel_items_start, sel_items_end + additional_space, parent_track_name, 0, parent_track_color)
            reaper.SetRegionRenderMatrix(0, regionID, parent_track, 1)
          else
            regionID = reaper.AddProjectMarker2(0, true, sel_items_start, sel_items_end + additional_space, "", 0, parent_track_color)
            reaper.SetRegionRenderMatrix(0, regionID, parent_track, 1)
          end
        end
      else
        regionID = reaper.AddProjectMarker2(0, true, sel_items_start, sel_items_end + additional_space, "", 0, 0)
        reaper.SetRegionRenderMatrix(0, regionID, reaper.GetMasterTrack( 0 ), 1)
      end
          
    else
      local response = reaper.MB("The selected items don't share the same parent folder.\n\nWould you still like to create a region?", "Region from Selected Items", 4)
      -- If yes, create a region
      if response == 6 then
        regionID = reaper.AddProjectMarker2(0, true, sel_items_start, sel_items_end + additional_space, "", 0, 0)
      end
    end
    
  else
    msg("No items selected!")
  end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ UTILITIES ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Deliver messages and add new line in console
function dbg(dbg)
  reaper.ShowConsoleMsg(dbg .. "\n")
end

-- Deliver messages using message box
function msg(msg)
  reaper.MB(msg, "Region from Selected Items", 0)
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
