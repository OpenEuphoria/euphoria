-- (c) Copyright - See License.txt
--
--****
-- == Windows Sound
--
-- <<LEVELTOC level=2 depth=4>>
--
 

namespace sound

include std/dll.e

public constant   
	SND_DEFAULT     = 0x00,
	SND_STOP        = 0x10,
	SND_QUESTION    = 0x20,
	SND_EXCLAMATION = 0x30,
	SND_ASTERISK    = 0x40,
	$


integer xMessageBeep
atom xUser32
--**
-- Makes a sound.
--
-- Parameters:
-- # sound_type: An atom. The type of sound to make. The default is SND_DEFAULT.
--
-- Comments:
-- The ##sound_type## value can be one of ...
-- * ##SND_ASTERISK## 
-- * ##SND_EXCLAMATION##
-- * ##SND_STOP##
-- * ##SND_QUESTION##
-- * ##SND_DEFAULT##
--
-- These are sounds associated with the same Windows events
-- via the Control Panel.
--
--Example:
-- <eucode>
--  sound( SND_EXCLAMATION )
-- </eucode>

public procedure sound( atom sound_type = SND_DEFAULT )
	if not object(xMessageBeep) then
		xUser32 = open_dll("user32.dll")
		xMessageBeep   = define_c_proc(xUser32, "MessageBeep", {C_UINT})
	end if
    c_proc( xMessageBeep, { sound_type } )
end procedure
