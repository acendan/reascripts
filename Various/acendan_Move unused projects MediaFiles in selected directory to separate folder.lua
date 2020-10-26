-- @description RPP Cleanup
-- @author Aaron Cendan
-- @version 1.0
-- @metapackage
-- @provides
--   [main] . > acendan_Clean up projects unused MediaFiles and move to separate folder.lua
-- @link https://aaroncendan.me

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Get this script's name and directory
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local script_directory = ({reaper.get_action_context()})[2]:sub(1,({reaper.get_action_context()})[2]:find("\\[^\\]*$"))

-- Init table of RPP source media
local RPP_source_media = {}

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function main()
  msg("This script is intended for cleaning up directories with multiple RPPs referencing the same MediaFiles folder. It's similar to:\n\nFile > Clean project directory...\n\nRather than delete, it moves unused files (across ALL projects in the original folder) to a new directory:\n\nOriginal Folder\\UnusedMediaFiles")
  
  folder = promptForFolder()
  if folder then
    -- Scan selected folder for 'MediaFiles'
    local dir_idx = 0
    repeat
      local sub_dir = reaper.EnumerateSubdirectories( folder, dir_idx)
      -- Do stuff to the sub_dirs
      if sub_dir == "MediaFiles" then
        found_MediaFiles = true
      end
      dir_idx = dir_idx + 1
    until not  reaper.EnumerateSubdirectories( folder, dir_idx )
    
    if found_MediaFiles then
      -- Scan files in folder for RPPs
      local fil_idx = 0
      repeat
        local dir_file = reaper.EnumerateFiles( folder, fil_idx )
        -- Scan RPPs for source file content
        if fileExtension(dir_file) == "RPP" then
          fetchRPPSourceMedia(folder .. "\\" .. dir_file)
        end
         
        fil_idx = fil_idx + 1
      until not reaper.EnumerateFiles( folder, fil_idx )
      
      -- Done scanning RPPS in folder - Let's scan through the media files now
      local fil_idx = 0
      local num_unused = 0
      repeat
         local dir_file = reaper.EnumerateFiles( folder .. "\\MediaFiles", fil_idx )
         local file_used = false
         
         -- Check if file is referenced in projects' source media table
         for _, referenced_file in pairs(RPP_source_media) do
           if dir_file == referenced_file then file_used = true end 
         end
         
         -- Move file if not used
         if not file_used then
           if not unused then os.execute('mkdir "' .. folder .. '\\UnusedMediaFiles"') end
           os.rename(folder .. "\\MediaFiles\\" .. dir_file, folder .. "\\UnusedMediaFiles\\" .. dir_file)
           num_unused = num_unused + 1
           unused = true
         end
         
         fil_idx = fil_idx + 1
      until not reaper.EnumerateFiles( folder .. "\\MediaFiles", fil_idx )

      -- Open unused file directory
      if unused then 
        openDirectory(folder .. "\\UnusedMediaFiles") 
        msg("Finished scanning MediaFiles!\n\nMoved " .. num_unused .. " media files to \\UnusedMediaFiles.")
      else
        msg("Finished scanning MediaFiles!\n\nAll files are currently referenced by the RPPs in selected folder.")
      end

    else
      msg("Unable to find 'MediaFiles' subfolder in selected folder. Please double check your folder selection.\n\n~~~\nIf you have re-configured Reaper to use another folder name for MediaFiles, then sorry about that. I'll have to update this script at some point. Feel free to shoot me a message at:\n\naaron.cendan@gmail.com\n\nOops :)")
    end
  end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ UTILITIES ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Deliver messages and add new line in console
function dbg(dbg)
  reaper.ShowConsoleMsg(dbg .. "\n")
end

-- Deliver messages using message box
function msg(msg)
  reaper.MB(msg, "MediaFile Folder Cleanup", 0)
end

-- Search RPP file for source media
function fetchRPPSourceMedia(filename)
  local file = io.open(filename)
  io.input(file)
  for line in io.lines() do
    -- Source media lines follow a consistent format, always the line after "<SOURCE"
    if source_media_line then
      line = line:sub(line:find("\\") + 1, string.len(line) - 1)
      table.insert(RPP_source_media, line)
      source_media_line = false
    end
    if line:find("<SOURCE") then
      source_media_line = true
    end
  end
  io.close(file)
end

-- Get 3 character all caps extension from a file path input // returns String
function fileExtension(filename)
  return filename:sub(-3):upper()
end

-- Check if a file exists // returns Boolean
function fileExists(filename)
   return reaper.file_exists(filename)
end

-- Open a webpage or file directory
function openDirectory(path)
  reaper.CF_ShellExecute(path)
end

-- Prompt user to locate folder in system
function promptForFolder()
  local ret, folder = reaper.JS_Dialog_BrowseForFolder( "Please select the parent folder with your Reaper projects and MediaFiles sub-folder.", "" )
  if ret == 1 then
    -- Folder found
    return folder
  elseif ret == 0 then
    -- Folder selection cancelled
    return nil
  else 
    -- Folder picking error
    msg("Something went wrong... Please try again!")
    promptForFolder()
  end
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
