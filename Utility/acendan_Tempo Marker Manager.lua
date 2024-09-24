-- @description Tempo Marker Manager (ImGui)
-- @author Aaron Cendan
-- @version 2.3
-- @metapackage
-- @provides
--   [main] .
-- @link https://ko-fi.com/acendan_
-- @about
--   # Tempo Marker Manager, similar to tempo manager in Logic Pro
-- @changelog
--   # ImGui Style

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
if reaper.file_exists( acendan_LuaUtils ) then dofile( acendan_LuaUtils ); if not acendan or acendan.version() < 8.0 then acendan.msg('This script requires a newer version of ACendan Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"ACendan Lua Utilities"); return end else reaper.ShowConsoleMsg("This script requires ACendan Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'ACendan Lua Utilities'"); return end

-- Prefix for saved tempo map extstates
local tempo_map_prefix = "acendan_TempoMap"

-- Count num of saved tempo maps
local function CountTempoMaps()
  local i = 0
  while reaper.EnumProjExtState(0, tempo_map_prefix .. i, 0) do
    i = i + 1
  end
  return i
end
local tempo_map_count = CountTempoMaps()

-- Separator for tempo map serialization
local sep = "||"

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function init()
  -- Confirm user has ImGui installed
  if not reaper.ImGui_Key_0() then acendan.msg("This script requires the ReaImGui API, which can be installed from:\n\nExtensions > ReaPack > Browse packages...") return end
    
  ctx = reaper.ImGui_CreateContext(script_name, reaper.ImGui_ConfigFlags_DockingEnable())
  
  window_flags = reaper.ImGui_WindowFlags_None()
  window_flags = window_flags | reaper.ImGui_WindowFlags_NoCollapse()
  window_flags = window_flags | reaper.ImGui_WindowFlags_MenuBar() 
  window_size = { width = 600, height = 520 }
  reaper.ImGui_SetNextWindowSize(ctx, window_size.width, window_size.height)
   
  -- ReaImGui_Demo
  -- Using those as a base value to create width/height that are factor of the size of our font
  TEXT_BASE_WIDTH  = reaper.ImGui_CalcTextSize(ctx, 'A')
  TEXT_BASE_HEIGHT = reaper.ImGui_GetTextLineHeightWithSpacing(ctx)
  FLT_MIN, FLT_MAX = reaper.ImGui_NumericLimits_Float()
  tables  = {}
  
  local timesig_num, timesig_denom, _ = reaper.TimeMap_GetTimeSigAtTime(0, 0)
  add_mkr = {
      id = 0,
      bpm = 120.0,
      tsig = acendan.TimeSig_ToString(timesig_num, timesig_denom),
      tpos = reaper.format_timestr(0.0,""), 
      mpos = 1,
      bpos = 1.0,
      lin = false
    }
  
  clipper = reaper.ImGui_CreateListClipper(ctx)

  main()
end

function main()
  acendan.ImGui_PushStyles()
  local rv, open = reaper.ImGui_Begin(ctx, script_name, true, window_flags)
  if not rv then return open end
  
  -- Set table properties (from ReaImGui Demo)
  if not tables.advanced then
    tables.advanced = {
      items = {},
      flags = reaper.ImGui_TableFlags_Resizable()       |
              --reaper.ImGui_TableFlags_Reorderable()     |
              reaper.ImGui_TableFlags_Hideable()        |
              reaper.ImGui_TableFlags_Sortable()        |
              reaper.ImGui_TableFlags_SortMulti()       |
              reaper.ImGui_TableFlags_RowBg()           |
              reaper.ImGui_TableFlags_Borders()         |
              -- reaper.ImGui_TableFlags_NoBordersInBody() |
              reaper.ImGui_TableFlags_ScrollX()         |
              reaper.ImGui_TableFlags_ScrollY()         |
              reaper.ImGui_TableFlags_SizingFixedFit(),

      freeze_cols             = 1,
      freeze_rows             = 1,
      row_min_height          = 0.0, -- Auto
      inner_width_with_scroll = 0.0, -- Auto-extend
      outer_size_enabled      = true,
      show_headers            = true,
      show_wrapped_text       = false,
      items_need_sort         = false,
    }
  end
  
  -- Update table size every loop
  tables.advanced.outer_size_value        = { 0.0, reaper.ImGui_GetWindowHeight(ctx) - 140 } --{ 0.0, TEXT_BASE_HEIGHT * 12 },
  
  -- Update time sel and region info every loop
  local start_time_sel, end_time_sel = reaper.GetSet_LoopTimeRange(0,0,0,0,0)
  local _, num_markers, num_regions = reaper.CountProjectMarkers( 0 )
  local num_total = num_markers + num_regions
  
  -- Update item list every loop
  tables.advanced.items_count = reaper.CountTempoTimeSigMarkers(0)
  tables.advanced.items = {}
  for n = 0, tables.advanced.items_count - 1 do
    local retval, timepos, measurepos, beatpos, bpm, timesig_num, timesig_denom, lineartempo = reaper.GetTempoTimeSigMarker( 0, n )
    
    -- Get time sig from position if not set
    if timesig_num < 0 and timesig_denom < 0 then
      timesig_num, timesig_denom, _ = reaper.TimeMap_GetTimeSigAtTime(0, timepos)
    end
    
    -- Prep item to add
    local item = {
      id = n + 1,
      bpm = math.floor(bpm*100)/100,
      tsig = acendan.TimeSig_ToString(timesig_num, timesig_denom),
      tpos = reaper.format_timestr(timepos,""), 
      mpos = round(measurepos) + 1,
      bpos = math.max(math.floor(beatpos*100)/100,0.0) + 1,
      lin = lineartempo,
      rgn = 0,
      rgn_name = "",
      rgn_col = 0,
      rgn_idx = 0,
      tsel = start_time_sel < timepos and timepos < end_time_sel
    }
    
    -- Get overlapping region
    if num_regions > 0 then
      -- Loop through all regions
      local i = 0
      while i < num_total do
        local _, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, i )
        if isrgn and timepos >= pos and timepos <= rgnend then
          item.rgn_idx = i
          item.rgn = markrgnindexnumber
          item.rgn_name = name
          item.rgn_col = reaper.ImGui_ColorConvertNative(color)
          break
        end
        i = i + 1
      end
    end
    
    table.insert(tables.advanced.items, item)
  end
  
  -- Menu bar
  reaper.ImGui_PushItemWidth(ctx, reaper.ImGui_GetFontSize(ctx) * -12)
  if reaper.ImGui_BeginMenuBar(ctx) then
    if reaper.ImGui_BeginMenu(ctx, 'Options') then
      tempo_map_count = CountTempoMaps()
      
      -- Save tempo map
      if reaper.ImGui_MenuItem(ctx, 'Save Project Tempo Map') then
        SaveTempoMap(tables.advanced.items)
      end
      reaper.ImGui_Separator(ctx)

      if tempo_map_count > 0 then
        -- Load tempo map
        if reaper.ImGui_BeginMenu(ctx, 'Load Project Tempo Map') then
          for i = 1, tempo_map_count do
            if reaper.ImGui_MenuItem(ctx, 'Load #' .. i) then
              LoadTempoMap(i - 1)
            end
          end
          reaper.ImGui_EndMenu(ctx)
        end
        
        -- Delete tempo map
        if reaper.ImGui_BeginMenu(ctx, 'Delete Project Tempo Map') then
          for i = 1, tempo_map_count do
            if reaper.ImGui_MenuItem(ctx, 'Delete #' .. i) then
              DeleteTempoMap(i - 1)
            end
          end
          reaper.ImGui_EndMenu(ctx)
        end
      else
        -- Greyed out options
        reaper.ImGui_MenuItem(ctx, 'Load Tempo Map', nil, false, false)
        reaper.ImGui_MenuItem(ctx, 'Delete Tempo Map', nil, false, false)
      end

      reaper.ImGui_EndMenu(ctx)
    end
    reaper.ImGui_EndMenuBar(ctx)
  end

  -- Submit table
  local inner_width_to_use = (tables.advanced.flags & reaper.ImGui_TableFlags_ScrollX()) ~= 0 and tables.advanced.inner_width_with_scroll or 0.0
  local w, h = 0, 0
  if tables.advanced.outer_size_enabled then
    w, h = table.unpack(tables.advanced.outer_size_value)
  end
  if reaper.ImGui_BeginTable(ctx, 'table_advanced', #colKeys, tables.advanced.flags, w, h, inner_width_to_use) then
    -- Declare columns
    -- We use the "user_id" parameter of TableSetupColumn() to specify a user id that will be stored in the sort specifications.
    -- This is so our sort function can identify a column given our own identifiereaper. We could also identify them based on their index!
    reaper.ImGui_TableSetupColumn(ctx, 'ID',      reaper.ImGui_TableColumnFlags_DefaultSort() | reaper.ImGui_TableColumnFlags_WidthFixed() | reaper.ImGui_TableColumnFlags_NoHide(), 0.0, colID_ID)
    reaper.ImGui_TableSetupColumn(ctx, 'BPM',     reaper.ImGui_TableColumnFlags_WidthFixed(), 0.0, colID_BPM)
    reaper.ImGui_TableSetupColumn(ctx, 'Sig.',    reaper.ImGui_TableColumnFlags_WidthFixed(), 0.0, colID_TSig)
    reaper.ImGui_TableSetupColumn(ctx, 'Time',    reaper.ImGui_TableColumnFlags_WidthStretch(), 0.0, colID_Time)
    reaper.ImGui_TableSetupColumn(ctx, 'Measure', reaper.ImGui_TableColumnFlags_WidthFixed(), 0.0, colID_Measure)
    reaper.ImGui_TableSetupColumn(ctx, 'Beat',    reaper.ImGui_TableColumnFlags_WidthFixed(), 0.0, colID_Beat)
    reaper.ImGui_TableSetupColumn(ctx, 'Linear',  reaper.ImGui_TableColumnFlags_WidthFixed(), 0.0, colID_Linear)
    reaper.ImGui_TableSetupColumn(ctx, 'Region',  reaper.ImGui_TableColumnFlags_WidthFixed(), 0.0, colID_Region)
    reaper.ImGui_TableSetupScrollFreeze(ctx, tables.advanced.freeze_cols, tables.advanced.freeze_rows)

    -- Sort our data
    table.sort(tables.advanced.items, CompareTableItems)

    -- Show headers
    if tables.advanced.show_headers then
      reaper.ImGui_TableHeadersRow(ctx)
    end

    -- Show data
    reaper.ImGui_PushButtonRepeat(ctx, true)

    -- Demonstrate using clipper for large vertical lists
    reaper.ImGui_ListClipper_Begin(clipper, #tables.advanced.items)
    while reaper.ImGui_ListClipper_Step(clipper) do
      local display_start, display_end = reaper.ImGui_ListClipper_GetDisplayRange(clipper)
      for row_n = display_start, display_end - 1 do
        local item = tables.advanced.items[row_n + 1]

        reaper.ImGui_PushID(ctx, item.id)
        reaper.ImGui_TableNextRow(ctx, reaper.ImGui_TableRowFlags_None(), tables.advanced.row_min_height)

        -- ID
        reaper.ImGui_TableSetColumnIndex(ctx, colID_ID - 1)
        local label = ('%03d'):format(item.id)
        if item.tsel then
          reaper.ImGui_TextColored(ctx, 0xE8EC9BFF, label)
        else
          reaper.ImGui_Text(ctx, label)
        end
        
        -- BPM
        if reaper.ImGui_TableSetColumnIndex(ctx, colID_BPM - 1) then
          reaper.ImGui_SetNextItemWidth( ctx, -FLT_MIN )
          local retval, buf = reaper.ImGui_InputText( ctx, "###bpm" .. tostring(row_n), item.bpm, reaper.ImGui_InputTextFlags_AllowTabInput() )
          if retval and tonumber(buf) then
            if tonumber(buf) > 0 then
              item.bpm = tonumber(buf)
              SetTempoMarker_Time(item)
            end
          end
        end
        
        -- Time Signature
        if reaper.ImGui_TableSetColumnIndex(ctx, colID_TSig - 1) then
          if item.id == 1 then
            reaper.ImGui_Text(ctx, item.tsig)
          else
            reaper.ImGui_SetNextItemWidth( ctx, -FLT_MIN )
            local retval, buf = reaper.ImGui_InputText( ctx, "###tsig" .. tostring(row_n), item.tsig, reaper.ImGui_InputTextFlags_AllowTabInput() )
            local num, denom = acendan.TimeSig_FromString(buf)
            if retval and num and denom then
              item.tsig = buf
              SetTempoMarker_MeasBeat(item)
            end
          end
        end
        
        -- Time
        if reaper.ImGui_TableSetColumnIndex(ctx, colID_Time - 1) then
          if item.id == 1 then
            reaper.ImGui_Text(ctx, item.tpos)
          else
            reaper.ImGui_SetNextItemWidth( ctx, -FLT_MIN )
            local retval, buf = reaper.ImGui_InputText( ctx, "###tpos" .. tostring(row_n), item.tpos, reaper.ImGui_InputTextFlags_AllowTabInput() )
            if retval then
              if reaper.parse_timestr(buf) > 0 then
                item.tpos = buf
                SetTempoMarker_Time(item)
              end
            end
          end
        end
        
        -- Measure
        if reaper.ImGui_TableSetColumnIndex(ctx, colID_Measure - 1) then
          if item.id == 1 then
            reaper.ImGui_Text(ctx, item.mpos)
          else
            reaper.ImGui_SetNextItemWidth( ctx, -FLT_MIN )
            local retval, buf = reaper.ImGui_InputText( ctx, "###mpos" .. tostring(row_n), item.mpos, reaper.ImGui_InputTextFlags_AllowTabInput() )
            if retval and tonumber(buf) then
              item.mpos = tonumber(buf)
              SetTempoMarker_MeasBeat(item)
            end
          end
        end

        -- Beat
        -- Must be clamped to time signature numerator
        if reaper.ImGui_TableSetColumnIndex(ctx, colID_Beat - 1) then
          if item.id == 1 then
            reaper.ImGui_Text(ctx, item.bpos)
          else
            reaper.ImGui_SetNextItemWidth( ctx, -FLT_MIN )
            local retval, buf = reaper.ImGui_InputText( ctx, "###bpos" .. tostring(row_n), item.bpos, reaper.ImGui_InputTextFlags_AllowTabInput())
            if retval and tonumber(buf) then
              local num, _ = reaper.TimeMap_GetTimeSigAtTime(0, reaper.parse_timestr(item.tpos))
              item.bpos = clamp(tonumber(buf), 1.0, num + 0.99)
              SetTempoMarker_MeasBeat(item)
            end
          end
        end
        
        -- Linear/Ramp
        if reaper.ImGui_TableSetColumnIndex(ctx, colID_Linear - 1) then
          local retval, v = reaper.ImGui_Checkbox( ctx, "###lin" .. tostring(row_n), item.lin )
          if retval then
            item.lin = v
            SetTempoMarker_Time(item)
          end
        end
        
        -- Region
        if reaper.ImGui_TableSetColumnIndex(ctx, colID_Region - 1) and item.rgn > 0 then
          -- Color picker
          local retval, imgui_col = reaper.ImGui_ColorEdit4(ctx, '##color', item.rgn_col, reaper.ImGui_ColorEditFlags_NoInputs() | reaper.ImGui_ColorEditFlags_NoAlpha())
          if retval and  reaper.ImGui_IsMouseDown(ctx, reaper.ImGui_MouseButton_Left()) then
            local native_col = reaper.ImGui_ColorConvertNative(imgui_col)|0x1000000
            local _, _, pos, rgnend, _, _, _ = reaper.EnumProjectMarkers3( 0, item.rgn_idx )
            reaper.SetProjectMarker3(0, item.rgn, true, pos, rgnend, item.rgn_name, native_col)
            reaper.UpdateTimeline()
          end
          
          reaper.ImGui_SameLine(ctx)
          reaper.ImGui_Text(ctx, tostring(item.rgn) .. ": " .. item.rgn_name)
        end

        reaper.ImGui_PopID(ctx)
      end
    end
    reaper.ImGui_PopButtonRepeat(ctx)

    reaper.ImGui_EndTable(ctx)
  end
  
  -- Add tempo marker section
  reaper.ImGui_Dummy(ctx, w, 10)
  reaper.ImGui_Text(ctx, "Add Tempo Marker")
  HelpMarker("Set 'Time' OR 'Measure & Beat', then click the + button!")
  
  -- Get edit cursor position button
  reaper.ImGui_SameLine(ctx, reaper.ImGui_GetWindowWidth(ctx) - 140)
  if reaper.ImGui_Button(ctx, 'Time @ Edit Cursor', -FLT_MIN, 0.0) then
    add_mkr.tpos = reaper.format_timestr(reaper.GetCursorPosition(),"")
  end
  
  if reaper.ImGui_BeginTable(ctx, 'add_marker_tbl', #colKeys, tables.advanced.flags & ~reaper.ImGui_TableFlags_Sortable(), w, 50, inner_width_to_use) then
      -- Declare columns
      -- We use the "user_id" parameter of TableSetupColumn() to specify a user id that will be stored in the sort specifications.
      -- This is so our sort function can identify a column given our own identifiereaper. We could also identify them based on their index!
      reaper.ImGui_TableSetupColumn(ctx, 'Add',      reaper.ImGui_TableColumnFlags_DefaultSort() | reaper.ImGui_TableColumnFlags_WidthFixed() | reaper.ImGui_TableColumnFlags_NoHide(), 0.0, colID_ID)
      reaper.ImGui_TableSetupColumn(ctx, 'BPM',     reaper.ImGui_TableColumnFlags_WidthFixed(), 0.0, colID_BPM)
      reaper.ImGui_TableSetupColumn(ctx, 'Sig.',    reaper.ImGui_TableColumnFlags_WidthFixed(), 0.0, colID_TSig)
      reaper.ImGui_TableSetupColumn(ctx, 'Time',    reaper.ImGui_TableColumnFlags_WidthStretch(), 0.0, colID_Time)
      reaper.ImGui_TableSetupColumn(ctx, 'Measure', reaper.ImGui_TableColumnFlags_WidthFixed(), 0.0, colID_Measure)
      reaper.ImGui_TableSetupColumn(ctx, 'Beat',    reaper.ImGui_TableColumnFlags_WidthFixed(), 0.0, colID_Beat)
      reaper.ImGui_TableSetupColumn(ctx, 'Linear',  reaper.ImGui_TableColumnFlags_WidthFixed(), 0.0, colID_Linear)
      reaper.ImGui_TableSetupScrollFreeze(ctx, tables.advanced.freeze_cols, tables.advanced.freeze_rows)
  
      -- Show headers
      if tables.advanced.show_headers then
        reaper.ImGui_TableHeadersRow(ctx)
      end
  
      -- Show data
      reaper.ImGui_PushButtonRepeat(ctx, true)

      reaper.ImGui_PushID(ctx, 'add_marker_rows')
      reaper.ImGui_TableNextRow(ctx, reaper.ImGui_TableRowFlags_None(), tables.advanced.row_min_height)

      -- Add tempo marker button
      reaper.ImGui_TableSetColumnIndex(ctx, colID_ID - 1)
      if reaper.ImGui_Button(ctx, '+', -FLT_MIN, 0.0) then
        local timepos =  reaper.parse_timestr(add_mkr.tpos)
        if timepos > 0 then
          SetTempoMarker_Time(add_mkr)
        else
          SetTempoMarker_MeasBeat(add_mkr)
        end
      end

      -- BPM
      if reaper.ImGui_TableSetColumnIndex(ctx, colID_BPM - 1) then
        reaper.ImGui_SetNextItemWidth( ctx, -FLT_MIN )
        local retval, buf = reaper.ImGui_InputText( ctx, "###addbpm", add_mkr.bpm, reaper.ImGui_InputTextFlags_AllowTabInput() )
        if retval and tonumber(buf) then
          if tonumber(buf) > 0 then
            add_mkr.bpm = tonumber(buf)
          end
        end
      end
      
      -- Time Signature
      if reaper.ImGui_TableSetColumnIndex(ctx, colID_TSig - 1) then
        reaper.ImGui_SetNextItemWidth( ctx, -FLT_MIN )
        local retval, buf = reaper.ImGui_InputText( ctx, "###addtsig" .. tostring(row_n), add_mkr.tsig, reaper.ImGui_InputTextFlags_AllowTabInput() )
        if retval then
          local num, denom = acendan.TimeSig_FromString(buf)
          if num and denom then
            add_mkr.tsig = buf
          else
            num, denom , _ = reaper.TimeMap_GetTimeSigAtTime(0, reaper.parse_timestr(add_mkr.tpos))
            add_mkr.tsig = acendan.TimeSig_ToString(num,denom)
          end
        end
      end
      
      -- Time
      if reaper.ImGui_TableSetColumnIndex(ctx, colID_Time - 1) then
        reaper.ImGui_SetNextItemWidth( ctx, -FLT_MIN )
        local retval, buf = reaper.ImGui_InputText( ctx, "###addtpos", add_mkr.tpos, reaper.ImGui_InputTextFlags_AllowTabInput() )
        if retval then
          if reaper.parse_timestr(buf) > 0 or buf:match("0+%:*0+%.*0+") then
            add_mkr.tpos = buf
          end
        end
      end
      
      -- Measure
      if reaper.ImGui_TableSetColumnIndex(ctx, colID_Measure - 1) then
        reaper.ImGui_SetNextItemWidth( ctx, -FLT_MIN )
        local retval, buf = reaper.ImGui_InputText( ctx, "###addmpos", add_mkr.mpos, reaper.ImGui_InputTextFlags_AllowTabInput() )
        if retval and tonumber(buf) then
          add_mkr.mpos = tonumber(buf)
        end
      end

      -- Beat
      -- Must be clamped to time signature numerator
      if reaper.ImGui_TableSetColumnIndex(ctx, colID_Beat - 1) then
        reaper.ImGui_SetNextItemWidth( ctx, -FLT_MIN )
        local retval, buf = reaper.ImGui_InputText( ctx, "###addbpos", add_mkr.bpos, reaper.ImGui_InputTextFlags_AllowTabInput())
        if retval and tonumber(buf) then
          local num, _ = reaper.TimeMap_GetTimeSigAtTime(0, reaper.parse_timestr(add_mkr.tpos))
          add_mkr.bpos = clamp(tonumber(buf), 1.0, num + 0.99)
        end
      end
      
      -- Linear/Ramp
      if reaper.ImGui_TableSetColumnIndex(ctx, colID_Linear - 1) then
        local retval, v = reaper.ImGui_Checkbox( ctx, "###addlin", add_mkr.lin )
        if retval then
          add_mkr.lin = v
        end
      end

      reaper.ImGui_PopID(ctx)

      
      reaper.ImGui_PopButtonRepeat(ctx)
  
      reaper.ImGui_EndTable(ctx)
    end
  

  reaper.ImGui_End(ctx)
  acendan.ImGui_PopStyles()
  if open then reaper.defer(main) else return end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ UTILITIES ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

colID_ID          = 1
colID_BPM         = 2
colID_TSig        = 3
colID_Time        = 4
colID_Measure     = 5
colID_Beat        = 6
colID_Linear      = 7
colID_Region      = 8

colKeys = { 'id', 'bpm', 'tsig', 'tpos', 'mpos', 'bpos', 'lin', 'rgn'}

function CompareTableItems(a, b)
  local next_id = 0
  while true do
    local ok, col_user_id, col_idx, sort_order, sort_direction = reaper.ImGui_TableGetColumnSortSpecs(ctx, next_id)
    if not ok then break end
    next_id = next_id + 1

    -- Fetch key from colKeys
    local key = colKeys[col_user_id]
    
    -- Fetch sort direction
    local is_ascending = sort_direction == reaper.ImGui_SortDirection_Ascending()
    
    -- Parse timepos val from string
    local aval, bval
    if key == 'tpos' then
      aval = reaper.parse_timestr(a[key])
      bval = reaper.parse_timestr(b[key])
    elseif key == 'lin' then
      aval = a[key] and 0 or 1
      bval = b[key] and 0 or 1
    elseif key == 'tsig' then
      aval = acendan.TimeSig_ToArbitraryNumber(a[key])
      bval = acendan.TimeSig_ToArbitraryNumber(b[key])
    else
      aval = a[key]
      bval = b[key]
    end
    
    -- Comparison
    if aval and bval then
      if aval < bval then
        return is_ascending
      elseif aval > bval then
        return not is_ascending
      end
    end
  end

  -- table.sort is instable so always return a way to differenciate items.
  -- Your own compare function may want to avoid fallback on implicit sort specs e.g. a Name compare if it wasn't already part of the sort specs.
  return a.id < b.id
end

function SetTempoMarker_Time(item)
  if reaper.ImGui_IsItemDeactivatedAfterEdit(ctx) or item.id == 0 then
    reaper.Undo_BeginBlock()
    local num, denom = acendan.TimeSig_FromString(item.tsig)
    if num and denom then
      reaper.SetTempoTimeSigMarker( 0, item.id - 1, reaper.parse_timestr(item.tpos), -1, -1, item.bpm, num, denom, item.lin)
    else
      reaper.SetTempoTimeSigMarker( 0, item.id - 1, reaper.parse_timestr(item.tpos), -1, -1, item.bpm, 0, 0, item.lin)
    end
    reaper.UpdateTimeline() 
    reaper.Undo_EndBlock(script_name,-1)
  end
end

function SetTempoMarker_MeasBeat(item)
  if reaper.ImGui_IsItemDeactivatedAfterEdit(ctx) or item.id == 0 then
    reaper.Undo_BeginBlock()
    local num, denom = acendan.TimeSig_FromString(item.tsig)
        if num and denom then
          reaper.SetTempoTimeSigMarker( 0, item.id - 1, -1, item.mpos - 1, item.bpos - 1, item.bpm, num, denom, item.lin)
        else
          reaper.SetTempoTimeSigMarker( 0, item.id - 1, -1, item.mpos - 1, item.bpos - 1, item.bpm, 0, 0, item.lin)
        end
    reaper.UpdateTimeline() 
    reaper.Undo_EndBlock(script_name,-1)
  end
end

-- Save all of the current tempo markers to projextstate
function SaveTempoMap(items)
  local extstate = tempo_map_prefix .. tempo_map_count
  for _, item in pairs(items) do
    reaper.SetProjExtState(0, extstate, tostring(item.id), SerializeItem(item))
  end
  reaper.Main_SaveProject(0,false)
  
  tempo_map_count = CountTempoMaps()
end

-- Save all of the current tempo markers to projextstate
function LoadTempoMap(index)
  reaper.PreventUIRefresh(1)
  
  -- Delete all current markers
  DeleteAllTempoMarkers()

  -- Load markers from ProjExtState
  local extstate = tempo_map_prefix .. index
  local i = 0
  while reaper.EnumProjExtState(0, extstate, i) do
    i = i + 1
    
    local ret, extitem = reaper.GetProjExtState(0, extstate, i)
    if ret and extitem then
      local item = {}
      item.id = 0 -- Add new marker at end
      item.bpm, item.tsig, item.tpos, item.lin = DeserializeItem(extitem)
      item.lin = item.lin == "true" and true or false
      SetTempoMarker_Time(item)
    end
  end
  
  reaper.PreventUIRefresh(-1)
end

-- Delete one of the saved tempo maps
function DeleteTempoMap(index)
  -- Delete the target ext state
  local extstate = tempo_map_prefix .. index
  reaper.SetProjExtState(0, extstate, "", "")

  -- Move all of the ext states after it that are empty
  for i = 0, tempo_map_count - 1 do
    if not reaper.EnumProjExtState(0, tempo_map_prefix .. i, 0) then
      MoveTempoMapExtState(i + 1, i)
    end
    i = i + 1
  end

  reaper.Main_SaveProject(0,false)
end

-- Move tempo map ext state from one index to another
function MoveTempoMapExtState(start_idx, end_idx)
  local start_extstate = tempo_map_prefix .. start_idx
  local end_extstate = tempo_map_prefix .. end_idx
  
  -- Copy from start_idx to end_idx
  local i = 0
  while reaper.EnumProjExtState(0, start_extstate, i) do
    i = i + 1
    
    local ret, extitem = reaper.GetProjExtState(0, start_extstate, i)
    if ret and extitem then
      reaper.SetProjExtState(0, end_extstate, tostring(i), extitem)
    end
  end
  
  -- Delete start_idx
  reaper.SetProjExtState(0, start_extstate, "", "")
  
  reaper.Main_SaveProject(0,false)
end

function DeleteAllTempoMarkers()
  local num_markers = reaper.CountTempoTimeSigMarkers(0)
  for i = 0, num_markers do
    reaper.DeleteTempoTimeSigMarker(0, num_markers - i)
    i = i + 1
  end
end

-- returns bpm || tsig || tpos || lin
function SerializeItem(item)
  return tostring(item.bpm) .. sep .. tostring(item.tsig) .. sep .. tostring(item.tpos) .. sep .. tostring(item.lin)
end

-- returns bpm, tsig, tpos, lin
function DeserializeItem(item)
  return acendan.stringSplit(item, sep, 4)
end

function round(n)
  return math.floor(n + .5)
end

function clamp(v, mn, mx)
  if v < mn then return mn end
  if v > mx then return mx end
  return v
end

function HelpMarker(desc)
  reaper.ImGui_SameLine(ctx)
  reaper.ImGui_TextDisabled(ctx, '(?)')
  if reaper.ImGui_IsItemHovered(ctx) then
    reaper.ImGui_BeginTooltip(ctx)
    reaper.ImGui_PushTextWrapPos(ctx, reaper.ImGui_GetFontSize(ctx) * 35.0)
    reaper.ImGui_Text(ctx, desc)
    reaper.ImGui_PopTextWrapPos(ctx)
    reaper.ImGui_EndTooltip(ctx)
  end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
init()
