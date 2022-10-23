-- @description Open Envelope w Automation Items
-- @author Aaron Cendan, ausbaxter
-- @version 1.3
-- @metapackage
-- @provides
--   [main] . > acendan_Open (volume) envelope for selected tracks and create (pooled) automation items for track items.lua
--   [main] . > acendan_Open (volume) envelope for selected tracks and create (unpooled) automation items for track items.lua
--   [main] . > acendan_Open (pan) envelope for selected tracks and create (pooled) automation items for track items.lua
--   [main] . > acendan_Open (pan) envelope for selected tracks and create (unpooled) automation items for track items.lua
--   [main] . > acendan_Open (last touched FX parameter) envelope for respective track and create (pooled) automation items for track items.lua
--   [main] . > acendan_Open (last touched FX parameter) envelope for respective track and create (unpooled) automation items for track items.lua
-- @link https://ko-fi.com/acendan_
-- @about
--   # Open Envelope w Automation Items
--   * Opens the appropriate envelope in script name and creates automation items based on track item positions.
-- @changelog
--   # Reduce number of annoying pop-ups, try to infer intention
--   # Select newly added automation items

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~ USER CONFIG - EDIT ME ~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Only process selected items (default = false)
only_selected_items = false

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Get this script's name and directory
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local script_directory = ({reaper.get_action_context()})[2]:sub(1,({reaper.get_action_context()})[2]:find("\\[^\\]*$"))

-- Load lua utilities
acendan_LuaUtils = reaper.GetResourcePath()..'/Scripts/ACendan Scripts/Development/acendan_Lua Utilities.lua'
if reaper.file_exists( acendan_LuaUtils ) then dofile( acendan_LuaUtils ); if not acendan or acendan.version() < 5.4 then acendan.msg('This script requires a newer version of ACendan Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"ACendan Lua Utilities"); return end else reaper.ShowConsoleMsg("This script requires ACendan Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'ACendan Lua Utilities'"); return end

-- Only used for testing
if script_name:find("Open envelope") then test_vol_pan = true; test_last_touched = false end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function main()
  -- Check pooled or unpooled; default pooled
  local pooled = true
  if script_name:find("(unpooled)") then pooled = false end

  -- Process envelope by script name
  if script_name:find("(volume)") or script_name:find("(pan)") or test_vol_pan then
    -- Select tracks of sel items
    if only_selected_items then
      reaper.Main_OnCommand(40297, 0) -- Track: Unselect (clear selection of) all tracks
      local num_sel_items = reaper.CountSelectedMediaItems(0)
      if num_sel_items > 0 then
        for i=0, num_sel_items - 1 do
          local it = reaper.GetSelectedMediaItem( 0, i )
          local tr = reaper.GetMediaItem_Track(it)
          reaper.SetTrackSelected(tr, true)
        end
      end
    end
    
    -- Check num tracks selected
    local num_sel_tracks = reaper.CountSelectedTracks( 0 )
    if not (num_sel_tracks > 0) then 
      return 
    end
    
    -- Save selected tracks to table
    local sel_tracks = {}
    acendan.saveSelectedTracks(sel_tracks)
    
    -- Select all items on selected tracks
    if not only_selected_items or (only_selected_items and reaper.CountSelectedMediaItems(0) == 0) then SelectAllItemsOnSelectedTracks() end
    
    -- Open and select track envelopes by command ID accordingly
    local sel_env_cmd = script_name:find("(volume)") and 41866 or 41868       -- Track: Select volume envelope   OR   Track: Select pan envelope
    SelectTrackEnvelopes(sel_tracks, sel_env_cmd)
    
    -- ausbaxter's Insert automation items script, modified to accept an argument for pooled vs. unpooled
    ausbaxter_InsertAutomationItems(pooled)
    
    -- Reselect initially selected tracks
    acendan.restoreSelectedTracks(sel_tracks)
    
    
  elseif script_name:find("(last touched FX parameter)") or test_last_touched then
    
    -- Select last touched fx parameter env track, adapted from:
    -- Script: Archie_Env; Show track envelope last touched FX parameter(add point in start of time selection)(`).lua
    local retval, tracknumber, fxnumber, paramnumber = reaper.GetLastTouchedFX()
    if not retval then acendan.msg("Unable to fetch last touched FX parameter. Please move an FX parameter and try again!\n\n~~~\n" .. script_name); return end
    
    -- Select track
    local track = reaper.GetTrack(0, tracknumber-1)
    if not track then acendan.msg("Unable to fetch the track for last touched FX parameter. Please try again!\n\n~~~\n" .. script_name); return end
    reaper.SetOnlyTrackSelected(track)
    if not only_selected_items or (only_selected_items and reaper.CountSelectedMediaItems(0) == 0) then SelectAllItemsOnSelectedTracks() end
    
    -- Select envelope
    local envelope =  reaper.GetFXEnvelope(track, fxnumber, paramnumber, true)
    reaper.SetCursorContext(2, envelope)
    reaper.TrackList_AdjustWindows(false)
    
    -- ausbaxter's Insert automation items script, modified to accept an argument for pooled vs. unpooled
    ausbaxter_InsertAutomationItems(pooled)
  
  else
    acendan.msg("Unable to parse script name for necessary envelope. Did you change the name of this script?\n\n~~~\n" .. script_name)
  end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ UTILITIES ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Iterates through table of tracks and selects envelope using native action
function SelectTrackEnvelopes(trk_tbl, cmd_id)
  for _, trk in pairs(trk_tbl) do
    reaper.SetOnlyTrackSelected(trk)
    reaper.Main_OnCommand(cmd_id, 0)  -- cmd_id = 41866 or 41868   -- Track: Select volume envelope   OR   Track: Select pan envelope
  end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ AUSBAXTER ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- The following functions were written by ausbaxter as part of the scripts:
-- Script: ausbaxter_Insert pooled automation items for selected envelope on selected items.lua
-- Script: ausbaxter_Select all items on selected tracks.lua
--
-- I have listed ausbaxter as a co-author of this script, as his contributions are what made this entire thing possible. Thanks <3
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function SelectAllItemsOnSelectedTracks()
    local unselect_all_items = 40289
    reaper.Main_OnCommand(unselect_all_items, 0)
    local track_count = reaper.CountSelectedTracks(0)
    for i = 0, track_count - 1 do
        local track = reaper.GetSelectedTrack(0, i)
        for j = 0, reaper.CountTrackMediaItems(track) - 1 do
            local item = reaper.GetTrackMediaItem(track, j)
            reaper.SetMediaItemInfo_Value(item, "B_UISEL", 1)
        end
    end
end

function SetPoolID()

    local starting_pool_id = 1000
    local retval, last_pool_id = reaper.GetProjExtState(0, "AB_AUTOITEM", "LASTPOOLID")

    local pool_id = retval == 0 and starting_pool_id or tonumber(last_pool_id) + 1

    reaper.SetProjExtState(0, "AB_AUTOITEM", "LASTPOOLID", pool_id)

    return pool_id

end

function IsGoodTrackEnvelope(envelope)
    -- Returns true if selected envelope is on a track containing a selected item, false otherwise.

    local tk = reaper.Envelope_GetParentTrack(envelope)

    for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        local i_tk = reaper.GetMediaItemTrack(item)
        if i_tk == tk then return true end
    end

    return false

end

function GetItemSize(source_media_item)
    local s = reaper.GetMediaItemInfo_Value(source_media_item, "D_POSITION")
    local l = reaper.GetMediaItemInfo_Value(source_media_item, "D_LENGTH")
    return s, l
end

function GetSelectedItemsTracks(env_track)
    -- Returns table {Track, ItemTable} ensuring that env_track is at index 1.
    local dl_tbl = {}
    local sorted = {}
    for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        local track = reaper.GetMediaItem_Track(item)
        if not dl_tbl[track] then 
            dl_tbl[track] = {item}
        else
            table.insert(dl_tbl[track], item)
        end
    end
    local c = 2
    for t, i in pairs(dl_tbl) do
        if env_track and env_track == track then
            sorted[1] = {track = t, items = i}
        else
            sorted[c] = {track = t, items = i}
            c = c + 1
        end
    end
    return sorted
end

function GetFxOfSelectedEnvelope(envelope_track, envelope)
    local _, chunk = reaper.GetEnvelopeStateChunk(envelope, "", false)
    local parm_idx = string.match( chunk, "<PARMENV (%d+)" )
    for i = 0, reaper.TrackFX_GetCount(envelope_track) - 1 do
        for j = 0, reaper.TrackFX_GetNumParams(envelope_track, i) - 1 do
            local env = reaper.GetFXEnvelope(envelope_track, i, j, false)
            if env == envelope then
                local _, fx = reaper.BR_TrackFX_GetFXModuleName(envelope_track, i, "", 20)
                return fx, parm_idx
            end
        end
    end
    return nil
end

function GetEnvelope(track)
    if source_fx then
        for fx_idx = 0, reaper.TrackFX_GetCount(track) - 1 do
            local retval, fx = reaper.BR_TrackFX_GetFXModuleName(track, fx_idx, "", 20) -- API doc specs 2 args, but 4 are req, Check 'C' reference
            if fx == source_fx then return reaper.GetFXEnvelope(track, fx_idx, source_fx_parm_id, false) end
        end
    else
        return reaper.GetTrackEnvelopeByChunkName(track, env_chunk)
    end
end

function FloatCompare(x, y)
  return math.abs(x - y) < 0.001
end

function InsertAutomationItems(item_tracks, pooled)
    local is_first = true
    local base_length = 0
    for i, t in pairs(item_tracks) do
        local dest_envelope = GetEnvelope(t.track)
        for _, item in ipairs(t.items) do
            if dest_envelope then
                local start, length = GetItemSize(item)
                
                -- Check if already an automation item in this spot; if so, select it and skip adding
                local exists = false
                for ai_idx = 0, reaper.CountAutomationItems(dest_envelope) - 1 do
                  local ai_start = reaper.GetSetAutomationItemInfo(dest_envelope, ai_idx, "D_POSITION", -1, false)
                  local ai_length = reaper.GetSetAutomationItemInfo(dest_envelope, ai_idx, "D_LENGTH", -1, false)
                  if FloatCompare(start, ai_start) and FloatCompare(length, ai_length) then exists = true end
                end
                
                -- Insert
                if not exists then
                  local ai_index =  reaper.InsertAutomationItem(dest_envelope, pooled and pool_id or -1, start, length)
                  if is_first then 
                      is_first = false
                      base_length = length
                  else
                      reaper.GetSetAutomationItemInfo(dest_envelope, ai_index, "D_PLAYRATE", base_length / length, true)
                  end
                end
            end
        end
    end
    
    -- Select automation items
    for i, t in pairs(item_tracks) do
      local dest_envelope = GetEnvelope(t.track)
      for _, item in ipairs(t.items) do
          if dest_envelope then
              local start, length = GetItemSize(item)
              for ai_idx = 0, reaper.CountAutomationItems(dest_envelope) - 1 do
                local ai_start = reaper.GetSetAutomationItemInfo(dest_envelope, ai_idx, "D_POSITION", -1, false)
                local ai_length = reaper.GetSetAutomationItemInfo(dest_envelope, ai_idx, "D_LENGTH", -1, false)
                if FloatCompare(start, ai_start) and FloatCompare(length, ai_length) then 
                  reaper.GetSetAutomationItemInfo(dest_envelope, ai_idx, "D_UISEL", 1, true)
                end
              end
          end
      end
  end
end

function ausbaxter_InsertAutomationItems(pooled)
    local envelope = reaper.GetSelectedEnvelope(0)
    if not envelope then
        --reaper.ShowMessageBox("No Envelope Selected", "Error: No Selected Envelope", 0)
        return
    end
    local env_track = reaper.Envelope_GetParentTrack(envelope)
    if not IsGoodTrackEnvelope(envelope) then 
        --reaper.ShowMessageBox("No media items found on selected track!\n\n~~~\n" .. script_name, "Create Automation Items", 0) 
        return 
    end
    local item_tracks = GetSelectedItemsTracks()
    local _, chunk = reaper.GetEnvelopeStateChunk(envelope, "", false)
    env_chunk = string.match(chunk, "<%w+ENV%w*")
    if env_chunk == "<PARMENV" then 
        source_fx, source_fx_parm_id = GetFxOfSelectedEnvelope(env_track, envelope) 
    end
    pool_id = SetPoolID()
    InsertAutomationItems(item_tracks, pooled)
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
