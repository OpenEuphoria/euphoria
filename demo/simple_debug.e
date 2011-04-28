
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
	printf(1, "(sdb) variable: [%s] = ", { debug:get_name( sym ) } )
	display( read_object( sym ) )
end procedure
set_debug_rid( DISPLAY_VAR, routine_id("display_var") )

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
			
		case "c" then
			trace_off()
		
		case "s" then
			step_over()
		
		case "q" then
			disable_trace()
		
		case "!" then
			abort_program()
		
		case "help", "h", "?" then
			puts(1, `
	n : execute the current line
	c : continue execution without trace
	s : resume executing, and begin tracing again when execution reaches the next line
	q : stop tracing for the remainder of the program
	! : abort the program immediately
`)
		case else
			puts(1, `Unknown command.  Use "help", "h" or "?" for a list of valid commands` & "\n" )
			
	end switch
	
end procedure
set_debug_rid( DEBUG_SCREEN, routine_id("debug_screen") )

ifdef EUI then
	-- let the interpreter know about the external debugger
	initialize_debugger( machine_func( M_INIT_DEBUGGER, {} ) )
end ifdef
