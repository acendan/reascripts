-- @description UCS Renaming Tool
-- @author Aaron Cendan
-- @version 8.2.6
-- @metapackage
-- @provides
--   [main] . > acendan_UCS Renaming Tool.lua
-- @link https://aaroncendan.me
-- @about
--   # Universal Category System (UCS) Renaming Tool
--   Developed by Aaron Cendan
--   https://aaroncendan.me
--   aaron.cendan@gmail.com
--
--   ### Useful Resources
--   * Blog post: https://www.aaroncendan.me/side-projects/ucs
--   * Tutorial vid: https://youtu.be/fO-2At7eEQ0
--   * Universal Category System: https://universalcategorysystem.com
--   * UCS Google Drive: https://drive.google.com/drive/folders/1dkTIZ-ZZAY9buNcQIN79PmuLy1fPNqUo
--
--   ### Toolbar Icon Setup
--   * If you would like to set up the UCS logo as a toolbar icon, go to:
--        REAPER\reaper_www_root\ucs_libraries\ucs_toolbar_icon_black.png
--   * Then copy the image(s) from that folder into:
--        REAPER\Data\toolbar_icons
--   * It should then show up when you are customizing toolbar icons in Reaper.
-- @changelog
--   * WIP - Support for NVK Folder Items

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARIABLES ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Initialize global var for full name, see setFullName()
local ucs_full_name = ""

-- Init copy settings (EDIT VIA SETTINGS MENU OF THE WEB INTERFACE)
local copy_to_clipboard = false
local copy_without_processing = false
local line_to_copy = ""

-- Toggle for debugging UCS input with message box & opening UCS tool on script file save
local debug_mode = false

-- Toggle for copying metadata to clipboard for Julibrary and other crowdsource/personal metadata sheets
local julibrary_mode = false      -- SET THIS TO 'true' IN ORDER TO COPY AFTER SUBMITTING IN THE TOOL 
local julibrary_headers = false   -- SET THIS TO 'true' TO INCLUDE ROW HEADERS WHILE COPYING

local julibrary_metadata = ""

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ FETCH EXT STATES ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--region Fetch Extended States
-- Retrieve stored projextstate data set by web interface
local ret_cat,  ucs_cat  = reaper.GetProjExtState( 0, "UCS_WebInterface", "Category" )
local ret_scat, ucs_scat = reaper.GetProjExtState( 0, "UCS_WebInterface", "Subcategory" )
local ret_usca, ucs_usca = reaper.GetProjExtState( 0, "UCS_WebInterface", "UserCategory" )
local ret_vend, ucs_vend = reaper.GetProjExtState( 0, "UCS_WebInterface", "VendorCategory" )
local ret_id,   ucs_id   = reaper.GetProjExtState( 0, "UCS_WebInterface", "CatID" )
local ret_name, ucs_name = reaper.GetProjExtState( 0, "UCS_WebInterface", "Name" )
local ret_num,  ucs_num  = reaper.GetProjExtState( 0, "UCS_WebInterface", "Number" )
local ret_enum, ucs_enum = reaper.GetProjExtState( 0, "UCS_WebInterface", "EnableNum" )
local ret_ixml, ucs_ixml = reaper.GetProjExtState( 0, "UCS_WebInterface", "iXMLMetadata" )
local ret_meta, ucs_meta = reaper.GetProjExtState( 0, "UCS_WebInterface", "ExtendedMetadata" )
local ret_dir,  ucs_dir  = reaper.GetProjExtState( 0, "UCS_WebInterface", "RenderDirectory" )
local ret_mpos, ucs_mpos = reaper.GetProjExtState( 0, "UCS_WebInterface", "MarkerPosition")
local ret_init, ucs_init = reaper.GetProjExtState( 0, "UCS_WebInterface", "Initials" )
local ret_show, ucs_show = reaper.GetProjExtState( 0, "UCS_WebInterface", "Show" )
local ret_type, ucs_type = reaper.GetProjExtState( 0, "UCS_WebInterface", "userInputItems" )
local ret_area, ucs_area = reaper.GetProjExtState( 0, "UCS_WebInterface", "userInputArea" )
local ret_data, ucs_data = reaper.GetProjExtState( 0, "UCS_WebInterface", "Data" )
local ret_caps, ucs_caps = reaper.GetProjExtState( 0, "UCS_WebInterface", "nameCapitalizationSetting")
local ret_frmt, ucs_frmt = reaper.GetProjExtState( 0, "UCS_WebInterface", "fxFormattingSetting")
local ret_copy, ucs_copy = reaper.GetProjExtState( 0, "UCS_WebInterface", "copyResultsSetting")

-- Extended metadata fields
local retm_title,  meta_title  = reaper.GetProjExtState( 0, "UCS_WebInterface", "MetaTitle")
local retm_desc,   meta_desc   = reaper.GetProjExtState( 0, "UCS_WebInterface", "MetaDesc")
local retm_keys,   meta_keys   = reaper.GetProjExtState( 0, "UCS_WebInterface", "MetaKeys")
local retm_recmed, meta_recmed = reaper.GetProjExtState( 0, "UCS_WebInterface", "MetaRecMed")
local retm_dsgnr,  meta_dsgnr  = reaper.GetProjExtState( 0, "UCS_WebInterface", "MetaDsgnr")
local retm_lib,    meta_lib    = reaper.GetProjExtState( 0, "UCS_WebInterface", "MetaLib")
local retm_loc,    meta_loc    = reaper.GetProjExtState( 0, "UCS_WebInterface", "MetaLoc")
local retm_url,    meta_url    = reaper.GetProjExtState( 0, "UCS_WebInterface", "MetaURL")
local retm_mftr,   meta_mftr   = reaper.GetProjExtState( 0, "UCS_WebInterface", "MetaMftr")
local retm_notes,  meta_notes  = reaper.GetProjExtState( 0, "UCS_WebInterface", "MetaNotes")
local retm_persp,  meta_persp  = reaper.GetProjExtState( 0, "UCS_WebInterface", "MetaPersp")
local retm_config, meta_config = reaper.GetProjExtState( 0, "UCS_WebInterface", "MetaConfig")
local retm_mic,    meta_mic    = reaper.GetProjExtState( 0, "UCS_WebInterface", "MetaMic")

-- GBX Mod
local retg_mod,  gbx_mod  = reaper.GetProjExtState( 0, "UCS_WebInterface", "GBXMod")
local retg_suff, gbx_suff = reaper.GetProjExtState( 0, "UCS_WebInterface", "GBXSuffix")

-- ASWG
local ret_aswg_contentType,  aswg_contentType  = reaper.GetProjExtState( 0, "UCS_WebInterface", "ASWGcontentType")
local ret_aswg_project,  aswg_project  = reaper.GetProjExtState( 0, "UCS_WebInterface", "ASWGproject")
local ret_aswg_originatorStudio,  aswg_originatorStudio  = reaper.GetProjExtState( 0, "UCS_WebInterface", "ASWGoriginatorStudio")
local ret_aswg_notes,  aswg_notes  = reaper.GetProjExtState( 0, "UCS_WebInterface", "ASWGnotes")
local ret_aswg_state,  aswg_state  = reaper.GetProjExtState( 0, "UCS_WebInterface", "ASWGstate")
local ret_aswg_editor,  aswg_editor  = reaper.GetProjExtState( 0, "UCS_WebInterface", "ASWGeditor")
local ret_aswg_mixer,  aswg_mixer  = reaper.GetProjExtState( 0, "UCS_WebInterface", "ASWGmixer")
local ret_aswg_fxChainName,  aswg_fxChainName  = reaper.GetProjExtState( 0, "UCS_WebInterface", "ASWGfxChainName")
local ret_aswg_channelConfig,  aswg_channelConfig  = reaper.GetProjExtState( 0, "UCS_WebInterface", "ASWGchannelConfig")
local ret_aswg_ambisonicFormat,  aswg_ambisonicFormat  = reaper.GetProjExtState( 0, "UCS_WebInterface", "ASWGambisonicFormat")
local ret_aswg_ambisonicChnOrder,  aswg_ambisonicChnOrder  = reaper.GetProjExtState( 0, "UCS_WebInterface", "ASWGambisonicChnOrder")
local ret_aswg_ambisonicNorm,  aswg_ambisonicNorm  = reaper.GetProjExtState( 0, "UCS_WebInterface", "ASWGambisonicNorm")
local ret_aswg_isDesigned,  aswg_isDesigned  = reaper.GetProjExtState( 0, "UCS_WebInterface", "ASWGisDesigned")
local ret_aswg_recEngineer,  aswg_recEngineer  = reaper.GetProjExtState( 0, "UCS_WebInterface", "ASWGrecEngineer")
local ret_aswg_recStudio,  aswg_recStudio  = reaper.GetProjExtState( 0, "UCS_WebInterface", "ASWGrecStudio")
local ret_aswg_impulseLocation,  aswg_impulseLocation  = reaper.GetProjExtState( 0, "UCS_WebInterface", "ASWGimpulseLocation")
local ret_aswg_text,  aswg_text  = reaper.GetProjExtState( 0, "UCS_WebInterface", "ASWGtext")
local ret_aswg_efforts,  aswg_efforts  = reaper.GetProjExtState( 0, "UCS_WebInterface", "ASWGefforts")
local ret_aswg_effortType,  aswg_effortType  = reaper.GetProjExtState( 0, "UCS_WebInterface", "ASWGeffortType")
local ret_aswg_projection,  aswg_projection  = reaper.GetProjExtState( 0, "UCS_WebInterface", "ASWGprojection")
local ret_aswg_language,  aswg_language  = reaper.GetProjExtState( 0, "UCS_WebInterface", "ASWGlanguage")
local ret_aswg_timingRestriction,  aswg_timingRestriction  = reaper.GetProjExtState( 0, "UCS_WebInterface", "ASWGtimingRestriction")
local ret_aswg_characterName,  aswg_characterName  = reaper.GetProjExtState( 0, "UCS_WebInterface", "ASWGcharacterName")
local ret_aswg_characterGender,  aswg_characterGender  = reaper.GetProjExtState( 0, "UCS_WebInterface", "ASWGcharacterGender")
local ret_aswg_characterAge,  aswg_characterAge  = reaper.GetProjExtState( 0, "UCS_WebInterface", "ASWGcharacterAge")
local ret_aswg_characterRole,  aswg_characterRole  = reaper.GetProjExtState( 0, "UCS_WebInterface", "ASWGcharacterRole")
local ret_aswg_actorName,  aswg_actorName  = reaper.GetProjExtState( 0, "UCS_WebInterface", "ASWGactorName")
local ret_aswg_actorGender,  aswg_actorGender  = reaper.GetProjExtState( 0, "UCS_WebInterface", "ASWGactorGender")
local ret_aswg_direction,  aswg_direction  = reaper.GetProjExtState( 0, "UCS_WebInterface", "ASWGdirection")
local ret_aswg_director,  aswg_director  = reaper.GetProjExtState( 0, "UCS_WebInterface", "ASWGdirector")
local ret_aswg_fxUsed,  aswg_fxUsed  = reaper.GetProjExtState( 0, "UCS_WebInterface", "ASWGfxUsed")
local ret_aswg_usageRights,  aswg_usageRights  = reaper.GetProjExtState( 0, "UCS_WebInterface", "ASWGusageRights")
local ret_aswg_isUnion,  aswg_isUnion  = reaper.GetProjExtState( 0, "UCS_WebInterface", "ASWGisUnion")
local ret_aswg_accent,  aswg_accent  = reaper.GetProjExtState( 0, "UCS_WebInterface", "ASWGaccent")
local ret_aswg_emotion,  aswg_emotion  = reaper.GetProjExtState( 0, "UCS_WebInterface", "ASWGemotion")
local ret_aswg_composer,  aswg_composer  = reaper.GetProjExtState( 0, "UCS_WebInterface", "ASWGcomposer")
local ret_aswg_artist,  aswg_artist  = reaper.GetProjExtState( 0, "UCS_WebInterface", "ASWGartist")
local ret_aswg_songTitle,  aswg_songTitle  = reaper.GetProjExtState( 0, "UCS_WebInterface", "ASWGsongTitle")
local ret_aswg_genre,  aswg_genre  = reaper.GetProjExtState( 0, "UCS_WebInterface", "ASWGgenre")
local ret_aswg_subGenre,  aswg_subGenre  = reaper.GetProjExtState( 0, "UCS_WebInterface", "ASWGsubGenre")
local ret_aswg_producer,  aswg_producer  = reaper.GetProjExtState( 0, "UCS_WebInterface", "ASWGproducer")
local ret_aswg_musicSup,  aswg_musicSup  = reaper.GetProjExtState( 0, "UCS_WebInterface", "ASWGmusicSup")
local ret_aswg_instrument,  aswg_instrument  = reaper.GetProjExtState( 0, "UCS_WebInterface", "ASWGinstrument")
local ret_aswg_musicPublisher,  aswg_musicPublisher  = reaper.GetProjExtState( 0, "UCS_WebInterface", "ASWGmusicPublisher")
local ret_aswg_rightsOwner,  aswg_rightsOwner  = reaper.GetProjExtState( 0, "UCS_WebInterface", "ASWGrightsOwner")
local ret_aswg_intensity,  aswg_intensity  = reaper.GetProjExtState( 0, "UCS_WebInterface", "ASWGintensity")
local ret_aswg_orderRef,  aswg_orderRef  = reaper.GetProjExtState( 0, "UCS_WebInterface", "ASWGorderRef")
local ret_aswg_isSource,  aswg_isSource  = reaper.GetProjExtState( 0, "UCS_WebInterface", "ASWGisSource")
local ret_aswg_isLoop,  aswg_isLoop  = reaper.GetProjExtState( 0, "UCS_WebInterface", "ASWGisLoop")
local ret_aswg_isFinal,  aswg_isFinal  = reaper.GetProjExtState( 0, "UCS_WebInterface", "ASWGisFinal")
local ret_aswg_isOst,  aswg_isOst  = reaper.GetProjExtState( 0, "UCS_WebInterface", "ASWGisOst")
local ret_aswg_isCinematic,  aswg_isCinematic  = reaper.GetProjExtState( 0, "UCS_WebInterface", "ASWGisCinematic")
local ret_aswg_isLicensed,  aswg_isLicensed  = reaper.GetProjExtState( 0, "UCS_WebInterface", "ASWGisLicensed")
local ret_aswg_isDiegetic,  aswg_isDiegetic  = reaper.GetProjExtState( 0, "UCS_WebInterface", "ASWGisDiegetic")
local ret_aswg_musicVersion,  aswg_musicVersion  = reaper.GetProjExtState( 0, "UCS_WebInterface", "ASWGmusicVersion")
local ret_aswg_isrcId,  aswg_isrcId  = reaper.GetProjExtState( 0, "UCS_WebInterface", "ASWGisrcId")
local ret_aswg_tempo,  aswg_tempo  = reaper.GetProjExtState( 0, "UCS_WebInterface", "ASWGtempo")
local ret_aswg_timeSig,  aswg_timeSig  = reaper.GetProjExtState( 0, "UCS_WebInterface", "ASWGtimeSig")
local ret_aswg_inKey,  aswg_inKey  = reaper.GetProjExtState( 0, "UCS_WebInterface", "ASWGinKey")
local ret_aswg_billingCode,  aswg_billingCode  = reaper.GetProjExtState( 0, "UCS_WebInterface", "ASWGbillingCode")
--endregion

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~ METADATA ~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
local iXML = {}
local iXMLMarkerTbl = {}
-- Built into UCS tool
iXML["IXML:USER:CatID"]          = "CatID"           -- CATId                  
iXML["IXML:USER:Category"]       = "Category"        -- CATEGORY                     
iXML["IXML:USER:SubCategory"]    = "SubCategory"     -- SUBCATEGORY                    
iXML["IXML:USER:CategoryFull"]   = "CategoryFull"    -- CATEGORY-SUBCATEGORY             
iXML["IXML:USER:FXName"]         = "FXName"          -- File name field               
iXML["IXML:USER:Notes"]          = "MetaNotes"       -- Metadata Notes     
iXML["IXML:USER:Show"]           = "Show"            -- Source ID                        
iXML["IXML:USER:UserCategory"]   = "UserCategory"    -- User Category                   
iXML["IXML:USER:VendorCategory"] = "VendorCategory"  -- Vendor Category

-- Extended Metadata Fields
iXML["IXML:USER:TrackTitle"]     = "TrackTitle"      -- SHORT ALL CAPS TITLE to catch attention.    userInputMetaTitle
iXML["IXML:USER:Description"]    = "Description"     -- Detailed description.                       userInputMetaDesc
iXML["IXML:USER:Keywords"]       = "Keywords"        -- Comma separated keywords.                   userInputMetaKeys
iXML["IXML:USER:Microphone"]     = "Microphone"      -- Microphone                                  userInputMetaMic
iXML["IXML:USER:MicPerspective"] = "MicPerspective"  -- MED | INT                                   userInputMetaPersp | userInputMetaIntExt
iXML["IXML:USER:RecType"]        = "RecType"         -- Mono/Stereo/Ambi Mic Configuration
iXML["IXML:USER:RecMedium"]      = "RecMedium"       -- Recorder                                    userInputMetaRecMed
iXML["IXML:USER:Designer"]       = "Designer"        -- The designer/recordist.                     userInputMetaDsgnr
iXML["IXML:USER:ShortID"]        = "ShortID"         -- ^ Shorten to 3 letters first, 3 last        ^^^
iXML["IXML:USER:Location"]       = "Location"        -- Location where it was recorded              userInputMetaLoc
iXML["IXML:USER:URL"]            = "URL"             -- Recordist's URL                             userInputMetaURL
iXML["IXML:USER:Manufacturer"]   = "Manufacturer"    -- Manufacturer
iXML["IXML:USER:Library"]        = "Library"         -- Library                                     userInputMetaLib

-- Reference other wildcards
iXML["IXML:USER:ReleaseDate"]    = "ReleaseDate"     -- $date
iXML["IXML:USER:Embedder"]       = "Embedder"        -- REAPER UCS Renaming Tool

-- DUPLICATES: Any metadata that copies a field from above, iXML or otherwise
iXML["IXML:USER:LongID"]         = "CatID"
iXML["IXML:USER:Source"]         = "Show"
iXML["IXML:USER:Artist"]         = "Designer"
iXML["IXML:BEXT:BWF_DESCRIPTION"]= "Description"
-- BWF
iXML["BWF:Description"]          = "Description"
iXML["BWF:Originator"]           = "Designer"
iXML["BWF:OriginatorReference"]  = "URL"
-- ID3
iXML["ID3:TIT2"]                 = "TrackTitle"
iXML["ID3:COMM"]                 = "Description"
iXML["ID3:TPE1"]                 = "Designer"
iXML["ID3:TPE2"]                 = "Show"
iXML["ID3:TCON"]                 = "Category"
iXML["ID3:TALB"]                 = "Library"
-- INFO
iXML["INFO:ICMT"]                = "Description"
iXML["INFO:IART"]                = "Designer"
iXML["INFO:IGNR"]                = "Category"
iXML["INFO:INAM"]                = "TrackTitle"
iXML["INFO:IPRD"]                = "Library"
-- XMP
iXML["XMP:dc/description"]       = "Description"
iXML["XMP:dm/artist"]            = "Designer"
iXML["XMP:dm/genre"]             = "Category"
iXML["XMP:dc/title"]             = "TrackTitle"
iXML["XMP:dm/album"]             = "Library"
-- VORBIS
iXML["VORBIS:DESCRIPTION"]       = "Description"
iXML["VORBIS:COMMENT"]           = "Description"
iXML["VORBIS:GENRE"]             = "Category"
iXML["VORBIS:TITLE"]             = "TrackTitle"
iXML["VORBIS:ARTIST"]            = "Designer"
iXML["VORBIS:ALBUM"]             = "Library"

--region ASWG
iXML["ASWG:contentType"] = "ASWGcontentType"
iXML["ASWG:project"] = "ASWGproject"
iXML["ASWG:originatorStudio"] = "ASWGoriginatorStudio"
iXML["ASWG:notes"] = "ASWGnotes"
iXML["ASWG:state"] = "ASWGstate"
iXML["ASWG:editor"] = "ASWGeditor"
iXML["ASWG:mixer"] = "ASWGmixer"
iXML["ASWG:fxChainName"] = "ASWGfxChainName"
iXML["ASWG:channelConfig"] = "ASWGchannelConfig"
iXML["ASWG:ambisonicFormat"] = "ASWGambisonicFormat"
iXML["ASWG:ambisonicChnOrder"] = "ASWGambisonicChnOrder"
iXML["ASWG:ambisonicNorm"] = "ASWGambisonicNorm"
iXML["ASWG:isDesigned"] = "ASWGisDesigned"
iXML["ASWG:recEngineer"] = "ASWGrecEngineer"
iXML["ASWG:recStudio"] = "ASWGrecStudio"
iXML["ASWG:impulseLocation"] = "ASWGimpulseLocation"
iXML["ASWG:text"] = "ASWGtext"
iXML["ASWG:efforts"] = "ASWGefforts"
iXML["ASWG:effortType"] = "ASWGeffortType"
iXML["ASWG:projection"] = "ASWGprojection"
iXML["ASWG:language"] = "ASWGlanguage"
iXML["ASWG:timingRestriction"] = "ASWGtimingRestriction"
iXML["ASWG:characterName"] = "ASWGcharacterName"
iXML["ASWG:characterGender"] = "ASWGcharacterGender"
iXML["ASWG:characterAge"] = "ASWGcharacterAge"
iXML["ASWG:characterRole"] = "ASWGcharacterRole"
iXML["ASWG:actorName"] = "ASWGactorName"
iXML["ASWG:actorGender"] = "ASWGactorGender"
iXML["ASWG:direction"] = "ASWGdirection"
iXML["ASWG:director"] = "ASWGdirector"
iXML["ASWG:fxUsed"] = "ASWGfxUsed"
iXML["ASWG:usageRights"] = "ASWGusageRights"
iXML["ASWG:isUnion"] = "ASWGisUnion"
iXML["ASWG:accent"] = "ASWGaccent"
iXML["ASWG:emotion"] = "ASWGemotion"
iXML["ASWG:composer"] = "ASWGcomposer"
iXML["ASWG:artist"] = "ASWGartist"
iXML["ASWG:songTitle"] = "ASWGsongTitle"
iXML["ASWG:genre"] = "ASWGgenre"
iXML["ASWG:subGenre"] = "ASWGsubGenre"
iXML["ASWG:producer"] = "ASWGproducer"
iXML["ASWG:musicSup"] = "ASWGmusicSup"
iXML["ASWG:instrument"] = "ASWGinstrument"
iXML["ASWG:musicPublisher"] = "ASWGmusicPublisher"
iXML["ASWG:rightsOwner"] = "ASWGrightsOwner"
iXML["ASWG:intensity"] = "ASWGintensity"
iXML["ASWG:orderRef"] = "ASWGorderRef"
iXML["ASWG:isSource"] = "ASWGisSource"
iXML["ASWG:isLoop"] = "ASWGisLoop"
iXML["ASWG:isFinal"] = "ASWGisFinal"
iXML["ASWG:isOst"] = "ASWGisOst"
iXML["ASWG:isCinematic"] = "ASWGisCinematic"
iXML["ASWG:isLicensed"] = "ASWGisLicensed"
iXML["ASWG:isDiegetic"] = "ASWGisDiegetic"
iXML["ASWG:musicVersion"] = "ASWGmusicVersion"
iXML["ASWG:isrcId"] = "ASWGisrcId"
iXML["ASWG:tempo"] = "ASWGtempo"
iXML["ASWG:timeSig"] = "ASWGtimeSig"
iXML["ASWG:inKey"] = "ASWGinKey"
iXML["ASWG:billingCode"] = "ASWGbillingCode"

-- Duplicates of existing fields
iXML["ASWG:originator"] = "Designer"
iXML["ASWG:micConfig"] = "RecType"
iXML["ASWG:micType"] = "Microphone"
iXML["ASWG:micDistance"] = "MicPerspective"
iXML["ASWG:recordingLoc"] = "Location"
iXML["ASWG:vendorCategory"] = "VendorCategory"
iXML["ASWG:userCategory"] = "UserCategory"
iXML["ASWG:subCategory"] = "SubCategory"
iXML["ASWG:sourceId"] = "Show"
iXML["ASWG:userData"] = "Notes"
iXML["ASWG:library"] = "Library"
iXML["ASWG:fxName"] = "FXName"
iXML["ASWG:creatorId"] = "ShortID"
iXML["ASWG:catId"] = "CatID"
iXML["ASWG:category"] = "Category"

-- Reaper project name
iXML["ASWG:session"] = "ASWGsession"
--endregion

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~~~~~~~~~~~  
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~ Parse UCS Input ~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
function parseUCSWebInterfaceInput()

  reaper.Undo_BeginBlock()

  -- Check Reaper version
  local reaper_version = tonumber(reaper.GetAppVersion():match("%d+%.%d+"))
  v633_mkrs = (reaper_version >= 6.33) and true or false

  -- Convert rets to booleans for cleaner function-writing down the line
  ucsRetsToBool()
  
  -- Safety-net evaluation if any of category/subcategory/catID are invalid
  -- The web interface should never even trigger this ReaScript anyways if CatID is invalid
  if not ret_cat and ret_scat and ret_id then do return end end
  
  -- Show message box with form inputs and respective ret bools. Toggle at top of script.
  if debug_mode then debugUCSInput() end
  
  -- Evaluate copy to clipboard settings
  if ret_copy and ucs_copy == "Copy after processing" then copy_to_clipboard = true
  elseif ret_copy and ucs_copy == "Copy WITHOUT processing" then copy_without_processing = true end

  if not copy_without_processing then
  
    -- Break out evaluation based on search type
    if ucs_type == "Regions" then
      local ret, num_markers, num_regions = reaper.CountProjectMarkers( 0 )
      if num_regions > 0 then
        if num_regions == 1 then ucs_enum = "false" end
        renameRegions(num_markers,num_regions)
      else
        reaper.MB("Project has no " .. ucs_type .. " to rename!", "UCS Renaming Tool", 0)
      end
      
    elseif ucs_type == "Markers" then
      local ret, num_markers, num_regions = reaper.CountProjectMarkers( 0 )
      if num_markers > 0 then
        if num_markers == 1 then ucs_enum = "false" end
        renameMarkers(num_markers,num_regions)
      else
        reaper.MB("Project has no " .. ucs_type .. " to rename!", "UCS Renaming Tool", 0)
      end
      
    elseif ucs_type == "Media Items" then
      local num_items = reaper.CountMediaItems( 0 )
      if num_items > 0 then
        if num_items == 1 then ucs_enum = "false" end
        renameMediaItems(num_items)
      else
        reaper.MB("Project has no " .. ucs_type .. " to rename!", "UCS Renaming Tool", 0)
      end

    elseif ucs_type == "NVK Folder Items" then
      -- Check for NVK API Extension
      if not reaper.NVK_IsFolderItem then
        --reaper.MB("Support for renaming NVK Folder Items depends on the NVK API, available in ReaPack, under the nvk-ReaScripts repository.\n\nExtensions > ReaPack > Browse Packages\n\nFilter for 'nvk-ReaScripts'. Right click to install.","UCS Renaming Tool", 0)
        reaper.MB("Support for NVK Folder Items is not yet available! Stay tuned for updates in the not-so-distant future...","UCS Renaming Tool", 0)
        return
      end
      
      local num_items = reaper.NVK_CountFolderItems(0)
      if num_items > 0 then
        if num_items == 1 then ucs_enum = "false" end
        renameNVKFolderItems(num_items)
      else
        reaper.MB("Project has no " .. ucs_type .. " to rename!", "UCS Renaming Tool", 0)
      end
        
    elseif ucs_type == "Tracks" then
      local num_tracks =  reaper.CountTracks( 0 )
      if num_tracks > 0 then
        if num_tracks == 1 then ucs_enum = "false" end
        renameTracks(num_tracks)
      else
        reaper.MB("Project has no " .. ucs_type .. " to rename!", "UCS Renaming Tool", 0)
      end
    
    else
      if ret_type then
        reaper.MB("Invalid search type. Did you tweak the 'userInputItems' options in UCS Renaming Tool Interface.html?", "UCS Renaming Tool", 0)
      else
        reaper.MB("Invalid search type. Did you remove or rename 'userInputItems' in UCS Renaming Tool Interface.html?", "UCS Renaming Tool", 0)
      end
    end
    
    -- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
    -- ~~~~~ POST PROCESSING ~~~~~
    -- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
    -- If iXML metadata enabled, then ensure project settings are set up correctly and set up iXML markers
    if ret_ixml and ucs_ixml == "true" and #iXMLMarkerTbl > 0 then 
      iXMLSetup() 
      iXMLMarkersEngage()
    end
    
    -- Copy to clipboard AFTER processing
    if copy_to_clipboard and line_to_copy then reaper.CF_SetClipboard( line_to_copy ) end
    
    -- Julibrary mode, copy metadata to clipboard
    if julibrary_mode then reaper.CF_SetClipboard( julibrary_metadata ) end

    -- Set render directory
    setRenderDirectory()
    
  -- Copy to clipboard WITHOUT processing
  else
    copy_to_clipboard = true
    leadingZeroUCSNumStr()
    setFullName()
    if line_to_copy then 
      reaper.CF_SetClipboard( line_to_copy )
      if debug_mode then reaper.MB(line_to_copy,"Copied to Clipboard",0) end
    end
  end

  reaper.Undo_EndBlock("UCS Renaming Tool", -1)
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~ REGIONS ~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
function renameRegions(num_markers,num_regions)
  local num_total = num_markers + num_regions
  
  if ucs_area == "Time Selection" then
    StartTimeSel, EndTimeSel = reaper.GetSet_LoopTimeRange(0,0,0,0,0);
    -- Confirm valid time selection
    if StartTimeSel ~= EndTimeSel then
      local i = 0
      while i < num_total do
        local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, i )
        if isrgn then
          if pos >= StartTimeSel and rgnend <= EndTimeSel then
            -- BUILD NAME
            leadingZeroUCSNumStr()
            setFullName()
            -- SET WILDCARDS
            local rgn_num = tostring(markrgnindexnumber)
            local relname = ucs_name
            if string.len(rgn_num) == 1 then rgn_num = "0" .. rgn_num end
            if ucs_full_name:ifind("$Regionnumber") then ucs_full_name = ucs_full_name:gisub("$Regionnumber",rgn_num); relname = relname:gisub("$Regionnumber",rgn_num) end
            if ucs_full_name:ifind("$Region") then ucs_full_name = ucs_full_name:gisub("$Region",name); relname = relname:gisub("$Region",name) end
            -- SET NAME
            reaper.SetProjectMarkerByIndex( 0, i, isrgn, pos, rgnend, markrgnindexnumber, ucs_full_name, color )
            -- METADATA
            if ret_ixml and ucs_ixml == "true" then 
              if ret_mpos and ucs_mpos == "true" then
                iXMLMarkers(rgnend + 0.0005,relname)
              else
                iXMLMarkers(pos,relname) 
              end
            end
            -- INCREMENT
            incrementUCSNumStr()
          end
        end
        i = i + 1
      end
    else
      reaper.MB("You haven't made a time selection!","UCS Renaming Tool", 0)
    end
  
  elseif ucs_area == "Full Project" then
    local i = 0
    while i < num_total do
      local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, i )
      if isrgn then
        leadingZeroUCSNumStr()
        setFullName()
        local rgn_num = tostring(markrgnindexnumber)
        local relname = ucs_name
        if string.len(rgn_num) == 1 then rgn_num = "0" .. rgn_num end
        if ucs_full_name:ifind("$Regionnumber") then ucs_full_name = ucs_full_name:gisub("$Regionnumber",rgn_num); relname = relname:gisub("$Regionnumber",rgn_num) end
        if ucs_full_name:ifind("$Region") then ucs_full_name = ucs_full_name:gisub("$Region",name); relname = relname:gisub("$Region",name) end
        reaper.SetProjectMarkerByIndex( 0, i, isrgn, pos, rgnend, markrgnindexnumber, ucs_full_name, color )
        if ret_ixml and ucs_ixml == "true" then 
          if ret_mpos and ucs_mpos == "true" then
            iXMLMarkers(rgnend + 0.0005,relname)
          else
            iXMLMarkers(pos,relname) 
          end
        end
        incrementUCSNumStr()
      end
      i = i + 1
    end

  elseif ucs_area == "Edit Cursor" then
    local markeridx, regionidx = reaper.GetLastMarkerAndCurRegion(0, reaper.GetCursorPosition())
    if regionidx ~= nil then
      local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, regionidx )
      if isrgn then
        leadingZeroUCSNumStr()
        setFullName()
        local rgn_num = tostring(markrgnindexnumber)
        local relname = ucs_name
        if string.len(rgn_num) == 1 then rgn_num = "0" .. rgn_num end
        if ucs_full_name:ifind("$Regionnumber") then ucs_full_name = ucs_full_name:gisub("$Regionnumber",rgn_num); relname = relname:gisub("$Regionnumber",rgn_num) end
        if ucs_full_name:ifind("$Region") then ucs_full_name = ucs_full_name:gisub("$Region",name); relname = relname:gisub("$Region",name) end
        reaper.SetProjectMarkerByIndex( 0, regionidx, isrgn, pos, rgnend, markrgnindexnumber, ucs_full_name, color )
        if ret_ixml and ucs_ixml == "true" then 
          if ret_mpos and ucs_mpos == "true" then
            iXMLMarkers(rgnend + 0.0005,relname)
          else
            iXMLMarkers(pos,relname) 
          end
        end
        incrementUCSNumStr()
      end
    end
    
  elseif ucs_area == "Selected Regions in Region Manager" then
    local sel_rgn_table = getSelectedRegions()
    if sel_rgn_table then 
      for _, regionidx in pairs(sel_rgn_table) do 
        local i = 0
        while i < num_total do
          local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, i )
          if isrgn and markrgnindexnumber == regionidx then
            leadingZeroUCSNumStr()
            setFullName()
            local rgn_num = tostring(markrgnindexnumber)
            local relname = ucs_name
            if string.len(rgn_num) == 1 then rgn_num = "0" .. rgn_num end
            if ucs_full_name:ifind("$Regionnumber") then ucs_full_name = ucs_full_name:gisub("$Regionnumber",rgn_num); relname = relname:gisub("$Regionnumber",rgn_num) end
            if ucs_full_name:ifind("$Region") then ucs_full_name = ucs_full_name:gisub("$Region",name); relname = relname:gisub("$Region",name) end
            reaper.SetProjectMarkerByIndex( 0, i, isrgn, pos, rgnend, markrgnindexnumber, ucs_full_name, color )
            if ret_ixml and ucs_ixml == "true" then 
              if ret_mpos and ucs_mpos == "true" then
                iXMLMarkers(rgnend + 0.0005,relname)
              else
                iXMLMarkers(pos,relname) 
              end
            end
            incrementUCSNumStr()
            break
          end
          i = i + 1
        end
      end
    else
      reaper.MB("No regions selected!\n\nPlease go to View > Region/Marker Manager to select regions.","UCS Renaming Tool", 0)
    end
  
  else
    if ret_area then
      reaper.MB("Invalid search area type. Did you tweak the 'userInputArea' options in UCS Renaming Tool Interface.html?", "UCS Renaming Tool", 0)
    else
      reaper.MB("Invalid search area type. Did you remove or rename 'userInputArea' in UCS Renaming Tool Interface.html?", "UCS Renaming Tool", 0)
    end
  end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~ MARKERS ~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
function renameMarkers(num_markers,num_regions)
  local num_total = num_markers + num_regions
  
  if ucs_area == "Time Selection" then
    StartTimeSel, EndTimeSel = reaper.GetSet_LoopTimeRange(0,0,0,0,0);
    -- Confirm valid time selection
    if StartTimeSel ~= EndTimeSel then
      local i = 0
      while i < num_total do
        local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, i )
        if not isrgn then
          if pos >= StartTimeSel and pos <= EndTimeSel then
            leadingZeroUCSNumStr()
            setFullName()
            local mkr_num = tostring(markrgnindexnumber)
            local relname = ucs_name
            if string.len(mkr_num) == 1 then mkr_num = "0" .. mkr_num end
            if ucs_full_name:ifind("$Markernumber") then ucs_full_name = ucs_full_name:gisub("$Markernumber",mkr_num); relname = relname:gisub("$Markernumber",mkr_num) end
            if ucs_full_name:ifind("$Marker") then ucs_full_name = ucs_full_name:gisub("$Marker",name); relname = relname:gisub("$Marker",name) end
            reaper.SetProjectMarkerByIndex( 0, i, isrgn, pos, rgnend, markrgnindexnumber, ucs_full_name, color )
            if ret_ixml and ucs_ixml == "true" then iXMLMarkers(pos,relname) end
            incrementUCSNumStr()
          end
        end
        i = i + 1
      end
    else
      reaper.MB("You haven't made a time selection!","UCS Renaming Tool", 0)
    end

  elseif ucs_area == "Full Project" then
    local i = 0
    while i < num_total do
      local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, i )
      if not isrgn then
        leadingZeroUCSNumStr()
        setFullName()
        local mkr_num = tostring(markrgnindexnumber)
        local relname = ucs_name
        if string.len(mkr_num) == 1 then mkr_num = "0" .. mkr_num end
        if ucs_full_name:ifind("$Markernumber") then ucs_full_name = ucs_full_name:gisub("$Markernumber",mkr_num); relname = relname:gisub("$Markernumber",mkr_num) end
        if ucs_full_name:ifind("$Marker") then ucs_full_name = ucs_full_name:gisub("$Marker",name); relname = relname:gisub("$Marker",name) end
        reaper.SetProjectMarkerByIndex( 0, i, isrgn, pos, rgnend, markrgnindexnumber, ucs_full_name, color )
        if ret_ixml and ucs_ixml == "true" then iXMLMarkers(pos,relname) end
        incrementUCSNumStr()
      end
      i = i + 1
    end
    
  elseif ucs_area == "Selected Markers in Marker Manager" then
    local sel_mkr_table = getSelectedMarkers()
    if sel_mkr_table then 
      for _, regionidx in pairs(sel_mkr_table) do 
        local i = 0
        while i < num_total do
          local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, i )
          if not isrgn and markrgnindexnumber == regionidx then
            leadingZeroUCSNumStr()
            setFullName()
            local mkr_num = tostring(markrgnindexnumber)
            local relname = ucs_name
            if string.len(mkr_num) == 1 then mkr_num = "0" .. mkr_num end
            if ucs_full_name:ifind("$Markernumber") then ucs_full_name = ucs_full_name:gisub("$Markernumber",mkr_num); relname = relname:gisub("$Markernumber",mkr_num) end
            if ucs_full_name:ifind("$Marker") then ucs_full_name = ucs_full_name:gisub("$Marker",name); relname = relname:gisub("$Marker",name) end
            reaper.SetProjectMarkerByIndex( 0, i, isrgn, pos, rgnend, markrgnindexnumber, ucs_full_name, color )
            if ret_ixml and ucs_ixml == "true" then iXMLMarkers(pos,relname) end
            incrementUCSNumStr()
            break
          end
          i = i + 1
        end
      end
    else
      reaper.MB("No markers selected!\n\nPlease go to View > Region/Marker Manager to select regions.","UCS Renaming Tool", 0)
    end
  
  else
    if ret_area then
      reaper.MB("Invalid search area type. Did you tweak the 'userInputArea' options in UCS Renaming Tool Interface.html?", "UCS Renaming Tool", 0)
    else
      reaper.MB("Invalid search area type. Did you remove or rename 'userInputArea' in UCS Renaming Tool Interface.html?", "UCS Renaming Tool", 0)
    end
  end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~ ITEMS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
function renameMediaItems(num_items)
  if ucs_area == "Selected Items" then
    local num_sel_items = reaper.CountSelectedMediaItems(0)
    if num_sel_items > 0 then
      for i=0, num_sel_items - 1 do
        local item = reaper.GetSelectedMediaItem( 0, i )
        local item_start = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
        local item_end = item_start + reaper.GetMediaItemInfo_Value( item, "D_LENGTH" )
        local take = reaper.GetActiveTake( item )
        local item_num = tostring(math.floor( reaper.GetMediaItemInfo_Value( item, "IP_ITEMNUMBER" ) + 1))
        if string.len(item_num) == 1 then item_num = "0" .. item_num end
        if take ~= nil then 
          leadingZeroUCSNumStr()
          setFullName()
          local relname = ucs_name
          if ucs_full_name:ifind("$Itemnumber") then ucs_full_name = ucs_full_name:gisub("$Itemnumber", item_num); relname = relname:gisub("$Itemnumber", item_num) end
          if ucs_full_name:ifind("$Item") then 
            local ret_name, item_name = reaper.GetSetMediaItemTakeInfo_String( take, "P_NAME", "", false )
            if ret_name then 
              ucs_full_name = ucs_full_name:gisub("$Item",item_name)
              relname = relname:gisub("$Item",item_name)
            else 
              ucs_full_name = ucs_full_name:gisub("$Item","") 
              relname = relname:gisub("$Item","")
            end
          end
          reaper.GetSetMediaItemTakeInfo_String( take, "P_NAME", ucs_full_name, true )
          if ret_ixml and ucs_ixml == "true" then 
            if ret_mpos and ucs_mpos == "true" then
              iXMLMarkers(item_end + 0.0005,relname)
            else
              iXMLMarkers(item_start,relname) 
            end
          end
          incrementUCSNumStr()
        end
      end
    else
      reaper.MB("No items selected!","UCS Renaming Tool", 0)
    end
    
  elseif ucs_area == "All Items" then
    for i=0, num_items - 1 do
      local item =  reaper.GetMediaItem( 0, i )
      local item_start = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
      local item_end = item_start + reaper.GetMediaItemInfo_Value( item, "D_LENGTH" )
      local take = reaper.GetActiveTake( item )
      local item_num = tostring(math.floor( reaper.GetMediaItemInfo_Value( item, "IP_ITEMNUMBER" ) + 1))
      if string.len(item_num) == 1 then item_num = "0" .. item_num end
      if take ~= nil then 
        leadingZeroUCSNumStr()
        setFullName()
        local relname = ucs_name
        if ucs_full_name:ifind("$Itemnumber") then ucs_full_name = ucs_full_name:gisub("$Itemnumber", item_num); relname = relname:gisub("$Itemnumber", item_num) end
        if ucs_full_name:ifind("$Item") then 
          local ret_name, item_name = reaper.GetSetMediaItemTakeInfo_String( take, "P_NAME", "", false )
          if ret_name then 
            ucs_full_name = ucs_full_name:gisub("$Item",item_name)
            relname = relname:gisub("$Item",item_name)
          else 
            ucs_full_name = ucs_full_name:gisub("$Item","") 
            relname = relname:gisub("$Item","")
          end
        end
        reaper.GetSetMediaItemTakeInfo_String( take, "P_NAME", ucs_full_name, true )
        if ret_ixml and ucs_ixml == "true" then 
          if ret_mpos and ucs_mpos == "true" then
            iXMLMarkers(item_end + 0.0005,relname)
          else
            iXMLMarkers(item_start,relname) 
          end
        end
        incrementUCSNumStr()
      end
    end
  else
    if ret_area then
      reaper.MB("Invalid search area type. Did you tweak the 'userInputArea' options in UCS Renaming Tool Interface.html?", "UCS Renaming Tool", 0)
    else
      reaper.MB("Invalid search area type. Did you remove or rename 'userInputArea' in UCS Renaming Tool Interface.html?", "UCS Renaming Tool", 0)
    end
  end
end

function renameNVKFolderItems(num_items)
  if ucs_area == "Selected Items" then
    local num_sel_items = reaper.NVK_CountSelectedFolderItems(0)
    if num_sel_items > 0 then
      for i=0, num_sel_items - 1 do
        local item = reaper.reaper.NVK_GetSelectedFolderItem(0, i)
        local item_start = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
        local item_end = item_start + reaper.GetMediaItemInfo_Value( item, "D_LENGTH" )
        local take = reaper.GetActiveTake( item )
        local item_num = tostring(math.floor( reaper.GetMediaItemInfo_Value( item, "IP_ITEMNUMBER" ) + 1))
        if string.len(item_num) == 1 then item_num = "0" .. item_num end
        if take ~= nil then 
          leadingZeroUCSNumStr()
          setFullName()
          local relname = ucs_name
          if ucs_full_name:ifind("$Itemnumber") then ucs_full_name = ucs_full_name:gisub("$Itemnumber", item_num); relname = relname:gisub("$Itemnumber", item_num) end
          if ucs_full_name:ifind("$Item") then 
            local ret_name, item_name = reaper.GetSetMediaItemTakeInfo_String( take, "P_NAME", "", false )
            if ret_name then 
              ucs_full_name = ucs_full_name:gisub("$Item",item_name)
              relname = relname:gisub("$Item",item_name)
            else 
              ucs_full_name = ucs_full_name:gisub("$Item","") 
              relname = relname:gisub("$Item","")
            end
          end
          reaper.GetSetMediaItemTakeInfo_String( take, "P_NAME", ucs_full_name, true )
          if ret_ixml and ucs_ixml == "true" then 
            if ret_mpos and ucs_mpos == "true" then
              iXMLMarkers(item_end + 0.0005,relname)
            else
              iXMLMarkers(item_start,relname) 
            end
          end
          incrementUCSNumStr()
        end
      end
    else
      reaper.MB("No NVK Folder Items selected!","UCS Renaming Tool", 0)
    end
    
  elseif ucs_area == "All Items" then
    for i=0, num_items - 1 do
      local item =  reaper.NVK_GetFolderItem( 0, i )
      local item_start = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
      local item_end = item_start + reaper.GetMediaItemInfo_Value( item, "D_LENGTH" )
      local take = reaper.GetActiveTake( item )
      local item_num = tostring(math.floor( reaper.GetMediaItemInfo_Value( item, "IP_ITEMNUMBER" ) + 1))
      if string.len(item_num) == 1 then item_num = "0" .. item_num end
      if take ~= nil then 
        leadingZeroUCSNumStr()
        setFullName()
        local relname = ucs_name
        if ucs_full_name:ifind("$Itemnumber") then ucs_full_name = ucs_full_name:gisub("$Itemnumber", item_num); relname = relname:gisub("$Itemnumber", item_num) end
        if ucs_full_name:ifind("$Item") then 
          local ret_name, item_name = reaper.GetSetMediaItemTakeInfo_String( take, "P_NAME", "", false )
          if ret_name then 
            ucs_full_name = ucs_full_name:gisub("$Item",item_name)
            relname = relname:gisub("$Item",item_name)
          else 
            ucs_full_name = ucs_full_name:gisub("$Item","") 
            relname = relname:gisub("$Item","")
          end
        end
        reaper.GetSetMediaItemTakeInfo_String( take, "P_NAME", ucs_full_name, true )
        if ret_ixml and ucs_ixml == "true" then 
          if ret_mpos and ucs_mpos == "true" then
            iXMLMarkers(item_end + 0.0005,relname)
          else
            iXMLMarkers(item_start,relname) 
          end
        end
        incrementUCSNumStr()
      end
    end
  else
    if ret_area then
      reaper.MB("Invalid search area type. Did you tweak the 'userInputArea' options in UCS Renaming Tool Interface.html?", "UCS Renaming Tool", 0)
    else
      reaper.MB("Invalid search area type. Did you remove or rename 'userInputArea' in UCS Renaming Tool Interface.html?", "UCS Renaming Tool", 0)
    end
  end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~ TRACKS ~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
function renameTracks(num_tracks)
  if ucs_area == "Selected Tracks" then
    num_sel_tracks = reaper.CountSelectedTracks( 0 )
    if num_sel_tracks > 0 then
      for i = 0, num_sel_tracks-1 do
        track = reaper.GetSelectedTrack(0,i)
        local track_num = tostring(math.floor(reaper.GetMediaTrackInfo_Value( track, "IP_TRACKNUMBER" )))
        if string.len(track_num) == 1 then track_num = "0" .. track_num end
        leadingZeroUCSNumStr()
        setFullName()
        if ucs_full_name:ifind("$Tracknumber") then ucs_full_name = ucs_full_name:gisub("$Tracknumber", track_num) end
        if ucs_full_name:ifind("$Track") then 
          local ret_name, track_name = reaper.GetSetMediaTrackInfo_String( track, "P_NAME", "", false )
          if ret_name then ucs_full_name = ucs_full_name:gisub("$Track",track_name)
          else ucs_full_name = ucs_full_name:gisub("$Track","") end
        end
        reaper.GetSetMediaTrackInfo_String( track, "P_NAME", ucs_full_name, true )
        incrementUCSNumStr()
      end
    else
      reaper.MB("No tracks selected!","UCS Renaming Tool", 0)
    end

  elseif ucs_area == "Selected in Track Manager" then
    local sel_trk_table = getSelectedTracks()
    if sel_trk_table then 
      for _, trkidx in pairs(sel_trk_table) do 
        track = reaper.GetTrack(0,trkidx - 1)
        local track_num = tostring(trkidx)
        if string.len(track_num) == 1 then track_num = "0" .. track_num end
        leadingZeroUCSNumStr()
        setFullName()
        if ucs_full_name:ifind("$Tracknumber") then ucs_full_name = ucs_full_name:gisub("$Tracknumber", track_num) end
        if ucs_full_name:ifind("$Track") then 
          local ret_name, track_name = reaper.GetSetMediaTrackInfo_String( track, "P_NAME", "", false )
          if ret_name then ucs_full_name = ucs_full_name:gisub("$Track",track_name)
          else ucs_full_name = ucs_full_name:gisub("$Track","") end
        end
        reaper.GetSetMediaTrackInfo_String( track, "P_NAME", ucs_full_name, true )
        incrementUCSNumStr()
      end
    else
      reaper.MB("No tracks selected!\n\nPlease go to View > Track Manager to select tracks.","UCS Renaming Tool", 0)
    end
    
  elseif ucs_area == "All Tracks" then
    for i = 0, num_tracks-1 do
     track = reaper.GetTrack(0,i)
     local track_num = tostring(math.floor(reaper.GetMediaTrackInfo_Value( track, "IP_TRACKNUMBER" )))
     if string.len(track_num) == 1 then track_num = "0" .. track_num end
     leadingZeroUCSNumStr()
     setFullName()
     if ucs_full_name:ifind("$Tracknumber") then ucs_full_name = ucs_full_name:gisub("$Tracknumber", track_num) end
     if ucs_full_name:ifind("$Track") then 
       local ret_name, track_name = reaper.GetSetMediaTrackInfo_String( track, "P_NAME", "", false )
       if ret_name then ucs_full_name = ucs_full_name:gisub("$Track",track_name)
       else ucs_full_name = ucs_full_name:gisub("$Track","") end
     end
     reaper.GetSetMediaTrackInfo_String( track, "P_NAME", ucs_full_name, true )
     incrementUCSNumStr()
    end
    
  else
    if ret_area then
      reaper.MB("Invalid search area type. Did you tweak the 'userInputArea' options in UCS Renaming Tool Interface.html?", "UCS Renaming Tool", 0)
    else
      reaper.MB("Invalid search area type. Did you remove or rename 'userInputArea' in UCS Renaming Tool Interface.html?", "UCS Renaming Tool", 0)
    end
  end
end


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~ UTILITIES ~~~~~~~~~~~~~~~~~~~~~  
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~ Set Full Name ~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Format: CatID(-UserCategory)_(VendorCategory-)File Name with Variation Number_Initials_(Show)
function setFullName()
  -- Initials
  if ret_caps and ucs_caps == "ALL CAPS (Default)" then ucs_init_final = "_" .. string.upper(ucs_init)
  elseif ret_caps and ucs_caps == "Title Case" then ucs_init_final = "_" .. ucs_init:gsub("(%a)([%w_']*)", toTitleCase)
  elseif ret_caps and ucs_caps == "Disable automatic capitalization" then ucs_init_final = "_" .. ucs_init
  else ucs_init_final = "_" .. string.upper(ucs_init) end
  -- GBX Mod
  if retg_mod and gbx_mod then ucs_init_final = "" end

  -- FX Name Title Case
  if ret_frmt and ucs_frmt:find("Enable") then
    ucs_name = ucs_name:gsub("(%a)([%w_']*)", toTitleCase)
  end

  -- Vendor & Enumeration
  if ret_vend then
    -- Vendor found
    if ret_caps and ucs_caps == "ALL CAPS (Default)"                   then ucs_vend = string.upper(ucs_vend)
    elseif ret_caps and ucs_caps == "Title Case"                       then ucs_vend = ucs_vend:gsub("(%a)([%w_']*)", toTitleCase)
    elseif ret_caps and ucs_caps == "Disable automatic capitalization" then ucs_vend = ucs_vend
    else ucs_vend = string.upper(ucs_vend) end
    
    if (ucs_enum == "true") then
      ucs_name_num_final = "_" .. ucs_vend .. "-" .. ucs_name .. " " .. ucs_num
    else
      ucs_name_num_final = "_" .. ucs_vend .. "-" .. ucs_name
    end
  else
    -- No Vendor
    if (ucs_enum == "true") then
      ucs_name_num_final = "_" .. ucs_name .. " " .. ucs_num
    else
      ucs_name_num_final = "_" .. ucs_name
    end
  end

  -- Source
  if ret_show then
    if ret_caps and ucs_caps == "ALL CAPS (Default)" then ucs_show_final = "_" .. string.upper(ucs_show)
    elseif ret_caps and ucs_caps == "Title Case" then ucs_show_final = "_" .. ucs_show:gsub("(%a)([%w_']*)", toTitleCase)
    elseif ret_caps and ucs_caps == "Disable automatic capitalization" then ucs_show_final = "_" .. ucs_show
    else ucs_show_final = "_" .. string.upper(ucs_show) end
  elseif retg_mod and gbx_mod then
    ucs_show_final = ""
  else
    ucs_show_final = "_NONE"
  end

  -- User Category
  if ret_usca then
    if ret_caps and ucs_caps == "ALL CAPS (Default)"                   then ucs_usca_final = "-" .. string.upper(ucs_usca)
    elseif ret_caps and ucs_caps == "Title Case"                       then ucs_usca_final = "-" .. ucs_usca:gsub("(%a)([%w_']*)", toTitleCase)
    elseif ret_caps and ucs_caps == "Disable automatic capitalization" then ucs_usca_final = "-" .. ucs_usca
    else ucs_usca_final = "-" .. string.upper(ucs_vend) end
  else
    ucs_usca_final = ""
  end

  -- Data
  if ret_data then
    ucs_data_final = "_" .. ucs_data
  else
    ucs_data_final = ""
  end
  
  -- Build the final name!
  ucs_full_name = ucs_id .. ucs_usca_final .. ucs_name_num_final .. ucs_init_final .. ucs_show_final .. ucs_data_final

  -- GBX Mod
  if retg_mod and gbx_mod then ucs_full_name = "GBX_" .. ucs_full_name .. "_" .. gbx_suff end

  -- Prep line to copy for clipboard
  if copy_to_clipboard then
    if line_to_copy == "" then line_to_copy = ucs_full_name
    else line_to_copy = line_to_copy .. "\n" .. ucs_full_name end
  end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~ GET SELECTED REGIONS ~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- https://github.com/ReaTeam/ReaScripts-Templates/blob/master/Regions-and-Markers/X-Raym_Get%20selected%20regions%20in%20region%20and%20marker%20manager.lua
function getSelectedRegions()
  local rgn_list = getRegionManagerList()

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

function getSelectedMarkers()
  local rgn_list = getRegionManagerList()

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

function getRegionManager()
  return reaper.JS_Window_Find(reaper.JS_Localize("Region/Marker Manager","common"), true) or nil
end

function getRegionManagerList()
  return reaper.JS_Window_FindEx(getRegionManager(), nil, "SysListView32", "") or nil
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~ GET SELECTED TRACKS  ~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~

function getSelectedTracks()
  local hWnd = getTrackManager()
  if hWnd == nil then return end  

  local container = reaper.JS_Window_FindChildByID(hWnd, 1071)

  sel_count, sel_indexes = reaper.JS_ListView_ListAllSelItems(container)
  if sel_count == 0 then return end 

  names = {}
  i = 0
  for index in string.gmatch(sel_indexes, '[^,]+') do 
    i = i+1
    local sel_item = reaper.JS_ListView_GetItemText(container, tonumber(index), 1)
    names[i] = tonumber(sel_item)
  end
  
  -- Return table of selected tracks
  return names
end

function getTrackManager()
  local title = reaper.JS_Localize("Track Manager", "common")
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

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~ Increment Num String ~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
function incrementUCSNumStr()
  ucs_num = tostring(tonumber(ucs_num) + 1)
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~ Title Case Full Name ~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
function toTitleCase(first, rest)
  return first:upper()..rest:lower()
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~ Add Leading Zero ~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
function leadingZeroUCSNumStr()
  local len = string.len(ucs_num)
  -- While num is < 10, add one leading zero. If you would prefer otherwise,
  -- change "0" to "00" and/or remove leading zeroes entirely by deleting this if/else block.
  -- "len" = the number of digits in the number.
  if len == 1 then 
    ucs_num = "0" .. ucs_num
  --elseif len == 2 then
    --ucs_num = "0" .. ucs_num
  end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~ iXML Setup ~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
function iXMLSetup()
  -- Copied directly from acendan_Set up SoundMiner iXML metadata markers in project render metadata settings.lua
  -- Sets up Project Render Metadata window with iXML marker values
  for k, v in pairs(iXML) do
    if v == "ReleaseDate" then
      local ret, str = reaper.GetSetProjectInfo_String( 0, "RENDER_METADATA", k .. "|$date", true)
    elseif v == "Embedder" then
      local ret, str = reaper.GetSetProjectInfo_String( 0, "RENDER_METADATA", k .. "|REAPER UCS Renaming Tool", true)
    elseif v == "ASWGsession" then
      local ret, str = reaper.GetSetProjectInfo_String( 0, "RENDER_METADATA", k .. "|$project", true)
    else
      -- v6.33 Marker Syntax [;]
      if v633_mkrs then
        local ret, str = reaper.GetSetProjectInfo_String( 0, "RENDER_METADATA", k .. "|$marker(" .. v .. ")[;]", true )
      
      -- Pre Reaper v6.33 Pile-Of-Markers Syntax
      else
        local ret, str = reaper.GetSetProjectInfo_String( 0, "RENDER_METADATA", k .. "|$marker(" .. v .. ")", true )
      end
    end
  end
end

-- Builds table of markers to setup at location with appropriate iXML info
function iXMLMarkers(position,relname)

  local multi_mics = {} 
  if retm_mic then
    for mic in meta_mic:gmatch("([^,]+)") do table.insert(multi_mics, mic:match("^%s*(.-)%s*$")) end
  end

  -- Set ASWG blanks for Content Type fields other than selection
  if ret_aswg_contentType and aswg_contentType ~= "" and aswg_contentType ~= "Mixed" then
    -- Set Dialogue specific fields blank
    if aswg_contentType ~= "Dialogue" then  
      aswg_text = ""
      aswg_efforts = ""
      aswg_effortType = ""
      aswg_projection = ""
      aswg_language = ""
      aswg_timingRestriction = ""
      aswg_characterName = ""
      aswg_characterGender = ""
      aswg_characterAge = ""
      aswg_characterRole = ""
      aswg_actorName = ""
      aswg_actorGender = ""
      aswg_direction = ""
      aswg_director = ""
      aswg_fxUsed = ""
      aswg_usageRights = ""
      aswg_isUnion = ""
      aswg_accent = ""
      aswg_emotion = ""
    end

    -- Set Music specific fields blank
    if aswg_contentType ~= "Music" then
      aswg_composer = ""
      aswg_artist = ""
      aswg_songTitle = ""
      aswg_genre = ""
      aswg_subGenre = ""
      aswg_producer = ""
      aswg_musicSup = ""
      aswg_instrument = ""
      aswg_musicPublisher = ""
      aswg_rightsOwner = ""
      aswg_intensity = ""
      aswg_orderRef = ""
      aswg_isSource = ""
      aswg_isLoop = ""
      aswg_isFinal = ""
      aswg_isOst = ""
      aswg_isCinematic = ""
      aswg_isLicensed = ""
      aswg_isDiegetic = ""
      aswg_musicVersion = ""
      aswg_isrcId = ""
      aswg_tempo = ""
      aswg_timeSig = ""
      aswg_inKey = ""
      aswg_billingCode = ""
    end

    -- Set Impulse location blank
    if aswg_contentType ~= "Impulse (IR)" then
      aswg_impulseLocation = ""
    end
  end

  -- v6.33 Marker Syntax [;]
  if v633_mkrs then

    local mega_marker = "META"

    -- Standard UCS
    mega_marker = mega_marker .. ";" .. "CatID=" .. ucs_id
    mega_marker = mega_marker .. ";" .. "Category=" .. ucs_cat
    mega_marker = mega_marker .. ";" .. "SubCategory=" .. ucs_scat
    mega_marker = mega_marker .. ";" .. "UserCategory=" .. ucs_usca
    mega_marker = mega_marker .. ";" .. "VendorCategory=" .. ucs_vend
    mega_marker = mega_marker .. ";" .. "FXName=" .. relname
    mega_marker = mega_marker .. ";" .. "Notes=" .. ucs_data
    mega_marker = mega_marker .. ";" .. "Show=" .. ucs_show
    mega_marker = mega_marker .. ";" .. "CategoryFull=" .. ucs_cat .. "-" .. ucs_scat

    -- Extended meta
    if ret_meta then
      mega_marker = mega_marker .. ";" .. "TrackTitle=" .. meta_title
      mega_marker = mega_marker .. ";" .. "Description=" .. meta_desc
      mega_marker = mega_marker .. ";" .. "Keywords=" .. meta_keys
      mega_marker = mega_marker .. ";" .. "RecMedium=" .. meta_recmed
      mega_marker = mega_marker .. ";" .. "Library=" .. meta_lib
      mega_marker = mega_marker .. ";" .. "Location=" .. meta_loc
      mega_marker = mega_marker .. ";" .. "URL=" .. meta_url
      mega_marker = mega_marker .. ";" .. "Manufacturer=" .. meta_mftr
      mega_marker = mega_marker .. ";" .. "MetaNotes=" .. meta_notes
      mega_marker = mega_marker .. ";" .. "MicPerspective=" .. meta_persp
      mega_marker = mega_marker .. ";" .. "RecType=" .. meta_config
      
      -- Microphone
      mega_marker = mega_marker .. ";" .. "Microphone=" .. meta_mic
      if #multi_mics > 1 then
        for idx, mic in ipairs(multi_mics) do
          local mic_key = "Mic" .. tostring(idx)
          local mic_idx = "MicIdx" .. tostring(idx)
          mega_marker = mega_marker .. ";" .. mic_key .. "=" .. mic
          mega_marker = mega_marker .. ";" .. mic_idx .. "=" .. tostring(idx)

          local suffix = idx == 1 and "" or ":" .. tostring(idx)
          iXML["IXML:TRACK_LIST:TRACK:NAME" .. suffix]              = mic_key
          iXML["IXML:TRACK_LIST:TRACK:INTERLEAVE_INDEX" .. suffix]  = mic_idx
          iXML["IXML:TRACK_LIST:TRACK:CHANNEL_INDEX" .. suffix]     = mic_idx
        end

        iXML["IXML:TRACK_LIST:TRACK_COUNT"]                         =  tostring(#multi_mics)
      end
      
      -- Designer and Short ID
      mega_marker = mega_marker .. ";" .. "Designer=" .. meta_dsgnr
      local meta_short = ""
      for i in string.gmatch(meta_dsgnr, "%S+") do
        meta_short = meta_short .. i:sub(1,3)
      end
      mega_marker = mega_marker .. ";" .. "ShortID=" .. meta_short

      -- ASWG
      if ret_aswg_contentType and aswg_contentType ~= "" then
        mega_marker = mega_marker .. ";" .. "ASWGcontentType=" .. aswg_contentType
        mega_marker = mega_marker .. ";" .. "ASWGproject=" .. aswg_project
        mega_marker = mega_marker .. ";" .. "ASWGoriginatorStudio=" .. aswg_originatorStudio
        mega_marker = mega_marker .. ";" .. "ASWGnotes=" .. aswg_notes
        mega_marker = mega_marker .. ";" .. "ASWGstate=" .. aswg_state
        mega_marker = mega_marker .. ";" .. "ASWGeditor=" .. aswg_editor
        mega_marker = mega_marker .. ";" .. "ASWGmixer=" .. aswg_mixer
        mega_marker = mega_marker .. ";" .. "ASWGfxChainName=" .. aswg_fxChainName
        mega_marker = mega_marker .. ";" .. "ASWGchannelConfig=" .. aswg_channelConfig
        mega_marker = mega_marker .. ";" .. "ASWGambisonicFormat=" .. aswg_ambisonicFormat
        mega_marker = mega_marker .. ";" .. "ASWGambisonicChnOrder=" .. aswg_ambisonicChnOrder
        mega_marker = mega_marker .. ";" .. "ASWGambisonicNorm=" .. aswg_ambisonicNorm
        mega_marker = mega_marker .. ";" .. "ASWGisDesigned=" .. aswg_isDesigned
        mega_marker = mega_marker .. ";" .. "ASWGrecEngineer=" .. aswg_recEngineer
        mega_marker = mega_marker .. ";" .. "ASWGrecStudio=" .. aswg_recStudio
        mega_marker = mega_marker .. ";" .. "ASWGimpulseLocation=" .. aswg_impulseLocation
        mega_marker = mega_marker .. ";" .. "ASWGtext=" .. aswg_text
        mega_marker = mega_marker .. ";" .. "ASWGefforts=" .. aswg_efforts
        mega_marker = mega_marker .. ";" .. "ASWGeffortType=" .. aswg_effortType
        mega_marker = mega_marker .. ";" .. "ASWGprojection=" .. aswg_projection
        mega_marker = mega_marker .. ";" .. "ASWGlanguage=" .. aswg_language
        mega_marker = mega_marker .. ";" .. "ASWGtimingRestriction=" .. aswg_timingRestriction
        mega_marker = mega_marker .. ";" .. "ASWGcharacterName=" .. aswg_characterName
        mega_marker = mega_marker .. ";" .. "ASWGcharacterGender=" .. aswg_characterGender
        mega_marker = mega_marker .. ";" .. "ASWGcharacterAge=" .. aswg_characterAge
        mega_marker = mega_marker .. ";" .. "ASWGcharacterRole=" .. aswg_characterRole
        mega_marker = mega_marker .. ";" .. "ASWGactorName=" .. aswg_actorName
        mega_marker = mega_marker .. ";" .. "ASWGactorGender=" .. aswg_actorGender
        mega_marker = mega_marker .. ";" .. "ASWGdirection=" .. aswg_direction
        mega_marker = mega_marker .. ";" .. "ASWGdirector=" .. aswg_director
        mega_marker = mega_marker .. ";" .. "ASWGfxUsed=" .. aswg_fxUsed
        mega_marker = mega_marker .. ";" .. "ASWGusageRights=" .. aswg_usageRights
        mega_marker = mega_marker .. ";" .. "ASWGisUnion=" .. aswg_isUnion
        mega_marker = mega_marker .. ";" .. "ASWGaccent=" .. aswg_accent
        mega_marker = mega_marker .. ";" .. "ASWGemotion=" .. aswg_emotion
        mega_marker = mega_marker .. ";" .. "ASWGcomposer=" .. aswg_composer
        mega_marker = mega_marker .. ";" .. "ASWGartist=" .. aswg_artist
        mega_marker = mega_marker .. ";" .. "ASWGsongTitle=" .. aswg_songTitle
        mega_marker = mega_marker .. ";" .. "ASWGgenre=" .. aswg_genre
        mega_marker = mega_marker .. ";" .. "ASWGsubGenre=" .. aswg_subGenre
        mega_marker = mega_marker .. ";" .. "ASWGproducer=" .. aswg_producer
        mega_marker = mega_marker .. ";" .. "ASWGmusicSup=" .. aswg_musicSup
        mega_marker = mega_marker .. ";" .. "ASWGinstrument=" .. aswg_instrument
        mega_marker = mega_marker .. ";" .. "ASWGmusicPublisher=" .. aswg_musicPublisher
        mega_marker = mega_marker .. ";" .. "ASWGrightsOwner=" .. aswg_rightsOwner
        mega_marker = mega_marker .. ";" .. "ASWGintensity=" .. aswg_intensity
        mega_marker = mega_marker .. ";" .. "ASWGorderRef=" .. aswg_orderRef
        mega_marker = mega_marker .. ";" .. "ASWGisSource=" .. aswg_isSource
        mega_marker = mega_marker .. ";" .. "ASWGisLoop=" .. aswg_isLoop
        mega_marker = mega_marker .. ";" .. "ASWGisFinal=" .. aswg_isFinal
        mega_marker = mega_marker .. ";" .. "ASWGisOst=" .. aswg_isOst
        mega_marker = mega_marker .. ";" .. "ASWGisCinematic=" .. aswg_isCinematic
        mega_marker = mega_marker .. ";" .. "ASWGisLicensed=" .. aswg_isLicensed
        mega_marker = mega_marker .. ";" .. "ASWGisDiegetic=" .. aswg_isDiegetic
        mega_marker = mega_marker .. ";" .. "ASWGmusicVersion=" .. aswg_musicVersion
        mega_marker = mega_marker .. ";" .. "ASWGisrcId=" .. aswg_isrcId
        mega_marker = mega_marker .. ";" .. "ASWGtempo=" .. aswg_tempo
        mega_marker = mega_marker .. ";" .. "ASWGtimeSig=" .. aswg_timeSig
        mega_marker = mega_marker .. ";" .. "ASWGinKey=" .. aswg_inKey
        mega_marker = mega_marker .. ";" .. "ASWGbillingCode=" .. aswg_billingCode
      end
    end

    iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, mega_marker, ucs_num}
    iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position + 0.001, "META", ucs_num}


  -- Pre Reaper v6.33 Pile-Of-Markers Syntax
  else
      
    -- Standard UCS
    iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "CatID=" .. ucs_id, ucs_num}
    iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "Category=" .. ucs_cat, ucs_num}
    iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "SubCategory=" .. ucs_scat, ucs_num}
    iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "UserCategory=" .. ucs_usca, ucs_num}
    iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "VendorCategory=" .. ucs_vend, ucs_num}
    iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "FXName=" .. relname, ucs_num}
    iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "Notes=" .. ucs_data, ucs_num}
    iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "Show=" .. ucs_show, ucs_num}
    iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "CategoryFull=" .. ucs_cat .. "-" .. ucs_scat, ucs_num}
    
    -- Extended meta
    if ret_meta then
      iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "TrackTitle=" .. meta_title, ucs_num}
      iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "Description=" .. meta_desc, ucs_num}
      iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "Keywords=" .. meta_keys, ucs_num}
      iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "Microphone=" .. meta_mic, ucs_num}
      iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "RecMedium=" .. meta_recmed, ucs_num}
      iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "Library=" .. meta_lib, ucs_num}
      iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "Location=" .. meta_loc, ucs_num}
      iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "URL=" .. meta_url, ucs_num}
      iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "Manufacturer=" .. meta_mftr, ucs_num}
      iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "MetaNotes=" .. meta_notes, ucs_num}
      iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "MicPerspective=" .. meta_persp, ucs_num}
      iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "RecType=" .. meta_config, ucs_num}
      
      -- Designer and Short ID
      iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "Designer=" .. meta_dsgnr, ucs_num}
      local meta_short = ""
      for i in string.gmatch(meta_dsgnr, "%S+") do
        meta_short = meta_short .. i:sub(1,3)
      end
      iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "ShortID=" .. meta_short, ucs_num}

      -- ASWG
      if ret_aswg_contentType and aswg_contentType ~= "" then
        iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "ASWGcontentType=" .. aswg_contentType, ucs_num}
        iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "ASWGproject=" .. aswg_project, ucs_num}
        iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "ASWGoriginatorStudio=" .. aswg_originatorStudio, ucs_num}
        iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "ASWGnotes=" .. aswg_notes, ucs_num}
        iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "ASWGstate=" .. aswg_state, ucs_num}
        iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "ASWGeditor=" .. aswg_editor, ucs_num}
        iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "ASWGmixer=" .. aswg_mixer, ucs_num}
        iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "ASWGfxChainName=" .. aswg_fxChainName, ucs_num}
        iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "ASWGchannelConfig=" .. aswg_channelConfig, ucs_num}
        iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "ASWGambisonicFormat=" .. aswg_ambisonicFormat, ucs_num}
        iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "ASWGambisonicChnOrder=" .. aswg_ambisonicChnOrder, ucs_num}
        iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "ASWGambisonicNorm=" .. aswg_ambisonicNorm, ucs_num}
        iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "ASWGisDesigned=" .. aswg_isDesigned, ucs_num}
        iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "ASWGrecEngineer=" .. aswg_recEngineer, ucs_num}
        iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "ASWGrecStudio=" .. aswg_recStudio, ucs_num}
        iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "ASWGimpulseLocation=" .. aswg_impulseLocation, ucs_num}
        iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "ASWGtext=" .. aswg_text, ucs_num}
        iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "ASWGefforts=" .. aswg_efforts, ucs_num}
        iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "ASWGeffortType=" .. aswg_effortType, ucs_num}
        iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "ASWGprojection=" .. aswg_projection, ucs_num}
        iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "ASWGlanguage=" .. aswg_language, ucs_num}
        iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "ASWGtimingRestriction=" .. aswg_timingRestriction, ucs_num}
        iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "ASWGcharacterName=" .. aswg_characterName, ucs_num}
        iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "ASWGcharacterGender=" .. aswg_characterGender, ucs_num}
        iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "ASWGcharacterAge=" .. aswg_characterAge, ucs_num}
        iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "ASWGcharacterRole=" .. aswg_characterRole, ucs_num}
        iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "ASWGactorName=" .. aswg_actorName, ucs_num}
        iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "ASWGactorGender=" .. aswg_actorGender, ucs_num}
        iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "ASWGdirection=" .. aswg_direction, ucs_num}
        iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "ASWGdirector=" .. aswg_director, ucs_num}
        iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "ASWGfxUsed=" .. aswg_fxUsed, ucs_num}
        iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "ASWGusageRights=" .. aswg_usageRights, ucs_num}
        iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "ASWGisUnion=" .. aswg_isUnion, ucs_num}
        iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "ASWGaccent=" .. aswg_accent, ucs_num}
        iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "ASWGemotion=" .. aswg_emotion, ucs_num}
        iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "ASWGcomposer=" .. aswg_composer, ucs_num}
        iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "ASWGartist=" .. aswg_artist, ucs_num}
        iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "ASWGsongTitle=" .. aswg_songTitle, ucs_num}
        iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "ASWGgenre=" .. aswg_genre, ucs_num}
        iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "ASWGsubGenre=" .. aswg_subGenre, ucs_num}
        iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "ASWGproducer=" .. aswg_producer, ucs_num}
        iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "ASWGmusicSup=" .. aswg_musicSup, ucs_num}
        iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "ASWGinstrument=" .. aswg_instrument, ucs_num}
        iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "ASWGmusicPublisher=" .. aswg_musicPublisher, ucs_num}
        iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "ASWGrightsOwner=" .. aswg_rightsOwner, ucs_num}
        iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "ASWGintensity=" .. aswg_intensity, ucs_num}
        iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "ASWGorderRef=" .. aswg_orderRef, ucs_num}
        iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "ASWGisSource=" .. aswg_isSource, ucs_num}
        iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "ASWGisLoop=" .. aswg_isLoop, ucs_num}
        iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "ASWGisFinal=" .. aswg_isFinal, ucs_num}
        iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "ASWGisOst=" .. aswg_isOst, ucs_num}
        iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "ASWGisCinematic=" .. aswg_isCinematic, ucs_num}
        iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "ASWGisLicensed=" .. aswg_isLicensed, ucs_num}
        iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "ASWGisDiegetic=" .. aswg_isDiegetic, ucs_num}
        iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "ASWGmusicVersion=" .. aswg_musicVersion, ucs_num}
        iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "ASWGisrcId=" .. aswg_isrcId, ucs_num}
        iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "ASWGtempo=" .. aswg_tempo, ucs_num}
        iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "ASWGtimeSig=" .. aswg_timeSig, ucs_num}
        iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "ASWGinKey=" .. aswg_inKey, ucs_num}
        iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "ASWGbillingCode=" .. aswg_billingCode, ucs_num}
      end
    end
  end

  -- Set up metadata fields if user input is a Reaper wildcard
  if ret_meta then
    for k, v in pairs(iXML) do
      if retm_title  and v == "TrackTitle"   and meta_title:sub(1,1) == "$"  then reaper.GetSetProjectInfo_String( 0, "RENDER_METADATA", k .. "|" .. meta_title, true )  end
      if retm_desc   and v == "Description"  and meta_desc:sub(1,1) == "$"   then reaper.GetSetProjectInfo_String( 0, "RENDER_METADATA", k .. "|" .. meta_desc, true )   end
      if retm_keys   and v == "Keywords"     and meta_keys:sub(1,1) == "$"   then reaper.GetSetProjectInfo_String( 0, "RENDER_METADATA", k .. "|" .. meta_keys, true )   end
      if retm_mic    and v == "Microphone"   and meta_mic:sub(1,1) == "$"    then reaper.GetSetProjectInfo_String( 0, "RENDER_METADATA", k .. "|" .. meta_mic, true )    end
      if retm_lib    and v == "Library"      and meta_lib:sub(1,1) == "$"    then reaper.GetSetProjectInfo_String( 0, "RENDER_METADATA", k .. "|" .. meta_lib, true )    end      
      if retm_url    and v == "URL"          and meta_url:sub(1,1) == "$"    then reaper.GetSetProjectInfo_String( 0, "RENDER_METADATA", k .. "|" .. meta_url, true )    end
      if retm_mftr   and v == "Manufacturer" and meta_mftr:sub(1,1) == "$"   then reaper.GetSetProjectInfo_String( 0, "RENDER_METADATA", k .. "|" .. meta_mftr, true )   end
      if retm_notes  and v == "MetaNotes"    and meta_notes:sub(1,1) == "$"  then reaper.GetSetProjectInfo_String( 0, "RENDER_METADATA", k .. "|" .. meta_notes, true )  end
      if retm_recmed and v == "RecMedium"    and meta_recmed:sub(1,1) == "$" then reaper.GetSetProjectInfo_String( 0, "RENDER_METADATA", k .. "|" .. meta_recmed, true ) end
      if retm_dsgnr  and v == "Designer"     and meta_dsgnr:sub(1,1) == "$"  then reaper.GetSetProjectInfo_String( 0, "RENDER_METADATA", k .. "|" .. meta_dsgnr, true )  end
    end
  end

  -- Prep clipboard contents for Julibrary mode
  if julibrary_mode then
    if julibrary_headers then
      julibrary_metadata = julibrary_metadata ..
        "Filename" .. "\t" .. 
        "CatID" .. "\t" ..
        "Title" .. "\t" .. 
        "Description" .. "\t" ..
        "Keywords" .. "\t" ..
        "Notes" .. "\t" ..
        
        "Configuration" .. "\t" ..
        "Perspective" .. "\t" ..
        "Microphone" .. "\t" ..
        "Recorder" .. "\t" ..
        
        "Designer" .. "\t" ..
        "Library" .. "\t" ..
        "Location" .. "\n"
    end
    
    
    julibrary_metadata = julibrary_metadata .. 
      ucs_full_name .. ".wav" .. "\t" .. 
      ucs_id .. "\t" ..
      meta_title .. "\t" ..
      meta_desc .. "\t" .. 
      meta_keys .. "\t" ..
      ucs_data .. "\t" ..
      
      meta_config .. "\t" ..
      meta_persp .. "\t" ..
      meta_mic .. "\t" .. 
      meta_recmed .. "\t" ..
      
      meta_dsgnr .. "\t" ..
      meta_lib .. "\t" ..
      meta_loc .. "\n"
  end
end

-- Imports iXML Markers after processing
function iXMLMarkersEngage()
  -- Store all project markers and their positions/names/ids to a local table
  local projMarkerTbl = {}
  local _, nmb_mkr, nmb_rgn = reaper.CountProjectMarkers(0)
  local nmb_tot = nmb_mkr + nmb_rgn
  local i = 0
  while i < nmb_tot do
    local _, isrgn, pos, _, name, idx, _ = reaper.EnumProjectMarkers3( 0, i )
    if not isrgn and name:find("=") then
       -- v6.33 Marker Syntax [;]
      if v633_mkrs then
        -- Store the position of all metadata related markers
        if name:sub(1,5) == "META;" then
          projMarkerTbl[#projMarkerTbl+1] = tostring(pos) .. "META;" .. "||" .. tostring(i)
        end

      -- Pre Reaper v6.33 Pile-Of-Markers Syntax
      else
        -- Use lua string match to only get the content before the equals sign
        projMarkerTbl[#projMarkerTbl+1] = tostring(pos) .. name:gsub("=.*","") .. "||" .. tostring(i)
      end
    elseif not isrgn and name == "META" then
      projMarkerTbl[#projMarkerTbl+1] = tostring(pos) .. "META_MKR"
    end
    i = i + 1
  end

  -- Insert marker in project
  for _, v in pairs(iXMLMarkerTbl) do

    -- v6.33 Marker Syntax [;]
    if v633_mkrs then
      -- Search for combination of marker position and metadata prefix
      local search = tostring(v[1]) .. "META;"
      local search2 = tostring(v[1]) .. "META_MKR"

      if tableContainsVal(projMarkerTbl,search) then
        -- Found an existing marker with that metadata tag in that position, so just rename it
        if debug_mode then reaper.ShowConsoleMsg("Found a metadata marker at pos: " .. tostring(v[1]) .. " - " .. v[2] .. "\n") end
        local val = fetchTableVal(projMarkerTbl,search)
        val = val:gsub(".*||","") -- Get idx from end of string
        local retval, isrgn, pos, rgnend, name, markrgnidx, color = reaper.EnumProjectMarkers3( 0, tonumber(val) )
        reaper.SetProjectMarkerByIndex( 0, tonumber(val), isrgn, pos, rgnend, markrgnidx, v[2], color )
      elseif tableContainsVal(projMarkerTbl, search2) then
        -- This is just a "META" marker that doesn't do anything
      else
        -- Need to create a new marker
        if debug_mode then reaper.ShowConsoleMsg("Did not find an existing metadata marker at pos: " .. tostring(v[1]) .. " - " .. v[2] .. "\n") end
        reaper.AddProjectMarker( 0, 0, v[1], v[1], v[2], v[3] )
      end
      
    -- Pre Reaper v6.33 Pile-Of-Markers Syntax
    else
      -- Search for combination of marker position and metadata prefix
      local search = tostring(v[1]) .. v[2]:gsub("=.*","") 
      if tableContainsVal(projMarkerTbl,search) then
        -- Found an existing marker with that metadata tag in that position, so just rename it
        if debug_mode then reaper.ShowConsoleMsg("Found a metadata marker at pos: " .. tostring(v[1]) .. " - " .. v[2] .. "\n") end
        local val = fetchTableVal(projMarkerTbl,search)
        val = val:gsub(".*||","") -- Get idx from end of string
        local retval, isrgn, pos, rgnend, name, markrgnidx, color = reaper.EnumProjectMarkers3( 0, tonumber(val) )
        reaper.SetProjectMarkerByIndex( 0, tonumber(val), isrgn, pos, rgnend, markrgnidx, v[2], color )
      else
        -- Need to create a new marker
        if debug_mode then reaper.ShowConsoleMsg("Did not find an existing metadata marker at pos: " .. tostring(v[1]) .. " - " .. v[2] .. "\n") end
        reaper.AddProjectMarker( 0, 0, v[1], v[1], v[2], v[3] )
      end
    end
  end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~ Set Render Dir~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
function setRenderDirectory()
  reaper.Main_OnCommand(reaper.NamedCommandLookup("_S&M_WNMAIN_HIDE_OTHERS"), 0)
  if ret_dir and ucs_dir == "true" then
    if v633_mkrs then
      if ucs_type == "Regions" then
        reaper.GetSetProjectInfo_String(0, "RENDER_PATTERN", "$marker(Category)[;]/$marker(Subcategory)[;]/$region", true)
      elseif ucs_type == "Markers" then
        reaper.GetSetProjectInfo_String(0, "RENDER_PATTERN", "$marker(Category)[;]/$marker(Subcategory)[;]/$marker", true)
      elseif ucs_type == "Media Items" or ucs_type == "NVK Folder Items" then
        reaper.GetSetProjectInfo_String(0, "RENDER_PATTERN", "$marker(Category)[;]/$marker(Subcategory)[;]/$item", true)
      elseif ucs_type == "Tracks" then
        reaper.GetSetProjectInfo_String(0, "RENDER_PATTERN", "$marker(Category)[;]/$marker(Subcategory)[;]/$track", true)
      end
    else
      if ucs_type == "Regions" then
        reaper.GetSetProjectInfo_String(0, "RENDER_PATTERN", "$marker(Category)/$marker(Subcategory)/$region", true)
      elseif ucs_type == "Markers" then
        reaper.GetSetProjectInfo_String(0, "RENDER_PATTERN", "$marker(Category)/$marker(Subcategory)/$marker", true)
      elseif ucs_type == "Media Items" or ucs_type == "NVK Folder Items" then
        reaper.GetSetProjectInfo_String(0, "RENDER_PATTERN", "$marker(Category)/$marker(Subcategory)/$item", true)
      elseif ucs_type == "Tracks" then
        reaper.GetSetProjectInfo_String(0, "RENDER_PATTERN", "$marker(Category)/$marker(Subcategory)/$track", true)
      end
    end
  else
    if ucs_type == "Regions" then
      reaper.GetSetProjectInfo_String(0, "RENDER_PATTERN", "$region", true)
    elseif ucs_type == "Markers" then
      reaper.GetSetProjectInfo_String(0, "RENDER_PATTERN", "$marker", true)
    elseif ucs_type == "Media Items" or ucs_type == "NVK Folder Items" then
      reaper.GetSetProjectInfo_String(0, "RENDER_PATTERN", "$item", true)
    elseif ucs_type == "Tracks" then
      reaper.GetSetProjectInfo_String(0, "RENDER_PATTERN", "$track", true)
    end
  end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~ Rets to Bools ~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
function ucsRetsToBool()
  if ret_cat  == 1 then ret_cat  = true else ret_cat  = false end
  if ret_scat == 1 then ret_scat = true else ret_scat = false end
  if ret_usca == 1 then ret_usca = true else ret_usca = false end
  if ret_id   == 1 then ret_id   = true else ret_id   = false end
  if ret_name == 1 then ret_name = true else ret_name = false end
  if ret_num  == 1 then ret_num  = true else ret_num  = false end
  if ret_enum == 1 then ret_enum = true else ret_enum = false end
  if ret_ixml == 1 then ret_ixml = true else ret_ixml = false end
  if ret_dir  == 1 then ret_dir  = true else ret_dir  = false end
  if ret_mkr  == 1 then ret_mkr  = true else ret_mkr  = false end
  if ret_mpos == 1 then ret_mpos = true else ret_mpos = false end
  if ret_meta == 1 then ret_meta = true else ret_meta = false end
  if ret_init == 1 then ret_init = true else ret_init = false end
  if ret_show == 1 then ret_show = true else ret_show = false end
  if ret_type == 1 then ret_type = true else ret_type = false end
  if ret_area == 1 then ret_area = true else ret_area = false end
  if ret_data == 1 then ret_data = true else ret_data = false end
  if ret_caps == 1 then ret_caps = true else ret_caps = false end
  if ret_frmt == 1 then ret_frmt = true else ret_frmt = false end
  if ret_copy == 1 then ret_copy = true else ret_copy = false end
  
  -- Vendor category
  if ret_vend == 1 and ucs_vend ~= "false" then ret_vend = true else ret_vend = false; ucs_vend = "" end
  
  -- Extended metadata
  if retm_title  == 1 then retm_title  = true else retm_title  = false end
  if retm_desc   == 1 then retm_desc   = true else retm_desc   = false end
  if retm_keys   == 1 then retm_keys   = true else retm_keys   = false end
  if retm_mic    == 1 then retm_mic    = true else retm_mic    = false end
  if retm_recmed == 1 then retm_recmed = true else retm_recmed = false end
  if retm_dsgnr  == 1 then retm_dsgnr  = true else retm_dsgnr  = false end
  if retm_lib    == 1 then retm_lib    = true else retm_lib    = false end
  if retm_loc    == 1 then retm_loc    = true else retm_loc    = false end
  if retm_url    == 1 then retm_url    = true else retm_url    = false end
  if retm_mftr   == 1 then retm_mftr   = true else retm_mftr   = false end
  if retm_notes  == 1 then retm_notes  = true else retm_notes  = false end
  if retm_persp  == 1 then retm_persp  = true else retm_persp  = false end
  if retm_config == 1 then retm_config = true else retm_config = false end
  
  -- GBX Mod
  if retg_mod == 1 and gbx_mod ~= "false" then retg_mod = true else retg_mod = false end

  -- ASWG
  if ret_aswg_contentType == 1 then ret_aswg_contentType  = true else ret_aswg_contentType = false end
  if ret_aswg_project == 1 then ret_aswg_project  = true else ret_aswg_project = false end
  if ret_aswg_originatorStudio == 1 then ret_aswg_originatorStudio  = true else ret_aswg_originatorStudio = false end
  if ret_aswg_notes == 1 then ret_aswg_notes  = true else ret_aswg_notes = false end
  if ret_aswg_state == 1 then ret_aswg_state  = true else ret_aswg_state = false end
  if ret_aswg_editor == 1 then ret_aswg_editor  = true else ret_aswg_editor = false end
  if ret_aswg_mixer == 1 then ret_aswg_mixer  = true else ret_aswg_mixer = false end
  if ret_aswg_fxChainName == 1 then ret_aswg_fxChainName  = true else ret_aswg_fxChainName = false end
  if ret_aswg_channelConfig == 1 then ret_aswg_channelConfig  = true else ret_aswg_channelConfig = false end
  if ret_aswg_ambisonicFormat == 1 then ret_aswg_ambisonicFormat  = true else ret_aswg_ambisonicFormat = false end
  if ret_aswg_ambisonicChnOrder == 1 then ret_aswg_ambisonicChnOrder  = true else ret_aswg_ambisonicChnOrder = false end
  if ret_aswg_ambisonicNorm == 1 then ret_aswg_ambisonicNorm  = true else ret_aswg_ambisonicNorm = false end
  if ret_aswg_isDesigned == 1 then ret_aswg_isDesigned  = true else ret_aswg_isDesigned = false end
  if ret_aswg_recEngineer == 1 then ret_aswg_recEngineer  = true else ret_aswg_recEngineer = false end
  if ret_aswg_recStudio == 1 then ret_aswg_recStudio  = true else ret_aswg_recStudio = false end
  if ret_aswg_impulseLocation == 1 then ret_aswg_impulseLocation  = true else ret_aswg_impulseLocation = false end
  if ret_aswg_text == 1 then ret_aswg_text  = true else ret_aswg_text = false end
  if ret_aswg_efforts == 1 then ret_aswg_efforts  = true else ret_aswg_efforts = false end
  if ret_aswg_effortType == 1 then ret_aswg_effortType  = true else ret_aswg_effortType = false end
  if ret_aswg_projection == 1 then ret_aswg_projection  = true else ret_aswg_projection = false end
  if ret_aswg_language == 1 then ret_aswg_language  = true else ret_aswg_language = false end
  if ret_aswg_timingRestriction == 1 then ret_aswg_timingRestriction  = true else ret_aswg_timingRestriction = false end
  if ret_aswg_characterName == 1 then ret_aswg_characterName  = true else ret_aswg_characterName = false end
  if ret_aswg_characterGender == 1 then ret_aswg_characterGender  = true else ret_aswg_characterGender = false end
  if ret_aswg_characterAge == 1 then ret_aswg_characterAge  = true else ret_aswg_characterAge = false end
  if ret_aswg_characterRole == 1 then ret_aswg_characterRole  = true else ret_aswg_characterRole = false end
  if ret_aswg_actorName == 1 then ret_aswg_actorName  = true else ret_aswg_actorName = false end
  if ret_aswg_actorGender == 1 then ret_aswg_actorGender  = true else ret_aswg_actorGender = false end
  if ret_aswg_direction == 1 then ret_aswg_direction  = true else ret_aswg_direction = false end
  if ret_aswg_director == 1 then ret_aswg_director  = true else ret_aswg_director = false end
  if ret_aswg_fxUsed == 1 then ret_aswg_fxUsed  = true else ret_aswg_fxUsed = false end
  if ret_aswg_usageRights == 1 then ret_aswg_usageRights  = true else ret_aswg_usageRights = false end
  if ret_aswg_isUnion == 1 then ret_aswg_isUnion  = true else ret_aswg_isUnion = false end
  if ret_aswg_accent == 1 then ret_aswg_accent  = true else ret_aswg_accent = false end
  if ret_aswg_emotion == 1 then ret_aswg_emotion  = true else ret_aswg_emotion = false end
  if ret_aswg_composer == 1 then ret_aswg_composer  = true else ret_aswg_composer = false end
  if ret_aswg_artist == 1 then ret_aswg_artist  = true else ret_aswg_artist = false end
  if ret_aswg_songTitle == 1 then ret_aswg_songTitle  = true else ret_aswg_songTitle = false end
  if ret_aswg_genre == 1 then ret_aswg_genre  = true else ret_aswg_genre = false end
  if ret_aswg_subGenre == 1 then ret_aswg_subGenre  = true else ret_aswg_subGenre = false end
  if ret_aswg_producer == 1 then ret_aswg_producer  = true else ret_aswg_producer = false end
  if ret_aswg_musicSup == 1 then ret_aswg_musicSup  = true else ret_aswg_musicSup = false end
  if ret_aswg_instrument == 1 then ret_aswg_instrument  = true else ret_aswg_instrument = false end
  if ret_aswg_musicPublisher == 1 then ret_aswg_musicPublisher  = true else ret_aswg_musicPublisher = false end
  if ret_aswg_rightsOwner == 1 then ret_aswg_rightsOwner  = true else ret_aswg_rightsOwner = false end
  if ret_aswg_intensity == 1 then ret_aswg_intensity  = true else ret_aswg_intensity = false end
  if ret_aswg_orderRef == 1 then ret_aswg_orderRef  = true else ret_aswg_orderRef = false end
  if ret_aswg_isSource == 1 then ret_aswg_isSource  = true else ret_aswg_isSource = false end
  if ret_aswg_isLoop == 1 then ret_aswg_isLoop  = true else ret_aswg_isLoop = false end
  if ret_aswg_isFinal == 1 then ret_aswg_isFinal  = true else ret_aswg_isFinal = false end
  if ret_aswg_isOst == 1 then ret_aswg_isOst  = true else ret_aswg_isOst = false end
  if ret_aswg_isCinematic == 1 then ret_aswg_isCinematic  = true else ret_aswg_isCinematic = false end
  if ret_aswg_isLicensed == 1 then ret_aswg_isLicensed  = true else ret_aswg_isLicensed = false end
  if ret_aswg_isDiegetic == 1 then ret_aswg_isDiegetic  = true else ret_aswg_isDiegetic = false end
  if ret_aswg_musicVersion == 1 then ret_aswg_musicVersion  = true else ret_aswg_musicVersion = false end
  if ret_aswg_isrcId == 1 then ret_aswg_isrcId  = true else ret_aswg_isrcId = false end
  if ret_aswg_tempo == 1 then ret_aswg_tempo  = true else ret_aswg_tempo = false end
  if ret_aswg_timeSig == 1 then ret_aswg_timeSig  = true else ret_aswg_timeSig = false end
  if ret_aswg_inKey == 1 then ret_aswg_inKey  = true else ret_aswg_inKey = false end
  if ret_aswg_billingCode == 1 then ret_aswg_billingCode  = true else ret_aswg_billingCode = false end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~ Debug UCS Input ~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
function debugUCSInput()
  reaper.ShowConsoleMsg("Category: " .. ucs_cat .. " (" .. tostring(ret_cat) .. ")" .. "\n")
  reaper.ShowConsoleMsg("Subcategory: " .. ucs_scat .. " (" .. tostring(ret_scat) .. ")" .. "\n")
  reaper.ShowConsoleMsg("User Cat.: " .. ucs_usca .. " (" .. tostring(ret_usca) .. ")" .. "\n")
  reaper.ShowConsoleMsg("Vendor Cat.: " .. ucs_vend .. " (" .. tostring(ret_vend) .. ")" .. "\n")
  reaper.ShowConsoleMsg("CatID: " .. ucs_id .. " (" .. tostring(ret_id) .. ")" .. "\n")
  reaper.ShowConsoleMsg("Name: " .. ucs_name .. " (" .. tostring(ret_name) .. ")" .. "\n")
  reaper.ShowConsoleMsg("Number: ".. ucs_num .. " (" .. tostring(ret_num).. ")" .. "\n")
  reaper.ShowConsoleMsg("Enum: " .. ucs_enum .. " (" .. tostring(ret_enum) .. ")" .. "\n")
  reaper.ShowConsoleMsg("iXML: " .. ucs_ixml .. " (" .. tostring(ret_ixml) .. ")" .. "\n")
  reaper.ShowConsoleMsg("Directory: " .. ucs_dir .." (" .. tostring(ret_dir) ..")" .. "\n")
  reaper.ShowConsoleMsg("Mrkr Pos:" .. ucs_mpos .. " (" .. tostring(ret_mpos) .. ")" .. "\n")
  reaper.ShowConsoleMsg("Initials: ".. ucs_init .. " (" .. tostring(ret_init) .. ")" .. "\n")
  reaper.ShowConsoleMsg("Show: ".. ucs_show .. " (" .. tostring(ret_show) .. ")" .. "\n")
  reaper.ShowConsoleMsg("Type: ".. ucs_type .. " (" .. tostring(ret_type) .. ")" .. "\n")
  reaper.ShowConsoleMsg("Data: ".. ucs_data .. " (" .. tostring(ret_data) .. ")" .. "\n")
  reaper.ShowConsoleMsg("Caps: ".. ucs_caps .. " (" .. tostring(ret_caps) .. ")" .. "\n")
  reaper.ShowConsoleMsg("FX Frmt: ".. ucs_frmt .. " (" .. tostring(ret_frmt) .. ")" .. "\n")
  reaper.ShowConsoleMsg("Copy: ".. ucs_copy .. " (" .. tostring(ret_copy) .. ")" .. "\n")
  reaper.ShowConsoleMsg("Area: ".. ucs_area .. " (" .. tostring(ret_area) .. ")" .. "\n")

  reaper.ShowConsoleMsg("\n~~~EXTENDED METADATA~~~\n")
  reaper.ShowConsoleMsg("Meta: ".. ucs_meta .. " (" .. tostring(ret_meta) .. ")" .. "\n")
  reaper.ShowConsoleMsg("Title: " .. meta_title .. " (" .. tostring(retm_title) .. ")" .. "\n")
  reaper.ShowConsoleMsg("Desc: ".. meta_desc .. " (" .. tostring(retm_desc) .. ")" .. "\n")
  reaper.ShowConsoleMsg("Keys: ".. meta_keys .. " (" .. tostring(retm_keys) .. ")" .. "\n")
  reaper.ShowConsoleMsg("Mic: " .. meta_mic .. " (" .. tostring(retm_mic) .. ")" .. "\n")
  reaper.ShowConsoleMsg("RecMed: ".. meta_recmed .. " (" .. tostring(retm_recmed) .. ")" .. "\n")
  reaper.ShowConsoleMsg("Designer: ".. meta_dsgnr .. " (" .. tostring(retm_dsgnr) .. ")" .. "\n")
  reaper.ShowConsoleMsg("Library: " .. meta_lib .. " (" .. tostring(retm_lib) .. ")" .. "\n")
  reaper.ShowConsoleMsg("Location: ".. meta_loc .. " (" .. tostring(retm_loc) .. ")" .. "\n")
  reaper.ShowConsoleMsg("URL: " .. meta_url .. " (" .. tostring(retm_url) .. ")" .. "\n")
  reaper.ShowConsoleMsg("Manufacturer: " .. meta_mftr .. " (" .. tostring(retm_mftr) .. ")" .. "\n")
  reaper.ShowConsoleMsg("Meta Notes: " .. meta_notes .. " (" .. tostring(retm_notes) .. ")" .. "\n")
  reaper.ShowConsoleMsg("Perspective: " .. meta_persp .. " (" .. tostring(retm_persp) .. ")" .. "\n")
  reaper.ShowConsoleMsg("Mic Config: ".. meta_config .. " (" .. tostring(retm_config) .. ")" .. "\n")

  reaper.ShowConsoleMsg("\n~~~ASWG~~~\n")
  reaper.ShowConsoleMsg("ASWGcontentType: " .. aswg_contentType .. " (" .. tostring(ret_aswg_contentType) .. ")" .. "\n")
  reaper.ShowConsoleMsg("ASWGproject: " .. aswg_project .. " (" .. tostring(ret_aswg_project) .. ")" .. "\n")
  reaper.ShowConsoleMsg("ASWGoriginatorStudio: " .. aswg_originatorStudio .. " (" .. tostring(ret_aswg_originatorStudio) .. ")" .. "\n")
  reaper.ShowConsoleMsg("ASWGnotes: " .. aswg_notes .. " (" .. tostring(ret_aswg_notes) .. ")" .. "\n")
  reaper.ShowConsoleMsg("ASWGstate: " .. aswg_state .. " (" .. tostring(ret_aswg_state) .. ")" .. "\n")
  reaper.ShowConsoleMsg("ASWGeditor: " .. aswg_editor .. " (" .. tostring(ret_aswg_editor) .. ")" .. "\n")
  reaper.ShowConsoleMsg("ASWGmixer: " .. aswg_mixer .. " (" .. tostring(ret_aswg_mixer) .. ")" .. "\n")
  reaper.ShowConsoleMsg("ASWGfxChainName: " .. aswg_fxChainName .. " (" .. tostring(ret_aswg_fxChainName) .. ")" .. "\n")
  reaper.ShowConsoleMsg("ASWGchannelConfig: " .. aswg_channelConfig .. " (" .. tostring(ret_aswg_channelConfig) .. ")" .. "\n")
  reaper.ShowConsoleMsg("ASWGambisonicFormat: " .. aswg_ambisonicFormat .. " (" .. tostring(ret_aswg_ambisonicFormat) .. ")" .. "\n")
  reaper.ShowConsoleMsg("ASWGambisonicChnOrder: " .. aswg_ambisonicChnOrder .. " (" .. tostring(ret_aswg_ambisonicChnOrder) .. ")" .. "\n")
  reaper.ShowConsoleMsg("ASWGambisonicNorm: " .. aswg_ambisonicNorm .. " (" .. tostring(ret_aswg_ambisonicNorm) .. ")" .. "\n")
  reaper.ShowConsoleMsg("ASWGisDesigned: " .. aswg_isDesigned .. " (" .. tostring(ret_aswg_isDesigned) .. ")" .. "\n")
  reaper.ShowConsoleMsg("ASWGrecEngineer: " .. aswg_recEngineer .. " (" .. tostring(ret_aswg_recEngineer) .. ")" .. "\n")
  reaper.ShowConsoleMsg("ASWGrecStudio: " .. aswg_recStudio .. " (" .. tostring(ret_aswg_recStudio) .. ")" .. "\n")
  reaper.ShowConsoleMsg("ASWGimpulseLocation: " .. aswg_impulseLocation .. " (" .. tostring(ret_aswg_impulseLocation) .. ")" .. "\n")
  reaper.ShowConsoleMsg("ASWGtext: " .. aswg_text .. " (" .. tostring(ret_aswg_text) .. ")" .. "\n")
  reaper.ShowConsoleMsg("ASWGefforts: " .. aswg_efforts .. " (" .. tostring(ret_aswg_efforts) .. ")" .. "\n")
  reaper.ShowConsoleMsg("ASWGeffortType: " .. aswg_effortType .. " (" .. tostring(ret_aswg_effortType) .. ")" .. "\n")
  reaper.ShowConsoleMsg("ASWGprojection: " .. aswg_projection .. " (" .. tostring(ret_aswg_projection) .. ")" .. "\n")
  reaper.ShowConsoleMsg("ASWGlanguage: " .. aswg_language .. " (" .. tostring(ret_aswg_language) .. ")" .. "\n")
  reaper.ShowConsoleMsg("ASWGtimingRestriction: " .. aswg_timingRestriction .. " (" .. tostring(ret_aswg_timingRestriction) .. ")" .. "\n")
  reaper.ShowConsoleMsg("ASWGcharacterName: " .. aswg_characterName .. " (" .. tostring(ret_aswg_characterName) .. ")" .. "\n")
  reaper.ShowConsoleMsg("ASWGcharacterGender: " .. aswg_characterGender .. " (" .. tostring(ret_aswg_characterGender) .. ")" .. "\n")
  reaper.ShowConsoleMsg("ASWGcharacterAge: " .. aswg_characterAge .. " (" .. tostring(ret_aswg_characterAge) .. ")" .. "\n")
  reaper.ShowConsoleMsg("ASWGcharacterRole: " .. aswg_characterRole .. " (" .. tostring(ret_aswg_characterRole) .. ")" .. "\n")
  reaper.ShowConsoleMsg("ASWGactorName: " .. aswg_actorName .. " (" .. tostring(ret_aswg_actorName) .. ")" .. "\n")
  reaper.ShowConsoleMsg("ASWGactorGender: " .. aswg_actorGender .. " (" .. tostring(ret_aswg_actorGender) .. ")" .. "\n")
  reaper.ShowConsoleMsg("ASWGdirection: " .. aswg_direction .. " (" .. tostring(ret_aswg_direction) .. ")" .. "\n")
  reaper.ShowConsoleMsg("ASWGdirector: " .. aswg_director .. " (" .. tostring(ret_aswg_director) .. ")" .. "\n")
  reaper.ShowConsoleMsg("ASWGfxUsed: " .. aswg_fxUsed .. " (" .. tostring(ret_aswg_fxUsed) .. ")" .. "\n")
  reaper.ShowConsoleMsg("ASWGusageRights: " .. aswg_usageRights .. " (" .. tostring(ret_aswg_usageRights) .. ")" .. "\n")
  reaper.ShowConsoleMsg("ASWGisUnion: " .. aswg_isUnion .. " (" .. tostring(ret_aswg_isUnion) .. ")" .. "\n")
  reaper.ShowConsoleMsg("ASWGaccent: " .. aswg_accent .. " (" .. tostring(ret_aswg_accent) .. ")" .. "\n")
  reaper.ShowConsoleMsg("ASWGemotion: " .. aswg_emotion .. " (" .. tostring(ret_aswg_emotion) .. ")" .. "\n")
  reaper.ShowConsoleMsg("ASWGcomposer: " .. aswg_composer .. " (" .. tostring(ret_aswg_composer) .. ")" .. "\n")
  reaper.ShowConsoleMsg("ASWGartist: " .. aswg_artist .. " (" .. tostring(ret_aswg_artist) .. ")" .. "\n")
  reaper.ShowConsoleMsg("ASWGsongTitle: " .. aswg_songTitle .. " (" .. tostring(ret_aswg_songTitle) .. ")" .. "\n")
  reaper.ShowConsoleMsg("ASWGgenre: " .. aswg_genre .. " (" .. tostring(ret_aswg_genre) .. ")" .. "\n")
  reaper.ShowConsoleMsg("ASWGsubGenre: " .. aswg_subGenre .. " (" .. tostring(ret_aswg_subGenre) .. ")" .. "\n")
  reaper.ShowConsoleMsg("ASWGproducer: " .. aswg_producer .. " (" .. tostring(ret_aswg_producer) .. ")" .. "\n")
  reaper.ShowConsoleMsg("ASWGmusicSup: " .. aswg_musicSup .. " (" .. tostring(ret_aswg_musicSup) .. ")" .. "\n")
  reaper.ShowConsoleMsg("ASWGinstrument: " .. aswg_instrument .. " (" .. tostring(ret_aswg_instrument) .. ")" .. "\n")
  reaper.ShowConsoleMsg("ASWGmusicPublisher: " .. aswg_musicPublisher .. " (" .. tostring(ret_aswg_musicPublisher) .. ")" .. "\n")
  reaper.ShowConsoleMsg("ASWGrightsOwner: " .. aswg_rightsOwner .. " (" .. tostring(ret_aswg_rightsOwner) .. ")" .. "\n")
  reaper.ShowConsoleMsg("ASWGintensity: " .. aswg_intensity .. " (" .. tostring(ret_aswg_intensity) .. ")" .. "\n")
  reaper.ShowConsoleMsg("ASWGorderRef: " .. aswg_orderRef .. " (" .. tostring(ret_aswg_orderRef) .. ")" .. "\n")
  reaper.ShowConsoleMsg("ASWGisSource: " .. aswg_isSource .. " (" .. tostring(ret_aswg_isSource) .. ")" .. "\n")
  reaper.ShowConsoleMsg("ASWGisLoop: " .. aswg_isLoop .. " (" .. tostring(ret_aswg_isLoop) .. ")" .. "\n")
  reaper.ShowConsoleMsg("ASWGisFinal: " .. aswg_isFinal .. " (" .. tostring(ret_aswg_isFinal) .. ")" .. "\n")
  reaper.ShowConsoleMsg("ASWGisOst: " .. aswg_isOst .. " (" .. tostring(ret_aswg_isOst) .. ")" .. "\n")
  reaper.ShowConsoleMsg("ASWGisCinematic: " .. aswg_isCinematic .. " (" .. tostring(ret_aswg_isCinematic) .. ")" .. "\n")
  reaper.ShowConsoleMsg("ASWGisLicensed: " .. aswg_isLicensed .. " (" .. tostring(ret_aswg_isLicensed) .. ")" .. "\n")
  reaper.ShowConsoleMsg("ASWGisDiegetic: " .. aswg_isDiegetic .. " (" .. tostring(ret_aswg_isDiegetic) .. ")" .. "\n")
  reaper.ShowConsoleMsg("ASWGmusicVersion: " .. aswg_musicVersion .. " (" .. tostring(ret_aswg_musicVersion) .. ")" .. "\n")
  reaper.ShowConsoleMsg("ASWGisrcId: " .. aswg_isrcId .. " (" .. tostring(ret_aswg_isrcId) .. ")" .. "\n")
  reaper.ShowConsoleMsg("ASWGtempo: " .. aswg_tempo .. " (" .. tostring(ret_aswg_tempo) .. ")" .. "\n")
  reaper.ShowConsoleMsg("ASWGtimeSig: " .. aswg_timeSig .. " (" .. tostring(ret_aswg_timeSig) .. ")" .. "\n")
  reaper.ShowConsoleMsg("ASWGinKey: " .. aswg_inKey .. " (" .. tostring(ret_aswg_inKey) .. ")" .. "\n")
  reaper.ShowConsoleMsg("ASWGbillingCode: " .. aswg_billingCode .. " (" .. tostring(ret_aswg_billingCode) .. ")" .. "\n")
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~ Open Web Interface ~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
function openUCSWebInterface()
  local web_int_settings = getWebInterfaceSettings()
  local localhost = "http://localhost:"
  local ucs_path = ""
  
  for _, line in pairs(web_int_settings) do
    if line:find("acendan_UCS Renaming Tool.html") then
      local port = getPort(line)
      ucs_path = localhost .. port
      break
    
    elseif line:find("acendan_UCS Renaming Tool_Dark.html") then
      local port = getPort(line)
      ucs_path = localhost .. port
      break
    end
  end
  
  if ucs_path ~= "" then
    openURL(ucs_path)
  else
    local response = reaper.MB("UCS Renaming Tool not found in Reaper Web Interface settings!\n\nWould you like to open the installation tutorial video?","Open UCS Renaming Tool",4)
    if response == 6 then openURL("https://youtu.be/fO-2At7eEQ0") end
  end
end

-- Open a webpage or file directory
function openURL(path)
  reaper.CF_ShellExecute(path)
end

-- Get web interface info from REAPER.ini // returns Table
function getWebInterfaceSettings()
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

-- Get localhost port from reaper.ini file line
function getPort(line)
  local port = line:sub(line:find(" ")+3,line:find("'")-2)
  return port
end


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~ UTILITIES ~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Check if a table contains a key // returns Boolean
function tableContainsKey(table, key)
  return table[key] ~= nil
end

-- Check if a table contains a value in any one of its keys // returns Boolean
function tableContainsVal(table, val)
  for index, value in ipairs(table) do
    if value:find(val) then
      return true
    end
  end
  return false
end

-- Modded version of above to return full value because this code is nuts
function fetchTableVal(table, val)
  for index, value in ipairs(table) do
    if value:find(val) then
      return value
    end
  end
  return ""
end

-- Case insensitive gsub // returns String
-- http://lua-users.org/lists/lua-l/2001-04/msg00206.html
function string.gisub(s, pat, repl, n)
  pat = string.gsub(pat, '(%a)', 
    function (v) return '['..string.upper(v)..string.lower(v)..']' end)
  if n then
    return string.gsub(s, pat, repl, n)
  else
    return string.gsub(s, pat, repl)
  end
end

-- Case insensitive find // returns Bool
function string.ifind(s, word)
  return string.find(string.lower(s),string.lower(word)) and true or false
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~~~~~~~~~~  
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Check for JS_ReaScript Extension
if not reaper.JS_Dialog_BrowseForSaveFile then
  reaper.MB("Please install the JS_ReaScriptAPI REAPER extension, available in ReaPack, under the ReaTeam Extensions repository.\n\nExtensions > ReaPack > Browse Packages\n\nFilter for 'JS_ReascriptAPI'. Right click to install.","UCS Renaming Tool", 0)
  return
end

-- Run from web interface, execute script
if reaper.HasExtState( "UCS_WebInterface", "runFromWeb" ) then
  if reaper.GetExtState( "UCS_WebInterface", "runFromWeb" ) == "true" then
    reaper.SetExtState( "UCS_WebInterface", "runFromWeb", "false", true )
    reaper.PreventUIRefresh(1)
    parseUCSWebInterfaceInput()
    reaper.PreventUIRefresh(-1)
    reaper.UpdateArrange()
    return
  end
end

-- Open web interface - No extstate found or run from Actions List
if not debug_mode then openUCSWebInterface() end
