-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
--****
-- == File System
--
-- Cross platform file operations for Euphoria
--
-- === Routines
--

-- TODO: Add unit tests

include dll.e
include file.e
include machine.e

object xCopyFile, xMoveFile, xDeleteFile, xCreateDirectory, xRemoveDirectory

ifdef WIN32 then
	constant lib = open_dll("kernel32")
	xCopyFile         = define_c_func(lib, "CopyFileA", 
		{C_POINTER, C_POINTER, C_LONG}, C_LONG)
	xMoveFile         = define_c_func(lib, "MoveFileA", 
		{C_POINTER, C_POINTER}, C_LONG)
	xDeleteFile       = define_c_func(lib, "DeleteFileA", {C_POINTER}, C_LONG)
	xCreateDirectory  = define_c_func(lib, "CreateDirectoryA", 
		{C_POINTER, C_POINTER}, C_LONG)
	xRemoveDirectory  = define_c_func(lib, "RemoveDirectoryA", 
		{C_POINTER}, C_LONG)

elsifdef LINUX then
	constant lib = open_dll("")

elsifdef FREEBSD then
	constant lib = open_dll("libc.so")
	
elsifdef OSX then
	constant lib = open_dll("libc.dylib")
	
else
	include machine.e
	crash("filesys.e requires Windows, Linux, FreeBSD or OS X")

end ifdef

ifdef UNIX then
	xMoveFile   = define_c_func(lib, "rename", {C_POINTER, C_POINTER}, C_LONG)
	xDeleteFile = define_c_func(lib, "remove", {C_POINTER}, C_LONG)
end ifdef

--**
-- Copy a file from src to dest.
--
-- Returns:
--     Returns false if failed, true if succeeded.
--
-- Comments:
--     If overwrite is true, if dest file already exists, 
--     the function overwrites the existing file and succeeds.

export function copy_file(sequence src, sequence dest, atom overwrite)
	atom psrc, pdest, ret

	psrc = allocate_string(src)
	pdest = allocate_string(dest)
	ret = c_func(xCopyFile, {psrc, pdest, not overwrite})
	free(pdest)
	free(psrc)
	
	return ret
end function

--**
-- Move/Rename a file from src to dest.
--
-- Returns:
--     Returns false if failed, true if succeeded.

export function move_file(sequence src, sequence dest)
	atom psrc, pdest, ret
	psrc = allocate_string(src)
	pdest = allocate_string(dest)
	ret = c_func(xMoveFile, {psrc, pdest})
	if platform() = LINUX then ret = not ret end if
	free(pdest)
	free(psrc)
	return ret
end function

--**
-- Delete a file named filename
--
-- Returns:
--     Returns false if failed, true if succeeded.

export function delete_file(sequence filename)
	atom pfilename, ret
	pfilename = allocate_string(filename)
	ret = c_func(xDeleteFile, {pfilename})
	if platform() = LINUX then ret = not ret end if
	free(pfilename)
	return ret
end function

--**
-- Create a directory named name
--
-- Returns:
--     Returns false if failed, true if succeeded.

export function create_directory(sequence name)
	atom pname, ret
	pname = allocate_string(name)
	ret = c_func(xCreateDirectory, {pname, 0})
	return ret
end function

--**
-- Remove a directory named name
--
-- Returns:
--     Returns false if failed, true if succeeded.

export function remove_directory(sequence name)
	atom pname, ret
	pname = allocate_string(name)
	ret = c_func(xRemoveDirectory, {pname})
	free(pname)
	return ret
end function

--**
-- Return length of file filename.
--
-- Comments:
--     if not found, returns -1

export function file_length(sequence filename)
	object list
	list = dir(filename)
	if atom(list) or length(list) = 0 then
		return -1
	end if
	return list[1][D_SIZE]
end function

--**
-- Returns the type of the file specified
-- 
-- Returns:
--     * 0 if filename does not exist
--     * 1 if filename is a file
--     * 2 if filename is a directory

export function file_type(sequence filename)
object dirfil
	if find('*', filename) or find('*', filename) then return 0 end if
	
	if length(filename) = 2 and filename[2] = ':' then
		filename &= "\\"
	end if
	
	dirfil = dir(filename)
	if sequence(dirfil) then
		if find('d', dirfil[1][2]) or (length(filename)=3 and filename[2]=':') then
			return 2
		else
			return 1
		end if
	else
		return 0
	end if
end function
