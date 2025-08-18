-- @description ACendan Lua Utilities
-- @author Aaron Cendan
-- @version 9.23
-- @metapackage
-- @provides
--   [main] .
--   Lib/*.{lua}
-- @link https://ko-fi.com/acendan_
-- @about
--   # Lua Utilities
-- @changelog
--   # Fixed up various ImGui issues for compatibility with 0.10.0.1 release

--[[
local acendan_LuaUtils = reaper.GetResourcePath()..'/Scripts/ACendan Scripts/Development/acendan_Lua Utilities.lua'
if reaper.file_exists(acendan_LuaUtils) then dofile(acendan_LuaUtils); if not acendan or acendan.version() < 8.0 then acendan.msg('This script requires a newer version of ACendan Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"ACendan Lua Utilities"); return end else reaper.ShowConsoleMsg("This script requires ACendan Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'ACendan Lua Utilities'"); return end
local VSDEBUG = os.getenv("VSCODE_DBG_UUID") == "df3e118e-8874-49f7-ab62-ceb166401fb9" and dofile('C:/Users/Aaron/.vscode/extensions/antoinebalaine.reascript-docs-0.1.7/debugger/LoadDebug.lua') or nil

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~ USER CONFIG - EDIT ME ~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ CONSTANTS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

local WIN, SEP = acendan.getOS()
local SCRIPT_NAME = ({ reaper.get_action_context() })[2]:match("([^/\\_]+)%.lua$")
local SCRIPT_DIR = ({ reaper.get_action_context() })[2]:sub(1, ({ reaper.get_action_context() })[2]:find(SEP .. "[^" .. SEP .. "]*$"))


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function main()

end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ UTILITIES ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()
main()
reaper.Undo_EndBlock(SCRIPT_NAME,-1)
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~ BACKGROUND SCRIPT ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ CONSTANTS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

local SCRIPT_NAME = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local SCRIPT_DIR = ({reaper.get_action_context()})[2]:sub(1,({reaper.get_action_context()})[2]:find("\\[^\\]*$"))

local REFRESH_RATE = 0.3
local _, _, SECTION, CMD_ID = reaper.get_action_context()


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function setup()
  local start = reaper.time_precise()
  check_time = start
  
  reaper.SetToggleCommandState( SECTION, CMD_ID, 1 )
  reaper.RefreshToolbar2( SECTION, CMD_ID )
end

function main()
  local now = reaper.time_precise()
  if now - check_time >= REFRESH_RATE then

    -- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    -- THIS IS WHERE YOU DO ALL OF THE ACTUAL CODE THINGS, ONCE EVERY REFRESH
    -- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    
    check_time = now
  end

  reaper.defer(main)
end

function exit()
  reaper.UpdateArrange()
  reaper.SetToggleCommandState( SECTION, CMD_ID, 0 )
  reaper.RefreshToolbar2( SECTION, CMD_ID )
  return reaper.defer(function() end)
end


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ UTILITIES ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

setup()
reaper.atexit(exit)
main()

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~ IMGUI TEMPLATE  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ CONSTANTS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

local SCRIPT_NAME = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local SCRIPT_DIR = ({reaper.get_action_context()})[2]:sub(1,({reaper.get_action_context()})[2]:find("\\[^\\]*$"))

local WINDOW_SIZE = { width = 300, height = 130 }
local WINDOW_FLAGS = reaper.ImGui_WindowFlags_NoCollapse()


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function init()
  ctx = reaper.ImGui_CreateContext(SCRIPT_NAME, reaper.ImGui_ConfigFlags_DockingEnable())
  reaper.ImGui_SetNextWindowSize(ctx, WINDOW_SIZE.width, WINDOW_SIZE.height)
  
  wgt = {
    
  }
end

function main()
  acendan.ImGui_PushStyles()
  local rv, open = reaper.ImGui_Begin(ctx, SCRIPT_NAME, true, WINDOW_FLAGS)
  if not rv then return open end
  
  
  
  reaper.ImGui_End(ctx)
  acendan.ImGui_PopStyles()
  if open then reaper.defer(main) else return end
end


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ UTILITIES ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
init()
main()


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

]]--

acendan = {}

function acendan.version()
  local file = io.open((reaper.GetResourcePath()..'/Scripts/ACendan Scripts/Development/acendan_Lua Utilities.lua'):gsub('\\','/'),"r")
  local vers_header = "-- @version "
  io.input(file)
  local t = 0
  for line in io.lines() do
    if line:find(vers_header) then
      t = line:gsub(vers_header,"")
      break
    end
  end
  io.close(file)
  return tonumber(t)
end

--[[
-- Check Reaper version
local reaper_version = tonumber(reaper.GetAppVersion():match("%d+%.%d+"))
local something = (reaper_version >= 6.33) and true or false

]]--

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~ DEBUG & MESSAGES ~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Deliver messages and add new line in console
function acendan.dbg(...)
  local args = {...}
  local str = ""
  for i = 1, #args do
    if type(args[i]) == "table" then
      str = str .. "[" .. table.concat(args[i], ", ") .. "]" .. "\n"
    else
      str = str .. tostring(args[i]) .. "\t"
    end
  end
  reaper.ShowConsoleMsg(str .. "\n")
end

-- Deliver messages using message box
function acendan.msg(msg, title)
  local title = title or "ACendan Info"
  reaper.MB(tostring(msg), title, 0)
end

-- Rets to bools // returns Boolean
function acendan.retToBool(ret)
  if ret == 1 then return true else return false end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~ GET USER INPUT ~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--[[
-- Single field
local ret_input, user_input = reaper.GetUserInputs( script_name, 1, "Input Field", "Placeholder" )
if not ret_input then return end

-- Multiple fields
local ret_input, user_input = reaper.GetUserInputs( script_name, 2,
                          "Input Field 1,Input Field 2" .. ",extrawidth=100",
                          "Placeholder 1,Placeholder 2" )
if not ret_input then return end
local input_1, input_2 = user_input:match("([^,]+),([^,]+)")
]]--


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~ IMGUI ~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
acendan.ImGui_Styles = {}
acendan.ImGui_Styles.colors = {
  { reaper.ImGui_Col_DragDropTarget, 0xCDA4DEFF },
  { reaper.ImGui_Col_FrameBg, 0x72727224 },
  { reaper.ImGui_Col_FrameBgHovered, 0x80808064 },
  { reaper.ImGui_Col_FrameBgActive, 0x80808080 },
  { reaper.ImGui_Col_CheckMark, 0xCDA4DEFF },
  { reaper.ImGui_Col_TitleBg, 0xB19CD932 },
  { reaper.ImGui_Col_TitleBgCollapsed, 0xB19CD932 },
  { reaper.ImGui_Col_TitleBgActive, 0x5A3F78CC },
  { reaper.ImGui_Col_Button, 0x60606066 },
  { reaper.ImGui_Col_ButtonHovered, 0x606060FF },
  { reaper.ImGui_Col_ButtonActive, 0x808080FF },
  { reaper.ImGui_Col_Text, 0xFFFFFFDE }, -- Google material recommended text color
  { reaper.ImGui_Col_TextDisabled, 0xFFFFFF61 }, -- Google material recommended text color
  { reaper.ImGui_Col_TextSelectedBg, 0xD8BFD864 },
  { reaper.ImGui_Col_ResizeGrip, 0x80808000 },
  { reaper.ImGui_Col_ResizeGripHovered, 0x80808000 },
  { reaper.ImGui_Col_ResizeGripActive, 0x80808000 },
  { reaper.ImGui_Col_Separator, 0x80808080 },
  { reaper.ImGui_Col_SeparatorHovered, 0x808080C7 },
  { reaper.ImGui_Col_SeparatorActive, 0x808080FF },
  { reaper.ImGui_Col_Tab, 0x60606066 },
  { reaper.ImGui_Col_TabHovered, 0x606060FF },
  { reaper.ImGui_Col_TabSelected, 0x6C6C6CFF },
  { reaper.ImGui_Col_WindowBg, 0x181818FF },
  { reaper.ImGui_Col_PopupBg, 0x181818F0 },
  { reaper.ImGui_Col_ScrollbarBg, 0x18181887 },
  { reaper.ImGui_Col_Header, 0x60606066 },
  { reaper.ImGui_Col_HeaderHovered, 0x606060FF },
  { reaper.ImGui_Col_HeaderActive, 0x808080FF },
  { reaper.ImGui_Col_TableRowBg, 0xFFFFFF00 },
  { reaper.ImGui_Col_TableRowBgAlt, 0xFFFFFF04 },
  { reaper.ImGui_Col_SliderGrab, 0xCDA4DEC8 },
  { reaper.ImGui_Col_SliderGrabActive, 0xD8BFD4DD },
  { reaper.ImGui_Col_PlotLines, 0xB19CD9FF },
  { reaper.ImGui_Col_PlotLinesHovered, 0xB19CD9FF },
  { reaper.ImGui_Col_PlotHistogram, 0xB19CD932 },
  { reaper.ImGui_Col_PlotHistogramHovered, 0xB19CD932 },
  { reaper.ImGui_Col_DockingPreview, 1123734963 },
  { reaper.ImGui_Col_TabDimmed, 640034552 },
  { reaper.ImGui_Col_TabDimmedSelected, 1819045119 },
  { reaper.ImGui_Col_Border, -2139062144 },
  { reaper.ImGui_Col_TableBorderLight, 993737727 },
  { reaper.ImGui_Col_TableBorderStrong, 1330597887 },
  { reaper.ImGui_Col_TableHeaderBg, 858993663 },
}
acendan.ImGui_Styles.vars = {
  { reaper.ImGui_StyleVar_Alpha(), 1.0 },
  { reaper.ImGui_StyleVar_DisabledAlpha(), 0.6 },
  { reaper.ImGui_StyleVar_WindowPadding(), { 8, 4 } },
  { reaper.ImGui_StyleVar_FramePadding(), { 4, 3 } },
  { reaper.ImGui_StyleVar_CellPadding(), { 4, 4 } },
  { reaper.ImGui_StyleVar_ItemSpacing(), { 4, 4 } },
  { reaper.ImGui_StyleVar_ItemInnerSpacing(), { 4, 4 } },
  { reaper.ImGui_StyleVar_IndentSpacing(), 21 },
  { reaper.ImGui_StyleVar_ScrollbarSize(), 14 },
  { reaper.ImGui_StyleVar_GrabMinSize(), 12 },
  { reaper.ImGui_StyleVar_WindowBorderSize(), 1 },
  { reaper.ImGui_StyleVar_ChildBorderSize(), 1 },
  { reaper.ImGui_StyleVar_PopupBorderSize(), 1 },
  { reaper.ImGui_StyleVar_FrameBorderSize(), 0 },
  { reaper.ImGui_StyleVar_WindowRounding(), 8 },
  { reaper.ImGui_StyleVar_ChildRounding(), 0 },
  { reaper.ImGui_StyleVar_FrameRounding(), 2 },
  { reaper.ImGui_StyleVar_PopupRounding(), 4 },
  { reaper.ImGui_StyleVar_ScrollbarRounding(), 4 },
  { reaper.ImGui_StyleVar_GrabRounding(), 2 },
  { reaper.ImGui_StyleVar_TabRounding(), 2 },
  { reaper.ImGui_StyleVar_WindowTitleAlign(), { 0.5, 0.5 } },
  { reaper.ImGui_StyleVar_ButtonTextAlign(), { 0.5, 0.5 } },
  { reaper.ImGui_StyleVar_SelectableTextAlign(), { 0, 0.5 } },
}
acendan.ImGui_Styles.scalable = {
  reaper.ImGui_StyleVar_WindowPadding(),
  reaper.ImGui_StyleVar_FramePadding(),
  reaper.ImGui_StyleVar_CellPadding(),
  reaper.ImGui_StyleVar_ItemSpacing(),
  reaper.ImGui_StyleVar_ItemInnerSpacing(),
  reaper.ImGui_StyleVar_IndentSpacing(),
  reaper.ImGui_StyleVar_ScrollbarSize(),
  reaper.ImGui_StyleVar_GrabMinSize(),
}
acendan.ImGui_Styles.font = nil

-- @NVK
-- Hacky stuff for autocomplete windows, adding this in the hopes that if this function gets added to the API, it won't break anything
if not reaper.ImGui_WindowFlags_ChildWindow then
  reaper.ImGui_WindowFlags_ChildWindow = function() return 1 << 24 end
end
acendan.ImGui_AutoFillComboFlags = reaper.ImGui_WindowFlags_ChildWindow() | reaper.ImGui_WindowFlags_NoMove()

function acendan.ImGui_SetFont(font_name, font_size)
  font_name = font_name or "Arial"
  font_size = math.floor((font_size or 14) * acendan.ImGui_GetScale())
  if acendan.ImGui_Styles.font then reaper.ImGui_Detach(ctx, acendan.ImGui_Styles.font) end
  acendan.ImGui_Styles.font = reaper.ImGui_CreateFont(font_name, font_size)
  reaper.ImGui_Attach(ctx, acendan.ImGui_Styles.font)
end

function acendan.ImGui_GetScale()
  return acendan.ImGui_GetSetting("ui_scale", 1.0)
end

function acendan.ImGui_SetScale(scale)
  acendan.ImGui_SetSetting("ui_scale", scale or acendan.ImGui_GetScale())
end

function acendan.ImGui_ScaleSlider(flags)
  local scale = acendan.ImGui_GetSetting("ui_scale", 1.0)
  local rv, scale = reaper.ImGui_SliderDouble(ctx, "UI Scale", scale, 0.5, 2.0, "%.2f", flags or reaper.ImGui_SliderFlags_AlwaysClamp())
  if rv then 
    acendan.ImGui_SetSetting("ui_scale", scale)
    return true
  end
  acendan.ImGui_Tooltip("Adjust the scale of the GUI elements.\n\nCtrl+Click to type in values.")
  return false
end

function acendan.ImGui_PushStyles()
  local scale = acendan.ImGui_GetSetting("ui_scale", 1.0)
  for idx, value in ipairs(acendan.ImGui_Styles.colors) do
    if value[1] then
      reaper.ImGui_PushStyleColor(ctx, value[1](), value[2])
    else
      acendan.dbg("ImGui style color has been removed at acendan.ImGui_Styles.colors index:" .. idx)
    end
  end
  for _, value in ipairs(acendan.ImGui_Styles.vars) do
    local style_var = value[1]
    local style_val = value[2]
    local is_table = type(style_val) == "table"

    if acendan.tableContainsVal(acendan.ImGui_Styles.scalable, style_var) then
      if is_table then
        style_val = { style_val[1] * scale, style_val[2] * scale }
      else
        style_val = style_val * scale
      end
    end

    if is_table then
      reaper.ImGui_PushStyleVar(ctx, style_var, style_val[1], style_val[2])
    else
      reaper.ImGui_PushStyleVar(ctx, style_var, style_val)
    end
  end
  reaper.ImGui_PushFont(ctx, acendan.ImGui_Styles.font, reaper.ImGui_GetFontSize(ctx))
end

function acendan.ImGui_PopStyles()
  reaper.ImGui_PopStyleColor(ctx, #acendan.ImGui_Styles.colors)  
  reaper.ImGui_PopStyleVar(ctx, #acendan.ImGui_Styles.vars)
  reaper.ImGui_PopFont(ctx)
end

function acendan.ImGui_HelpMarker(desc, wrap_pos)
  wrap_pos = wrap_pos or 18.0
  reaper.ImGui_SameLine(ctx)
  reaper.ImGui_TextDisabled(ctx, '(?)')
  acendan.ImGui_Tooltip(desc, wrap_pos)
end

function acendan.ImGui_Tooltip(desc, wrap_pos)
  wrap_pos = wrap_pos or 18.0
  if reaper.ImGui_IsItemHovered(ctx) then
    reaper.ImGui_BeginTooltip(ctx)
    reaper.ImGui_PushTextWrapPos(ctx, reaper.ImGui_GetFontSize(ctx) * wrap_pos)
    reaper.ImGui_Text(ctx, desc)
    reaper.ImGui_PopTextWrapPos(ctx)
    reaper.ImGui_EndTooltip(ctx)
  end
end

function acendan.ImGui_GetSetting(key, default)
  return reaper.HasExtState("acendan_imgui", key) and reaper.GetExtState("acendan_imgui", key) or default
end

function acendan.ImGui_GetSettingBool(key, default)
  return acendan.ImGui_GetSetting(key, default and "true" or "false") == "true"
end

function acendan.ImGui_SetSetting(key, value)
  return reaper.SetExtState("acendan_imgui", key, value, true)
end

function acendan.ImGui_SetSettingBool(key, value)
  return acendan.ImGui_SetSetting(key, tostring(value))
end

-- Ripped from ReaImGui_Demo demo.HSV
function acendan.ImGui_HSV(h, s, v, a)
  local r, g, b = reaper.ImGui_ColorConvertHSVtoRGB(h, s, v)
  return reaper.ImGui_ColorConvertDouble4ToU32(r, g, b, a or 1.0)
end

function acendan.ImGui_Button(label, callback, color_h)
  reaper.ImGui_PushID(ctx, 0)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(),        acendan.ImGui_HSV(color_h, 0.5, 0.5, 1.0))
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), acendan.ImGui_HSV(color_h, 0.7, 0.7, 1.0))
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(),  acendan.ImGui_HSV(color_h, 0.8, 0.8, 1.0))
  if reaper.ImGui_Button(ctx, label) then
    reaper.PreventUIRefresh(1)
    reaper.Undo_BeginBlock()
    callback()
    reaper.Undo_EndBlock(label, -1)
    reaper.PreventUIRefresh(-1)
    reaper.UpdateArrange()
  end
  reaper.ImGui_PopStyleColor(ctx, 3)
  reaper.ImGui_PopID(ctx)
end

function acendan.ImGui_ComboBox(ctx, title, items, selected)
  local ret = nil
  if reaper.ImGui_BeginCombo(ctx, title, items[selected]) then
    for i, value in ipairs(items) do
      local is_selected = selected == i
      if reaper.ImGui_Selectable(ctx, value, is_selected) then
        ret = { i, value }
      end
      if is_selected then reaper.ImGui_SetItemDefaultFocus(ctx) end
    end
    reaper.ImGui_EndCombo(ctx)
  end
  
  -- Clear 'x'
  reaper.ImGui_SameLine(ctx)
  reaper.ImGui_PushItemFlag(ctx, reaper.ImGui_ItemFlags_NoTabStop(), true)
  if reaper.ImGui_SmallButton(ctx, 'x##' .. title) then
    ret = { 0, "" }
  end
  reaper.ImGui_PopItemFlag(ctx)
  acendan.ImGui_Tooltip("Clear selection.")

  if ret then return true, ret[1], ret[2] end
end

function acendan.ImGui_AutoFillComboBox(ctx, title, items, selected, filter)
  assert(filter, "ImGui_AutoFillComboBox: filter is nil. Please create a filter with ImGui_TextFilter_Create()")

  local ret = nil

  -- Search filter
  -- For some reason, this does NOT autofill w tab key when using reaper.ImGui_TextFilter_Draw
  -- Instead, just manually draw an input text and use the results to filter
  local rv, str = reaper.ImGui_InputText(ctx, title .. "##" .. title .. "_filter", reaper.ImGui_TextFilter_Get(filter), reaper.ImGui_InputTextFlags_EscapeClearsAll())
  if rv and reaper.ImGui_IsItemActive(ctx) then reaper.ImGui_TextFilter_Set(filter, str) end

  -- Input states
  local tabbed = reaper.ImGui_IsKeyPressed(ctx, reaper.ImGui_Key_Tab()) and not reaper.ImGui_IsKeyDown(ctx, reaper.ImGui_Mod_Shift())
  local arrowed = reaper.ImGui_IsKeyPressed(ctx, reaper.ImGui_Key_DownArrow()) or reaper.ImGui_IsKeyPressed(ctx, reaper.ImGui_Key_UpArrow())
  local filteractive = reaper.ImGui_IsItemActive(ctx)
  local filterfocused = reaper.ImGui_IsItemFocused(ctx)
  local clicked = false
  local focused = false

  -- Open popup on focus
  if filteractive then reaper.ImGui_OpenPopup(ctx, title .. "_popup") end

  -- Popup
  local visible_items = {}
  local x_l, y_hi = reaper.ImGui_GetItemRectMin(ctx)
  local x_r, y_lo = reaper.ImGui_GetItemRectMax(ctx)
  reaper.ImGui_SetNextWindowPos(ctx, x_l, y_lo, reaper.ImGui_Cond_Always(), 0, 0)
  if reaper.ImGui_BeginPopup(ctx, title .. "_popup", acendan.ImGui_AutoFillComboFlags) then

    -- Hacky focus manipulation
    if not filterfocused and reaper.ImGui_IsWindowFocused( ctx ) then reaper.ImGui_SetNextWindowFocus( ctx ) end
    if arrowed and not reaper.ImGui_IsAnyItemFocused( ctx ) then reaper.ImGui_SetWindowFocusEx( ctx, title .. "_popup" ) end

    -- Dropdown list
    if reaper.ImGui_BeginListBox(ctx, "##" .. title .. "_listbox") then
      for i, item in ipairs(items) do
        if reaper.ImGui_TextFilter_PassFilter(filter, item) then
          visible_items[#visible_items + 1] = item
          if reaper.ImGui_Selectable(ctx, item, item == items[selected]) then
            ret = { i, item }
            clicked = true
          end

          -- Focus on first visible item
          if arrowed and not focused and not reaper.ImGui_IsAnyItemFocused(ctx) and reaper.ImGui_IsItemVisible(ctx) then reaper.ImGui_SetKeyboardFocusHere(ctx, -1); focused = true end
        end
      end
      reaper.ImGui_EndListBox(ctx)
    end

    if tabbed or clicked then reaper.ImGui_CloseCurrentPopup(ctx) end
    reaper.ImGui_EndPopup(ctx)
  end

  -- If tab is pressed, select first visible item in listbox
  if tabbed and #visible_items > 0 then
    local first_visible_item = visible_items[1]
    ret = { acendan.tableContainsVal(items, first_visible_item), first_visible_item }
  end

  -- Clear 'x'
  reaper.ImGui_SameLine(ctx)
  reaper.ImGui_PushItemFlag(ctx, reaper.ImGui_ItemFlags_NoTabStop(), true)
  if reaper.ImGui_SmallButton(ctx, 'x##' .. title) then
    ret = { 0, "" }
    reaper.ImGui_TextFilter_Clear(filter)
  end
  reaper.ImGui_PopItemFlag(ctx)
  acendan.ImGui_Tooltip("Clear selection.")

  -- Exit focus on filter
  if filteractive and (tabbed or clicked) then reaper.ImGui_SetKeyboardFocusHere(ctx) end

  -- Return selected item num, text
  if ret then
    reaper.ImGui_TextFilter_Set(filter, ret[2])
    return true, ret[1], ret[2]
  end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~ VALUE MANIPULATION ~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Check if an input string starts with another string // returns Boolean
function acendan.stringStarts(str, start)
   return str:sub(1, #start) == start
end

-- Check if an input string ends with another string // returns Boolean
function acendan.stringEnds(str, ending)
   return ending == "" or str:sub(-#ending) == ending
end

-- Pattern escaping gsub alternative that works with hyphens and other lua stuff // returns String
-- https://stackoverflow.com/a/29379912
function acendan.stringReplace(str, what, with)
  what = string.gsub(what, "[%(%)%.%+%-%*%?%[%]%^%$%%]", "%%%1") -- escape pattern
  with = string.gsub(with, "[%%]", "%%%%") -- escape replacement
  return string.gsub(str, what, with)
end

-- Split a string into multiple return values by a separator
-- local part1, part2, part3 = acendan.stringSplit("blah|blah|blah", "%|", 3)
function acendan.stringSplit(str, sep, reps)
  sep = sep and sep or ","
  if not acendan.stringEnds(str, sep) then str = str .. sep end
  return str:match(("([^" .. sep .. "]*)" .. sep):rep(reps))
end

-- Encapsulates strings in quotes if they contain spaces
function acendan.encapsulate(str)
  if str:find("%s") then
    str = '"' .. str .. '"'
  end
  return str
end

-- Uncapsulate strings if they start and end with quotes
function acendan.uncapsulate(str)
  if acendan.stringStarts(str, '"') and acendan.stringEnds(str, '"') then
    str = str:sub(2,-2)
  end
  return str
end

-- Clamp a value to given range // returns Number
function acendan.clampValue(input,min,max)
  return math.min(math.max(input,min),max)
end

-- Scale value from range to range
function acendan.scaleBetween(unscaled_val, min_new_range, max_new_range, min_old_range, max_old_range)
  return (max_new_range - min_new_range) * (unscaled_val - min_old_range) / (max_old_range - min_old_range) + min_new_range
end

-- Round the input value // returns Number
function acendan.roundValue(input)
  return math.floor(input + 0.5)
end

-- Increment a number formatted as a string // returns Number
function acendan.incrementNumStr(num)
  return tostring(tonumber(num) + 1)
end

-- Convert An Input String To Title Case // returns String
-- To use this, add the utility function then insert the line below where needed:
--> input_string = input_string:gsub("(%a)([%w_']*)", toTitleCase)
function acendan.toTitleCase(first, rest)
  return first:upper()..rest:lower()
end

-- remove trailing and leading whitespace from string.
-- http://en.wikipedia.org/wiki/Trim_(programming)
function acendan.removeLeadTrailWhitespace(s)
  -- from PiL2 20.4
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

-- attempts to remove _01 style enumeration from the end of strings
function acendan.removeEnumeration(s)
  local pattern = '^(.-)%_%d+'
  return s:find(pattern) and s:match(pattern) or s
end

-- Convert seconds (w decimal) into h:mm:ss:ms
function acendan.dispTime(time)
  local hours = math.floor((time % 86400)/3600)
  local minutes = math.floor((time % 3600)/60)
  local seconds = math.floor((time % 60))
  local milli = tostring(math.floor(time * 100)):sub(1,2)
  return string.format("%d:%02d:%02d.%02d",hours,minutes,seconds,milli)
end

-- Count number of occurrences of a substring in a string // returns Number
function acendan.countOccurrences(base, pattern)
    return select(2, string.gsub(base, pattern, ""))
end

--https://github.com/majek/wdl/blob/master/WDL/db2val.h
function acendan.DB2VAL(x) return math.exp((x)*0.11512925464970228420089957273422) end  

--https://github.com/majek/wdl/blob/master/WDL/db2val.h
function acendan.VAL2DB(x, reduce)   
  if not x or x < 0.0000000298023223876953125 then return -150.0 end
  local v=math.log(x)*8.6858896380650365530225783783321
  if v<-150.0 then return -150.0 else 
    if reduce then 
      return string.format('%.2f', v)
     else 
      return v 
    end
  end
end

-- Convert a time signature string to a pair of numbers
-- local num, denom = acendan.TimeSig_FromString("4/4")
function acendan.TimeSig_FromString(tsig)
  local pos = tsig:find("/")
  if tsig and pos then
    return tonumber(tsig:sub(0,pos-1)), tonumber(tsig:sub(pos+1,-1))
  else
    return nil, nil
  end
end

-- Convert a time signature number pair to a string
-- local tsig = acendan.TimeSig_ToString(4, 4)
function acendan.TimeSig_ToString(num,denom)
  if num >= 0 and denom >= 0 then
    return tostring(num) .. "/" .. tostring(denom)
  else
    return ""
  end
end

-- Convert a time signature string to a rather arbitrary number used for sorting 
function acendan.TimeSig_ToArbitraryNumber(tsig)
  local num, denom = acendan.TimeSig_FromString(tsig)
  if num and denom then
    return (num + (denom * 10))
  else
    return 0
  end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~ TABLES ~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Get length/number of entries in a table // returns Number
-- This is relatively unnecessary, as table length can just be acquired with #table
function acendan.tableLength(table)
  local i = 0
  for _ in pairs(table) do i = i + 1 end
  return i
end

-- Check if a table contains a key // returns Boolean
function acendan.tableContainsKey(table, key)
    return table[key] ~= nil
end

-- Check if a table contains a value in any one of its keys // returns Number or False
function acendan.tableContainsVal(table, val)
  for index, value in ipairs(table) do
      if value == val then
          return index
      end
  end
  return false
end

-- Counts num of occurrences of a given value in a table // returns Number
function acendan.tableCountOccurrences(table, val)
  local occurrences = 0
  for index, value in ipairs(table) do
      if value == val then
          occurrences = occurrences + 1
      end
  end
  return occurrences
end

-- Append new item to end of table
function acendan.tableAppend(table, item)
  table[#table+1] = item
end

-- Clear all elements of a table
function acendan.clearTable(t)
  count = #t
  for i=0, count do t[i]=nil end
end

-- CSV to Table
-- http://lua-users.org/wiki/LuaCsv
function acendan.parseCSVLine (line,sep) 
  local res = {}
  local pos = 1
  sep = sep or ','
  while true do 
    local c = string.sub(line,pos,pos)
    if (c == "") then break end
    if (c == '"') then
      -- quoted value (ignore separator within)
      local txt = ""
      repeat
        local startp,endp = string.find(line,'^%b""',pos)
        txt = txt .. string.sub(line,startp+1,endp-1)
        pos = endp + 1
        c = string.sub(line,pos,pos) 
        if (c == '"') then txt = txt..'"' end 
        -- check first char AFTER quoted string, if it is another
        -- quoted string without separator, then append it
        -- this is the way to "escape" the quote char in a quote. example:
        --   value1,"blub""blip""boing",value3  will result in blub"blip"boing  for the middle
      until (c ~= '"')
      table.insert(res,txt)
      assert(c == sep or c == "")
      pos = pos + 1
    else     
      -- no quotes used, just look for the first separator
      local startp,endp = string.find(line,sep,pos)
      if (startp) then 
        table.insert(res,string.sub(line,pos,startp-1))
        pos = endp + 1
      else
        -- no separator found -> use rest of string and terminate
        table.insert(res,string.sub(line,pos))
        break
      end 
    end
  end
  return res
end

-- Useful table statistics functions available at:
-- http://lua-users.org/wiki/SimpleStats

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~ ITEMS ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--[[
-- Loop through all items
local num_items = reaper.CountMediaItems( 0 )
if num_items > 0 then
  for i=0, num_items - 1 do
    local item =  reaper.GetMediaItem( 0, i )
    local take = reaper.GetActiveTake( item )
    if take ~= nil then 
      
    end
  end
else
  acendan.msg("Project has no items!")
end

-- Loop through all items on specific track
local track = reaper.GetTrack(0, 0) -- Get first track
local num_items = reaper.CountTrackMediaItems( track )
if num_items > 0 then
  for i=0, num_items - 1 do
    local item = reaper.GetTrackMediaItem( track, i )
    local take = reaper.GetActiveTake( item )
    if take ~= nil then 
      
    end
  end
else
  acendan.msg("Track has no items!")
end

-- Loop through selected items
local num_sel_items = reaper.CountSelectedMediaItems(0)
if num_sel_items > 0 then
  for i=0, num_sel_items - 1 do
    local item = reaper.GetSelectedMediaItem( 0, i )
    local take = reaper.GetActiveTake( item )
    if take ~= nil then 
      
    end
  end
else
  acendan.msg("No items selected!")
end
]]--

-- Save initially selected items to table
function acendan.saveSelectedItems(items_table)
  for i = 1, reaper.CountSelectedMediaItems(0) do
    items_table[i] = reaper.GetSelectedMediaItem(0, i-1)
  end
end

-- Restore selected items from table. Requires tableLength() above
function acendan.restoreSelectedItems(items_table)
  reaper.Main_OnCommand(40289, 0) -- Unselect all media items
  for i = 1, acendan.tableLength(items_table) do
    reaper.SetMediaItemSelected( items_table[i], true )
  end
end

-- Sorts a table of media items by their position in timeline order
function acendan.sortItemTableByPos(items_table)
  local sortByPos = function(item1, item2)
    return reaper.GetMediaItemInfo_Value( item1, "D_POSITION" ) < reaper.GetMediaItemInfo_Value( item2, "D_POSITION" )
  end
  table.sort(items_table, sortByPos)
end

-- Set only item selected
function acendan.setOnlyItemSelected(item)
  reaper.Main_OnCommand(40289,0) -- Unselect all items
  reaper.SetMediaItemSelected(item, true)
end

-- Select only tracks with selected items
function acendan.selectTracksOfSelectedItems()
  reaper.Main_OnCommand(40297,0) -- Unselect all tracks
  local num_sel_items = reaper.CountSelectedMediaItems(0)
  if num_sel_items > 0 then
    for i=0, num_sel_items - 1 do
      reaper.SetTrackSelected(reaper.GetMediaItemTrack(reaper.GetSelectedMediaItem( 0, i )),true)
    end
  end
end

-- Get starting position of selected items // returns Number (position)
function acendan.getStartPosSelItems()
  local position = math.huge

  -- Loop through selected items
  local num_sel_items = reaper.CountSelectedMediaItems(0)
  if num_sel_items > 0 then
    for i=0, num_sel_items - 1 do
      local item = reaper.GetSelectedMediaItem( 0, i )
      local item_start_pos = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
      if item_start_pos < position then
        position = item_start_pos
      end
    end
  else
    acendan.dbg("No items selected!")
  end

  return position
end

-- Get ending position of selected items // returns Number (position)
function acendan.getEndPosSelItems()
  local position = 0.0

  -- Loop through selected items
  local num_sel_items = reaper.CountSelectedMediaItems(0)
  if num_sel_items > 0 then
    for i=0, num_sel_items - 1 do
      local item = reaper.GetSelectedMediaItem( 0, i )
      local item_start_pos = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
      local item_end_pos = item_start_pos + reaper.GetMediaItemInfo_Value( item, "D_LENGTH" )
      if item_end_pos > position then
        position = item_end_pos
      end
    end
  else
    acendan.dbg("No items selected!")
  end

  return position
end

-- Get source file name of active take from item input  // returns String
function acendan.getFilenameTrackActiveTake(item)
  if item ~= nil then
    local tk = reaper.GetActiveTake(item)
    if tk ~= nil then
      local pcm_source = reaper.GetMediaItemTake_Source(tk)
      local filenamebuf = ""
      filenamebuf = reaper.GetMediaSourceFileName(pcm_source, filenamebuf)
      return filenamebuf
    end
  end
  return nil
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~ NVK ~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Check if this is a top level folder item
function acendan.isFolderItem(item)
  return select(2, reaper.GetSetMediaItemTakeInfo_String(reaper.GetActiveTake(item), 'P_EXT:nvk_take_source_type_v2', '', false)) == 'EMPTY'
end

-- Typically, others should be the selected items. Could also be *all* items.
function acendan.isTopLevelFolderItem(item, others)
  local track = reaper.GetMediaItem_Track(item)
  local parent = reaper.GetMediaTrackInfo_Value( track, "P_PARTRACK")
  local item_start = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
  local item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH" )
  local item_end = item_start + item_len
  
  -- Check if track is at root level/top
  if parent == 0 then return true end
  
  -- Check if other item is a folder item on this track's parent at these bounds
  for _, other in ipairs(others) do
    local other_is_nvk = acendan.isFolderItem(other)
    local other_track = reaper.GetMediaItem_Track(other)
    local other_start = reaper.GetMediaItemInfo_Value(other, "D_POSITION" )
    local other_len = reaper.GetMediaItemInfo_Value(other, "D_LENGTH" )
    local other_end = other_start + other_len
    if other_is_nvk and parent == other_track and item_start >= other_start - 0.01 and item_end <= other_end + 0.01 then
      return false
    end
  end
  
  return true
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ TRACKS ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--[[
-- Loop through all tracks
local num_tracks =  reaper.CountTracks( 0 )
if num_tracks > 0 then
  for i = 0, num_tracks-1 do
    local track = reaper.GetTrack(0,i)
    -- Process track
  end
else
  acendan.msg("Project has no tracks!")
end
    
-- Loop through selected tracks
local num_sel_tracks = reaper.CountSelectedTracks( 0 )
if num_sel_tracks > 0 then
  for i = 0, num_sel_tracks-1 do
    local track = reaper.GetSelectedTrack(0,i)
    -- Process track
  end
else
  acendan.msg("No tracks selected!")
end
]]--

-- Save initially selected tracks to table
function acendan.saveSelectedTracks (table)
  for i = 1, reaper.CountSelectedTracks(0) do
    table[i] = reaper.GetSelectedTrack(0, i-1)
  end
end

-- Restore selected tracks from table. Requires tableLength() above
function acendan.restoreSelectedTracks(table)
  reaper.Main_OnCommand(40297, 0) -- Unselect all tracks
  for _, track in pairs(table) do
    reaper.SetTrackSelected( track, true )
  end
end

-- Counts the maximum number of channels on a media item in the given track // returns Number
function acendan.countTrackItemsMaxChannels(track)
  -- Loop through selected tracks, count max number of channels of an item on this track
  local track_item_max_channels = -1
  
  if reaper.CountTrackMediaItems( track ) > 0 then
  
    -- Loop through media items on track
    for i = 1, reaper.CountTrackMediaItems( track ) do
      
      local item = reaper.GetTrackMediaItem(track, i - 1)
      local take = reaper.GetActiveTake(item)
      
      -- Get active take
      if take ~= nil then
        
        -- Get source media num channels/mode
        local take_pcm = reaper.GetMediaItemTake_Source(take)
        local take_pcm_chan = reaper.GetMediaSourceNumChannels(take_pcm)
        local take_chan_mod = reaper.GetMediaItemTakeInfo_Value(take, "I_CHANMODE")
        local item_chan = -1
  
        -- Set item channel number based on take channel mode
        local item_chan = (take_chan_mod <= 1) and take_pcm_chan or 1
        
        -- Set max track channels
        track_item_max_channels = (item_chan > track_item_max_channels) and item_chan or track_item_max_channels
      end
    end
    
    --reaper.ShowConsoleMsg("MAX ITEM NUM CHANNELS: " .. track_item_max_channels)
    return track_item_max_channels
    
  else
    reaper.MB("No media items found on selected track!","",0)
    return 0
  end
end

-- Gets the shared parent track (or master track) of the selected tracks // returns MediaTrack
function acendan.getSelectedTracksSharedParent()
  local shared_parent_track = nil
  
  -- Loop through selected tracks
  local num_sel_tracks = reaper.CountSelectedTracks( 0 )
  if num_sel_tracks > 0 then
    local start_time_sel, end_time_sel = reaper.GetSet_LoopTimeRange(0,0,0,0,0);
    if num_sel_tracks == 1 then
      shared_parent_track = reaper.GetSelectedTrack(0,0)
    else
      for k = 0, num_sel_tracks-1 do
        local track = reaper.GetSelectedTrack(0,k)
        local parent_track = reaper.GetParentTrack(track)
        if not parent_track then parent_track = reaper.GetMasterTrack( 0 ) end
        if k == 0 then 
          shared_parent_track = parent_track
        else
          if reaper.GetTrackGUID(parent_track) ~= reaper.GetTrackGUID(shared_parent_track) then 
            shared_parent_track = reaper.GetMasterTrack( 0 ) 
            break
          end
        end
      end
    end
  end
  
  return shared_parent_track or reaper.GetMasterTrack( 0 )
end

-- Parses full track chunk RPPXML, returning table with lane names; nil if no lanes
function acendan.getTrackLaneNames(track)
  local ret, track_chunk = reaper.GetTrackStateChunk(track, "",false)
  if not ret then return end
  
  local lane_name_line = ""
  for line in track_chunk:gmatch("[^\r\n]+") do
    if line:sub(1, 8) == "LANENAME" then
      lane_name_line = line
      break
    end
  end
  if lane_name_line == "" then return end
  
  local lane_names = {}
  local quote = false
  local capture = ""
  for i=1, #lane_name_line do
    local c = lane_name_line:sub(i,i)
    if c == '"' then
      quote = not quote
    elseif c == ' ' and not quote then
      if #capture > 0 then
        table.insert(lane_names, capture)
        capture = ""
      end
    else
      capture = capture .. c
    end
  end
  if #capture > 0 then
    table.insert(lane_names, capture)
  end

  -- Remove the first element ("LANENAME")
  table.remove(lane_names, 1)

  return lane_names
end


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ REGIONS ~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--[[
-- Loop through all regions
local ret, num_markers, num_regions = reaper.CountProjectMarkers( 0 )
local num_total = num_markers + num_regions
if num_regions > 0 then
  local i = 0
  while i < num_total do
    local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, i )
    if isrgn then
      -- Process region
    end
    i = i + 1
  end
else
  acendan.msg("Project has no regions!")
end
    
-- Loop through regions in time selection
local ret, num_markers, num_regions = reaper.CountProjectMarkers( 0 )
local num_total = num_markers + num_regions
local start_time_sel, end_time_sel = reaper.GetSet_LoopTimeRange(0,0,0,0,0);
if start_time_sel ~= end_time_sel then
  local i = 0
  while i < num_total do
    local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, i )
    if isrgn then
      if pos >= start_time_sel and rgnend <= end_time_sel then
        -- Process regions
      end
    end
    i = i + 1
  end
else
  acendan.msg("You need to make a time selection!")
end

-- Loop through regions at edit cursor
local ret, num_markers, num_regions = reaper.CountProjectMarkers( 0 )
local num_total = num_markers + num_regions
if num_regions > 0 then
  local edit_cur_pos = reaper.GetCursorPosition()
  local i = 0
  while i < num_total do
    local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, i )
    if isrgn and pos <= edit_cur_pos and rgnend >= edit_cur_pos then
      -- Process regions
    end
    i = i + 1
  end
else
  acendan.msg("Project has no regions!")
end
  
]]--

-- Get selected regions in Rgn Mrkr Manager using JS_Reaper API, requires getRegionManager
-- https://github.com/ReaTeam/ReaScripts-Templates/blob/master/Regions-and-Markers/X-Raym_Get%20selected%20regions%20in%20region%20and%20marker%20manager.lua
--[[ EXAMPLE USAGE

  local sel_rgn_table = acendan.getSelectedRegions()
  if sel_rgn_table then 
    local ret, num_markers, num_regions = reaper.CountProjectMarkers( 0 )
    local num_total = num_markers + num_regions
    
    for _, regionidx in pairs(sel_rgn_table) do 
      local i = 0
      while i < num_total do
        local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, i )
        if isrgn and markrgnindexnumber == regionidx then
          
          -- Do something with the selected regions!
          reaper.SetProjectMarkerByIndex( 0, i, isrgn, pos, rgnend, markrgnindexnumber, name, color )

          break
        end
        i = i + 1
      end
    end
  else
    acendan.msg("No regions selected!\n\nPlease go to View > Region/Marker Manager to select regions.\n\n\nIf you are on mac... sorry but there is a bug that prevents this script from working. Out of my control :(") 
  end
  
]]--

-- edited by joshnt (08/09/2024)
-- adapted from edgemeal: Select next region in region manager window.lua
-- https://github.com/ReaTeam/ReaScripts-Templates/blob/master/Regions-and-Markers/X-Raym_Get%20selected%20regions%20in%20region%20and%20marker%20manager.lua
function acendan.getSelectedRegions()
  
  local rgn_list, item_count = acendan.getRegionManagerListAndItemCount()
  if not rgn_list then return end
  local regionOrderInManager, _ = acendan.getRegionsAndMarkerInManagerOrder(rgn_list, item_count)

  if item_count == 0 then return end
  
  local indexSelRgn = {}

  -- get pos in rgn manager as keyvalues (instead of keys) to sort them numerically
  local keys = {}

  for posInRgnMgn, markerNum in pairs(regionOrderInManager) do
    local sel = reaper.JS_ListView_GetItemState(rgn_list, posInRgnMgn)
    if sel > 1 then
      table.insert(keys, posInRgnMgn)
    end
  end
  table.sort(keys)

  for _, posInRgnMgn in ipairs(keys) do
    indexSelRgn[#indexSelRgn+1] = regionOrderInManager[posInRgnMgn]
  end

  -- Return table of selected regions
  return indexSelRgn
end

function acendan.getSelectedMarkers()
  
  local rgn_list, item_count = acendan.getRegionManagerListAndItemCount()
  if not rgn_list then return end
  local _, markerOrderInManager = acendan.getRegionsAndMarkerInManagerOrder(rgn_list, item_count)

  if item_count == 0 then return end
  
  local indexSelMrk = {}

  -- get pos in rgn manager as keyvalues (instead of keys) to sort them numerically
  local keys = {}

  for posInRgnMgn, markerNum in pairs(markerOrderInManager) do
    local sel = reaper.JS_ListView_GetItemState(rgn_list, posInRgnMgn)
    if sel > 1 then
      table.insert(keys, posInRgnMgn)
    end
  end
  table.sort(keys)

  for _, posInRgnMgn in ipairs(keys) do
    indexSelMrk[#indexSelMrk+1] = markerOrderInManager[posInRgnMgn]
  end

  -- Return table of selected regions
  return indexSelMrk
end

function acendan.getRegionManagerListAndItemCount()
  -- Open region/marker manager window if not found (as regions can be selected without the region manager being opened)
  local title = reaper.JS_Localize('Region/Marker Manager', 'common')
  local manager = reaper.JS_Window_Find(title, true)
  if not manager then
    reaper.Main_OnCommand(40326, 0) -- View: Show region/marker manager window
    manager = reaper.JS_Window_Find(title, true)
  end
  if manager then
    reaper.DockWindowActivate(manager)      -- OPTIONAL: Select/show manager if docked
    local lv = reaper.JS_Window_FindChildByID(manager, 1071)
    local item_cnt = reaper.JS_ListView_GetItemCount(lv)
    return lv, item_cnt;

  else reaper.MB("Unable to get Region/Marker Manager!","Error",0) return end
end

function acendan.getRegionsAndMarkerInManagerOrder(lv, cnt)
  local regions = {} -- table with position in list as key and region index as value
  local marker = {} -- table with position in list as key and marker index as value
  for i = 0, cnt-1 do
    local rgnMrkString_TEMP = reaper.JS_ListView_GetItemText(lv, i, 1)
    if rgnMrkString_TEMP:match("R%d") then
      local RGN_Index = string.gsub(rgnMrkString_TEMP, "R","")
      regions[i]= tonumber(RGN_Index)
    elseif rgnMrkString_TEMP:match("M%d") then
      local MRK_Index = string.gsub(rgnMrkString_TEMP, "M","")
      marker[i]= tonumber(MRK_Index)
    end
  end
  return regions, marker
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ MARKERS ~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--[[
-- Loop through all markers
local ret, num_markers, num_regions = reaper.CountProjectMarkers( 0 )
local num_total = num_markers + num_regions
if num_markers > 0 then
  local i = 0
  while i < num_total do
    local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, i )
    if not isrgn then
      -- Process markers
    end
    i = i + 1
  end
else
  acendan.msg("Project has no markers!")
end
    
-- Loop through markers in time selection
local ret, num_markers, num_regions = reaper.CountProjectMarkers( 0 )
local num_total = num_markers + num_regions
local start_time_sel, end_time_sel = reaper.GetSet_LoopTimeRange(0,0,0,0,0);
if start_time_sel ~= end_time_sel then
  local i = 0
  while i < num_total do
    local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, i )
    if not isrgn then
      if pos >= start_time_sel and pos <= end_time_sel then
        -- Process markers
      end
    end
    i = i + 1
  end
else
  acendan.msg("You need to make a time selection!")
end
]]--

-- Get selected markers in Rgn Mrkr Manager using JS_Reaper API, requires getRegionManager
--[[ EXAMPLE USAGE

  local sel_mkr_table = getSelectedMarkers()
  if sel_mkr_table then 
    for _, mkr_idx in pairs(sel_mkr_table) do 
      acendan.dbg(mkr_idx)
    end
  else
    acendan.msg("No markers selected!\n\nPlease go to View > Region/Marker Manager to select regions.") 
  end
  
]]--

-- Save current project markers to table of marker indexes // Returns table
function acendan.saveProjectMarkersTable()
  local ret, num_markers, num_regions = reaper.CountProjectMarkers( 0 )
  local num_total = num_markers + num_regions
  if num_markers > 0 then
    local table = {}
    local i = 0
    while i < num_total do
      local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, i )
      if not isrgn then
        table[#table+1]=markrgnindexnumber
      end
      i = i + 1
    end
    return table
  else
    return nil
  end
end

-- Save all project markers to table *WITH FULL MARKER ENUM DETAILS*
function acendan.saveProjectMarkers(table)
  -- Loop through all markers
  local ret, num_markers, num_regions = reaper.CountProjectMarkers( 0 )
  local num_total = num_markers + num_regions
  if num_markers > 0 then
    local i = 0
    while i < num_total do
      local _, isrgn, pos, _, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, i )
      if not isrgn then
        table[#table+1] = { isrgn, pos, name, markrgnindexnumber, color }
      end
      i = i + 1
    end
  end
end

-- Wrapper for SWS action
function acendan.deleteAllProjectMarkers()
  reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWSMARKERLIST9"), 0) -- SWS: Delete all markers
end

-- Restore project markers from table saved by acendan.saveProjectMarkers(table)
function acendan.restoreProjectMarkers(table)
  for i = 1, acendan.tableLength(table) do
    mkr = table[i]
    --                 mkr = { isrgn,   pos,            name,   idx,    color }
    reaper.AddProjectMarker2(0, mkr[1], mkr[2], mkr[2], mkr[3], mkr[4], mkr[5])
  end
end

-- Add action marker by command and preview text
function acendan.addActionMarker(mkr_cmd, mkr_text, mkr_col, pos)
  reaper.AddProjectMarker2(0, false, pos, pos, mkr_cmd, -1, mkr_col)
  reaper.AddProjectMarker2(0, false, pos, pos + 0.01, mkr_text, -1, mkr_col)
end

-- Delete action marker by command and preview text
function acendan.deleteActionMarker(mkr_cmd, mkr_text)
  local reset = true
  while reset do
    reset = false
    local ret, num_markers, num_regions = reaper.CountProjectMarkers( 0 )
    local num_total = num_markers + num_regions
    if num_markers > 0 then
      local i = 0
      while i < num_total do
        if not reset then
          local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, i )
          if not isrgn then
            if name == mkr_text or name == mkr_cmd then
              reaper.DeleteProjectMarkerByIndex(0, i)
              reset = true
            end
          end
        end
        i = i + 1
      end
    end
  end
end

function acendan.deleteProjectMarkers(delrgns, pos, contains, tolerance)
  tolerance = tolerance or 0.01
  local _, num_markers, num_regions = reaper.CountProjectMarkers( 0 )
  local num_total = num_markers + num_regions
  if num_markers > 0 then
    local del_mkrs = {}
    local i = 0
    while i < num_total do
      local _, isrgn, mkpos, _, name, markrgnindexnumber, _ = reaper.EnumProjectMarkers3( 0, i )
      if (isrgn == delrgns) and (math.abs(mkpos - pos) < 0.01) and name:find(contains) then
        del_mkrs[#del_mkrs+1] = markrgnindexnumber
      end
      i = i + 1
    end
    for _, mkr in ipairs(del_mkrs) do
      reaper.DeleteProjectMarker(0, mkr, false)
    end
  end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~  VIDEO  ~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

--[[      DEMO OF VIDEO PROCESSOR TEXT ITEM FUNCTIONS

MediaItem=reaper.GetSelectedMediaItem(0,0)
SuccessfulOrNot, VideoProcessorText=GetTextInVideoProcessor(MediaItem)
reaper.ShowConsoleMsg("Original Text: " .. VideoProcessorText)

SuccessfulOrNot, MsgInCaseOfError=SetTextInVideoProcessor(MediaItem, "Hello Mother")
reaper.ShowConsoleMsg("New Text: " .. tostring(SuccessfulOrNot) .. MsgInCaseOfError)

]]--

function acendan.SetTextInVideoProcessor(item, text)
  -- sets the videotext in a given item in it's first(!) Video Processor in the FXChain.
  -- the Video Processor must be set to the built-in "Title text overlay"-preset!
  -- multiline-texts are allowed
  
  --   item - a MediaItem object as returned by reaper.GetMediaItem
  --   text - the text, that you want to set. Write \n to include a newline.
  -- The function returns retval, errormessage
  --     retval - true, in case of success; false, in case of an error
  --     errormessage - in case of an error, this message gives you a hint, what went wrong.

  -- Meo Mespotine - mespotine.de
  -- licensed under an MIT-license
  
  if reaper.ValidatePtr2(0, item, "MediaItem*")==false then return false, "No valid MediaItem" end
  if type(text)~="string" then return false, "Must be a string" end
  local _bool, StateChunk=reaper.GetItemStateChunk(item, "", false)
  if StateChunk:match("VIDEO_EFFECT")==nil then return false, "No Video Processor found in this item" end
  local part1, code, part2=StateChunk:match("(.-)(<TAKEFX.-\n>)(\nCODEPARM.*)")
  
  if code:match("// Text overlay")==nil then return false, "Only default preset \"Title text overlay\" supported. Please select accordingly." 
  else 
    local c1,test,c3=code:match("(.-text=\")(.-)(\".*)") 
    text=string.gsub(text, "\n", "\\n")
    code=c1..text..c3
  end
  StateChunk=part1..code..part2
  return reaper.SetItemStateChunk(item, StateChunk, false), "Done"
end

function acendan.GetTextInVideoProcessor(item)
  -- gets the videotext in a given item in it's first(!) Video Processor in the FXChain.
  -- the Video Processor must be set to the built-in "Title text overlay"-preset!
  -- multiline-texts are allowed


  --   item - a MediaItem object as returned by reaper.GetMediaItem
  -- The function returns retval, errormessage, textinvideoitem
  --     retval - true, in case of success; false, in case of an error
  --     errormessage - in case of an error, this message gives you a hint, what went wrong.
  --     textinvideoitem - the text, that is currently set in videoitem

  -- Meo Mespotine - mespotine.de
  -- licensed under an MIT-license
  
  if reaper.ValidatePtr2(0, item, "MediaItem*")==false then return false, "No valid MediaItem" end
  local _bool, StateChunk=reaper.GetItemStateChunk(item, "", false)
  if StateChunk:match("VIDEO_EFFECT")==nil then return false, "No Video Processor found in this item" end
  local part1, code, part2=StateChunk:match("(.-)(<TAKEFX.-\n>)(\nCODEPARM.*)")
  --reaper.ShowConsoleMsg(code)
  if code:match("// Text overlay")==nil then return false, "Only default preset \"Title text overlay\" supported. Please select accordingly." 
  else 
    local c1,test,c3=code:match("(.-text=\")(.-)(\".*)") 
    test=string.gsub(test, "\\n", "\n")
    return true, test
  end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ TIME SEL ~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Save original time/loop selection
function acendan.saveLoopTimesel()
  init_start_timesel, init_end_timesel = reaper.GetSet_LoopTimeRange(0, 0, 0, 0, 0)
  init_start_loop, init_end_loop = reaper.GetSet_LoopTimeRange(0, 1, 0, 0, 0)
end

-- Restore original time/loop selection
function acendan.restoreLoopTimesel()
  reaper.GetSet_LoopTimeRange(1, 0, init_start_timesel, init_end_timesel, 0)
  reaper.GetSet_LoopTimeRange(1, 1, init_start_loop, init_end_loop, 0)
end

-- Save original cursor position
function acendan.saveCursorPos()
  init_cur_pos = reaper.GetCursorPosition()
end

-- Restore original cursor position
function acendan.restoreCursorPos()
  reaper.SetEditCurPos(init_cur_pos,false,false)
end


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~ SCRIPT NAME ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Get number from anywhere in a script name // returns Number
function acendan.extractNumberInScriptName(script_name)
  return tonumber(string.match(script_name, "%d+"))
end

-- Get text field from end of script name, formatted like "acendan_Blah blah blah-FIELD.lua" // returns String
function acendan.extractFieldScriptName(script_name)
  return string.sub( script_name, string.find(script_name, "-") + 1, string.len(script_name))
end


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~ COLORS ~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Convert RGB value to int for Reaper native colors, i.e. region coloring // returns Number
function acendan.rgb2int ( R, G, B )
  return (R + 256 * G + 65536 * B)|16777216
end

-- Get SWS custom color using a temp track // returns Number (os-dependent color)
-- color_index = 1 - 16 for SWS custom color #
function acendan.getSWSCustomColor(color_index)
  local init_sel_trks = {}
  acendan.saveSelectedTracks(init_sel_trks)
  
  -- Insert temp track
  local temp_trk_idx = reaper.CountTracks(0)
  reaper.InsertTrackAtIndex(temp_trk_idx,false)
  local temp_trk = reaper.GetTrack(0, temp_trk_idx)
  reaper.SetOnlyTrackSelected(temp_trk)
  
  -- Set/get SWS color
  reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_TRACKCUSTCOL" .. tostring(color_index)),0) -- SWS: Set selected track(s) to custom color *color_index*
  local cust_color = reaper.GetTrackColor(temp_trk)
  
  -- Delete temp track
  reaper.DeleteTrack(temp_trk)
  
  acendan.restoreSelectedTracks(init_sel_trks)
  return cust_color
end



-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FILE MGMT ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Check if a file exists // returns Boolean
function acendan.fileExists(filename)
   return reaper.file_exists(filename)
end

-- Check if a directory/folder exists. // returns Boolean
function acendan.directoryExists(folder)
  local ok, err, code = os.rename(folder.."/", folder.."/")
  if not ok then
     if code == 13 then
        return true -- Permission denied, but it exists
     end
  end
  return ok, err
end

-- Build a filepath from table
function acendan.pathBuilder(prefix, paths)
  local _, sep = acendan.getOS()
  local full = prefix
  for _, subpath in ipairs(paths) do
    full = full .. sep .. subpath
  end
  return full
end

--[[
-- Loop through the files in a directory
local fil_idx = 0
repeat
   local dir_file = reaper.EnumerateFiles( directory, fil_idx )
   -- Do stuff to the dir_files
   acendan.dbg(dir_file)
   
   fil_idx = fil_idx + 1
until not reaper.EnumerateFiles( directory, fil_idx )

-- Loop through subdirectories in a directory
local dir_idx = 0
repeat
  local sub_dir = reaper.EnumerateSubdirectories( directory, dir_idx)
  -- Do stuff to the sub_dirs
  acendan.dbg(sub_dir)
  
  dir_idx = dir_idx + 1
until not  reaper.EnumerateSubdirectories( directory, dir_idx )
]]---

-- Count the number of files in a directory
function acendan.countFilesDirectory(directory)
  if directoryExists(directory) then
    local file_count = 0
    repeat file_count = file_count + 1 until not reaper.EnumerateFiles( directory, file_count )
    return file_count
  else
    return 0
  end
end

-- Get project directory (folder) // returns String
function acendan.getProjDir()
  if reaper.GetOS() == "Win32" or reaper.GetOS() == "Win64" then
    separator = "\\"
  else
    separator = "/"
  end
  retval, project_path_name = reaper.EnumProjects(-1, "")
  if project_path_name ~= "" then
    dir = project_path_name:match("(.*" .. separator ..")")
    return dir
  else
    return ""
  end
end

-- Open a webpage or file directory
function acendan.openDirectoryOrURL(path)
  reaper.CF_ShellExecute(path)
end

-- Get 3 character all caps extension from a file path input // returns String
function acendan.fileExtension(filename)
  return filename:sub(-3):upper()
end

-- More legit ways to get file info
-- TODO: Confirm that this didn't break other scripts after using .getOS() for separator
function acendan.getFileName(filename)
  local _, sep = acendan.getOS()
  return filename:match("^.+" .. sep .. "(.+)$")
end

function acendan.getFileExtension(filename)
  return filename:match("^.+(%..+)$")
end

-- On Windows, this will return: "C:\"
function acendan.getRootDirectory(filename)
  local win = string.find(reaper.GetOS(), "Win") ~= nil
  local sep = win and '\\' or '/'
  return filename:sub(1,filename:find(sep))
end

-- Convert file input to table, each line = new entry // returns Table
function acendan.fileToTable(filename)
  local file = io.open(filename)
  io.input(file)
  local t = {}
  for line in io.lines() do
    table.insert(t, line)
  end
  table.insert(t, "")
  io.close(file)
  return t
end

-- Convert table input to file, each entry = new line
function acendan.tableToFile(  tbl,filename )
  -- declare local variables
  --// exportstring( string )
  --// returns a "Lua" portable version of the string
  local function exportstring( s )
    return string.format("%q", s)
  end
  
  local charS,charE = "   ","\n"
  local file,err = io.open( filename, "wb" )
  if err then return err end

  -- initiate variables for save procedure
  local tables,lookup = { tbl },{ [tbl] = 1 }
  file:write( "return {"..charE )

  for idx,t in ipairs( tables ) do
     file:write( "-- Table: {"..idx.."}"..charE )
     file:write( "{"..charE )
     local thandled = {}

     for i,v in ipairs( t ) do
        thandled[i] = true
        local stype = type( v )
        -- only handle value
        if stype == "table" then
           if not lookup[v] then
              table.insert( tables, v )
              lookup[v] = #tables
           end
           file:write( charS.."{"..lookup[v].."},"..charE )
        elseif stype == "string" then
           file:write(  charS..exportstring( v )..","..charE )
        elseif stype == "number" then
           file:write(  charS..tostring( v )..","..charE )
        end
     end

     for i,v in pairs( t ) do
        -- escape handled values
        if (not thandled[i]) then
        
           local str = ""
           local stype = type( i )
           -- handle index
           if stype == "table" then
              if not lookup[i] then
                 table.insert( tables,i )
                 lookup[i] = #tables
              end
              str = charS.."[{"..lookup[i].."}]="
           elseif stype == "string" then
              str = charS.."["..exportstring( i ).."]="
           elseif stype == "number" then
              str = charS.."["..tostring( i ).."]="
           end
        
           if str ~= "" then
              stype = type( v )
              -- handle value
              if stype == "table" then
                 if not lookup[v] then
                    table.insert( tables,v )
                    lookup[v] = #tables
                 end
                 file:write( str.."{"..lookup[v].."},"..charE )
              elseif stype == "string" then
                 file:write( str..exportstring( v )..","..charE )
              elseif stype == "number" then
                 file:write( str..tostring( v )..","..charE )
              end
           end
        end
     end
     file:write( "},"..charE )
  end
  file:write( "}" )
  file:close()
end

-- Get web interface info from REAPER.ini // returns Table
function acendan.getWebInterfaceSettings()
  local ini_file = reaper.get_ini_file()
  local ret, num_webs = reaper.BR_Win32_GetPrivateProfileString( "reaper", "csurf_cnt", "", ini_file )
  local t = {}
  if ret then
    for i = 0, num_webs do
      local ret, web_int = reaper.BR_Win32_GetPrivateProfileString( "reaper", "csurf_" .. i, "", ini_file )
      table.insert(t, web_int)
    end
  end
  return t
end

-- Get localhost port from reaper.ini web interface file line. Works best with getWebInterfaceSettings()// returns String
function acendan.getPort(line)
  local port = line:sub(line:find(" ")+3,line:find("'")-2)
  return port
end

-- Prompt user to locate folder in system // returns String (or nil if cancelled)
function acendan.promptForFolder(message)
  local ret, folder = reaper.JS_Dialog_BrowseForFolder( message, "" )
  if ret == 1 then
    -- Folder found
    local win, sep = acendan.getOS()
    if not acendan.stringEnds(folder, sep) then folder = folder .. sep end
    return folder
  elseif ret == 0 then
    -- Folder selection cancelled
    return nil
  else 
    -- Folder picking error
    acendan.msg("Something went wrong... Please try again!","Folder picker error")
    acendan.promptForFolder(message)
  end
end

-- Prompt user to locate file in system // returns String (or nil if cancelled)
function acendan.promptForFile(message, start_dir, start_file, exts, allow_mult)
  -- Check for Reaper JS Extension
  if reaper.JS_Dialog_BrowseForSaveFile then
    local ret, file = reaper.JS_Dialog_BrowseForOpenFiles( message, start_dir or "", start_file or "", exts or "", allow_mult or false)
    if ret and file ~= "" then
      -- File found
      return file
    else 
      return nil
    end
  else
    acendan.msg("Please install JS_ReaScript REAPER extension, available in Reapack extension, under ReaTeam Extensions repository.","Missing JS API")
    return nil
  end
end

-- Gets current platform and separator
-- USE THIS IN YOUR SCRIPTS:
-- local win, sep = acendan.getOS()
function acendan.getOS()
  local win = string.find(reaper.GetOS(), "Win") ~= nil
  local sep = win and '\\' or '/'
  return win, sep
end

-- Make symbolic link
function acendan.mkSymLink(from, to, is_dir)
  local win, sep = acendan.getOS()
  local cmd = win and
    "mklink" .. (is_dir and " /D" or " /H") .. " " .. acendan.encapsulate(to) .. " " .. acendan.encapsulate(from) or
    "ln -s " .. acendan.encapsulate(from) .. " " .. acendan.encapsulate(to)
  os.execute(cmd)
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ RENDERING ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Render settings are bitwise. For example:
-- if input & acendan.RENDER_SETTINGS.USE_RENDER_MATRIX == acendan.RENDER_SETTINGS.USE_RENDER_MATRIX then
acendan.RENDER_SETTINGS = {
  MASTER_MIX = 0,
  STEMS_MASTER_MIX = 1,
  STEMS_ONLY = 2,
  MULTICHANNEL_TRACKS = 4,
  USE_RENDER_MATRIX = 8,
  MONO_MEDIA_TO_MONO_FILES = 16,
  SELECTED_MEDIA_ITEMS = 32,
  SELECTED_MEDIA_ITEMS_MASTER = 64,
  SELECTED_TRACKS_MASTER = 128,
  STRETCH_MARKERS = 256,
  EMBED_METADATA = 512,
  TAKE_MARKERS = 1024,
  SECOND_PASS_RENDER = 2048
}

-- Render bounds are just regular numbers, no need for bitwise comparison
acendan.RENDER_BOUNDSFLAG = {
  CUSTOM_TIME_BOUNDS = 0,
  ENTIRE_PROJECT = 1,
  TIME_SELECTION = 2,
  ALL_PROJECT_REGIONS = 3,
  SELECTED_MEDIA_ITEMS = 4,
  SELECTED_PROJECT_REGIONS = 5,
  ALL_PROJECT_MARKERS = 6,
  SELECTED_PROJECT_MARKERS = 7
}

-- Get/Set render settings to/from table
function acendan.getRenderSettings()
  local t = {}
  t.rendersettings   = reaper.GetSetProjectInfo(0, "RENDER_SETTINGS", -1, false)            -- Master mix, stems, etc
  t.boundsflag       = reaper.GetSetProjectInfo(0, "RENDER_BOUNDSFLAG", -1, false)          -- Time selection, project, etc
  t._, t.renderformat    = reaper.GetSetProjectInfo_String(0, 'RENDER_FORMAT', "", false)   -- File format, i.e. "ewav"
  t._, t.renderdirectory = reaper.GetSetProjectInfo_String(0, "RENDER_FILE", "", false)     -- C:\users\aaron\docs\blah
  t._, t.renderfilename  = reaper.GetSetProjectInfo_String(0, "RENDER_PATTERN", "", false)  -- $item_$itemnumber_JU20
  return t
end

function acendan.setRenderSettings(t)
  reaper.GetSetProjectInfo(0, "RENDER_SETTINGS", t.rendersettings, true)
  reaper.GetSetProjectInfo(0, "RENDER_BOUNDSFLAG", t.boundsflag, true)
  reaper.GetSetProjectInfo_String(0, 'RENDER_FORMAT', t.renderformat, true)
  reaper.GetSetProjectInfo_String(0, "RENDER_FILE", t.renderdirectory, true)
  reaper.GetSetProjectInfo_String(0, "RENDER_PATTERN", t.renderfilename, true)
end


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~ MEDIA EXPLORER ~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Returns hWnd for media explorer window
function acendan.getMediaExplorer()
  return reaper.JS_Window_Find(reaper.JS_Localize("Media Explorer","common"), true) or nil
end

-- Returns list view hWnd for media explorer's file list
function acendan.getMediaExplorerList()
  return reaper.JS_Window_FindEx(acendan.getMediaExplorer(), nil, "SysListView32", "") or nil
end

-- Count selected items media explorer // returns Number
function acendan.countSelectedItemsMediaExplorer()
  local hWnd = acendan.getMediaExplorer()
  if hWnd == nil then msg("Unable to find media explorer. Try going to:\n\nExtensions > ReaPack > Browse Packages\n\nand re-installing the JS_Reascript extension.") return end  

  local file_LV = acendan.getMediaExplorerList()
  
  sel_count, sel_indexes = reaper.JS_ListView_ListAllSelItems(file_LV)
  return sel_count
end

-- Get selected item details media explorer
function acendan.getSelectedItemsDetailsMediaExplorer()
  local hWnd = acendan.getMediaExplorer()
  if hWnd == nil then acendan.msg("Unable to find media explorer. Try going to:\n\nExtensions > ReaPack > Browse Packages\n\nand re-installing the JS_Reascript extension.","Media Explorer Items") return end  

  local file_LV = acendan.getMediaExplorerList()
  
  sel_count, sel_indexes = reaper.JS_ListView_ListAllSelItems(file_LV)
  if sel_count == 0 then acendan.msg("No items selected in media explorer!","Media Explorer Items") return end

  for ndx in string.gmatch(sel_indexes, '[^,]+') do 
    index = tonumber(ndx)
    local fname = reaper.JS_ListView_GetItemText(file_LV, index, 0)
    local size = reaper.JS_ListView_GetItemText(file_LV, index, 1)
    local date = reaper.JS_ListView_GetItemText(file_LV, index, 2)
    local ftype = reaper.JS_ListView_GetItemText(file_LV, index, 3)
    acendan.dbg(fname .. ', ' .. size .. ', ' .. date .. ', ' .. ftype) 
  end
  
  -- Get selected path  from edit control inside combobox
  local combo = reaper.JS_Window_FindChildByID(hWnd, 1002)
  local edit = reaper.JS_Window_FindChildByID(combo, 1001)
  local path = reaper.JS_Window_GetTitle(edit, "", 255)
  acendan.dbg(path)

end

-- Filter Media Explorer for files
function acendan.filterMediaExplorer(search)
  if reaper.APIExists("JS_Window_Find") then
    local IDC_SEARCH = 0x3f7
    local WM_COMMAND = 0x111
    local CBN_EDITCHANGE = 5
    
    local mediaExplorer = reaper.OpenMediaExplorer( "", false )
    local winHWND = acendan.getMediaExplorer()
    local mediaExpFilter =  reaper.JS_Window_FindChildByID( winHWND, 1015 )
    local filtered = reaper.JS_Window_SetTitle(mediaExpFilter,search)
    reaper.BR_Win32_SendMessage(mediaExplorer, WM_COMMAND, (CBN_EDITCHANGE<<16) | IDC_SEARCH, 0)
  else
    acendan.msg("This script requires the JS Reascript API. Please install it via ReaPack.\n\nExtensions > ReaPack > Browse Packages > js_ReaScriptAPI: API functions for ReaScripts","Missing JS ReaScript API")  
  end
end


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~ ACTIONS LIST ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Filter actions list for scripts or search term
function acendan.filterActionsList(search)
  if reaper.APIExists("JS_Window_Find")then;
    reaper.ShowActionList();
    local winHWND = reaper.JS_Window_Find(reaper.JS_Localize("Actions", "common"),true);
    local filter_Act = reaper.JS_Window_FindChildByID(winHWND,1324);
    reaper.JS_Window_SetTitle(filter_Act,search);
  else
    reaper.MB("This script requires the JS Reascript API. Please install it via ReaPack.\n\nExtensions > ReaPack > Browse Packages > js_ReaScriptAPI: API functions for ReaScripts","Missing JS ReaScript API", 0)  
  end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~ REAPACK ~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Open ReaPack About page for this script
function acendan.help()
  if not reaper.ReaPack_GetOwner then
    reaper.MB('This feature requires ReaPack v1.2 or newer.', script_name, 0)
    return
  end
  local owner = reaper.ReaPack_GetOwner(({reaper.get_action_context()})[2])
  if not owner then
    reaper.MB(string.format(
      'This feature is unavailable because "%s" was not installed using ReaPack.',
      script_name), script_name, 0)
    return
  end
  reaper.ReaPack_AboutInstalledPackage(owner)
  reaper.ReaPack_FreeEntry(owner)
end

--[[
-- Check for JS_ReaScript Extension
if reaper.JS_Dialog_BrowseForSaveFile then

else
  acendan.msg("Please install the JS_ReaScriptAPI REAPER extension, available in ReaPack, under the ReaTeam Extensions repository.\n\nExtensions > ReaPack > Browse Packages\n\nFilter for 'JS_ReascriptAPI'. Right click to install.")
end
]]--

-- Looks for JSFX by name in Effects/ACendan Scripts/JSFX/      \\ Returns boolean
function acendan.checkForJSFX(jsfx_name)
  if not jsfx_name:find(".jsfx") then jsfx_name = jsfx_name .. ".jsfx" end
  if reaper.file_exists(acendan.pathBuilder(reaper.GetResourcePath(), {"Effects","ACendan Scripts","JSFX",jsfx_name})) then
    return true
  else
    return false
  end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~ YAML ~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function acendan.loadYaml(filename, sep)
  local yamllib = acendan.pathBuilder(reaper.GetResourcePath(), {"Scripts","ACendan Scripts","Development","Lib","yaml.lua"})
  if not yaml and reaper.file_exists(yamllib) then dofile(yamllib) end
  if not yaml then acendan.msg("Failed to load YAML library!"); return nil end
  if not reaper.file_exists(filename) then return nil end

  local function readAll(file)
    local f = io.open(file, "rb")
    local content = f:read("*all")
    f:close()
    return content
  end

  local content = readAll(filename)
  -- DEBUG
  -- local tokens = yaml.tokenize(content)
  -- local i = 1
  -- while tokens[i] do
  --   acendan.dbg(i .. ' ' .. tokens[i][1] .. ' ' .. "'" .. (tokens[i].raw or '') .. "'")
  --   i = i + 1
  -- end
  return yaml.eval(content)
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

return acendan
