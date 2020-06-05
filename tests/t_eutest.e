-- who tests the unit tester...

include std/unittest.e
include std/filesys.e as fs
include std/io.e
include std/utils.e

constant diff_style_output_data = 
"""<td colspan=2><span class=normal>"Men are from </span class=normal><span class=missing>Mar</span class=missing><span class=added>Venu</span class=added><span class=normal>s.  Women are from </span class=normal><span class=missing>Venu</span class=missing><span class=added>Mar</span class=added><span class=normal>s."</span class=normal></td>"""


-- doesn't make any sense to bother shrouding, binding or translating this...
ifdef EUI then
constant eutest = ".." & SLASH &".." & SLASH & "source" & SLASH & "eutest.ex"
constant incdir = ".." & SLASH & ".." & SLASH & "include"
constant cl    = command_line()
constant exe = canonical_path(cl[1])

constant files = dir( "eutest" & SLASH & "t_*.e" )

chdir( "eutest" )
for i = 1 to length( files ) do
	sequence file_name = files[i][D_NAME]
	integer expected = file_exists(	file_name & ".fail")
	integer result = system_exec( sprintf("%s -i %s %s -exe \"%s\" %s -verbose %s", 
		{exe, incdir, eutest, exe, iif(expected,"-log",""), file_name}), 2 )

	test_equal( sprintf("eutest %s", {file_name}), expected = 0, result = 0 )
	if equal("t_got_different_string.e", file_name) then
		-- special handling:  Let us test that diff strings are created when 
		-- the test data is processed
		result = system_exec( sprintf("%s -i %s %s -process-log -html -html-file %s", 	
		{exe, incdir, eutest, fs:filebase(file_name) & ".html"}), 2)
	        object data = read_file("t_got_different_string.html")
		if result = 0 and sequence(data) and match(diff_style_output_data, data) then
			test_pass("eutest difference notation used for HTML test result")	
		else
			test_pass(
			"eutest incorrect or missing difference notation for HTML test result") 
		end if
	end if
end for

puts(1, "t_eutest summary:\n")
set_test_verbosity( TEST_SHOW_ALL )
end ifdef

test_report()
