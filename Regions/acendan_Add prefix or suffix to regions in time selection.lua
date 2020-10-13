-- @description Add prefix or suffix to regions in time selection
-- @author Aaron Cendan
-- @version 1.2
-- @metapackage
-- @provides
--   [main] . > acendan_Add prefix or suffix to regions in time selection.lua
-- @link https://aaroncendan.me
-- @changelog Fixed isolated pre/suff usage

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Get this script's name and directory
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local script_directory = ({reaper.get_action_context()})[2]:sub(1,({reaper.get_action_context()})[2]:find("\\[^\\]*$"))

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function main()
  -- Loop through regions in time selection
  local ret, num_markers, num_regions = reaper.CountProjectMarkers( 0 )
  local num_total = num_markers + num_regions
  local start_time_sel, end_time_sel = reaper.GetSet_LoopTimeRange(0,0,0,0,0);
  
  if num_regions > 0 then
    -- Multiple fields
    local ret_input, user_input = reaper.GetUserInputs( script_name, 2,
                              "Prefix,Suffix" .. ",extrawidth=100",
                              "," )
    if not ret_input then return end

    if user_input:find(",") == 1 then 
      -- NO PREFIX INCLUDED
      in_prefix = ""
      in_suffix = user_input:sub(2,user_input:len())
    elseif user_input:find(",") == user_input:len() then
      -- NO SUFFIX INCLUDED
      in_prefix = user_input:sub(1,user_input:len()-1)
      in_suffix = ""
    else
      -- BOTH INCLUDED
      in_prefix, in_suffix = user_input:match("([^,]+),([^,]+)")
    end
    
    if start_time_sel ~= end_time_sel then
      local i = 0
      while i < num_total do
        local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, i )
        if isrgn then
          if pos >= start_time_sel and rgnend <= end_time_sel then
            reaper.SetProjectMarker3( 0, markrgnindexnumber, isrgn, pos, rgnend, in_prefix .. name .. in_suffix, color )
          end
        end
        i = i + 1
      end
    else
      local i = 0
      while i < num_total do
        local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, i )
        if isrgn then
          -- Process region
          reaper.SetProjectMarker3( 0, markrgnindexnumber, isrgn, pos, rgnend, in_prefix .. name .. in_suffix, color )
        end
        i = i + 1
      end
    end
  else
    msg("Project has no regions!")
  end
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

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock()

main()

reaper.Undo_EndBlock(script_name,-1)

reaper.PreventUIRefresh(-1)

reaper.UpdateArrange()
