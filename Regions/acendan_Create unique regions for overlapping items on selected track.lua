-- @description Create Unique Regions Overlapping Items
-- @author Aaron Cendan
-- @version 1.3
-- @metapackage
-- @provides
--   [main] . > acendan_Create unique regions for overlapping items on selected tracks.lua
-- @link https://ko-fi.com/acendan_
-- @about
--   # Creates unique regions for each bundle of overlapping items on the selected track
-- @changelog
--   # Add support for items within time selection. Lua's total lack of a 'continue' statement is just super duper awesome.

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~ USER CONFIG - EDIT ME ~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Set this to 'true' in order to assign regions to the selected track(s), their shared parent track, or the master in the RRM
set_region_render_matrix_to_tracks = true

-- Set this to 'true' in order to assign newly created region names to the *first* item that was used to create the region
-- This should correspond to the first overlapping item on the earliest track on the timeline
use_first_item_name = true

-- Set this to 'true' in order to assign newly created regions color to the *first* item color that was used to create the region
use_first_item_color = true

-- Set this to 'true' to only process items within the time selection on the selected tracks
only_items_time_selection = false

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Get this script's name and directory
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local script_directory = ({reaper.get_action_context()})[2]:sub(1,({reaper.get_action_context()})[2]:find("\\[^\\]*$"))

-- Load lua utilities
acendan_LuaUtils = reaper.GetResourcePath()..'/scripts/ACendan Scripts/Development/acendan_Lua Utilities.lua'
if reaper.file_exists( acendan_LuaUtils ) then dofile( acendan_LuaUtils ); if not acendan or acendan.version() < 4.4 then acendan.msg('This script requires a newer version of ACendan Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"ACendan Lua Utilities"); return end else reaper.ShowConsoleMsg("This script requires ACendan Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'ACendan Lua Utilities'"); return end


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function main()
  local num_sel_tracks = reaper.CountSelectedTracks( 0 )
  if num_sel_tracks > 0 then
    local start_time_sel, end_time_sel = reaper.GetSet_LoopTimeRange(0,0,0,0,0);
    
    -- Get shared parent track
    if set_region_render_matrix_to_tracks then
      if num_sel_tracks == 1 then
        shared_parent_track = reaper.GetSelectedTrack(0,0)
      else
        for k = 0, num_sel_tracks-1 do
          local track = reaper.GetSelectedTrack(0,k)
          local parent_track = reaper.GetParentTrack(track)
          if not parent_track then parent_track =  reaper.GetMasterTrack( 0 ) end
          if k == 0 then 
            shared_parent_track = parent_track
          else
            if reaper.GetTrackGUID(parent_track) ~= reaper.GetTrackGUID(shared_parent_track) then 
              shared_parent_track = reaper.GetMasterTrack( 0 ) 
              break
            end
          end
        end
      end
    end
    
    -- Loop through items on selected tracks and create regions
    for k = 0, num_sel_tracks-1 do
      local track = reaper.GetSelectedTrack(0,k)
      local num_track_items = reaper.CountTrackMediaItems(track)
      if num_track_items > 0 then
        for i=0, num_track_items - 1 do
          local item = reaper.GetTrackMediaItem( track, i )
          local take = reaper.GetActiveTake(item)
          local item_name = take and select(2,reaper.GetSetMediaItemTakeInfo_String(take,"P_NAME","",false)) or ""
          local item_start_pos = reaper.GetMediaItemInfo_Value(item,"D_POSITION")
          local item_end_pos = item_start_pos + reaper.GetMediaItemInfo_Value(item,"D_LENGTH")
          local item_color = reaper.GetDisplayedMediaItemColor(item)
          
          -- Check if item is within time selection
          local skip_item = false
          if only_items_time_selection then
            if item_end_pos < start_time_sel or item_start_pos > end_time_sel then
              skip_item = true
            end
          end
          
          -- Check if there is a region overlapping this item already
          -- Loop through all regions
          local overlapping_region_idx = -1
          local ret, num_markers, num_regions = reaper.CountProjectMarkers( 0 )
          local num_total = num_markers + num_regions
          if num_regions > 0 and not skip_item then
            local j = 0
            while j < num_total do
              local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, j )
              -- Check if it's a region and it's bounds are within the current media item's
              -- Start of region happens before the end of the item AND end of region happens after start of item
              if isrgn and pos < item_end_pos and rgnend > item_start_pos then
                --acendan.dbg("OVERLAPPING REGION: Item #" .. tostring(i+1) .. " - Region #" .. tostring(j+1))
                overlapping_region_idx = markrgnindexnumber
                
                -- Stretch the end of the overlapping region to the end of the item
                if item_end_pos > rgnend then
                  rgnend = item_end_pos
                  reaper.SetProjectMarker3(0, markrgnindexnumber, isrgn, pos, rgnend, name, color)
                end
                
                -- Stretch the start of the overlapping region to the start of the item
                if item_start_pos < pos then
                  pos = item_start_pos
                  reaper.SetProjectMarker3(0, markrgnindexnumber, isrgn, pos, rgnend, name, color)
                end
                
                -- Set name if currently blank
                if name == "" and use_first_item_name then
                  reaper.SetProjectMarker3(0, markrgnindexnumber, isrgn, pos, rgnend, item_name, color)
                end
                
                -- Set region to track in RRM
                if set_region_render_matrix_to_tracks and shared_parent_track then reaper.SetRegionRenderMatrix(0, overlapping_region_idx, shared_parent_track, 1) end
              end
              j = j + 1
            end
          end
          
          -- Check if there was no overlapping region, then create region at item bounds...
          if overlapping_region_idx == -1 and not skip_item then
            -- Global settings
            if not use_first_item_name then item_name = "" end
            if not use_first_item_color then item_color = 0 end
            
            -- Create region
            local new_region_idx = reaper.AddProjectMarker2(0, true, item_start_pos, item_end_pos, item_name, 0, item_color) 
            
            -- Assign track in RRM
            if set_region_render_matrix_to_tracks and shared_parent_track then reaper.SetRegionRenderMatrix(0, new_region_idx, shared_parent_track, 1) end
          end
          
        end
      end
    end -- End loop through selected tracks
    
  else
    acendan.msg("No track selected!")
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
