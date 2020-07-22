-- @description Extend right edge of time selection by x seconds
-- @author Aaron Cendan
-- @version 1.0
-- @metapackage
-- @provides
--   [main] . > acendan_Extend right edge of time selection by 1 second.lua
--   [main] . > acendan_Extend right edge of time selection by 2 seconds.lua
--   [main] . > acendan_Extend right edge of time selection by 3 seconds.lua
--   [main] . > acendan_Extend right edge of time selection by 4 seconds.lua
--   [main] . > acendan_Extend right edge of time selection by 5 seconds.lua
-- @link https://aaroncendan.me
-- @about
--   # Extend right edge of time seleciton by x seconds
-- 	 * Change number of seconds by copying script and changing number value in script name

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

num_seconds = 0

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function extendRightEdge()
  local start_time, end_time = reaper.GetSet_LoopTimeRange( 0, 0, 0, 0, 0 )
  if type(num_seconds) == "number" then
    reaper.GetSet_LoopTimeRange( 1, 0, start_time , end_time + num_seconds, 0 )
  end
end


-- Get number from script name
function extractNumberInScriptName()
  local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
  num_seconds = tonumber(string.match(script_name, "%d+"))
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock()

extractNumberInScriptName()

extendRightEdge()

reaper.Undo_EndBlock("Extend Right Edge",-1)

reaper.PreventUIRefresh(-1)

reaper.UpdateArrange()
