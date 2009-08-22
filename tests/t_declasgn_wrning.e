include std/filesys.e
include std/unittest.e

ifdef EC then
	-- don't bother with translator for this test, because the warning file
	-- is already gone
elsedef
	integer fn = open("warning.lst","r")
	test_true("warning file generated", fn >= 0)
	if fn >= 0 then
		test_equal("with warning += #1","Warning ( short_circuit ):\n", gets(fn))
		ifdef DOS32 then
			if find(gets(fn), {
				"\t<0219>:: t_declasgn.e:16 - call to f() might be short-circuited\n",
				"\t<0219>:: t_declas.e:16 - call to f() might be short-circuited\n",
				"\t<0219>:: T_DECLAS.E:16 - call to f() might be short-circuited\n",
				"\t<0219>:: T_DECL~1.E:16 - call to f() might be short-circuited\n",
				"\t<0219>:: T_DECL~2.E:16 - call to f() might be short-circuited\n"
			}) then
				test_pass("with warning += #2")
			else
				test_fail("with warning += #2")
			end if
		elsedef
			test_equal("with warning += #2","\t<0219>:: t_declasgn.e:16 - call to f() might be short-circuited\n", gets(fn))
		end ifdef
		
		test_equal("warning() #1","Warning ( custom ):\n", gets(fn))
		test_equal("warning() #2","\tUseless code\n", gets(fn))
		if find("-STRICT", option_switches()) != 0 then
			test_equal("with warning sc += #1","Warning ( short_circuit ):\n", gets(fn))
			ifdef DOS32 then
				if find(gets(fn), {
					"\t<0219>:: t_declasgn.e:31 - call to f() might be short-circuited\n",
					"\t<0219>:: t_declas.e:31 - call to f() might be short-circuited\n",
					"\t<0219>:: T_DECLAS.E:31 - call to f() might be short-circuited\n",
					"\t<0219>:: T_DECL~1.E:31 - call to f() might be short-circuited\n",
					"\t<0219>:: T_DECL~2.E:31 - call to f() might be short-circuited\n"
				}) then
					test_pass("with warning sc += #2")
				else
					test_fail("with warning sc += #2")
				end if
			elsedef
				test_equal("with warning sc += #2","\t<0219>:: t_declasgn.e:31 - call to f() might be short-circuited\n", gets(fn))
			end ifdef
		end if
		
		test_equal("with warning += #3","Warning ( not_used ):\n", gets(fn))
		ifdef DOS32 then
			if find(gets(fn), {
				"\t<0229>:: t_declasgn.e - module variable 'n0' is not used\n",
				"\t<0229>:: t_declas.e - module variable 'n0' is not used\n",
				"\t<0229>:: T_DECLAS.E - module variable 'n0' is not used\n",
				"\t<0229>:: T_DECL~1.E - module variable 'n0' is not used\n",
				"\t<0229>:: T_DECL~2.E - module variable 'n0' is not used\n"
			}) then
				test_pass("with warning += #4")
			else
				test_fail("with warning += #4")
			end if
		elsedef
			test_equal("with warning += #4","\t<0229>:: t_declasgn.e - module variable 'n0' is not used\n", gets(fn))
		end ifdef
		test_equal("with warning -=", -1, gets(fn))
		
		close(fn)
		fn=delete_file("warning.lst")
	
	end if
end ifdef
test_report()

