include std/unittest.e
include std/error.e

warning_file(-1)

integer fn = open("override.txt","w")

override procedure puts(integer channel,sequence text)
	eu:puts(fn,"This is the new puts()!\n")
	eu:puts(fn,text)
end procedure

puts(fn,"This is a test")
close(fn)

fn = open("override.txt","r")
test_equal("Alternate version used", "This is the new puts()!\n", gets(fn))
test_equal("Task carried out", "This is a test\n", gets(fn))
close(fn)

include std/filesys.e
include override.e
fn = open("override.txt","r")
test_equal("Standard version used", "This is another test\n", gets(fn))
test_equal("Anything else?", -1, gets(fn))
close(fn)

fn=delete_file("override.txt")

test_report()






