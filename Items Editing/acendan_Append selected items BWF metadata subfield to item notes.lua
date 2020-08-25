-- @description Sound Devices MixPre Metadata Tools - Item Notes
-- @author Aaron Cendan
-- @version 1.0
-- @metapackage
-- @provides
--   [main] . > acendan_MixPre items BWF description subfield to item notes-sTAKE.lua
--   [main] . > acendan_MixPre items BWF description subfield to item notes-sSCENE.lua
--   [main] . > acendan_MixPre items BWF description subfield to item notes-sFILENAME.lua
--   [main] . > acendan_MixPre items BWF description subfield to item notes-sTAPE.lua
--   [main] . > acendan_MixPre items BWF description subfield to item notes-sNOTE.lua
-- @link https://aaroncendan.me
-- @about
--   Appends BWF sub-field after hyphen (-) in script name to original item notes.

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

bwf_field = ""

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function appendMetadata()
  local num_sel_items = reaper.CountSelectedMediaItems(0)
  if num_sel_items > 0 then
    for i=0, num_sel_items - 1 do
      local item = reaper.GetSelectedMediaItem( 0, i )
      local take = reaper.GetActiveTake( item )
      if take ~= nil then 
        local src = reaper.GetMediaItemTake_Source(take)
        local src_parent = reaper.GetMediaSourceParent(src)
        
        if src_parent ~= nil then
          ret, full_desc = reaper.CF_GetMediaSourceMetadata( src_parent, "DESC", "" )
        else
          ret, full_desc = reaper.CF_GetMediaSourceMetadata( src, "DESC", "" )
        end
        
        if ret then
          local start_of_field = string.find( full_desc, bwf_field .. "=" ) + string.len( bwf_field .. "=" )
          local field_to_end = string.sub( full_desc, start_of_field, string.len( full_desc ))
          local end_of_field = start_of_field + string.find( field_to_end , "\r\n")
          local bwf_field_contents = string.sub( full_desc, start_of_field, end_of_field)
          
          if reaper.ULT_GetMediaItemNote( item ) == "" then
            reaper.ULT_SetMediaItemNote( item, bwf_field_contents)
          else
            reaper.ULT_SetMediaItemNote( item, reaper.ULT_GetMediaItemNote( item ) .. " - " .. bwf_field_contents)
          end
        end
      end
    end
  else
    reaper.MB("No items selected!","Append Metadata", 0)
  end
end


function extractFieldScriptName()
  local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
  if string.find(script_name, "-") then
    bwf_field = string.sub( script_name, string.find(script_name, "-") + 1, string.len(script_name))
  else
    reaper.MB("Unable to find BWF description subfield in script name.", "Append BWF to Item Notes", 0)
  end
end
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock()

extractFieldScriptName()

appendMetadata()

reaper.Undo_EndBlock("Append Metadata to Item Names",-1)

reaper.PreventUIRefresh(-1)

reaper.UpdateArrange()
