-- @description ACendan Lua Utilities
-- @author Aaron Cendan
-- @version 7.0
-- @metapackage
-- @provides
--   [main] .
-- @link https://ko-fi.com/acendan_
-- @about
--   # Lua Utilities
-- @changelog
--   # Append platform specific separator from acendan.promptForFolder()

--[[
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
if reaper.file_exists( acendan_LuaUtils ) then dofile( acendan_LuaUtils ); if not acendan or acendan.version() < 6.2 then acendan.msg('This script requires a newer version of ACendan Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"ACendan Lua Utilities"); return end else reaper.ShowConsoleMsg("This script requires ACendan Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'ACendan Lua Utilities'"); return end


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
reaper.Undo_EndBlock(script_name,-1)
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~ BACKGROUND SCRIPT ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- @description Background Script Template
-- @author Aaron Cendan
-- @version 1.0
-- @metapackage
-- @provides
--   [main] . > acendan_Background script title.lua
-- @link https://aaroncendan.me
-- @about
--   # This is a background/toggle script!
--   By Aaron Cendan - Sept 2020
--
--   ### Notes
--   * When prompted if you want to terminate instances, click the little checkbox then terminate.

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Refresh rate (in seconds)
local refresh_rate = 0.3

-- Get action context info (needed for toolbar button toggling)
local _, _, section, cmdID = reaper.get_action_context()

-- Get this script's name and directory
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local script_directory = ({reaper.get_action_context()})[2]:sub(1,({reaper.get_action_context()})[2]:find("\\[^\\]*$"))

-- Load lua utilities
acendan_LuaUtils = reaper.GetResourcePath()..'/Scripts/ACendan Scripts/Development/acendan_Lua Utilities.lua'
if reaper.file_exists( acendan_LuaUtils ) then dofile( acendan_LuaUtils ); if not acendan or acendan.version() < 5.4 then acendan.msg('This script requires a newer version of ACendan Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"ACendan Lua Utilities"); return end else reaper.ShowConsoleMsg("This script requires ACendan Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'ACendan Lua Utilities'"); return end


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Setup runs once on script startup
function setup()
  -- Timing control
  local start = reaper.time_precise()
  check_time = start
  
  -- Toggle command state on
  reaper.SetToggleCommandState( section, cmdID, 1 )
  reaper.RefreshToolbar2( section, cmdID )
end

-- Main function will run in Reaper's defer loop. EFFICIENCY IS KEY.
function main()
  -- System time in seconds (3600 per hour)
  local now = reaper.time_precise()
  
  -- If the amount of time passed is greater than refresh rate, execute code
  if now - check_time >= refresh_rate then

    -- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    -- THIS IS WHERE YOU DO ALL OF THE ACTUAL CODE THINGS, ONCE EVERY REFRESH
    -- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    
    -- Reset last used time
    check_time = now
  end

  reaper.defer(main)
end

-- Exit function will run once when the script is terminated
function Exit()
  reaper.UpdateArrange()
  reaper.SetToggleCommandState( section, cmdID, 0 )
  reaper.RefreshToolbar2( section, cmdID )
  return reaper.defer(function() end)
end


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ UTILITIES ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

setup()
reaper.atexit(Exit)
main()

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~ IMGUI TEMPLATE  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- @description ImGui Script Template
-- @author Aaron Cendan
-- @version 1.0
-- @metapackage
-- @provides
--   [main] .
-- @link https://ko-fi.com/acendan_
-- @about
--   # 
-- @changelog
--   + 

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
if reaper.file_exists( acendan_LuaUtils ) then dofile( acendan_LuaUtils ); if not acendan or acendan.version() < 6.2 then acendan.msg('This script requires a newer version of ACendan Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"ACendan Lua Utilities"); return end else reaper.ShowConsoleMsg("This script requires ACendan Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'ACendan Lua Utilities'"); return end


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function init()
  -- Confirm user has ImGui installed
  if not reaper.ImGui_Key_0() then acendan.msg("This script requires the ReaImGui API, which can be installed from:\n\nExtensions > ReaPack > Browse packages...") return end
  
	ctx = reaper.ImGui_CreateContext(script_name)
  
  window_flags = reaper.ImGui_WindowFlags_None()
  window_flags = window_flags | reaper.ImGui_WindowFlags_NoCollapse()
  window_size = { width = 400, height = 520 }
	reaper.ImGui_SetNextWindowSize(ctx, window_size.width, window_size.height)
  
	TEXT_BASE_WIDTH  = reaper.ImGui_CalcTextSize(ctx, 'A')
  TEXT_BASE_HEIGHT = reaper.ImGui_GetTextLineHeightWithSpacing(ctx)
  FLT_MIN, FLT_MAX = reaper.ImGui_NumericLimits_Float()
	
  main()
end

function main()
  local rv, open = reaper.ImGui_Begin(ctx, script_name, true, window_flags)
  if not rv then return open end
  
  
  
  reaper.ImGui_End(ctx)
  if open then reaper.defer(main) else reaper.ImGui_DestroyContext(ctx) end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ UTILITIES ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()
init()
reaper.Undo_EndBlock(script_name,-1)
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~ CONTINUOUS KEY COMBO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- @description Continuous Key Combo Template
-- @author Aaron Cendan
-- @version 1.0
-- @metapackage
-- @provides
--   [main] . > acendan_Continuous Key Combo Template.lua
-- @link https://aaroncendan.me
-- @about Setup instructions...
-- ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓ IMPORTANT! READ ME!  ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
--   *
--   * This script is a background script, meaning it will run continuously in the background to check if a key combo is held
--   * This means that you should NOT set up a traditional keyboard shortcut for it in the actions menu. This script will NOT work if you do that.
--   * Please set up a shortcut key in the User Config section below, then save this file. 
--   * After, I recommend setting this script as a Global Startup Action or enabling in your default Project Template so that it's always enabled.

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ USER CONFIG ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function UserConfig()
  
  -- Manually set up your key command here
  key = keys.K    -- Replace with your preferred key. For a list of all available keys, refer to the 'keys' table below. 
  ctrl = false    -- Toggle for ctrl key modifier   - true/false
  shift = false   -- Toggle for shift key modifier  - true/false
  alt = false     -- Toggle for alt key modifier    - true/false

-- ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑
end

-- Find your key here! To reference a key, format it with a period like this: keys.TAB
keys = {
  A = 0x41, -- A key
  B = 0x42, -- B key
  C = 0x43, -- C key
  D = 0x44, -- D key
  E = 0x45, -- E key
  F = 0x46, -- F key
  G = 0x47, -- G key
  H = 0x48, -- H key
  I = 0x49, -- I key
  J = 0x4A, -- J key
  K = 0x4B, -- K key
  L = 0x4C, -- L key
  M = 0x4D, -- M key
  N = 0x4E, -- N key
  O = 0x4F, -- O key
  P = 0x50, -- P key
  Q = 0x51, -- Q key
  R = 0x52, -- R key
  S = 0x53, -- S key
  T = 0x54, -- T key
  U = 0x55, -- U key
  V = 0x56, -- V key
  W = 0x57, -- W key
  X = 0x58, -- X key
  Y = 0x59, -- Y key
  Z = 0x5A, -- Z key
  CONTROL = 0x11, -- CTRL key
  LCONTROL = 0xA2, -- Left CONTROL key
  RCONTROL = 0xA3, -- Right CONTROL key
  SHIFT = 0x10, -- SHIFT key
  LSHIFT = 0xA0, -- Left SHIFT key
  RSHIFT = 0xA1, -- Right SHIFT key
  MENU = 0x12, -- ALT key
  LWIN = 0x5B, -- Left Windows key (Natural keyboard)
  RWIN = 0x5C, -- Right Windows key (Natural keyboard)
  LBUTTON = 0x01, -- Left mouse button
  RBUTTON = 0x02, -- Right mouse button
  CANCEL = 0x03, -- Control-break processing
  MBUTTON = 0x04, -- Middle mouse button (three-button mouse)
  XBUTTON1 = 0x05, -- X1 mouse button
  XBUTTON2 = 0x06, -- X2 mouse button
  BACK = 0x08, -- BACKSPACE key
  TAB = 0x09, -- TAB key
  CLEAR = 0x0C, -- CLEAR key
  RETURN = 0x0D, -- ENTER key
  ESCAPE = 0x1B, -- ESC key
  CAPITAL = 0x14, -- CAPS LOCK key
  SPACE = 0x20, -- SPACEBAR
  PRIOR = 0x21, -- PAGE UP key
  NEXT = 0x22, -- PAGE DOWN key
  END = 0x23, -- END key
  HOME = 0x24, -- HOME key
  LEFT = 0x25, -- LEFT ARROW key
  UP = 0x26, -- UP ARROW key
  RIGHT = 0x27, -- RIGHT ARROW key
  DOWN = 0x28, -- DOWN ARROW key
  SELECT = 0x29, -- SELECT key
  PRINT = 0x2A, -- PRINT key
  EXECUTE = 0x2B, -- EXECUTE key
  SNAPSHOT = 0x2C, -- PRINT SCREEN key
  INSERT = 0x2D, -- INS key
  DELETE = 0x2E, -- DEL key
  HELP = 0x2F, -- HELP key
  NUMLOCK = 0x90, -- NUM LOCK key
  SCROLL = 0x91, -- SCROLL LOCK key
  LMENU = 0xA4, -- Left MENU key
  RMENU = 0xA5, -- Right MENU key
  APPS = 0x5D, -- Applications key (Natural keyboard)
  SLEEP = 0x5F, -- Computer Sleep key
  ZERO = 0x30, -- 0 key
  ONE = 0x31, -- 1 key
  TWO = 0x32, -- 2 key
  THREE = 0x33, -- 3 key
  FOUR = 0x34, -- 4 key
  FIVE = 0x35, -- 5 key
  SIX = 0x36, -- 6 key
  SEVEN = 0x37, -- 7 key
  EIGHT = 0x38, -- 8 key
  NINE = 0x39, -- 9 key
  NUMPAD0 = 0x60, -- Numeric keypad 0 key
  NUMPAD1 = 0x61, -- Numeric keypad 1 key
  NUMPAD2 = 0x62, -- Numeric keypad 2 key
  NUMPAD3 = 0x63, -- Numeric keypad 3 key
  NUMPAD4 = 0x64, -- Numeric keypad 4 key
  NUMPAD5 = 0x65, -- Numeric keypad 5 key
  NUMPAD6 = 0x66, -- Numeric keypad 6 key
  NUMPAD7 = 0x67, -- Numeric keypad 7 key
  NUMPAD8 = 0x68, -- Numeric keypad 8 key
  NUMPAD9 = 0x69, -- Numeric keypad 9 key
  MULTIPLY = 0x6A, -- Multiply key
  ADD = 0x6B, -- Add key
  SEPARATOR = 0x6C, -- Separator key
  SUBTRACT = 0x6D, -- Subtract key
  DECIMAL = 0x6E, -- Decimal key
  DIVIDE = 0x6F, -- Divide key
  F1 = 0x70, -- F1 key
  F2 = 0x71, -- F2 key
  F3 = 0x72, -- F3 key
  F4 = 0x73, -- F4 key
  F5 = 0x74, -- F5 key
  F6 = 0x75, -- F6 key
  F7 = 0x76, -- F7 key
  F8 = 0x77, -- F8 key
  F9 = 0x78, -- F9 key
  F10 = 0x79, -- F10 key
  F11 = 0x7A, -- F11 key
  F12 = 0x7B, -- F12 key
  F13 = 0x7C, -- F13 key
  F14 = 0x7D, -- F14 key
  F15 = 0x7E, -- F15 key
  F16 = 0x7F, -- F16 key
  F17 = 0x80, -- F17 key
  F18 = 0x81, -- F18 key
  F19 = 0x82, -- F19 key
  F20 = 0x83, -- F20 key
  F21 = 0x84, -- F21 key
  F22 = 0x85, -- F22 key
  F23 = 0x86, -- F23 key
  F24 = 0x87, -- F24 key
  BROWSER_BACK = 0xA6, -- Browser Back key
  BROWSER_FORWARD = 0xA7, -- Browser Forward key
  BROWSER_REFRESH = 0xA8, -- Browser Refresh key
  BROWSER_STOP = 0xA9, -- Browser Stop key
  BROWSER_SEARCH = 0xAA, -- Browser Search key
  BROWSER_FAVORITES = 0xAB, -- Browser Favorites key
  BROWSER_HOME = 0xAC, -- Browser Start and Home key
  VOLUME_MUTE = 0xAD, -- Volume Mute key
  VOLUME_DOWN = 0xAE, -- Volume Down key
  VOLUME_UP = 0xAF, -- Volume Up key
  MEDIA_NEXT_TRACK = 0xB0, -- Next Track key
  MEDIA_PREV_TRACK = 0xB1, -- Previous Track key
  MEDIA_STOP = 0xB2, -- Stop Media key
  MEDIA_PLAY_PAUSE = 0xB3, -- Play/Pause Media key
  LAUNCH_MAIL = 0xB4, -- Start Mail key
  LAUNCH_MEDIA_SELECT = 0xB5, -- Select Media key
  LAUNCH_APP1 = 0xB6, -- Start Application 1 key
  LAUNCH_APP2 = 0xB7, -- Start Application 2 key
  KANA = 0x15, -- IME Kana mode
  HANGUEL = 0x15, -- IME Hanguel mode (maintained for compatibility; use VK_HANGUL)
  HANGUL = 0x15, -- IME Hangul mode
  IME_ON = 0x16, -- IME On
  JUNJA = 0x17, -- IME Junja mode
  FINAL = 0x18, -- IME final mode
  HANJA = 0x19, -- IME Hanja mode
  KANJI = 0x19, -- IME Kanji mode
  IME_OFF = 0x1A, -- IME Off
  CONVERT = 0x1C, -- IME convert
  NONCONVERT = 0x1D, -- IME nonconvert
  ACCEPT = 0x1E, -- IME accept
  MODECHANGE = 0x1F, -- IME mode change request
  OEM_1 = 0xBA, -- Used for miscellaneous characters; it can vary by keyboard. For the US standard keyboard, the ';:' key"
  OEM_PLUS = 0xBB, -- For any country/region, the '+' key
  OEM_COMMA = 0xBC, -- For any country/region, the ',' key
  OEM_MINUS = 0xBD, -- For any country/region, the '-' key
  OEM_PERIOD = 0xBE, -- For any country/region, the '.' key 
  OEM_2 = 0xBF, -- Used for miscellaneous characters; it can vary by keyboard. For the US standard keyboard, the '/?' key"
  OEM_3 = 0xC0, -- Used for miscellaneous characters; it can vary by keyboard. For the US standard keyboard, the '`~' key"
  OEM_4 = 0xDB, -- Used for miscellaneous characters; it can vary by keyboard. For the US standard keyboard, the '[{' key"
  OEM_5 = 0xDC, -- Used for miscellaneous characters; it can vary by keyboard. For the US standard keyboard, the '\|' key"
  OEM_6 = 0xDD, -- Used for miscellaneous characters; it can vary by keyboard. For the US standard keyboard, the ']}' key"
  OEM_7 = 0xDE, -- Used for miscellaneous characters; it can vary by keyboard. For the US standard keyboard, the 'single-quote/double-quote' key"
  OEM_8 = 0xDF, -- Used for miscellaneous characters; it can vary by keyboard.
  OEM_102 = 0xE2, -- Either the angle bracket key or the backslash key on the RT 102-key keyboard
  OEM_CLEAR = 0xFE, -- Clear key
  PROCESSKEY = 0xE5, -- IME PROCESS key
  PACKET = 0xE7, -- Used to pass Unicode characters as if they were keystrokes. The VK_PACKET key is the low word of a 32-bit Virtual Key value used for non-keyboard input methods. For more information, see Remark in KEYBDINPUT, SendInput, WM_KEYDOWN, and WM_KEYUP
  ATTN = 0xF6, -- Attn key
  CRSEL = 0xF7, -- CrSel key
  EXSEL = 0xF8, -- ExSel key
  EREOF = 0xF9, -- Erase EOF key
  PLAY = 0xFA, -- Play key
  PAUSE = 0x13, -- PAUSE key
  ZOOM = 0xFB, -- Zoom key
  PA1 = 0xFD -- PA1 key
}


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  
-- Main Function (loops in background)
function main()

  -- Get cursor info
  local window, segment, details = reaper.BR_GetMouseCursorContext()
  
  -- TWEAK THIS IF YOU NEED SOMETHING OTHER THAN THE ARRANGE WINDOW
  -- If hovering with mouse over the arrange over a valid track...
  if window == "arrange" and segment == "track" then

    -- Get keyboard input array
    local state = reaper.JS_VKeys_GetState(0)
    
    -- Check key
    key_state = state:byte(key)
    
    -- Check modifiers
    if ctrl  then ctrl_state  = state:byte(keys.CONTROL)  end
    if shift then shift_state = state:byte(keys.SHIFT) end
    if alt   then alt_state   = state:byte(keys.MENU)   end
    
    -- Execute if full key command received
    if key_state ~= 0 and ctrl_state ~= 0 and shift_state ~= 0 and alt_state ~= 0 then
      if toggle_state == 0 then
        
        -- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        -- THIS IS WHERE YOU DO ALL OF THE ACTUAL CODE THINGS ON KEY PRESS
        -- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        
        toggle_state = 1
      end
    else
      if toggle_state == 1 then
        
        -- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        -- THIS IS WHERE YOU DO ALL OF THE ACTUAL CODE THINGS ON KEY RELEASE
        -- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!
            
        toggle_state = 0
      end
    end
  end
  
  reaper.defer( main )
end


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ UTILITIES ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Set ToolBar Button State
function SetButtonState( set )
  if not set then set = 0 end
  local is_new_value, filename, sec, cmd, mode, resolution, val = reaper.get_action_context()
  local state = reaper.GetToggleCommandStateEx( sec, cmd )
  reaper.SetToggleCommandState( sec, cmd, set ) -- Set ON
  reaper.RefreshToolbar2( sec, cmd )
end


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~ SETUP ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Set up user's preferred shortcut
UserConfig()

-- Stores key array values in main loop (or always set to 1 if modifiers disabled in user config)
key_state = 0
if ctrl  then ctrl_state = 0  else ctrl_state = 1 end
if shift then shift_state = 0 else shift_state = 1 end
if alt   then alt_state = 0   else alt_state = 1 end

-- Prevents repetitive execution while held
toggle_state = 0

-- Check for first time launch           !!!!!!!! CHANGE THE KEYS TO BE UNIQUE PER SCRIPT!!!!!!!!!!!!!
local run_previously = reaper.HasExtState( "acendan_Lock item horizontal", "first_time" )  
if run_previously then
  -- Validate user's key
  if key then
    -- Check for JS ReaScript API
    if reaper.JS_VKeys_GetState then
      reaper.ClearConsole()
      SetButtonState( 1 )
      main()
      reaper.atexit( SetButtonState )
    else
      reaper.MB("This script requires the JS Reascript API. Please install it via ReaPack.\n\nExtensions > ReaPack > Browse Packages > js_ReaScriptAPI: API functions for ReaScripts","Error", 0)  
    end
  else
    reaper.MB("Key variable is not set to a valid key! Please double check the options avaialable in the 'keys' table. Must be ALL CAPS!","Error",0)
  end
else
  reaper.SetExtState( "acendan_Lock item horizontal", "first_time", "https://youtu.be/dQw4w9WgXcQ", true )
  reaper.MB("This script requires some basic setup! Please click 'Edit Action' and follow the instructions under About and User Config.","Setup",0)
end
]]--


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

--[[
-- Load lua utilities
acendan_LuaUtils = reaper.GetResourcePath()..'/Scripts/ACendan Scripts/Development/acendan_Lua Utilities.lua'
if reaper.file_exists( acendan_LuaUtils ) then dofile( acendan_LuaUtils ); if not acendan or acendan.version() < 3.0 then acendan.msg('This script requires a newer version of ACendan Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"ACendan Lua Utilities"); return end else reaper.ShowConsoleMsg("This script requires ACendan Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'ACendan Lua Utilities'"); return end
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
function acendan.dbg(dbg)
  reaper.ShowConsoleMsg(tostring(dbg) .. "\n")
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
    -- Process item
    
    local take = reaper.GetActiveTake( item )
    if take ~= nil then 
      -- Process active take
    end
  end
else
  acendan.msg("Project has no items!")
end

-- Loop through selected items
local num_sel_items = reaper.CountSelectedMediaItems(0)
if num_sel_items > 0 then
  for i=0, num_sel_items - 1 do
    local item = reaper.GetSelectedMediaItem( 0, i )
    -- Process item
    
    local take = reaper.GetActiveTake( item )
    if take ~= nil then 
      -- Process active take
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
function acendan.getRegionManager()
  return reaper.JS_Window_Find(reaper.JS_Localize("Region/Marker Manager","common"), true) or nil
end

function acendan.getRegionManagerList()
	return reaper.JS_Window_FindEx(acendan.getRegionManager(), nil, "SysListView32", "") or nil
end

function acendan.getSelectedRegions()
  local rgn_list = acendan.getRegionManagerList()

  sel_count, sel_indexes = reaper.JS_ListView_ListAllSelItems(rgn_list)
  if sel_count == 0 then return end 

  names = {}
  i = 0
  for index in string.gmatch(sel_indexes, '[^,]+') do 
    i = i+1
    local sel_item = reaper.JS_ListView_GetItemText(rgn_list, tonumber(index), 1)
    if sel_item:find("R") ~= nil then
      names[i] = tonumber(sel_item:sub(2))
    end
  end
  
  -- Return table of selected regions
  return names
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
function acendan.getSelectedMarkers()
  local rgn_list = acendan.getRegionManagerList()

  sel_count, sel_indexes = reaper.JS_ListView_ListAllSelItems(rgn_list)
  if sel_count == 0 then return end 

  names = {}
  i = 0
  for index in string.gmatch(sel_indexes, '[^,]+') do 
    i = i+1
    local sel_item = reaper.JS_ListView_GetItemText(rgn_list, tonumber(index), 1)
    if sel_item:find("M") ~= nil then
      names[i] = tonumber(sel_item:sub(2))
    end
  end
  
  -- Return table of selected regions
  return names
end

function acendan.getRegionManager()
  local title = reaper.JS_Localize("Region/Marker Manager", "common")
  local arr = reaper.new_array({}, 1024)
  reaper.JS_Window_ArrayFind(title, true, arr)
  local adr = arr.table()
  for j = 1, #adr do
    local hwnd = reaper.JS_Window_HandleFromAddress(adr[j])
    -- verify window by checking if it also has a specific child.
    if reaper.JS_Window_FindChildByID(hwnd, 1056) then -- 1045:ID of clear button
      return hwnd
    end 
  end
end

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
  local fileHandle, strError = io.open(folder .. "\\*.*","r")
  if fileHandle ~= nil then
    io.close(fileHandle)
    return true
  else
    if string.match(strError,"No such file or directory") then
      return false
    else
      return true
    end
  end
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
function acendan.getFileName(filename)
  return filename:match("^.+/(.+)$")
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

-- Gets current platform and separator
-- USE THIS IN YOUR SCRIPTS:
-- local win, sep = acendan.getOS()
function acendan.getOS()
  local win = string.find(reaper.GetOS(), "Win") ~= nil
  local sep = win and '\\' or '/'
  return win, sep
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ RENDERING ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
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
  
  if reaper.file_exists( reaper.GetResourcePath() .. "\\Effects\\ACendan Scripts\\JSFX\\" .. jsfx_name ) then
    return true
  else
    return false
  end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

return acendan
