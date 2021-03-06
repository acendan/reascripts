-- @description RPP Cleanup
-- @author Aaron Cendan
-- @version 1.4
-- @metapackage
-- @provides
--   [main] . > acendan_Clean up projects unused MediaFiles and move to separate folder.lua
-- @link https://aaroncendan.me
-- @changelog
--   Fixed a bug for Tzvi. Not sure how it happened but whatever, consider it squished.

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- ~~~ USER CONFIG - EDIT THESE! ~~~~

-- The location in your reaper project where Media Files are stored
media_files_folder = "MediaFiles"

-- The location you would like to move unused media files to
unused_media_folder = "UnusedMediaFiles"

-- Toggle true/false to use the active Reaper project's directory and skip folder picker dialog
use_this_rpp = false



-- ~~~~~ DO NOT EDIT THESE ~~~~~~~~~~

-- Get this script's name and directory
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local script_directory = ({reaper.get_action_context()})[2]:sub(1,({reaper.get_action_context()})[2]:find("\\[^\\]*$"))

-- Init table of RPP source media
local RPP_source_media = {}

-- OS BASED SEPARATOR
if reaper.GetOS() == "Win32" or reaper.GetOS() == "Win64" then separator = "\\" else separator = "/" end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function main()
  -- Warn if first time running
  local ret_once = reaper.GetExtState("acendan","cleanup")
  if ret_once ~= "true" then
    msg("This script is similar to: File > Clean project directory...\n\nRather than delete, it moves unused files from ALL .RPPs in the original folder to a new directory:\n\nOriginal Folder\\" .. unused_media_folder)
    reaper.SetExtState("acendan","cleanup","true",true)
  end

  -- Get folder
  if use_this_rpp then
    folder = reaper.GetProjectPath("")
    if folder:find(separator .. "MediaFiles") then folder = folder:gsub(separator .. "MediaFiles","") end
  else
    folder = promptForFolder()
  end
  
  if folder then
    -- Scan selected folder for 'MediaFiles'
    local dir_idx = 0
    repeat
      local sub_dir = reaper.EnumerateSubdirectories( folder, dir_idx)
      -- Do stuff to the sub_dirs
      if string.lower(sub_dir) == string.lower(media_files_folder) and sub_dir then
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
          fetchRPPSourceMedia(folder .. separator .. dir_file)
        end
         
        fil_idx = fil_idx + 1
      until not reaper.EnumerateFiles( folder, fil_idx )
      
      -- Count initial files in unused folder
      local count_start = countFilesDirectory(folder .. separator .. unused_media_folder)
      
      -- Done scanning RPPS in folder - Let's scan through the media files now
      local fil_idx = 0
      local num_unused = 0
      repeat
         local dir_file = reaper.EnumerateFiles( folder .. separator .. media_files_folder, fil_idx )
         local file_used = false
         
         -- Check if file is referenced in projects' source media table
         for _, referenced_file in pairs(RPP_source_media) do
           if dir_file == referenced_file then file_used = true end 
         end
         
         -- Move file if not used
         if dir_file and not file_used then
           if not unused then os.execute('mkdir "' .. folder .. separator .. unused_media_folder .. '"') end
           os.rename(folder .. separator .. media_files_folder .. separator .. dir_file, folder .. separator .. unused_media_folder .. separator .. dir_file)
           num_unused = num_unused + 1
           unused = true
         end
         
         fil_idx = fil_idx + 1
      until not reaper.EnumerateFiles( folder .. separator .. media_files_folder, fil_idx )
      
      -- Count files in directory after
      local count_end = countFilesDirectory(folder .. separator .. unused_media_folder)
      local count_diff = count_end - count_start

      -- Open unused file directory
      if unused then 
        openDirectory(folder .. separator .. unused_media_folder) 
        local high_count = (num_unused > count_diff) and num_unused or count_diff
        msg("Finished scanning " .. media_files_folder .. "!\n\nMoved " .. high_count .. " media files to " .. unused_media_folder .. ".")
      else
        msg("Finished scanning " .. media_files_folder .. "!\n\nAll files are currently referenced by the RPPs in selected folder.")
      end

    else
      msg("Unable to find '" .. media_files_folder .. "' subfolder in selected folder. Please double check your project selection and user config settings in this script.")
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
  reaper.MB(msg, "Media File Folder Cleanup", 0)
end

-- Search RPP file for source media
function fetchRPPSourceMedia(filename)
  
  local file = io.open(filename)
  io.input(file)
  for line in io.lines() do
    -- Source media lines follow a consistent format, always the line after "<SOURCE"
    if source_media_line then
      if line:find(separator) then
        line = line:sub(line:find(separator) + 1, string.len(line) - 1)
        table.insert(RPP_source_media, line)
        source_media_line = false
      end
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

-- Check if a directory/folder exists. // returns Boolean
function directoryExists(folder)
  local fileHandle, strError = io.open(folder .. separator .. "*.*","r")
  if fileHandle ~= nil then
    io.close(fileHandle)
    return true
  else
    if string.match(strError,"No such file or directory") then
      return false
    else
      return true
    end
  end
end

-- Open a webpage or file directory
function openDirectory(path)
  reaper.CF_ShellExecute(path)
end

-- Prompt user to locate folder in system
function promptForFolder()
  local ret, folder = reaper.JS_Dialog_BrowseForFolder( "Please select the parent folder with your Reaper projects and " .. media_files_folder .. " sub-folder.", "" )
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

-- Count the number of files in a directory
function countFilesDirectory(directory)
  if directoryExists(directory) then
    local file_count = 0
    repeat file_count = file_count + 1 until not reaper.EnumerateFiles( directory, file_count )
    return file_count
  else
    return 0
  end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock()

-- Check for JS_ReaScript Extension
if reaper.JS_Dialog_BrowseForSaveFile then
  main()
else
  msg("This script requires the JS_ReaScriptAPI REAPER extension, available in ReaPack, under the ReaTeam Extensions repository.\n\nExtensions > ReaPack > Browse Packages\n\nFilter for 'JS_ReascriptAPI'. Right click to install.")
end

reaper.Undo_EndBlock(script_name,-1)

reaper.PreventUIRefresh(-1)

reaper.UpdateArrange()
