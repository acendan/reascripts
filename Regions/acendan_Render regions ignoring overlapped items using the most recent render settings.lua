-- @description Render Regions Ignoring Overlaps
-- @author Aaron Cendan
-- @version 1.0
-- @metapackage
-- @provides
--   [main] .
-- @link https://ko-fi.com/acendan_
-- @about
--   # Idea courtesy of the inimitable Juan Pablo Uribe

local acendan_LuaUtils = reaper.GetResourcePath()..'/Scripts/ACendan Scripts/Development/acendan_Lua Utilities.lua'
if reaper.file_exists( acendan_LuaUtils ) then dofile( acendan_LuaUtils ); if not acendan or acendan.version() < 7.2 then acendan.msg('This script requires a newer version of ACendan Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"ACendan Lua Utilities"); return end else reaper.ShowConsoleMsg("This script requires ACendan Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'ACendan Lua Utilities'"); return end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ CONSTANTS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

local SCRIPT_NAME = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local SCRIPT_DIR = ({reaper.get_action_context()})[2]:sub(1,({reaper.get_action_context()})[2]:find("\\[^\\]*$"))

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function main()

  local render_settings = acendan.getRenderSettings()
  local rendering_regions = render_settings.rendersettings & acendan.RENDER_SETTINGS.USE_RENDER_MATRIX ~= 0
  if not rendering_regions then acendan.msg("Set source to Region Render Matrix in the render dialog!", "Render Regions") return end

  local items = getAllItems()
  if #items == 0 then acendan.msg("No items in project!", "Render Regions") return end

  if render_settings.boundsflag == acendan.RENDER_BOUNDSFLAG.ALL_PROJECT_REGIONS then
    local ret, num_markers, num_regions = reaper.CountProjectMarkers( 0 )
    local num_total = num_markers + num_regions
    if num_regions > 0 then
      local i = 0
      while i < num_total do
        local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, i )
        if isrgn then
          disableOverlappingItems(items, pos, rgnend, name)
        end
        i = i + 1
      end
    else
      acendan.msg("Project has no regions!")
    end
  
  elseif render_settings.boundsflag == acendan.RENDER_BOUNDSFLAG.SELECTED_PROJECT_REGIONS then
    local sel_rgn_table = acendan.getSelectedRegions()
    if sel_rgn_table then 
      local ret, num_markers, num_regions = reaper.CountProjectMarkers( 0 )
      local num_total = num_markers + num_regions
      
      for _, regionidx in pairs(sel_rgn_table) do 
        local i = 0
        while i < num_total do
          local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, i )
          if isrgn and markrgnindexnumber == regionidx then
            disableOverlappingItems(items, pos, rgnend, name)
            break
          end
          i = i + 1
        end
      end
    else
      acendan.msg("No regions selected!\n\nPlease go to View > Region/Marker Manager to select regions.\n\n\nIf you are on a Mac... sorry but there is a bug that prevents this script from working. Out of my control :(") 
    end
  else
    acendan.msg("Unrecognized region bounds flag! Please report this as a bug to aaron.cendan@gmail.com", "Render Regions")
    return
  end
  
  
  -- File: Render project, using the most recent render settings, auto-close render dialog
  reaper.Main_OnCommand(42230, 0)
  
  unmuteItems(items)
  
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ UTILITIES ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function getAllItems()
  local items = {}
  for i=0, reaper.CountMediaItems(0) - 1 do
    local item = reaper.GetMediaItem( 0, i )
    local item_start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local item_end = item_start + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    local item_muted = reaper.GetMediaItemInfo_Value(item, "B_MUTE")
    items[#items + 1] = {
      item       = item,
      item_start = item_start,
      item_end   = item_end,
      item_muted = item_muted
    }
  end
  return items
end

function disableOverlappingItems(items, rgn_start, rgn_end, rgn_name)
  for _, item in pairs(items) do
    -- If not fully contained in region...
    if not (item.item_start >= rgn_start and item.item_end <= rgn_end) then
      -- If overlapping edges...
      if (item.item_start < rgn_end and item.item_end > rgn_start) or
       (item.item_end > rgn_start and item.item_start < rgn_end) then
       reaper.SetMediaItemInfo_Value(item.item, "B_MUTE", 1)
       
       --acendan.dbg(rgn_name .. " - " .. reaper.GetTakeName(reaper.GetActiveTake(item.item)))
       --acendan.dbg("Item: " .. item.item_start .. " - " .. item.item_end)
       --acendan.dbg("Regn: " .. rgn_start .. " - " .. rgn_end)
      end
    end
  end
end

function unmuteItems(items)
  for _, item in pairs(items) do
    -- Respect original mute state
    if item.item_muted == 0 then
      reaper.SetMediaItemInfo_Value(item.item, "B_MUTE", 0)
    end
  end
end


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()
main()
reaper.Undo_EndBlock(SCRIPT_NAME,-1)
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
