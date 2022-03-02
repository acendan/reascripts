-- @description Move Project Markers
-- @author Aaron Cendan
-- @version 1.0
-- @metapackage
-- @provides
--   [main] .
-- @link https://ko-fi.com/acendan_
-- @about
--   # Lua Utilities
-- @changelog
--   # Added tableCountOccurrences

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~ USER CONFIG - EDIT ME ~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Get this script's name and directory
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local script_directory = ({reaper.get_action_context()})[2]:sub(1,({reaper.get_action_context()})[2]:find("\\[^\\]*$"))

-- Load lua utilities
acendan_LuaUtils = reaper.GetResourcePath()..'/scripts/ACendan Scripts/Development/acendan_Lua Utilities.lua'
if reaper.file_exists( acendan_LuaUtils ) then dofile( acendan_LuaUtils ); if not acendan or acendan.version() < 4.4 then acendan.msg('This script requires a newer version of ACendan Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"ACendan Lua Utilities"); return end else reaper.ShowConsoleMsg("This script requires ACendan Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'ACendan Lua Utilities'"); return end


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function main()
  -- Loop through all markers
  local ret, num_markers, num_regions = reaper.CountProjectMarkers( 0 )
  local num_total = num_markers + num_regions
  if num_markers > 0 then
    -- Prompt for user input
    local ret_input, user_input = reaper.GetUserInputs( "Move Markers", 2,
                              "All Mkrs (a) or Time Sel (t),Marker Pos Offset" .. ",extrawidth=100",
                              "a,0.0" )
    if not ret_input then return end
    local all_or_ts, pos_off = user_input:match("([^,]+),([^,]+)")
    pos_off = tonumber(pos_off)
    
    if all_or_ts == "t" then
      start_time_sel, end_time_sel = reaper.GetSet_LoopTimeRange(0,0,0,0,0);
      if start_time_sel == end_time_sel then 
        acendan.msg("You need to make a time selection!")
        return
      end
    end
    
    -- Loop through markers
    local i = 0
    while i < num_total do
      local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, i )
      local new_pos = pos + pos_off
      if new_pos < 0 then new_pos = 0 end
      
      if not isrgn then
        -- Move markers in time selection
        if all_or_ts == "t" then
          if (pos >= start_time_sel) and (pos <= end_time_sel) then
            reaper.SetProjectMarker3( 0, markrgnindexnumber, isrgn, new_pos, new_pos, name, color )
          end
          
        -- Move all project markers
        else
          reaper.SetProjectMarker3( 0, markrgnindexnumber, isrgn, new_pos, new_pos, name, color )
        end
      end
      i = i + 1
    end
  else
    acendan.msg("Project has no markers!")
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
