--****
-- == Pretty Printing
--
-- <<LEVELTOC level=2 depth=4>>
--

namespace pretty

-- pretty print variables
integer pretty_end_col, pretty_chars, pretty_start_col, pretty_level, 
		pretty_file, pretty_ascii, pretty_indent, pretty_ascii_min,
		pretty_ascii_max, pretty_line_count, pretty_line_max, pretty_dots,
		pretty_line_breaks, pretty_printing
sequence pretty_fp_format, pretty_int_format, pretty_line

procedure pretty_out(object text)
-- Output text, keeping track of line length.
-- Buffering lines speeds up Windows console output.
	pretty_line &= text
	if equal(text, '\n') and pretty_printing then
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
	if not pretty_line_breaks then	
		pretty_chars = 0
		return
	end if
	if pretty_chars + n > pretty_end_col then
		pretty_out('\n')
		pretty_chars = 0
	end if
end procedure

procedure indent()
-- indent the display of a sequence
	if pretty_line_breaks = 0 then	
		pretty_chars = 0
		return
	elsif pretty_line_breaks = -1 then
		
		cut_line( 0 )
		
	else
		if pretty_chars > 0 then
			pretty_out('\n')
			pretty_chars = 0
		end if
		pretty_out(repeat(' ', (pretty_start_col-1) + 
								pretty_level * pretty_indent))	
	end if
	
end procedure

function esc_char(integer a)
-- show escaped characters
	switch a do
		case'\t' then
			return `\t`
			
		case'\n' then
			return `\n`
			
		case'\r' then
			return `\r`
			
		case'\\' then
			return `\\`
			
		case'"' then
			return `\"`
			
		case else
			return a
	end switch
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
					
					elsif find(a, "\t\n\r\\") then
						sbuff = '\'' & esc_char(a) & '\''  -- display char only
					
					end if
				else -- pretty ascii 1 or 2
					 -- add display character to number?
					if (a >= pretty_ascii_min and a <= pretty_ascii_max) and pretty_ascii < 2 then
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
				(pretty_ascii < 2 or not find(a[i], "\t\r\n\\"))) or 
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
				pretty_out(esc_char(a[i]))
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

ifdef UNIX then
	public constant PRETTY_DEFAULT = {1, 2, 1, 78, "%d", "%.10g", 32, 126, 1000000000, 1}
elsedef
	public constant PRETTY_DEFAULT = {1, 2, 1, 78, "%d", "%.10g", 32, 127, 1000000000, 1}
end ifdef

public enum
	DISPLAY_ASCII = 1,
	INDENT,
	START_COLUMN,
	WRAP,
	INT_FORMAT,
	FP_FORMAT,
	MIN_ASCII,
	MAX_ASCII,
	MAX_LINES,
	LINE_BREAKS

--****
-- === Routines

procedure pretty( object x, sequence options )
	if length(options) < length( PRETTY_DEFAULT ) then
		options &= PRETTY_DEFAULT[length(options)+1..$]
	end if
	
	-- set options 
	pretty_ascii = options[DISPLAY_ASCII] 
	pretty_indent = options[INDENT]
	pretty_start_col = options[START_COLUMN]
	pretty_end_col = options[WRAP]
	pretty_int_format = options[INT_FORMAT]
	pretty_fp_format = options[FP_FORMAT]
	pretty_ascii_min = options[MIN_ASCII]
	pretty_ascii_max = options[MAX_ASCII]
	pretty_line_max = options[MAX_LINES]
	pretty_line_breaks = options[LINE_BREAKS]
	
	pretty_chars = pretty_start_col
	
	pretty_level = 0 
	pretty_line = ""
	pretty_line_count = 0
	pretty_dots = 0
	rPrint(x)
end procedure

--**
-- prints an object to a file or device using braces ##{ , , , }##, indentation, and multiple lines
-- to show the structure.
--
-- Parameters:
-- # ##fn## : an integer, the file or device number to write to
-- # ##x## : the object to display or convert to printable form
-- # ##options## : is an (up to) 10-element options sequence.
--
-- Comments:
--
--  Pass ##{}## in ##options## to select the defaults, or set options as below:
--   # display ASCII characters:
--     ** 0 ~-- never
--     ** 1 ~-- alongside any integers in printable ASCII range (default)
--     ** 2 ~--  display as "string" when all integers of a sequence
--             are in ASCII range
--     ** 3 ~-- show strings, and quoted characters (only) for any integers
--             in ASCII range as well as the characters: \t \r \n
--   # amount to indent for each level of sequence nesting ~-- default: 2
--   # column we are starting at ~-- default: 1
--   # approximate column to wrap at ~-- default: 78
--   # format to use for integers ~-- default: "%d"
--   # format to use for floating-point numbers ~-- default: "%.10g"
--   # minimum value for printable ASCII ~-- default 32
--   # maximum value for printable ASCII ~-- default 127
--   # maximum number of lines to output 
--   # line breaks between elements   ~-- default 1 (0 = no line breaks, -1 = line breaks to wrap only)
-- 
-- If the length is less than ten, unspecified options at
-- the end of the sequence will keep the default values.    
-- For example: ##{0, 5}## will choose ##"never display ASCII"##,
-- plus 5-character indentation, with defaults for everything else.
--
-- The default options can be applied using the public constant ##PRETTY_DEFAULT##, and the
-- elements may be accessed using the following public enum~:
--
-- # ##DISPLAY_ASCII##
-- # ##INDENT##
-- # ##START_COLUMN##
-- # ##WRAP##
-- # ##INT_FORMAT##
-- # ##FP_FORMAT##
-- # ##MIN_ASCII##
-- # ##MAX_ASCII##
-- # ##MAX_LINES##
-- # ##LINE_BREAKS##
--
-- The display will start at the current cursor position. Normally you will want to call 
-- ##pretty_print## when the cursor is in column 1 (after printing a ##\n## character). 
-- If you want to start in a different column, you should call ##position## and specify a value 
-- for option ##[3]##. This will ensure that the first and last braces in a sequence line up 
-- vertically.
--
-- When specifying the format to use for integers and floating-point numbers, you can add 
-- some decoration. For example: ##"(%d)"## or ##"$ %.2f"## . 
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
--
-- See Also:
-- [[:print]], [[:sprint]], [[:printf]], [[:sprintf]], [[:pretty_sprint]]
--
public procedure pretty_print(integer fn, object x, sequence options = PRETTY_DEFAULT )
	pretty_printing = 1
	pretty_file = fn
	pretty( x, options )
	puts(pretty_file, pretty_line)
end procedure

--**
-- formats an object using braces { , , , }, indentation, and multiple lines to show the structure.
--
-- Parameters:
--   # ##x## : the object to display
--   # ##options## : is an (up to) 10-element options sequence: Pass {} to select the defaults, or
--     set options 
--
-- Returns:
--		A **sequence**, of printable characters, representing ##x## in an human-readable form.
--
-- Comments:
--
--   This function formats objects the same as [[:pretty_print]] but returns the sequence obtained instead of sending it to some file..
--
-- See Also:
--   [[:pretty_print]], [[:sprint]]

public function pretty_sprint(object x, sequence options = PRETTY_DEFAULT )
	pretty_printing = 0
	pretty( x, options )
	return pretty_line
end function
