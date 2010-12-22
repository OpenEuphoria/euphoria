--****
-- === callmach.ex
--
-- Examples of calling a machine code routine from Euphoria

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

-- Example #1 - Any Platform 
-- Use define_c_func() to allow parameters to be passed to machine code. 
-- This particular example demonstrates integer calculations only.


add_code = {
       -- first int argument is at stack offset +4, 2nd int is at +8 
       #8B, #44, #24, #04,        -- mov   eax, +4[esp]
       #03, #44, #24, #08,        -- add   eax, +8[esp]
       #C2, #00, #08 * (platform() = WIN32) -- ret 8  -- pop 8 bytes off the stack
}

code_space = allocate_code(add_code)
    
r = define_c_func("", code_space, {C_INT, C_INT}, C_INT)

x = -17
w = 80
printf(1, "  the result of %d + %d is: %d\n", {x, w, c_func(r, {x, w})})

free_code(code_space,length(add_code))


-- Example #2
-- Use define_c_func() to allow parameters to be passed
-- to machine code. 
-- Floating-point results should be returned in ST(0) - the top of the 
-- floating-point register stack.

sequence multiply_code
multiply_code = {
   -- int argument is at stack offset +4, double is at +8 
   #DB, #44, #24, #04,        -- fild  dword ptr +4[esp]
   #DC, #4C, #24, #08,        -- fmul  qword ptr +8[esp]
   #C2, #0C * (platform()=WIN32), #00  -- ret C -- pop 12 (or 0) bytes 
					   -- off the stack
    }

code_space = allocate_code(multiply_code)

r = define_c_func("", code_space, {C_INT, C_DOUBLE}, C_DOUBLE)

x = 7
y = 8.5
printf(1, "  the result of %d * %.2f is: %g\n",  
      {x, y, c_func(r, {x, y})})

free_code(code_space,length(multiply_code))
maybe_any_key("Finished.  Press any key to exit.\n")

