-- @description Enumerate Regions
-- @author Aaron Cendan
-- @version 1.4
-- @metapackage
-- @provides
--   [main] . > acendan_Enumerate regions in project.lua
-- @link https://aaroncendan.me
-- @about
--   * This script requires ACendan Lua Utilities!!! 
--   * There are quite a few options in this script, so I recommend messing around in a test project.
--   * "Only Repeated Regions" will restart enumeration for repeated names and SKIP enumerating one-off/single occurrences
--   * Also set up recall using extstates. Didn't do it very efficiently but whatever I'm tired.
-- @changelog
--   # Update LuaUtils path with case sensitivity for Linux

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Get this script's name and directory
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local script_directory = ({reaper.get_action_context()})[2]:sub(1,({reaper.get_action_context()})[2]:find("\\[^\\]*$"))

-- Load lua utilities
local function loadUtilities(file); local E,A=pcall(dofile,file); if not(E)then return end; return A; end
local acendan = loadUtilities((reaper.GetResourcePath()..'/Scripts/ACendan Scripts/Development/acendan_Lua Utilities.lua'):gsub('\\','/'))
if not acendan then reaper.MB("This script requires ACendan Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'ACendan Lua Utilities'","ACendan Lua Utilities",0); return end
if acendan.version() < 3.0 then acendan.msg('This script requires a newer version of ACendan Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"ACendan Lua Utilities"); return end

-- Init repeats table
local singles_table = {}
local repeats_table = {}
local allrgns_table = {}

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function main()
  -- Get num regions
  local ret, num_markers, num_regions = reaper.CountProjectMarkers( 0 )
  if not ret or num_regions < 1 then acendan.msg("Project has no regions!"); return end
  local num_total = num_markers + num_regions
  
  -- Get extstates or default placeholders
  local _, plc_enum = reaper.GetProjExtState(0,"acendan_EnumRegions","enumerator")
  if plc_enum == "" then plc_enum = "01" end
  local _, plc_sep = reaper.GetProjExtState(0,"acendan_EnumRegions","separator")
  if plc_sep == "" then plc_sep = "_" end
  local _, plc_place = reaper.GetProjExtState(0,"acendan_EnumRegions","placement")
  if plc_place == "" then plc_place = "e" end
  local _, plc_sect = reaper.GetProjExtState(0,"acendan_EnumRegions","section")
  if plc_sect == "" then plc_sect = "p" end
  local _, plc_rep = reaper.GetProjExtState(0,"acendan_EnumRegions","repeats_mode")
  if plc_rep == "" then plc_rep = "n" end

  -- Get user input
  local ret_input, user_input = reaper.GetUserInputs( "Enumerate Regions", 5,
                            "Starting Number,Separator,Start (s) or End (e) of Name,Proj (p) Time (t) or Manager (m),Only Repeated Regions (y/n)" .. ",extrawidth=100",
                            plc_enum..","..plc_sep..","..plc_place..","..plc_sect..","..plc_rep )
  if not ret_input then return end
  enumerator, separator, placement, section, repeats_mode = user_input:match("([^,]+),([^,]+),([^,]+),([^,]+),([^,]+)")
  
  -- Set extstates
  reaper.SetProjExtState(0,"acendan_EnumRegions","enumerator",enumerator)
  reaper.SetProjExtState(0,"acendan_EnumRegions","separator",separator)
  reaper.SetProjExtState(0,"acendan_EnumRegions","placement",placement)
  reaper.SetProjExtState(0,"acendan_EnumRegions","section",section)
  reaper.SetProjExtState(0,"acendan_EnumRegions","repeats_mode",repeats_mode)
  
  -- Build table of repeated names
  if repeats_mode == "y" then buildRepeatsTable(num_total,num_regions) end
  
  -- Check for leading zero
  if (tonumber(enumerator:sub(1,1)) == 0) then
    leading_zero = true
    enumerator = tonumber(enumerator:sub(2))
    -- acendan.msg("LEADING ZERO!\n"..tostring(enumerator))
  else
    leading_zero = false
    enumerator = tonumber(enumerator)
    -- acendan.msg("NO LEADING ZERO!\n"..tostring(enumerator))
  end
  
  -- Split by section (default to project)
  if section == "m" then
    -- Iterate through selected regions
    local sel_rgn_table = acendan.getSelectedRegions()
    if sel_rgn_table then 
      for _, regionidx in pairs(sel_rgn_table) do 
        local i = 0
        while i < num_total do
          local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, i )
          if isrgn and markrgnindexnumber == regionidx then
            reaper.SetProjectMarkerByIndex( 0, i, isrgn, pos, rgnend, markrgnindexnumber, getEnumeratedName(name), color )
            incrementNumStr()
            break
          end
          i = i + 1
        end
      end
    else
      acendan.msg("No regions selected!\n\nPlease go to View > Region/Marker Manager to select regions.\n\n\nIf you are on mac... sorry but there is a bug that prevents this script from working. Out of my control :(") 
    end
  elseif section == "t" then
    -- Loop through regions in time selection
    local start_time_sel, end_time_sel = reaper.GetSet_LoopTimeRange(0,0,0,0,0);
    if start_time_sel ~= end_time_sel then
      local i = 0
      while i < num_total do
        local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, i )
        if isrgn then
          if pos >= start_time_sel and rgnend <= end_time_sel then
            reaper.SetProjectMarkerByIndex( 0, i, isrgn, pos, rgnend, markrgnindexnumber, getEnumeratedName(name), color )
            incrementNumStr()
          end
        end
        i = i + 1
      end
    else
      msg("You need to make a time selection!")
    end
  else
    -- Loop through all regions
    local i = 0
    while i < num_total do
      local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, i )
      if isrgn then
        reaper.SetProjectMarkerByIndex( 0, i, isrgn, pos, rgnend, markrgnindexnumber, getEnumeratedName(name), color )
        incrementNumStr()
      end
      i = i + 1
    end
  end
  
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ UTILITIES ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function buildRepeatsTable(num_total,num_regions)
  if num_regions > 0 then
    local i = 0
    while i < num_total do
      local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, i )
      if isrgn then
        -- Check if this name is in the singles table but NOT yet in the repeats table
        if not acendan.tableContainsVal(repeats_table,name) and acendan.tableContainsVal(singles_table,name) then
          acendan.tableAppend(repeats_table,name)
        
        -- Not in either singles or repeats, so add to singles
        elseif not acendan.tableContainsVal(singles_table,name) then
          acendan.tableAppend(singles_table,name)
        end
      end
      i = i + 1
    end
  end
end

-- Takes in current region name, then returns new, enumerated name
function getEnumeratedName(rgn_name)
  -- Deal with repeated names
  if repeats_mode == "y" then
    acendan.tableAppend(allrgns_table,rgn_name)
    
    -- Check to see if this name is repeated
    if acendan.tableContainsVal(repeats_table,rgn_name) then
      -- Count num of occurrences in table with all regions
      local occurrences = tostring(acendan.tableCountOccurrences(allrgns_table,rgn_name))
      
      -- Leading zero
      if leadingZero then if string.len(occurrences) == 1 then occurrences = "0" .. occurrences end end
      
      -- Enumerate at start vs end of region
      if placement == "s" then return occurrences .. separator .. rgn_name else return rgn_name .. separator .. occurrences end
    else
      -- This is a one-off single occurrence. Don't enumerate.
      return rgn_name
    end
  else
    -- Prepend leading zero to enumeration
    if leading_zero then leadingZero() end
    
    -- Enumerate at start vs end of region
    if placement == "s" then return enumerator .. separator .. rgn_name else return rgn_name .. separator .. enumerator end
  end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~ Increment Num String ~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
function incrementNumStr()
  enumerator = tostring(tonumber(enumerator) + 1)
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~ Add Leading Zero ~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
function leadingZero()
  local len = string.len(enumerator)
  -- While num is < 10, add one leading zero. If you would prefer otherwise,
  -- change "0" to "00" and/or remove leading zeroes entirely by deleting this if/else block.
  -- "len" = the number of digits in the number.
  if len == 1 then 
    enumerator = "0" .. enumerator
  --elseif len == 2 then
    --ucs_num = "0" .. ucs_num
  end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock()

main()

reaper.Undo_EndBlock(script_name,-1)

reaper.PreventUIRefresh(-1)

reaper.UpdateArrange()

