-- regular expressions

include sequence.e

-- TODO:
--   Create a search/replace() function
--   Wrap pcre_free()

constant
		M_COMPILE_PCRE = 68,
		M_EXEC_PCRE    = 69
-- Options:
global constant 
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

-- Error codes:
global constant
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

global type regex(object o)
	return atom(o)
end type

-- Compiles the pattern and returns an atom that represents the regular expression
-- to be used elsewhere.
-- TODO: document
global function new(sequence pattern)
		return machine_func(M_COMPILE_PCRE, pattern)
end function

-- Searches text using the regular expression, re, which was returned from new(), and returns:
--  * No matches:  an atom representing the PCRE error condition
--  * N matches:  an N+1 length sequence.  Each element of the sequence
--                is a pair of indices into text representing the start
--                and end of the substring.  The first element is the 
--                entire match, and subsequent elements are the captured
--                substrings, if any.  An empty substring will be {1,0}.
-- TODO: document
global function search(regex re, sequence text, atom options)
		return machine_func(M_EXEC_PCRE, { re, text, options, 0 })
end function

-- TODO: document
global function search_from(regex re, sequence text, atom options, integer from)
		return machine_func(M_EXEC_PCRE, { re, text, options, from - 1 })
end function

-- TODO: document
global function search_all(regex re, sequence text, atom options)
	object result
	sequence results
	integer from
	
	from = 1
	results = {}
	
	while 1 do
		result = search_from(re, text, options, from)
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

-- TODO: document
global function search_replace(regex re, sequence text, sequence replacement, 
							   atom options)
	sequence matches
	
	matches = search_all(re, text, options)
	for i = length(matches) to 1 by -1 do
		text = replace(text, replacement, matches[i][1][1], matches[i][1][2])
	end for
	
	return text
end function

-- TODO: document
global function search_replace_user(regex re, sequence text, integer rid, 
									atom options)
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

-- TODO: document
global function matches(regex re, sequence text, atom options)
	return sequence(search(re, text, options))
end function

