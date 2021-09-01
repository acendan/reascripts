-- @description UCS Renaming Tool
-- @author Aaron Cendan
-- @version 5.2
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
--   + Added native Reaper wildcard support in Metadata section of the tool

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS FROM WEB INTERFACE ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

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
local ret_mkr,  ucs_mkr  = reaper.GetProjExtState( 0, "UCS_WebInterface", "MarkerFormat" )
local ret_mpos, ucs_mpos = reaper.GetProjExtState( 0, "UCS_WebInterface", "MarkerPosition")
local ret_init, ucs_init = reaper.GetProjExtState( 0, "UCS_WebInterface", "Initials" )
local ret_show, ucs_show = reaper.GetProjExtState( 0, "UCS_WebInterface", "Show" )
local ret_type, ucs_type = reaper.GetProjExtState( 0, "UCS_WebInterface", "userInputItems" )
local ret_area, ucs_area = reaper.GetProjExtState( 0, "UCS_WebInterface", "userInputArea" )
local ret_data, ucs_data = reaper.GetProjExtState( 0, "UCS_WebInterface", "Data" )
local ret_caps, ucs_caps = reaper.GetProjExtState( 0, "UCS_WebInterface", "nameCapitalizationSetting")
local ret_copy, ucs_copy = reaper.GetProjExtState( 0, "UCS_WebInterface", "copyResultsSetting")

-- Extended metadata fields
local retm_title,  meta_title  = reaper.GetProjExtState( 0, "UCS_WebInterface", "MetaTitle")
local retm_desc,   meta_desc   = reaper.GetProjExtState( 0, "UCS_WebInterface", "MetaDesc")
local retm_keys,   meta_keys   = reaper.GetProjExtState( 0, "UCS_WebInterface", "MetaKeys")
local retm_mic,    meta_mic    = reaper.GetProjExtState( 0, "UCS_WebInterface", "MetaMic")
local retm_recmed, meta_recmed = reaper.GetProjExtState( 0, "UCS_WebInterface", "MetaRecMed")
local retm_dsgnr,  meta_dsgnr  = reaper.GetProjExtState( 0, "UCS_WebInterface", "MetaDsgnr")
local retm_lib,    meta_lib    = reaper.GetProjExtState( 0, "UCS_WebInterface", "MetaLib")
local retm_loc,    meta_loc    = reaper.GetProjExtState( 0, "UCS_WebInterface", "MetaLoc")
local retm_url,    meta_url    = reaper.GetProjExtState( 0, "UCS_WebInterface", "MetaURL")
local retm_persp,  meta_persp  = reaper.GetProjExtState( 0, "UCS_WebInterface", "MetaPersp")
local retm_config, meta_config = reaper.GetProjExtState( 0, "UCS_WebInterface", "MetaConfig")

-- Initialize global var for full name, see setFullName()
local ucs_full_name = ""

-- Init copy settings (EDIT VIA SETTINGS MENU OF THE WEB INTERFACE)
local copy_to_clipboard = false
local copy_without_processing = false
local line_to_copy = ""

-- Toggle for debugging UCS input with message box & opening UCS tool on script file save
local debug_mode = false

-- Toggle for copying metadata to clipboard for Julibrary metadata sheet
local julibrary_mode = false
local julibrary_metadata = ""
local tab = "\t"


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
iXML["IXML:USER:Notes"]          = "Notes"           -- User Data/Notes (Optional)     
iXML["IXML:USER:Show"]           = "Show"            -- Source ID                        
iXML["IXML:USER:UserCategory"]   = "UserCategory"    -- User Category                   
iXML["IXML:USER:VendorCategory"] = "VendorCategory"  -- Vendor Category

-- Extended Metadata Fields
iXML["IXML:USER:TrackTitle"]     = "TrackTitle"      -- SHORT ALL CAPS TITLE to catch attention.    userInputMetaTitle
iXML["IXML:USER:Description"]    = "Description"     -- Detailed description.                       userInputMetaDesc
iXML["IXML:USER:Keywords"]       = "Keywords"        -- Comma separated keywords.                   userInputMetaKeys
iXML["IXML:USER:Microphone"]     = "Microphone"      -- Microphone                                  userInputMetaMic
iXML["IXML:USER:MicPerspective"] = "MicPerspective"  -- MED | INT                                   userInputMetaPersp | userInputMetaIntExt
iXML["IXML:USER:RecMedium"]      = "RecMedium"       -- Recorder                                    userInputMetaRecMed
iXML["IXML:USER:Designer"]       = "Designer"        -- The designer/recordist.                     userInputMetaDsgnr
iXML["IXML:USER:ShortID"]        = "ShortID"         -- ^ Shorten to 3 letters first, 3 last        ^^^
iXML["IXML:USER:Location"]       = "Location"        -- Location where it was recorded              userInputMetaLoc
iXML["IXML:USER:URL"]            = "URL"             -- Recordist's URL                             userInputMetaURL
iXML["IXML:USER:Library"]        = "Library"         -- Library                                     userInputMetaLib

-- Reference other wildcards
iXML["IXML:USER:RecType"]        = "RecType"         -- $bitdepth/$sampleratekk
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

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~~~~~~~~~~~  
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~ Parse UCS Input ~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
function parseUCSWebInterfaceInput()

  reaper.Undo_BeginBlock()

  -- Convert rets to booleans for cleaner function-writing down the line
  ucsRetsToBool()
  
  -- Safety-net evaluation if any of category/subcategory/catID are invalid
  -- The web interface should never even trigger this ReaScript anyways if CatID is invalid
  if not ret_cat and ret_scat and ret_id then do return end end
  
  -- Show message box with form inputs and respective ret bools. Toggle at top of script.
  if debug_mode then debugUCSInput() end
  
  -- If iXML metadata enabled, then ensure project settings are set up correctly
  if ret_ixml and ucs_ixml == "true" then iXMLSetup() end
  
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
    -- Set up iXML markers
    if ret_ixml and ucs_ixml == "true" and #iXMLMarkerTbl > 0 then iXMLMarkersEngage() end
    
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
            if ucs_full_name:find("$Regionnumber") then ucs_full_name = ucs_full_name:gsub("$Regionnumber",rgn_num); relname = relname:gisub("$Regionnumber",rgn_num) end
            if ucs_full_name:find("$Region") then ucs_full_name = ucs_full_name:gsub("$Region",name); relname = relname:gisub("$Region",name) end
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
        if ucs_full_name:find("$Regionnumber") then ucs_full_name = ucs_full_name:gsub("$Regionnumber",rgn_num); relname = relname:gisub("$Regionnumber",rgn_num) end
        if ucs_full_name:find("$Region") then ucs_full_name = ucs_full_name:gsub("$Region",name); relname = relname:gisub("$Region",name) end
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
        if ucs_full_name:find("$Regionnumber") then ucs_full_name = ucs_full_name:gsub("$Regionnumber",rgn_num); relname = relname:gisub("$Regionnumber",rgn_num) end
        if ucs_full_name:find("$Region") then ucs_full_name = ucs_full_name:gsub("$Region",name); relname = relname:gisub("$Region",name) end
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
            if ucs_full_name:find("$Regionnumber") then ucs_full_name = ucs_full_name:gsub("$Regionnumber",rgn_num); relname = relname:gisub("$Regionnumber",rgn_num) end
            if ucs_full_name:find("$Region") then ucs_full_name = ucs_full_name:gsub("$Region",name); relname = relname:gisub("$Region",name) end
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
            if ucs_full_name:find("$Markernumber") then ucs_full_name = ucs_full_name:gsub("$Markernumber",mkr_num); relname = relname:gisub("$Markernumber",mkr_num) end
            if ucs_full_name:find("$Marker") then ucs_full_name = ucs_full_name:gsub("$Marker",name); relname = relname:gisub("$Marker",name) end
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
        if ucs_full_name:find("$Markernumber") then ucs_full_name = ucs_full_name:gsub("$Markernumber",mkr_num); relname = relname:gisub("$Markernumber",mkr_num) end
        if ucs_full_name:find("$Marker") then ucs_full_name = ucs_full_name:gsub("$Marker",name); relname = relname:gisub("$Marker",name) end
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
            if ucs_full_name:find("$Markernumber") then ucs_full_name = ucs_full_name:gsub("$Markernumber",mkr_num); relname = relname:gisub("$Markernumber",mkr_num) end
            if ucs_full_name:find("$Marker") then ucs_full_name = ucs_full_name:gsub("$Marker",name); relname = relname:gisub("$Marker",name) end
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
          if ucs_full_name:find("$Itemnumber") then ucs_full_name = ucs_full_name:gsub("$Itemnumber", item_num); relname = relname:gisub("$Itemnumber", item_num) end
          if ucs_full_name:find("$Item") then 
            local ret_name, item_name = reaper.GetSetMediaItemTakeInfo_String( take, "P_NAME", "", false )
            if ret_name then 
              ucs_full_name = ucs_full_name:gsub("$Item",item_name)
              relname = relname:gisub("$Item",item_name)
            else 
              ucs_full_name = ucs_full_name:gsub("$Item","") 
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
        if ucs_full_name:find("$Itemnumber") then ucs_full_name = ucs_full_name:gsub("$Itemnumber", item_num); relname = relname:gisub("$Itemnumber", item_num) end
        if ucs_full_name:find("$Item") then 
          local ret_name, item_name = reaper.GetSetMediaItemTakeInfo_String( take, "P_NAME", "", false )
          if ret_name then 
            ucs_full_name = ucs_full_name:gsub("$Item",item_name)
            relname = relname:gisub("$Item",item_name)
          else 
            ucs_full_name = ucs_full_name:gsub("$Item","") 
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
        if ucs_full_name:find("$Tracknumber") then ucs_full_name = ucs_full_name:gsub("$Tracknumber", track_num) end
        if ucs_full_name:find("$Track") then 
          local ret_name, track_name = reaper.GetSetMediaTrackInfo_String( track, "P_NAME", "", false )
          if ret_name then ucs_full_name = ucs_full_name:gsub("$Track",track_name)
          else ucs_full_name = ucs_full_name:gsub("$Track","") end
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
        if ucs_full_name:find("$Tracknumber") then ucs_full_name = ucs_full_name:gsub("$Tracknumber", track_num) end
        if ucs_full_name:find("$Track") then 
          local ret_name, track_name = reaper.GetSetMediaTrackInfo_String( track, "P_NAME", "", false )
          if ret_name then ucs_full_name = ucs_full_name:gsub("$Track",track_name)
          else ucs_full_name = ucs_full_name:gsub("$Track","") end
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
     if ucs_full_name:find("$Tracknumber") then ucs_full_name = ucs_full_name:gsub("$Tracknumber", track_num) end
     if ucs_full_name:find("$Track") then 
       local ret_name, track_name = reaper.GetSetMediaTrackInfo_String( track, "P_NAME", "", false )
       if ret_name then ucs_full_name = ucs_full_name:gsub("$Track",track_name)
       else ucs_full_name = ucs_full_name:gsub("$Track","") end
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

  -- Name and Vendor
  if ret_vend then
    -- Vendor found
    if ret_caps and ucs_caps == "ALL CAPS (Default)"                   then ucs_vend = string.upper(ucs_vend)
    elseif ret_caps and ucs_caps == "Title Case"                       then ucs_vend = ucs_vend:gsub("(%a)([%w_']*)", toTitleCase)
    elseif ret_caps and ucs_caps == "Disable automatic capitalization" then ucs_vend = ucs_vend
    else ucs_vend = string.upper(ucs_vend) end
    
    if (ucs_enum == "true") then
      ucs_name_num_final = "_" .. ucs_vend .. "-" .. ucs_name:gsub("(%a)([%w_']*)", toTitleCase) .. " " .. ucs_num
    else
      ucs_name_num_final = "_" .. ucs_vend .. "-" .. ucs_name:gsub("(%a)([%w_']*)", toTitleCase)
    end
  else
    -- No Vendor
    if (ucs_enum == "true") then
      ucs_name_num_final = "_" .. ucs_name:gsub("(%a)([%w_']*)", toTitleCase) .. " " .. ucs_num
    else
      ucs_name_num_final = "_" .. ucs_name:gsub("(%a)([%w_']*)", toTitleCase)
    end
  end

  -- Source
  if ret_show then
    if ret_caps and ucs_caps == "ALL CAPS (Default)" then ucs_show_final = "_" .. string.upper(ucs_show)
    elseif ret_caps and ucs_caps == "Title Case" then ucs_show_final = "_" .. ucs_show:gsub("(%a)([%w_']*)", toTitleCase)
    elseif ret_caps and ucs_caps == "Disable automatic capitalization" then ucs_show_final = "_" .. ucs_show
    else ucs_show_final = "_" .. string.upper(ucs_show) end
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
  local hWnd = getRegionManager()
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

function getSelectedMarkers()
  local hWnd = getRegionManager()
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

function getRegionManager()
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
    else
      -- v6.33 Marker Syntax [;]
      if ret_mkr and ucs_mkr == "true" then
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

  -- v6.33 Marker Syntax [;]
  if ret_mkr and ucs_mkr == "true" then

    local mega_marker = "META"

    -- Standard UCS
    if ret_id   then mega_marker = mega_marker .. ";" .. "CatID=" .. ucs_id end
    if ret_cat  then mega_marker = mega_marker .. ";" .. "Category=" .. ucs_cat end
    if ret_scat then mega_marker = mega_marker .. ";" .. "SubCategory=" .. ucs_scat end
    if ret_usca then mega_marker = mega_marker .. ";" .. "UserCategory=" .. ucs_usca end
    if ret_vend then mega_marker = mega_marker .. ";" .. "VendorCategory=" .. ucs_vend end
    if ret_name then mega_marker = mega_marker .. ";" .. "FXName=" .. relname end
    if ret_data then mega_marker = mega_marker .. ";" .. "Notes=" .. ucs_data end
    if ret_show then mega_marker = mega_marker .. ";" .. "Show=" .. ucs_show end
    if ret_cat and ret_scat then mega_marker = mega_marker .. ";" .. "CategoryFull=" .. ucs_cat .. "-" .. ucs_scat end

    -- Extended meta
    if ret_meta then
      if retm_title  then mega_marker = mega_marker .. ";" .. "TrackTitle=" .. meta_title end
      if retm_desc   then mega_marker = mega_marker .. ";" .. "Description=" .. meta_desc end
      if retm_keys   then mega_marker = mega_marker .. ";" .. "Keywords=" .. meta_keys end
      if retm_mic    then mega_marker = mega_marker .. ";" .. "Microphone=" .. meta_mic end
      if retm_recmed then mega_marker = mega_marker .. ";" .. "RecMedium=" .. meta_recmed end
      if retm_lib    then mega_marker = mega_marker .. ";" .. "Library=" .. meta_lib end
      if retm_loc    then mega_marker = mega_marker .. ";" .. "Location=" .. meta_loc end
      if retm_url    then mega_marker = mega_marker .. ";" .. "URL=" .. meta_url end
      if retm_persp  then mega_marker = mega_marker .. ";" .. "MicPerspective=" .. meta_persp end
      if retm_config then mega_marker = mega_marker .. ";" .. "RecType=" .. meta_config end
      
      -- Designer and Short ID
      if retm_dsgnr  then 
        mega_marker = mega_marker .. ";" .. "Designer=" .. meta_dsgnr
        local meta_short = ""
        for i in string.gmatch(meta_dsgnr, "%S+") do
          meta_short = meta_short .. i:sub(1,3)
        end
        mega_marker = mega_marker .. ";" .. "ShortID=" .. meta_short
      end
    end

    iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, mega_marker, ucs_num}
    iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position + 0.001, "META", ucs_num}


  -- Pre Reaper v6.33 Pile-Of-Markers Syntax
  else
      
    -- Standard UCS
    if ret_id   then iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "CatID=" .. ucs_id, ucs_num} end
    if ret_cat  then iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "Category=" .. ucs_cat, ucs_num} end
    if ret_scat then iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "SubCategory=" .. ucs_scat, ucs_num} end
    if ret_usca then iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "UserCategory=" .. ucs_usca, ucs_num} end
    if ret_vend then iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "VendorCategory=" .. ucs_vend, ucs_num} end
    if ret_name then iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "FXName=" .. relname, ucs_num} end
    if ret_data then iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "Notes=" .. ucs_data, ucs_num} end
    if ret_show then iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "Show=" .. ucs_show, ucs_num} end
    if ret_cat and ret_scat then iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "CategoryFull=" .. ucs_cat .. "-" .. ucs_scat, ucs_num} end
    
    -- Extended meta
    if ret_meta then
      if retm_title  then iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "TrackTitle=" .. meta_title, ucs_num} end
      if retm_desc   then iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "Description=" .. meta_desc, ucs_num} end
      if retm_keys   then iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "Keywords=" .. meta_keys, ucs_num} end
      if retm_mic    then iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "Microphone=" .. meta_mic, ucs_num} end
      if retm_recmed then iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "RecMedium=" .. meta_recmed, ucs_num} end
      if retm_lib    then iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "Library=" .. meta_lib, ucs_num} end
      if retm_loc    then iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "Location=" .. meta_loc, ucs_num} end
      if retm_url    then iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "URL=" .. meta_url, ucs_num} end
      if retm_persp  then iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "MicPerspective=" .. meta_persp, ucs_num} end
      if retm_config then iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "RecType=" .. meta_config, ucs_num} end
      
      -- Designer and Short ID
      if retm_dsgnr  then 
        iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "Designer=" .. meta_dsgnr, ucs_num}
        local meta_short = ""
        for i in string.gmatch(meta_dsgnr, "%S+") do
          meta_short = meta_short .. i:sub(1,3)
        end
        iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, "ShortID=" .. meta_short, ucs_num}
      end
    end
  end

  -- Set up metadata fields if user input is a Reaper wildcard
  if ret_meta then
    for k, v in pairs(iXML) do
      if retm_title  and v == "TrackTitle"  and meta_title:sub(1,1) == "$"  then reaper.GetSetProjectInfo_String( 0, "RENDER_METADATA", k .. "|" .. meta_title, true )  end
      if retm_desc   and v == "Description" and meta_desc:sub(1,1) == "$"   then reaper.GetSetProjectInfo_String( 0, "RENDER_METADATA", k .. "|" .. meta_desc, true )   end
      if retm_keys   and v == "Keywords"    and meta_keys:sub(1,1) == "$"   then reaper.GetSetProjectInfo_String( 0, "RENDER_METADATA", k .. "|" .. meta_keys, true )   end
      if retm_mic    and v == "Microphone"  and meta_mic:sub(1,1) == "$"    then reaper.GetSetProjectInfo_String( 0, "RENDER_METADATA", k .. "|" .. meta_mic, true )    end
      if retm_lib    and v == "Library"     and meta_lib:sub(1,1) == "$"    then reaper.GetSetProjectInfo_String( 0, "RENDER_METADATA", k .. "|" .. meta_lib, true )    end      
      if retm_url    and v == "URL"         and meta_url:sub(1,1) == "$"    then reaper.GetSetProjectInfo_String( 0, "RENDER_METADATA", k .. "|" .. meta_url, true )    end
      if retm_recmed and v == "RecMedium"   and meta_recmed:sub(1,1) == "$" then reaper.GetSetProjectInfo_String( 0, "RENDER_METADATA", k .. "|" .. meta_recmed, true ) end
      if retm_dsgnr  and v == "Designer"    and meta_dsgnr:sub(1,1) == "$"  then reaper.GetSetProjectInfo_String( 0, "RENDER_METADATA", k .. "|" .. meta_dsgnr, true )  end
    end
  end

  -- Prep clipboard contents for Julibrary mode
  if julibrary_mode then
    local rec_type = "24/" .. tostring(reaper.GetSetProjectInfo( 0, "RENDER_SRATE", 0, false)/1000):gsub("%..+","k")
    julibrary_metadata = julibrary_metadata .. 
      ucs_full_name .. ".wav" .. tab .. 
      meta_desc .. tab .. 
      relname .. tab .. 
      meta_title .. tab ..
      meta_persp .. tab ..
      meta_mic .. tab .. 
      rec_type .. tab .. 
      ucs_id .. tab ..
      meta_loc .. tab .. 
      ucs_data .. "\n"
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
      if ret_mkr and ucs_mkr == "true" then
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
    if ret_mkr and ucs_mkr == "true" then
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
    if ret_mkr and ucs_mkr == "true" then
      if ucs_type == "Regions" then
        reaper.GetSetProjectInfo_String(0, "RENDER_PATTERN", "$marker(Category)[;]/$marker(Subcategory)[;]/$region", true)
      elseif ucs_type == "Markers" then
        reaper.GetSetProjectInfo_String(0, "RENDER_PATTERN", "$marker(Category)[;]/$marker(Subcategory)[;]/$marker", true)
      elseif ucs_type == "Media Items" then
        reaper.GetSetProjectInfo_String(0, "RENDER_PATTERN", "$marker(Category)[;]/$marker(Subcategory)[;]/$item", true)
      elseif ucs_type == "Tracks" then
        reaper.GetSetProjectInfo_String(0, "RENDER_PATTERN", "$marker(Category)[;]/$marker(Subcategory)[;]/$track", true)
      end
    else
      if ucs_type == "Regions" then
        reaper.GetSetProjectInfo_String(0, "RENDER_PATTERN", "$marker(Category)/$marker(Subcategory)/$region", true)
      elseif ucs_type == "Markers" then
        reaper.GetSetProjectInfo_String(0, "RENDER_PATTERN", "$marker(Category)/$marker(Subcategory)/$marker", true)
      elseif ucs_type == "Media Items" then
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
    elseif ucs_type == "Media Items" then
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
  if ret_copy == 1 then ret_copy = true else ret_copy = false end
  
  -- Vendor category
  if ret_vend == 1 and ucs_vend ~= "false" then ret_vend = true else ret_vend = false end
  
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
  if retm_persp  == 1 then retm_persp  = true else retm_persp  = false end
  if retm_config == 1 then retm_config = true else retm_config = false end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~ Debug UCS Input ~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
function debugUCSInput()
  reaper.MB("Category: "    .. ucs_cat  .. " (" .. tostring(ret_cat)  .. ")" .. "\n" .. 
            "Subcategory: " .. ucs_scat .. " (" .. tostring(ret_scat) .. ")" .. "\n" .. 
            "User Cat.: "   .. ucs_usca .. " (" .. tostring(ret_usca) .. ")" .. "\n" .. 
            "Vendor Cat.: " .. ucs_vend .. " (" .. tostring(ret_vend) .. ")" .. "\n" ..
            "CatID: "       .. ucs_id   .. " (" .. tostring(ret_id)   .. ")" .. "\n" .. 
            "Name: "        .. ucs_name .. " (" .. tostring(ret_name) .. ")" .. "\n" .. 
            "Number: "      .. ucs_num  .. " (" .. tostring(ret_num)  .. ")" .. "\n" .. 
            "Enum: "        .. ucs_enum .. " (" .. tostring(ret_enum) .. ")" .. "\n" ..
            "iXML: "        .. ucs_ixml .. " (" .. tostring(ret_ixml) .. ")" .. "\n" ..
            "Directory: "   .. ucs_dir  .. " (" .. tostring(ret_dir)  .. ")" .. "\n" ..
            "Mrkr Format: " .. ucs_mkr  .. " (" .. tostring(ret_mkr)  .. ")" .. "\n" ..
            "Mrkr Pos:"     .. ucs_mpos .. " (" .. tostring(ret_mpos) .. ")" .. "\n" ..
            "Initials: "    .. ucs_init .. " (" .. tostring(ret_init) .. ")" .. "\n" .. 
            "Show: "        .. ucs_show .. " (" .. tostring(ret_show) .. ")" .. "\n" .. 
            "Type: "        .. ucs_type .. " (" .. tostring(ret_type) .. ")" .. "\n" .. 
            "Data: "        .. ucs_data .. " (" .. tostring(ret_data) .. ")" .. "\n" ..
            "Caps: "        .. ucs_caps .. " (" .. tostring(ret_caps) .. ")" .. "\n" .. 
            "Copy: "        .. ucs_copy .. " (" .. tostring(ret_copy) .. ")" .. "\n" ..
            "Area: "        .. ucs_area .. " (" .. tostring(ret_area) .. ")" .. "\n" ..
            
            "\n~~~EXTENDED METADATA~~~\n" ..
            "Meta: "        .. ucs_meta .. " (" .. tostring(ret_meta) .. ")" .. "\n" ..
            "Title: "       .. meta_title .. " (" .. tostring(retm_title) .. ")" .. "\n" ..
            "Desc: "        .. meta_desc .. " (" .. tostring(retm_desc) .. ")" .. "\n" ..
            "Keys: "        .. meta_keys .. " (" .. tostring(retm_keys) .. ")" .. "\n" ..
            "Mic: "         .. meta_mic .. " (" .. tostring(retm_mic) .. ")" .. "\n" ..
            "RecMed: "      .. meta_recmed .. " (" .. tostring(retm_recmed) .. ")" .. "\n" ..
            "Designer: "    .. meta_dsgnr .. " (" .. tostring(retm_dsgnr) .. ")" .. "\n" ..
            "Library: "     .. meta_lib .. " (" .. tostring(retm_lib) .. ")" .. "\n" ..
            "Location: "    .. meta_loc .. " (" .. tostring(retm_loc) .. ")" .. "\n" ..
            "URL: "         .. meta_url .. " (" .. tostring(retm_url) .. ")" .. "\n" ..
            "Perspective: " .. meta_persp .. " (" .. tostring(retm_persp) .. ")" .. "\n" ..
            "Mic Config: "  .. meta_config .. " (" .. tostring(retm_config) .. ")"
            , "UCS Renaming Tool", 0)
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


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~~~~~~~~~~  
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
reaper.PreventUIRefresh(1)

-- Check for JS_ReaScript Extension
if reaper.JS_Dialog_BrowseForSaveFile then
  
  if reaper.HasExtState( "UCS_WebInterface", "runFromWeb" ) then

    if reaper.GetExtState( "UCS_WebInterface", "runFromWeb" ) == "true" then
      -- RUN FROM WEB INTERFACE, EXECUTE SCRIPT
      reaper.SetExtState( "UCS_WebInterface", "runFromWeb", "false", true )
      parseUCSWebInterfaceInput()

    else
      -- RUN FROM REAPER, OPEN INTERFACE
      if not debug_mode then openUCSWebInterface() end
    end

  else
    -- NO EXTSTATE FOUND, OPEN INTERFACE
    if not debug_mode then openUCSWebInterface() end
  end

else
  reaper.MB("Please install the JS_ReaScriptAPI REAPER extension, available in ReaPack, under the ReaTeam Extensions repository.\n\nExtensions > ReaPack > Browse Packages\n\nFilter for 'JS_ReascriptAPI'. Right click to install.","UCS Renaming Tool", 0)
end

reaper.PreventUIRefresh(-1)

reaper.UpdateArrange()