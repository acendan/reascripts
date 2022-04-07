-- @description Copy Selected Items Take Envelope
-- @author Aaron Cendan, Claudiohbsantos
-- @version 1.0
-- @metapackage
-- @provides
--   [main] . > acendan_Copy selected items take (Volume) envelope to selected automation envelope.lua
--   [main] . > acendan_Copy selected items take (Pan) envelope to selected automation envelope.lua
--   [main] . > acendan_Copy selected items take (Mute) envelope to selected automation envelope.lua
--   [main] . > acendan_Copy selected items take (Pitch) envelope to selected automation envelope.lua
-- @link https://ko-fi.com/acendan_
-- @about
--   # Copy Take Envelope To Automation Envelope
--   * Copies the selected items' take envelope to the selected automation envelope
--   * Modified from Claudiohbsantos' script: CS_Copy Take Volume Envelope to Track Volume Envelope.lua
-- @changelog
--   # Initial release (Thanks for the idea, @iBuyPowder!)

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Get this script's name and directory
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local script_directory = ({reaper.get_action_context()})[2]:sub(1,({reaper.get_action_context()})[2]:find("\\[^\\]*$"))

-- Load lua utilities
acendan_LuaUtils = reaper.GetResourcePath()..'/scripts/ACendan Scripts/Development/acendan_Lua Utilities.lua'
if reaper.file_exists( acendan_LuaUtils ) then dofile( acendan_LuaUtils ); if not acendan or acendan.version() < 5.4 then acendan.msg('This script requires a newer version of ACendan Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"ACendan Lua Utilities"); return end else reaper.ShowConsoleMsg("This script requires ACendan Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'ACendan Lua Utilities'"); return end

-- Take envelope to copy
if script_name:find("%(%a+%)") then target_take_env = script_name:match("%(%a+%)"):sub(2,-2) else target_take_env = "Pan" end
hide_env_cmd = (target_take_env == "Volume") and "_S&M_TAKEENV4" or (target_take_env == "Pan") and "_S&M_TAKEENV5" or (target_take_env == "Mute") and "_S&M_TAKEENV6" or ""
ini_sel_env = reaper.GetSelectedTrackEnvelope(0)
if reaper.CountSelectedMediaItems(0) < 1 then acendan.msg("No items selected!") return end
if not ini_sel_env then
  -- NO ENVELOPE SELECTED
  acendan.msg("No track automation envelope selected!")
  return  
else
  reaper.Main_OnCommand(reaper.NamedCommandLookup("_BR_ENV_HIDE_ALL_BUT_ACTIVE_SEL"),0) -- SWS/BR: Hide all but selected track envelope for selected tracks       
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function saveOriginalSelection()
  originalState = {}

  originalState.editCur = reaper.GetCursorPositionEx(0)
  originalState.timeSelStart,originalState.timeSelEnd = reaper.GetSet_LoopTimeRange2(0,false,true,0,0,false)

  originalState.selTracks = {}

  for i=1,reaper.CountSelectedTracks2(0,true),1 do
    originalState.selTracks[#originalState.selTracks+1] = reaper.GetSelectedTrack2(0,i-1,true)
  end
end

function restoreOriginalSelection()
  reaper.SetEditCurPos2(0,originalState.editCur,false,false)

  reaper.GetSet_LoopTimeRange2(0,true,true,originalState.timeSelStart,originalState.timeSelEnd,false)
  reaper.Main_OnCommand(40297,0) -- unselect all tracks
  for i=1, #originalState.selTracks,1 do
    reaper.SetTrackSelected(originalState.selTracks[i],true)
  end
end

local function main()
  saveOriginalSelection()

  local TotalSelItems = reaper.CountSelectedMediaItems(0)

  local selectedItems = {}
  for i=1,TotalSelItems,1 do
    local tempSelItem = reaper.GetSelectedMediaItem(0,i-1)
    local nTakes = reaper.CountTakes(tempSelItem)
    if nTakes ~= 0 then 
      selectedItems[#selectedItems+1] = tempSelItem
    end
  end

  for i=1,#selectedItems,1 do

    reaper.SelectAllMediaItems(0,false)
    reaper.SetMediaItemSelected(selectedItems[i],true)
    reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_SELTRKWITEM"),0) -- select track with selected items
    reaper.Main_OnCommand(40290,0) -- set time selection to item and move edit cursor to beginning

    local take = reaper.GetActiveTake(selectedItems[i])

    local takeEnv = reaper.GetTakeEnvelopeByName(take, target_take_env)

    if takeEnv then

      local brTakeEnv = reaper.BR_EnvAlloc(takeEnv,true)
      local takeEnvIsActive = reaper.BR_EnvGetProperties(brTakeEnv)
      
      if takeEnvIsActive then
        takeEnv = reaper.GetTakeEnvelopeByName(take, target_take_env)

        local track = reaper.GetMediaItem_Track(selectedItems[i])
        reaper.Main_OnCommand(41864,0) -- Track: Select next envelope
        local trackEnv = ini_sel_env

        if trackEnv then
          
          local brTrackEnv = reaper.BR_EnvAlloc(trackEnv, false)
          local trackEnvIsActive,_, armed, inLane, laneHeight, defaultShape, faderScaling = reaper.BR_EnvGetProperties(brTrackEnv)
  
          reaper.BR_EnvSetProperties(brTrackEnv,true,true,armed,inLane,laneHeight,defaultShape,faderScaling)
          
          reaper.SetCursorContext(2, takeEnv)
          reaper.Main_OnCommand(reaper.NamedCommandLookup("_BR_INSERT_2_ENV_POINT_TIME_SEL"),0) -- add 2 points
          reaper.Main_OnCommand(40324,0) -- Copy points within time selection
          reaper.Main_OnCommand(40330,0) -- select points in time selection
          reaper.Main_OnCommand(40333,0) -- delete selected points
          if hide_env_cmd ~= "" then reaper.Main_OnCommand(reaper.NamedCommandLookup(hide_env_cmd),0) end -- hide take envelope
  
          reaper.Main_OnCommand(41864,0) -- Track: Select next envelope
          
          if reaper.GetSelectedTrackEnvelope(0) ~= nil then
            reaper.Main_OnCommand(40726,0) -- insert 4 points at edges of time selection
            reaper.Main_OnCommand(40058,0) -- Paste points
          end
          
          reaper.BR_EnvFree(brTrackEnv,false)
        else
          -- NO ENVELOPE SELECTED
          acendan.dbg("No track automation envelope selected!")
        end
      end
    end     
  end

  restoreOriginalSelection()
end

---------------------------------------------------------------

reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock2(0)

main()

reaper.Undo_EndBlock2(0,script_name,0)
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()

