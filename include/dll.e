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
-- Open a .DLL file		 
global function open_dll(sequence file_name)
	return machine_func(M_OPEN_DLL, file_name)
end function
--**

--**
-- Return the memory address where a global C variable is stored
global function define_c_var(atom lib, sequence variable_name)
	return machine_func(M_DEFINE_VAR, {lib, variable_name})
end function
--**

--**
-- Define a C function with VOID return type, or where the
-- return value will always be ignored.
-- Alternatively, define a machine-code routine at a given address.
global function define_c_proc(object lib, object routine_name, 
							  sequence arg_types)
	return machine_func(M_DEFINE_C, {lib, routine_name, arg_types, 0})
end function
--**

--**
-- define a C function (or machine code routine)
global function define_c_func(object lib, object routine_name, 
							  sequence arg_types, atom return_type)
	return machine_func(M_DEFINE_C, {lib, routine_name, arg_types, return_type})
end function
--**

--**
-- return a 32-bit call-back address for a Euphoria routine
--
-- Comments:
-- id can be of the form: 
--     routine_id          - for Linux or Windows stdcall calls, 
-- or 
--     {'+', routine_id}   - for Windows cdecl calls
global function call_back(object id)
	return machine_func(M_CALL_BACK, id)
end function
--**

--**
-- Delete the console text-window (if one currently exists).
--
-- Comments:
-- Call this if you are getting an unwanted "Press Enter" message
-- at the end of execution of your program on Linux/FreeBSD or Windows.
global procedure free_console()
	machine_proc(M_FREE_CONSOLE, 0)
end procedure
--**
