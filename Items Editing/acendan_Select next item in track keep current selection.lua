-- @description Select Next Item Track Keep Current Selection
-- @author Aaron Cendan
-- @version 1.0
-- @metapackage
-- @provides
--   [main] .
-- @link https://ko-fi.com/acendan_
-- @about
--   # Adapted from Archie's "Select Next item in track"

    ------------------------------------------------------
    local function no_undo()reaper.defer(function()end)end;
    -------------------------------------------------------


    local CountSelitem = reaper.CountSelectedMediaItems(0);
    if CountSelitem == 0 then no_undo() return end;


    local CountTrack = reaper.CountTracks(0);
    if CountTrack == 0 then no_undo() return end;

    reaper.Undo_BeginBlock();
    reaper.PreventUIRefresh(1);

    for i = 1,CountTrack do;
        local track = reaper.GetTrack(0,i-1);

        ---
        local CountTrItem = reaper.CountTrackMediaItems(track);
        local sel2,item2;
        for i = CountTrItem-1,0,-1 do;

            local item = reaper.GetTrackMediaItem(track,i);
            local take = reaper.GetActiveTake(item);

            local sel = reaper.GetMediaItemInfo_Value(item,'B_UISEL');

            if sel == 1 and sel2 == 0 then;
                reaper.SetMediaItemInfo_Value(item2,'B_UISEL',1);
                reaper.SetMediaItemInfo_Value(item,'B_UISEL',1);
                sel = 0;
            end;
            sel2 = sel;
            item2 = item;
        end;
        ---
    end;

    reaper.PreventUIRefresh(1);
    reaper.Undo_EndBlock('Select Next item in track',-1);

    reaper.UpdateArrange();




