-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
--****
-- == Text Manipulation
-- **Page Contents**
--
-- <<LEVELTOC depth=2>>
--
-- === Routines

--**
-- Signature:
-- global function sprintf(sequence st, object x)
--
-- Description:
-- This is exactly the same as printf(), except that the output is returned as a sequence 
-- of characters, rather than being sent to a file or device. st is a format string, ##x##
-- is the value or sequence of values to be formatted. ##printf(fn, st, x)## is equivalent 
-- to ##puts(fn, sprintf(st, x))##.
--
-- Comments:
-- Some typical uses of ##sprintf()## are:
--
-- # Converting numbers to strings.
-- # Creating strings to pass to system().
-- # Creating formatted error messages that can be passed to a common error message handler.
--
-- Example 1: 	
-- <eucode>
-- s = sprintf("%08d", 12345)
-- -- s is "00012345"
-- </eucode>
--
-- See Also:
--   [[:printf]], [[:sprint]]

--**
-- The representation of x as a string of characters is returned. This is exactly the same 
-- as print(fn, x), except that the output is returned as a sequence of characters, rather 
-- than being sent to a file or device. x can be any Euphoria object.
--
-- Parameters:
--   # ##x## - Any Euphoria object.
--
-- Returns:
--   ##sequence## - A text representation of ##x##.
--
-- Comments:
-- The atoms contained within x will be displayed to a maximum of 10 significant digits, 
-- just as with print().
--
-- Example 1:
-- <eucode>
-- s = sprint(12345)
-- -- s is "12345"
-- </eucode>
--
-- Example 2: 	
-- <eucode>
-- s = sprint({10,20,30}+5)
-- -- s is "{15,25,35}"
-- </eucode>
--
-- See Also:
--    [[:sprintf]], [[:printf]]

export function sprint(object x)
-- Return the string representation of any Euphoria data object. 
-- This is the same as the output from print(1, x) or '?', but it's
-- returned as a string sequence rather than printed.
	sequence s

	if atom(x) then
		return sprintf("%.10g", x)
	else
		s = "{"
		for i = 1 to length(x) do
			if atom(x[i]) then
				s &= sprintf("%.10g", x[i])
			else
				s &= sprint(x[i])
			end if
			s &= ','
		end for
		if s[$] = ',' then
			s[$] = '}'
		else
			s &= '}'
		end if
		return s
	end if
end function

--**
-- Trim any item in ##what## from the head (start) of ##str##
--
-- Parameters:
--   # ##str## - string to trim.
--   # ##what## - what to trim (defaults to " \t\r\n").
--
-- Returns:
--   ##sequence## - The trimmed version of ##str##
--
-- Example 1:
-- <eucode>
-- s = trim_head("\r\nSentence read from a file\r\n", "\r\n")
-- -- s is "Sentence read from a file\r\n"
-- </eucode>
--
-- See Also:
--   [[:trim_tail]], [[:trim]], [[:pad_head]]

export function trim_head(sequence str, object what=" \t\r\n")
	if atom(what) then
		what = {what}
	end if

	for i = 1 to length(str) do
		if find(str[i], what) = 0 then
			return str[i..$]
		end if
	end for

	return ""
end function

--**
-- Trim any item in ##what## from the end (tail) of ##str##
--
-- Parameters:
--   # ##str## - string to trim.
--   # ##what## - what to trim (defaults to " \t\r\n").
--
-- Returns:
--   ##sequence## - The trimmed version of ##str##
--
-- Example 1:
-- <eucode>
-- s = trim_tail("\r\nSentence read from a file\r\n", "\r\n")
-- -- s is "\r\nSentence read from a file"
-- </eucode>
--
-- See Also:
--   [[:trim_head]], [[:trim]], [[:pad_tail]]

export function trim_tail(sequence str, object what=" \t\r\n")
	if atom(what) then
		what = {what}
	end if

	for i = length(str) to 1 by -1 do
		if find(str[i], what) = 0 then
			return str[1..i]
		end if
	end for

	return ""
end function

--**
-- Trim any item in ##what## from the head (start) and tail (end) of ##str##
--
-- Parameters:
--   # ##str## - string to trim.
--   # ##what## - what to trim (defaults to " \t\r\n").
--
-- Returns:
--   ##sequence## - The trimmed version of ##str##
--
-- Example 1:
-- <eucode>
-- s = trim("\r\nSentence read from a file\r\n", "\r\n")
-- -- s is "Sentence read from a file"
-- </eucode>
--
-- See Also:
--   [[:trim_head]], [[:trim_tail]]

export function trim(sequence str, object what=" \t\r\n")
	return trim_tail(trim_head(str, what), what)
end function

constant TO_LOWER = 'a' - 'A'

--**
-- Convert an atom or sequence to lower case. 
--
-- Parameters:
--   # ##x## - Any Euphoria object.
--
-- Comments:
-- Alters characters in the 'A'..'Z' range. \\
-- **WARNING**, This also effects floating point numbers in the range 65 to 90.
--
-- Returns:
--   ##sequence## - The lowercase version of ##x##
--
-- Example 1:
-- <eucode>
-- s = lower("Euphoria")
-- -- s is "euphoria"
--
-- a = lower('B')
-- -- a is 'b'
--
-- s = lower({"Euphoria", "Programming"})
-- -- s is {"euphoria", "programming"}
-- </eucode>
--
-- See Also:
--   [[:upper]]

export function lower(object x)
-- convert atom or sequence to lower case
	return x + (x >= 'A' and x <= 'Z') * TO_LOWER
end function

--**
-- Convert an atom or sequence to upper case.
--
-- Parameters:
--   # ##x## - Any Euphoria object.
--
-- Comments:
-- Alters characters in the 'a'..'z' range. \\
-- **WARNING**, This also effects floating point numbers in the range 97 to 122.
--
-- Returns:
--   ##sequence## - The uppercase version of ##x##
--
-- Example 1:
-- <eucode>
-- s = upper("Euphoria")
-- -- s is "EUPHORIA"
--
-- a = upper('b')
-- -- a is 'B'
--
-- s = upper({"Euphoria", "Programming"})
-- -- s is {"EUPHORIA", "PROGRAMMING"}
-- </eucode>
--
-- See Also:
--     [[:lower]]

export function upper(object x)
-- convert atom or sequence to upper case
	return x - (x >= 'a' and x <= 'z') * TO_LOWER
end function


--**
-- Converts a string containing Key/Value pairs into a set of 
-- sequences, one per K/V pair.
--
-- By default, pairs can be delimited by either a comma or semi-colon ",;" and
-- a key is delimited from its value by either an equal or a colon "=:". 
-- Whitespace between pairs, and between delimiters is ignored.
--
-- By default, each value must have a key and if you don't supply one, the
-- routine generates a key in the format "p[<n>]" where <n> is the count of
-- K/V pairs so far processed. See example #2.
--
-- If you need to have one of the delimiters in the value data, enclose it in
-- quotation marks. You can use any of single, double and back quotes, which 
-- also means you can quote quotation marks themselves. See example #3.
--
-- It is possible that the value data itself is a nested set of pairs. To do
-- this enclose the value in parentheses. Nested sets can nested to any level.
-- See example #4.
--
-- If a sublist has only data values and not keys, enclose it in either braces
-- or square brackets. See example #5.
-- If you need to have a bracket as the first character in a data value, prefix
-- it with a tilde. Actually a leading tilde will always just be stripped off
-- regardless of what it prefixes. See example #6.
--
-- Parameters:
-- # ##source## - A text sequence, containing the representation of the key/values.
-- # ##pair_delim## - An object containing a list of elements that delimit one
--                   key/value pair from the next. The defaults are semi-colon (;)
--                   and comma (,).
-- # ##kv_delim## - An object containing a list of elements that delimit the
--                key from its value. The defaults are colon (:) and equal (=).
-- # ##quotes## - An object containing a list of elements that can be used to
--                enclose either keys or values that contain delimiters or
--                whitespace. The defaults are double-quote ("), single-quote (')
--                and back-quote (`)
-- # ##whitespace## - An object containing a list of elements that are regarded
--                as whitespace characters. The defaults are space, tab, new-line,
--                and carriage-return.
-- # ##haskeys## An integer containing true or false. The default is true. When
-- ##true##, the ##kv_delimim## values are used to separate keys from values, but
-- when ##false## it is assumed that each 'pair' is actually just a value. 
--
-- Returns:
--
-- Example 1:
-- <eucode>
-- s = keyvalues("foo=bar, qwe=1234, asdf='contains space, comma, and equal(=)'")
-- -- s is { {"foo", "bar"}, {"qwe", "1234"}, {"asdf", "contains space, comma, and equal(=)"}}
-- </eucode>
--
-- Example 2:
-- <eucode>
-- s = keyvalues("abc fgh=ijk def")
-- -- s is { {"p[1]", "abc"}, {"fgh", "ijk"}, {"p[3]", "def"} }
-- </eucode>
--
-- Example 3:
-- <eucode>
-- s = keyvalues("abc=`'quoted'`")
-- -- s is { {"abc", "'quoted'"} }
-- </eucode>
--
-- Example 4:
-- <eucode>
-- s = keyvalues("colors=(a=black, b=blue, c=red)")
-- -- s is { {"colors", {{"a", "black"}, {"b", "blue"},{"c", "red"}}  } }
-- s = keyvalues("colors=(black=[0,0,0], blue=[0,0,FF], red=[FF,0,0])")
-- -- s is { {"colors", {{"black",{"0", "0", "0"}}, {"blue",{"0", "0", "FF"}},{"red", {"FF","0","0"}}}} }
-- </eucode>
--
-- Example 5:
-- <eucode>
-- s = keyvalues("colors=[black, blue, red]")
-- -- s is { {"colors", { "black", "blue", "red"}  } }
-- </eucode>
--
-- Example 6:
-- <eucode>
-- s = keyvalues("colors=~[black, blue, red]")
-- -- s is { {"colors", "[black, blue, red]"}  } }
-- -- The following is another way to do the same.
-- s = keyvalues("colors=`[black, blue, red]`")
-- -- s is { {"colors", "[black, blue, red]"}  } }
-- </eucode>

export function keyvalues(sequence source, object pair_delim = ";,", 
                          object kv_delim = ":=", object quotes =  "\"'`", 
                          object whitespace = " \t\n\r", integer haskeys = 1)
                          
	sequence lKeyValues
	sequence lValue
	sequence lKey
	sequence lAllDelim
	sequence lWhitePair
	sequence lStartBracket
	sequence lEndBracket
	sequence lBracketed
	integer lQuote
	integer lPos
	integer lChar
	integer lBPos
	integer lWasKV

	source = trim(source)
	if length(source) = 0 then
		return {}
	end if
	
	if atom(pair_delim) then
		pair_delim = {pair_delim}
	end if		
	if atom(kv_delim) then
		kv_delim = {kv_delim}
	end if		
	if atom(quotes) then
		quotes = {quotes}
	end if		
	if atom(whitespace) then
		whitespace = {whitespace}
	end if		
	
	lAllDelim = whitespace & pair_delim & kv_delim
	lWhitePair = whitespace & pair_delim
	lStartBracket = "{[("
	lEndBracket   = "}])"
	
	lKeyValues = {}
	lPos = 1
	while lPos <= length(source) do
		-- ignore leading whitespace
		while lPos < length(source) do
			if find(source[lPos], whitespace) = 0 then
				exit
			end if
			lPos +=1 
		end while
		
		-- Get key. Ends at any of unquoted whitespace or unquoted delimiter
		lKey = ""
		lQuote = 0
		lChar = 0
		lWasKV = 0
		if haskeys then
			while lPos <= length(source) do
				lChar = source[lPos]
				if find(lChar, quotes) != 0 then
					if lChar = lQuote then
						-- End of quoted span
						lQuote = 0
						lChar = -1
					elsif lQuote = 0 then
						-- Start of quoted span
						lQuote = lChar
						lChar = -1
					end if
									
				elsif lQuote = 0 and find(lChar, lAllDelim) != 0 then
					exit
					
				end if
				if lChar > 0 then
					lKey &= lChar			
				end if
				lPos += 1
			end while
			
			-- ignore next whitespace
			if find(lChar, whitespace) != 0 then
				lPos += 1
				while lPos <= length(source) do
					lChar = source[lPos]
					if find(lChar, whitespace) = 0 then
						exit
					end if
					lPos +=1 
				end while
			end if
		else
			lPos -= 1	-- Put back the last char.
		end if
						
		lValue = ""
		if find(lChar, kv_delim) != 0  or not haskeys then
		
			if find(lChar, kv_delim) != 0 then
				lWasKV = 1
			end if
			
			-- ignore next whitespace
			lPos += 1
			while lPos <= length(source) do
				lChar = source[lPos]
				if find(lChar, whitespace) = 0 then
					exit
				end if
				lPos +=1 
			end while
			
			-- Get value. Ends at any of unquoted whitespace or unquoted delimiter
			lQuote = 0
			lChar = 0
			lBracketed = {}
			while lPos <= length(source) do
				lChar = source[lPos]
				if length(lBracketed) = 0 and find(lChar, quotes) != 0 then
					if lChar = lQuote then
						-- End of quoted span
						lQuote = 0
						lChar = -1		
					elsif lQuote = 0 then
						-- Start of quoted span
						lQuote = lChar
						lChar = -1		
					end if
				elsif find(lChar, lStartBracket) > 0 then
					lBPos = find(lChar, lStartBracket)
					lBracketed &= lEndBracket[lBPos]
				
				elsif length(lValue) = 1 and lValue[1] = '~' and find(lChar, lStartBracket) > 0 then
					lBPos = find(lChar, lStartBracket)
					lBracketed &= lEndBracket[lBPos]
				
				elsif length(lBracketed) != 0 and lChar = lBracketed[$] then
					lBracketed = lBracketed[1..$-1]
					
				elsif length(lBracketed) = 0 and lQuote = 0 and find(lChar, lWhitePair) != 0 then
					exit
					
				end if
				
				if lChar > 0 then
					lValue &= lChar			
				end if
				lPos += 1
			end while
			
			if find(lChar, whitespace) != 0  then			
				-- ignore next whitespace
				lPos += 1
				while lPos <= length(source) do
					lChar = source[lPos]
					if find(lChar, whitespace) = 0 then
						exit
					end if
					lPos +=1 
				end while
			end if
			
			if find(lChar, pair_delim) != 0  then
				lPos += 1
				if lPos <= length(source) then
					lChar = source[lPos]
				end if
			end if
		end if

		if find(lChar, pair_delim) != 0  then
			lPos += 1
		end if
		
		if length(lValue) = 0 then
			if length(lKey) = 0 then
				lKeyValues = append(lKeyValues, {})
				continue
			end if
			
			if not lWasKV then
				lValue = lKey
				lKey = ""
			end if
		end if
		
		if length(lKey) = 0 then
			if haskeys then			
				lKey =  sprintf("p[%d]", length(lKeyValues) + 1)
			end if
		end if
		
		if length(lValue) > 0 then
			lChar = lValue[1]					
			lBPos = find(lChar, lStartBracket)
			if lBPos > 0 and lValue[$] = lEndBracket[lBPos] then
				if lChar = '(' then
					lValue = keyvalues(lValue[2..$-1], pair_delim, kv_delim, quotes, whitespace, haskeys)
				else
					lValue = keyvalues(lValue[2..$-1], pair_delim, kv_delim, quotes, whitespace, 0)
				end if
			elsif lChar = '~' then	
				lValue = lValue[2 .. $]
			end if
		end if
		
		if length(lKey) = 0 then
			lKeyValues = append(lKeyValues, lValue)
		else
			lKeyValues = append(lKeyValues, {lKey, lValue})
		end if
		
	end while
		
	return lKeyValues
end function

