include file.e
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


sequence fullname, pname, fname, fext, nl, driveid
integer sep

ifdef UNIX then
    fullname = "/opt/euphoria/docs/readme.txt"
    pname = "/opt/euphoria/docs"
    sep = '/'
    nl = "\n"
    driveid = ""
else
    fullname = "C:\\EUPHORIA\\DOCS\\readme.txt"
    pname = "\\EUPHORIA\\DOCS"
    sep = '\\'
    nl = "\r\n"
    driveid = "C"
end ifdef

fname = "readme"
fext = "txt"

test_equal("pathinfo() fully qualified path", {pname, fname & '.' & fext, fname, fext, driveid},
    pathinfo(fullname))
test_equal("pathinfo() no extension", {pname, fname, fname, "", ""},
    pathinfo(pname & PATHSEP & fname))
test_equal("pathinfo() no dir", {"", fname & '.' & fext, fname, fext, ""}, pathinfo(fname & "." & fext))
test_equal("pathinfo() no dir, no extension", {"", fname, fname, "", ""}, pathinfo("readme"))

test_equal("dirname() full path", pname, dirname(fullname))
test_equal("dirname() filename only", "", dirname(fname & "." & fext))

test_equal("filename() full path", fname & "." & fext, filename(fullname))
test_equal("filename() filename only", fname & "." & fext, filename(fname & "." & fext))
test_equal("filename() filename no extension", fname, filename(fname))

test_equal("fileext() full path", fext, fileext(fullname))
test_equal("fileext() filename only", fext, fileext(fullname))
test_equal("fileext() filename no extension", "", fileext(fname))

test_equal("PATHSEP", sep, PATHSEP)
test_equal("NL", nl, NL)

test_report()

