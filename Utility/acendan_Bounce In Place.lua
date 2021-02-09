-- @description ACendan Lua Utilities
-- @author Aaron Cendan
-- @version 1.3
-- @metapackage
-- @provides
--   [main] . > acendan_Bounce In Place.lua
-- @link https://aaroncendan.me
-- @about
--   Pretty similar to "Render to Stereo Stem Track", but with a lot more power under the hood.
--   Handles tracks with items that have a mixed channel count
--   Optional extra space, alternative track name appending, delete original after render, etc
-- @changelog
--   Added options for deleting original track after render and tweaking the name that's appended to the new track


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~ USER CONFIG - EDIT ME ~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Amount of space to add to end of items on track, in seconds. Good for reverb tails
extra_space = 3

-- Append track name
append_track_name = " - stem"

-- OPTIONAL: Deletes the original track after render
delete_after_render = false



-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function main()

  -- Prep time selection
  reaper.Main_OnCommand(40289,0) -- Item: Unselect all items
  reaper.Main_OnCommand(reaper.NamedCommandLookup("_XENAKIOS_SELFIRSTOFSELTRAX"),0) -- Xenakios/SWS: Select first of selected tracks
  reaper.Main_OnCommand(40421,0) -- Item: Select all items in track
  reaper.Main_OnCommand(40290,0) -- Time selection: Set time selection to items
 
  -- Extend edge of time selection with extra space
  local ts_start_time, ts_end_time = reaper.GetSet_LoopTimeRange( 0, 0, 0, 0, 0 )
  reaper.GetSet_LoopTimeRange( 1, 0, ts_start_time , ts_end_time + extra_space, 0 )
  
  
  -- Get the max number of channels on an item in track
  if reaper.CountSelectedTracks(0) > 0 then
    track = reaper.GetSelectedTrack(0,0)
    track_idx = reaper.GetMediaTrackInfo_Value( track, "IP_TRACKNUMBER" ) - 1
    track_max_channels = countTrackItemsMaxChannels(track)
  else
    reaper.MB("No track selected!","",0)
  end
  
  -- Render accordingly
  if track_max_channels then
    -- Mono
    if track_max_channels == 1 then
      reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_AWRENDERMONOSMART"),0) -- SWS/AW: Render tracks to mono stem tracks, obeying time selection
    
    -- Stereo
    elseif track_max_channels == 2 then
      reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_AWRENDERSTEREOSMART"),0) -- SWS/AW: Render tracks to stereo stem tracks, obeying time selection
    
    -- Multichannel
    elseif track_max_channels > 2 then
      
      -- Get track items start and end points
      local track_items_count = reaper.CountTrackMediaItems( track )
      track_items_start = math.huge
      track_items_end = 0
      
      for j = 0, track_items_count - 1 do
        local item = reaper.GetTrackMediaItem( track, j)
        local item_start = reaper.GetMediaItemInfo_Value( item, "D_POSITION")
        local item_len = reaper.GetMediaItemInfo_Value( item, "D_LENGTH")
        local item_end = item_start + item_len
        if item_start < track_items_start then track_items_start = item_start end
        if item_end > track_items_end then track_items_end = item_end end
      end

      -- Render multichannel
      reaper.Main_OnCommand(40893,0) -- Track: Render tracks to multichannel stem tracks (and mute originals)

    end
    
    -- Color tracks, re-order, collapse state, set FX bypass, etc
    reaper.Main_OnCommand(reaper.NamedCommandLookup("_XENAKIOS_SELNEXTTRACK"),0) -- Xenakios/SWS: Select next tracks
    reaper.Main_OnCommand(reaper.NamedCommandLookup("_XENAKIOS_BYPASSFXOFSELTRAX"),0) -- Xenakios/SWS: Bypass FX of selected tracks
    reaper.Main_OnCommand(reaper.NamedCommandLookup("_XENAKIOS_SELPREVTRACKKEEP"),0) -- Xenakios/SWS: Select previous tracks, keeping current selection
    reaper.Main_OnCommand(40738,0) -- Track: Clear automatic record-arm
    reaper.Main_OnCommand(reaper.NamedCommandLookup("_XENAKIOS_SELTRAX_RECUNARMED"),0) -- Xenakios/SWS: Set selected tracks record unarmed
    reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_MAKEFOLDER"),0) -- SWS: Make folder from selected tracks
    reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_COLTRACKNEXT"),0) -- SWS: Set selected track(s) to next track's color
    reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_COLCHILDREN"),0) -- SWS: Set selected track(s) children to same color
    reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_INPUTMATCH"),0) -- SWS: Set all selected tracks inputs to match first selected track
    reaper.Main_OnCommand(1042,0) -- Track: Cycle folder collapsed state
    
    -- Post processing vars
    local new_track = reaper.GetTrack( 0, track_idx )
    local new_item = reaper.GetTrackMediaItem( new_track, 0 )
    local original_track = reaper.GetTrack( 0, track_idx + 1 )
    
    -- If multichannel, trim item
    if track_max_channels > 2 then
      reaper.BR_SetItemEdges(new_item,track_items_start,track_items_end + extra_space)
    end
    
    -- Delete original track after bounce in place option
    if delete_after_render then
      reaper.SetOnlyTrackSelected(original_track) 
      reaper.Main_OnCommand(40005,0) -- Track: Remove tracks
    end
    
    -- Rename track with different append
    if append_track_name ~= " - stem" then
      local ret, current_track_name = reaper.GetSetMediaTrackInfo_String(new_track,"P_NAME","",false)
      if ret then reaper.GetSetMediaTrackInfo_String(new_track,"P_NAME",replace(current_track_name," - stem",append_track_name),true) end
    end
    
    -- Select new track and item
    reaper.SetOnlyTrackSelected(new_track)
    reaper.SetMediaItemSelected(new_item, true)
    
  end
end


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ UTILITIES ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Counts the maximum number of channels on a media item in the given track // returns Number
function countTrackItemsMaxChannels(track)
  -- Loop through selected tracks, count max number of channels of an item on this track
  local track_item_max_channels = -1
  
  if reaper.CountTrackMediaItems( track ) > 0 then
  
    -- Loop through media items on track
    for i = 1, reaper.CountTrackMediaItems( track ) do
      
      local item = reaper.GetTrackMediaItem(track, i - 1)
      local take = reaper.GetActiveTake(item)
      
      -- Get active take
      if take ~= nil then
        
        -- Get source media num channels/mode
        local take_pcm = reaper.GetMediaItemTake_Source(take)
        local take_pcm_chan = reaper.GetMediaSourceNumChannels(take_pcm)
        local take_chan_mod = reaper.GetMediaItemTakeInfo_Value(take, "I_CHANMODE")
        local item_chan = -1
  
        -- Set item channel number based on take channel mode
        local item_chan = (take_chan_mod <= 1) and take_pcm_chan or 1
        
        -- Set max track channels
        track_item_max_channels = (item_chan > track_item_max_channels) and item_chan or track_item_max_channels
      end
    end
    
    --reaper.ShowConsoleMsg("MAX ITEM NUM CHANNELS: " .. track_item_max_channels)
    return track_item_max_channels
    
  else
    reaper.MB("No media items found on selected track!","",0)
    return 0
  end
end

-- Pattern escaping gsub alternative that works with hyphens and other lua stuff
-- https://stackoverflow.com/a/29379912
function replace(str, what, with)
  what = string.gsub(what, "[%(%)%.%+%-%*%?%[%]%^%$%%]", "%%%1") -- escape pattern
  with = string.gsub(with, "[%%]", "%%%%") -- escape replacement
  return string.gsub(str, what, with)
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock();
local store_start, store_end = reaper.GetSet_LoopTimeRange( 0, 0, 0, 0, 0 )
main()
reaper.GetSet_LoopTimeRange( 1, 0, store_start , store_end, 0 )
reaper.Undo_EndBlock("Bounce In Place",-1)
reaper.PreventUIRefresh(-1)
