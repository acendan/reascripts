-- @description Add Marker End Items
-- @author Aaron Cendan
-- @version 1.2
-- @metapackage
-- @provides
--   [main] . > acendan_Add marker to end of selected items prompt for name.lua
-- @link https://aaroncendan.me
-- @changelog
--   # Update LuaUtils path with case sensitivity for Linux

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~ USER CONFIG - EDIT ME ~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Get this script's name and directory
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local script_directory = ({reaper.get_action_context()})[2]:sub(1,({reaper.get_action_context()})[2]:find("\\[^\\]*$"))

-- Load lua utilities
acendan_LuaUtils = reaper.GetResourcePath()..'/Scripts/ACendan Scripts/Development/acendan_Lua Utilities.lua'
if reaper.file_exists( acendan_LuaUtils ) then dofile( acendan_LuaUtils ); if not acendan or acendan.version() < 4.4 then acendan.msg('This script requires a newer version of ACendan Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"ACendan Lua Utilities"); return end else reaper.ShowConsoleMsg("This script requires ACendan Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'ACendan Lua Utilities'"); return end


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function main()
  -- Loop through selected items
  local num_sel_items = reaper.CountSelectedMediaItems(0)
  if num_sel_items > 0 then
    -- Prompt for user input
    local ret_input, user_input = reaper.GetUserInputs( "Item End Markers", 3,
                              "Marker Name,Marker Pos Offset,Project (p) or Take (t) Marker" .. ",extrawidth=100",
                              "end,0.0,t" )
    if not ret_input then return end
    local mkr_name, pos_off, proj_or_take = user_input:match("([^,]+),([^,]+),([^,]+)")
    pos_off = tonumber(pos_off)
    
  
    for i=0, num_sel_items - 1 do
      local item = reaper.GetSelectedMediaItem( 0, i )
      local item_start = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
      local item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH" )
      local item_end = item_start + item_len
      
      if proj_or_take == "t" then
        -- Add as take marker
        reaper.SetTakeMarker(reaper.GetActiveTake(item),-1,mkr_name,(item_end + pos_off) - item_start)
        
      else
        -- Add as project marker
        reaper.AddProjectMarker( 0, 0, item_end + pos_off, item_end + pos_off, mkr_name, i )
      end
    end
  else
    acendan.msg("No items selected!")
  end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ UTILITIES ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock()

main()

reaper.Undo_EndBlock(script_name,-1)

reaper.PreventUIRefresh(-1)

reaper.UpdateArrange()

