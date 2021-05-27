-- @description SoundMiner iXML Metadata Columns
-- @author Aaron Cendan
-- @version 1.1
-- @metapackage
-- @provides
--   [main=mediaexplorer] .
-- @link https://aaroncendan.me

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Table of iXML Columns
local iXML = {}
iXML["IXML:USER:CATID"]          = "CatID"
iXML["IXML:USER:CATEGORY"]       = "Category"
iXML["IXML:USER:SUBCATEGORY"]    = "SubCategory"
iXML["IXML:USER:DESCRIPTION"]    = "Description"
iXML["IXML:USER:NOTES"]          = "Notes"
iXML["IXML:USER:MICROPHONE"]     = "Microphone"
iXML["IXML:USER:MICPERSPECTIVE"] = "MicPerspective"
iXML["IXML:USER:LIBRARY"]        = "Library"
iXML["IXML:USER:DESIGNER"]       = "Designer"
iXML["IXML:USER:SHOOTDATE"]      = "ShootDate"
iXML["IXML:USER:CATEGORYFULL"]   = "CategoryFull"
iXML["IXML:USER:RECTYPE"]        = "RecType"
iXML["IXML:USER:SHORTID"]        = "ShortID"
iXML["IXML:USER:TRACKYEAR"]      = "TrackYear"
iXML["IXML:USER:KEYWORDS"]       = "Keywords"
iXML["IXML:USER:SHOW"]           = "Show"
iXML["IXML:USER:SOURCE"]         = "Source"
iXML["IXML:USER:LOCATION"]       = "Location"
iXML["IXML:USER:FXNAME"]         = "FXName"
iXML["IXML:USER:TRACKTITLE"]     = "TrackTitle"
iXML["IXML:USER:ARTIST"]         = "Artist"
iXML["IXML:USER:LONGID"]         = "LongID"
iXML["IXML:USER:VOLUME"]         = "Volume"
iXML["IXML:USER:TRACK"]          = "Track"
iXML["IXML:USER:MANUFACTURER"]   = "Manufacturer"
iXML["IXML:USER:RECMEDIUM"]      = "RecMedium"
iXML["IXML:USER:CDTITLE"]        = "CDTitle"
iXML["IXML:USER:RATING"]         = "Rating"
iXML["IXML:USER:URL"]            = "URL"
iXML["IXML:USER:RELEASEDATE"]    = "ReleaseDate"
iXML["IXML:USER:OPENTIER"]       = "OpenTier"
iXML["IXML:USER:USERCATEGORY"]   = "UserCategory"
iXML["IXML:USER:VENDORCATEGORY"] = "VendorCategory"

-- Other globals
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local script_directory = ({reaper.get_action_context()})[2]:sub(1,({reaper.get_action_context()})[2]:find("\\[^\\]*$"))
local ini_section = "reaper_explorer"
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
      local ret = reaper.BR_Win32_WritePrivateProfileString(ini_section,"user" .. tostring(i) .. "_key",k,ini_file)
      local ret2 = reaper.BR_Win32_WritePrivateProfileString(ini_section,"user" .. tostring(i) .. "_desc",v,ini_file)
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

