include std/io.e
include std/filesys.e
include std/unittest.e
include std/text.e
include std/sequence.e

-- TODO: add more tests

object data, tmp

constant test_file_data = `
This is a file used for unit tests. Please
do not alter this file. Tests require this
file to be of a known content.

Changing it's content will cause unit tests
to believe they have failed when there may
in fact be nothing wrong with them.

Thank You!

`
constant data_length = length(test_file_data)
constant new_line_count = 9
write_file("file.txt", test_file_data, DOS_TEXT)

data = read_lines("file.txt")
tmp = set_test_abort(1)
test_equal("read file.txt", 1, sequence(data))
tmp = set_test_abort(tmp)

test_equal("read_lines() #1", 9, length(data))
test_equal("read_lines() #2", 42, length(data[1]))
test_equal("read_lines() #3", "This is a file used for unit tests. Please", data[1])
test_equal("read_lines() #4", "Thank You!", data[9])

tmp = open("file.txt", "r")
data = read_lines(tmp)
test_equal("read_lines() #5", 9, length(data))
test_equal("read_lines() #6", 42, length(data[1]))
test_equal("read_lines() #7", "This is a file used for unit tests. Please", data[1])
test_equal("read_lines() #8", "Thank You!", data[9])
close(tmp)

data = read_file("file.txt")
test_equal("read_file() #1", data_length+new_line_count, length(data))
test_equal("read_file() #2", "alter this file", data[52..66])

tmp = open("file.txt", "rb")
test_equal("where() #1", 0, where(tmp))
data = read_file(tmp)
test_equal("read_file() #1a", data_length+new_line_count, length(data))
test_equal("read_file() #2a", "alter this file", data[52..66])
test_equal("where() #2", data_length+new_line_count, where(tmp))
close(tmp)

tmp = open("file.txt", "r")
test_equal("where() #1b", 0, where(tmp))
data = read_file(tmp) -- BINARY_MODE even though file was opened in 'text' mode.
ifdef WINDOWS then
	test_equal("read_file() #1b", data_length, length(data))
	test_equal("read_file() #2b", "alter this file", data[51..65])
elsedef
	test_equal("read_file() #1b", data_length+new_line_count, length(data))
	test_equal("read_file() #2b", "alter this file", data[52..66])
end ifdef

test_equal("where() #2b", data_length+new_line_count, where(tmp))
close(tmp)

test_equal("write_file() filename", 1, write_file("fileb.txt", "Hello World"))
test_equal("write_file() read back", "Hello World", read_file("fileb.txt"))

test_equal("write_lines() filename", 1, write_lines("fileb.txt", {"Goodbye", "World"}))
test_equal("write_file() read back", {"Goodbye", "World"}, read_lines("fileb.txt"))

tmp = open("fileb.txt", "wb")
test_equal("write_file() file handle", 1, write_file(tmp, "Hello World"))
close(tmp)
test_equal("write_file() read back", "Hello World", read_file("fileb.txt"))

tmp = open("fileb.txt", "wb")
test_equal("write_lines() file handle", 1, write_lines(tmp, {"Goodbye", "World"}))
close(tmp)
test_equal("write_file() read back", {"Goodbye", "World"}, read_lines("fileb.txt"))

test_equal("write_lines() filename #2", 1, write_lines("fileb.txt", {"Hello World"}))
test_equal("append_lines() ", 1, append_lines("fileb.txt", {"I'm back"}))
test_equal("append_lines() read back", {"Hello World", "I'm back"}, read_lines("fileb.txt"))

sequence testdata_raw = "test\r\ndata\r\nfile\r\nLastLine" & 26 & "EOF"
-- The text formats of the above raw data exclude characters from the EOF marker,
-- and always have a EOL marker on last line.
sequence testdata_dos = "test\r\ndata\r\nfile\r\nLastLine\r\n"
sequence testdata_unix = "test\ndata\nfile\nLastLine\n"

-- Data written in binary mode should be unchanged when read back in binary mode.
write_file("filec.txt", testdata_raw, BINARY_MODE) -- Write out as raw data.
test_equal("read file binary #1a", testdata_raw, read_file("filec.txt", BINARY_MODE))
write_file("filec.txt", testdata_unix, BINARY_MODE) -- Write out as raw data.
test_equal("read file binary #1b", testdata_unix, read_file("filec.txt", BINARY_MODE))
write_file("filec.txt", testdata_dos, BINARY_MODE) -- Write out as raw data.
test_equal("read file binary #1c", testdata_dos, read_file("filec.txt", BINARY_MODE))

-- Test the default mode value, which should be BINARY
write_file("filec.txt", testdata_raw) -- Write out as raw data.
test_equal("read/write file default should be binary", testdata_raw, read_file("filec.txt"))

-- A file read in TEXT_MODE should always be in UNIX format regardless of the current opsys.
test_equal("read file text #1", testdata_unix, read_file("filec.txt", TEXT_MODE))

write_file("filea.txt", testdata_raw, TEXT_MODE) -- Write out as current o/s text data.
write_file("fileb.txt", testdata_unix, TEXT_MODE) -- Write out as current o/s text data.
write_file("filec.txt", testdata_dos, TEXT_MODE) -- Write out as current o/s text data.

ifdef WINDOWS then
	sequence res_text = testdata_dos
elsifdef UNIX then
	sequence res_text = testdata_unix
elsedef
	sequence res_text = "unsupported op sys"
end ifdef
test_equal("read file binary #2a", res_text, read_file("filea.txt", BINARY_MODE))
test_equal("read file binary #2b", res_text, read_file("fileb.txt", BINARY_MODE))
test_equal("read file binary #2c", res_text, read_file("filec.txt", BINARY_MODE))

-- A file read in TEXT_MODE should be in UNIX format regardless of the current opsys.
test_equal("read file text #2", testdata_unix, read_file("filec.txt", TEXT_MODE))

-- Force output to be in UNIX format and use BINARY mode to see if that worked,
write_file("filec.txt", testdata_raw, UNIX_TEXT) -- Write out as Unix text data.
test_equal("write/read unix text #1", testdata_unix, read_file("filec.txt", BINARY_MODE))
write_file("filec.txt", testdata_dos, UNIX_TEXT) -- Write out as Unix text data.
test_equal("write/read unix text #2", testdata_unix, read_file("filec.txt", BINARY_MODE))
write_file("filec.txt", testdata_unix, UNIX_TEXT) -- Write out as Unix text data.
test_equal("write/read unix text #3", testdata_unix, read_file("filec.txt", BINARY_MODE))

-- Force output to be in DOS format and use BINARY mode to see if that worked,
write_file("filec.txt", testdata_raw, DOS_TEXT) -- Write out as DOS/Windows text data.
test_equal("write/read dos text #1", testdata_dos, read_file("filec.txt", BINARY_MODE))
write_file("filec.txt", testdata_unix, DOS_TEXT) -- Write out as DOS/Windows text data.
test_equal("write/read dos text #2", testdata_dos, read_file("filec.txt", BINARY_MODE))
write_file("filec.txt", testdata_dos, DOS_TEXT) -- Write out as DOS/Windows text data.
test_equal("write/read dos text #3", testdata_dos, read_file("filec.txt", BINARY_MODE))

-- Types
test_true("file_number #1", file_number(10))
test_false("file_number #2", file_number(-32))
test_false("file_number #3", file_number(-1))
test_true("file_position #1", file_position(0))
test_true("file_position #2", file_position(20930))
test_true("file_position #3", file_position(-1))
test_false("file_position #4", file_position(-203))
test_false("file_position #5", file_position(-2))
test_true("lock_type #1", lock_type(LOCK_SHARED))
test_true("lock_type #2", lock_type(LOCK_EXCLUSIVE))
test_false("lock_type #3", lock_type(20))

tmp = open( "file.txt", "r", 1 )
test_not_equal( "open file with auto close", -1, tmp )
delete(tmp)

tmp = open( "file.txt", "r", 1 )
test_not_equal( "open file with auto close after calling delete", -1, tmp )
tmp = 0

tmp = open( "file.txt", "r", 1 )
test_not_equal( "open file with auto close after deref closing", -1, tmp )
delete(tmp)

tmp = {}

sequence alt_tmp = {}

function test_proc(sequence aLine, integer line_no, object data)
	tmp &= aLine
	tmp &= '\n'
	
	alt_tmp = append(alt_tmp, format(data[1], {line_no, aLine}))
	
	return 0
end function

test_equal( "process lines #1", 0, process_lines("file.txt", routine_id("test_proc"), {"[1z:4] : [2]", 0}))
test_equal( "process lines #2", test_file_data, tmp)
tmp = split(test_file_data, '\n')
tmp = tmp[1..$-1] -- Strip off final empty sequence.
for i = 1 to length(tmp) do
	tmp[i] = sprintf("%04d : %s", {i, tmp[i]})
end for
test_equal( "process lines #3", tmp, alt_tmp)


-- OpenBSD allows seeking on STDIN, STDOUT and STDERR
ifdef not OPENBSD and not NETBSD then
	test_equal( "Seek STDIN",  1, seek(0, 0))
	test_equal( "Seek STDOUT", 1, seek(1, 0))
	test_equal( "Seek STDERR", 1, seek(2, 0))
end ifdef

integer fh

fh = open("file.txt", "r")
test_equal( "Seek opened file", 0, seek(fh, -1))
close(fh)
test_equal( "Seek closed file", 1, seek(fh, -1))

fh = open("file.txt", "ab")
test_equal( "Where on append mode file should be its length (binary)", data_length+new_line_count, where(fh))
close(fh)
fh = open("file.txt", "a")
test_equal( "Where on append mode file should be its length", data_length+new_line_count, where(fh))
close(fh)

fh = open("file.txt", "u")
test_equal( "Where on update mode file should be 0", 0, where(fh))
close(fh)

fh = open("file.txt", "ub")
test_equal( "Where on update mode file should be 0 (binary)", 0, where(fh))
close(fh)

delete_file("file.txt")
delete_file("filea.txt")
delete_file("fileb.txt")
delete_file("filec.txt")
test_report()

