-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
--****
-- == File System
--
-- Cross platform file operations for Euphoria
--
-- <<LEVELTOC depth=2>>

ifdef DOS32 then
	-- constant short_names = dosver() < 7 or atom(getenv("windir"))
	constant short_names = 1 -- make this 0 if not using an LFN driver/TSR
	include std\dos\interrup.e
else
	include std/dll.e
end ifdef

include std/machine.e
include std/wildcard.e
include std/sort.e
include std/search.e
include std/memory.e

constant
	M_DIR	      = 22,
	M_CURRENT_DIR = 23,
	M_CHDIR       = 63

ifdef WIN32 then
	constant lib = open_dll("kernel32")
	constant xCopyFile         = define_c_func(lib, "CopyFileA",   {C_POINTER, C_POINTER, C_LONG}, 
		C_LONG)
	constant xMoveFile         = define_c_func(lib, "MoveFileA",   {C_POINTER, C_POINTER}, C_LONG)
	constant xDeleteFile       = define_c_func(lib, "DeleteFileA", {C_POINTER}, C_LONG)
	constant xCreateDirectory  = define_c_func(lib, "CreateDirectoryA", {C_POINTER, C_POINTER}, 
		C_LONG)
	constant xRemoveDirectory  = define_c_func(lib, "RemoveDirectoryA", {C_POINTER}, C_LONG)
	constant xGetFileAttributes= define_c_func(lib, "GetFileAttributesA", {C_POINTER}, C_INT)

elsifdef LINUX then
	constant lib = open_dll("")

elsifdef FREEBSD then
	constant lib = open_dll("libc.so")
	
elsifdef OSX then
	constant lib = open_dll("libc.dylib")
	
else
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

--**
-- Signature:
-- global constant SLASH
--
-- Description:
-- Current platform's path separator character
--
-- Comments:
-- When on //DOS// or //Windows//, '~\\'. When on //Unix//, '/'.
--

--**
-- Signature:
-- global constant SLASHES
--
-- Description:
-- Current platform's possible path separators. This is slightly different
-- in that on //Windows// and //DOS// the path separators variable contains
-- ##~\~\## as well as ##~:## and ##/## as newer //Windows// versions support
-- ##/## as a path separator. On //Unix// systems, it only contains ##/##.

--**
-- Signature:
-- global constant SLASHES
--
-- Description:
-- Current platform's possible path separators. This is slightly different
-- in that on //Windows// and //DOS// the path separators variable contains
-- ##~\~\## as well as ##~:## and ##/## as newer //Windows// versions support
-- ##/## as a path separator. On //Unix// systems, it only contains ##/##.

--**
-- Signature:
-- global constant CRLF
--
-- Description:
-- Current platform's newline character(s): ##\n## on //Unix//, else ##\r\n##.

--**
-- Signature:
-- global constant PATHSEP
--
-- Description:
-- Current platform's path separator character: ##:## on //Unix//, else ##;##.

ifdef UNIX then
	public constant SLASH='/'
	public constant SLASHES = "/"
	public constant CRLF = "\n"
	public constant PATHSEP = ':'
else
	public constant SLASH='\\'
	public constant SLASHES = ":\\/"
	public constant CRLF = "\r\n"
	public constant PATHSEP = ';'
end ifdef

--****
-- === Directory Handling

--**
-- Create a new directory.
--
-- Parameters:
-- 		# ##name##: a sequence, the name of the new directory to create
--		# ##mode##: on //Unix// systems, permissions for the new directory. Default is 
--		  448 (all rights for owner, none for others).
--      # ##mkparent## If true (default) the parent directories are also created
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
	
	ifdef DOS32 then
		atom low_buff
		sequence reg_list
		mode = mode -- get rid of not used warning
		low_buff = allocate_low(length (name) + 1)
		if not low_buff then
			return 0
		end if

		poke(low_buff, name & 0)
		reg_list = repeat(0,10)
		if short_names then
			reg_list[REG_AX] = #3900
		else
			reg_list[REG_AX] = #7139
		end if

		reg_list[REG_DS] = floor(low_buff / 16)
		reg_list[REG_DX] = remainder(low_buff, 16)
		reg_list[REG_FLAGS] = or_bits(reg_list[REG_FLAGS], 1)
		reg_list = dos_interrupt(#21, reg_list)
		free_low(low_buff)

		if and_bits(reg_list[REG_FLAGS], 1) != 0 then
			return 0
		else
			return 1
		end if
	else
		pname = allocate_string(name)
	end ifdef

	ifdef UNIX then
		ret = not c_func(xCreateDirectory, {pname, mode})
	elsifdef WIN32 then
		ret = c_func(xCreateDirectory, {pname, 0})
		mode = mode -- get rid of not used warning
	end ifdef

	return ret
end function

--**
-- Remove a directory.
--
-- Parameters:
--		# ##name##: a sequence, the name of the directory to remove.
--      # ##force##: an integer, if 1 this will also remove files and
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

integer delete_file_id = -1, dir_id = -1
with trace
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

	files = call_func(dir_id, {dir_name})
	if atom(files) then
		return 0
	end if
	if not equal(files[1][D_NAME], ".") then
		return 0	-- Supplied dir_name was not a directory
	end if
	
	
	dir_name &= SLASH
	
	for i = 1 to length(files) do
		if find(files[i][D_NAME], {".", ".."}) then
			continue
			
		elsif not force then
			return 0
		else
			if find('d', files[i][D_ATTRIBUTES]) then
				ret = remove_directory(dir_name & files[i][D_NAME] & SLASH, force)
			else
				ret = call_func(delete_file_id, {dir_name & files[i][D_NAME]})
			end if
			if not ret then
				return 0
			end if
		end if
	end for
	
	ifdef DOS32 then
	    atom low_buff
	    sequence reg_list
	    low_buff = allocate_low(length(dir_name) + 1)
	    if not low_buff then
	        return 0
	    end if
	    poke(low_buff, dir_name & 0)
	    reg_list = repeat(0,10)
	    if short_names then
	        reg_list[REG_AX] = #3A00
	    else
	        reg_list[REG_AX] = #713A
	    end if
	    reg_list[REG_DS] = floor(low_buff / 16)
	    reg_list[REG_DX] = remainder(low_buff, 16)
	    reg_list[REG_FLAGS] = or_bits(reg_list[REG_FLAGS], 1)
	    reg_list = dos_interrupt(#21, reg_list)
	    free_low(low_buff)
	    if and_bits(reg_list[REG_FLAGS], 1) != 0 then
	        return 0
	    else
	        return 1
	    end if
	end ifdef
	
	pname = allocate_string(dir_name)
	ret = c_func(xRemoveDirectory, {pname})
	ifdef UNIX then
			ret = not ret 
	end ifdef
	free(pname)
	return ret
end function

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
-- Return directory information for the specified file or directory.
--
-- Parameters:
--     # ##name##: a sequence, the name to be looked up in the file system.
--
-- Returns:
--     An **object**: -1 if no match found, else a sequence of sequence entries
--
-- Errors:
-- The length of ##name## should not exceed 1,024 characters.
--
-- Comments:
--     ##name## can also contain * and ? wildcards to select multiple
-- files.
--
-- The returned information is similar to what you would get from the DOS DIR command. A sequence
-- is returned where each element is a sequence that describes one file or subdirectory.
-- 
-- If ##name## refers to a **directory** you may have entries for "." and "..",
-- just as with the DOS DIR command. If it refers to an existing **file**, and has no wildcards, 
-- then the returned sequence will have just one entry, i.e. its length will be 1. If ##name## 
-- contains wildcards you may have multiple entries.
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

public function dir(sequence name)
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
	if find(SLASH, name) = 0 then
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
dir_id = routine_id("dir")

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
-- 		##newdir##: a sequence, the name for the new working directory.
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
-- On //DOS32// and //WIN32// the current directory is a public property shared
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

--**
-- Bad path error code

public constant W_BAD_PATH = -1 -- error code

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
public integer my_dir = DEFAULT

--**
-- Generalized Directory Walker
--
-- Parameters:
-- 		# ##path_name##: a sequence, the name of the directory to walk through
-- 		# ##your_function##: an integer, either ##my_dir## or the routine id of a callback 
-- 		  Euphoria function
-- 		# ##scan_subdirs##: an integer, 1 to also walk though subfolders, 0 to skip them all.
--
-- Returns:
-- An **object**:
-- * 0 on success
-- * W_BAD_PATH: an error occurred
-- * anything else: the custom function returned something to stop [[:walk_dir]]().
--
-- Comments:
--
-- This routine will "walk" through a directory named ##path_name##. For each entry in the 
-- directory, it will call a function, whose routine_id is ##your_function##.
-- If ##scan_subdirs## is non-zero (TRUE), then the subdirectories in
-- st will be walked through recursively in the very same way.
--
-- The routine that you supply should accept two sequences, the path name and dir() entry for 
-- each file and subdirectory. It should return 0 to keep going, or non-zero to stop 
-- walk_dir(). Returning ##W_BAD_PATH## is taken as denoting some error.
--
-- This mechanism allows you to write a simple function that handles one file at a time, 
-- while walk_dir() handles the process of walking through all the files and subdirectories.
--
-- By default, the files and subdirectories will be visited in alphabetical order. To use 
-- a different order, set the public integer ##my_dir## to the routine id of your own modified
-- [[:dir]] function that sorts the directory entries differently. See the default ##dir()##
-- function in filesys.e.
--
-- The path that you supply to ##walk_dir()## must not contain wildcards (* or ?). Only a 
-- single directory (and its subdirectories) can be searched at one time.
--
-- Example 1:
-- <eucode>
-- function look_at(sequence path_name, sequence item)
-- -- this function accepts two sequences as arguments
--     printf(STDOUT, "%s\\%s: %d\n",
--            {path_name, item[D_NAME], item[D_SIZE]})
--     return 0 -- keep going
-- end function
--
-- exit_code = walk_dir("C:\\MYFILES", routine_id("look_at"), TRUE)
-- </eucode>
--
-- See Also:
--   ##bin\search.ex##

public function walk_dir(sequence path_name, object your_function, integer scan_subdirs)
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
-- === File Handling
--

--**
-- Check to see if a file exists
--
-- Parameters:
--   * name - filename to check existence of
--
-- Returns:
--   1 on yes, 0 on no
--
-- Example 1:
-- <eucode>
-- if file_exists("abc.e") then
--     puts(1, "abc.e exists already\n")
-- end if
-- </eucode>

public function file_exists(sequence name)
	ifdef WIN32 then
		atom pName = allocate_string(name)
		integer r = c_func(xGetFileAttributes, {pName})
		free(pName)

		return r > 0

	elsifdef UNIX then
		atom pName = allocate_string(name)
		integer r = c_func(xGetFileAttributes, {pName, 0})
		free(pName)

		return r = 0

	else

		return sequence(dir(name))
	end ifdef
end function

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
--     If ##overwrite## is true, and if dest file already exists,
--     the function overwrites the existing file and succeeds.
--
-- See Also:
-- [[:move_file]], [[:rename_file]]

public function copy_file(sequence src, sequence dest, atom overwrite)
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
-- 		If ##dest## contains a path specification, this is equivalent to moving the file, as 
-- 		well as possibly changing its name. However, the path must be on the same drive for 
-- 		this to work.
--
-- See Also:
-- [[:move_file]], [[:copy_file]]

public function rename_file(sequence src, sequence dest)
	atom psrc, pdest, ret
	ifdef DOS32 then
    atom low_buff_old, low_buff_new
    integer i
    sequence reg_list
    if length(src) > 3 and length(dest) > 3 then
        if not compare(src[2],":") and not compare(dest[2],":") then
            if compare(src[1], dest[1]) then
		-- renaming a file across drives is not supported
                return 0
            end if
        end if
    end if
    low_buff_old = allocate_low(length(src) + 1)
    if not low_buff_old then
        return 0
    end if
    low_buff_new = allocate_low(length(dest) + 1)
    if not low_buff_new then
        free_low(low_buff_old)
        return 0
    end if
    poke(low_buff_old, src & 0)
    poke(low_buff_new, dest & 0)
    reg_list = repeat(0,10)
    if short_names then
        reg_list[REG_AX] = #5600
    else
        reg_list[REG_AX] = #7156
    end if
    reg_list[REG_DS] = floor(low_buff_old / 16)
    reg_list[REG_DX] = remainder(low_buff_old, 16)
    reg_list[REG_ES] = floor(low_buff_new / 16)
    reg_list[REG_DI] = remainder(low_buff_new, 16)
    reg_list[REG_FLAGS] = or_bits(reg_list[REG_FLAGS], 1)
    reg_list = dos_interrupt(#21, reg_list)
    free_low(low_buff_old)
    free_low(low_buff_new)
    if and_bits(reg_list[REG_FLAGS], 1) != 0 then
        return 0
    else
        return 1
    end if
	end ifdef
	
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

public function delete_file(sequence name)
	atom pfilename, ret

	ifdef DOS32 then
    atom low_buff
    sequence reg_list
    low_buff = allocate_low(length(name) + 1)
    if not low_buff then
        return 0
    end if
    poke(low_buff, name & 0)
    reg_list = repeat(0,10)
    if short_names then
        reg_list[REG_AX] = #4100
    else
        reg_list[REG_AX] = #7141
    end if
    reg_list[REG_DS] = floor(low_buff / 16)
    reg_list[REG_DX] = remainder(low_buff, 16)
    reg_list[REG_SI] = #0000
    reg_list[REG_FLAGS] = or_bits(reg_list[REG_FLAGS], 1)
    reg_list = dos_interrupt(#21, reg_list)
    free_low(low_buff)
    if and_bits(reg_list[REG_FLAGS], 1) != 0 then
        return 0
    else
        return 1
    end if
	end ifdef

	pfilename = allocate_string(name)
	ret = c_func(xDeleteFile, {pfilename})
	
	ifdef UNIX then
		ret = not ret
	end ifdef

	free(pfilename)

	return ret
end function
delete_file_id = routine_id("delete_file")

ifdef LINUX then
	function xstat(atom psrc, atom psrcbuf)
		return c_func(xStatFile, {3, psrc, psrcbuf})
	end function
elsifdef UNIX then
	function xstat(atom psrc, atom psrcbuf)
		return c_func(xStatFile, {psrc, psrcbuf})
	end function
end ifdef
integer dirname_id = -1

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
--
-- See Also:
-- [[:rename_file]], [[:copy_file]]

public function move_file(sequence src, sequence dest, atom overwrite=0)
	atom psrc, pdest, ret, pdir
	ifdef DOS32 then
    atom low_buff_old, low_buff_new
    integer i
    sequence reg_list
    if length(src) > 3 and length(dest) > 3 then
        if not compare(src[2],":") and not compare(dest[2],":") then
            if compare(src[1], dest[1]) then
                i = copy_file(src,dest,overwrite)
                if not i then
                    return i
                end if
                i = delete_file(src)
                return i
            end if
        end if
    end if
    low_buff_old = allocate_low(length(src) + 1)
    if not low_buff_old then
        return 0
    end if
    low_buff_new = allocate_low(length(dest) + 1)
    if not low_buff_new then
        free_low(low_buff_old)
        return 0
    end if
    poke(low_buff_old, src & 0)
    poke(low_buff_new, dest & 0)
    reg_list = repeat(0,10)
    if short_names then
        reg_list[REG_AX] = #5600
    else
        reg_list[REG_AX] = #7156
    end if
    reg_list[REG_DS] = floor(low_buff_old / 16)
    reg_list[REG_DX] = remainder(low_buff_old, 16)
    reg_list[REG_ES] = floor(low_buff_new / 16)
    reg_list[REG_DI] = remainder(low_buff_new, 16)
    reg_list[REG_FLAGS] = or_bits(reg_list[REG_FLAGS], 1)
--TODO double check that this honors the overwrite flag, and manually add a check if not
    reg_list = dos_interrupt(#21, reg_list)
    free_low(low_buff_old)
    free_low(low_buff_new)
    if and_bits(reg_list[REG_FLAGS], 1) != 0 then
        return 0
    else
        return 1
    end if
	end ifdef
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
		ret = xstat(psrc, psrcbuf)
		if ret then
			goto "out"
		end if
		ret = xstat(pdest, pdestbuf)
		if ret then
			if length(call_func(dirname_id,{dest})) = 0 then
				pdir = allocate_string(current_dir())
			else
				pdir = allocate_string(call_func(dirname_id,{dest}))
			end if
			ret = xstat(pdir, pdestbuf)
			free(pdir)
		end if
		if ret then
			goto "continue"
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
		label "continue"
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

public function file_length(sequence filename)
	object list
	list = dir(filename)
	if atom(list) or length(list) = 0 then
		return -1
	end if
	return list[1][D_SIZE]
end function

public enum
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
-- A public enum has been created for ease of use:
-- * FILETYPE_UNDEFINED     = -1,
-- * FILETYPE_NOT_FOUND, -- = 0
-- * FILETYPE_FILE,      -- = 1
-- * FILETYPE_DIRECTORY  -- = 2
--
-- See Also:
-- [[:dir]]

public function file_type(sequence filename)
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

public enum
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
--
-- A public enum has been created for ease of using the returned value:
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

public function pathinfo(sequence path)
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

public function dirname(sequence path)
	sequence data
	data = pathinfo(path)
	return data[1]
end function
dirname_id = routine_id("dirname")

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
  
public function filename(sequence path)
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

public function filebase(sequence path)
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

public function fileext(sequence path)
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
-- 		# ##path##: the path to check for an extension.
-- 		# ##defext##: the extentsion to add if ##path## does not have one.
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

--- TODO
--- copy_directory( srcpath, destpath, structonly = 0)

--**
-- Clear (delete) a directory of all files, but retaining sub-directories.
--
-- Parameters:
--		# ##name##: a sequence, the name of the directory whose files you want to remove.
--		# ##recurse##: an integer, whether or not to remove files in the 
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
		if find(files[i][D_NAME], {".", ".."}) then
			continue
		elsif find('d', files[i][D_ATTRIBUTES]) then
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

