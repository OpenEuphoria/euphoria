namespace debug

include std/dll.e
include std/machine.e
include euphoria/symstruct.e

without trace

--****
-- == Debugging tools
--
-- <<LEVELTOC level=2 depth=4>>

constant M_CALL_STACK = 103

--****
-- === Call Stack Constants

public enum
--** CS_ROUTINE_NAME: index of the routine name in the sequence returned by [[:call_stack]]
	CS_ROUTINE_NAME,
--** CS_FILE_NAME: index of the file name in the sequence returned by [[:call_stack]]
	CS_FILE_NAME,
--** CS_LINE_NO: index of the line number in the sequence returned by [[:call_stack]]
	CS_LINE_NO,
	$

--****
--=== DEBUG_ROUTINE Enum Type
-- These constants are used to register euphoria routines that handle various debugger
-- tasks, displaying information or waiting for user input.

public enum type DEBUG_ROUTINE
--**** 
-- Signature:
-- SHOW_DEBUG
--Description: 
-- a procedure that takes an integer parameter that represents the current line in the global line table
	SHOW_DEBUG,
--****
-- Signature:
-- DISPLAY_VAR
-- Description:
-- A procedure that takes a pointer to the variable in the symbol table, and a flag to indicate whether the user requested this variable or not.  Euphoria generally
-- calls this when a variable is assigned to.
	DISPLAY_VAR,
--****
-- Signature:
-- UPDATE_GLOBALS
-- Description:
-- A procedure called when the debug screen should update the display of any non-private
-- variables
	UPDATE_GLOBALS,
--** DEBUG_SCREEN: called when the debugger should finish displaying and wait for user input before continuing
	DEBUG_SCREEN
end type

--****
--=== Debugging Routines

--**
-- Description:
-- Returns information about the call stack of the code currently running.
-- 
-- Returns:
-- A sequence where each element represents one level in the call stack.  See the
-- [[:Call Stack Constants]] for constants that can be used to access the call stack
-- information.
-- # routine name
-- # file name
-- # line number
public function call_stack()
	return machine_func( M_CALL_STACK, {} )
end function


atom
	symbol_table    = 0,
	slist           = 0,
	op_table        = 0,
	data_buffer     = 0,
	read_object_cid = -1,
	file_name_ptr   = 0,
	$

integer
	show_debug_rid     = -1,
	display_var_rid    = -1,
	update_globals_rid = -1,
	debug_screen_rid   = -1,
	$

function show_debug()
	if show_debug_rid != -1 then
		call_proc( show_debug_rid, { peek_pointer( data_buffer ) } )
	end if
	return 0
end function

function display_var()
	if display_var_rid != -1 then
		call_proc( display_var_rid, peek_pointer( data_buffer & 2 ) )
	end if
	return 0
end function


function update_globals()
	if update_globals_rid != -1 then
		call_proc( update_globals_rid, {} )
	end if
	return 0
end function

function debug_screen()
	if debug_screen_rid != -1 then
		call_proc( debug_screen_rid, {} )
	end if
	return 0
end function

public constant M_INIT_DEBUGGER  = 104

enum type INIT_ACCESSORS 
	IA_SYMTAB,
	IA_SLIST,
	IA_OPS,
	IA_READ_OBJECT,
	IA_FILE_NAME,
	$
end type

enum type INIT_PARAMS
	IP_BUFFER,
	IP_SHOW_DEBUG,
	IP_DISPLAY_VAR,
	IP_UPDATE_GLOBALS,
	IP_DEBUG_SCREEN,
	IP_SIZE,
	$
end type

--**
-- Description:
-- Initializes an external debugger.  It can also be called
-- from a debugger compiled into a DLL / SO.
-- 
-- Parameters:
-- # ##init_ptr## : The result of ##[[:machine_func]]( M_INIT_DEBUGGER, {} )##.
public procedure initialize_debugger( atom init_ptr )
	-- let the interpreter know that we're using an external debugger
	data_buffer = allocate( sizeof( C_POINTER ) )
	
	sequence init_params = repeat( 0, IP_SIZE - 1 )
	init_params[IP_BUFFER] = data_buffer
	init_params[IP_SHOW_DEBUG]     = call_back( '+' & routine_id("show_debug") )
	init_params[IP_DISPLAY_VAR]    = call_back( '+' & routine_id("display_var") )
	init_params[IP_UPDATE_GLOBALS] = call_back( '+' & routine_id("update_globals") )
	init_params[IP_DEBUG_SCREEN]   = call_back( '+' & routine_id("debug_screen") )
	
	
	sequence init_data = c_func( define_c_func( "", { '+', init_ptr}, { E_SEQUENCE }, E_SEQUENCE ), { init_params } )
	symbol_table     = init_data[IA_SYMTAB]
	slist            = init_data[IA_SLIST]
	op_table         = init_data[IA_OPS]
	read_object_cid  = define_c_func( "", { '+', init_data[IA_READ_OBJECT] }, { C_POINTER }, E_OBJECT )
	file_name_ptr    = init_data[IA_FILE_NAME]
	
end procedure


-- **
-- Description:
-- Used to initialize the external debuggers handlers.
-- 
-- Parameters:
-- # ##rtn## : A [[:DEBUG_ROUTINE Enum Type]] enum that signifies which routine
-- # ##rid## : The routine id that will be called when a specified debugging routine is called
public procedure set_debug_rid( DEBUG_ROUTINE rtn, integer rid )
	switch rtn do
		case SHOW_DEBUG then
			show_debug_rid = rid
		case DISPLAY_VAR then
			display_var_rid = rid
		case UPDATE_GLOBALS then
			update_globals_rid = rid
		case DEBUG_SCREEN then
			debug_screen_rid = rid
	end switch
end procedure

public function read_object( atom sym )
	return c_func( read_object_cid, { sym } )
end function

public function get_name( atom sym )
	return peek_string( peek_pointer( sym + ST_NAME ) )
end function

public function get_source( integer line )
	return peek_string( peek_pointer( slist + SL_SIZE * line + SL_SRC ) )
end function

public function get_file_no( integer line )
	return peek( slist + line * SL_SIZE + SL_FILE_NO )
end function

public function get_file_name( integer file_no )
	return peek_string( peek_pointer( file_name_ptr + sizeof( C_POINTER ) * file_no ) )
end function

public function get_file_line( integer line )
	return peek2u( slist + line * SL_SIZE + SL_LINE )
end function
