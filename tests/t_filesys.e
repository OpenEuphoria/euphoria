include std/filesys.e
include std/unittest.e

sequence fullname, pname, fname, fext, crlf, driveid
integer sep

ifdef UNIX then
    fullname = "/opt/euphoria/docs/readme.txt"
    pname = "/opt/euphoria/docs"
    sep = '/'
    crlf = "\n"
    driveid = ""
elsedef
    fullname = "C:\\EUPHORIA\\DOCS\\readme.txt"
    pname = "\\EUPHORIA\\DOCS"
    sep = '\\'
    crlf = "\r\n"
    driveid = "C"
end ifdef

fname = "readme"
fext = "txt"

test_equal("pathinfo() fully qualified path", {pname, fname & '.' & fext, fname, fext, driveid},
    pathinfo(fullname))
test_equal("pathinfo() no extension", {pname, fname, fname, "", ""},
    pathinfo(pname & SLASH & fname))
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

test_equal("defaultext #1", "abc.def", defaultext("abc", "def"))
test_equal("defaultext #2", "abc.xyz", defaultext("abc.xyz", "def"))
test_equal("defaultext #3", "abc.xyz" & SLASH & "abc.xyz", defaultext("abc.xyz" & SLASH & "abc.xyz", "def"))
test_equal("defaultext #4", "abc.xyz" & SLASH & "abc.def", defaultext("abc.xyz" & SLASH & "abc", "def"))


test_equal("SLASH", sep, SLASH)
test_equal("CRLF", crlf, CRLF)

test_equal("file_exists #1", 1, file_exists("t_filesys.e"))
test_equal("file_exists #2", 0, file_exists("nononononono.txt"))

test_report()

