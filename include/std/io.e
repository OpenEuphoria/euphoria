-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
--****
-- == I/O
--
-- <<LEVELTOC depth=2>>

include std/sort.e
include std/wildcard.e
include std/types.e
include std/memory.e

constant M_SEEK  = 19,
		 M_WHERE = 20,
		 M_FLUSH = 60,
		 M_LOCK_FILE = 61,
		 M_UNLOCK_FILE = 62

--****
-- === Constants

--**
-- Standard Input

public constant STDIN = 0

--**
-- Standard Output

public constant STDOUT = 1

--**
-- Standard Error

public constant STDERR = 2

--**
-- Screen (Standard Out)

public constant SCREEN = 1

--**
-- End of file

public constant EOF = -1


--****
-- === Read/Write Routines

--**
-- Signature:
-- <built-in> procedure ? (no parens around he unique parameter)
--
-- Description:
-- Shorthand way of saying: **pretty_print(STDOUT, x, {})** - i.e. printing the value of an 
-- expression to the standard output, with braces and indentation to show the structure.
--
-- Example 1:
-- <eucode>
-- ? {1, 2} + {3, 4}  -- will display {4, 6}
-- </eucode>
--
-- See Also:
--   [[:print]]

--**
-- Signature:
-- <built-in> procedure print(integer fn, object x)
--
-- Description:
-- Print an object to a file or device, with braces { , , , } to show the structure.
--
-- Parameters:
--		# ##fn##: an integer, the handle to a file or device to output to
-- 		# ##x##: the object to print
--
-- Errors:
-- The target fole or device must be open.
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
--
-- See Also:
-- 		[[:?]], [[:puts]]

--**
-- Signature:
-- <built-in> procedure printf(integer fn, sequence format, object values)
--
-- Description:
-- Print one or more values to a file or device, using a format string to embed them in and define how they should be represented.
--
-- Parameters:
--		# ##fn##: an integer, the handle to a file or device to output to
--		# ##format##: a sequence, the text to print. This text may contain format specifiers.
--		# ##values##: usually, a sequence of values. It should have as many elements as format specifiers in ##format##, as these values will be substituted to the specifiers.
--
-- Errors:
-- 		If there are less values to show than format specifiers, a run time error will occur.
--
-- The target fole or device must be open.
--
-- Comments:
-- A format specifier is a string of characters starting with a percent sign ( ~%~ ) and ending 
-- in a letter. Some extra information may come in the middle.
--
-- ##format## will be scanned for format specifiers. Whenever one is found, the current value 
-- in ##values## will be turned into a string according to the format specifier. The resulting 
-- string will be plugged in the result, as if replacing the modifier with the printed value.
-- Then moving on to next value and carrying the process on.
--
-- This way, printf() always takes
-- exactly 3 arguments, no matter how many values are to be printed. Only the length of the last 
-- argument, containing the values to be printed, will vary.
--
-- The basic format specifiers are...
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
-- * ##~%~%## - print the '%' character itself. This is not an actual format specifier.
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
-- If there is only one % format specifier, and if the value it stands for is an atom, then ##values## may be simply that atom.
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
--     [[:sprintf]], [[:sprint]], [[:print]]

--**
-- Signature:
-- <built-in> procedure puts(integer fn, object text)
--
-- Description:
-- Output, to a file or device, a single byte (atom) or sequence of bytes. The low order
-- 8-bits of each value is actually sent out. If outputting to the screen you will see text
-- characters displayed.
--
-- Parameters:
-- 		# ##fn##: an integer, the handle to an opened file or device
--		# ##text##: an object, either a single character or a sequence of characters.
--
-- Errors:
-- The target fole or device must be open.
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
--
-- See Also:
--   [[:print]]

--**
-- Signature:
-- <built-in> function getc(integer fn)
--
-- Description:
--     Get the next character (byte) from a file or device fn. 
--
-- Parameters:
--		# ##fn##: an integer, the handle of the file or device to read from.
--
-- Returns:
--		An **integer**, the character read from the file, in the 0..255 range. If no character is left to read, [[:EOF]] is returned instead.
--
-- Errors:
-- The target file or device must be open.
--
-- Comments:
--     File input using getc() is buffered, i.e. getc() does not actually go out to the disk 
--     for each character. Instead, a large block of characters will be read in at one time 
--     and returned to you one by one from a memory buffer.
--
--     When getc() reads from the keyboard, it will not see any characters until the user 
--     presses Enter. Note that the user can type CTRL+Z, which the operating system treats 
--     as "end of file". [[:EOF]] will be returned. 
-- See Also:
-- 		[[:gets]], [[:get_key]]

--**
-- Signature:
-- <built-in> function gets(integer fn)
--
-- Description:
--     Get the next sequence (one line, including '\n') of characters from a file or device.
-- Parameters:
--		# ##fn##: an integer, the handle of the file or device to read from.
--
-- Returns:
--		An **object**, either [[:EOF]] on end of file, or the next line of text from the file.
--
-- Errors:
-- The file or device must be open.
--
-- Comments:
--    The characters will have values from 0 to 255.
--
--	If the line had an end of line marker, a ~'\n'~ terminates the line. The last line of a file needs not have an end of line marker.
--
--     After reading a line of text from the keyboard, you should normally output a \n character, 
--     e.g.  puts(1, '\n'), before printing something. Only on the last line of the screen does the 
--     operating system automatically scroll the screen and advance to the next line.
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
--
-- See Also:
--		[[:getc]], [[:read_lines]]

--**
-- Signature:
-- <built-in> function get_key()
--
-- Description:
--     Get the next keystroke without waiting for it or echoing it on the console. 
--
-- Parameters:
--		# None.
--
-- Returns:
--		An **integer**, the code number for the key pressed. If there is no key
--      press waiting, then this returns -1.
--
-- See Also:
-- 		[[:gets]], [[:getc]]

constant CHUNK = 100

--**
-- Read the next bytes from a file.
--
-- Parameters:
--		# ##fn##: an integer, the handle to an open file to read from.
--		# ##n##: a positive integer, the number of bytes to read.
--
-- Returns:
--		A **sequence** of length at most ##n##, made of the bytes that could be read from the file.
--
-- Comments:
--     When ##n## > 0 and the function returns a sequence of length less than ##n## you know
--     you've reached the end of file. Eventually, an
--     empty sequence will be returned.
--
--     This function is normally used with files opened in binary mode, "rb".
--     This avoids the confusing situation in text mode where //DOS// or //Windows// will convert CR LF pairs to LF.
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
--
-- See Also:
-- 		[[:getc]], [[:gets]], [[:get_integer32]], [[::get_dstring]]

public function get_bytes(integer fn, integer n)
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


atom mem0, mem1, mem2, mem3
mem0 = allocate(4)
mem1 = mem0 + 1
mem2 = mem0 + 2
mem3 = mem0 + 3

--**
-- Read the next four bytes from a file and returns them as a single integer.
--
-- Parameters:
--		# ##fh##: an integer, the handle to an open file to read from.
--
-- Returns:
--		An **atom**, made of the bytes that could be read from the file.
--
-- Comments:
--     * This function is normally used with files opened in binary mode, "rb".
--     * Assumes that there at least four bytes available to be read.
--
-- Example 1:
--     <eucode>
--     
--     integer fn
--     fn = open("temp", "rb")  -- an existing file
--
--     atom file_type_code
--     file_type_code = get_integer32(fn)
--     </eucode>
--
-- See Also:
-- 		[[:getc]], [[:gets]], [[:get_bytes]], [[::get_dstring]]

public function get_integer32(integer fh)
-- read the 4 bytes as a single integer value at current position in file
	poke(mem0, getc(fh))
	poke(mem1, getc(fh))
	poke(mem2, getc(fh))
	poke(mem3, getc(fh))
	return peek4u(mem0)
end function

--**
-- Write the supplied integer as four bytes to a file.
--
-- Parameters:
--		# ##fh##: an integer, the handle to an open file to write to.
--      # ##val##: an integer 
--
-- Comments:
--     * This function is normally used with files opened in binary mode, "wb".
--
-- Example 1:
--     <eucode>
--     
--     integer fn
--     fn = open("temp", "wb")
--
--     put_integer32(fn, 1234)
--     </eucode>
--
-- See Also:
-- 		[[:getc]], [[:gets]], [[:get_bytes]], [[::get_dstring]]

public procedure put_integer32(integer fh, integer val)
	poke4(mem0, val)
	puts(fh, peek({mem0,4}))
end procedure

--**
-- Read a delimited byte string from an opened file .
--
-- Parameters:
--		# ##fh##: an integer, the handle to an open file to read from.
--      # ##delim##: an integer, the delimiter that marks the end of a byte string.
--                   If omitted, a zero is assumed.
--
-- Returns:
--		An **sequence**, made of the bytes that could be read from the file.
--
-- Comments:
--     * If the end-of-file is found before the delimiter, the delimiter is appended
--       to the returned string.
--
-- Example 1:
--     <eucode>
--     
--     integer fn
--     fn = open("temp", "rb")  -- an existing file
--
--     sequence text
--     text = get_dstring(fn)	-- Get a zero-delimited string
--     text = get_dstring(fn, '$')	-- Get a '$'-delimited string
--     </eucode>
--
-- See Also:
-- 		[[:getc]], [[:gets]], [[:get_bytes]], [[::get_integer32]]

public function get_dstring(integer fh, integer delim = 0)
	sequence s
	integer c
	integer i

	s = repeat(-1, 256)
	i = 0
	while c != delim entry do
		i += 1
		if i > length(s) then
			s &= repeat(-1, 256)
		end if
		
		if c = -1 then
			exit
		end if
		s[i] = c
	  entry
		c = getc(fh)
	end while
	
	return s[1..i]
end function

--****
-- === Low Level File/Device Handling

--
-- Described under lock_file()
--


--**
-- Lock Type Constants

public enum LOCK_SHARED, LOCK_EXCLUSIVE

--**
-- File number type

public type file_number(integer f)
	return f >= 0
end type

--**
-- File position type

public type file_position(atom p)
	return p >= -1
end type

		 
--**
-- Lock Type

public type lock_type(integer t)
	return t = LOCK_SHARED or t = LOCK_EXCLUSIVE
end type

--**
-- Byte Range Type

public type byte_range(sequence r)
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
-- <built-in> function open(sequence path, sequence mode)
--
-- Description:
-- Open a file or device, to get the file number. 
--
-- Parameters:
--		# ##path##: a string, the path to the file or device to open.
-- 		# ##mode##: a string, the mode being used o open the file.
--
-- Returns:
-- 		A small **integer**, -1 on failure, else 0 or more.
--
-- Errors:
--	There is a limit on the number of files that can be simultaneously opened, currently 40. 
-- If this limit is reached, the next attempt to ##open##() a file will error out.
--
-- The length of ##path## should not exceed 1,024 characters.
--
-- Comments:
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
-- On //DOS// or //Windows//, output to text files will have carriage-return characters automatically
-- added before linefeed characters. On input, these carriage-return characters are removed. 
-- A control-Z character (ASCII 26) will signal an immediate end of file. Note: on some 
-- versions of DOS, a control-Z typed by the user might cause standard input to permanently 
-- appear to be at the end-of-file, until the DOS window is closed.
--
-- I/O to binary files is not modified in any way. Any byte values from 0 to 255 can be 
-- read or written. On //Unix//, all files are binary files, so "r" mode and "rb"
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
-- Close a file or device when done with it, flushing out any still-buffered characters prior.
--
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
-- <built-in> procedure close(atom fn)
--
-- Description:
-- Close a file or device and flush out any still-buffered characters.
--
-- Parameters:
-- 		# ##fn##: an integer, the handle to the file or device to query.
--
-- Errors:
-- The target file or device must be open.
--
-- Comments:
-- Any still-open files will be closed automatically when your program terminates.

--**
-- Seek (move) to any byte position in a file.
--
-- Parameters:
--		# ##fn##: an integer, the handle to the file or device to seek()
--		# ##pos##: an atom, either an absolute 0-based position or -1 to seek to end of file.
--
-- Returns:
--		An **integer**, 0 on success, 1 on failure. 
--
-- Errors:
-- The target file or device must be open.
--
-- Comments:
-- For each open file, there is a current byte position that is updated as a result of I/O
-- operations on the file. The initial file position is 0 for files opened for read, write 
-- or update. The initial position is the end of file for files opened for append.
-- It is possible to seek past the end of a file. If you seek past the end of the file, and
-- write some data, undefined bytes will be inserted into the gap between the original end 
-- of file and your new data.
--
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
-- include std/io.e
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
--
-- See Also:
--		[[:get_bytes]], [[:puts]], [[:where]]

public function seek(file_number fn, file_position pos)
	return machine_func(M_SEEK, {fn, pos})
end function

--**
-- Retrieves the current file position for an opened file or device.
-- 
-- Parameters:
-- 		# ##fn##: an integer, the handle to the file or device to query.
--
--
-- Returns:
--		An **atom**, the current byte position in the file.
--
-- Errors:
-- The target file or device must be open.
--
--
-- Comments:
-- The file position is is the place in the file where the next byte
-- will be read from, or written to. It is updated
-- by reads, writes and seeks on the file. 

public function where(file_number fn)
	return machine_func(M_WHERE, fn)
end function

--**
-- Force writing any buffered data to an open file or device.
--
-- Parameters:
-- 		# ##fn##: an integer, the handle to the file or device to close.
--
-- Errors:
-- The target file or device must be open.
--
-- Comments:
-- When you write data to a file, Euphoria normally stores the data
-- in a memory buffer until a large enough chunk of data has accumulated.
-- This large chunk can then be written to disk very efficiently. 
-- Sometimes you may want to force, or flush, all data out immediately, 
-- even if the memory buffer is not full. To do this you must call flush(fn),
-- where fn is the file number of a file open for writing or appending.
--
-- When a file is closed, (see close()), all buffered data is flushed out. 
--  When a program terminates, all open files are flushed and closed 
--  automatically. Use flush() when another process may need to
--  see all of the data written so far, but you are not ready
--   to close the file yet. flush() is also used in crash routines, where files may not be closed in the cleanest possible way.
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
--
-- See Also:
--		[[:close]], [[:crash_routine]]

public procedure flush(file_number fn)
	machine_proc(M_FLUSH, fn)
end procedure

--**
-- When multiple processes can simultaneously access a
-- file, some kind of locking mechanism may be needed to avoid mangling
-- the contents of the file, or causing erroneous data to be read from the file.
--
-- Parameters:
--		# ##fn##: an integer, the handle to the file or device to (partially) lock.
--		# ##t##: an integer which defines the kind of lock to apply.
--		# ##r##: a sequence, defining a section of the file to be locked, or {} for the whole file (the default).
--
-- Returns:
--		An **integer**, 0 on failure, 1 on success.
--
-- Errors:
-- The target file or device must be open.
--
-- Comments:
-- ##lock_file()## attempts to place a lock on an open file, ##fn##, to stop
-- other processes from using the file while your program is reading it
-- or writing it.
--
-- Under //Unix//, there are two types of locks that
-- you can request using the ##t## parameter. (Under //DOS32// and //WIN32// the
-- parameter ##t## is ignored, but should be an integer.)
-- Ask for a **shared** lock when you intend to read a file, and you want to 
-- temporarily block other processes from writing it. Ask for an 
-- **exclusive** lock when you intend to write to a file and you want to temporarily 
-- block other processes from reading or writing it. It's ok for many processes to 
-- simultaneously have shared locks on the same file, but only one process 
-- can have an exclusive lock, and that can happen only when no other 
-- process has any kind of lock on the file. io.e contains the following declarations:
-- 
-- <eucode>
-- public enum
--     LOCK_SHARED, 
--     LOCK_EXCLUSIVE
-- </eucode>
--
-- On //DOS32// and //WIN32// you can lock a specified portion of a file using the ##r##  parameter.
-- ##r## is a sequence of the form: ##{first_byte, last_byte}##. It indicates the first byte and
-- last byte in the file,  that the lock applies to. Specify the empty sequence ##{}##, 
-- if you want to lock the whole file, or don't specify it at all, as this is the default. In the current release for //Unix//, locks
-- always apply to the whole file, and you should use this default value.
--
-- ##lock_file()## does not wait
-- for other processes to relinquish their locks. You may have to call it repeatedly, 
-- before the lock request is granted.
--
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
-- include std/io.e
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
--
-- See Also:
--		[[:unlock_file]]

public function lock_file(file_number fn, lock_type t, byte_range r={})
	return machine_func(M_LOCK_FILE, {fn, t, r})
end function

--**
-- Unlock (a portion of) an open file.
--
-- Parameters:
--		# ##fn##: an integer, the handle to the file or device to (partially) lock.
--		# ##r##: a sequence, defining a section of the file to be locked, or {} for the whole file (the default).
--
-- Errors:
-- The target file or device must be open.
--
-- Comments:
-- You must have previously locked the
-- file using ##lock_file##(). On //DOS32// and //WIN32// you can unlock a range of bytes within a
-- file by specifying the ##r## as {first_byte, last_byte}. The same range of bytes
-- must have been locked by a previous call to [[:lock_file]](). On //Unix// you can
-- currently only lock or unlock an entire file. ##r## should be {} when you
-- want to unlock an entire file. On //Unix//, ##r## must always be {}, which is the default.
--
--  You should unlock a file as soon as possible so other processes can use it.
--
-- 	Any files that you have locked, will automatically be unlocked when your program 
--  terminates.
--
-- See Also:
-- 		[[:lock_file]]

public procedure unlock_file(file_number fn, byte_range r={})
-- The byte range can be {} if you want to unlock the whole file.
	machine_proc(M_UNLOCK_FILE, {fn, r})
end procedure

--****
-- === File Reading/Writing

--**
-- Read the contents of a file as a sequence of lines.
--
-- Parameters:
--		##file##: an object, either a file path or the handle to an open file.
--
-- Returns:
--		A **sequence** made of lines from the file, as [[:gets]] could read them.
--
-- Comments:
--	If ##file## was a sequence, the file will be closed on completion. Otherwise, it will remain open, but at end of file.
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
--
-- See Also:
--		[[:gets]], [[:write_lines]], [[:read_file]]

public function read_lines(object file)
	object fn, ret, y
	if sequence(file) then
			fn = open(file, "r")
	else
			fn = file
	end if
	if fn < 0 then return -1 end if
	
	ret = {}
	while sequence(y) entry do
		if y[$] = '\n' then
			y = y[1..$-1]
ifdef UNIX then
			if length(y) then
				if y[$] = '\r' then
					y = y[1..$-1]
				end if
			end if
end ifdef
		end if
		ret = append(ret, y)
	entry
		y = gets(fn)
	end while
	
	if sequence(file) then
			close(fn)
	end if
	return ret
end function

--**
-- Write a sequence of lines to a file.
--
-- Parameters:
--		# ##file##: an object, either a file path or the handle to an open file.
--		# ##lines##: the sequence of lines to write
--
-- Returns:
--     An **integer**: 1 on success, -1 on failure.
--
-- Errors:
--		If [[:puts]] cannot write some line of text, a runtime error will occur.
--
-- Comments:
--	If ##file## was a sequence, the file will be closed on completion. Otherwise, it will remain open, but at end of file.
--
-- Whatever integer the lines in ##lines## holds will be truncated to its 8 lowest bits so as to fall in the 0.255 range.
--
-- Example 1:
-- <eucode>
-- if write_lines("data.txt", {"This is important data", "Goodbye"}) != -1 then
--     puts(STDERR, "Failed to write data\n")
-- end if
-- </eucode>
--
-- See Also:
--     [[:read_lines]], [[:write_file]], [[:puts]]

public function write_lines(object file, sequence lines)
	object fn

	if sequence(file) then
    	fn = open(file, "w")
	else
		fn = file
	end if
	if fn < 0 then return -1 end if

	for i = 1 to length(lines) do
		puts(fn, lines[i])
		puts(fn, '\n')
	end for

	if sequence(file) then
		close(fn)
	end if

	return 1
end function

--**
-- Append a sequence of lines to a file.
--
-- Parameters:
--		# ##file##: an object, either a file path or the handle to an open file.
--		# ##lines##: the sequence of lines to write
--
-- Returns:
--     An **integer**: 1 on success, -1 on failure.
--
-- Errors:
--		If [[:puts]] cannot write some line of text, a runtime error will occur.
--
-- Comments:
-- ##file## is opened, written to and then closed.
--
-- Example 1:
-- <eucode>
-- if append_lines("data.txt", {"This is important data", "Goodbye"}) != -1 then
--     puts(STDERR, "Failed to append data\n")
-- end if
-- </eucode>
--
-- See Also:
--     [[:write_lines]], [[:puts]]

public function append_lines(sequence file, sequence lines)
	object fn

  	fn = open(file, "a")
	if fn < 0 then return -1 end if

	for i = 1 to length(lines) do
		puts(fn, lines[i])
		puts(fn, '\n')
	end for

	close(fn)

	return 1
end function

--**
-- Read the contents of a file as a single sequence of bytes.
--
-- Parameters:
--		# ##file#: an object, either a file path or the handle to an open file.
--
-- Returns:
--		A **sequence** holding all the bytes in the file.
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

public function read_file(object file)
	integer fn
	integer len
	sequence ret
	integer temp

	if sequence(file) then
		fn = open(file, "rb")
	else
		fn = file
	end if
	if fn < 0 then return -1 end if
	
	temp = seek(fn, -1) 	
	len = where(fn)
	temp = seek(fn, 0)

	ret = repeat(0, len)	
	for i = 1 to len do
		ret[i] = getc(fn)
	end for
		
	if sequence(file) then
		close(fn)
	end if

	return ret
end function

--**
-- Write a sequence of bytes to a file.
--
-- Parameters:
--		# ##file##: an object, either a file path or the handle to an open file.
--		# ##data##: the sequence of bytes to write
--
-- Returns:
--     An **integer**: 1 on success, -1 on failure.
--
-- Errors:
--		If [[:puts]] cannot write ##data##, a runtime error will occur.
--
-- Comments:
-- When ##file## is a file handle, the file is not closed after writing is finished. When ##file## is a
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

public function write_file(object f, sequence data)
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
