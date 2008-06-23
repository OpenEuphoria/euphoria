include unittest.e
include machine.e
warning_file(-1)
integer fn
override procedure puts(integer channel,sequence text)
eu:puts(fn,text)
end procedure
fn = open("override.txt","w")
puts(fn,"This is another test")
close(fn)
fn = open("override.txt","r")
test_equal("Standard version used",gets(fn),"This is another test")
test_equal("Anything else?",gets(fn),-1)
close(fn)
include filesys.e
fn=delete_file("override.txt")

test_embedded_report()
