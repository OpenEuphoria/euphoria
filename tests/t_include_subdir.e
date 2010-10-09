
include std/unittest.e
include std/filesys.e
include std/io.e
include std/sequence.e

chdir("include_subdir/foo")

ifdef EUC then
-- translated

system("euc foo.ex", 2)
system("./foo > test.err", 2)

elsedef
-- not translated

system("eui foo.ex > test.err", 2)

end ifdef

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

test_report()
