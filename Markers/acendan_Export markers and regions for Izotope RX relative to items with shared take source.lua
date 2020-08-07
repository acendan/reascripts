-- @description Export Markers and Regions for RX
-- @author Aaron Cendan
-- @version 1.0
-- @metapackage
-- @provides
--   [main] . > acendan_Export markers and regions for Izotope RX relative to items with shared take source.lua
-- @link https://aaroncendan.me
-- @about
--   # Lua Utilities
--   By Aaron Cendan - July 2020
--   * Adapted from XRaym's script: Export markers and regions to tab-delimited CSV file

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Get script name for undo text and extracting numbers/other info, if needed
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function Main()

  local f = io.open(file, "w")
  
  export(f,"Marker file version: 1")
  export(f,"Time format: Time")
  
  -- Loop through all markers and regions
  i=0
  repeat
    iRetval, bIsrgnOut, iPosOut, iRgnendOut, name, iMarkrgnindexnumberOut, iColorOur = reaper.EnumProjectMarkers3(0,i)
    if iRetval >= 1 then

      if bIsrgnOut then
        -- REGIONS
        -- Loop through item bounds tables to validate position
        if (name == "") then name = "Region " .. iMarkrgnindexnumberOut end
        
        for idx, it_bounds in pairs(item_bounds) do
          local item_start, item_end = it_bounds:match("([^,]+),([^,]+)")
          item_start = tonumber(item_start)
          item_end = tonumber(item_end)
          
          -- If region starts in time frame of item bounds
          if (iPosOut >= item_start) and (iPosOut <= item_end) then
            -- Clamp end if necessary
            if not (iRgnendOut <= item_end) then iRgnendOut = item_end end
            
            local rel_start_pos = iPosOut - item_start + item_offsets[idx]
            local rel_end_pos = iRgnendOut - item_start + item_offsets[idx]
            
            -- [Region 2  00:00:24.00000000  00:00:33.50829167]
            line = name .. "\t" .. rel_start_pos .. "\t" .. rel_end_pos
            export(f, line)
            break
          -- Else if region ends in time frame of item bounds
          elseif (iRgnendOut >= item_start) and (iRgnendOut <= item_end) then
            -- Clamp start if necessary
            if not (iPosOut >= item_start) then iPosOut = item_start end
          
            local rel_start_pos = iPosOut - item_start + item_offsets[idx]
            local rel_end_pos = iRgnendOut - item_start + item_offsets[idx]
          
            -- [Region 2  00:00:24.00000000  00:00:33.50829167]
            line = name .. "\t" .. rel_start_pos .. "\t" .. rel_end_pos
            export(f, line)
            break
          end
        end
      
      else 
        -- MARKERS
        -- Loop through item bounds tables to validate position
        if (name == "") then name = "Marker " .. iMarkrgnindexnumberOut end
        
        for idx, it_bounds in pairs(item_bounds) do
          local item_start, item_end = it_bounds:match("([^,]+),([^,]+)")
          item_start = tonumber(item_start)
          item_end = tonumber(item_end)
          
          if (iPosOut >= item_start) and (iPosOut <= item_end) then
            local rel_pos = iPosOut - item_start + item_offsets[idx]
            
            -- [Marker 1  00:00:16.00000000]
            line = name .. "\t" .. rel_pos
            export(f, line)
            break -- Exit for loop
          end
        end
      end
    end
    i = i+1
  until iRetval == 0

  -- CLOSE FILE
  f:close() -- never forget to close the file
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
  reaper.MB(msg, script_name, 0)
end

-- Write line to file
function export(f, variable)
  f:write(variable)
  f:write("\n")
end

-- Get directory of active Reaper project, returns blank if not saved
function getProjDir()
  if reaper.GetOS() == "Win32" or reaper.GetOS() == "Win64" then
    separator = "\\"
  else
    separator = "/"
  end
  retval, project_path_name = reaper.EnumProjects(-1, "")
  if project_path_name ~= "" then
    dir = project_path_name:match("(.*" .. separator ..")")
    return dir
  else
    return ""
  end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock()

-- Check for Reaper JS Extension
if reaper.JS_Dialog_BrowseForSaveFile then

  local num_sel_items = reaper.CountSelectedMediaItems(0)
  if num_sel_items > 0 then
    -- Get parent info from first selected item
    parent_item = reaper.GetSelectedMediaItem( 0, 0 )
    parent_source = reaper.GetMediaItemTake_Source( reaper.GetActiveTake( parent_item ) )
    ret, parent_item_name = reaper.GetSetMediaItemTakeInfo_String( reaper.GetActiveTake( parent_item ), "P_NAME", "", false )
    if not ret then parent_item_name = "" end
    
    -- Iterate through all items with the same parent source
    local archie_action = reaper.NamedCommandLookup("_RS88d4e973f6a85ec8cc3485ba9fef91f6c940abde")
    if archie_action then
      reaper.Main_OnCommand(40289,0)                   -- Unselect all items
      reaper.SetMediaItemSelected( parent_item, true ) -- Reselect parent item
      reaper.Main_OnCommand(archie_action,0)           -- Archie_Item: Select All Items in Project with Sources of Selected Items
      
      -- Recount num selected items
      num_sel_items = reaper.CountSelectedMediaItems(0)
      
      -- Build item bounds tables 
      item_bounds = {}
      item_offsets = {}
      for i=0, num_sel_items - 1 do
        local item = reaper.GetSelectedMediaItem( 0, i )
        local take = reaper.GetActiveTake( item )
        if take ~= nil then 
          local it_start = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
          local it_end = reaper.GetMediaItemInfo_Value( item, "D_POSITION" ) + reaper.GetMediaItemInfo_Value( item, "D_LENGTH" )
          
          item_bounds[#item_bounds+1] = it_start .. "," .. it_end
          item_offsets[#item_offsets+1] = reaper.GetMediaItemTakeInfo_Value( reaper.GetActiveTake( item ), "D_STARTOFFS" )
        end
      end
      
      local project_directory = getProjDir()
      retval, file = reaper.JS_Dialog_BrowseForSaveFile( "Export Markers and Regions for RX", project_directory, "Markers and Regions - " .. parent_item_name, 'Text Files (.txt)\0*.csv\0All Files (*.*)\0*.*\0' )
      
      if retval and file ~= '' then
        if not file:find('.txt') then file = file .. ".txt" end
        reaper.defer(Main)
      end
    
    else
      msg("Please install the script: 'Archie_Item: Select All Items in Project with Sources of Selected Items' in ReaPack\n\nhttps://github.com/ArchieScript/Archie_ReaScripts/raw/master/index.xml")
    end
  else
    msg("No item selected!")
  end
else
  msg("Please install JS_ReaScript REAPER extension, available in Reapack extension, under ReaTeam Extensions repository.")
end

reaper.Undo_EndBlock(script_name,-1)

reaper.PreventUIRefresh(-1)

reaper.UpdateArrange()
