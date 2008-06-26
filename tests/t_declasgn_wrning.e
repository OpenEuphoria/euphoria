include filesys.e
include unittest.e

integer fn = open("warning.lst","r")

test_equal("warning file generated",1,fn>=0)
test_equal("with warning += #1","Warning ( short_circuit_warning ):\n",gets(fn))
test_equal("with warning += #2","\tt_declasgn.e:11 - call to f() might be short-circuited\n",gets(fn))
test_equal("warning() #1","Warning ( custom_warning ):\n",gets(fn))
test_equal("warning() #2","\tUseless code\n",gets(fn))
test_equal("with warning += #3","Warning ( not_used_warning ):\n",gets(fn))
test_equal("with warning += #4","\tlocal variable n0 in t_declasgn.e is not used\n",gets(fn))
test_equal("with warning -=",-1,gets(fn))

close(fn)
fn=delete_file("warning.lst")

test_embedded_report()

