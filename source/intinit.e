--****
-- == intinit.e: Common command line initialization of interpreter

include std/cmdline.e
include std/text.e
include std/map.e as m

include global.e
include cominit.e
include error.e
include pathopen.e

sequence interpreter_opt_def = {}

export procedure intoptions()
	if Argc < 3 then
		Argv &= GetDefaultArgs()
		Argc = length(Argv)
	end if

	expand_config_options()
	m:map opts = cmd_parse(common_opt_def & interpreter_opt_def,
		{ NO_VALIDATION_AFTER_FIRST_EXTRA }, Argv)

	handle_common_options(opts)

	if length(m:get(opts, "extras")) = 0 then
		show_banner()
		puts(2, "\nERROR: Must specify the file to be interpreted on the command line\n\n")
		show_help(common_opt_def & interpreter_opt_def)

		abort(1)
	end if


	finalize_command_line(opts)
end procedure
