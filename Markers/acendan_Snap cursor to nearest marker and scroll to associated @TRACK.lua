-- @description Marker Track Wildcards
-- @author Aaron Cendan
-- @version 1.1
-- @metapackage
-- @provides
--   [main] .
-- @link https://ko-fi.com/acendan_
-- @about
--   # To use this script, simply name your markers with an @ symbol at the start, followed by a number, then shift+alt+click on the ruler near a marker
--   # For example, you can have markers named:
--   #     @24          <- This would jump to track number 24 when you shift+alt+click on the ruler near that marker
--   #     @47 Impact   <- This would jump to track number 47, ignoring the additional text after your marker number wildcard
--   # Alt on PC = Option on Mac
-- @changelog
--   # Update LuaUtils path with case sensitivity for Linux

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Get this script's name and directory
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local cmd_id = ({reaper.get_action_context()})[4]
local script_directory = ({reaper.get_action_context()})[2]:sub(1,({reaper.get_action_context()})[2]:find("\\[^\\]*$"))

-- Load lua utilities
acendan_LuaUtils = reaper.GetResourcePath()..'/Scripts/ACendan Scripts/Development/acendan_Lua Utilities.lua'
if reaper.file_exists( acendan_LuaUtils ) then dofile( acendan_LuaUtils ); if not acendan or acendan.version() < 4.4 then acendan.msg('This script requires a newer version of ACendan Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"ACendan Lua Utilities"); return end else reaper.ShowConsoleMsg("This script requires ACendan Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'ACendan Lua Utilities'"); return end


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function main()

  local cur = reaper.GetCursorPosition()
  
  -- me2beats_Move cursor to closest marker.lua
  local projects_markers = reaper.CountProjectMarkers()
  local min_pos = 10000
  for i = 0, projects_markers-1 do
    local _, reg, m_pos, _, m_name = reaper.EnumProjectMarkers3(0, i)
    if not reg then
      if min_pos > math.abs(cur-m_pos) then 
        min_pos = math.abs(cur-m_pos)
        cur_ = m_pos
        name = m_name
      end
    end
  end
  if not cur_ then return end
  reaper.SetEditCurPos2(0, cur_, 1, 0)
  
  -- Check marker for track number wildcard
  if name ~= "" and name:find("@") then
    local track_num = tonumber(name:match("^@%d+"):sub(2))
    if track_num and type(track_num) == "number" then
      local track = reaper.GetTrack(0,track_num-1)
      if track then
        reaper.Main_OnCommand(40297,0)-- Unselect all tracks
        reaper.SetTrackSelected(track, true)
        reaper.Main_OnCommand(40913,0) -- Track: Vertical scroll selected tracks into view
        reaper.Main_OnCommand(40914,0) -- Track: Set first selected track as last touched track
      end
    end
  end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ UTILITIES ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function CheckSetModifier()
  local current_action = reaper.NamedCommandLookup(reaper.GetMouseModifier("MM_CTX_RULER_CLK",5,""))
  if current_action ~= cmd_id then
    local ok = reaper.MB("To use this script, simply name your markers with an @ symbol at the start, followed by a track number, then Shift+Alt+Click on the ruler near a marker. For example...\n\n@42 Big Impact        <- This would jump to track number 42.\n\nClicking 'OK' in this prompt will overwrite your mouse modifiers for\n'Shift + Alt + Left Click' on the Ruler.\n\nClick 'Edit Action' for further details.","READ ME PLEASE",1)
    if ok == 1 then
      reaper.SetMouseModifier("MM_CTX_RULER_CLK",5,cmd_id)
    end
  end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock()

CheckSetModifier()

main()

reaper.Undo_EndBlock(script_name,-1)

reaper.PreventUIRefresh(-1)

reaper.UpdateArrange()


