-- (c) Copyright 2007 Rapid Deployment Software - See License.txt
--
-- Common initialization (command line options)

include global.e
include pathopen.e

sequence switches, switch_cache
switches = {}
switch_cache = {}

-- These flags are available for both the interpreter and translator
global constant COMMON_OPTIONS = {
	"-C",    -- specify a euinc.conf file
	"-I",    -- specify a directory to search for include files
	"-D",    -- define a word
	"-BATCH",-- batch processing, do not "Press Enter" on error
	"-TEST", -- do not execute, only test syntax
	"-STRICT", -- enable all warnings (lint option)
	"-W",    -- defines warning level
	"-X",    -- defines warning level by exclusion
	"-WF",   -- defines the file to which the warnings will go instead of stderr
	"-?",    -- Display 'usage' help
	"-HELP"  -- Display 'usage' help
}

global enum
	EUINC_OPTION,  -- -conf
	INCDIR_OPTION, -- -include dirs
	DEFINE_OPTION, -- ifdef defines
	BATCH_OPTION,  -- batch processing, do not "Press Enter" on error
	TEST_OPTION,   -- do not execute, only test syntax
	STRICT_OPTION,   -- enable all warnings
	WARNING_OPTION, -- startup warning level
	WARNING_EXCLUDE_OPTION, -- startup warning level by exclusion
	WARNING_FILE_OPTION,	-- warning file name
	HELP_OPTION,  -- Show command line usage
	HELP2_OPTION  -- Show command line usage

constant COMMON_PARAMS = {
	EUINC_OPTION,
	INCDIR_OPTION,
	DEFINE_OPTION, -- ifdef defines
	0,  -- batch processing, do not "Press Enter" on error
	0,   -- do not execute, only test syntax
	0,   -- enable all warnings
	WARNING_OPTION, -- startup warning level
	WARNING_EXCLUDE_OPTION, -- startup warning level by exclusion
	WARNING_FILE_OPTION,	-- warning file name
	0,   -- COmmand line usage
	0   -- COmmand line usage
}


-- s = the text of the switch
-- deferred:  1 = it's an argument for the switch, and won't be added
--                to the list of switches until the next non-deferred
--                switch is passed
global procedure add_switch( sequence s, integer deferred )
	if deferred then
		switch_cache = append( switch_cache, s )
	else
		switches = append( switches, s )
		switches &= switch_cache
		switch_cache = {}
	end if
end procedure

global function get_switches()
	return switches
end function

global procedure move_args( integer start )
	Argv[start .. Argc - 1] = Argv[start + 1 .. Argc ]
	Argc -= 1
end procedure

integer usage_shown = 0
global procedure show_usage()
	if usage_shown = 0 then
		puts(1,
##
____________
            Euphoria Interpreter Usage: Command line arguments ...
            -C <filename>    -- specify a configuration file
            -I <dirname>     -- specify a directory to search for include files
            -D <word>        -- define a word
            -BATCH           -- batch processing, do not "Press Enter" on error
            -TEST            -- do not execute, only test syntax
            -STRICT          -- enable all warnings (lint option)
            -W <warningname> -- defines warning level
            -X <warningname> -- defines warning level by exclusion
            -WF <warnfile>   -- defines the file to which the warnings will go
            -? or -HELP      -- Display this 'usage' help

		#)
		usage_shown = 1
	end if
end procedure

integer option_W
option_W=0
global procedure common_options( integer option, integer ix )
	integer n
	object param

	-- we only need to remove our extra options
	param = {}

	if COMMON_PARAMS[option] != 0 then
		if ix < Argc then
			param = Argv[ix+1]
			add_switch( param, 1 )
			move_args( ix+1 )
		else
			Warning("missing option parameter for: %s" , cmdline_warning_flag, {Argv[ix]})
			show_usage()
		end if
	end if

	switch option do
	case  EUINC_OPTION:
		sequence new_args = load_euinc_conf( param )
		Argv = Argv[1 .. ix] & new_args & Argv[ix + 1 .. $]
		Argc += length(new_args)
		break

	case  INCDIR_OPTION:
		add_include_directory( param )
		break

	case  DEFINE_OPTION:
		OpDefines &= {param}
		break

	case  TEST_OPTION:
		test_only = 1
		batch_job = 1
		break

	case  BATCH_OPTION:
		batch_job = 1
		break

	case  HELP_OPTION:
	case  HELP2_OPTION:
		show_usage()
		break

	case  WARNING_OPTION:
		n = find(param ,warning_names)
		if n != 0 then
			if option_W = 1 then
				OpWarning = or_bits(OpWarning, warning_flags[n])
			else
				option_W = 1
				OpWarning = warning_flags[n]
			end if
			prev_OpWarning = OpWarning
		end if
		break

	case  WARNING_EXCLUDE_OPTION:
		n = find(param, warning_names)
		if n != 0 then
			if option_W = -1 then
				OpWarning = and_bits(OpWarning, not_bits(warning_flags[n]))
			else
				option_W = -1
				OpWarning = strict_warning_flag - warning_flags[n]
			end if
			prev_OpWarning = OpWarning
		end if
		break

	case  STRICT_OPTION:
		Strict_is_on = 1
		break

	case  WARNING_FILE_OPTION:
		TempWarningName = param
		break

	end switch

end procedure
