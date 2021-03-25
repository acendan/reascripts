-- @description Create Multichannel Render
-- @author Aaron Cendan
-- @version 1.0
-- @metapackage
-- @provides
--   [main] . > acendan_Create multichannel render from selected tracks with mono items.lua
-- @link https://aaroncendan.me
-- @about
--   Basically lets you take tracks with mono media and merge them into 
--   a single multichannel file. Gif here: https://twitter.com/acendan_/status/1374921578765557762?s=20
---  Also follow me on Twitter while you're there :)

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Get this script's name and directory
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local script_directory = ({reaper.get_action_context()})[2]:sub(1,({reaper.get_action_context()})[2]:find("\\[^\\]*$"))

-- Load lua utilities
acendan_LuaUtils = reaper.GetResourcePath()..'/scripts/ACendan Scripts/Development/acendan_Lua Utilities.lua'
if reaper.file_exists( acendan_LuaUtils ) then dofile( acendan_LuaUtils ); if not acendan or acendan.version() < 3.0 then acendan.msg('This script requires a newer version of ACendan Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"ACendan Lua Utilities"); return end else reaper.ShowConsoleMsg("This script requires ACendan Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'ACendan Lua Utilities'"); return end


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function main()

  -- Loop through selected tracks
  local num_sel_tracks = reaper.CountSelectedTracks( 0 )
  if num_sel_tracks > 0 then
    for i = 0, num_sel_tracks-1 do
      local track = reaper.GetSelectedTrack(0,i)
      
      -- Get starting track index
      if not starting_track_idx then starting_track_idx = reaper.GetMediaTrackInfo_Value( track, "IP_TRACKNUMBER" ) end
      
      -- Pan track left
      reaper.SetMediaTrackInfo_Value( track, "D_PAN", -1 )
      
      -- Set track starting channels incrementing up
      reaper.SetMediaTrackInfo_Value( track, "C_MAINSEND_OFFS", i )
    end
    
    -- Insert track
    reaper.InsertTrackAtIndex(starting_track_idx - 1, false)
    parent_track = reaper.GetTrack(0,starting_track_idx - 1)
    reaper.SetTrackSelected(parent_track,true)
    
    -- Create folder
    reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_MAKEFOLDER"), 0) -- SWS: Make folder from selected tracks
    
    -- Set channel count for track
    if (num_sel_tracks % 2 == 0) then channels = num_sel_tracks else channels = num_sel_tracks + 1 end
    
    -- Set parent to accommodate num channels
    reaper.SetMediaTrackInfo_Value( parent_track, "I_NCHAN", channels )
    
    -- Set only parent selected
    reaper.SetOnlyTrackSelected(parent_track)
    
    -- Render parent track to multichannel
    reaper.Main_OnCommand(40893, 0) -- Track: Render tracks to multichannel stem tracks (and mute originals)
  else
    acendan.msg("No tracks selected!")
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
