-- @description SoundMiner iXML Metadata Columns
-- @author Aaron Cendan
-- @version 1.4
-- @metapackage
-- @provides
--   [main=mediaexplorer] .
-- @link https://aaroncendan.me
-- @changelog
--   # Set newly added columns to custom, instead of Read-Only

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Load lua utilities
acendan_LuaUtils = reaper.GetResourcePath()..'/scripts/ACendan Scripts/Development/acendan_Lua Utilities.lua'
if reaper.file_exists( acendan_LuaUtils ) then dofile( acendan_LuaUtils ); if not acendan or acendan.version() < 4.4 then acendan.msg('This script requires a newer version of ACendan Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"ACendan Lua Utilities"); return end else reaper.ShowConsoleMsg("This script requires ACendan Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'ACendan Lua Utilities'"); return end

-- Table of iXML Columns
local iXML = {}
iXML["IXML:USER:CatID"]          = "CatID"
iXML["IXML:USER:Category"]       = "Category"
iXML["IXML:USER:SubCategory"]    = "SubCategory"
iXML["IXML:USER:Description"]    = "Description"
iXML["IXML:USER:Notes"]          = "Notes"
iXML["IXML:USER:Microphone"]     = "Microphone"
iXML["IXML:USER:MicPerspective"] = "MicPerspective"
iXML["IXML:USER:Library"]        = "Library"
iXML["IXML:USER:Designer"]       = "Designer"
iXML["IXML:USER:ShootDate"]      = "ShootDate"
iXML["IXML:USER:CategoryFull"]   = "CategoryFull"
iXML["IXML:USER:RecType"]        = "RecType"
iXML["IXML:USER:ShortID"]        = "ShortID"
iXML["IXML:USER:TrackYear"]      = "TrackYear"
iXML["IXML:USER:Keywords"]       = "Keywords"
iXML["IXML:USER:Show"]           = "Show"
iXML["IXML:USER:Source"]         = "Source"
iXML["IXML:USER:Location"]       = "Location"
iXML["IXML:USER:FXName"]         = "FXName"
iXML["IXML:USER:TrackTitle"]     = "TrackTitle"
iXML["IXML:USER:Artist"]         = "Artist"
iXML["IXML:USER:LongID"]         = "LongID"
iXML["IXML:USER:Volume"]         = "Volume"
iXML["IXML:USER:Track"]          = "Track"
iXML["IXML:USER:Manufacturer"]   = "Manufacturer"
iXML["IXML:USER:RecMedium"]      = "RecMedium"
iXML["IXML:USER:CDTitle"]        = "CDTitle"
iXML["IXML:USER:Rating"]         = "Rating"
iXML["IXML:USER:URL"]            = "URL"
iXML["IXML:USER:ReleaseDate"]    = "ReleaseDate"
iXML["IXML:USER:OpenTier"]       = "OpenTier"
iXML["IXML:USER:UserCategory"]   = "UserCategory"
iXML["IXML:USER:VendorCategory"] = "VendorCategory"

-- Other globals
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local script_directory = ({reaper.get_action_context()})[2]:sub(1,({reaper.get_action_context()})[2]:find("\\[^\\]*$"))
local win, sep = acendan.getOS()
local ini_section = win and "reaper_explorer" or "reaper_sexplorer" -- For some reason, it's 'sexplorer' on Mac
local dbg = false

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function main()
  local reaper_version = tonumber(reaper.GetAppVersion():sub(1,4))
  if reaper_version >= 6.29 then
    AddIXML()
  else
    -- ~~~~~~~~~ PRE-RELEASE BUILDS ONLY
    if dbg then AddIXML() else
    -- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    reaper.MB("This script requires Reaper v6.29 or greater! Please update Reaper.","ERROR: Update Reaper!",0) end
  end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ UTILITIES ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Adds the IXML columns to the Media Explorer
function AddIXML()
  local ini_file = reaper.get_ini_file()
  local i = 0
  repeat 
    -- Check .ini file for custom user columns
    local ret,val = reaper.BR_Win32_GetPrivateProfileString(ini_section,"user" .. tostring(i) .. "_key","",ini_file)
    -- Check if custom user column is already in table
    if tableContainsKey(iXML,val) then
      if dbg then reaper.ShowConsoleMsg("Found existing entry for: " .. iXML[val] .. "\n") end
      iXML[val] = nil
    end
    i = i+1
  until ret == 0
  
  i = i-1
  
  -- Loop through iXML metadata table  
  if tableLength(iXML) > 0 then 
    for k, v in pairs(iXML) do
      -- Set metadata scheme/key
      local ret = reaper.BR_Win32_WritePrivateProfileString(ini_section,"user" .. tostring(i) .. "_key",k,ini_file)
      -- Set column description
      local ret2 = reaper.BR_Win32_WritePrivateProfileString(ini_section,"user" .. tostring(i) .. "_desc",v,ini_file)
      -- Set custom entry flag
      local ret3 = reaper.BR_Win32_WritePrivateProfileString(ini_section,"user" .. tostring(i) .. "_flags","1",ini_file)
      if ret and ret2 then 
        if dbg then reaper.ShowConsoleMsg("Succesfully added entry: " .. k .. " - " .. v .. "\n") end
      else
        reaper.ShowConsoleMsg("ERROR! Failed to add entry: " .. k .. " - " .. v .. "\n")
      end
      i = i + 1
    end
    
    -- Force refresh the media explorer
    reaper.Main_OnCommand(50124,0) -- Show/hide media explorer
    reaper.Main_OnCommand(50124,0) -- Show/hide media explorer
    reaper.OpenMediaExplorer("",false)
    
    reaper.MB("Succesfully updated Media Explorer metadata columns!\n\nTo populate new columns: select your file(s), right click, and run 'Re-read metadata from media'.","Media Explorer Metadata",0)
  else
    -- Force refresh the media explorer
    reaper.Main_OnCommand(50124,0) -- Show/hide media explorer
    reaper.Main_OnCommand(50124,0) -- Show/hide media explorer
    reaper.OpenMediaExplorer("",false)
    
    reaper.MB("All SoundMiner iXML metadata columns are already set up!\n\nIf you don't see them, try right clicking on a Media Explorer column and checking whether your User Columns at the bottom of the menu are enabled/visible.","Media Explorer Metadata",0)
  end
end

-- Check if a table contains a key // returns Boolean
function tableContainsKey(table, key)
    return table[key] ~= nil
end

-- Get table length for non numeric keys (unlike # or table.getn function)
function tableLength(table)
  local i = 0
  for _ in pairs(table) do i = i + 1 end
  return i
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock()

main()

reaper.Undo_EndBlock(script_name,-1)

reaper.PreventUIRefresh(-1)

reaper.UpdateArrange()

