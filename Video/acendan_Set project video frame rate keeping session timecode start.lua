-- @description Set Project Frame Rate
-- @author Aaron Cendan
-- @version 1.1
-- @changelog Reaper really just hates 23.976, huh...
-- @provides
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

-- Load lua utilities
acendan_LuaUtils = reaper.GetResourcePath()..'/scripts/ACendan Scripts/Development/acendan_Lua Utilities.lua'
if reaper.file_exists( acendan_LuaUtils ) then dofile( acendan_LuaUtils ); if not acendan or acendan.version() < 4.4 then acendan.msg('This script requires a newer version of ACendan Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"ACendan Lua Utilities"); return end else reaper.ShowConsoleMsg("This script requires ACendan Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'ACendan Lua Utilities'"); return end

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

local dbg = false
if dbg then acendan.dbg("____" .. SCRIPT_NAME:match('%(([^%)]+)%)') .. "______") end

-- Get original session start timecode
local proj_timeoffset = reaper.GetProjectTimeOffset(0, true)
if dbg then acendan.dbg("Initial proj time offset: " .. tostring(proj_timeoffset)) end

-- Set new frame rate using Ultraschall API
local retval = ultraschall.ProjectSettings_SetVideoFramerate(PROJECT_FRAMERATE, false)
reaper.UpdateTimeline()
reaper.UpdateArrange()

local after_setvideoframerate = reaper.GetProjectTimeOffset(0, true)
if dbg then acendan.dbg("After set project framerate: " .. tostring(after_setvideoframerate)) end

-- Set session start timecode
local reaper_proj = acendan.getProjDir() .. reaper.GetProjectName(0)
ret, _ = ultraschall.SetProject_ProjOffsets(reaper_proj, proj_timeoffset,1,0)
reaper.SNM_SetDoubleConfigVar('projtimeoffs', proj_timeoffset)
reaper.UpdateTimeline()
reaper.UpdateArrange()

local after_setsession = reaper.GetProjectTimeOffset(0, true)
if dbg then acendan.dbg("After set project time offset: " .. tostring(after_setsession)) end
