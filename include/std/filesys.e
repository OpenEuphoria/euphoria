--****
-- == File System
--
-- Cross platform file operations for Euphoria
--
-- <<LEVELTOC level=2 depth=4>>

namespace filesys

include std/datetime.e
include std/dll.e
include std/io.e
include std/machine.e
include std/hash.e
include std/math.e
include std/search.e
include std/sequence.e
include std/sort.e
include std/text.e
include std/wildcard.e

include std/types.e

ifdef UNIX then
	include std/get.e -- for disk_size()
end ifdef

constant
	M_DIR	      = 22,
	M_CURRENT_DIR = 23,
	M_CHDIR       = 63

ifdef WINDOWS then	
	constant lib = dll:open_dll("kernel32")

elsifdef LINUX then
	constant lib = dll:open_dll("")

elsifdef OSX then
	constant lib = dll:open_dll("libc.dylib")

elsifdef UNIX then
	constant lib = dll:open_dll("libc.so")
	
end ifdef

ifdef LINUX then
	integer STAT_VER
	if sizeof( C_POINTER ) = 8 then
		STAT_VER = 0
	else
		STAT_VER = 3
	end if
	constant xStatFile = dll:define_c_func(lib, "__xstat", {dll:C_INT, dll:C_POINTER, dll:C_POINTER}, dll:C_INT)
elsifdef OSX then
	function define_stat()
		integer xStatFile = dll:define_c_func(lib, "stat64", {dll:C_POINTER, dll:C_POINTER}, dll:C_INT)
		if xStatFile = -1 then
			xStatFile = dll:define_c_func(lib, "stat", {dll:C_POINTER, dll:C_POINTER}, dll:C_INT)
		end if
		return xStatFile
	end function
	constant xStatFile = define_stat()
	
elsifdef UNIX then
	constant xStatFile = dll:define_c_func(lib, "stat", {dll:C_POINTER, dll:C_POINTER}, dll:C_INT)
end ifdef

ifdef UNIX then
	constant xMoveFile        = dll:define_c_func(lib, "rename", {dll:C_POINTER, dll:C_POINTER}, dll:C_INT)
	--constant xDeleteFile      = define_c_func(lib, "remove", {C_POINTER}, C_LONG)
	constant xDeleteFile      = dll:define_c_func(lib, "unlink", {dll:C_POINTER}, dll:C_INT)
	constant xCreateDirectory = dll:define_c_func(lib, "mkdir", {dll:C_POINTER, dll:C_INT}, dll:C_INT)
	constant xRemoveDirectory = dll:define_c_func(lib, "rmdir", {dll:C_POINTER}, dll:C_INT)
	constant xGetFileAttributes = dll:define_c_func(lib, "access", {dll:C_POINTER, dll:C_INT}, dll:C_INT)
elsifdef WINDOWS then
	constant xCopyFile         = dll:define_c_func(lib, "CopyFileA",   {dll:C_POINTER, dll:C_POINTER, dll:C_BOOL},
		C_BOOL)
	constant xMoveFile         = dll:define_c_func(lib, "MoveFileA",   {dll:C_POINTER, dll:C_POINTER}, dll:C_BOOL)
	constant xDeleteFile       = dll:define_c_func(lib, "DeleteFileA", {dll:C_POINTER}, dll:C_BOOL)
	constant xCreateDirectory  = dll:define_c_func(lib, "CreateDirectoryA", 
		{C_POINTER, C_POINTER}, C_BOOL)
	constant xRemoveDirectory  = dll:define_c_func(lib, "RemoveDirectoryA", {dll:C_POINTER}, dll:C_BOOL)
	constant xGetFileAttributes= dll:define_c_func(lib, "GetFileAttributesA", {dll:C_POINTER}, dll:C_INT) -- N.B DWORD return fails this.
	constant xGetDiskFreeSpace = dll:define_c_func(lib, "GetDiskFreeSpaceA", 
		{dll:C_POINTER, dll:C_POINTER, dll:C_POINTER, dll:C_POINTER, dll:C_POINTER}, dll:C_BOOL)	 
elsedef
	constant xCopyFile          = -1
	constant xMoveFile          = -1
	constant xDeleteFile        = -1
	constant xCreateDirectory   = -1
	constant xRemoveDirectory   = -1
	constant xGetFileAttributes = -1
end ifdef


--****
-- === Constants

--****
-- Signature:
-- <eucode>
-- public constant SLASH
-- </eucode>
--
-- Description:
-- Current platform's path separator character
--
-- Comments:
-- When on //Windows//, ##'~\\'##. When on //Unix//, ##'/'##.
--

--****
-- Signature:
-- <eucode>
-- public constant SLASHES
-- </eucode>
--
-- Description:
-- Current platform's possible path separators. This is slightly different
-- in that on //Windows// the path separators variable contains
-- ##~\~\## as well as ##~:## and ##/## as newer //Windows// versions support
-- ##/## as a path separator. On //Unix// systems, it only contains ##/##.

--****
-- Signature:
-- <eucode>
-- public constant SLASHES
-- </eucode>
--
-- Description:
-- Current platform's possible path separators. This is slightly different
-- in that on //Windows// the path separators variable contains
-- ##~\~\## as well as ##~:## and ##/## as newer //Windows// versions support
-- ##/## as a path separator. On //Unix// systems, it only contains ##/##.

--****
-- Signature:
-- <eucode>
-- public constant EOLSEP
-- </eucode>
--
-- Description:
-- Current platform's newline string: ##"\n"## on //Unix//, else ##"\r\n"##.

--****
-- Signature:
-- <eucode>
-- public constant EOL
-- </eucode>
--
-- Description:
-- All platform's newline character: ##'\n'##. When text lines are read the native
-- platform's EOLSEP string is replaced by a single character EOL.

--****
-- Signature:
-- <eucode>
-- public constant PATHSEP
-- </eucode>
--
-- Description:
-- Current platform's path separator character: ##:## on //Unix//, else ##;##.

--****
-- Signature:
-- <eucode>
-- public constant NULLDEVICE
-- </eucode>
--
-- Description:
-- Current platform's null device path: ##/dev/null## on //Unix//, else ##NUL:##.

--****
-- Signature:
-- <eucode>
-- public constant SHARED_LIB_EXT
-- </eucode>
--
-- Description:
-- Current platform's shared library extension. For instance it can be ##dll##, 
-- ##so## or ##dylib## depending on the platform.

ifdef UNIX then
	public constant SLASH='/'
	public constant SLASHES = "/"
	public constant EOLSEP = "\n"
	public constant PATHSEP = ':'
	public constant NULLDEVICE = "/dev/null"
	ifdef OSX then
		public constant SHARED_LIB_EXT = "dylib"
	elsedef
		public constant SHARED_LIB_EXT = "so"
	end ifdef

elsifdef WINDOWS then

	public constant SLASH='\\'
	public constant SLASHES = "\\/:"
	public constant EOLSEP = "\r\n"
	public constant PATHSEP = ';'
	public constant NULLDEVICE = "NUL:"
	public constant SHARED_LIB_EXT = "dll"
end ifdef

public constant EOL = '\n'

--****
-- === Directory Handling

public enum 
	D_NAME,
	D_ATTRIBUTES,
	D_SIZE,
	D_YEAR,
	D_MONTH,
	D_DAY,
	D_HOUR,
	D_MINUTE,
	D_SECOND,
	D_MILLISECOND,
	D_ALTNAME


--****
-- Signature:
-- <eucode>
-- public constant W_BAD_PATH
-- </eucode>
--
-- Description:
-- Bad path error code. See [[:walk_dir]]

--****
-- Signature:
-- <eucode>
-- public constant W_SKIP_DIRECTORY
-- </eucode>



public constant 
	W_BAD_PATH = -1, -- error code
	W_SKIP_DIRECTORY = -975864

function find_first_wildcard( sequence name, integer from = 1 )
	integer asterisk_at = eu:find('*', name, from)
	integer question_at = eu:find('?', name, from)
	integer first_wildcard_at = asterisk_at
	if asterisk_at or question_at then
		-- Empty if so that we can short circuit if * is found, otherwise
		-- we would have to run a search for * and ? even if * is found.
		if question_at and question_at < asterisk_at then
			first_wildcard_at = question_at
		end if
	end if
	return first_wildcard_at
end function

--**
-- returns directory information for the specified file or directory.
--
-- Parameters:
--     # ##name## : a sequence, the name to be looked up in the file system.
--
-- Returns:
--     An **object**,  -1 if no match found, else a sequence of sequence entries
--
-- Errors:
-- The length of ##name## should not exceed 1_024 characters.
--
-- Comments:
--     ##name## can also contain ##*## and ##?## wildcards to select multiple files.
--
-- The returned information is similar to what you would get from the DIR command. A sequence
-- is returned where each element is a sequence that describes one file or subdirectory.
-- 
-- If ##name## refers to a **directory** you may have entries for "." and "..", just as with the 
-- DIR command. If it refers to an existing **file**, and has no wildcards, then the returned 
-- sequence will have just one entry (that is its length will be ##1##). If ##name## contains wildcards 
-- you may have multiple entries.
-- 
-- Each entry contains the name, attributes and file size as well as
-- the time of the last modification.
--
-- You can refer to the elements of an entry with the following constants~:
--  
-- <eucode>
-- public constant 
--     -- File Attributes
--     D_NAME       = 1,
--     D_ATTRIBUTES = 2,
--     D_SIZE       = 3,
--     D_YEAR       = 4,
--     D_MONTH      = 5,
--     D_DAY        = 6,
--     D_HOUR       = 7,
--     D_MINUTE     = 8,
--     D_SECOND     = 9,
--     D_MILLISECOND = 10,
--     D_ALTNAME    = 11
-- </eucode>
--
-- The attributes element is a string sequence containing characters chosen from~:
--  
-- || Attribute || Description ||
-- | 'd'         | directory
-- | 'r'         | read only file
-- | 'h'         | hidden file
-- | 's'         | system file
-- | 'v'         | volume-id entry 
-- | 'a'         | archive file
-- | 'c'         | compressed file
-- | 'e'         | encrypted file
-- | 'N'         | not indexed
-- | 'D'         | a device name
-- | 'O'         | offline
-- | 'R'         | reparse point or symbolic link
-- | 'S'         | sparse file
-- | 'T'         | temporary file
-- | 'V'         | virtual file
--
-- A normal file without special attributes would just have an empty string, ##""##, in this field.
--
-- The top level directory ( therefore c:\ does not have "." or ".." entries).
-- 
-- This function is often used just to test if a file or directory exists.
-- 
-- Under //Windows//, the argument can have a long file or directory name anywhere in 
-- the path.
-- 
-- Under //Unix//, the only attribute currently available is ##'d'## and the milliseconds
-- are always zero.
-- 
-- //Windows//: The file name returned in ##[D_NAME]## will be a long file name. If ##[D_ALTNAME]##
-- is not zero, it contains the 'short' name of the file.
--
-- Example 1:
-- <eucode>
-- d = dir(current_dir())
--
-- -- d might have:
-- --  {
-- --    {".",    "d",     0  1994, 1, 18,  9, 30, 02},
-- --    {"..",   "d",     0  1994, 1, 18,  9, 20, 14},
-- --    {"fred", "ra", 2350, 1994, 1, 22, 17, 22, 40},
-- --    {"sub",  "d" ,    0, 1993, 9, 20,  8, 50, 12}
-- --  }
--
-- d[3][D_NAME] would be "fred"
-- </eucode>
--
-- See Also:
--   [[:walk_dir]]
--

public function dir(sequence name)
	ifdef WINDOWS then
		return machine_func(M_DIR, name)
	elsedef
		object dir_data, data, the_name, the_dir, the_suffix = 0
		integer idx

		-- Did the user give a wildcard? If not, just return the standard dir.
		integer first_wildcard_at = find_first_wildcard( name )
		if first_wildcard_at = 0 then
			return machine_func(M_DIR, name)
		end if

		-- Is there a path involved?
		if first_wildcard_at then
			idx = search:rfind(SLASH, name, first_wildcard_at )
		else
			idx = search:rfind(SLASH, name )
		end if
		
		if idx = 0 then
			the_dir = "."
			the_name = name
		else
			-- Find a SLASH character and break the name there resulting in
			-- a directory and file name.
			the_dir = name[1 .. idx]
			integer next_slash = 0
			if first_wildcard_at then
				next_slash = eu:find( SLASH, name, first_wildcard_at )
			end if
			
			if next_slash then
				first_wildcard_at = find_first_wildcard( name, next_slash )
				if first_wildcard_at then
					the_name = name[idx+1..next_slash-1]
					the_suffix = name[next_slash..$]
				end if
			else
				the_name = name[idx+1 .. $]
				the_suffix = 0
			end if
			
		end if

		-- Get directory contents
		dir_data = dir( the_dir )
		
		-- Did an error occur?
		if atom(dir_data) then
			return dir_data
		end if
		
		-- Filter the directory contents returning only those items
		-- matching name.
		data = {}
		for i = 1 to length(dir_data) do
			if wildcard:is_match(the_name, dir_data[i][1]) then
					data = append(data, dir_data[i])
			end if
		end for

		if not length(data) then
			-- no matches found, act like it doesn't exist
			return -1
		end if
		
		if sequence( the_suffix ) then
			sequence wild_data = {}
			for i = 1 to length( dir_data ) do
				sequence interim_dir = the_dir & dir_data[i][D_NAME] & SLASH
				object dir_results = dir( interim_dir & the_suffix )
				if sequence( dir_results ) then
					for j = 1 to length( dir_results ) do
						dir_results[j][D_NAME] = interim_dir & dir_results[j][D_NAME]
					end for
					wild_data &= dir_results
				end if
			end for
			return wild_data
		end if
		
		return data
	end ifdef
end function

--**
-- Return the name of the current working directory.
--
-- Returns:
--		A **sequence**, the name of the current working directory
--
-- Comments:
-- There will be no slash or backslash on the end of the current directory, except under
-- //Windows//, at the top-level of a drive (such as ##C:\##).
--
-- Example 1:
-- <eucode>
-- sequence s
-- s = current_dir()
-- -- s would have "C:\EUPHORIA\DOC" if you were in that directory
-- </eucode>
--
-- See Also:
-- 	[[:dir]], [[:chdir]]

public function current_dir()
-- returns name of current working directory
	return machine_func(M_CURRENT_DIR, 0)
end function

--**
-- sets a new value for the current directory.
--
-- Parameters:
-- 		##newdir## : a sequence, the name for the new working directory.
--
-- Returns:
-- 		An **integer**, ##0## on failure, ##1## on success.
--
-- Comments:
-- By setting the current directory, you can refer to files in that directory using just
-- the file name.
-- 
-- The [[:current_dir]] function will return the name of the current directory.
-- 
-- On //Windows// the current directory is a public property shared
-- by all the processes running under one shell. On //Unix// a subprocess
-- can change the current directory for itself, but this will not
-- affect the current directory of its parent process.
--
-- Example 1:
-- <eucode>
-- if chdir("c:\\euphoria") then
--     f = open("readme.doc", "r")
-- else
--     puts(STDERR, "Error: No euphoria directory?\n")
-- end if
-- </eucode>
--
-- See Also:
-- [[:current_dir]], [[:dir]]

public function chdir(sequence newdir)
	return machine_func(M_CHDIR, newdir)
end function

-- Generalized recursive directory walker

function default_dir(sequence path)
-- Default directory sorting function for walk_dir().
-- * sorts by name *
	object d
	
	d = dir(path)
	if atom(d) then
		return d
	else
		-- sort by name
		return stdsort:sort(d)
	end if
end function

-- override the dir sorting function with your own routine id
constant DEFAULT_DIR_SOURCE = -2

-- it's better not to use routine_id() here,
-- or else users will have to bind with clear routine names

--**
-- **Deprecated**, so therefore not documented.
public integer my_dir = DEFAULT_DIR_SOURCE  

--**
-- Generalized Directory Walker
--
-- Parameters:
-- 	# ##path_name## : a sequence, the name of the directory to walk through
-- 	# ##your_function## : the routine id of a function that will receive each path
--                       returned from the result of ##dir_source##, one at a time.
--                       Optionally, to include extra data for your function, ##your_function##
--                       can be a 2 element sequence, with the routine_id as the first element and other data
--                       as the second element.
-- # ##scan_subdirs## : an optional integer, ##1## to also walk though subfolders, ##0## (the default) to skip them all.
--  # ##dir_source## : an optional integer. A routine_id of a user-defined routine that 
--                    returns the list of paths to pass to ##your_function##. If omitted,
--                    the [[:dir]]() function is used. If your routine requires an extra parameter,
--                    ##dir_source## may be a 2 element sequence where the first element is the
--                    routine id and the second is the extra data to be passed as the second parameter
--                    to your function.
--
-- Returns:
-- An **object**,
-- * ##0## on success
-- * ##W_BAD_PATH##  an error occurred
-- * anything else the custom function returned something to stop [[:walk_dir]].
--
-- Comments:
-- This routine will "walk" through a directory named ##path_name##. For each entry in the 
-- directory, it will call a function, whose routine_id is ##your_function##.
-- If ##scan_subdirs## is non-zero (TRUE), then the subdirectories in
-- ##path_name## will be walked through recursively in the very same way.
--
-- The routine that you supply should accept two sequences, the //path name// and //dir// entry for 
-- each file and subdirectory. It should return ##0## to keep going, ##W_SKIP_DIRECTORY## to avoid
-- scan the contents of the supplied path name (if a directory), or non-zero to stop 
-- ##walk_dir##. Returning ##W_BAD_PATH## is taken as denoting some error.
--
-- This mechanism allows you to write a simple function that handles one file at a time, 
-- while ##walk_dir## handles the process of walking through all the files and subdirectories.
--
-- By default, the files and subdirectories will be visited in alphabetical order. To use 
-- a different order, use the ##dir_source## to pass the routine_id of your own modified
-- [[:dir]] function that sorts the directory entries differently.
--
-- The path that you supply to ##walk_dir## must not contain wildcards (##*## or ##?##). Only a 
-- single directory (and its subdirectories) can be searched at one time.
--
-- For //Windows// systems, any ##'/'## characters in ##path_name## are replaced with ##'\'##.
--
-- All trailing slash and whitespace characters are removed from ##path_name##.
--
-- Example 1:
-- <eucode>
-- function look_at(sequence path_name, sequence item)
-- -- this function accepts two sequences as arguments
-- -- it displays all C/C++ source files and their sizes
--     if find('d', item[D_ATTRIBUTES]) then
--         -- Ignore directories
--         if find('s', item[D_ATTRIBUTES]) then
--            return W_SKIP_DIRECTORY -- Don't recurse a system directory
--         else
--            return 0 -- Keep processing as normal
--         end if
--     end if
--     if not find(fileext(item[D_NAME]), {"c","h","cpp","hpp","cp"}) then
--         return 0 -- ignore non-C/C++ files
--     end if
--     printf(STDOUT, "%s%s%s: %d\n",
--            {path_name, {SLASH}, item[D_NAME], item[D_SIZE]})
--     return 0 -- keep going
-- end function
--
-- function mysort(sequence path)
-- 	object d
-- 	
-- 	d = dir(path)
-- 	if atom(d) then
-- 		return d
-- 	end if
-- 	-- Sort in descending file size.
--  return sort_columns(d, {-D_SIZE})
-- end function
--
-- exit_code = walk_dir("C:\\MYFILES\\", routine_id("look_at"), TRUE, 
--                                                         routine_id("mysort"))
-- </eucode>
--
-- See Also:
--   [[:dir]], [[:sort]], [[:sort_columns]]

public function walk_dir(sequence path_name, object your_function, integer scan_subdirs = types:FALSE, object dir_source = types:NO_ROUTINE_ID)
	object d, abort_now
	object orig_func
	sequence user_data = {path_name, 0}
	object source_orig_func
	object source_user_data = ""
	
	orig_func = your_function
	if sequence(your_function) then
		user_data = append(user_data, your_function[2])
		your_function = your_function[1]
	end if
	
	source_orig_func = dir_source
	if sequence(dir_source) then
		source_user_data = dir_source[2]
		dir_source = dir_source[1]
	end if

	-- get the full directory information
	if not equal(dir_source, types:NO_ROUTINE_ID) then
		if atom(source_orig_func) then
			d = call_func(dir_source, {path_name})
		else
			d = call_func(dir_source, {path_name, source_user_data})
		end if
		
	elsif my_dir = DEFAULT_DIR_SOURCE then
		d = default_dir(path_name)
	else
		d = call_func(my_dir, {path_name})
	end if
	if atom(d) then
		return W_BAD_PATH
	end if
	
	-- trim any trailing blanks or '\' '/' characters from the path
	ifdef not UNIX then
		path_name = match_replace('/', path_name, '\\')
	end ifdef
	path_name = text:trim_tail(path_name, {' ', SLASH, '\n'})
	user_data[1] = path_name
	
	for i = 1 to length(d) do
		if eu:find(d[i][D_NAME], {".", ".."}) then
			continue
		end if
		
		user_data[2] = d[i]
		abort_now = call_func(your_function, user_data)
		if not find(abort_now, {0, W_SKIP_DIRECTORY}) then
			return abort_now
		end if
		
		if eu:find('d', d[i][D_ATTRIBUTES]) then
			-- a directory
			if scan_subdirs and abort_now != W_SKIP_DIRECTORY then
				abort_now = walk_dir(path_name & SLASH & d[i][D_NAME],
									 orig_func, scan_subdirs, source_orig_func)
				
				if not equal(abort_now, 0) and 
				   not equal(abort_now, W_BAD_PATH) then
					-- allow BAD PATH, user might delete a file or directory 
					return abort_now
				end if
			end if
		end if
	end for
	return 0
end function

--**
-- creates a new directory.
--
-- Parameters:
-- 		# ##name## : a sequence, the name of the new directory to create
--		# ##mode## : on //Unix// systems, permissions for the new directory. Default is 
--		  ##448## (all rights for owner, none for others).
--      # ##mkparent## : If true (default) the parent directories are also created
--        if needed. 
--
-- Returns:
--     An **integer**, ##0## on failure, ##1## on success.
--
-- Comments:
-- 		##mode## is ignored on //Windows// platforms.
--
-- Example 1:
-- <eucode>
-- if not create_directory("the_new_folder") then
--		crash("Filesystem problem - could not create the new folder")
-- end if
-- 
-- -- This example will also create "myapp/" and "myapp/interface/" 
-- -- if they don't exist.
-- if not create_directory("myapp/interface/letters") then
--		crash("Filesystem problem - could not create the new folder")
-- end if
--
-- -- This example will NOT create "myapp/" and "myapp/interface/" 
-- -- if they don't exist.
-- if not create_directory("myapp/interface/letters",,0) then
--		crash("Filesystem problem - could not create the new folder")
-- end if
-- </eucode>
--
-- See Also:
-- 	[[:remove_directory]], [[:chdir]]

public function create_directory(sequence name, integer mode=448, integer mkparent = 1)
	atom pname, ret
	integer pos

	if length(name) = 0 then
		return 0 -- failed
	end if
	
	-- Remove any trailing slash.
	if name[$] = SLASH then
		name = name[1 .. $-1]
	end if
	
	if mkparent != 0 then
		pos = search:rfind(SLASH, name)
		if pos != 0 then
			ret = create_directory(name[1.. pos-1], mode, mkparent)
		end if
	end if
	
	pname = machine:allocate_string(name)

	ifdef UNIX then
		ret = not c_func(xCreateDirectory, {pname, mode})
	elsifdef WINDOWS then
		ret = c_func(xCreateDirectory, {pname, 0})
		mode = mode -- get rid of not used warning
	end ifdef

	return ret
end function

--**
-- Create a new file.
--
-- Parameters:
-- 		# ##name## : a sequence, the name of the new file to create
--
-- Returns:
--     An **integer**, ##0## on failure, ##1## on success.
--
-- Comments:
-- * The created file will be empty, that is it has a length of zero.
-- * The created file will not be open when this returns.
--
-- Example 1:
-- <eucode>
-- if not create_file("the_new_file") then
--		crash("Filesystem problem - could not create the new file")
-- end if
-- </eucode>
--
-- See Also:
-- 	[[:create_directory]]

public function create_file(sequence name)
	integer fh = open(name, "wb")
	integer ret = (fh != -1)
	if ret then
		close(fh)
	end if
	return ret
end function

--**
-- deletes a file.
--
-- Parameters:
-- 		# ##name## : a sequence, the name of the file to delete.
--
-- Returns:
--     An **integer**, ##0## on failure, ##1## on success.

public function delete_file(sequence name)

	atom pfilename = machine:allocate_string(name)
	integer success = c_func(xDeleteFile, {pfilename})
		
	ifdef UNIX then
		success = not success
	end ifdef
	
	machine:free(pfilename)

	return success
end function

--**
-- Returns the current directory, with a trailing SLASH
--
-- Parameters:
--		# ##drive_id## : For //Windows// systems only. This is the Drive letter to
--      to get the current directory of. If omitted, the current drive is used.
--
-- Returns:
--     A **sequence**, the current directory.
--
-- Comments:
--  //Windows// maintains a current directory for each disk drive. You
--  would use this routine if you wanted the current directory for a drive that
--  may not be the current drive.
--
--  For //Unix// systems, this is simply ignored because there is only one current
--  directory at any time on //Unix//.
--
-- Note: 
-- This always ensures that the returned value has a trailing //SLASH//
-- character.
--
-- Example 1:
-- <eucode>
-- res = curdir('D') -- Find the current directory on the D: drive.
-- -- res might be "D:\backup\music\"
-- res = curdir()    -- Find the current directory on the current drive.
-- -- res might be "C:\myapp\work\"
-- </eucode>

public function curdir(integer drive_id = 0)

    sequence lCurDir
	ifdef not LINUX then
	    sequence lOrigDir = ""
	    sequence lDrive
	
	    if t_alpha(drive_id) then
		    lOrigDir =  current_dir()
		    lDrive = "  "
		    lDrive[1] = drive_id
		    lDrive[2] = ':'
		    if chdir(lDrive) = 0 then
		    	lOrigDir = ""
		    end if
		end if
	end ifdef
    
    lCurDir = current_dir()
	ifdef not LINUX then
		if length(lOrigDir) > 0 then
	    	chdir(lOrigDir[1..2])
	    end if
	end ifdef

	-- Ensure that it ends in a path separator.
	if (lCurDir[$] != SLASH) then
		lCurDir &= SLASH
	end if
	
	return lCurDir
end function

sequence InitCurDir = curdir() -- Capture the original PWD

--**
-- returns the original current directory.
--
-- Parameters:
--		# None.
--
-- Returns:
--     A **sequence**, the current directory at the time the program started running.
--
-- Comments:
-- You would use this if the program might change the current directory during
-- its processing and you wanted to return to the original directory.
--
-- Note: 
-- This always ensures that the returned value has a trailing ##SLASH##
-- character.
--
-- Example 1:
-- <eucode>
-- res = init_curdir() -- Find the original current directory.
-- </eucode>

public function init_curdir()
	return InitCurDir
end function

--- TODO
--- copy_directory( srcpath, destpath, structonly = 0)

--**
-- clears (deletes) a directory of all files, but retaining sub-directories.
--
-- Parameters:
--		# ##name## : a sequence, the name of the directory whose files you want to remove.
--		# ##recurse## : an integer, whether or not to remove files in the 
--        directory's sub-directories. If ##0## then this function is identical
--        to ##remove_directory##. If ##1##, then we recursively delete the
--        directory and its contents. Defaults to ##1## .
--
-- Returns:
--     An **integer**, ##0## on failure, otherwise the number of files plus ##1## .
--
-- Comments:
-- This never removes a directory. It only ever removes files. It is used to 
-- clear a directory structure of all existing files, leaving the structure
-- intact.
--
-- Example 1:
-- <eucode>
-- integer cnt = clear_directory("the_old_folder")
-- if cnt = 0 then
--		crash("Filesystem problem - could not remove one or more of the files.")
-- end if
-- printf(1, "Number of files removed: %d\n", cnt - 1)
-- </eucode>
--
-- See Also:
-- 	[[:remove_directory]], [[:delete_file]]

public function clear_directory(sequence path, integer recurse = 1)
	object files
	integer ret

	if length(path) > 0 then
		if path[$] = SLASH then
			path = path[1 .. $-1]
		end if
	end if
	
	if length(path) = 0 then
		return 0 -- Nothing specified to clear. Not safe to assume anything.
		         -- (btw, not allowed to clear root directory)
	end if
	ifdef WINDOWS then
		if length(path) = 2 then
			if path[2] = ':' then
				return 0 -- nothing specified to delete
			end if
		end if
	end ifdef

	
	files = dir(path)
	if atom(files) then
		return 0
	end if
	
	ifdef WINDOWS then
		if length( files ) < 3 then
			return 0 -- Supplied name was not a directory
		end if
		if not equal(files[1][D_NAME], ".") then
			return 0 -- Supplied name was not a directory
		end if
		if not eu:find('d', files[1][D_ATTRIBUTES]) then
			return 0 -- Supplied name was not a directory
		end if
	elsedef
		if length( files ) < 2 then
			return 0 -- not a directory
		end if
	end ifdef
	
	ret = 1
	path &= SLASH
	
	ifdef WINDOWS then
		for i = 3 to length(files) do
			if eu:find('d', files[i][D_ATTRIBUTES]) then
				if recurse then
					integer cnt = clear_directory(path & files[i][D_NAME], recurse)
					if cnt = 0 then
						return 0
					end if
					ret += cnt
				else
					continue
				end if
			else
				if delete_file(path & files[i][D_NAME]) = 0 then
					return 0
				end if
				ret += 1
			end if
		end for
	elsedef
		for i = 1 to length(files) do
			if files[i][D_NAME][1] = '.' then
				continue
			end if
			if eu:find('d', files[i][D_ATTRIBUTES]) then
				if recurse then
					integer cnt = clear_directory(path & files[i][D_NAME], recurse)
					if cnt = 0 then
						return 0
					end if
					ret += cnt
				else
					continue
				end if
			else
				if delete_file(path & files[i][D_NAME]) = 0 then
					return 0
				end if
				ret += 1
			end if
		end for
	end ifdef
	return ret
end function

--**
-- removes a directory.
--
-- Parameters:
--		# ##name## : a sequence, the name of the directory to remove.
--      # ##force## : an integer, if ##1## this will also remove files and
--                    sub-directories in the directory. The default is
--                   ##0##, which means that it will only remove the
--                   directory if it is already empty.
--
-- Returns:
--     An **integer**, ##0## on failure, ##1## on success.
--
-- Example 1:
-- <eucode>
-- if not remove_directory("the_old_folder") then
--		crash("Filesystem problem - could not remove the old folder")
-- end if
-- </eucode>
--
-- See Also:
-- 	[[:create_directory]], [[:chdir]], [[:clear_directory]]

public function remove_directory(sequence dir_name, integer force=0)
	atom pname, ret
	object files
	integer D_NAME = 1, D_ATTRIBUTES = 2
	
	-- Remove any trailing slash
 	if length(dir_name) > 0 then
		if dir_name[$] = SLASH then
			dir_name = dir_name[1 .. $-1]
		end if
	end if
	
	if length(dir_name) = 0 then
		return 0	-- nothing specified to delete.
		            -- (not allowed to delete root directory btw)
	end if
	
	ifdef WINDOWS then
		if length(dir_name) = 2 then
			if dir_name[2] = ':' then
				return 0 -- nothing specified to delete
			end if
		end if
	end ifdef

	files = dir(dir_name)
	if atom(files) then
		return 0
	end if
	if length( files ) < 2 then
		return 0	-- Supplied dir_name was not a directory
	end if
	ifdef WINDOWS then
	
		if not equal(files[1][D_NAME], ".") then
			return 0 -- Supplied name was not a directory
		end if
		if not eu:find('d', files[1][D_ATTRIBUTES]) then
			return 0 -- Supplied name was not a directory
		end if
		if length(files) > 2 then
			if not force then
				return 0 -- Directory is not already emptied.
			end if
		end if
	end ifdef
	
	dir_name &= SLASH
	ifdef WINDOWS then
		for i = 3 to length(files) do
			if eu:find('d', files[i][D_ATTRIBUTES]) then
				ret = remove_directory(dir_name & files[i][D_NAME] & SLASH, force)
			else
				
				ret = delete_file(dir_name & files[i][D_NAME])
			end if
			if not ret then
				return 0
			end if

		end for
	elsedef
		for i = 1 to length(files) do
			if find( files[i][D_NAME], {".",".."}) then
				continue
			end if
			if eu:find('d', files[i][D_ATTRIBUTES]) then
				ret = remove_directory(dir_name & files[i][D_NAME] & SLASH, force)
			else
				ret = delete_file(dir_name & files[i][D_NAME])
			end if
			if not ret then
				return 0
			end if
		end for
	end ifdef
	pname = machine:allocate_string(dir_name)
	ret = c_func(xRemoveDirectory, {pname})
	ifdef UNIX then
			ret = not ret 
	end ifdef
	machine:free(pname)
	return ret
end function


--****
-- === File Name Parsing

public enum
	PATH_DIR,
	PATH_FILENAME,
	PATH_BASENAME,
	PATH_FILEEXT,
	PATH_DRIVEID

--**
-- parses a fully qualified pathname.
-- Parameters:
-- 		# ##path## : a sequence, the path to parse
--
-- Returns:
-- 		A **sequence**, of length five. Each of these elements is a string:
-- 		* The path name. For //Windows// this excludes the drive id.
--		* The full unqualified file name
--		* the file name, without extension
--		* the file extension
--		* the drive id
--
-- Comments:
--
-- The host operating system path separator is used in the parsing.
--
-- Example 1:
-- <eucode>
-- -- WINDOWS
-- info = pathinfo("C:\\euphoria\\docs\\readme.txt")
-- -- info is {"C:\\euphoria\\docs", "readme.txt", "readme", "txt", "C"}
-- </eucode>
--
-- Example 2:
-- <eucode>
-- -- Unix variants
-- info = pathinfo("/opt/euphoria/docs/readme.txt")
-- -- info is {"/opt/euphoria/docs", "readme.txt", "readme", "txt", ""}
-- </eucode>
--
-- Example 3:
-- <eucode>
-- -- no extension
-- info = pathinfo("/opt/euphoria/docs/readme")
-- -- info is {"/opt/euphoria/docs", "readme", "readme", "", ""}
-- </eucode>
--
-- See Also:
--   [[:driveid]], [[:dirname]], [[:filename]], [[:fileext]],
--   [[:PATH_BASENAME]], [[:PATH_DIR]], [[:PATH_DRIVEID]], [[:PATH_FILEEXT]],
--   [[:PATH_FILENAME]]

public function pathinfo(sequence path, integer std_slash = 0)
	integer slash, period, ch
	sequence dir_name, file_name, file_ext, file_full, drive_id

	dir_name  = ""
	file_name = ""
	file_ext  = ""
	file_full = ""
	drive_id  = ""

	slash = 0
	period = 0

	for i = length(path) to 1 by -1 do
		ch = path[i]
		if period = 0 and ch = '.' then
			period = i
		elsif eu:find(ch, SLASHES) then
			slash = i
			exit
		end if
	end for

	if slash > 0 then
		dir_name = path[1..slash-1]
		
		ifdef not UNIX then
			ch = eu:find(':', dir_name)
			if ch != 0 then
				drive_id = dir_name[1..ch-1]
				dir_name = dir_name[ch+1..$]
			end if
		end ifdef
	end if
	if period > 0 then
		file_name = path[slash+1..period-1]
		file_ext = path[period+1..$]
		file_full = file_name & '.' & file_ext
	else
		file_name = path[slash+1..$]
		file_full = file_name
	end if
	
	if std_slash != 0 then
		if std_slash < 0 then
			std_slash = SLASH
			ifdef UNIX then
			sequence from_slash = "\\"
			elsedef
			sequence from_slash = "/"
			end ifdef
			dir_name = search:match_replace(from_slash, dir_name, std_slash)
		else
			dir_name = search:match_replace("\\", dir_name, std_slash)
			dir_name = search:match_replace("/", dir_name, std_slash)
		end if
	end if

	return {dir_name, file_full, file_name, file_ext, drive_id }
end function

--**
-- returns the directory name of a fully qualified filename.
--
-- Parameters:
-- 		# ##path## : the path from which to extract information
--      # ##pcd## : If not zero and there is no directory name in ##path##
--                 then "." is returned. The default (##0##) will just return
--                 any directory name in ##path##.
--
-- Returns:
-- 		A **sequence**, the full file name part of ##path##.
--
-- Comments:
-- The host operating system path separator is used.
--
-- Example 1:
-- <eucode>
-- fname = dirname("/opt/euphoria/docs/readme.txt")
-- -- fname is "/opt/euphoria/docs"
-- </eucode>
--
-- See Also:
--   [[:driveid]], [[:filename]], [[:pathinfo]]

public function dirname(sequence path, integer pcd = 0)
	sequence data
	data = pathinfo(path)
	if pcd then
		if length(data[1]) = 0 then
			return "."
		end if
	end if
	return data[1]
end function

--**
-- returns the directory name of a fully qualified filename.
--
-- Parameters:
-- 		# ##path## : the path from which to extract information
--      # ##pcd## : If not zero and there is no directory name in ##path##
--                 then "." is returned. The default (##0##) will just return
--                 any directory name in ##path##.
--
-- Returns:
-- 		A **sequence**, the full file name part of ##path##.
--
-- Comments:
-- The host operating system path separator is used.
--
-- Example 1:
-- <eucode>
-- fname = dirname("/opt/euphoria/docs/readme.txt")
-- -- fname is "/opt/euphoria/docs"
-- </eucode>
--
-- See Also:
--   [[:driveid]], [[:filename]], [[:pathinfo]]

public function pathname(sequence path)
	sequence data
	integer stop
	
	data = canonical_path(path)
	stop = search:rfind(SLASH, data)
	
	return data[1 .. stop - 1]

end function

--**
-- returns the file name portion of a fully qualified filename.
--
-- Parameters:
-- 		# ##path## : the path from which to extract information
--
-- Returns:
-- 		A **sequence**, the file name part of ##path##.
--
-- Comments:
-- The host operating system path separator is used.
--
-- Example 1:
-- <eucode>
-- fname = filename("/opt/euphoria/docs/readme.txt")
-- -- fname is "readme.txt"
-- </eucode>
--
-- See Also:
--   [[:pathinfo]], [[:filebase]], [[:fileext]]
  
public function filename(sequence path)
	sequence data

	data = pathinfo(path)

	return data[2]
end function

--**
-- returns the base filename of path.
--
-- Parameters:
-- 		# ##path## : the path from which to extract information
--
-- Returns:
-- 		A **sequence**, the base file name part of ##path##.
--
-- TODO: Test
--
-- Example 1:
-- <eucode>
-- base = filebase("/opt/euphoria/readme.txt")
-- -- base is "readme"
-- </eucode>
--
-- See Also:
--     [[:pathinfo]], [[:filename]], [[:fileext]]

public function filebase(sequence path)
	sequence data

	data = pathinfo(path)

	return data[3]
end function

--**
-- returns the file extension of a fully qualified filename.
--
-- Parameters:
-- 		# ##path## : the path from which to extract information
--
-- Returns:
-- 		A **sequence**, the file extension part of ##path##.
--
-- Comments:
-- The host operating system path separator is used.
--
-- Example 1:
-- <eucode>
-- fname = fileext("/opt/euphoria/docs/readme.txt")
-- -- fname is "txt"
-- </eucode>
--
-- See Also:
--     [[:pathinfo]], [[:filename]], [[:filebase]]

public function fileext(sequence path)
	sequence data
	data = pathinfo(path)
	return data[4]
end function
	
--**
-- returns the drive letter of the path on //Windows// platforms.
--
-- Parameters:
-- 		# ##path## : the path from which to extract information
--
-- Returns:
-- 		A **sequence**, the file extension part of ##path##.
--
-- TODO: Test
--
-- Example 1:
-- <eucode>
-- letter = driveid("C:\\EUPHORIA\\Readme.txt")
-- -- letter is "C"
-- </eucode>
--
-- See Also:
--     [[:pathinfo]], [[:dirname]], [[:filename]]

public function driveid(sequence path)
	sequence data
	data = pathinfo(path)
	return data[5]
end function

--**
-- returns the supplied filepath with the supplied extension, if
-- the filepath does not have an extension already.
--
-- Parameters:
-- 		# ##path## : the path to check for an extension.
-- 		# ##defext## : the extension to add if ##path## does not have one.
--
-- Returns:
-- 		A **sequence**, the path with an extension.
--
-- Example 1:
-- <eucode>
--  -- ensure that the supplied path has an extension, 
--  -- but if it doesn't use "tmp".
-- theFile = defaultext(UserFileName, "tmp")
-- </eucode>
--
-- See Also:
--     [[:pathinfo]]

public function defaultext( sequence path, sequence defext)
	if length(defext) = 0 then
		return path
	end if
	
	for i = length(path) to 1 by -1 do
		if path[i] = '.' then
			-- There is a dot in the file name part
			return path
		end if
		if find(path[i], SLASHES) then
			if i = length(path) then
				-- No file name in supplied path
				return path
			else
				-- No dot in file name part.
				exit
			end if
		end if
	end for
	
	if defext[1] != '.' then
		path &= '.'
	end if
	
	return path & defext
end function

--**
-- determines if the supplied string is an absolute path or a relative path.
--
-- Parameters:
--		# ##filename## : a sequence, the name of the file path
--
-- Returns:
--     An **integer**, ##0## if ##filename## is a relative path or ##1## otherwise.
--
-- Comments:
-- A //relative// path is one which is relative to the current directory and
-- an //absolute// path is one that doesn't need to know the current directory
-- to find the file.
--
-- Example 1:
-- <eucode>
-- ? absolute_path("") -- returns 0
-- ? absolute_path("/usr/bin/abc") -- returns 1
-- ? absolute_path("\\temp\\somefile.doc") -- returns 1
-- ? absolute_path("../abc") -- returns 0
-- ? absolute_path("local/abc.txt") -- returns 0
-- ? absolute_path("abc.txt") -- returns 0
-- ? absolute_path("c:..\\abc") -- returns 0
--
-- -- The next two examples return 
-- -- 0 on Unix platforms and 
-- -- 1 on Microsoft platforms
-- ? absolute_path("c:\\windows\\system32\\abc")
-- ? absolute_path("c:/windows/system32/abc")
-- </eucode>

public function absolute_path(sequence filename)
	if length(filename) = 0 then
		return 0
	end if
	
	if eu:find(filename[1], SLASHES) then
		return 1
	end if
	
	ifdef WINDOWS then
		if length(filename) = 1 then
			return 0
		end if
		
		if filename[2] != ':' then
			return 0
		end if
		
		if length(filename) < 3 then
			return 0
		end if
		
		if eu:find(filename[3], SLASHES) then
			return 1
		end if
	end ifdef
	return 0
end function


public enum
	AS_IS = 0, TO_LOWER = 1, CORRECT = 2, TO_SHORT = 4

ifdef WINDOWS then
	constant starting_current_dir = machine_func(M_CURRENT_DIR)
	constant system_drive_case = and_bits(and_bits('a',not_bits('A')),starting_current_dir[1]) -- 32 if lower case, 0 if upper case.
end ifdef

public type case_flagset_type(integer x)
	return x >= AS_IS and x < 2*TO_SHORT
end type


--**
-- returns the full path and file name of the supplied file name.
--
-- Parameters:
--	# ##path_in## : A sequence. This is the file name whose full path you want.
--  #   ##directory_given## : An integer. This is zero if ##path_in## is 
--  to be interpreted as a file specification otherwise it is assumed to be a
--  directory specification. The default is zero.
--  # ##case_flags## : An integer. This is a combination of flags.  
--            AS_IS      =  Includes no flags
--            TO_LOWER   =  If passed will convert the part of the path not affected by
--                          other case flags to lowercase.
--            CORRECT    =  If passed will correct the parts of the filepath that
--                          exist in the current filesystem in parts of the filesystem
--                          that is case insensitive.  This should  work on //Windows//
--                          or SMB mounted volumes on //Unix// and all OS X filesystems.
--
--           TO_LOWER    =  If passed alone the entire path is converted to lowercase.
--           or_bits(TO_LOWER,CORRECT) = If these flags are passed together the the part that
--                          exists has the case of that of the filesystem.  The part that
--                          does not is converted to lower case.
--           TO_SHORT    =  If passed the elements of the path that exist are also converted
--                          to their //Windows// short names if avaliable.  
--
-- Returns:
--     A **sequence**, the full path and file name.
--
-- Comments:
-- * The supplied file/directory does not have to actually exist.
-- * ##path_in## can be enclosed in quotes, which will be stripped off.
-- * If ##path_in## begins with a tilde ##'~~'## then that is replaced by the
--   contents of ##$HOME## in //Unix// platforms and ##%HOMEDRIVE%%HOMEPATH%## in //Windows//.
-- * In //Windows// all ##'/'## characters are replaced by ##'\'## characters.
-- * Does not (yet) handle UNC paths or //Unix// links.
--
--
-- Example 1:
-- <eucode>
-- -- Assuming the current directory is "/usr/foo/bar" 
-- res = canonical_path("../abc.def")
-- -- res is now "/usr/foo/abc.def"
-- </eucode>
--
-- Example 2:
-- <eucode>
-- -- res is "C:\Program Files" on systems that have that directory.
-- res = canonical_path("c:\pRoGrAm FiLeS", CORRECT)
-- -- on Windows Vista this would be "c:\Program Files" for Vista uses lowercase for its drives.
-- </eucode>
public function canonical_path(sequence path_in, integer directory_given = 0, case_flagset_type case_flags = AS_IS)
	
    sequence lPath = ""
    integer lPosA = -1
    integer lPosB = -1
    sequence lLevel = ""
    object lHome
    path_in = path_in
    
	ifdef UNIX then
		lPath = path_in
	elsedef
	    sequence lDrive
	    -- Replace unix style separators with Windows style
	    lPath = match_replace("/", path_in, SLASH)
	end ifdef

    -- Strip off any enclosing quotes.
    if (length(lPath) > 2 and lPath[1] = '"' and lPath[$] = '"') then
        lPath = lPath[2..$-1]
	end if

    -- Replace any leading tilde with 'HOME' directory.
    if (length(lPath) > 0 and lPath[1] = '~') then
    	-- Not common but can be set on Windows
		lHome = getenv("HOME")
		ifdef WINDOWS then
			if atom(lHome) then
				lHome = getenv("HOMEDRIVE") & getenv("HOMEPATH")
			end if
		end ifdef
		
		if lHome[$] != SLASH then
			lHome &= SLASH
		end if
		
		if length(lPath) > 1 and lPath[2] = SLASH then
			lPath = lHome & lPath[3 .. $]
		else
			lPath = lHome & lPath[2 .. $]
		end if
    end if

	ifdef WINDOWS then
		-- Strip off any drive letter attached.
	    if ( (length(lPath) > 1) and (lPath[2] = ':' ) ) then
			lDrive = lPath[1..2]
			lPath = lPath[3..$]
		else
			lDrive = driveid(current_dir()) & ':'
		end if
	end ifdef

	sequence wildcard_suffix
	integer first_wildcard_at = find_first_wildcard( lPath )
	if first_wildcard_at then
		integer last_slash = search:rfind( SLASH, lPath, first_wildcard_at )
		if last_slash then
			wildcard_suffix = lPath[last_slash..$]
			lPath = remove( lPath, last_slash, length( lPath ) )
		else
			wildcard_suffix = lPath
			lPath = ""
		end if
	else
		wildcard_suffix = ""
	end if
	
	-- If a relative path, prepend the PWD of the appropriate drive.
	if ((length(lPath) = 0) or not find(lPath[1], "/\\")) then
		ifdef UNIX then
			lPath = curdir() & lPath
		elsedef
			if (length(lDrive) = 0) then
				lPath = curdir() & lPath
			else
				lPath = curdir(lDrive[1]) & lPath
			end if
			-- Strip of the drive letter if it got attached again.
			if ( (length(lPath) > 1) and (lPath[2] = ':' ) ) then
				if (length(lDrive) = 0) then
					lDrive = lPath[1..2]
				end if
				lPath = lPath[3..$]
			end if
		end ifdef		
	end if

	-- If the input is supposed to be a directory, ensure it ends in a path separator.
	if ((directory_given != 0) and (lPath[$] != SLASH) ) then
		lPath &= SLASH
	end if
	
	-- Replace all instances of "/./" with "/"
	lLevel = SLASH & '.' & SLASH
	lPosA = 1
	while( lPosA != 0 ) with entry do
		lPath = eu:remove(lPath, lPosA, lPosA + 1)
		
	  entry
		lPosA = match(lLevel, lPath, lPosA )
	end while
	
	-- Replace all instances of "X/Y/../" with "X/"
	lLevel = SLASH & ".." & SLASH
	
	lPosB = 1
	while( lPosA != 0 ) with entry do
		-- Locate preceding directory separator.
		lPosB = lPosA-1
		while((lPosB > 0) and (lPath[lPosB] != SLASH)) do
			lPosB -= 1
		end while
		if (lPosB <= 0) then
			lPosB = 1
		end if
		lPath = eu:remove(lPath, lPosB, lPosA + 2)
		
	  entry
		lPosA = match(lLevel, lPath, lPosB )
	end while
	
	if case_flags = TO_LOWER then
		lPath = lower( lPath )
	
	elsif case_flags != AS_IS then
		sequence sl = find_all(SLASH,lPath) -- split apart lPath
		integer short_name = and_bits(TO_SHORT,case_flags)=TO_SHORT
		integer correct_name = and_bits(case_flags,CORRECT)=CORRECT
		integer lower_name = and_bits(TO_LOWER,case_flags)=TO_LOWER
		if lPath[$] != SLASH then
			sl = sl & {length(lPath)+1}
		end if

		for i = length(sl)-1 to 1 by -1 label "partloop" do
			ifdef WINDOWS then
				sequence part = lDrive & lPath[1..sl[i]-1]
			elsedef
				sequence part = lPath[1..sl[i]-1]
			end ifdef
			
			object list = dir( part & SLASH )
			sequence supplied_name = lPath[sl[i]+1..sl[i+1]-1]
			
			if atom(list) then
				if lower_name then
					lPath = part & lower(lPath[sl[i]..$])
				end if
				continue
			end if
				
			-- check for a case sensitive match
			for j = 1 to length(list) do
				sequence read_name = list[j][D_NAME]
				if equal(read_name, supplied_name) then
					if short_name and sequence(list[j][D_ALTNAME]) then
						lPath = lPath[1..sl[i]] & list[j][D_ALTNAME] & lPath[sl[i+1]..$]
						sl[$] = length(lPath)+1
					end if
					continue "partloop"
				end if
			end for
				
			-- the only way we get in this block is when the entity above is on
			-- a case-insensitive file system.  
			for j = 1 to length(list) do
				sequence read_name = list[j][D_NAME]
				if equal(lower(read_name), lower(supplied_name)) then
					if short_name and sequence(list[j][D_ALTNAME]) then
						lPath = lPath[1..sl[i]] & list[j][D_ALTNAME] & lPath[sl[i+1]..$]
						sl[$] = length(lPath)+1
					end if
					if correct_name then
						lPath = lPath[1..sl[i]] & read_name & lPath[sl[i+1]..$]
					end if
					continue "partloop"
				end if
			end for
				
			-- Entitiy doesn't exist.  Change the remaining to lowercase
			-- if requested with case_flags.
			if and_bits(TO_LOWER,case_flags) then
				lPath = lPath[1..sl[i]-1] & lower(lPath[sl[i]..$])
			end if
			exit
		end for
		if and_bits(case_flags,or_bits(CORRECT,TO_LOWER))=TO_LOWER and length(lPath) then
			lPath = lower(lPath)
		end if
	end if
	
	ifdef WINDOWS then
		if and_bits(CORRECT,case_flags) then
			-- must use if-block to handle non-ASCII correctly...
			if or_bits(system_drive_case,'A') = 'a' then
				lDrive = lower(lDrive)
			else
				lDrive = upper(lDrive)
			end if
		elsif and_bits(TO_LOWER,case_flags) then
			lDrive = lower(lDrive)
		end if
		lPath = lDrive & lPath
	end ifdef
	
	return lPath & wildcard_suffix
end function


-- Change the parts of s to lower case that exist on a case insensitive file 
-- system.
--
--        
function fs_case(sequence s)
	-- Bugs:
	-- Normally Windows is insensitive and others are sensitive.  
	-- On the other hand:
	--        EXT2 filesystem mounted on Windows is case sensitive.
	--        OS X's filesystems may be insensitive.
	--        SMB filesystems mounted on UNIX are insensitive.
	ifdef WINDOWS then
		return lower(s)
	elsedef
		return s
	end ifdef
end function


--**
-- returns a path string to the supplied file which is shorter than the 
-- given path string.
--
-- Parameters:
--	# ##orig_path## : A sequence. This is the path to a file.
--  # ##base_paths## : A sequence. This is an optional list of paths that may
--  prefix the original path. The default is an empty list.
--
-- Returns:
--     A **sequence**, an equivalent path to ##orig_path## which is shorter 
--     than the supplied path. If a shorter one cannot be formed, then the
--     original path is returned.
--
-- Comments:
-- * This function is primarily used to get the shortest form of a file path
--   for output to a file or screen.
-- * It works by first trying to find if the ##orig_path## begins with any
--   of the ##base_paths##. If so it returns the parameter minus the
--   base path prefix.
-- * Next it checks if the ##orig_path## begins with the current directory path.
--   If so it returns the parameter minus the current directory path.
-- * Next it checks if it can form a relative path from the current directory
--   to the supplied file which is shorter than the parameter string.
-- * Failing all of that, it returns the original parameter.
-- * In //Windows// the shorter result has all ##'/'## characters are replaced by ##'\'##
--	 characters.
-- * The supplied path does not have to actually exist.
-- * ##orig_path## can be enclosed in quotes, which will be stripped off.
-- * If ##orig_path## begins with a tilde ##'~~'## then that is replaced by the
--   contents of ##$HOME## in //Unix// platforms and ##%HOMEDRIVE%%HOMEPATH%## in //Windows//.
--
--
-- Example 1:
-- <eucode>
-- -- Assuming the current directory is "/usr/foo/bar" 
-- res = abbreviate_path("/usr/foo/abc.def")
-- -- res is now "../abc.def"
-- res = abbreviate_path("/usr/foo/bar/inc/abc.def")
-- -- res is now "inc/abc.def"
-- res = abbreviate_path("abc.def", {"/usr/foo"})
-- -- res is now "bar/abc.def"
-- </eucode>

public function abbreviate_path(sequence orig_path, sequence base_paths = {})
	sequence expanded_path

	-- Get full path of the parameter
	expanded_path = canonical_path(orig_path)
	
	-- Add the current directory onto the list of base search paths.
	base_paths = append(base_paths, curdir())
	
	for i = 1 to length(base_paths) do
		base_paths[i] = canonical_path(base_paths[i], 1) -- assume each base path is meant to be a directory.
	end for
	
	-- normalize for OSes with case insensitive filesystems
	-- by setting all to lowercase
	base_paths = fs_case(base_paths)
	sequence lowered_expanded_path = fs_case(expanded_path)
	
	-- The first pass is to see if the parameter begins with any of the base paths.
	for i = 1 to length(base_paths) do
		if search:begins(base_paths[i], lowered_expanded_path) then
			-- Found one, so strip it off and return the remainder.
			return expanded_path[length(base_paths[i]) + 1 .. $]
		end if
	end for
	
	-- Second pass is to try and find the given path, relative to the current directory.
	ifdef WINDOWS then
		-- If not on same drive just return what was supplied.
		if not equal(base_paths[$][1], lowered_expanded_path[1]) then
			return orig_path
		end if
	end ifdef
	
	-- Separate the current dir into its component directories.
	base_paths = stdseq:split(base_paths[$], SLASH)
	-- Separate full given path into its components.
	expanded_path = stdseq:split(expanded_path, SLASH)
	lowered_expanded_path = ""
	
	-- locate where the two paths begin to get different.
	for i = 1 to math:min({length(expanded_path), length(base_paths) - 1}) do
		if not equal(fs_case(expanded_path[i]), base_paths[i]) then
			-- Create a new path by backing up from the current dir to
			-- the point of difference and tacking on the remainder of the
			-- parameter's path.
			expanded_path = repeat("..", length(base_paths) - i) & expanded_path[i .. $]
			expanded_path = stdseq:join(expanded_path, SLASH)
			if length(expanded_path) < length(orig_path) then
				-- If the result is actually smaller then we abbreviated it.
		  		return expanded_path
			end if
			exit
		end if
	end for
	
	-- If all else fails, just return the original data.
	return orig_path
end function

--**
-- split a filename into path segments.
--
-- Parameters:
--   * ##fname## ~-- Filename to split
--
-- Returns:
--   A sequence of strings representing each path element found in ##fname##.
--
-- Example 1:
-- <eucode>
-- sequence path_elements = split_path("/usr/home/john/hello.txt")
-- -- path_elements would be { "usr", "home", "john", "hello.txt" }
-- </eucode>
--
-- Versioning:
--   * Added in 4.0.1
--
-- See Also:
--   [[:join_path]]
--

public function split_path(sequence fname)
	return stdseq:split(fname, SLASH, 1)
end function

--**
-- Join multiple path segments into a single path/filename
--
-- Parameters:
--   * ##path_elements## ~-- Sequence of path elements
--
-- Returns:
--   A string representing the path elements on the given platform
--
-- Example 1:
-- <eucode>
-- sequence fname = join_path({ "usr", "home", "john", "hello.txt" })
-- -- fname would be "/usr/home/john/hello.txt" on Unix
-- -- fname would be "\\usr\\home\\john\\hello.txt" on Windows
-- </eucode>
--
-- Versioning:
--   * Added in 4.0.1
--
-- See Also:
--   [[:split_path]]
--

public function join_path(sequence path_elements)
	sequence fname = ""

	for i = 1 to length(path_elements) do
		sequence elem = path_elements[i]

		if elem[$] = SLASH then
			elem = elem[1..$ - 1]
		end if

		if length(elem) and elem[1] != SLASH then
			ifdef WINDOWS then
				if elem[$] != ':' then
					elem = SLASH & elem
				end if
			elsedef
				elem = SLASH & elem
			end ifdef
		end if

		fname &= elem
	end for

	return fname
end function

--****
-- === File Types

public enum
	FILETYPE_UNDEFINED = -1,
	FILETYPE_NOT_FOUND,
	FILETYPE_FILE,
	FILETYPE_DIRECTORY

--**
-- gets the type of a file.
--
-- Parameters:
--   # ##filename## : the name of the file to query. It must not have wildcards.
-- 
-- Returns:
--   An **integer**,
--     * FILETYPE_UNDEFINED (-1) if file could be multiply defined (i.e., contains any wildcards - '*' or '?')
--     * FILETYPE_NOT_FOUND (0) if filename does not exist
--     * FILETYPE_FILE (1) if filename is a file
--     * FILETYPE_DIRECTORY (2) if filename is a directory
--
-- See Also:
-- [[:dir]], [[:FILETYPE_DIRECTORY]], [[:FILETYPE_FILE]], [[:FILETYPE_NOT_FOUND]],
-- [[:FILETYPE_UNDEFINED]]

public function file_type(sequence filename)
object dirfil
	if eu:find('*', filename) or eu:find('?', filename) then return FILETYPE_UNDEFINED end if
	
	ifdef WINDOWS then
		if length(filename) = 2 and filename[2] = ':' then
			filename &= "\\"
		end if
	end ifdef
	
	dirfil = dir(filename)
	if sequence(dirfil) then
		if length( dirfil ) > 1 or eu:find('d', dirfil[1][2]) or (length(filename)=3 and filename[2]=':') then
			return FILETYPE_DIRECTORY
		else
			return FILETYPE_FILE
		end if
	else
		return FILETYPE_NOT_FOUND
	end if
end function

--****
-- === File Handling
--

public enum
	SECTORS_PER_CLUSTER,
	BYTES_PER_SECTOR,
	NUMBER_OF_FREE_CLUSTERS,
	TOTAL_NUMBER_OF_CLUSTERS

public enum
	TOTAL_BYTES,
	FREE_BYTES,
	USED_BYTES

public enum
	COUNT_DIRS,
	COUNT_FILES,
	COUNT_SIZE,
	COUNT_TYPES

public enum
	EXT_NAME,
	EXT_COUNT,
	EXT_SIZE

--**
-- checks to see if a file exists.
--
-- Parameters:
--   # ##name## :  filename to check existence of
--
-- Returns:
--   An **integer**, ##1## on yes, ##0## on no.
--
-- Example 1:
-- <eucode>
-- if file_exists("abc.e") then
--     puts(1, "abc.e exists already\n")
-- end if
-- </eucode>

public function file_exists(object name)
	if atom(name) then
		return 0
	end if
	
	ifdef WINDOWS then
		atom pName = allocate_string(name)
		atom r = c_func(xGetFileAttributes, {pName})
		free(pName)

		return r > 0

	elsifdef UNIX then
		atom pName = machine:allocate_string(name)
		atom r = c_func(xGetFileAttributes, {pName, 0})
		machine:free(pName)

		return r = 0

	elsedef

		return sequence(dir(name))
	end ifdef
end function

--**
-- gets the timestamp of the file.
--
-- Parameters:
--   # ##name## : the filename to get the date of
--	 
-- Returns:
--   A valid **datetime type**, representing the files date and time or ##-1## if the
--	 file's date and time could not be read.
-- 

public function file_timestamp(sequence fname)
	object d = dir(fname)
	if atom(d) then return -1 end if
	
	return datetime:new(d[1][D_YEAR], d[1][D_MONTH], d[1][D_DAY],
		d[1][D_HOUR], d[1][D_MINUTE], d[1][D_SECOND])
end function

--**
-- copies a file.
--
-- Parameters:
-- 		# ##src## : a sequence, the name of the file or directory to copy
-- 		# ##dest## : a sequence, the new name or location of the file
-- 		# ##overwrite## : an integer; ##0## (the default) will prevent an existing destination
--                       file from being overwritten. Non-zero will overwrite the
--                       destination file.
--
-- Returns:
--     An **integer**, ##0## on failure, ##1## on success.
--
-- Comments:
--     If ##overwrite## is true, and if ##dest## file already exists,
--     the function overwrites the existing file and succeeds.
--
-- See Also:
-- [[:move_file]], [[:rename_file]]

public function copy_file(sequence src, sequence dest, integer overwrite = 0)
	
	if length(dest) then
		if file_type( dest ) = FILETYPE_DIRECTORY then
			if dest[$] != SLASH then
				dest &= SLASH
			end if
			sequence info = pathinfo( src )
			dest &= info[PATH_FILENAME]
		end if
	end if
	
	ifdef WINDOWS then
		atom psrc = allocate_string(src)
		atom pdest = allocate_string(dest)
		integer success = c_func(xCopyFile, {psrc, pdest, not overwrite})
		free({pdest, psrc})
		
	elsedef
		integer success = 0
		if file_exists(src) then
			if overwrite or not file_exists( dest ) then
				integer
					in  = open( src, "rb" ),
					out = open( dest, "wb" )
				if in != -1 and out != -1 then
					integer byte
					while byte != -1 with entry do
						puts( out, byte )
					entry
						byte = getc( in )
					end while
					success = 1
					close( in )
					close( out )
				end if
			end if
		end if
		
	end ifdef

	return success

end function

--**
-- rename a file.
-- 
-- Parameters:
-- 		# ##old_name## : a sequence, the name of the file or directory to rename.
-- 		# ##new_name## : a sequence, the new name for the renamed file
--		# ##overwrite## : an integer, ##0## (the default) to prevent renaming if destination file exists,
--                                   ##1## to delete existing destination file first
--
-- Returns:
--     An **integer**, ##0## on failure, ##1## on success.
--
-- Comments:
-- 	*	If ##new_name## contains a path specification, this is equivalent to moving the file, as 
-- 		well as possibly changing its name. However, the path must be on the same drive for 
-- 		this to work.
-- * If ##overwrite## was requested but the rename fails, any existing destination
--  file is preserved.
--
-- See Also:
-- [[:move_file]], [[:copy_file]]

public function rename_file(sequence old_name, sequence new_name, integer overwrite=0)
	atom psrc, pdest, ret
	sequence tempfile = ""

	if not overwrite then
		if file_exists(new_name) then
			return 0
		end if
	else
		if file_exists(new_name) then
			tempfile = temp_file(new_name)
			ret = move_file(new_name, tempfile)
		end if
	end if
	
	
	psrc = machine:allocate_string(old_name)
	pdest = machine:allocate_string(new_name)
	ret = c_func(xMoveFile, {psrc, pdest})
		
	ifdef UNIX then
		ret = not ret 
	end ifdef
		
	machine:free({pdest, psrc})
	
	if overwrite then
		if not ret then
			if length(tempfile) > 0 then
				-- rename was unsuccessful so restore from tempfile
				ret = move_file(tempfile, new_name)
			end if
		end if
		delete_file(tempfile)
	end if
	
	return ret
end function

ifdef LINUX then
			ifdef BITS32 then
				constant
					STAT_ST_BLKSIZE = 48,
					SIZEOF_STAT     = 88,
					$
			elsedef
				constant
					STAT_ST_BLKSIZE = 88,
					SIZEOF_STAT     = 144,
					$
			end ifdef
	
elsifdef UNIX then
		ifdef OSX then
			ifdef BITS32 then
				constant
					STAT_ST_BLKSIZE = 76,
					SIZEOF_STAT     = 108,
					$
			elsedef
				constant
					STAT_ST_BLKSIZE = 112,
					SIZEOF_STAT     = 144,
					$
			end ifdef
		elsifdef FREEBSD then
			ifdef BITS32 then
				constant
					STAT_ST_BLKSIZE = 64,
					SIZEOF_STAT     = 96,
					$
			elsedef
				constant
					STAT_ST_BLKSIZE = 88,
					SIZEOF_STAT     = 120,
					$
			end ifdef
		elsifdef OPENBSD then
			constant
				STAT_ST_BLKSIZE = 72,
				SIZEOF_STAT     = 112,
				$
		elsifdef NETBSD then
			constant
				STAT_ST_BLKSIZE = 80,
				SIZEOF_STAT     = 100,
				$
			stat_t_offset = 80
			stat_buf_size = 100
		end ifdef
end ifdef

ifdef UNIX then
	enum
		STAT_DEV,
		STAT_BLKSIZE,
		STAT_RETURN,
		$
	
	constant
		STAT_ST_DEV = 0
	
	function stat( sequence src )
		atom psrc = machine:allocate_string( src, 1 )
		atom psrcbuf = machine:allocate( SIZEOF_STAT, 1 )
		sequence stat_result = repeat( 0, STAT_RETURN )
		ifdef LINUX then
			stat_result[STAT_RETURN] = c_func(xStatFile, {STAT_VER, psrc, psrcbuf})
		elsedef
			stat_result[STAT_RETURN] = c_func(xStatFile, {psrc, psrcbuf})
		end ifdef
		ifdef OSX or FREEBSD then
			stat_result[STAT_DEV] = peek4u( psrcbuf + STAT_ST_DEV )
		elsedef
			stat_result[STAT_DEV]    = peek8u( psrcbuf + STAT_ST_DEV )
		end ifdef
		ifdef FREEBSD then
			stat_result[STAT_BLKSIZE] = peek4u( psrcbuf + STAT_ST_BLKSIZE )
		elsedef
			stat_result[STAT_BLKSIZE] = peek_pointer( psrcbuf + STAT_ST_BLKSIZE )
		end ifdef
		return stat_result
	end function
end ifdef

--**
-- moves a file to another location.
--
-- Parameters:
--   # ##src## : a sequence, the name of the file or directory to move
--   # ##dest## : a sequence, the new location for the file
--   # ##overwrite## : an integer, ##0## (the default) to prevent overwriting an existing destination file,
--                     ##1## to overwrite existing destination file
--
-- Returns:
--   An **integer**, ##0## on failure, ##1## on success.
--
-- Comments:
--  If ##overwrite## was requested but the move fails, any existing destination file is preserved.
--
-- See Also:
--   [[:rename_file]], [[:copy_file]]
public function move_file(sequence src, sequence dest, integer overwrite=0)
	atom psrc = 0, pdest = 0, ret
	sequence tempfile = ""
	if not file_exists(src) then
		return 0
	end if
	
	if not overwrite then
		if file_exists( dest ) then
			return 0
		end if
	end if

	ifdef UNIX then
		sequence src_result, dest_result
		src_result = stat( src )
		ret = src_result[STAT_RETURN]
		if ret then
			return 0
		end if
		
		dest_result = stat( dest )
		ret = dest_result[STAT_RETURN]
		if ret then
			-- Assume destination doesn't exist
			atom pdir
			if length(dirname(dest)) = 0 then
				dest_result = stat( current_dir() )
			else
				dest_result = stat( dirname( dest ) )
			end if
			ret = dest_result[STAT_RETURN]
		end if
		
		if not ret and dest_result[STAT_DEV] != src_result[STAT_DEV] then
			-- on different filesystems, can not use rename
			-- fall back on copy&delete
			if copy_file(src, dest, overwrite) then
				return delete_file(src)
			else			    
 			    return 0
 			end if
		end if
		
	end ifdef
	
	psrc  = machine:allocate_string(src, 1)
	pdest = machine:allocate_string(dest, 1)
	

	if overwrite then
		-- return value is ignored, we don't care if it existed or not
		tempfile = temp_file(dest)
		move_file(dest, tempfile)
	end if
	
	ret = c_func(xMoveFile, {psrc, pdest})
	
	ifdef UNIX then
		ret = not ret
	end ifdef
	
	if overwrite then
		if not ret then
			-- move was unsuccessful so restore tempfile
			move_file(tempfile, dest)
		end if
		delete_file(tempfile)
	end if
	return ret
end function


--**
-- returns the size of a file.
--
-- Parameters:
-- 		# ##filename## : the name of the queried file
--
-- Returns:
-- 		An **atom**, the file size, or ##-1## if file is not found.
--
-- Comments:
--     This function does not compute the total size for a directory, and returns ##0## instead.
-- See Also:
-- [[:dir]]

public function file_length(sequence filename)
	object list
	list = dir(filename)
	if atom(list) or length(list) = 0 then
		return -1
	end if
	return list[1][D_SIZE]
end function

--**
-- locates a file by looking in a set of directories for it.
--
-- Parameters:
--		# ##filename## : a sequence, the name of the file to search for.
--		# ##search_list## : a sequence, the list of directories to look in. By
--        default this is ##""##, meaning that a predefined set of directories
--        is scanned. See comments below.
--      # ##subdir## : a sequence, the sub directory within the search directories
--        to check. This is optional. 
--
-- Returns:
--     A **sequence**, the located file path if found, else the original file name.
--
-- Comments:
-- If ##filename## is an absolute path, it is just returned and no searching
-- takes place.
--
-- If ##filename## is located, the full path of the file is returned.
--
-- If ##search_list## is supplied, it can be either a sequence of directory names,
-- of a string of directory names delimited by ##':'## in //Unix// and ##';'## in //Windows//.
--
-- If the ##search_list## is omitted or ##""##, this will look in the following places~:
-- * The current directory
-- * The directory that the program is run from.
-- * The directory in ##$HOME## (##$HOMEDRIVE & $HOMEPATH## in //Windows//)
-- * The parent directory of the current directory
-- * The directories returned by ##include_paths##
-- * $EUDIR/bin
-- * $EUDIR/docs
-- * $EUDIST/
-- * $EUDIST/etc
-- * $EUDIST/data
-- * The directories listed in $USERPATH
-- * The directories listed in $PATH
--
-- If the ##subdir## is supplied, the function looks in this sub directory for each
-- of the directories in the search list.
--
-- Example 1:
-- <eucode>
--  res = locate_file("abc.def", {"/usr/bin", "/u2/someapp", "/etc"})
--  res = locate_file("abc.def", "/usr/bin:/u2/someapp:/etc")
--  res = locate_file("abc.def") 
--        -- Scan default locations.
--  res = locate_file("abc.def", , "app") 
--        -- Scan the 'app' sub directory in the default locations.
-- </eucode>

public function locate_file(sequence filename, sequence search_list = {}, sequence subdir = {})
	object extra_paths
	sequence this_path
	
	if absolute_path(filename) then
		return filename
	end if

	if length(search_list) = 0 then
		search_list = append(search_list, "." & SLASH)
		
		extra_paths = command_line()
		extra_paths = canonical_path(dirname(extra_paths[2]), 1)
		search_list = append(search_list, extra_paths)

		ifdef UNIX then
			extra_paths = getenv("HOME")
			
		elsedef
			extra_paths = getenv("HOMEDRIVE") & getenv("HOMEPATH")
		end ifdef		
			
		if sequence(extra_paths) then
			search_list = append(search_list, extra_paths & SLASH)
		end if				
				
		search_list = append(search_list, ".." & SLASH)
		
		extra_paths = getenv("EUDIR")
		if sequence(extra_paths) then
			search_list = append(search_list, extra_paths & SLASH & "bin" & SLASH)
			search_list = append(search_list, extra_paths & SLASH & "docs" & SLASH)
		end if
		
		extra_paths = getenv("EUDIST")
		if sequence(extra_paths) then
			search_list = append(search_list, extra_paths & SLASH)
			search_list = append(search_list, extra_paths & SLASH & "etc" & SLASH)
			search_list = append(search_list, extra_paths & SLASH & "data" & SLASH)
		end if
		
		ifdef UNIX then
			-- typical install directories:
			search_list = append( search_list, "/usr/local/share/euphoria/bin/" )
			search_list = append( search_list, "/usr/share/euphoria/bin/" )
		end ifdef
		
		search_list &= include_paths(1)
		
		
		extra_paths = getenv("USERPATH")
		if sequence(extra_paths) then
			extra_paths = stdseq:split(extra_paths, PATHSEP)
			search_list &= extra_paths
		end if
		
		extra_paths = getenv("PATH")
		if sequence(extra_paths) then
			extra_paths = stdseq:split(extra_paths, PATHSEP)
			search_list &= extra_paths
		end if
	else
		if integer(search_list[1]) then
			search_list = stdseq:split(search_list, PATHSEP)
		end if
	end if

	if length(subdir) > 0 then
		if subdir[$] != SLASH then
			subdir &= SLASH
		end if	
	end if
			
	for i = 1 to length(search_list) do
		if length(search_list[i]) = 0 then
			continue
		end if
		
		if search_list[i][$] != SLASH then
			search_list[i] &= SLASH
		end if

		
		if length(subdir) > 0 then
			this_path = search_list[i] & subdir & filename
		else
			this_path = search_list[i] & filename
		end if
		
		if file_exists(this_path) then
			return canonical_path(this_path)
		end if		
		
	end for
	return filename
end function

--**
-- returns some information about a disk drive.
--
-- Parameters:
--	# ##disk_path## : A sequence. This is the path that identifies the disk to inquire upon.
--
-- Returns:
--     A **sequence**, containing ##SECTORS_PER_CLUSTER##, ##BYTES_PER_SECTOR##, 
--                     ##NUMBER_OF_FREE_CLUSTERS##, and ##TOTAL_NUMBER_OF_CLUSTERS##
--
-- Example 1:
-- <eucode>
-- res = disk_metrics("C:\\")
-- min_file_size = res[SECTORS_PER_CLUSTER] * res[BYTES_PER_SECTOR]
-- </eucode>

public function disk_metrics(object disk_path) 
	sequence result = {0, 0, 0, 0} 
	atom path_addr = 0
	atom metric_addr = 0
	
	ifdef WINDOWS then
		if sequence(disk_path) then 
			path_addr = allocate_string(disk_path) 
		else 
			path_addr = 0 
		end if 
	 
		metric_addr = allocate(16) 
	 
		if c_func(xGetDiskFreeSpace, {path_addr, 
		                               metric_addr + 0,
		                               metric_addr + 4,
		                               metric_addr + 8,
		                               metric_addr + 12
		                               }) then 
			result = peek4s({metric_addr, 4}) 
		end if 
	 
		free({path_addr, metric_addr}) 
	elsifdef UNIX then
	
		sequence size_of_disk = {0,0,0}

		atom bytes_per_cluster
		atom ret
		integer stat_t_offset, stat_buf_size

		sequence stat_result = stat( disk_path )
		ret               = stat_result[STAT_RETURN]
		bytes_per_cluster = stat_result[STAT_BLKSIZE]

		if ret then
			-- failure
			return result 
		end if

		size_of_disk = disk_size(disk_path)
		
		-- this is hardcoded for now, but may be x86 specific
		-- on other Unix platforms that run on non x86 hardware, this
		-- may need to be changed - there is no portable way to get this
		result[BYTES_PER_SECTOR] = 512

		result[SECTORS_PER_CLUSTER] = bytes_per_cluster / result[BYTES_PER_SECTOR]
		result[TOTAL_NUMBER_OF_CLUSTERS] = size_of_disk[TOTAL_BYTES] / bytes_per_cluster
		result[NUMBER_OF_FREE_CLUSTERS] = size_of_disk[FREE_BYTES] / bytes_per_cluster

	end ifdef 
	
	return result 
end function 
 
--**
-- returns the amount of space for a disk drive.
--
-- Parameters:
--	# ##disk_path## : A sequence. This is the path that identifies the disk to inquire upon.
--
-- Returns:
--     A **sequence**, containing ##TOTAL_BYTES##, ##USED_BYTES##, ##FREE_BYTES##, and a string which represents the filesystem name
--
-- Example 1:
-- <eucode>
-- res = disk_size("C:\\")
-- printf(1, "Drive %s has %3.2f%% free space\n", { 
--     "C:", res[FREE_BYTES] / res[TOTAL_BYTES]
-- })
-- </eucode>

public function disk_size(object disk_path) 
	sequence disk_size = {0,0,0, disk_path}
	
	ifdef WINDOWS then
		sequence result 
		atom bytes_per_cluster
		
	
		result = disk_metrics(disk_path) 
		
		bytes_per_cluster = result[BYTES_PER_SECTOR] * result[SECTORS_PER_CLUSTER]
	
		disk_size[TOTAL_BYTES] = bytes_per_cluster * result[TOTAL_NUMBER_OF_CLUSTERS] 
		disk_size[FREE_BYTES]  = bytes_per_cluster * result[NUMBER_OF_FREE_CLUSTERS] 
		disk_size[USED_BYTES]  = disk_size[TOTAL_BYTES] - disk_size[FREE_BYTES] 
	elsifdef UNIX then
		integer temph
		sequence tempfile
		object data
		sequence filesys = ""

		tempfile = "/tmp/eudf" & sprintf("%d", rand(1000)) & ".tmp"
		system("df -k "&disk_path&" > "&tempfile, 2)

		temph = open(tempfile, "r")
		if temph = -1 then
			-- failure
			return disk_size
		end if
		-- skip the human readable header
		data = gets(temph)
		-- skip the name of the device node
		while 1 do 
			data = getc(temph)
			if find(data," \t\r\n") then
				exit
			end if
			if data = -1 then
				-- failure
				close(temph)
				temph = delete_file(tempfile)
				disk_size[4] = filesys
				return disk_size
			end if
			filesys &= data
			
		end while

		data = stdget:get(temph)
		disk_size[TOTAL_BYTES] = data[2] * 1024
		data = stdget:get(temph)
		disk_size[USED_BYTES] = data[2] * 1024
		data = stdget:get(temph)
		disk_size[FREE_BYTES] = data[2] * 1024
		disk_size[4] = filesys

		close(temph)
		temph = delete_file(tempfile)

	end ifdef 
	
	return disk_size 
end function 

sequence file_counters = {}

-- Parameter inst contains two items: 'count_all' flag, and 'index' into file_counters.

function count_files(sequence orig_path, sequence dir_info, sequence inst)
	integer pos = 0
	sequence ext

	orig_path = orig_path
	if equal(dir_info[D_NAME], ".") then
		return 0
	end if
	if equal(dir_info[D_NAME], "..") then
		return 0
	end if
	
	
	if inst[1] = 0 then -- count all is false
		if find('h', dir_info[D_ATTRIBUTES]) then
			return 0
		end if
		
		if find('s', dir_info[D_ATTRIBUTES]) then
			return 0
		end if
	end if
		
	file_counters[inst[2]][COUNT_SIZE] += dir_info[D_SIZE]
	if find('d', dir_info[D_ATTRIBUTES]) then
		file_counters[inst[2]][COUNT_DIRS] += 1
	else
		file_counters[inst[2]][COUNT_FILES] += 1
		ifdef not UNIX then
			ext = fileext(lower(dir_info[D_NAME]))
		elsedef
			ext = fileext(dir_info[D_NAME])
		end ifdef
			
		pos = 0
		for i = 1 to length(file_counters[inst[2]][COUNT_TYPES]) do
			if equal(file_counters[inst[2]][COUNT_TYPES][i][EXT_NAME], ext) then
				pos = i
				exit
			end if
		end for

		if pos = 0 then
			file_counters[inst[2]][COUNT_TYPES] &= {{ext, 0, 0}}
			pos = length(file_counters[inst[2]][COUNT_TYPES])
		end if

		file_counters[inst[2]][COUNT_TYPES][pos][EXT_COUNT] += 1
		file_counters[inst[2]][COUNT_TYPES][pos][EXT_SIZE] += dir_info[D_SIZE]
	end if

	return 0
end function


--**
-- returns the amount of space used by a directory.
--
-- Parameters:
--	# ##dir_path## : A sequence. This is the path that identifies the directory to inquire upon.
--  # ##count_all## : An integer. Used by //Windows// systems. If zero (the default) 
--                    it will not include //system// or //hidden// files in the
--                    count, otherwise they are included.
--
-- Returns:
--   A **sequence**, containing four elements; the number of sub-directories ##[COUNT_DIRS]##,
--   the number of files ##[COUNT_FILES]##, the total space used by the directory ##[COUNT_SIZE]##, 
--   and breakdown of the file contents by file extension ##[COUNT_TYPES]##.
--                  
-- Comments:
--  * The total space used by the directory does not include space used by any sub-directories.
--  * The file breakdown is a sequence of three-element sub-sequences. Each sub-sequence
--    contains the extension ##[EXT_NAME]##, the number of files of this extension ##[EXT_COUNT]##,
--    and the space used by these files ##[EXT_SIZE]##. The sub-sequences are presented in
--    extension name order. On //Windows// the extensions are all in lowercase.
--
-- Example 1:
-- <eucode>
-- res = dir_size("/usr/localbin")
-- printf(1, "Directory %s contains %d files\n", {
--         "/usr/localbin", res[COUNT_FILES]
--     })
-- for i = 1 to length(res[COUNT_TYPES]) do
--     printf(1, "Type: %s (%d files %d bytes)\n", {
--         res[COUNT_TYPES][i][EXT_NAME],
--         res[COUNT_TYPES][i][EXT_COUNT],
--         res[COUNT_TYPES][i][EXT_SIZE]
--     })
-- end for
-- </eucode>

public function dir_size(sequence dir_path, integer count_all = 0)
	sequence fc

	-- We create our own instance of the global 'file_counters' to use in case
	-- the application is using threads.
	
	file_counters = append(file_counters, {0,0,0,{}})
	walk_dir(dir_path, {routine_id("count_files"), {count_all, length(file_counters)}}, 0)
	
	fc = file_counters[$]
	file_counters = file_counters[1 .. $-1]
	fc[COUNT_TYPES] = stdsort:sort(fc[COUNT_TYPES])

	return fc
end function

--**
-- returns a file name that can be used as a temporary file.
--
-- Parameters:
--	# ##temp_location## : A sequence. A directory where the temporary file is expected
--               to be created. 
--            ** If omitted (the default) the 'temporary' directory
--               will be used. The temporary directory is defined in the "TEMP" 
--               environment symbol, or failing that the "TMP" symbol and failing
--               that "C:\TEMP\" is used on //Windows// systems and "/tmp/" is used
--               on //Unix// systems. 
--            ** If ##temp_location## was supplied, 
--               *** If it is an existing file, that file's directory is used.
--               *** If it is an existing directory, it is used.
--               *** If it doesn't exist, the directory name portion is used.
--  # ##temp_prefix## : A sequence: The is prepended to the start of the generated file name.
--               The default is ##""## .
--  # ##temp_extn## : A sequence: The is a file extention used in the generated file. 
--               The default is ##"_T_"## .
--  # ##reserve_temp## : An integer: If not zero an empty file is created using the 
--               generated name. The default is not to reserve (create) the file.
--
-- Returns:
--   A **sequence**, A generated file name.
--                  
-- Example 1:
-- <eucode>
-- temp_file("/usr/space", "myapp", "tmp") --> /usr/space/myapp736321.tmp
-- temp_file() --> /tmp/277382._T_
-- temp_file("/users/me/abc.exw") --> /users/me/992831._T_
-- </eucode>
--

public function temp_file(sequence temp_location = "", sequence temp_prefix = "", sequence temp_extn = "_T_", integer reserve_temp = 0)
	sequence  randname
	
	if length(temp_location) = 0 then
		object envtmp
		envtmp = getenv("TEMP")
		if atom(envtmp) then
			envtmp = getenv("TMP")
		end if
		ifdef WINDOWS then			
			if atom(envtmp) then
				envtmp = "C:\\temp\\"
			end if
		elsedef
			if atom(envtmp) then
				envtmp = "/tmp/"
			end if
		end ifdef
		temp_location = envtmp
	else
		switch file_type(temp_location) do
			case FILETYPE_FILE then
				temp_location = dirname(temp_location, 1)
				
			case FILETYPE_DIRECTORY then
				-- use temp_location
				temp_location = temp_location
								
			case FILETYPE_NOT_FOUND then
				object tdir = dirname(temp_location, 1)
				if file_exists(tdir) then
					temp_location = tdir
				else
					temp_location = "."
				end if
				
			case else
				temp_location = "."
				
		end switch
	end if
	
	if temp_location[$] != SLASH then
		temp_location &= SLASH
	end if
	
	if length(temp_extn) and temp_extn[1] != '.' then
		temp_extn = '.' & temp_extn
	end if
	
	while 1 do
		randname = sprintf("%s%s%06d%s", {temp_location, temp_prefix, rand(1_000_000) - 1, temp_extn})
		if not file_exists( randname ) then
			exit
		end if
	end while
	
	if reserve_temp then
		-- Reserve the name by creating an empty file.
		if not file_exists(temp_location) then
			if create_directory(temp_location) = 0 then
				return ""
			end if
		end if
		io:write_file(randname, "")
	end if
	
	return randname
	
end function


--**
-- returns a checksum value for the specified file.
--
-- Parameters:
--	# ##filename## : A sequence. The name of the file whose checksum you want.
--  # ##size## : An integer. The number of atoms to return. Default is 4 
--  # ##usename##: An integer. If not zero then the actual text of ##filename## will
--  affect the resulting checksum. The default (##0##) will not use the name of
--  the file.
--  # ##return_text##: An integer. If not zero, the check sum is returned as a
--  text string of hexadecimal digits otherwise (the default) the check sum
--  is returned as a sequence of ##size## atoms.
--
-- Returns:
--     A **sequence** containing ##size## atoms.
--                  
-- Comments:
--  * The larger the ##size## value, the more unique will the checksum be. For 
-- most files and uses, a single atom will be sufficient as this gives a 32-bit
-- file signature. However, if you require better proof that the content of two
-- files are different then use higher values for ##size##. For example, 
-- ##size = 8## gives you 256 bits of file signature.
-- * If ##size## is zero or negative, an empty sequence is returned.
-- * All files of zero length will return the same checksum value when ##usename##
--  is zero.
--
-- Example 1:
-- <eucode>
--  -- Example values. The exact values depend on the contents of the file.
--  include std/console.e
--  display( checksum("myfile", 1) ) --> {92837498}
--  display( checksum("myfile", 2) ) --> {1238176, 87192873}
--  display( checksum("myfile", 2,,1)) --> "0012E480 05327529"
--  display( checksum("myfile", 4) ) --> {23448, 239807, 79283749, 427370}
--  display( checksum("myfile") )    --> {23448, 239807, 79283749, 427370} -- default
-- </eucode>

public function checksum(sequence filename, integer size = 4, integer usename = 0, integer return_text = 0)
	integer fn
	sequence cs
	sequence hits
	integer ix	
	atom jx
	atom fx
	sequence data
	integer nhit
	integer nmiss
	
	if size <= 0 then
		-- No checksum can be done.
		return {}
	end if
	fn = open(filename, "rb")
	if fn = -1 then
		-- No checksum can be done.
		return {}
	end if
	
	-- Initialize the result array based on the file's length and size of the array.
	jx = file_length(filename)
	cs = repeat(jx, size)
	for i = 1 to size do
		cs[i] = hash(i + size, cs[i])
	end for

	-- If filename is to be used, then seed each checksum bucket with a character
	-- from the file name plus the hash of the entire name. All buckets and
	-- every character is used to do this.	
	if usename != 0 then
		nhit = 0
		nmiss = 0
		hits = {0,0}
		fx = hash(filename, stdhash:HSIEH32) -- Get a hash value for the whole name.
		while find(0, hits) do
			-- find next character to use.
			nhit += 1
			if nhit > length(filename) then
				nhit = 1
				hits[1] = 1
			end if
			-- find next bucket to use.
			nmiss += 1
			if nmiss > length(cs) then
				nmiss = 1
				hits[2] = 1
			end if
			
			-- adjust the bucket's seed value
			cs[nmiss] = hash(filename[nhit], xor_bits(fx, cs[nmiss]))
		end while -- repeat until every bucket and every character has been used.
	end if
	
	hits = repeat(0, size)
	if jx != 0 then
		-- File is not empty file.
	
		-- Process the file, one set of bytes at a time
		-- The size of the byte set is dependant on the file length and the check sum length requested,
		-- and it is some value between 7 and 14 bytes long.
		data = repeat(0, remainder( hash(jx * jx / size , stdhash:HSIEH32), 8) + 7)
		
	
		while data[1] != -1 with entry do
			-- Determine which array entry gets affected. 
			-- Depends on the current byte value, array size and initial file length
			jx = hash(jx, data)
			ix = remainder(jx, size) + 1
			-- Change the index offset determinant for the next byte.
			
			-- flip some bits in the array, based on the byte set and current hash.
			cs[ix] = xor_bits(cs[ix], hash(data, stdhash:HSIEH32))
			hits[ix] += 1
							
		entry
			-- get the next set of bytes.
			-- Note that if a file ends before the 'set' is filled,
			-- this algorithm still uses the -1 values as if it were
			-- data from the file. This is by design to speed up the
			-- calculations.
			for i = 1 to length(data) do
				data[i] = getc(fn)
			end for
		end while
	
		-- Check for the situation where not all the check sum buckets have been
		-- updated. In this situation, use the affected buckets to update the ones
		-- not yet affected.
		nhit = 0
		while nmiss with entry do
			-- Find next 'affected' bucket to use.
			while 1 do
				nhit += 1
				if nhit > length(hits) then
					nhit = 1
				end if
				if hits[nhit] != 0 then
					exit
				end if
			end while
			
			-- Update the missed one.
			cs[nmiss] = hash(cs[nmiss], cs[nhit])
			hits[nmiss] += 1
		entry
			-- Find next missed bucket.
			nmiss = find(0, hits)	
		end while
	
	end if

	close(fn)
	if return_text then
		-- Convert set of atoms to fixed length (8) hex strings.
		sequence cs_text = ""
		for i = 1 to length(cs) do
			cs_text &= text:format("[:08X]", cs[i])
			if i != length(cs) then
				-- Add a space in between each 8-digit set
				cs_text &= ' '
			end if
		end for
		
		return cs_text
	else
		return cs
	end if
end function

