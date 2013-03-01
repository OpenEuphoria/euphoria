--****
-- == Syntax Coloring
--
-- <<LEVELTOC level=2 depth=4>>
--
--				Syntax Color
-- Break Euphoria statements into words with multiple colors.
-- The editor and pretty printer (eprint.ex) both use this file.

-- The user can define the following identifiers to be colors for the
-- various syntax classes:
--		 NORMAL_COLOR
--		COMMENT_COLOR
--		KEYWORD_COLOR
--		BUILTIN_COLOR
--		 STRING_COLOR
--		BRACKET_COLOR  (a sequence of colors)
--
-- <<LEVELTOC level=2 depth=4>>
--

namespace syncolor

include std/text.e
include std/eumem.e

public include tokenize.e

integer NORMAL_COLOR,
		COMMENT_COLOR,
		KEYWORD_COLOR,
		BUILTIN_COLOR,
		STRING_COLOR

sequence BRACKET_COLOR

enum
	S_TOKENIZER,
	S_BRACKET_LEVEL,
	S_KEEP_NEWLINES

--****
-- === Routines
--

public procedure set_colors(sequence pColorList)
	sequence lColorName
	for i = 1 to length(pColorList) do
		lColorName = text:upper(pColorList[i][1])
		switch lColorName do
			case "NORMAL" then
				NORMAL_COLOR  = pColorList[i][2]
			case "COMMENT" then
				COMMENT_COLOR  = pColorList[i][2]
			case "KEYWORD" then
				KEYWORD_COLOR  = pColorList[i][2]
			case "BUILTIN" then
				BUILTIN_COLOR  = pColorList[i][2]
			case "STRING" then
				STRING_COLOR  = pColorList[i][2]
			case "BRACKET" then
				BRACKET_COLOR  = pColorList[i][2]
			case else
				printf(2, "syncolor.e: Unknown color name '%s', ignored.\n", {lColorName})
		end switch
	end for
end procedure

public procedure init_class()
-- set default color scheme
	NORMAL_COLOR  = #330033
	COMMENT_COLOR = #FF0055
	KEYWORD_COLOR = #0000FF
	BUILTIN_COLOR = #FF00FF
	STRING_COLOR  = #00A033
	BRACKET_COLOR = {NORMAL_COLOR, #993333, #0000FF, #5500FF, #00FF00}

end procedure

constant DONT_CARE = -1  -- any color is ok - blanks, tabs

sequence line           -- the line being processed
sequence color_segments -- the value returned
sequence linebuf = "" -- a buffer for same color segments of a line
integer current_color, seg -- token of current segment of line

procedure seg_flush(integer new_color)
-- if the color must change,
-- add the current color segment to the sequence
-- and start a new segment
	if new_color != current_color then
		if current_color != DONT_CARE then
			color_segments = append(color_segments,
					{current_color, linebuf})
			linebuf = ""
		end if
		current_color = new_color
	end if
	linebuf &= line[seg][tokenize:TDATA]
end procedure

function default_state(atom token = 0)
	if not token then
		token = tokenize:new()
	end if
	return {
		token, -- S_TOKENIZER
		0,  -- S_BRACKET_LEVEL
		0  -- S_KEEP_NEWLINES
	}
end function

atom g_state = eumem:malloc()
eumem:ram_space[g_state] = default_state()

--**
-- Create a new colorizer state
--
-- See Also:
--   [[:reset]], [[:SyntaxColor]]
--

public function new()
	atom state = eumem:malloc()
	
	reset(state)
	
	return state
end function

--
-- Reset the state to begin parsing a new file
--
-- See Also:
--   [[:new]], [[:SyntaxColor]]
--
procedure tokenize_reset(atom token)
	if token then
		tokenize:reset(token)
	end if
end procedure

public procedure reset(atom state = g_state)
	atom token = eumem:ram_space[state][S_TOKENIZER]
	tokenize_reset(token)
	eumem:ram_space[state] = default_state(token)
	eumem:ram_space[state] = default_state()
end procedure

public procedure keep_newlines(integer val = 1, atom state = g_state)
	eumem:ram_space[state][S_KEEP_NEWLINES] = val
end procedure





--**
-- Parse Euphoria code into tokens of like colors.
--
-- Parameters:
-- # ##pline## the source code to color
-- # ##state## (default g_state) the tokenizer to use
-- # ##multi## the multiline token from the previous line
--
-- Break up a new-line terminated line into colored text segments identifying the
-- various parts of the Euphoria language. They are broken into separate tokens.
--
-- Returns:
--   A sequence that looks like:
--   <eucode>
--	 {{color1, "text1"}, {color2, "text2"}, ... }
--   </eucode>
--
-- Comments:
-- In order to properly color multiline syntax (strings and comments), you should pass
-- a value for ##multi##. This value can be attained by calling ##[[:last_multiline_token]]##
-- after coloring the previous line.

public function SyntaxColor(sequence pline, atom state=g_state, multiline_token multi = 0)
	integer class, last, i
	sequence word, c
	atom token = eumem:ram_space[state][S_TOKENIZER]

	tokenize:keep_builtins(,token)
	tokenize:keep_keywords(,token)
	tokenize:keep_whitespace(,token)
	tokenize:keep_newlines(,token)
	tokenize:keep_comments(,token)
	tokenize:string_numbers(,token)
	tokenize:return_literal_string(,token)
	tokenize:string_strip_quotes(0,token)

	line = tokenize:tokenize_string(pline, token, 0, multi)
	-- TODO error checking?
	line = line[1]
	current_color = DONT_CARE
	seg = 1
	color_segments = {}

	while 1 do
		if seg > length(line) then
			exit
		end if

		c = line[seg]
		class = c[tokenize:TTYPE]

		if class = tokenize:T_WHITE then
			linebuf &= c[tokenize:TDATA]-- continue with current color
		elsif class = tokenize:T_KEYWORD then
			seg_flush(KEYWORD_COLOR)

		elsif class = tokenize:T_BUILTIN then
			seg_flush(KEYWORD_COLOR)

		elsif class = tokenize:T_IDENTIFIER then
			seg_flush(NORMAL_COLOR)

		elsif class = tokenize:T_LPAREN or class = tokenize:T_RPAREN or
		class = tokenize:T_LBRACKET or class = tokenize:T_RBRACKET or
		class = tokenize:T_LBRACE or class = tokenize:T_RBRACE then
			if class = tokenize:T_LPAREN or class = tokenize:T_LBRACKET or
			class = tokenize:T_LBRACE then
				eumem:ram_space[state][S_BRACKET_LEVEL] += 1
			end if

			if eumem:ram_space[state][S_BRACKET_LEVEL] >= 1 and
			   eumem:ram_space[state][S_BRACKET_LEVEL] <= length(BRACKET_COLOR)
			then
				seg_flush(BRACKET_COLOR[eumem:ram_space[state][S_BRACKET_LEVEL]])
			else
				seg_flush(NORMAL_COLOR)
			end if

			if class = tokenize:T_RPAREN or class = tokenize:T_RBRACKET or
			class = tokenize:T_RBRACE then
				eumem:ram_space[state][S_BRACKET_LEVEL] -= 1
			end if

		elsif class = tokenize:T_NEWLINE then
			if eumem:ram_space[state][S_KEEP_NEWLINES] then
				-- continue with current color
				if equal(c[tokenize:TDATA],"") then
					linebuf &= '\n'
				else
					linebuf &= c[tokenize:TDATA]
				end if
			end if
			exit  -- end of line

		elsif class = tokenize:T_EOF then
			exit  -- end of line

		elsif class = tokenize:T_COMMENT then
			seg_flush(COMMENT_COLOR)

		elsif class = tokenize:T_STRING or class = tokenize:T_CHAR then
			seg_flush(STRING_COLOR)

		else
			seg_flush(NORMAL_COLOR)
		end if
		seg += 1
	end while

	-- add the final piece:
	if current_color = DONT_CARE then
		current_color = NORMAL_COLOR
	end if

	sequence ret = linebuf
	linebuf = ""
	return append(color_segments, {current_color, ret})
end function

new()
init_class()
