-- @description Mousewheel Items Volume
-- @author Aaron Cendan
-- @version 1.2
-- @metapackage
-- @provides
--   [main] . > acendan_Mousewheel adjust source volume of item active take under cursor.lua
-- @link https://aaroncendan.me
-- @about
--   # Thanks NVK for the mousewheel script formatting <3
-- @changelog
--   # Added optional reverse direction toggle


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~ USER CONFIG - EDIT ME ~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

speed = 1             -- 0 is slowest speed. Set to higher integers to shift values faster

vshift = 0.25         -- The amount to volume shift by, in dB. One 'bump' on my mousewheel is equal to vshift * 2, but this offset will likely
                      -- vary depending on the mousewheel settings in your OS. Tweak this value however you'd like.

selected_items = true -- If set to true, this will adjust volume of selected items when mouse is NOT hovering over a specific item.

track_vol = true      -- If set to true, this will adjust the volume of the track under the mouse when mouse is over the TCP

reverse_dir = false   -- If set to true, this will reverse the direction of the scroll wheel

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Load lua utilities
acendan_LuaUtils = reaper.GetResourcePath()..'/scripts/ACendan Scripts/Development/acendan_Lua Utilities.lua'
if reaper.file_exists( acendan_LuaUtils ) then dofile( acendan_LuaUtils ); if not acendan or acendan.version() < 4.8 then acendan.msg('This script requires a newer version of ACendan Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"ACendan Lua Utilities"); return end else reaper.ShowConsoleMsg("This script requires ACendan Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'ACendan Lua Utilities'"); return end

local function no_undo()reaper.defer(function()end)end

function Main()
  is_new,name,sec,cmd,rel,res,val = reaper.get_action_context()
  trk,ctxt,_ = reaper.BR_TrackAtMouseCursor()
  
  val = reverse_dir and -val or val

  -- IF HOVERING OVER TRACK CONTROL PANEL
  if ctxt == 0 and trk and track_vol then
    if val < 0 then
      -- LOWER VOLUME
      for i = 0, speed do
        -- MPL made his fancy pants scripts paid... smh
        local it_vol = reaper.GetMediaTrackInfo_Value( trk, 'D_VOL' ) 
        local it_vol_db = acendan.VAL2DB(it_vol)
        local it_vol_out = math.max(acendan.DB2VAL(it_vol_db - vshift),0)
        
        reaper.SetMediaTrackInfo_Value(trk, 'D_VOL', it_vol_out)

      end
    else
      -- RAISE VOLUME
      for i = 0, speed do
        -- MPL made his fancy pants scripts paid... smh
        local it_vol = reaper.GetMediaTrackInfo_Value( trk, 'D_VOL' )
        local it_vol_db = acendan.VAL2DB(it_vol)
        local it_vol_out = math.max(acendan.DB2VAL(it_vol_db + vshift),0)
        
        reaper.SetMediaTrackInfo_Value(trk, 'D_VOL', it_vol_out)
      end
    end
  
  -- NOT HOVERING OVER TRACK CONTROL PANEL
  else
    if val < 0 then
      -- LOWER VOLUME
      for i = 0, speed do
        local item, position = reaper.BR_ItemAtMouseCursor()
        if item then
          local take = reaper.GetActiveTake(item)
          if take then
            -- MPL made his fancy pants scripts paid... smh
            local it_vol = reaper.GetMediaItemTakeInfo_Value( take, 'D_VOL' )
            local it_vol_db = acendan.VAL2DB(it_vol)
            local it_vol_out = math.max(acendan.DB2VAL(it_vol_db - vshift),0)
            
            reaper.SetMediaItemTakeInfo_Value(take, 'D_VOL', it_vol_out)
            reaper.UpdateItemInProject( item )
          end
  
        elseif selected_items then
          local num_sel_items = reaper.CountSelectedMediaItems(0)
          if num_sel_items > 0 then
            for i=0, num_sel_items - 1 do
              local item = reaper.GetSelectedMediaItem( 0, i )
              local take = reaper.GetActiveTake(item)
              if take then
                -- MPL made his fancy pants scripts paid... smh
                local it_vol = reaper.GetMediaItemTakeInfo_Value( take, 'D_VOL' )
                local it_vol_db = acendan.VAL2DB(it_vol)
                local it_vol_out = math.max(acendan.DB2VAL(it_vol_db - vshift),0)
                
                reaper.SetMediaItemTakeInfo_Value(take, 'D_VOL', it_vol_out)
                reaper.UpdateItemInProject( item )
              end
            end
          end
        end
      end
    else
      -- RAISE VOLUME
      for i = 0, speed do
        local item, position = reaper.BR_ItemAtMouseCursor()
        if item then
          local take = reaper.GetActiveTake(item)
          if take then
            -- MPL made his fancy pants scripts paid... smh
            local it_vol = reaper.GetMediaItemTakeInfo_Value( take, 'D_VOL' )
            local it_vol_db = acendan.VAL2DB(it_vol)
            local it_vol_out = math.max(acendan.DB2VAL(it_vol_db + vshift),0)
            
            reaper.SetMediaItemTakeInfo_Value(take, 'D_VOL', it_vol_out)
            reaper.UpdateItemInProject( item )
          end
        
        elseif selected_items then
          local num_sel_items = reaper.CountSelectedMediaItems(0)
          if num_sel_items > 0 then
            for i=0, num_sel_items - 1 do
              local item = reaper.GetSelectedMediaItem( 0, i )
              local take = reaper.GetActiveTake(item)
              if take then
                -- MPL made his fancy pants scripts paid... smh
                local it_vol = reaper.GetMediaItemTakeInfo_Value( take, 'D_VOL' )
                local it_vol_db = acendan.VAL2DB(it_vol)
                local it_vol_out = math.max(acendan.DB2VAL(it_vol_db + vshift),0)
                
                reaper.SetMediaItemTakeInfo_Value(take, 'D_VOL', it_vol_out)
                reaper.UpdateItemInProject( item )
              end
            end
          end
        end
      end
    end
    reaper.SetCursorContext(1, nil)
  end
end

reaper.PreventUIRefresh(1)
Main()
reaper.PreventUIRefresh(-1)

