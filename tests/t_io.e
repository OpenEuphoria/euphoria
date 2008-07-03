include io.e
include unittest.e

-- TODO: add more tests

object data, tmp

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
test_equal("read_file() #1", 253, length(data))
test_equal("read_file() #2", "alter this file", data[51..65])

tmp = open("file.txt", "r")
test_equal("where() #1", 0, where(tmp))
data = read_file(tmp)
test_equal("read_file() #1", 253, length(data))
test_equal("read_file() #2", "alter this file", data[51..65])
test_equal("where() #2", 253, where(tmp))
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

test_report()

