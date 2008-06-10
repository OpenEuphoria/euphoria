-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
-- Input and Conversion Routines:
-- get()
-- value()
-- wait_key()

--****
-- Category: 
--   get
--
-- Title:
--   Input Routines
--****

-- error status values returned from get() and value():
global constant GET_SUCCESS = 0,
				GET_EOF = -1,
				GET_FAIL = 1,
				GET_NOTHING = -2

constant M_WAIT_KEY = 26

constant DIGITS = "0123456789",
		 HEX_DIGITS = DIGITS & "ABCDEF",
		 START_NUMERIC = DIGITS & "-+.#"

constant TRUE = 1

type natural(integer x)
	return x >= 0
end type

type char(integer x)
	return x >= -1 and x <= 255
end type

natural input_file  -- file to be read from

object input_string -- string to be read from
natural string_next

char ch  -- the current character

--**
-- Signature:
-- global function get_key()
--
-- Description:
-- Return the key that was pressed by the user, without waiting. Return -1 if no key was pressed. Special codes are returned for the function keys, arrow keys etc.
--
-- Comments:
-- The operating system can hold a small number of key-hits in its keyboard buffer. get_key() will return the next one from the buffer, or -1 if the buffer is empty.
--
-- Run the key.bat program to see what key code is generated for each key on your keyboard. 
--
-- Example 1:
-- 
--**

--**
-- Signature:
-- global function getc(integer fn)
--
-- Description:
-- Get the next character (byte) from file or device fn. The character will have a value from 0 to 255. -1 is returned at end of file.
--
-- Comments:
-- File input using getc() is buffered, i.e. getc() does not actually go out to the disk for each character. Instead, a large block of characters will be read in at one time and returned to you one by one from a memory buffer.
--
-- When getc() reads from the keyboard, it will not see any characters until the user presses Enter. Note that the user can type CTRL+Z, which the operating system treats as "end of file". -1 will be returned. 
--**

--**
-- Signature:
-- global function gets(integer fn)
--
-- Description:
-- Get the next sequence (one line, including '\n') of characters from file or device fn. The characters will have values from 0 to 255. The atom -1 is returned on end of file.
--
-- Comments:
-- Because either a sequence or an atom (-1) might be returned, you should probably assign the result to a variable declared as object.
--
-- After reading a line of text from the keyboard, you should normally output a \n character, e.g. puts(1, '\n'), before printing something. Only on the last line of the screen does the operating system automatically scroll the screen and advance to the next line.
--
-- The last line in a file might not end with a new-line '\n' character.
--
-- When your program reads from the keyboard, the user can type control-Z, which the operating system treats as "end of file". -1 will be returned.
--
-- In SVGA modes, DOS might set the wrong cursor position, after a call to gets(0) to read the keyboard.
-- You should set it yourself using <strong>position()</strong>.
--
-- Example 1:
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
--         exit   -- -1 is returned at end of file
--     end if
--     buffer = append(buffer, line)
-- end while
--
-- Example 2:
-- object line
--
-- puts(1, "What is your name?\n")
-- line = gets(0)  -- read standard input (keyboard)
-- line = line[1..length(line)-1] -- get rid of \n character at end
-- puts(1, '\n')   -- necessary
-- puts(1, line & " is a nice name.\n")
--**

--**
-- Return the next key pressed by the user. Don't return until a key is pressed.
--
-- Comments:
-- You could achieve the same result using get_key() as follows:
-- <eucode>
--     while 1 do
--         k = get_key()
--         if k != -1 then
--             exit
--         end if
--     end while
-- </eucode>
--
-- 	However, on multi-tasking systems like Windows or Linux/FreeBSD, this "busy waiting" would tend to slow the system down. wait_key() lets the operating system do other useful work while your program is waiting for the user to press a key.
--
-- You could also use getc(0), assuming file number 0 was input from the keyboard, except that you wouldn't pick up the special codes for function keys, arrow keys etc. 

global function wait_key()
-- Get the next key pressed by the user.
-- Wait until a key is pressed.
	return machine_func(M_WAIT_KEY, 0)
end function
--**

procedure get_ch()
-- set ch to the next character in the input stream (either string or file)

	if sequence(input_string) then
		if string_next <= length(input_string) then
			ch = input_string[string_next]
			string_next += 1
		else
			ch = GET_EOF
		end if
	else
		ch = getc(input_file)
		if ch = GET_EOF then
			string_next += 1
		end if
	end if
end procedure

constant white_space = " \t\n\r"
procedure skip_blanks()
-- skip white space
-- ch is "live" at entry and exit

	while find(ch, white_space) do
		get_ch()
	end while
end procedure

constant ESCAPE_CHARS = "nt'\"\\r",
		 ESCAPED_CHARS = "\n\t'\"\\\r"

function escape_char(char c)
-- return escape character
	natural i

	i = find(c, ESCAPE_CHARS)
	if i = 0 then
		return GET_FAIL
	else
		return ESCAPED_CHARS[i]
	end if
end function

function get_qchar()
-- get a single-quoted character
-- ch is "live" at exit
	char c
	
	get_ch()
	c = ch
	if ch = '\\' then
		get_ch()
		c = escape_char(ch)
		if c = GET_FAIL then
			return {GET_FAIL, 0}
		end if
	elsif ch = '\'' then
		return {GET_FAIL, 0}
	end if
	get_ch()
	if ch != '\'' then
		return {GET_FAIL, 0}
	else
		get_ch()
		return {GET_SUCCESS, c}
	end if
end function

function get_string()
-- get a double-quoted character string
-- ch is "live" at exit
	sequence text

	text = ""
	while TRUE do
		get_ch()
		if ch = GET_EOF or ch = '\n' then
			return {GET_FAIL, 0}
		elsif ch = '"' then
			get_ch()
			return {GET_SUCCESS, text}
		elsif ch = '\\' then
			get_ch()
			ch = escape_char(ch)
			if ch = GET_FAIL then
				return {GET_FAIL, 0}
			end if
		end if
		text = text & ch
	end while
end function

type plus_or_minus(integer x)
	return x = -1 or x = +1
end type

constant GET_IGNORE = GET_NOTHING
function read_comment()
	if atom(input_string) then
		while ch!='\n' and ch!='\r' and ch!=-1 do
			get_ch()
		end while
		get_ch()
		if ch=-1 then
			return {GET_EOF,0}
		else
			return {GET_IGNORE,0}
		end if
	else
		for i=string_next to length(input_string) do
			ch=input_string[i]
			if ch='\n' or ch='\r' then
				string_next=i+1
				return {GET_IGNORE,0}
			end if
		end for
		return {GET_EOF,0}
	end if
end function

function get_number()
-- read a number or a comment
-- ch is "live" at entry and exit
	plus_or_minus sign, e_sign
	natural ndigits
	integer hex_digit
	atom mantissa, dec, e_mag

	sign = +1
	mantissa = 0
	ndigits = 0

	-- process sign
	if ch = '-' then
		sign = -1
		get_ch()
		if ch='-' then
			return read_comment()
		end if
	elsif ch = '+' then
		get_ch()
	end if

	-- get mantissa
	if ch = '#' then
		-- process hex integer and return
		get_ch()
		while TRUE do
			hex_digit = find(ch, HEX_DIGITS)-1
			if hex_digit >= 0 then
				ndigits += 1
				mantissa = mantissa * 16 + hex_digit
				get_ch()
			else
				if ndigits > 0 then
					return {GET_SUCCESS, sign * mantissa}
				else
					return {GET_FAIL, 0}
				end if
			end if
		end while       
	end if

	-- decimal integer or floating point
	while ch >= '0' and ch <= '9' do
		ndigits += 1
		mantissa = mantissa * 10 + (ch - '0')
		get_ch()
	end while
	
	if ch = '.' then
		-- get fraction
		get_ch()
		dec = 10
		while ch >= '0' and ch <= '9' do
			ndigits += 1
			mantissa += (ch - '0') / dec
			dec *= 10
			get_ch()
		end while
	end if
	
	if ndigits = 0 then
		return {GET_FAIL, 0}
	end if
	
	mantissa = sign * mantissa
	
	if ch = 'e' or ch = 'E' then
		-- get exponent sign
		e_sign = +1
		e_mag = 0
		get_ch()
		if ch = '-' then
			e_sign = -1
			get_ch()
		elsif ch = '+' then
			get_ch()
		end if
		-- get exponent magnitude 
		if ch >= '0' and ch <= '9' then
			e_mag = ch - '0'
			get_ch()
			while ch >= '0' and ch <= '9' do
				e_mag = e_mag * 10 + ch - '0'
				get_ch()                          
			end while
		else
			return {GET_FAIL, 0} -- no exponent
		end if
		e_mag *= e_sign 
		if e_mag > 308 then
			-- rare case: avoid power() overflow
			mantissa *= power(10, 308)
			if e_mag > 1000 then
				e_mag = 1000 
			end if
			for i = 1 to e_mag - 308 do
				mantissa *= 10
			end for
		else
			mantissa *= power(10, e_mag)
		end if
	end if
	
	return {GET_SUCCESS, mantissa}
end function

function Get()
-- read a Euphoria data object as a string of characters
-- and return {error_flag, value}
-- Note: ch is "live" at entry and exit of this routine
	sequence s, e
	integer e1

	-- init
	while find(ch, white_space) do
		get_ch()
	end while

	if ch = -1 then -- string is made of whitespace only
		return {GET_EOF, 0}
	end if

	while 1 do
		if find(ch, START_NUMERIC) then
			e = get_number()
			if e[1] != GET_IGNORE then -- either a number or something illegal was read, so exit: the other goto
				return e
			end if          -- else go read next item, starting at top of loop
			skip_blanks()
			if ch=-1 or ch='}' then -- '}' is expected only in the "{--\n}" case
				return {GET_NOTHING, 0} -- just a comment
			end if

		elsif ch = '{' then
			-- process a sequence
			s = {}
			get_ch()
			skip_blanks()
			if ch = '}' then -- empty sequence
				get_ch()
				return {GET_SUCCESS, s} -- empty sequence
			end if
			
			while TRUE do -- read: comment(s),element,comment(s),comma and so on till it terminates or errors out
				while 1 do -- read zero or more comments and an element
					e = Get() -- read next element, using standard function
					e1 = e[1]
					if e1 = GET_SUCCESS then
						s = append(s, e[2])
						exit  -- element read and added to result
					elsif e1 != GET_IGNORE then
						return e
					-- else it was a comment, keep going
					elsif ch='}' then
						get_ch()
						return {GET_SUCCESS, s} -- empty sequence
					end if
				end while
				
				while 1 do -- now read zero or more post element comments
					skip_blanks()
					if ch = '}' then
						get_ch()
					return {GET_SUCCESS, s}
					elsif ch!='-' then 
						exit
					else -- comment starts after item and before comma
						e = get_number() -- reads anything starting witn '-'
						if e[1] != GET_IGNORE then  -- it wasn't a coment, this is illegal
							return {GET_FAIL, 0}
						end if
						-- read next comment or , or }
					end if
			end while
				if ch != ',' then
				return {GET_FAIL, 0}
				end if
			get_ch() -- skip comma
			end while

		elsif ch = '\"' then
			return get_string()
		elsif ch = '\'' then
			return get_qchar()
		else
			return {GET_FAIL, 0}

		end if
		
	end while

end function

integer leading_whitespace

function Get2(natural offset)
-- read a Euphoria data object as a string of characters
-- and return {error_flag, value,total number of characters, leading whitespace}
-- Note: ch is "live" at entry and exit of this routine.
-- Uses the regular Get() to read esequence elements.
	sequence s, e
	integer e1

	-- init
	get_ch()
	while find(ch, white_space) do
		get_ch()
	end while

	if ch = -1 then -- string is made of whitespace only
		return {GET_EOF, 0,string_next-1-offset,string_next-1}
	end if

	leading_whitespace = string_next-2-offset -- index of the last whitespace: string_next points past the first non whitespace

	while 1 do
		if find(ch, START_NUMERIC) then
			e = get_number()
			if e[1] != GET_IGNORE then -- either a number or something illegal was read, so exit: the other goto
				return e & {string_next-1-offset-(ch!=-1),leading_whitespace}
			end if          -- else go read next item, starting at top of loop
			get_ch()
			if ch=-1 then
				return {GET_NOTHING, 0,string_next-1-offset-(ch!=-1),leading_whitespace} -- empty sequence
			end if

		elsif ch = '{' then
			-- process a sequence
			s = {}
			get_ch()
			skip_blanks()
			if ch = '}' then -- empty sequence
				get_ch()
				return {GET_SUCCESS, s,string_next-1-offset-(ch!=-1),leading_whitespace} -- empty sequence
			end if

			while TRUE do -- read: comment(s),element,comment(s),comma and so on till it terminates or errors out
				while 1 do -- read zero or more comments and an element
					e = Get() -- read next element, using standard function
					e1 = e[1]
					if e1 = GET_SUCCESS then
						s = append(s, e[2])
						exit  -- element read and added to result
					elsif e1 != GET_IGNORE then
						return e & {string_next-1-offset-(ch!=-1),leading_whitespace}
					-- else it was a comment, keep going
					elsif ch='}' then
						get_ch()
						return {GET_SUCCESS, s,string_next-1-offset-(ch!=-1),leading_whitespace} -- empty sequence
					end if
				end while
				
				while 1 do -- now read zero or more post element comments
					skip_blanks()
					if ch = '}' then
						get_ch()
					return {GET_SUCCESS, s,string_next-1-offset-(ch!=-1),leading_whitespace}
					elsif ch!='-' then
						exit
					else -- comment starts after item and before comma
						e = get_number() -- reads anything starting witn '-'
						if e[1] != GET_IGNORE then  -- it wasn't a coment, this is illegal
							return {GET_FAIL, 0,string_next-1-offset-(ch!=-1),leading_whitespace}
						end if
						-- read next comment or , or }
					end if
			end while
				if ch != ',' then
				return {GET_FAIL, 0,string_next-1-offset-(ch!=-1),leading_whitespace}
				end if
			get_ch() -- skip comma
			end while

		elsif ch = '\"' then
			e = get_string()
			return e & {string_next-1-offset-(ch!=-1),leading_whitespace}
		elsif ch = '\'' then
			e = get_qchar()
			return e & {string_next-1-offset-(ch!=-1),leading_whitespace}
		else
			return {GET_FAIL, 0,string_next-1-offset-(ch!=-1),leading_whitespace}

		end if
		
	end while

end function

--**
-- Input, from file fn, a human-readable string of characters representing a Euphoria object. Convert the string into the numeric value of that object. s will be a 2-element sequence: <strong>{error status, value}</strong>. Error status codes are:
--
-- <eucode>
--     GET_SUCCESS -- object was read successfully
--     GET_EOF     -- end of file before object was read completely
--     GET_FAIL    -- object is not syntactically correct
--     GET_NOTHING -- nothing was read, even a partial object string, before end of input
-- </eucode>
--
-- get() can read arbitrarily complicated Euphoria objects. You
--  could have a long sequence of values in braces and separated by
--  commas and comments, e.g. {23, {49, 57}, 0.5, -1, 99, 'A', "john"}.
--  A single call to get() will read in this
--  entire sequence and return its value as a result, as well as complementary information.
-- 
-- get() returns a 2 element sequence, like value() does:
-- <ul>
-- <li> a status code (success/error/end of file/no value at all)</li>
-- <li> the value just read (meaningful only when the status code is GET_SUCCESS)</li>
-- </ul>
-- Each call to get() picks up where the previous call left off. For instance, a series of 5 calls to get() would be needed to read in:
-- 
-- <console>"99 5.2 {1,2,3} "Hello" -1"</console>
-- 
-- On the sixth and any subsequent call to get() you would see a GET_EOF status. If you had something like:
-- 
-- <console>{1, 2, xxx}</console>
-- 
-- in the input stream you would see a GET_FAIL error status because xxx is not a Euphoria object. And seeing
-- 
--    -- something\nBut no value
-- 
-- and the input stream stops right there, you'll  receive a status code of GET_NOTHING, because nothing but whitespace or comments was read.
-- 
-- Multiple "top-level" objects in the input stream must be
--  separated from each other with one or more "whitespace"
--  characters (blank, tab, \r or \n). At the very least, a top
--  level number must be followed by a white space from the following object.
--  Whitespace is not necessary <b><i>within</i></b> a top-level object. Comments, terminated by either '\n' or '\r',
--  are allowed anywhere inside sequences, and ignored if at the top level.
--  A call to get() will read one entire top-level object, plus possibly one additional
--  (whitespace) character, after a top level number, even though the next object may have an identifiable starting pont.
--
-- Comments:
-- The combination of print() and get() can be used to save a
--  Euphoria object to disk and later read it back. This technique
--  could be used to implement a database as one or more large
--  Euphoria sequences stored in disk files. The sequences could be
--  read into memory, updated and then written back to disk after
--  each series of transactions is complete. Remember to write out
--  a whitespace character (using puts()) after each call to print(),
--  at least when a top level number was just printed.
-- 
-- The value returned is not meaningful unless you have a GET_SUCCESS status.
--
-- Example 1:
-- If he types 77.5, get(0) would return:
--
-- {GET_SUCCESS, 77.5}
--
-- -- whereas gets(0) would return:
--
-- "77.5\n"
--
-- Example 2:
-- See <path>bin\mydata.ex</path>

global function get(integer file)
-- Read the string representation of a Euphoria object
-- from a file. Convert to the value of the object.
-- Return {error_status, value}.
-- Embedded comments inside sequences are now supported.
	input_file = file
	string_next = 1
	input_string = 0
	get_ch() 
	return Get()
end function
--**

--**
-- Read the string representation of a Euphoria object, and compute the value of that object. A 2-element sequence, {error_status, value} is actually returned, where error_status can be one of:
--
--	<eucode>
--     GET_SUCCESS -- a valid object representation was found
--     GET_EOF     -- end of string reached too soon
--     GET_FAIL    -- syntax is wrong
--	</eucode>
--
-- Comments:
-- This works the same as get(), but it reads from a string that you supply, rather than from a file or device.
--
-- After reading one valid representation of a Euphoria object, value() will stop reading and ignore any additional characters in the string. For example, "36" and "36P" will both give you {GET_SUCCESS, 36}. 
--
-- Example 1:
-- s = value("12345"}
-- s is {GET_SUCCESS, 12345}
--
-- Example 2: 	
-- s = value("{0, 1, -99.9}")
-- -- s is {GET_SUCCESS, {0, 1, -99.9}}
--
-- Example 3: 	
-- s = value("+++")
-- -- s is {GET_FAIL, 0}

global function value(sequence string)
-- Read the representation of a Euphoria object
-- from a sequence of characters. Convert to the value of the object.
-- Trailing whitespace or comments are not considered.
-- Return {error_status, value}.
-- Embedded comments inside sequence are now supported.
	input_string = string
	string_next = 1
	get_ch() 
	return Get()
end function
--**

--**
-- Read the string representation of a Euphoria object, and computes
--  the value of that object. The string which is read is the tail of st which starts at index i.
--  A 4-element sequence,
--  <b>{error_status, value, total characters read, number of leading whitespace}</b> is
--   actually returned, where error_status can be one of:
--  
-- <eucode>
--     GET_SUCCESS -- a valid object representation was found
--     GET_EOF     -- end of string reached too soon
--     GET_FAIL    -- syntax is wrong
--     GET_NOTHING -- end of string reached without any value being even partially read
-- </eucode>
--
-- Comments:
-- This works the same as <b>value()</b>, but
-- <ul>
-- <li> reading starts where you instruct the routine to, instead of starting from the beginning of the string. You can always pass value() a slice to achieve a similar effect.</li>
-- <li> it returns extra information value() doesn't.</li>
-- </ul>
--  
--  After reading one valid representation of a Euphoria object, value_from() will
--  stop reading and ignore any additional characters in the string. For
--  example, "36" and "36P" will both give you {GET_SUCCESS, 36, 2, 0}.". After reading an
--  invalid representation, the value field is undefined (usually 0), and the third field is the
--  1 based index of the character the reading of which caused an error.
--  
--  If the representation was valid, you can use the third returned element to pick up where you 
--  left, like get() does in a file. There is no corresponding get_from(), at least because 
--  calling where() before and after get() will tell you how many characters were read.
--
-- Example 1:
-- s = value_from("  12345"} -- notice the two leading spaces
-- -- s is {GET_SUCCESS, 12345, 7, 2}
--
-- Example 2:
-- s = value_from("{0, 1, -99.9}")
-- -- s is {GET_SUCCESS, {0, 1, -99.9}, 13, 0}
--
-- Example 3:
-- s = value_from("+++")
-- -- s is {GET_FAIL, 0, 2, 0} -- error condition triggered on reading the 2nd character

global function value_from(sequence string, natural starting_point = 1)
-- Read the representation of a Euphoria object
-- from a sequence of characters. Convert to the value of the object.
-- Trailing whitespace or comment are not considered.
-- Return {error_status, value,total # of characters,# leading whitespaces).
-- On error, the third element is the index at which the error condition was seen.
-- Embedded comments inside sequences are supported.
	if string[starting_point] then end if -- checks whether starting_point is valid
	input_string = string
	string_next = starting_point
	return Get2(starting_point-1)
end function
--**

--**
-- Prompt the user to enter a number. st is a string of text that will be displayed on the screen. s is a sequence of two values {lower, upper} which determine the range of values that the user may enter. If the user enters a number that is less than lower or greater than upper, he will be prompted again. s can be empty, {}, if there are no restrictions.
--
-- Comments:
-- If this routine is too simple for your needs, feel free to copy it and make your own more specialized version.
--
-- Example 1:
-- age = prompt_number("What is your age? ", {0, 150})
--
-- Example 2: 	
-- t = prompt_number("Enter a temperature in Celcius:\n", {})

global function prompt_number(sequence prompt, sequence range)
-- Prompt the user to enter a number.
-- A range of allowed values may be specified.
	object answer

	while 1 do
		 puts(1, prompt)
		 answer = gets(0) -- make sure whole line is read
		 puts(1, '\n')

		 answer = value(answer)
		 if answer[1] != GET_SUCCESS or sequence(answer[2]) then
			  puts(1, "A number is expected - try again\n")
		 else
			 if length(range) = 2 then
				  if range[1] <= answer[2] and answer[2] <= range[2] then
					  return answer[2]
				  else
					  printf(1,
					  "A number from %g to %g is expected here - try again\n",
					   range)
				  end if
			  else
				  return answer[2]
			  end if
		 end if
	end while
end function
--**

--**
-- Prompt the user to enter a string of text. st is a string that will be displayed on the screen. The string that the user types will be returned as a sequence, minus any new-line character.
--
-- Comments:
-- If the user happens to type control-Z (indicates end-of-file), "" will be returned.
--
-- Example 1:
-- name = prompt_string("What is your name? ")

global function prompt_string(sequence prompt)
-- Prompt the user to enter a string
	object answer
	
	puts(1, prompt)
	answer = gets(0)
	puts(1, '\n')
	if sequence(answer) and length(answer) > 0 then
		return answer[1..$-1] -- trim the \n
	else
		return ""
	end if
end function
--**

constant CHUNK = 100

--**
-- Read the next n bytes from file number fn. Return the bytes
--  as a sequence. The sequence will be of length n, except
--  when there are fewer than n bytes remaining to be read in the
--  file.
--
-- Comments:
-- When i > 0 and <a href="lib_seq.htm#length">length(s)</a> < i you know
--  you've reached the end of file. Eventually, an
--  <a href="refman_2.htm#empty_seq">empty sequence</a> will be returned
--  for s.
--  
--  This function is normally used with files opened in binary mode, "rb".
--  This avoids the confusing situation in text mode where DOS will convert CR LF pairs to LF.
--
-- Example 1:
-- include get.e
--
-- integer fn
-- fn = open("temp", "rb")  -- an existing file
--
-- sequence whole_file
-- whole_file = {}
--
-- sequence chunk
--
-- while 1 do
--     chunk = get_bytes(fn, 100) -- read 100 bytes at a time
--     whole_file &= chunk        -- chunk might be empty, that's ok
--     if length(chunk) < 100 then
--         exit
--     end if
-- end while
--
-- close(fn)
-- ? length(whole_file)  -- should match DIR size of "temp"

global function get_bytes(integer fn, integer n)
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
	if c = GET_EOF then
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
		if s[last] = GET_EOF then  
			-- trim the EOF's and return
			while s[last] = GET_EOF do
				last -= 1
			end while 
			return s[1..last]
		end if
	end while   
	return s
end function
--**
