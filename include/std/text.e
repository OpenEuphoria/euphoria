-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
--****
-- == Text Manipulation
-- **Page Contents**
--
-- <<LEVELTOC depth=2>>
--

--****
-- === Routines

include std/filesys.e
include std/types.e
include std/sequence.e
include std/io.e
include std/search.e
include std/convert.e
include std/serialize.e

--****
-- Signature:
-- <built-in> function sprintf(sequence format, object values)
--
-- Description:
-- This is exactly the same as [[:printf]](), except that the output is returned as a sequence
-- of characters, rather than being sent to a file or device. 
--
-- Parameters:
--		# ##format##: a sequence, the text to print. This text may contain format specifiers.
--		# ##values##: usually, a sequence of values. It should have as many elements as format specifiers in ##format##, as these values will be substituted to the specifiers.
--
-- Returns:
-- A **squence** of printable characters, representing ##format## with the values in ##values## spliced in.
--
-- Comments:
--
-- ##printf(fn, st, x)## is equivalent to ##puts(fn, sprintf(st, x))##.
--
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
-- Returns the representation of any Euphoria object as a string of characters.
--
-- Parameters:
--   # ##x## - Any Euphoria object.
--
-- Returns:
--   A **sequence**, a string representation of ##x##.
--
-- Comments:
--
-- This is exactly the same as ##print(fn, x)##, except that the output is returned as a sequence of characters, rather
-- than being sent to a file or device. x can be any Euphoria object.
--
-- The atoms contained within ##x## will be displayed to a maximum of 10 significant digits,
-- just as with [[:print]]().
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

public function sprint(object x)
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
-- Trim all items in the supplied set from the leftmost (start or head) of a sequence.
--
-- Parameters:
--   # ##source##: the sequence to trim.
--   # ##what##: the set of item to trim from ##source## (defaults to " \t\r\n").
--   # ##ret_index##: If zero (the default) returns the trimmed sequence, otherwise
--                    it returns the index of the leftmost item **not** in ##what##.
--
-- Returns:
--   A **sequence**, if ##ret_index## is zero, which is the trimmed version of ##source##
--   A **integer**, if ##ret_index## is not zero, which is index of the leftmost 
--                  element in ##source## that is not in ##what##.
--
-- Example 1:
-- <eucode>
-- object s
-- s = trim_head("\r\nSentence read from a file\r\n", "\r\n")
-- -- s is "Sentence read from a file\r\n"
-- s = trim_head("\r\nSentence read from a file\r\n", "\r\n", TRUE)
-- -- s is 3
-- </eucode>
--
--
-- See Also:
--   [[:trim_tail]], [[:trim]], [[:pad_head]]

public function trim_head(sequence source, object what=" \t\r\n", integer ret_index = 0)
	integer lpos
	if atom(what) then
		what = {what}
	end if

	lpos = 1
	while lpos <= length(source) do
		if not find(source[lpos], what) then
			exit
		end if
		lpos += 1
	end while
		
	if ret_index then
		return lpos
	else
		return source[lpos .. $]
	end if
end function

--**
-- Trim all items in the supplied set from the rightmost (end or tail) of a sequence.
--
-- Parameters:
--   # ##source##: the sequence to trim.
--   # ##what##: the set of item to trim from ##source## (defaults to " \t\r\n").
--   # ##ret_index##: If zero (the default) returns the trimmed sequence, otherwise
--                    it returns the index of the rightmost item **not** in ##what##.
--
-- Returns:
--   A **sequence**, if ##ret_index## is zero, which is the trimmed version of ##source##
--   A **integer**, if ##ret_index## is not zero, which is index of the rightmost 
--                  element in ##source## that is not in ##what##.
--
-- Example 1:
-- <eucode>
-- object s
-- s = trim_tail("\r\nSentence read from a file\r\n", "\r\n")
-- -- s is "\r\nSentence read from a file"
-- s = trim_tail("\r\nSentence read from a file\r\n", "\r\n", TRUE)
-- -- s is 27
-- </eucode>
--
-- See Also:
--   [[:trim_head]], [[:trim]], [[:pad_tail]]

public function trim_tail(sequence source, object what=" \t\r\n", integer ret_index = 0)
	integer rpos
	
	if atom(what) then
		what = {what}
	end if

	rpos = length(source)
	while rpos > 0 do
		if not find(source[rpos], what) then
			exit
		end if
		rpos -= 1
	end while
		
	if ret_index then
		return rpos
	else
		return source[1..rpos]
	end if
end function

--**
-- Trim all items in the supplied set from both the left end (head/start) and right end (tail/end)
-- of a sequence.
--
-- Parameters:
--   # ##source##: the sequence to trim.
--   # ##what##: the set of item to trim from ##source## (defaults to " \t\r\n").
--   # ##ret_index##: If zero (the default) returns the trimmed sequence, otherwise
--                    it returns a 2-element sequence containing the index of the
--                    leftmost item and rightmost item **not** in ##what##.
--
-- Returns:
--   A **sequence**, if ##ret_index## is zero, which is the trimmed version of ##source##
--   A **2-element sequence**, if ##ret_index## is not zero, in the form {left_index, right_index}.
--
-- Example 1:
-- <eucode>
-- object s
-- s = trim("\r\nSentence read from a file\r\n", "\r\n")
-- -- s is "Sentence read from a file"
-- s = trim("\r\nSentence read from a file\r\n", "\r\n", TRUE)
-- -- s is {3,27}
-- </eucode>
--
-- See Also:
--   [[:trim_head]], [[:trim_tail]]

public function trim(sequence source, object what=" \t\r\n", integer ret_index = 0)
	integer rpos
	integer lpos
	
	if atom(what) then
		what = {what}
	end if

	lpos = 1
	while lpos <= length(source) do
		if not find(source[lpos], what) then
			exit
		end if
		lpos += 1
	end while
	
	rpos = length(source)
	while rpos > lpos do
		if not find(source[rpos], what) then
			exit
		end if
		rpos -= 1
	end while
		
	if ret_index then
		return {lpos, rpos}
	else
		if lpos = 1 then
			if rpos = length(source) then
				return source
			end if
		end if
		if lpos > length(source) then
			return {}
		end if
		return source[lpos..rpos]
	end if
end function


constant TO_LOWER = 'a' - 'A'

sequence lower_case_SET = {}
sequence upper_case_SET = {}
sequence encoding_NAME = "ASCII"

function load_code_page(sequence cpname)
	object cpdata
	integer pos
	sequence kv
	sequence cp_source
	sequence cp_db

	cp_source = defaultext(cpname, ".ecp")
	cp_source = locate_file(cp_source)
	
	cpdata = read_lines(cp_source)
	if sequence(cpdata) then
	
		pos = 0
		while pos < length(cpdata) do
			pos += 1
			cpdata[pos]  = trim(cpdata[pos])
			if begins("--HEAD--", cpdata[pos]) then
				continue
			end if
			if cpdata[pos][1] = ';' then
				continue	-- A comment line
			end if
			if begins("--CASE--", cpdata[pos]) then
				exit
			end if
			
			kv = keyvalues(cpdata[pos],,,,"")
			if equal(lower(kv[1][1]), "title") then
				encoding_NAME = kv[1][2]
			end if
		end while
		if pos > length(cpdata) then
			return -2 -- No Case Conversion table found.
		end if
		
		upper_case_SET = ""
		lower_case_SET = ""
		while pos < length(cpdata) do
			pos += 1
			cpdata[pos]  = trim(cpdata[pos])
			if length(cpdata[pos]) < 3 then
				continue
			end if
			if cpdata[pos][1] = ';' then
				continue	-- A comment line
			end if
			if cpdata[pos][1] = '-' then
				exit
			end if
	
			kv = keyvalues(cpdata[pos])		
			upper_case_SET &= hex_text(kv[1][1])
			lower_case_SET &= hex_text(kv[1][2])
		end while
			
	else
		-- See if its in the database.
		cp_db = locate_file("ecp.dat")
		integer fh = open(cp_db, "rb")
		if fh = -1 then
			return -2 -- Couldn't open DB
		end if
		object idx
		object vers
		vers = deserialize(fh)  -- get the database version
		if vers[1] = 1 then
			idx = deserialize(fh)  -- get Code Page index offset
			pos = seek(fh, idx)
			idx = deserialize(fh)	-- get the Code Page Index
			pos = find(cpname, idx[1])
			if pos != 0 then
				pos = seek(fh, idx[2][pos])
				upper_case_SET = deserialize(fh) -- "uppercase"
				lower_case_SET = deserialize(fh) -- "lowercase"
				encoding_NAME = deserialize(fh) -- "title"
			end if
		end if
		close(fh)
				
	end if
	return 0
end function

--**
-- Sets the table of lowercase and uppercase characters that is used by
-- [[:lower]] and [[:upper]] 
--
-- Parameters:
--   # ##en## - The name of the encoding represented by these character sets
--   # ##lc## - The set of lowercase characters
--   # ##uc## - The set of upper case characters
--
--
-- Comments:
-- * ##lc## and ##uc## must be the same length.
-- * If no parameters are given, the default ASCII table is set.
--
-- Example 1:
-- <eucode>
-- set_encoding_properties( "Elvish", "aeiouy", "AEIOUY")
-- </eucode>
--
-- Example 1:
-- <eucode>
-- set_encoding_properties( "1251") -- Loads a predefined code page.
-- </eucode>
--
-- See Also:
--   [[:lower]], [[:upper]], [[:get_encoding_properties]]

public procedure set_encoding_properties(sequence en = "", sequence lc = "", sequence uc = "")
	integer res
	
	if length(en) > 0 and length(lc) = 0 and length(uc) = 0 then
		res = load_code_page(en)
		if res != 0 then
			printf(2, "Failed to load code page '%s'. Error # %d\n", {en, res})
		end if
		return
	end if
	
	if length(lc) = length(uc) then
		if length(lc) = 0 and length(en) = 0 then
			en = "ASCII"
		end if
		lower_case_SET = lc
		upper_case_SET = uc
		encoding_NAME = en
	end if
end procedure

--**
-- Gets the table of lowercase and uppercase characters that is used by
-- [[:lower]] and [[:upper]] 
--
-- Parameters: none
--
-- Returns: A sequence containing three items.\\
--   {Encoding_Name, LowerCase_Set, UpperCase_Set}
--
-- Example 1:
-- <eucode>
-- encode_sets = get_encoding_properties()
-- </eucode>
--
-- See Also:
--   [[:lower]], [[:upper]], [[:set_encoding_properties]]
public function get_encoding_properties( )
	return {encoding_NAME, lower_case_SET, upper_case_SET}
end function

--**
-- Each character from ##subject## found in ##from_SET## is transformed into the
-- corresponding character in ##to_SET##
--
-- Parameters:
--   # ##subject##: Any Euphoria object to be transformed.
--   # ##from_SET##: A sequence of characters representing the only characters from
--                   ##subect## that are actually transformed.
--   # ##to_SET##: A sequence of characters representing that transformed equivalents
--                 of those found in ##from_SET##.
--
-- Returns:
--   An **object**: The transformed version of ##subject##.
--
-- Example 1:
--   <eucode>
--   res = transform("The Cat in the Hat", "aeiou", "AEIOU")
--   -- res is now "ThE CAt In thE HAt"
--   </eucode>

public function transform(object subject, sequence from_SET, sequence to_SET)
	integer pos

	if atom(subject) then
		pos = find(subject, from_SET)
		if pos != 0 then
			subject = to_SET[pos]
		end if
	else
		for i = 1 to length(subject) do
			if atom(subject[i]) then
				pos = find(subject[i], from_SET)
				if pos != 0 then
					subject[i] = to_SET[pos]
				end if
			else
				subject[i] = transform(subject[i], from_SET, to_SET)
			end if
		end for
	end if
	
	return subject
end function

--**
-- Convert an atom or sequence to lower case. 
--
-- Parameters:
--   # ##x## - Any Euphoria object.
--
-- Returns:
--   A **sequence**, the lowercase version of ##x##
--
-- Comments:
-- * This uses the case conversion tables set in by [[:set_encoding_properties]]
-- * By default, this only works on ASCII characters. It alters characters in
--   the 'a'..'z' range. If you need to do case conversion with other encodings
--   use the [[:set_encoding_properties]] first.
-- * ##x## may be a sequence of any shape, all atoms of which will be acted upon.
--
-- **WARNING**, When using ASCII encoding, this can also affects floating point
-- numbers in the range 65 to 90.
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
--   [[:upper]], [[:proper]], [[:set_encoding_properties]], [[:get_encoding_properties]]

public function lower(object x)
-- convert atom or sequence to lower case
	if length(lower_case_SET) != 0 then
		return transform(x, upper_case_SET, lower_case_SET)
	end if
	return x + (x >= 'A' and x <= 'Z') * TO_LOWER
end function

--**
-- Convert an atom or sequence to upper case.
--
-- Parameters:
--   # ##x## - Any Euphoria object.
--
-- Returns:
--   A **sequence**, the uppercase version of ##x##
--
-- Comments:
-- * This uses the case conversion tables set in by [[:set_encoding_properties]]
-- * By default, this only works on ASCII characters. It alters characters in
--   the 'a'..'z' range. If you need to do case conversion with other encodings
--   use the [[:set_encoding_properties]] first.
-- * ##x## may be a sequence of any shape, all atoms of which will be acted upon.
--
-- **WARNING**, When using ASCII encoding, this can also affects floating point
-- numbers in the range 97 to 122.
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
--     [[:lower]], [[:proper]], [[:set_encoding_properties]], [[:get_encoding_properties]]

public function upper(object x)
-- convert atom or sequence to upper case
	if length(upper_case_SET) != 0 then
		return transform(x, lower_case_SET, upper_case_SET)
	end if
	return x - (x >= 'a' and x <= 'z') * TO_LOWER
end function

--**
-- Convert a text sequence to capitalized words.
--
-- Parameters:
--   # ##x## - A text sequence.
--
-- Returns:
--   A **sequence**, the Capitalized Version of ##x##
--
-- Comments:
-- A text sequence is one in which all elements are either characters or
-- text sequences. This means that if a non-character is found in the input,
-- it is not converted. However this rule only applies to elements on the
-- same level, meaning that sub-sequences could be converted if they are 
-- actually text sequences.
-- 
--
-- Example 1:
-- <eucode>
-- s = proper("euphoria programming language")
-- -- s is "Euphoria Programming Language"
-- s = proper("EUPHORIA PROGRAMMING LANGUAGE")
-- -- s is "Euphoria Programming Language"
-- s = proper({"EUPHORIA PROGRAMMING", "language", "rapid dEPLOYMENT", "sOfTwArE"})
-- -- s is {"Euphoria Programming", "Language", "Rapid Deployment", "Software"}
-- s = proper({'a', 'b', 'c'})
-- -- s is {'A', 'b', c'} -- "Abc"
-- s = proper({'a', 'b', 'c', 3.1472})
-- -- s is {'a', 'b', c', 3.1472} -- Unchanged because it contains a non-character.
-- s = proper({"abc", 3.1472})
-- -- s is {"Abc", 3.1472} -- The embedded text sequence is converted.
-- </eucode>
--
-- See Also:
--     [[:lower]] [[:upper]]

public function proper(sequence x)
-- Converts text to lowercase and makes each word start with an uppercase.
	integer pos
	integer inword
	integer convert
	sequence res
	
	inword = 0	-- Initially not in a word
	convert = 1	-- Initially convert text
	res = x		-- Work on a copy of the original, in case we need to restore.
	for i = 1 to length(res) do
		if integer(res[i]) then
			if convert then
				-- Check for upper case
				pos = t_upper(res[i])
				if pos = 0 then
					-- Not upper, so check for lower case
					pos = t_lower(res[i])
					if pos = 0 then
						-- Not lower so check for digits
						-- n.b. digits have no effect on if its in a word or not.
						pos = t_digit(res[i])
						if pos = 0 then
							-- not digit so check for special word chars
							pos = t_specword(res[i])
							if pos then
								inword = 1
							else
								inword = 0
							end if
						end if
					else
						if inword = 0 then
							-- start of word, so convert only lower to upper.
							if pos <= 26 then
								res[i] = upper(res[i]) -- Convert to uppercase
							end if
							inword = 1	-- now we are in a word
						end if
					end if
				else
					if inword = 1 then
						-- Upper, but as we are in a word convert it to lower.
						res[i] = lower(res[i]) -- Convert to lowercase
					else
						inword = 1	-- now we are in a word
					end if
				end if
			end if
		else
			-- A non-integer means this is NOT a text sequence, so
			-- only convert subsequences.
			if convert then
				-- Restore any values that might have been converted.
				for j = 1 to i-1 do
					if atom(x[j]) then
						res[j] = x[j]
					end if
				end for
				-- Turn conversion off for the rest of this level.
				convert = 0
			end if
			
			if sequence(res[i]) then
				res[i] = proper(res[i])	-- recursive conversion
			end if			
		end if
	end for
	return res
end function

--**
-- Converts a string containing Key/Value pairs into a set of
-- sequences, one per K/V pair.
--
-- Parameters:
-- # ##source##: a text sequence, containing the representation of the key/values.
-- # ##pair_delim##: an object containing a list of elements that delimit one
--                   key/value pair from the next. The defaults are semi-colon (;)
--                   and comma (,).
-- # ##kv_delim##: an object containing a list of elements that delimit the
--                key from its value. The defaults are colon (:) and equal (=).
-- # ##quotes##: an object containing a list of elements that can be used to
--                enclose either keys or values that contain delimiters or
--                whitespace. The defaults are double-quote ("), single-quote (')
--                and back-quote (`)
-- # ##whitespace##: an object containing a list of elements that are regarded
--                as whitespace characters. The defaults are space, tab, new-line,
--                and carriage-return.
-- # ##haskeys##: an integer containing true or false. The default is true. When
-- ##true##, the ##kv_delim## values are used to separate keys from values, but
-- when ##false## it is assumed that each 'pair' is actually just a value. 
--
-- Returns:
-- 		A **sequence** of pairs. Each pair is in the form {key, value}.
--
-- Comments:
--
-- String representations of atoms are not converted, either in the key or value part, but returned as any regular string instead.
--
-- If ##haskeys## is ##true##, but a substring only holds what appears to be a value, the key 
-- is synthesized as ##p[n]##, where ##n## is the number of the pair. See example #2.
--
-- By default, pairs can be delimited by either a comma or semi-colon ",;" and
-- a key is delimited from its value by either an equal or a colon "=:". 
-- Whitespace between pairs, and between delimiters is ignored.
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

public function keyvalues(sequence source, object pair_delim = ";,", 
                          object kv_delim = ":=", object quotes =  "\"'`", 
                          object whitespace = " \t\n\r", integer haskeys = 1)
                          
	sequence lKeyValues
	sequence value_
	sequence key_
	sequence lAllDelim
	sequence lWhitePair
	sequence lStartBracket
	sequence lEndBracket
	sequence lBracketed
	integer lQuote
	integer pos_
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
	pos_ = 1
	while pos_ <= length(source) do
		-- ignore leading whitespace
		while pos_ < length(source) do
			if find(source[pos_], whitespace) = 0 then
				exit
			end if
			pos_ +=1 
		end while

		-- Get key. Ends at any of unquoted whitespace or unquoted delimiter
		key_ = ""
		lQuote = 0
		lChar = 0
		lWasKV = 0
		if haskeys then
			while pos_ <= length(source) do
				lChar = source[pos_]
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
					key_ &= lChar			
				end if
				pos_ += 1
			end while
			
			-- ignore next whitespace
			if find(lChar, whitespace) != 0 then
				pos_ += 1
				while pos_ <= length(source) do
					lChar = source[pos_]
					if find(lChar, whitespace) = 0 then
						exit
					end if
					pos_ +=1 
				end while
			end if
		else
			pos_ -= 1	-- Put back the last char.
		end if
						
		value_ = ""
		if find(lChar, kv_delim) != 0  or not haskeys then
		
			if find(lChar, kv_delim) != 0 then
				lWasKV = 1
			end if
			
			-- ignore next whitespace
			pos_ += 1
			while pos_ <= length(source) do
				lChar = source[pos_]
				if find(lChar, whitespace) = 0 then
					exit
				end if
				pos_ +=1 
			end while
			
			-- Get value. Ends at any of unquoted whitespace or unquoted delimiter
			lQuote = 0
			lChar = 0
			lBracketed = {}
			while pos_ <= length(source) do
				lChar = source[pos_]
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
				
				elsif length(value_) = 1 and value_[1] = '~' and find(lChar, lStartBracket) > 0 then
					lBPos = find(lChar, lStartBracket)
					lBracketed &= lEndBracket[lBPos]
				
				elsif length(lBracketed) != 0 and lChar = lBracketed[$] then
					lBracketed = lBracketed[1..$-1]
					
				elsif length(lBracketed) = 0 and lQuote = 0 and find(lChar, lWhitePair) != 0 then
					exit
					
				end if
				
				if lChar > 0 then
					value_ &= lChar			
				end if
				pos_ += 1
			end while
			
			if find(lChar, whitespace) != 0  then			
				-- ignore next whitespace
				pos_ += 1
				while pos_ <= length(source) do
					lChar = source[pos_]
					if find(lChar, whitespace) = 0 then
						exit
					end if
					pos_ +=1 
				end while
			end if
			
			if find(lChar, pair_delim) != 0  then
				pos_ += 1
				if pos_ <= length(source) then
					lChar = source[pos_]
				end if
			end if
		end if

		if find(lChar, pair_delim) != 0  then
			pos_ += 1
		end if
		
		if length(value_) = 0 then
			if length(key_) = 0 then
				lKeyValues = append(lKeyValues, {})
				continue
			end if
			
			if not lWasKV then
				value_ = key_
				key_ = ""
			end if
		end if
		
		if length(key_) = 0 then
			if haskeys then			
				key_ =  sprintf("p[%d]", length(lKeyValues) + 1)
			end if
		end if
		
		if length(value_) > 0 then
			lChar = value_[1]					
			lBPos = find(lChar, lStartBracket)
			if lBPos > 0 and value_[$] = lEndBracket[lBPos] then
				if lChar = '(' then
					value_ = keyvalues(value_[2..$-1], pair_delim, kv_delim, quotes, whitespace, haskeys)
				else
					value_ = keyvalues(value_[2..$-1], pair_delim, kv_delim, quotes, whitespace, 0)
				end if
			elsif lChar = '~' then	
				value_ = value_[2 .. $]
			end if
		end if
		
		key_ = trim(key_)
		value_ = trim(value_)
		if length(key_) = 0 then
			lKeyValues = append(lKeyValues, value_)
		else
			lKeyValues = append(lKeyValues, {key_, value_})
		end if
		
	end while
		
	return lKeyValues
end function


--**
-- Return a quoted version of the first argument.
--
-- Parameters:
--   # ##text_in##: The string or set of strings to quote.
--   # ##quote_pair##: A sequence of two strings. The first string is the opening
--              quote to use, and the second string is the closing quote to use.
--              The default is {"\"", "\""} which means that the output will be
--              enclosed by double-quotation marks.
--   # ##esc##: A single escape character. If this is not negative (the default), 
--              then this is used to 'escape' any embedded quote characters and 
--              'esc' characters already in the ##text_in## string.
--   # ##sp##: A list of zero or more special characters. The ##text_in## is only
--             quoted if it contains any of the special characters. The default
--             is "" which means that the ##text_in## is always quoted.
--
-- Returns:
--   A **sequence**, the quoted version of ##text_in##.
--
-- Example 1:
-- <eucode>
-- -- Using the defaults. Output enclosed in double-quotes, no escapes and no specials.
-- s = quote("The small man")
-- -- 's' now contains '"the small man"' including the double-quote characters.
-- </eucode>
--
-- Example 2:
-- <eucode>
-- s = quote("The small man", {"(", ")"} )
-- -- 's' now contains '(the small man)'
-- </eucode>
--
-- Example 3:
-- <eucode>
-- s = quote("The (small) man", {"(", ")"}, '~' )
-- -- 's' now contains '(the ~(small~) man)'
-- </eucode>
--
-- Example 4:
-- <eucode>
-- s = quote("The (small) man", {"(", ")"}, '~', "#" )
-- -- 's' now contains 'the (small) man'
-- -- because the input did not contain a '#' character.
-- </eucode>
--
-- Example 5:
-- <eucode>
-- s = quote("The #1 (small) man", {"(", ")"}, '~', "#" )
-- -- 's' now contains '(the #1 ~(small~) man)'
-- -- because the input did contain a '#' character.
-- </eucode>
--
-- Example 6:
-- <eucode>
-- -- input is a set of strings...
-- s = quote({"a b c", "def", "g hi"},)
-- -- 's' now contains three quoted strings: '"a b c"', '"def"', and '"g hi"'
-- </eucode>
public function quote( sequence text_in, object quote_pair = {"\"", "\""}, integer esc = -1, t_text sp = "" )

	if length(text_in) = 0 then
		return text_in
	end if
	
	if atom(quote_pair) then
		quote_pair = {{quote_pair}, {quote_pair}}
	elsif length(quote_pair) = 1 then
		quote_pair = {quote_pair[1], quote_pair[1]}
	elsif length(quote_pair) = 0 then
		quote_pair = {"\"", "\""}
	end if
	
	if sequence(text_in[1]) then
		for i = 1 to length(text_in) do
			if sequence(text_in[i]) then
				text_in[i] = quote(text_in[i], quote_pair, esc, sp)
			end if
		end for
		
		return text_in
	end if
	
	-- Only quote the input if it contains any of the items in 'sp'	
	for i = 1 to length(sp) do
		if find(sp[i], text_in) then
			exit
		end if
		
		if i = length(sp) then
			-- Contains none of them, so just return the input untouched.
			return text_in
		end if
	end for
	
	if esc >= 0  then
		-- If the input already contains a quote, replace them with esc-quote,
		-- but make sure that if the input already contains esc-quote that all
		-- embedded esces are replaced with esc-esc first.
		if atom(quote_pair[1]) then
			quote_pair[1] = {quote_pair[1]}
		end if
		if atom(quote_pair[2]) then
			quote_pair[2] = {quote_pair[2]}
		end if
		
		if equal(quote_pair[1], quote_pair[2]) then
			-- Simple case where both open and close quote are the same.
			if match(quote_pair[1], text_in) then
				if match(esc & quote_pair[1], text_in) then	
					text_in = replace_all(text_in, esc, esc & esc)
				end if
				text_in = replace_all(text_in, quote_pair[1], esc & quote_pair[1])
			end if
		else
			if match(quote_pair[1], text_in) or
			   match(quote_pair[2], text_in) then
				if match(esc & quote_pair[1], text_in) then	
					text_in = replace_all(text_in, esc & quote_pair[1], esc & esc & esc & quote_pair[1])
				end if
				text_in = replace_all(text_in, quote_pair[1], esc & quote_pair[1])
			end if
			
			if match(quote_pair[2], text_in) then
				if match(esc & quote_pair[2], text_in) then	
					text_in = replace_all(text_in, esc & quote_pair[2], esc & esc & esc & quote_pair[2])
				end if
				text_in = replace_all(text_in, quote_pair[2], esc & quote_pair[2])
			end if
		end if
	end if
		
	return quote_pair[1] & text_in & quote_pair[2]

end function

--** 
-- Removes 'quotation' text from the argument.
-- Parameters:
--   # ##text_in##: The string or set of strings to de-quote.
--   # ##quote_pairs##: A set of one or more sub-sequences of two strings. 
--              The first string in each sub-sequence is the opening
--              quote to look for, and the second string is the closing quote.
--              The default is {{"\"", "\""}} which means that the output is
--              'quoted' if it is enclosed by double-quotation marks.
--   # ##esc##: A single escape character. If this is not negative (the default), 
--              then this is used to 'escape' any embedded occurances of the
--              quote characters. In which case the 'escape' character is also
--              removed.
--
-- Returns:
-- A sequence. The original text but with 'quote' strings stripped of quotes.
--
-- Example 1:
-- <eucode>
-- -- Using the defaults. 
-- s = quote("\"The small man\"")
-- -- 's' now contains 'The small man'
-- </eucode>
--
-- Example 2:
-- <eucode>
-- -- Using the defaults. 
-- s = quote("(The small ?(?) man)", {{"[","]"}}, '?')
-- -- 's' now contains 'The small () man'
-- </eucode>
--
public function dequote(object text_in, sequence quote_pairs = {{"\"", "\""}}, integer esc = -1)

	if length(text_in) = 0 then
		return text_in
	end if
	
	if atom(quote_pairs) then
		quote_pairs = {{quote_pairs}, {quote_pairs}}
	elsif length(quote_pairs) = 1 then
		quote_pairs = {quote_pairs[1], quote_pairs[1]}
	elsif length(quote_pairs) = 0 then
		quote_pairs = {"\"", "\""}
	end if
	
	if sequence(text_in[1]) then
		for i = 1 to length(text_in) do
			if sequence(text_in[i]) then
				text_in[i] = dequote(text_in[i], quote_pairs, esc)
			end if
		end for
		
		return text_in
	end if
	
	-- If the text begins and ends with a quote-pair then strip them off and
	-- remove the 'escape' from any 'escaped' quote_pairs within the text.
	for i = 1 to length(quote_pairs) do
		if length(text_in) >= length(quote_pairs[i][1]) + length(quote_pairs[i][2]) then
			if begins(quote_pairs[i][1], text_in) and ends(quote_pairs[i][2], text_in) then
				text_in = text_in[1 + length(quote_pairs[i][1]) .. $ - length(quote_pairs[i][2])]
				integer pos = 1
				while pos > 0 with entry do
					if begins(quote_pairs[i][1], text_in[pos+1 .. $]) then
						text_in = text_in[1 .. pos-1] & text_in[pos + 1 .. $]
					elsif begins(quote_pairs[i][2], text_in[pos+1 .. $]) then
						text_in = text_in[1 .. pos-1] & text_in[pos + 1 .. $]
					else
						pos += 1
					end if
				entry
					pos = find_from(esc, text_in, pos)
				end while
				exit
			end if
		end if
	end for

	return text_in
end function

