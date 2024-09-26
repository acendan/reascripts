-- @description UCS Renaming Tool - Send To Interface
-- @author Aaron Cendan
-- @version 8.3.1
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
-- @changelog
--   * Add support for NVK Folder Items!

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

  elseif ucs_type == "NVK Folder Items" and reaper.NVK_CountFolderItems(0) > 0 then
    -- Check for NVK API Extension
    if not reaper.NVK_IsFolderItem then
      --reaper.MB("Support for renaming NVK Folder Items depends on the NVK API, available in ReaPack, under the nvk-ReaScripts repository.\n\nExtensions > ReaPack > Browse Packages\n\nFilter for 'nvk-ReaScripts'. Right click to install.","UCS Renaming Tool", 0)
      reaper.MB("Support for NVK Folder Items is not yet available! Stay tuned for updates in the not-so-distant future...","UCS Renaming Tool", 0)
      return
    end
    
    local item = nil
    if ucs_area == "Selected Items" then
      item = reaper.NVK_GetSelectedFolderItem(0, 0)
    elseif ucs_area == "All Items" then
      item = reaper.NVK_GetFolderItem(0, 0)
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
-- edited by joshnt (08/09/2024)
-- adapted from edgemeal: Select next region in region manager window.lua
-- https://github.com/ReaTeam/ReaScripts-Templates/blob/master/Regions-and-Markers/X-Raym_Get%20selected%20regions%20in%20region%20and%20marker%20manager.lua
function getSelectedRegions()
  
  local rgn_list, item_count = getRegionManagerListAndItemCount()
  if not rgn_list then return end
  local regionOrderInManager, _ = getRegionsAndMarkerInManagerOrder(rgn_list, item_count)

  if item_count == 0 then return end
  
  local indexSelRgn = {}

  -- get pos in rgn manager as keyvalues (instead of keys) to sort them numerically
  local keys = {}

  for posInRgnMgn, markerNum in pairs(regionOrderInManager) do
    local sel = reaper.JS_ListView_GetItemState(rgn_list, posInRgnMgn)
    if sel > 1 then
      table.insert(keys, posInRgnMgn)
    end
  end
  table.sort(keys)

  for _, posInRgnMgn in ipairs(keys) do
    indexSelRgn[#indexSelRgn+1] = regionOrderInManager[posInRgnMgn]
  end

  -- Return table of selected regions
  return indexSelRgn
end

function getSelectedMarkers()
  
  local rgn_list, item_count = getRegionManagerListAndItemCount()
  if not rgn_list then return end
  local _, markerOrderInManager = getRegionsAndMarkerInManagerOrder(rgn_list, item_count)

  if item_count == 0 then return end
  
  local indexSelMrk = {}

  -- get pos in rgn manager as keyvalues (instead of keys) to sort them numerically
  local keys = {}

  for posInRgnMgn, markerNum in pairs(markerOrderInManager) do
    local sel = reaper.JS_ListView_GetItemState(rgn_list, posInRgnMgn)
    if sel > 1 then
      table.insert(keys, posInRgnMgn)
    end
  end
  table.sort(keys)

  for _, posInRgnMgn in ipairs(keys) do
    indexSelMrk[#indexSelMrk+1] = markerOrderInManager[posInRgnMgn]
  end

  -- Return table of selected regions
  return indexSelMrk
end

function getRegionManagerListAndItemCount()
  -- Open region/marker manager window if not found (as regions can be selected without the region manager being opened)
  local title = reaper.JS_Localize('Region/Marker Manager', 'common')
  local manager = reaper.JS_Window_Find(title, true)
  if not manager then
    reaper.Main_OnCommand(40326, 0) -- View: Show region/marker manager window
    manager = reaper.JS_Window_Find(title, true)
  end
  if manager then
    reaper.DockWindowActivate(manager)      -- OPTIONAL: Select/show manager if docked
    local lv = reaper.JS_Window_FindChildByID(manager, 1071)
    local item_cnt = reaper.JS_ListView_GetItemCount(lv)
    return lv, item_cnt;

  else reaper.MB("Unable to get Region/Marker Manager!","Error",0) return end
end

function getRegionsAndMarkerInManagerOrder(lv, cnt)
  local regions = {} -- table with position in list as key and region index as value
  local marker = {} -- table with position in list as key and marker index as value
  for i = 0, cnt-1 do
    local rgnMrkString_TEMP = reaper.JS_ListView_GetItemText(lv, i, 1)
    if rgnMrkString_TEMP:match("R%d") then
      local RGN_Index = string.gsub(rgnMrkString_TEMP, "R","")
      regions[i]= tonumber(RGN_Index)
    elseif rgnMrkString_TEMP:match("M%d") then
      local MRK_Index = string.gsub(rgnMrkString_TEMP, "M","")
      marker[i]= tonumber(MRK_Index)
    end
  end
  return regions, marker
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~ DO IT! ~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
sendToInterface()
