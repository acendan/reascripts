-- @description UCS Renaming Tool - Send To Interface
-- @author Aaron Cendan
-- @version 8.2.5
-- @metapackage
-- @provides
--   [main] . > acendan_UCS Renaming Tool - Send To Interface.lua
-- @link https://aaroncendan.me
-- @about
--   # Universal Category System (UCS) Renaming Tool
--   Developed by Aaron Cendan
--   https://aaroncendan.me
--   aaron.cendan@gmail.com
--
--   ### Notes
--   * This is just a helper script for the UCS Renaming Tool! It doesn't really do anything on it's own :)

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS FROM WEB INTERFACE ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Toggle for debugging UCS input with message box
local debug_UCS_Input = false

-- Retrieve stored projextstate data set by web interface
local ret_type, ucs_type = reaper.GetProjExtState( 0, "UCS_WebInterface", "userInputItems" )
local ret_area, ucs_area = reaper.GetProjExtState( 0, "UCS_WebInterface", "userInputArea" )

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~~~~~~~~~~~  
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~ Search Media Explorer ~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function sendToInterface()
  -- Convert rets to booleans for cleaner function-writing down the line
  ucsRetsToBool()

  -- Find relevant UCS-named content and metadata by processing area
  local ucs_name, meta_mkr = getUCSNameAndMeta()

  -- Set ext states
  setExtStates(ucs_name, meta_mkr)

end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~ Get UCS Name & Meta ~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Find target region/item name.
-- Find closest meta marker.
-- Returns pair of strings or nil on failure.
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
function getUCSNameAndMeta()
  local _, num_markers, num_regions = reaper.CountProjectMarkers( 0 )
  local num_total = num_markers + num_regions
  local ucs_name = nil -- The name of the region/item
  local position = nil -- The start pos of the item or region, used for fetching closest marker
  local meta_mkr = nil -- The name of the closest metadata marker

  -- Regions
  if ucs_type == "Regions" and num_regions > 0 then
    -- find closest marker to region
    if ucs_area == "Time Selection" then
      local start_time_sel, end_time_sel = reaper.GetSet_LoopTimeRange(0,0,0,0,0);
      if start_time_sel ~= end_time_sel then
        local i = 0
        while i < num_total do
          local _, isrgn, pos, _, name, _, _= reaper.EnumProjectMarkers3( 0, i )
          if isrgn and pos >= start_time_sel then
            ucs_name = name
            position = pos
            break
          end
          i = i + 1
        end
      end

    elseif ucs_area == "Full Project" then
      local i = 0
      while i < num_total do
        local _, isrgn, pos, _, name, _, _= reaper.EnumProjectMarkers3( 0, i )
        if isrgn then
          ucs_name = name
          position = pos
          break
        end
        i = i + 1
      end

    elseif ucs_area == "Edit Cursor" then
      local _, regionidx = reaper.GetLastMarkerAndCurRegion(0, reaper.GetCursorPosition())
      if regionidx ~= nil then
        local _, isrgn, pos, _, name, _, _= reaper.EnumProjectMarkers3( 0, regionidx )
        if isrgn then
          ucs_name = name
          position = pos
        end
      end

    elseif ucs_area == "Selected Regions in Region Manager" then
      local sel_rgn_table = getSelectedRegions()
      if sel_rgn_table then 
        for _, regionidx in pairs(sel_rgn_table) do 
          local i = 0
          while i < num_total do
            local _, isrgn, pos, _, name, markrgnindexnumber, _= reaper.EnumProjectMarkers3( 0, i )
            if isrgn and markrgnindexnumber == regionidx then
              ucs_name = name
              position = pos
              break
            end
            i = i + 1
          end
        end
      end
    end

  -- Media Items
  elseif ucs_type == "Media Items" and reaper.CountMediaItems() > 0 then
    local item = nil
    if ucs_area == "Selected Items" then
      item = reaper.GetSelectedMediaItem( 0, 0 )
    elseif ucs_area == "All Items" then
      item = reaper.GetMediaItem( 0, 0 )
    end
    if item then
      local take = reaper.GetActiveTake( item )
      if take then
        local ret, item_name = reaper.GetSetMediaItemTakeInfo_String( take , "P_NAME", "", false )
        if ret and item_name ~= "" then ucs_name = item_name end
      end
      position = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
    end
  end

  -- Find closest marker name
  if position and position >= 0 then
    local i = 0
    while i < num_total do
      local _, isrgn, pos, _, mkr_name, _, _= reaper.EnumProjectMarkers3( 0, i )
      if not isrgn and pos >= position and mkr_name:find("META;") then
        meta_mkr = mkr_name
        break
      end
      i = i + 1
    end
  end

  return ucs_name, meta_mkr
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~ Set Ext States ~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
function setExtStates(ucs_name, meta_mkr)
  if ucs_name then reaper.SetProjExtState(0, "UCS_WebInterface", "ReacallName", ucs_name) end
  if meta_mkr then reaper.SetProjExtState(0, "UCS_WebInterface", "ReacallMeta", meta_mkr) end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~ Rets to Bools ~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
function ucsRetsToBool()
  if ret_srch == 1 then ret_srch = true else ret_srch = false end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~ Debug UCS Input ~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
function debugUCSInput()
  reaper.MB("Search: "      .. ucs_srch .. " (" .. tostring(ret_srch) .. ")", "UCS Renaming Tool", 0)
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~ GET SELECTED REGIONS ~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- https://github.com/ReaTeam/ReaScripts-Templates/blob/master/Regions-and-Markers/X-Raym_Get%20selected%20regions%20in%20region%20and%20marker%20manager.lua
function getSelectedRegions()
  local rgn_list = getRegionManagerList()

  sel_count, sel_indexes = reaper.JS_ListView_ListAllSelItems(rgn_list)
  if sel_count == 0 then return end 

  names = {}
  i = 0
  for index in string.gmatch(sel_indexes, '[^,]+') do 
    i = i+1
    local sel_item = reaper.JS_ListView_GetItemText(rgn_list, tonumber(index), 1)
    if sel_item:find("R") ~= nil then
      names[i] = tonumber(sel_item:sub(2))
    end
  end
  
  -- Return table of selected regions
  return names
end

function getSelectedMarkers()
  local rgn_list = getRegionManagerList()

  sel_count, sel_indexes = reaper.JS_ListView_ListAllSelItems(rgn_list)
  if sel_count == 0 then return end 

  names = {}
  i = 0
  for index in string.gmatch(sel_indexes, '[^,]+') do 
    i = i+1
    local sel_item = reaper.JS_ListView_GetItemText(rgn_list, tonumber(index), 1)
    if sel_item:find("M") ~= nil then
      names[i] = tonumber(sel_item:sub(2))
    end
  end
  
  -- Return table of selected regions
  return names
end

function getRegionManager()
  return reaper.JS_Window_Find(reaper.JS_Localize("Region/Marker Manager","common"), true) or nil
end

function getRegionManagerList()
  return reaper.JS_Window_FindEx(getRegionManager(), nil, "SysListView32", "") or nil
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~ DO IT! ~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
sendToInterface()
