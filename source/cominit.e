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
	"-WF"    -- defines the file to which the warnings will go instead of stderr
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
	WARNING_FILE_OPTION	-- warning file name


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

global procedure move_args( integer start, integer args )
	Argc -= args
	for j = start to Argc do
		Argv[j] = Argv[j+args]
	end for

end procedure

integer option_W
option_W=0
global procedure common_options( integer option, integer ix )
	integer args, n
	-- we only need to remove our extra options
	args = 0

	switch option do
	case  EUINC_OPTION:
		if ix < Argc then
			load_euinc_conf( Argv[ix+1] )
			add_switch( Argv[ix+1], 1 )
			args += 1
		end if
		break

	case  INCDIR_OPTION:
		if ix < Argc then
			add_include_directory( Argv[ix+1] )
			add_switch( Argv[ix+1], 1 )
			args += 1
		end if
		break

	case  DEFINE_OPTION:
		if ix < Argc then
			OpDefines &= {Argv[ix+1]}
			add_switch(Argv[ix+1], 1)
			args += 1
		end if
		break

	case  TEST_OPTION:
		test_only = 1
		batch_job = 1
		break

	case  BATCH_OPTION:
		batch_job = 1
		break

	case  WARNING_OPTION:
		if ix < Argc then
			n = find(Argv[ix+1],warning_names)
			if n>0 then
				if option_W=1 then
					OpWarning = or_bits(OpWarning, warning_flags[n])
				else
					option_W = 1
					OpWarning = warning_flags[n]
				end if
				prev_OpWarning = OpWarning
			end if
			add_switch(Argv[ix+1], 1)
			args += 1
		end if
		break

	case  WARNING_EXCLUDE_OPTION:
		if ix < Argc then
			n = find(Argv[ix+1],warning_names)
			if n>0 then
				if option_W=-1 then
					OpWarning = and_bits(OpWarning, not_bits(warning_flags[n]))
				else
					option_W = -1
					OpWarning = strict_warning_flag - warning_flags[n]
				end if
				prev_OpWarning = OpWarning
			end if
			add_switch(Argv[ix+1], 1)
			args += 1
		end if
		break

	case  STRICT_OPTION:
		Strict_is_on = 1
		break

	case  WARNING_FILE_OPTION:
		if ix < Argc then
			TempWarningName = Argv[ix+1]
			add_switch(Argv[ix+1], 1)
			args += 1
		end if
		break
		
	end switch

	move_args( ix+1, args )

end procedure
