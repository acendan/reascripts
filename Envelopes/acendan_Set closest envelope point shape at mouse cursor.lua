-- @description Set Env Shape at Cursor
-- @author Aaron Cendan
-- @version 1.1
-- @metapackage
-- @provides
--   [main] . > acendan_Set closest envelope points shape at mouse cursor - Bezier.lua
--   [main] . > acendan_Set closest envelope points shape at mouse cursor - Fast End.lua
--   [main] . > acendan_Set closest envelope points shape at mouse cursor - Fast Start.lua
--   [main] . > acendan_Set closest envelope points shape at mouse cursor - Linear.lua
--   [main] . > acendan_Set closest envelope points shape at mouse cursor - Slow Start End.lua
--   [main] . > acendan_Set closest envelope points shape at mouse cursor - Square.lua
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
  
  -- Focus arrange window for compatibility with contextual toolbars
  reaper.Main_OnCommand(reaper.NamedCommandLookup("_BR_FOCUS_ARRANGE_WND"),0)
  
  -- Get cursor pos
  local window, segment, details = reaper.BR_GetMouseCursorContext()
  local mouse_cursor_pos = reaper.BR_GetMouseCursorContext_Position()
 
  -- Get envelope under cursor
  reaper.Main_OnCommand(reaper.NamedCommandLookup("_BR_SEL_ENV_MOUSE"),0) -- SWS/BR: Select envelope at mouse cursor
  local envelope = reaper.GetSelectedEnvelope(0)
  if envelope then 
  
    -- Unselect all selected points on envelope
    local num_pts = reaper.CountEnvelopePoints(envelope)
    for i = 1, num_pts do
      reaper.SetEnvelopePoint( envelope, i, time, value, shape, tension, false )
    end
    
    -- Get shape from script name
    if script_name:find("Linear") then
      env_shape = 0
    elseif script_name:find("Square") then
      env_shape = 1
    elseif script_name:find("Slow Start End") then
      env_shape = 2
    elseif script_name:find("Fast Start") then
      env_shape = 3
    elseif script_name:find("Fast End") then
      env_shape = 4
    elseif script_name:find("Bezier") then
      env_shape = 5
    else
      env_shape = 0
    end
  
    -- Set nearest point selected, set curve
    local nearest_point =  reaper.GetEnvelopePointByTime( envelope, mouse_cursor_pos )
    local retval, time, value, shape, tension, selected = reaper.GetEnvelopePoint( envelope, nearest_point )
    if retval then reaper.SetEnvelopePoint( envelope, nearest_point, time, value, env_shape, tension, true ) end
  
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
