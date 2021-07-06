-- @noindex
-- @description GUI Media Explorer Cover Art
-- @author Aaron Cendan
-- @version 1.0
-- @metapackage
-- @provides
--   [main] . > acendan_GUI_Display selected media explorer item embedded cover image art.lua
-- @link https://aaroncendan.me
-- @about
--   Requires ffmpeg

-- FFMPEG COMMAND
-- "C:\REAPER\UserPlugins\ffmpeg" -i "DESIRED WAV FILEPATH" -an -y -vcodec copy "TEMP IMG FILEPATH"

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Get this script's name and directory
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local script_directory = ({reaper.get_action_context()})[2]:sub(1,({reaper.get_action_context()})[2]:find("\\[^\\]*$"))

-- Load lua utilities
acendan_LuaUtils = reaper.GetResourcePath()..'/scripts/ACendan Scripts/Development/acendan_Lua Utilities.lua'
if reaper.file_exists( acendan_LuaUtils ) then dofile( acendan_LuaUtils ); if not acendan or acendan.version() < 4.4 then acendan.msg('This script requires a newer version of ACendan Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"ACendan Lua Utilities"); return end else reaper.ShowConsoleMsg("This script requires ACendan Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'ACendan Lua Utilities'"); return end

-- Get media explorer hwnd
local hWnd = reaper.JS_Window_Find(reaper.JS_Localize("Media Explorer","common"), true)
if hWnd == nil then acendan.msg("Unable to find media explorer. Try going to:\n\nExtensions > ReaPack > Browse Packages\n\nand re-installing the JS_Reascript extension.","Media Explorer Items") return end  

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ GUI SETUP ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
defer_cnt=0
function cooldown()
  if defer_cnt >= 20 then -- run mainloop() every ~600ms
    defer_cnt=0
    reaper.PreventUIRefresh(1)
    main()
    reaper.PreventUIRefresh(-1)
  else
    defer_cnt=defer_cnt+1
  end
  gfxchar=gfx.getchar(); if gfxchar >= 0 then reaper.defer(cooldown); end
end

local gui = {}
function init()
  gui.settings = {}                 -- Add "settings" table to "gui" table 
  gui.settings.font_size = 20       -- font size
  gui.settings.docker_id = 0        -- try 0, 1, 257, 513, 1027 etc.
  
  gfx.init("Cover Art", 200, 200, gui.settings.docker_id)
  gfx.setfont(1,"Arial", gui.settings.font_size)
  gfx.dock(0)
  gfx.clear = 3355443

  main()
end


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function main()
  displayImage("C:\\Users\\Aaron\\Documents\\REAPER Media\\Field Recording\\Crowdsources\\Boring Cars\\Renders\\Photos\\Test.jpg")
  acendan.dbg(getSelectedItemsPathMediaExplorer())
  gfx.update()
end

function displayImage(image)
  local imageBuffer = gfx.loadimg(buffer, image)
  if imageBuffer then 
    -- Fetch image size then load image
    local image_w, image_h = gfx.getimgdim(imageBuffer)
    gfx.blit(imageBuffer,1,0,0,0,image_w,image_h,0,0,gfx.w,gfx.h)
  else
    error("IButton: The specified image was not found") 
  end
end

-- Get selected item file path media explorer
function getSelectedItemsPathMediaExplorer()
  local container = reaper.JS_Window_FindChildByID(hWnd, 0)
  local file_LV = reaper.JS_Window_FindChildByID(container, 1000)
  sel_count, sel_indexes = reaper.JS_ListView_ListAllSelItems(file_LV)
  if sel_count > 0 then 
    return reaper.JS_ListView_GetItemText(file_LV, 1, 2)
  else
    return nil
  end
end

init()
cooldown()
