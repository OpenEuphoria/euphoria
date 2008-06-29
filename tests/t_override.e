include unittest.e
include error.e

warning_file(-1)

integer fn = open("override.txt","w")

override procedure puts(integer channel,sequence text)
	eu:puts(fn,"This is the new puts()!\n")
	eu:puts(fn,text)
end procedure

puts(fn,"This is a test")
close(fn)

fn = open("override.txt","r")
test_equal("Alternate version used",gets(fn),"This is the new puts()!\n")
test_equal("Task carried out",gets(fn),"This is a test")
close(fn)

include filesys.e
include override.e
fn = open("override.txt","r")
test_equal("Standard version used",gets(fn),"This is another test")
test_equal("Anything else?",gets(fn),-1)
close(fn)

fn=delete_file("override.txt")

test_report()






