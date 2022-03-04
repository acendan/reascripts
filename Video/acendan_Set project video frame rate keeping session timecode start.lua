-- @description Set Project Frame Rate
-- @author Aaron Cendan
-- @version 1.0
-- @changelog Add a "set to 0" action
-- @provides
--   .
--   [main] . > acendan_Set project video frame rate keeping session timecode start (23.976).lua
--   [main] . > acendan_Set project video frame rate keeping session timecode start (24).lua
--   [main] . > acendan_Set project video frame rate keeping session timecode start (25).lua
--   [main] . > acendan_Set project video frame rate keeping session timecode start (29.97ND).lua
--   [main] . > acendan_Set project video frame rate keeping session timecode start (29.97DF).lua
--   [main] . > acendan_Set project video frame rate keeping session timecode start (30).lua
--   [main] . > acendan_Set project video frame rate keeping session timecode start (48).lua
--   [main] . > acendan_Set project video frame rate keeping session timecode start (50).lua
--   [main] . > acendan_Set project video frame rate keeping session timecode start (60).lua
--   [main] . > acendan_Set project video frame rate keeping session timecode start (75).lua
-- @link https://ko-fi.com/acendan_
-- @about
--   # Modified from cfillion's Script: cfillion_Set timecode at edit cursor.lua

-- Load Ultraschall API
ultraschall_path = reaper.GetResourcePath().."/UserPlugins/ultraschall_api.lua"
if reaper.file_exists( ultraschall_path ) then dofile( ultraschall_path ) else reaper.ShowConsoleMsg("This script requires the Ultraschall API, available via Reapack. Extensions > ReaPack > Import Repositories:\n\nhttps://raw.githubusercontent.com/Ultraschall/ultraschall-lua-api-for-reaper/master/ultraschall_api_index.xml"); return end

local SCRIPT_NAME = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")

local PROJECT_FRAMERATE = ({
  ['23.976'    ] =  -1,
  ['29.97ND' ] =  -2,
  ['29.97DF'  ] =  0,
  ['24'] = 24,
  ['25'] = 25,
  ['30'] = 30,
  ['48'] = 48,
  ['50'] = 50,
  ['60'] = 60,
  ['75'] = 75
})[SCRIPT_NAME:match('%(([^%)]+)%)') or '24']

assert(PROJECT_FRAMERATE, "Internal error: unknown timecode format")
assert(reaper.SNM_GetDoubleConfigVar, "SWS is required to use this script")

-- Save and recall cursor
init_cur_pos = reaper.GetCursorPosition()

-- Get original session start timecode
reaper.Main_OnCommand(40042,0) -- Transport: Go to start of project
local curpos = reaper.GetCursorPosition()
local timecode = 0
timecode = reaper.format_timestr_pos(curpos, '', 5) --5 = frames mode
timecode = reaper.parse_timestr_len(timecode, 0, 5)

-- Set new frame rate using Ultraschall API
local retval = ultraschall.ProjectSettings_SetVideoFramerate(PROJECT_FRAMERATE, false)

-- Set session start timecode
reaper.SNM_SetDoubleConfigVar('projtimeoffs', timecode - curpos)

reaper.SetEditCurPos(init_cur_pos,false,false)
reaper.UpdateTimeline()
