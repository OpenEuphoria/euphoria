-- (c) Copyright 2007 Rapid Deployment Software - See License.txt
--
-- Euphoria 4.0
-- Miscellaneous routines and constants

--****
-- Category: 
--   misc
--
-- File:
--   lib_misc
--
-- Title:
--   Euphoria Standard Library Miscellaneous Routines
--****

-- platform() values:
global constant DOS32 = 1,  -- ex.exe
				WIN32 = 2,  -- exw.exe
				LINUX = 3,  -- exu
				FREEBSD = 3 -- exu

constant M_INSTANCE = 55, M_SLEEP = 64

--**
-- Signature:
-- global procedure print(integer fn, object x)
--
-- Description:
-- Print, to file or device fn, an object x with braces { , , , } to show the structure.
--
-- Example 1: 	
-- print(1, "ABC")  -- output is:  {65, 66, 67}
-- puts(1, "ABC")   -- output is:  ABC
--
-- Example 2: 	
-- print(1, repeat({10,20}, 3)) -- output is: {{10,20},{10,20},{10,20}} 
--**

--**
-- Signature:
-- global procedure printf(integer fn, sequence st, sequence x)
--
-- Description:
-- Print x, to file or device fn, using format string st. If x is a sequence, then format specifiers from st are matched with corresponding elements of x. If x is an atom, then normally st will contain just one format specifier and it will be applied to x, however if st contains multiple format specifiers, each one will be applied to the same value x. Thus printf() always takes exactly 3 arguments. Only the length of the last argument, containing the values to be printed, will vary. The basic format specifiers are:
--
-- %d - print an atom as a decimal integer
-- %x - print an atom as a hexadecimal integer. Negative numbers are printed in two's complement, so -1 will print as FFFFFFFF
-- %o - print an atom as an octal integer
-- %s - print a sequence as a string of characters, or print an atom as a single character
-- %e - print an atom as a floating-point number with exponential notation
-- %f - print an atom as a floating-point number with a decimal point but no exponent
-- %g - print an atom as a floating-point number using whichever format seems appropriate, given the magnitude of the number
-- %% - print the '%' character itself
--
-- Field widths can be added to the basic formats, e.g. %5d, %8.2f, %10.4s. The number before the decimal point is the minimum field width to be used. The number after the decimal point is the precision to be used.
--
-- If the field width is negative, e.g. %-5d then the value will be left-justified within the field. Normally it will be right-justified. If the field width starts with a leading 0, e.g. %08d then leading zeros will be supplied to fill up the field. If the field width starts with a '+' e.g. %+7d then a plus sign will be printed for positive values. 
--
-- Comments:
-- Watch out for the following common mistake:
--
-- <eucode>
--     name="John Smith"
--     printf(1, "%s", name)     -- error!
-- </eucode>
--
-- 	This will print only the first character, J, of name, as each element of name is taken to be a separate value to be formatted. You must say this instead:
-- 	
-- <eucode>
--     name="John Smith"
--     printf(1, "%s", {name})   -- correct
-- </eucode>
--
-- Now, the third argument of printf() is a one-element sequence containing the item to be formatted.
--
-- Example 1: 	
-- rate = 7.875
-- printf(myfile, "The interest rate is: %8.2f\n", rate)
--
--       The interest rate is:     7.88
--
-- Example 2:
-- name="John Smith"
-- score=97
-- printf(1, "%15s, %5d\n", {name, score})

--       John Smith,    97

-- Example 3: 	
-- printf(1, "%-10.4s $ %s", {"ABCDEFGHIJKLMNOP", "XXX"})
--       ABCD       $ XXX
--
-- Example 4:
-- printf(1, "%d  %e  %f  %g", 7.75) -- same value in different formats
--
--       7  7.750000e+000  7.750000  7.75
--**

--**
-- Signature:
-- global procedure puts(integer fn, sequence x)
--
-- Description:
-- Output, to file or device fn, a single byte (atom) or sequence of bytes. The low order 8-bits of each value is actually sent out. If fn is the screen you will see text characters displayed.
--
-- Comments:
-- When you output a sequence of bytes it must not have any (sub)sequences within it. It must be a sequence of atoms only. (Typically a string of ASCII codes).
--
-- Avoid outputting 0's to the screen or to standard output. Your output might get truncated.
--
-- Remember that if the output file was opened in text mode, DOS and Windows will change \n (10) to \r\n (13 10). Open the file in binary mode if this is not what you want. 
--
-- Example 1: 	
-- puts(SCREEN, "Enter your first name: ")
--
-- Example 2: 	
-- puts(output, 'A')  -- the single byte 65 will be sent to output
--**

--**
-- Signature:
-- global function sprintf(sequence st, object x)
--
-- Description:
-- This is exactly the same as printf(), except that the output is returned as a sequence of characters, rather than being sent to a file or device. st is a format string, x is the value or sequence of values to be formatted. printf(fn, st, x)  is equivalent to puts(fn, sprintf(st, x)).
--
-- Comments:
-- Some typical uses of sprintf() are:
--
-- <ol>
-- <li>Converting numbers to strings.</li>
-- <li>Creating strings to pass to system().</li>
-- <li>Creating formatted error messages that can be passed to a common error message handler. </li>
-- </ol>
--
-- Example 1: 	
-- s = sprintf("%08d", 12345)
-- -- s is "00012345"
--**

global function instance()
-- WIN32: returns hInstance - handle to this instance of the program
-- DOS32: returns 0
	return machine_func(M_INSTANCE, 0)
end function

global procedure sleep(integer t)
-- go to sleep for t seconds
-- allowing (on WIN32 and Linux) other processes to run
	if t >= 0 then
		machine_proc(M_SLEEP, t)
	end if
end procedure

--**
-- The representation of x as a string of characters is returned. This is exactly the same as print(fn, x), except that the output is returned as a sequence of characters, rather than being sent to a file or device. x can be any Euphoria object.
--
-- Comments:
-- The atoms contained within x will be displayed to a maximum of 10 significant digits, just as with print().
--
-- Example 1:
-- s = sprint(12345)
-- -- s is "12345"
--
-- Example 2: 	
-- s = sprint({10,20,30}+5)
-- -- s is "{15,25,35}"

global function sprint(object x)
-- Return the string representation of any Euphoria data object. 
-- This is the same as the output from print(1, x) or '?', but it's
-- returned as a string sequence rather than printed.
	sequence s
								 
	if atom(x) then
		return sprintf("%.10g", x)
	else
		s = "{"
		for i = 1 to length(x) do
			s &= sprint(x[i])  
			if i < length(x) then
				s &= ','
			end if
		end for
		s &= "}"
		return s
	end if
end function
--**

-- pretty print variables
integer pretty_end_col, pretty_chars, pretty_start_col, pretty_level, 
		pretty_file, pretty_ascii, pretty_indent, pretty_ascii_min,
		pretty_ascii_max, pretty_line_count, pretty_line_max, pretty_dots
sequence pretty_fp_format, pretty_int_format, pretty_line

procedure pretty_out(object text)
-- Output text, keeping track of line length.
-- Buffering lines speeds up Windows console output.
	pretty_line &= text
	if equal(text, '\n') then
		puts(pretty_file, pretty_line)
		pretty_line = ""
		pretty_line_count += 1
	end if
	if atom(text) then
		pretty_chars += 1
	else
		pretty_chars += length(text)
	end if
end procedure

procedure cut_line(integer n)
-- check for time to do line break
	if pretty_chars + n > pretty_end_col then
		pretty_out('\n')
		pretty_chars = 0
	end if
end procedure

procedure indent()
-- indent the display of a sequence
	if pretty_chars > 0 then
		pretty_out('\n')
		pretty_chars = 0
	end if
	pretty_out(repeat(' ', (pretty_start_col-1) + 
							pretty_level * pretty_indent))
end procedure

function show(integer a)
-- show escaped characters
	if a = '\t' then
		return "\\t"
	elsif a = '\n' then
		return "\\n"
	elsif a = '\r' then
		return "\\r"
	else
		return a
	end if
end function

procedure rPrint(object a)
-- recursively print a Euphoria object  
	sequence sbuff
	integer multi_line, all_ascii
	
	if atom(a) then
		if integer(a) then
			sbuff = sprintf(pretty_int_format, a)
			if pretty_ascii then 
				if pretty_ascii >= 3 then 
					-- replace number with display character?
					if (a >= pretty_ascii_min and a <= pretty_ascii_max) then
						sbuff = '\'' & a & '\''  -- display char only
					
					elsif find(a, "\t\n\r") then
						sbuff = '\'' & show(a) & '\''  -- display char only
					
					end if
				else -- pretty ascii 1 or 2
					 -- add display character to number?
					if (a >= pretty_ascii_min and a <= pretty_ascii_max) then
						sbuff &= '\'' & a & '\'' -- add to numeric display
					end if
				end if
			end if
		else    
			sbuff = sprintf(pretty_fp_format, a)
		end if
		pretty_out(sbuff)
	
	else
		-- sequence 
		cut_line(1)
		multi_line = 0
		all_ascii = pretty_ascii > 1
		for i = 1 to length(a) do
			if sequence(a[i]) and length(a[i]) > 0 then
				multi_line = 1
				all_ascii = 0
				exit
			end if
			if not integer(a[i]) or
			   (a[i] < pretty_ascii_min and 
				(pretty_ascii < 3 or not find(a[i], "\t\r\n"))) or 
				a[i] > pretty_ascii_max then
				all_ascii = 0
			end if
		end for
		
		if all_ascii then
			pretty_out('\"')
		else
			pretty_out('{')
		end if
		pretty_level += 1
		for i = 1 to length(a) do
			if multi_line then
				indent()
			end if
			if all_ascii then
				pretty_out(show(a[i]))
			else    
				rPrint(a[i])
			end if
			if pretty_line_count >= pretty_line_max then
				if not pretty_dots then
					pretty_out(" ...")
				end if
				pretty_dots = 1
				return
			end if
			if i != length(a) and not all_ascii then
				pretty_out(',')
				cut_line(6)
			end if
		end for
		pretty_level -= 1
		if multi_line then
			indent()
		end if
		if all_ascii then
			pretty_out('\"')
		else
			pretty_out('}')
		end if
	end if
end procedure

--**
-- Print, to file or device fn, an object x, using braces { , , , }, indentation, and multiple lines to show the structure.
--
-- argument 1: file number to write to
-- argument 2: the object to display
-- argument 3: is an (up to) 8-element options sequence:
--   Pass {} to select the defaults, or set options as below:
--   [1] display ASCII characters:
--       0: never
--       1: alongside any integers in printable ASCII range (default)
--       2: display as "string" when all integers of a sequence 
--          are in ASCII range
--       3: show strings, and quoted characters (only) for any integers 
--          in ASCII range as well as the characters: \t \r \n
--   [2] amount to indent for each level of sequence nesting - default: 2
--   [3] column we are starting at - default: 1
--   [4] approximate column to wrap at - default: 78
--   [5] format to use for integers - default: "%d"
--   [6] format to use for floating-point numbers - default: "%.10g"
--   [7] minimum value for printable ASCII - default 32
--   [8] maximum value for printable ASCII - default 127
--   [9] maximum number of lines to output
-- 
-- If the length is less than 8, unspecified options at 
-- the end of the sequence will keep the default values.    
-- e.g. {0, 5} will choose "never display ASCII", 
-- plus 5-character indentation, with defaults for everything else  
--
-- Comments:
-- The display will start at the current cursor position. Normally you will want to call pretty_print() when the cursor is in column 1 (after printing a \n character). If you want to start in a different column, you should call position() and specify a value for option [3]. This will ensure that the first and last braces in a sequence line up vertically.
--
-- When specifying the format to use for integers and floating-point numbers, you can add some decoration, e.g. "(%d)" or "$ %.2f" 
--
-- Example 1:
-- pretty_print(1, "ABC", {})    
--
-- <console>{65'A',66'B',67'C'}</console>
--
-- Example 2:
-- pretty_print(1, {{1,2,3}, {4,5,6}}, {})  
-- 
-- <console>{
--   {1,2,3},
--   {4,5,6}
-- }</console>
--
-- Example 3:
-- pretty_print(1, {"Euphoria", "Programming", "Language"}, {2})  
--
-- <console>{
--   "Euphoria",
--   "Programming",
--   "Language"
-- }</console>
--
-- Example 4:
-- puts(1, "word_list = ") -- moves cursor to column 13
-- pretty_print(1, 
--              {{"Euphoria", 8, 5.3}, 
--               {"Programming", 11, -2.9}, 
--               {"Language", 8, 9.8}}, 
--              {2, 4, 13, 78, "%03d", "%.3f"}) -- first 6 of 8 options
--
-- word_list = {
--                 {
--                     "Euphoria",
--                     008,
--                     5.300
--                 },
--                 {
--                     "Programming",
--                     011,
--                     -2.900
--                 },
--                 {
--                     "Language",
--                     008,
--                     9.800
--                 }
--             }

global procedure pretty_print(integer fn, object x, sequence options)
	integer n
	
	-- set option defaults 
	pretty_ascii = 1             --[1] 
	pretty_indent = 2            --[2]
	pretty_start_col = 1         --[3]
	pretty_end_col = 78          --[4]
	pretty_int_format = "%d"     --[5]
	pretty_fp_format = "%.10g"   --[6]
	pretty_ascii_min = 32        --[7]
	pretty_ascii_max = 127       --[8] 
			- (platform() = LINUX) -- DEL is a problem with ANSI code display
	pretty_line_max = 1000000000 --[9]
	
	n = length(options)
	if n >= 1 then
		pretty_ascii = options[1] 
		if n >= 2 then
			pretty_indent = options[2]
			if n >= 3 then
				pretty_start_col = options[3]
				if n >= 4 then
					pretty_end_col = options[4]
					if n >= 5 then
						pretty_int_format = options[5]
						if n >= 6 then
							pretty_fp_format = options[6]
							if n >= 7 then
								pretty_ascii_min = options[7]
								if n >= 8 then
									pretty_ascii_max = options[8]
									if n >= 9 then
										pretty_line_max = options[9]
									end if
								end if
							end if
						end if
					end if
				end if
			end if
		end if
	end if  
	
	pretty_chars = pretty_start_col
	pretty_file = fn
	pretty_level = 0 
	pretty_line = ""
	pretty_line_count = 0
	pretty_dots = 0
	rPrint(x)
	puts(pretty_file, pretty_line)
end procedure
--**
