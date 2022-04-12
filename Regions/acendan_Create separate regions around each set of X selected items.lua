-- @description Create Separate Regions Around X Items
-- @author Aaron Cendan
-- @version 1.1
-- @metapackage
-- @provides
--   [main] .
-- @link https://ko-fi.com/acendan_
-- @about
--   # Create Separate Regions Around X Items
-- @changelog
--   # Assign region to shared parent in RRM

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~ USER CONFIG - EDIT ME ~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- This number will determine how many items are used in each set. Change it to whatever you want!
number_of_items_per_set = 12

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Get this script's name and directory
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local script_directory = ({reaper.get_action_context()})[2]:sub(1,({reaper.get_action_context()})[2]:find("\\[^\\]*$"))

-- Load lua utilities
acendan_LuaUtils = reaper.GetResourcePath()..'/scripts/ACendan Scripts/Development/acendan_Lua Utilities.lua'
if reaper.file_exists( acendan_LuaUtils ) then dofile( acendan_LuaUtils ); if not acendan or acendan.version() < 6.1 then acendan.msg('This script requires a newer version of ACendan Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"ACendan Lua Utilities"); return end else reaper.ShowConsoleMsg("This script requires ACendan Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'ACendan Lua Utilities'"); return end

local dbg = false
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function main()

  local num_sel_items = reaper.CountSelectedMediaItems(0)
  if num_sel_items > 0 then
    acendan.selectTracksOfSelectedItems()
    local shared_parent = acendan.getSelectedTracksSharedParent()
    
    local counter = 1
    local num_regions = 1
    local rgn_name = ""
    local rgn_start = 0.0
    local rgn_end = 0.0
    
    for i=0, num_sel_items - 1 do
      local item = reaper.GetSelectedMediaItem( 0, i )
      local item_start_pos = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
      local item_end_pos = item_start_pos + reaper.GetMediaItemInfo_Value( item, "D_LENGTH" )
      local take = reaper.GetActiveTake(item)
      
      -- Set up region name
      local item_name = ""
      if take then _, item_name = reaper.GetSetMediaItemTakeInfo_String(reaper.GetActiveTake(item),"P_NAME","",false) end
      if rgn_name == "" and item_name ~= "" then 
        -- Remove _01 style enumeration if applicable
        rgn_name = acendan.removeEnumeration(item_name)
      end
      
      -- Increment through items in bundle
      if counter == 1 then
        -- Start new region
        rgn_start = item_start_pos
        rgn_end = item_end_pos
        
        if dbg then acendan.dbg(tostring(counter) .. " - " .. tostring(item_start_pos)) end
        counter = counter + 1
      
      
      elseif counter < number_of_items_per_set then
        rgn_end = item_end_pos
        
        -- Item in middle of counter, ignore
        if dbg then acendan.dbg(tostring(counter) .. " - " .. tostring(item_start_pos)) end
        counter = counter + 1
      
      else
        -- Last item in bundle, close and create region then reset counter
        rgn_end = item_end_pos
        local rgn_idx = reaper.AddProjectMarker(0, true, rgn_start, rgn_end, rgn_name, -1)
        reaper.SetRegionRenderMatrix(0, rgn_idx, shared_parent, 1)
        if dbg then acendan.dbg("REGION #" .. tostring(num_regions) .. "\n") end
        rgn_name = ""
        num_regions = num_regions + 1
        
        if dbg then acendan.dbg(tostring(counter) .. " - " .. tostring(item_start_pos)) end
        
        -- Reset counter if not last item
        counter = 1
      end
    end
    
    -- Make sure last region was safely closed
    if counter > 1 then
      local rgn_idx = reaper.AddProjectMarker(0, true, rgn_start, rgn_end, tostring(rgn_name), -1)
      reaper.SetRegionRenderMatrix(0, rgn_idx, shared_parent, 1)
      if dbg then acendan.dbg("REGION #" .. tostring(num_regions) .. "\n") end
      rgn_name = ""
      num_regions = num_regions + 1
    end
    
  else
    acendan.msg("No items selected!")
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
