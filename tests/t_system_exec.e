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
	
    constant test_dir = "t_system_exec spaces"
    constant test_prg = "spaced.ex"
	sequence cmds = command_line()
    sequence interpreter = cmds[1]
    sequence prg_content = """
    
--include std/io.e
atom fd = open("spaced.ex", "r")
puts(1, "FD:" & fd)
if fd = -1 then
    abort(0)
end if
abort(1)
    
    """
    if not file_exists(test_dir) then
        assert("Could not create '" & test_dir & "' directory", create_directory(test_dir),)
    end if
    sequence interpreter_copy = join_path({test_dir, filename(interpreter)})
    interpreter_copy = interpreter_copy[2..$]
    
    if not file_exists(interpreter_copy) then
        assert("Copy interpreter", copy_file(interpreter, test_dir))
    end if
    
    sequence full_test_prg = join_path({test_dir, test_prg})
    full_test_prg = full_test_prg[2..$]
    atom fd = open(full_test_prg, "w")
    puts(fd, prg_content)
    close(fd)
    
    sequence test_cmd = "\"" & interpreter_copy & "\" \"" & full_test_prg & "\""
    puts(1, test_cmd & "\n")
    test_false("Should not fail to execute: " & test_cmd, system_exec(test_cmd))
end ifdef

test_report()
