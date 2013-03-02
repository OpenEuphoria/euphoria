namespace debug

include std/dll.e
include std/machine.e

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
--** CS_ROUTINE_SYM: (debugger only) Pointer to the routine symbol
	CS_ROUTINE_SYM,
--** CS_PC: (debugger only) The program counter pointer for this routine
	CS_PC,
--** CS_GLINE: (debugger only) The index into the global line array
	CS_GLINE,
	$

--****
--=== DEBUG_ROUTINE Enum Type
-- These constants are used to register euphoria routines that handle various debugger
-- tasks, displaying information or waiting for user input.

public enum type DEBUG_ROUTINE
--****
-- SHOW_DEBUG
--Description: 
-- a procedure that takes an integer parameter that represents the current line in the global line table
	SHOW_DEBUG,
--****
-- DISPLAY_VAR
-- Description:
-- A procedure that takes a pointer to the variable in the symbol table, and a flag to indicate whether the user requested this variable or not.  Euphoria generally
-- calls this when a variable is assigned to.
	DISPLAY_VAR,
--****
-- UPDATE_GLOBALS
-- Description:
-- A procedure called when the debug screen should update the display of any non-private
-- variables
	UPDATE_GLOBALS,
--** DEBUG_SCREEN: called when the debugger should finish displaying and wait for user input before continuing
	DEBUG_SCREEN,
--** ERASE_PRIVATES: A procedure that takes a pointer to the routine  that has gone out of scope, and whose symbols should be removed from the display.
	ERASE_PRIVATES,
--** ERASE_SYMBOL: A procedure that takes a pointer to the symbol that should be removed from the display
	ERASE_SYMBOL
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

public memstruct Var
	pointer symtab_entry declared_in
end memstruct

public memstruct Block
	unsigned int first_line
	unsigned int last_line
end memstruct

public memstruct private_block
	int task_number
	pointer private_block next
	object block[2]
end memstruct

public memstruct Subp
	pointer object code
	pointer symtab_entry temps
	pointer private_block saved_privates
	pointer object block
	pointer int linetab
	unsigned int firstline
	unsigned int num_args
	int resident_task
	unsigned int stack_space
end memstruct

public memunion U
	Var var
	Subp subp
	Block block
end memunion

public memstruct symtab_entry
	object obj
	pointer symtab_entry next
	pointer symtab_entry next_in_block
	char mode
	char scope
	unsigned char file_no
	unsigned char dummy
	int token
	pointer char name
	U u
end memstruct

public memstruct source_line
	pointer char src
	short        line
	char         file_no
	char         options
end memstruct


atom
	symbol_table    = 0,
	slist           = 0,
	op_table        = 0,
	data_buffer     = 0,
	file_name_ptr   = 0,
	$

-- C routines for interfacing with the interpreter
integer
	read_object_cid   = -1,
	trace_off_cid     = -1,
	disable_trace_cid = -1,
	step_over_cid     = -1,
	abort_program_cid = -1,
	RTLookup_cid      = -1,
	get_pc_cid        = -1,
	is_novalue_cid    = -1,
	back_trace_cid    = -1,
	call_stack_cid    = -1,
	break_routine_cid = -1,
	$

integer
	show_debug_rid     = -1,
	display_var_rid    = -1,
	update_globals_rid = -1,
	debug_screen_rid   = -1,
	erase_privates_rid = -1,
	erase_symbol_rid   = -1,
	$

atom showing_line = -1

function show_debug()
	if show_debug_rid != -1 then
		showing_line = peek_pointer( data_buffer )
		call_proc( show_debug_rid, { showing_line } )
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

function erase_privates( atom proc_sym )
	if erase_privates_rid != -1 then
		call_proc( erase_privates_rid, { proc_sym } )
	end if
	return 0
end function

function erase_symbol( atom sym )
	if erase_symbol_rid != -1 then
		call_proc( erase_symbol_rid, { sym } )
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
	IA_TRACE_OFF,
	IA_DISABLE_TRACE,
	IA_STEP_OVER,
	IA_ABORT_PROGRAM,
	IA_RTLOOKUP,
	IA_GET_PC,
	IA_IS_NOVALUE,
	IA_CALL_STACK,
	IA_BREAK_ROUTINE,
	$
end type

enum type INIT_PARAMS
	IP_BUFFER,
	IP_SHOW_DEBUG,
	IP_DISPLAY_VAR,
	IP_UPDATE_GLOBALS,
	IP_DEBUG_SCREEN,
	IP_ERASE_PRIVATE_NAMES,
	IP_ERASE_SYMBOL,
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
	init_params[IP_SHOW_DEBUG]          = call_back( '+' & routine_id("show_debug") )
	init_params[IP_DISPLAY_VAR]         = call_back( '+' & routine_id("display_var") )
	init_params[IP_UPDATE_GLOBALS]      = call_back( '+' & routine_id("update_globals") )
	init_params[IP_DEBUG_SCREEN]        = call_back( '+' & routine_id("debug_screen") )
	init_params[IP_ERASE_PRIVATE_NAMES] = call_back( '+' & routine_id("erase_privates") )
	init_params[IP_ERASE_SYMBOL]        = call_back( '+' & routine_id("erase_symbol") )
	
	
	sequence init_data = c_func( define_c_func( "", { '+', init_ptr}, { E_SEQUENCE }, E_SEQUENCE ), { init_params } )
	symbol_table       = init_data[IA_SYMTAB]
	slist              = init_data[IA_SLIST]
	op_table           = init_data[IA_OPS]
	read_object_cid    = define_c_func( "", { '+', init_data[IA_READ_OBJECT] }, { C_POINTER }, E_OBJECT )
	file_name_ptr      = init_data[IA_FILE_NAME]
	trace_off_cid      = define_c_proc( "", { '+', init_data[IA_TRACE_OFF] }, {} )
	disable_trace_cid  = define_c_proc( "", { '+', init_data[IA_DISABLE_TRACE] }, {} )
	step_over_cid      = define_c_proc( "", { '+', init_data[IA_STEP_OVER] }, {} )
	abort_program_cid  = define_c_proc( "", { '+', init_data[IA_ABORT_PROGRAM] }, {} )
	RTLookup_cid       = define_c_func( "", { '+', init_data[IA_RTLOOKUP] }, 
			{ C_POINTER, C_INT, C_POINTER, C_POINTER, C_INT, C_ULONG}, C_POINTER )
	get_pc_cid         = define_c_func( "", { '+', init_data[IA_GET_PC] }, {}, C_POINTER )
	is_novalue_cid     = define_c_func( "", { '+', init_data[IA_IS_NOVALUE] }, { C_POINTER }, C_INT )
	call_stack_cid     = define_c_func( "", { '+', init_data[IA_CALL_STACK] }, { C_INT }, E_OBJECT )
	break_routine_cid  = define_c_func( "", { '+', init_data[IA_BREAK_ROUTINE] }, { C_POINTER, C_INT }, C_INT )
	
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
		case ERASE_PRIVATES then
			erase_privates_rid = rid
		case ERASE_SYMBOL then
			erase_symbol_rid = rid
	end switch
end procedure

public function read_object( atom sym )
	return c_func( read_object_cid, { sym } )
end function

public procedure trace_off()
	c_proc( trace_off_cid, {} )
end procedure

public procedure disable_trace()
	c_proc( disable_trace_cid, {} )
end procedure

public procedure step_over()
	c_proc( step_over_cid, {} )
end procedure

public procedure abort_program()
	c_proc( abort_program_cid, {} )
end procedure

public function get_current_line()
	return showing_line
end function

public function symbol_lookup( sequence name, integer line = get_current_line(), atom pc = get_pc() )
	atom name_ptr = allocate_string( name, 1 )
	
-- 	symtab_ptr RTLookup(char *name, int file, intptr_t *pc, symtab_ptr routine, int stlen, unsigned long current_line )
	return c_func( RTLookup_cid, { name_ptr, get_file_no( line ), pc, 0, peek_pointer( symbol_table) , line } )
end function

public function get_pc()
	return c_func( get_pc_cid, {} )
end function

public function is_novalue( atom sym_ptr )
	return c_func( is_novalue_cid, { sym_ptr } )
end function

public function debugger_call_stack()
	sequence stack = c_func( call_stack_cid, { 1 } )
	ifdef EUI then
		-- if using an interpreted debugger, strip off debugger junk
		-- from the top of the stack:
		for i = 1 to length( stack ) do
			if length( stack[i][2] ) = 0 then
				stack = remove( stack, 1, i )
				exit
			end if
		end for
	end ifdef
	return stack
end function

public function break_routine( atom routine_sym, integer enable )
	return c_func( break_routine_cid, { routine_sym, enable } )
end function

public function get_name( atom sym )
	return peek_string( sym.symtab_entry.name )
end function

public function get_source( integer src_line )
	return peek_string( slist.source_line[src_line].src )
end function

public function get_file_no( integer line )
	return slist.source_line[line].file_no
end function

public function get_file_name( integer file_no )
	return peek_string( file_name_ptr + sizeof( pointer ) * file_no )
end function

public function get_file_line( integer line_no )
	return slist.source_line[line_no].line
end function

public function get_next( atom sym )
	return sym.symtab_entry.next
end function

public function is_variable( atom sym_ptr )
	if sym_ptr = 0 then
		return 0
	end if
	
	return -100 = sym_ptr.symtab_entry.token
end function

public function get_parameter_syms( atom rtn_sym )
	integer param_count = rtn_sym.symtab_entry.u.subp.num_args
	sequence syms = repeat( 0, param_count )
	atom next_sym = rtn_sym.symtab_entry.next
	for i = 1 to param_count do
		while next_sym.symtab_entry.scope != 3 do -- SC_PRIVATE = 3
			next_sym = next_sym.symtab_entry.next
		end while
		syms[i] = next_sym
	end for
	return syms
end function

public function get_symbol_table()
	return symbol_table
end function
