--@noindex

-- List reascripts in repo
function listReascripts()
  -- Get directories
  local script_directory = ({reaper.get_action_context()})[2]:sub(1,({reaper.get_action_context()})[2]:find("\\[^\\]*$")-1)
  local repo_directory = script_directory:sub(1,script_directory:find("\\[^\\]*$"))
  local self_name = "acendan_" .. ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$") .. ".lua"
  
  -- Prep temp file
  local filepath = repo_directory .. "acendan_reascripts.txt"
  local file = io.open(filepath,"w")
  
  -- Loop through subdirectories
  local dir_idx = 0
  repeat
    local subdir = reaper.EnumerateSubdirectories( repo_directory, dir_idx)
    -- Confirm isn't a github folder
    if not (subdir:sub(1,1) == ".") then
      
      -- Loop through files in subdirectory
      local fil_idx = 0
      repeat
        local dir_file = reaper.EnumerateFiles( repo_directory .. subdir, fil_idx )
        
        -- Scrape for lua files and don't include this script
        if dir_file:find(".lua") and dir_file ~= self_name then
          file:write(" - " .. subdir .. "\\" .. dir_file:sub(1,-5) .. "\n")
        end
        
        fil_idx = fil_idx + 1
      until not reaper.EnumerateFiles( repo_directory .. subdir, fil_idx )
    end

    dir_idx = dir_idx + 1
  until not  reaper.EnumerateSubdirectories( repo_directory, dir_idx )
  
  file:close()
  
  openTextFile(repo_directory .. "README.md")
  openTextFile(filepath)
end

-- Deliver messages and add new line in console
function dbg(dbg)
  reaper.ShowConsoleMsg(dbg .. "\n")
end

-- Open file in text editor
function openTextFile(filepath)
  local OS,cmd = reaper.GetOS();
  if OS == "OSX32" or OS == "OSX64" then
      cmd = os.execute('open notepad++ "'..filepath..'"')
  else
      cmd = os.execute('start notepad++ "" '..filepath)
  end
end


reaper.PreventUIRefresh(1)

listReascripts()

reaper.PreventUIRefresh(-1)

reaper.UpdateArrange()

