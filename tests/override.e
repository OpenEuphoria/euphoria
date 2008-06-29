include unittest.e
include error.e

warning_file(-1)

integer fn
override procedure puts(integer channel,sequence text)
	eu:puts(fn,text)
end procedure

fn = open("override.txt","w")
puts(fn,"This is another test")
close(fn)
