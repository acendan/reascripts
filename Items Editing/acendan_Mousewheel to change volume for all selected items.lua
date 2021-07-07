-- @description Mousewheel Sel Item Vol
-- @author Aaron Cendan
-- @version 1.2
-- @metapackage
-- @provides
--   [main] . > acendan_Mousewheel to change volume for all selected items.lua
-- @link https://aaroncendan.me
-- @about
--   MPL's libraries cost money and I'm not bout that life. Re-wrote it. Doesn't do fancy logarithm stuff, sorry.
-- @changelog
--   # Converted to db increment

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~ USER CONFIG - EDIT ME ~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

speed = 1        -- 0 is slowest speed. Set to higher integers to shift faster
vshift = 0.2     -- The amount to volume shift by, in dB. One 'bump' on my mousewheel is equal to vshift * 2, but this offset will likely
                 -- vary depending on the mousewheel settings in your OS. Tweak this value however you'd like.


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Load lua utilities
acendan_LuaUtils = reaper.GetResourcePath()..'/scripts/ACendan Scripts/Development/acendan_Lua Utilities.lua'
if reaper.file_exists( acendan_LuaUtils ) then dofile( acendan_LuaUtils ); if not acendan or acendan.version() < 4.8 then acendan.msg('This script requires a newer version of ACendan Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"ACendan Lua Utilities"); return end else reaper.ShowConsoleMsg("This script requires ACendan Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'ACendan Lua Utilities'"); return end

local function no_undo()reaper.defer(function()end)end

function Main()
  is_new,name,sec,cmd,rel,res,val = reaper.get_action_context()
  local num_sel_items = reaper.CountSelectedMediaItems(0)
  if val < 0 then
    -- LOWER PITCH
    for i = 0, speed do
      if num_sel_items > 0 then
        for i=0, num_sel_items - 1 do
          local item = reaper.GetSelectedMediaItem( 0, i )
          local it_vol = reaper.GetMediaItemInfo_Value( item, 'D_VOL' )
          local it_vol_db = acendan.VAL2DB(it_vol)
          local it_vol_out = math.max(acendan.DB2VAL(it_vol_db - vshift),0)
          reaper.SetMediaItemInfo_Value( item, 'D_VOL' ,it_vol_out )
          reaper.UpdateItemInProject( item )
        end
      end
    end
  else
    -- RAISE PITCH
    for i = 0, speed do
      if num_sel_items > 0 then
        for i=0, num_sel_items - 1 do
          local item = reaper.GetSelectedMediaItem( 0, i )
          local it_vol = reaper.GetMediaItemInfo_Value( item, 'D_VOL' )
          local it_vol_db = acendan.VAL2DB(it_vol)
          local it_vol_out = math.max(acendan.DB2VAL(it_vol_db + vshift),0)
          reaper.SetMediaItemInfo_Value( item, 'D_VOL' ,it_vol_out )
          reaper.UpdateItemInProject( item )
        end
      end
    end
  end
  reaper.SetCursorContext(1, nil)
end

reaper.PreventUIRefresh(1)
Main()
reaper.PreventUIRefresh(-1)

