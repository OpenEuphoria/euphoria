--****
-- == Dynamic Linking to External Code
--
-- <<LEVELTOC level=2 depth=4>>
--

namespace dll

include std/error.e
include std/machine.e
include std/types.e

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
	--** char  8-bits
	C_CHAR    = #01000001,
	--** byte  8-bits
	C_BYTE    = #01000001,
	--** unsigned char 8-bits
	C_UCHAR   = #02000001,
	--** ubyte 8-bits
	C_UBYTE   = #02000001,
	--** short 16-bits
	C_SHORT   = #01000002,
	--** word 16-bits
	C_WORD   = #01000002,
	--** unsigned short 16-bits
	C_USHORT  = #02000002,
	--** int 32-bits
	C_INT     = #01000004,
	--** bool 32-bits
	C_BOOL    = C_INT,
	--** unsigned int 32-bits
	C_UINT    = #02000004,
	--** long 32-bits except on 64-bit //Unix//, where it is 64-bits
	C_LONG    = #01000008,
	--** unsigned long 32-bits except on 64-bit //Unix//, where it is 64-bits
	C_ULONG   = #02000008,
	--** size_t unsigned long 32-bits except on 64-bit //Unix//, where it is 64-bits
	C_SIZE_T  = C_ULONG,
	--** any valid pointer
	C_POINTER = #03000001,
	--** longlong 64-bits
	C_LONGLONG  = #03000002,
	$
ifdef BITS32 then
public constant
	--** signed integer sizeof pointer
	C_LONG_PTR = C_LONG
elsedef
public constant
	C_LONG_PTR = C_LONGLONG
end ifdef
public constant
	--** handle sizeof pointer
	C_HANDLE  = C_LONG_PTR,
	--** hwnd sizeof pointer
	C_HWND    = C_LONG_PTR,
	--** dword 32-bits
	C_DWORD   = C_UINT,
	--** wparam sizeof pointer
	C_WPARAM  = C_POINTER,
	--** lparam sizeof pointer
	C_LPARAM  = C_POINTER,
	--** hresult 32-bits
	C_HRESULT = C_LONG,
	--** float 32-bits
	C_FLOAT   = #03000004,
	--** double 64-bits
	C_DOUBLE  = #03000008,
	--** dwordlong 64-bits
	C_DWORDLONG  = C_LONGLONG,
	$
	
--****
-- === External Euphoria Type Constants
-- These are used for arguments to and the return value from a Euphoria shared
-- library file (##.dll##, ##.so##, or ##.dylib##).

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
-- Signature:
-- <built-in> function sizeof( atom data_type )
--
-- Parameters:
--# ##data_type## A C data type constant
--
-- Description:
-- Returns the size, in bytes of the specified data type.

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
-- opens a //Windows// dynamic link library (##.dll##) file, or a //Unix// shared library
-- (##.so##) file. 
--
-- Parameters:
--   # ##file_name## : a sequence, the name of the shared library to open or a sequence of filename's
--     to try to open.
--
-- Returns:
--   An **atom**, actually a 32-bit address. 0 is returned if the ##.dll## can not be found.
--
-- Errors:
--   The length of ##file_name## (or any filename contained therein) should not exceed
--   1_024 characters.
--
-- Comments:
--   ##file_name## can be a relative or an absolute file name. Most operating systems will use
--   the normal search path for locating non-relative files.
--
--   ##file_name## can be a list of file names to try. On different Linux platforms especially,
--   the filename will not always be the same. For instance, you may wish to try opening
--   ##libmylib.so, libmylib.so.1, libmylib.so.1.0, libmylib.so.1.0.0.## If given a sequence of
--   file names to try, the first successful library loaded will be returned. If no library
--   could be loaded then zero will be returned after exhausting the entire list of file names.
--
--   The value returned by ##open_dll## can be passed to ##define_c_proc##, ##define_c_func##,
--   or ##define_c_var##.
-- 
--   You can open the same ##.dll## or ##.so## file multiple times. No extra memory is used and you will
--   get the same number returned each time.
-- 
--   Euphoria will close the ##.dll## or ##.so## for you automatically at the end of execution.
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
-- Example 2:
-- <eucode>
-- atom mysql_lib
-- mysql_lib = open_dll({"libmysqlclient.so", "libmysqlclient.so.15", 
--                      "libmysqlclient.so.15.0"})
-- if mysql_lib = 0 then
--   puts(1, "Couldn't find the mysql client library\n")
-- end if
-- </eucode>
--
-- See Also:
--     [[:define_c_func]], [[:define_c_proc]], [[:define_c_var]], [[:c_func]], [[:c_proc]]

public function open_dll(sequence file_name)
	if length(file_name) > 0 and types:string(file_name) then
		return machine_func(M_OPEN_DLL, file_name)
	end if

	-- We have a list of filenames to try, try each one, when one succeeds
	-- abort the search and return it's value
	for idx = 1 to length(file_name) do
		atom fh = machine_func(M_OPEN_DLL, file_name[idx])
		if not fh = 0 then
			return fh
		end if
	end for

	return 0
end function

--**
-- gets the address of a symbol in a shared library or in RAM.
--
-- Parameters:
--   # ##lib## : an atom, the address of a //Unix// ##.so## or //Windows// ##.dll##, as returned by ##open_dll##.
--   # ##variable_name## : a sequence, the name of a public C variable defined within the library.
--
-- Returns:
--   An **atom**, the memory address of ##variable_name##.
--
-- Comments:
--   Once you have the address of a C variable, and you know its type, you can use ##peek##
--   and ##poke## to read or write the value of the variable. You can in the same way obtain 
--   the address of a C function and pass it to any external routine that requires a callback address.
--
-- Example 1:
-- see ##.../euphoria/demo/linux/mylib.ex##
--
-- See Also:
--     [[:c_proc]], [[:define_c_func]], [[:c_func]], [[:open_dll]]

public function define_c_var(atom lib, sequence variable_name)
	return machine_func(M_DEFINE_VAR, {lib, variable_name})
end function

--**
-- defines the characteristics of either a C function, or a machine-code routine that you
-- wish to call as a procedure from your Euphoria program. 
--
-- Parameters:
-- 		# ##lib## : an object, either an entry point returned as an atom by [[:open_dll]], or ##""## to denote a routine the RAM address is known.
-- 		# ##routine_name## : an object, either the name of a procedure in a shared object or the machine address of the procedure.
-- 		# ##argtypes## : a sequence of type constants.
--
-- Returns:
-- 		A small **integer**, known as a routine id, will be returned.
--
-- Errors:
-- The length of ##name## should not exceed 1_024 characters.
--
-- Comments:
-- 		Use the returned routine id as the first argument to [[:c_proc]] when
-- you wish to call the routine from Euphoria.
--
-- 	A returned value of ##-1## indicates that the procedure could not be found or linked to.
--
-- On //Windows// you can add
-- a ##'+'## character as a prefix to the procedure name. This tells Euphoria that the function
-- uses the cdecl calling convention. By default, Euphoria assumes that C routines accept 
-- the stdcall convention.
--
-- When defining a machine code routine, ##lib## must be the empty sequence, ##""## or ##{}##, and ##routine_name##
-- indicates the address of the machine code routine. You can poke the bytes of machine code
-- into a block of memory reserved using ##allocate##. On //Windows// the machine code routine is
-- normally expected to follow the stdcall calling convention, but if you wish to use the
-- cdecl convention instead you can code ##{'+', address}## instead of address.
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
-- to a structure. However, you can pass a 64 bit integer by pretending to pass two C_LONG instead. 
-- When calling the routine, pass low doubleword first, then high doubleword.
--
--     The C function can return a value but it will be ignored. If you want to use the value
--     returned by the C function, you must instead define it with [[:define_c_func]] and call it
--     with [[:c_func]].
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
	if atom(routine_name) and not machine:safe_address(routine_name, 1, machine:A_EXECUTE) then
        error:crash("A C function is being defined from Non-executable memory.")
	end if			
	return machine_func(M_DEFINE_C, {lib, routine_name, arg_types, 0})
end function

--**
-- defines the characteristics of either a C function, or a machine-code routine that returns 
-- a value. 
--
-- Parameters:
-- 		# ##lib## : an object, either an entry point returned as an atom by [[:open_dll]], or ##""## to denote a routine the RAM address is known.
-- 		# ##routine_name## : an object, either the name of a procedure in a shared object or the machine address of the procedure.
-- 		# ##argtypes## : a sequence of type constants.
-- 		# ##return_type## : an atom, indicating what type the function will return.
--
-- Returns:
-- 		A small **integer**, known as a routine id, will be returned.
--
-- Errors:
-- The length of ##name## should not exceed 1_024 characters.
--
-- Comments:
-- 		Use the returned routine id as the first argument to [[:c_proc]] when
-- you wish to call the routine from Euphoria.
--
-- 	A returned value of ##-1## indicates that the procedure could not be found or linked to.
--
-- On //Windows// you can add a
-- ##'+'## character as a prefix to the function name. This indicates to Euphoria that the 
-- function uses the cdecl calling convention. By default, Euphoria assumes that C routines
-- accept the stdcall convention.
-- 
-- When defining a machine code routine, ##x1## must be the empty sequence ( ##""## or ##{}##), and ##x2##
-- indicates the address of the machine code routine. You can poke the bytes of machine code
-- into a block of memory reserved using ##allocate##. On //Windows// the machine code routine is
-- normally expected to follow the stdcall calling convention, but if you wish to use the
-- cdecl convention instead, you can code ##{'+', address}## instead of address for ##x2##.
--
--The C function that you define could be one created by the Euphoria To C Translator, in
-- which case you can pass Euphoria data to it, and receive Euphoria data back. A list of 
-- Euphoria types is contained in ##dll.e##:
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
-- result. However, you can pass a 64 bit integer as two ##C_LONG## instead. On calling the routine, pass low doubleword first, then high doubleword.
--
-- If you are not interested in using the value returned by the C function, you should 
-- instead define it with [[:define_c_proc]] and call it with [[:c_proc]].
-- 
-- If you use euiw to call a cdecl C routine that returns a floating-point value, it might not 
-- work. This is because the Watcom C compiler (used to build ##euiw##) has a non-standard way of 
-- handling cdecl floating-point return values.
--
-- Passing floating-point values to a machine code routine will be faster if you use 
-- ##c_func## rather than ##call## to call the routine, since you will not have to use 
-- ##atom_to_float64## and ##poke## to get the floating-point values into memory.
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
-- -- all standard .dll routines in the WINDOWS API. 
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
	  if atom(routine_name) and not machine:safe_address(routine_name, 1, machine:A_EXECUTE) then
	      error:crash("A C function is being defined from Non-executable memory.")
	  end if			
	  return machine_func(M_DEFINE_C, {lib, routine_name, arg_types, return_type})
end function

--****
-- Signature:
-- <built-in> function c_func(integer rid, sequence args={})
--
-- Description:
-- calls a C function, machine code function, translated Euphoria function, or compiled Euphoria function by routine id. 
--
-- Parameters:
--		# ##rid## : an integer, the routine_id of the external function being called.
--		# ##args## : a sequence, the list of parameters to pass to the function
--
-- Returns:
--	An **object**, whose type and meaning was defined on calling [[:define_c_func]].
--
-- Errors:
-- If ##rid## is not a valid routine id, or the arguments do not match the prototype of
-- the routine being called, an error occurs.
--
-- Comments:
-- ##rid## must have been returned by [[:define_c_func]], **not** by [[:routine_id]]. The
-- type checks are different, and you would get a machine level exception in the best case.
--
-- If the function does not take any arguments then ##args## should be ##{}##.
--
-- If you pass an argument value which contains a fractional part, where the C function expects
-- a C integer type, the argument will be rounded towards zero. For example: ##5.9## will be passed as ##5## and ##-5.9## will be passed as ##-5##.
-- 
-- The function could be part of a ##.dll## or ##.so## created by the Euphoria To C Translator. In this case, 
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
-- [[:c_proc]], [[:define_c_proc]], [[:open_dll]], [[:Platform-Specific Issues]]
--        

--****
-- Signature:
-- <built-in> procedure c_proc(integer rid, sequence args={})
--
-- Description:
-- calls a C void function, machine code function, translated Euphoria procedure, or compiled Euphoria procedure by routine id.
--
-- Parameters:
--		# ##rid## : an integer, the routine_id of the external function being called.
--		# ##args## : a sequence, the list of parameters to pass to the function
--
-- Errors:
-- If ##rid## is not a valid routine id, or the arguments do not match the prototype of
-- the routine being called, an error occurs.
--
-- Comments:
-- ##rid## must have been returned by [[:define_c_proc]], **not** by [[:routine_id]]. The
-- type checks are different, and you would get a machine level exception in the best case.
--
-- If the procedure does not take any arguments then ##args## should be ##{}##.
--
-- If you pass an argument value which contains a fractional part, where the C void function expects
-- a C integer type, the argument will be rounded towards zero. For example: ##5.9## will be passed as ##5## and ##-5.9## will be passed as ##-5##.
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
-- [[:c_func]], [[:define_c_func]], [[:open_dll]], [[:Platform-Specific Issues]]
-- 

constant M_CALL_BACK = 52

--**
-- gets a machine address for an Euphoria procedure.
--
-- Parameters:
--   # ##id## : an object, either the id returned by [[:routine_id]] (for the function or procedure), or a pair ##{'+', id}##.
--
-- Returns:
--   An **atom**, the address of the machine code of the routine. It can be
--   used by //Windows//, an external C routine in a //Windows// ##.dll##,  or //Unix//
--   shared library (##.so##), as a 32-bit "call-back" address for calling your
--   Euphoria routine.
--
-- Errors:
--   The length of ##name## should not exceed 1_024 characters.
--
-- Comments:
--   By default, your routine will work with the stdcall convention. On
--   //Windows// you can specify its id as ##{'+', id}##, in which case it will
--   work with the cdecl calling convention instead. On //Unix//
--   platforms, you should only use simple IDs, as there is just one standard
--   cdecl calling convention.
--
--   You can set up as many call-back functions as you like, but they must all be Euphoria
--   functions (or types) with ##0## to ##9## arguments. If your routine has nothing to return
--   (it should really be a procedure), just return ##0## (say), and the calling C routine can
--   ignore the result.
--
--   When your routine is called, the argument values will all be 32-bit unsigned (positive)
--   values. You should declare each parameter of your routine as atom, unless you want to
--   impose tighter checking. Your routine must return a 32-bit integer value.
--
--   You can also use a call-back address to specify a Euphoria routine as an exception
--   handler in the Linux or FreeBSD ##signal## function. For example, you might want to catch
--   the SIGTERM signal, and do a graceful shutdown. Some Web hosts send a SIGTERM to a CGI
--   process that has used too much CPU time.
--
--   A call-back routine that uses the cdecl convention and returns a floating-point result,
--   might not work with euiw. This is because the Watcom C compiler (used to build ##euiw##) has
--   a non-standard way of handling cdecl floating-point return values.
--
-- Example 1: 
--   See~: ##.../euphoria/demo/win32/window.exw##
--
-- Example 2:
--  See~: ##.../euphoria/demo/linux/qsort.ex##
--
-- See Also:
--     [[:routine_id]]

public function call_back(object id)
		return machine_func(M_CALL_BACK, id)
end function

ifdef EU4_0 then
	--**
	-- @nodoc@
	public function sizeof(integer x)
		switch x with fallthru do
			case C_CHAR, C_BYTE, C_UCHAR, C_UBYTE then
				return 1
			case C_SHORT, C_WORD, C_USHORT then
				return 2
			-- In 4.0 everything is x86-32
			case E_OBJECT, E_ATOM, E_SEQUENCE, E_INTEGER then
			case C_INT, C_LONG, C_ULONG then
			case C_SIZE_T, C_POINTER, C_FLOAT then
				return 4
			case C_DOUBLE, C_DWORDLONG, C_LONGLONG then
				return 8
		end switch
	end function
end ifdef
