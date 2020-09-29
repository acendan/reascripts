-- @description NVK Game Audio Affirmations Once An Hour
-- @author Aaron Cendan
-- @version 1.1
-- @metapackage
-- @provides
--   [main] . > acendan_Randomly deliver nvk_Game Audio Affirmations once an hour.lua
-- @link https://aaroncendan.me
-- @about
--   # This is a background/toggle script!
--   By Aaron Cendan - Sept 2020
--
--   ### Credits
--   * All credit to Nick von Kaenel for writing the Game Audio Affirmations script. You're a legend.
--
--   ### Notes
--   * When prompted if you want to terminate instances, click the little checkbox then terminate.

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Get action context info
local _, _, section, cmdID = reaper.get_action_context()

-- Refresh rate (random second within an hour), starting with somewhere between 0.5 and 1hr
local refresh_rate = math.random(1800,3600)

-- Get this script's name and directory
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local script_directory = ({reaper.get_action_context()})[2]:sub(1,({reaper.get_action_context()})[2]:find("\\[^\\]*$"))

-- NVK Affirmations
local nvk_affirmations = reaper.NamedCommandLookup("_RS494410d201156d124966a3a080d98a5686df4abb")
if nvk_affirmations == 0 then script_located = false else script_located = true end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function setup()
  -- Timing control
  local start = reaper.time_precise()
  check_time = start
  
  -- Toggle command state on
  reaper.SetToggleCommandState( section, cmdID, 1 )
  reaper.RefreshToolbar2( section, cmdID )
end


function main()
  -- System time in seconds (3600 per hour)
  local now = reaper.time_precise()
  
  if now - check_time >= refresh_rate then

    -- Script: nvk_MISC - Game Audio Affirmations.lua
    reaper.Main_OnCommand(nvk_affirmations,0)

    -- Reseed refresh rate (okay technically this is actually a window of 45min - 1hr45min but whatever)
    refresh_rate = 2400 + math.random(1,3600)
    
    -- Reset last used time
    check_time = now
  end

  reaper.defer(main)
end

function Exit()
  reaper.UpdateArrange()
  reaper.SetToggleCommandState( section, cmdID, 0 )
  reaper.RefreshToolbar2( section, cmdID )
  return reaper.defer(function() end)
end

if script_located then
  setup()
  reaper.atexit(Exit)
  main()
else
  reaper.MB("Unable to locate 'nvk_MISC - Game Audio Affirmations.lua'. Please install it via ReaPack!\n\nCancelling random delivery.","",0)
end
