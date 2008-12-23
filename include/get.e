-- (c) Copyright 2007 Rapid Deployment Software - See License.txt
--
-- Euphoria 3.1
-- Input and Conversion Routines:
-- get()
-- value()
-- wait_key()

-- error status values returned from get() and value():
global constant GET_SUCCESS = 0,
		GET_EOF = -1,
		GET_FAIL = 1

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

global function wait_key()
-- Get the next key pressed by the user.
-- Wait until a key is pressed.
    return machine_func(M_WAIT_KEY, 0)
end function

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
    end if
end procedure

procedure skip_blanks()
-- skip white space
-- ch is "live" at entry and exit

    while find(ch, " \t\n\r") do
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

function get_number()
-- read a number
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

    skip_blanks()

    if find(ch, START_NUMERIC) then
	return get_number()

    elsif ch = '{' then
	-- process a sequence
	s = {}
	get_ch()
	skip_blanks()
	if ch = '}' then
	    get_ch()
	    return {GET_SUCCESS, s} -- empty sequence
	end if
	
	while TRUE do
	    e = Get() -- read next element
	    if e[1] != GET_SUCCESS then
		return e
	    end if
	    s = append(s, e[2])
	    skip_blanks()
	    if ch = '}' then
		get_ch()
		return {GET_SUCCESS, s}
	    elsif ch != ',' then
		return {GET_FAIL, 0}
	    end if
	    get_ch() -- skip comma
	end while

    elsif ch = '\"' then
	return get_string()

    elsif ch = '\'' then
	return get_qchar()

    elsif ch = -1 then
	return {GET_EOF, 0}

    else
	return {GET_FAIL, 0}

    end if
end function

global function get(integer file)
-- Read the string representation of a Euphoria object 
-- from a file. Convert to the value of the object.
-- Return {error_status, value}.
    input_file = file
    input_string = 0
    get_ch()
    return Get()
end function

global function value(sequence string)
-- Read the representation of a Euphoria object
-- from a sequence of characters. Convert to the value of the object.
-- Return {error_status, value).
    input_string = string
    string_next = 1
    get_ch()
    return Get()
end function

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

constant CHUNK = 100

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


