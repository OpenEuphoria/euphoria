-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
--****
-- Category: 
--   c
--
-- Title:
--   Dynamic Linking to C
--****

-- C types for .dll arguments and return value:
global constant 
		 C_CHAR    = #01000001,
		 C_UCHAR   = #02000001,
		 C_SHORT   = #01000002,
		 C_USHORT  = #02000002,
		 C_INT     = #01000004,
		 C_UINT    = #02000004,
		 C_LONG    = C_INT,
		 C_ULONG   = C_UINT,
		 C_POINTER = C_ULONG,
		 C_FLOAT   = #03000004,
		 C_DOUBLE  = #03000008

-- Euphoria types for .dll arguments and return value:
global constant
		 E_INTEGER = #06000004,
		 E_ATOM    = #07000004,
		 E_SEQUENCE= #08000004,
		 E_OBJECT  = #09000004

global constant NULL = 0 -- NULL pointer

constant M_OPEN_DLL  = 50,
		 M_DEFINE_C  = 51,
		 M_CALL_BACK = 52,
		 M_FREE_CONSOLE = 54,
		 M_DEFINE_VAR = 56

--**
-- Open a Windows dynamic link library (.dll) file, or a Linux or FreeBSD shared library 
-- (.so) file. A 32-bit address will be returned, or 0 if the .dll can't be found. st can 
-- be a relative or an absolute file name. Windows will use the normal search path for 
-- locating .dll files.
--
-- Comments:
-- The value returned by open_dll() can be passed to define_c_proc(), define_c_func(), 
-- or define_c_var().
-- 
-- You can open the same .dll or .so file multiple times. No extra memory is used and you'll 
-- get the same number returned each time.
-- 
-- Euphoria will close the .dll for you automatically at the end of execution. 
--
-- Example 1:
-- atom user32
-- user32 = open_dll("user32.dll")
-- if user32 = 0 then
--    puts(1, "Couldn't open user32.dll!\n")
-- end if
-- 
-- See Also:
--     define_c_func, define_c_proc, define_c_var, c_func, c_proc, platform.doc 

global function open_dll(sequence file_name)
	return machine_func(M_OPEN_DLL, file_name)
end function
--**

--**
-- a2 is the address of a Linux or FreeBSD shared library, or Windows .dll, as returned by 
-- open_dll(). s is the name of a global C variable defined within the library. a1 will be 
-- the memory address of variable s.
--
-- Comments:
--     Once you have the address of a C variable, and you know its type, you can use peek() 
--     and poke() to read or write the value of the variable.
-- 
--     For an example, see euphoria/demo/linux/mylib.exu
--
-- See Also:
--     c_proc, define_c_func, c_func, open_dll, platform.doc

global function define_c_var(atom lib, sequence variable_name)
	return machine_func(M_DEFINE_VAR, {lib, variable_name})
end function
--**

--**
-- Define the characteristics of either a C function, or a machine-code routine that you 
-- wish to call as a procedure from your Euphoria program. A small integer, known as a 
-- routine id, will be returned. Use this routine id as the first argument to c_proc() when 
-- you wish to call the routine from Euphoria.
-- 
-- When defining a C function, x1 is the address of the library containing the C function, 
-- while x2 is the name of the C function. x1 is a value returned by open_dll(). If the C 
-- function can't be found, -1 will be returned as the routine id. On Windows, you can add 
-- a '+' character as a prefix to the function name. This tells Euphoria that the function 
-- uses the cdecl calling convention. By default, Euphoria assumes that C routines accept 
-- the stdcall convention.
--
-- When defining a machine code routine, x1 must be the empty sequence, "" or {}, and x2 
-- indicates the address of the machine code routine. You can poke the bytes of machine code 
-- into a block of memory reserved using allocate(). On Windows, the machine code routine is 
-- normally expected to follow the stdcall calling convention, but if you wish to use the 
-- cdecl convention instead, you can code {'+', address} instead of address.
-- 
-- s1 is a list of the parameter types for the function. A list of C types is contained in 
-- dll.e, and shown above. These can be used to define machine code parameters as well.
--
-- The C function that you define could be one created by the Euphoria To C Translator, in 
-- which case you can pass Euphoria data to it, and receive Euphoria data back. A list of 
-- Euphoria types is contained in dll.e, and shown above.
--
-- Comments:
--     You can pass any C integer type or pointer type. You can also pass a Euphoria atom as 
--     a C double or float.
--
--     Parameter types which use 4 bytes or less are all passed the same way, so it is not 
--     necessary to be exact.
--
--     Currently, there is no way to pass a C structure by value. You can only pass a pointer
--     to a structure.
--
--     The C function can return a value but it will be ignored. If you want to use the value
--     returned by the C function, you must instead define it with define_c_func() and call it 
--     with c_func().
--
-- Example 1:
-- atom user32
-- integer ShowWindow
-- 
-- -- open user32.dll - it contains the ShowWindow C function
-- user32 = open_dll("user32.dll")
-- 
-- -- It has 2 parameters that are both C int.
-- ShowWindow = define_c_proc(user32, "ShowWindow", {C_INT, C_INT})
-- -- If ShowWindow used the cdecl convention, 
-- -- we would have coded "+ShowWindow" here
-- 
-- if ShowWindow = -1 then
--     puts(1, "ShowWindow not found!\n")
-- end if
--
-- See Also:
--     c_proc, define_c_func, c_func, open_dll, platform.doc

global function define_c_proc(object lib, object routine_name, 
							  sequence arg_types)
	return machine_func(M_DEFINE_C, {lib, routine_name, arg_types, 0})
end function
--**

--**
-- Define the characteristics of either a C function, or a machine-code routine that returns 
-- a value. A small integer, i1, known as a routine id, will be returned. Use this routine id
-- as the first argument to c_func() when you wish to call the function from Euphoria.
--
-- When defining a C function, x1 is the address of the library containing the C function,
-- while x2 is the name of the C function. x1 is a value returned by open_dll(). If the C
-- function can't be found, -1 will be returned as the routine id. On Windows, you can add a
-- '+' character as a prefix to the function name. This indicates to Euphoria that the 
-- function uses the cdecl calling convention. By default, Euphoria assumes that C routines
-- accept the stdcall convention.
-- 
-- When defining a machine code routine, x1 must be the empty sequence, "" or {}, and x2
-- indicates the address of the machine code routine. You can poke the bytes of machine code
-- into a block of memory reserved using allocate(). On Windows, the machine code routine is
-- normally expected to follow the stdcall calling convention, but if you wish to use the
-- cdecl convention instead, you can code {'+', address} instead of address for x2.
--
-- s1 is a list of the parameter types for the function. i2 is the return type of the
-- function. A list of C types is contained in dll.e, and these can be used to define machine
-- code parameters as well:
--	
-- <ul>
-- <li>C_CHAR = #01000001</li>
-- <li>C_UCHAR = #02000001</li>
-- <li>C_SHORT = #01000002</li>
-- <li>C_USHORT = #02000002</li>
-- <li>C_INT = #01000004</li>
-- <li>C_UINT = #02000004</li>
-- <li>C_LONG = C_INT</li>
-- <li>C_ULONG = C_UINT</li>
-- <li>C_POINTER = C_ULONG</li>
-- <li>C_FLOAT = #03000004</li>
-- <li>C_DOUBLE = #0300000</li>
-- </ul>
--
-- The C function that you define could be one created by the Euphoria To C Translator, in
-- which case you can pass Euphoria data to it, and receive Euphoria data back. A list of 
-- Euphoria types is contained in dll.e:
--
-- <ul>
-- <li>E_INTEGER = #06000004</li>
-- <li>E_ATOM    = #07000004</li>
-- <li>E_SEQUENCE= #08000004</li>
-- <li>E_OBJECT  = #09000004</li>
-- </ul>
--
-- You can pass or return any C integer type or pointer type. You can also pass a Euphoria 
-- atom as a C double or float, and get a C double or float returned to you as a Euphoria atom.
--
-- Parameter types which use 4 bytes or less are all passed the same way, so it is not 
-- necessary to be exact when choosing a 4-byte parameter type. However the distinction 
-- between signed and unsigned may be important when you specify the return type of a function.
-- 
-- Currently, there is no way to pass a C structure by value or get a C structure as a return 
-- result. You can only pass a pointer to a structure and get a pointer to a structure as a 
-- result.
--
-- If you are not interested in using the value returned by the C function, you should 
-- instead define it with define_c_proc() and call it with c_proc().
-- 
-- If you use exw to call a cdecl C routine that returns a floating-point value, it might not 
-- work. This is because the Watcom C compiler (used to build exw) has a non-standard way of 
-- handling cdecl floating-point return values.
--
-- Passing floating-point values to a machine code routine will be faster if you use 
-- c_func() rather than call() to call the routine, since you won't have to use 
-- atom_to_float64() and poke() to get the floating-point values into memory.
-- 
-- ex.exe (DOS) uses calls to WATCOM floating-point routines (which then use hardware 
-- floating-point instructions if available), so floating-point values are generally passed 
-- and returned in integer register-pairs rather than floating-point registers. You'll have 
-- to disassemble some Watcom code to see how it works.
--
-- Example 1:
-- atom user32
-- integer LoadIcon
-- 
-- -- open user32.dll - it contains the LoadIconA C function
-- user32 = open_dll("user32.dll")
-- 
-- -- It takes a C pointer and a C int as parameters.
-- -- It returns a C int as a result.
-- LoadIcon = define_c_func(user32, "LoadIconA",
--                          {C_POINTER, C_INT}, C_INT)
-- -- We use "LoadIconA" here because we know that LoadIconA
-- -- needs the stdcall convention, as do
-- -- all standard .dll routines in the WIN32 API. 
-- -- To specify the cdecl convention, we would have used "+LoadIconA".
--
-- if LoadIcon = -1 then
--     puts(1, "LoadIconA could not be found!\n")
-- end if
--
-- See Also
--     euphoria\demo\callmach.ex, c_func, define_c_proc, c_proc, open_dll, platform.doc

global function define_c_func(object lib, object routine_name, 
							  sequence arg_types, atom return_type)
	return machine_func(M_DEFINE_C, {lib, routine_name, arg_types, return_type})
end function
--**

--**
-- Get a machine address for the Euphoria routine with routine id i. This address can be
-- used by Windows, or an external C routine in a Windows .dll or Linux/FreeBSD shared
-- library (.so), as a 32-bit "call-back" address for calling your Euphoria routine. On 
-- Windows, you can specify i1, which determines the C calling convention that can be used to 
-- call your routine. If i1 is '+', then your routine will work with the cdecl calling
-- convention. By default it will work with the stdcall convention. On Linux and FreeBSD you 
-- should only use the first form, as there is just one standard calling convention
--
-- Comments:
--     You can set up as many call-back functions as you like, but they must all be Euphoria 
--     functions (or types) with 0 to 9 arguments. If your routine has nothing to return
--     (it should really be a procedure), just return 0 (say), and the calling C routine can
--     ignore the result.
--
--     When your routine is called, the argument values will all be 32-bit unsigned (positive)
--     values. You should declare each parameter of your routine as atom, unless you want to 
--     impose tighter checking. Your routine must return a 32-bit integer value.
--
--     You can also use a call-back address to specify a Euphoria routine as an exception 
--     handler in the Linux/FreeBSD signal() function. For example, you might want to catch
--     the SIGTERM signal, and do a graceful shutdown. Some Web hosts send a SIGTERM to a CGI
--     process that has used too much CPU time.
--
--     A call-back routine that uses the cdecl convention and returns a floating-point result, 
--     might not work with exw. This is because the Watcom C compiler (used to build exw) has 
--     a non-standard way of handling cdecl floating-point return values.
--
--     For an example, see: demo\win32\window.exw, demo\linux\qsort.exu
--
-- See Also:
--     routine_id, platform.doc

global function call_back(object id)
	return machine_func(M_CALL_BACK, id)
end function
--**

--**
-- Free (delete) any console window associated with your program.
--
-- Comments:
--     Euphoria will create a console text window for your program the first time that your 
--     program prints something to the screen, reads something from the keyboard, or in some 
--     way needs a console (similar to a DOS-prompt window). On WIN32 this window will 
--     automatically disappear when your program terminates, but you can call free_console() 
--     to make it disappear sooner. On Linux or FreeBSD, the text mode console is always 
--     there, but an xterm window will disappear after Euphoria issues a "Press Enter" prompt 
--     at the end of execution.
--
--     On Linux or FreeBSD, free_console() will set the terminal parameters back to normal, 
--     undoing the effect that curses has on the screen.
--
--     In a Linux or FreeBSD xterm window, a call to free_console(), without any further 
--     printing to the screen or reading from the keyboard, will eliminate the 
--     "Press Enter" prompt that Euphoria normally issues at the end of execution.
--
--     After freeing the console window, you can create a new console window by printing 
--     something to the screen, or simply calling clear_screen(), position() or any other 
--     routine that needs a console.
--
--     When you use the trace facility, or when your program has an error, Euphoria will 
--     automatically create a console window to display trace information, error messages etc.
--
--     There's a WIN32 API routine, FreeConsole() that does something similar to 
--     free_console(). You should use free_console(), because it lets the interpreter know 
--     that there is no longer a console.
--
-- See Also:
--     clear_screen, platform.doc

global procedure free_console()
	machine_proc(M_FREE_CONSOLE, 0)
end procedure
--**

