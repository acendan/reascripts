-- @description Create Unique Regions Overlapping Items
-- @author Aaron Cendan
-- @version 1.0
-- @metapackage
-- @provides
--   [main] .
-- @link https://ko-fi.com/acendan_
-- @about
--   # Creates unique regions for each bundle of overlapping items on the selected track
-- @changelog
--   + Initial release

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~ USER CONFIG - EDIT ME ~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


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
  local track = reaper.GetSelectedTrack(0,0)
  if track then
    reaper.SetOnlyTrackSelected(track)
    -- Loop through items on track
    local num_track_items = reaper.CountTrackMediaItems(track)
    if num_track_items > 0 then
      for i=0, num_track_items - 1 do
        local item = reaper.GetTrackMediaItem( track, i )
        local item_start_pos = reaper.GetMediaItemInfo_Value(item,"D_POSITION")
        local item_end_pos = item_start_pos + reaper.GetMediaItemInfo_Value(item,"D_LENGTH")
        
        -- Check if there is a region overlapping this item already
        -- Loop through all regions
        local overlapping_region_idx = -1
        local ret, num_markers, num_regions = reaper.CountProjectMarkers( 0 )
        local num_total = num_markers + num_regions
        if num_regions > 0 then
          local j = 0
          while j < num_total do
            local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, j )
            -- Check if it's a region and it's bounds are within the current media item's
            -- Start of region happens before the end of the item AND end of region happens after start of item
            if isrgn and pos < item_end_pos and rgnend > item_start_pos then
              --acendan.dbg("OVERLAPPING REGION: Item #" .. tostring(i+1) .. " - Region #" .. tostring(j+1))
            
              -- Stretch the end of the overlapping region to the end of the item
              reaper.SetProjectMarker3(0, markrgnindexnumber, isrgn, pos, item_end_pos, name, color)
              overlapping_region_idx = markrgnindexnumber
              
              -- Set region to track in RRM just in case
              reaper.SetRegionRenderMatrix(0, overlapping_region_idx, track, 1)
            end
            j = j + 1
          end
        end
        
        -- Check if there was no overlapping region, then create region at item bounds...
        if overlapping_region_idx == -1 then
          local new_region_idx = reaper.AddProjectMarker(0, true, item_start_pos, item_end_pos, "", 0) 
          reaper.SetRegionRenderMatrix(0, new_region_idx, track, 1)
        end
        
      end
    else
      acendan.msg("No items on selected track!")
    end
    
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
