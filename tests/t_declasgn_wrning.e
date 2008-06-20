include get.e
include unittest.e

test_equal("warning",1,prompt_number("\nWere the following warnings displayed, and only those:\n"&
"Warning: t_declasgn.e:9 - call to f() might be short-circuite?\n"&
"Warning: Useless code\n"&
"Warning: local variable n0 in t_declasgn.e is not used\n\n"&
"\n( 1 = Yes, 0 = No) :   ",{0,1}))

test_embedded_report()
