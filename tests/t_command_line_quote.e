-- test that indeed the function quote_command_line(s) returns a value that can be passed to
-- system() so that in the resulting process command_line() will return the original s from its
-- parent process.

-- I have no logic for finding the interpreter here for the case
-- of translated code and this method 
-- below is a fork bomb when run as compiled translated C code. 

include std/unittest.e
ifdef EUI then
	
	include std/io.e
	include std/filesys.e
	include std/pretty.e
	include std/get.e
	include std/cmdline.e
	
	constant command_arrays = { 
		{ "1", "2", "3" }, 
		{ "1 2", "3" }, 
		{ "\"1 2\" 3" },
		{"hi there", "bye" },
		{ "This is the \"best\" first sentence.", "This is another sentence." },							
		{ "1", "2", "3" }, 
		{ "1 2", "3" }, 
		{"hi there", "bye" },
		{ "This is the best first sentence.", "This is another sentence." },
		{ "C:\\Program Files\\FOOFT\\FOOFT.exe", "-send", 
		  "C:\\Documents and Settings\\Charles Wallace\\A Wrinkle In Time.txt", 
		  "MY FRIEND" },
		$
	}
	
	for i = 2 to length(command_arrays) do
		sequence cmds = command_line()
		sequence interpreter = cmds[1]
		integer fd
		sequence get_data
		object x
		sequence cmdline
		
		cmds = { interpreter, "print_command_line.ex" } & command_arrays[i]
		
		cmdline = build_commandline( splice( cmds, option_switches(), 2 ) )
		ifdef WINDOWS then
			system(cmdline)
		elsedef
			system_exec(cmdline, 2)
		end ifdef
		sequence lines = read_lines("command_line.txt")
	
		if length(lines) != length(command_arrays[i]) then
			test_fail(sprintf("command line quote - differing lines, %d read, %d sent", {
				length(lines), length(command_arrays[i]) }))
		else
			for j = 1 to length(lines) do
				test_equal(sprintf("command line quote %d/%d", { i, j }), 
					command_arrays[i][j], lines[j])
			end for
		end if
		
		delete_file("command_line.txt")
	end for
end ifdef

test_report()
