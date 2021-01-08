-- @description Lock Items Horizontal
-- @author Aaron Cendan
-- @version 1.0
-- @metapackage
-- @provides
--   [main] . > acendan_Lock item horizontal movement while key combo held (background).lua
-- @link https://aaroncendan.me
-- @about
-- ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓  IMPORTANT! READ ME!  ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
--   *
--   * This script is a background script, meaning it will run continuously in the background to check if a key combo is held
--   * This means that you should NOT set up a traditional keyboard shortcut for it in the actions menu. This script will NOT work if you do that.
--   * Please set up a shortcut key in the User Config section below.

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
        reaper.Main_OnCommand( 40577, 0 ) -- Set item left/right locking mode
        reaper.Main_OnCommand( 40581, 0 ) -- Clear item up/down locking mode
        reaper.Main_OnCommand( 40569, 0 ) -- Enable locking
        toggle_state = 1
      end
    else
      if toggle_state == 1 then
        reaper.Main_OnCommand( 40570, 0 ) -- Disable locking
        reaper.Main_OnCommand( 40578, 0 ) -- Clear item left/right locking mode
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

-- Check for first time launch
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
      reaper.MB("This script requires the JS Reascript API. Please install it via ReaPack.\n\nExtensions > ReaPack > Browse Packages > js_ReaScriptAPI: API functions for ReaScripts","Lock Horizontal Error")  
    end
  else
    reaper.MB("Key variable is not set to a valid key! Please double check the options avaialable in the 'keys' table. Must be ALL CAPS!","Lock Horizontal Error",0)
  end
else
  reaper.SetExtState( "acendan_Lock item horizontal", "first_time", "https://youtu.be/dQw4w9WgXcQ", true )
  reaper.MB("This script requires some basic setup! Please click 'Edit Action' and follow the instructions under About and User Config.","Lock Horizontal Setup",0)
end
