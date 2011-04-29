
public include euphoria/debug/debug.e

include std/console.e
include std/text.e

integer last_line = -1
procedure show_debug( integer start_line )
	if start_line = last_line then
		return
	end if
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
	atom sym = symbol_lookup( name )
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

procedure back_trace()
	sequence bt = debugger_call_stack()
	for i = 1 to length( bt ) do
		printf(1, "(sdb %d) [%s:%d] %s", {
			i,
			bt[i][CS_FILE_NAME],
			bt[i][CS_LINE_NO],
			bt[i][CS_ROUTINE_NAME]
			} )
		
		if i != length( bt ) then
			sequence params = get_parameter_syms( bt[i][CS_ROUTINE_SYM] )
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
	end for
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
		case "n" then
			return
			
		case "c" then
			trace_off()
			return
			
		case "s" then
			step_over()
			return
			
		case "q" then
			disable_trace()
			return
			
		case "!" then
			abort_program()
		
		case "bt" then
			back_trace()
		
		case "help", "h", "?" then
			puts(1, `
	n : execute the current line
	c : continue execution without trace
	s : resume executing, and begin tracing again when execution reaches the next line
	q : stop tracing for the remainder of the program
	! : abort the program immediately
`)
		case else
			if match( "print ", command ) = 1 then
				lookup_var( command )
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
