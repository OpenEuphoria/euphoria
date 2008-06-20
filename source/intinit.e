-- (c) Copyright 2007 Rapid Deployment Software - See License.txt
--
-- Common initialization (command line options)
include cominit.e
include error.e
include sequence.e

global procedure intoptions()
-- set translator command-line options  
	integer i, option
	sequence uparg
	
	-- put file first, strip out the options
	i = 3
	while i <= Argc do
		if Argv[i][1] = '-' then
			uparg = upper(Argv[i])
			option = find( uparg, COMMON_OPTIONS )
			if option then
				common_options( option, i )
			else
				Warning("unknown option: " & Argv[i],0)
			end if
			add_switch( Argv[i], 0 )
			-- delete "-" option from the list of args */
			Argc -= 1
			for j = i to Argc do
				Argv[j] = Argv[j+1]
			end for
		else 
			return -- non "-" items are assumed to be the source file
		end if      
	end while
end procedure

