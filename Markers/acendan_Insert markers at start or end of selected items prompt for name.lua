-- @description Insert markers at end of selected items with item name
-- @author Aaron Cendan
-- @version 1.1
-- @metapackage
-- @provides
--   [main] . > acendan_Insert markers at start or end of selected items prompt for name.lua
-- @link https://aaroncendan.me
-- @changelog
--  # 1-based enumeration
--  + Use 'Restart Enumeration = n' to continue with previous iteration

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function insertMarkers()
  reaper.Undo_BeginBlock()
  
  local num_sel_items = reaper.CountSelectedMediaItems(0)
  if num_sel_items > 0 then
  
    -- Get placeholders from ext state if exist
    local pl_name = reaper.HasExtState( "acendan_Item markers", "in_name" ) and  reaper.GetExtState( "acendan_Item markers", "in_name" ) or "$item"
    local pl_inc  = reaper.HasExtState( "acendan_Item markers", "in_inc" )  and  reaper.GetExtState( "acendan_Item markers", "in_inc" )  or "y"
    local pl_pos  = reaper.HasExtState( "acendan_Item markers", "in_pos" )  and  reaper.GetExtState( "acendan_Item markers", "in_pos" )  or "s"
    local pl_res  = reaper.HasExtState( "acendan_Item markers", "in_res" )  and  reaper.GetExtState( "acendan_Item markers", "in_res" )  or "y"
    
    -- Multiple fields
    local ret_input, user_input = reaper.GetUserInputs( "Insert Markers", 4,
                              "Name (Wildcards: $item, $track),Increment (y/n),Start/End of Item (s/e),Restart Enumeration (y/n)" .. ",extrawidth=100",
                              pl_name .. "," .. pl_inc .. "," .. pl_pos .. "," .. pl_res )
    if not ret_input then return end
    local in_name, in_inc, in_pos, in_res = user_input:match("([^,]+),([^,]+),([^,]+),([^,]+)")
    
    -- Double-check user inputs for shenanigans
    if in_inc ~= "y" and in_inc ~= "n" then in_inc = "y" end
    if in_pos ~= "s" and in_pos ~= "e" then in_pos = "s" end
    if in_res ~= "y" and in_res ~= "n" then in_res = "y" end
    
    -- Store to ext states
    reaper.SetExtState( "acendan_Item markers", "in_name", in_name, true )
    reaper.SetExtState( "acendan_Item markers", "in_inc",  in_inc,  true )
    reaper.SetExtState( "acendan_Item markers", "in_pos",  in_pos,  true )
    reaper.SetExtState( "acendan_Item markers", "in_res",  in_res,  true )
    
    -- Get offset number
    local offset = 0
    if in_res == "n" then
      local _, num_markers, num_regions = reaper.CountProjectMarkers( 0 )
      local num_total = num_markers + num_regions
      if num_markers > 0 then
        local i = 0
        while i < num_total do
          local _, isrgn, _, _, _, markrgnindexnumber, _ = reaper.EnumProjectMarkers3( 0, i )
          if not isrgn then
            if markrgnindexnumber > offset then offset = markrgnindexnumber end
          end
          i = i + 1
        end
      end
    end
    
    -- Loop through items
    for i=1+offset, num_sel_items+offset do
      local item = reaper.GetSelectedMediaItem( 0, i - 1 - offset)
      local item_start = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
      local item_length = reaper.GetMediaItemInfo_Value( item, "D_LENGTH" )
      local item_end = item_start + item_length
      
      local mkr_name = in_name
     
      -- Replace $item wildcard with name
      if mkr_name:find("$item") then
        local take = reaper.GetActiveTake( item )
        local ret, name = reaper.GetSetMediaItemTakeInfo_String( take, "P_NAME", "", false )
        mkr_name = mkr_name:gsub("$item",name)
      end
      
      -- Replace $track wildcard with name
      if mkr_name:find("$track") then
        local track = reaper.GetMediaItem_Track( item )
        local ret, name = reaper.GetSetMediaTrackInfo_String( track, "P_NAME", "", false )
        mkr_name = mkr_name:gsub("$track",name)
      end
      
      -- Increment
      if in_inc == "y" then
        -- Add leading zero to increment
        local inc = (string.len(tostring(i)) == 1) and  "_0" .. tostring(i) or "_" .. tostring(i)
        mkr_name = mkr_name .. inc
      end
      
      -- Set marker
      local idx = (in_pos == "e") and reaper.AddProjectMarker( 0, 0, item_end, item_end, mkr_name, i ) or reaper.AddProjectMarker( 0, 0, item_start, item_start, mkr_name, i )

    end
  else
    reaper.MB("No items selected!","Insert Markers", 0)
  end

  reaper.Undo_EndBlock("Shrink Region Edges", -1)
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
reaper.PreventUIRefresh(1)

insertMarkers()

reaper.PreventUIRefresh(-1)

reaper.UpdateArrange()
