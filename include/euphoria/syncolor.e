--****
-- == Syntax Coloring
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

namespace syncolor

include std/text.e
include std/wildcard.e
include std/eumem.e as mem

include keywords.e

integer NORMAL_COLOR,
		COMMENT_COLOR,
		KEYWORD_COLOR,
		BUILTIN_COLOR,
		STRING_COLOR

sequence BRACKET_COLOR

enum
	S_STRING_TRIPLE,
	S_STRING_BACKTICK,
	S_MULTILINE_COMMENT,
	S_BRACKET_LEVEL

-- character classes
enum
	DIGIT,
	OTHER,
	LETTER,
	BRACKET,
	QUOTE,
	BACKTICK,
	DASH,
	FORWARD_SLASH,
	WHITE_SPACE,
	NEW_LINE

sequence char_class

public procedure set_colors(sequence pColorList)
	sequence lColorName
	for i = 1 to length(pColorList) do
		lColorName = upper(pColorList[i][1])
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

-- set up character classes for easier line scanning
-- (assume no 0 char)
	char_class = repeat(OTHER, 255)

	char_class['a'..'z'] = LETTER
	char_class['A'..'Z'] = LETTER
	char_class['_'] = LETTER
	char_class['0'..'9'] = DIGIT
	char_class['['] = BRACKET
	char_class[']'] = BRACKET
	char_class['('] = BRACKET
	char_class[')'] = BRACKET
	char_class['{'] = BRACKET
	char_class['}'] = BRACKET
	char_class['\''] = QUOTE
	char_class['"'] = QUOTE
	char_class['`'] = BACKTICK
	char_class[' '] = WHITE_SPACE
	char_class['\t'] = WHITE_SPACE
	char_class['\r'] = WHITE_SPACE
	char_class['\n'] = NEW_LINE
	char_class['-'] = DASH
	char_class['/'] = FORWARD_SLASH
end procedure

constant DONT_CARE = -1  -- any color is ok - blanks, tabs

sequence line           -- the line being processed
sequence color_segments -- the value returned
integer current_color, seg_start, seg_end -- start and end of current segment of line

procedure seg_flush(integer new_color)
-- if the color must change,
-- add the current color segment to the sequence
-- and start a new segment
	if new_color != current_color then
		if seg_start <= seg_end then
			if current_color != DONT_CARE then
				color_segments = append(color_segments,
						{current_color, line[seg_start..seg_end]})
				seg_start = seg_end + 1
			end if
		end if
		current_color = new_color
	end if
end procedure

function default_state()
	return {
		0, -- S_MULTILINE_COMMENT
		0, -- S_STRING_TRIPLE
		0, -- S_STRING_BACKTICK
		0  -- S_BRACKET_LEVEL
	}
end function

atom g_state = eumem:malloc()
ram_space[g_state] = default_state()

--**
-- Create a new colorizer state
--
-- See Also:
--   [[:reset]], [[:SyntaxColor]]
--

public function new()
	atom state = mem:malloc()
	reset(state)
	return state
end function

--**
-- Reset the state to begin parsing a new file
--
-- See Also:
--   [[:new]], [[:SyntaxColor]]
--

public procedure reset(atom state = g_state)
	ram_space[state] = default_state()
end procedure

--**
-- Parse Euphoria code into tokens of like colors.
--
-- Break up a new-line terminated line into colored text segments identifying the
-- various parts of the Euphoria language. Consecutive characters of the same color
-- are all placed in the same 'segment' - seg_start..seg_end.
--
-- Returns:
--   A sequence that looks like:
--   <eucode>
--	 {{color1, "text1"}, {color2, "text2"}, ... }
--   </eucode>
--

public function SyntaxColor(sequence pline, atom state=g_state)
	integer class, last, i, c
	sequence word

	-- Ensure we have a new-line to end this one.
	if length(pline) > 0 and pline[$] != '\n' then
		pline &= '\n'
	end if

	-- Don't bother if the line is empty
	if length(pline) < 2 then
		return {}
	end if

	line = pline
	current_color = DONT_CARE
	seg_start = 1
	seg_end = 0
	color_segments = {}

	-- TOOD: Hackery?
	if ram_space[state][S_MULTILINE_COMMENT] then
		goto "MULTILINE_COMMENT"

	elsif ram_space[state][S_STRING_TRIPLE] then
		goto "MULTILINE_STRING"

	elsif ram_space[state][S_STRING_BACKTICK] then
		goto "BACKTICK_STRING"

	end if

	while 1 do
		c = line[seg_end + 1]
		class = char_class[c]

		if class = WHITE_SPACE then
			seg_end += 1  -- continue with current color

		elsif class = LETTER then
			last = length(line)-1
			for j = seg_end + 2 to last do
				c = line[j]
				class = char_class[c]
				if class != LETTER then
					if class != DIGIT then
						last = j - 1
						exit
					end if
				end if
			end for
			word = line[seg_end+1..last]
			if find(word, keywords) then
				seg_flush(KEYWORD_COLOR)
			elsif find(word, builtins) then
				seg_flush(BUILTIN_COLOR)
			else
				seg_flush(NORMAL_COLOR)
			end if
			seg_end = last

		elsif class <= OTHER then -- DIGIT too
			seg_flush(NORMAL_COLOR)
			seg_end += 1

		elsif class = BRACKET then
			if find(c, "([{") then
				ram_space[state][S_BRACKET_LEVEL] += 1
			end if

			if ram_space[state][S_BRACKET_LEVEL] >= 1 and
			   ram_space[state][S_BRACKET_LEVEL] <= length(BRACKET_COLOR)
			then
				seg_flush(BRACKET_COLOR[ram_space[state][S_BRACKET_LEVEL]])
			else
				seg_flush(NORMAL_COLOR)
			end if

			if find(c, ")]}") then
				ram_space[state][S_BRACKET_LEVEL] -= 1
			end if

			seg_end += 1

		elsif class = NEW_LINE then
			exit  -- end of line

		elsif class = DASH then
			if line[seg_end+2] = '-' then
				seg_flush(COMMENT_COLOR)
				seg_end = length(line)-1
				exit
			end if
			seg_flush(NORMAL_COLOR)
			seg_end += 1

		elsif class = FORWARD_SLASH then
			if line[seg_end + 2] = '*' then
label "MULTILINE_COMMENT"
				if seg_end = 0 then
					seg_end = 1
				end if
				seg_flush(COMMENT_COLOR)
				i = match_from("*/", line, seg_end)
				if i = 0 then
					ram_space[state][S_MULTILINE_COMMENT] = 1
					seg_end = length(line) - 1
					exit
				end if
			
				integer old_seg_end = seg_end + 2
				seg_end = i + 1
				
				if old_seg_end < i and match("/*", line[old_seg_end..i]) then
					goto "MULTILINE_COMMENT"
				end if
			
				ram_space[state][S_MULTILINE_COMMENT] = 0
			else
				seg_flush(NORMAL_COLOR)
				seg_end += 1
			end if

		elsif class = BACKTICK then
label "BACKTICK_STRING"
			if seg_end = 0 then
				seg_end = 1
			end if

			seg_flush(STRING_COLOR)
			i = match_from("`", line, seg_end + 2)
			if i = 0 then
				ram_space[state][S_STRING_BACKTICK] = 1
				seg_end = length(line) - 1
				exit
			end if

			seg_end = i
			ram_space[state][S_STRING_BACKTICK] = 0

		else  -- QUOTE
			if line[seg_end + 2] = '"' and line[seg_end + 3] = '"' then
label "MULTILINE_STRING"
				seg_end += 1
				seg_flush(STRING_COLOR)
			
				if seg_end + 3 < length(line) then
					i = match_from(`"""`, line, seg_end + 3)
					if i = 0 then
						ram_space[state][S_STRING_TRIPLE] = 1
						seg_end = length(line) - 1
						exit
					end if
				else
					i = length(line)
					exit
				end if

				seg_end = i + 2
				ram_space[state][S_STRING_TRIPLE] = 0
			else
				i = seg_end + 2
				while i < length(line) do
					if line[i] = c then
						i += 1
						exit
					elsif line[i] = '\\' then
						if i < length(line)-1 then
							i += 1 -- ignore escaped char
						end if
					end if
					i += 1
				end while
				seg_flush(STRING_COLOR)
				seg_end = i - 1
			end if
		end if
	end while

	-- add the final piece:
	if current_color = DONT_CARE then
		current_color = NORMAL_COLOR
	end if

	return append(color_segments, {current_color, line[seg_start..seg_end]})
end function

new()
init_class()
