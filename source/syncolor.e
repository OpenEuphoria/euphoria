-- (c) Copyright - See License.txt
--
ifdef ETYPE_CHECK then
	with type_check
elsedef
	without type_check
end ifdef

include euphoria/syncolor.e

-- COLOR values -- for characters and pixels
constant 
	 BLACK = 0,  -- in graphics modes this is "transparent"
	 GREEN = 2,
	 MAGENTA = 5,
	 WHITE = 7,
	 GRAY  = 8,
	 BRIGHT_GREEN = 10,
	 BRIGHT_MAGENTA = 13,
	 BRIGHT_WHITE = 15
integer 
	 BLUE, CYAN, RED, BROWN, BRIGHT_BLUE, BRIGHT_CYAN, BRIGHT_RED, YELLOW

include platform.e

if TWINDOWS = 0 then
    BLUE  = 4
    CYAN =  6
    RED   = 1
    BROWN = 3
    BRIGHT_BLUE = 12
    BRIGHT_CYAN = 14
    BRIGHT_RED = 9
    YELLOW = 11
else
    BLUE  = 1
    CYAN =  3
    RED   = 4
    BROWN = 6
    BRIGHT_BLUE = 9
    BRIGHT_CYAN = 11
    BRIGHT_RED = 12
    YELLOW = 14
end if

-- colors needed by syncolor.e:
-- Adjust to suit your monitor and your taste.
constant NORMAL_COLOR = BLACK,   -- GRAY might look better
				COMMENT_COLOR = RED,
				KEYWORD_COLOR = BLUE,
				BUILTIN_COLOR = MAGENTA,
				STRING_COLOR = GREEN,   -- BROWN might look better
				BRACKET_COLOR = {NORMAL_COLOR, YELLOW, BRIGHT_WHITE, 
								 BRIGHT_BLUE, BRIGHT_RED, BRIGHT_CYAN, 
								 BRIGHT_GREEN}

atom synstate = syncolor:new()
syncolor:keep_newlines(,synstate)
		syncolor:set_colors({
				{"NORMAL", NORMAL_COLOR},
				{"COMMENT", COMMENT_COLOR},
				{"KEYWORD", KEYWORD_COLOR},
				{"BUILTIN", BUILTIN_COLOR},
				{"STRING", STRING_COLOR},
				{"BRACKET", BRACKET_COLOR}})	

public function DisplayColorLine(sequence pline, integer string_color)
	sequence line
	syncolor:set_colors({{"STRING", string_color}})
	line = syncolor:SyntaxColor(pline, synstate)
	for i = 1 to length(line) do
		--graphics:text_color(line[i][1])
		--machine_proc(9, line[i][1])
		machine_proc(201, line[i][1])
		--puts(2, line[i][2])
		machine_proc(200, line[i][2])
	end for
	return 0
end function
