-- @description UCS Renaming Tool
-- @author Aaron Cendan
-- @version 3.5
-- @metapackage
-- @provides
--   [main] . > acendan_UCS Renaming Tool.lua
-- @link https://aaroncendan.me
-- @about
--   # Universal Category System (UCS) Renaming Tool
--   Developed by Aaron Cendan
--   https://aaroncendan.me
--   aaron.cendan@gmail.com
--
--   ### Useful Resources
--   * Blog post: https://www.aaroncendan.me/side-projects/ucs
--   * Tutorial vid: https://youtu.be/fO-2At7eEQ0
--   * Universal Category System: https://universalcategorysystem.com
--   * UCS Google Drive: https://drive.google.com/drive/folders/1dkTIZ-ZZAY9buNcQIN79PmuLy1fPNqUo
--
--   ### Toolbar Icon Setup
--   * If you would like to set up the UCS logo as a toolbar icon, go to:
--        REAPER\reaper_www_root\ucs_libraries\ucs_toolbar_icon_black.png
--   * Then copy the image(s) from that folder into:
--        REAPER\Data\toolbar_icons
--   * It should then show up when you are customizing toolbar icons in Reaper.
-- @changelog
--   Added track manager selections functionality

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS FROM WEB INTERFACE ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Toggle for debugging UCS input with message box
local debug_UCS_Input = false

-- Retrieve stored projextstate data set by web interface
local ret_cat,  ucs_cat  = reaper.GetProjExtState( 0, "UCS_WebInterface", "Category" )
local ret_scat, ucs_scat = reaper.GetProjExtState( 0, "UCS_WebInterface", "Subcategory" )
local ret_usca, ucs_usca = reaper.GetProjExtState( 0, "UCS_WebInterface", "UserCategory" )
local ret_id,   ucs_id   = reaper.GetProjExtState( 0, "UCS_WebInterface", "CatID" )
local ret_name, ucs_name = reaper.GetProjExtState( 0, "UCS_WebInterface", "Name" )
local ret_num,  ucs_num  = reaper.GetProjExtState( 0, "UCS_WebInterface", "Number" )
local ret_enum, ucs_enum = reaper.GetProjExtState( 0, "UCS_WebInterface", "EnableNum" )
local ret_init, ucs_init = reaper.GetProjExtState( 0, "UCS_WebInterface", "Initials" )
local ret_show, ucs_show = reaper.GetProjExtState( 0, "UCS_WebInterface", "Show" )
local ret_type, ucs_type = reaper.GetProjExtState( 0, "UCS_WebInterface", "userInputItems" )
local ret_area, ucs_area = reaper.GetProjExtState( 0, "UCS_WebInterface", "userInputArea" )
local ret_data, ucs_data = reaper.GetProjExtState( 0, "UCS_WebInterface", "Data" )

-- Initialize global var for full name, see setFullName()
local ucs_full_name = ""


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~~~~~~~~~~~  
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~ Parse UCS Input ~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
function parseUCSWebInterfaceInput()

  reaper.Undo_BeginBlock()

  -- Convert rets to booleans for cleaner function-writing down the line
  ucsRetsToBool()
  
  -- Safety-net evaluation if any of category/subcategory/catID are invalid
  -- The web interface should never even trigger this ReaScript anyways if CatID is invalid
  if not ret_cat and ret_scat and ret_id then do return end end
  
  -- Show message box with form inputs and respective ret bools. Toggle at top of script.
  if debug_UCS_Input then debugUCSInput() end
 
  -- Break out evaluation based on search type
  if ucs_type == "Regions" then
    local ret, num_markers, num_regions = reaper.CountProjectMarkers( 0 )
    if num_regions > 0 then
      renameRegions(num_markers,num_regions)
    else
      reaper.MB("Project has no " .. ucs_type .. " to rename!", "UCS Renaming Tool", 0)
    end
    
  elseif ucs_type == "Markers" then
    local ret, num_markers, num_regions = reaper.CountProjectMarkers( 0 )
    if num_markers > 0 then
      renameMarkers(num_markers,num_regions)
    else
      reaper.MB("Project has no " .. ucs_type .. " to rename!", "UCS Renaming Tool", 0)
    end
    
  elseif ucs_type == "Media Items" then
    local num_items = reaper.CountMediaItems( 0 )
    if num_items > 0 then
      renameMediaItems(num_items)
    else
      reaper.MB("Project has no " .. ucs_type .. " to rename!", "UCS Renaming Tool", 0)
    end
      
  elseif ucs_type == "Tracks" then
    local num_tracks =  reaper.CountTracks( 0 )
    if num_tracks > 0 then
      renameTracks(num_tracks)
    else
      reaper.MB("Project has no " .. ucs_type .. " to rename!", "UCS Renaming Tool", 0)
    end
  
  else
    if ret_type then
      reaper.MB("Invalid search type. Did you tweak the 'userInputItems' options in UCS Renaming Tool Interface.html?", "UCS Renaming Tool", 0)
    else
      reaper.MB("Invalid search type. Did you remove or rename 'userInputItems' in UCS Renaming Tool Interface.html?", "UCS Renaming Tool", 0)
    end
  end

  reaper.Undo_EndBlock("UCS Renaming Tool", -1)
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~ REGIONS ~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
function renameRegions(num_markers,num_regions)
  local num_total = num_markers + num_regions
  
  if ucs_area == "Time Selection" then
    StartTimeSel, EndTimeSel = reaper.GetSet_LoopTimeRange(0,0,0,0,0);
    -- Confirm valid time selection
    if StartTimeSel ~= EndTimeSel then
      local i = 0
      while i < num_total do
        local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, i )
        if isrgn then
          if pos >= StartTimeSel and rgnend <= EndTimeSel then
            -- BUILD NAME
            leadingZeroUCSNumStr()
            setFullName()
            -- SET WILDCARDS
            local rgn_num = tostring(markrgnindexnumber)
            if string.len(rgn_num) == 1 then rgn_num = "0" .. rgn_num end
            if ucs_full_name:find("$Regionnumber") then ucs_full_name = ucs_full_name:gsub("$Regionnumber",rgn_num) end
            if ucs_full_name:find("$Region") then ucs_full_name = ucs_full_name:gsub("$Region",name) end
            -- SET NAME
            reaper.SetProjectMarkerByIndex( 0, i, isrgn, pos, rgnend, markrgnindexnumber, ucs_full_name, color )
            -- INCREMENT
            incrementUCSNumStr()
          end
        end
        i = i + 1
      end
    else
      reaper.MB("You haven't made a time selection!","UCS Renaming Tool", 0)
    end
  
  elseif ucs_area == "Full Project" then
    local i = 0
    while i < num_total do
      local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, i )
      if isrgn then
        leadingZeroUCSNumStr()
        setFullName()
        local rgn_num = tostring(markrgnindexnumber)
        if string.len(rgn_num) == 1 then rgn_num = "0" .. rgn_num end
        if ucs_full_name:find("$Regionnumber") then ucs_full_name = ucs_full_name:gsub("$Regionnumber",rgn_num) end
        if ucs_full_name:find("$Region") then ucs_full_name = ucs_full_name:gsub("$Region",name) end
        reaper.SetProjectMarkerByIndex( 0, i, isrgn, pos, rgnend, markrgnindexnumber, ucs_full_name, color )
        incrementUCSNumStr()
      end
      i = i + 1
    end

  elseif ucs_area == "Edit Cursor" then
    local markeridx, regionidx = reaper.GetLastMarkerAndCurRegion(0, reaper.GetCursorPosition())
    if regionidx ~= nil then
      local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, regionidx )
      if isrgn then
        leadingZeroUCSNumStr()
        setFullName()
        local rgn_num = tostring(markrgnindexnumber)
        if string.len(rgn_num) == 1 then rgn_num = "0" .. rgn_num end
        if ucs_full_name:find("$Regionnumber") then ucs_full_name = ucs_full_name:gsub("$Regionnumber",rgn_num) end
        if ucs_full_name:find("$Region") then ucs_full_name = ucs_full_name:gsub("$Region",name) end
        reaper.SetProjectMarkerByIndex( 0, regionidx, isrgn, pos, rgnend, markrgnindexnumber, ucs_full_name, color )
        incrementUCSNumStr()
      end
    end
    
  elseif ucs_area == "Selected Regions in Region Manager" then
    local sel_rgn_table = getSelectedRegions()
    if sel_rgn_table then 
      for _, regionidx in pairs(sel_rgn_table) do 
        local i = 0
        while i < num_total do
          local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, i )
          if isrgn and markrgnindexnumber == regionidx then
            leadingZeroUCSNumStr()
            setFullName()
            local rgn_num = tostring(markrgnindexnumber)
            if string.len(rgn_num) == 1 then rgn_num = "0" .. rgn_num end
            if ucs_full_name:find("$Regionnumber") then ucs_full_name = ucs_full_name:gsub("$Regionnumber",rgn_num) end
            if ucs_full_name:find("$Region") then ucs_full_name = ucs_full_name:gsub("$Region",name) end
            reaper.SetProjectMarkerByIndex( 0, i, isrgn, pos, rgnend, markrgnindexnumber, ucs_full_name, color )
            incrementUCSNumStr()
            break
          end
          i = i + 1
        end
      end
    else
      reaper.MB("No regions selected!\n\nPlease go to View > Region/Marker Manager to select regions.","UCS Renaming Tool", 0)
    end
  
  else
    if ret_area then
      reaper.MB("Invalid search area type. Did you tweak the 'userInputArea' options in UCS Renaming Tool Interface.html?", "UCS Renaming Tool", 0)
    else
      reaper.MB("Invalid search area type. Did you remove or rename 'userInputArea' in UCS Renaming Tool Interface.html?", "UCS Renaming Tool", 0)
    end
  end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~ MARKERS ~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
function renameMarkers(num_markers,num_regions)
  local num_total = num_markers + num_regions
  
  if ucs_area == "Time Selection" then
    StartTimeSel, EndTimeSel = reaper.GetSet_LoopTimeRange(0,0,0,0,0);
    -- Confirm valid time selection
    if StartTimeSel ~= EndTimeSel then
      local i = 0
      while i < num_total do
        local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, i )
        if not isrgn then
          if pos >= StartTimeSel and pos <= EndTimeSel then
            leadingZeroUCSNumStr()
            setFullName()
            local mkr_num = tostring(markrgnindexnumber)
            if string.len(mkr_num) == 1 then mkr_num = "0" .. mkr_num end
            if ucs_full_name:find("$Markernumber") then ucs_full_name = ucs_full_name:gsub("$Markernumber",mkr_num) end
            if ucs_full_name:find("$Marker") then ucs_full_name = ucs_full_name:gsub("$Marker",name) end
            reaper.SetProjectMarkerByIndex( 0, i, isrgn, pos, rgnend, markrgnindexnumber, ucs_full_name, color )
            incrementUCSNumStr()
          end
        end
        i = i + 1
      end
    else
      reaper.MB("You haven't made a time selection!","UCS Renaming Tool", 0)
    end

  elseif ucs_area == "Full Project" then
    local i = 0
    while i < num_total do
      local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, i )
      if not isrgn then
        leadingZeroUCSNumStr()
        setFullName()
        local mkr_num = tostring(markrgnindexnumber)
        if string.len(mkr_num) == 1 then mkr_num = "0" .. mkr_num end
        if ucs_full_name:find("$Markernumber") then ucs_full_name = ucs_full_name:gsub("$Markernumber",mkr_num) end
        if ucs_full_name:find("$Marker") then ucs_full_name = ucs_full_name:gsub("$Marker",name) end
        reaper.SetProjectMarkerByIndex( 0, i, isrgn, pos, rgnend, markrgnindexnumber, ucs_full_name, color )
        incrementUCSNumStr()
      end
      i = i + 1
    end
    
  elseif ucs_area == "Selected Markers in Marker Manager" then
    local sel_mkr_table = getSelectedMarkers()
    if sel_mkr_table then 
      for _, regionidx in pairs(sel_mkr_table) do 
        local i = 0
        while i < num_total do
          local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, i )
          if not isrgn and markrgnindexnumber == regionidx then
            leadingZeroUCSNumStr()
            setFullName()
            local mkr_num = tostring(markrgnindexnumber)
            if string.len(mkr_num) == 1 then mkr_num = "0" .. mkr_num end
            if ucs_full_name:find("$Markernumber") then ucs_full_name = ucs_full_name:gsub("$Markernumber",mkr_num) end
            if ucs_full_name:find("$Marker") then ucs_full_name = ucs_full_name:gsub("$Marker",name) end
            reaper.SetProjectMarkerByIndex( 0, i, isrgn, pos, rgnend, markrgnindexnumber, ucs_full_name, color )
            incrementUCSNumStr()
            break
          end
          i = i + 1
        end
      end
    else
      reaper.MB("No markers selected!\n\nPlease go to View > Region/Marker Manager to select regions.","UCS Renaming Tool", 0)
    end
  
  else
    if ret_area then
      reaper.MB("Invalid search area type. Did you tweak the 'userInputArea' options in UCS Renaming Tool Interface.html?", "UCS Renaming Tool", 0)
    else
      reaper.MB("Invalid search area type. Did you remove or rename 'userInputArea' in UCS Renaming Tool Interface.html?", "UCS Renaming Tool", 0)
    end
  end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~ ITEMS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
function renameMediaItems(num_items)
  if ucs_area == "Selected Items" then
    local num_sel_items = reaper.CountSelectedMediaItems(0)
    if num_sel_items > 0 then
      for i=0, num_sel_items - 1 do
        local item = reaper.GetSelectedMediaItem( 0, i )
        local take = reaper.GetActiveTake( item )
        local item_num = tostring(math.floor( reaper.GetMediaItemInfo_Value( item, "IP_ITEMNUMBER" ) + 1))
        if string.len(item_num) == 1 then item_num = "0" .. item_num end
        if take ~= nil then 
          leadingZeroUCSNumStr()
          setFullName()
          if ucs_full_name:find("$Itemnumber") then ucs_full_name = ucs_full_name:gsub("$Itemnumber", item_num) end
          if ucs_full_name:find("$Item") then 
            local ret_name, item_name = reaper.GetSetMediaItemTakeInfo_String( take, "P_NAME", "", false )
            if ret_name then ucs_full_name = ucs_full_name:gsub("$Item",item_name)
            else ucs_full_name = ucs_full_name:gsub("$Item","") end
          end
          reaper.GetSetMediaItemTakeInfo_String( take, "P_NAME", ucs_full_name, true )
          incrementUCSNumStr()
        end
      end
    else
      reaper.MB("No items selected!","UCS Renaming Tool", 0)
    end
    
  elseif ucs_area == "All Items" then
    for i=0, num_items - 1 do
      local item =  reaper.GetMediaItem( 0, i )
      local take = reaper.GetActiveTake( item )
      local item_num = tostring(math.floor( reaper.GetMediaItemInfo_Value( item, "IP_ITEMNUMBER" ) + 1))
      if string.len(item_num) == 1 then item_num = "0" .. item_num end
      if take ~= nil then 
        leadingZeroUCSNumStr()
        setFullName()
        if ucs_full_name:find("$Itemnumber") then ucs_full_name = ucs_full_name:gsub("$Itemnumber", item_num) end
        if ucs_full_name:find("$Item") then 
          local ret_name, item_name = reaper.GetSetMediaItemTakeInfo_String( take, "P_NAME", "", false )
          if ret_name then ucs_full_name = ucs_full_name:gsub("$Item",item_name)
          else ucs_full_name = ucs_full_name:gsub("$Item","") end
        end
        reaper.GetSetMediaItemTakeInfo_String( take, "P_NAME", ucs_full_name, true )
        incrementUCSNumStr()
      end
    end
  else
    if ret_area then
      reaper.MB("Invalid search area type. Did you tweak the 'userInputArea' options in UCS Renaming Tool Interface.html?", "UCS Renaming Tool", 0)
    else
      reaper.MB("Invalid search area type. Did you remove or rename 'userInputArea' in UCS Renaming Tool Interface.html?", "UCS Renaming Tool", 0)
    end
  end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~ TRACKS ~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
function renameTracks(num_tracks)
  if ucs_area == "Selected Tracks" then
    num_sel_tracks = reaper.CountSelectedTracks( 0 )
    if num_sel_tracks > 0 then
      for i = 0, num_sel_tracks-1 do
        track = reaper.GetSelectedTrack(0,i)
        local track_num = tostring(math.floor(reaper.GetMediaTrackInfo_Value( track, "IP_TRACKNUMBER" )))
        if string.len(track_num) == 1 then track_num = "0" .. track_num end
        leadingZeroUCSNumStr()
        setFullName()
        if ucs_full_name:find("$Tracknumber") then ucs_full_name = ucs_full_name:gsub("$Tracknumber", track_num) end
        if ucs_full_name:find("$Track") then 
          local ret_name, track_name = reaper.GetSetMediaTrackInfo_String( track, "P_NAME", "", false )
          if ret_name then ucs_full_name = ucs_full_name:gsub("$Track",track_name)
          else ucs_full_name = ucs_full_name:gsub("$Track","") end
        end
        reaper.GetSetMediaTrackInfo_String( track, "P_NAME", ucs_full_name, true )
        incrementUCSNumStr()
      end
    else
      reaper.MB("No tracks selected!","UCS Renaming Tool", 0)
    end

  elseif ucs_area == "Selected in Track Manager" then
    local sel_trk_table = getSelectedTracks()
    if sel_trk_table then 
      for _, trkidx in pairs(sel_trk_table) do 
        track = reaper.GetTrack(0,trkidx - 1)
        local track_num = tostring(trkidx)
        if string.len(track_num) == 1 then track_num = "0" .. track_num end
        leadingZeroUCSNumStr()
        setFullName()
        if ucs_full_name:find("$Tracknumber") then ucs_full_name = ucs_full_name:gsub("$Tracknumber", track_num) end
        if ucs_full_name:find("$Track") then 
          local ret_name, track_name = reaper.GetSetMediaTrackInfo_String( track, "P_NAME", "", false )
          if ret_name then ucs_full_name = ucs_full_name:gsub("$Track",track_name)
          else ucs_full_name = ucs_full_name:gsub("$Track","") end
        end
        reaper.GetSetMediaTrackInfo_String( track, "P_NAME", ucs_full_name, true )
        incrementUCSNumStr()
      end
    else
      reaper.MB("No tracks selected!\n\nPlease go to View > Track Manager to select tracks.","UCS Renaming Tool", 0)
    end
    
  elseif ucs_area == "All Tracks" then
    for i = 0, num_tracks-1 do
     track = reaper.GetTrack(0,i)
     local track_num = tostring(math.floor(reaper.GetMediaTrackInfo_Value( track, "IP_TRACKNUMBER" )))
     if string.len(track_num) == 1 then track_num = "0" .. track_num end
     leadingZeroUCSNumStr()
     setFullName()
     if ucs_full_name:find("$Tracknumber") then ucs_full_name = ucs_full_name:gsub("$Tracknumber", track_num) end
     if ucs_full_name:find("$Track") then 
       local ret_name, track_name = reaper.GetSetMediaTrackInfo_String( track, "P_NAME", "", false )
       if ret_name then ucs_full_name = ucs_full_name:gsub("$Track",track_name)
       else ucs_full_name = ucs_full_name:gsub("$Track","") end
     end
     reaper.GetSetMediaTrackInfo_String( track, "P_NAME", ucs_full_name, true )
     incrementUCSNumStr()
    end
    
  else
    if ret_area then
      reaper.MB("Invalid search area type. Did you tweak the 'userInputArea' options in UCS Renaming Tool Interface.html?", "UCS Renaming Tool", 0)
    else
      reaper.MB("Invalid search area type. Did you remove or rename 'userInputArea' in UCS Renaming Tool Interface.html?", "UCS Renaming Tool", 0)
    end
  end
end


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~ UTILITIES ~~~~~~~~~~~~~~~~~~~~~  
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~ Set Full Name ~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Format: CatID(-UserCategory)_(VendorCategory-)File Name with Variation Number_Initials_(Show)
function setFullName()
  -- Initials
  ucs_init_final = "_" .. string.upper(ucs_init)

  -- Name and Vendor
  local s, e = string.find(ucs_name,"-")
  if not s then s = 6 end
  if (s <= 5) then
    -- Vendor found
    local vendorCat = string.sub(ucs_name, 1, s-1)
    local name = string.sub(ucs_name, s+1)
    if (ucs_enum == "true") then
      ucs_name_num_final = "_" .. string.upper(vendorCat) .. "-" .. name:gsub("(%a)([%w_']*)", toTitleCase) .. " " .. ucs_num
    else
      ucs_name_num_final = "_" .. string.upper(vendorCat) .. "-" .. name:gsub("(%a)([%w_']*)", toTitleCase)
    end
  else
    -- No Vendor
    if (ucs_enum == "true") then
      ucs_name_num_final = "_" .. ucs_name:gsub("(%a)([%w_']*)", toTitleCase) .. " " .. ucs_num
    else
      ucs_name_num_final = "_" .. ucs_name:gsub("(%a)([%w_']*)", toTitleCase)
    end
  end

  -- Show
  if ret_show then
    ucs_show_final = "_" .. string.upper(ucs_show)
  else
    ucs_show_final = "_NONE"
  end

  -- User Category
  if ret_usca then
    ucs_usca_final = "-" .. string.upper(ucs_usca)
  else
    ucs_usca_final = ""
  end

  -- Data
  if ret_data then
    ucs_data_final = "_" .. ucs_data
  else
    ucs_data_final = ""
  end
  
  -- Build the final name!
  ucs_full_name = ucs_id .. ucs_usca_final .. ucs_name_num_final .. ucs_init_final .. ucs_show_final .. ucs_data_final

end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~ GET SELECTED REGIONS ~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- https://github.com/ReaTeam/ReaScripts-Templates/blob/master/Regions-and-Markers/X-Raym_Get%20selected%20regions%20in%20region%20and%20marker%20manager.lua
function getSelectedRegions()
  local hWnd = getRegionManager()
  if hWnd == nil then return end  

  local container = reaper.JS_Window_FindChildByID(hWnd, 1071)

  sel_count, sel_indexes = reaper.JS_ListView_ListAllSelItems(container)
  if sel_count == 0 then return end 

  names = {}
  i = 0
  for index in string.gmatch(sel_indexes, '[^,]+') do 
    i = i+1
    local sel_item = reaper.JS_ListView_GetItemText(container, tonumber(index), 1)
    if sel_item:find("R") ~= nil then
      names[i] = tonumber(sel_item:sub(2))
    end
  end
  
  -- Return table of selected regions
  return names
end

function getSelectedMarkers()
  local hWnd = getRegionManager()
  if hWnd == nil then return end
  
  local container = reaper.JS_Window_FindChildByID(hWnd, 1071)

  sel_count, sel_indexes = reaper.JS_ListView_ListAllSelItems(container)
  if sel_count == 0 then return end 

  names = {}
  i = 0
  for index in string.gmatch(sel_indexes, '[^,]+') do 
    i = i+1
    local sel_item = reaper.JS_ListView_GetItemText(container, tonumber(index), 1)
    if sel_item:find("M") ~= nil then
      names[i] = tonumber(sel_item:sub(2))
    end
  end
  
  -- Return table of selected regions
  return names
end

function getRegionManager()
  local title = reaper.JS_Localize("Region/Marker Manager", "common")
  local arr = reaper.new_array({}, 1024)
  reaper.JS_Window_ArrayFind(title, true, arr)
  local adr = arr.table()

  for j = 1, #adr do
    local hwnd = reaper.JS_Window_HandleFromAddress(adr[j])
    -- verify window by checking if it also has a specific child.
    if reaper.JS_Window_FindChildByID(hwnd, 1056) then -- 1045:ID of clear button
      return hwnd
    end 
  end
end


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~ GET SELECTED TRACKS  ~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~

function getSelectedTracks()
  local hWnd = getTrackManager()
  if hWnd == nil then return end  

  local container = reaper.JS_Window_FindChildByID(hWnd, 1071)

  sel_count, sel_indexes = reaper.JS_ListView_ListAllSelItems(container)
  if sel_count == 0 then return end 

  names = {}
  i = 0
  for index in string.gmatch(sel_indexes, '[^,]+') do 
    i = i+1
    local sel_item = reaper.JS_ListView_GetItemText(container, tonumber(index), 1)
    names[i] = tonumber(sel_item)
  end
  
  -- Return table of selected tracks
  return names
end

function getTrackManager()
  local title = reaper.JS_Localize("Track Manager", "common")
  local arr = reaper.new_array({}, 1024)
  reaper.JS_Window_ArrayFind(title, true, arr)
  local adr = arr.table()

  for j = 1, #adr do
    local hwnd = reaper.JS_Window_HandleFromAddress(adr[j])
    -- verify window by checking if it also has a specific child.
    if reaper.JS_Window_FindChildByID(hwnd, 1056) then -- 1045:ID of clear button
      return hwnd
    end 
  end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~ Increment Num String ~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
function incrementUCSNumStr()
  ucs_num = tostring(tonumber(ucs_num) + 1)
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~ Title Case Full Name ~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
function toTitleCase(first, rest)
  return first:upper()..rest:lower()
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~ Add Leading Zero ~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
function leadingZeroUCSNumStr()
  local len = string.len(ucs_num)
  -- While num is < 10, add one leading zero. If you would prefer otherwise,
  -- change "0" to "00" and/or remove leading zeroes entirely by deleting this if/else block.
  -- "len" = the number of digits in the number.
  if len == 1 then 
    ucs_num = "0" .. ucs_num
  --elseif len == 2 then
    --ucs_num = "0" .. ucs_num
  end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~ Rets to Bools ~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
function ucsRetsToBool()
  if ret_cat  == 1 then ret_cat  = true else ret_cat  = false end
  if ret_scat == 1 then ret_scat = true else ret_scat = false end
  if ret_usca == 1 then ret_usca = true else ret_usca = false end
  if ret_id   == 1 then ret_id   = true else ret_id   = false end
  if ret_name == 1 then ret_name = true else ret_name = false end
  if ret_num  == 1 then ret_num  = true else ret_num  = false end
  if ret_enum == 1 then ret_enum = true else ret_enum = false end
  if ret_init == 1 then ret_init = true else ret_init = false end
  if ret_show == 1 then ret_show = true else ret_show = false end
  if ret_type == 1 then ret_type = true else ret_type = false end
  if ret_area == 1 then ret_area = true else ret_area = false end
  if ret_data == 1 then ret_data = true else ret_data = false end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~ Debug UCS Input ~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
function debugUCSInput()
  reaper.MB("Category: "    .. ucs_cat  .. " (" .. tostring(ret_cat)  .. ")" .. "\n" .. 
            "Subcategory: " .. ucs_scat .. " (" .. tostring(ret_scat) .. ")" .. "\n" .. 
            "User Cat.: "   .. ucs_usca .. " (" .. tostring(ret_usca) .. ")" .. "\n" .. 
            "CatID: "       .. ucs_id   .. " (" .. tostring(ret_id)   .. ")" .. "\n" .. 
            "Name: "        .. ucs_name .. " (" .. tostring(ret_name) .. ")" .. "\n" .. 
            "Number: "      .. ucs_num  .. " (" .. tostring(ret_num)  .. ")" .. "\n" .. 
            "Enum: "        .. ucs_enum .. " (" .. tostring(ret_enum) .. ")" .. "\n" ..
            "Initials: "    .. ucs_init .. " (" .. tostring(ret_init) .. ")" .. "\n" .. 
            "Show: "        .. ucs_show .. " (" .. tostring(ret_show) .. ")" .. "\n" .. 
            "Type: "        .. ucs_type .. " (" .. tostring(ret_type) .. ")" .. "\n" .. 
            "Data: "        .. ucs_data .. " (" .. tostring(ret_data) .. ")" .. "\n" ..
            "Area: "        .. ucs_area .. " (" .. tostring(ret_area) .. ")" .. "\n" 
            , "UCS Renaming Tool", 0)
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~ Open Web Interface ~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
function openUCSWebInterface()
  local web_int_settings = getWebInterfaceSettings()
  local localhost = "http://localhost:"
  local ucs_path = ""
  
  for _, line in pairs(web_int_settings) do
    if line:find("acendan_UCS Renaming Tool.html") then
      local port = getPort(line)
      ucs_path = localhost .. port
      break
    
    elseif line:find("acendan_UCS Renaming Tool_Dark.html") then
      local port = getPort(line)
      ucs_path = localhost .. port
      break
    end
  end
  
  if ucs_path ~= "" then
    openURL(ucs_path)
  else
    local response = reaper.MB("UCS Renaming Tool not found in Reaper Web Interface settings!\n\nWould you like to open the installation tutorial video?","Open UCS Renaming Tool",4)
    if response == 6 then openURL("https://youtu.be/fO-2At7eEQ0") end
  end
end

-- Open a webpage or file directory
function openURL(path)
  reaper.CF_ShellExecute(path)
end

-- Get web interface info from REAPER.ini // returns Table
function getWebInterfaceSettings()
  local ini_file = reaper.get_ini_file()
  local ret, num_webs = reaper.BR_Win32_GetPrivateProfileString( "reaper", "csurf_cnt", "", ini_file )
  local t = {}
  if ret then
    for i = 0, num_webs do
      local ret, web_int = reaper.BR_Win32_GetPrivateProfileString( "reaper", "csurf_" .. i, "", ini_file )
      table.insert(t, web_int)
    end
  end
  return t
end

-- Get localhost port from reaper.ini file line
function getPort(line)
  local port = line:sub(line:find(" ")+3,line:find("'")-2)
  return port
end


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~~~~~~~~~~  
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
reaper.PreventUIRefresh(1)

-- Check for JS_ReaScript Extension
if reaper.JS_Dialog_BrowseForSaveFile then
  
  if reaper.HasExtState( "UCS_WebInterface", "runFromWeb" ) then

    if reaper.GetExtState( "UCS_WebInterface", "runFromWeb" ) == "true" then
      -- RUN FROM WEB INTERFACE, EXECUTE SCRIPT
      reaper.SetExtState( "UCS_WebInterface", "runFromWeb", "false", true )
      parseUCSWebInterfaceInput()

    else
      -- RUN FROM REAPER, OPEN INTERFACE
      openUCSWebInterface()
    end

  else
    -- NO EXTSTATE FOUND, OPEN INTERFACE
    openUCSWebInterface()
  end

else
  reaper.MB("Please install the JS_ReaScriptAPI REAPER extension, available in ReaPack, under the ReaTeam Extensions repository.\n\nExtensions > ReaPack > Browse Packages\n\nFilter for 'JS_ReascriptAPI'. Right click to install.","UCS Renaming Tool", 0)
end

reaper.PreventUIRefresh(-1)

reaper.UpdateArrange()