
include std/unittest.e
include std/filesys.e
include std/io.e
include std/sequence.e

chdir("include_subdir/foo")

ifdef EUI then
	-- interpret only
	sequence eui = command_line()

	system( eui[1] & " -batch foo.ex > test.err", 2)


	integer success = 0
	integer fn = open("test.err", "r")
	if fn != -1 then
		sequence lines = flatten(read_lines(fn))
		close(fn)
		if equal("Success.", lines) then
			success = 1
		end if
	end if

	test_true("include relying on main file path when in different subdirectory", success)

end ifdef
test_report()
