include std/unittest.e

include dll.e

test_pass("std/dll.e parses correctly")
constant files = { "nonamedll.dll", "user32.dll", "libc.so", "libc.so.1", "libc.so.2",
	"libc.so.3", "libc.so.4", "libc.so.5", "libc.so.6", "libc.so.7", "libc.so.8", "libc.dylib" }
atom fh = 0
for i = 1 to length( files ) do
	fh = open_dll( files[i] )
	if fh then
		exit
	end if
end for
test_true("open_dll", not fh = 0)

test_report()
