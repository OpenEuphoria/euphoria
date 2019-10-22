include std/unittest.e
include std/filesys.e
include std/io.e
include std/utils.e

constant full_cl = command_line()
constant exe     = full_cl[1]
puts(1, exe & 10)
constant build_dir = pathname(exe)
puts(1, build_dir & 10)
constant proposed_return15 = build_dir & SLASH & "return15.exe"
puts(1,proposed_return15 & 10)
constant return15_in_same_dir_as_eui = file_exists(proposed_return15)

test_true("return15.exe was found", return15_in_same_dir_as_eui)
constant return15exe = proposed_return15
test_equal("Program that returns 15", 15, system_exec( sprintf("..\\source\\build\\return15.exe", {}), 2 ))
		
test_report()