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
	{ "coverage",  0, GetMsgText(332,0), { NO_CASE, MULTIPLE, HAS_PARAMETER, "dir|file" } },
	{ "coverage-db",  0, GetMsgText(333,0), { NO_CASE, HAS_PARAMETER, "file" } },
	{ "coverage-erase",  0, GetMsgText(334,0), { NO_CASE } },
	{ "coverage-exclude", 0, GetMsgText(338,0), { NO_CASE, MULTIPLE, HAS_PARAMETER, "pattern"}},
	$}

add_options( interpreter_opt_def )

--**
-- Merges values from map b into map a, using operation CONCAT
procedure merge_maps( m:map a, m:map b )
	sequence pairs = m:pairs( b )
	for i = 1 to length( pairs ) do
		m:put( a, pairs[i][1], pairs[i][2], m:CONCAT )
	end for
end procedure

include std/pretty.e
sequence pretty_opt = PRETTY_DEFAULT
pretty_opt[DISPLAY_ASCII] = 2
export procedure intoptions()

	sequence pause_msg = ""

	if find("WIN32_GUI", OpDefines) then
		if not batch_job then
			pause_msg = GetMsgText(278,0)
		end if
	end if

	Argv = expand_config_options(Argv)
	m:map opts = cmd_parse( get_options(),
		{ NO_VALIDATION_AFTER_FIRST_EXTRA, PAUSE_MSG, pause_msg }, Argv)

	sequence tmp_Argv = Argv
	Argv = Argv[1..2] & GetDefaultArgs()
	Argc = length(Argv)

	m:map default_opts = cmd_parse( get_options(), , Argv )
	merge_maps( opts, default_opts )

	Argv = tmp_Argv
	Argc = length( Argv )

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
	
	if length(m:get(opts, OPT_EXTRAS)) = 0 then
		show_banner()
		ShowMsg(2, 249)
		show_help( get_options() )
		if find("WIN32_GUI", OpDefines) then
			if not batch_job then
				any_key(pause_msg, 2)
			end if
		end if

		abort(1)
	end if

	OpDefines &= { "EUI" }

	finalize_command_line(opts)
end procedure
