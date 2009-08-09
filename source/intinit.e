-- (c) Copyright - See License.txt
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

sequence interpreter_opt_def = {}

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


	expand_config_options()
	m:map opts = cmd_parse( get_options(),
		{ NO_VALIDATION_AFTER_FIRST_EXTRA }, Argv)

	sequence tmp_Argv = Argv
	Argv = Argv[1..2] & GetDefaultArgs()
	Argc = length(Argv)

	m:map default_opts = cmd_parse( get_options(), , Argv )
	merge_maps( opts, default_opts )

	Argv = tmp_Argv
	Argc = length( Argv )

	handle_common_options(opts)

	if length(m:get(opts, "extras")) = 0 then
		show_banner()
		ShowMsg(2, 249)
		show_help( get_options() )
		if find("WIN32_GUI", OpDefines) then
			if not batch_job then
				any_key(GetMsgText(278,0), 2)
			end if
		end if

		abort(1)
	end if

	OpDefines &= { "EUI" }

	finalize_command_line(opts)
end procedure
