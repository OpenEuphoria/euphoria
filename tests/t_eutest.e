-- who tests the unit tester...

include std/unittest.e
include std/filesys.e

-- doesn't make any sense to bother translating this...
ifdef EUI then
sequence eutest = ".." & SLASH &".." & SLASH & "source" & SLASH & "eutest.ex"
sequence incdir = ".." & SLASH & ".." & SLASH & "include"
sequence exe    = command_line()
exe = exe[1]

if not file_exists(exe) then
	exe = locate_file(exe, getenv("PATH"))
end if

sequence files = dir( "eutest" & SLASH & "t_*.e" )

chdir( "eutest" )
for i = 1 to length( files ) do
	
	integer result = system_exec( sprintf("%s -i %s %s -exe \"%s\" -verbose %s", 
		{exe, incdir, eutest, exe, files[i][D_NAME]}), 2 )

	integer expected = file_exists(	files[i][D_NAME] & ".fail")
	test_equal( sprintf("eutest %s", {files[i][D_NAME]}), expected = 0, result = 0 )
	
end for

puts(1, "t_eutest summary:\n")
set_test_verbosity( TEST_SHOW_ALL )
end ifdef

test_report()
