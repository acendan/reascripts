-- @description Multi Mic Manager
-- @author Aaron Cendan
-- @version 0.1
-- @metapackage
-- @provides
--   [main] .
-- @link https://ko-fi.com/acendan_
-- @about
--   # Allows for managing tracks interleaved with multiple mics on different channels
-- @changelog
--   # Render settings tables (thanks Ultraschall API!)

local acendan_LuaUtils = reaper.GetResourcePath()..'/Scripts/ACendan Scripts/Development/acendan_Lua Utilities.lua'
if reaper.file_exists( acendan_LuaUtils ) then dofile( acendan_LuaUtils ); if not acendan or acendan.version() < 7.3 then acendan.msg('This script requires a newer version of ACendan Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"ACendan Lua Utilities"); return end else reaper.ShowConsoleMsg("This script requires ACendan Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'ACendan Lua Utilities'"); return end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ CONSTANTS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

local SCRIPT_NAME = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local SCRIPT_DIR = ({reaper.get_action_context()})[2]:sub(1,({reaper.get_action_context()})[2]:find("\\[^\\]*$"))

local WINDOW_SIZE = { width = 210, height = 220 }
local WINDOW_FLAGS = reaper.ImGui_WindowFlags_NoCollapse()


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function init()
  -- Ensure REAPER v7+
  if tonumber(string.match(reaper.GetAppVersion(), "(%d+).")) < 7 then
    acendan.msg("This script requires REAPER v7!", SCRIPT_NAME)
  end
  
  ctx = reaper.ImGui_CreateContext(SCRIPT_NAME, reaper.ImGui_ConfigFlags_DockingEnable())
  reaper.ImGui_SetNextWindowSize(ctx, WINDOW_SIZE.width, WINDOW_SIZE.height)
  
  wgt = {
    warning = "",
    enable_grouping = acendan.ImGui_GetSettingBool("mmm_grouping", true),
    enable_pan_env = acendan.ImGui_GetSettingBool("mmm_panning", false),
    single_lane = acendan.ImGui_GetSettingBool("mmm_single_lane", false)
  }
end

function main()
  local rv, open = reaper.ImGui_Begin(ctx, SCRIPT_NAME, true, WINDOW_FLAGS)
  if not rv then return open end
  
  acendan.ImGui_Button("Create Mic Lanes", createMicLanes, 0.42)
  acendan.ImGui_HelpMarker("Creates fixed item lanes for each mic in items on selected track.")
  
  acendan.ImGui_Button("Restore Multi Mic", restoreMultiMic, 0)
  acendan.ImGui_HelpMarker("Reverts changes, restoring original Multi Mic items on selected track.")
  
  acendan.ImGui_Button("Write Mic Metadata", writeMetadata, 0.71)
  acendan.ImGui_HelpMarker("EXPERIMENTAL\nUses BWF MetaEdit to write mic lane names to item metadata.")
  
  reaper.ImGui_TextColored(ctx, 0xFFFF00FF, wgt.warning)
  
  -- Options
  --   TODO: Explode onto tracks (V6 support) rather than lanes
  --   TODO: Route to original channels
  reaper.ImGui_Spacing(ctx)
  reaper.ImGui_Spacing(ctx)
  reaper.ImGui_SeparatorText(ctx, "Options")
  
  rv, wgt.enable_grouping = reaper.ImGui_Checkbox(ctx, "Enable Grouping", wgt.enable_grouping)
  if rv then acendan.ImGui_SetSettingBool("mmm_grouping", wgt.enable_grouping) end
  
  rv, wgt.enable_pan_env = reaper.ImGui_Checkbox(ctx, "Enable Pan Envelope", wgt.enable_pan_env)
  if rv then acendan.ImGui_SetSettingBool("mmm_panning", wgt.enable_pan_env) end
  
  rv, wgt.single_lane = reaper.ImGui_Checkbox(ctx, "Single Mic Lane", wgt.single_lane)
  if rv then acendan.ImGui_SetSettingBool("mmm_single_lane", wgt.single_lane) end
  
  reaper.ImGui_End(ctx)
  if open then reaper.defer(main) else reaper.ImGui_DestroyContext(ctx) end
end


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ UTILITIES ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function createMicLanes()
  local num_sel_tracks = reaper.CountSelectedTracks(0)
  if num_sel_tracks == 0 then
    wgt.warning = "No track selected!"
    return
  else
    wgt.warning = ""
  end
  local ini_sel_tracks = {}
  acendan.saveSelectedTracks(ini_sel_tracks)

  local ini_cur_pos = reaper.GetCursorPosition()
  local start_time, end_time = reaper.GetSet_ArrangeView2(0, false, 0, 0, 0, 0)
  
  for _, track in ipairs(ini_sel_tracks) do
    local ini_track_height = reaper.GetMediaTrackInfo_Value(track, "I_TCPH")
    reaper.SetOnlyTrackSelected(track)
    reaper.Main_OnCommand(42431, 0) -- Track properties: Set fixed item lanes
    reaper.Main_OnCommand(40289, 0) -- Unselect all media items
    reaper.Main_OnCommand(40421, 0) -- Item: Select all items in track
    
    local ini_sel_items = {}
    acendan.saveSelectedItems(ini_sel_items)
    
    for _, item in ipairs(ini_sel_items) do
      -- Save this batch of items for grouping later
      local items = {}
      items[#items + 1] = item
      
      local take = reaper.GetActiveTake( item )
      if take ~= nil then 
        
        local src = reaper.GetMediaItemTake_Source(take)
        local src_parent = reaper.GetMediaSourceParent(src)
        
        -- Get source num channels
        if src_parent ~= nil then
          src_chans = reaper.GetMediaSourceNumChannels( src_parent )
        else
          src_chans = reaper.GetMediaSourceNumChannels( src )
        end
        
        local lane_name_chunk = "LANENAME MultiMic"
        for chnl = 1, src_chans do
          -- Copy item to lane for channel
          acendan.setOnlyItemSelected(item)
          reaper.Main_OnCommand(41173, 0) -- Move cursor at item start
          reaper.Main_OnCommand(40698, 0) -- Copy the item
          reaper.Main_OnCommand(40914, 0) -- Set selected track as last touched
          reaper.Main_OnCommand(40058, 0) -- Paste item
          
          -- Set item lane and channel
          local new_item = reaper.GetSelectedMediaItem(0, 0)
          items[#items + 1] = new_item
          reaper.SetMediaItemInfo_Value(new_item, "I_FIXEDLANE", chnl)
          reaper.SetMediaItemTakeInfo_Value(reaper.GetActiveTake( new_item ) , "I_CHANMODE", 2 + chnl)
          
          if wgt.enable_pan_env then
            reaper.Main_OnCommand(reaper.NamedCommandLookup("_S&M_TAKEENVSHOW2"), 0) -- SWS/S&M: Show take pan envelope
          end 
          
          -- Rename lane from metadata
          local track_name_meta = chnl == 1 and "IXML:TRACK_LIST:TRACK:NAME" or "IXML:TRACK_LIST:TRACK:NAME:" .. tostring(chnl)
          local ret, lane_name = reaper.GetMediaFileMetadata(src, track_name_meta)
          lane_name_chunk = ret ~= 0 and (lane_name_chunk .. " " .. acendan.encapsulate(lane_name)) or (lane_name_chunk .. " Ch." .. tostring(chnl))
        end
        
        -- Set track lane names and height
        local _, track_chunk = reaper.GetTrackStateChunk(track, "", false)
        reaper.SetTrackStateChunk(track, track_chunk:gsub("(LANENAME.-)\n", lane_name_chunk .. "\n"), false)
        reaper.SetMediaTrackInfo_Value(track, "I_TCPH", ini_track_height / src_chans + 1)
        
        -- Set first mic track as selected lane
        reaper.SetMediaTrackInfo_Value(track, "C_LANEPLAYS:1", 1)
        if wgt.single_lane then
          reaper.Main_OnCommand(42638, 0) -- Track properties: Show/play only one fixed item lane
        end
        
        -- Mute original item
        reaper.SetMediaItemInfo_Value(item, "B_MUTE", 1)
        
        -- Group items
        if wgt.enable_grouping then
          acendan.restoreSelectedItems(items)
          reaper.Main_OnCommand(40032, 0) -- Item grouping: Group items
        end
      end
    end
    
    acendan.restoreSelectedItems(ini_sel_items)
  end
  
  reaper.SetEditCurPos(ini_cur_pos, false, false)
  reaper.GetSet_ArrangeView2(0, false, 0, 0, start_time, end_time)
end

function restoreMultiMic()
  if reaper.CountSelectedTracks(0) == 0 then
    wgt.warning = "No track selected!"
    return
  else
    wgt.warning = ""
  end
  local ini_sel_tracks = {}
  acendan.saveSelectedTracks(ini_sel_tracks)
  
  for _, track in ipairs(ini_sel_tracks) do
    reaper.SetOnlyTrackSelected(track)
    reaper.SetMediaTrackInfo_Value(track, "C_LANEPLAYS:0", 1)
    reaper.Main_OnCommand(42662, 0) -- Track properties: Unset free item positioning/fixed item lanes (convert fixed lanes to takes)
    reaper.Main_OnCommand(40289, 0) -- Unselect all media items
    reaper.Main_OnCommand(40421, 0) -- Item: Select all items in track
    reaper.Main_OnCommand(40131, 0) -- Take: Crop to active take in items
    reaper.Main_OnCommand(40720, 0) -- Item properties: Unmute
    reaper.Main_OnCommand(40033, 0) -- Item grouping: Remove items from group
    reaper.Main_OnCommand(reaper.NamedCommandLookup("_S&M_DELEMPTYTAKE"), 0) -- SWS/S&M: Takes - Remove empty takes/items among selected items
  end
end

function writeMetadata()
  wgt.warning = "Work in progress..."
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
init()
main()

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~ TESTING ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
