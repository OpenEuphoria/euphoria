
public include euphoria/debug/debug.e

include std/console.e
include std/convert.e
include std/text.e

integer last_line = -1
procedure show_debug( integer start_line )
	if start_line = last_line then
		return
	end if
	debug_level = 1
	last_line = start_line
	-- display the source file, line number and source code:
	printf(1, "(sdb) [%s:%d] %s\n", 
		{ 	get_file_name( get_file_no( start_line ) ), 
			get_file_line( start_line ), 
			get_source( start_line )
		} )
end procedure
-- register the event
set_debug_rid( SHOW_DEBUG, routine_id("show_debug") )

procedure display_var( atom sym, integer user_requested )
	-- when a variable value changes, we'll show the new value
	printf(1, "(sdb) [%s] = ", { debug:get_name( sym ) } )
	display( read_object( sym ) )
end procedure
set_debug_rid( DISPLAY_VAR, routine_id("display_var") )

procedure lookup_var( sequence command )
	sequence name = command[7..$]
	atom sym
	check_stack()
	sym = symbol_lookup( name, debug_stack[debug_level][CS_GLINE], debug_stack[debug_level][CS_PC] )
	
	if sym = 0 then
		printf( 1, "(sdb) Could not find symbol named '%s'\n", { name } )
	elsif not is_variable( sym ) then
		printf( 1, "(sdb) %s - not defined here\n", { name } )
	
	elsif is_novalue( sym ) then
		printf( 1, "(sdb) %s <no value assigned>\n", { name } )
		
	else
		display_var( sym, 1 )
	end if
	
end procedure

sequence debug_stack = {}
integer  debug_level = 0

procedure check_stack()
	debug_stack = debugger_call_stack()
	if debug_level > length( debug_stack ) then
		debug_level = 1
	end if
end procedure

procedure navigate_up( integer amount )
	debug_stack = debugger_call_stack()
	debug_level += amount
	if debug_level > length( debug_stack ) then
		debug_level = length( debug_stack )
	end if
	display_stack_level( debug_level )
end procedure

procedure navigate_down( integer amount )
	debug_stack = debugger_call_stack()
	debug_level -= amount
	if debug_level < 1 then
		debug_level = 1
	end if
	display_stack_level( debug_level )
end procedure

procedure clear_stack()
	debug_stack = {}
	debug_level = 0
end procedure

procedure display_stack_level( integer level )
	printf(1, "(sdb %d) [%s:%d] %s", {
		level,
		debug_stack[level][CS_FILE_NAME],
		debug_stack[level][CS_LINE_NO],
		debug_stack[level][CS_ROUTINE_NAME]
		} )
	
	if level != length( debug_stack ) then
		sequence params = get_parameter_syms( debug_stack[level][CS_ROUTINE_SYM] )
		puts( 1, "(")
		for j = 1 to length( params ) do
			if j > 1 then
				puts( 1, "," )
			end if
			printf( 1, " %s", { get_name( params[j] ) } )
		end for
		puts( 1, " )")
		
	end if
	puts( 1, "\n" )
end procedure

procedure back_trace()
	debug_stack = debugger_call_stack()
	debug_level = 1
	for i = 1 to length( debug_stack ) do
		display_stack_level( i )
		
	end for
end procedure

function find_routine( sequence name )
	sequence stack = debugger_call_stack()
	atom sym = stack[$][CS_ROUTINE_SYM]  -- TopLevel
	
	while sym and compare( name, get_name( sym ) ) do
		sym = get_next( sym )
	end while
	
	return sym
	
end function

procedure routine_breakpoint( sequence command )
	sequence name = command[3..$]
	atom routine_sym = find_routine( name )
	
	if routine_sym then
		break_routine( routine_sym, 1 )
	else
		printf(1, "Could not find routine [%s].  Break point not set.\n", { name } )
	end if
	
end procedure


sequence last_command = ""
procedure debug_screen()
	-- wait for user input before continuing
	sequence command = trim( prompt_string( "(sdb): ") )
	
	if not length( command ) then
		if not length( last_command ) then
			debug_screen()
			return
		else
			command = last_command
		end if
	end if
	last_command = command
	switch command do
		case "s" then
			step_over()
			fallthru
		
		case "n" then
			clear_stack()
			return
			
		case "c" then
			clear_stack()
			trace_off()
			return
			
		case "u" then
			navigate_up( 1 )
			
		case "d" then
			navigate_down( 1 )
			
		case "q" then
			disable_trace()
			return
			
		case "!" then
			abort_program()
		
		case "bt" then
			back_trace()
		
		case "help", "h", "?" then
			puts(1, `
	bt: show the call stack
	u : go up one level in the call stack
	d : go down one level in the call stack
	c : continue execution without trace
	n : execute the current line
	s : resume executing, and begin tracing again when execution reaches the next line
	q : stop tracing for the remainder of the program
	
	! : abort the program immediately
	
	print <x> : print the value of variable <x>
	b <x>     : set a break point in routine <x>
`)
		case else
			if match( "print ", command ) = 1 then
				lookup_var( command )
			
			elsif match( "u ", command ) = 1 then
				navigate_up( to_number( command[3..$] ) )
			elsif match( "d ", command ) = 1 then
				navigate_down( to_number( command[3..$] ) )
			elsif match( "b ", command ) = 1 then
				routine_breakpoint( command )
			else
				puts(1, `Unknown command.  Use "help", "h" or "?" for a list of valid commands` & "\n" )
			end if
			
			
	end switch
	debug_screen()
end procedure
set_debug_rid( DEBUG_SCREEN, routine_id("debug_screen") )

ifdef EUI then
	-- let the interpreter know about the external debugger
	initialize_debugger( machine_func( M_INIT_DEBUGGER, {} ) )
end ifdef
