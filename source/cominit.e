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
	"-C",  -- specify a euinc.conf file
	"-I",  -- specify a directory to search for include files
        "-D"  -- define a word
	},
    EUINC_OPTION = 1,   -- -conf
    INCDIR_OPTION = 2,   -- -i
    DEFINE_OPTION = 3

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

procedure move_args( integer start, integer args )
    Argc -= args
    for j = start to Argc do
    	Argv[j] = Argv[j+args]
    end for
    
end procedure


global procedure common_options( integer option, integer ix )
    integer args
    -- we only need to remove our extra options
    args = 0

    if option = EUINC_OPTION then
	if ix < Argc then
	    load_euinc_conf( Argv[ix+1] )
	    add_switch( Argv[ix+1], 1 )
	    args += 1
	end if
    	
    elsif option = INCDIR_OPTION then
	if ix < Argc then
	    add_include_directory( Argv[ix+1] )
	    add_switch( Argv[ix+1], 1 )
	    args += 1
	end if

    elsif option = DEFINE_OPTION then
        if ix < Argc then
            OpDefines &= {Argv[ix+1]}
            args += 1
        end if
    end if

    move_args( ix+1, args )
    
end procedure

