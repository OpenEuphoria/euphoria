-- (c) Copyright - See License.txt
--
--****
-- == File System
--
-- Cross platform file operations for Euphoria
--
-- <<LEVELTOC depth=2>>
namespace filesys

include std/dll.e

include std/machine.e
include std/wildcard.e
include std/sort.e
include std/search.e
include std/machine.e
include std/sequence.e
include std/types.e
include std/text.e
include std/io.e
include std/datetime.e as dt

ifdef UNIX then
	include std/get.e -- for disk_size()
end ifdef

constant
	M_DIR	      = 22,
	M_CURRENT_DIR = 23,
	M_CHDIR       = 63

ifdef WIN32 then
	constant lib = open_dll("kernel32")
	constant xCopyFile         = define_c_func(lib, "CopyFileA",   {C_POINTER, C_POINTER, C_BOOL},
		C_BOOL)
	constant xMoveFile         = define_c_func(lib, "MoveFileA",   {C_POINTER, C_POINTER}, C_BOOL)
	constant xDeleteFile       = define_c_func(lib, "DeleteFileA", {C_POINTER}, C_BOOL)
	constant xCreateDirectory  = define_c_func(lib, "CreateDirectoryA", 
		{C_POINTER, C_POINTER}, C_BOOL)
	constant xRemoveDirectory  = define_c_func(lib, "RemoveDirectoryA", {C_POINTER}, C_BOOL)
	constant xGetFileAttributes= define_c_func(lib, "GetFileAttributesA", {C_POINTER}, C_INT) -- N.B DWORD return fails this.
	constant xGetDiskFreeSpace = define_c_func(lib, "GetDiskFreeSpaceA", 
		{C_POINTER, C_POINTER, C_POINTER, C_POINTER, C_POINTER}, C_BOOL)	 

elsifdef LINUX then
	constant lib = open_dll("")

elsifdef FREEBSD or SUNOS or OPENBSD then
	constant lib = open_dll("libc.so")
	
elsifdef OSX then
	constant lib = open_dll("libc.dylib")

elsedef
	constant xCopyFile          = -1
	constant xMoveFile          = -1
	constant xDeleteFile        = -1
	constant xCreateDirectory   = -1
	constant xRemoveDirectory   = -1
	constant xGetFileAttributes = -1

end ifdef

ifdef LINUX then
	constant xStatFile = define_c_func(lib, "__xstat", {C_INT, C_POINTER, C_POINTER}, C_INT)
elsifdef UNIX then
	constant xStatFile = define_c_func(lib, "stat", {C_POINTER, C_POINTER}, C_INT)
end ifdef

ifdef UNIX then
	constant xMoveFile        = define_c_func(lib, "rename", {C_POINTER, C_POINTER}, C_INT)
	--constant xDeleteFile      = define_c_func(lib, "remove", {C_POINTER}, C_LONG)
	constant xDeleteFile      = define_c_func(lib, "unlink", {C_POINTER}, C_INT)
	constant xCreateDirectory = define_c_func(lib, "mkdir", {C_POINTER, C_INT}, C_INT)
	constant xRemoveDirectory = define_c_func(lib, "rmdir", {C_POINTER}, C_INT)
	constant xGetFileAttributes = define_c_func(lib, "access", {C_POINTER, C_INT}, C_INT)
end ifdef


--****
-- === Constants

--****
-- Signature:
-- public constant SLASH
--
-- Description:
-- Current platform's path separator character
--
-- Comments:
-- When on //Windows//, '~\\'. When on //Unix//, '/'.
--

--****
-- Signature:
-- public constant SLASHES
--
-- Description:
-- Current platform's possible path separators. This is slightly different
-- in that on //Windows// the path separators variable contains
-- ##~\~\## as well as ##~:## and ##/## as newer //Windows// versions support
-- ##/## as a path separator. On //Unix// systems, it only contains ##/##.

--****
-- Signature:
-- public constant SLASHES
--
-- Description:
-- Current platform's possible path separators. This is slightly different
-- in that on //Windows// the path separators variable contains
-- ##~\~\## as well as ##~:## and ##/## as newer //Windows// versions support
-- ##/## as a path separator. On //Unix// systems, it only contains ##/##.

--****
-- Signature:
-- public constant EOLSEP
--
-- Description:
-- Current platform's newline string: ##"\n"## on //Unix//, else ##"\r\n"##.

--****
-- Signature:
-- public constant EOL
--
-- Description:
-- All platform's newline character: ##'\n'##. When text lines are read the native
-- platform's EOLSEP string is replaced by a single character EOL.

--****
-- Signature:
-- public constant PATHSEP
--
-- Description:
-- Current platform's path separator character: ##:## on //Unix//, else ##;##.

--****
-- Signature:
-- public constant NULLDEVICE
--
-- Description:
-- Current platform's null device path: ##/dev/null## on //Unix//, else ##NUL:##.

--****
-- Signature:
-- public constant SHARED_LIB_EXT
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
	D_SECOND

--**
-- Bad path error code. See [[:walk_dir]]

public constant W_BAD_PATH = -1 -- error code


--**
-- Return directory information for the specified file or directory.
--
-- Parameters:
--     # ##name## : a sequence, the name to be looked up in the file system.
--
-- Returns:
--     An **object**,  -1 if no match found, else a sequence of sequence entries
--
-- Errors:
-- The length of ##name## should not exceed 1,024 characters.
--
-- Comments:
--     ##name## can also contain * and ? wildcards to select multiple files.
--
-- The returned information is similar to what you would get from the DIR command. A sequence
-- is returned where each element is a sequence that describes one file or subdirectory.
-- 
-- If ##name## refers to a **directory** you may have entries for "." and "..", just as with the 
-- DIR command. If it refers to an existing **file**, and has no wildcards, then the returned 
-- sequence will have just one entry, i.e. its length will be 1. If ##name## contains wildcards 
-- you may have multiple entries.
-- 
-- Each entry contains the name, attributes and file size as well as
-- the year, month, day, hour, minute and second of the last modification.
-- You can refer to the elements of an entry with the following constants:
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
--     D_SECOND     = 9
-- </eucode>
--
-- The attributes element is a string sequence containing characters chosen from:
--  
-- || Attribute || Description ||
-- | 'd'         | directory
-- | 'r'         | read only file
-- | 'h'         | hidden file
-- | 's'         | system file
-- | 'v'         | volume-id entry
-- | 'a'         | archive file
--
-- A normal file without special attributes would just have an empty string, "", in this field.
--
-- The top level directory, e.g. c:\ does not have "." or ".." entries.
-- 
-- This function is often used just to test if a file or directory exists.
-- 
-- Under //WIN32//, st can have a long file or directory name anywhere in 
-- the path.
-- 
-- Under //Unix//, the only attribute currently available is 'd'.
-- 
-- //WIN32//: The file name returned in D_NAME will be a long file name.
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
	object dir_data, data, the_name, the_dir
	integer idx

	-- Did the user give a wildcard? If not, just return the standard dir.
	if eu:find('*', name) > 0 or eu:find('?', name) > 0 then
		-- Empty if so that we can short circuit if * is found, otherwise
		-- we would have to run a search for * and ? even if * is found.
	else
		return machine_func(M_DIR, name)
	end if

	-- Is there a path involved?
	if eu:find(SLASH, name) = 0 then
		the_dir = "."
		the_name = name
	else
		-- Find a SLASH character and break the name there resulting in
		-- a directory and file name.
		idx = rfind(SLASH, name)
		the_dir = name[1 .. idx]
		the_name = name[idx+1 .. $]
	end if

	-- Get directory contents
	dir_data = machine_func(M_DIR, the_dir)

	-- Did an error occur?
	if atom(dir_data) then
		return dir_data
	end if

	data = {}
	-- Filter the directory contents returning only those items
	-- matching name.
	for i = 1 to length(dir_data) do
 		if wildcard_file(the_name, dir_data[i][1]) then
 				data = append(data, dir_data[i])
 		end if
	end for

	if not length(data) then
		-- no matches found, act like it doesn't exist
		return -1
	end if
	return data
end function

--**
-- Return the name of the current working directory.
--
-- Returns:
--		A **sequence**, the name of the current working directory
--
-- Comments:
-- There will be no slash or backslash on the end of the current directory, except under
-- //Windows//, at the top-level of a drive, e.g. C:\
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
-- Set a new value for the current directory 
--
-- Parameters:
-- 		##newdir## : a sequence, the name for the new working directory.
--
-- Returns:
-- 		An **integer**, 0 on failure, 1 on success.
--
-- Comments:
-- By setting the current directory, you can refer to files in that directory using just
-- the file name.
-- 
-- The [[:current_dir]]() function will return the name of the current directory.
-- 
-- On //WIN32// the current directory is a public property shared
-- by all the processes running under one shell. On //Unix// a subprocess
-- can change the current directory for itself, but this won't
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
		return sort(d)
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
-- 	# ##scan_subdirs## : an optional integer, 1 to also walk though subfolders, 0 (the default) to skip them all.
--  # ##dir_source## : an optional integer. A routine_id of a user-defined routine that 
--                    returns the list of paths to pass to ##your_function##. If omitted,
--                    the [[:dir]]() function is used.   
--
-- Returns:
-- An **object**,
-- * 0 on success
-- * W_BAD_PATH: an error occurred
-- * anything else: the custom function returned something to stop [[:walk_dir]]().
--
-- Comments:
-- This routine will "walk" through a directory named ##path_name##. For each entry in the 
-- directory, it will call a function, whose routine_id is ##your_function##.
-- If ##scan_subdirs## is non-zero (TRUE), then the subdirectories in
-- ##path_name## will be walked through recursively in the very same way.
--
-- The routine that you supply should accept two sequences, the path name and dir() entry for 
-- each file and subdirectory. It should return 0 to keep going, or non-zero to stop 
-- ##walk_dir##(). Returning ##W_BAD_PATH## is taken as denoting some error.
--
-- This mechanism allows you to write a simple function that handles one file at a time, 
-- while ##walk_dir##() handles the process of walking through all the files and subdirectories.
--
-- By default, the files and subdirectories will be visited in alphabetical order. To use 
-- a different order, use the ##dir_source## to pass the routine_id of your own modified
-- [[:dir]] function that sorts the directory entries differently.
--
-- The path that you supply to ##walk_dir()## must not contain wildcards (* or ?). Only a 
-- single directory (and its subdirectories) can be searched at one time.
--
-- For non-unix systems, any '/' characters in ##path_name## are replaced with '\'.
--
-- All trailing slash and whitespace characters are removed from ##path_name##.
--
-- Example 1:
-- <eucode>
-- function look_at(sequence path_name, sequence item)
-- -- this function accepts two sequences as arguments
-- -- it displays all C/C++ source files and their sizes
--     if find('d', item[D_ATTRIBUTES]) then
--         return 0 -- Ignore directories
--     end if
--     if not find(fileext(item[D_NAME]), {"c,h,cpp,hpp,cp"}) then
--         return 0 -- ignore non-C/C++ files
--     end if
--     printf(STDOUT, "%s%s%s: %d\n",
--            {path_name, SLASH, item[D_NAME], item[D_SIZE]})
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
-- exit_code = walk_dir("C:\\MYFILES\\", routine_id("look_at"), TRUE, routine_id("mysort"))
-- </eucode>
--
-- See Also:
--   [[:dir]], [[:sort]], [[:sort_columns]]

public function walk_dir(sequence path_name, object your_function, integer scan_subdirs = FALSE, object dir_source = -1)
	object d, abort_now
	object orig_func
	sequence user_data = {path_name, 0}
	object source_orig_func
	object source_user_data
	
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
	if not equal(dir_source, -1) then
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
		path_name = replace_all(path_name, '/', '\\')
	end ifdef
	path_name = trim_tail(path_name, {' ', SLASH, '\n'})
	user_data[1] = path_name
	
	for i = 1 to length(d) do
		if eu:find(d[i][D_NAME], {".", ".."}) then
			continue
		end if
		
		user_data[2] = d[i]
		abort_now = call_func(your_function, user_data)
		if not equal(abort_now, 0) then
			return abort_now
		end if
		
		if eu:find('d', d[i][D_ATTRIBUTES]) then
			-- a directory
			if scan_subdirs then
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
-- Create a new directory.
--
-- Parameters:
-- 		# ##name## : a sequence, the name of the new directory to create
--		# ##mode## : on //Unix// systems, permissions for the new directory. Default is 
--		  448 (all rights for owner, none for others).
--      # ##mkparent## : If true (default) the parent directories are also created
--        if needed. 
--
-- Returns:
--     An **integer**, 0 on failure, 1 on success.
--
-- Comments:
-- 		##mode## is ignored on non-Unix platforms.
--
-- Example 1:
-- <eucode>
-- if not create_directory("the_new_folder") then
--		crash("Filesystem problem - could not create the new folder")
-- end if
-- 
-- -- This example will also create "myapp/" and "myapp/interface/" if they don't exist.
-- if not create_directory("myapp/interface/letters") then
--		crash("Filesystem problem - could not create the new folder")
-- end if
--
-- -- This example will NOT create "myapp/" and "myapp/interface/" if they don't exist.
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
		return 1
	end if
	
	-- Remove any trailing slash.
	if name[$] = SLASH then
		name = name[1 .. $-1]
	end if
	
	if mkparent != 0 then
		pos = rfind(SLASH, name)
		if pos != 0 then
			ret = create_directory(name[1.. pos-1], mode, mkparent)
		end if
	end if
	
	pname = allocate_string(name)

	ifdef UNIX then
		ret = not c_func(xCreateDirectory, {pname, mode})
	elsifdef WIN32 then
		ret = c_func(xCreateDirectory, {pname, 0})
		mode = mode -- get rid of not used warning
	end ifdef

	return ret
end function

--**
-- Delete a file.
--
-- Parameters:
-- 		# ##name## : a sequence, the name of the file to delete.
--
-- Returns:
--     An **integer**, 0 on failure, 1 on success.

public function delete_file(sequence name)
	atom pfilename = allocate_string(name)
	integer success = c_func(xDeleteFile, {pfilename})
		
	ifdef UNIX then
		success = not success
	end ifdef
	
	free(pfilename)

	return success
end function

--**
-- Returns the current directory, with a trailing SLASH
--
-- Parameters:
--		# ##drive_id## : For non-Unix systems only. This is the Drive letter to
--      to get the current directory of. If omitted, the current drive is used.
--
-- Returns:
--     A **sequence**, the current directory.
--
-- Comment:
--  Windows maintain a current directory for each disk drive. You
--  would use this routine if you wanted the current directory for a drive that
--  may not be the current drive.
--
--  For Unix systems, this is simply ignored because there is only one current
--  directory at any time on Unix.
--
-- Note: 
-- This always ensures that the returned value has a trailing SLASH
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
	    object void
	
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
	    	void = chdir(lOrigDir[1..2])
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
-- Returns the original current directory
--
-- Parameters:
--		# None.
--
-- Returns:
--     A **sequence**, the current directory at the time the program started running.
--
-- Comment:
-- You would use this if the program might change the current directory during
-- its processing and you wanted to return to the original directory.
--
-- Note: 
-- This always ensures that the returned value has a trailing SLASH
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
-- Clear (delete) a directory of all files, but retaining sub-directories.
--
-- Parameters:
--		# ##name## : a sequence, the name of the directory whose files you want to remove.
--		# ##recurse## : an integer, whether or not to remove files in the 
--        directory's sub-directories. If 0 then this function is identical
--        to remove_directory(). If 1, then we recursively delete the
--        directory and its contents. Defaults to 1.
--
-- Returns:
--     An **integer**, 0 on failure, otherwise the number of files plus 1.
--
-- Comment:
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
	ifdef WIN32 then
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
	if not equal(files[1][D_NAME], ".") then
		return 0 -- Supplied name was not a directory
	end if
	
	ret = 1
	path &= SLASH
	
	for i = 1 to length(files) do
		if eu:find(files[i][D_NAME], {".", ".."}) then
			continue
		elsif eu:find('d', files[i][D_ATTRIBUTES]) then
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
	return ret
end function

--**
-- Remove a directory.
--
-- Parameters:
--		# ##name## : a sequence, the name of the directory to remove.
--      # ##force## : an integer, if 1 this will also remove files and
--                    sub-directories in the directory. The default is
--                   0, which means that it will only remove the
--                   directory if it is already empty.
--
-- Returns:
--     An **integer**, 0 on failure, 1 on success.
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
	
	ifdef WIN32 then
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
	if not equal(files[1][D_NAME], ".") then
		return 0	-- Supplied dir_name was not a directory
	end if
	
	
	dir_name &= SLASH
	
	for i = 1 to length(files) do
		if eu:find(files[i][D_NAME], {".", ".."}) then
			continue
			
		elsif not force then
			return 0
		else
			if eu:find('d', files[i][D_ATTRIBUTES]) then
				ret = remove_directory(dir_name & files[i][D_NAME] & SLASH, force)
			else
				ret = delete_file(dir_name & files[i][D_NAME])
			end if
			if not ret then
				return 0
			end if
		end if
	end for
	
	pname = allocate_string(dir_name)
	ret = c_func(xRemoveDirectory, {pname})
	ifdef UNIX then
			ret = not ret 
	end ifdef
	free(pname)
	return ret
end function


--****
-- === File name parsing

public enum
	PATH_DIR,
	PATH_FILENAME,
	PATH_BASENAME,
	PATH_FILEEXT,
	PATH_DRIVEID

--**
-- Parse a fully qualified pathname.
-- Parameters:
-- 		# ##path## : a sequence, the path to parse
--
-- Returns:
-- 		A **sequence**, of length 5. Each of these elements is a string:
-- 		* The path name
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
-- -- WIN32
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
			dir_name = replace_all(dir_name, from_slash, std_slash)
		else
			dir_name = replace_all(dir_name, "\\", std_slash)
			dir_name = replace_all(dir_name, "/", std_slash)
		end if
	end if

	return {dir_name, file_full, file_name, file_ext, drive_id}
end function

--**
-- Return the directory name of a fully qualified filename
--
-- Parameters:
-- 		# ##path## : the path from which to extract information
--      # ##pcd## : If not zero and there is no directory name in ##path##
--                 then "." is returned. The default (0) will just return
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
-- Return the file name portion of a fully qualified filename
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
-- Return the base filename of path.
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
-- Return the file extension of a fully qualified filename
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
-- Return the drive letter of the path on //WIN32// platforms.
--
-- Parameters:
-- 		# ##path## : the path from which to extract information
--
-- Returns:
-- 		A **sequence**, the file extension part of ##path##.
--
-- TODO: Test
--
-- Example:
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
-- Returns the supplied filepath with the supplied extension, if
-- the filepath does not have an extension already.
--
-- Parameters:
-- 		# ##path## : the path to check for an extension.
-- 		# ##defext## : the extension to add if ##path## does not have one.
--
-- Returns:
-- 		A **sequence**, the path with an extension.
--
-- Example:
-- <eucode>
--  -- ensure that the supplied path has an extension, but if it doesn't use "tmp".
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
		if path[i] = SLASH then
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
-- Determine if the supplied string is an absolute path or a relative path.
--
-- Parameters:
--		# ##filename## : a sequence, the name of the file path
--
-- Returns:
--     An **integer**, 0 if ##filename## is a relative path or 1 otherwise.
--
-- Comment:
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
-- -- The next two examples return 0 on Unix platforms and 1 on Microsoft platforms
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


--**
-- Returns the full path and file name of the supplied file name.
--
-- Parameters:
--	# ##path_in## : A sequence. This is the file name whose full path you want.
--  # ##directory_given## : An integer. This is zero if ##path_in## is 
--  to be interpreted as a file specification otherwise it is assumed to be a
--  directory specification. The default is zero.
--
-- Returns:
--     A **sequence**, the full path and file name.
--
-- Comment:
-- * In non-Unix systems, the result is always in lowercase.
-- * The supplied file/directory does not have to actually exist.
-- * Does not (yet) handle UNC paths or unix links.
--
--
-- Example 1:
-- <eucode>
-- -- Assuming the current directory is "/usr/foo/bar" 
-- res = canonical_path("../abc.def")
-- -- res is now "/usr/foo/abc.def"
-- </eucode>

public function canonical_path(sequence path_in, integer directory_given = 0)
    sequence lPath = ""
    integer lPosA = -1
    integer lPosB = -1
    integer lPosC = -1
    sequence lLevel = ""
    sequence lHome

	ifdef UNIX then
		lPath = path_in
	elsedef
	    sequence lDrive = ""
	    -- Replace unix style separators with Windows style
	    lPath = match_replace("/", path_in, SLASH)
	end ifdef

    -- Strip off any enclosing quotes.
    if (length(lPath) > 2 and lPath[1] = '"' and lPath[$] = '"') then
        lPath = lPath[2..$-1]
	end if

    -- Replace any leading tilde with 'HOME' directory.
    if (length(lPath) > 0 and lPath[1] = '~') then
		ifdef UNIX then
				lHome = getenv("HOME")
		elsedef
				lHome = getenv("HOMEDRIVE") & getenv("HOMEPATH")
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

	ifdef not UNIX then
		-- Strip off any drive letter attached.
	    if ( (length(lPath) > 1) and (lPath[2] = ':' ) )
		then
			lDrive = lPath[1..2]
			lPath = lPath[3..$]
		end if
	end ifdef

	-- If a relative path, prepend the PWD of the appropriate drive.
	if ( (length(lPath) = 0) or (lPath[1] != SLASH) )
	then
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
	while( lPosA != 0 ) with entry do
		lPath = lPath[1..lPosA-1] & lPath[lPosA + 2 .. $]
		
	  entry
		lPosA = match(lLevel, lPath)
	end while
	
	-- Replace all instances of "X/Y/../" with "X/"
	lLevel = SLASH & ".." & SLASH
	
	while( lPosA != 0 ) with entry do
		-- Locate preceding directory separator.
		lPosB = lPosA-1
		while((lPosB > 0) and (lPath[lPosB] != SLASH)) do
			lPosB -= 1
		end while
		if (lPosB <= 0) then
			lPosB = 1
		end if
		
		lPath = lPath[1..lPosB-1] & lPath[lPosA + 3 .. $]
		
	  entry
		lPosA = match(lLevel, lPath)
	end while
	
	ifdef not UNIX then
		lPath = lower(lDrive & lPath)
	end ifdef
	
	return lPath
end function


--****
-- === File Types

public enum
	FILETYPE_UNDEFINED = -1,
	FILETYPE_NOT_FOUND,
	FILETYPE_FILE,
	FILETYPE_DIRECTORY

--**
-- Get the type of a file.
--
-- Parameters:
--  		# ##filename## : the name of the file to query. It must not have wildcards.
-- 
-- Returns:
--		An **integer**,
--		* -1 if file could be multiply defined
--      *  0 if filename does not exist
--      *  1 if filename is a file
--      *  2 if filename is a directory
--
-- See Also:
-- [[:dir]], [[:FILETYPE_DIRECTORY]], [[:FILETYPE_FILE]], [[:FILETYPE_NOT_FOUND]],
-- [[:FILETYPE_UNDEFINED]]

public function file_type(sequence filename)
object dirfil
	if eu:find('*', filename) or eu:find('?', filename) then return FILETYPE_UNDEFINED end if
	
	if length(filename) = 2 and filename[2] = ':' then
		filename &= "\\"
	end if
	
	dirfil = dir(filename)
	if sequence(dirfil) then
		if eu:find('d', dirfil[1][2]) or (length(filename)=3 and filename[2]=':') then
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
-- Check to see if a file exists
--
-- Parameters:
--   # ##name## :  filename to check existence of
--
-- Returns:
--   An **integer**, 1 on yes, 0 on no
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
	
	ifdef WIN32 then
		atom pName = allocate_string(name)
		atom r = c_func(xGetFileAttributes, {pName})
		free(pName)

		return r > 0

	elsifdef UNIX then
		atom pName = allocate_string(name)
		atom r = c_func(xGetFileAttributes, {pName, 0})
		free(pName)

		return r = 0

	elsedef

		return sequence(dir(name))
	end ifdef
end function

--**
-- Get the timestamp of the file
--
-- Parameters:
--   # ##name## : the filename to get the date of
--	 
-- Returns:
--   A valid **datetime type**, representing the files date and time or -1 if the
--	 file's date and time could not be read.
-- 

public function file_timestamp(sequence fname)
	object d = dir(fname)
	if atom(d) then return -1 end if
	
	return dt:new(d[1][D_YEAR], d[1][D_MONTH], d[1][D_DAY],
		d[1][D_HOUR], d[1][D_MINUTE], d[1][D_SECOND])
end function

--**
-- Copy a file.
--
-- Parameters:
-- 		# ##src## : a sequence, the name of the file or directory to copy
-- 		# ##dest## : a sequence, the new name or location of the file
-- 		# ##overwrite## : an integer; 0 (the default) will prevent an existing destination
--                       file from being overwritten. Non-zero will overwrite the
--                       destination file.
--
-- Returns:
--     An **integer**, 0 on failure, 1 on success.
--
-- Comments:
--     If ##overwrite## is true, and if dest file already exists,
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
	
	ifdef WIN32 then
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
-- Rename a file.
-- 
-- Parameters:
-- 		# ##src## : a sequence, the name of the file or directory to rename.
-- 		# ##dest## : a sequence, the new name for the renamed file
--		# ##overwrite## : an integer, 0 (the default) to prevent renaming if destination file exists,
--                                   1 to delete existing destination file first
--
-- Returns:
--     An **integer**, 0 on failure, 1 on success.
--
-- Comments:
-- 	*	If ##dest## contains a path specification, this is equivalent to moving the file, as 
-- 		well as possibly changing its name. However, the path must be on the same drive for 
-- 		this to work.
-- * If ##overwrite## was requested but the rename fails, any existing destination
--  file is preserved.
--
-- See Also:
-- [[:move_file]], [[:copy_file]]

public function rename_file(sequence src, sequence dest, integer overwrite=0)
	atom psrc, pdest, ret
	sequence tempfile = ""
	
	if not overwrite then
		if file_exists(dest) then
			return 0
		end if
	else
		if file_exists(dest) then
			tempfile = temp_file(dest)
			ret = move_file(dest, tempfile)
		end if
	end if
	
	
	psrc = allocate_string(src)
	pdest = allocate_string(dest)
	ret = c_func(xMoveFile, {psrc, pdest})
		
	ifdef UNIX then
		ret = not ret 
	end ifdef
		
	free({pdest, psrc})
	
	if overwrite then
		if not ret then
			if length(tempfile) > 0 then
				-- rename was unsuccessful so restore from tempfile
				ret = move_file(tempfile, dest)
			end if
		end if
		delete_file(tempfile)
	end if
	
	return ret
end function

ifdef LINUX then
	function xstat(atom psrc, atom psrcbuf)
		return c_func(xStatFile, {3, psrc, psrcbuf})
	end function
elsifdef UNIX then
	function xstat(atom psrc, atom psrcbuf)
		return c_func(xStatFile, {psrc, psrcbuf})
	end function
end ifdef

--**
-- Move a file to another location.
--
-- Parameters:
-- 		# ##src## : a sequence, the name of the file or directory to move
-- 		# ##dest## : a sequence, the new location for the file
--		# ##overwrite## : an integer, 0 (the default) to prevent overwriting an existing destination file,
--                                   1 to overwrite existing destination file
--
-- Returns:
--     An **integer**, 0 on failure, 1 on success.
--
-- Comments:
-- * If ##overwrite## was requested but the move fails, any existing destination
--  file is preserved.
-- See Also:
-- [[:rename_file]], [[:copy_file]]

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
		atom psrcbuf = 0, pdestbuf = 0
		integer stat_t_offset, dev_t_size, stat_buf_size
	end ifdef
	ifdef LINUX then
		stat_t_offset = 0
		stat_buf_size = 88
		dev_t_size = 8
	elsifdef OSX then
		--TODO
		stat_t_offset = 0
		stat_buf_size = 88
		dev_t_size = 8
	elsifdef FREEBSD or SUNOS then
		--TODO
		stat_t_offset = 0
		stat_buf_size = 88
		dev_t_size = 8
	end ifdef
	

	ifdef UNIX then
		psrcbuf = allocate(stat_buf_size)
		psrc = allocate_string(src)
		ret = xstat(psrc, psrcbuf)
		if ret then
 			free({psrcbuf, psrc})
 			return 0
		end if
		
		pdestbuf = allocate(stat_buf_size)
		pdest = allocate_string(dest)
		ret = xstat(pdest, pdestbuf)
		if ret then
			-- Assume destination doesn't exist
			atom pdir
			if length(dirname(dest)) = 0 then
				pdir = allocate_string(current_dir())
			else
				pdir = allocate_string(dirname(dest))
			end if
			ret = xstat(pdir, pdestbuf)
			free(pdir)
		end if
		
		if not ret and not equal(peek(pdestbuf+stat_t_offset), peek(psrcbuf+stat_t_offset)) then
			-- on different filesystems, can not use rename
			-- fall back on copy&delete
			ret = copy_file(src, dest, overwrite)
			if ret then
				ret = delete_file(src)
			end if
 			free({psrcbuf, psrc, pdestbuf, pdest})
 			return (not ret)
		end if
		
	elsedef		
		psrc = allocate_string(src)
		pdest = allocate_string(dest)
	end ifdef

	if overwrite then
		-- return value is ignored, we don't care if it existed or not
		tempfile = temp_file(dest)
		move_file(dest, tempfile)
	end if

	ret = c_func(xMoveFile, {psrc, pdest})
	
	ifdef UNIX then
		ret = not ret 
		free({psrcbuf, pdestbuf})
	end ifdef
	free({pdest, psrc})
	
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
-- Return the size of a file.
--
-- Parameters:
-- 		# ##filename## : the name of the queried file
--
-- Returns:
-- 		An **atom**, the file size, or -1 if file is not found.
--
-- Comments:
--     This function does not compute the total size for a directory, and returns 0 instead.
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
-- Locates a file by looking in a set of directories for it.
--
-- Parameters:
--		# ##filename## : a sequence, the name of the file to search for.
--		# ##search_list## : a sequence, the list of directories to look in. By
--        default this is "", meaning that a predefined set of directories
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
-- of a string of directory names delimited by ':' in UNIX and ';' in Windows.
--
-- If the ##search_list## is omitted or "", this will look in the following places...
-- * The current directory
-- * The directory that the program is run from.
-- * The directory in $HOME ($HOMEDRIVE & $HOMEPATH in Windows)
-- * The parent directory of the current directory
-- * The directories returned by include_paths()
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
--  res = locate_file("abc.def") -- Scan default locations.
--  res = locate_file("abc.def", , "app") -- Scan the 'app' sub directory in the default locations.
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

		ifdef LINUX	then
			extra_paths = getenv("HOME")
		elsifdef WIN32 then
			extra_paths = getenv("HOMEDRIVE") & getenv("HOMEPATH")
		end ifdef		
			
		if sequence(extra_paths) then
			search_list = append(search_list, extra_paths & SLASH)
		end if				
				
		search_list = append(search_list, ".." & SLASH)
		
		search_list &= include_paths(1)
		
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
		
		extra_paths = getenv("USERPATH")
		if sequence(extra_paths) then
			extra_paths = split(extra_paths, PATHSEP)
			search_list &= extra_paths
		end if
		
		extra_paths = getenv("PATH")
		if sequence(extra_paths) then
			extra_paths = split(extra_paths, PATHSEP)
			search_list &= extra_paths
		end if
	else
		if integer(search_list[1]) then
			search_list = split(search_list, PATHSEP)
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
-- Returns some information about a disk drive.
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
	
	ifdef WIN32 then
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
		sequence disk_size = {0,0,0}

		atom bytes_per_cluster
		atom psrc, ret, psrcbuf
		integer stat_t_offset, dev_t_size, stat_buf_size

		ifdef LINUX then
			stat_t_offset = 48
			stat_buf_size = 88
			dev_t_size = 4
		elsifdef OSX then
			--TODO
			stat_t_offset = 48
			stat_buf_size = 88
			dev_t_size = 4
		elsifdef FREEBSD or SUNOS then
			--TODO
			stat_t_offset = 48
			stat_buf_size = 88
			dev_t_size = 4
		end ifdef

		psrc = allocate_string(disk_path)
		psrcbuf = allocate(stat_buf_size)
		ret = xstat(psrc,psrcbuf)
		bytes_per_cluster = peek4s(psrcbuf+stat_t_offset)
		free({psrcbuf, psrc})
		if ret then
			-- failure
			return result 
		end if

		disk_size = disk_size(disk_path)

		-- this is hardcoded for now, but may be x86 specific
		-- on other Unix platforms that run on non x86 hardware, this
		-- may need to be changed - there is no portable way to get this
		result[BYTES_PER_SECTOR] = 512

		result[SECTORS_PER_CLUSTER] = bytes_per_cluster / result[BYTES_PER_SECTOR]
		result[TOTAL_NUMBER_OF_CLUSTERS] = disk_size[TOTAL_BYTES] / bytes_per_cluster
		result[NUMBER_OF_FREE_CLUSTERS] = disk_size[FREE_BYTES] / bytes_per_cluster

	end ifdef 
	
	return result 
end function 
 
--**
-- Returns the amount of space for a disk drive.
--
-- Parameters:
--	# ##disk_path## : A sequence. This is the path that identifies the disk to inquire upon.
--
-- Returns:
--     A **sequence**, containing TOTAL_BYTES, USED_BYTES, FREE_BYTES, and a string which represents the filesystem name
--
-- Example 1:
-- <eucode>
-- res = disk_size("C:\\")
-- printf(1, "Drive %s has %3.2f%% free space\n", {"C:", res[FREE_BYTES] / res[TOTAL_BYTES]})
-- </eucode>

public function disk_size(object disk_path) 
	sequence disk_size = {0,0,0, disk_path}
	
	ifdef WIN32 then
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
		system("df "&disk_path&" > "&tempfile, 2)

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

		data = get(temph)
		disk_size[TOTAL_BYTES] = data[2] * 1024
		data = get(temph)
		disk_size[USED_BYTES] = data[2] * 1024
		data = get(temph)
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
-- Returns the amount of space used by a directory.
--
-- Parameters:
--	# ##dir_path## : A sequence. This is the path that identifies the directory to inquire upon.
--  # ##count_all## : An integer. Used by Windows systems. If zero (the default) 
--                    it will not include //system// or //hidden// files in the
--                    count, otherwise they are included.
--
-- Returns:
--     A **sequence**, containing four elements; the number of sub-directories [COUNT_DIRS],
--                     the number of files [COUNT_FILES], 
--                     the total space used by the directory [COUNT_SIZE], and
--                     breakdown of the file contents by file extension [COUNT_TYPES].
--                  
-- Comments:
--  * The total space used by the directory does not include space used by any sub-directories.
--  * The file breakdown is a sequence of three-element sub-sequences. Each sub-sequence
--    contains the extension [EXT_NAME], the number of files of this extension [EXT_COUNT],
--    and the space used by these files [EXT_SIZE]. The sub-sequences are presented in
--    extension name order. On Windows the extensions are all in lowercase.
--
-- Example 1:
-- <eucode>
-- res = dir_size("/usr/localbin")
-- printf(1, "Directory %s contains %d files\n", {"/usr/localbin", res[COUNT_FILES]})
-- for i = 1 to length(res[COUNT_TYPES]) do
--   printf(1, "  Type: %s (%d files %d bytes)\n", {res[COUNT_TYPES][i][EXT_NAME],
--                                                  res[COUNT_TYPES][i][EXT_COUNT],
--                                                  res[COUNT_TYPES][i][EXT_SIZE]})
-- end for
-- </eucode>

public function dir_size(sequence dir_path, integer count_all = 0)
	integer ok 
	sequence fc

	-- We create our own instance of the global 'file_counters' to use in case
	-- the application is using threads.
	
	file_counters = append(file_counters, {0,0,0,{}})
	ok = walk_dir(dir_path, {routine_id("count_files"), {count_all, length(file_counters)}}, 0)
	
	fc = file_counters[$]
	file_counters = file_counters[1 .. $-1]
	fc[COUNT_TYPES] = sort(fc[COUNT_TYPES])

	return fc
end function

--**
-- Returns a file name that can be used as a temporary file.
--
-- Parameters:
--	# ##temp_location## : A sequence. A directory where the temporary file is expected
--               to be created. 
--            ** If omitted (the default) the 'temporary' directory
--               will be used. The temporary directory is defined in the "TEMP" 
--               environment symbol, or failing that the "TMP" symbol and failing
--               that "C:\TEMP\" is used in non-Unix systems and "/tmp/" is used
--               in Unix systems. 
--            ** If ##temp_location## was supplied, 
--               *** If it is an existing file, that file's directory is used.
--               *** If it is an existing directory, it is used.
--               *** If it doesn't exist, the directory name portion is used.
--  # ##temp_prefix## : A sequence: The is prepended to the start of the generated file name.
--               The default is "".
--  # ##temp_extn## : A sequence: The is a file extention used in the generated file. 
--               The default is "_T_".
--  # ##reserve_temp## : An integer: If not zero an empty file is created using the 
--               generated name. The default is not to reserve (create) the file.
--
-- Returns:
--     A **sequence**, A generated file name.
--                  
-- Comments:
--
-- Example 1:
-- <eucode>
--  ? temp_file("/usr/space", "myapp", "tmp") --> /usr/space/myapp736321.tmp
--  ? temp_file() --> /tmp/277382._T_
--  ? temp_file("/users/me/abc.exw") --> /users/me/992831._T_
-- </eucode>

public function temp_file(sequence temp_location = "", sequence temp_prefix = "", sequence temp_extn = "_T_", integer reserve_temp = 0)
	sequence  randname
	
	if length(temp_location) = 0 then
		object envtmp
		envtmp = getenv("TEMP")
		if atom(envtmp) then
			envtmp = getenv("TMP")
		end if
		ifdef WIN32 then			
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
	
	
	while 1 do
		randname = sprintf("%s%s%06d.%s", {temp_location, temp_prefix, rand(1_000_000) - 1, temp_extn})
		if not file_exists( randname ) then
			exit
		end if
	end while
	
	if reserve_temp then
		integer ret
		-- Reserve the name by creating an empty file.
		if not file_exists(temp_location) then
			if create_directory(temp_location) = 0 then
				return ""
			end if
		end if
		ret = write_file(randname, "")
	end if
	
	return randname
	
end function
