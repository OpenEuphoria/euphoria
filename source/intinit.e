-- (c) Copyright 2007 Rapid Deployment Software - See License.txt
--
-- Common initialization (command line options)
include std/text.e

include global.e
include cominit.e
include error.e
include pathopen.e

global procedure intoptions()
-- set interpreter command-line options
	integer i, option
	sequence uparg

	object default_args = 0
	-- put file first, strip out the options

	i = 3
	if i > Argc then
		default_args = GetDefaultArgs()
		if length(default_args) > 0 then
			Argv = Argv[1.. i-1] & default_args & Argv[i .. Argc ]
			Argc += length(default_args)
		end if
	end if
	while i <= Argc do
		if Argv[i][1] = '-' then
			uparg = upper(Argv[i])
			option = find( uparg, COMMON_OPTIONS )
			if option then
				common_options( option, i )
			else
				show_usage()
				Warning("unknown option: %s" ,cmdline_warning_flag, {Argv[i]})
			end if
			add_switch( Argv[i], 0 )
			-- delete "-" option from the list of args */
			Argv[i .. Argc-1] = Argv[i+1 .. Argc ]
			Argc -= 1

		elsif atom(default_args) then
			default_args = GetDefaultArgs()
			if length(default_args) > 0 then
				Argv = Argv[1.. i-1] & default_args & Argv[i .. Argc ]
				Argc += length(default_args)
			end if

		else
			exit -- first non "-" item is assumed to be the source file
		end if
	end while

	if Strict_is_on then -- overrides any -W/-X switches
		OpWarning = all_warning_flag
		prev_OpWarning = OpWarning
	end if

end procedure

