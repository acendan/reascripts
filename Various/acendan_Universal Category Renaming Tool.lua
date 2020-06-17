-- @description Universal Category Renaming Tool
-- @author Aaron Cendan
-- @version 1.0
-- @metapackage
-- @provides
--   [main] . > acendan_Universal Category Renaming Tool.lua
-- @link https://aaroncendan.me
-- @about
--   # Universal Category Renaming Tool

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS FROM WEB INTERFACE ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Toggle for debugging UCS input with message box
local debug_UCS_Input = false

-- Retrieve stored projextstate data set by web interface
local ret_cat,  ucs_cat  = reaper.GetProjExtState( 0, "UCS_WebInterface", "Category" )
local ret_scat, ucs_scat = reaper.GetProjExtState( 0, "UCS_WebInterface", "Subcategory" )
local ret_id,   ucs_id   = reaper.GetProjExtState( 0, "UCS_WebInterface", "CatID" )
local ret_name, ucs_name = reaper.GetProjExtState( 0, "UCS_WebInterface", "Name" )
local ret_num,  ucs_num  = reaper.GetProjExtState( 0, "UCS_WebInterface", "Number" )
local ret_init, ucs_init = reaper.GetProjExtState( 0, "UCS_WebInterface", "Initials" )
local ret_show, ucs_show = reaper.GetProjExtState( 0, "UCS_WebInterface", "Show" )
local ret_type, ucs_type = reaper.GetProjExtState( 0, "UCS_WebInterface", "userInputItems" )
local ret_area, ucs_area = reaper.GetProjExtState( 0, "UCS_WebInterface", "userInputArea" )

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
-- Ideally, it would be possible to run this on regions
-- that are selected in the Region Render Matrix, but unfortunately, that info is not
-- exposed via the API as of Reaper v6.12
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
            leadingZeroUCSNumStr()
            setFullName()
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
      if isrgn then
        leadingZeroUCSNumStr()
        setFullName()
        reaper.SetProjectMarkerByIndex( 0, i, isrgn, pos, rgnend, markrgnindexnumber, ucs_full_name, color )
        incrementUCSNumStr()
      end
      i = i + 1
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
        reaper.SetProjectMarkerByIndex( 0, i, isrgn, pos, rgnend, markrgnindexnumber, ucs_full_name, color )
        incrementUCSNumStr()
      end
      i = i + 1
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
        if take ~= nil then 
          leadingZeroUCSNumStr()
          setFullName()
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
      if take ~= nil then 
        leadingZeroUCSNumStr()
        setFullName()
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
        leadingZeroUCSNumStr()
        setFullName()
        reaper.GetSetMediaTrackInfo_String( track, "P_NAME", ucs_full_name, true )
        incrementUCSNumStr()
      end
    else
      reaper.MB("No tracks selected!","UCS Renaming Tool", 0)
    end
    
  elseif ucs_area == "All Tracks" then
    for i = 0, num_tracks-1 do
     track = reaper.GetTrack(0,i)
     leadingZeroUCSNumStr()
     setFullName()
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
-- Format: (CatID)_(File Name with Variation Number)_(Initials)_(Show)
function setFullName()
  if ret_show then 
    ucs_full_name = ucs_id .. "_" .. ucs_name .. " " .. ucs_num .. "_" .. ucs_init .. "_" .. ucs_show
  else 
    ucs_full_name = ucs_id .. "_" .. ucs_name .. " " .. ucs_num .. "_" .. ucs_init 
  end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~ Increment Num String ~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
function incrementUCSNumStr()
  ucs_num = tostring(tonumber(ucs_num) + 1)
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~ Add Leading Zero ~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
function leadingZeroUCSNumStr()
  local len = string.len(ucs_num)
  -- While num is < 10, add two leading zeroes. If you would prefer otherwise,
  -- change "00" to "0" or remove leading zeroes entirely by deleting this if/else block
  if len == 1 then 
    ucs_num = "00" .. ucs_num
  elseif len == 2 then
    ucs_num = "0" .. ucs_num
  end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~ Rets to Bools ~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
function ucsRetsToBool()
  if ret_cat  == 1 then ret_cat  = true else ret_cat  = false end
  if ret_scat == 1 then ret_scat = true else ret_scat = false end
  if ret_id   == 1 then ret_id   = true else ret_id   = false end
  if ret_name == 1 then ret_name = true else ret_name = false end
  if ret_num  == 1 then ret_num  = true else ret_num  = false end
  if ret_init == 1 then ret_init = true else ret_init = false end
  if ret_show == 1 then ret_show = true else ret_show = false end
  if ret_type == 1 then ret_type = true else ret_type = false end
  if ret_area == 1 then ret_area = true else ret_area = false end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~ Debug UCS Input ~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
function debugUCSInput()
  reaper.MB("Category: "    .. ucs_cat  .. " (" .. tostring(ret_cat)  .. ")" .. "\n" .. 
            "Subcategory: " .. ucs_scat .. " (" .. tostring(ret_scat) .. ")" .. "\n" .. 
            "CatID: "       .. ucs_id   .. " (" .. tostring(ret_id)   .. ")" .. "\n" .. 
            "Name: "        .. ucs_name .. " (" .. tostring(ret_name) .. ")" .. "\n" .. 
            "Number: "      .. ucs_num  .. " (" .. tostring(ret_num)  .. ")" .. "\n" .. 
            "Initials: "    .. ucs_init .. " (" .. tostring(ret_init) .. ")" .. "\n" .. 
            "Show: "        .. ucs_show .. " (" .. tostring(ret_show) .. ")" .. "\n" .. 
            "Type: "        .. ucs_type .. " (" .. tostring(ret_type) .. ")" .. "\n" .. 
            "Area: "        .. ucs_area .. " (" .. tostring(ret_area) .. ")" .. "\n" 
            , "UCS Renaming Tool", 0)
end


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~~~~~~~~~~  
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
reaper.PreventUIRefresh(1)

parseUCSWebInterfaceInput()

reaper.PreventUIRefresh(-1)

reaper.UpdateArrange()