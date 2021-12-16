-- @description Game Recommendation Engine
-- @author Aaron Cendan
-- @version 1.0
-- @metapackage
-- @provides
--   [main] .
-- @link https://ko-fi.com/acendan_


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
    local _, _ = reaper.GetUserInputs( script_name .. " - Part 1/3", 2, "Most recent game played?,Did you like it?,extrawidth=200", "Halo Infinite,Number Scale: 1 (Hated) - 5 (Loved)" )
    local _, _ = reaper.GetUserInputs( script_name .. " - Part 2/3", 2, "Most played game all time?,Do you play competitively?,extrawidth=200", "Valorant,Number Scale: 1 (Not at all) - 5 (Fight me.)" )
    local _, _ = reaper.GetUserInputs( script_name .. " - Part 3/3", 2, "Favorite series/franchise?,Have you played all releases?,extrawidth=200", "Legend of Zelda,Number Scale: 1 (Just one...) - 5 (Always pre-order)" )

    for i=0,100 do
        reaper.ClearConsole()

        local tick = ""
        if (i%4 == 1) then tick = "[^]"
        elseif (i%4 == 2) then tick = "[>]" 
        elseif (i%4 == 3) then tick = "[v]" 
        elseif (i%4 == 4) then tick = "[<]"
        end
        
        if (i < 33) then
            acendan.dbg("Calculating " .. tick:rep(i%3))
        elseif (i < 66) then
            acendan.dbg("Scanning databases " .. tick:rep(i%3))
        else
            acendan.dbg("Finalizing " .. tick:rep(i%3))   
        end

        sleep(0.2)
    end

    reaper.Main_OnCommand(reaper.NamedCommandLookup("_S&M_WNMAIN_HIDE_OTHERS"),0) -- focus main
    reaper.MB("Given your preferences and excellent taste in video games...","",4)
    reaper.MB("The algorithm has decided that you should play...","",4)
    reaper.MB("Super Smash Brothers Melee for the Nintendo GameCube","",0)
end

function sleep(s)
    local ntime = os.clock() + s/10
    repeat until os.clock() > ntime
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
