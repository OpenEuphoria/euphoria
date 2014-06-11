-- Test calling system_exec with quotes on parameters that contain spaces

include std/unittest.e
ifdef EUI then
	
	include std/io.e
	include std/filesys.e
	include std/pretty.e
	include std/get.e
	include std/cmdline.e
	
    constant test_dir = "t_system_exec spaces"
    constant test_prg = "spaced.ex"
    
    -- Simple Euphoria program which tries to open itself
    sequence prg_content = """    
atom fd = open("spaced.ex", "r")
if fd = -1 then
    abort(0)
end if
abort(1)
    """
    if not file_exists(test_dir) then
        assert("Create '" & test_dir & "' directory", create_directory(test_dir))
    end if

	sequence cmds = command_line()
    
    sequence interpreter = cmds[1]
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
    test_false("Should not fail to execute: " & test_cmd, system_exec(test_cmd))
    
    delete_file(interpreter_copy)
    delete_file(full_test_prg)
    remove_directory(test_dir)
end ifdef

test_report()
