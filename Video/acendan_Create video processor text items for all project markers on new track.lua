-- @description Video Text for Markers
-- @author Aaron Cendan
-- @version 1.1
-- @metapackage
-- @provides
--   [main] . > acendan_Create video processor text items for all project markers on new track.lua
--   acendan_Text Overlay Preset.txt
-- @link https://aaroncendan.me

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~ USER CONFIG - EDIT THESE ~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Name for new track at top of project with video processor items
local track_name = "Video Markers"

-- Length of video processor items, in seconds
local vid_title_len = 3

-- Parameter presets for video processor text
local parm_TEXT_HEIGHT = 0.07
local parm_Y_POSITION  = 0.9
local parm_X_POSITION  = 0.05 
local parm_BORDER      = 0.1
local parm_TEXT_BRIGHT = 1
local parm_TEXT_ALPHA  = 1
local parm_BG_BRIGHT   = 0.55
local parm_BG_ALPHA    = 0.4


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Get this script's name and directory
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local script_directory = ({reaper.get_action_context()})[2]:sub(1,({reaper.get_action_context()})[2]:find("\\[^\\]*$"))
local separator = reaper.GetOS():find("Win") and "\\" or "/"
local text_preset = script_directory .. separator .. "acendan_Text Overlay Preset.txt"

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function main()
  local ret, num_markers, num_regions = reaper.CountProjectMarkers(0)
  
  -- Confirm markers in project
  if num_markers > 0 then 
    
    -- Try to find existing vid title track
    local ret, trk_guid = reaper.GetProjExtState(0,"acendan_vid_mrkrs","trk_guid")
    if ret then
      track = reaper.BR_GetMediaTrackByGUID(0,trk_guid)
      if not track then PrepProjectVidTrack() end
    else
      PrepProjectVidTrack()
    end
    reaper.SetOnlyTrackSelected(track)
    reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_DELALLITEMS"),0) -- SWS: Delete all items on selected track(s)
    
    -- Loop through all markers
    local num_total = num_markers + num_regions
    local i = 0
    local j = 0
    while i < num_total do
      local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, i )
      if not isrgn then   -- Process markers
        
        -- Insert new video processor item at marker position, w/ user length
        reaper.Main_OnCommand(40020,0) -- Time selection: Remove time selection and loop points
        reaper.SetEditCurPos(pos,false,false)
        reaper.GetSet_LoopTimeRange(1, 0, pos, pos + vid_title_len, 0)
        reaper.Main_OnCommand(41932,0) -- Insert dedicated video processor item
        
        -- Add video processor FX
        local item = reaper.GetTrackMediaItem(track,j)
        local take = reaper.GetActiveTake(item)
        local vidfx_pos = reaper.TakeFX_AddByName(take,"Video processor",1)
        
        -- Write code for text overlay to video processor
        AddTextPresetToVideoProcessor(item)
        
        -- Set name in video processor chunk to marker name
        SetTextInVideoProcessor(item, name)
        
        -- Set preset values
        SetTextOverlayParameters(take)
        
        -- Ensure vid fx window is closed
        reaper.TakeFX_SetOpen(take, vidfx_pos, false)
        
        j = j + 1
      end
      i = i + 1
    end
  
  else
    reaper.MB("Project has no markers!","",0)
  end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ UTILITIES ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- No vid track found, prepare session with video track
function PrepProjectVidTrack()
  reaper.Main_OnCommand(reaper.NamedCommandLookup("_XENAKIOS_INSNEWTRACKTOP"), 0) -- Xenakios/SWS: Insert new track at the top of track list
  track = reaper.GetTrack(0,0)
  trk_guid = reaper.GetTrackGUID(track)
  reaper.SetProjExtState(0,"acendan_vid_mrkrs","trk_guid",trk_guid)
  reaper.GetSetMediaTrackInfo_String(track,"P_NAME",track_name,true)
end

-- Store the contents of the preset text file into local text
function GetPreset()
  preset_code_block = ""
  local file = io.open(text_preset)
  io.input(file)
  for line in io.lines() do
    preset_code_block = preset_code_block .. line .. "\n"
  end
  io.close(file)
end

-- Adds the preset as text because Reaper won't let me reference native presets for some reason 
function AddTextPresetToVideoProcessor(item)
  if not preset_code_block then GetPreset() end

  local _bool, StateChunk=reaper.GetItemStateChunk(item, "", false)
  if StateChunk:match("VIDEO_EFFECT")==nil then return false, "No Video Processor found in this item" end
  local part1, code, part2=StateChunk:match("(.-)(<TAKEFX.-\n>)(\nCODEPARM.*)")
  StateChunk=part1..preset_code_block..part2
  return reaper.SetItemStateChunk(item, StateChunk, false), "Done"
end


-- Adapted from Meo Mespotine's solution on the Reaper forums
-- https://forums.cockos.com/showpost.php?p=2006396&postcount=12
function SetTextInVideoProcessor(item, text)
  if reaper.ValidatePtr2(0, item, "MediaItem*")==false then return false, "No valid MediaItem" end
  if type(text)~="string" then return false, "Must be a string" end
  local _bool, StateChunk=reaper.GetItemStateChunk(item, "", false)
  if StateChunk:match("VIDEO_EFFECT")==nil then return false, "No Video Processor found in this item" end
  local part1, code, part2=StateChunk:match("(.-)(<TAKEFX.-\n>)(\nCODEPARM.*)")
  
  if code:match("// Text overlay")==nil then return false, "Only default preset \"Title text overlay\" supported. Please select accordingly." 
  else 
    local c1,test,c3=code:match("(.-text=\")(.-)(\".*)") 
    text=string.gsub(text, "\n", "\\n")
    code=c1..text..c3
  end
  StateChunk=part1..code..part2
  return reaper.SetItemStateChunk(item, StateChunk, false), "Done"
end

-- Adapted from Meo Mespotine's solution on the Reaper forums
-- https://forums.cockos.com/showpost.php?p=2006396&postcount=12
function GetTextInVideoProcessor(item)
  if reaper.ValidatePtr2(0, item, "MediaItem*")==false then return false, "No valid MediaItem" end
  local _bool, StateChunk=reaper.GetItemStateChunk(item, "", false)
  if StateChunk:match("VIDEO_EFFECT")==nil then return false, "No Video Processor found in this item" end
  local part1, code, part2=StateChunk:match("(.-)(<TAKEFX.-\n>)(\nCODEPARM.*)")
  --reaper.ShowConsoleMsg(code)
  if code:match("// Text overlay")==nil then return false, "Only default preset \"Title text overlay\" supported. Please select accordingly." 
  else 
    local c1,test,c3=code:match("(.-text=\")(.-)(\".*)") 
    test=string.gsub(test, "\\n", "\n")
    return true, test
  end
end

-- Set text overlay parameter values
function SetTextOverlayParameters(take)
  reaper.TakeFX_SetParam(take,0,0,parm_TEXT_HEIGHT)
  reaper.TakeFX_SetParam(take,0,1,parm_Y_POSITION)
  reaper.TakeFX_SetParam(take,0,2,parm_X_POSITION)
  reaper.TakeFX_SetParam(take,0,3,parm_BORDER)
  reaper.TakeFX_SetParam(take,0,4,parm_TEXT_BRIGHT)
  reaper.TakeFX_SetParam(take,0,5,parm_TEXT_ALPHA)
  reaper.TakeFX_SetParam(take,0,6,parm_BG_BRIGHT)
  reaper.TakeFX_SetParam(take,0,7,parm_BG_ALPHA)
end

-- Save original time/loop selection
function saveLoopTimesel()
  init_start_timesel, init_end_timesel = reaper.GetSet_LoopTimeRange(0, 0, 0, 0, 0)
  init_start_loop, init_end_loop = reaper.GetSet_LoopTimeRange(0, 1, 0, 0, 0)
end

-- Restore original time/loop selection
function restoreLoopTimesel()
  reaper.GetSet_LoopTimeRange(1, 0, init_start_timesel, init_end_timesel, 0)
  reaper.GetSet_LoopTimeRange(1, 1, init_start_loop, init_end_loop, 0)
end

-- Save original cursor position
function saveCursorPos()
  init_cur_pos = reaper.GetCursorPosition()
end

-- Restore original cursor position
function restoreCursorPos()
  reaper.SetEditCurPos(init_cur_pos,false,false)
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock()

saveLoopTimesel()
saveCursorPos()

main()

restoreLoopTimesel()
restoreCursorPos()

reaper.Undo_EndBlock(script_name,-1)

reaper.PreventUIRefresh(-1)

reaper.UpdateArrange()
