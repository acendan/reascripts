-- @description Organize TeamTalk Conference Recordings
-- @author Aaron Cendan
-- @version 1.1
-- @metapackage
-- @provides
--   [main] .
-- @link https://ko-fi.com/acendan_
-- @about
--   # TeamTalk Conference Recordings
-- @changelog
--   # Update LuaUtils path with case sensitivity for Linux

--[[

TEAMTALK RECORDING FORMAT:
YYYYMMDD-MILTIME #USER (UserName).wav

20220501-221708 #0 AaronCendan.wav
20220501-221708 #459.wav
20220501-221720 #461.wav
20220501-221724 #461.wav
20220501-221921 #459.wav
20220501-221924 #459.wav
20220501-221938 #463.wav
20220501-221956 #459.wav

]]--

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
if reaper.file_exists( acendan_LuaUtils ) then dofile( acendan_LuaUtils ); if not acendan or acendan.version() < 6.0 then acendan.msg('This script requires a newer version of ACendan Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"ACendan Lua Utilities"); return end else reaper.ShowConsoleMsg("This script requires ACendan Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'ACendan Lua Utilities'"); return end


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function main()
  -- Loop through all items
  local num_items = reaper.CountMediaItems( 0 )
  if num_items > 0 then
  
    -- Populate tables with valid TeamTalk items
    local item_tbl = {}
    local dates_tbl = {}
    local users_tbl = {}
    for i=0, num_items - 1 do
      local item =  reaper.GetMediaItem( 0, i )
      local take = reaper.GetActiveTake( item )
      if take ~= nil then 
        local _, item_name = reaper.GetSetMediaItemTakeInfo_String(take,"P_NAME","",false)
        if item_name:len() > 0 then
        
          local item_tt_date = getTTDate(item_name)
          local item_tt_time = getTTTime(item_name)
          local item_tt_user = getTTUser(item_name)
          
          -- If item has valid TeamTalk filename...
          if item_tt_date and item_tt_time and item_tt_user then
            
            -- Reformat date, time, user for insertion in project
            item_tt_date = tonumber(item_tt_date)
            item_tt_time = tonumber(timeToRaw(item_tt_time:sub(2,-1)))
            item_tt_user = "User " .. item_tt_user
            --acendan.dbg(item_tt_date .. " - " .. item_tt_time .. " - " .. item_tt_user)
            
            -- Add to items table
            item_tbl[#item_tbl+1] = { item, item_tt_date, item_tt_time, item_tt_user }
            
            -- Populate dates and users table
            if not acendan.tableContainsVal(dates_tbl, item_tt_date) then dates_tbl[#dates_tbl+1] = item_tt_date end
            if not acendan.tableContainsVal(users_tbl, item_tt_user) then users_tbl[#users_tbl+1] = item_tt_user end
          end
        end
      end
    end
    
    -- Confirm that there's at least one TT item
    if #item_tbl > 0 then
      
      -- Sort date and user tables
      table.sort(dates_tbl)
      table.sort(users_tbl)

      -- Get earliest recording time
      local earliest_day = dates_tbl[1]
      local earliest_time = getEarliestTime(item_tbl, earliest_day)
      
      -- Create new tracks for users
      local users_tracks_tbl = {}
      -- Add existing user tracks to table
      local num_tracks =  reaper.CountTracks( 0 )
      if num_tracks > 0 then
        for i = 0, num_tracks-1 do
          local track = reaper.GetTrack(0,i)
          local ret, track_name = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", 0)
          if ret and track_name:len() > 0 then
            local user_tbl_idx = acendan.tableContainsVal(users_tbl, track_name)
            if user_tbl_idx then 
              -- Found existing track with current user number
              users_tracks_tbl[user_tbl_idx] = track 
            end
          end
        end
      end
      -- Create new tracks for those that don't have one
      for k, v in ipairs(users_tbl) do
        if not users_tracks_tbl[k] then 
          local track_idx = reaper.GetNumTracks()
          reaper.InsertTrackAtIndex(track_idx,true)
          users_tracks_tbl[k] = reaper.GetTrack(0, track_idx)
          reaper.GetSetMediaTrackInfo_String(users_tracks_tbl[k], "P_NAME", tostring(v), true)
        end
      end
      
      -- Loop through item table and move to track/time
      local item_info = {}
      for k, item_info in ipairs(item_tbl) do
        local item = item_info[1]
        local item_tt_date = item_info[2]
        local item_tt_time = item_info[3]
        local item_tt_user = item_info[4]
        
        -- Move to track
        reaper.MoveMediaItemToTrack(item, users_tracks_tbl[acendan.tableContainsVal(users_tbl, item_tt_user)])
        
        -- Move to timeline position
        local item_relative_time = item_tt_time + ((acendan.tableContainsVal(dates_tbl,item_tt_date) - 1) * 86400 ) - earliest_time
        reaper.SetMediaItemPosition(item, item_relative_time, false)
      end
      
    else
      acendan.msg("Didn't find any valid TeamTalk conference recordings! Please import your TeamTalk conference recordings in the active Reaper project.")
    end
  else
    acendan.msg("Project has no items! Please import your TeamTalk conference recordings in the active Reaper project.")
  end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ UTILITIES ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function getTTDate(name)
  return name:match("%d+")
end

function getTTTime(name)
  return name:match("%-%d+")
end


function getTTUser(name)
  return name:match("%#%d+")
end

function getEarliestTime(item_tbl, earliest_day)
  local earliest_time = math.huge
  for k, item_info in ipairs(item_tbl) do
    local item_tt_date = item_info[2]
    local item_tt_time = item_info[3]
    if item_tt_date == earliest_day then
      if item_tt_time < earliest_time then earliest_time = item_tt_time end
    end
  end
  return earliest_time
end

-- Convert HHMMSS to raw seconds
function timeToRaw(time)
  --      Hours                              Minutes                         Seconds
  return (tonumber(time:sub(1,2)) * 3600) + (tonumber(time:sub(3,4)) * 60) + tonumber(time:sub(5,6))
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

