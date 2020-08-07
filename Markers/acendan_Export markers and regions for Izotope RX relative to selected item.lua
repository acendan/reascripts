-- @noindex

-- @description Export Markers and Regions for RX
-- @author Aaron Cendan
-- @version 1.1
-- @metapackage
-- @provides
--   [main] . > acendan_Export markers and regions for Izotope RX relative to selected item.lua
-- @link https://aaroncendan.me
-- @about
--   # Lua Utilities
--   By Aaron Cendan - July 2020
--   * Adapted from XRaym's script: Export markers and regions to tab-delimited CSV file

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ VARIABLES ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Copy file path to clipboard on save
local copy_path = true

-- Show copy path notification message
local copy_path_notification = true

-- Get script name for undo text and extracting numbers/other info, if needed
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function Main()

  local f = io.open(file, "w")
  
  export(f,"Marker file version: 1")
  export(f,"Time format: Time")
  
  local item_start = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
  local item_end = item_start + reaper.GetMediaItemInfo_Value( item, "D_LENGTH" )
  
  i=0
  repeat
    iRetval, bIsrgnOut, iPosOut, iRgnendOut, name, iMarkrgnindexnumberOut, iColorOur = reaper.EnumProjectMarkers3(0,i)
    if iRetval >= 1 then
      local t, duration
      if bIsrgnOut then
        -- REGIONS
        if (name == "") then name = "Region " .. iMarkrgnindexnumberOut end
        
        -- If region starts in time frame of item bounds
        if (iPosOut >= item_start) and (iPosOut <= item_end) then
          -- Clamp end if necessary
          if not (iRgnendOut <= item_end) then iRgnendOut = item_end end
          
          local rel_start_pos = iPosOut - item_start
          local rel_end_pos = iRgnendOut - item_start
          
          -- [Region 2  00:00:24.00000000  00:00:33.50829167]
          line = name .. "\t" .. rel_start_pos .. "\t" .. rel_end_pos
          export(f, line)
        
        -- Else if region ends in time frame of item bounds
        elseif (iRgnendOut >= item_start) and (iRgnendOut <= item_end) then
          -- Clamp start if necessary
          if not (iPosOut >= item_start) then iPosOut = item_start end
        
          local rel_start_pos = iPosOut - item_start
          local rel_end_pos = iRgnendOut - item_start
        
          -- [Region 2  00:00:24.00000000  00:00:33.50829167]
          line = name .. "\t" .. rel_start_pos .. "\t" .. rel_end_pos
          export(f, line)
        end
      
      else 
        -- MARKERS
        if (name == "") then name = "Marker " .. iMarkrgnindexnumberOut end
        
        -- If marker is in time frame of item bounds
        if (iPosOut >= item_start) and (iPosOut <= item_end) then
          
          local rel_pos = iPosOut - item_start
          
          -- [Marker 1  00:00:16.00000000]
          line = name .. "\t" .. rel_pos
          export(f, line)
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
if not reaper.JS_Dialog_BrowseForSaveFile then
  msg("Please install JS_ReaScript REAPER extension, available in Reapack extension, under ReaTeam Extensions repository.")
else

  local num_sel_items = reaper.CountSelectedMediaItems(0)
  if num_sel_items > 0 then
    item = reaper.GetSelectedMediaItem( 0, 0 )
    local ret, item_name = reaper.GetSetMediaItemTakeInfo_String( reaper.GetActiveTake( item ), "P_NAME", "", false )
    if not ret then item_name = "" end
    
    local project_directory = getProjDir()
    retval, file = reaper.JS_Dialog_BrowseForSaveFile( "Export Markers and Regions for RX", project_directory, "Markers and Regions - " .. item_name .. ".txt", 'Text Files (.txt)\0*.csv\0All Files (*.*)\0*.*\0' )
    
    if retval and file ~= '' then
      if not file:find('.txt') then file = file .. ".txt" end
      if copy_path then
        reaper.CF_SetClipboard( file )
        if copy_path_notification then
          msg("File path copied to clipboard!\n\nTo disable this, click 'Edit Action' and set the 'copy_path' variable to false.")
        end
      end
      reaper.defer(Main)
    end
  else
    msg("No item selected!")
  end
end

reaper.Undo_EndBlock(script_name,-1)

reaper.PreventUIRefresh(-1)

reaper.UpdateArrange()