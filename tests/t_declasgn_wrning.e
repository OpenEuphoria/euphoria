include std/filesys.e
include std/unittest.e

ifdef EC then
	-- don't bother with translator for this test, because the warning file
	-- is already gone
else

integer fn = open("warning.lst","r")
test_true("warning file generated", fn >= 0)
test_equal("with warning += #1","Warning ( short_circuit ):\n", gets(fn))
ifdef DOS32 then
	if find(gets(fn), {
		"\tt_declasgn.e:14 - call to f() might be short-circuited\n",
		"\tt_declas.e:14 - call to f() might be short-circuited\n",
		"\tT_DECLAS.E:14 - call to f() might be short-circuited\n",
		"\tT_DECL~1.E:14 - call to f() might be short-circuited\n",
		"\tT_DECL~2.E:14 - call to f() might be short-circuited\n"
	}) then
		test_pass("with warning += #2")
	else
		test_fail("with warning += #2")
	end if
else
	test_equal("with warning += #2","\tt_declasgn.e:14 - call to f() might be short-circuited\n", gets(fn))
end ifdef
test_equal("warning() #1","Warning ( custom ):\n", gets(fn))
test_equal("warning() #2","\tUseless code\n", gets(fn))
test_equal("with warning += #3","Warning ( not_used ):\n", gets(fn))
ifdef DOS32 then
	if find(gets(fn), {
		"\tlocal variable n0 in t_declasgn.e is not used\n",
		"\tlocal variable n0 in t_declas.e is not used\n",
		"\tlocal variable n0 in T_DECLAS.E is not used\n",
		"\tlocal variable n0 in T_DECL~1.E is not used\n",
		"\tlocal variable n0 in T_DECL~2.E is not used\n"
	}) then
		test_pass("with warning += #4")
	else
		test_fail("with warning += #4")
	end if
else
	test_equal("with warning += #4","\tlocal variable n0 in t_declasgn.e is not used\n", gets(fn))
end ifdef
test_equal("with warning -=", -1, gets(fn))

close(fn)
fn=delete_file("warning.lst")

end ifdef
test_report()

