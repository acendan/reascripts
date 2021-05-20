-- @description SoundMiner iXML Metadata Render Settings
-- @author Aaron Cendan
-- @version 1.1
-- @metapackage
-- @provides
--   [main] . > acendan_Set up SoundMiner iXML metadata markers in project render metadata settings.lua
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

-- Other globals
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local script_directory = ({reaper.get_action_context()})[2]:sub(1,({reaper.get_action_context()})[2]:find("\\[^\\]*$"))

function main()
  for k, v in pairs(iXML) do
    if v == "RecType" then
      local ret, str = reaper.GetSetProjectInfo_String( 0, "RENDER_METADATA", k .. "|$bitdepth/$sampleratekk", true)
    elseif v == "ReleaseDate" then
      local ret, str = reaper.GetSetProjectInfo_String( 0, "RENDER_METADATA", k .. "|$date", true)
    elseif v == "LongID" then
      local ret, str = reaper.GetSetProjectInfo_String( 0, "RENDER_METADATA", k .. "|$marker(CatID)", true)
    elseif v == "Source" then
      local ret, str = reaper.GetSetProjectInfo_String( 0, "RENDER_METADATA", k .. "|$marker(Show)", true)
    elseif v == "Artist" then
      local ret, str = reaper.GetSetProjectInfo_String( 0, "RENDER_METADATA", k .. "|$marker(Designer)", true)
    else
      local ret, str = reaper.GetSetProjectInfo_String( 0, "RENDER_METADATA", k .. "|$marker(" .. v .. ")", true )
    end
  end
end


reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock()

main()

reaper.Undo_EndBlock(script_name,-1)

reaper.PreventUIRefresh(-1)

