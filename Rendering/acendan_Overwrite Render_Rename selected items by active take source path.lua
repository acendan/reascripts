-- @noindex
-- @description Render Overwrite Item Source
-- @author Aaron Cendan
-- @version 1.0
-- @metapackage
-- @provides
--   [main] . > acendan_Overwrite Render_Rename selected items by active take source path.lua
-- @link https://aaroncendan.me
-- @about
--   This script allows for easily rendering over an item's source file
--   A few caveats:
--      * "Silently increment" must be unchecked in the render window
--      * All items must be rendered to the same hard drive, as the root directory is hard-coded into the render dialog
--      * Will only overwrite files with render formats that match the extension of the source

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~ USER CONFIG - EDIT ME ~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Change this variable to match your preferred render settings:
--    false -> "Selected media items"
--    true -> "Selected media items via master"
local render_items_via_master = true

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Get this script's name and directory
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local script_directory = ({reaper.get_action_context()})[2]:sub(1,({reaper.get_action_context()})[2]:find("\\[^\\]*$"))

-- Load lua utilities
acendan_LuaUtils = reaper.GetResourcePath()..'/scripts/ACendan Scripts/Development/acendan_Lua Utilities.lua'
if reaper.file_exists( acendan_LuaUtils ) then dofile( acendan_LuaUtils ); if not acendan or acendan.version() < 4.4 then acendan.msg('This script requires a newer version of ACendan Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"ACendan Lua Utilities"); return end else reaper.ShowConsoleMsg("This script requires ACendan Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'ACendan Lua Utilities'"); return end

-- Check operating system
local windows = string.find(reaper.GetOS(), "Win") ~= nil
local separator = windows and '\\' or '/'

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function main()
  -- Loop through selected items
  local num_sel_items = reaper.CountSelectedMediaItems(0)
  if num_sel_items > 0 then
    for i=0, num_sel_items - 1 do
      local item = reaper.GetSelectedMediaItem( 0, i )
      local take = reaper.GetActiveTake( item )
      if take ~= nil then 
        local pcm_source = reaper.GetMediaItemTake_Source(take)
        local filenamebuf = ""
        filenamebuf = reaper.GetMediaSourceFileName(pcm_source, filenamebuf)
        if filenamebuf ~= "" then
          -- String manipulation/parsing
          filenamebuf = filenamebuf:gsub("\\",separator)
          local directory = filenamebuf:sub(1,filenamebuf:find(separator))
          local extension = GetFileExtension(filenamebuf)
          local filename = filenamebuf:gsub(directory,""):gsub(extension,"")
          
          -- Set item names and render settings
          reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", filename, true)
          reaper.GetSetProjectInfo_String(0, "RENDER_FILE", directory, true)
          reaper.GetSetProjectInfo_String(0, "RENDER_PATTERN", "$item", true)
          if render_items_via_master then reaper.GetSetProjectInfo(0, "RENDER_SETTINGS", 64, true) else reaper.GetSetProjectInfo(0, "RENDER_SETTINGS", 32, true) end
        end
      end
    end
  else
    acendan.msg("No items selected!")
  end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ UTILITIES ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function GetFileExtension(filename)
  return filename:match("^.+(%..+)$")
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
