-- @description Regions from Subprojects
-- @author Aaron Cendan
-- @version 1.1
-- @metapackage
-- @provides
--   [main] .
-- @link https://ko-fi.com/acendan_
-- @about
--   # Select subproject items from the parent main project, run this, and make some sweet regions


local acendan_LuaUtils = reaper.GetResourcePath()..'/Scripts/ACendan Scripts/Development/acendan_Lua Utilities.lua'
if reaper.file_exists(acendan_LuaUtils) then dofile(acendan_LuaUtils); if not acendan or acendan.version() < 8.0 then acendan.msg('This script requires a newer version of ACendan Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"ACendan Lua Utilities"); return end else reaper.ShowConsoleMsg("This script requires ACendan Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'ACendan Lua Utilities'"); return end

local WIN, SEP = acendan.getOS()
local SCRIPT_NAME = ({ reaper.get_action_context() })[2]:match("([^/\\_]+)%.lua$")
local SCRIPT_DIR = ({ reaper.get_action_context() })[2]:sub(1, ({ reaper.get_action_context() })[2]:find(SEP .. "[^" .. SEP .. "]*$"))

function main()
  for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    local filename, track, pcm_source = getFilenameTrackActiveTake(item)
    if (filename ~= nil) and (filename:sub(-3):upper() == "RPP") then 
      local subproj = reaper.GetSubProjectFromSource(pcm_source)
      
      local _, num_markers, num_regions = reaper.CountProjectMarkers( subproj )
      local num_total = num_markers + num_regions
      if num_markers > 0 then
      
        local new_rgn_name = ""
        local new_rgn_col = 0
        local new_rgn_start = -1
        local new_rgn_end = -1
      
        local j = 0
        while j < num_total do
          local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3(subproj, j)
          if not isrgn then
            if new_rgn_start < 0 then
              new_rgn_start = pos
              new_rgn_name = name
              new_rgn_col = color
            else
              new_rgn_end = pos
              
              reaper.AddProjectMarker2(0, true, new_rgn_start, new_rgn_end, new_rgn_name, -1, new_rgn_col) 
              
              new_rgn_start = new_rgn_end
              new_rgn_name = name
              new_rgn_col = color
            end
          end
          j = j + 1
        end
      end
    end
  end
end

function getFilenameTrackActiveTake(item)
  if item ~= nil then
    local tk = reaper.GetActiveTake(item)
    if tk ~= nil then
      local pcm_source = reaper.GetMediaItemTake_Source(tk)
      local filenamebuf = ""
      filenamebuf = reaper.GetMediaSourceFileName(pcm_source, filenamebuf)
      local track = reaper.GetMediaItemTrack(item)
      return filenamebuf, track, pcm_source
    end
  end
  return nil, nil
end

reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()
main()
reaper.Undo_EndBlock(SCRIPT_NAME,-1)
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()

