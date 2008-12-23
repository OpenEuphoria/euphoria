-- (c) Copyright 2007 Rapid Deployment Software - See License.txt
--
-- Euphoria 3.1
-- Miscellaneous routines and constants

-- platform() values:
global constant DOS32 = 1,  -- ex.exe
		WIN32 = 2,  -- exw.exe
		LINUX = 3,  -- exu
		FREEBSD = 3 -- exu

constant M_INSTANCE = 55, M_SLEEP = 64

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

global function reverse(sequence s)
-- reverse the top-level elements of a sequence.
-- Thanks to Hawke' for helping to make this run faster.
    integer lower, n, n2
    sequence t
    
    n = length(s)
    n2 = floor(n/2)+1
    t = repeat(0, n)
    lower = 1
    for upper = n to n2 by -1 do
	t[upper] = s[lower]
	t[lower] = s[upper]
	lower += 1
    end for
    return t
end function

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


global procedure pretty_print(integer fn, object x, sequence options)
-- Print any Euphoria object x, to file fn, in a form that shows 
-- its structure.
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


-- trig formulas provided by Larry Gregg

global constant PI = 3.141592653589793238

constant PI_HALF =  PI / 2.0  -- this is pi/2

type trig_range(object x)
--  values passed to arccos and arcsin must be [-1,+1]
    if atom(x) then
	return x >= -1 and x <= 1
    else
	for i = 1 to length(x) do
	    if not trig_range(x[i]) then
		return 0
	    end if
	end for
	return 1
    end if
end type

global function arccos(trig_range x)
--  returns angle in radians
    return PI_HALF - 2 * arctan(x / (1.0 + sqrt(1.0 - x * x)))
end function

global function arcsin(trig_range x)
--  returns angle in radians
    return 2 * arctan(x / (1.0 + sqrt(1.0 - x * x)))
end function


