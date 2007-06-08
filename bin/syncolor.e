-- (c) Copyright 2007 Rapid Deployment Software - See License.txt
--
--              Syntax Color
-- Break Euphoria statements into words with multiple colors. 
-- The editor and pretty printer (eprint.ex) both use this file.

-- The user must define the following symbols to be colors for the
-- various syntax classes:
--       NORMAL_COLOR
--      COMMENT_COLOR
--      KEYWORD_COLOR
--      BUILTIN_COLOR
--       STRING_COLOR
--      BRACKET_COLOR  (a sequence of colors)

include keywords.e

-- character classes
constant DIGIT = 1,
	 OTHER = 2,
	 LETTER  = 3,
	 BRACKET = 4,
	 QUOTE   = 5,
	 DASH = 6,
	 WHITE_SPACE = 7,
	 NEW_LINE = 8

sequence char_class

global procedure init_class()
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
    char_class[' '] = WHITE_SPACE
    char_class['\t'] = WHITE_SPACE
    char_class['\r'] = WHITE_SPACE
    char_class['\n'] = NEW_LINE
    char_class['-'] = DASH
end procedure

constant DONT_CARE = -1  -- any color is ok - blanks, tabs

sequence line  -- the line being processed
integer seg_start, seg_end -- start and end of current segment of line
integer current_color
sequence color_segments -- the value returned

procedure seg_flush(integer new_color)
-- if the color must change, 
-- add the current color segment to the sequence
-- and start a new segment
    if new_color != current_color then
	if current_color != DONT_CARE then
	    color_segments = append(color_segments, 
				    {current_color, line[seg_start..seg_end]})
	    seg_start = seg_end + 1
	end if
	current_color = new_color
    end if
end procedure

global function SyntaxColor(sequence pline)
-- Break up a '\n'-terminated line into colored text segments identifying the
-- various parts of the Euphoria language.
-- Consecutive characters of the same color are all placed in the
-- same 'segment' - seg_start..seg_end.
-- A sequence is returned that looks like:
--     {{color1, "text1"}, {color2, "text2"}, ... }
    integer class, last, i, c, bracket_level
    sequence word

    line = pline
    current_color = DONT_CARE
    bracket_level = 0
    seg_start = 1
    seg_end = 0
    color_segments = {}
    
    while 1 do
	c = line[seg_end+1]
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
		bracket_level += 1
	    end if
	    if bracket_level >= 1 and
	       bracket_level <= length(BRACKET_COLOR) then
		seg_flush(BRACKET_COLOR[bracket_level])
	    else
		seg_flush(NORMAL_COLOR)
	    end if
	    if find(c, ")]}") then
		bracket_level -= 1
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

	else  -- QUOTE
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
    end while
    -- add the final piece:
    if current_color = DONT_CARE then
	current_color = NORMAL_COLOR
    end if
    return append(color_segments, {current_color, line[seg_start..seg_end]})
end function

