-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
--****
-- == File System
--
-- Cross platform file operations for Euphoria
--
-- **Page Contents**
--
-- <<LEVELTOC depth=2>>

ifdef !DOS32 then
include dll.e
end ifdef
include machine.e
include wildcard.e
include sort.e

constant
	M_DIR	      = 22,
	M_CURRENT_DIR = 23,
	M_CHDIR       = 63

ifdef WIN32 then
	constant lib = open_dll("kernel32")
	constant xCopyFile         = define_c_func(lib, "CopyFileA",   {C_POINTER, C_POINTER, C_LONG}, C_LONG)
	constant xMoveFile         = define_c_func(lib, "MoveFileA",   {C_POINTER, C_POINTER}, C_LONG)
	constant xDeleteFile       = define_c_func(lib, "DeleteFileA", {C_POINTER}, C_LONG)
	constant xCreateDirectory  = define_c_func(lib, "CreateDirectoryA", {C_POINTER, C_POINTER}, C_LONG)
	constant xRemoveDirectory  = define_c_func(lib, "RemoveDirectoryA", {C_POINTER}, C_LONG)

elsifdef LINUX then
	constant lib = open_dll("")

elsifdef FREEBSD then
	constant lib = open_dll("libc.so")
	
elsifdef OSX then
	constant lib = open_dll("libc.dylib")
	
else
	constant xCopyFile        = -1
	constant xMoveFile        = -1
	constant xDeleteFile      = -1
	constant xCreateDirectory = -1
	constant xRemoveDirectory = -1

end ifdef

ifdef UNIX then
	constant xStatFile        = define_c_func(lib, "stat", {C_POINTER, C_POINTER}, C_INT)
	constant xMoveFile        = define_c_func(lib, "rename", {C_POINTER, C_POINTER}, C_INT)
	--constant xDeleteFile      = define_c_func(lib, "remove", {C_POINTER}, C_LONG)
	constant xDeleteFile      = define_c_func(lib, "unlink", {C_POINTER}, C_INT)
	constant xCreateDirectory = define_c_func(lib, "mkdir", {C_POINTER, C_INT}, C_INT)
	constant xRemoveDirectory = define_c_func(lib, "rmdir", {C_POINTER}, C_INT)
end ifdef


--****
-- === Constants

--**
-- Signature:
-- export constant SLASH
--
-- Description:
-- Current platform's path separator character
--
-- Comments:
-- When on //DOS// or //Windows//, '~\\'. When on //Unix//, '/'.
--

--**
-- Signature:
-- export constant SLASHES
--
-- Description:
-- Current platform's possible path separators. This is slightly different
-- in that on //Windows// and //DOS// the path separators variable contains
-- ##~\~\## as well as ##~:## and ##/## as newer //Windows// versions support
-- ##/## as a path separator. On //Unix// systems, it only contains ##/##.

--**
-- Signature:
-- export constant SLASHES
--
-- Description:
-- Current platform's possible path separators. This is slightly different
-- in that on //Windows// and //DOS// the path separators variable contains
-- ##~\~\## as well as ##~:## and ##/## as newer //Windows// versions support
-- ##/## as a path separator. On //Unix// systems, it only contains ##/##.

--**
-- Signature:
-- export constant CRLF
--
-- Description:
-- Current platform's newline character(s)

--**
-- Signature:
-- export constant PATHSEP
--
-- Description:
-- Current platform's path separator character

ifdef UNIX then
	export constant SLASH='/'
	export constant SLASHES = "/"
	export constant CRLF = "\n"
	export constant PATHSEP = ':'
else
	export constant SLASH='\\'
	export constant SLASHES = ":\\/"
	export constant CRLF = "\r\n"
	export constant PATHSEP = ';'
end ifdef

--****
-- === Directory Handling

--**
-- Create a new directory.
--
-- Parameters:
-- 		# ##name##: a sequence, the name of the new directory to create
--		# ##mode##: on //Unix// systems, permissions for the new directory. Default is 448 (all rights for owner, none for others).
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
-- </eucode>
-- See Also:
-- 	[[:relove_directory]], [[:chdir]]

export function create_directory(sequence name, integer mode=448)
	atom pname, ret
	pname = allocate_string(name)
	ifdef UNIX then
		ret = not c_func(xCreateDirectory, {pname, mode})
	elsifdef WIN32 then
		ret = c_func(xCreateDirectory, {pname, 0})
		mode = mode -- get rid of not used warning
	-- else TODO: implement for DOS
	end ifdef
	return ret
end function

--**
-- Remove a directory.
--
-- Parameters:
--		# ##name##: a sequence, the name of the directory to remove.
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
-- See Also:
-- 	[[:create_directory]], [[:chdir]]

export function remove_directory(sequence name)
	atom pname, ret
	pname = allocate_string(name)
	ret = c_func(xRemoveDirectory, {pname})
	ifdef UNIX then
		ret = not ret 
	-- else TODO: implement for DOS and Windows
	end ifdef
	free(pname)
	return ret
end function

global enum 
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
-- Return directory information for the specofoed file or directory.
--
-- Parameters:
-- 		# ##name##: a sequence, the name to be looked up in the file system.
--
-- Returns:
--		An **object**: -1 if no match found, else a sequence of sequence entries
--
-- Comments:
-- 		##name## can also contain * and ? wildcards to select multiple
-- files.
--
-- The returned information is similar to what you would get from the DOS DIR command. A sequence
-- is returned where each element is a sequence that describes one file or subdirectory.
-- 
-- If ##name## refers to a **directory** you may have entries for "." and "..",
-- just as with the DOS DIR command. If it refers to an existing **file**, and has no wildcards, then the returned sequence will
-- have just one entry, i.e. its length will
-- be 1. If ##name## contains wildcards you may have multiple entries.
-- 
-- Each entry contains the name, attributes and file size as well as
-- the year, month, day, hour, minute and second of the last modification.
-- You can refer to the elements of an entry with the following constants:
--  
-- <eucode>
-- global constant 
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
-- //DOS32//: The file name returned in D_NAME will be a standard DOS 8.3 name. (See 
-- [[http://www.rapideuphoria.com/cgi-bin/asearch.exu?dos=on&keywords=dir|Archive Web page]]
-- for a better solution).
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
--   ##bin\search.ex##
--

global function dir(sequence name)
	object dir_data, data, the_name, the_dir
	integer idx

	-- Did the user give a wildcard? If not, just return the standard dir.
	if find('*', name) > 0 or find('?', name) > 0 then
		-- Empty if so that we can short circuit if * is found, otherwise
		-- we would have to run a search for * and ? even if * is found.
	else
		return machine_func(M_DIR, name)
	end if

	-- Is there a path involved?
	if find('/', name) = 0 and find('\\', name) = 0 then
		the_dir = "."
		the_name = name
	else
		-- Find a SLASH character and break the name there resulting in
		-- a directory and file name.
		idx = length(name)
		while idx > 0 do
			ifdef WIN32 then
				if name[idx] = '\\' then
					exit
				end if
			end ifdef
			if name[idx] = '/' then
				exit
			end if
			idx -= 1
		end while

		the_dir = name[1..idx]
		the_name = name[idx+1..$]
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
-- //DOS/Windows//, at the top-level of a drive, e.g. C:\
--
-- Example 1:
-- <eucode>
-- sequence s
-- s = current_dir()
-- -- s would have "C:\EUPHORIA\DOC" if you were in that directory
-- </eucode>
-- See Also:
-- 	[[:dir]], [[:chdir]]
global function current_dir()
-- returns name of current working directory
	return machine_func(M_CURRENT_DIR, 0)
end function

--**
-- Set a new value for the current directory 
--
-- Parameters:
-- 		##newdir##: a sequence, the name for the new working directory.
--
-- Returns:
-- 		An **integer**, 0 on failure, 1 on success.
--
-- Comments:
-- By setting the current directory, you can refer to files in that directory using just
-- the file name.
-- 
-- The function current_dir() will return the name of the current directory.
-- 
-- On //DOS32// and //WIN32// the current directory is a global property shared
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
-- See Also:
-- [[:current_dir]], [[:dir]]
global function chdir(sequence newdir)
-- Changes the current directory. Returns 1 - success, 0 - fail.
	return machine_func(M_CHDIR, newdir)
end function

-- Generalized recursive directory walker

global constant W_BAD_PATH = -1 -- error code

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
constant DEFAULT = -2

-- it's better not to use routine_id() here,
-- or else users will have to bind with clear routine names
global integer my_dir = DEFAULT

--**
-- Generalized Directory Walker
--
-- Parameters:
-- 		# ##path_name##: a sequence, the name of the directory to walk through
-- 		# ##your_function##: an integer, either ##my_dir## or the routine id of a callback Euphoria function
-- 		# ##scan_subdirs##: an integer, 1 to also walk though subfolders, 0 to skip them all.
--
-- Comments:
--
-- This routine will "walk" through a directory named ##path_name##. For each entry in the directory, it will call a function, whose routine_id is ##your_function##.
-- If ##scan_subdirs## is non-zero (TRUE), then the subdirectories in
-- st will be walked through recursively in the very same way.
--
-- The routine that you supply should accept two sequences, the path name and dir() entry for each file and
-- subdirectory. It should return 0 to keep going, or non-zero to stop walk_dir(). 
--
-- This mechanism allows you to write a simple function that handles one file at a time, 
-- while walk_dir() handles the process of walking through all the files and subdirectories.

-- By default, the files and subdirectories will be visited in alphabetical order. To use 
-- a different order, set the global integer ##my_dir## to the routine id of your own modified
-- [[:dir]] function that sorts the directory entries differently. See the default ##dir()##
-- function in filesys.e.

-- The path that you supply to ##walk_dir()## must not contain wildcards (* or ?). Only a 
-- single directory (and its subdirectories) can be searched at one time.
--
-- Example 1:
-- <eucode>
-- function look_at(sequence path_name, sequence entry)
-- -- this function accepts two sequences as arguments
--     printf(STDOUT, "%s\\%s: %d\n",
--            {path_name, entry[D_NAME], entry[D_SIZE]})
--     return 0 -- keep going
-- end function
--
-- exit_code = walk_dir("C:\\MYFILES", routine_id("look_at"), TRUE)
-- </eucode>
--
-- See Also:
--   ##bin\search.ex##

global function walk_dir(sequence path_name, object your_function, integer scan_subdirs)
	object d, abort_now
	object orig_func
	object user_data
	
	orig_func = your_function
	if sequence(your_function) then
		user_data = your_function[2]
		your_function = your_function[1]
	end if
	-- get the full directory information
	if my_dir = DEFAULT then
		d = default_dir(path_name)
	else
		d = call_func(my_dir, {path_name})
	end if
	if atom(d) then
		return W_BAD_PATH
	end if
	
	-- trim any trailing blanks or '\' characters from the path
	while length(path_name) > 0 and 
		  find(path_name[$], {' ', SLASH}) do
		path_name = path_name[1..$-1]
	end while
	
	for i = 1 to length(d) do
		if find('d', d[i][D_ATTRIBUTES]) then
			-- a directory
			if not find(d[i][D_NAME], {".", ".."}) then
				if atom(orig_func) then
					abort_now = call_func(your_function, {path_name, d[i]})
				else
					abort_now = call_func(your_function, {path_name, d[i], user_data})
				end if
				if not equal(abort_now, 0) then
					return abort_now
				end if
				if scan_subdirs then
					abort_now = walk_dir(path_name & SLASH & d[i][D_NAME],
										 orig_func, scan_subdirs)
					
					if not equal(abort_now, 0) and 
					   not equal(abort_now, W_BAD_PATH) then
						-- allow BAD PATH, user might delete a file or directory 
						return abort_now
					end if
				end if
			end if
		else
			-- a file
			if atom(orig_func) then
				abort_now = call_func(your_function, {path_name, d[i]})
			else
				abort_now = call_func(your_function, {path_name, d[i], user_data})
			end if
			if not equal(abort_now, 0) then
				return abort_now
			end if
		end if
	end for
	return 0
end function


--****
-- === Routines
--

--**
-- Copy a file.
--
-- Parameters:
-- 		# ##src##: a sequence, the name of the file or directory to copy
-- 		# ##dest##: a sequence, the new name or location of the file
-- 		# ##overwrite##: an integer, 0 to prevent overwriting an existing file
--
-- Returns:
--     An **integer**, 0 on failure, 1 on success.
--
-- Comments:
--     If overwrite is true, and if dest file already exists,
--     the function overwrites the existing file and succeeds.
-- See Also:
-- [[:move_file]], [[:rename_file]]
export function copy_file(sequence src, sequence dest, atom overwrite)
	ifdef WIN32 then
	atom psrc, pdest, ret

	psrc = allocate_string(src)
	pdest = allocate_string(dest)
	ret = c_func(xCopyFile, {psrc, pdest, not overwrite})
	free(pdest)
	free(psrc)
	else
		integer f, h, c, ret
		ret = 0
		f = open(src, "rb")
		if f = -1 then
			return ret
		end if
		if not overwrite then
			h = open(dest, "rb")
			if h != -1 then
				goto "cleanupboth"
			end if
		end if
		h = open(dest, "wb")
		if h = -1 then
			goto "cleanupf"
		end if
		while c != -1 entry do
			puts(h, c)
		entry
			c = getc(f)
		end while
	
		label "cleanupboth"
		close(h)

		label "cleanupf"
		close(f)
	end ifdef

	return ret

end function

--**
-- Rename a file.
-- 
-- Parameters:
-- 		# ##src##: a sequence, the name of the file or directory to rename.
-- 		# ##dest##: a sequence, the new name for the renamed file
--
-- Returns:
--     An **integer**, 0 on failure, 1 on success.
--
-- Comments:
-- 		If ##dest## contains a path specification, this is equivalent to moving the file, as well as possibly changing its name. However, the path must be on the same drive for this to work.
-- See Also:
-- [[:move_file]], [[:copy_file]]
export function rename_file(sequence src, sequence dest)
	atom psrc, pdest, ret
	
	psrc = allocate_string(src)
	pdest = allocate_string(dest)
	ret = c_func(xMoveFile, {psrc, pdest})
	
	ifdef UNIX then
		ret = not ret 
	end ifdef
	
	free(pdest)
	free(psrc)
	
	return ret
end function

--**
-- Delete a file.
--
-- Parameters:
-- 		# ##name##: a sequence, the name of the file to delete.
--
-- Returns:
--     An **integer**, 0 on failure, 1 on success.

export function delete_file(sequence name)
	atom pfilename, ret

	ifdef DOS32 then
		-- quick hack TODO check whether access was granted
		system("del "&name&" > NUL", 2)
		return 1
	end ifdef

	pfilename = allocate_string(name)
	ret = c_func(xDeleteFile, {pfilename})
	
	ifdef UNIX then
		ret = not ret
	end ifdef

	free(pfilename)

	return ret
end function

--**
-- Move a file to another location.
--
-- Parameters:
-- 		# ##src##: a sequence, the name of the file or directory to move
-- 		# ##dest##: a sequence, the new location for the file
--		# ##overwrite##: an integer, 0 to disable overwriting an existing file (the default)
--
-- Returns:
--     An **integer**, 0 on failure, 1 on success.
-- See Also:
-- [[:rename_file]], [[:copy_file]]

export function move_file(sequence src, sequence dest, atom overwrite=0)
	atom psrc, pdest, ret
	ifdef UNIX then
		atom psrcbuf, pdestbuf
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
	elsifdef FREEBSD then
		--TODO
		stat_t_offset = 0
		stat_buf_size = 88
		dev_t_size = 8
	end ifdef
	
	psrc = allocate_string(src)
	pdest = allocate_string(dest)

	ifdef UNIX then
		psrcbuf = allocate(stat_buf_size)
		pdestbuf = allocate(stat_buf_size)
		ret = c_func(xStatFile, {psrc, psrcbuf})
		if ret then
			goto "out"
		end if
		ret = c_func(xStatFile, {pdest, pdestbuf})
		if ret then
			goto "out"
		end if
		if not equal(peek(pdestbuf+stat_t_offset), peek(psrcbuf+stat_t_offset)) then
			-- on different filesystems, can not use rename
			-- fall back on copy&delete
			ret = copy_file(src, dest, overwrite)
			if not ret then
				goto "out"
			end if
			ret = delete_file(src)
			goto "out"
		end if
	end ifdef

	if overwrite then
		-- return value is ignored, we don't care if it existed or not
		ret = open(src, "rb")
		if ret != -1 then
			-- check to make sure the source exists before copying
			close(ret)
			ret = delete_file(dest)
		end if
	end if

	ret = c_func(xMoveFile, {psrc, pdest})
	
	ifdef UNIX then
		ret = not ret 
	end ifdef
	
	ifdef UNIX then
		label "out"
		free(psrcbuf)
		free(pdestbuf)
	end ifdef
	free(pdest)
	free(psrc)
	
	return ret
end function


--**
-- Return the size of a file.
--
-- Parameters:
-- 		# ##filename##: the name of the queried file
--
-- Returns:
-- 		An **atom**, the file size, or -1 if file is not found.
--
-- Comments:
--     This function does not compute the total size for a directory, and returns 0 instead.
-- See Also:
-- [[:dir]]
export function file_length(sequence filename)
	object list
	list = dir(filename)
	if atom(list) or length(list) = 0 then
		return -1
	end if
	return list[1][D_SIZE]
end function

export enum
	FILETYPE_UNDEFINED = -1,
	FILETYPE_NOT_FOUND,
	FILETYPE_FILE,
	FILETYPE_DIRECTORY

--**
-- Get the type of a file.
--
-- Parameters:
--  		# ##filename##: the name of the file to query. It must not have wildcards.
-- 
-- Returns:
--		An **integer**:
--		* -1 if file could be multiply defined
--      *  0 if filename does not exist
--      *  1 if filename is a file
--      *  2 if filename is a directory
--
-- Comments:
-- An exported enum has been created for ease of use:
-- * FILETYPE_UNDEFINED     = -1,
-- * FILETYPE_NOT_FOUND, -- = 0
-- * FILETYPE_FILE,      -- = 1
-- * FILETYPE_DIRECTORY  -- = 2
--
-- See Also:
-- [[:dir]]

export function file_type(sequence filename)
object dirfil
	if find('*', filename) or find('?', filename) then return FILETYPE_UNDEFINED end if
	
	if length(filename) = 2 and filename[2] = ':' then
		filename &= "\\"
	end if
	
	dirfil = dir(filename)
	if sequence(dirfil) then
		if find('d', dirfil[1][2]) or (length(filename)=3 and filename[2]=':') then
			return FILETYPE_DIRECTORY
		else
			return FILETYPE_FILE
		end if
	else
		return FILETYPE_NOT_FOUND
	end if
end function


--****
-- === File name parsing

export enum
	PATH_DIR,
	PATH_FILENAME,
	PATH_BASENAME,
	PATH_FILEEXT,
	PATH_DRIVEID

--**
-- Parse a fully qualified pathname.
-- Parameters:
-- 		# ##path##: a sequence, the path to parse
--
-- Returns:
-- 		A **sequence** of length 5. Each of these elements is a string:
-- 		* The path name
--		* The full unqualified file name
--		* the file name, without extension
--		* the file extension
--		* the drive id
-- Comments:
-- An exported enum has been created for ease of using the returned value:
--
-- * PATH_DIR
-- * PATH_FILENAME
-- * PATH_BASENAME
-- * PATH_FILEEXT
-- * PATH_DRIVEID
--
-- The host operating system path separator is used in the parsing.
--
-- Example 1:
-- <eucode>
-- -- DOS32/WIN32
-- info = pathinfo("C:\\euphoria\\docs\\readme.txt")
-- -- info is {"C:\\euphoria\\docs", "readme.txt", "readme", "txt"}
-- </eucode>
--
-- Example 2:
-- <eucode>
-- -- Linux/FreeBSD
-- info = pathinfo("/opt/euphoria/docs/readme.txt")
-- -- info is {"/opt/euphoria/docs", "readme.txt", "readme", "txt"}
-- </eucode>
--
-- Example 3:
-- <eucode>
-- -- no extension
-- info = pathinfo("/opt/euphoria/docs/readme")
-- -- info is {"/opt/euphoria/docs", "readme", "readme", ""}
-- </eucode>
--
-- See Also:
--   [[:driveid]], [[:dirname]], [[:filename]], [[:fileext]]

export function pathinfo(sequence path)
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
		elsif find(ch, SLASHES) then
			slash = i
			exit
		end if
	end for

	if slash > 0 then
		dir_name = path[1..slash-1]
		
		ifdef !UNIX then
			ch = find(':', dir_name)
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

	return {dir_name, file_full, file_name, file_ext, drive_id}
end function

--**
-- Return the directory name of a fully qualified filename
--
-- Parameters:
-- 		# ##path##: the path from which to extract information
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

export function dirname(sequence path)
	sequence data
	data = pathinfo(path)
	return data[1]
end function

--**
-- Return the file name portion of a fully qualified filename
--
-- Parameters:
-- 		# ##path##: the path from which to extract information
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
  
export function filename(sequence path)
	sequence data

	data = pathinfo(path)

	return data[2]
end function

--**
-- Return the base filename of path.
--
-- Parameters:
-- 		# ##path##: the path from which to extract information
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

export function filebase(sequence path)
	sequence data

	data = pathinfo(path)

	return data[3]
end function

--**
-- Return the file extension of a fully qualified filename
--
-- Parameters:
-- 		# ##path##: the path from which to extract information
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

export function fileext(sequence path)
	sequence data
	data = pathinfo(path)
	return data[4]
end function

--**
-- Return the drive letter of the path on //DOS32// and //WIN32// platforms.
--
-- Parameters:
-- 		# ##path##: the path from which to extract information
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

export function driveid(sequence path)
	sequence data
	data = pathinfo(path)
	return data[5]
end function
