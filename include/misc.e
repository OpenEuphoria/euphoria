-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
--****
-- == Misc Routines and Constants
-- === Constants

-- platform() values:

global constant 
	DOS32   = 1, -- ex.exe
	WIN32   = 2, -- exw.exe
	LINUX   = 3, -- exu
	FREEBSD = 3, -- exu
	OSX     = 4  -- exu

constant M_INSTANCE = 55, M_SLEEP = 64

--****
-- === Routines

--**
-- Signature:
-- global procedure print(integer fn, object x)
--
-- Description:
-- Print, to file or device fn, an object x with braces { , , , } to show the structure.
--
-- Example 1:
-- <eucode>
-- print(1, "ABC")  -- output is:  {65, 66, 67}
-- puts(1, "ABC")   -- output is:  ABC
-- </eucode>
--
-- Example 2:
-- <eucode>
-- print(1, repeat({10,20}, 3)) -- output is: {{10,20},{10,20},{10,20}} 
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
-- * ##%%## - print the '%' character itself</li>
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
-- printf(1, "%s", name)     -- error!
-- </eucode>
--
-- This will print only the first character, J, of name, as each element of 
-- name is taken to be a separate value to be formatted. You must say this instead:
-- 	
-- <eucode>
-- name="John Smith"
-- printf(1, "%s", {name})   -- correct
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
-- printf(1, "%15s, %5d\n", {name, score})
--
-- --      John Smith,    97
-- </eucode>
--
-- Example 3:
-- <eucode>
-- printf(1, "%-10.4s $ %s", {"ABCDEFGHIJKLMNOP", "XXX"})
-- --      ABCD       $ XXX
--
-- Example 4:
-- printf(1, "%d  %e  %f  %g", 7.75) -- same value in different formats
--
-- --      7  7.750000e+000  7.750000  7.75
-- </eucode>
--
-- See Also:
--     sequence:sprintf, sequence:sprint
--**

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
-- Remember that if the output file was opened in text mode, <platform>DOS</platform> and 
-- <platform>Windows</platform> will change <code>\n</code> (10) to <code>\r\n</code> 
-- (13 10). Open the file in binary mode if this is not what you want. 
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
global function instance()
-- WIN32: returns hInstance - handle to this instance of the program
-- DOS32: returns 0
	return machine_func(M_INSTANCE, 0)
end function

--*
global procedure sleep(atom t)
-- go to sleep for t seconds
-- allowing (on WIN32 and Linux) other processes to run
	if t >= 0 then
		machine_proc(M_SLEEP, t)
	end if
end procedure

--**
global procedure task_delay(atom delaytime)
-- akin to sleep, but allows other tasks to run while sleeping
--causes a delay while allowing other tasks to run.
	atom t
	t = time()

	while time() - t < delaytime do
		machine_proc(M_SLEEP, 0.01)
		task_yield()
	end while
end procedure

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
-- Print, to file or device fn, an object x, using braces { , , , }, indentation, and multiple lines 
-- to show the structure.
--
-- Parameters:
-- # file number to write to
-- # the object to display
-- # is an (up to) 8-element options sequence: Pass {} to select the defaults, or set options as below:
--   ## display ASCII characters:
--      *** 0: never
--      *** 1: alongside any integers in printable ASCII range (default)
--      *** 2: display as "string" when all integers of a sequence 
--             are in ASCII range
--      *** 3: show strings, and quoted characters (only) for any integers 
--             in ASCII range as well as the characters: \t \r \n
--   ## amount to indent for each level of sequence nesting - default: 2
--   ## column we are starting at - default: 1
--   ## approximate column to wrap at - default: 78
--   ## format to use for integers - default: "%d"
--   ## format to use for floating-point numbers - default: "%.10g"
--   ## minimum value for printable ASCII - default 32
--   ## maximum value for printable ASCII - default 127
--   ## maximum number of lines to output
-- 
-- If the length is less than 8, unspecified options at 
-- the end of the sequence will keep the default values.    
-- e.g. {0, 5} will choose "never display ASCII", 
-- plus 5-character indentation, with defaults for everything else  
--
-- Comments:
-- The display will start at the current cursor position. Normally you will want to call 
-- pretty_print() when the cursor is in column 1 (after printing a <code>\n</code> character). 
-- If you want to start in a different column, you should call position() and specify a value 
-- for option [3]. This will ensure that the first and last braces in a sequence line up 
-- vertically.
--
-- When specifying the format to use for integers and floating-point numbers, you can add 
-- some decoration, e.g. "(%d)" or "$ %.2f" 
--
-- Example 1:
-- <eucode>
-- pretty_print(1, "ABC", {})    
--
-- {65'A',66'B',67'C'}
-- </eucode>
--
-- Example 2:
-- <eucode>
-- pretty_print(1, {{1,2,3}, {4,5,6}}, {})  
-- 
-- {
--   {1,2,3},
--   {4,5,6}
-- }
-- </eucode>
--
-- Example 3:
-- <eucode>
-- pretty_print(1, {"Euphoria", "Programming", "Language"}, {2})  
--
-- {
--   "Euphoria",
--   "Programming",
--   "Language"
-- }
-- </eucode>
--
-- Example 4:
-- <eucode>
-- puts(1, "word_list = ") -- moves cursor to column 13
-- pretty_print(1, 
--     {{"Euphoria", 8, 5.3}, 
--      {"Programming", 11, -2.9}, 
--      {"Language", 8, 9.8}}, 
--      {2, 4, 13, 78, "%03d", "%.3f"}) -- first 6 of 8 options
--
-- word_list = {
--     {
--         "Euphoria",
--         008,
--         5.300
--     },
--     {
--         "Programming",
--         011,
--         -2.900
--     },
--     {
--         "Language",
--         008,
--         9.800
--     }
-- }
-- </eucode>

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

