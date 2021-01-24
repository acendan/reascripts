-- @description Mousewheel Items Pitch
-- @author Aaron Cendan
-- @version 1.0
-- @metapackage
-- @provides
--   [main] . > acendan_Mousewheel adjust pitch of item under cursor.lua
-- @link https://aaroncendan.me
-- @about
--   # Thanks NVK for the mousewheel script formatting <3


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~ USER CONFIG - EDIT ME ~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

speed = 1       -- 0 is slowest speed. Set to higher integers to shift faster
pshift = 0.1    -- The amount to pitch shift by. One 'bump' on my mousewheel is equal to pshift / 2, but this offset will likely
                --   vary depending on the mousewheel settings in your OS. Tweak this pshift value however you'd like.


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

local function no_undo()reaper.defer(function()end)end

function Main()
  is_new,name,sec,cmd,rel,res,val = reaper.get_action_context()
  if val < 0 then
    -- LOWER PITCH
    for i = 0, speed do
      local item, position = reaper.BR_ItemAtMouseCursor()
      if item then
        local take = reaper.GetActiveTake(item)
        reaper.SetMediaItemTakeInfo_Value(take, "D_PITCH", reaper.GetMediaItemTakeInfo_Value(take, "D_PITCH") - pshift / 2)
        reaper.UpdateItemInProject(item)
      end
    end
  else
    -- RAISE PITCH
    for i = 0, speed do
      local item, position = reaper.BR_ItemAtMouseCursor()
      if item then
        local take = reaper.GetActiveTake(item)
        reaper.SetMediaItemTakeInfo_Value(take, "D_PITCH", reaper.GetMediaItemTakeInfo_Value(take, "D_PITCH") + pshift / 2)
        reaper.UpdateItemInProject(item)
      end
    end
  end
  reaper.SetCursorContext(1, nil)
end

reaper.PreventUIRefresh(1)
Main()
reaper.PreventUIRefresh(-1)

