-- @description Remove User Metadata Columns
-- @author Aaron Cendan
-- @version 1.0
-- @metapackage
-- @provides
--   [main=mediaexplorer] .
-- @link https://aaroncendan.me

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Other globals
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local script_directory = ({reaper.get_action_context()})[2]:sub(1,({reaper.get_action_context()})[2]:find("\\[^\\]*$"))
local ini_section = "reaper_explorer"
local dbg = false
local user_keys = 0
local user_vals = 0

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function main()
  local reaper_version = tonumber(reaper.GetAppVersion():sub(1,4))
  if reaper_version >= 6.29 then
    removeUserColumns()
  else
    reaper.MB("This script requires Reaper v6.29 or greater! Please update Reaper.","ERROR: Update Reaper!",0)
  end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ UTILITIES ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Adds the IXML columns to the Media Explorer
function removeUserColumns()
  local ini_file = reaper.get_ini_file()
  
  -- Write ini file without user content to table
  local ini_table = fileToTable(ini_file)

  if user_keys > 0 then
    -- Write table back to file
    tableToFile(ini_table,ini_file,"")
    
    -- Force refresh the media explorer
    reaper.Main_OnCommand(50124,0) -- Show/hide media explorer
    reaper.Main_OnCommand(50124,0) -- Show/hide media explorer
    reaper.OpenMediaExplorer("",false)
    
    reaper.MB("Succesfully deleted " .. tostring(user_keys) .. " custom user metadata columns!","Media Explorer Metadata",0)
  else
    reaper.MB("No custom user metadata columns found!","Media Explorer Metadata",0)
  end
end

-- Convert file input to table
function fileToTable(filename)
  local file = io.open(filename)
  io.input(file)
  local t = {}
  for line in io.lines() do
    if not line:find("user%d*_key=") and not line:find("user%d*_desc=") then
      table.insert(t, line)
    else
      if line:find("user%d*_key=") then user_keys = user_keys + 1
      elseif line:find("user%d*_desc=") then user_vals = user_vals + 1 end
    end
  end
  table.insert(t, "")
  io.close(file)
  return t
end

-- Convert table to file
function tableToFile(  tbl,filename,sep )
  local charS,charE = "","\n"
  local file,err = io.open( filename, "wb" )
  if err then return err end
  
  local sep = sep or ""

  -- This method only works when table keys are index numbers, not strings or other stuffs
  local i = 1
  for k, v in pairs(tbl) do
    if i < #tbl then file:write(v .. "\n") else file:write(v) end
    i = i + 1
  end

  file:close()
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

