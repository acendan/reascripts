-- @description Enumerate Regions
-- @author Aaron Cendan
-- @version 1.0
-- @metapackage
-- @provides
--   [main] . > acendan_Enumerate selected regions in manager.lua
-- @link https://aaroncendan.me
-- @about
--   This script requires ACendan Lua Utilities!!! 
--   Also... it will only work on Windows because there's a bug with Mac that prevents me from getting
--   the selected regions in the region/marker manager... :(


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Get this script's name and directory
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local script_directory = ({reaper.get_action_context()})[2]:sub(1,({reaper.get_action_context()})[2]:find("\\[^\\]*$"))

-- Load lua utilities
local function loadUtilities(file); local E,A=pcall(dofile,file); if not(E)then return end; return A; end
local acendan = loadUtilities((reaper.GetResourcePath()..'/scripts/ACendan Scripts/Development/acendan_Lua Utilities.lua'):gsub('\\','/'))
if not acendan then reaper.MB("This script requires ACendan Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'ACendan Lua Utilities'","ACendan Lua Utilities",0); return end
if acendan.version() < 3.0 then acendan.msg('This script requires a newer version of ACendan Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"ACendan Lua Utilities"); return end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function main()
  -- Get user input
  local ret_input, user_input = reaper.GetUserInputs( "Enumerate Regions", 2,
                            "Starting Number,Space (s) or Underscore (_)" .. ",extrawidth=25",
                            "01,_" )
  if not ret_input then return end
  enumerator, prefix = user_input:match("([^,]+),([^,]+)")
  
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
  
  -- Set up prefix
  if prefix == "s" then prefix = " " else prefix = "_" end
  
  -- Iterate through regions
  local sel_rgn_table = acendan.getSelectedRegions()
  if sel_rgn_table then 
    local ret, num_markers, num_regions = reaper.CountProjectMarkers( 0 )
    local num_total = num_markers + num_regions
    
    for _, regionidx in pairs(sel_rgn_table) do 
      local i = 0
      while i < num_total do
        local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, i )
        if isrgn and markrgnindexnumber == regionidx then
          if leading_zero then leadingZero() end
          reaper.SetProjectMarkerByIndex( 0, i, isrgn, pos, rgnend, markrgnindexnumber, name .. prefix .. enumerator, color )
          incrementNumStr()
          break
        end
        i = i + 1
      end
    end
  else
    acendan.msg("No regions selected!\n\nPlease go to View > Region/Marker Manager to select regions.\n\n\nIf you are on mac... sorry but there is a bug that prevents this script from working. Out of my control :(") 
  end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ UTILITIES ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

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

