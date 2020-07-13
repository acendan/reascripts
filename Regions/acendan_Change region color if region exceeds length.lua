-- @description Change region color if region exceeds length
-- @author Aaron Cendan
-- @version 1.0
-- @link https://aaroncendan.me
-- @about Change Region Color if Region Exceeds Length
--  This is a toggle script. If prompted whether you should terminate or start new instances,
--  click "Remember my answer" and "Terminate". Works well on toolbars.

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARIABLES - EDIT THESE ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- SET MAX REGION LENGTH -- Seconds, can be a float like 12.3456
-- Any region longer than this will have its color changed.
local max_len = 10

-- SET LONG REGION COLOR -- Integers, 0-255
local red, green, blue = 0, 255, 100

-- SET REFRESH RATE -- Seconds, 0.1 - 3
local refresh_rate = 0.3


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARIABLES - DO NOT EDIT ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Get default color for short regions from theme
local default_short_color = reaper.GetThemeColor( "region", 0 )

-- Get action context info
local _, _, section, cmdID = reaper.get_action_context()

-- Initialize original color table (don't edit this)
local original_color_table = {}

-- Initialize region index list
local rgn_idx_list = ""

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~ SETUP ~~~~~~~~~~~~~~~~~~~~~~~  
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function setup()
  -- Clamp values
  red   = clampValue(red, 0, 255)
  green = clampValue(green, 0, 255)
  blue  = clampValue(blue, 0, 255)
  
  refresh_rate = clampValue(refresh_rate, 0.1, 5)
  
  -- Convert to hex
  long_color = rgb2int(red, green, blue)
  
  -- Timing control
  start = reaper.time_precise()
  check_time = start
  
  -- Toggle command state on
  reaper.SetToggleCommandState( section, cmdID, 1 )
  reaper.RefreshToolbar2( section, cmdID )
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~~~~~~~~~  
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function main()

  local now = reaper.time_precise()

  if now - check_time >= refresh_rate then
    local ret, num_markers, num_regions = reaper.CountProjectMarkers( 0 )
    if num_regions > 0 then
      local num_total = num_markers + num_regions
      i = 0
      while i < num_total do
        local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, i )
        if isrgn then
          rgn_idx_list = rgn_idx_list .. " " .. tostring(markrgnindexnumber)
          
          local rgnlen = rgnend - pos
          local in_table = setContains(original_color_table, markrgnindexnumber)
          
          -- ~~~~~~~~~~~~
          -- LONG REGIONS
          -- ~~~~~~~~~~~~
          if rgnlen >= max_len then
            if color ~= long_color then
              -- Set original color value to current color
              original_color_table[markrgnindexnumber] = color
              
              -- Set color of region to long color from global vars
              reaper.SetProjectMarker3( 0, markrgnindexnumber, isrgn, pos, rgnend, name, long_color )
            end
          
          -- ~~~~~~~~~~~~~
          -- SHORT REGIONS
          -- ~~~~~~~~~~~~~
          else
            -- Check to see if color is stored for short regions
            if in_table then
              -- Get stored value and current value
              original_color = original_color_table[markrgnindexnumber]
              current_color = color
              
              -- If stored value ~= current value, then change color
              if current_color ~= original_color then
                if original_color ~= 0 then reaper.SetProjectMarker3( 0, markrgnindexnumber, isrgn, pos, rgnend, name, original_color )
                else reaper.SetProjectMarker3( 0, markrgnindexnumber, isrgn, pos, rgnend, name, default_short_color ) end
              end

            else
              -- If default color, then use the short color value above. Otherwise, use current color
              if color ~= 0 then
                r, g, b = reaper.ColorFromNative( color )
                original_color_to_hex = rgb2int(r,g,b)
                original_color_table[markrgnindexnumber] = original_color_to_hex
              else
                original_color_table[markrgnindexnumber] = default_short_color
              end
            end
          end
        end
        i = i + 1
      end
      
      -- Clean up original color table (check for deleted regions and remove entries)
      for key, value in pairs(original_color_table) do
        if not string.find(rgn_idx_list, key) then
          original_color_table[key] = nil
        end
      end
    end
    rgn_idx_list = ""
    check_time = now
  end

  reaper.defer(main)
  
end

function Exit()
  reaper.UpdateArrange()
  reaper.SetToggleCommandState( section, cmdID, 0 )
  reaper.RefreshToolbar2( section, cmdID )
  return reaper.defer(function() end)
end


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~ UTILITIES ~~~~~~~~~~~~~~~~~~~~~  
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~ Clamp Value Range ~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
function clampValue(input,min,max)
  local clamped_val = math.min(math.max(input,min),max)
  --debug("Original value: " .. input .. "\n" .. "Clamped value: " ..  clamped_val)
  return clamped_val
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~ Check Set Contains ~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
function setContains(set, key)
    return set[key] ~= nil
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~ RGB 2 INT ~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
function rgb2int ( R, G, B )
  local new_color = (R + 256 * G + 65536 * B)|16777216
  return new_color
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~ Get Table Length ~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
function tableLength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~~~~~~~~  
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

setup()
reaper.atexit(Exit)
main()
