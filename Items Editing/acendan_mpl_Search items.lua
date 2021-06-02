-- @description Search Items
-- @author Aaron Cendan
-- @version 1.0
-- @metapackage
-- @provides
--   [main] . > acendan_mpl_Search items.lua
-- @link https://aaroncendan.me
-- @about
--   Modification of MPL's Search Tracks script

  ---------------------------------------------------------------------------------------
  
  function msg(s) reaper.ShowConsoleMsg(s..'\n') end

  ---------------------------------------------------------------------------------------
    
  function TextBox(char)
    if not textbox_t.active_char then textbox_t.active_char = 0 end
    if not textbox_t.text        then textbox_t.text = '' end
     
    if char ==  1919379572 or char == 1818584692 then return end -- Ctrl+ArrLeft/Right
    
    if  -- regular input
        (
            (char >= 65 -- a
            and char <= 90) --z
            or (char >= 97 -- a
            and char <= 122) --z
            or ( char >= 212 -- A
            and char <= 223) --Z
            or ( char >= 48 -- 0
            and char <= 57) --Z
            or char == 95 -- _
            or char == 44 -- ,
            or char == 32 -- (space)
            or char == 45 -- (-)
        )
        then        
          textbox_t.text = textbox_t.text:sub(0,textbox_t.active_char)..
            string.char(char)..
            textbox_t.text:sub(textbox_t.active_char+1)
          textbox_t.active_char = textbox_t.active_char + 1
      end
      
      if char == 8 then -- backspace
        textbox_t.text = textbox_t.text:sub(0,textbox_t.active_char-1)..
          textbox_t.text:sub(textbox_t.active_char+1)
        textbox_t.active_char = textbox_t.active_char - 1
      end

      if char == 6579564 then -- delete
        textbox_t.text = textbox_t.text:sub(0,textbox_t.active_char)..
          textbox_t.text:sub(textbox_t.active_char+2)
        textbox_t.active_char = textbox_t.active_char
      end
            
      if char == 1818584692 then -- left arrow
        textbox_t.active_char = textbox_t.active_char - 1
      end
      
      if char == 1919379572 then -- right arrow
        textbox_t.active_char = textbox_t.active_char + 1
      end
      
    --[[if char == 13  then   -- enter
        -- RUN search for textbox_t.text
    end]]
    
    if textbox_t.active_char < 0 then textbox_t.active_char = 0 end
    if textbox_t.active_char > textbox_t.text:len()  then textbox_t.active_char = textbox_t.text:len() end
  end
     
  ---------------------------------------------------------------------------------------    
  
  function SearchItems(text)
      if not text then return end
      local  matched_it_guids = {}
      local num_items = reaper.CountMediaItems( 0 )
      if num_items > 0 then
        for i=0, num_items - 1 do
          local item =  reaper.GetMediaItem( 0, i )
          local take = reaper.GetActiveTake( item )
          if take ~= nil then 
            local ret, item_name = reaper.GetSetMediaItemTakeInfo_String( take, "P_NAME", "", false )
            if item_name:lower():find(text) then
              matched_it_guids[#matched_it_guids+1] = reaper.BR_GetMediaItemGUID( item )
            end
          end
        end
      end
      return matched_it_guids
    end
  ---------------------------------------------------------------------------------------    
    
  function Run()
      char  = gfx.getchar()
      
      alpha  = math.abs((os.clock()%1) -0.5)
      --  draw back
        gfx.set(  1,1,1,  0.2,  0) --rgb a mode
        gfx.rect(0,0,obj_mainW,obj_mainH,1)
      --  draw frame
        gfx.set(  1,1,1,  0.1,  0) --rgb a mode
        gfx.rect(obj_offs,obj_offs,obj_mainW-obj_offs*2,gui_fontsize+obj_offs/2 ,1)
        
      -- draw text
        gfx.set(  1,1,1,  0.8,  0) --rgb a mode
        gfx.setfont(1, gui_fontname, gui_fontsize)
        gfx.x = obj_offs*2
        gfx.y = obj_offs
        gfx.drawstr(textbox_t.text) 
        
      -- active char
        if textbox_t.active_char ~= nil then
          gfx.set(  1,1,1, alpha,  0) --rgb a mode
          gfx.x = obj_offs*1.5+
                  gfx.measurestr(textbox_t.text:sub(0,textbox_t.active_char))  
          gfx.y = obj_offs + gui_fontsize/2 - gfx.texth/2
          gfx.drawstr('|')
        end    

      -- draw ctrl help text
        local str = 'Use Ctrl+Left/Right for results'
        gfx.set(  1,1,1,  0.3,  0) --rgb a mode
        gfx.setfont(1, gui_fontname, gui_fontsize-7)
        gfx.x = obj_mainW - obj_offs*2 - gfx.measurestr(str)
        gfx.y = obj_offs
        gfx.drawstr(str) 
                     
      TextBox(char) -- perform typing
      
      if char > 0  
        and textbox_t.text 
        and char ~=  1919379572
        and char ~= 1818584692 then 
          matched = SearchItems(textbox_t.text) 
          matched_id = 1 
      end
      
      -- get id
        if char ==  1919379572 then  
          matched_id = matched_id + 1
          if matched_id > #matched then matched_id = #matched end
         elseif char == 1818584692 then
          matched_id = matched_id - 1    
          if    matched_id < 1 then matched_id = 1 end 
        end
        
      if not matched_id then matched_id = 1 end          
      if last_char and matched_id and last_char > 0 and char == 0 and matched then  
        sel_item = reaper.BR_GetMediaItemByGUID( 0, matched[matched_id] )
        if sel_item then 
          reaper.Main_OnCommand(40289, 0) -- Unselect all media items
          reaper.SetMediaItemSelected( sel_item, true )
          reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_HZOOMITEMS"),0) -- Horizontal zoom to sel item
          
          local sel_track = reaper.GetMediaItem_Track( sel_item )
          reaper.SetMixerScroll( sel_track )
          reaper.Main_OnCommand(40297,0) -- unselect all tracks
          reaper.SetTrackSelected( sel_track, true )
          reaper.Main_OnCommand(40913,0)-- vert scroll sel track into view
        end
        --
      end
        
      gfx.update()
      last_char = char
      if char ~= -1 and char ~= 27 and char ~= 13  then reaper.defer(Run) else reaper.atexit(gfx.quit) end
      
    end 

  ---------------------------------------------------------------------------------------
  
  function Lokasenna_WindowAtCenter (w, h)
    -- thanks to Lokasenna 
    -- http://forum.cockos.com/showpost.php?p=1689028&postcount=15    
    local l, t, r, b = 0, 0, w, h    
    local __, __, screen_w, screen_h = reaper.my_getViewport(l, t, r, b, l, t, r, b, 1)    
    local x, y = (screen_w - w) / 2, (screen_h - h) / 2    
    gfx.init("Search Items", w, h, 0, x, y)
    local w = reaper.JS_Window_Find("Search Items", true)
    if w then reaper.JS_Window_AttachTopmostPin(w) end
  end

  ---------------------------------------------------------------------------------------
    
  obj_mainW = 400
  obj_mainH = 50
  obj_offs = 10
  
  gui_aa = 1
  gui_fontname = 'Calibri'
  gui_fontsize = 23      
  local gui_OS = reaper.GetOS()
  if gui_OS == "OSX32" or gui_OS == "OSX64" then gui_fontsize = gui_fontsize - 7 end
  
  mouse = {}
  textbox_t = {}  

  matched = SearchItems('')
  matched_id = 1
  
  Lokasenna_WindowAtCenter (obj_mainW,obj_mainH)
  Run()
