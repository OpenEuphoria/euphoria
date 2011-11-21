-- (c) Copyright - See License.txt
--
--****
-- == intinit.e: Common command line initialization of interpreter

ifdef ETYPE_CHECK then
	with type_check
elsedef
	without type_check
end ifdef

include std/cmdline.e
include std/text.e
include std/map.e as m
include std/console.e

include global.e
include cominit.e
include error.e
include pathopen.e
include msgtext.e
include coverage.e

sequence interpreter_opt_def = {
	{ "coverage",         0, GetMsgText(332,0), { NO_CASE, MULTIPLE, HAS_PARAMETER, "dir|file" } },
	{ "coverage-db",      0, GetMsgText(333,0), { NO_CASE, ONCE, HAS_PARAMETER, "file" } },
	{ "coverage-erase",   0, GetMsgText(334,0), { NO_CASE, ONCE } },
	{ "coverage-exclude", 0, GetMsgText(338,0), { NO_CASE, MULTIPLE, HAS_PARAMETER, "pattern"} },
	$
}

add_options( interpreter_opt_def )

include std/pretty.e
sequence pretty_opt = PRETTY_DEFAULT
pretty_opt[DISPLAY_ASCII] = 2

export procedure intoptions()
	sequence pause_msg = GetMsgText(278, 0)
	
	Argv = expand_config_options(Argv)
	Argc = length(Argv)
	
	sequence opts_array = get_options()

	m:map opts = cmd_parse( opts_array, 
		{ NO_VALIDATION_AFTER_FIRST_EXTRA, PAUSE_MSG, pause_msg }, Argv)
	
	handle_common_options(opts)

	sequence opt_keys = map:keys(opts)
	integer option_w = 0

	for idx = 1 to length(opt_keys) do
		sequence key = opt_keys[idx]
		object val = map:get(opts, key)
		
		switch key do
			case "coverage" then
				for i = 1 to length( val ) do
					add_coverage( val[i] )
				end for
				
			case "coverage-db" then
				coverage_db( val )
			
			case "coverage-erase" then
				new_coverage_db()
			
			case "coverage-exclude" then
				coverage_exclude( val )
		end switch
	end for
	
	if length(m:get(opts, cmdline:EXTRAS)) = 0 then
		show_banner()
		ShowMsg(2, 249)
		show_help( opts_array )

		if not batch_job and not test_only then
			maybe_any_key(pause_msg)
		end if

		abort(1)
	end if

	OpDefines &= { "EUI" }

	finalize_command_line(opts)
end procedure
