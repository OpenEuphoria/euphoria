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
include std/console.e
include std/map.e as m
include std/sort.e
include std/text.e

include global.e
include cominit.e
include error.e
include pathopen.e
include msgtext.e
include coverage.e

sequence interpreter_opt_def = {
	{ "coverage",         0, GetMsgText(INDICATE_FILES_OR_DIRECTORIES_FOR_WHICH_TO_GATHER_COVERAGE_STATISTICS,0), { NO_CASE, MULTIPLE, HAS_PARAMETER, "dir|file" } },
	{ "coverage-db",      0, GetMsgText(SPECIFY_THE_FILENAME_FOR_THE_COVERAGE_DATABASE,0), { NO_CASE, ONCE, HAS_PARAMETER, "file" } },
	{ "coverage-erase",   0, GetMsgText(ERASE_AN_EXISTING_COVERAGE_DATABASE_AND_START_A_NEW_COVERAGE_ANALYSIS,0), { NO_CASE, ONCE } },
	{ "coverage-exclude", 0, GetMsgText(EXCLUDE_FROM_COVERAGE,0), { NO_CASE, MULTIPLE, HAS_PARAMETER, "pattern"} },
	{ 0, "debugger", GetMsgText( EXTERNAL_DEBUGGER, 0), {NO_CASE, ONCE, HAS_PARAMETER, "debugger"} },
	$
}

add_options( interpreter_opt_def )

include std/pretty.e
sequence pretty_opt = PRETTY_DEFAULT
pretty_opt[DISPLAY_ASCII] = 2

export object external_debugger = 0

export procedure intoptions()
	sequence pause_msg = GetMsgText(MSG_PRESS_ANY_KEY_AND_WINDOW_WILL_CLOSE, 0)
	
	Argv = expand_config_options(Argv)
	Argc = length(Argv)
	
	sequence opts_array = sort( get_options() )

	m:map opts = cmd_parse( opts_array, 
		{ NO_HELP_ON_ERROR, NO_VALIDATION_AFTER_FIRST_EXTRA, PAUSE_MSG, pause_msg }, Argv)
	
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
			
			case "debugger" then
				external_debugger = val
			
		end switch
	end for
	
	if length(m:get(opts, cmdline:EXTRAS)) = 0 and not repl then
		show_banner()
		ShowMsg(2, ERROR_MUST_SPECIFY_THE_FILE_TO_BE_INTERPRETED_ON_THE_COMMAND_LINE)

		if not batch_job and not test_only then
			maybe_any_key(pause_msg)
		end if

		abort(1)
	end if

	OpDefines &= { "EUI" }

	finalize_command_line(opts)
end procedure
