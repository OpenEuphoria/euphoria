sequence initial_directory = current_dir() & SLASH

include std/filesys.e
include std/io.e
include std/search.e
include std/sort.e
include std/text.e
include std/unittest.e
include std/os.e
include std/utils.e

sequence fullname, pname, fname, fext, eolsep, driveid, entire_driveid
integer sep

test_equal( "init_curdir", initial_directory, init_curdir() )

ifdef UNIX then
    fullname = "/opt/euphoria/docs/readme.txt"
    pname = "/opt/euphoria/docs"
    sep = '/'
    eolsep = "\n"
    driveid = ""
	entire_driveid = ""
elsedef
    fullname = "C:\\EUPHORIA\\DOCS\\readme.txt"
    pname = "\\EUPHORIA\\DOCS"
    sep = '\\'
    eolsep = "\r\n"
    driveid = "C"
	entire_driveid = driveid & ":"
end ifdef

object home = getenv("HOME")
ifdef WINDOWS then
	-- When MingW or CygWin is used HOME will be set.  In this case, we should use this variable.
	if atom(home) then
		-- Not defined so use alternative.
		home = getenv("HOMEDRIVE")
		if sequence(home) then
			home &= getenv("HOMEPATH")
		end if
	end if
end ifdef
if sequence(home) then
	if home[$] != SLASH then
		home &= SLASH
	end if
end if

test_not_equal("dir() #1", dir(home & '*'),-1)
if file_exists(lower(home)) then
	test_not_equal("dir() #2", dir(lower(home) & '*'),-1)
	test_not_equal("dir() #3", dir(lower(home[1..$-1]) & '*'),-1)
end if
if file_exists(upper(home)) then
	test_not_equal("dir() #4", dir(upper(home) & '*'),-1)
	test_not_equal("dir() #5", dir(upper(home[1..$-1]) & '*'),-1)
end if
test_not_equal("dir() #6", dir(home[1..$-1] & '*'),-1)

fname = "readme"
fext = "txt"

test_equal("pathinfo() fully qualified path", 
	{ pname, fname & '.' & fext, fname, fext, driveid },
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
test_equal("file_exists #3", 0, file_exists( 1 ))

test_false("absolute_path('')", absolute_path(""))
test_true("absolute_path('/usr/bin/abc')", absolute_path("/usr/bin/abc"))
test_false("absolute_path('../abc')", absolute_path("../abc"))
test_false("absolute_path('local/abc.txt')", absolute_path("local/abc.txt"))
test_false("absolute_path('abc.txt')", absolute_path("abc.txt"))
test_false("absolute_path('c:..\\abc')", absolute_path("c:..\\abc"))
test_false("absolute_path('a')", absolute_path("a"))
test_false("absolute_path('ab')", absolute_path("ab"))
test_false("absolute_path('a:')", absolute_path("a:"))
test_false("absolute_path('a:b')", absolute_path("a:b"))

ifdef WINDOWS then
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

-- filebase()
test_equal( "file base", "readme", filebase("/opt/euphoria/readme.txt") )

-- file_type()
test_equal( "file_type() directory", FILETYPE_DIRECTORY, file_type( current_dir() ))

-- canonical_path()
test_equal( "canonical_path() #1", current_dir() & SLASH & "t_filesys.e", canonical_path( "t_filesys.e" ) )
test_equal( "canonical_path() #2", current_dir() & SLASH & "t_filesys.e", canonical_path( `"t_filesys.e"` ) )
test_equal( "canonical_path() #3", current_dir() & SLASH, canonical_path( current_dir() & SLASH & '.' & SLASH ) )

test_equal( "canonical_path() tilde = HOME #1", home, canonical_path("~"))
test_equal( "canonical_path() tilde = HOME #2", home & 'a', canonical_path("~/a"))
test_equal( "canonical_path() tilde = HOME #3", home & 'a', canonical_path("~a"))

test_equal( "canonical_path() #5", current_dir() & SLASH, canonical_path( current_dir() & SLASH & "foo" & SLASH & ".." & SLASH ) )
test_equal( "canonical_path() #6", current_dir() & SLASH & "UPPERNAME", canonical_path( "UPPERNAME",,CORRECT ))
test_equal( "canonical_path() #7", current_dir() & SLASH & "UPPERNAME", canonical_path( "UPPERNAME",,AS_IS ))

ifdef WINDOWS then
	test_equal( "canonical_path() #8", filesys:driveid(current_dir()) & ":" & SLASH & "john" & SLASH & "doe.txt",
		canonical_path("/john/doe.txt"))
end ifdef

test_equal( "canonical_path() #9", lower(current_dir() & SLASH & "UPPERNAME"), canonical_path( "UPPERNAME",, TO_LOWER ) )
test_equal( "canonical_path() #10",current_dir() & SLASH & lower("UPPERNAME"),  canonical_path( "UPPERNAME",,or_bits(TO_LOWER,CORRECT)))
test_equal( "canonical_path() #11",current_dir() & SLASH, canonical_path(lower(current_dir()), 1, CORRECT)) 


ifdef WINDOWS then
	include std/dll.e
	include std/machine.e
	constant k32 = open_dll( "kernel32.dll" ),
		GetShortPathNameA = define_c_proc( k32, "GetShortPathNameA", { C_POINTER, C_POINTER, C_UINT } )
	function get_short_path( sequence path )
		atom short_name = allocate( length( path ) + 1, 1 )
		poke( short_name, 0 )
		c_proc( GetShortPathNameA, { allocate_string( path, 1 ), short_name, length( path ) + 1 } )
		return peek_string( short_name )
	end function
	
	object program_files = getenv("ProgramFiles")
	
	if sequence(program_files) then
		sequence shortened = filebase( get_short_path( program_files ) )
		test_equal( "canonical_path() #12", shortened, filebase(canonical_path(program_files,,TO_SHORT)))
	end if
end ifdef

test_equal( "canonical_path() #13", current_dir() & SLASH & "*.txt", canonical_path( "*.txt" ) )
test_equal( "canonical_path() #14", current_dir() & SLASH & "*.txt", canonical_path( "../tests/*.txt" ) )

ifdef WINDOWS then
	-- These tests only make sense on a case insensitive file system.
	-- Technically, that doesn't necessarily mean windows, but in 
	-- general Windows is where this happens.
	
	-- one of these two tests below will change the case of the drive letter and CORRECT should restore it.
	test_equal( "canonical_path #15 can change lower case version to the original version",
		current_dir(), canonical_path(lower(current_dir()),, CORRECT) )

	test_equal( "canonical_path #16 can change upper case version to the original version",
		current_dir(), canonical_path(upper(current_dir()),, CORRECT) )
end ifdef
sequence walk_data = {}
function test_walk( sequence path_name, sequence item )
	walk_data = append( walk_data, { path_name, item[D_NAME] } )
	return 0
end function

procedure dir_tests()
	if file_exists( "filesyse_dir" ) then
		test_true( "remove existing testing directory", remove_directory( "filesyse_dir", 1))
		
	end if
	
	test_false( "Bad name #1", create_directory( ".." ) )
	test_false( "Bad name #2", create_directory( "" ) )
	
	test_false( "testing directory is gone", file_exists( "filesyse_dir" ) )
	test_true( "create filesyse_dir", create_directory( canonical_path( "filesyse_dir" ) & SLASH ) )
	
	test_true( "chdir filesyse_dir", chdir( "filesyse_dir" ) )
	sequence expected_walk_data = {}
	
	for h = 0 to 1 do
		for d = 1 to 2 do
			sequence dirname = sprintf("%sdirectory%d", { repeat('.', h), d } )
			test_true( "create dir " & dirname, create_directory( dirname ) )
			test_true( "chdir " & dirname, chdir( dirname ))
			expected_walk_data = append( expected_walk_data, { "filesyse_dir", dirname } )
			for f = 1 to 2 do
				sequence filename = sprintf("file%d",f)
				create_file( filename)
				test_true( "File exists " & filename, file_exists(filename))
				expected_walk_data = append( expected_walk_data, { "filesyse_dir" & SLASH & dirname, filename } )
			end for
			test_true( "back to filesyse_dir", chdir( ".." ))
		end for
	end for
	create_file( "test-file")
	test_true( "test-file exists", file_exists("test-file"))
	
	expected_walk_data = sort( append( expected_walk_data, {"filesyse_dir", "test-file"}) )
	
	test_true("back to tests", chdir("..") )
	
	test_equal( "walk dir", 0, walk_dir( "filesyse_dir", routine_id("test_walk"), 1 ) )
	
	test_equal( "test walk_dir results", expected_walk_data, sort( walk_data ) )
	
	sequence test_dir_size = dir_size( "filesyse_dir" )
	test_equal( "dir size dir count", 4, test_dir_size[COUNT_DIRS] )
	test_equal( "dir size file count", 1, test_dir_size[COUNT_FILES] )
	
	test_not_equal( "clear directory", 0, clear_directory( "filesyse_dir/directory1", 0 ) )
	test_true( "remove testing directory", remove_directory( "filesyse_dir", 1 ) )
end procedure
dir_tests()


sequence metrics = disk_metrics( "." ) 
test_not_equal( "current dir disk_metrics", repeat( 0, length( metrics) ), metrics )

test_true( "simple disk_size test", sequence( disk_size( "." ) ) )
metrics = disk_size( "." )
test_not_equal( "disk size", repeat( 0, length( metrics ) - 1 ), metrics[1..$-1] )


copy_file( "t_filesys.e", "checksum-t_filesys.e", 1 )
for i = 1 to 4 do
	test_not_equal( sprintf("checksum diff %d", i), checksum( "t_filesys.e", i ), checksum( "t_ifdef.e", i ) )
	test_equal(     sprintf("checksum same %d", i), checksum( "t_filesys.e", i ), checksum( "checksum-t_filesys.e", i ) )
	
	test_equal(     sprintf("checksum same with name and text %d", i), checksum( "t_filesys.e", i, 1, 1 ), checksum( "t_filesys.e", i, 1, 1 ) )
	test_not_equal( sprintf("checksum with name %d vs not with name diff", i), checksum( "t_filesys.e", i ), checksum( "checksum-t_filesys.e", i, 1 ) )
	
end for
delete_file( "checksum-t_filesys.e" )

-- TODO: these test miss a lot of abbreviate_path, but I can't figure out how to get there...
test_equal( "abbreviate_path", 
	"tests" & SLASH & "t_filesys.e",  
	abbreviate_path( canonical_path( "t_filesys.e" ), { canonical_path( ".." & SLASH ) } ) ) 

test_equal( "abbreviate_path with extra non matching paths 1", 
	"tests" & SLASH & "t_filesys.e",  
	abbreviate_path( canonical_path( "t_filesys.e" ), { "foo", canonical_path( ".." & SLASH ) } ) )

test_equal( "abbreviate_path with non matching paths 1", 
	filesys:driveid(current_dir()) & iif(platform()=WIN32,':',"") & SLASH & "baz" & SLASH & "tests" & SLASH & "t_filesys.e",
	abbreviate_path( canonical_path( "/baz/tests/t_filesys.e" ) ) )

test_equal( "pathname", current_dir(), pathname( current_dir() & SLASH & "t_filesys.e" ) )

test_true( "driveid returns sequence", sequence( filesys:driveid( current_dir() ) ) )

--
-- temp_file()
--

sequence tmp_name

tmp_name = temp_file("..")
test_true("temp_file .. directory prefix", begins("..", tmp_name))

tmp_name = filename(temp_file( , "T_", "TMP"))
test_true("temp_file T_ prefix", begins("T_", tmp_name))
test_true("temp file .TMP extension", ends(".TMP", tmp_name))

tmp_name = filename(temp_file( , , ""))
test_false("temp_file no extension", find('.', tmp_name))

--
-- Split/Join path
--

sequence spath_eles

ifdef WINDOWS then
	test_equal("split_path #1", { "Users", "john", "hello.txt" }, split_path("\\Users\\john\\hello.txt"))
	test_equal("join_path #1", "\\Users\\john\\hello.txt", join_path({ "Users", "\\john\\", "hello.txt" }))
	test_equal("split_path #2", { "C:", "Users", "john", "hello.txt" }, split_path("C:\\Users\\john\\hello.txt"))
	test_equal("join_path #2", "C:\\Users\\john\\hello.txt", join_path({ "C:", "Users", "\\john\\", "hello.txt" }))
elsedef
	test_equal("split_path #1", { "usr", "home", "john", "hello.txt"},
		split_path("/usr/home/john/hello.txt"))
	test_equal("join path #1", "/usr/home/john/hello.txt",
		join_path({ "/usr/", "/home", "john", "hello.txt" }))
end ifdef

-- Please port to Windows...
ifdef UNIX then
	delete_file("abnormal")
	delete_file("other-unreadable")
	create_directory("normal.d")
	create_file("unwritable")
	create_file("unreadable")
	create_directory("unwritable.d", or_bits(0t100, 0t400))
	create_directory("unreadable.d", or_bits(0t100, 0t200))
	create_file("unreadable.d/hidden")
	system("chmod a-r unreadable")
	system("chmod a-w unwritable")
	integer ret

	test_false("Copying a directory with copy_file returns false", copy_file("normal.d", "abnormal"))
	test_false("Trying to copy a directory with copy_file doesn't create a file.", file_exists("abnormal"))
	
	for i = 1 to 100 do
		ret = copy_file("unreadable", "other-unreadable")
	end for
	test_false("When copy_file fails because it cannot read the source, it doesn't leave a file handle open.", ret)
	
	for i = 1 to 100 do
		ret = copy_file("t_filesys.e", "unwritable")
	end for
	test_false("When copy_file fails because it cannot write destination, it doesn't leave a file handle open.", ret)
	
	for i = 1 to 100 do
		ret = copy_file("t_filesys.e", "unwritable.d")
	end for
	test_false("When copy_file fails because it cannot write destination directory, it doesn't leave a file handle open.", ret)
	-- the O/S should enforce this but if we get our commands wrong above when porting it could fail.
	test_false("Trying to copy a file to unwritable directory with copy_file doesn't create a file.", file_exists("unwritable.d/t_filesys.e"))
	
	-- cleanup
	remove_directory("unwritable.d")
	remove_directory("unreadable.d", 1)
	remove_directory("normal.d")
	delete_file("unwritable")
	delete_file("unreadable")
	delete_file("abnormal")
	delete_file("other-unreadable")
end ifdef
test_report()

