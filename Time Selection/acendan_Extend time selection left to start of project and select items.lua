-- @description Extend Time Selection to Start
-- @author Aaron Cendan
-- @version 1.0
-- @metapackage
-- @provides
--   [main] . > acendan_Extend time selection left to start of project and select items.lua
-- @link https://aaroncendan.me

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
  -- Get cursor info
  local _, cur_end = reaper.GetSet_LoopTimeRange(0, 0, 0, 0, 0)
  -- Set time selection
  reaper.GetSet_LoopTimeRange(1, 0, 0, cur_end, 0)
  reaper.GetSet_LoopTimeRange(1, 1, 0, cur_end, 0)

  -- Modification of me2beats_Select only items from start of project to cursor.lua
  t = {}
  local items = reaper.CountMediaItems()
  for i = 0, items-1 do
    local item = reaper.GetMediaItem(0, i)
    local it_start = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
    if it_start+0.000001 < cur_end then t[#t+1] = item end
  end
  if #t ~= 0 then
    reaper.SelectAllMediaItems(0, 0) -- unselect all items
    for i = 1,#t do reaper.SetMediaItemSelected(t[i],1); reaper.UpdateItemInProject(t[i]) end
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

