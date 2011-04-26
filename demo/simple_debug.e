public include euphoria/debug/debug.e
include std/console.e

procedure show_debug( integer start_line )
	-- display the source file, line number and source code:
	printf(1, "\nSIMPLE DEBUGGER source line [%s:%d] %s\n", 
		{ 	get_file_name( get_file_no( start_line ) ), 
			get_file_line( start_line ), 
			get_source( start_line )
		} )
end procedur
-- register the event
set_debug_rid( SHOW_DEBUG, routine_id("show_debug") )


procedure display_var( atom sym, integer user_requested )
	-- when a variable value changes, we'll show the new value
	printf(1, "\nSIMPLE DEBUGGER variable: [%s] = ", { debug:get_name( sym ) } )
	display( read_object( sym ) )
end procedure
set_debug_rid( DISPLAY_VAR, routine_id("display_var") )

procedure debug_screen()
	-- wait for user input before continuing
	puts(1, "\nSIMPLE DEBUGGER: press enter to continue")
	gets(0)
end procedure
set_debug_rid( DEBUG_SCREEN, routine_id("debug_screen") )

ifdef EUI then
	-- let the interpreter know about the external debugger
	initialize_debugger( machine_func( M_INIT_DEBUGGER, {} ) )
end ifdef
