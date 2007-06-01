-- (c) Copyright 2007 Rapid Deployment Software - See License.txt
--
-- Euphoria 3.1
-- Windows message_box() function

include dll.e
include machine.e
include misc.e

without warning

-- Possible style values for message_box() style sequence
global constant 
    MB_ABORTRETRYIGNORE = #02, --  Abort, Retry, Ignore
    MB_APPLMODAL = #00,       -- User must respond before doing something else
    MB_DEFAULT_DESKTOP_ONLY = #20000,    
    MB_DEFBUTTON1 = #00,      -- First button is default button
    MB_DEFBUTTON2 = #100,      -- Second button is default button
    MB_DEFBUTTON3 = #200,      -- Third button is default button
    MB_DEFBUTTON4 = #300,   -- Fourth button is default button
    MB_HELP = #4000,            -- Windows 95: Help button generates help event
    MB_ICONASTERISK = #40,
    MB_ICONERROR = #10, 
    MB_ICONEXCLAMATION = #30, -- Exclamation-point appears in the box
    MB_ICONHAND = MB_ICONERROR,        -- A hand appears
    MB_ICONINFORMATION = MB_ICONASTERISK,-- Lowercase letter i in a circle appears
    MB_ICONQUESTION = #20,    -- A question-mark icon appears
    MB_ICONSTOP = MB_ICONHAND,
    MB_ICONWARNING = MB_ICONEXCLAMATION,
    MB_OK = #00,              -- Message box contains one push button: OK
    MB_OKCANCEL = #01,        -- Message box contains OK and Cancel
    MB_RETRYCANCEL = #05,     -- Message box contains Retry and Cancel
    MB_RIGHT = #80000,        -- Windows 95: The text is right-justified
    MB_RTLREADING = #100000,   -- Windows 95: For Hebrew and Arabic systems
    MB_SERVICE_NOTIFICATION = #40000, -- Windows NT: The caller is a service 
    MB_SETFOREGROUND = #10000,   -- Message box becomes the foreground window 
    MB_SYSTEMMODAL  = #1000,    -- All applications suspended until user responds
    MB_TASKMODAL = #2000,       -- Similar to MB_APPLMODAL 
    MB_YESNO = #04,           -- Message box contains Yes and No
    MB_YESNOCANCEL = #03      -- Message box contains Yes, No, and Cancel

-- possible values returned by MessageBox() 
-- 0 means failure
global constant IDABORT = 3,  -- Abort button was selected.
		IDCANCEL = 2, -- Cancel button was selected.
		IDIGNORE = 5, -- Ignore button was selected.
		IDNO = 7,     -- No button was selected.
		IDOK = 1,     -- OK button was selected.
		IDRETRY = 4,  -- Retry button was selected.
		IDYES = 6    -- Yes button was selected.

atom lib
integer msgbox_id, get_active_id

if platform() = WIN32 then
    lib = open_dll("user32.dll")
    msgbox_id = define_c_func(lib, "MessageBoxA", {C_POINTER, C_POINTER, 
						   C_POINTER, C_INT}, C_INT)
    if msgbox_id = -1 then
	puts(2, "couldn't find MessageBoxA\n")
	abort(1)
    end if

    get_active_id = define_c_func(lib, "GetActiveWindow", {}, C_LONG)
    if get_active_id = -1 then
	puts(2, "couldn't find GetActiveWindow\n")
	abort(1)
    end if
end if

global function message_box(sequence text, sequence title, object style)
    integer or_style
    atom text_ptr, title_ptr, ret
    
    text_ptr = allocate_string(text)
    if not text_ptr then
	return 0
    end if
    title_ptr = allocate_string(title)
    if not title_ptr then
	free(text_ptr)
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
    free(text_ptr)
    free(title_ptr)
    return ret
end function


