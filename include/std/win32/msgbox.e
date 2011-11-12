--****
-- == Windows Message Box
--
-- <<LEVELTOC level=2 depth=4>>
--

namespace msgbox

include std/dll.e
include std/machine.e

without warning

--****
-- === Style Constants
-- 
-- Possible style values for message_box() style sequence
--

public constant
	--** Abort, Retry, Ignore
	MB_ABORTRETRYIGNORE = #02,
	--** User must respond before doing something else
	MB_APPLMODAL = #00,               
	MB_DEFAULT_DESKTOP_ONLY = #20000,
	--** First button is default button
	MB_DEFBUTTON1 = #00,
	--** Second button is default button
	MB_DEFBUTTON2 = #100,
	--** Third button is default button
	MB_DEFBUTTON3 = #200,
	--** Fourth button is default button
	MB_DEFBUTTON4 = #300,
	--** Windows 95: Help button generates help event
	MB_HELP = #4000,                  
	MB_ICONASTERISK = #40,
	MB_ICONERROR = #10,
	--** Exclamation-point appears in the box
	MB_ICONEXCLAMATION = #30,
	--** A hand appears
	MB_ICONHAND = MB_ICONERROR,
	--** Lowercase letter i in a circle appears
	MB_ICONINFORMATION = MB_ICONASTERISK,
	--** A question-mark icon appears
	MB_ICONQUESTION = #20,            
	MB_ICONSTOP = MB_ICONHAND,
	MB_ICONWARNING = MB_ICONEXCLAMATION,
	--** Message box contains one push button: OK
	MB_OK = #00,
	--** Message box contains OK and Cancel
	MB_OKCANCEL = #01,
	--** Message box contains Retry and Cancel
	MB_RETRYCANCEL = #05,
	--** Windows 95: The text is right-justified
	MB_RIGHT = #80000,
	--** Windows 95: For Hebrew and Arabic systems
	MB_RTLREADING = #100000,
	--** Windows NT: The caller is a service
	MB_SERVICE_NOTIFICATION = #40000,
	--** Message box becomes the foreground window
	MB_SETFOREGROUND = #10000,
	--** All applications suspended until user responds
	MB_SYSTEMMODAL  = #1000,
	--** Similar to MB_APPLMODAL
	MB_TASKMODAL = #2000,
	--** Message box contains Yes and No
	MB_YESNO = #04,
	--** Message box contains Yes, No, and Cancel
	MB_YESNOCANCEL = #03              

--****
-- === Return Value Constants
--
-- possible values returned by MessageBox(). 0 means failure

public constant
	--** Abort button was selected.
	IDABORT = 3,
	--** Cancel button was selected.
	IDCANCEL = 2,
	--** Ignore button was selected.
	IDIGNORE = 5,
	--** No button was selected.
	IDNO = 7,
	--** OK button was selected.
	IDOK = 1,
	--** Retry button was selected.
	IDRETRY = 4,
	--** Yes button was selected.
	IDYES = 6     

atom lib
integer msgbox_id, get_active_id

ifdef WINDOWS then
	lib = dll:open_dll("user32.dll")
	msgbox_id = dll:define_c_func(lib, "MessageBoxA", {C_POINTER, C_POINTER, 
												   C_POINTER, C_UINT}, C_INT)
	if msgbox_id = -1 then
		puts(2, "couldn't find MessageBoxA\n")
		abort(1)
	end if

	get_active_id = dll:define_c_func(lib, "GetActiveWindow", {}, C_POINTER)
	if get_active_id = -1 then
		puts(2, "couldn't find GetActiveWindow\n")
		abort(1)
	end if
end ifdef

--****
-- === Routines
--

--**
-- Displays a window with a title, message, buttons and an icon, usually known as a message box.
--
-- Parameters:
--   # ##text##: a sequence, the message to be displayed
--   # ##title##: a sequence, the title the box should have
--   # ##style##: an object which defines which,icon should be displayed, if any, and which buttons will be presented.
--
-- Returns:
--   An **integer**, the button which was clicked to close the message box, or 0 on failure.
--
-- Comments:
--   See [[:Style Constants]] above for a complete list of possible values for ##style## and
--   [[:Return Value Constants]] for the returned value. If ##style## is a sequence, its elements will be
--   or'ed together.

public function message_box(sequence text, sequence title, object style)
	integer or_style
	atom text_ptr, title_ptr, ret
	
	text_ptr = machine:allocate_string(text)
	if not text_ptr then
		return 0
	end if
	title_ptr = machine:allocate_string(title)
	if not title_ptr then
		machine:free(text_ptr)
		return 0
	end if
	if atom(style) then
		or_style = style
	else
		or_style = 0
		for i = 1 to length(style) do
			or_style = or_bits(or_style, style[i])
		end for
	end if
	
	ret = c_func(msgbox_id, {c_func(get_active_id, {}), 
							 text_ptr, title_ptr, or_style})
	machine:free(text_ptr)
	machine:free(title_ptr)

	return ret
end function

