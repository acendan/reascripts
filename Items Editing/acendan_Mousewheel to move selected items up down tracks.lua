-- @description Mousewheel Move Items Tracks
-- @author Aaron Cendan
-- @version 1.0
-- @metapackage
-- @provides
--   [main] . > acendan_Mousewheel to move selected items up down visible tracks.lua
-- @link https://aaroncendan.me
-- @about
--   # Thanks NVK for the mousewheel script formatting <3
--   # Thanks to Archie for the item track moving scripts


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~ USER CONFIG - EDIT ME ~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

speed = 1       -- 1 = 1 track at a time. Set to higher integers to jump multiple tracks


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

local function no_undo()reaper.defer(function()end)end

function Main()
  is_new,name,sec,cmd,rel,res,val = reaper.get_action_context()
  if reaper.CountSelectedMediaItems(0) > 0 then
    if val < 0 then
      -- LOWER TRACK
      for i = 0, speed - 1 do
        DownByOne()  
      end
    else
      -- RAISE TRACK
      for i = 0, speed - 1 do
        UpByOne()  
      end
    end
  end
  reaper.SetCursorContext(1, nil)
end

-- Script: Archie_Item; Move selected items down by one visible track.lua
function DownByOne()
  local HowMuchDown = 1;
  local CountSelItem = reaper.CountSelectedMediaItems(0);
  
  HowMuchDown = math.abs(tonumber(HowMuchDown)or 1);
  
  for i = CountSelItem-1,0,-1 do;
      local SelItem = reaper.GetSelectedMediaItem(0,i);
      local track = reaper.GetMediaItemTrack(SelItem);
      local preHeightTr = reaper.GetMediaTrackInfo_Value(track,'I_TCPH');
      if preHeightTr > 0 then;
          local numb = reaper.GetMediaTrackInfo_Value(track,"IP_TRACKNUMBER");
          local new_track = reaper.GetTrack(0,numb-1+HowMuchDown);
          if new_track then;
              local heightTr = reaper.GetMediaTrackInfo_Value(new_track,'I_TCPH');
              if heightTr <= 0 then;
                  new_track = nil;
                  for i2 = (numb-1+HowMuchDown),reaper.CountTracks(0)-1 do;
                      local track = reaper.GetTrack(0,i2);
                      local heightTr = reaper.GetMediaTrackInfo_Value(track,'I_TCPH');
                      if heightTr > 0 then;
                          new_track = track;
                          break;
                      end;
                  end;
              end;
  
              if new_track then;
                  reaper.MoveMediaItemToTrack(SelItem,new_track);
              end;
          end;
      else;
          reaper.SetMediaItemInfo_Value(SelItem,'B_UISEL',0);
      end;
  end;
  reaper.UpdateArrange();
end

-- Script: Archie_Item; Move selected items up by one visible track.lua
function UpByOne()
  local HowMuchUp = 1;
  
  local CountSelItem = reaper.CountSelectedMediaItems(0);

  HowMuchUp = math.abs(tonumber(HowMuchUp)or 1);

  for i = 1,CountSelItem do;
      local SelItem = reaper.GetSelectedMediaItem(0,i-1);
      local track = reaper.GetMediaItemTrack(SelItem);
      local preHeightTr = reaper.GetMediaTrackInfo_Value(track,'I_TCPH');
      if preHeightTr > 0 then;
          local numb = reaper.GetMediaTrackInfo_Value(track,"IP_TRACKNUMBER");
          local new_track = reaper.GetTrack(0,numb-1-HowMuchUp);
          if new_track then;
              local heightTr = reaper.GetMediaTrackInfo_Value(new_track,'I_TCPH');
              if heightTr <= 0 then;
                  new_track = nil;
                  for i2 = (numb-1-HowMuchUp),0,-1 do;
                      local track = reaper.GetTrack(0,i2);
                      local heightTr = reaper.GetMediaTrackInfo_Value(track,'I_TCPH');
                      if heightTr > 0 then;
                          new_track = track;
                          break;
                      end;
                  end;
              end;

              if new_track then;
                  reaper.MoveMediaItemToTrack(SelItem,new_track);
              end;
          end;
      else;
          reaper.SetMediaItemInfo_Value(SelItem,'B_UISEL',0);
      end;
  end;
  reaper.UpdateArrange();
end

reaper.PreventUIRefresh(1)
Main()
reaper.PreventUIRefresh(-1)

