-- @description The Last Renamer
-- @author Aaron Cendan
-- @version 2.31
-- @metapackage
-- @provides
--   [main] .
--   Schemes/*.{yaml}
--   Meta/*.{yaml}
--   VSCode/*.{json}
-- @link https://ko-fi.com/acendan_
-- @about
--   # The Last Renamer
-- @changelog
--   # Added ultra minimalist yaml scheme as an example

local acendan_LuaUtils = reaper.GetResourcePath() .. '/Scripts/ACendan Scripts/Development/acendan_Lua Utilities.lua'
if reaper.file_exists(acendan_LuaUtils) then
  dofile(acendan_LuaUtils); if not acendan or acendan.version() < 9.30 then
    acendan.msg(
      'This script requires a newer version of ACendan Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',
      "ACendan Lua Utilities"); return
  end
else
  reaper.ShowConsoleMsg(
    "This script requires ACendan Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'ACendan Lua Utilities'"); return
end

if reaper.ImGui_Key_0() then
  package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua'
  require 'imgui' '0.10.0.1'
else
  acendan.msg(
    "This script requires the ReaImGui API, which can be installed from:\n\nExtensions > ReaPack > Browse packages...")
  return
end
local VSDEBUG = os.getenv("VSCODE_DBG_UUID") == "df3e118e-8874-49f7-ab62-ceb166401fb9" and
    dofile('C:/Users/aaron/.vscode/extensions/antoinebalaine.reascript-docs-0.1.14/debugger/LoadDebug.lua') or nil

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ CONSTANTS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

local WIN, SEP = acendan.getOS()
local SCRIPT_NAME = ({ reaper.get_action_context() })[2]:match("([^/\\_]+)%.lua$")
local SCRIPT_DIR = ({ reaper.get_action_context() })[2]:sub(1, ({ reaper.get_action_context() })[2]:find(SEP .. "[^" .. SEP .. "]*$"))

local WINDOW_SIZE = { width = 500, height = 100 }
local WINDOW_FLAGS = reaper.ImGui_WindowFlags_NoCollapse() | reaper.ImGui_WindowFlags_AlwaysAutoResize()
local CONFIG_FLAGS = reaper.ImGui_ConfigFlags_DockingEnable() | reaper.ImGui_ConfigFlags_NavEnableKeyboard()
local SLIDER_FLAGS = reaper.ImGui_SliderFlags_AlwaysClamp()
local FLT_MIN, FLT_MAX = reaper.ImGui_NumericLimits_Float()
local DBL_MIN, DBL_MAX = reaper.ImGui_NumericLimits_Double()

local SCHEMES_DIR = SCRIPT_DIR .. "Schemes" .. SEP
local BACKUPS_DIR = SCRIPT_DIR .. "Backups" .. SEP
local META_DIR = SCRIPT_DIR .. "Meta" .. SEP

local META_MKR_PREFIX = "#META"

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function Init()
  wgt = {}
  wgt.schemes = FetchSchemes()                            -- Table of filenames in scheme dir
  wgt.scheme = GetPreviousValue("scheme", wgt.schemes[1]) -- Active scheme filename
  wgt.data = nil                                          -- Active scheme data
  wgt.meta = nil                                          -- Metadata
  wgt.name = ""                                           -- Generated name
  wgt.preset = {}                                         -- Preset data
  wgt.history = {}                                        -- History data
  wgt.dragdrop = {}                                       -- Drag-dropped files
  wgt.serialize = {}                                      -- Serialized fields
  wgt.values = {}                                         -- Values for duplicate checking

  wgt.targets = {}
  wgt.targets.Regions = { "Selected", "All", "Time Selection", "Edit Cursor" }
  wgt.targets.Items = { "Selected", "All" }
  wgt.targets.Tracks = { "Selected", "All" }

  -- Try loading scheme, and if it fails, just load up empty window
  if not LoadScheme(wgt.scheme) then wgt.scheme = nil end

  ctx = reaper.ImGui_CreateContext(SCRIPT_NAME, CONFIG_FLAGS)
  acendan.ImGui_SetFont()
  local scale = acendan.ImGui_GetScale()
  reaper.ImGui_SetNextWindowSize(ctx, WINDOW_SIZE.width * scale, WINDOW_SIZE.height * scale)
  acendan.ImGui_SetScale(scale)
end

function LoadField(field)
  local unskippable = (field.skip and field.skip == false) or not field.skip
  local meta = field.meta and true or false
  local sep = (wgt.name == "" or meta) and "" or field.separator and field.separator or wgt.data.separator
  local value = ""
  local wildcard_help = ""
  local serialize = meta and wgt.meta.serialize or wgt.serialize

  -- If metadata field's value is missing, skip
  if meta and not field.value then return end

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
      AppendSerializedField(serialize, field.field, field.value)
    end
    if not meta then
      wgt.enumeration = {
        start = field.value,
        zeroes = field.zeroes or 1,
        singles = field.singles or false,
        wildcard = "$enum",
        sep = sep
      }
      value = field.numwild and "$num" or wgt.enumeration.wildcard
      wildcard_help = wildcard_help .. "$num: Use project number from renaming target.\n"
    end

    -- Text
  elseif type(field.value) == "string" then
    local rv, str = reaper.ImGui_InputTextWithHint(ctx, field.field, field.hint, field.value)
    if rv then
      field.value = str
      AppendSerializedField(serialize, field.field, field.value)
    end
    if not meta then
      value = field.value
      wildcard_help = wildcard_help .. "$name: Use original name from renaming target.\n"
    end

    -- Dropdown
  elseif type(field.value) == "table" then
    if not field.selected then field.selected = field.default or 0 end
    if not field.filter then field.filter = reaper.ImGui_CreateTextFilter(field.value[field.selected] or ""); reaper.ImGui_Attach(ctx, field.filter) end
    local rv, rownum, rowtext
    if GetPreviousValue("opt_autofill", false) == "true" then
      rv, rownum, rowtext = acendan.ImGui_AutoFillComboBox(ctx, field.field, field.value, field.selected, field.filter)
    else
      rv, rownum, rowtext = acendan.ImGui_ComboBox(ctx, field.field, field.value, field.selected)
    end
    if rv then
      -- acendan.dbg("Selected: " .. rowtext .. " (" .. rownum .. ")" .. " Text Filter: " .. reaper.ImGui_TextFilter_Get(field.filter))
      field.selected = rownum
      AppendSerializedField(serialize, field.field, field.selected)
    end

    if not meta then
      -- Use short value as abbreviation, if applicable
      value = (field.selected and field.short) and field.short[field.selected] or
          (field.selected) and field.value[field.selected] or ""
    end

    -- Checkbox
  elseif type(field.value) == "boolean" then
    local rv, bool = reaper.ImGui_Checkbox(ctx, field.field, field.value)
    if rv then
      field.value = bool
      AppendSerializedField(serialize, field.field, field.value)
    end
    if not meta then
      value = field.value and field.btrue or field.bfalse
    end
  end

  -- Append to name
  if unskippable and value ~= "" and not meta then
    if field.capitalization then value = Capitalize(value, field.capitalization) end
    wgt.name = wgt.name .. sep .. value
    wgt.values[#wgt.values+1] = value
  end

  -- Enforce required fields
  local empty_short = (field.selected and field.short) and field.short[field.selected] == "" or false
  if field.required and value == "" and not empty_short then
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
  if field.id == nil then return true end
  if not parent then return false end
  if type(field.id) == "table" then
    for i, id in ipairs(field.id) do
      if parent.value[parent.selected] == id then return true end
    end
    return false
  end
  if type(field.id) == "boolean" then
    return parent.value == field.id
  end
  return parent.value[parent.selected] == field.id
end

-- Load all fields and nested subfields recursively
function LoadFields(fields, parent)
  for i, field in ipairs(fields) do
    -- If field has an ID, it's dependent on parent dropdown's selected value
    if PassesIDCheck(field, parent) then
      LoadField(field)
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
        SetCurrentValue("target", target)
        wgt.mode = nil
        DeleteCurrentValue("mode")
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

  -- If target is Items, add toggle to respect overlaps
  if wgt.target == "Items" then
    if not wgt.overlap then wgt.overlap = GetPreviousValue("opt_overlap", false) == "true" end
    local rv, overlap = reaper.ImGui_Checkbox(ctx, "Respect Overlaps", wgt.overlap)
    if rv then
      wgt.overlap = overlap
      SetCurrentValue("opt_overlap", overlap)
    end
    acendan.ImGui_Tooltip("If checked, enumeration will not increment on items that overlap with neighbors on this track.")
  end
  
  -- If target is Items - Selected and NVK Only is enabled, display warning
  if wgt.target == "Items" and wgt.mode == "Selected" and GetPreviousValue("opt_nvk_only", false) == "true" then
    reaper.ImGui_SameLine(ctx)
    reaper.ImGui_TextColored(ctx, 0x13BD99FF, "NVK")
    acendan.ImGui_Tooltip("Only NVK Folder Items will be targeted when set to 'Items - Selected'.\n\nDisable this option in Settings if you want to target standard media items.")
  end
end

function ValidateFields(preview_name)
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
  if wgt.data.maxchars and preview_name and #preview_name > wgt.data.maxchars then
    wgt.invalid = "Name length (" .. #preview_name .. ") exceeds max num characters (" .. wgt.data.maxchars .. ")."; return
  end
  if not wgt.data.dupes and #wgt.values > 0 then
    local dupes_tbl = {}
    -- if value contains separator(s), split and add each part to dupes_tbl
    for _, value in ipairs(wgt.values) do
      if wgt.data.separator and value:find(wgt.data.separator) then
        for part in value:gmatch("[^" .. wgt.data.separator .. "]+") do
          dupes_tbl[#dupes_tbl + 1] = part:lower()
        end
      else
        dupes_tbl[#dupes_tbl + 1] = value:lower()
      end
    end
    -- check for dupes
    for _, value in ipairs(dupes_tbl) do
      if acendan.tableCountOccurrences(dupes_tbl, value:lower()) > 1 then
        wgt.invalid = "Duplicate field found: " .. value; return
      end
    end
  end
end

function FindField(fields, field)
  -- Field may have one id or multiple ids after name, separated by :
  local field_name = field:match("([^:]+)")
  local field_ids = {}
  for id in field:gmatch(":(%w+)") do
    field_ids[#field_ids + 1] = id
  end
  for _, f in ipairs(fields) do
    if f.field == field_name then
      if #field_ids == 0 then return f end
      if f.id then
        for _, id in ipairs(field_ids) do
          if type(f.id) == "table" and acendan.tableContainsVal(f.id, id) or f.id == id then return f end
        end
      end
    end
    if f.fields then
      local find_field = FindField(f.fields, field)
      if find_field then return find_field end
    end
  end
end

function ClickLoadPreset()
  local preset = wgt.preset.presets[wgt.preset.idx]
  for field, value in pairs(preset) do
    if field ~= "preset" then
      local find_field = FindField(wgt.data.fields, field)
      if find_field then SetFieldValue(find_field, value) end
    end
  end
  wgt.serialize = {}
end

function LoadPresets()
  reaper.ImGui_SameLine(ctx, 0, 50)
  if reaper.ImGui_Button(ctx, "Presets") then
    RecallPresets()
    reaper.ImGui_OpenPopup(ctx, "PresetPopup")
  end
  if reaper.ImGui_BeginPopup(ctx, "PresetPopup") then
    local items = {}
    for _, preset in ipairs(wgt.preset.presets) do
      items[#items + 1] = preset.preset
    end
    if reaper.ImGui_BeginListBox(ctx, "##PresetsList", -FLT_MIN, 5 * reaper.ImGui_GetTextLineHeightWithSpacing(ctx)) then
      for n, v in ipairs(items) do
        local is_selected = wgt.preset.idx == n
        if reaper.ImGui_Selectable(ctx, v .. "##" .. tostring(n), is_selected, reaper.ImGui_SelectableFlags_AllowDoubleClick()) then
          wgt.preset.idx = n
          if reaper.ImGui_IsMouseDoubleClicked(ctx, reaper.ImGui_MouseButton_Left()) then
            ClickLoadPreset()
            reaper.ImGui_CloseCurrentPopup(ctx)
          end
        end

        -- Set the initial focus when opening the combo (scrolling + keyboard navigation focus)
        if is_selected then
          reaper.ImGui_SetItemDefaultFocus(ctx)
        end
      end
      reaper.ImGui_EndListBox(ctx)
    end

    -- Load
    local enabled = wgt.preset.idx and wgt.preset.idx > 0
    if not enabled then reaper.ImGui_BeginDisabled(ctx) end
    acendan.ImGui_Button("Load", ClickLoadPreset, 0.42)
    acendan.ImGui_Tooltip("Loads the selected preset into the naming fields.\n\nPro Tip: Double-click a preset to load and close this menu.")

    -- Overwrite selected
    reaper.ImGui_SameLine(ctx)
    acendan.ImGui_Button("Overwrite", function()
      -- Delete selected preset then save current settings as new preset with same name
      local preset = wgt.preset.presets[wgt.preset.idx].preset
      DeletePreset(wgt.preset.idx)
      StorePreset(preset)
    end, 0.15)
    acendan.ImGui_Tooltip("Overwrites the selected preset with the current naming fields.")

    -- Delete
    reaper.ImGui_SameLine(ctx)
    acendan.ImGui_Button("Delete", function()
      DeletePreset(wgt.preset.idx)
      wgt.preset.idx = nil
    end, 0)
    if not enabled then reaper.ImGui_EndDisabled(ctx) end
    acendan.ImGui_Tooltip("Permanently deletes the selected preset.")

    -- Save
    reaper.ImGui_Separator(ctx)
    local rv, new_preset = reaper.ImGui_InputTextWithHint(ctx, "##new_preset", "Preset Name", wgt.preset.new)
    if rv then
      wgt.preset.new = new_preset
    end
    reaper.ImGui_SameLine(ctx)
    local enabled = wgt.preset.new and wgt.preset.new ~= ""
    if not enabled then reaper.ImGui_BeginDisabled(ctx) end
    acendan.ImGui_Button("Save", function()
      StorePreset(wgt.preset.new)
      wgt.preset.new = ""
    end, 0.42)
    acendan.ImGui_Tooltip("Saves the current naming fields as a new preset.")
    if not enabled then reaper.ImGui_EndDisabled(ctx) end

    reaper.ImGui_EndPopup(ctx)
  end
end

function ClickLoadHistory()
  local history = wgt.history.presets[wgt.history.idx]
  for field, value in pairs(history) do
    if field ~= "history" then
      local find_field = FindField(wgt.data.fields, field)
      if find_field then SetFieldValue(find_field, value) end
    end
  end
  wgt.serialize = {}
end

function LoadHistory()
  reaper.ImGui_SameLine(ctx)
  if reaper.ImGui_Button(ctx, "History") then
    reaper.ImGui_OpenPopup(ctx, "HistoryPopup")
  end
  if reaper.ImGui_BeginPopup(ctx, "HistoryPopup") then
    local items = {}
    for _, history in ipairs(wgt.history.presets) do
      items[#items + 1] = history.history
    end
    if reaper.ImGui_BeginListBox(ctx, "##HistoryList", 300, 5 * reaper.ImGui_GetTextLineHeightWithSpacing(ctx)) then
      for n, v in ipairs(items) do
        local is_selected = wgt.history.idx == n
        if reaper.ImGui_Selectable(ctx, v .. "##" .. tostring(n), is_selected, reaper.ImGui_SelectableFlags_AllowDoubleClick()) then
          wgt.history.idx = n
          if reaper.ImGui_IsMouseDoubleClicked(ctx, reaper.ImGui_MouseButton_Left()) then
            ClickLoadHistory()
            reaper.ImGui_CloseCurrentPopup(ctx)
          end
        end
        acendan.ImGui_Tooltip(v)

        -- Set the initial focus when opening the combo (scrolling + keyboard navigation focus)
        if is_selected then
          reaper.ImGui_SetItemDefaultFocus(ctx)
        end
      end
      reaper.ImGui_EndListBox(ctx)
    end

    -- Load
    local enabled = wgt.history.idx and wgt.history.idx > 0
    if not enabled then reaper.ImGui_BeginDisabled(ctx) end
    acendan.ImGui_Button("Load", ClickLoadHistory, 0.42)
    acendan.ImGui_Tooltip(
      "Loads the selected history into the naming fields.\n\nPro Tip: Double-click a history to load and close this menu.")
    if not enabled then reaper.ImGui_EndDisabled(ctx) end

    reaper.ImGui_EndPopup(ctx)
  end
end

function TabNaming()
  -- Load scheme
  if not LoadScheme(wgt.scheme) then
    wgt.load_failed = wgt.load_failed or
    (wgt.scheme and "Failed to load scheme:  " .. wgt.scheme or "Failed to load scheme!")
    reaper.ImGui_TextColored(ctx, 0xFFFF00BB, wgt.load_failed .. "\n\nPlease select a new scheme in the Settings tab.")
    wgt.scheme = nil
    return
  end
  wgt.load_failed = nil
  wgt.name = ""
  wgt.required = ""
  wgt.values = {}

  ----------------- Naming -----------------------
  reaper.ImGui_Text(ctx, wgt.data.title)
  reaper.ImGui_PushItemFlag(ctx, reaper.ImGui_ItemFlags_NoTabStop(), true)
  LoadPresets()
  LoadHistory()
  reaper.ImGui_PopItemFlag(ctx)
  LoadFields(wgt.data.fields)

  ----------------- Target -----------------------
  reaper.ImGui_Spacing(ctx)
  reaper.ImGui_SeparatorText(ctx, "Targets")
  LoadTargets()

  ----------------- Submit -----------------------
  local preview_name = SanitizeName(wgt.name, wgt.enumeration, {}, true)
  ValidateFields(preview_name)
  if wgt.invalid then reaper.ImGui_BeginDisabled(ctx) end
  Button("Rename", ApplyName,
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
    ApplyName()
  end

  ----------------- Preview -----------------------
  -- Preview name text in grey
  reaper.ImGui_Spacing(ctx)
  reaper.ImGui_Separator(ctx)

  -- Copy to clipboard button next to preview text
  Button("Copy", function()
    if not wgt.name or wgt.name == "" then return end
    reaper.CF_SetClipboard(SanitizeName(wgt.name, nil, {}, true))
  end, "Copies the generated name to your clipboard.\n\nUnfortunately, this can not resolve wildcards or enumeration.")

  -- Display generated name
  reaper.ImGui_SameLine(ctx)
  reaper.ImGui_TextDisabled(ctx, preview_name)

  if wgt.data.maxchars then
    reaper.ImGui_SameLine(ctx)
    reaper.ImGui_TextDisabled(ctx, "(" .. #preview_name .. "/" .. wgt.data.maxchars .. ")")
  end

  -- Button to clear local settings for current scheme
  Button("Clear All Fields", function()
    ClearFields(wgt.data.title, wgt.data.fields)
    SetScheme(wgt.scheme)
  end, "Clears out all fields, restoring them to their default state.", 0)
end

function ClearFields(title, fields)
  for i, field in ipairs(fields) do
    DeleteCurrentValue(title .. " - " .. field.field)
    if field.fields then ClearFields(title, field.fields) end
  end
end

function TabMetadata()
  if not ValidateMeta() then return end

  ----------------- Metadata -----------------------
  reaper.ImGui_Text(ctx, "Metadata")
  acendan.ImGui_HelpMarker("Metadata fields are optional, and will be placed as a META marker after your target.\n\n'Add new metadata' setting must be enabled in the Render window!")
  LoadFields(wgt.meta.fields)

  ----------------- Target -----------------------
  reaper.ImGui_Spacing(ctx)
  reaper.ImGui_SeparatorText(ctx, "Targets")
  LoadTargets()

  -- Disable target Tracks if on metadata tab
  local disabled = not wgt.target or wgt.target == "Tracks" or not wgt.mode
  if disabled then reaper.ImGui_BeginDisabled(ctx) end

  ----------------- Submit -----------------------
  Button("Apply Metadata", ApplyMetadata,
    "Applies your metadata to the given target!\n\nPro Tip: You can press the 'Enter' key to trigger metadata application from any of the fields above.",
    0.42)

  if disabled then
    reaper.ImGui_SameLine(ctx)
    local warning = wgt.target and ((wgt.target == "Tracks" or wgt.mode) and "Unsupported metadata target: " .. wgt.target or "Please select a mode for: " .. wgt.target) or "Please select a target."
    reaper.ImGui_TextColored(ctx, 0xFFFF00BB, warning)
    reaper.ImGui_EndDisabled(ctx)
  elseif wgt.meta.error then
    reaper.ImGui_SameLine(ctx)
    reaper.ImGui_TextColored(ctx, 0xFF0000FF, wgt.meta.error)
  elseif reaper.ImGui_IsKeyReleased(ctx, reaper.ImGui_Key_Enter()) then
    ApplyMetadata()
  end

  -- Clear all fields
  reaper.ImGui_Spacing(ctx)
  reaper.ImGui_Separator(ctx)
  Button("Clear All Fields", function()
    ClearFields("Metadata", wgt.meta.fields)
    wgt.meta = nil
  end, "Clears out all fields, restoring them to their default state.", 0)
end

function TabSettings()
  reaper.ImGui_SeparatorText(ctx, "Scheme")

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

  -- Add shared scheme
  Button("Add Shared Scheme", function()
    local shared_scheme = acendan.promptForFile("Select a shared scheme to import", "", "",
      "YAML Files (*.yaml)\0*.yaml\0\0")
    if shared_scheme then
      local shared_scheme_name = shared_scheme:match("[^/\\]+$")
      -- Ignore if shared scheme is in schemes directory
      if shared_scheme:find(SCHEMES_DIR) then
        acendan.msg("Shared scheme must be outside of the schemes directory!", "The Last Renamer")
        return
      end

      local shared_schemes_table = GetSharedSchemes()
      -- Check if scheme already exists in shared schemes
      for _, scheme in ipairs(shared_schemes_table) do
        if scheme == shared_scheme then
          acendan.msg("Shared scheme already exists!", "The Last Renamer")
          return
        end
      end
      shared_schemes_table[#shared_schemes_table + 1] = shared_scheme
      SetCurrentValue("shared_schemes", table.concat(shared_schemes_table, ";"))

      wgt.schemes = FetchSchemes()
      SetScheme("Shared: " .. shared_scheme_name)
    else
      acendan.msg("No shared scheme selected!", "The Last Renamer")
    end
  end,
    "Import a shared scheme from a YAML file outside of the schemes directory (for example, a file used by multiple team members via Perforce).\n\nNote: Shared Schemes can not have hyphens in their filename.")

  -- Remove shared scheme
  reaper.ImGui_SameLine(ctx)
  Button("Remove Shared Scheme", function()
    if not wgt.scheme:find("Shared: ") then
      acendan.msg("Selected scheme is not a shared scheme!", "The Last Renamer")
      return
    end
    local shared_scheme_name = wgt.scheme:match("Shared: ([^/\\]+)")
    local shared_schemes_table = GetSharedSchemes()
    for i, scheme in ipairs(shared_schemes_table) do
      if scheme:find(shared_scheme_name) then
        table.remove(shared_schemes_table, i)
        break
      end
    end
    SetCurrentValue("shared_schemes", table.concat(shared_schemes_table, ";"))

    wgt.schemes = FetchSchemes()
    SetScheme(wgt.schemes[1])
  end, "Removes the selected shared scheme from the schemes list.", 0)

  -- Button to open schemes directory
  reaper.ImGui_Spacing(ctx)
  reaper.ImGui_Text(ctx, "File System")
  Button("Open Schemes Folder", function()
    reaper.CF_ShellExecute(SCHEMES_DIR)
  end, "Open the folder containing your schemes in a file browser.")

  -- Rescan schemes directory
  reaper.ImGui_SameLine(ctx)
  Button("Rescan Folder", function()
    wgt.schemes = FetchSchemes()
  end, "Rescan the schemes directory for new scheme files.")

  ----------------- Options -----------------------
  reaper.ImGui_Spacing(ctx)
  reaper.ImGui_SeparatorText(ctx, "Options")

  -- Checkbox to auto clear on load
  local auto_clear = GetPreviousValue("opt_auto_clear", false)
  local rv, auto_clear = reaper.ImGui_Checkbox(ctx, "Auto Clear Fields", auto_clear == "true" and true or false)
  if rv then SetCurrentValue("opt_auto_clear", auto_clear) end
  acendan.ImGui_Tooltip("Automatically clear all fields when loading scheme (opening tool or switching scheme).")

  -- Enable metadata
  local enable_meta = GetPreviousValue("opt_enable_meta", false)
  local rv, enable_meta = reaper.ImGui_Checkbox(ctx, "Enable Metadata Tab", enable_meta == "true" and true or false)
  if rv then SetCurrentValue("opt_enable_meta", enable_meta) end
  acendan.ImGui_Tooltip("Enable the metadata tab for adding metadata to your renaming targets.\n\nRequires 'Add new metadata' setting in the Render window!")

  -- Enable autofill dropdowns
  local autofill = GetPreviousValue("opt_autofill", false)
  local rv, autofill = reaper.ImGui_Checkbox(ctx, "Enable Autofill Dropdowns", autofill == "true" and true or false)
  if rv then SetCurrentValue("opt_autofill", autofill) end
  acendan.ImGui_Tooltip("Experimental - Overrides standard dropdowns with custom dropdowns that auto-fill with tab while typing.\n\nMay be buggy!")

  -- Only process NVK folder items in items mode
  local nvk_only = GetPreviousValue("opt_nvk_only", false)
  local rv, nvk_only = reaper.ImGui_Checkbox(ctx, "NVK Folder Items", nvk_only == "true" and true or false)
  if rv then SetCurrentValue("opt_nvk_only", nvk_only) end
  acendan.ImGui_Tooltip("Only target NVK Folder Items when set to 'Items - Selected'. If unsure, leave unchecked.")

  -- Slider to set UI element scale
  if acendan.ImGui_ScaleSlider() then wgt.set_font = true end

  -- Slider for num history, from 3 to 50
  local num_hist = tonumber(GetPreviousValue("opt_num_hist", 10))
  local rv, num_hist = reaper.ImGui_SliderInt(ctx, "History Count", num_hist, 1, 50)
  if rv then SetCurrentValue("opt_num_hist", num_hist) end
  acendan.ImGui_Tooltip("Number of history entries to store for each scheme.")

  ----------------- Backup -----------------------
  reaper.ImGui_Spacing(ctx)
  reaper.ImGui_SeparatorText(ctx, "Backup")

  -- Button to export all presets for the selected scheme to an ini file
  Button("Export Presets", function()
    -- Get presets
    local presets = {}
    while true do
      local preset_title = wgt.data.title .. " - Preset" .. tostring(#presets + 1)
      local preset = GetPreviousValue(preset_title, nil)
      if not preset then break end
      presets[#presets + 1] = { title = preset_title, preset = preset }
    end
    if #presets == 0 then
      acendan.msg("No presets found for scheme: " .. wgt.data.title, "The Last Renamer")
      return
    end

    -- Ensure dir exists
    local start_ini_path = acendan.encapsulate(BACKUPS_DIR .. "TheLastRenamer_" .. wgt.scheme:gsub("yaml", "ini"))
    local ini_path = start_ini_path
    if not acendan.directoryExists(BACKUPS_DIR) then
      reaper.RecursiveCreateDirectory(BACKUPS_DIR, 0)
      if not acendan.directoryExists(BACKUPS_DIR) then
        acendan.msg("Error creating backups directory:\n\n" .. BACKUPS_DIR, "The Last Renamer")
        return
      end
    end
    local i = 1
    while acendan.fileExists(ini_path) do
      ini_path = start_ini_path:gsub(".ini", "_" .. tostring(i) .. ".ini")
      i = i + 1
    end

    -- Create ini file
    local file, err = io.open(ini_path, "w") -- "w" opens for writing and wipes file
    if not file or err then
      acendan.msg("Error creating ini file:\n\n" .. tostring(err), "The Last Renamer")
      return
    end
    file:write("[The Last Renamer]\n")
    for _, preset in ipairs(presets) do
      file:write(preset.title .. "=" .. preset.preset .. "\n")
    end
    file:close()

    -- Copy path to clipboard
    reaper.CF_SetClipboard(ini_path)
    acendan.msg(tostring(#presets) .. " preset(s) exported to:\n\n" .. ini_path .. "\n\nPath copied to clipboard.",
      "The Last Renamer")
  end, "Exports all presets for the selected scheme to an ini file.")

  -- Button to import presets from drag-dropped ini files
  reaper.ImGui_SameLine(ctx)
  Button("Import Presets", function()
    -- Check for drag-dropped files
    if #wgt.dragdrop == 0 then
      acendan.msg("No preset files found to import! Please drag-drop preset .ini files below.", "The Last Renamer")
      return
    end

    -- Read ini file(s)
    local presets = {}
    for _, file in ipairs(wgt.dragdrop) do
      local i = 1
      while true do
        local preset_title = wgt.data.title .. " - Preset" .. tostring(i)
        local ret, preset = reaper.BR_Win32_GetPrivateProfileString("The Last Renamer", preset_title, "", file)
        if not ret or not preset or preset == "" then break end
        presets[#presets + 1] = {
          title = wgt.data.title .. " - Preset" .. tostring(#presets + 1),
          preset = preset
        }
        i = i + 1
      end
    end

    -- Clear existing presets for this scheme if overwrite enabled
    if GetPreviousValue("opt_overwrite", false) == "true" then
      local num_presets = #wgt.preset.presets
      for i = 1, num_presets do
        local preset_title = wgt.data.title .. " - Preset" .. tostring(i)
        if HasValue(preset_title) then
          DeleteCurrentValue(preset_title)
        end
      end
      wgt.preset.presets = {}
    end

    -- Import presets
    for _, preset in ipairs(presets) do
      StorePreset(preset.title, nil, nil, preset.preset)
    end
    acendan.msg(tostring(#presets) .. " preset(s) imported from " .. tostring(#wgt.dragdrop) .. " files!",
      "The Last Renamer")
  end, "Imports presets from ini file(s) drag-dropped below. Only imports presets for the active scheme.")

  -- Overwrite On Import checkbox
  reaper.ImGui_SameLine(ctx)
  local overwrite = GetPreviousValue("opt_overwrite", false)
  local rv, overwrite = reaper.ImGui_Checkbox(ctx, "Overwrite?", overwrite == "true" and true or false)
  if rv then SetCurrentValue("opt_overwrite", overwrite) end
  acendan.ImGui_Tooltip(
    "If unchecked, imported presets will be added to existing ones. If checked, will erase pre-existing presets on import.\n\nIf you enable this, back up existing ones with the Export button first!")

  -- Drag drop box for ini files
  if reaper.ImGui_BeginChild(ctx, '##drop_files', 300, 50, reaper.ImGui_ChildFlags_FrameStyle()) then
    if #wgt.dragdrop == 0 then
      reaper.ImGui_Text(ctx, 'Drag-drop preset file(s) to import...')
    else
      reaper.ImGui_Text(ctx, ('Ready to import %d file(s):'):format(#wgt.dragdrop))
      reaper.ImGui_SameLine(ctx)
      if reaper.ImGui_SmallButton(ctx, 'Clear') then
        wgt.dragdrop = {}
      end
    end
    for _, file in ipairs(wgt.dragdrop) do
      reaper.ImGui_Bullet(ctx)
      reaper.ImGui_TextWrapped(ctx, file:match('[^/\\]+$'))
    end
    reaper.ImGui_EndChild(ctx)
  end

  -- Drag drop handler
  if reaper.ImGui_BeginDragDropTarget(ctx) then
    local rv, count = reaper.ImGui_AcceptDragDropPayloadFiles(ctx)
    if rv then
      wgt.dragdrop = {}
      for i = 0, count - 1 do
        local filename
        rv, filename = reaper.ImGui_GetDragDropPayloadFile(ctx, i)
        if rv and filename:match("%.ini$") then
          table.insert(wgt.dragdrop, filename)
        end
      end
    end
    reaper.ImGui_EndDragDropTarget(ctx)
  end
end

function Main()
  if wgt.set_font then
    acendan.ImGui_SetFont(); wgt.set_font = false
  end
  acendan.ImGui_PushStyles()

  local rv, open = reaper.ImGui_Begin(ctx, SCRIPT_NAME, true, WINDOW_FLAGS)
  if not rv then return open end

  if reaper.ImGui_BeginTabBar(ctx, "TabBar") then
    TabItem("Naming", TabNaming)
    TabItem("Metadata", TabMetadata, "opt_enable_meta")
    TabItem("Settings", TabSettings)

    -- Documentation link button
    if reaper.ImGui_TabItemButton(ctx, '?', reaper.ImGui_TabItemFlags_Trailing() | reaper.ImGui_TabItemFlags_NoTooltip()) then
      reaper.CF_ShellExecute("https://github.com/acendan/reascripts/wiki/The-Last-Renamer")
    end

    reaper.ImGui_EndTabBar(ctx)
  end

  -- If esc pressed, close window
  if reaper.ImGui_IsKeyDown(ctx, reaper.ImGui_Key_Escape()) and not reaper.ImGui_IsPopupOpen(ctx, "", reaper.ImGui_PopupFlags_AnyPopupId()) then open = false end

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
  if SCHEMES_DIR ~= nil then
    local file_idx = 0
    repeat
      schemes[#schemes + 1] = reaper.EnumerateFiles(SCHEMES_DIR, file_idx)
      file_idx = file_idx + 1
    until not reaper.EnumerateFiles(SCHEMES_DIR, file_idx)
  else
    acendan.msg("Schemes directory not found: " .. SCHEMES_DIR)
    return schemes
  end
  local shared_schemes_table = GetSharedSchemes()
  for _, shared_scheme in ipairs(shared_schemes_table) do
    local shared_scheme_name = shared_scheme:match("[^/\\]+$")
    schemes[#schemes + 1] = "Shared: " .. shared_scheme_name
  end
  if #schemes == 0 then
    acendan.msg("No schemes found in: " .. SCHEMES_DIR)
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

  -- Clear presets if scheme has changed
  wgt.preset.presets = nil
  RecallPresets()

  -- Clear histories if scheme has changed
  wgt.history.presets = nil
  RecallHistories()

  -- Clear on load if setting is enabled
  if GetPreviousValue("opt_auto_clear", false) == "true" then ClearFields(wgt.data.fields) end
  return true
end

function ValidateScheme(scheme)
  if not scheme then return nil end
  local scheme_path = ""
  if scheme:find("Shared: ") then
    -- Load shared scheme
    local shared_schemes_table = GetSharedSchemes()
    for _, shared_scheme in ipairs(shared_schemes_table) do
      local shared_scheme_name = shared_scheme:match("[^/\\]+$")
      if scheme:find(shared_scheme_name) then
        scheme_path = shared_scheme
        break
      end
    end
  else
    -- Load scheme from schemes directory
    scheme_path = SCHEMES_DIR .. scheme
  end
  local status, result = pcall(acendan.loadYaml, scheme_path)
  if not status then
    acendan.msg("Error loading scheme: " .. scheme .. "\n\n" .. tostring(result), "The Last Renamer"); return nil
  end
  return result
end

function ValidateMeta()
  if wgt.meta then return true end
  local status, result = pcall(acendan.loadYaml, META_DIR .. "meta.yaml")
  if not status then
    reaper.ImGui_TextColored(ctx, 0xFF0000FF, "Error loading metadata!\n\n" .. tostring(result))
    return false
  end
  wgt.meta = result
  wgt.meta.serialize = {}
  RecallSettings("Metadata", wgt.meta.fields, wgt.meta.serialize)
  return true
end

function GetPreviousValue(key, default)
  return HasValue(key) and reaper.GetExtState(SCRIPT_NAME, key) or default
end

function SetCurrentValue(key, value)
  reaper.SetExtState(SCRIPT_NAME, key, tostring(value), true)
end

function DeleteCurrentValue(key)
  reaper.DeleteExtState(SCRIPT_NAME, key, true)
end

function HasValue(key)
  return reaper.HasExtState(SCRIPT_NAME, key)
end

function StoreSettings(title, serialize)
  title = title or wgt.data.title
  serialize = serialize or wgt.serialize
  for i = 1, #serialize do
    local field, value = table.unpack(serialize[i])
    SetCurrentValue(title .. " - " .. field, value)
  end
end

function RecallSettings(title, fields, serialize)
  serialize = serialize or wgt.serialize
  for i, field in ipairs(fields) do
    local prev = GetPreviousValue(title .. " - " .. field.field, nil)
    if prev then SetFieldValue(field, prev) end
    if field.fields then RecallSettings(title, field.fields) end
  end
  serialize = {}
end

function GetFieldValue(field, short)
  -- For dropdowns, `short = false` will use fully qualified value rather than abbr
  short = short == nil or short
  if type(field.value) == "table" then
    if field.selected then
      if field.short and short then
        return field.short[field.selected]
      else
        return field.value[field.selected]
      end
    end
  else
    return tostring(field.value)
  end
  return ""
end

function SetFieldValue(field, value)
  -- Dropdowns
  if type(field.value) == "table" then
    field.selected = tonumber(value)
    if field.filter then reaper.ImGui_TextFilter_Set(field.filter, field.value[field.selected]) end

    -- Enumeration
  elseif type(field.value) == "number" then
    if type(value) == "number" then
      field.value = tonumber(value)
    elseif value == "$num" then
      field.numwild = true
      field.value = value
    end

    -- Dropdowns
  elseif type(field.value) == "boolean" then
    field.value = value == "true" and true or false

    -- Text
  elseif type(field.value) == "string" then
    field.value = value
  end
end

function StoreHistory()
  -- Remove anything after max history
  local prefix = "History"
  local i = 1
  local max = tonumber(GetPreviousValue("opt_num_hist", 10))
  local history = {}
  while true do
    local prev = GetPreviousValue(wgt.data.title .. " - " .. prefix .. i, nil)
    if not prev then break end
    if i >= max then
      DeleteCurrentValue(wgt.data.title .. " - " .. prefix .. i)
    else
      history[#history + 1] = prev
    end
    i = i + 1
  end

  -- Move all previous history back a slot
  for i, hist in ipairs(history) do
    SetCurrentValue(wgt.data.title .. " - " .. prefix .. tostring(i + 1), hist)
  end
  DeleteCurrentValue(wgt.data.title .. " - " .. prefix .. "1")

  -- Store current settings in first slot
  StorePreset(wgt.name, prefix, wgt.history)

  -- Refresh history
  wgt.history.presets = nil
  RecallHistories()
end

function StorePreset(preset, prefix, settings, preserialized)
  prefix = prefix or "Preset"
  settings = settings or wgt.preset
  local function SerializeFields(fields)
    for _, field in ipairs(fields) do
      local name = tostring(field.field)

      -- Append id(s) to name
      if field.id ~= nil then
        if type(field.id) == "table" then
          for _, id in ipairs(field.id) do
            name = name .. ":" .. acendan.encapsulate(tostring(id))
          end
        else
          name = name .. ":" .. acendan.encapsulate(tostring(field.id))
        end
      end

      -- Append to preset buffer
      if type(field.value) == "table" then
        if field.selected then
          settings.buf = settings.buf .. name .. "=" .. acendan.encapsulate(tostring(field.selected)) .. "||"
        end
      else
        local valstr = tostring(field.value)
        if valstr ~= "" then
          settings.buf = settings.buf .. name .. "=" .. acendan.encapsulate(tostring(field.value)) .. "||"
        end
      end

      -- Recurse through nested fields
      if field.fields then
        SerializeFields(field.fields)
      end
    end
  end

  -- Store preset in next available slot for this scheme
  local i = 1
  while true do
    local prev = GetPreviousValue(wgt.data.title .. " - " .. prefix .. i, nil)
    if not prev then
      if preserialized then
        settings.buf = preserialized
      else
        settings.buf = prefix:lower() .. "=" .. preset .. "||"
        SerializeFields(wgt.data.fields)
      end
      SetCurrentValue(wgt.data.title .. " - " .. prefix .. i, settings.buf)
      break
    end
    i = i + 1
  end

  -- Append to presets table
  settings.presets[#settings.presets + 1] = RecallPreset(#settings.presets + 1, prefix)
end

function RecallPresets(prefix, settings)
  -- Load all presets for this scheme
  prefix = prefix or "Preset"
  settings = settings or wgt.preset
  if settings.presets then return end
  settings.presets = {}
  local i = 1
  while true do
    local preset = GetPreviousValue(wgt.data.title .. " - " .. prefix .. i, nil)
    if not preset then break end
    settings.presets[#settings.presets + 1] = RecallPreset(i, prefix)
    i = i + 1
  end
end

function RecallHistories()
  -- Load all histories for this scheme
  if wgt.history.presets then return end
  wgt.history.presets = {}
  local prefix = "History"
  local i = 1
  while true do
    local history = GetPreviousValue(wgt.data.title .. " - " .. prefix .. i, nil)
    if not history then break end
    wgt.history.presets[#wgt.history.presets + 1] = RecallPreset(i, prefix)
    i = i + 1
  end
end

function RecallPreset(idx, prefix)
  local function DeserializePreset(preset)
    local fields = {}
    for field, value in preset:gmatch('([^=]+)=([^|]+)||') do
      -- Serialization has to handle strings that may or may not be encapsulated
      fields[acendan.uncapsulate(field)] = acendan.uncapsulate(value)
    end
    return fields
  end

  local preset = GetPreviousValue(wgt.data.title .. " - " .. prefix .. idx, nil)
  if not preset then return nil end
  return DeserializePreset(preset)
end

function DeletePreset(idx, prefix)
  prefix = prefix or "Preset"
  DeleteCurrentValue(wgt.data.title .. " - " .. prefix .. idx)
  wgt.preset.presets[idx] = nil
  -- Shift all presets down by one
  local i = idx + 1
  while true do
    local preset = GetPreviousValue(wgt.data.title .. " - " .. prefix .. i, nil)
    if not preset then break end
    SetCurrentValue(wgt.data.title .. " - " .. prefix .. i - 1, preset)
    wgt.preset.presets[i - 1] = wgt.preset.presets[i]
    i = i + 1
  end
  -- Delete the last one
  DeleteCurrentValue(wgt.data.title .. " - " .. prefix .. i - 1)
  wgt.preset.presets[i - 1] = nil
end

function Capitalize(str, capitalization)
  local lowstr = str:lower()
  if lowstr == "$name" or lowstr == "$enum" then return lowstr end
  if not capitalization or capitalization == "" then return str end
  
  local caps = capitalization:lower() -- oh the irony of case sensitive :find()
  if caps:find("title") then
    return str:gsub("(%a)([%w_']*)", function(first, rest) return first:upper() .. rest:lower() end)
  elseif caps:find("pascal") then
    return str:gsub("(%a)([%w_']*)", function(first, rest) return first:upper() .. rest end):gsub(" ", "")
  elseif caps:find("up") then
    return str:upper()
  elseif caps:find("low") then
    return str:lower()
  else
    return str
  end
end

-- Get shared schemes table
function GetSharedSchemes()
  local shared_schemes = GetPreviousValue("shared_schemes", "")
  local shared_schemes_table = {}
  for shared_scheme in shared_schemes:gmatch("[^;]+") do
    shared_schemes_table[#shared_schemes_table + 1] = shared_scheme
  end
  return shared_schemes_table
end

-- Remove existing entry and append new one to serialize table
function AppendSerializedField(serialize, field, value)
  for i, entry in ipairs(serialize) do
    if entry[1] == field then
      table.remove(serialize, i)
      break
    end
  end
  serialize[#serialize + 1] = { field, value }
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
    acendan.ImGui_Tooltip(help)
  end
end

function TabItem(name, tab, setting)
  -- If present, setting can be used to toggle visibility of tab
  if setting and GetPreviousValue(setting, false) ~= "true" then return end
  if reaper.ImGui_BeginTabItem(ctx, name) then
    tab()
    reaper.ImGui_EndTabItem(ctx)
  end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~ RENAMING ~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
function ApplyName()
  reaper.Undo_BeginBlock()
  wgt.error = Rename(wgt.target, wgt.mode, wgt.name, wgt.enumeration)
  reaper.Undo_EndBlock("The Last Renamer - " .. wgt.data.title, -1)
  StoreSettings()
  StoreHistory()
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
  if not target or not mode then
    return "Missing renaming target!"
  elseif not name then
    return "Attempting rename with empty name!"
  elseif not enumeration then
    if FindField(wgt.data.fields, "Enumeration") then
      return "Missing enumeration!"
    else
      -- Scheme doesn't define enumeration settings, provide a dummy fallback
      enumeration = {
        start = 1,
        zeroes = 1,
        singles = false,
        wildcard = "$enum",
        sep = wgt.data.separator
      }
    end
  end

  if target == "Regions" then
    local _, num_markers, num_regions = reaper.CountProjectMarkers(0)
    if num_regions > 0 then
      return ProcessRegions(mode, num_markers + num_regions, name, enumeration)
    end
  elseif target == "Items" then
    local num_items = reaper.CountMediaItems(0)
    if num_items > 0 then
      return ProcessItems(mode, num_items, name, enumeration)
    end
  elseif target == "Tracks" then
    local num_tracks = reaper.CountTracks(0)
    if num_tracks > 0 then
      return ProcessTracks(mode, num_tracks, name, enumeration)
    end
  end

  return "Project has no " .. target .. " to rename!"
end

function SanitizeName(name, enumeration, wildcards, skipincrement)
  -- Uses enumeration struct to generate string substitution for enumeration
  local function GetEnumeration(enumeration)
    if not enumeration or (enumeration.num == 1 and not enumeration.singles) then
      return ""
    elseif type(enumeration.start) == "string" then
      return enumeration.sep
    end
    local num_str = PadZeroes(enumeration.start, enumeration.zeroes)
    if not skipincrement then
      enumeration.start = enumeration.start + 1
    end
    return enumeration.sep .. num_str
  end

  -- Resolve wildcards
  local wild = name
  for _, wildcard in ipairs(wildcards) do
    wild = wild:gsub(wildcard.find, wildcard.replace)
  end

  -- Resolve enumeration
  if enumeration then
    wild = wild:gsub(enumeration.sep .. enumeration.wildcard, GetEnumeration(enumeration))
  end

  -- Strip illegal characters and leading/trailing spaces
  local stripped = wild:match("^%s*(.-)%s*$")
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

function ProcessRegions(mode, num_mkrs_rgns, name, enumeration, meta)
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
    if meta then return queue end

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

function ProcessItems(mode, num_items, name, enumeration, meta)
  local error = nil
  local queue = {}
  local ini_sel_items = {}

  if mode == "Selected" then
    -- Target NVK folder items (deselect others)
    if GetPreviousValue("opt_nvk_only", false) == "true" then
      acendan.saveSelectedItems(ini_sel_items)
      for _, item in ipairs(ini_sel_items) do
        if not acendan.isFolderItem(item) or not acendan.isTopLevelFolderItem(item, ini_sel_items) then
          reaper.SetMediaItemSelected(item, false)
        end
      end

      -- If no folder items still selected, revert to initial selection
      if reaper.CountSelectedMediaItems(0) == 0 then
        acendan.restoreSelectedItems(ini_sel_items)
        ini_sel_items = {}
      end
    end

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
          queue[#queue + 1] = { item, take, wildcards, item_start, item_end, item_num }
        end
      end
    else
      error = "No items selected!"
    end

    -- Restore items (if deselected in NVK mode)
    if #ini_sel_items > 0 then acendan.restoreSelectedItems(ini_sel_items) end

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
        queue[#queue + 1] = { item, take, wildcards, item_start, item_end, item_num }
      end
    end
  end

  -- Process queue
  if #queue > 0 then
    if meta then return queue end

    enumeration.num = #queue
    for _, item_data in ipairs(queue) do
      local item, take, wildcards, item_start, item_end, item_num = table.unpack(item_data)

      -- Handle overlaps if the option is enabled
      if wgt.overlap then
        local track = reaper.GetMediaItem_Track(item)
        local track_num_items = reaper.CountTrackMediaItems( track )
        local has_overlap = false
        if track_num_items > 0 then
          for i=0, track_num_items - 1 do
            local track_item = reaper.GetTrackMediaItem( track, i )
            if item ~= track_item then
              -- If this item overlaps with an earlier one (on its left side), only start incrementing after the rightmost item in this overlap chain
              local track_item_start = reaper.GetMediaItemInfo_Value( track_item, "D_POSITION" )
              local track_item_end = track_item_start + reaper.GetMediaItemInfo_Value( track_item, "D_LENGTH" )
              has_overlap = item_start < track_item_end and item_end > track_item_start
              if has_overlap then break end
            elseif i == 0 then
              -- If the current item is the first one in the track, then toggle the flag to prevent incrementing
              has_overlap = true
              break
            end
          end
        end
        if not has_overlap then
          enumeration.start = enumeration.start + 1
        end
      end

      -- Rename item
      local new_name = SanitizeName(name, enumeration, wildcards, wgt.overlap) -- Skip incrementing the enumeration if overlaps are enabled
      reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", new_name, true)
    end
  else
    error = "No items to rename (" .. mode .. ")!"
  end

  return error
end

function ProcessTracks(mode, num_tracks, name, enumeration)
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
-- ~~~~~~~~~~~~~~ META ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function ApplyMetadata()
  wgt.meta.error = nil

  local marker = GenerateMetadataMarker()
  if not marker or marker == "" then
    wgt.meta.error = "No metadata to apply!"
    return
  end

  StoreSettings("Metadata", wgt.meta.serialize)

  reaper.Undo_BeginBlock()

  if wgt.target == "Regions" then
    local _, num_markers, num_regions = reaper.CountProjectMarkers(0)
    if num_regions > 0 then
      local queue = ProcessRegions(wgt.mode, num_markers + num_regions, nil, nil, true)
      if type(queue) == "table" then
        for _, rgn in ipairs(queue) do
          local _, _, rgnend, _, idx, _ = table.unpack(rgn)
          SetMetadataMarker(marker, rgnend, idx)
        end
      else
        wgt.meta.error = queue
      end
    else
      wgt.meta.error = "No regions to apply metadata to!"
    end
  elseif wgt.target == "Items" then
    local num_items = reaper.CountMediaItems(0)
    if num_items > 0 then
      local queue = ProcessItems(wgt.mode, num_items, nil, nil, true)
      if type(queue) == "table" then
        for _, item in ipairs(queue) do
          local _, _, _, _, item_end, item_num = table.unpack(item)
          SetMetadataMarker(marker, item_end, item_num)
        end
      else
        wgt.meta.error = queue
      end
    else
      wgt.meta.error = "No items to apply metadata to!"
    end
  end

  reaper.Undo_EndBlock("The Last Renamer - Metadata", -1)
end

function GenerateMetadataMarker()
  local function SetRenderMetadata(marker, meta, key, val)
    if val == "" then return marker end
    for _, metaspec in ipairs(meta) do
      reaper.GetSetProjectInfo_String( 0, "RENDER_METADATA", metaspec .. "|$marker(" .. key .. ")[;]", true )
    end
    return marker .. key .. "=" .. tostring(val) .. ";"
  end

  -- Function to recursively iterate through meta fields and generate a marker string
  local function GenerateMarkerString(fields, marker, parent)
    for _, field in ipairs(fields) do
      if field.value and PassesIDCheck(field, parent) and not field.skip then
        marker = SetRenderMetadata(marker, field.meta, field.field,  GetFieldValue(field))
      end
      if field.fields then
        marker = GenerateMarkerString(field.fields, marker, field)
      end
    end
    return marker
  end

  -- Resolve meta references that use data from naming tab
  local function ResolveMetaRefs(fields, marker, refs)
    if not fields or not refs then return marker end
    for _, field in ipairs(fields) do
      if type(field.id) == "table" then
        -- If ID is an array, resolve each one
        for _, id in ipairs(field.id) do
          local find_field = FindField(refs, id)
          if find_field then
            marker = SetRenderMetadata(marker, field.meta, field.field,  GetFieldValue(find_field, field.short))
          end
        end
      else
        -- If ID is something like "Subcategory:Category", resolve it
        local field_name = field.id:match("([^:]+)")
        for id in field.id:gmatch(":(%w+)") do        
          local find_field = FindField(refs, id)
          if find_field then
            field_name = field_name .. ":" .. GetFieldValue(find_field, field.short)
          end
        end

        -- Resolve the field
        local find_field = FindField(refs, field_name)
        if find_field then
          marker = SetRenderMetadata(marker, field.meta, field.field,  GetFieldValue(find_field, field.short))
        end
      end
    end
    return marker
  end

  -- Hard-codes metadata fields into the settings menu
  local function ApplyHardCodedFields(hardcoded)
    if not hardcoded then return end
    for _, field in ipairs(hardcoded) do
      if field.hard then
        for _, metaspec in ipairs(field.meta) do
          reaper.GetSetProjectInfo_String( 0, "RENDER_METADATA", metaspec .. "|" .. field.hard, true )
        end
      end
    end
  end

  local marker = META_MKR_PREFIX .. ";"
  marker = GenerateMarkerString(wgt.meta.fields, marker, nil)
  marker = ResolveMetaRefs(wgt.meta.refs, marker, wgt.data and wgt.data.fields or nil)
  ApplyHardCodedFields(wgt.meta.hardcoded)
  return marker
end

function SetMetadataMarker(marker, pos, num)
  acendan.deleteProjectMarkers(false, pos, META_MKR_PREFIX)                             -- Delete existing meta markers at position
  reaper.AddProjectMarker(0, false, pos, 0, marker, num and num or -1)                  -- Actual meta marker
  reaper.AddProjectMarker(0, false, pos + 0.001, 0, META_MKR_PREFIX, num and num or -1) -- Second marker slightly after to hide the name of the first
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Init()
Main()
