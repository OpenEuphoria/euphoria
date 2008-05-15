-- (c) Copyright 2007 Rapid Deployment Software - See License.txt
--
-- Modularizes the code, while allowing files to explicitly include the
-- files they need.

integer interpret
integer translate
integer bind
integer do_extra_check
integer init_backend_rid
integer backend_rid
integer extract_options_rid
integer output_il_rid
integer target_plat
integer backend
target_plat = platform()

global procedure set_mode( sequence mode, integer extra_check )
	interpret = equal( mode, "interpret" )
	translate = equal( mode, "translate" )
	bind      = equal( mode, "bind" )
	backend   = equal( mode, "backend" )
	do_extra_check = extra_check
end procedure

global procedure set_backend( integer rid )
	backend_rid = rid
end procedure

global procedure set_init_backend( integer rid )
	init_backend_rid = rid
end procedure

global procedure InitBackEnd( integer x )
	call_proc( init_backend_rid, {x} )
end procedure

global procedure BackEnd( atom x )
	call_proc( backend_rid, {x} )
end procedure

global function get_interpret()
		return interpret
end function

global function get_translate()
	return translate
end function

global function get_bind()
	return bind
end function

global function get_backend()
	return backend
end function

global function get_extra_check()
	return do_extra_check
end function

global procedure set_extract_options( integer rid )
	extract_options_rid = rid
end procedure

global function extract_options( sequence s )
	return call_func( extract_options_rid, {s} )
end function

global procedure set_output_il( integer rid )
	output_il_rid = rid
end procedure

global procedure OutputIL()
	call_proc( output_il_rid, {} )
end procedure

global procedure set_target_platform( integer target )
	target_plat = target
end procedure

global function target_platform()
	return target_plat
end function
