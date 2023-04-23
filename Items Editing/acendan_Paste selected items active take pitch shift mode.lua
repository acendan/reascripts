-- @description Paste Pitch Shift Mode
-- @author Aaron Cendan
-- @version 1.0
-- @metapackage
-- @provides
--   [main] .
-- @link https://ko-fi.com/acendan_
-- @about
--   # Thanks for the idea, Nikolaj!

-- Get this script's name and directory
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local script_directory = ({reaper.get_action_context()})[2]:sub(1,({reaper.get_action_context()})[2]:find("\\[^\\]*$"))

-- Load lua utilities
acendan_LuaUtils = reaper.GetResourcePath()..'/Scripts/ACendan Scripts/Development/acendan_Lua Utilities.lua'
if reaper.file_exists( acendan_LuaUtils ) then dofile( acendan_LuaUtils ); if not acendan or acendan.version() < 6.2 then acendan.msg('This script requires a newer version of ACendan Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"ACendan Lua Utilities"); return end else reaper.ShowConsoleMsg("This script requires ACendan Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'ACendan Lua Utilities'"); return end

function main()
 local clipboard = tonumber(reaper.CF_GetClipboard())
  if not clipboard then
    acendan.msg("Failed to get pitch mode from clipboard! Please run the 'copy item pitch mode' script first.")
    return
  end
  
  -- Loop through selected items
  local num_sel_items = reaper.CountSelectedMediaItems(0)
  if num_sel_items > 0 then
    for i=0, num_sel_items - 1 do
      local item = reaper.GetSelectedMediaItem( 0, i )
      local take = reaper.GetActiveTake( item )
      if take ~= nil then 
        reaper.SetMediaItemTakeInfo_Value(take, "I_PITCHMODE", clipboard)
      end
    end
  else
    acendan.msg("No items selected!")
  end
end

reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()
main()
reaper.Undo_EndBlock(script_name,-1)
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
