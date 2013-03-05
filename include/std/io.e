--****
-- == I/O
--
-- <<LEVELTOC level=2 depth=4>>

namespace io

include std/error.e
include std/machine.e
include std/text.e
include std/search.e
include std/types.e

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

public constant EOF = (-1)

--****
-- === Read and Write Routines

--****
-- @[q_print|]
-- Signature:
-- <built-in> procedure ##?## 
--
-- Description:
-- displays an object using numbers and braces.
--
-- Note:
-- There are no parenthesis delimiting the single argument to this procedure.
-- This is a unique shortcut in Euphoria syntax.
--
-- Comments:
-- This is a shorthand way of writing ##pretty_print(STDOUT, x, {})##. An object or an expression is printed 
-- to the standard output with braces and indentation to show the structure.
--
-- Example 1:
-- <eucode>
-- ? {1, 2} + {3, 4}  -- will display {4, 6}
-- </eucode>
--
-- See Also:
--   [[:print]]

--****
-- Signature:
-- <built-in> procedure print(integer fn, object x)
--
-- Description:
-- displays an object using numbers and braces.
--
-- Comments:
-- All data objects are in //binary// format within computer hardware; something that is easy to forget. An output
-- routine must convert these binary values into "text" to be human readable.
-- The procedures ##print## and ##?## produce a "text" representation of an object that is output to a file or device.
-- The text shows the __numerical form__ of the object.
-- If the object ##x## is a sequence it uses braces **##{ , , , }##** to
-- show the structure.
--
-- Parameters:
--		# ##fn## : an integer, the handle to a file or device to output to
-- 		# ##x## : the object to print
--
-- Errors:
-- The target file or device must be open and able to be written to.
--
-- Comments:
-- This is not used to write to "binary" files as it only outputs text.
--
-- Example 1:
-- <eucode>
-- include std/io.e
-- print(STDOUT, "ABC")   -- output is:  "{65,66,67}"
-- puts (STDOUT, "ABC")    -- output is:  "ABC"
-- print(STDOUT, "65")    -- output is:  "65"
-- puts (STDOUT, 65)       -- output is:  "A"  (ASCII-65 ==> 'A')
-- print(STDOUT, 65.1234) -- output is:  "65.1234"
-- puts (STDOUT, 65.1234)  -- output is:  "A" (Converts to integer first)
-- </eucode>
--
-- Example 2:
-- <eucode>
-- include std/io.e
-- print(STDOUT, repeat({10,20}, 3)) -- output is: {{10,20},{10,20},{10,20}}
-- </eucode>
--
-- See Also:
-- 		[[:q_print|?]], [[:puts]]

--****
-- Signature:
-- <built-in> procedure printf(integer fn, sequence format, object values)
--
-- Description:
-- prints one or more values to a file or device, using a format string to embed them in and define how they should be represented.
--
-- Parameters:
--		# ##fn## : an integer, the handle to a file or device to output to
--		# ##format## : a sequence, the text to print. This text may contain format specifiers.
--		# ##values## : usually, a sequence of values. It should have as many elements as format specifiers in ##format##, as these values will be substituted to the specifiers.
--
-- Errors:
-- 		If there are less values to show than format specifiers, a run time error will occur.
--
-- The target file or device must be open.
--
-- Comments:
-- A **format specifier** is a string of characters starting with a percent sign ( ~%~ ) and ending
-- in a letter. Some extra information may come in between those.
--
-- This procedure writes out the ##format## text to the output file ##fn##, 
-- replacing format specifiers with the corresponding data from the ##values##
-- parameter. Whenever a format specifiers is found in ##format##, the n-th item
-- in ##values## will be turned into a string according to the format specifier. The resulting
-- string will the format specifier. This means that the first format specifier uses the
-- first item in ##values##, the second format specifier the second item, and so on.
--
-- You must have at least as many items in ##values## as there are format specifiers
-- in ##format##. This means that if there is only one format specifier then ##values##
-- can be either an atom, integer or a non-empty sequence. And when there are more
-- than one format specifier in ##format## then ##values## must be a sequence with 
-- a length that is greater than or equal to the number of format specifiers present.
--
-- This way, ##printf## always takes exactly three arguments no matter how many
-- values are to be printed.
--
-- The basic format specifiers are~:
--
-- * ##%d## ~-- print an atom as a decimal integer
-- * ##%x## ~-- print an atom as a hexadecimal integer. Negative numbers are printed
--            in two's complement, so -1 will print as ##FFFFFFFF##
-- * ##%o## ~-- print an atom as an octal integer
-- * ##%s## ~-- print a sequence as a string of characters, or print an atom as a single
--            character
-- * ##%e## ~-- print an atom as a floating-point number with exponential notation
-- * ##%f## ~-- print an atom as a floating-point number with a decimal point but no exponent
-- * ##%g## ~-- print an atom as a floating-point number using whichever format seems
--            appropriate, given the magnitude of the number
-- * ##~%~%## ~-- print the ##'%'## character itself. This is not an actual format specifier.
--
-- Field widths can be added to the basic formats (for example: ## %5d, %8.2f, %10.4s##). The number
-- before the decimal point is the minimum field width to be used. The number after
-- the decimal point is the precision to be used for numeric values.
--
-- If the field width is negative (for example ##%-5d##) then the value will be left-justified
-- within the field. Normally it will be right-justified, even strings. If the field width
-- starts with a leading 0 (for example ##%08d##) then leading zeros will be supplied to fill up
-- the field. If the field width starts with a ##'+'## (for example ##%+7d## ) then a plus sign will
-- be printed for positive values.
--
-- Comments:
-- Watch out for the following common mistake. The intention is to
-- output all the characters in the third argument but actually only 
-- outputs the first character~:
--
-- <eucode>
-- include std/io.e
-- sequence name="John Smith"
-- printf(STDOUT, "My name is %s", name)
--    --> My name is J
-- </eucode>
--
-- The output of this will be //##My name is J##// because each format specifier
-- uses exactly //one// item from the ##values## parameter. In this case we have
-- only one specifier so it uses the first item in the ##values## parameter, which
-- is the character ##'J'##. To fix this situation, you must ensure that the first
-- item in the ##values## parameter is the entire text string and not just a
--  character, so you need code this instead~:
--
-- <eucode>
-- include std/io.e
-- name="John Smith"
-- printf(STDOUT, "My name is %s", {name})
--    --> My name is John Smith
-- </eucode>
--
-- Now, the third argument of ##printf## is a one-element sequence containing all
-- the text to be formatted.
--
-- Also note that if there is only one format specifier then ##values## can 
-- simply be an atom or integer.
--
-- Example 1:
-- <eucode>
-- include std/io.e
-- atom rate = 7.875
-- printf(STDOUT, "The interest rate is: %8.2f\n", rate)
--
-- --      The interest rate is:     7.88
-- </eucode>
--
-- Example 2:
-- <eucode>
-- include std/io.e
-- sequence name="John Smith"
-- integer score=97
-- printf(STDOUT, "%15s, %5d\n", {name, score})
--
-- -- "     John Smith,    97"
-- </eucode>
--
-- Example 3:
-- <eucode>
-- include std/io.e
-- printf(STDOUT, "%-10.4s $ %s", {"ABCDEFGHIJKLMNOP", "XXX"})
-- --      ABCD       $ XXX
-- </eucode>
--
-- Example 4:
-- <eucode>
-- include std/io.e
-- printf(STDOUT, "%d  %e  %f  %g", repeat(7.75, 4)) 
--                   -- same value in different formats
--
-- --      7  7.750000e+000  7.750000  7.75
-- </eucode>
--
-- **//NOTE//** that ##printf## cannot use an item in ##values## that contains
-- nested sequences. Thus this is an error ...
-- <eucode>
-- include std/io.e
-- sequence name = {"John", "Smith"}
-- printf(STDOUT, "%s", {name} )
-- </eucode>
-- because the item that is used from the ##values## parameter contains two
-- subsequences (strings in this case). To get the correct output you would
-- need to do this instead ...
--
-- <eucode>
-- include std/io.e
-- sequence name = {"John", "Smith"}
-- printf(STDOUT, "%s %s", {name[1], name[2]} )
-- </eucode>
--
-- See Also:
--     [[:sprintf]], [[:sprint]], [[:print]]

--****
-- Signature:
-- <built-in> procedure puts(integer fn, object text)
--
-- Description:
-- outputs text characters to a screen or file.
--
-- Parameters:
-- 		# ##fn## : an integer, the handle to an opened file or device
--		# ##text## : an object, either a single character or a sequence of characters.
--
-- Errors:
-- The target file or device must be open.
--
-- Comments:
-- This procedures outputs, to a file or device, a single byte (atom) or sequence of bytes. The low order
-- 8-bits of each value is actually sent out. If outputting to the screen you will see text
-- characters displayed.
--
-- When you output a sequence of bytes it must not have any sub-sequences within it. It
-- must be a sequence of atoms only. (Typically a string of ASCII codes).
--
-- Avoid outputting 0's to the screen or to standard output. Your output might get truncated.
--
-- Remember that if the output file was opened in text mode, //Windows// will change ##\n## (10) 
-- to ##\r\n## ##(13 10)##. Open the file in binary mode if this is not what you want.
--
-- Example 1:
-- <eucode>
-- include std/io.e
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

--****
-- Signature:
-- <built-in> function getc(integer fn)
--
-- Description:
--     gets the next character (byte) from a file or device ##fn##.
--
-- Parameters:
--		# ##fn## : an integer, the handle of the file or device to read from.
--
-- Returns:
--		An **integer**, the character read from the file, in the 0..255 range. 
-- If no character is left to read, [[:EOF]] is returned instead.
--
-- Errors:
-- The target file or device must be open.
--
-- Comments:
--     File input using ##getc## is buffered, that means ##getc## does not actually go out to the disk
--     for each character. Instead, a large block of characters will be read in at one time
--     and returned to you one by one from a memory buffer.
--
--     When ##getc## reads from the keyboard, it will not see any characters until the user
--     presses Enter. Note that the user can type Control+Z, which the operating system treats
--     as "end of file" returning [[:EOF]].
--
-- See Also:
-- 		[[:gets]], [[:get_key]]

--****
-- Signature:
-- <built-in> function gets(integer fn)
--
-- Description:
-- gets a sequence of characters.
--
-- Parameters:
--		# ##fn## : an integer, the handle of the file or device to read from.
--
-- Returns:
--		An **object**, either [[:EOF]] on end of file, or the next line of text from the file.
--
-- Errors:
-- The file or device must be open.
--
-- Comments:
--    This function gets the next sequence (one line, including ##'\n'##) of characters from a file or device.
--    The characters will have values from 0 to 255.
--
--	If the line had an end of line marker, a ##~'\n'~## terminates the line. The last line of a file needs not have an end of line marker.
--
--     After reading a line of text from the keyboard, you should normally output a ##\n## character,
--     (for example  ##puts(1, '\n')## ), before printing something. Only on the last line of the screen does the
--     operating system automatically scroll the screen and advance to the next line.
--
--     When your program reads from the keyboard, the user can type Control+Z, which the operating
--     system treats as "end of file". [[:EOF]] will be returned.
--
-- Example 1:
-- <eucode>
-- sequence buffer
-- object line
-- integer fn
--
-- -- read a text file into a sequence
-- fn = open("my_file.txt", "r")
-- if fn = -1 then
--     puts(1, "Couldn't open my_file.txt\n")
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
-- line = line[1..$-1] -- get rid of \n character at end
-- puts(1, '\n')   -- necessary
-- puts(1, line & " is a nice name.\n")
-- </eucode>
--
-- See Also:
--		[[:getc]], [[:read_lines]]

constant CHUNK = 100

--**
-- reads the next bytes from a file.
--
-- Parameters:
--		# ##fn## : an integer, the handle to an open file to read from.
--		# ##n## : a positive integer, the number of bytes to read.
--
-- Returns:
--		A **sequence**, of length at most ##n##, made of the bytes that could be read from the file.
--
-- Comments:
--   When ##n## ##> 0## and the function returns a sequence of length less than ##n## you know
--  you have reached the end of file. Eventually, an
--  empty sequence will be returned.
--
--  This function is normally used with files opened in binary mode, ##"rb"##.
--  This avoids the confusing situation in text mode where //Windows// will convert CR LF 
--  pairs to LF.
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
-- 		[[:getc]], [[:gets]], [[:get_integer32]], [[:get_dstring]]

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
mem0 = machine:allocate(4)
mem1 = mem0 + 1
mem2 = mem0 + 2
mem3 = mem0 + 3

--**
-- reads the next four bytes from a file and returns them as a single integer.
--
-- Parameters:
--		# ##fh## : an integer, the handle to an open file to read from.
--
-- Returns:
--		An **atom**, between ##-1## and ##power(2,32)-1##, made of the bytes that could be read from the file.
--      When an end of file is encountered, it returns ##-1##.
--
-- Comments:
--     * This function is normally used with files opened in binary mode, ##"rb"##.
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
-- 		[[:getc]], [[:gets]], [[:get_bytes]], [[:get_dstring]]

public function get_integer32(integer fh)
-- read the 4 bytes as a single integer value at current position in file
	integer c -- a positive byte integer, 0 or -1
	c = getc(fh)
	poke(mem0, c)
	c = getc(fh)
	poke(mem1, c)
	c = getc(fh)
	poke(mem2, c)
	c = getc(fh)
	if c = -1 then
		return -1
	end if
	poke(mem3, c)
	return peek4u(mem0)
end function

--**
-- reads the next two bytes from a file and returns them as a single integer.
--
-- Parameters:
--		# ##fh## : an integer, the handle to an open file to read from.
--
-- Returns:
--		An **integer**, made of the bytes that could be read from the file.
--      When an end of file is encountered, it returns ##-1##.
--
-- Comments:
--     * This function is normally used with files opened in binary mode, ##"rb"##.
--
-- Example 1:
--     <eucode>
--
--     integer fn
--     fn = open("temp", "rb")  -- an existing file
--
--     atom file_type_code
--     file_type_code = get_integer16(fn)
--     </eucode>
--
-- See Also:
-- 		[[:getc]], [[:gets]], [[:get_bytes]], [[:get_dstring]]

public function get_integer16(integer fh)
-- read the 2 bytes as a single integer value at current position in file
	integer c -- a positive byte integer from 0 to 255 or -1
	c = getc(fh)
	poke(mem0, c)
	c = getc(fh)
	if c = -1 then
		return -1
	end if
	poke(mem1, c)
	return peek2u(mem0)
end function

--**
-- writes the supplied integer as four bytes to a file.
--
-- Parameters:
--		# ##fh## : an integer, the handle to an open file to write to.
--      # ##val## : an integer
--
-- Comments:
--     * This function is normally used with files opened in binary mode, ##"wb"##.
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
-- 		[[:getc]], [[:gets]], [[:get_bytes]], [[:get_dstring]]

public procedure put_integer32(integer fh, atom val)
	poke4(mem0, val)
	puts(fh, peek({mem0,4}))
end procedure

--**
-- writes the supplied integer as two bytes to a file.
--
-- Parameters:
--		# ##fh## : an integer, the handle to an open file to write to.
--      # ##val## : an integer
--
-- Comments:
--     * This function is normally used with files opened in binary mode, ##"wb"##.
--
-- Example 1:
--     <eucode>
--
--     integer fn
--     fn = open("temp", "wb")
--
--     put_integer16(fn, 1234)
--     </eucode>
--
-- See Also:
-- 		[[:getc]], [[:gets]], [[:get_bytes]], [[:get_dstring]]

public procedure put_integer16(integer fh, atom val)
	poke2(mem0, val)
	puts(fh, peek({mem0,2}))
end procedure

--**
-- read a delimited byte string from an opened file.
--
-- Parameters:
--		# ##fh## : an integer, the handle to an open file to read from.
--      # ##delim## : an integer, the delimiter that marks the end of a byte string.
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
-- 		[[:getc]], [[:gets]], [[:get_bytes]], [[:get_integer32]]

public function get_dstring(integer fh, integer delim = 0)
	sequence s
	integer c
	integer i

	s = repeat(-1, 256)
	i = 0
	while c != delim with entry do
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
-- === Low Level File and Device Handling

--
-- Described under lock_file()
--

public enum LOCK_SHARED, LOCK_EXCLUSIVE

--**
-- File number type

public type file_number(object f)
	if integer(f) and f >= 0 then
		return 1
	else
		return 0
	end if
end type

--**
-- File position type

public type file_position(object p)
	if atom(p) and p >= -1 then
		return 1
	else
		return 0
	end if
end type


--**
-- Lock Type

public type lock_type(object t)
	if integer(t) and (t = LOCK_SHARED or t = LOCK_EXCLUSIVE) then
		return 1
	else
		return 0
	end if
end type

--**
-- Byte Range Type

public type byte_range(object r)
	if atom(r) then
		return 0
	end if
	if length(r) = 0 then
		return 1
	end if
	if length(r) != 2 then
		return 0
	end if
	
	if not (atom(r[1]) and atom(r[2])) then
		return 0
	end if
	
	if r[1] < 0 or r[2] < 0 then
		return 0
	end if
	
	return r[1] <= r[2]

end type

--****
-- Signature:
-- <built-in> function open(sequence path, sequence mode, integer cleanup = 0)
--
-- Description:
-- opens a file or device, to get the file number.
--
-- Parameters:
--		# ##path## : a string, the path to the file or device to open.
-- 		# ##mode## : a string, the mode being used o open the file.
--		# ##cleanup## : an integer, if 0, then the file must be manually closed by the
-- coder.  If 1, then the file will be closed when either the file handle's references
-- goes to 0, or if called as a parameter to ##delete##.
--
-- Returns:
-- 		A small **integer**, -1 on failure, else 0 or more.
--
-- Errors:
--	There is a limit on the number of files that can be simultaneously opened, currently 40.
-- After this limit is reached the next call to ##open## will produce an error.
--
-- The length of ##path## should not exceed 1_024 characters.
--
-- Comments:
-- Possible modes are~:
--
-- * ##"r"## ~-- open text file for reading
-- * ##"rb"## ~-- open binary file for reading
-- * ##"w"## ~-- create text file for writing
-- * ##"wb"## ~-- create binary file for writing
-- * ##"u"## ~-- open text file for update (reading and writing)
-- * ##"ub"## ~-- open binary file for update
-- * ##"a"## ~-- open text file for appending
-- * ##"ab"## ~-- open binary file for appending
--
-- Files opened for read or update must already exist. Files opened for write or append will
-- be created if necessary. A file opened for write will be set to 0 bytes. Output to a
-- file opened for append will start at the end of file.
--
-- On //Windows//, output to text files will have carriage-return characters automatically
-- added before linefeed characters. On input, these carriage-return characters are removed.
-- A Control+Z character (ASCII 26) will signal an immediate end of file.
--
-- I/O to binary files is not modified in any way. Any byte values from 0 to 255 can be
-- read or written. On //Unix//, all files are binary files, so ##"r"## mode and ##"rb"##
-- mode are equivalent, as are ##"w"## and ##"wb"##, ##"u"## and ##"ub"##, and ##"a"## and ##"ab"##.
--
-- Some typical devices that you can open on //Windows// are~:
--
-- * ##"CON"## ~-- the console (screen)
-- * ##"AUX"## ~-- the serial auxiliary port
-- * ##"COM1"## ~-- serial port 1
-- * ##"COM2"## ~-- serial port 2
-- * ##"PRN"## ~-- the printer on the parallel port
-- * ##"NUL"## ~-- a non-existent device that accepts and discards output
--
-- Close a file or device when done with it, flushing out any still-buffered characters prior.
--
-- //Windows// and //Unix//: Long filenames are fully supported for reading and writing and
-- creating.
--
-- //Windows//: Be careful not to use the special device names in a file name, even if you add an
-- extension. For example: ##CON.TXT##, ##CON.DAT##, ##CON.JPG## all refer to the ##CON## device and
-- //not// to a file.
--
-- Example 1:
-- <eucode>
-- integer file_num, file_num95
-- sequence first_line
-- constant ERROR = 2
--
-- file_num = open("my_file", "r")
-- if file_num = -1 then
--     puts(ERROR, "couldn't open my_file\n")
-- else
--     first_line = gets(file_num)
-- end if
--
-- file_num = open("PRN", "w") -- open printer for output
--
-- -- on Windows 95:
-- file_num95 = open("big_directory_name\\very_long_file_name.abcdefg",
--                   "r")
-- if file_num95 != -1 then
--     puts(STDOUT, "it worked!\n")
-- end if
-- </eucode>

--****
-- Signature:
-- <built-in> procedure close(atom fn)
--
-- Description:
-- closes a file or device and flushes out any still-buffered characters.
--
-- Parameters:
-- 		# ##fn## : an integer, the handle to the file or device to query.
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
--		# ##fn## : an integer, the handle to the file or device to ##seek##
--		# ##pos## : an atom, either an absolute 0-based position or -1 to seek to end of file.
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
-- After seeking and reading (writing) a series of bytes, you may need to call ##seek##
-- explicitly before you switch to writing (reading) bytes, even though the file position
-- should already be what you want.
--
-- This function is normally used with files opened in binary mode. In text mode, //Windows//
-- converts CR LF to LF on input, and LF to CR LF on output, which can cause great confusion
-- when you are trying to count bytes because ##seek## counts the //Windows// end of line sequences
-- as two bytes, even if the file has been opened in text mode.
--
-- Example 1:
-- <eucode>
-- include std/io.e
--
-- integer fn
-- fn = open("my.data", "rb")
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
-- retrieves the current file position for an opened file or device.
--
-- Parameters:
-- 		# ##fn## : an integer, the handle to the file or device to query.
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
-- The file position is is the place in the file where the next byte will be read from, or 
-- written to. It is updated by reads, writes and seeks on the file. This procedure always 
-- counts //Windows// end of line sequences (CR LF) as two bytes even when the file number has 
-- been opened in text mode.
--

public function where(file_number fn)
	return machine_func(M_WHERE, fn)
end function

--**
-- forces writing any buffered data to an open file or device.
--
-- Parameters:
-- 		# ##fn## : an integer, the handle to the file or device to close.
--
-- Errors:
-- The target file or device must be open.
--
-- Comments:
-- When you write data to a file, Euphoria normally stores the data
-- in a memory buffer until a large enough chunk of data has accumulated.
-- This large chunk can then be written to disk very efficiently.
-- Sometimes you may want to force, or flush, all data out immediately,
-- even if the memory buffer is not full. To do this you must call ##flush(fn)##,
-- where fn is the file number of a file open for writing or appending.
--
-- When a file is closed, (see ##[[:close]]##), all buffered data is flushed out.
--  When a program terminates, all open files are flushed and closed
--  automatically. Use ##flush## when another process may need to
--  see all of the data written so far, but you are not ready
--   to close the file yet. ##flush## is also used in crash routines, where files may not be closed in the cleanest possible way.
--
-- Example 1:
-- <eucode>
-- f = open("file.log", "w")
-- puts(f, "Record#1\n")
-- puts(STDOUT, "Press Enter when ready\n")
--
-- flush(f)  -- This forces "Record #1" into "file.log" on disk.
--           -- Without this, "file.log" will appear to have
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
-- locks a file so access is restricted.
--
-- Parameters:
--		# ##fn## : an integer, the handle to the file or device to (partially) lock.
--		# ##t## : an integer which defines the kind of lock to apply.
--		# ##r## : a sequence, defining a section of the file to be locked, or ##{}## for the whole file (the default).
--
-- Returns:
--		An **integer**, 0 on failure, 1 on success.
--
-- Errors:
-- The target file or device must be open.
--
-- Comments:
-- When multiple processes can simultaneously access a
-- file, some kind of locking mechanism may be needed to avoid mangling
-- the contents of the file, or causing erroneous data to be read from the file.
--
-- ##lock_file## attempts to place a lock on an open file, ##fn##, to stop
-- other processes from using the file while your program is reading it
-- or writing it.
--
-- There are two types of locks that
-- you can request using the ##t## parameter.
-- Ask for a **shared** lock when you intend to read a file, and you want to
-- temporarily block other processes from writing it. Ask for an
-- **exclusive** lock when you intend to write to a file and you want to temporarily
-- block other processes from reading or writing it. It is ok for many processes to
-- simultaneously have shared locks on the same file, but only one process
-- can have an exclusive lock, and that can happen only when no other
-- process has any kind of lock on the file. ##io.e## contains the following declarations:
--
-- <eucode>
-- public enum
--     LOCK_SHARED,
--     LOCK_EXCLUSIVE
-- </eucode>
--
-- On ///Windows// you can lock a specified portion of a file using the ##r##  parameter.
-- ##r## is a sequence of the form: ##{first_byte, last_byte}##. It indicates the first byte and
-- last byte in the file,  that the lock applies to. Specify the empty sequence ##{}##,
-- if you want to lock the whole file, or don't specify it at all, as this is the default. In the current release for //Unix//, locks
-- always apply to the whole file, and you should use this default value.
--
-- ##lock_file## does not wait
-- for other processes to relinquish their locks. You may have to call it repeatedly,
-- before the lock request is granted.
--
-- On //Unix//, these locks are called advisory locks, which means they are not enforced
-- by the operating system. It is up to the processes that use a particular file to cooperate
-- with each other. A process can access a file without first obtaining a lock on it. On
-- //Windows// locks are enforced by the operating system.
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
-- unlock (a portion of) an open file.
--
-- Parameters:
--		# ##fn## : an integer, the handle to the file or device to (partially) lock.
--		# ##r## : a sequence, defining a section of the file to be locked, or ##{}## for the whole file (the default).
--
-- Errors:
-- The target file or device must be open.
--
-- Comments:
-- You must have previously locked the
-- file using ##lock_file##. On //Windows// you can unlock a range of bytes within a
-- file by specifying the ##r## as ##{first_byte, last_byte}##. The same range of bytes
-- must have been locked by a previous call to [[:lock_file]]. On //Unix// you can
-- currently only lock or unlock an entire file. ##r## should be ##{}## when you
-- want to unlock an entire file. On //Unix//, ##r## must always be ##{}##, which is the default.
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
-- === File Reading and Writing

--**
-- reads the contents of a file as a sequence of lines.
--
-- Parameters:
--		##file## : an object, either a file path or the handle to an open file.
--                 If this is an empty string, STDIN (the console) is used.
--
-- Returns:
--		-1 on error or a **sequence**, made of lines from the file, as [[:gets]] could read them.
--
-- Comments:
--	If ##file## was a sequence, the file will be closed on completion. Otherwise, it will remain open, but at end of file.
--
-- Example 1:
-- <eucode>
-- data = read_lines("my_file.txt")
-- -- data contains the entire contents of ##my_file.txt##, 1 sequence per line:
-- -- {"Line 1", "Line 2", "Line 3"}
-- </eucode>
--
-- Example 2:
-- <eucode>
-- fh = open("my_file.txt", "r")
-- data = read_lines(fh)
-- close(fh)
--
-- -- data contains the entire contents of ##my_file.txt##, 1 sequence per line:
-- -- {"Line 1", "Line 2", "Line 3"}
-- </eucode>
--
-- See Also:
--		[[:gets]], [[:write_lines]], [[:read_file]]

public function read_lines(object file)
	object fn, ret, y
	if sequence(file) then
		if length(file) = 0 then
			fn = 0
		else
			fn = open(file, "r")
		end if
	else
		fn = file
	end if
	if fn < 0 then return -1 end if

	ret = {}
	while sequence(y) with entry do
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
		if fn = 0 then
			puts(2, '\n')
		end if
	entry
		y = gets(fn)
	end while

	if sequence(file) and length(file) != 0 then
		close(fn)
	end if

	return ret
end function

--**
-- processes the contents of a file, one line at a time.
--
-- Parameters:
-- # ##file## : an object. Either a file path or the handle to an open file. An 
-- empty string signifies ##STDIN## ~-- the console keyboard.
-- # ##proc## : an integer. The routine_id of a function that will process the line.
-- # ##user_data## : on object. This is passed untouched to ##proc## for each line.
--
-- Returns:
--	An object. If 0 then all the file was processed successfully. Anything else
--  means that something went wrong and this is whatever value was returned by ##proc##.
--
-- Comments:
--  * The function ##proc## must accept three parameters~:
--    ** A sequence: The line to process. It will **not** contain an end-of-line character.
--    ** An integer: The line number.
--    ** An object : This is the ##user_data## that was passed to ##process_lines##.
--	* If ##file## was a sequence, the file will be closed on completion. 
--  Otherwise, it will remain open, and be positioned where ever reading stopped.
--
-- Example 1:
-- <eucode>
-- -- Format each supplied line according to the format pattern supplied as well.
-- function show(sequence aLine, integer line_no, object data)
--   writefln( data[1], {line_no, aLine})
--   if data[2] > 0 and line_no = data[2] then
--   	return 1
--   else
--   	return 0
--   end if
-- end function
-- -- Show the first 20 lines.
-- process_lines("sample.txt", routine_id("show"), {"[1z:4] : [2]", 20})
-- </eucode>
--
-- See Also:
--		[[:gets]], [[:read_lines]], [[:read_file]]

public function process_lines(object file, integer proc, object user_data = 0)
	integer fh
	object aLine
	object res
	integer line_no = 0
	
	res = 0
	if sequence(file) then
		if length(file) = 0 then
			fh = 0
		else
			fh = open(file, "r")
		end if
	else
		fh = file
	end if
	if fh < 0 then 
		return -1 
	end if
	
	while sequence(aLine) with entry do
		line_no += 1
		if length(aLine) then
			if aLine[$] = '\n' then
				aLine = aLine[1 .. $-1]
				ifdef UNIX then
					if length(aLine) then
						if aLine[$] = '\r' then
							aLine = aLine[1 .. $-1]
						end if
					end if
				end ifdef
			end if
		end if
		res = call_func(proc, {aLine, line_no, user_data})
		if not equal(res, 0) then
			exit
		end if
		
	entry
		aLine = gets(fh)
	end while

	if sequence(file) and length(file) != 0 then
		close(fh)
	end if

	return res
end function

--**
-- write a sequence of lines to a file.
--
-- Parameters:
--		# ##file## : an object, either a file path or the handle to an open file.
--		# ##lines## : the sequence of lines to write
--
-- Returns:
--     An **integer**, 1 on success, -1 on failure.
--
-- Errors:
--		If [[:puts]] cannot write some line of text, a runtime error will occur.
--
-- Comments:
--	If ##file## was a sequence, the file will be closed on completion. Otherwise, it will remain open, but at end of file.
--
-- Whatever integer the lines in ##lines## holds will be truncated to its 8 lowest bits so as to fall in the 0..255 range.
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
-- appends a sequence of lines to a file.
--
-- Parameters:
--		# ##file## : an object, either a file path or the handle to an open file.
--		# ##lines## : the sequence of lines to write
--
-- Returns:
--     An **integer**, 1 on success, -1 on failure.
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

public enum
	BINARY_MODE,
	TEXT_MODE,
	UNIX_TEXT,
	DOS_TEXT

--**
-- reads the contents of a file as a single sequence of bytes.
--
-- Parameters:
--		# ##file## : an object, either a file path or the handle to an open file.
--      # ##as_text## : integer, ##BINARY_MODE## (the default) assumes //binary mode// that
--                     causes every byte to be read in,
--                     and ##TEXT_MODE## assumes //text mode// that ensures that
--                     lines end with just a Control+J (NewLine) character,
--                     and the first byte value of 26 (Control+Z) is interpreted as End-Of-File.
--
-- Returns:
--		A **sequence**, holding the entire file. 
--
-- Comments
-- * When using ##BINARY_MODE##, each byte in the file is returned as an element in
--   the return sequence.
-- * When not using ##BINARY_MODE##, the file will be interpreted as a text file. This
-- means that all line endings will be transformed to a single ##0x0A## character and
-- the first ##0x1A## character (Control+Z) will indicate the end of file (all data after this 
-- will not be returned to the caller.)
--
-- Example 1:
-- <eucode>
-- data = read_file("my_file.txt")
-- -- data contains the entire contents of ##my_file.txt##
-- </eucode>
--
-- Example 2:
-- <eucode>
-- fh = open("my_file.txt", "r")
-- data = read_file(fh)
-- close(fh)
--
-- -- data contains the entire contents of ##my_file.txt##
-- </eucode>
--
-- See Also:
--     [[:write_file]], [[:read_lines]]

public function read_file(object file, integer as_text = BINARY_MODE)
	integer fn
	integer len
	sequence ret

	if sequence(file) then
		fn = open(file, "rb")
	else
		fn = file
	end if
	if fn < 0 then return -1 end if

	seek(fn, -1)
	len = where(fn)
	seek(fn, 0)

	ret = repeat(0, len)
	for i = 1 to len do
		ret[i] = getc(fn)
	end for

	if sequence(file) then
		close(fn)
	end if

	ifdef WINDOWS then
		-- Remove any extra -1 (EOF) characters in case file
		-- had been opened in Windows 'text mode'.
		for i = len to 1 by -1 do
			if ret[i] != -1 then
				if i != len then
					ret = ret[1 .. i]
				end if
				exit
			end if
		end for
	end ifdef

	if as_text = BINARY_MODE then
		return ret
	end if
	
	-- Treat as a text file.
	fn = find(26, ret) -- Any Ctrl-Z found?
	if fn then
		-- Ok, so truncate the file data
		ret = ret[1 .. fn - 1]
	end if

	-- Convert Windows endings
	ret = search:match_replace({13,10}, ret, {10})
	if length(ret) > 0 then
		if ret[$] != 10 then
			ret &= 10
		end if
	else
		ret = {10}
	end if

	return ret
end function

--**
-- write a sequence of bytes to a file.
--
-- Parameters:
--		# ##file## : an object, either a file path or the handle to an open file.
--		# ##data## : the sequence of bytes to write
--      # ##as_text## : integer
--         ** ##BINARY_MODE## (the default) assumes //binary mode// that
--                     causes every byte to be written out as is,
--         ** ##TEXT_MODE## assumes //text mode// that causes a NewLine
--                     to be written out according to the operating system's
--                     end of line convention. On //Unix// this is Control+J and on
--                     //Windows// this is the pair ##{Ctrl-L, Ctrl-J}##.
--         ** ##UNIX_TEXT## ensures that lines are written out with //Unix// style
--                     line endings (Control+J).
--         ** ##DOS_TEXT## ensures that lines are written out with //Windows// style
--                     line endings ##{Ctrl-L, Ctrl-J}##.
-- Returns:
--     An **integer**, 1 on success, -1 on failure.
--
-- Errors:
--		If [[:puts]] cannot write ##data##, a runtime error will occur.
--
-- Comments:
-- * When ##file## is a file handle, the file is not closed after writing is finished. When ##file## is a
-- file name, it is opened, written to and then closed.
-- * Note that when writing the file in ony of the text modes, the file is truncated
-- at the first Control+Z character in the input data.
--
-- Example 1:
-- <eucode>
-- if write_file("data.txt", "This is important data\nGoodbye") = -1 then
--     puts(STDERR, "Failed to write data\n")
-- end if
-- </eucode>
--
-- See Also:
--    [[:read_file]], [[:write_lines]]

public function write_file(object file, sequence data, integer as_text = BINARY_MODE)
	integer fn

	if as_text != BINARY_MODE then
		-- Truncate at first Ctrl-Z
		fn = find(26, data)
		if fn then
			data = data[1 .. fn-1]
		end if
		-- Ensure last line has a line-end marker.
		if length(data) > 0 then
			if data[$] != 10 then
				data &= 10
			end if
		else
			data = {10}
		end if

		if as_text = TEXT_MODE then
			-- Standardize all line endings
			data = search:match_replace({13,10}, data, {10})

		elsif as_text = UNIX_TEXT then
			data = search:match_replace({13,10}, data, {10})

		elsif as_text = DOS_TEXT then
			data = search:match_replace({13,10}, data, {10})
			data = search:match_replace({10}, data, {13,10})
		end if
	end if

		
	if sequence(file) then
		if as_text = TEXT_MODE then
			fn = open(file, "w")
		else
			fn = open(file, "wb")
		end if
	else
		fn = file
	end if
	if fn < 0 then return -1 end if

	puts(fn, data)

	if sequence(file) then
		close(fn)
	end if

	return 1
end function


--**
-- writes formatted text to a file.
--
-- Parameters:
-- There are two ways to pass arguments to this function~:
--
-- # Traditional way with first arg being a file handle.
--		## : integer, The file handle.
--		## : sequence, The format pattern.
--      ## : object, The data that will be formatted.
--      ## ##data_not_string##: object, If not 0 then the ##data## is not a string.
--        By default this is 0 meaning that ##data## could be a single string.
--
-- # Alternative way with first argument being the format pattern.
--		## : sequence, Format pattern.
--		## : sequence, The data that will be formatted,
--      ## : object, The file to receive the formatted output. Default is
--      to the STDOUT device (console).
--      ## ##data_not_string##: object, If not 0 then the ##data## is not a string.
--        By default this is 0 meaning that ##data## could be a single string.
-- 
-- Comments:
-- * With the traditional arguments, the first argument must be an integer file handle.
-- * With the alternative arguments, the thrid argument can be a file name string, 
--   in which case it is opened for output, written to and then closed.
-- * With the alternative arguments, the third argument can be a two-element sequence
--   containing a file name string and an output type (##"a"## for append, ##"w"## for write),
--   in which case it is opened accordingly, written to and then closed.
-- * With the alternative arguments, the third argument can a file handle, 
--   in which case it is written to only
-- * The format pattern uses the formatting codes defined in [[:text:format]].
-- * When the data to be formatted is a single text string, it does not have to
--   be enclosed in braces, 
--
-- Example 1:
-- <eucode>
-- -- To console
-- writef("Today is [4], [u2:3] [3:02], [1:4].", 
--        {Year, MonthName, Day, DayName})
-- -- To "sample.txt"
-- writef("Today is [4], [u2:3] [3:02], [1:4].", 
--        {Year, MonthName, Day, DayName}, "sample.txt")
-- -- To "sample.dat"
-- integer dat = open("sample.dat", "w")
-- writef("Today is [4], [u2:3] [3:02], [1:4].", 
--        {Year, MonthName, Day, DayName}, dat)
-- -- Appended to "sample.log"
-- writef("Today is [4], [u2:3] [3:02], [1:4].", 
--        {Year, MonthName, Day, DayName}, {"sample.log", "a"})
-- -- Simple message to console
-- writef("A message")
-- -- Another console message
-- writef(STDERR, "This is a []", "message")
-- -- Outputs two numbers
-- writef(STDERR, "First [], second []", {65, 100}, 1)
--      -- Note that {65, 100} is also "Ad"
-- </eucode>
--
-- See Also:
--    [[:text:format]], [[:writefln]], [[:write_lines]]

public procedure writef(object fm, object data={}, object fn = 1, object data_not_string = 0)
	integer real_fn = 0
	integer close_fn = 0
	sequence out_style = "w"
	
	if integer(fm) then
		object ts
		-- File Handle in first arguement so rotate the arguments.
		ts = fm
		fm = data
		data = fn
		fn = ts
	end if
	
	if sequence(fn) then
		if length(fn) = 2 then
			if sequence(fn[1]) then
				if equal(fn[2], 'a') then
					out_style = "a"
				elsif not equal(fn[2], "a") then
					out_style = "w"
				else
					out_style = "a"
				end if
				fn = fn[1]
			end if
		end if
		real_fn = open(fn, out_style)
		
		if real_fn = -1 then
			error:crash("Unable to write to '%s'", {fn})
		end if
		close_fn = 1
	else
		real_fn = fn
	end if
	
	if equal(data_not_string, 0) then
		if types:t_display(data) then
			data = {data}
		end if
	end if
    puts(real_fn, text:format( fm, data ) )
    if close_fn then
    	close(real_fn)
    end if
end procedure

--**
-- writes formatted text to a file, ensuring that a new line is also output.
--
-- Parameters:
--		# ##fm## : sequence, Format pattern.
--		# ##data## : sequence, The data that will be formatted,
--      # ##fn## : object, The file to receive the formatted output. Default is
--      to the ##STDOUT## device (console).
--      # ##data_not_string##: object, If not 0 then the ##data## is not a string.
--        By default this is 0 meaning that ##data## could be a single string.
--
-- Comments:
-- * This is the same as [[:writef]], except that it always adds a New Line to 
--   the output.
-- * When ##fn## is a file name string, it is opened for output, 
--   written to and then closed.
-- * When ##fn## is a two-element sequence containing a file name string and 
--   an output type (##"a"## for append, ##"w"## for write), it is opened accordingly, 
--   written to and then closed.
-- * When ##fn## is a file handle, it is written to only
-- * The ##fm## uses the formatting codes defined in [[:text:format]].
--
-- Example 1:
-- <eucode>
-- -- To console
-- writefln("Today is [4], [u2:3] [3:02], [1:4].", 
--          {Year, MonthName, Day, DayName})
-- -- To "sample.txt"
-- writefln("Today is [4], [u2:3] [3:02], [1:4].", 
--          {Year, MonthName, Day, DayName}, "sample.txt")
-- -- Appended to "sample.log"
-- writefln("Today is [4], [u2:3] [3:02], [1:4].", 
--          {Year, MonthName, Day, DayName}, {"sample.log", "a"})
-- </eucode>
--
-- See Also:
--    [[:text:format]], [[:writef]], [[:write_lines]]
public procedure writefln(object fm, object data={}, object fn = 1, object data_not_string = 0)
	if integer(fm) then
		writef(data & '\n', fn, fm, data_not_string)
	else
		writef(fm & '\n', data, fn, data_not_string)
	end if
end procedure
