-- @description Random Glitchy Stutter Generator
-- @author Aaron Cendan
-- @version 1.0
-- @metapackage
-- @provides
--   [main] . > acendan_Random glitchy stutter generator.lua
-- @link https://aaroncendan.me
-- @about
--  - This script is pretty whacky, and the best way to get
--  a feel for it is to just plug in some numbers and try it out.
--  - I recommend starting with something like max 30 splices
--  and max slice length of 150ms.
--  - "Create automatic fade-in/fade-out for new items"
--  in Media Item Defaults of the preferences window will 
--  play a big role in the pops/smoothness of the glitches

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~ GLOBAL VARIABLES ~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Retrieve stored data set by user
local ret_rand,  rand_max = reaper.GetProjExtState( 0, "Glitch_Generator", "Rand_Max" )
local ret_len,  slice_len = reaper.GetProjExtState( 0, "Glitch_Generator", "Slice_Length" )

-- Fixed minimum slice length, in seconds. Default is one sample at 48khz sample rate.
-- Change this if you want; it's just to prevent cuts smaller than a sample
local min_slice_len  = 0.020833
-- 44.1khz min_slice = 0.022676
-- 48khz min_slice   = 0.020833
-- 96khz min_slice   = 0.010417
-- 192khz min_slice  = 0.005208

-- Validation booleans
local get_user_input = false
local valid_input = true

-- Selected items tables
local init_sel_items = {}
local glitched_items = {}


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~ STUTTER GENERATOR ~~~~~~~~~~~~~~~~  
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function glitchyStutterGenerator()

  reaper.Undo_BeginBlock()

  -- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- ~ SECTION 1: GET USER INPUT ~
  -- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- Check to see if user has a stored value that's safe to use
  if rand_max == "" or slice_len == "" or not ret_rand or not ret_len then
    -- If not, prompt the user for new values
    get_user_input = true
  end

  -- Prompt user for input
  if get_user_input then
    -- Show message box with two user text inputs
    ret_input, user_input = reaper.GetUserInputs("Glitch Generator",  2,
                            "Max # of slices (integer, 1-250):,Max slice length (ms, 1-1000):,extrawidth=100",",")
    
    -- Check to see if user cancelled input
    if not ret_input then return end
    
    -- Split user input string
    input_max, input_len = user_input:match("([^,]+),([^,]+)")
    
    -- Format user input
    formatUserInput(input_max, input_len)
  else
    -- Redundancy to check if stored values are valid
    formatUserInput(rand_max, slice_len)
  end
 
 
  -- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- ~ SECTION 2: LOOP THROUGH ITEMS ~
  -- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- Confirm that the user's input was valid
  if valid_input then
    --debug("Max # of random slices: " .. rand_max .. "\n" .. "Slice length: " .. slice_len)
    
    -- Check to see if the user selected any items
    local num_items = reaper.CountSelectedMediaItems( 0 )
    if num_items > 0 then
    
      -- If there are items selected, loop through each one
      -- For loops automatically increment by one, but can take an optional 3rd argument for step size
      for i, item in ipairs( init_sel_items ) do
        
        -- Store the MediaItem's track as a variable; track
        local track = reaper.GetMediaItem_Track( item )
        -- USE SELECTED ITEM TABLE
        
        -- Set current item as only selected item
        reaper.SelectAllMediaItems( 0, false )
        reaper.SetMediaItemSelected( item, true )
        
        -- Get the item starting position and total length
        local item_pos = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
        local item_len = reaper.GetMediaItemInfo_Value( item, "D_LENGTH" )
        local item_end = item_pos + item_len
        --debug("Item start: "  .. item_pos .. "\n" .. "Item end: "    .. item_end .. "\n")
        
        -- Get random number of slices using max value from user
        local rand_slices = math.random(rand_max)
        --debug(rand_slices)
        
        
        -- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        -- ~ SECTION 3: LOOP THROUGH SLICES ~
        -- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        -- Loop through the random slice number
        -- While loops need to be manually incremented
        -- There is also a third kind of looping, called a Repeat > Until loop, which checks the conditional at the end of evaluation
        local j = 0
        while j < rand_slices do
          -- Get a random split position
          local rand_split_pos = randomSlice(item_len)
          
          -- Split item at position. Original item = left side. Middle gap will be cut out.
          local middle_gap = reaper.SplitMediaItem( item, item_pos + rand_split_pos )
          
          -- If split was succesful then... 
          if middle_gap then
            -- Get a random gap length (/1000 because it's in ms)
            local rand_gap_len = randomSlice(slice_len)/1000
            
            -- Confirm gap random gap length is larger than a sample at 48k
            rand_gap_len = math.max(min_slice_len, rand_gap_len)
            
            -- Right side = right of gap.
            local right_side = reaper.SplitMediaItem( middle_gap, item_pos + rand_split_pos + rand_gap_len )
            
            -- Delete the gap
            reaper.DeleteTrackMediaItem( track, middle_gap )
          end

          j = j + 1
        end -- End loop through each random slice
        
        -- Glue the spliced up item back together
        reaper.Main_OnCommand( 41588, 1 )
        
        -- Add the glued item to the glitched items table
        local glued_item = reaper.GetSelectedMediaItem( 0, 0 )
        appendToTable(glitched_items, glued_item)
        
      end -- End loop through selected items table
      
    else
      debug("No items selected!")
    end
  else    
    -- This is a great place to put in more detailed debug text (i.e. what specifically was wrong)
    debug("Your input was invalid! Please try again.")
    
    -- Get new user input
    -- THIS IS CRITICAL. Otherwise, it will bypass getting user input and failing again in an infinite loop. 
    -- User then needs to force close Reaper. 
    get_user_input = true
   
    -- Run this script again
    glitchyStutterGenerator()
  end

  reaper.Undo_EndBlock("Glitch Generator", -1)
end


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~ UTILITIES ~~~~~~~~~~~~~~~~~~~~~  
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~ Format/Store Input ~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
function formatUserInput(input_max, input_len)
  -- Convert string values to numbers
  rand_max = tonumber(input_max)
  slice_len = tonumber(input_len)
  
  -- If valid numbers (nil otherwise), then save them to the project data
  if rand_max and slice_len then
    -- Round values to whole numbers if necessary
    rand_max  = roundValue(rand_max)
    slice_len = roundValue(slice_len)
    
    -- Clamp values within specified range
    rand_max  = clampValue(rand_max,  1, 250)
    slice_len = clampValue(slice_len, 1, 1000)
    
    -- Store values in project data
    reaper.SetProjExtState( 0, "Glitch_Generator", "Rand_Max", rand_max )
    reaper.SetProjExtState( 0, "Glitch_Generator", "Slice_Length", slice_len )
    
    -- Set global input validity boolean
    valid_input = true
  else
    valid_input = false
  end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~ Clamp Value Range ~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
function clampValue(input,min,max)
  local clamped_val = math.min(math.max(input,min),max)
  --debug("Original value: " .. input .. "\n" .. "Clamped value: " ..  clamped_val)
  return clamped_val
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~ Round Value Up ~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
function roundValue(input)
  local rounded_val  = math.floor(input + 0.5)
  --debug("Original value: " .. input .. "\n" .. "Rounded value: " ..  rounded_val)
  return rounded_val
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~ Random Slice Len ~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
function randomSlice(length)
  -- The random function doesn't like when the length is too small
  if length > 0.0001 then 
    -- The Lua function math.random returns a whole integer, so we multiply and divide the length
    -- by 10000 to give more precision to the randomness (rather than just whole second split values)
    local rand_pos = math.random(roundValue(length * 10000))/10000
    return rand_pos
  else
    return 0.001
  end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~ Debug Message Tool ~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
function debug(msg)
  reaper.MB(msg, "Glitch Generator", 0)
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~ Save Selected Items ~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
function saveSelectedItems (table)
  for i = 1, reaper.CountSelectedMediaItems(0) do
    table[i] = reaper.GetSelectedMediaItem(0, i-1)
  end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~ Restore Selected Items ~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
function restoreSelectedItems(table)
  for i = 1, tableLength(table) do
    reaper.SetMediaItemSelected( table[i], true )
  end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~ Get Table Length ~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
function tableLength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~ Append To Table ~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
function appendToTable(table, item)
  table[#table+1] = item
end


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~~~~~~~~~~  
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
reaper.PreventUIRefresh(1)

-- Save a table of the selected items at the start
saveSelectedItems( init_sel_items )

-- Run the glitch generator
glitchyStutterGenerator()

-- Reselect table of the newly glitched up items
restoreSelectedItems( glitched_items )

reaper.PreventUIRefresh(-1)

reaper.UpdateArrange()
