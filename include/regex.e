-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
-- Regular expression routines

--****
-- == Regular Expressions
-- **Page Contents**
--
-- <<LEVELTOC depth=2>>

include sequence.e

constant
		M_COMPILE_PCRE = 68,
		M_EXEC_PCRE    = 69,
		M_FREE_PCRE    = 70

--****
-- === Constants
--

--****
-- ==== Options
--

export constant 
	DEFAULT            = #00000000,
	CASELESS           = #00000001,
	MULTILINE          = #00000002,
	DOTALL             = #00000004,
	EXTENDED           = #00000008,
	ANCHORED           = #00000010,
	DOLLAR_ENDONLY     = #00000020,
	EXTRA              = #00000040,
	NOTBOL             = #00000080,
	NOTEOL             = #00000100,
	UNGREEDY           = #00000200,
	NOTEMPTY           = #00000400,
	UTF8               = #00000800,
	NO_AUTO_CAPTURE    = #00001000,
	NO_UTF8_CHECK      = #00002000,
	AUTO_CALLOUT       = #00004000,
	PARTIAL            = #00008000,
	DFA_SHORTEST       = #00010000,
	DFA_RESTART        = #00020000,
	FIRSTLINE          = #00040000,
	DUPNAMES           = #00080000,
	NEWLINE_CR         = #00100000,
	NEWLINE_LF         = #00200000,
	NEWLINE_CRLF       = #00300000,
	NEWLINE_ANY        = #00400000,
	NEWLINE_ANYCRLF    = #00500000,
	BSR_ANYCRLF        = #00800000,
	BSR_UNICODE        = #01000000

--****
-- ==== Error Codes
--

export constant
	ERROR_NOMATCH        =  (-1),
	ERROR_NULL           =  (-2),
	ERROR_BADOPTION      =  (-3),
	ERROR_BADMAGIC       =  (-4),
	ERROR_UNKNOWN_OPCODE =  (-5),
	ERROR_UNKNOWN_NODE   =  (-5), -- /* For backward compatibility */
	ERROR_NOMEMORY       =  (-6),
	ERROR_NOSUBSTRING    =  (-7),
	ERROR_MATCHLIMIT     =  (-8),
	ERROR_CALLOUT        =  (-9), -- /* Never used by PCRE itself */
	ERROR_BADUTF8        = (-10),
	ERROR_BADUTF8_OFFSET = (-11),
	ERROR_PARTIAL        = (-12),
	ERROR_BADPARTIAL     = (-13),
	ERROR_INTERNAL       = (-14),
	ERROR_BADCOUNT       = (-15),
	ERROR_DFA_UITEM      = (-16),
	ERROR_DFA_UCOND      = (-17),
	ERROR_DFA_UMLIMIT    = (-18),
	ERROR_DFA_WSSIZE     = (-19),
	ERROR_DFA_RECURSE    = (-20),
	ERROR_RECURSIONLIMIT = (-21),
	ERROR_NULLWSLIMIT    = (-22), -- /* No longer actually used */
	ERROR_BADNEWLINE     = (-23)

--****
-- === Types
--

--**
-- Basically, a ##regex## is an memory address, hence an atom.
export type regex(object o)
	return atom(o)
end type

--****
-- === Routines
-- 

--**
-- Return an allocated regular expression, which must be freed using free() when done.
--
-- Parameters:
--		# ##pattern##: a sequence representing a human readable regular expression
--		# ##flags##: an atom, which may be used to pass options to the processing of ##pattern##. Defaults to 0.
--
-- Returns:
--		A **regex** which other regular expression routines can work on.
--
-- Comments:
--
-- This routine is the only one that accepts a human readable regular expression like "[A-Z_a-z0-9]". The string is compiled and a regex is returned. This is allocated memory and has to be freed when done wih it.
--
-- See the pcre manpages for more details on regular expressions: [[http://www.pcre.org/pcre.txt]]
--
-- Example:
-- <eucode>
-- re = new("foo")
-- </eucode>

export function new(sequence pattern, atom flags=0)
		return machine_func(M_COMPILE_PCRE, {pattern, flags})
end function

--**
-- Returns the first match in text
--
-- Parameters:
--		# ##re##: a regex for a subject to be matched against
--		# ##text##: a string, the sequence inside which matches will be looked for
--		# ##from##: an integer, the point in the string from which to start matching. Defaults to 1.
--		# ##options##: an atom, used to pass options to the match engine. Defaults to 0.
--
-- Returns:
--		An **object**, either an atom when an error occurred or no matc was found, or a sequence. The sequence is made of pairs, described in the Comments below.
--
-- Comments:
-- If any match is found, then a sequence of pairs is returned. Each pair is made of the dtart and end point of a slice of ##text##. The first element represents the whole match.
--
-- If the matched regex has sunstrings, which means some groups are delineated by an opening and closing parenthesis, then each of thiese substrings was matched as well, and the subsequent pairs show where these submatches took place.
--
-- Example 1:
-- <eucode>
-- re = new("foo(bar)")
-- text = "this is foobar"
-- substrings = search( re, text )
-- for i = 1 to length( substrings ) do
--     printf(1, "substring #%d: %s\n", {i, text[substrings[i][1]..substrings[i][2]] } )
-- end for
-- -- substring #1 (full match): foobar
-- -- substring #2 (first sunstring): bar
-- -- no more substrings, so match results stop here.
-- See Also:
--	[[:search_all]]
-- </eucode>

export function search(regex re, sequence text, integer from=1, atom options=0)
		return machine_func(M_EXEC_PCRE, { re, text, options, from-1 })
end function

--**
-- Returns all matches in text
--
-- Parameters:
--		# ##re##: a regex for a subject to be matched against
--		# ##text##: a string, the sequence inside which matches will be looked for
--		# ##from##: an integer, the point in the string from which to start matching. Defaults to 1.
--		# ##options##: an atom, used to pass options to the match engine. Defaults to 0.
--
-- Returns:
--		An **object**, either an atom for no match or some error, or a sequence of match results.
--
-- Comments:
--     When the function returns a sequence, each element is a sequence itself, as described in the Comments: section for [[:search]].
-- See Also:
--	[[:search]]
export function search_all(regex re, sequence text, integer from=1, atom options=0)
	object result
	sequence results
	
	results = {}
	
	while 1 do
		result = search(re, text, from, options)
		if atom(result) then
			exit
		end if
		
		results = append(results, result)
		from = result[1][2] + 1
		if from > length(text) then
			exit
		end if
	end while
	
	return results
end function

--**
--  Replaces all matches of a regex with the replacement text.
--
-- Parameters:
-- 		# ##re##: a regex which iwill be used for matching
--		# ##text##: a string on which search and replace will apply
--		# ##replacement##: a string, used to replace each of the full matches found.
--		# ##options##: an atom, defaulted to 0.
--
-- Returns:
--		A **sequence**, the modified ##text##.
--
--	Comments:
--	Matches may be found against the result of previous replacements. Careful experimentation is highly recommended before doing things like text = regex:search_replace(re,text,whatever,something).

export function search_replace(regex re, sequence text, sequence replacement, 
                               atom options = 0)
	sequence matches
	
	matches = search_all(re, text, options)
	for i = length(matches) to 1 by -1 do
		text = replace(text, replacement, matches[i][1][1], matches[i][1][2])
	end for
	
	return text
end function

--**
-- Performs a search nd replace operation, with the replacement being computed by a user defined routine.
--
-- Parameters:
-- 		# ##re##: a regex which iwill be used for matching
--		# ##text##: a string on which search and replace will apply
--		# ##rid##: an integer, the id of a routine which will determine the replacement string at each step.
--		# ##options##: an atom, defaulted to 0.
--
-- Returns:
--		A **sequence**, the modified ##text##.
--
-- Comments:
-- Whenever a match is found, [[:search_replace]] uses a fixed value as a replacement. OInstead, ##search_replace_user##() will replace slices by actual substrings, and pass the resulting sequence to the function you are required to pass the id of.
--
-- The custom replace function must take one argument, a sequence of strings, and must return a string. This string will be used as the replacement for the given full match.
--
-- Apart from the above, ##search_replace_user##() works like [[:search_replace]].
--
-- The routine is responsible for maintaining any state it requires for proper operation.
--
-- See Also:
-- [[:search_replace]]
export function search_replace_user(regex re, sequence text, integer rid, 
									atom options = 0)
	sequence matches, m
	
	matches = search_all(re, text, options)
	for i = length(matches) to 1 by -1 do
		m = matches[i]
		for a = 1 to length(m)  do
			m[a] = text[m[a][1]..m[a][2]]
		end for
		
		text = replace(text, call_func(rid, {m}), matches[i][1][1], 
					   matches[i][1][2])
	end for
	
	return text
end function

--**
-- Returns 1 if the regex matches anywhere in the text, 0 otherwise.
--
-- Parameters:
--		# ##re##: a regex for a subject to be matched against
--		# ##text##: a string, the sequence inside which matches will be looked for
--		# ##from##: an integer, the point in the string from which to start matching. Defaults to 1.
--		# ##options##: an atom, used to pass options to the match engine. Defaults to 0.
--
-- Returns:
-- 		An **integer**, 0 if no match or some error, 1 if there is any match.
export function matches(regex re, sequence text, integer from=1, atom options = 0)
	return sequence(search(re, text,from,  options))
end function

--**
-- Frees the memory used by regex re, which must have been previously returned by new()
--
-- Parameters:
--		# ##re##: the regex to free.
--
-- Comments:
-- Be sure to use ##regex:free##(), not [[:machine:free]]().
--
-- See Also:
--     [[:new]]

export procedure free( regex re )
	machine_proc( M_FREE_PCRE, re )
end procedure

--**
-- Returns 1 if the regex matches the entire text, 0 otherwise
--
-- Parameters:
--		# ##re##: a regex for a subject to be matched against
--		# ##text##: a string, the sequence inside which matches will be looked for
--		# ##options##: an atom, used to pass options to the match engine. Defaults to 0.
--
-- Returns:
-- 		An **integer**, 0 if no match or some error, 1 if the whole of ##text## matches ##re## using ##options##.
--
-- See Also:
-- [[:matches]]
export function full_match(regex re, sequence text, atom options = 0)
	object matches
	matches = search( re, text, 1, options )
	if sequence( matches ) and matches[1][1] = 1 and matches[1][2] = length(text) then
		return 1
	end if

	return 0
end function
