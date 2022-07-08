-- @description Tempo Marker Manager (ImGui)
-- @author Aaron Cendan
-- @version 1.6
-- @metapackage
-- @provides
--   [main] .
-- @link https://ko-fi.com/acendan_
-- @about
--   # Tempo Marker Manager, similar to tempo manager in Logic Pro
-- @changelog
--   # Update timeline when adding tempo markers

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
acendan_LuaUtils = reaper.GetResourcePath()..'/scripts/ACendan Scripts/Development/acendan_Lua Utilities.lua'
if reaper.file_exists( acendan_LuaUtils ) then dofile( acendan_LuaUtils ); if not acendan or acendan.version() < 6.2 then acendan.msg('This script requires a newer version of ACendan Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"ACendan Lua Utilities"); return end else reaper.ShowConsoleMsg("This script requires ACendan Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'ACendan Lua Utilities'"); return end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function init()
  -- Confirm user has ImGui installed
  if not reaper.ImGui_Key_0() then acendan.msg("This script requires the ReaImGui API, which can be installed from:\n\nExtensions > ReaPack > Browse packages...") return end
    
  ctx = reaper.ImGui_CreateContext(script_name, reaper.ImGui_ConfigFlags_DockingEnable())
  
  window_flags = reaper.ImGui_WindowFlags_None()
  window_flags = window_flags | reaper.ImGui_WindowFlags_NoCollapse()
  window_size = { width = 450, height = 420 }
  reaper.ImGui_SetNextWindowSize(ctx, window_size.width, window_size.height)
   
  -- ReaImGui_Demo
  -- Using those as a base value to create width/height that are factor of the size of our font
  TEXT_BASE_WIDTH  = reaper.ImGui_CalcTextSize(ctx, 'A')
  TEXT_BASE_HEIGHT = reaper.ImGui_GetTextLineHeightWithSpacing(ctx)
  FLT_MIN, FLT_MAX = reaper.ImGui_NumericLimits_Float()
  tables  = {}
  
  add_mkr = {
      id = 0,
      bpm = 120.0,
      tpos = reaper.format_timestr(0.0,""), 
      mpos = 1,
      bpos = 1.0,
      lin = false
    }
  
  main()
end

function main()
  local rv, open = reaper.ImGui_Begin(ctx, script_name, true, window_flags)
  if not rv then return open end
  
  -- Set table properties (from ReaImGui Demo)
  if not tables.advanced then
    tables.advanced = {
      items = {},
      flags = reaper.ImGui_TableFlags_Resizable()       |
              reaper.ImGui_TableFlags_Reorderable()     |
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
  tables.advanced.outer_size_value        = { 0.0, reaper.ImGui_GetWindowHeight(ctx) - 120 } --{ 0.0, TEXT_BASE_HEIGHT * 12 },
  
  -- Update item list every loop
  local start_time_sel, end_time_sel = reaper.GetSet_LoopTimeRange(0,0,0,0,0);
  tables.advanced.items_count = reaper.CountTempoTimeSigMarkers(0)
  tables.advanced.items = {}
  for n = 0, tables.advanced.items_count - 1 do
    local retval, timepos, measurepos, beatpos, bpm, timesig_num, timesig_denom, lineartempo = reaper.GetTempoTimeSigMarker( 0, n )
    local item = {
      id = n + 1,
      bpm = math.floor(bpm*100)/100,
      tpos = reaper.format_timestr(timepos,""), 
      mpos = round(measurepos) + 1,
      bpos = math.max(math.floor(beatpos*100)/100,0.0) + 1,
      lin = lineartempo,
      tsel = start_time_sel < timepos and timepos < end_time_sel
    }
    table.insert(tables.advanced.items, item)
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
    reaper.ImGui_TableSetupColumn(ctx, 'BPM',     reaper.ImGui_TableColumnFlags_WidthStretch(), 0.0, colID_BPM)
    reaper.ImGui_TableSetupColumn(ctx, 'Time',    reaper.ImGui_TableColumnFlags_WidthStretch(), 0.0, colID_Time)
    reaper.ImGui_TableSetupColumn(ctx, 'Measure', reaper.ImGui_TableColumnFlags_WidthFixed(), 0.0, colID_Measure)
    reaper.ImGui_TableSetupColumn(ctx, 'Beat',    reaper.ImGui_TableColumnFlags_WidthFixed(), 0.0, colID_Beat)
    reaper.ImGui_TableSetupColumn(ctx, 'Linear',  reaper.ImGui_TableColumnFlags_WidthFixed(), 0.0, colID_Linear)
    reaper.ImGui_TableSetupScrollFreeze(ctx, tables.advanced.freeze_cols, tables.advanced.freeze_rows)

    -- Sort our data if sort specs have been changed!
    local specs_dirty, has_specs = reaper.ImGui_TableNeedSort(ctx)
    if has_specs and (specs_dirty or tables.advanced.items_need_sort) then
      table.sort(tables.advanced.items, CompareTableItems)
      tables.advanced.items_need_sort = false
    end

    -- Take note of whether we are currently sorting based on the Quantity field,
    -- we will use this to trigger sorting when we know the data of this column has been modified.
    local sorts_specs_using_quantity = (reaper.ImGui_TableGetColumnFlags(ctx, 3) & reaper.ImGui_TableColumnFlags_IsSorted()) ~= 0

    -- Show headers
    if tables.advanced.show_headers then
      reaper.ImGui_TableHeadersRow(ctx)
    end

    -- Show data
    reaper.ImGui_PushButtonRepeat(ctx, true)

    -- Demonstrate using clipper for large vertical lists
    local clipper = reaper.ImGui_CreateListClipper(ctx)
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
  
  if reaper.ImGui_BeginTable(ctx, 'add_marker_tbl', #colKeys, tables.advanced.flags & ~reaper.ImGui_TableFlags_Sortable(), w, 40, inner_width_to_use) then
      -- Declare columns
      -- We use the "user_id" parameter of TableSetupColumn() to specify a user id that will be stored in the sort specifications.
      -- This is so our sort function can identify a column given our own identifiereaper. We could also identify them based on their index!
      reaper.ImGui_TableSetupColumn(ctx, 'Add',      reaper.ImGui_TableColumnFlags_DefaultSort() | reaper.ImGui_TableColumnFlags_WidthFixed() | reaper.ImGui_TableColumnFlags_NoHide(), 0.0, colID_ID)
      reaper.ImGui_TableSetupColumn(ctx, 'BPM',     reaper.ImGui_TableColumnFlags_WidthStretch(), 0.0, colID_BPM)
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
  if open then reaper.defer(main) else reaper.ImGui_DestroyContext(ctx) end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ UTILITIES ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

colID_ID          = 1
colID_BPM         = 2
colID_Time        = 3
colID_Measure     = 4
colID_Beat        = 5
colID_Linear      = 6

colKeys = { 'id', 'bpm', 'tpos', 'mpos', 'bpos', 'lin'}

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
    reaper.SetTempoTimeSigMarker( 0, item.id - 1, reaper.parse_timestr(item.tpos), -1, -1, item.bpm, 0, 0, item.lin)
    reaper.UpdateTimeline() 
    reaper.Undo_EndBlock(script_name,-1)
  end
end

function SetTempoMarker_MeasBeat(item)
  if reaper.ImGui_IsItemDeactivatedAfterEdit(ctx) or item.id == 0 then
    reaper.Undo_BeginBlock()
    reaper.SetTempoTimeSigMarker( 0, item.id - 1, -1, item.mpos - 1, item.bpos - 1, item.bpm, 0, 0, item.lin)
    reaper.UpdateTimeline() 
    reaper.Undo_EndBlock(script_name,-1)
  end
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
