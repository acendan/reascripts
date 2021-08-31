-- @description Random Track FX
-- @author Aaron Cendan
-- @version 1.0
-- @metapackage
-- @provides
--   [main] .
-- @link https://ko-fi.com/acendan_

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Get this script's name and directory
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local script_directory = ({reaper.get_action_context()})[2]:sub(1,({reaper.get_action_context()})[2]:find("\\[^\\]*$"))

-- Load lua utilities
acendan_LuaUtils = reaper.GetResourcePath()..'/scripts/ACendan Scripts/Development/acendan_Lua Utilities.lua'
if reaper.file_exists( acendan_LuaUtils ) then dofile( acendan_LuaUtils ); if not acendan or acendan.version() < 4.4 then acendan.msg('This script requires a newer version of ACendan Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"ACendan Lua Utilities"); return end else reaper.ShowConsoleMsg("This script requires ACendan Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'ACendan Lua Utilities'"); return end


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function main()
  local win, sep = acendan.getOS()
  local vst_file = reaper.GetResourcePath() .. sep .. "reaper-vstplugins64.ini"
  local vsts = {}
  if reaper.file_exists(vst_file) then
    -- Fetch VSTs
    local vst_tbl = acendan.fileToTable(vst_file)
    for _, v in pairs(vst_tbl) do
      local vst = v:gsub(" %(.*","")
      if vst:find(",") and not vst:find("<SHELL>") then
        vst = vst:sub(vst:find(",[^,]*$")+1)
        vsts[#vsts+1]=vst
      end
    end

    -- Loop through selected tracks
    local num_sel_tracks = reaper.CountSelectedTracks( 0 )
    if num_sel_tracks > 0 then
      for i = 0, num_sel_tracks-1 do
        local track = reaper.GetSelectedTrack(0,i)
        reaper.TrackFX_AddByName(track,vsts[math.random(#vsts)],false,-1)
        reaper.TrackFX_Show(track, reaper.TrackFX_GetCount(track)-1,3)
      end
    else
      acendan.msg("No tracks selected!")
    end
  else
    acendan.msg("Unable to find reaper-vstplugins64.ini file!")
  end
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

