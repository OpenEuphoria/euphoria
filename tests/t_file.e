include file.e
include unittest.e

setTestModuleName("file.e")

-- TODO: add more tests

object data, tmp

data = readlines("file.txt")
testEqual("readlines() #1", 7, length(data))
testEqual("readlines() #2", 42, length(data[1]))
testEqual("readlines() #3", "This is a file used for unit tests. Please", data[1])
testEqual("readlines() #4", "Thank You!", data[7])

tmp = open("file.txt", "r")
data = readlines(tmp)
testEqual("readlines() #5", 7, length(data))
testEqual("readlines() #6", 42, length(data[1]))
testEqual("readlines() #7", "This is a file used for unit tests. Please", data[1])
testEqual("readlines() #8", "Thank You!", data[7])
close(tmp)

data = readfile("file.txt")
testEqual("readfile() #1", 253, length(data))
testEqual("readfile() #2", "alter this file", data[51..65])

tmp = open("file.txt", "r")
data = readfile(tmp)
testEqual("readfile() #1", 253, length(data))
testEqual("readfile() #2", "alter this file", data[51..65])
close(tmp)

sequence fullname, pname, fname, fext
integer sep

if platform() = DOS32 or platform() = WIN32 then
    fullname = "C:\\EUPHORIA\\DOCS\\readme.txt"
    pname = "C:\\EUPHORIA\\DOCS"
    sep = '\\'
else
    fullname = "/opt/euphoria/docs/readme.txt"
    pname = "/opt/euphoria/docs"
    sep = '/'
end if

fname = "readme"
fext = "txt"

testEqual("pathinfo() fully qualified path", {pname, fname, fext},
    pathinfo(fullname))
testEqual("pathinfo() no extension", {pname, fname, ""},
    pathinfo(pname & PATHSEP & fname))
testEqual("pathinfo() no dir", {"", fname, fext}, pathinfo(fname & "." & fext))
testEqual("pathinfo() no dir, no extension", {"", fname, ""}, pathinfo("readme"))

testEqual("dirname() full path", pname, dirname(fullname))
testEqual("dirname() filename only", "", dirname(fname & "." & fext))

testEqual("filename() full path", fname & "." & fext, filename(fullname))
testEqual("filename() filename only", fname & "." & fext, filename(fname & "." & fext))
testEqual("filename() filename no extension", fname, filename(fname))

testEqual("fileext() full path", fext, fileext(fullname))
testEqual("fileext() filename only", fext, fileext(fullname))
testEqual("fileext() filename no extension", "", fileext(fname))

testEqual("PATHSEP", sep, PATHSEP)
