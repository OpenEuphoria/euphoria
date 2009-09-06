-- (c) Copyright - See License.txt
--
-- Modularizes the code, while allowing files to explicitly include the
-- files they need.

ifdef ETYPE_CHECK then
	with type_check
elsedef
	without type_check
end ifdef

integer interpret
integer translate
integer bind
integer do_extra_check
integer init_backend_rid = -1
integer backend_rid = -1
integer extract_options_rid
integer output_il_rid
integer backend
integer check_platform_rid = -1
integer target_plat = platform()

type valid_mode( sequence mode )
	return find(mode, {"interpret","translate","bind","backend"})
end type


export procedure set_mode( valid_mode mode, integer extra_check )
	interpret = equal( mode, "interpret" )
	translate = equal( mode, "translate" )
	bind      = equal( mode, "bind" )
	backend   = equal( mode, "backend" )
	do_extra_check = extra_check
end procedure

export procedure set_backend( integer rid )
	backend_rid = rid
end procedure

export procedure set_init_backend( integer rid )
	init_backend_rid = rid
end procedure

export procedure InitBackEnd( integer x )
	call_proc( init_backend_rid, {x} )
end procedure

export procedure BackEnd( atom x )
	call_proc( backend_rid, {x} )
end procedure

export procedure CheckPlatform()
	if check_platform_rid != -1 then
		call_proc( check_platform_rid, {} )
	end if
end procedure

export procedure set_check_platform( integer rid )
	check_platform_rid = rid
end procedure

export function get_interpret()
		return interpret
end function

export function get_translate()
	return translate
end function

export function get_bind()
	return bind
end function

export function get_backend()
	return backend
end function

export function get_extra_check()
	return do_extra_check
end function

export procedure set_extract_options( integer rid )
	extract_options_rid = rid
end procedure

export function extract_options( sequence s )
	return call_func( extract_options_rid, {s} )
end function

export procedure set_output_il( integer rid )
	output_il_rid = rid
end procedure

export procedure OutputIL()
	call_proc( output_il_rid, {} )
end procedure

export procedure set_target_platform( integer target )
	target_plat = target
end procedure

export function target_platform()
	return target_plat
end function
