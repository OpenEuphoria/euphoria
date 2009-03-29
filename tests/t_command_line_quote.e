-- test that indeed the function quote_command_line(s) returns a value that can be passed to
-- system() so that in the resulting process command_line() will return the original s from its
-- parent process.
include std/unittest.e
include std/io.e
include std/filesys.e
include std/pretty.e
include std/get.e
include std/os.e

ifdef UNIX then
constant command_arrays = { { "1", "2", "3" }, { "1 2", "3" }, { "\"1 2\" 3" },
				{"hi there", "bye" },
				{ "This is the \"best\" first sentence.", 
				   "This is another sentence." }
							
			}
elsedef
constant command_arrays = { { "1", "2", "3" }, { "1 2", "3" }, 
				{"hi there", "bye" },
				{ "This is the best first sentence.", 
				   "This is another sentence." }
			}
end ifdef


sequence cmds
sequence interpreter
cmds = command_line()
-- I have no logic for finding the interpreter here for the case
-- of translated code and this method 
-- below is a fork bomb when run as compiled translated C code. 
ifdef not EC then

    integer xl = length(command_arrays)
	interpreter = cmds[1]	
	for i = 1 to xl do
 		integer fd
 		sequence get_data
 		object x
 		sequence cmdline
 		cmds = { interpreter,
 			"print_command_line.ex" } & command_arrays[i]
		cmdline = build_commandline( splice( cmds, option_switches(), 2 ) )
 		system( cmdline, 2 )
 		fd = open( "command_line.txt", "r" )
 		if fd != -1 then
 			 get_data = get(fd)
 			 x = get_data[2]
 			 if get_data[1] = GET_SUCCESS then
 				test_equal( sprintf("command_line_quote(%s)",{pretty_sprint(command_arrays)}), cmds, x )
 			 end if
 			 close(fd)
 		end if
 		if delete_file("command_line.txt") then end if

	end for
end ifdef
test_report()
	 
