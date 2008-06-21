include filesys.e
include unittest.e

integer fn
fn = open("warning.lst","r")
test_equal("warning file generated",1,fn>=0)
test_equal("with warning += #1",gets(fn),
			"Warning: t_declasgn.e:11 - call to f() might be short-circuited\n")
test_equal("Sarning +=",gets(fn),"Warning: Useless code\n")
test_equal("with warning += #2",gets(fn),"Warning: local variable n0 in t_declasgn.e is not used\n")
test_equal("with warning -=",gets(fn),-1)
close(fn)
fn=delete_file("warning.lst")
test_embedded_report()
