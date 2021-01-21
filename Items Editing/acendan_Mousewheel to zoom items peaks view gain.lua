-- @description Mousewheel Items Peaks
-- @author Aaron Cendan
-- @version 1.0
-- @metapackage
-- @provides
--   [main] . > acendan_Mousewheel to zoom items peaks view gain.lua
-- @link https://aaroncendan.me
-- @about
--   # I TOTALLY COPIED THIS FROM NVK THANK YOU <3
--    What a horrible name

speed = 1 --0 is slowest speed. Set to higher integers to zoom faster


local function no_undo()reaper.defer(function()end)end

function Main()
  is_new,name,sec,cmd,rel,res,val = reaper.get_action_context()
  if val < 0 then
    for i = 0, speed do
      reaper.Main_OnCommand(40156, 0) -- Peaks: Decrease peaks view gain
    end
  else
    for i = 0, speed do
      reaper.Main_OnCommand(40155, 0) -- Peaks: Increase peaks view gain
    end
  end
  reaper.SetCursorContext(1, nil)
end


--scrName = ({reaper.get_action_context()})[2]:match(".+[/\\](.+)")
--reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.PreventUIRefresh(-1)
--reaper.Undo_EndBlock(scrName, -1)
--no_undo()

