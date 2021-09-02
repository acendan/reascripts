-- @description Create Region for Selected Items Across Tracks
-- @author Aaron Cendan
-- @version 1.3
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
-- @changelog
--   # Fixed naming w folder tracks extra underscore

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~ USER CONFIG - EDIT ME ~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Add extra space at end of regions (in seconds)
local additional_space = 0

-- Name region with folder track structure. If true, then separator will be used between parent tracks when naming regions.
local name_w_folders = true
local separator = "_"

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Get script name for undo text and extracting numbers/other info, if needed
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")

-- Init region bounds
local sel_items_start = math.huge
local sel_items_end = 0

-- Init all same track check
local same_track_guid
local all_same_track = true
      
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
    local first_named_track = ""
    
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
      
      -- Get track name from item
      track =  reaper.GetMediaItemTrack( item )
      tname_ret, trackName = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "test", false)
      if tname_ret and first_named_track == "" then first_named_track = trackName end
      
      -- Check to see if items are all on same track
      local current_track_guid = reaper.GetTrackGUID(track)
      if i == 0 then 
        same_track_guid = current_track_guid
      else
        if current_track_guid ~= same_track_guid then all_same_track = false end 
      end
    end
    
    -- If items share parent
    if shared_parent then
      if not parent_is_master then
        local parent_track = reaper.BR_GetMediaTrackByGUID( 0, shared_parent_guid )
        local parent_track_color =  reaper.GetTrackColor( parent_track )
        local ret_prnt, parent_track_name = reaper.GetSetMediaTrackInfo_String(parent_track, "P_NAME", "", false)
              
        if sel_items_start < math.huge then
          -- Naming priority: first track with a name, then parent, then blank
          if name_w_folders and ret_prnt then
            
            local name_incl_folders = ""
            if parent_track_name ~= "" and first_named_track ~= "" then
              name_incl_folders = parent_track_name .. separator .. first_named_track
            elseif parent_track_name == "" and first_named_track ~= "" then
              name_incl_folders = first_named_track
            elseif parent_track_name ~= "" and first_named_track == "" then  
              name_incl_folders = parent_track_name
            end
            
            -- While loop through parents
            local cur_parent = parent_track
            while reaper.GetParentTrack(cur_parent) do
              cur_parent = reaper.GetParentTrack(cur_parent)
              local ret_curr_prnt, curr_prnt_trck_name = reaper.GetSetMediaTrackInfo_String(cur_parent, "P_NAME", "", false)
              if ret_curr_prnt and curr_prnt_trck_name ~= "" then
                name_incl_folders = curr_prnt_trck_name .. separator .. name_incl_folders
              end
            end


            --msg(name_incl_folders)
            
            regionID = reaper.AddProjectMarker2(0, true, sel_items_start, sel_items_end + additional_space, name_incl_folders, 0, parent_track_color)
            reaper.SetRegionRenderMatrix(0, regionID, parent_track, 1)
          
          elseif all_same_track and first_named_track ~= "" then
            regionID = reaper.AddProjectMarker2(0, true, sel_items_start, sel_items_end + additional_space, first_named_track, 0, parent_track_color)
            reaper.SetRegionRenderMatrix(0, regionID, parent_track, 1)
          else
            if ret_prnt then
              regionID = reaper.AddProjectMarker2(0, true, sel_items_start, sel_items_end + additional_space, parent_track_name, 0, parent_track_color)
              reaper.SetRegionRenderMatrix(0, regionID, parent_track, 1)
            else
              regionID = reaper.AddProjectMarker2(0, true, sel_items_start, sel_items_end + additional_space, "", 0, parent_track_color)
              reaper.SetRegionRenderMatrix(0, regionID, parent_track, 1)
            end
          end
        end
        
      -- Parent track is master track
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
