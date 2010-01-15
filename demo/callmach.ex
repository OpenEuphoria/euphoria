		-- Examples of calling a machine code 
		-- routine from Euphoria

include std/os.e
include std/machine.e
include std/graphics.e
include std/dll.e

sequence vc
vc = video_config()

atom screen
if vc[VC_COLOR] then
    screen = #B8000 -- color
else
    screen = #B0000 -- mono
end if

-- First example: write a color text string to the screen using call()

sequence string_copy_code, string
atom code_space, string_space, screen_location

clear_screen()

string = {'E', BRIGHT_BLUE, 'u', BRIGHT_GREEN, 'p', BRIGHT_CYAN, 
	  'h', BRIGHT_RED, 'o', BRIGHT_MAGENTA, 'r', YELLOW,
	  'i', BRIGHT_WHITE, 'a', GREEN, '!', BROWN+128}


-- Example #2 - Any Platform 
-- Use define_c_func() to allow parameters to be passed to machine code. 
-- This particular example demonstrates integer calculations only.

-- Note:euid.exe uses software-emulated floating-point. It keeps
-- floating-point values in register pairs (eax, edx) and (ebx, ecx).
-- Floating-point results should be returned in (eax, edx).

sequence add_code
integer r, x, w 
atom y

add_code = {
       -- first int argument is at stack offset +4, 2nd int is at +8 
       #8B, #44, #24, #04,        -- mov   eax, +4[esp]
       #03, #44, #24, #08,        -- add   eax, +8[esp]
       #C2, #00, #08 * platform() = WIN32 -- ret 8  -- pop 8 bytes off the stack
}

code_space = allocate_code(add_code)
    
r = define_c_func("", code_space, {C_INT, C_INT}, C_INT)

x = -17
w = 80
printf(1, "  the result of %d + %d is: %d\n", {x, w, c_func(r, {x, w})})

free_code(code_space,length(add_code))


-- Example #3 - Windows/Linux 
-- Use define_c_func() to allow parameters to be passed
-- to machine code. eui.exe uses hardware floating-point instructions. 
-- Floating-point results should be returned in ST(0) - the top of the 
-- floating-point register stack.

sequence multiply_code
multiply_code = {
   -- int argument is at stack offset +4, double is at +8 
   #DB, #44, #24, #04,        -- fild  dword ptr +4[esp]
   #DC, #4C, #24, #08,        -- fmul  qword ptr +8[esp]
   #C2, #0C * (platform()=WIN32), #00  -- ret C -- pop 12 (or 8) bytes 
					   -- off the stack
    }

if platform() = WIN32 or platform() = LINUX or platform() = OSX then
    
    code_space = allocate_code(multiply_code)
    
    r = define_c_func("", code_space, {C_INT, C_DOUBLE}, C_DOUBLE)

    x = 7
    y = 8.5
    printf(1, "  the result of %d * %.2f is: %g\n",  
	  {x, y, c_func(r, {x, y})})

    free_code(code_space,length(multiply_code))
    puts(1, "Finished.  Press any key to exit.\n" )
    if getc(0) then
    end if
end if
