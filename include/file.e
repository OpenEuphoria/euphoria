-- (c) Copyright 2007 Rapid Deployment Software - See License.txt
--
-- Euphoria 3.1
-- Directory and File Operations --

include sort.e
include misc.e

constant M_SEEK  = 19,
	 M_WHERE = 20,
	 M_DIR   = 22,
	 M_CURRENT_DIR = 23,
	 M_ALLOW_BREAK = 42,
	 M_CHECK_BREAK = 43,
	 M_FLUSH = 60,
	 M_LOCK_FILE = 61,
	 M_UNLOCK_FILE = 62,
	 M_CHDIR = 63

type file_number(integer f)
    return f >= 0
end type

type file_position(atom p)
    return p >= -1
end type

type boolean(integer b)
    return b = 0 or b = 1
end type

global function seek(file_number fn, file_position pos)
-- Seeks to a byte position in the file, 
-- or to end of file if pos is -1.
-- This function is normally used with
-- files opened in binary mode.
    return machine_func(M_SEEK, {fn, pos})
end function

global function where(file_number fn)
-- Returns the current byte position in the file.
-- This function is normally used with
-- files opened in binary mode.
    return machine_func(M_WHERE, fn)
end function

global procedure flush(file_number fn)
-- flush out the buffer associated with file fn
    machine_proc(M_FLUSH, fn)
end procedure

global constant LOCK_SHARED = 1, 
		LOCK_EXCLUSIVE = 2
	 
type lock_type(integer t)
    if platform() = LINUX then
	return t = LOCK_SHARED or t = LOCK_EXCLUSIVE
    else
	return 1
    end if
end type

type byte_range(sequence r)
    if length(r) = 0 then
	return 1
    elsif length(r) = 2 and r[1] <= r[2] then
	return 1
    else
	return 0
    end if
end type

global function lock_file(file_number fn, lock_type t, byte_range r)
-- Attempt to lock a file so other processes won't interfere with it.
-- The byte range can be {} if you want to lock the whole file
    return machine_func(M_LOCK_FILE, {fn, t, r})
end function

global procedure unlock_file(file_number fn, byte_range r) 
-- The byte range can be {} if you want to unlock the whole file.
    machine_proc(M_UNLOCK_FILE, {fn, r})
end procedure

global constant 
	D_NAME = 1,
	D_ATTRIBUTES = 2,
	D_SIZE = 3,

	D_YEAR = 4,
	D_MONTH = 5,
	D_DAY = 6,

	D_HOUR = 7,
	D_MINUTE = 8,
	D_SECOND = 9
global function dir(sequence name)
-- returns directory information, given the name
-- of a file or directory. Format returned is:
-- {
--  {"name1", attributes, size, year, month, day, hour, minute, second},
--  {"name2", ...                                                     },
-- }
    return machine_func(M_DIR, name)
end function

global function current_dir()
-- returns name of current working directory
    return machine_func(M_CURRENT_DIR, 0)
end function

global function chdir(sequence newdir)
-- Changes the current directory. Returns 1 - success, 0 - fail.
    return machine_func(M_CHDIR, newdir)
end function

global procedure allow_break(boolean b)
-- If b is TRUE then allow control-c/control-break to
-- terminate the program. If b is FALSE then don't allow it.
-- Initially they *will* terminate the program, but only when it
-- tries to read input from the keyboard.
    machine_proc(M_ALLOW_BREAK, b)
end procedure

global function check_break()
-- returns the number of times that control-c or control-break
-- were pressed since the last time check_break() was called
    return machine_func(M_CHECK_BREAK, 0)
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

integer SLASH
if platform() = LINUX then
    SLASH='/'
else
    SLASH='\\'
end if

-- override the dir sorting function with your own routine id
constant DEFAULT = -2
global integer my_dir 
my_dir = DEFAULT  -- it's better not to use routine_id() here,
		  -- or else users will have to bind with clear routine names

global function walk_dir(sequence path_name, integer your_function, 
			 integer scan_subdirs)
-- Generalized Directory Walker
-- Walk through a directory and (optionally) its subdirectories,
-- "visiting" each file and subdirectory. Your function will be called
-- via its routine id. The visits will occur in alphabetical order.
-- Your function should accept the path name and dir() entry for
-- each file and subdirectory. It should return 0 to keep going,
-- or an error code (greater than 0) to quit, or it can return
-- any sequence or atom other than 0 as a useful diagnostic value.
    object d, abort_now
    
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
		abort_now = call_func(your_function, {path_name, d[i]})
		if not equal(abort_now, 0) then
		    return abort_now
		end if
		if scan_subdirs then
		    abort_now = walk_dir(path_name & SLASH & d[i][D_NAME],
					 your_function, scan_subdirs)
		    
		    if not equal(abort_now, 0) and 
		       not equal(abort_now, W_BAD_PATH) then
			-- allow BAD PATH, user might delete a file or directory 
			return abort_now
		    end if
		end if
	    end if
	else
	    -- a file
	    abort_now = call_func(your_function, {path_name, d[i]})
	    if not equal(abort_now, 0) then
		return abort_now
	    end if
	end if
    end for
    return 0
end function


