--****
-- == Euphoria Source Tokenizer
--
-- <<LEVELTOC level=2 depth=4>>
--

namespace tokenize

include std/convert.e
include std/io.e
include std/eumem.e

include keywords.e

constant 
	EOL = '\n',
	TRUE = 1,
	FALSE = 0

--****
-- === tokenize return sequence key

public enum
	ET_TOKENS,
	ET_ERROR,
	ET_ERR_LINE,
	ET_ERR_COLUMN

--****
-- === Tokens

public enum
	T_EOF,
	T_NULL,
	T_SHBANG,
	T_NEWLINE,
	T_COMMENT,
	T_NUMBER,
	--**
	-- quoted character
	T_CHAR,
	--**
	-- string
	T_STRING,
	T_IDENTIFIER,
	T_KEYWORD,
	T_DOUBLE_OPS,
	T_PLUSEQ = T_DOUBLE_OPS,
	T_MINUSEQ,
	T_MULTIPLYEQ,
	T_DIVIDEEQ,
	T_LTEQ,
	T_GTEQ,
	T_NOTEQ,
	T_CONCATEQ,
	T_DELIMITER,
	T_PLUS = T_DELIMITER,
	T_MINUS,
	T_MULTIPLY,
	T_DIVIDE,
	T_LT,
	T_GT,
	T_NOT,
	T_CONCAT,
	T_SINGLE_OPS,
	T_EQ = T_SINGLE_OPS,
	T_LPAREN,
	T_RPAREN,
	T_LBRACE,
	T_RBRACE,
	T_LBRACKET,
	T_RBRACKET,
	T_QPRINT,
	T_COMMA,
	T_PERIOD,
	T_COLON,
	T_DOLLAR,
	T_SLICE,
	T_WHITE,
	T_BUILTIN,
	T_TEXT,
	--****
	-- === T_NUMBER formats and T_types
	TF_HEX = 1,
	TF_INT,
	TF_ATOM,
	TF_STRING_SINGLE,
	TF_STRING_TRIPLE,
	TF_STRING_BACKTICK,
	TF_STRING_HEX,
	TF_COMMENT_SINGLE,
	TF_COMMENT_MULTIPLE,
	$

-- this list of delimiters must match the order of the corresponding T_ codes above
constant Delimiters = "+-*/<>!&" & "=(){}[]?,.:$" -- double & single ops

public enum
	TTYPE,
	TDATA,
	TLNUM,
	TLPOS,
	TFORM,
	$

sequence Token = { T_EOF, "", 0, 0, 0 }

sequence source_text = ""
integer	 sti  = 0
integer	 LNum = 0
integer	 LPos = 0
integer	 Look = EOL

integer ERR		  = 0
integer ERR_LNUM  = 0
integer ERR_LPOS  = 0

--****
-- === ET error codes

public enum
	ERR_NONE = 0,
	ERR_OPEN,
	ERR_ESCAPE,
	ERR_EOL_CHAR,
	ERR_CLOSE_CHAR,
	ERR_EOL_STRING,
	ERR_HEX,
	ERR_DECIMAL,
	ERR_UNKNOWN,
	ERR_EOF,
	ERR_EOF_STRING,
	ERR_HEX_STRING,
	$

-- use error_string(code) to retrieve these
constant ERROR_STRING = { 
	"Failed to open file",
	"Expected an escape character",
	"End of line reached without closing \' char",
	"Expected a closing \' char",
	"End of line reached without closing \" char",
	"Expected a hex value",
	"Expected a decimal value",
	"Unknown token type",
	"Expected EOF",
	"End of file reached without closing \" char",
	"Invalid hexadecimal or unicode string",
	$
}

procedure report_error(integer err)
	Look = io:EOF
	ERR = err
	ERR_LNUM = Token[TLNUM]
	ERR_LPOS = Token[TLPOS]
end procedure

--**
-- Get an error message string for a given error code.
--

public function error_string(integer err)
	if err >= ERR_OPEN and err <= ERR_EOF then
		return ERROR_STRING[err]
	else
		return ""
	end if
end function

function default_state()
	return {
		TRUE, --IGNORE_NEWLINES
		TRUE, --IGNORE_COMMENTS
		FALSE, --STRING_NUMBERS
		TRUE, --DELETE_WHITE
		FALSE, --ID_BUILTIN
		TRUE, --ID_KEYWORD
		FALSE, --LITERAL_STRING
		FALSE --STRING_KEEP_QUOTES
	}
end function

atom g_state = eumem:malloc()
eumem:ram_space[g_state] = default_state()

--**
-- Create a new tokenizer state
--
-- See Also:
--   [[:reset]], [[:tokenize_string]], [[:tokenize_file]]
--

public function new()
	atom state = eumem:malloc()
	
	reset(state)
	
	return state
end function

--**
-- Reset the state to begin parsing a new file
--
-- See Also:
--   [[:new]], [[:tokenize_string]], [[:tokenize_file]]
--

public procedure reset(atom state = g_state)
	eumem:ram_space[state] = default_state()
end procedure

--**
-- Parse Euphoria code into tokens of like colors.
--****
-- === get/set options

enum
IGNORE_NEWLINES,
IGNORE_COMMENTS,
STRING_NUMBERS,
DELETE_WHITE,
ID_BUILTIN,
ID_KEYWORD,
LITERAL_STRING,
STRING_KEEP_QUOTES

--**
-- Specify whether to identify builtins specially or not
--
-- default is FALSE

public procedure keep_builtins(integer val = 1, atom state = g_state)
	eumem:ram_space[state][ID_BUILTIN] = val
end procedure

--**
-- Specify whether to identify keywords specially or not
--
-- default is TRUE

public procedure keep_keywords(integer val = 1, atom state = g_state)
	eumem:ram_space[state][ID_KEYWORD] = val
end procedure

--**
-- Return white space (other than newlines) as tokens.
--
-- default is FALSE

public procedure keep_whitespace(integer val = 1, atom state = g_state)
	eumem:ram_space[state][DELETE_WHITE] = not val
end procedure

--**
-- Return new lines as tokens.
--
-- default is FALSE

public procedure keep_newlines(integer val = 1, atom state = g_state)
	eumem:ram_space[state][IGNORE_NEWLINES] = not val
end procedure

--**
-- Return comments as tokens
--
-- default is FALSE
--

public procedure keep_comments(integer val = 1, atom state = g_state)
	eumem:ram_space[state][IGNORE_COMMENTS] = not val
end procedure

--**
-- When returning string tokens, we have the option to process them and
-- return their value, or to return the literal text that made up the
-- original string.
--
-- Right now, this option only affects the processing of hex strings.
--
-- default is FALSE - process the string and return its value
--

public procedure return_literal_string(integer val = 1, atom state = g_state)
	eumem:ram_space[state][LITERAL_STRING] = val
end procedure

--**
-- When returning string tokens, we have the option to strip the quotes.
--
-- default is TRUE
--

public procedure string_strip_quotes(integer val = 1, atom state = g_state)
	eumem:ram_space[state][STRING_KEEP_QUOTES] = not val
end procedure

--**
-- Return TDATA for all T_NUMBER tokens in "string" format.
--
-- Defaults:
--	* T_NUMBER tokens return atoms
--	* T_CHAR tokens return single integer chars
--	* T_EOF tokens return undefined data
--	* Other tokens return strings
--

public procedure string_numbers(integer val = 1, atom state = g_state)
	eumem:ram_space[state][STRING_NUMBERS] = val
end procedure

---------------------------------------------------------------------------------
--
-- CHAR TYPE ROUTINES
--
---------------------------------------------------------------------------------

type White_Char(object c)
	return integer(c) and (c >= 0) and (c <= ' ')
end type

type Digit_Char(object c)
	return integer(c) and ((('0' <= c) and (c <= '9')) or (c = '_'))
end type

type uHex_Char(object c)
	return integer(c) and ('A' <= c) and (c <= 'F')
end type

type lHex_Char(object c)
	return integer(c) and ('a' <= c) and (c <= 'f')
end type

type Hex_Char(object c)
	return integer(c) and (Digit_Char(c) or uHex_Char(c) or lHex_Char(c))
end type

type uAlpha_Char(object c)
	return integer(c) and ('A' <= c) and (c <= 'Z')
end type

type lAlpha_Char(object c)
	return integer(c) and ('a' <= c) and (c <= 'z')
end type

type Alpha_Char(object c)
	return integer(c) and (uAlpha_Char(c) or lAlpha_Char(c))
end type

type Alphanum_Char(object c)
	return integer(c) and (Alpha_Char(c) or Digit_Char(c))
end type

type Identifier_Char(object c)
	return Alphanum_Char(c)
end type

procedure scan_char(atom state = g_state)
	state = state -- supress warning
	if Look = EOL then
		LNum += 1
		LPos = 0
		if length(Token[TDATA]) = 0 then
			Token[TLNUM] = LNum
			Token[TLPOS] = 1
		end if
	end if
	LPos += 1
	sti += 1
	if sti > length(source_text) then
		Look = io:EOF
	else
		Look = source_text[sti]
	end if
end procedure

function lookahead(integer dist = 1, atom state = g_state)
	state = state -- supress warning
	if sti + dist <= length(source_text) then
		return source_text[sti + dist]
	else
		return io:EOF
	end if
end function

-- returns TRUE if a newline was parsed
function scan_white(atom state = g_state)
	Token[TTYPE] = T_NEWLINE
	Token[TDATA] = ""

	while White_Char(Look) do
		scan_char(state)
		if Look = EOL then
			return TRUE
		end if
	end while

	return FALSE
end function

-- returns TRUE if a newline was parsed
function scankeep_white(atom state = g_state)
	Token[TTYPE] = T_WHITE
	Token[TDATA] = ""

	while White_Char(Look) do
		Token[TDATA] &= Look
		scan_char(state)
		if Look = EOL then
			exit
		end if
	end while

	if length(Token[TDATA]) then
		return TRUE
	end if
	return FALSE
end function

function scan_multicomment(atom state = g_state)
	Token[TTYPE] = T_COMMENT
	Token[TDATA] = "/"
	Token[TFORM] = TF_COMMENT_MULTIPLE

	while 1 do
		if (Look = io:EOF) or (Look = EOL) then
-- 			report_error(ERR_EOF)
			return TRUE 
		end if

		if (Look = '*') and lookahead(1) = '/' then
			Token[TDATA] &= "*/"

			scan_char(state) -- skip the */
			scan_char(state)
			exit
		end if

		Token[TDATA] &= Look
		scan_char(state)
	end while

	return TRUE
end function

constant QFLAGS = "t\\r\'n\""

procedure scan_escaped_char(atom state = g_state)
	integer f
	Token[TDATA] &= Look
	if (Look = '\\') then
		scan_char(state)
		Token[TDATA] &= Look
		f = find(Look,QFLAGS)
		if not f then
			report_error(ERR_ESCAPE)
		end if
	end if
	scan_char(state)
end procedure

function scan_qchar(atom state = g_state)
	if (Look != '\'') then return FALSE end if
	scan_char(state)
	Token[TTYPE] = T_CHAR
	Token[TDATA] = ""
	if (Look = EOL) then
		if eumem:ram_space[state][STRING_KEEP_QUOTES] then
			Token[TDATA] = "'" & Token[TDATA]
		end if
		report_error(ERR_EOL_CHAR)
		return TRUE
	end if
	scan_escaped_char(state)
	while Look != '\'' and Look != EOL do
		Token[TDATA] &= Look
		scan_char( state )
	end while
	if (Look != '\'') then
		if eumem:ram_space[state][STRING_KEEP_QUOTES] then
			Token[TDATA] = "'" & Token[TDATA]
		end if
		report_error(ERR_CLOSE_CHAR)
		return TRUE
	end if
	scan_char(state)
	if eumem:ram_space[state][STRING_KEEP_QUOTES] then
		Token[TDATA] = "'" & Token[TDATA] & "'"
	end if
	return TRUE
end function

function lookahead_for( object needle, integer look_at =  1 )
	if atom( needle ) then
		needle = {needle}
	end if
	for i = 1 to length( needle ) do
		if lookahead( look_at ) != needle[i] then
			return FALSE
		end if
		look_at += 1
	end for
	return TRUE
end function

function raw_string( sequence delimiter, atom state )
	Token[TTYPE] = T_STRING
	Token[TDATA] = ""

	if equal( delimiter, "`" ) then
		Token[TFORM] = TF_STRING_BACKTICK
	else
		Token[TFORM] = TF_STRING_TRIPLE
	end if
	
	while lookahead(1) != io:EOF and not lookahead_for( delimiter ) with entry do
		scan_char(state)
		Token[TDATA] &= Look
		
	end while

	if Look != io:EOF then
		sti += length( delimiter )
		scan_char(state)
	end if

	if eumem:ram_space[state][STRING_KEEP_QUOTES] then
		if Look = io:EOF then
			Token[TDATA] = delimiter & Token[TDATA]
		else
			Token[TDATA] = delimiter & Token[TDATA] & delimiter
		end if
	end if
	
	return TRUE
end function

function scan_string(atom state = g_state)
	if (Look = '`') then
		return raw_string( "`", state )
	end if
	if (Look != '"') then 
		return FALSE 
	end if

	if sti + 3 < length(source_text) then
		if equal(source_text[sti .. sti + 2], "\"\"\"") then
			-- Got a raw string
			sti += 2
			return raw_string( `"""`, state )
		end if
	end if

	scan_char(state)
	Token[TTYPE] = T_STRING
	Token[TDATA] = ""
	Token[TFORM] = TF_STRING_SINGLE

	while (Look != '"') do
		if (Look = EOL) then 
			if eumem:ram_space[state][STRING_KEEP_QUOTES] then
				Token[TDATA] = "\"" & Token[TDATA] -- & "\""
			end if
			report_error(ERR_EOL_STRING)
			return TRUE
		end if

		scan_escaped_char(state)

		if ERR then 
			if eumem:ram_space[state][STRING_KEEP_QUOTES] then
				Token[TDATA] = "\"" & Token[TDATA] & "\""
			end if
			return TRUE
		end if
	end while

	scan_char(state)

	if eumem:ram_space[state][STRING_KEEP_QUOTES] then
		Token[TDATA] = "\"" & Token[TDATA] & "\""
	end if
	return TRUE
end function

function hex_val(integer h)
	if h >= 'a' then
		return h - 'a' + 10
	elsif h >= 'A' then
		return h - 'A' + 10
	else
		return h - '0'
	end if
end function

function start_hex()
	if Look = '#' and Hex_Char( lookahead( 1 ) ) then
		return TRUE
	elsif Look = '0' and lookahead( 1 ) = 'x' and Hex_Char( lookahead( 2 ) ) then
		sti += 1
		return TRUE
	else
		return FALSE
	end if
end function

function scan_hex(atom state = g_state)
	if not start_hex() then
		return FALSE
	end if

	integer startSti = sti
	
	scan_char(state)

	if not Hex_Char(Look) then
		report_error(ERR_HEX) return FALSE
	end if

	Token[TTYPE] = T_NUMBER
	Token[TFORM] = TF_HEX

	if eumem:ram_space[state][STRING_NUMBERS] then
		while Hex_Char(Look) do
			scan_char(state)
		end while
		
		Token[TDATA] = source_text[startSti .. sti - 1]
	else
		Token[TDATA] = hex_val(Look)
		scan_char(state)

		while Hex_Char(Look) do
			if Look != '_' then
				Token[TDATA] = Token[TDATA] * 16 + hex_val(Look)
			end if
			scan_char(state)
		end while
	end if

	return TRUE
end function

integer SUBSCRIPT = 0
function scan_integer(atom state = g_state)
	atom i = 0

	while Digit_Char(Look) do
		if (Look != '_') then
			i = (i * 10) + (Look - '0')
		end if

		scan_char(state)
	end while

	return i
end function

function scan_fraction(atom v, atom state = g_state)
	if not Digit_Char(Look) then report_error(ERR_DECIMAL) return 0 end if

	atom d = 10
	while Digit_Char(Look) do
		if Look != '_' then
			v += (Look - '0') / d
			d *= 10
		end if
		scan_char(state)
	end while
	return v
end function

function scan_exponent(atom v, atom state = g_state)
	atom e

	if ((Look != 'e') and (Look != 'E')) then return v end if
	scan_char(state)

	if (Look = '-') then
		scan_char(state)
		e = -scan_integer(state)
	else
		if (Look = '+') then scan_char(state) end if
		e = scan_integer(state)
	end if

	if e > 308 then
		v *= power(10, 308)
		if e > 1000 then e = 1000 end if
		for i = 1 to e - 308 do
			v *= 10
		end for
	else
		v *= power(10, e)
	end if
	return v
end function

function scan_number(atom state = g_state)
	if not Digit_Char(Look) then
		return FALSE
	end if
	
	Token[TTYPE] = T_NUMBER
	Token[TFORM] = TF_INT

	if eumem:ram_space[state][STRING_NUMBERS] then
		integer startSti = sti

		while Digit_Char(Look) do
			scan_char(state)
		end while
		
		if Look = '.' and lookahead(1, state) != '.' then
			Token[TFORM] = TF_ATOM
			scan_char(state)
			
			while Digit_Char(Look) do
				scan_char(state)
			end while
		end if
		
		Token[TDATA] = source_text[startSti .. sti - 1]
	else
		atom v

		Token[TDATA] = scan_integer(state)

		if not SUBSCRIPT then
			v = Token[TDATA]
			if Look = '.' then
				if lookahead() = '.' then
					-- We have a slice, put the token back and return our number.
					return TRUE
				end if
	
				scan_char()
				Token[TDATA] = scan_fraction(Token[TDATA], state)

				if ERR then return TRUE end if
			end if

			Token[TDATA] = scan_exponent(Token[TDATA], state)
			if v != Token[TDATA] then
				Token[TFORM] = TF_ATOM
			end if
		end if
	end if

	return TRUE
end function

function scan_prefixed_number(atom state = g_state)
	if not (Look = '0') then
		return FALSE
	end if

	integer pfxCh = lookahead(1, state)
	if find(pfxCh, "btdx") = 0 then
		return FALSE
	end if

	integer firstCh = lookahead(2, state)
	if Digit_Char(firstCh) or Hex_Char(firstCh) then
		integer startSti = sti

		scan_char(state) -- skip the leading zero
		scan_char(state) -- skip prefix character

		Token[TTYPE] = T_NUMBER

		if pfxCh = 'x' then
			Token[TFORM] = TF_HEX
		else
			Token[TFORM] = TF_INT
		end if

		while Hex_Char(Look) or Digit_Char(Look) do
			scan_char(state)
		end while

		if eumem:ram_space[state][STRING_NUMBERS] then
			Token[TDATA] = source_text[startSti .. sti - 1]
		else
			Token[TDATA] = convert:to_number(source_text[startSti + 2 .. sti - 1])
		end if

		return TRUE
	end if

	return FALSE
end function

function hex_string(sequence textdata, integer string_type)
	integer ch
	integer digit
	atom val
	integer nibble
	integer maxnibbles
	sequence string_text

	switch string_type do
		case 'x' then
			maxnibbles = 2
		case 'u' then
			maxnibbles = 4
		case 'U' then
			maxnibbles = 8
		case else
			printf(2, "tokenize.e: Unknown base code '%s', ignored.\n", {string_type})
	end switch

	string_text = ""
	nibble = 1
	val = -1
	for cpos = 1 to length(textdata) do
		ch = textdata[cpos]

		digit = find(ch, "0123456789ABCDEFabcdef _\t\n\r")
		if digit = 0 then
			return 0
		end if

		if digit < 23 then
			if digit > 16 then
				digit -= 6
			end if
			if nibble = 1 then
				val = digit - 1
			else
				val = val * 16 + digit - 1
				if nibble = maxnibbles then
					string_text &= val
					val = -1
					nibble = 0
				end if
			end if
			nibble += 1

		else
			if val >= 0 then
				-- Expecting 2nd hex digit but didn't get one, so assume we got everything.
				string_text &= val
				val = -1
			end if
			nibble = 1
		end if
	end for

	if val >= 0 then
		-- Expecting 2nd hex digit but didn't get one, so assume we got everything.
		string_text &= val
	end if

	return string_text
end function

integer INCLUDE_NEXT = FALSE

function scan_identifier(atom state = g_state)
	integer nextch
	integer startpos
	object textdata

	if not Alpha_Char(Look) and Look != '_' then
		return FALSE
	end if

	if find(Look, "xuU") then
		nextch = lookahead(state, state)
		if nextch = '"' then
			-- A special string token
			integer whichhex = Look
			textdata = ""
			scan_char(state)	-- Skip over starting quote
			scan_char(state) -- First char of string
			startpos = sti

			while not find(Look, {'"', io:EOF}) do
				scan_char(state)
			end while

			if Look = io:EOF then
				if eumem:ram_space[state][STRING_KEEP_QUOTES] then
					Token[TDATA] = whichhex &"\"" & Token[TDATA] & "\""
				end if
				-- No matching end-quote
				report_error(ERR_EOF_STRING)
				return TRUE
			end if

			if not eumem:ram_space[state][LITERAL_STRING] then
				textdata = hex_string(source_text[startpos .. sti-1], source_text[startpos - 2])
			end if
			if atom(textdata) then
				-- Invalid hex string
				if eumem:ram_space[state][STRING_KEEP_QUOTES] then
					Token[TDATA] = whichhex &"\"" & Token[TDATA] & "\""
				end if
				report_error(ERR_HEX_STRING)
				return TRUE
			end if

			Token[TTYPE] = T_STRING
			Token[TDATA] = textdata
			Token[TFORM] = TF_STRING_HEX

			scan_char(state)	-- go to next char after end of string
			if eumem:ram_space[state][STRING_KEEP_QUOTES] then
				Token[TDATA] = whichhex &"\"" & Token[TDATA] & "\""
			end if

			return TRUE
		end if
	end if

	Token[TTYPE] = T_IDENTIFIER
	Token[TDATA] = ""

	while Identifier_Char(Look) do
		Token[TDATA] &= Look
		scan_char(state)
	end while

	if find(Token[TDATA],keywords) then
		if eumem:ram_space[state][ID_KEYWORD] then
			Token[TTYPE] = T_KEYWORD
		end if
		if equal(Token[TDATA],"include") then
			INCLUDE_NEXT = TRUE
		end if
	end if

	if find(Token[TDATA],builtins) and eumem:ram_space[state][ID_BUILTIN] then
		Token[TTYPE] = T_BUILTIN
	end if

	return TRUE
end function

function scan_include(atom state = g_state)
	if not INCLUDE_NEXT then
		return FALSE
	end if

	INCLUDE_NEXT = FALSE

	Token[TTYPE] = T_IDENTIFIER
	Token[TDATA] = ""

	if not scan_string(state) then
		-- scan until whitespace
		while not White_Char(Look) do
			Token[TDATA] &= Look
			scan_char(state)
		end while
	end if

	return TRUE
end function

procedure next_token(atom state = g_state)
	Token[TLNUM] = LNum
	Token[TLPOS] = LPos
	Token[TFORM] = -1

	if Look = EOL and not eumem:ram_space[state][IGNORE_NEWLINES] then
		-- We have a left over EOL, process it
		Token[TDATA] = ""
		Token[TTYPE] = T_NEWLINE

		scan_char(state) -- advance past this newline

		return
	end if

	if not eumem:ram_space[state][DELETE_WHITE] and scankeep_white(state) then
		-- got whitespace token
		return
	end if

	-- scan_white returns TRUE if it hit a T_NEWLINE
	if scan_white(state) then
		if eumem:ram_space[state][IGNORE_NEWLINES] then next_token(state) end if
		return
	end if

	if scan_include(state) then
		return
	end if

	Token[TTYPE] = find(Look, Delimiters)

	if Token[TTYPE] then
		-- handle delimiters and special cases
		Token[TTYPE] += T_DELIMITER - 1
		Token[TDATA] = { Look }

		scan_char(state)

		if (Token[TTYPE] = T_LBRACKET) then
			-- must check before T_PERIOD
			SUBSCRIPT += 1 -- push subscript stack counter

		elsif (Token[TTYPE] = T_RBRACKET) then
			-- must check before T_PERIOD
			SUBSCRIPT -= 1 -- pop subscript stack counter

		elsif (Look = '=') and (Token[TTYPE] <= T_SINGLE_OPS) then
			-- is a valid double op
			-- double operators: += -= *= /= etc..
			Token[TTYPE] -= T_DOUBLE_OPS - 3
			Token[TDATA] &= Look

			scan_char(state)

		elsif (Token[TTYPE] = T_PERIOD) then
			-- check for .. or .number
			if (Look = '.') then
				-- scan for ..
				Token[TTYPE] = T_SLICE
				Token[TDATA] &= Look

				scan_char(state)
			else
				-- .number
				Token[TTYPE] = T_NUMBER
				Token[TDATA] = scan_fraction(0, state)
				Token[TFORM] = TF_ATOM
				if ERR then
					return
				end if

				Token[TDATA] = scan_exponent(Token[TDATA], state)

				if eumem:ram_space[state][STRING_NUMBERS] then
					if integer(Token[TDATA]) then
						Token[TDATA] = sprintf("%d",{Token[TDATA]})
					else
						Token[TDATA] = sprintf("%g",{Token[TDATA]})
					end if
				end if
			end if

		elsif (Look = '-') and (Token[TTYPE] = T_MINUS) then
			-- check for comment
			Token[TTYPE] = T_COMMENT
			Token[TDATA] = "--"
			Token[TFORM] = TF_COMMENT_SINGLE

			scan_char(state)

			while (Look != EOL) do
				Token[TDATA] &= Look
				scan_char(state)
			end while

			if eumem:ram_space[state][IGNORE_COMMENTS] then
				next_token(state)
			end if

		elsif (Look = '*') and (Token[TTYPE] = T_DIVIDE) then
			-- check for multi-line comment
			scan_multicomment(state)
		end if

	elsif scan_identifier(state) then

	elsif scan_qchar(state) then

	elsif scan_string(state) then

	elsif scan_prefixed_number(state) then

	elsif scan_hex(state) then

	elsif scan_number(state) then

	elsif Look != io:EOF and not White_Char( Look ) then
		while Look != io:EOF and not White_Char( Look ) do
			Token[TDATA] &= Look
			scan_char(state)
		end while
		Token[TTYPE] = T_TEXT
	else
		
		-- error or end of file
		Token[TTYPE] = T_EOF
		Token[TDATA] = Look

		if (Look != io:EOF) then
			report_error(ERR_UNKNOWN)
		end if
	end if
end procedure


--****
-- === Routines

public function tokenize_string(sequence code, atom state = g_state, integer stop_on_error = TRUE)
	sequence tokens

	ERR = FALSE
	ERR_LNUM = 0
	ERR_LPOS = 0

	tokens = {}

	source_text = code
	if not length( source_text ) or source_text[$] != EOL then
		source_text &= EOL
	end if
	source_text &= io:EOF
	LNum = 1
	LPos = 1
	sti = 1
	Look = source_text[sti]
	Token[TTYPE] = io:EOF
	Token[TDATA] = ""
	Token[TLNUM] = 1
	Token[TLPOS] = 1

	if (Look = '#') and (lookahead(1) = '!') then
		sti += 1
		scan_char(state)
		if eumem:ram_space[state][DELETE_WHITE] then
			scan_white(state)
		end if
		Token[TTYPE] = T_SHBANG
		Token[TDATA] = "#!"
		while Look != EOL do
			Token[TDATA] &= Look
			scan_char(state)
		end while
		scan_char(state)
		tokens &= { Token }
	end if

	next_token(state)
	if not stop_on_error or not ERR then
		while Token[TTYPE] != T_EOF do
			tokens &= { Token }
			next_token(state)
			if stop_on_error and ERR then
				exit
			end if
		end while
	end if

	return { tokens, ERR, ERR_LNUM, ERR_LPOS }
end function

public function tokenize_file(sequence fname, atom state = g_state)
	object txt = io:read_file(fname, io:TEXT_MODE)
	if atom(txt) and txt = -1 then
		return {{}, ERR_OPEN, ERR_LNUM, ERR_LPOS}
	end if

	return tokenize_string(txt, state)
end function

--****
-- === Debugging
--

--**
-- Sequence containing token names for debugging

public constant token_names = {
	"T_EOF", "T_NULL", "T_SHBANG", "T_NEWLINE", "T_COMMENT", "T_NUMBER", "T_CHAR", "T_STRING",
	"T_IDENTIFIER", "T_KEYWORD", "T_PLUSEQ", "T_MINUSEQ", "T_MULTIPLYEQ", "T_DIVIDEEQ", "T_LTEQ", 
	"T_GTEQ", "T_NOTEQ", "T_CONCATEQ", "T_PLUS", "T_MINUS", "T_MULTIPLY", "T_DIVIDE", "T_LT", "T_GT", 
	"T_NOT", "T_CONCAT", "T_EQ", "T_LPAREN", "T_RPAREN", "T_LBRACE", "T_RBRACE", "T_LBRACKET",
	"T_RBRACKET", "T_QPRINT", "T_COMMA", "T_PERIOD", "T_COLON", "T_DOLLAR", "T_SLICE", "T_WHITE", "T_BUILTIN"
}

public constant token_forms = {
	"TF_HEX", "TF_INT", "TF_ATOM", "TF_STRING_SINGLE", "TF_STRING_TRIPPLE",
	"TF_STRING_BACKTICK", "TF_STRING_HEX", "TF_COMMENT_SINGLE", "TF_COMMENT_MULTIPLE"
}

--**
-- Print token names and data for each token in `tokens` to the file handle `fh`
--
-- Parameters:
--   * ##fh## - file handle to print information to
--   * ##tokens## - token sequence to print
--
-- Comments:
--   This does not take direct output from ##[[:tokenize_string]]## or ##[[:tokenize_file]]##. Instead
--   they take the first element of their return value, the token stream only.
--
-- See Also:
--   [[:tokenize_string]], [[:tokenize_file]]
--

public procedure show_tokens(integer fh, sequence tokens)
	for i = 1 to length(tokens) do
		switch tokens[i][TTYPE] do
			case T_STRING then
				printf(fh, "T_STRING %20s : [[[%s]]]\n", { 
					token_forms[tokens[i][TFORM]], tokens[i][TDATA] 
				})

			case T_NUMBER then
				object v = tokens[i][TDATA]
				if integer(v) then
					v = sprintf("%d", { v })
				elsif atom(v) then
					v = sprintf("%f", { v })
				end if

				printf(fh, "T_NUMBER %20s : %s\n", { 
					token_forms[tokens[i][TFORM]], v
				})

			case T_NEWLINE then
				printf(fh, "T_NEWLINE                     : \\n\n", {})

			case else
				if tokens[i][TTYPE] < 1 or tokens[i][TTYPE] > length(token_names) then
					printf(fh, "UNKNOWN                       : %d\n", { tokens[i][TTYPE] })
				else
					printf(fh, "%-29s : %s\n", { 
						token_names[tokens[i][TTYPE]], tokens[i][TDATA]
					})
				end if
		end switch
	end for
end procedure

