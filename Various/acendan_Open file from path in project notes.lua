-- @description Open File Project Notes
-- @author Aaron Cendan
-- @version 1.0
-- @metapackage
-- @provides
--   [main] .
-- @link https://ko-fi.com/acendan_

function main()
  local proj_notes = reaper.GetSetProjectNotes(0,false,"")
  if reaper.file_exists(proj_notes) then reaper.CF_ShellExecute(proj_notes) else reaper.MB("No file found in project notes!","",0) end
end
main()

