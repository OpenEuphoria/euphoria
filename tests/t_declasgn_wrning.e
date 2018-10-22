include std/filesys.e
include std/unittest.e

ifdef EUC or EUB then
	-- don't bother with translator or binding for this test, because the warning file
	-- is already gone
elsedef
	integer fn = open("warning.lst","r")
	test_true("warning file generated", fn >= 0)
	if fn >= 0 then
		test_equal("with warning += #1","Warning { short_circuit }:\n", gets(fn))
		test_equal("with warning += #2","\t<0219>:: t_declasgn.e:17 - call to f() might be short-circuited\n", gets(fn))
		
		test_equal("warning() #1","Warning { custom }:\n", gets(fn))
		test_equal("warning() #2","\tUseless code\n", gets(fn))
		if find("-STRICT", option_switches()) != 0 then
			test_equal("with warning sc += #1","Warning { short_circuit }:\n", gets(fn))
			test_equal("with warning sc += #2","\t<0219>:: t_declasgn.e:31 - call to f() might be short-circuited\n", gets(fn))
		end if
		
		test_equal("with warning += #3","Warning { not_used }:\n", gets(fn))
		test_equal("with warning += #4","\t<0228>:: t_declasgn.e - module constant 'cmd' is not used\n", gets(fn))
		test_equal("with warning += #3","Warning { not_used }:\n", gets(fn))
		test_equal("with warning += #4","\t<0229>:: t_declasgn.e - module variable 'n0' is not used\n", gets(fn))
		test_equal("with warning -=", -1, gets(fn))
		
		close(fn)
		fn=delete_file("warning.lst")
	
	end if
end ifdef
test_report()

