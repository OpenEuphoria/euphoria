-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
--****
-- == Dynamic Linking to external code
--
-- <<LEVELTOC depth=2>>
--

include std/convert.e

--****
-- === C Type Constants
-- These C type constants are used when defining external C functions in a shared
-- library file.
--
-- Example 1:
--   See [[:define_c_proc]]
--
-- See Also:
--   [[:define_c_proc]], [[:define_c_func]], [[:define_c_var]]

public constant
	--** char
	C_CHAR    = #01000001,
	--** unsigned char
	C_UCHAR   = #02000001,
	--** short
	C_SHORT   = #01000002,
	--** unsigned short
	C_USHORT  = #02000002,
	--** int
	C_INT     = #01000004,
	--** unsigned int
	C_UINT    = #02000004,
	--** long
	C_LONG    = C_INT,
	--** unsigned long
	C_ULONG   = C_UINT,
	--** any valid pointer
	C_POINTER = C_ULONG,
	--** float
	C_FLOAT   = #03000004,
	--** double
	C_DOUBLE  = #03000008

--****
-- === External Euphoria Type Constants
-- These are used for arguments to and the return value from a Euphoria shared
-- library file (.dll, .so or .dylib).

public constant
	--** integer
	E_INTEGER = #06000004,
	--** atom
	E_ATOM    = #07000004,
	--** sequence
	E_SEQUENCE= #08000004,
	--** object
	E_OBJECT  = #09000004


--****
-- === Constants

--**
-- C's NULL pointer

public constant NULL = 0

constant M_OPEN_DLL  = 50,
		 M_DEFINE_C  = 51,
		 M_DEFINE_VAR = 56

--****
-- === Routines
--

--**
-- Open a Windows dynamic link library (.dll) file, or a //Unix// shared library
-- (.so) file. 
--
-- Parameters:
-- 		# ##file_name##: a sequence, the name of the shared library to open.
--
-- Returns:
--		An **atom**, actually a 32-bit address. 0 is returned if the .dll can't be found.
--
-- Errors:
-- The length of ##file_name## should not exceed 1,024 characters.
--
-- Comments:
-- 		##file_name## can
-- be a relative or an absolute file name. Windows will use the normal search path for 
-- locating .dll files.
--
-- The value returned by open_dll() can be passed to define_c_proc(), define_c_func(), 
-- or define_c_var().
-- 
-- You can open the same .dll or .so file multiple times. No extra memory is used and you'll 
-- get the same number returned each time.
-- 
-- Euphoria will close the .dll/.so for you automatically at the end of execution.
--
-- Example 1:
-- <eucode>
-- atom user32
-- user32 = open_dll("user32.dll")
-- if user32 = 0 then
--    puts(1, "Couldn't open user32.dll!\n")
-- end if
-- </eucode>
-- 
-- See Also:
--     [[:define_c_func]], [[:define_c_proc]], [[:define_c_var]], [[:c_func]], [[:c_proc]]

public function open_dll(sequence file_name)
	return machine_func(M_OPEN_DLL, file_name)
end function

--**
-- Gets the address of a symbol in a shared library or in RAM.
--
-- Platform:
--	not //DOS//
--
-- Parameters:
-- 		 # ##lib##: an atom, the address of a Linux or FreeBSD shared library, or Windows .dll, as returned by open_dll().
-- 		# ##variable_name##: a sequence, the name of a public C variable defined within the library.
--
-- Returns:
--		An **atom**, the memory address of ##variable_name##.
--
-- Comments:
--     Once you have the address of a C variable, and you know its type, you can use peek()
--     and poke() to read or write the value of the variable. You can in the same way obtain 
-- the address of a C function and pass it to any external routine that requires a callback address.
--
--     For an example, see ##euphoria/demo/linux/mylib.exu##
--
-- See Also:
--     [[:c_proc]], [[:define_c_func]], [[:c_func]], [[:open_dll]]

public function define_c_var(atom lib, sequence variable_name)
	return machine_func(M_DEFINE_VAR, {lib, variable_name})
end function

--**
-- Define the characteristics of either a C function, or a machine-code routine that you
-- wish to call as a procedure from your Euphoria program. 
--
-- Parameters:
-- 		# ##lib##: an object, either an entry point returned as an atom by [[:open_dll]](), or "" to denote a routine the RAM address is known.
-- 		# ##routine_name##: an object, either the name of a procedure in a shared object or the machine address of the procedure.
-- 		# ##argtypes##: a sequence of type constants.
--
-- Returns:
-- 		A small **integer**, known as a routine id, will be returned.
--
-- Errors:
-- The length of ##name## should not exceed 1,024 characters.
--
-- Comments:
-- 		Use the returned routine id as the first argument to [[:c_proc]]() when
-- you wish to call the routine from Euphoria.
--
-- 	A returned value of -1 indicates that the procedure could not be found or linked to.
--
-- On Windows, you can add
-- a '+' character as a prefix to the procedure name. This tells Euphoria that the function
-- uses the cdecl calling convention. By default, Euphoria assumes that C routines accept 
-- the stdcall convention.
--
-- When defining a machine code routine, ##lib## must be the empty sequence, "" or {}, and ##routine_name##
-- indicates the address of the machine code routine. You can poke the bytes of machine code
-- into a block of memory reserved using allocate(). On Windows, the machine code routine is
-- normally expected to follow the stdcall calling convention, but if you wish to use the
-- cdecl convention instead, you can code {'+', address} instead of address.
--
-- ##argtypes## is made of type constants, which describe the C types of arguments to the procedure. They may be used to define machine code parameters as well.
--
-- The C function that you define could be one created by the Euphoria To C Translator, in
-- which case you can pass Euphoria data to it, and receive Euphoria data back. A list of 
-- Euphoria types is shown above.
--
--     You can pass any C integer type or pointer type. You can also pass a Euphoria atom as
--     a C double or float.
--
--     Parameter types which use 4 bytes or less are all passed the same way, so it is not 
--     necessary to be exact.
--
--     Currently, there is no way to pass a C structure by value. You can only pass a pointer
-- to a structure. However, you can pass a 64 bit integer by pretending to pass two C_LONG instead. When calling the routine, pass low doubleword first, then high doubleword.
--
--     The C function can return a value but it will be ignored. If you want to use the value
--     returned by the C function, you must instead define it with [[:define_c_func()]] and call it
--     with [[:c_func]]().
--
-- Example 1:
-- <eucode>
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
-- </eucode>
--
-- See Also:
--     [[:c_proc]], [[:define_c_func]], [[:c_func]], [[:open_dll]]

public function define_c_proc(object lib, object routine_name, 
							  sequence arg_types)
	return machine_func(M_DEFINE_C, {lib, routine_name, arg_types, 0})
end function

--**
-- Define the characteristics of either a C function, or a machine-code routine that returns 
-- a value. 
--
-- Parameters:
-- 		# ##lib##: an object, either an entry point returned as an atom by [[:open_dll]](), or "" to denote a routine the RAM address is known.
-- 		# ##routine_name##: an object, either the name of a procedure in a shared object or the machine address of the procedure.
-- 		# ##argtypes##: a sequence of type constants.
-- 		# ##return_type##: an atom, indicating what type the function will return.
--
-- Returns:
-- 		A small **integer**, known as a routine id, will be returned.
--
-- Errors:
-- The length of ##name## should not exceed 1,024 characters.
--
-- Comments:
-- 		Use the returned routine id as the first argument to [[:c_proc]]() when
-- you wish to call the routine from Euphoria.
--
-- 	A returned value of -1 indicates that the procedure could not be found or linked to.
--
-- On Windows, you can add a
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
--The C function that you define could be one created by the Euphoria To C Translator, in
-- which case you can pass Euphoria data to it, and receive Euphoria data back. A list of 
-- Euphoria types is contained in dll.e:
--
-- * E_INTEGER = #06000004
-- * E_ATOM    = #07000004
-- * E_SEQUENCE= #08000004
-- * E_OBJECT  = #09000004
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
-- result. However, you can pass a 64 bit integer as two C_LONG instead. On calling the routine, pass low doubleword first, then high doubleword.
--
-- If you are not interested in using the value returned by the C function, you should 
-- instead define it with [[:define_c_proc]]() and call it with [[:c_proc]]().
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
-- <eucode>
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
-- </eucode>
--
-- See Also:
--     ##demo\callmach.ex##, [[:c_func]], [[:define_c_proc]], [[:c_proc]], [[:open_dll]]

public function define_c_func(object lib, object routine_name,
							  sequence arg_types, atom return_type)
	return machine_func(M_DEFINE_C, {lib, routine_name, arg_types, return_type})
end function

--**
-- Signature:
-- <built-in> function c_func(integer rid, sequence args)
--
-- Description:
-- Call a C function, or machine code function, or translated/compiled Euphoria function by routine id. 
--
-- Parameters:
--		# ##rid##: an integer, the routine_id of the external function being called.
--		# ##args##: a sequence, the list of parameters to pass to the function
--
-- Returns:
--	An **object**, whose type and meaning was defined on calling [[:define_c_func]]().
--
-- Errors:
-- If ##rid## is not a valid routine id, or the arguments do not match the prototype of
-- the routine being called, an error occurs.
--
-- Comments:
-- ##rid## must have been returned by [[:define_c_func]](), **not** by [[:routine_id]](). The
-- type checks are different, and you would get a machine level exception in the best case.
--
-- If the function does not take any arguments then ##args## should be ##{}##.
--
-- If you pass an argument value which contains a fractional part, where the C function expects
-- a C integer type, the argument will be rounded towards 0. e.g. 5.9 will be passed as 5, -5.9 will be passed as -5.
-- 
-- The function could be part of a .dll or .so created by the Euphoria To C Translator. In this case, 
-- a Euphoria atom or sequence could be returned. C and machine code functions can only return 
-- integers, or more generally, atoms (IEEE floating-point numbers).
--  
-- Example 1:
-- <eucode>
--  atom user32, hwnd, ps, hdc
-- integer BeginPaint
--
-- -- open user32.dll - it contains the BeginPaint C function
-- user32 = open_dll("user32.dll")
-- 
-- -- the C function BeginPaint takes a C int argument and
-- -- a C pointer, and returns a C int as a result:
-- BeginPaint = define_c_func(user32, "BeginPaint",
--                            {C_INT, C_POINTER}, C_INT)
-- 
-- -- call BeginPaint, passing hwnd and ps as the arguments,
-- -- hdc is assigned the result:
-- hdc = c_func(BeginPaint, {hwnd, ps})
-- </eucode>
--
-- See Also: 
--
-- [[:c_func]], [[:define_c_proc]], [[:open_dll]], [[../docs/platform.txt]]
--        

--**
-- Signature:
-- <built-in> procedure c_proc(integer rid, sequence args)
--
-- Description:
-- Call a C void function, or machine code function, or translated/compiled Euphoria procedure by routine id.
--
-- Parameters:
--		# ##rid##: an integer, the routine_id of the external function being called.
--		# ##args##: a sequence, the list of parameters to pass to the function
--
-- Errors:
-- If ##rid## is not a valid routine id, or the arguments do not match the prototype of
-- the routine being called, an error occurs.
--
-- Comments:
-- ##rid## must have been returned by [[:define_c_proc]](), **not** by [[:routine_id]](). The
-- type checks are different, and you would get a machine level exception in the best case.
--
-- If the procedure does not take any arguments then ##args## should be ##{}##.
--
-- If you pass an argument value which contains a fractional part, where the C void function expects
-- a C integer type, the argument will be rounded towards 0. e.g. 5.9 will be passed as 5, -5.9 will be passed as -5.
--
-- Example 1:
-- <eucode>
-- atom user32, hwnd, rect
-- integer GetClientRect
-- 
-- -- open user32.dll - it contains the GetClientRect C function
-- user32 = open_dll("user32.dll")
-- 
-- -- GetClientRect is a VOID C function that takes a C int
-- -- and a C pointer as its arguments:
-- GetClientRect = define_c_proc(user32, "GetClientRect",
--                               {C_INT, C_POINTER})
-- 
-- -- pass hwnd and rect as the arguments
-- c_proc(GetClientRect, {hwnd, rect})
-- </eucode>
--
-- See Also:
-- [[:c_proc]], [[:define_c_func]], [[:open_dll]], [[../docs/platform.txt]]
-- 


