-- @description Stretch selected items to fit between nearest markers
-- @author Aaron Cendan
-- @version 1.1
-- @metapackage
-- @provides
--   [main] . > acendan_Stretch selected items to fit between nearest markers.lua
-- @link https://aaroncendan.me
-- @changelog
--   # Added setting for stretching inside nearest regions, thanks @kytdkut!

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~ USER CONFIG - EDIT ME ~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Toggle to 'true' to stretch inside nearest regions instead of markers
stretch_inside_regions = false

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function StretchItems()
  local items = reaper.CountSelectedMediaItems(0)
  if items > 0 then
    reaper.Undo_BeginBlock(); 
    
    tb = {}
    for i = 0, items-1 do tb[#tb+1] = reaper.GetSelectedMediaItem(0,i) end
    for i = 1, #tb do
      reaper.Main_OnCommand(40289,0) -- unselect items
      reaper.SetMediaItemSelected(tb[i], 1)
  
      -- Set time selection to area between nearest markers
      item_start = reaper.GetMediaItemInfo_Value( tb[i], "D_POSITION" )
      item_len = reaper.GetMediaItemInfo_Value( tb[i], "D_LENGTH" )
      item_mid = item_start + ( item_len / 2 )
      
      local m_start_i, m_start, m_end
      if stretch_inside_regions then
        local _, l_start_i = reaper.GetLastMarkerAndCurRegion(0, item_mid)
        if l_start_i == -1 then return end
        m_start_i = l_start_i

        local _,_, l_start, l_end = reaper.EnumProjectMarkers(m_start_i)
        m_start = l_start
        m_end = l_end
      else
        local l_start_i = reaper.GetLastMarkerAndCurRegion(0, item_mid)
        if l_start_i == -1 then return end
        m_start_i = l_start_i

        local _,_, l_start = reaper.EnumProjectMarkers(m_start_i)
        local _,_, l_end = reaper.EnumProjectMarkers(m_start_i+1)
        m_start = l_start
        m_end = l_end
      end

      if m_end and (m_end<m_start or m_end==m_start) then return end
      reaper.GetSet_LoopTimeRange(1, 0, m_start, m_end, 0)
      
      reaper.Main_OnCommand(41206,0) -- move and stretch item to fit time selection
    end
    for i = 1, #tb do reaper.SetMediaItemSelected(tb[i], 1) end
    
    reaper.Undo_EndBlock('Stretch items to markers', -1)
  else
    reaper.MB("No items selected!","Stretch Items",0)
  end
end
  
function SaveLoopTimesel()
  init_start_timesel, init_end_timesel = reaper.GetSet_LoopTimeRange(0, 0, 0, 0, 0)
  init_start_loop, init_end_loop = reaper.GetSet_LoopTimeRange(0, 1, 0, 0, 0)
end
  
function RestoreLoopTimesel()
  reaper.GetSet_LoopTimeRange(1, 0, init_start_timesel, init_end_timesel, 0)
  reaper.GetSet_LoopTimeRange(1, 1, init_start_loop, init_end_loop, 0)
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
reaper.PreventUIRefresh(1)

SaveLoopTimesel()

StretchItems()

RestoreLoopTimesel()

reaper.PreventUIRefresh(-1)

reaper.UpdateArrange()
