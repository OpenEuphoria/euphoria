include std/dll.e
include std/unittest.e

-- Tests to ensure dll.e is parsed correctly

test_pass("std/dll.e parses correctly")

atom fh = open_dll({ "nonamedll.dll", "user32.dll", "libc.so", "libc.so.1", "libc.so.2",
	"libc.so.3", "libc.so.4", "libc.so.5", "libc.so.6", "libc.so.7", "libc.so.8" })

test_true("open_dll with sequence of filenames", not fh = 0)

test_report()
