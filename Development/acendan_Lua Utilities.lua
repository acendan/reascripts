-- @description ACendan Lua Utilities
-- @author Aaron Cendan
-- @version 3.7
-- @metapackage
-- @provides
--   [main] . > acendan_Lua Utilities.lua
-- @link https://aaroncendan.me
-- @about
--   # Lua Utilities
--   By Aaron Cendan - July 2020
--
--   ### Upper Section - Templates
--   * Provides a basic template for typical lua reascripts and background scripts
--
--   ### Lower Section - Utilities
--   * Packageable as a library to reference in future scripts
--   * Pretty much just a big pile of helper functions.
--   * Ctrl + F is your friend here.
--   * I wish I kept better documentation of the original script creators, as not all of these are my own original functions.
--   * If you recognize one of your functions in here, I will gladly credit you directly next to that script, reach out at my website above.

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
acendan_LuaUtils = reaper.GetResourcePath()..'/scripts/ACendan Scripts/Development/acendan_Lua Utilities.lua'
if reaper.file_exists( acendan_LuaUtils ) then
  dofile( acendan_LuaUtils ); if not acendan or acendan.version() < 2.5 then acendan.msg('This script requires a newer version of ACendan Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"ACendan Lua Utilities"); return end
else
  reaper.MB("This script requires ACendan Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'ACendan Lua Utilities'","ACendan Lua Utilities",0); return
end

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
acendan_LuaUtils = reaper.GetResourcePath()..'/scripts/ACendan Scripts/Development/acendan_Lua Utilities.lua'
if reaper.file_exists( acendan_LuaUtils ) then
  dofile( acendan_LuaUtils ); if not acendan or acendan.version() < 2.5 then acendan.msg('This script requires a newer version of ACendan Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"ACendan Lua Utilities"); return end
else
  reaper.MB("This script requires ACendan Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'ACendan Lua Utilities'","ACendan Lua Utilities",0); return
end

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
acendan_LuaUtils = reaper.GetResourcePath()..'/scripts/ACendan Scripts/Development/acendan_Lua Utilities.lua'
if reaper.file_exists( acendan_LuaUtils ) then
  dofile( acendan_LuaUtils ); if not acendan or acendan.version() < 2.5 then acendan.msg('This script requires a newer version of ACendan Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"ACendan Lua Utilities"); return end
else
  reaper.MB("This script requires ACendan Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'ACendan Lua Utilities'","ACendan Lua Utilities",0); return
end
]]--

acendan = {}

function acendan.version()
  local file = io.open((reaper.GetResourcePath()..'/scripts/ACendan Scripts/Development/acendan_Lua Utilities.lua'):gsub('\\','/'),"r")
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

-- Check if a table contains a value in any one of its keys // returns Boolean
function acendan.tableContainsVal(table, val)
  for index, value in ipairs(table) do
      if value == val then
          return true
      end
  end
  return false
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
  msg("Project has no items!")
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
  msg("No items selected!")
end
]]--

-- Save initially selected items to table
function acendan.saveSelectedItems (table)
  for i = 1, reaper.CountSelectedMediaItems(0) do
    table[i] = reaper.GetSelectedMediaItem(0, i-1)
  end
end

-- Restore selected items from table. Requires tableLength() above
function acendan.restoreSelectedItems(table)
  reaper.Main_OnCommand(40289, 0) -- Unselect all media items
  for i = 1, acendan.tableLength(table) do
    reaper.SetMediaItemSelected( table[i], true )
  end
end

reaper.Main_OnCommand(40289,0) -- Unselect all items

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
  msg("Project has no tracks!")
end
    
-- Loop through selected tracks
local num_sel_tracks = reaper.CountSelectedTracks( 0 )
if num_sel_tracks > 0 then
  for i = 0, num_sel_tracks-1 do
    local track = reaper.GetSelectedTrack(0,i)
    -- Process track
  end
else
  msg("No tracks selected!")
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
  for i = 1, acendan.tableLength(table) do
    reaper.SetTrackSelected( table[i], true )
  end
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
  msg("Project has no regions!")
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
  msg("You need to make a time selection!")
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
function acendan.getSelectedRegions()
  local hWnd = acendan.getRegionManager()
  if hWnd == nil then return end  

  local container = reaper.JS_Window_FindChildByID(hWnd, 1071)

  sel_count, sel_indexes = reaper.JS_ListView_ListAllSelItems(container)
  if sel_count == 0 then return end 

  names = {}
  i = 0
  for index in string.gmatch(sel_indexes, '[^,]+') do 
    i = i+1
    local sel_item = reaper.JS_ListView_GetItemText(container, tonumber(index), 1)
    if sel_item:find("R") ~= nil then
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
  msg("Project has no markers!")
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
  msg("You need to make a time selection!")
end
]]--

-- Get selected markers in Rgn Mrkr Manager using JS_Reaper API, requires getRegionManager
--[[ EXAMPLE USAGE

  local sel_mkr_table = getSelectedMarkers()
  if sel_mkr_table then 
    for _, mkr_idx in pairs(sel_mkr_table) do 
      dbg(mkr_idx)
    end
  else
    msg("No markers selected!\n\nPlease go to View > Region/Marker Manager to select regions.") 
  end
  
]]--
function acendan.getSelectedMarkers()
  local hWnd = acendan.getRegionManager()
  if hWnd == nil then return end  

  local container = reaper.JS_Window_FindChildByID(hWnd, 1071)

  sel_count, sel_indexes = reaper.JS_ListView_ListAllSelItems(container)
  if sel_count == 0 then return end 

  names = {}
  i = 0
  for index in string.gmatch(sel_indexes, '[^,]+') do 
    i = i+1
    local sel_item = reaper.JS_ListView_GetItemText(container, tonumber(index), 1)
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
   dbg(dir_file)
   
   fil_idx = fil_idx + 1
until not reaper.EnumerateFiles( directory, fil_idx )

-- Loop through subdirectories in a directory
local dir_idx = 0
repeat
  local sub_dir = reaper.EnumerateSubdirectories( directory, dir_idx)
  -- Do stuff to the sub_dirs
  dbg(sub_dir)
  
  dir_idx = dir_idx + 1
until not  reaper.EnumerateSubdirectories( directory, dir_idx )
]]---


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
-- Count selected items media explorer // returns Number
function acendan.countSelectedItemsMediaExplorer()
  local hWnd = reaper.JS_Window_Find(reaper.JS_Localize("Media Explorer","common"), true)
  if hWnd == nil then msg("Unable to find media explorer. Try going to:\n\nExtensions > ReaPack > Browse Packages\n\nand re-installing the JS_Reascript extension.") return end  
  
  local container = reaper.JS_Window_FindChildByID(hWnd, 0)
  local file_LV = reaper.JS_Window_FindChildByID(container, 1000)
  
  sel_count, sel_indexes = reaper.JS_ListView_ListAllSelItems(file_LV)
  if sel_count == 0 then 
    acendan.msg("No items selected in media explorer!","Media Explorer Items")
  elseif sel_count == 1 then
    acendan.msg("1 item selected in media explorer.","Media Explorer Items")
  else
    acendan.msg(sel_count .. " items selected in media explorer.","Media Explorer Items")
  end 
  
  return sel_count
end

-- Get selected item details media explorer
function acendan.getSelectedItemsDetailsMediaExplorer()
  local hWnd = reaper.JS_Window_Find(reaper.JS_Localize("Media Explorer","common"), true)
  if hWnd == nil then acendan.msg("Unable to find media explorer. Try going to:\n\nExtensions > ReaPack > Browse Packages\n\nand re-installing the JS_Reascript extension.","Media Explorer Items") return end  
  
  local container = reaper.JS_Window_FindChildByID(hWnd, 0)
  local file_LV = reaper.JS_Window_FindChildByID(container, 1000)
  
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
    local winHWND = reaper.JS_Window_Find(reaper.JS_Localize("Media Explorer", "common"),true)
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
  msg("Please install the JS_ReaScriptAPI REAPER extension, available in ReaPack, under the ReaTeam Extensions repository.\n\nExtensions > ReaPack > Browse Packages\n\nFilter for 'JS_ReascriptAPI'. Right click to install.")
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
