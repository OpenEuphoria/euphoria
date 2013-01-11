--****
-- == Regular Expressions
--
-- <<LEVELTOC level=2 depth=4>>
--
-- === Introduction
--
-- Regular expressions in Euphoria are based on the PCRE (Perl Compatible Regular Expressions)
-- library created by Philip Hazel.
--
-- This document will detail the Euphoria interface to Regular Expressions, not really
-- regular expression syntax. It is a very complex subject that many books have been
-- written on. Here are a few good resources online that can help while learning
-- regular expressions.
--
-- * [[EUForum Article -> http://openeuphoria.org/wiki/euwiki.cgi?EuGuide%20Regular%20Expressions ]]
-- * [[Perl Regular Expressions Man Page -> http://perldoc.perl.org/perlre.html]]
-- * [[Regular Expression Library -> http://regexlib.com/]] (user supplied regular
--   expressions for just about any task).
-- * [[WikiPedia Regular Expression Article -> http://en.wikipedia.org/wiki/Regular_expression]]
-- * [[Man page of PCRE in HTML -> http://www.slabihoud.de/software/archives/pcrecompat.html]]
--
-- === General Use
--
-- Many functions take an optional ##options## argument. This argument can be either
-- a single option constant (see [[:Option Constants]]), multiple option constants or'ed
-- together into a single atom or a sequence of options, in which the function will take
-- care of ensuring the are or'ed together correctly.  Options are like their C equivalents
-- with the 'PCRE_' prefix stripped off.  Name spaces disambiguate symbols so we do not
-- need this prefix.
--
-- All strings passed into this library must be either 8-bit per character strings or
-- UTF which uses multiple bytes to encode UNICODE characters. You can
-- use UTF8 encoded UNICODE strings when you pass the UTF8 option.

namespace regex
include std/types.e
include std/flags.e as flags
include std/machine.e
include std/math.e
include std/search.e
include std/text.e

enum 
	M_PCRE_COMPILE          = 68,
	M_PCRE_EXEC             = 70,
	M_PCRE_REPLACE          = 71,
	M_PCRE_ERROR_MESSAGE    = 95,
	M_PCRE_GET_OVECTOR_SIZE = 97,
	$

--****
-- === Option Constants
--
-- ==== Compile Time and Match Time
--
-- When a regular expression object is created via ##new## we call also say it gets "compiled."
-- The options you may use for this are called "compile time" option constants.  Once
-- the regular expression is created you can use the other functions that take this regular
-- expression and a string.  These routines' options are called "match time" option constants.
-- To not set any options at all, do not supply the options argument or supply [[:DEFAULT]].
--
-- ===== Compile Time Option Constants
--
--     The only options that may set at "compile time" (that is to pass to ##new##)
--     are [[:ANCHORED]], [[:AUTO_CALLOUT]], [[:BSR_ANYCRLF]], [[:BSR_UNICODE]], [[:CASELESS]],
--     [[:DEFAULT]], [[:DOLLAR_ENDONLY]], [[:DOTALL]], [[:DUPNAMES]], [[:EXTENDED]], [[:EXTRA]],
--     [[:FIRSTLINE]], [[:MULTILINE]], [[:NEWLINE_CR]], [[:NEWLINE_LF]], [[:NEWLINE_CRLF]],
--     [[:NEWLINE_ANY]], [[:NEWLINE_ANYCRLF]],  [[:NO_AUTO_CAPTURE]], [[:NO_UTF8_CHECK]],
--     [[:UNGREEDY]], and [[:UTF8]].
--
--
-- ===== Match Time Option Constants
--
--     Options that may be set at "match time" are: [[:ANCHORED]], [[:NEWLINE_CR]], [[:NEWLINE_LF]],
--     [[:NEWLINE_CRLF]], [[:NEWLINE_ANY]] [[:NEWLINE_ANYCRLF]] [[:NOTBOL]], [[:NOTEOL]],
--     [[:NOTEMPTY]], [[:NO_UTF8_CHECK]].  
--
-- Routines that take match time option constants: ##match##,
--     ##split##, or ##replace## a regular expression against some string.
--
--

--****
-- Signature:
-- <eucode>
-- public constant ANCHORED
-- </eucode>
--
-- Description:
-- Forces matches to be only from the first place it is asked to
-- try to make a search.
-- In C, this is called PCRE_ANCHORED.
-- This is passed to all routines including [[:new]].

--****
-- Signature:
-- <eucode>
-- public constant AUTO_CALLOUT
-- </eucode>
--
-- Description:
-- In C, this is called PCRE_AUTO_CALLOUT.
-- To get the functionality of this flag in Euphoria, you can use:
-- [[:find_replace_callback]] without passing this option.
-- This is passed to [[:new]].

--****
-- Signature:
-- <eucode
-- public constant BSR_ANYCRLF
-- </eucode>
--
-- Description:
-- With this option only ASCII new line sequences are recognized as newlines.  Other UNICODE
-- newline sequences (encoded as UTF8) are not recognized as an end of line marker.
-- This is passed to all routines including [[:new]].

--****
-- Signature:
-- <eucode>
-- public constant BSR_UNICODE
-- </eucode>
--
-- Description:
-- With this option any UNICODE new line sequence is recognized as a newline.
-- The UNICODE will have to be encoded as UTF8, however.
-- This is passed to all routines including [[:new]].

--****
-- Signature:
-- <eucode>
-- public constant CASELESS
-- </eucode>
--
-- Description:
-- This will make your regular expression matches case insensitive.  With this
-- flag for example, ##[a-z]## is the same as ##[A-Za-z]##.
-- This is passed to [[:new]].

--****
-- Signature:
-- <eucode>
-- public constant DEFAULT
-- </eucode>
--
-- Description:
-- This is a value used for not setting any flags at all.  This can be passed to
-- all routines including [[:new]]

--****
-- Signature:
-- <eucode>
-- public constant DFA_SHORTEST
-- </eucode>
--
-- Description:
-- This is NOT used by any standard library routine.

--****
-- Signature:
-- <eucode>
-- public constant DFA_RESTART
-- </eucode>
--
-- Description:
-- This is NOT used by any standard library routine.

--****
-- Signature:
-- <eucode>
-- public constant DOLLAR_ENDONLY
-- </eucode>
--
-- Description:
-- If this bit is set, a dollar sign metacharacter in the pattern matches only
-- at the end of the subject string. Without this option,  a  dollar sign  also
-- matches  immediately before a newline at the end of the string (but not
-- before any other newlines). Thus you must include the newline character
-- in the pattern before the dollar sign if you want to match a line that contanis
-- a newline character.
-- The ##DOLLAR_ENDONLY## option  is  ignored if  ##MULTILINE##  is  set.
-- There is no way to set this option within a pattern.
-- This is passed to [[:new]].

--****
-- Signature:
-- <eucode>
-- public constant DOTALL
-- </eucode>
--
-- Description:
-- With this option the '.' character also matches a newline sequence.
-- This is passed to [[:new]].

--****
-- Signature:
-- <eucode>
-- public constant DUPNAMES
-- </eucode>
--
-- Description:
-- Allow duplicate names for named subpatterns.
-- Since there is no way to access named subpatterns this flag has no effect.
-- This is passed to [[:new]].

--****
-- Signature:
-- <eucode>
-- public constant EXTENDED
-- </eucode>
--
-- Description:
-- Whitespace and characters beginning with a hash mark to the end of the line
-- in the pattern will be ignored when searching except when the whitespace or hash
-- is escaped or in a character class.
-- This is passed to [[:new]].

--****
-- Signature:
-- <eucode>
-- public constant EXTRA
-- </eucode>
--
-- Description:
-- When an alphanumeric follows a backslash ( ##\## ) has no special meaning an
-- error is generated.
-- This is passed to [[:new]].

--****
-- Signature:
-- <eucode>
-- public constant FIRSTLINE
-- </eucode>
--
-- Description:
-- If ##PCRE_FIRSTLINE## is set, the match must happen before or at the first
-- newline in the subject (though it may continue over the newline).
-- This is passed to [[:new]].

--****
-- Signature:
-- <eucode>
-- public constant MULTILINE
-- </eucode>
--
-- Description:
-- When  ##MULTILINE##  is set the "start of line" and "end of line"
-- constructs match immediately following or immediately  before  internal
-- newlines  in  the  subject string, respectively, as well as at the very
-- start and end.  This is passed to [[:new]].

--****
-- Signature:
-- <eucode>
-- public constant NEWLINE_CR
-- </eucode>
--
-- Description:
-- Sets CR as the ##NEWLINE## sequence.
-- The ##NEWLINE## sequence will match ##$##
-- when ##MULTILINE## is set.
-- This is passed to all routines including [[:new]].

--****
-- Signature:
-- <eucode>
-- public constant NEWLINE_LF
-- </eucode>
--
-- Description:
-- Sets LF as the ##NEWLINE## sequence.
-- The ##NEWLINE## sequence will match ##$##
-- when ##MULTILINE## is set.
-- This is passed to all routines including [[:new]].

--****
-- Signature:
-- <eucode>
-- public constant NEWLINE_CRLF
-- </eucode>
--
-- Description:
-- Sets ##CRLF## as the ##NEWLINE## sequence
-- The ##NEWLINE## sequence will match ##$##
-- when ##MULTILINE## is set.
-- This is passed to all routines including [[:new]].

--****
-- Signature:
-- <eucode>
-- public constant NEWLINE_ANY
-- </eucode>
--
-- Description:
-- Sets ##ANY## newline sequence as the ##NEWLINE## sequence including
-- those from UNICODE when UTF8 is also set.  The string will have
-- to be encoded as UTF8, however.
-- The ##NEWLINE## sequence will match ##$##
-- when ##MULTILINE## is set.
-- This is passed to all routines including [[:new]].

--****
-- Signature:
-- <eucode>
-- public constant NEWLINE_ANYCRLF
-- </eucode>
--
-- Description:
-- Sets ##ANY## newline sequence from ASCII.
-- The ##NEWLINE## sequence will match ##$##
-- when ##MULTILINE## is set.
-- This is passed to all routines including [[:new]].

--****
-- Signature:
-- <eucode>
-- public constant NOTBOL
-- </eucode>
--
-- Description:
-- This indicates that beginning of the passed string does NOTBOL ( **NOT** start
-- at the **B**eginning **O**f a **L**ine) so a carrot symbol (##^##) in the
-- original pattern will //not match// the beginning of the string.
-- This is used by routines other than [[:new]].

--****
-- Signature:
-- <eucode>
-- public constant NOTEOL
-- </eucode>
--
-- Description:
-- This indicates that end of the passed string does NOTEOL ( **NOT** end
-- at the **E**nd **O**f a **L**ine) so a dollar sign (##$##) in the
-- original pattern will //not match// the end of the string.
-- This is used by routines other than [[:new]].

--****
-- Signature:
-- <eucode>
-- public constant NO_AUTO_CAPTURE
-- </eucode>
--
-- Description:
-- Disables capturing subpatterns except when the subpatterns are
-- named.
-- This is passed to [[:new]].

--****
-- Signature:
-- <eucode>
-- public constant NO_UTF8_CHECK
-- </eucode>
--
-- Description:
-- Turn off checking for the validity of your UTF string.  Use this
-- with caution.  An invalid utf8 string with this option could //crash//
-- your program.  Only use this if you know the string is a valid utf8 string.
-- !!See [[:unicode:validate]].
-- This is passed to all routines including [[:new]].

--****
-- Signature:
-- <eucode>
-- public constant NOTEMPTY
-- </eucode>
--
-- Description:
-- Here matches of empty strings will not be allowed.  In C, this is ##PCRE_NOTEMPTY##.
-- The pattern: ##`A*a*`## will match ##"AAAA"##, ##"aaaa"##, and ##"Aaaa"## but not ##""##.
-- This is used by routines other than [[:new]].

--****
-- Signature:
-- <eucode>
-- public constant PARTIAL
-- </eucode>
--
-- Description:
-- This option has no effect on whether a match will occur or not.
-- However, it does affect the error code generated by [[:find]] in the event of a failure~:
-- If for some pattern ##re##, and two strings ##s1## and ##s2##,
-- ##find( re, s1 & s2 )## would return a match
-- but both ##find( re, s1 )## and ##find( re, s2 )## would not,
-- then ##find( re, s1, 1, PCRE_PARTIAL )##
-- will return ##ERROR_PARTIAL## rather than ##ERROR_NOMATCH##.
-- We say ##s1## has a //partial match// of ##re##.
--
-- Note that ##find( re, s2, 1, PCRE_PARTIAL )## will ##ERROR_NOMATCH##.
-- In C, this constant is called ##PCRE_PARTIAL##.

--****
-- Signature:
-- <eucode>
-- public constant STRING_OFFSETS
-- </eucode>
--
-- Description:
-- This is used by [[:matches]] and [[:all_matches]].

--****
-- Signature:
-- <eucode>
-- public constant UNGREEDY
-- </eucode>
--
-- Description:
-- This is passed to [[:new]].
-- This modifier sets the pattern such that quantifiers are
-- not greedy by default, but become greedy if followed by a question mark.



--****
-- Signature:
-- <eucode>
-- public constant UTF8
-- </eucode>
--
-- Description:
-- Makes strings passed in to be interpreted as a UTF8 encoded string.
-- This is passed to [[:new]].

public constant
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
	BSR_UNICODE        = #01000000,
	STRING_OFFSETS     = #0C000000

constant option_names = {
	{ DEFAULT,         "DEFAULT"         },
	{ CASELESS,        "CASELESS"        },
	{ MULTILINE,       "MULTILINE"       },
	{ DOTALL,          "DOTALL"          },
	{ EXTENDED,        "EXTENDED"        },
	{ ANCHORED,        "ANCHORED"        },
	{ DOLLAR_ENDONLY,  "DOLLAR_ENDONLY"  },
	{ EXTRA,           "EXTRA"           },
	{ NOTBOL,          "NOTBOL"          },
	{ NOTEOL,          "NOTEOL"          },
	{ UNGREEDY,        "UNGREEDY"        },
	{ NOTEMPTY,        "NOTEMPTY"        },
	{ UTF8,            "UTF8"            },
	{ NO_AUTO_CAPTURE, "NO_AUTO_CAPTURE" },
	{ NO_UTF8_CHECK,   "NO_UTF8_CHECK"   },
	{ AUTO_CALLOUT,    "AUTO_CALLOUT"    },
	{ PARTIAL,         "PARTIAL"         },
	{ DFA_SHORTEST,    "DFA_SHORTEST"    },
	{ DFA_RESTART,     "DFA_RESTART"     },
	{ FIRSTLINE,       "FIRSTLINE"       },
	{ DUPNAMES,        "DUPNAMES"        },
	{ NEWLINE_CR,      "NEWLINE_CR"      },
	{ NEWLINE_LF,      "NEWLINE_LF"      },
	{ NEWLINE_CRLF,    "NEWLINE_CRLF"    },
	{ NEWLINE_ANY,     "NEWLINE_ANY"     },
	{ NEWLINE_ANYCRLF, "NEWLINE_ANYCRLF" },
	{ BSR_ANYCRLF,     "BSR_ANYCRLF"     },
	{ BSR_UNICODE,     "BSR_UNICODE"     },
	{ STRING_OFFSETS,  "STRING_OFFSETS"  }
}

--****
-- === Error Constants
-- 
-- Error constants differ from their C equivalents as they do not have ##PCRE_## prepended to each name.
--

public constant
	--** There was no match found.
	ERROR_NOMATCH        =  (-1),
	--** There was an internal error in the EUPHORIA wrapper (std/regex.e in the standard include directory or be_regex.c in the EUPHORIA source).
	ERROR_NULL           =  (-2),
	--** There was an internal error in the EUPHORIA wrapper (std/regex.e in the standard include directory or be_regex.c in the EUPHORIA source).
	ERROR_BADOPTION      =  (-3),
	--** The pattern passed is not a value returned from [[:new]].
	ERROR_BADMAGIC       =  (-4),
	--** An internal error either in the pcre library EUPHORIA uses or its wrapper occured.
	ERROR_UNKNOWN_OPCODE =  (-5),
	--** An internal error either in the pcre library EUPHORIA uses or its wrapper occured.
	ERROR_UNKNOWN_NODE   =  (-5),
	--** Out of memory.
	ERROR_NOMEMORY       =  (-6),
	--** The wrapper or the PCRE backend did not preallocate enough capturing groups for this pattern.
	ERROR_NOSUBSTRING    =  (-7),
	--** Too many matches encountered.
	ERROR_MATCHLIMIT     =  (-8),
	--** Not applicable to our implementation.
	ERROR_CALLOUT        =  (-9),
	--** The subject or pattern is not valid UTF8 but it was specified as such with [[:UTF8]].
	ERROR_BADUTF8        = (-10),
	--** The offset specified does not start on a UTF8 character boundary but it was specified as UTF8 with [[:UTF8]].
	ERROR_BADUTF8_OFFSET = (-11),
	--** Pattern didn't match, but there is a //partial match//.  See [[:PARTIAL]].
	ERROR_PARTIAL        = (-12),
	--** PCRE backend doesn't support partial matching for this pattern.
	ERROR_BADPARTIAL     = (-13),
	ERROR_INTERNAL       = (-14),
	--** size parameter to find is less than minus 1.
	ERROR_BADCOUNT       = (-15),
	--** Not applicable to our implementation: The PCRE wrapper doesn't use DFA routines
	ERROR_DFA_UITEM      = (-16),
	--** Not applicable to our implementation: The PCRE wrapper doesn't use DFA routines
	ERROR_DFA_UCOND      = (-17),
	--** Not applicable to our implementation: The PCRE wrapper doesn't use DFA routines
	ERROR_DFA_UMLIMIT    = (-18),
	--** Not applicable to our implementation: The PCRE wrapper doesn't use DFA routines
	ERROR_DFA_WSSIZE     = (-19),
	--** Not applicable to our implementation: The PCRE wrapper doesn't use DFA routines
	ERROR_DFA_RECURSE    = (-20),
	--** Too much recursion used for match.
	ERROR_RECURSIONLIMIT = (-21),
	--** This error isn't in the source code.
	ERROR_NULLWSLIMIT    = (-22),
	--** Both BSR_UNICODE and BSR_ANY options were specified.  These options are contradictory.
	ERROR_BADNEWLINE     = (-23)

public constant error_names = {
	{ERROR_NOMATCH,        "ERROR_NOMATCH"             },
	{ERROR_NULL,           "ERROR_NULL"                },
	{ERROR_BADOPTION,      "ERROR_BADOPTION"           },
	{ERROR_BADMAGIC,       "ERROR_BADMAGIC"            },
	{ERROR_UNKNOWN_OPCODE, "ERROR_UNKNOWN_OPCODE/NODE" },
	{ERROR_UNKNOWN_NODE,   "ERROR_UNKNOWN_OPCODE/NODE" },
	{ERROR_NOMEMORY,       "ERROR_NOMEMORY"            },
	{ERROR_NOSUBSTRING,    "ERROR_NOSUBSTRING"         },
	{ERROR_MATCHLIMIT,     "ERROR_MATCHLIMIT"          },
	{ERROR_CALLOUT,        "ERROR_CALLOUT"             },
	{ERROR_BADUTF8,        "ERROR_BADUTF8"             },
	{ERROR_BADUTF8_OFFSET, "ERROR_BADUTF8_OFFSET"      },
	{ERROR_PARTIAL,        "ERROR_PARTIAL"             },
	{ERROR_BADPARTIAL,     "ERROR_BADPARTIAL"          },
	{ERROR_INTERNAL,       "ERROR_INTERNAL"            },
	{ERROR_BADCOUNT,       "ERROR_BADCOUNT"            },
	{ERROR_DFA_UITEM,      "ERROR_DFA_UITEM"           },
	{ERROR_DFA_UCOND,      "ERROR_DFA_UCOND"           },
	{ERROR_DFA_UMLIMIT,    "ERROR_DFA_UMLIMIT"         },
	{ERROR_DFA_WSSIZE,     "ERROR_DFA_WSSIZE"          },
	{ERROR_DFA_RECURSE,    "ERROR_DFA_RECURSE"         },
	{ERROR_RECURSIONLIMIT, "ERROR_RECURSIONLIMIT"      },
	{ERROR_NULLWSLIMIT,    "ERROR_NULLWSLIMIT"         },
	{ERROR_BADNEWLINE,     "ERROR_BADNEWLINE"          }
}

constant all_options = math:or_all({
	DEFAULT,
	CASELESS,
	MULTILINE,
	DOTALL,
	EXTENDED,
	ANCHORED,
	DOLLAR_ENDONLY,
	EXTRA,
	NOTBOL,
	NOTEOL,
	UNGREEDY,
	NOTEMPTY,
	UTF8,
	NO_AUTO_CAPTURE,
	NO_UTF8_CHECK,
	AUTO_CALLOUT,
	PARTIAL,
	DFA_SHORTEST,
	DFA_RESTART,
	FIRSTLINE,
	DUPNAMES,
	NEWLINE_CR,
	NEWLINE_LF,
	NEWLINE_CRLF,
	NEWLINE_ANY,
	NEWLINE_ANYCRLF,
	BSR_ANYCRLF,
	BSR_UNICODE,
	STRING_OFFSETS
})

--****
-- === Create and Destroy

--**
-- Regular expression type

public type regex(object o)
	return sequence(o)
end type

--**
-- Regular expression option specification type
--
-- Although the functions do not use this type (they return an error instead),
-- you can use this to check if your routine is receiving something sane.

public type option_spec(object o)
	if atom(o) then
		if not integer(o) then
			return 0
		else
			if (or_bits(o,all_options) != all_options) then
				return 0
			else
				return 1
			end if
		end if
	elsif integer_array(o) then
		return option_spec( math:or_all(o) )
	else
		return 0
	end if
end type

--**
-- converts an option spec to a string.
--
-- This can be useful for debugging what options were passed in.
-- Without it you have to convert a number to hex and lookup the
-- constants in the source code.

public function option_spec_to_string(option_spec o)
	return flags:flags_to_string(o, option_names)
end function

--**
-- converts an regex error to a string.
--
-- This can be useful for debugging and even something rough to give to
-- the user incase of a regex failure.  It is preferable to
-- a number.
--
-- See Also:
-- [[:error_message]]

public function error_to_string(integer i)
	if i >= 0 or i < -23 then
		return sprintf("%d",{i})
	else
		return search:vlookup(i, error_names, 1, 2, "Unknown Error")
	end if
end function

--**
-- returns an allocated regular expression.
--
-- Parameters:
--   # ##pattern## : a sequence representing a human readable regular expression
--   # ##options## : defaults to [[:DEFAULT]]. See [[:Compile Time Option Constants]].
--
-- Returns:
--   A **regex**, which other regular expression routines can work on or an atom to indicate an
--   error. If an error, you can call [[:error_message]] to get a detailed error message.
--
-- Comments:
--   This is the only routine that accepts a human readable regular expression. The string is
--   compiled and a [[:regex]] is returned. Analyzing and compiling a regular expression is a
--   costly operation and should not be done more than necessary. For instance, if your application
--   looks for an email address among text frequently, you should create the regular expression
--   as a constant accessible to your source code and any files that may use it, thus, the regular
--   expression is analyzed and compiled only once per run of your application.
--
--   <eucode>
--   -- Bad Example
--   include std/regex.e as re
--
--   while sequence(line) do
--       re:regex proper_name = re:new("[A-Z][a-z]+ [A-Z][a-z]+")
--       if re:find(proper_name, line) then
--           -- code
--       end if
--   end while
--   </eucode>
--
--   <eucode>
--   -- Good Example
--   include std/regex.e as re
--   constant re_proper_name = re:new("[A-Z][a-z]+ [A-Z][a-z]+")
--   while sequence(line) do
--       if re:find(re_proper_name, line) then
--           -- code
--       end if
--   end while
--   </eucode>
--
-- Example 1:
--   <eucode>
--   include std/regex.e as re
--   re:regex number = re:new("[0-9]+")
--   </eucode>
--
-- Note:
--   For simple matches, the built-in Euphoria
--   routine [[:eu:match]] and the library routine [[:wildcard:is_match]]
--   are often times easier to use and
--   a little faster. Regular expressions are faster for complex searching/matching.
--
-- See Also:
--   [[:error_message]], [[:find]], [[:find_all]]

public function new(string pattern, option_spec options=DEFAULT)
	if sequence(options) then 
		options = math:or_all(options) 
	end if
		
	-- concatenation ensures we really get a new sequence, and don't just use the
	-- one passed in, which could be another regex previously created...this may
	-- be a bug with the refcount/delete_instance/regex code
	return machine_func(M_PCRE_COMPILE, { pattern, options })
end function

--**
-- returns a text based error message.
--
-- Parameters:
--   # ##re##: Regular expression to get the error message from
--
-- Returns:
--   An atom (0) when no error message exists, otherwise a sequence describing the error.
--
-- Comments:
-- If ##[[:new]]## returns an atom, this function will return a text error message
-- as to the reason.
--
-- Example 1:
-- <eucode>
-- include std/regex.e
-- object r = regex:new("[A-Z[a-z]*")
-- if atom(r) then
--   printf(1, "Regex failed to compile: %s\n", { regex:error_message(r) })
-- end if
-- </eucode>
--

public function error_message(object re)
	return machine_func(M_PCRE_ERROR_MESSAGE, { re })
end function

--****
-- === Utility Routines
--

--**
-- escapes special regular expression characters that may be entered into a search
-- string from user input.
--
-- Parameters:
--   # ##s##: string sequence to escape
--
-- Returns:
--   An escaped ##sequence## representing ##s##.
--
-- Note:
--   Special regex characters are~:
--       {{{
--   . \ + * ? [ ^ ] $ ( ) { } = ! < > | : -
--       }}}
--
-- Example 1:
-- <eucode>
-- include std/regex.e as re
-- sequence search_s = re:escape("Payroll is $***15.00")
-- -- search_s = "Payroll is \\$\\*\\*\\*15\\.00"
-- </eucode>
--

public function escape(string s)
	return text:escape(s, ".\\+*?[^]$(){}=!<>|:-")
end function

--**
-- returns the number of capturing subpatterns (the ovector size) for a regex.
--
-- Parameters:
--   # ##ex## : a regex
--   # ##maxsize## : optional maximum number of named groups to get data from
--
-- Returns:
--   An **integer**
--

public function get_ovector_size(regex ex, integer maxsize=0)
	integer m = machine_func(M_PCRE_GET_OVECTOR_SIZE, {ex})
	if (m > maxsize) then
		return maxsize
	end if
	
	return m+1
end function

--****
-- === Match

--**
-- returns the first match of ##re## in ##haystack##. You can optionally start at the position
-- ##from##.
--
-- Parameters:
--   # ##re## : a regex for a subject to be matched against
--   # ##haystack## : a string in which to searched
--   # ##from## : an integer setting the starting position to begin searching from. Defaults to 1
--   # ##options## : defaults to [[:DEFAULT]]. See [[:Match Time Option Constants]].
--     The only options that
--     may be set when calling find are [[:ANCHORED]], [[:NEWLINE_CR]], [[:NEWLINE_LF]],
--     [[:NEWLINE_CRLF]], [[:NEWLINE_ANY]] [[:NEWLINE_ANYCRLF]] [[:NOTBOL]], [[:NOTEOL]],
--     [[:NOTEMPTY]], and [[:NO_UTF8_CHECK]].
--     ##options## can be any match time option or a
--     sequence of valid options or it can be a value that comes from using or_bits on
--     any two valid option values.
--   # ##size## : internal (how large an array the C backend should allocate). Defaults to 90, in 
--        rare cases this number may need to be increased in order to accomodate complex regex 
--        expressions.
--
-- Returns:
--   An **object**, which is either an atom of 0, meaning nothing matched or a sequence of 
--   index pairs.  These index pairs may be fewer than the number of groups specified.  These
--   index pairs may be the invalid index pair ##{0,0}##.
--
--   The first pair is the starting and ending indeces of the sub-string that matches the 
--   expression.  This pair may be followed by indeces of the groups.  The groups are 
--   subexpressions in the regular expression surrounded by parenthesis ().  
--
--   Now, it is possible to get a match without having all of the groups match.
--   This can happen when there is a quantifier after a group.  For example: ##'([01])*'## or ##'([01])?'##.
--   In this case, the returned sequence of pairs will be missing the last group indeces for
--   which there is no match.   
--   However, if the missing group is followed by a group that *does* match, ##{0,0}## will be 
--   used as a place holder.
--   You can ensure your groups match when your expression matches by keeping quantifiers 
--   inside your groups~: 
--   For example use: ##'([01]?)'## instead of ##'([01])?'##
--
--
--
-- Example 1:
--   <eucode>
--   include std/regex.e as re
--   r = re:new("([A-Za-z]+) ([0-9]+)") -- John 20 or Jane 45
--   object result = re:find(r, "John 20")
--
--   -- The return value will be:
--   -- {
--   --    { 1, 7 }, -- Total match
--   --    { 1, 4 }, -- First grouping "John" ([A-Za-z]+)
--   --    { 6, 7 }  -- Second grouping "20" ([0-9]+)
--   -- }
--   </eucode>
--

public function find(regex re, string haystack, integer from=1, option_spec options=DEFAULT, integer size = get_ovector_size(re, 30))
	if sequence(options) then 
		options = math:or_all(options) 
	end if
	
	if size < 0 then
		size = 0
	end if

	return machine_func(M_PCRE_EXEC, { re, haystack, length(haystack), options, from, size })
end function

--**
-- returns all matches of ##re## in ##haystack## optionally starting at the sequence position
-- ##from##.
--
-- Parameters:
--   # ##re## : a regex for a subject to be matched against
--   # ##haystack## : a string in which to searched
--   # ##from## : an integer setting the starting position to begin searching from. Defaults to 1
--   # ##options## : defaults to [[:DEFAULT]]. See [[:Match Time Option Constants]].
--
-- Returns:
--   A **sequence** of **sequences** that were returned by [[:find]] and in the case of
--   no matches this returns an empty **sequence**.
--
-- Comments:
--   Please see [[:find]] for a detailed description of each member of the return
--   sequence.
--
-- Example 1:
--   <eucode>
--   include std/regex.e as re
--   constant re_number = re:new("[0-9]+")
--   object matches = re:find_all(re_number, "10 20 30")
--
--   -- matches is:
--   -- {
--   --     {{1, 2}},
--   --     {{4, 5}},
--   --     {{7, 8}}
--   -- }
--   </eucode>
--

public function find_all(regex re, string haystack, integer from=1, option_spec options=DEFAULT, integer size = get_ovector_size(re, 30))
	if sequence(options) then 
		options = math:or_all(options) 
	end if
	
	if size < 0 then
		size = 0
	end if
	
	object result
	sequence results = {}
	atom pHaystack = machine:allocate_string(haystack)
	while sequence(result) with entry do
		results = append(results, result)
		from = math:max(result) + 1
		
		if from > length(haystack) then
			exit
		end if
	entry
		result = machine_func(M_PCRE_EXEC, { re, pHaystack, length(haystack), options, from, size })
	end while
	
	machine:free(pHaystack)
	
	return results
end function

--**
-- determines if ##re## matches any portion of ##haystack##.
--
-- Parameters:
--   # ##re## : a regex for a subject to be matched against
--   # ##haystack## : a string in which to searched
--   # ##from## : an integer setting the starting position to begin searching from. Defaults to 1
--   # ##options## : defaults to [[:DEFAULT]]. See [[:Match Time Option Constants]].
--     ##options## can be any match time option or a
--     sequence of valid options or it can be a value that comes from using or_bits on
--     any two valid option values.
--
-- Returns:
--   An **atom**, 1 if ##re## matches any portion of ##haystack## or 0 if not.
--

public function has_match(regex re, string haystack, integer from=1, option_spec options=DEFAULT)
	return sequence(find(re, haystack, from, options))
end function

--**
-- determines if the entire ##haystack## matches ##re##.
--
-- Parameters:
--   # ##re## : a regex for a subject to be matched against
--   # ##haystack## : a string in which to searched
--   # ##from## : an integer setting the starting position to begin searching from. Defaults to 1
--   # ##options## : defaults to [[:DEFAULT]].  See [[:Match Time Option Constants]].
--     ##options## can be any match time option or a
--     sequence of valid options or it can be a value that comes from using or_bits on
--     any two valid option values.
--
-- Returns:
--   An **atom**,  1 if ##re## matches the entire ##haystack## or 0 if not.
--

public function is_match(regex re, string haystack, integer from=1, option_spec options=DEFAULT)
	object m = find(re, haystack, from, options)
	
	if sequence(m) and length(m) > 0 and m[1][1] = from and m[1][2] = length(haystack) then
		return 1
	end if
	
	return 0
end function

--**
-- gets the matched text only.
--
-- Parameters:
--   # ##re## : a regex for a subject to be matched against
--   # ##haystack## : a string in which to searched
--   # ##from## : an integer setting the starting position to begin searching from. Defaults to 1
--   # ##options## : defaults to [[:DEFAULT]]. See [[:Match Time Option Constants]].
--     ##options## can be any match time option or STRING_OFFSETS or a
--     sequence of valid options or it can be a value that comes from using or_bits on
--     any two valid option values.
--
-- Returns:
--   Returns a **sequence** of strings, the first being the entire match and subsequent
--   items being each of the captured groups or **ERROR_NOMATCH** of there is no match.
--   The size of the sequence is the number
--   of groups in the expression plus one (for the entire match).
--
--   If ##options## contains the bit [[:STRING_OFFSETS]], then the result is different.
--   For each item, a sequence is returned containing the matched text, the starting
--   index in ##haystack## and the ending index in ##haystack##.
--
-- Example 1:
--   <eucode>
--   include std/regex.e as re
--   constant re_name = re:new("([A-Z][a-z]+) ([A-Z][a-z]+)")
--
--   object matches = re:matches(re_name, "John Doe and Jane Doe")
--   -- matches is:
--   -- {
--   --   "John Doe", -- full match data
--   --   "John",     -- first group
--   --   "Doe"       -- second group
--   -- }
--
--   matches = re:matches(re_name, "John Doe and Jane Doe", 1, re:STRING_OFFSETS)
--   -- matches is:
--   -- {
--   --   { "John Doe", 1, 8 }, -- full match data
--   --   { "John",     1, 4 }, -- first group
--   --   { "Doe",      6, 8 }  -- second group
--   -- }
--   </eucode>
--
-- See Also:
--   [[:all_matches]]
--
public function matches(regex re, string haystack, integer from=1, option_spec options=DEFAULT)
	if sequence(options) then 
		options = math:or_all(options) 
	end if
	integer str_offsets = and_bits(STRING_OFFSETS, options)
	object match_data = find(re, haystack, from, and_bits(options, not_bits(STRING_OFFSETS)))
	
	if atom(match_data) then 
		return ERROR_NOMATCH 
	end if
			
	for i = 1 to length(match_data) do
		sequence tmp
		if match_data[i][1] = 0 then
			tmp = ""
		else
			tmp = haystack[match_data[i][1]..match_data[i][2]]
		end if
		if str_offsets then
			match_data[i] = { tmp, match_data[i][1], match_data[i][2] }
		else
			match_data[i] = tmp
		end if
	end for
	
	return match_data
end function

--**
-- gets the text of all matches.
--
-- Parameters:
--   # ##re## : a regex for a subject to be matched against
--   # ##haystack## : a string in which to searched
--   # ##from## : an integer setting the starting position to begin searching from. Defaults to 1
--   # ##options## : options, defaults to [[:DEFAULT]].  See [[:Match Time Option Constants]].
--     ##options## can be any match time option or a
--     sequence of valid options or it can be a value that comes from using or_bits on
--     any two valid option values.
--
-- Returns:
--   Returns **ERROR_NOMATCH** if there are no matches, or a **sequence** of **sequences** of
--   **strings** if there is at least one match. In each member sequence of the returned sequence,
--   the first string is the entire match and subsequent items being each of the
--   captured groups.  The size of the sequence is
--   the number of groups in the expression plus one (for the entire match).  In other words,
--   each member of the return value will be of the same structure of that is returned by
--   [[:matches]].
--
--   If ##options## contains the bit [[:STRING_OFFSETS]], then the result is different.
--   In each member sequence, instead of each member being a string each member is itself a sequence
--   containing the matched text, the starting index in ##haystack## and the ending
--   index in ##haystack##.
--
-- Example 1:
--   <eucode>
--   include std/regex.e as re
--   constant re_name = re:new("([A-Z][a-z]+) ([A-Z][a-z]+)")
--
--   object matches = re:all_matches(re_name, "John Doe and Jane Doe")
--   -- matches is:
--   -- {
--   --   {             -- first match
--   --     "John Doe", -- full match data
--   --     "John",     -- first group
--   --     "Doe"       -- second group
--   --   },
--   --   {             -- second match
--   --     "Jane Doe", -- full match data
--   --     "Jane",     -- first group
--   --     "Doe"       -- second group
--   --   }
--   -- }
--
--   matches = re:all_matches(re_name, "John Doe and Jane Doe", , re:STRING_OFFSETS)
--   -- matches is:
--   -- {
--   --   {                         -- first match
--   --     { "John Doe",  1,  8 }, -- full match data
--   --     { "John",      1,  4 }, -- first group
--   --     { "Doe",       6,  8 }  -- second group
--   --   },
--   --   {                         -- second match
--   --     { "Jane Doe", 14, 21 }, -- full match data
--   --     { "Jane",     14, 17 }, -- first group
--   --     { "Doe",      19, 21 }  -- second group
--   --   }
--   -- }
--   </eucode>
--
-- See Also:
--   [[:matches]]

public function all_matches(regex re, string haystack, integer from=1, option_spec options=DEFAULT)
	if sequence(options) then 
		options = math:or_all(options) 
	end if
	integer str_offsets = and_bits(STRING_OFFSETS, options)
	object match_data = find_all(re, haystack, from, and_bits(options, not_bits(STRING_OFFSETS)))
	
	if length(match_data) = 0 then 
		return ERROR_NOMATCH 
	end if
		
	for i = 1 to length(match_data) do
		for j = 1 to length(match_data[i]) do
			sequence tmp
			integer a,b
			a = match_data[i][j][1]
			if a = 0 then
				tmp = ""
			else
				b = match_data[i][j][2]
				tmp = haystack[a..b]
			end if
			if str_offsets then
				match_data[i][j] = { tmp, a, b }
			else
				match_data[i][j] = tmp
			end if
		end for
	end for

	return match_data
end function

--****
-- === Splitting

--**
-- splits a string based on a regex as a delimiter.
--
-- Parameters:
--   # ##re## : a regex which will be used for matching
--   # ##text## : a string on which search and replace will apply
--   # ##from## : optional start position
--   # ##options## : options, defaults to [[:DEFAULT]]. See [[:Match Time Option Constants]].
--     ##options## can be any match time option or a
--     sequence of valid options or it can be a value that comes from using or_bits on
--     any two valid option values.
--
-- Returns:
--   A **sequence** of string values split at the delimiter and if no delimiters were matched
-- this **sequence** will be a one member sequence equal to ##{text}##.
--
-- Example 1:
-- <eucode>
-- include std/regex.e as re
-- regex comma_space_re = re:new(`,\s`)
-- sequence data = re:split(comma_space_re, 
--                          "euphoria programming, source code, reference data")
-- -- data is
-- -- {
-- --   "euphoria programming",
-- --   "source code",
-- --   "reference data"
-- -- }
-- </eucode>
--

public function split(regex re, string text, integer from=1, option_spec options=DEFAULT)
	return split_limit(re, text, 0, from, options)
end function

public function split_limit(regex re, string text, integer limit=0, integer from=1, option_spec options=DEFAULT)
	if sequence(options) then 
		options = math:or_all(options) 
	end if
	sequence match_data = find_all(re, text, from, options), result
	integer last = 1
	
	if limit = 0 or limit > length(match_data) then
		limit = length(match_data)
	end if
	
	result = repeat(0, limit)
	
	for i = 1 to limit do
		integer a
		a = match_data[i][1][1]
		if a = 0 then
			result[i] = ""
		else
			result[i] = text[last..a - 1]
			last = match_data[i][1][2] + 1
		end if
	end for
	
	if last < length(text) then
		result &= { text[last..$] }
	end if
	
	return result
end function

--****
-- === Replacement
--

--**
-- replaces all matches of a regex with the replacement text.
--
-- Parameters:
--   # ##re## : a regex which will be used for matching
--   # ##text## : a string on which search and replace will apply
--   # ##replacement## : a string, used to replace each of the full matches
--   # ##from## : optional start position
--   # ##options## : options, defaults to [[:DEFAULT]].  See [[:Match Time Option Constants]].
--     ##options## can be any match time option or a
--     sequence of valid options or it can be a value that comes from using or_bits on
--     any two valid option values.
--
-- Returns:
--   A **sequence**, the modified ##text##.  If there is no match with ##re## the
--  return value will be the same as ##text## when it was passed in.
--
-- Comments:
-- Special replacement operators~:
--
-- * **##\##**  ~-- Causes the next character to lose its special meaning.
-- * **##\n##** ~ -- Inserts a ##0x0A## (LF) character.
-- * **##\r##** ~-- Inserts a ##0x0D## (CR) character.
-- * **##\t##** ~-- Inserts a ##0x09## (TAB) character.
-- * **##\1##** to **##\9##** ~-- Recalls stored substrings from registers (\1, \2, \3, to \9).
-- * **##\0##** ~-- Recalls entire matched pattern.
-- * **##\u##** ~-- Convert next character to uppercase
-- * **##\l##** ~-- Convert next character to lowercase
-- * **##\U##** ~-- Convert to uppercase till ##\E## or ##\e##
-- * **##\L##** ~-- Convert to lowercase till ##\E## or ##\e##
-- * **##\E##** or **##\e##** ~-- Terminate a ##{{{\\}}}U## or ##\L## conversion
--
-- Example 1:
-- <eucode>
-- include std/regex.e
-- regex r = new(`([A-Za-z]+)\.([A-Za-z]+)`)
-- sequence details = find_replace(r, "hello.txt", 
--                                         `Filename: \U\1\e Extension: \U\2\e`)
-- -- details = "Filename: HELLO Extension: TXT"
-- </eucode>
--

public function find_replace(regex ex, string text, sequence replacement, integer from=1,
			option_spec options=DEFAULT)
	return find_replace_limit(ex, text, replacement, -1, from, options)
end function

--**
-- replaces up to ##limit## matches of ##ex## in ##text## except when ##limit## is 0.  When
-- ##limit## is 0, this routine replaces all of the matches.
--
-- Parameters:
--   # ##re## : a regex which will be used for matching
--   # ##text## : a string on which search and replace will apply
--   # ##replacement## : a string, used to replace each of the full matches
--   # ##limit## : the number of matches to process
--   # ##from## : optional start position
--   # ##options## : options, defaults to [[:DEFAULT]].  See [[:Match Time Option Constants]].
--     ##options## can be any match time option or a
--     sequence of valid options or it can be a value that comes from using or_bits on
--     any two valid option values.
--
-- Comments:
-- This function is identical to [[:find_replace]] except it allows you to limit the number of
-- replacements to perform. Please see the documentation for [[:find_replace]] for all the
-- details.
--
-- Returns:
--   A **sequence**, the modified ##text##.
--
-- See Also:
--   [[:find_replace]]
--

public function find_replace_limit(regex ex, string text, sequence replacement,
			integer limit, integer from=1, option_spec options=DEFAULT)
	if sequence(options) then 
		options = math:or_all(options) 
	end if

    return machine_func(M_PCRE_REPLACE, { ex, text, replacement, options, 
			from, limit })
end function

--**
-- finds and then replaces text that is processed by a call back function.
--
-- Parameters:
--   # ##re## : a regex which will be used for matching
--   # ##text## : a string on which search and replace will apply
--   # ##rid## : routine id to execute for each match
--   # ##limit## : the number of matches to process
--   # ##from## : optional start position
--   # ##options## : options, defaults to [[:DEFAULT]].  See [[:Match Time Option Constants]].
--     ##options## can be any match time option or a
--     sequence of valid options or it can be a value that comes from using or_bits on
--     any two valid option values.
--
-- Returns:
--   A **sequence**, the modified ##text##.
--
-- Comments:
-- When ##limit## is positive,
-- this routine replaces up to ##limit## matches of ##ex## in ##text## with the
-- result of the user
-- defined callback, ##rid##, and when ##limit## is 0, replaces
-- all matches of ##ex## in ##text## with the result of this user defined callback, ##rid##.
--
-- The callback should take one sequence.  The first member of this sequence will be a
-- a string
-- representing the entire match and the subsequent members, if they exist,
-- will be a strings
-- for the captured groups within the regular expression.
--
--   The function rid.  Must take one sequence parameter.  The function needs to accept a sequence
-- of strings and return a string.  For each match, the function will be passed a sequence of 
-- strings.  The first string is the entire match the subsequent strings are for the capturing groups.  
-- If a match succeeds with groups that don't exist, that place will contain a 0. If the sub-group 
-- does exist, the palce will contain the matching group string.
-- for that group.
--
--
-- Example 1:
-- <eucode>
-- include std/text.e 
-- function my_convert(sequence params)
--     switch params[1] do
--         case "1" then
--             return "one "
--         case "2" then
--             return "two "
--         case else
--             return "unknown "
--     end switch
-- end function
-- 
-- regex r = re:new(`\d`)
-- sequence result = re:find_replace_callback(r, "125",routine_id("my_convert"))
-- -- result = "one two unknown "
-- 
-- 
-- integer missing_data_flag = 0
-- regex r2 = re:new(`[A-Z][a-z]+ ([A-Z][a-z]+)?`)
-- function my_toupper( sequence params)
--       -- here params[2] may be 0.
--       return upper( params[1] )
-- end function
-- 
-- result = find_replace_callback(r2, "John Doe", routine_id("my_toupper"))
-- -- params[2] is "Doe"
-- -- result = "JOHN DOE"
-- printf(1, "result=%s\n", {result} )
-- result = find_replace_callback(r2, "Mary", routine_id("my_toupper"))
-- -- result = "MARY"
-- </eucode>
--
public function find_replace_callback(regex ex, string text, integer rid, integer limit=0,
                integer from=1, option_spec options=DEFAULT)
	if sequence(options) then 
		options = math:or_all(options) 
	end if
	sequence match_data = find_all(ex, text, from, options), replace_data
	
	if limit = 0 or limit > length(match_data) then
		limit = length(match_data)
	end if
	replace_data = repeat(0, limit)

	for i = 1 to limit do
		sequence params = repeat(0, length(match_data[i]))
		for j = 1 to length(match_data[i]) do
			if equal(match_data[i][j],{0,0}) then
				params[j] = 0
			else
				params[j] = text[match_data[i][j][1]..match_data[i][j][2]]
			end if
		end for
		
		replace_data[i] = call_func(rid, { params })
	end for

	for i = limit to 1 by -1 do
		text = replace(text, replace_data[i], match_data[i][1][1], match_data[i][1][2])
	end for
	
	return text
end function
