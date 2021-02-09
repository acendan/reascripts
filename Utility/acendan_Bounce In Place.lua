-- @description ACendan Lua Utilities
-- @author Aaron Cendan
-- @version 1.0
-- @metapackage
-- @provides
--   [main] . > acendan_Bounce In Place.lua
-- @link https://aaroncendan.me
-- @about
--   Pretty similar to "Render to Stereo Stem Track


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function main()
  --Extend right edge of time selection by x seconds
  if reaper.NamedCommandLookup("_RScb04d1b87bb78ad6a28afc690691d653d38026ff") > 0 then
    
    -- Prep time selection
    reaper.Main_OnCommand(40289,0) -- Item: Unselect all items
    reaper.Main_OnCommand(reaper.NamedCommandLookup("_XENAKIOS_SELFIRSTOFSELTRAX"),0) -- Xenakios/SWS: Select first of selected tracks
    reaper.Main_OnCommand(40421,0) -- Item: Select all items in track
    reaper.Main_OnCommand(40290,0) -- Time selection: Set time selection to items
    reaper.Main_OnCommand(reaper.NamedCommandLookup("_RScb04d1b87bb78ad6a28afc690691d653d38026ff"),0) -- Script: acendan_Extend right edge of time selection by 3 seconds.lua
    
    -- Get the max number of channels on an item in track
    if reaper.CountSelectedTracks(0) > 0 then
      local track = reaper.GetSelectedTrack(0,0)
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
      
    else
      
      reaper.MB("Something went wrong... If you're seeing this a lot please reach out to me at:\n\naaron.cendan@gmail.com","",0)
      
    end
    
  else
    -- ERROR MSG
    reaper.ShowConsoleMsg("This script requires ACendan's script 'Extend right edge of time selection by x seconds'. Please install it via ReaPack.\n\nhttps://acendan.github.io/reascripts/index.xml")
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


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock();
main()
reaper.Undo_EndBlock("Bounce In Place",-1)
reaper.PreventUIRefresh(-1)
