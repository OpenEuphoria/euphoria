--****
-- == Console
--
-- <<LEVELTOC level=2 depth=4>>

namespace console

include std/get.e
include std/pretty.e
include std/text.e
include std/types.e
include std/map.e

public include std/graphcst.e

-- machine() commands
constant
	M_WAIT_KEY    = 26,
	M_ALLOW_BREAK = 42,
	M_CHECK_BREAK = 43,
	M_CURSOR      = 6,
	M_TEXTROWS    = 12,
	M_FREE_CONSOLE = 54,
	M_GET_SCREEN_CHAR = 58,
	M_PUT_SCREEN_CHAR = 59,
	M_HAS_CONSOLE = 99,
	M_KEY_CODES   = 100,
	$


--****
-- === Information

--**
-- determines if the process has a console (terminal) window.
--
-- Returns:
-- An **atom**,
--  * ##1## if there is more than one process attached to the current console, 
--  * ##0## if a console does not exist or only one process (Euphoria) is attached to
--     the current console.
--
-- Comments:
--  * On //Unix// systems always returns ##1## .
--  * On //Windows// client systems earlier than Windows XP the function always returns ##0## .
--  * On //Windows// server systems earlier than Windows Server 2003 the function always returns ##0## .
--
-- Example 1:
-- <eucode>
-- include std/console.e
--
-- if has_console() then
--     printf(1, "Hello Console!")
-- end if
-- </eucode>
--

public function has_console()
	return machine_func(M_HAS_CONSOLE, 0)
end function


--**
-- gets and sets the keyboard codes used internally by Euphoria.
--
-- Parameters:
--  # ##codes## : Either a sequence of exactly 256 integers or an atom (the default).
--
-- Returns:
--   A **sequence**, 
-- of the current 256 keyboard codes, prior to any changes that
-- this function might make.
--
-- Comments:
--   When ##codes## is a atom then no change to the existing codes is made, otherwise
--   the set of 256 integers in ##codes## completely replaces the existing codes.
--
-- Example 1:
-- <eucode>
-- include std/console.e
-- sequence kc
-- kc = key_codes() -- Get existing set.
-- kc[KC_LEFT] = 263 -- Change the code for the left-arrow press.
-- key_codes(kc) -- Set the new codes.
-- </eucode>
--

public function key_codes(object codes = 0)
	return machine_func(M_KEY_CODES, codes)
end function


--****
-- === Key Code Names
--  These are the names of the index values for each of the 256 key code values.
-- 
--
-- See Also:
--   [[:key_codes]]
public constant
	KC_LBUTTON  = #01 + 1, --  Left mouse button
	KC_RBUTTON  = #02 + 1, --  Right mouse button
	KC_CANCEL  = #03 + 1, --  Control-break processing
	KC_MBUTTON  = #04 + 1, --  Middle mouse button (three-button mouse)
	KC_XBUTTON1  = #05 + 1, --  Windows 2000/XP: X1 mouse button
	KC_XBUTTON2  = #06 + 1, --  Windows 2000/XP: X2 mouse button
	KC_BACK  = #08 + 1, --  BACKSPACE key
	KC_TAB  = #09 + 1, --  TAB key
	KC_CLEAR  = #0C + 1, --  CLEAR key NUMPAD-5
	KC_RETURN  = #0D + 1, --  ENTER key NUMPAD-ENTER
	KC_SHIFT  = #10 + 1, --  SHIFT key
	KC_CONTROL  = #11 + 1, --  Control key
	KC_MENU  = #12 + 1, --  ALT key
	KC_PAUSE  = #13 + 1, --  PAUSE key
	KC_CAPITAL  = #14 + 1, --  CAPS LOCK key
	KC_KANA  = #15 + 1, --  Input Method Editor (IME)  Kana mode
	KC_JUNJA  = #17 + 1, --  IME Junja mode
	KC_FINAL  = #18 + 1, --  IME final mode
	KC_HANJA  = #19 + 1, --  IME Hanja mode
	KC_ESCAPE  = #1B + 1, --  ESC key
	KC_CONVERT  = #1C + 1, --  IME convert
	KC_NONCONVERT  = #1D + 1, --  IME nonconvert
	KC_ACCEPT  = #1E + 1, --  IME accept
	KC_MODECHANGE  = #1F + 1, --  IME mode change request
	KC_SPACE  = #20 + 1, --  SPACEBAR
	KC_PRIOR  = #21 + 1, --  PAGE UP key
	KC_NEXT  = #22 + 1, --  PAGE DOWN key
	KC_END  = #23 + 1, --  END key
	KC_HOME  = #24 + 1, --  HOME key
	KC_LEFT  = #25 + 1, --  LEFT ARROW key
	KC_UP  = #26 + 1, --  UP ARROW key
	KC_RIGHT  = #27 + 1, --  RIGHT ARROW key
	KC_DOWN  = #28 + 1, --  DOWN ARROW key
	KC_SELECT  = #29 + 1, --  SELECT key
	KC_PRINT  = #2A + 1, --  PRINT key
	KC_EXECUTE  = #2B + 1, --  EXECUTE key
	KC_SNAPSHOT  = #2C + 1, --  PRINT SCREEN key
	KC_INSERT  = #2D + 1, --  INS key
	KC_DELETE  = #2E + 1, --  DEL key
	KC_HELP  = #2F + 1, --  HELP key
	KC_LWIN  = #5B + 1, --  Left Windows key (Microsoft Natural keyboard)
	KC_RWIN  = #5C + 1, --  Right Windows key (Natural keyboard)
	KC_APPS  = #5D + 1, --  Applications key (Natural keyboard)
	KC_SLEEP  = #5F + 1, --  Computer Sleep key
	KC_NUMPAD0  = #60 + 1, --  Numeric keypad 0 key
	KC_NUMPAD1  = #61 + 1, --  Numeric keypad 1 key
	KC_NUMPAD2  = #62 + 1, --  Numeric keypad 2 key
	KC_NUMPAD3  = #63 + 1, --  Numeric keypad 3 key
	KC_NUMPAD4  = #64 + 1, --  Numeric keypad 4 key
	KC_NUMPAD5  = #65 + 1, --  Numeric keypad 5 key
	KC_NUMPAD6  = #66 + 1, --  Numeric keypad 6 key
	KC_NUMPAD7  = #67 + 1, --  Numeric keypad 7 key
	KC_NUMPAD8  = #68 + 1, --  Numeric keypad 8 key
	KC_NUMPAD9  = #69 + 1, --  Numeric keypad 9 key
	KC_MULTIPLY  = #6A + 1, --  Multiply key NUMPAD
	KC_ADD  = #6B + 1, --  Add key NUMPAD
	KC_SEPARATOR  = #6C + 1, --  Separator key
	KC_SUBTRACT  = #6D + 1, --  Subtract key NUMPAD
	KC_DECIMAL  = #6E + 1, --  Decimal key NUMPAD
	KC_DIVIDE  = #6F + 1, --  Divide key NUMPAD
	KC_F1  = #70 + 1, --  F1 key
	KC_F2  = #71 + 1, --  F2 key
	KC_F3  = #72 + 1, --  F3 key
	KC_F4  = #73 + 1, --  F4 key
	KC_F5  = #74 + 1, --  F5 key
	KC_F6  = #75 + 1, --  F6 key
	KC_F7  = #76 + 1, --  F7 key
	KC_F8  = #77 + 1, --  F8 key
	KC_F9  = #78 + 1, --  F9 key
	KC_F10  = #79 + 1, --  F10 key
	KC_F11  = #7A + 1, --  F11 key
	KC_F12  = #7B + 1, --  F12 key
	KC_F13  = #7C + 1, --  F13 key
	KC_F14  = #7D + 1, --  F14 key
	KC_F15  = #7E + 1, --  F15 key
	KC_F16  = #7F + 1, --  F16 key
	KC_F17  = #80 + 1, --  F17 key
	KC_F18  = #81 + 1, --  F18 key
	KC_F19  = #82 + 1, --  F19 key
	KC_F20  = #83 + 1, --  F20 key
	KC_F21  = #84 + 1, --  F21 key
	KC_F22  = #85 + 1, --  F22 key
	KC_F23  = #86 + 1, --  F23 key
	KC_F24  = #87 + 1, --  F24 key
	KC_NUMLOCK  = #90 + 1, --  NUM LOCK key
	KC_SCROLL  = #91 + 1, --  SCROLL LOCK key
	KC_LSHIFT  = #A0 + 1, --  Left SHIFT key
	KC_RSHIFT  = #A1 + 1, --  Right SHIFT key
	KC_LCONTROL  = #A2 + 1, --  Left CONTROL key
	KC_RCONTROL  = #A3 + 1, --  Right CONTROL key
	KC_LMENU  = #A4 + 1, --  Left MENU key
	KC_RMENU  = #A5 + 1, --  Right MENU key
	KC_BROWSER_BACK  = #A6 + 1, --  Windows 2000/XP: Browser Back key
	KC_BROWSER_FORWARD  = #A7 + 1, --  Windows 2000/XP: Browser Forward key
	KC_BROWSER_REFRESH  = #A8 + 1, --  Windows 2000/XP: Browser Refresh key
	KC_BROWSER_STOP  = #A9 + 1, --  Windows 2000/XP: Browser Stop key
	KC_BROWSER_SEARCH  = #AA + 1, --  Windows 2000/XP: Browser Search key 
	KC_BROWSER_FAVORITES  = #AB + 1, --  Windows 2000/XP: Browser Favorites key
	KC_BROWSER_HOME  = #AC + 1, --  Windows 2000/XP: Browser Start and Home key
	KC_VOLUME_MUTE  = #AD + 1, --  Windows 2000/XP: Volume Mute key
	KC_VOLUME_DOWN  = #AE + 1, --  Windows 2000/XP: Volume Down key
	KC_VOLUME_UP  = #AF + 1, --  Windows 2000/XP: Volume Up key
	KC_MEDIA_NEXT_TRACK  = #B0 + 1, --  Windows 2000/XP: Next Track key
	KC_MEDIA_PREV_TRACK  = #B1 + 1, --  Windows 2000/XP: Previous Track key
	KC_MEDIA_STOP  = #B2 + 1, --  Windows 2000/XP: Stop Media key
	KC_MEDIA_PLAY_PAUSE  = #B3 + 1, --  Windows 2000/XP: Play/Pause Media key
	KC_LAUNCH_MAIL  = #B4 + 1, --  Windows 2000/XP: Start Mail key
	KC_LAUNCH_MEDIA_SELECT  = #B5 + 1, --  Windows 2000/XP: Select Media key
	KC_LAUNCH_APP1  = #B6 + 1, --  Windows 2000/XP: Start Application 1 key
	KC_LAUNCH_APP2  = #B7 + 1, --  Windows 2000/XP: Start Application 2 key
	KC_OEM_1  = #BA + 1, --  Used for miscellaneous characters; it can vary by keyboard. Windows 2000/XP: For the US standard keyboard, the ';:' key 
	KC_OEM_PLUS  = #BB + 1, --  Windows 2000/XP: For any country/region, the '+' key
	KC_OEM_COMMA  = #BC + 1, --  Windows 2000/XP: For any country/region, the ',' key
	KC_OEM_MINUS  = #BD + 1, --  Windows 2000/XP: For any country/region, the '-' key
	KC_OEM_PERIOD  = #BE + 1, --  Windows 2000/XP: For any country/region, the '.' key
	KC_OEM_2  = #BF + 1, --  Used for miscellaneous characters; it can vary by keyboard. Windows 2000/XP: For the US standard keyboard, the '/-1' key 
	KC_OEM_3  = #C0 + 1, --  Used for miscellaneous characters; it can vary by keyboard. Windows 2000/XP: For the US standard keyboard, the '`~' key 
	KC_OEM_4  = #DB + 1, --  Used for miscellaneous characters; it can vary by keyboard. Windows 2000/XP: For the US standard keyboard, the '[{' key
	KC_OEM_5  = #DC + 1, --  Used for miscellaneous characters; it can vary by keyboard. Windows 2000/XP: For the US standard keyboard, the '\|' key
	KC_OEM_6  = #DD + 1, --  Used for miscellaneous characters; it can vary by keyboard. Windows 2000/XP: For the US standard keyboard, the ']}' key
	KC_OEM_7  = #DE + 1, --  Used for miscellaneous characters; it can vary by keyboard. Windows 2000/XP: For the US standard keyboard, the 'single-quote/double-quote' key
	KC_OEM_8  = #DF + 1, --  Used for miscellaneous characters; it can vary by keyboard.
	KC_OEM_102  = #E2 + 1, --  Windows 2000/XP: Either the angle bracket key or the backslash key on the RT 102-key keyboard
	KC_PROCESSKEY  = #E5 + 1, --  Windows 95/98/Me, Windows NT 4.0, Windows 2000/XP: IME PROCESS key
	KC_PACKET  = #E7 + 1, --  Windows 2000/XP: Used to pass Unicode characters as if they were keystrokes. The KC_PACKET key is the low word of a 32-bit Virtual Key value used for non-keyboard input methods. For more information, see Remark in KEYBDINPUT, SendInput, WM_KEYDOWN, and WM_KEYUP
	KC_ATTN  = #F6 + 1, --  Attn key
	KC_CRSEL  = #F7 + 1, --  CrSel key
	KC_EXSEL  = #F8 + 1, --  ExSel key
	KC_EREOF  = #F9 + 1, --  Erase EOF key
	KC_PLAY  = #FA + 1, --  Play key
	KC_ZOOM  = #FB + 1, --  Zoom key
	KC_NONAME  = #FC + 1, --  Reserved 
	KC_PA1  = #FD + 1, --  PA1 key
	KC_OEM_CLEAR  = #FE + 1, --  Clear key
	KM_CONTROL = #1000, -- Ctrl modifier
	KM_SHIFT   = #2000, -- Shift modifier
	KM_ALT     = #4000, -- Alt modifier
	$

--**
-- changes the default codes returned by the keyboard.
--
-- Parameters:
--   # ##kcfile## : Either the name of a text file or the handle of an opened (for reading) text file.
--
-- Returns:
-- An **integer**,
-- * ##0## means no error.
-- * ##-1## means that the supplied file could not me loaded in to a [[:map]].
-- * ##-2## means that a new key value was not an integer.
-- * ##-3## means that an unknown key name was found in the file.
--
-- Comments:
--   The text file is expected to contain bindings for one or more keyboard codes.
--
-- The format of the files is a set of lines, one line per key binding, in the
-- form ##KEYNAME = NEWVALUE##. The ##KEYNAME## is the same as the constants but without
-- the "##KC_##" prefix. The key bindings can be in any order.
-- 
-- Example 1:
-- {{{
--  -- doskeys.txt file containing some key bindings
--    F1 = 260
--    F2 = 261
--    INSERT = 456
-- }}}
-- <eucode>
--   set_keycodes( "doskeys.txt" )
-- </eucode>
--
-- See Also:
-- 		[[:key_codes]]

public function set_keycodes( object kcfile )

	object m
	sequence kcv
	sequence kc
	sequence keyname
	integer  keycode
	
	-- Convert the text file containing new key codes into a map.
	m = map:load_map(kcfile)
	if not map(m) then
		return -1 -- The file could not be loaded into a map.
	end if
	
	-- Get key-value pairs found in the kcfile
	kcv = map:pairs(m)
	
	-- Get the current keycode values.
	kc = key_codes(0)
	
	-- Replace the ones required to be changed.
	for i = 1 to length(kcv) do
		if integer(kcv[i][2]) then
			keyname = upper(kcv[i][1])
			keycode = kcv[i][2]
		
			switch keyname do
			
				case "LBUTTON" then
					kc[KC_LBUTTON] = keycode
					
				case "RBUTTON" then
					kc[KC_RBUTTON] = keycode
					
				case "CANCEL" then
					kc[KC_CANCEL] = keycode
					
				case "MBUTTON" then
					kc[KC_MBUTTON] = keycode
					
				case "XBUTTON1" then
					kc[KC_XBUTTON1] = keycode
					
				case "XBUTTON2" then
					kc[KC_XBUTTON2] = keycode
					
				case "BACK" then
					kc[KC_BACK] = keycode
					
				case "TAB" then
					kc[KC_TAB] = keycode
					
				case "CLEAR" then
					kc[KC_CLEAR] = keycode
					
				case "RETURN" then
					kc[KC_RETURN] = keycode
					
				case "SHIFT" then
					kc[KC_SHIFT] = keycode
					
				case "CONTROL" then
					kc[KC_CONTROL] = keycode
					
				case "MENU" then
					kc[KC_MENU] = keycode
					
				case "PAUSE" then
					kc[KC_PAUSE] = keycode
					
				case "CAPITAL" then
					kc[KC_CAPITAL] = keycode
					
				case "KANA" then
					kc[KC_KANA] = keycode
					
				case "JUNJA" then
					kc[KC_JUNJA] = keycode
					
				case "FINAL" then
					kc[KC_FINAL] = keycode
					
				case "HANJA" then
					kc[KC_HANJA] = keycode
					
				case "ESCAPE" then
					kc[KC_ESCAPE] = keycode
					
				case "CONVERT" then
					kc[KC_CONVERT] = keycode
					
				case "NONCONVERT" then
					kc[KC_NONCONVERT] = keycode
					
				case "ACCEPT" then
					kc[KC_ACCEPT] = keycode
					
				case "MODECHANGE" then
					kc[KC_MODECHANGE] = keycode
					
				case "SPACE" then
					kc[KC_SPACE] = keycode
					
				case "PRIOR" then
					kc[KC_PRIOR] = keycode
					
				case "NEXT" then
					kc[KC_NEXT] = keycode
					
				case "END" then
					kc[KC_END] = keycode
					
				case "HOME" then
					kc[KC_HOME] = keycode
					
				case "LEFT" then
					kc[KC_LEFT] = keycode
					
				case "UP" then
					kc[KC_UP] = keycode
					
				case "RIGHT" then
					kc[KC_RIGHT] = keycode
					
				case "DOWN" then
					kc[KC_DOWN] = keycode
					
				case "SELECT" then
					kc[KC_SELECT] = keycode
					
				case "PRINT" then
					kc[KC_PRINT] = keycode
					
				case "EXECUTE" then
					kc[KC_EXECUTE] = keycode
					
				case "SNAPSHOT" then
					kc[KC_SNAPSHOT] = keycode
					
				case "INSERT" then
					kc[KC_INSERT] = keycode
					
				case "DELETE" then
					kc[KC_DELETE] = keycode
					
				case "HELP" then
					kc[KC_HELP] = keycode
					
				case "LWIN" then
					kc[KC_LWIN] = keycode
					
				case "RWIN" then
					kc[KC_RWIN] = keycode
					
				case "APPS" then
					kc[KC_APPS] = keycode
					
				case "SLEEP" then
					kc[KC_SLEEP] = keycode
					
				case "NUMPAD0" then
					kc[KC_NUMPAD0] = keycode
					
				case "NUMPAD1" then
					kc[KC_NUMPAD1] = keycode
					
				case "NUMPAD2" then
					kc[KC_NUMPAD2] = keycode
					
				case "NUMPAD3" then
					kc[KC_NUMPAD3] = keycode
					
				case "NUMPAD4" then
					kc[KC_NUMPAD4] = keycode
					
				case "NUMPAD5" then
					kc[KC_NUMPAD5] = keycode
					
				case "NUMPAD6" then
					kc[KC_NUMPAD6] = keycode
					
				case "NUMPAD7" then
					kc[KC_NUMPAD7] = keycode
					
				case "NUMPAD8" then
					kc[KC_NUMPAD8] = keycode
					
				case "NUMPAD9" then
					kc[KC_NUMPAD9] = keycode
					
				case "MULTIPLY" then
					kc[KC_MULTIPLY] = keycode
					
				case "ADD" then
					kc[KC_ADD] = keycode
					
				case "SEPARATOR" then
					kc[KC_SEPARATOR] = keycode
					
				case "SUBTRACT" then
					kc[KC_SUBTRACT] = keycode
					
				case "DECIMAL" then
					kc[KC_DECIMAL] = keycode
					
				case "DIVIDE" then
					kc[KC_DIVIDE] = keycode
					
				case "F1" then
					kc[KC_F1] = keycode
					
				case "F2" then
					kc[KC_F2] = keycode
					
				case "F3" then
					kc[KC_F3] = keycode
					
				case "F4" then
					kc[KC_F4] = keycode
					
				case "F5" then
					kc[KC_F5] = keycode
					
				case "F6" then
					kc[KC_F6] = keycode
					
				case "F7" then
					kc[KC_F7] = keycode
					
				case "F8" then
					kc[KC_F8] = keycode
					
				case "F9" then
					kc[KC_F9] = keycode
					
				case "F10" then
					kc[KC_F10] = keycode
					
				case "F11" then
					kc[KC_F11] = keycode
					
				case "F12" then
					kc[KC_F12] = keycode
					
				case "F13" then
					kc[KC_F13] = keycode
					
				case "F14" then
					kc[KC_F14] = keycode
					
				case "F15" then
					kc[KC_F15] = keycode
					
				case "F16" then
					kc[KC_F16] = keycode
					
				case "F17" then
					kc[KC_F17] = keycode
					
				case "F18" then
					kc[KC_F18] = keycode
					
				case "F19" then
					kc[KC_F19] = keycode
					
				case "F20" then
					kc[KC_F20] = keycode
					
				case "F21" then
					kc[KC_F21] = keycode
					
				case "F22" then
					kc[KC_F22] = keycode
					
				case "F23" then
					kc[KC_F23] = keycode
					
				case "F24" then
					kc[KC_F24] = keycode
					
				case "NUMLOCK" then
					kc[KC_NUMLOCK] = keycode
					
				case "SCROLL" then
					kc[KC_SCROLL] = keycode
					
				case "LSHIFT" then
					kc[KC_LSHIFT] = keycode
					
				case "RSHIFT" then
					kc[KC_RSHIFT] = keycode
					
				case "LCONTROL" then
					kc[KC_LCONTROL] = keycode
					
				case "RCONTROL" then
					kc[KC_RCONTROL] = keycode
					
				case "LMENU" then
					kc[KC_LMENU] = keycode
					
				case "RMENU" then
					kc[KC_RMENU] = keycode
					
				case "BROWSER_BACK" then
					kc[KC_BROWSER_BACK] = keycode
					
				case "BROWSER_FORWARD" then
					kc[KC_BROWSER_FORWARD] = keycode
					
				case "BROWSER_REFRESH" then
					kc[KC_BROWSER_REFRESH] = keycode
					
				case "BROWSER_STOP" then
					kc[KC_BROWSER_STOP] = keycode
					
				case "BROWSER_SEARCH" then
					kc[KC_BROWSER_SEARCH] = keycode
					
				case "BROWSER_FAVORITES" then
					kc[KC_BROWSER_FAVORITES] = keycode
					
				case "BROWSER_HOME" then
					kc[KC_BROWSER_HOME] = keycode
					
				case "VOLUME_MUTE" then
					kc[KC_VOLUME_MUTE] = keycode
					
				case "VOLUME_DOWN" then
					kc[KC_VOLUME_DOWN] = keycode
					
				case "VOLUME_UP" then
					kc[KC_VOLUME_UP] = keycode
					
				case "MEDIA_NEXT_TRACK" then
					kc[KC_MEDIA_NEXT_TRACK] = keycode
					
				case "MEDIA_PREV_TRACK" then
					kc[KC_MEDIA_PREV_TRACK] = keycode
					
				case "MEDIA_STOP" then
					kc[KC_MEDIA_STOP] = keycode
					
				case "MEDIA_PLAY_PAUSE" then
					kc[KC_MEDIA_PLAY_PAUSE] = keycode
					
				case "LAUNCH_MAIL" then
					kc[KC_LAUNCH_MAIL] = keycode
					
				case "LAUNCH_MEDIA_SELECT" then
					kc[KC_LAUNCH_MEDIA_SELECT] = keycode
					
				case "LAUNCH_APP1" then
					kc[KC_LAUNCH_APP1] = keycode
					
				case "LAUNCH_APP2" then
					kc[KC_LAUNCH_APP2] = keycode
					
				case "OEM_1" then
					kc[KC_OEM_1] = keycode
					
				case "OEM_PLUS" then
					kc[KC_OEM_PLUS] = keycode
					
				case "OEM_COMMA" then
					kc[KC_OEM_COMMA] = keycode
					
				case "OEM_MINUS" then
					kc[KC_OEM_MINUS] = keycode
					
				case "OEM_PERIOD" then
					kc[KC_OEM_PERIOD] = keycode
					
				case "OEM_2" then
					kc[KC_OEM_2] = keycode
					
				case "OEM_3" then
					kc[KC_OEM_3] = keycode
					
				case "OEM_4" then
					kc[KC_OEM_4] = keycode
					
				case "OEM_5" then
					kc[KC_OEM_5] = keycode
					
				case "OEM_6" then
					kc[KC_OEM_6] = keycode
					
				case "OEM_7" then
					kc[KC_OEM_7] = keycode
					
				case "OEM_8" then
					kc[KC_OEM_8] = keycode
					
				case "OEM_102" then
					kc[KC_OEM_102] = keycode
					
				case "PROCESSKEY" then
					kc[KC_PROCESSKEY] = keycode
					
				case "PACKET" then
					kc[KC_PACKET] = keycode
					
				case "ATTN" then
					kc[KC_ATTN] = keycode
					
				case "CRSEL" then
					kc[KC_CRSEL] = keycode
					
				case "EXSEL" then
					kc[KC_EXSEL] = keycode
					
				case "EREOF" then
					kc[KC_EREOF] = keycode
					
				case "PLAY" then
					kc[KC_PLAY] = keycode
					
				case "ZOOM" then
					kc[KC_ZOOM] = keycode
					
				case "NONAME" then
					kc[KC_NONAME] = keycode
					
				case "PA1" then
					kc[KC_PA1] = keycode
					
				case "OEM_CLEAR" then
					kc[KC_OEM_CLEAR] = keycode
					
				case else
					return -3 -- Unknown keyname used.
					
			end switch
		else
			return -2 -- New key value is not an integer
		end if		
	end for
	
	-- Set the new keycode values
	key_codes(kc)
  
  return 0 -- All done okay
end function

--****
-- === Cursor Style Constants
--
-- In cursor constants the second and fourth hex digits (from the
-- left) determine the top and bottom row of pixels in the cursor. The first
-- digit controls whether the cursor will be visible or not. For example~: ###0407##
-- turns on the 4th through 7th rows.
--
-- Note: //Windows// only.
--
-- See Also:
--   [[:cursor]]

public constant
	NO_CURSOR              = #2000,
	UNDERLINE_CURSOR       = #0607,
	THICK_UNDERLINE_CURSOR = #0507,
	HALF_BLOCK_CURSOR      = #0407,
	BLOCK_CURSOR           = #0007

--****
-- === Keyboard Related Routines

--**
-- Signature:
-- 		<built-in> function get_key()
--
-- Description:
--     returns the key that was pressed by the user, without waiting. Special 
--  codes are returned for the function keys, arrow keys, and so on.
--
-- Returns:
--	 	An **integer**, 
-- either -1 if no key waiting, or the code of the next key
--  waiting in keyboard buffer.
--
-- Comments:
--     The operating system can hold a small number of key-hits in its keyboard buffer.
--     ##get_key## will return the next one from the buffer, or ##-1## if the buffer is empty.
--
--     Run the ##.../euphoria/demo/key.ex## program to see what key code is generated for each key on your
--     keyboard.
--
-- Example 1:
-- <eucode>
-- integer n = get_key()
-- if n=-1 then
--     puts(1, "No key waiting.\n")
-- end if
-- </eucode>
--
-- See Also:
--   [[:wait_key]]

--**
-- sets the behavior of Control+C and Control+Break keys. 
--
-- Parameters:
--   # ##b## : a boolean,  TRUE ( != 0 ) to enable the trapping of
--     Control+C and Control+Break, FALSE ( 0 ) to disable it.
--
-- Comments:
--   When ##b## is ##1## (true), Control+C and Control+Break can terminate
--   your program when it tries to read input from the keyboard. When
--   ##b## is ##0## (false) your program will not be terminated by Control+C or Control+Break.
--   
--   Initially your program can be terminated at any point where
--   it tries to read from the keyboard.
--   
--   You can find out if the user has pressed Control+C or Control+Break by calling
--   [[:check_break]].
--
-- Example 1:
-- <eucode>
-- allow_break(0)  -- don't let the user kill the program!
-- </eucode>
--
-- See Also:
-- 		[[:check_break]]

public procedure allow_break( types:boolean b)
	machine_proc(M_ALLOW_BREAK, b)
end procedure

--**
-- Description:
-- 		returns the number of Control+C and Control+Break key presses.
--
-- Returns:
-- 		An **integer**, 
-- the number of times that Control+C or Control+Break have
--  been pressed since the last call to ##check_break##, or since the
--  beginning of the program if this is the first call.
--
-- Comments:
-- This is useful after you have called [[:allow_break]](0) which
--  prevents Control+C or Control+Break from terminating your
--  program. You can use ##check_break## to find out if the user
--  has pressed one of these keys. You might then perform some action
--  such as a graceful shutdown of your program.
--
-- Neither Control+C nor Control+Break will be returned as input
--  characters when you read the keyboard. You can only detect
--  them by calling ##check_break##.
--
-- Example 1:
-- <eucode>
-- k = get_key()
-- if check_break() then  -- ^C or ^Break was hit once or more
--     temp = graphics_mode(-1)
--     puts(STDOUT, "Shutting down...")
--     save_all_user_data()
--     abort(1)
-- end if
-- </eucode>
--
-- See Also:
-- 		[[:allow_break]]

public function check_break()
	return machine_func(M_CHECK_BREAK, 0)
end function

--**
-- Description:
--   waits for user to press a key, unless any is pending, and returns key code.
--
-- Returns:
--   An **integer**, 
-- which is a key code. If one is waiting in keyboard buffer, then return it. Otherwise, wait for one to come up.
--
-- See Also:
--   [[:get_key]], [[:getc]]

public function wait_key()
	return machine_func(M_WAIT_KEY, 0)
end function

--**
-- Description:
--   displays a prompt to the user and waits for any key.
--
-- Parameters:
--   # ##prompt## : Prompt to display, defaults to ##"Press Any Key to continue..."## .
--   # ##con## : Either ##1## (stdout), or ##2## (stderr). Defaults to ##1## .
--
-- Comments:
-- This wraps [[:wait_key]] by giving a clue that the user should press a key, and
-- perhaps do some other things as well.
--
-- Example 1:
-- <eucode>
-- any_key() -- "Press Any Key to continue..."
-- </eucode>
--
-- Example 2:
-- <eucode>
-- any_key("Press Any Key to quit")
-- </eucode>
--
-- See Also:
-- 	[[:wait_key]]

public procedure any_key(sequence prompt="Press Any Key to continue...", integer con = 1)
	if not find(con, {1,2}) then
		con = 1
	end if
	puts(con, prompt)
	wait_key()
	puts(con, "\n")
end procedure

--**
-- Description:
--   displays a prompt to the user and waits for any key. //Only// if the user is
--   running under a GUI environment.
--   
-- Parameters:
--   # ##prompt## : Prompt to display, defaults to ##"Press Any Key to continue..."##
--   # ##con## : Either 1 (stdout), or 2 (stderr). Defaults to 1.
--
-- Comments:
-- This wraps [[:wait_key]] by giving a clue that the user should press a key, and
-- perhaps do some other things as well.
--
-- Requires Windows XP or later or Windows 2003 or later to work.  Earlier versions of //Windows//
-- or O/S will always pause even when not needed.
--
-- On //Unix// systems this will not pause even when needed.
--
-- Example 1:
-- <eucode>
-- any_key() -- "Press Any Key to continue..."
-- </eucode>
--
-- Example 2:
-- <eucode>
-- any_key("Press Any Key to quit")
-- </eucode>
--
-- See Also:
-- 	[[:wait_key]]

public procedure maybe_any_key(sequence prompt="Press Any Key to continue...", integer con = 1)
	if not has_console() then
		any_key(prompt, con)
	end if
end procedure

--**
-- Description:
--   prompts the user to enter a number and returns only validated input.
--
-- Parameters:
--   # ##st## : is a string of text that will be displayed on the screen.
--   # ##s## : is a sequence of two values {lower, upper} which determine the range of values
--  		   that the user may enter. s can be empty, {}, if there are no restrictions.
--
-- Returns:
--   An **atom**, 
-- in the assigned range which the user typed in.
--
-- Errors:
--   If [[:puts]] cannot display ##st## on standard output, or if the first or second element
--   of ##s## is a sequence, a runtime error will be raised.
--
--   If user tries cancelling the prompt by hitting Control+Z, the program will abort as well,
--   issuing a type check error.
--
-- Comments:
--   As long as the user enters a number that is less than lower or greater
--   than upper, the user will be prompted again.
--
--   If this routine is too simple for your needs, feel free to copy it and make your
--   own more specialized version.
--
-- Example 1:
--   <eucode>
--   age = prompt_number("What is your age? ", {0, 150})
--   </eucode>
--
-- Example 2:
--   <eucode>
--   t = prompt_number("Enter a temperature in Celcius:\n", {})
--   </eucode>
--
-- See Also:
-- 	[[:puts]], [[:prompt_string]]
--

public function prompt_number(sequence prompt, sequence range)
	object answer

	while 1 do
		 puts(1, prompt)
		 answer = gets(0) -- make sure whole line is read
		 puts(1, '\n')

		 answer = stdget:value(answer)
		 if answer[1] != stdget:GET_SUCCESS or sequence(answer[2]) then
			  puts(1, "A number is expected - try again\n")
		 else
			 if length(range) = 2 then
				  if range[1] <= answer[2] and answer[2] <= range[2] then
					  return answer[2]
				  else
					printf(1, "A number from %g to %g is expected here - try again\n", range)
				  end if
			  else
				  return answer[2]
			  end if
		 end if
	end while
end function

--**
-- prompts the user to enter a string of text.
--
-- Parameters:
--		# ##st## : is a string that will be displayed on the screen.
--
-- Returns:
-- 		A **sequence**, 
-- the string that the user typed in, stripped of any new-line character.
--
-- Comments:
--     If the user happens to type Control+Z (indicates end-of-file), "" will be returned.
--
-- Example 1:
--     <eucode>
--     name = prompt_string("What is your name? ")
--     </eucode>
--
-- See Also:
-- 	[[:prompt_number]]

public function prompt_string(sequence prompt)
	object answer

	puts(1, prompt)
	answer = gets(0)
	puts(1, '\n')
	if sequence(answer) and length(answer) > 0 then
		return answer[1..$-1] -- trim the \n
	else
		return ""
	end if
end function

--****
-- === Cross Platform Text Graphics

type positive_atom(atom x)
	return x >= 1
end type

type text_point(sequence p)
	return length(p) = 2 and p[1] >= 1 and p[2] >= 1
		   and p[1] <= 200 and p[2] <= 500 -- rough sanity check
end type

public type positive_int(object x)
	if integer(x) and x >= 1 then
		return 1
	else
		return 0
	end if
end type

--**
-- Signature:
-- <built-in> procedure clear_screen()
--
-- Description:
-- clears the screen using the current background color. 
--
-- Comments:
-- The background color can be set by [[:bk_color]] ).
--
-- See Also:
-- [[:bk_color]]
--

--**
-- gets the value and attribute of the character at a given screen location.
--
-- Parameters:
-- 		# ##line## : the 1-base line number of the location.
-- 		# ##column## : the 1-base column number of the location.
--      # ##fgbg## : an integer, if ##0## (the default) you get an attribute_code
--                   returned otherwise you get a foreground and background color
--                   number returned.
--
-- Returns:
-- * If fgbg is zero then a **sequence** of //two// elements, ##{character, attribute_code}##
-- for the specified location.
-- * If fgbg is not zero then a **sequence** of //three// elements, ##{characterfg_color, bg_color}##.
--
-- Comments:
-- * This function inspects a single character on the //active page//.
-- * The attribute_code is an atom that contains the foreground and background
-- color of the character, and possibly other operating-system dependant 
-- information describing the appearance of the character on the screen.
-- * With ##get_screen_char## and ##put_screen_char## you can save and restore
-- a character on the screen along with its attribute_code.
-- * The ##fg_color## and ##bg_color## are integers in the range ##0## to ##15## which correspond
-- to the values in the table~:
--
-- Color Table
--
-- |= color number |= name |
-- |       0       | black      |
-- |       1       | dark blue      |
-- |       2       | green      |
-- |       3       | cyan      |
-- |       4       | crimson      |
-- |       5       | purple      |
-- |       6       | brown      |
-- |       7       | light gray      |
-- |       8       | dark gray      |
-- |       9       | blue      |
-- |       10      | bright green      |
-- |       11      | light blue      |
-- |       12      | red      |
-- |       13      | magenta      |
-- |       14      | yellow      |
-- |       15      | white      |
--
--
-- Example 1:
-- <eucode>
-- -- read character and attributes at top left corner
-- s = get_screen_char(1,1)
-- -- s could be {'A', 92}
-- -- store character and attributes at line 25, column 10
-- put_screen_char(25, 10, s)
-- </eucode>
--
-- Example 2:
-- <eucode>
-- -- read character and colors at line 25, column 10.
-- s = get_screen_char(25,10, 1)
-- -- s could be {'A', 12, 5}
-- </eucode>
--
-- See Also:
--   [[:put_screen_char]], [[:save_text_image]]

public function get_screen_char(positive_atom line, positive_atom column, integer fgbg = 0)
	sequence ca
	
	ca = machine_func(M_GET_SCREEN_CHAR, {line, column})
	if fgbg then
		ca = ca[1] & and_bits({ca[2], ca[2]/16}, 0x0F)
	end if
	
	return ca
end function

--**
-- stores and displays a sequence of characters with attributes at a given location.
--
-- Parameters:
-- 		# ##line## : the 1-based line at which to start writing.
-- 		# ##column## : the 1-based column at which to start writing.
-- 		# ##char_attr## : a sequence of alternated characters and attribute codes.
--
-- Comments:
--
-- ##char_attr## must be in the form  ##{character, attribute code, character, attribute code, ...}##.
--
-- Errors:
-- 		The length of ##char_attr## must be a multiple of two.
--
-- Comments:
--
-- The attributes atom contains the foreground color, background color, and possibly other platform-dependent information controlling how the character is displayed on the screen.
-- If ##char_attr## has ##0## length, nothing will be written to the screen. The characters are written to the //active page//.
-- It is faster to write several characters to the screen with a single call to ##put_screen_char## than it is to write one character at a time.
--
-- Example 1:
-- <eucode>
-- -- write AZ to the top left of the screen
-- -- (attributes are platform-dependent)
-- put_screen_char(1, 1, {'A', 152, 'Z', 131})
-- </eucode>
--
-- See Also:
--   [[:get_screen_char]], [[:display_text_image]]

public procedure put_screen_char(positive_atom line, positive_atom column, sequence char_attr)
	machine_proc(M_PUT_SCREEN_CHAR, {line, column, char_attr})
end procedure


--**
-- converts an attribute code to its foreground and background color components.
--
-- Parameters:
-- 		# ##attr_code## : integer, an attribute code.
--
-- Returns:
-- A **sequence**,
--  of two elements ~-- ##{fgcolor, bgcolor}##
--
-- Example 1:
-- <eucode>
-- ? attr_to_colors(92) --> {12, 5}
-- </eucode>
--
-- See Also:
--   [[:get_screen_char]], [[:colors_to_attr]]

public function attr_to_colors(integer attr_code)
    sequence fgbg = and_bits({attr_code, attr_code/16}, 0x0F)
    return {find(fgbg[1],true_fgcolor)-1, find(fgbg[2],true_bgcolor)-1}
end function

--**
-- converts a foreground and background color set to its attribute code format.
--
-- Parameters:
-- 		# ##fgbg## : Either a sequence of ##{fgcolor, bgcolor}## or just an integer fgcolor.
--      # ##bg## : An integer bgcolor. Only used when ##fgbg## is an integer.
--
-- Returns:
--        An **integer**,
-- an attribute code.
--
-- Example 1:
-- <eucode>
-- ? colors_to_attr({12, 5}) --> 92
-- ? colors_to_attr(12, 5) --> 92
-- </eucode>
--
-- See Also:
--   [[:get_screen_char]], [[:put_screen_char]], [[:attr_to_colors]]

public function colors_to_attr(object fgbg, integer bg = 0)
	if sequence(fgbg) then
                return true_fgcolor[fgbg[1]+1] + true_bgcolor[fgbg[2]+1] * 16
	else
                return true_fgcolor[fgbg+1] + true_bgcolor[bg+1] * 16
	end if
end function

--**
-- displays a text image in any text mode.
--
-- Parameters:
-- 		# ##xy## : a pair of 1-based coordinates representing the point at which to start writing.
--		# ##text## : a list of sequences of alternated character and attribute.
--
-- Comments:
-- This routine displays to the active text page, and only works in text modes.
--
-- You might use [[:save_text_image]] and [[:display_text_image]] in a text-mode graphical
-- user interface, to allow "pop-up" dialog boxes, and drop-down menus to appear and disappear
-- without losing what was previously on the screen.
--
-- Example 1:
-- <eucode>
-- clear_screen()
-- display_text_image({1,1}, {{'A', WHITE, 'B', GREEN},
--                            {'C', RED+16*WHITE},
--                            {'D', BLUE}})
-- -- displays:
-- --     AB
-- --     C
-- --     D
-- -- at the top left corner of the screen.
-- -- 'A' will be white with black (0) background color,
-- -- 'B' will be green on black,
-- -- 'C' will be red on white, and
-- -- 'D' will be blue on black.
-- </eucode>
--
-- See Also:
--   [[:save_text_image]], [[:put_screen_char]]
--

public procedure display_text_image(text_point xy, sequence text)
	integer extra_col2, extra_lines
	sequence vc, one_row

	vc = graphcst:video_config()
	if xy[1] < 1 or xy[2] < 1 then
		return -- bad starting point
	end if
	extra_lines = vc[graphcst:VC_LINES] - xy[1] + 1
	if length(text) > extra_lines then
		if extra_lines <= 0 then
			return -- nothing to display
		end if
		text = text[1..extra_lines] -- truncate
	end if
	extra_col2 = 2 * (vc[graphcst:VC_COLUMNS] - xy[2] + 1)
	for row = 1 to length(text) do
		one_row = text[row]
		if length(one_row) > extra_col2 then
			if extra_col2 <= 0 then
				return -- nothing to display
			end if
			one_row = one_row[1..extra_col2] -- truncate
		end if
		
		machine_proc(M_PUT_SCREEN_CHAR, {xy[1]+row-1, xy[2], one_row})
	end for
end procedure

--**
-- copies a rectangular block of text out of screen memory.
--
-- Parameters:
--   # ##top_left## : the coordinates, given as a pair, of the upper left corner of the area to save.
--   # ##bottom_right## : the coordinates, given as a pair, of the lower right corner of the area to save.
--
-- Returns:
--   A **sequence**, 
-- of ##{character, attribute, character, ...}## lists.
--	 
-- Comments:
--
-- The returned value is appropriately handled by [[:display_text_image]].
--
-- This routine reads from the active text page, and only works in text modes.
--
-- You might use this function in a text-mode graphical user interface to save a portion of the 
-- screen before displaying a drop-down menu, dialog box, alert box, and so on.
--
-- Example 1:
-- <eucode>
-- -- Top 2 lines are: Hello and World
-- s = save_text_image({1,1}, {2,5})
--
-- -- s is something like: {"H-e-l-l-o-", "W-o-r-l-d-"}
-- </eucode>
--
-- See Also:
--   [[:display_text_image]], [[:get_screen_char]]

public function save_text_image(text_point top_left, text_point bottom_right)
	sequence image, row_chars

	image = {}
	for row = top_left[1] to bottom_right[1] do
		row_chars = {}
		for col = top_left[2] to bottom_right[2] do
			row_chars &= machine_func(M_GET_SCREEN_CHAR, {row, col})
		end for

		image = append(image, row_chars)
	end for
	return image
end function

--**
-- sets the number of lines on a text-mode screen.
--
-- Parameters:
-- 		# ##rows## : an integer, the desired number of rows.
--
-- Platform:
--		//Windows//
--
-- Returns:
-- 		An **integer**, 
-- the actual number of text lines.
--
-- Comments:
-- Values of 25, 28, 43 and 50 lines are supported by most video cards.
--
-- See Also:
--
--   [[:graphics_mode]], [[:video_config]]

public function text_rows(positive_int rows)
	return machine_func(M_TEXTROWS, rows)
end function

--**
-- selects a style of cursor.
--
-- Parameters:
-- 		# ##style## : an integer defining the cursor shape.
--
-- Platform:
--		//Windows//
--
-- Comments:
--
--   In pixel-graphics modes no cursor is displayed.
--
-- Example 1:
-- <eucode>
-- cursor(BLOCK_CURSOR)
-- </eucode>
--
-- Cursor Type Constants~:
-- * [[:NO_CURSOR]]
-- * [[:UNDERLINE_CURSOR]]
-- * [[:THICK_UNDERLINE_CURSOR]]
-- * [[:HALF_BLOCK_CURSOR]]
-- * [[:BLOCK_CURSOR]]
--
-- See Also:
--   [[:graphics_mode]], [[:text_rows]]
--

public procedure cursor(integer style)
	machine_proc(M_CURSOR, style)
end procedure

--**
-- frees (deletes) any console window associated with your program.
--
-- Comments:
--  Euphoria will create a console text window for your program the first time that your
--  program prints something to the screen, reads something from the keyboard, or in some
--  way needs a console. On //Windows// this window will automatically disappear when your program
--  terminates, but you can call ##free_console## to make it disappear sooner. On //Unix// 
--  the text mode console is always there, but an xterm window will disappear after Euphoria 
--  issues a ##"Press Enter"## prompt at the end of execution.
--  
--  On //Unix// ##free_console## will set the terminal parameters back to normal,
--  undoing the effect that curses has on the screen.
--  
--  In a //Unix// terminal a call to ##free_console## (without any further
--  printing to the screen or reading from the keyboard) will eliminate the
--  "Press Enter" prompt that Euphoria normally issues at the end of execution.
--  
--  After freeing the console window, you can create a new console window by printing
--  something to the screen, calling ##clear_screen##, ##position##, or any other
--  routine that needs a console.
--  
--  When you use the trace facility, or when your program has an error, Euphoria will
--  automatically create a console window to display trace information, error messages, and so on.
--  
--  There is a WINDOWS API routine, {{{FreeConsole()}}} that does something similar to
--  ##free_console##. Use the Euphoria ##free_console## because it lets the interpreter know
--  that there is no longer a console to write to or read from.
--
-- See Also:
--     [[:clear_screen]]

public procedure free_console()
	machine_proc(M_FREE_CONSOLE, 0)
end procedure


--**
-- displays the supplied data on the console screen at the current cursor position.
--
-- Parameters:
-- # ##data_in## : Any object.
-- # ##args## : Optional arguments used to format the output. Default is ##1## .
-- # ##finalnl## : Optional. Determines if a new line is output after the data.
-- Default is to output a new line.
--
-- Comments:
-- * If ##data_in## is an atom or integer, it is simply displayed.
--
-- * If ##data_in## is a simple text string, then ##args## can be used to
--   produce a formatted output with ##data_in## providing the [[:text:format]] string and
--   ##args## being a sequence containing the data to be formatted.
-- ** If the last character of ##data_in## is an underscore character then it
-- is stripped off and ##finalnl## is set to zero. Thus ensuring that a new line
-- is **not** output.
-- ** The formatting codes expected in ##data_in## are the ones used by [[:text:format]].
-- It is not mandatory to use formatting codes, and if ##data_in## does not contain
-- any then it is simply displayed and anything in ##args## is ignored.
--
-- * If ##data_in## is a sequence containing floating-point numbers, sub-sequences 
-- or integers that are not characters, then ##data_in## is forwarded on to the
--  [[:pretty_print]] to display. 
-- ** If ##args## is a non-empty sequence, it is assumed to contain the pretty_print formatting options.
-- ** if ##args## is an atom or an empty sequence, the assumed pretty_print formatting
-- options are assumed to be ##{2}##.
--
-- After the data is displayed, the routine will normally output a New Line. If you
-- want to avoid this, ensure that the last parameter is a zero. Or to put this
-- another way, if the last parameter is zero then a New Line will **not** be output.
--
-- Example 1:
-- <eucode>
-- display("Some plain text") 
--         -- Displays this string on the console plus a new line.
-- display("Your answer:",0)  
--        -- Displays this string on the console without a new line.
-- display("cat")
-- display("Your answer:",,0) 
--         -- Displays this string on the console without a new line.
-- display("")
-- display("Your answer:_")   
--        -- Displays this string, 
--        -- except the '_', on the console without a new line.
-- display("dog")
-- display({"abc", 3.44554}) 
--        -- Displays the contents of 'res' on the console.
-- display("The answer to [1] was [2]", {"'why'", 42}) 
--        -- formats these with a new line.
-- display("",2)
-- display({51,362,71}, {1})
-- </eucode>
-- Output would be~:
-- {{{
-- Some plain text
-- Your answer:cat
-- Your answer:
-- Your answer:dog
-- {
--   "abc",
--   3.44554
-- }
-- The answer to 'why' was 42
-- ""
-- {51'3',362,71'G'}
-- }}}
--

public procedure display( object data_in, object args = 1, integer finalnl = -918_273_645)

	if atom(data_in) then
		if integer(data_in) then
			printf(1, "%d", data_in)
		else
			puts(1, text:trim(sprintf("%15.15f", data_in), '0'))
		end if

	elsif length(data_in) > 0 then
		if types:t_display( data_in ) then
			if data_in[$] = '_' then
				data_in = data_in[1..$-1]
				finalnl = 0
			end if
			
			puts(1, text:format(data_in, args))
			
		else
			if atom(args) or length(args) = 0 then
				pretty:pretty_print(1, data_in, {2})
			else
				pretty:pretty_print(1, data_in, args)
			end if
		end if
	else
		if equal(args, 2) then
			puts(1, `""`)
		end if
	end if
	
	if finalnl = 0 then
		-- no new line
	elsif finalnl = -918_273_645 and equal(args,0) then
		-- no new line
	else
		puts(1, '\n')
	end if

	return
end procedure
