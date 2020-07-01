-- @description Clear glitchy stutter generator stored values
-- @author Aaron Cendan
-- @version 1.1
-- @metapackage
-- @provides
--   [main] . > acendan_Clear glitchy stutter generator stored values.lua
-- @link https://aaroncendan.me

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~ CLEAR STORED VALUES ~~~~~~~~~~~~~~~  
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
reaper.SetProjExtState( 0, "Glitch_Generator", "Rand_Max", "" )
reaper.SetProjExtState( 0, "Glitch_Generator", "Slice_Length", "" )
