-- Examples of calling a machine code 
-- routine from Euphoria

include std/os.e
include std/machine.e
include std/dll.e
include std/console.e
include std/convert.e

sequence add_code
integer r, x, w
atom y
atom code_space
sequence vc
sequence string_copy_code, string
atom string_space, screen_location
atom screen

clear_screen()

-- Example #1 - DOS32 
-- First example: write a color text string to the screen using call()
-- The screen is only accessible like this under DOS
ifdef DOS32 then
	
	vc = video_config()
	
	if vc[VC_COLOR] then
		screen = #B8000 -- color
	else
		screen = #B0000 -- mono
	end if
	
	string = { 'E', BRIGHT_BLUE, 'u', BRIGHT_GREEN, 'p', BRIGHT_CYAN,
		'h', BRIGHT_RED, 'o', BRIGHT_MAGENTA, 'r', YELLOW,
		'i', BRIGHT_WHITE, 'a', GREEN, '!', BROWN + 128 }
	
	-- The screen is only accessible like this under DOS
	
	string_space = allocate(length(string) + 1)
	screen_location = screen + 11 * 80 * 2 + 64 -- 11 lines down, 32 across
	
	-- String Copy machine code:
	-- (will move at least one char)
	-- This works with WATCOM, but not DJGPP, since
	-- in DJGPP low addresses need special treatment.
	string_copy_code =
		 { #50, -- push eax
			#53, -- push ebx
			#52, -- push edx
			#B8 } & -- mov eax, 
		int_to_bytes(string_space) & -- string address (source)
		 { #BA } & -- mov edx, 
		int_to_bytes(screen_location) & -- screen address (destination)
		 { #8A, #18, -- L1: mov bl, [eax]
			#40, -- inc eax
			#88, #1A, -- mov [edx],bl
			#83, #C2, #1, -- add edx, #1
			#80, #38, #0, -- cmp byte ptr [eax], #00
			#75, #F3, -- jne L1
			#5A, -- pop edx       
			#5B, -- pop ebx
			#58, -- pop eax
			#C3 } -- ret
	
	-- poke in the machine code:
	code_space = allocate_code((string_copy_code))
	
	-- poke in the string:
	poke(string_space, string & 0)
	
	puts(1, "\n  calling machine code routine ... ")
	
	-- call the machine code:
	
	call(code_space) -- copies string to screen
	
	-- these would be freed anyway when the program ends:
	free_code(code_space, length(string_copy_code))
	free(string_space)
	
	puts(1, "success\n\n")
	
	any_key("Press Enter to continue")
end ifdef

-- Example #2 - Any Platform 
-- Use define_c_func() to allow parameters to be passed to machine code. 
-- This particular example demonstrates integer calculations only.

add_code = {
	-- first int argument is at stack offset +4, 2nd int is at +8 
	#8B, #44, #24, #4, -- mov   eax, +4[esp]
	#3, #44, #24, #8, -- add   eax, +8[esp]
	#C2, #0, #8 * (platform() = WIN32) -- ret 8  -- pop 8 bytes off the stack
}

code_space = allocate_code(add_code)

r = define_c_func("", code_space, { C_INT, C_INT }, C_INT)

x = - 17
w = 80
printf(1, "  the result of %d + %d is: %d\n", { x, w, c_func(r, { x, w }) })

free_code(code_space, length(add_code))

-- Example #3
-- Use define_c_func() to allow parameters to be passed
-- to machine code. 
-- Floating-point results should be returned in ST(0) - the top of the 
-- floating-point register stack.

sequence multiply_code
multiply_code = {
	-- int argument is at stack offset +4, double is at +8 
	#DB, #44, #24, #4, -- fild  dword ptr +4[esp]
	#DC, #4C, #24, #8, -- fmul  qword ptr +8[esp]
	#C2, #C * (platform() = WIN32), #0 -- ret C -- pop 12 (or 0) bytes 
-- off the stack
}

code_space = allocate_code(multiply_code)

r = define_c_func("", code_space, { C_INT, C_DOUBLE }, C_DOUBLE)

x = 7
y = 8.5
printf(1, "  the result of %d * %.2f is: %g\n",
	 { x, y, c_func(r, { x, y }) })

free_code(code_space, length(multiply_code))
maybe_any_key("Finished.  Press any key to exit.\n")

