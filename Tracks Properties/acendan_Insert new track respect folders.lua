-- @description Insert New Track Respect Folders
-- @author Aaron Cendan
-- @version 1.2
-- @metapackage
-- @provides
--   [main] . > acendan_Insert new track respect folders.lua
-- @link https://aaroncendan.me
-- @about
--   # Insert New Track Respect Folders
--   By Aaron Cendan - Sept 2020
--
--   ### Reaper's defaults suck
--   * Bind this to ctrl + T and now when you insert a track with the last track in a folder selected, it will be added to the end of the folder.


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
  if reaper.CountSelectedTracks( 0 ) > 0 then
    -- Get selected track
    local sel_track = reaper.GetSelectedTrack(0,0)
    local sel_track_idx = reaper.GetMediaTrackInfo_Value( sel_track, "IP_TRACKNUMBER" )
    
    local folder_depth = reaper.GetMediaTrackInfo_Value( sel_track, "I_FOLDERDEPTH" )
    local folder_depth_prev_track = 0
    if sel_track_idx > 1 then
      folder_depth_prev_track = reaper.GetMediaTrackInfo_Value( reaper.GetTrack(0, sel_track_idx - 2), "I_FOLDERDEPTH" )
    end
    
    --dbg(tostring("Selected track folder depth: " .. folder_depth))
    --dbg(tostring("Previous track folder depth: " .. folder_depth_prev_track))
    
    -- Normal track right after the last track in a nested folder
    if folder_depth == 0 and folder_depth_prev_track < 0 then
      -- Insert new track below selected
      reaper.InsertTrackAtIndex( sel_track_idx, true )
      
      -- Set new track color
      local new_track = reaper.GetTrack(0, sel_track_idx)
      reaper.SetMediaTrackInfo_Value( new_track, "I_CUSTOMCOLOR", reaper.GetMediaTrackInfo_Value( sel_track, "I_CUSTOMCOLOR" ) )

    -- Folder parent
    elseif folder_depth == 1 then
      -- Insert new track below selected
      reaper.InsertTrackAtIndex( sel_track_idx, true )
      
      -- Set new track color
      local new_track = reaper.GetTrack(0, sel_track_idx)
      reaper.SetMediaTrackInfo_Value( new_track, "I_CUSTOMCOLOR", reaper.GetMediaTrackInfo_Value( sel_track, "I_CUSTOMCOLOR" ) )
     
    -- Normal track, or last track in folder/nested folder
    elseif folder_depth <= 0 then
       -- Insert new track above selected
       reaper.InsertTrackAtIndex( sel_track_idx - 1, true )
       
       -- Set new track color
       local new_track = reaper.GetTrack(0, sel_track_idx - 1)
       reaper.SetMediaTrackInfo_Value( new_track, "I_CUSTOMCOLOR", reaper.GetMediaTrackInfo_Value( sel_track, "I_CUSTOMCOLOR" ) )
       
       -- Move new track below originally selected track
       reaper.SetOnlyTrackSelected( sel_track )
       reaper.ReorderSelectedTracks( sel_track_idx - 1, 2 )
       
       -- Select new track
       reaper.SetOnlyTrackSelected( new_track )
       
    end

  else
    -- Insert track at end of project if none selected
    reaper.InsertTrackAtIndex( reaper.CountTracks( 0 ), true )
  end
  
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ UTILITIES ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Deliver messages and add new line in console
function dbg(dbg)
  reaper.ShowConsoleMsg(dbg .. "\n")
end

-- Deliver messages using message box
function msg(msg)
  reaper.MB(msg, script_name, 0)
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