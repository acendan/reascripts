-- @description Reset Item Pitch and Playback Rate
-- @author Aaron Cendan
-- @version 1.0
-- @metapackage
-- @provides
--   [main] . > acendan_Reset item properties pitch adjustment and playback rate to default.lua
-- @link https://aaroncendan.me

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function main()
  local item = reaper.GetSelectedMediaItem( 0, 0 )
  local take = reaper.GetActiveTake( item )
  
  reaper.SetMediaItemTakeInfo_Value( take, "D_PITCH", 0 )
  reaper.SetMediaItemTakeInfo_Value( take, "D_PLAYRATE", 1)
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock()

main()

reaper.Undo_EndBlock("Reset Item Pitch Playback",-1)

reaper.PreventUIRefresh(-1)

reaper.UpdateArrange()
