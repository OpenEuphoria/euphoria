include std/filesys.e
include std/io.e
include std/unittest.e

sequence fullname, pname, fname, fext, eolsep, driveid
integer sep

ifdef UNIX then
    fullname = "/opt/euphoria/docs/readme.txt"
    pname = "/opt/euphoria/docs"
    sep = '/'
    eolsep = "\n"
    driveid = ""
elsedef
    fullname = "C:\\EUPHORIA\\DOCS\\readme.txt"
    pname = "\\EUPHORIA\\DOCS"
    sep = '\\'
    eolsep = "\r\n"
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
test_equal("fileext() with period in the filename", "txt", fileext("hello.world.txt"))

test_equal("defaultext #1", "abc.def", defaultext("abc", "def"))
test_equal("defaultext #2", "abc.xyz", defaultext("abc.xyz", "def"))
test_equal("defaultext #3", "abc.xyz" & SLASH & "abc.xyz", defaultext("abc.xyz" & SLASH & "abc.xyz", "def"))
test_equal("defaultext #4", "abc.xyz" & SLASH & "abc.def", defaultext("abc.xyz" & SLASH & "abc", "def"))


test_equal("SLASH", sep, SLASH)
test_equal("EOLSEP", eolsep, EOLSEP)

test_equal("file_exists #1", 1, file_exists("t_filesys.e"))
test_equal("file_exists #2", 0, file_exists("nononononono.txt"))

test_false("absolute_path('')", absolute_path(""))
test_true("absolute_path('/usr/bin/abc')", absolute_path("/usr/bin/abc"))
test_false("absolute_path('../abc')", absolute_path("../abc"))
test_false("absolute_path('local/abc.txt')", absolute_path("local/abc.txt"))
test_false("absolute_path('abc.txt')", absolute_path("abc.txt"))
test_false("absolute_path('c:..\\abc')", absolute_path("c:..\\abc"))

ifdef DOSFAMILY or WINDOWS then
test_true("absolute_path('\\temp\\somefile.doc')", absolute_path("\\temp\\somefile.doc"))
test_true("absolute_path('c:\\windows\\system32\\abc')", absolute_path("c:\\windows\\system32\\abc"))
test_true("absolute_path('c:/windows/system32/abc')", absolute_path("c:/windows/system32/abc"))
elsedef
test_false("absolute_path('c:\\windows\\system32\\abc')", absolute_path("c:\\windows\\system32\\abc"))
test_false("absolute_path('c:/windows/system32/abc')", absolute_path("c:/windows/system32/abc"))
end ifdef

-- move_file()
delete_file("fstesta.txt")
delete_file("fstestb.txt")
write_file("fstesta.txt", "move data", TEXT_MODE)
test_true("move_file #1", move_file("fstesta.txt", "fstestb.txt", 1))
test_true("move_file #2", sequence( dir("fstestb.txt"))) -- 'b' should now exist
test_false("move_file #3", sequence( dir("fstesta.txt"))) -- 'a' should now be gone
write_file("fstesta.txt", "some data", TEXT_MODE)
test_false("move_file #4", move_file("fstesta.txt", "fstestb.txt")) -- should not overwrite existing file
test_false("move_file #5", move_file("fstesta.txt", "fstestb.txt", 0)) -- should not overwrite existing file
test_true("move_file #6", move_file("fstesta.txt", "fstestb.txt", 1)) -- should overwrite existing file
delete_file("fstesta.txt")
delete_file("fstestb.txt")

-- rename_file()
delete_file("fstesta.txt")
delete_file("fstestb.txt")
write_file("fstesta.txt", "rename data", TEXT_MODE)
test_true("rename_file #1", rename_file("fstesta.txt", "fstestb.txt", 1))
test_true("rename_file #2", sequence( dir("fstestb.txt"))) -- 'b' should now exist
test_false("rename_file #3", sequence( dir("fstesta.txt"))) -- 'a' should now be gone
write_file("fstesta.txt", "some data", TEXT_MODE)
test_false("rename_file #4", rename_file("fstesta.txt", "fstestb.txt")) -- should not overwrite existing file
test_false("rename_file #5", rename_file("fstesta.txt", "fstestb.txt", 0)) -- should not overwrite existing file
test_true("rename_file #6", rename_file("fstesta.txt", "fstestb.txt", 1)) -- should overwrite existing file
delete_file("fstesta.txt")
delete_file("fstestb.txt")

-- copy_file()
delete_file("fstesta.txt")
delete_file("fstestb.txt")
write_file("fstesta.txt", "copying data", TEXT_MODE)
test_true("copy_file #1", copy_file("fstesta.txt", "fstestb.txt", 1))
test_true("copy_file #2", sequence( dir("fstestb.txt"))) -- 'b' should now exist
test_true("copy_file #3", sequence( dir("fstesta.txt"))) -- 'a' should still exist
test_false("copy_file #4", copy_file("fstesta.txt", "fstestb.txt")) -- should not overwrite existing file
test_false("copy_file #5", copy_file("fstesta.txt", "fstestb.txt", 0)) -- should not overwrite existing file
delete_file("fstesta.txt")
delete_file("fstestb.txt")


test_report()

