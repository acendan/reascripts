-- @description Razor Edit Edges
-- @author Aaron Cendan
-- @version 1.0
-- @metapackage
-- @provides
--   [main] . > acendan_Snap edit cursor to nearest razor edit edge in first selected track.lua
-- @link https://aaroncendan.me

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
  -- Snap edit cursor to nearest razor edit edge
  local track = reaper.GetSelectedTrack(0, 0)        -- First selected track
  if track then
    local _, razor_edit = reaper.GetSetMediaTrackInfo_String(track, 'P_RAZOREDITS', '', false)
    if razor_edit ~= '' then
        -- Build table of razor edit edge positions
        local positions={}
        for pos in string.gmatch(razor_edit, "([^%s]+)") do
          if not pos:find('"') then 
            table.insert(positions, tonumber(pos))
          end
        end
        
        -- Snap edit cursor to nearest pos
        local cursor_pos = reaper.GetCursorPosition()
        local _, nearest_pos = NearestValue(positions, cursor_pos)
        if nearest_pos then reaper.SetEditCurPos(nearest_pos, true, false) end
    end
  end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ UTILITIES ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Find nearest value in table, courtesy of:
-- https://stackoverflow.com/questions/29987249/find-the-nearest-value
function NearestValue(table, number)
    local smallestSoFar, smallestIndex
    for i, y in ipairs(table) do
        if not smallestSoFar or (math.abs(number-y) < smallestSoFar) then
            smallestSoFar = math.abs(number-y)
            smallestIndex = i
        end
    end
    return smallestIndex, table[smallestIndex]
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
