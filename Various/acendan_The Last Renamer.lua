-- @description The Last Renamer
-- @author Aaron Cendan
-- @version 0.4
-- @metapackage
-- @provides
--   [main] .
--   Schemes/*.{yaml}
-- @link https://ko-fi.com/acendan_
-- @about
--   # The Last Renamer
-- @changelog
--   # Load empty window if active scheme fails to load

local acendan_LuaUtils = reaper.GetResourcePath() .. '/Scripts/ACendan Scripts/Development/acendan_Lua Utilities.lua'
if reaper.file_exists(acendan_LuaUtils) then
  dofile(acendan_LuaUtils); if not acendan or acendan.version() < 8.1 then
    acendan.msg(
      'This script requires a newer version of ACendan Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',
      "ACendan Lua Utilities"); return
  end
else
  reaper.ShowConsoleMsg(
    "This script requires ACendan Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'ACendan Lua Utilities'"); return
end
if not reaper.ImGui_Key_0() then
  acendan.msg(
    "This script requires the ReaImGui API, which can be installed from:\n\nExtensions > ReaPack > Browse packages...")
  return
end
local VSDEBUG = os.getenv("VSCODE_DBG_UUID") == "df3e118e-8874-49f7-ab62-ceb166401fb9" and
    dofile('C:/Users/aaron/.vscode/extensions/antoinebalaine.reascript-docs-0.1.12/debugger/LoadDebug.lua') or nil

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ CONSTANTS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

local SCRIPT_NAME = ({ reaper.get_action_context() })[2]:match("([^/\\_]+)%.lua$")
local SCRIPT_DIR = ({ reaper.get_action_context() })[2]:sub(1, ({ reaper.get_action_context() })[2]:find("\\[^\\]*$"))
local WIN, SEP = acendan.getOS()

local WINDOW_SIZE = { width = 500, height = 100 }
local WINDOW_FLAGS = reaper.ImGui_WindowFlags_NoCollapse() | reaper.ImGui_WindowFlags_AlwaysAutoResize()
local CONFIG_FLAGS = reaper.ImGui_ConfigFlags_DockingEnable() | reaper.ImGui_ConfigFlags_NavEnableKeyboard()
local SLIDER_FLAGS = reaper.ImGui_SliderFlags_AlwaysClamp()

local SCHEMES_DIR = SCRIPT_DIR .. "Schemes" .. SEP

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function Init()
  wgt = {}
  wgt.schemes = FetchSchemes()                            -- Table of filenames in scheme dir
  wgt.scheme = GetPreviousValue("scheme", wgt.schemes[1]) -- Active scheme filename
  wgt.data = nil                                          -- Active scheme data
  wgt.name = ""

  wgt.targets = {}
  wgt.targets.Regions = { "Selected", "All", "Time Selection", "Edit Cursor" }
  wgt.targets.Items = { "Selected", "All" }
  wgt.targets.Tracks = { "Selected", "All" }

  -- Try loading scheme, and if it fails, just load up empty window
  if not LoadScheme(wgt.scheme) then wgt.scheme = nil end

  ctx = reaper.ImGui_CreateContext(SCRIPT_NAME, CONFIG_FLAGS)
  reaper.ImGui_SetNextWindowSize(ctx, WINDOW_SIZE.width, WINDOW_SIZE.height)
end

function LoadField(field, parent)
  local sep = wgt.name == "" and "" or field.separator and field.separator or wgt.data.separator
  local unskippable = (field.skip and field.skip == false) or not field.skip
  local value = ""
  local wildcard_help = ""

  -- Enumeration
  if type(field.value) == "number" or field.numwild then
    local rv, str = reaper.ImGui_InputText(ctx, field.field, tostring(field.value))
    if rv then
      if tonumber(str) then
        field.value = tonumber(str)
        field.numwild = false
      elseif str == "$num" then
        field.value = str
        field.numwild = true
      end
      wgt.serialize[#wgt.serialize + 1] = { field.field, field.value }
    end
    wgt.enumeration = {
      start = field.value,
      zeroes = field.zeroes or 1,
      singles = field.singles or false,
      wildcard = "$enum",
      sep = sep
    }
    value = field.numwild and "$num" or wgt.enumeration.wildcard
    wildcard_help = wildcard_help .. "$num: Use project number from renaming target.\n"

    -- Text
  elseif type(field.value) == "string" then
    local rv, str = reaper.ImGui_InputText(ctx, field.field, field.value)
    if rv then
      field.value = str
      wgt.serialize[#wgt.serialize + 1] = { field.field, field.value }
    end
    value = field.value
    wildcard_help = wildcard_help .. "$name: Use original name from renaming target.\n"

    -- Dropdown
  elseif type(field.value) == "table" then
    local selected = field.selected and field.selected or 0
    if reaper.ImGui_BeginCombo(ctx, field.field, field.value[selected]) then
      for i, value in ipairs(field.value) do
        local is_selected = selected == i
        if reaper.ImGui_Selectable(ctx, value, is_selected) then
          field.selected = i
          wgt.serialize[#wgt.serialize + 1] = { field.field, field.selected }
        end
        if is_selected then reaper.ImGui_SetItemDefaultFocus(ctx) end
      end
      reaper.ImGui_EndCombo(ctx)
    end

    -- Use short value as abbreviation, if applicable
    value = (field.selected and field.short) and field.short[field.selected] or
        (field.selected) and field.value[field.selected] or ""

    -- Checkbox
  elseif type(field.value) == "boolean" then
    local rv, bool = reaper.ImGui_Checkbox(ctx, field.field, field.value)
    if rv then
      field.value = bool
      wgt.serialize[#wgt.serialize + 1] = { field.field, field.value }
    end
    value = field.value and field.btrue or field.bfalse
  end

  -- Append to name
  if unskippable and value ~= "" then
    if field.capitalization then value = Capitalize(value, field.capitalization) end
    wgt.name = wgt.name .. sep .. value
  end

  -- Enforce required fields
  if field.required and value == "" then
    reaper.ImGui_SameLine(ctx)
    reaper.ImGui_TextColored(ctx, 0xFF0000FF, "*")
    if wgt.required == "" then wgt.required = field.field end
  end

  -- Help marker
  if field.help and wildcard_help ~= "" then
    acendan.ImGui_HelpMarker(field.help .. "\n\nWildcards\n" .. wildcard_help)
  elseif field.help then
    acendan.ImGui_HelpMarker(field.help)
  elseif wildcard_help ~= "" then
    acendan.ImGui_HelpMarker("Wildcards\n" .. wildcard_help)
  end
end

function PassesIDCheck(field, parent)
  if not field.id then return true end
  if not parent then return false end
  if type(field.id) == "table" then
    for i, id in ipairs(field.id) do
      if parent.value[parent.selected] == id then return true end
    end
    return false
  end
  return parent.value[parent.selected] == field.id
end

-- Load all fields and nested subfields recursively
function LoadFields(fields, parent)
  for i, field in ipairs(fields) do
    -- If field has an ID, it's dependent on parent dropdown's selected value
    if PassesIDCheck(field, parent) then
      LoadField(field, parent)
      if field.fields then LoadFields(field.fields, field) end
    end
  end
end

-- Target = Regions, Items, Tracks
function LoadTargets()
  if not wgt.target then wgt.target = GetPreviousValue("target", nil) end
  if not wgt.mode then wgt.mode = GetPreviousValue("mode", nil) end

  if reaper.ImGui_BeginCombo(ctx, "Target", wgt.target) then
    for target, modes in pairs(wgt.targets) do
      if reaper.ImGui_Selectable(ctx, target, wgt.target == target) then
        wgt.target = target
        wgt.mode = nil
        SetCurrentValue("target", target)
      end
    end
    reaper.ImGui_EndCombo(ctx)
  end
  if wgt.target then
    if reaper.ImGui_BeginCombo(ctx, "Mode", wgt.mode) then
      for i, mode in ipairs(wgt.targets[wgt.target]) do
        if reaper.ImGui_Selectable(ctx, mode, wgt.mode == mode) then
          wgt.mode = mode
          SetCurrentValue("mode", mode)
        end
      end
      reaper.ImGui_EndCombo(ctx)
    end
  end
end

function ValidateFields()
  wgt.invalid = nil
  if wgt.required ~= "" then
    wgt.invalid = "Missing field: " .. wgt.required; return
  end
  if wgt.name == "" then
    wgt.invalid = "Generated name is blank!"; return
  end
  if not wgt.target then
    wgt.invalid = "Please set a renaming target!"; return
  end
  if wgt.target and not wgt.mode then
    wgt.invalid = "Please set a renaming mode for target: " .. wgt.target; return
  end
end

function TabNaming()
  if not LoadScheme(wgt.scheme) then
    wgt.scheme = nil
    return
  end
  wgt.name = ""
  wgt.required = ""

  ----------------- Naming -----------------------
  -- TODO: Add custom font for titles
  reaper.ImGui_Text(ctx, wgt.data.title)
  LoadFields(wgt.data.fields)
  reaper.ImGui_Separator(ctx)

  ----------------- Target -----------------------
  reaper.ImGui_Text(ctx, "Renaming Target")
  LoadTargets()

  ----------------- Submit -----------------------
  ValidateFields()
  if wgt.invalid then reaper.ImGui_BeginDisabled(ctx) end
  Button("Rename", RenameButton,
    "Applies your name to the given target!\n\nPro Tip: You can press the 'Enter' key to trigger renaming from any of the fields above.",
    0.42)
  if wgt.invalid then
    reaper.ImGui_EndDisabled(ctx)
    reaper.ImGui_SameLine(ctx)
    reaper.ImGui_TextColored(ctx, 0xFFFF00BB, wgt.invalid)
  elseif wgt.error then
    reaper.ImGui_SameLine(ctx)
    reaper.ImGui_TextColored(ctx, 0xFF0000FF, wgt.error)
  elseif reaper.ImGui_IsKeyReleased(ctx, reaper.ImGui_Key_Enter()) then
    -- If we know there are no errors or warnings, allow user to press Enter to rename
    RenameButton()
  end
  reaper.ImGui_Separator(ctx)

  ----------------- Preview -----------------------
  -- Preview name text in grey
  reaper.ImGui_Text(ctx, "Preview: ")
  reaper.ImGui_SameLine(ctx)
  reaper.ImGui_TextDisabled(ctx, SanitizeName(wgt.name, wgt.enumeration, {}))

  -- Copy to clipboard button next to preview text
  if wgt.name ~= "" then
    if reaper.ImGui_Button(ctx, "Copy to Clipboard") then
      reaper.CF_SetClipboard(wgt.name)
    end
  end

  -- Button to clear local settings for current scheme
  reaper.ImGui_SameLine(ctx)
  Button("Clear All Fields", function()
    ClearFields(wgt.data.fields)
    SetScheme(wgt.scheme)
  end, nil, 0)
end

function ClearFields(fields)
  for i, field in ipairs(fields) do
    DeleteCurrentValue(wgt.data.title .. " - " .. field.field)
    if field.fields then ClearFields(field.fields) end
  end
end

-- function TabMetadata()
--   return
-- end

function TabSettings()
  -- Combobox for schemes
  if reaper.ImGui_BeginCombo(ctx, "Scheme", wgt.scheme) then
    for i, scheme in ipairs(wgt.schemes) do
      if reaper.ImGui_Selectable(ctx, scheme, wgt.scheme == scheme) then
        SetScheme(scheme)
      end
    end
    reaper.ImGui_EndCombo(ctx)
  end

  -- Button to validate selected scheme
  Button("Validate Scheme", function()
    if wgt.scheme and ValidateScheme(wgt.scheme) then
      acendan.msg("Scheme is valid!", "The Last Renamer")
    end
  end, "Check the selected scheme for YAML formatting errors.")

  -- Button to open schemes directory
  reaper.ImGui_Separator(ctx)
  Button("Open Schemes Directory", function()
    reaper.CF_ShellExecute(SCHEMES_DIR)
  end, "Open the folder containing your schemes in a file browser.")

  -- Rescan schemes directory
  Button("Rescan Schemes Directory", function()
    wgt.schemes = FetchSchemes()
  end, "Rescan the schemes directory for new scheme files.")

  -- Button to open the wiki
  Button("Documentation", function()
    reaper.CF_ShellExecute("https://github.com/acendan/reascripts/wiki/The-Last-Renamer")
  end, "Open the wiki for The Last Renamer.")
end

function Main()
  acendan.ImGui_PushStyles()
  local rv, open = reaper.ImGui_Begin(ctx, SCRIPT_NAME, true, WINDOW_FLAGS)
  if not rv then return open end

  if reaper.ImGui_BeginTabBar(ctx, "TabBar") then
    TabItem("Naming", TabNaming)
    --TabItem("Metadata", TabMetadata)
    TabItem("Settings", TabSettings)
    reaper.ImGui_EndTabBar(ctx)
  end

  reaper.ImGui_End(ctx)
  acendan.ImGui_PopStyles()
  if open then reaper.defer(Main) else return end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ UTILITIES ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Fetch filenames from SCHEMES_DIR
function FetchSchemes()
  local schemes = {}
  if acendan.directoryExists(SCHEMES_DIR) then
    local file_idx = 0
    repeat
      schemes[#schemes + 1] = reaper.EnumerateFiles(SCHEMES_DIR, file_idx)
      file_idx = file_idx + 1
    until not reaper.EnumerateFiles(SCHEMES_DIR, file_idx)
  end
  return schemes
end

function SetScheme(scheme)
  wgt.scheme = scheme
  wgt.data = nil
  SetCurrentValue("scheme", scheme)
end

-- Load named scheme into wgt.data
function LoadScheme(scheme)
  if wgt.data then return true end
  wgt.data = ValidateScheme(scheme)
  if not wgt.data then return false end
  RecallSettings(wgt.data.title, wgt.data.fields)
  return true
end

function ValidateScheme(scheme)
  if not scheme then return nil end
  local scheme_path = SCHEMES_DIR .. scheme
  local status, result = pcall(acendan.loadYaml, scheme_path)
  if not status then
    acendan.msg("Error loading scheme: " .. scheme .. "\n\n" .. tostring(result), "The Last Renamer"); return nil
  end
  return result
end

function GetPreviousValue(key, default)
  return reaper.HasExtState(SCRIPT_NAME, key) and reaper.GetExtState(SCRIPT_NAME, key) or default
end

function SetCurrentValue(key, value)
  reaper.SetExtState(SCRIPT_NAME, key, tostring(value), true)
end

function DeleteCurrentValue(key)
  reaper.DeleteExtState(SCRIPT_NAME, key, true)
end

function StoreSettings()
  for i = 1, #wgt.serialize do
    local field, value = table.unpack(wgt.serialize[i])
    SetCurrentValue(wgt.data.title .. " - " .. field, value)
  end
end

function RecallSettings(title, fields)
  for i, field in ipairs(fields) do
    local prev = GetPreviousValue(title .. " - " .. field.field, nil)
    if prev then
      -- Dropdowns
      if type(field.value) == "table" then
        field.selected = tonumber(prev)

        -- Enumeration
      elseif type(field.value) == "number" then
        if type(prev) == "number" then
          field.value = tonumber(prev)
        elseif prev == "$num" then
          field.numwild = true
          field.value = prev
        end

        -- Dropdowns
      elseif type(field.value) == "boolean" then
        field.value = prev == "true" and true or false

        -- Text
      elseif type(field.value) == "string" then
        field.value = prev
      end
    end
    if field.fields then RecallSettings(title, field.fields) end
  end
  wgt.serialize = {}
end

function Capitalize(str, capitalization)
  local caps = capitalization:lower() -- oh the irony of case sensitive :find()
  if caps:find("title") then
    return str:gsub("(%a)([%w_']*)", function(first, rest) return first:upper() .. rest:lower() end)
  elseif caps:find("up") then
    return str:upper()
  elseif caps:find("low") then
    return str:lower()
  else
    return str
  end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~ IMGUI ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function Button(name, callback, help, color)
  if color then
    acendan.ImGui_Button(name, callback, color)
  elseif reaper.ImGui_Button(ctx, name, color) then
    callback()
  end
  if help then
    acendan.ImGui_HelpMarker(help)
  end
end

function TabItem(name, tab)
  if reaper.ImGui_BeginTabItem(ctx, name) then
    tab()
    reaper.ImGui_EndTabItem(ctx)
  end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~ RENAMING ~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
function RenameButton()
  reaper.Undo_BeginBlock()
  wgt.error = Rename(wgt.target, wgt.mode, wgt.name, wgt.enumeration)
  reaper.Undo_EndBlock("The Last Renamer - " .. wgt.data.title, -1)
  StoreSettings()
end

-- @param target Regions, Items, Tracks
-- @param mode Selected, All, Time Selection, Edit Cursor
-- @param name New name
-- @param enumeration { start, zeroes, singles, wildcard, sep }
--        start: Start number for enumeration.
--        zeroes: Number of zeroes to pad enumeration with.
--        singles: Default false. If true, enumerate standalone item/region/track.
--        wildcard: Find/replace wildcard in name for enumeration.
--        sep: Separator before wildcard.
-- @return error
function Rename(target, mode, name, enumeration)
  if not target or not mode or not name or not enumeration then
    return "Missing required parameters!"
  end

  if target == "Regions" then
    local _, num_markers, num_regions = reaper.CountProjectMarkers(0)
    if num_regions > 0 then
      return RenameRegions(mode, num_markers + num_regions, name, enumeration)
    end
  elseif target == "Items" then
    local num_items = reaper.CountMediaItems(0)
    if num_items > 0 then
      return RenameItems(mode, num_items, name, enumeration)
    end
  elseif target == "Tracks" then
    local num_tracks = reaper.CountTracks(0)
    if num_tracks > 0 then
      return RenameTracks(mode, num_tracks, name, enumeration)
    end
  end

  return "Project has no " .. target .. " to rename!"
end

function SanitizeName(name, enumeration, wildcards)
  -- Uses enumeration struct to generate string substitution for enumeration
  local function GetEnumeration(enumeration)
    if (enumeration.num == 1 and not enumeration.singles) or type(enumeration.start) == "string" then
      return enumeration.sep
    end
    local num_str = PadZeroes(enumeration.start, enumeration.zeroes)
    enumeration.start = enumeration.start + 1
    return enumeration.sep .. num_str
  end

  -- Resolve wildcards
  local wild = name
  for _, wildcard in ipairs(wildcards) do
    wild = wild:gsub(wildcard.find, wildcard.replace)
  end

  -- Resolve enumeration
  local enumerated = wild:gsub(enumeration.sep .. enumeration.wildcard, GetEnumeration(enumeration))

  -- Strip illegal characters and leading/trailing spaces
  local stripped = enumerated:match("^%s*(.-)%s*$")
  local illegal = wgt.data.illegal or { ":", "*", "?", "\"", "<", ">", "|", "\\", "/" }
  for _, char in ipairs(illegal) do
    stripped = stripped:gsub(char, "")
  end

  -- Find & replace after generating all other parts of the name
  if wgt.data.find and wgt.data.replace then
    for _, char in ipairs(wgt.data.find) do
      stripped = stripped:gsub(char, wgt.data.replace)
    end
  end
  return stripped
end

-- Convert a number to a string, adding given number of zeroes to the front if necessary
function PadZeroes(num, zeroes)
  local num_str = tostring(num)
  local num_len = string.len(num_str)
  local pad = (zeroes and zeroes or 1) - num_len + 1
  if pad > 0 then
    for j = 1, pad do
      num_str = "0" .. num_str
    end
  end
  return num_str
end

function RenameRegions(mode, num_mkrs_rgns, name, enumeration)
  local error = nil
  local queue = {}

  if mode == "Time Selection" then
    local start_time_sel, end_time_sel = reaper.GetSet_LoopTimeRange(0, 0, 0, 0, 0);
    if start_time_sel ~= end_time_sel then
      local i = 0
      while i < num_mkrs_rgns do
        local _, isrgn, pos, rgnend, rgnname, markrgnindexnumber, color = reaper.EnumProjectMarkers3(0, i)
        if isrgn then
          if pos >= start_time_sel and rgnend <= end_time_sel then
            local wildcards = { { find = "$name", replace = rgnname }, { find = "$num", replace = PadZeroes(markrgnindexnumber) } }
            queue[#queue + 1] = { i, pos, rgnend, color, markrgnindexnumber, wildcards }
          end
        end
        i = i + 1
      end
    else
      error = "You haven't made a time selection!"
    end
  elseif mode == "All" then
    local i = 0
    while i < num_mkrs_rgns do
      local _, isrgn, pos, rgnend, rgnname, markrgnindexnumber, color = reaper.EnumProjectMarkers3(0, i)
      if isrgn then
        local wildcards = { { find = "$name", replace = rgnname }, { find = "$num", replace = PadZeroes(markrgnindexnumber) } }
        queue[#queue + 1] = { i, pos, rgnend, color, markrgnindexnumber, wildcards }
      end
      i = i + 1
    end
  elseif mode == "Edit Cursor" then
    local _, regionidx = reaper.GetLastMarkerAndCurRegion(0, reaper.GetCursorPosition())
    if regionidx ~= nil then
      local _, isrgn, pos, rgnend, rgnname, markrgnindexnumber, color = reaper.EnumProjectMarkers3(0, regionidx)
      if isrgn then
        local wildcards = { { find = "$name", replace = rgnname }, { find = "$num", replace = PadZeroes(markrgnindexnumber) } }
        queue[#queue + 1] = { regionidx, pos, rgnend, color, markrgnindexnumber, wildcards }
      end
    end
  elseif mode == "Selected" then
    local sel_rgn_table = acendan.getSelectedRegions()
    if sel_rgn_table then
      for _, regionidx in pairs(sel_rgn_table) do
        local i = 0
        while i < num_mkrs_rgns do
          local _, isrgn, pos, rgnend, rgnname, markrgnindexnumber, color = reaper.EnumProjectMarkers3(0, i)
          if isrgn and markrgnindexnumber == regionidx then
            local wildcards = { { find = "$name", replace = rgnname }, { find = "$num", replace = PadZeroes(markrgnindexnumber) } }
            queue[#queue + 1] = { i, pos, rgnend, color, markrgnindexnumber, wildcards }
            break
          end
          i = i + 1
        end
      end
    else
      error = "No regions selected!\n\nPlease go to View > Region/Marker Manager to select regions."
    end
  end

  -- Process queue
  if #queue > 0 then
    enumeration.num = #queue
    for _, item in ipairs(queue) do
      local i, pos, rgnend, color, markrgnindexnumber, wildcards = table.unpack(item)
      reaper.SetProjectMarkerByIndex(0, i, true, pos, rgnend, markrgnindexnumber,
        SanitizeName(name, enumeration, wildcards), color)
    end
  else
    error = "No regions to rename (" .. mode .. ")!"
  end

  return error
end

function RenameItems(mode, num_items, name, enumeration)
  local error = nil
  local queue = {}

  if mode == "Selected" then
    local num_sel_items = reaper.CountSelectedMediaItems(0)
    if num_sel_items > 0 then
      for i = 0, num_sel_items - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        local item_start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local item_end = item_start + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        local take = reaper.GetActiveTake(item)
        local _, item_name = reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", "", false)
        local item_num = math.floor(reaper.GetMediaItemInfo_Value(item, "IP_ITEMNUMBER") + 1)
        if take ~= nil then
          local wildcards = { { find = "$name", replace = item_name }, { find = "$num", replace = PadZeroes(item_num) } }
          queue[#queue + 1] = { take, wildcards }
        end
      end
    else
      error = "No items selected!"
    end
  elseif mode == "All" then
    for i = 0, num_items - 1 do
      local item = reaper.GetMediaItem(0, i)
      local item_start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
      local item_end = item_start + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
      local take = reaper.GetActiveTake(item)
      local _, item_name = reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", "", false)
      local item_num = math.floor(reaper.GetMediaItemInfo_Value(item, "IP_ITEMNUMBER") + 1)
      if take ~= nil then
        local wildcards = { { find = "$name", replace = item_name }, { find = "$num", replace = PadZeroes(item_num) } }
        queue[#queue + 1] = { take, wildcards }
      end
    end
  end

  -- Process queue
  if #queue > 0 then
    enumeration.num = #queue
    for _, item in ipairs(queue) do
      local take, wildcards = table.unpack(item)
      reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", SanitizeName(name, enumeration, wildcards), true)
    end
  else
    error = "No items to rename (" .. mode .. ")!"
  end

  return error
end

function RenameTracks(mode, num_tracks, name, enumeration)
  local error = nil
  local queue = {}

  if mode == "Selected" then
    local num_sel_tracks = reaper.CountSelectedTracks(0)
    if num_sel_tracks > 0 then
      for i = 0, num_sel_tracks - 1 do
        local track = reaper.GetSelectedTrack(0, i)
        local _, track_name = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)
        local track_num = math.floor(reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER"))
        local wildcards = { { find = "$name", replace = track_name }, { find = "$num", replace = PadZeroes(track_num) } }
        queue[#queue + 1] = { track, wildcards }
      end
    else
      error = "No tracks selected!"
    end
  elseif mode == "All" then
    for i = 0, num_tracks - 1 do
      local track = reaper.GetTrack(0, i)
      local _, track_name = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)
      local track_num = math.floor(reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER"))
      local wildcards = { { find = "$name", replace = track_name }, { find = "$num", replace = PadZeroes(track_num) } }
      queue[#queue + 1] = { track, wildcards }
    end
  end

  -- Process queue
  if #queue > 0 then
    enumeration.num = #queue
    for _, item in ipairs(queue) do
      local track, wildcards = table.unpack(item)
      reaper.GetSetMediaTrackInfo_String(track, "P_NAME", SanitizeName(name, enumeration, wildcards), true)
    end
  else
    error = "No tracks to rename (" .. mode .. ")!"
  end

  return error
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Init()
Main()
