-- @description Set Snap Offset First Transient
-- @author ausbaxter, acendan
-- @version 1.0
-- @metapackage
-- @provides
--   [main] .
-- @link https://ko-fi.com/acendan_
-- @changelog
--   # 2024-06-04 acendan - Moved items to end of project to avoid overlapping item transient alignment issues

item_tbl = {}
for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
  table.insert(item_tbl, reaper.GetSelectedMediaItem(0,i))
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

cursor_origin = reaper.GetCursorPosition()
reaper.Main_OnCommand(40043, 0) -- Transport: Go to end of project
cursor_proj_end = reaper.GetCursorPosition()

for i, item in ipairs(item_tbl) do
  local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
  reaper.SetMediaItemInfo_Value(item, "D_POSITION", cursor_proj_end)
  reaper.SetEditCurPos2(0, cursor_proj_end, false, false)
  reaper.Main_OnCommand(40375,0) -- Item navigation: Move cursor to next transient in items
  reaper.Main_OnCommand(40541,0) -- Item: Set snap offset to cursor
  reaper.SetMediaItemInfo_Value(item, "D_POSITION", item_pos)
end

reaper.SetEditCurPos2(0, cursor_origin, false, false)

reaper.Main_OnCommand(1012, 0) -- View: Zoom in horizontal
reaper.Main_OnCommand(1011, 0) -- View: Zoom out horizontal

reaper.UpdateArrange()
reaper.UpdateTimeline()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock("Set snap offset to first transient in items", -1)
