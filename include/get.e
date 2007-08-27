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
          with trace
function Get()
-- read a Euphoria data object as a string of characters
-- and return {error_flag, value}
-- Note: ch is "live" at entry and exit of this routine
    sequence s, e
    integer e1
            trace(1)
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
            get_ch()
            if ch=-1 then
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

global function value_from(sequence string, natural starting_point)
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

?value("{1,--a\n1}")?machine_func(26,0)