-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
--****
-- == I/O
-- **Page Contents**
--
-- <<LEVELTOC depth=2>>

include sort.e
include wildcard.e
include types.e

constant M_SEEK  = 19,
		 M_WHERE = 20,
		 M_FLUSH = 60,
		 M_LOCK_FILE = 61,
		 M_UNLOCK_FILE = 62

--****
-- === Constants

--**
-- Standard Input
export constant STDIN = 0

--**
-- Standard Output
export constant STDOUT = 1

--**
-- Standard Error
export constant STDERR = 2

--**
-- Screen (Standard Out)
export constant SCREEN = 1

--**
-- End of file
export constant EOF = -1

--****
-- ==== Routines

--**
-- Signature:
-- global procedure ?
--
-- Description:
-- Shorthand way of saying: **pretty_print(STDOUT, x, {})** - i.e. printing the value of an 
-- expression to the standard output, with braces and indentation to show the structure.
--
-- Example 1:
-- <eucode>
-- ? {1, 2} + {3, 4}  -- will display {4, 6}
-- </eucode>

--**
-- Signature:
-- global procedure print(integer fn, object x)
--
-- Description:
-- Print, to file or device fn, an object x with braces { , , , } to show the structure.
--
-- Example 1:
-- <eucode>
-- print(STDOUT, "ABC")  -- output is:  {65, 66, 67}
-- puts(STDOUT, "ABC")   -- output is:  ABC
-- </eucode>
--
-- Example 2:
-- <eucode>
-- print(STDOUT, repeat({10,20}, 3)) -- output is: {{10,20},{10,20},{10,20}} 
-- </eucode>

--**
-- Signature:
-- global procedure printf(integer fn, sequence st, sequence x)
--
-- Description:
-- Print x, to file or device fn, using format string st. If x is a sequence, 
-- then format specifiers from st are matched with corresponding elements of 
-- x. If x is an atom, then normally st will contain just one format specifier 
-- and it will be applied to x, however if st contains multiple format specifiers, 
-- each one will be applied to the same value x. Thus printf() always takes 
-- exactly 3 arguments. Only the length of the last argument, containing the 
-- values to be printed, will vary. The basic format specifiers are...
--
-- * ##%d## - print an atom as a decimal integer
-- * ##%x## - print an atom as a hexadecimal integer. Negative numbers are printed
--            in two's complement, so -1 will print as FFFFFFFF
-- * ##%o## - print an atom as an octal integer
-- * ##%s## - print a sequence as a string of characters, or print an atom as a single 
--            character
-- * ##%e## - print an atom as a floating-point number with exponential notation
-- * ##%f## - print an atom as a floating-point number with a decimal point but no exponent
-- * ##%g## - print an atom as a floating-point number using whichever format seems 
--            appropriate, given the magnitude of the number
-- * ##~%~%## - print the '%' character itself
--
-- Field widths can be added to the basic formats, e.g. %5d, %8.2f, %10.4s. The number 
-- before the decimal point is the minimum field width to be used. The number after 
-- the decimal point is the precision to be used.
--
-- If the field width is negative, e.g. %-5d then the value will be left-justified 
-- within the field. Normally it will be right-justified. If the field width 
-- starts with a leading 0, e.g. %08d then leading zeros will be supplied to fill up 
-- the field. If the field width starts with a '+' e.g. %+7d then a plus sign will 
-- be printed for positive values. 
--
-- Comments:
-- Watch out for the following common mistake:
--
-- <eucode>
-- name="John Smith"
-- printf(STDOUT, "%s", name)     -- error!
-- </eucode>
--
-- This will print only the first character, J, of name, as each element of 
-- name is taken to be a separate value to be formatted. You must say this instead:
-- 	
-- <eucode>
-- name="John Smith"
-- printf(STDOUT, "%s", {name})   -- correct
-- </eucode>
--
-- Now, the third argument of printf() is a one-element sequence containing the 
-- item to be formatted.
--
-- Example 1:
-- <eucode>
-- rate = 7.875
-- printf(myfile, "The interest rate is: %8.2f\n", rate)
--
-- --      The interest rate is:     7.88
-- </eucode>
--
-- Example 2:
-- <eucode>
-- name="John Smith"
-- score=97
-- printf(STDOUT, "%15s, %5d\n", {name, score})
--
-- --      John Smith,    97
-- </eucode>
--
-- Example 3:
-- <eucode>
-- printf(STDOUT, "%-10.4s $ %s", {"ABCDEFGHIJKLMNOP", "XXX"})
-- --      ABCD       $ XXX
-- </eucode>
--
-- Example 4:
-- <eucode>
-- printf(STDOUT, "%d  %e  %f  %g", 7.75) -- same value in different formats
--
-- --      7  7.750000e+000  7.750000  7.75
-- </eucode>
--
-- See Also:
--     [[:sprintf]], [[:sprint]]

--**
-- Signature:
-- global procedure puts(integer fn, sequence x)
--
-- Description:
-- Output, to file or device fn, a single byte (atom) or sequence of bytes. The low order 
-- 8-bits of each value is actually sent out. If fn is the screen you will see text 
-- characters displayed.
--
-- Comments:
-- When you output a sequence of bytes it must not have any (sub)sequences within it. It 
-- must be a sequence of atoms only. (Typically a string of ASCII codes).
--
-- Avoid outputting 0's to the screen or to standard output. Your output might get truncated.
--
-- Remember that if the output file was opened in text mode, //DOS// and 
-- //Windows// will change ##\n## (10) to ##\r\n## (13 10). Open the file in binary mode if 
-- this is not what you want. 
--
-- Example 1:
-- <eucode>
-- puts(SCREEN, "Enter your first name: ")
-- </eucode>
--
-- Example 2: 	
-- <eucode>
-- puts(output, 'A')  -- the single byte 65 will be sent to output
-- </eucode>

--**
-- Signature:
-- global function getc(integer fn)
--
-- Description:
--     Get the next character (byte) from file or device fn. The character will have a value 
--     from 0 to 255. [[:EOF]] is returned at end of file.
--
-- Comments:
--     File input using getc() is buffered, i.e. getc() does not actually go out to the disk 
--     for each character. Instead, a large block of characters will be read in at one time 
--     and returned to you one by one from a memory buffer.
--
--     When getc() reads from the keyboard, it will not see any characters until the user 
--     presses Enter. Note that the user can type CTRL+Z, which the operating system treats 
--     as "end of file". [[:EOF]] will be returned. 

--**
-- Signature:
-- global function gets(integer fn)
--
-- Description:
--     Get the next sequence (one line, including '\n') of characters from file or device fn. The 
--     characters will have values from 0 to 255. The atom [[:EOF]] is returned on end of file.
--
-- Comments:
--     Because either a sequence or an atom (-1) might be returned, you should probably assign the 
--     result to a variable declared as object.
--
--     After reading a line of text from the keyboard, you should normally output a \n character, 
--     e.g.  puts(1, '\n'), before printing something. Only on the last line of the screen does the 
--     operating system automatically scroll the screen and advance to the next line.
--
--     The last line in a file might not end with a new-line '\n' character.
--
--     When your program reads from the keyboard, the user can type control-Z, which the operating 
--     system treats as "end of file". [[:EOF]] will be returned.
--
--     In SVGA modes, DOS might set the wrong cursor position, after a call to gets(0) to read the
--     keyboard. You should set it yourself using ##position()##.
--
-- Example 1:
-- <eucode>
-- sequence buffer
-- object line
-- integer fn
--
-- -- read a text file into a sequence
-- fn = open("myfile.txt", "r")
-- if fn = -1 then
--     puts(1, "Couldn't open myfile.txt\n")
--     abort(1)
-- end if
--
-- buffer = {}
-- while 1 do
--     line = gets(fn)
--     if atom(line) then
--         exit   -- EOF is returned at end of file
--     end if
--     buffer = append(buffer, line)
-- end while
-- </eucode>
--
-- Example 2:
-- <eucode>
-- object line
--
-- puts(1, "What is your name?\n")
-- line = gets(0)  -- read standard input (keyboard)
-- line = line[1..length(line)-1] -- get rid of \n character at end
-- puts(1, '\n')   -- necessary
-- puts(1, line & " is a nice name.\n")
-- </eucode>

constant CHUNK = 100

--**
-- Read the next n bytes from file number fn. Return the bytes
-- as a sequence. The sequence will be of length n, except
-- when there are fewer than n bytes remaining to be read in the
-- file.
--
-- Comments:
--     When i > 0 and <a href="lib_seq.htm#length">length(s)</a> < i you know
--     you've reached the end of file. Eventually, an
--     <a href="refman_2.htm#empty_seq">empty sequence</a> will be returned
--     for s.
--  
--     This function is normally used with files opened in binary mode, "rb".
--     This avoids the confusing situation in text mode where DOS will convert CR LF pairs to LF.
--
-- Example 1:
--     <eucode>
--     
--     integer fn
--     fn = open("temp", "rb")  -- an existing file
--
--     sequence whole_file
--     whole_file = {}
--
--     sequence chunk
--
--     while 1 do
--         chunk = get_bytes(fn, 100) -- read 100 bytes at a time
--         whole_file &= chunk        -- chunk might be empty, that's ok
--         if length(chunk) < 100 then
--             exit
--         end if
--     end while
--
--     close(fn)
--     ? length(whole_file)  -- should match DIR size of "temp"
--     </eucode>

export function get_bytes(integer fn, integer n)
-- Return a sequence of n bytes (maximum) from an open file.
-- If n > 0 and fewer than n bytes are returned,
-- you've reached the end of file.
-- This function is normally used with files opened in binary mode.
	sequence s
	integer c, first, last

	if n = 0 then
		return {}
	end if
	
	c = getc(fn)
	if c = EOF then
		return {}
	end if
	
	s = repeat(c, n)

	last = 1
	while last < n do
		-- for speed, read a chunk without checking for EOF
		first = last+1
		last  = last+CHUNK
		if last > n then
			last = n
		end if
		for i = first to last do
			s[i] = getc(fn)
		end for
		-- check for EOF after each chunk
		if s[last] = EOF then  
			-- trim the EOF's and return
			while s[last] = EOF do
				last -= 1
			end while 
			return s[1..last]
		end if
	end while   
	return s
end function


--****
-- === Low Level File/Device Handling

--
-- Described under lock_file()
--

global enum 
	LOCK_SHARED, 
	LOCK_EXCLUSIVE

--**
-- File number type

export type file_number(integer f)
	return f >= 0
end type

--**
-- File position type

export type file_position(atom p)
	return p >= -1
end type

		 
--**
-- Lock Type

export type lock_type(integer t)
	return t = LOCK_SHARED or t = LOCK_EXCLUSIVE
end type

--**
-- Byte Range Type

export type byte_range(sequence r)
	if length(r) = 0 then
		return 1
	elsif length(r) = 2 and r[1] <= r[2] then
		return 1
	else
		return 0
	end if
end type

--**
-- Signature:
-- global function open(atom st1, sequence st2)
--
-- Description:
-- Open a file or device, to get the file number. -1 is returned if the open fails. st1 is 
-- the path name of the file or device. st2 is the mode in which the file is to be opened. 
-- Possible modes are:
--
-- * "r" - open text file for reading
-- * "rb" - open binary file for reading
-- * "w" - create text file for writing
-- * "wb" - create binary file for writing
-- * "u" - open text file for update (reading and writing)
-- * "ub" - open binary file for update
-- * "a" - open text file for appending
-- * "ab" - open binary file for appending
--
-- Files opened for read or update must already exist. Files opened for write or append will 
-- be created if necessary. A file opened for write will be set to 0 bytes. Output to a 
-- file opened for append will start at the end of file.
--
-- On DOS or Windows, output to text files will have carriage-return characters automatically 
-- added before linefeed characters. On input, these carriage-return characters are removed. 
-- A control-Z character (ASCII 26) will signal an immediate end of file. Note: on some 
-- versions of DOS, a control-Z typed by the user might cause standard input to permanently 
-- appear to be at the end-of-file, until the DOS window is closed.
--
-- I/O to binary files is not modified in any way. Any byte values from 0 to 255 can be 
-- read or written. On Linux and FreeBSD, all files are binary files, so "r" mode and "rb" 
-- mode are equivalent, as are "w" and "wb", "u" and "ub", and "a" and "ab".
--
-- Some typical devices that you can open on DOS or Windows are:
--
-- * "CON" - the console (screen)
-- * "AUX" - the serial auxiliary port
-- * "COM1" - serial port 1
-- * "COM2" - serial port 2
-- * "PRN" - the printer on the parallel port
-- * "NUL" - a non-existent device that accepts and discards output
--
-- Currently, files up to 2 Gb in size can be handled. Beyond that, some file operations may 
-- not work correctly. This limit will likely be increased in the future. 
--
-- Close a file or device and flush out any still-buffered characters.
--
-- Comments:
-- //DOS32//: When running under //Windows 95// or later, you can open any existing file that has a 
-- long file or directory name in its path (i.e. greater than the standard DOS 8.3 format) 
-- using any open mode - read, write etc. However, if you try to create a new file (open 
-- with "w" or "a" and the file does not already exist) then the name will be truncated if 
-- necessary to an 8.3 style name. We hope to support creation of new long-filename files in 
-- a future release.
--
-- //WIN32// and //Unix//: Long filenames are fully supported for reading and writing and 
-- creating.
--
-- //DOS32//: Be careful not to use the special device names in a file name, even if you add an 
-- extension. e.g. ##CON.TXT##, ##CON.DAT##, ##CON.JPG## etc. all refer to the ##CON## device, 
-- **not a file**.
--
-- Example 1:
-- <eucode>
-- integer file_num, file_num95
-- sequence first_line
-- constant ERROR = 2
--
-- file_num = open("myfile", "r")
-- if file_num = -1 then
--     puts(ERROR, "couldn't open myfile\n")
-- else
--     first_line = gets(file_num)
-- end if
--
-- file_num = open("PRN", "w") -- open printer for output
--
-- -- on Windows 95:
-- file_num95 = open("bigdirectoryname\\verylongfilename.abcdefg",
--                   "r")
-- if file_num95 != -1 then
--     puts(STDOUT, "it worked!\n")
-- end if
-- </eucode>

--**
-- Signature:
-- global procedure close(atom fn)
--
-- Description:
-- Close a file or device and flush out any still-buffered characters.
--
-- Comments:
-- Any still-open files will be closed automatically when your program terminates.

--**
-- Seek (move) to any byte position in the file fn or to the end of file if a1 is -1. For 
-- each open file there is a current byte position that is updated as a result of I/O 
-- operations on the file. The initial file position is 0 for files opened for read, write 
-- or update. The initial position is the end of file for files opened for append. The value 
-- returned by seek() is 0 if the seek was successful, and non-zero if it was unsuccessful. 
-- It is possible to seek past the end of a file. If you seek past the end of the file, and 
-- write some data, undefined bytes will be inserted into the gap between the original end 
-- of file and your new data.
--
-- Comments:
-- After seeking and reading (writing) a series of bytes, you may need to call seek() 
-- explicitly before you switch to writing (reading) bytes, even though the file position 
-- should already be what you want.
--
-- This function is normally used with files opened in binary mode. In text mode, DOS 
-- converts CR LF to LF on input, and LF to CR LF on output, which can cause great confusion 
-- when you are trying to count bytes. 
--
-- Example 1:
-- <eucode>
-- include file.e
--
-- integer fn
-- fn = open("mydata", "rb")
-- -- read and display first line of file 3 times:
-- for i = 1 to 3 do
--     puts(STDOUT, gets(fn))
--     if seek(fn, 0) then
--         puts(STDOUT, "rewind failed!\n")
--     end if
-- end for
-- </eucode>

global function seek(file_number fn, file_position pos)
-- Seeks to a byte position in the file, 
-- or to end of file if pos is -1.
-- This function is normally used with
-- files opened in binary mode.
	return machine_func(M_SEEK, {fn, pos})
end function

--**
-- This function returns the current byte position in the file fn. This position is updated 
-- by reads, writes and seeks on the file. It is the place in the file where the next byte 
-- will be read from, or written to.

global function where(file_number fn)
-- Returns the current byte position in the file.
-- This function is normally used with
-- files opened in binary mode.
	return machine_func(M_WHERE, fn)
end function

--**
-- When you write data to a file, Euphoria normally stores the data
-- in a memory buffer until a large enough chunk of data has accumulated. 
-- This large chunk can then be written to disk very efficiently. 
-- Sometimes you may want to force, or flush, all data out immediately, 
-- even if the memory buffer is not full. To do this you must call flush(fn),
-- where fn is the file number of a file open for writing or appending.
--
-- Comments:
-- When a file is closed, (see close()), all buffered data is flushed out. 
--  When a program terminates, all open files are flushed and closed 
--  automatically. Use flush() when another process may need to
--  see all of the data written so far, but you aren't ready
--   to close the file yet.
--
-- Example 1:
-- <eucode>
-- f = open("logfile", "w")
-- puts(f, "Record#1\n")
-- puts(STDOUT, "Press Enter when ready\n")
--
-- flush(f)  -- This forces "Record #1" into "logfile" on disk.
--           -- Without this, "logfile" will appear to have 
--           -- 0 characters when we stop for keyboard input.
--
-- s = gets(0) -- wait for keyboard input
-- </eucode>

global procedure flush(file_number fn)
-- flush out the buffer associated with file fn
	machine_proc(M_FLUSH, fn)
end procedure

--**
-- When multiple processes can simultaneously access a
-- file, some kind of locking mechanism may be needed to avoid mangling
-- the contents of the file, or causing erroneous data to be read from the file.
--
-- ##lock_file()## attempts to place a lock on an open file, ##fn##, to stop 
-- other processes from using the file while your program is reading it 
-- or writing it. Under //Unix//, there are two types of locks that 
-- you can request using the ##t## parameter. (Under //DOS32// and //WIN32// the
-- parameter ##t## is ignored, but should be an integer.)
-- Ask for a **shared** lock when you intend to read a file, and you want to 
-- temporarily block other processes from writing it. Ask for an 
-- **exclusive** lock when you intend to write to a file and you want to temporarily 
-- block other processes from reading or writing it. It's ok for many processes to 
-- simultaneously have shared locks on the same file, but only one process 
-- can have an exclusive lock, and that can happen only when no other 
-- process has any kind of lock on the file. file.e contains the following
-- declaration:
-- 
-- <eucode>
-- global enum
--     LOCK_SHARED, 
--     LOCK_EXCLUSIVE
-- </eucode>
--
-- On //DOS32// and //WIN32// you can lock a specified portion of a file using the s parameter. 
-- s is a sequence of the form: ##{first_byte, last_byte}##. It indicates the first byte and 
-- last byte in the file,  that the lock applies to. Specify the empty sequence ##{}##, 
-- if you want to lock the whole file. In the current release for //Unix//, locks 
-- always apply to the whole file, and you should specify ##{}##
-- for this parameter.
-- 
-- If it is successful in obtaining the desired lock, ##lock_file()## will return 1. If 
-- unsuccessful, it will return 0. ##lock_file()## does not wait
-- for other processes to relinquish their locks. You may have to call it repeatedly, 
-- before the lock request is granted.
--
-- Comments:
-- On //Unix//, these locks are called advisory locks, which means they aren't enforced 
-- by the operating system. It is up to the processes that use a particular file to cooperate 
-- with each other. A process can access a file without first obtaining a lock on it. On 
-- //WIN32// and //DOS32//, locks are enforced by the operating system.
--
-- On //DOS32//, ##lock_file()## is more useful when file sharing is enabled. It will 
-- typically return 0 (unsuccessful) under plain MS-DOS, outside of Windows.
--
-- Example 1:
-- <eucode>
-- include file.e
-- integer v
-- atom t
-- v = open("visitor_log", "a")  -- open for append
-- t = time()
-- while not lock_file(v, LOCK_EXCLUSIVE, {}) do
--     if time() > t + 60 then
--         puts(STDOUT, "One minute already ... I can't wait forever!\n")
--         abort(1)
--     end if
--     sleep(5) -- let other processes run
-- end while
-- puts(v, "Yet another visitor\n")
-- unlock_file(v, {})
-- close(v)
-- </eucode>

global function lock_file(file_number fn, lock_type t, byte_range r)
-- Attempt to lock a file so other processes won't interfere with it.
-- The byte range can be {} if you want to lock the whole file
	return machine_func(M_LOCK_FILE, {fn, t, r})
end function

--**
-- Unlock an open file fn, or a portion of file fn. You must have previously locked the 
-- file using lock_file(). On DOS32 and WIN32 you can unlock a range of bytes within a 
-- file by specifying the s parameter as {first_byte, last_byte}. The same range of bytes 
-- must have been locked by a previous call to lock_file(). On Linux/FreeBSD you can 
-- currently only lock or unlock an entire file. The s parameter should be {} when you 
-- want to unlock an entire file. On Linux/FreeBSD, s must always be {}.
--
-- Comments:
--  You should unlock a file as soon as possible so other processes can use it.
--
-- 	Any files that you have locked, will automatically be unlocked when your program 
--  terminates.
--
-- 	See lock_file() for further comments and an example.
--

global procedure unlock_file(file_number fn, byte_range r) 
-- The byte range can be {} if you want to unlock the whole file.
	machine_proc(M_UNLOCK_FILE, {fn, r})
end procedure

--****
-- === File Reading/Writting

--**
-- Read the contents of either file named s1 or an open file handle i1 as a sequence of lines.
--
-- Example 1:
-- <eucode>
-- data = read_lines("myfile.txt")
-- -- data contains the entire contents of 'myfile.txt', 1 sequence per line:
-- -- {"Line 1", "Line 2", "Line 3"}
-- </eucode>
--
-- Example 2:
-- <eucode>
-- fh = open("myfile.txt", "r")
-- data = read_lines(fh)
-- close(fh)
--
-- -- data contains the entire contents of 'myfile.txt', 1 sequence per line:
-- -- {"Line 1", "Line 2", "Line 3"}
-- </eucode>

export function read_lines(object f)
	object fn, ret, y
	if sequence(f) then
			fn = open(f, "r")
	else
			fn = f
	end if
	if fn < 0 then return -1 end if
	
	ret = {}
	while sequence(y) entry do
		if y[$] = '\n' then
			y = y[1..$-1]
		end if
		ret = append(ret, y)
	entry
		y = gets(fn)
	end while
	
	if sequence(f) then
			close(fn)
	end if
	return ret
end function

--**
-- Write lines contained in s to file named x or file handle x. 
--
-- Returns:
--     1 on success
--     -1 on failure.
--
-- Comments:
-- If x is an atom, it is assumed to be an open file handle. If x is a sequence, it is assumed
-- to be a filename.
--
-- When x is a file handle, the file is not closed after writing is finished. When x is a
-- file name, it is opened, written to and then closed.
--
-- Example 1:
-- <eucode>
-- if write_lines("data.txt", {"This is important data", "Goodybe"}) != -1 then
--     puts(STDERR, "Failed to write data\n")
-- end if
-- </eucode>
--
-- See Also:
--     [[:read_lines]], [[:write_file]]

export function write_lines(object f, sequence lines)
	object fn

	if sequence(f) then
    	fn = open(f, "w")
	else
		fn = f
	end if
	if fn < 0 then return -1 end if

	for i = 1 to length(lines) do
		puts(fn, lines[i])
		puts(fn, '\n')
	end for

	if sequence(f) then
		close(fn)
	end if

	return 1
end function

--**
-- Append lines contained in s2 to file named s1. Returns 1 on success, -1 on failure.
--
-- Comments:
-- s1 is a filename.
--
-- It is opened, written to and then closed.
--
-- Example 1:
-- <eucode>
-- if append_lines("data.txt", {"This is important data", "Goodbye"}) != -1 then
--     puts(STDERR, "Failed to append data\n")
-- end if
-- </eucode>
--
-- See Also:
--     [[:write_lines]]

export function append_lines(sequence f, sequence lines)
	object fn

  	fn = open(f, "a")
	if fn < 0 then return -1 end if

	for i = 1 to length(lines) do
		puts(fn, lines[i])
		puts(fn, '\n')
	end for

	close(fn)

	return 1
end function

--**
-- Read the contents of either file named s1 or an open file handle i1. Returns the contents 
-- as 1 sequence.
--
-- Example 1:
-- <eucode>
-- data = read_file("myfile.txt")
-- -- data contains the entire contents of 'myfile.txt'
-- </eucode>
--
-- Example 2:
-- <eucode>
-- fh = open("myfile.txt", "r")
-- data = read_file(fh)
-- close(fh)
--
-- -- data contains the entire contents of 'myfile.txt'
-- </eucode>
--
-- See Also:
--     [[:write_file]], [[:read_lines]]

export function read_file(object f)
	integer fn
	integer len
	sequence ret
	integer temp

	if sequence(f) then
		fn = open(f, "rb")
	else
		fn = f
	end if
	if fn < 0 then return -1 end if
	
	temp = seek(fn, -1) 	
	len = where(fn)
	temp = seek(fn, 0)

	ret = repeat(0, len)	
	for i = 1 to len do
		ret[i] = getc(fn)
	end for
		
	if sequence(f) then
		close(fn)
	end if

	return ret
end function

--**
-- Write data to file named f or file handle f. Returns 1 on success, 0 on failure.
--
-- Comments:
-- If x is an atom, it is assumed to be an open file handle. If x is a sequence, it is 
-- assumed to be a filename.
--
-- When x is a file handle, the file is not closed after writing is finished. When x is a 
-- file name, it is opened, written to and then closed.
--
-- Example 1:
-- <eucode>
-- if write_file("data.txt", "This is important data\nGoodybe") = 0 then
--     puts(STDERR, "Failed to write data\n")
-- end if
-- </eucode>
--
-- See Also:
--    [[:read_file]], [[:write_lines]]

export function write_file(object f, sequence data)
	integer fn

	if sequence(f) then
		fn = open(f, "wb")
	else
		fn = f
	end if
	if fn < 0 then return -1 end if
	
	puts(fn, data)

	if sequence(f) then
		close(fn)
	end if

	return 1
end function

