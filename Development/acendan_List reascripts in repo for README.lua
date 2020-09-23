--@noindex

-- Get directories
local script_directory = ({reaper.get_action_context()})[2]:sub(1,({reaper.get_action_context()})[2]:find("\\[^\\]*$")-1)
local repo_directory = script_directory:sub(1,script_directory:find("\\[^\\]*$"))
local self_name = "acendan_" .. ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$") .. ".lua"
local script_table = {}

-- List reascripts in repo
function listReascripts()
  
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
          local file_line = " - " .. subdir .. "\\" .. dir_file:sub(1,-5)
          script_table[#script_table+1] = file_line
          file:write( file_line  .. "\n")
        end
        
        fil_idx = fil_idx + 1
      until not reaper.EnumerateFiles( repo_directory .. subdir, fil_idx )
    end

    dir_idx = dir_idx + 1
  until not  reaper.EnumerateSubdirectories( repo_directory, dir_idx )
  
  file:close()
end

function editReadme()
  local readme = io.open(repo_directory .. "README.md","r")
  io.input(readme)
  local readme_info = {}
  local save_line = true
  local insert_here = 0
  
  for line in io.lines() do
    if save_line then
      table.insert(readme_info, line)
    end
    
    if line:find("Scripts included in my GitHub") then 
      insert_here = #readme_info
      for _, script in pairs(script_table) do
        table.insert(readme_info, script)
      end
      save_line = false 
    end
    
    if line:find("Manual Download Instructions") then 
      table.insert(readme_info, "\n" .. line)
      save_line = true 
    end
  end
  io.close()
  
  local readme = io.open(repo_directory .. "README.md","w")
  for _, line in pairs(readme_info) do
    readme:write(line, "\n")
  end
  readme:lines()
  readme:close()
  
  reaper.MB("Updated GitHub 'README.md'\n\nYou've uploaded " .. tostring(#script_table) .. " scripts!","Success",0)
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

editReadme()

--openTextFile(repo_directory .. "README.md")
--openTextFile(filepath)

reaper.PreventUIRefresh(-1)

reaper.UpdateArrange()

