-- screen.e: access to the screen

	      ---------------------
	      -- graphics screen --
	      ---------------------
-- in calls to read_screen and write_screen
-- the screen looks like:

-- (1,1)..................(1,HSIZE)
-- ................................
-- ................................
-- (VSIZE,1)..........(VSIZE,HSIZE)

-- "y" (second arg) is the row or line starting from the top
-- "x" (first arg) is the character position starting at the left
--  within the y-line. This is consistent with the TRS-80 version.

-- However, for better efficiency in Euphoria, the screen variable
-- is implemented such that the first subscript selects the line
-- and the second selects the character within that line. This helps
-- when multiple characters are read or written on one line, since
-- we can use a slice.

integer mono_monitor
global integer max_lines

sequence vc
vc = video_config()
mono_monitor = not vc[VC_COLOR]
max_lines = vc[VC_LINES]


global constant HSIZE = 80,            -- horizontal size (char positions)
		VSIZE = max_lines - 4   -- vertical size (lines)


global type h_coord(integer x)
-- true if x is a horizontal screen coordinate
    return x >= 1 and x <= HSIZE
end type

global type v_coord(integer y)
-- true if y is a vertical screen coordinate
    return y >= 1 and y <= VSIZE
end type

global type extended_h_coord(atom x)
    -- horizontal coordinate, can be slightly off screen
    return x >= -10 and x <= HSIZE + 10
end type

global type extended_v_coord(atom y)
    -- vertical coordinate, can be slightly off screen
    return y >= -10 and y <= VSIZE + 10
end type

global type screen_pos(sequence x)
-- true if x is a valid screen position
-- n.b. position() wants to see (x[2],x[1])
    return length(x) = 2 and h_coord(x[1]) and v_coord(x[2])
end type

sequence screen

integer last_text_color
last_text_color = -1

global procedure set_color(integer color)
-- all foreground color changes come through here
    if mono_monitor then
	return
    else
	if color != last_text_color then
	    text_color(color)
	end if
	last_text_color = color
    end if
end procedure

integer last_bk_color
last_bk_color = -1

global procedure set_bk_color(integer color)
-- all background color changes come through here
    if mono_monitor then
	return
    else
	if color != last_bk_color then
	    bk_color(color)
	end if
	last_bk_color = color
    end if
end procedure


global boolean scanon -- galaxy scan on/off

global function read_screen(object x,
			    v_coord y)
-- return one or more characters at logical position (x, y)
    if atom(x) then
	return screen[y][x]
    else
	return screen[y][x[1]..x[1]+x[2]-1]
    end if
end function

global sequence object_color 
object_color =          {
			YELLOW, YELLOW,
			BRIGHT_BLUE, BRIGHT_BLUE,
			BRIGHT_RED, BRIGHT_RED,
			BRIGHT_RED, BRIGHT_RED,
			BRIGHT_GREEN, BRIGHT_GREEN,
			BROWN,
			BROWN,
			YELLOW, YELLOW,
			YELLOW,
			BRIGHT_MAGENTA, BRIGHT_MAGENTA
			}

constant shape_list =   {
			EUPHORIA_L, EUPHORIA_R,
			BASIC_L, BASIC_R,
			KRC_L, KRC_R,
			ANC_L, ANC_R,
			JAVA_L, JAVA_R,
			PLANET_TOP,
			PLANET_MIDDLE,
			SHUTTLE_L, SHUTTLE_R,
			BASE,
			CPP_L, CPP_R
			}

global constant BASIC_COL = find(BASIC_L, shape_list)

function which_color(object shape)
-- Return color for an object based on its "shape".
-- This makes it easy to add color to this old mono TRS-80 program.
    integer object_number

    if atom(shape) then
	if shape = '+' or shape = '-' then
	    return object_color[9] -- Java phasor
	elsif shape = '*' or shape = '@' then
	    return BRIGHT_WHITE
	else
	    return WHITE
	end if
    end if
    object_number = find(shape, shape_list)
    if object_number then
	return object_color[object_number]
    else
	return WHITE -- not found (blanks, stars)
    end if
end function

global procedure write_screen(h_coord x, v_coord y, object c)
-- write a character or string to the screen variable
-- and to the physical screen

    if atom(c) then
	screen[y][x] = c
    else
	screen[y][x..x+length(c)-1] = c
    end if
    if not scanon then
	set_bk_color(BLACK)
	set_color(which_color(c))
	position(y, x)
	puts(CRT, c)
    end if
end procedure

global procedure display_screen(h_coord x, v_coord y, object c)
-- display a character or string on the screen, but it does not affect
-- the logic of the game at all (blank is actually stored)
    if atom(c) then
	screen[y][x] = ' '
    else
	screen[y][x..x + length(c) - 1] = ' '
    end if
    if not scanon then
	position(y, x)
	puts(CRT, c)
    end if
end procedure

global constant BLANK_LINE = repeat(' ', HSIZE)

global procedure BlankScreen(boolean var_too)
-- set physical upper screen to all blanks
-- and optionally blank the screen variable too
-- initially the screen variable is undefined

    if not scanon then
	for i = 1 to VSIZE do
	    position(i, 1)
	    puts(CRT, BLANK_LINE) -- blank upper 3/4 of screen
	end for
    end if
    if var_too then
	screen = repeat(BLANK_LINE, VSIZE) -- new blank screen
    end if
end procedure

global procedure ShowScreen()
-- rewrite screen after galaxy scan
    set_bk_color(BLACK)
    set_color(WHITE)
    position(1, 1)
    for i = 1 to VSIZE do
	position(i, 1)
	puts(CRT, screen[i])
    end for
end procedure

	   ----------------------------
	   -- text portion of screen --
	   ----------------------------

global constant QUAD_LINE = VSIZE + 1,
		WARP_LINE = VSIZE + 2,
		CMD_LINE  = VSIZE + 3,
		MSG_LINE  = VSIZE + 4

global constant CMD_POS = 39,     -- place for first char of user command
	       WARP_POS = 9,      -- place for "WARP:" to appear
	       DREP_POS = 51,     -- place for damage report
	       WEAPONS_POS = 34,  -- place for torpedos/pos/deflectors display
	       ENERGY_POS = 67,   -- place for ENERGY display
	       MSG_POS = 16,      -- place for messages to start
	       DIRECTIONS_POS = 1 -- place to put directions

