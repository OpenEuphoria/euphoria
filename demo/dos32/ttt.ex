		-------------------------------
		-- 3-Dimensional Tic Tac Toe --
		-------------------------------

-- Play 3 dimensional tic-tac-toe against one of two computer algorithms
-- or against another human -- or let the two computer algorithms play
-- each other. Which algorithm is better?

-- How it Works:
-- * There are two major data structures. positions describes each board 
--   position. lines describes each possible winning line of 4 positions  
--   in a row.
-- * ttt keeps a close eye on the lines data structure, looking first for
--   lines where it has 3 of the 4 positions, and the 4th is empty. If it
--   finds one of those, it wins (don't worry - it *will* always find it
--   if it's there!)
-- * If it can't win right away, it looks for lines where *you* have 3
--   positions and the 4th is empty. It will take the empty position to block
--   you.
-- * After that, it looks for various forced-win patterns for itself and
--   for you, e.g. creating two winning lines of 3 with one move.
-- * If it can't find any winning patterns, it evaluates each remaining
--   free position and assigns it a score, based on how many possibilities
--   are created by that position. This is where "DEFENDO" and "AGGRESSO"
--   differ in their strategies. AGGRESSO is more concerned with its
--   own possibilities of winning than with blocking your possibilities.

include graphics.e
include mouse.e
include wildcard.e
include sequence.e

constant TRUE = 1, FALSE = 0
constant ON = 1, OFF = 0

constant COLORS = {BRIGHT_RED, BRIGHT_GREEN, YELLOW, BRIGHT_MAGENTA}

sequence pcolors -- colors of circular markers
pcolors = {BRIGHT_BLUE, BRIGHT_WHITE}

constant SQUARE_SIZE = 24

constant TOP_LEFT = {240, 26}

constant KEYB = 0, SCREEN = 1  -- I/O devices

constant
    NPOSITIONS = 64,  -- number of board positions
	NLINES = 76   -- number of 4-in-a-row lines

type line(integer x)
    return x >= 0 and x <= NLINES
end type

type Position(integer x)
    return x >= 0 or x <= NPOSITIONS
end type

type all_positions(sequence x)
    return length(x) = NPOSITIONS
end type

type all_lines(sequence x)
    return length(x) = NLINES
end type

type boolean(integer x)
    return x = TRUE or x = FALSE
end type

type players(sequence x)
    return length(x) = 4
end type

type player_number(integer x)
    return x = 1 or x = 2
end type

type positive_int(integer x)
    return x >= 1
end type

type natural(integer x)
    return x >= 0
end type

type human_count(integer x)
    return x >=0 and x <= 2
end type

type move_value(integer x)
    return integer(x) and x >= -1
end type

type time_delay(integer x)
    return x >= 0 and x < 1000
end type

type reason_number(integer x)
    return x >= 1 and x <= 10
end type

type three_digits(sequence x)
    return length(x) = 3
end type

type move_number(integer x)
    return x >= 111 and x <= 444
end type

all_positions positions
    -- positions is a list of all the board positions

constant
    -- positions 2-d sequence columns:
    LINES_THRU = 1, -- the number of lines passing through this position
    LINE1 = 2,      -- the first of up to 7 lines passing
		    -- through this position
    NLIVE = 9,      -- the number of "live" lines passing through this position
    NEXTP = 10,     -- index of next position (or 0)
    PREVP = 11,     -- index of previous position (or 0)
    AVAIL = 12      -- is this position available, 1 = yes, 0 = no

all_lines lines     -- lines is a list of all the lines of 4 positions in a row
		    -- it is indexed from 1 to NLINES

constant
    -- lines 2-d sequence columns:
    COUNT = 1,   -- number of "live" markers on this line
    POS1 = 2,    -- first position of 4
    POS4 = 5,    -- last position
    NEXTL = 6,   -- index of next line (or 0)
    PREVL = 7,   -- index of previous line (or 0)
    STATUS = 8,  -- status of this line
	-- possible status of a line:
	EMPTY = 0,
	COMPUTER = 1,
	HUMAN = 2,
	DEAD = 3

sequence lp       -- L->P format
all_positions pl  -- P->L format
sequence dbl      -- used in 3x3 check
players ptype,    -- player types
	pname     -- player names

line fptr,  -- free position list
     cptr,  -- computer's line list
     hptr,  -- human's line list
     eptr   -- empty line list
player_number player
natural cmoves, hmoves, l2
boolean endgame, found
human_count humans
move_value bestval
atom x

procedure Delay(time_delay t)
-- waste some time
    atom t0

    if humans = 0 and endgame = FALSE then
	return
    end if
    t0 = time()
    while time() < t0 + t/700 do
    end while
end procedure

procedure Why(reason_number reason)
-- show the reason why the computer made its move
    position(22, 11)
    if reason = 1 then
	puts(SCREEN, "BLOCK 3 IN A ROW")
    elsif reason = 2 then
	puts(SCREEN, "FORCE 3X3       ")
    elsif reason = 3 then
	puts(SCREEN, "FORCE 3-2-2-1   ")
    elsif reason = 4 then
	puts(SCREEN, "FORCE 3-2-2     ")
    elsif reason = 5 then
	puts(SCREEN, "PREVENT 3X3     ")
    elsif reason = 6 then
	puts(SCREEN, "PREVENT 3-2-2-1 ")
    elsif reason = 7 then
	puts(SCREEN, "PREVENT 3-2-2   ")
    elsif reason = 8 then
	printf(SCREEN, "VALUE=%d         ", bestval)
    else
	puts(SCREEN, "                ")
    end if
end procedure


function Get4th()
-- grab the final winning 4th position in a line
integer pos
    for z = POS1 to POS4 do
	pos = lines[x][z]
	if positions[lp[pos]][AVAIL] = 0 then
	    return pos
	end if
    end for
end function


function Find2()
-- Find two lines that intersect where I have 2 markers on each line.
-- I can take the intersection and create two lines of 3 at once.
integer pos
    for z = POS1 to POS4 do
	pos = lines[x][z]
	if positions[lp[pos]][AVAIL] = 0 then
	    dbl[l2] = pos
	    l2 += 1
	end if
    end for
    if l2 < 4 then
	return 0
    end if
    for z = l2 - 2 to l2 - 1 do
	for z1 = 1 to l2 - 3 do
	    if dbl[z] = dbl[z1] then
		found = TRUE
		return dbl[z]
	    end if
	end for
    end for
    return 0
end function


function FindA()
-- find forcing pattern "A"
integer k, z1, line, zz
    k = 0
    for z = POS1 to POS4 do
	z1 = lp[lines[x][z]]
	for i = LINE1 to positions[z1][LINES_THRU] + 1 do
	    line = positions[z1][i]
	    if lines[line][STATUS] = l2 then
		if lines[line][COUNT] = 2 then
		    k += 1
		    exit
		end if
	    end if
	end for
	if k = 3 then
	    zz = z
	    exit
	end if
    end for
    if k = 3 then
	found = TRUE
	return lines[x][zz]
    end if
    return 0
end function


function FindB()
-- find forcing pattern "B"
integer k, z1, line
    k = 0
    for z = POS1 to POS4 do
	z1 = lp[lines[x][z]]
	if positions[z1][AVAIL] = 0 then
	    for i = LINE1 to positions[z1][LINES_THRU] + 1 do
		line = positions[z1][i]
		if lines[line][STATUS] = l2 then
		    if lines[line][COUNT] = 2 then
			k += 1
			exit
		    end if
		end if
	    end for
	    if k = 2 then
		found = TRUE
		return lines[x][z]
	    end if
	end if
    end for
    return 0
end function


function FindMax()
-- find best free position
integer i, bestm
    i = fptr
    bestval = -1
    while i do
	if positions[i][NLIVE] > bestval then
	    bestval = positions[i][NLIVE]
	    bestm = i
	elsif positions[i][NLIVE] = bestval then
	    if rand(7) = 1 then
		bestm = i
	    end if
	end if
	i = positions[i][NEXTP]
    end while
    return pl[bestm]
end function

function mouse_square(sequence spot)
-- map x,y mouse coordinate to plane, row, column
    integer x, y
    natural m

    spot -= TOP_LEFT
    x = spot[1]
    y = spot[2]
    -- which plane are we on?
    m = 111
    while y > 4 * SQUARE_SIZE do
	y -= 4.5 * SQUARE_SIZE
	x -= 2.5 * SQUARE_SIZE
	m += 100
    end while
    -- which row are we on?
    while y > SQUARE_SIZE do
	y -= SQUARE_SIZE
	m += 10
    end while
    if x > 4 * SQUARE_SIZE then
	return 0 
    end if
    -- which column are we on?
    while x > SQUARE_SIZE do
	x -= SQUARE_SIZE
	m += 1
    end while
    if x < 0 or y < 0 then
	return 0
    else
	return m
    end if
end function


function GetMove()
-- get human's move via the mouse
    natural m
    object event

    while TRUE do
	position(20, 1)
	puts(SCREEN, repeat(' ', 30))
	position(20, 1)
	puts(SCREEN, ' ' & pname[player])
	puts(SCREEN, "'s move? ")
	event = -1
	while atom(event) do
	    event = get_mouse()
	    if get_key() != -1 then
		if graphics_mode(-1) then
		end if
		abort(1)
	    end if
	end while
	m = mouse_square(event[2..3])
	if m >= 111 and m <= 444 then
	    if lp[m] then
		if positions[lp[m]][AVAIL] = 0 then
		    position(20, 1)
		    puts(SCREEN, repeat(' ', 30))
		    exit
		end if
	    end if
	end if
    end while
    return m
end function


procedure AdjValues(integer x, integer delta)
-- adjust the "value" of positions along a line
integer pos
    for z = POS1 to POS4 do
	pos = lp[lines[x][z]]
	positions[pos][NLIVE] += delta
    end for
end procedure


procedure Relink(integer player, integer x)
-- adjust some data structures after a move
    line prev, next

    next = lines[x][NEXTL]
    prev = lines[x][PREVL]

    if player = COMPUTER then
	AdjValues(x, 1)
	lines[x][NEXTL] = cptr
	lines[x][PREVL] = 0
	if cptr then
	    lines[cptr][PREVL] = x
	end if
	cptr = x
    else
	lines[x][NEXTL] = hptr
	lines[x][PREVL] = 0
	if hptr then
	    lines[hptr][PREVL] = x
	end if
	hptr = x
    end if
    if prev then
	lines[prev][NEXTL] = next
	if next then
	    lines[next][PREVL] = prev
	end if
    else
	eptr = next
	if eptr then
	    lines[eptr][PREVL] = 0
	end if
    end if
end procedure

function digits(natural x)
-- return the 3-digits in number x
    three_digits d

    d = {0, 0, 0}
    while x >= 100 do
	d[1] += 1
	x -= 100
    end while

    while x >= 10 do
	d[2] += 1
	x -= 10
    end while

    d[3] = x
    return d
end function


procedure PrintMove(move_number move)
-- print the move that was just made
    three_digits d
    integer px, py

    d = digits(move)
    py = (d[1] - 1) * 4.5 * SQUARE_SIZE + (d[2]-1) * SQUARE_SIZE + TOP_LEFT[2]
    px = (d[1] - 1) * 2.5 * SQUARE_SIZE + (d[3]-1) * SQUARE_SIZE + TOP_LEFT[1]
    mouse_pointer(OFF)
    for i = 1 to 3 do
	ellipse(GRAY, 1, {px+1, py+1}, 
		      {px + SQUARE_SIZE - 2, py + SQUARE_SIZE - 2})
	Delay(70)
	ellipse(pcolors[player], 1, {px+1, py+1}, 
				    {px + SQUARE_SIZE - 2, py + SQUARE_SIZE - 2})
	Delay(70)
    end for
    mouse_pointer(ON)
    if endgame then
	return
    end if
    if player = COMPUTER then
	cmoves += 1
    else
	hmoves += 1
    end if
end procedure


procedure Another(line x)
-- add to the number of positions occupied by a player
-- along a line x
    integer inarow

    inarow = lines[x][COUNT] + 1
    lines[x][COUNT] = inarow
    if inarow < 4 then
	return
    end if
    position(21,6)
    text_color(BRIGHT_RED)
    puts(SCREEN, pname[player])
    puts(SCREEN, " WINS!          ")
    text_color(YELLOW)
    endgame = TRUE
    mouse_pointer(OFF)
    for i = 1 to 4 do
	for j = POS1 to POS4 do
	    PrintMove(lines[x][j])
	end for
	Delay(80)
    end for
    mouse_pointer(ON)
end procedure


procedure Delete_c(line x)
-- delete from computer list
    line prev, next

    prev = lines[x][PREVL]
    next = lines[x][NEXTL]
    if prev then
	lines[prev][NEXTL] = next
    else
	cptr = next
    end if
    if next then
	lines[next][PREVL] = prev
    end if
end procedure


procedure Delete_h(line x)
-- delete from human list
    line prev, next

    prev = lines[x][PREVL]
    next = lines[x][NEXTL]
    if prev then
	lines[prev][NEXTL] = next
    else
	hptr = next
    end if
    if next then
	lines[next][PREVL] = prev
    end if
end procedure


procedure init()
-- initialize variables
    integer temp, u, line, t

    clear_screen()
    endgame = FALSE
    cmoves = 0
    hmoves = 0
    for i = 1 to NLINES do
	lines[i][STATUS] = EMPTY
	lines[i][COUNT] = 0
    end for
    for i = 1 to NPOSITIONS do
	positions[i][LINES_THRU] = 0
	positions[i][AVAIL] = 0
    end for
    line = 1
    for i = POS1 to POS4 do
	lines[line][i] = (i-1) * 111
	lines[line+1][i] = (i-1) * 109 + 5
	lines[line+2][i] = (i-1) * 91 + 50
	lines[line+3][i] = (i-1) * 89 + 55
    end for
    line += 4
    for i = 1 to 4 do
	for j = POS1 to POS4 do
	    lines[line][j] = i * 100 + (j-1) * 11
	    lines[line+1][j] = i * 100 + (j-1) * 9 + 5
	    lines[line+2][j] = (j-1) * 101 + i * 10
	    lines[line+3][j] = (j-1) * 99 + i * 10 + 5
	    lines[line+4][j] = (j-1) * 110 + i
	    lines[line+5][j] = (j-1) * 90 + 50 + i
	end for
	line += 6
    end for
    for i = 1 to 4 do
	for j = 1 to 4 do
	    for k = POS1 to POS4 do
		t = 100 * i + 10 * j + k - 1
		u = (i - 1) * 16 + (j - 1) * 4 + k - 1
		lp[t] = u
		pl[u] = t
		lines[line][k] = t
		lines[line+1][k] = 100 * j + 10 * (k-1) + i
		lines[line+2][k] = 100 * (k-1) + 10 * i + j
	    end for
	    line += 3
	end for
    end for
    for i = 1 to NPOSITIONS do
	positions[i][PREVP] = i - 1
	positions[i][NEXTP] = i + 1
    end for
    positions[1][PREVP] = 0
    positions[NPOSITIONS][NEXTP] = 0
    fptr = 1
    for i = 1 to NLINES do
	lines[i][NEXTL] = i + 1
	lines[i][PREVL] = i - 1
	for j = POS1 to POS4 do
	    t = lines[i][j]
	    u = lp[t]
	    temp = positions[u][LINES_THRU] + 1
	    positions[u][LINES_THRU] = temp
	    positions[u][temp+1] = i
	end for
    end for
    cptr = 0
    hptr = 0
    eptr = 0
    lines[NLINES][NEXTL] = 0
    lines[1][PREVL] = 0
    for i = 1 to NPOSITIONS do
	positions[i][NLIVE] = positions[i][LINES_THRU]
    end for
    position(15, 2)
    text_color(COLORS[1])
    puts(SCREEN, "3-D ")
    text_color(COLORS[2])
    puts(SCREEN, "tic ")
    text_color(COLORS[3])
    puts(SCREEN, "TAC ")
    text_color(COLORS[4])
    puts(SCREEN, "toe ")
end procedure


procedure UpdateMove(move_number m)
-- update data structures after making move m
    Position x1
    line x2
    integer prev, next, val, s

    x1 = lp[m]
    positions[x1][AVAIL] = 1
    prev = positions[x1][PREVP]
    next = positions[x1][NEXTP]
    if prev then
	positions[prev][NEXTP] = next
	if next then
	    positions[next][PREVP] = prev
	end if
    else
	fptr = next
	if fptr then
	    positions[fptr][PREVP] = 0
	end if
    end if
    for j = LINE1 to 1+positions[x1][LINES_THRU] do
	x2 = positions[x1][j]
	s = lines[x2][STATUS]
	if s = EMPTY then
	    lines[x2][STATUS] = player
	    lines[x2][COUNT] = 1
	    Relink(player, x2)
	elsif s = COMPUTER then
	    if player = COMPUTER then
		Another(x2)
	    else
		lines[x2][STATUS] = DEAD
		AdjValues(x2, -2)
		Delete_c(x2)
	    end if
	elsif s = HUMAN then
	    if player = HUMAN then
		Another(x2)
		if lines[x2][COUNT] = 2 then
		    val = 4
		else
		    val = 0
		end if
		AdjValues(x2, val)
	    else
		if lines[x2][COUNT] > 1 then
		    val = -5
		else
		    val = -1
		end if
		lines[x2][STATUS] = DEAD
		AdjValues(x2, val)
		Delete_h(x2)
	    end if
	end if
    end for
end procedure


function Think()
-- pick the best move, return {move, reason for it}
    integer m, mymoves, myptr, me, him, hisptr, hismoves

    found = FALSE
    if player = COMPUTER then
	mymoves = cmoves
	hismoves = hmoves
	myptr = cptr
	hisptr = hptr
	me = COMPUTER
	him = HUMAN
    else
	mymoves = hmoves
	hismoves = cmoves
	myptr = hptr
	hisptr = cptr
	me = HUMAN
	him = COMPUTER
    end if

    -- Have I got 3 in a row?
    if mymoves >= 3 then
	x = myptr
	while x do
	    if lines[x][COUNT] = 3 then
		return {Get4th(), 9}
	    end if
	    x = lines[x][NEXTL]
	end while
    end if

    -- Does the other guy have 3 in a row?
    if hismoves >= 3 then
	x = hisptr
	while x do
	    if lines[x][COUNT] = 3 then
		return {Get4th(), 1}
	    end if
	    x = lines[x][NEXTL]
	end while
    end if

    -- Do I have a 2x2 force?
    if mymoves >= 4 then
	x = myptr
	l2 = 1
	while x do
	    if lines[x][COUNT] = 2 then
		m = Find2()
		if found then
		    return {m, 2}
		end if
	    end if
	    x = lines[x][NEXTL]
	end while

	-- Do I have a 3-2-2-1 force ?
	x = eptr
	l2 = me
	while x do
	    m = FindA()
	    if found then
		return {m, 3}
	    end if
	    x = lines[x][NEXTL]
	end while

	-- do I have a 3-2-2 force?
	if mymoves >= 5 then
	    x = myptr
	    while x do
		if lines[x][COUNT] = 1 then
		    m = FindB()
		    if found then
			return {m, 4}
		    end if
		end if
		x = lines[x][NEXTL]
	    end while
	end if
    end if

    -- does the other guy have a 2x2 force?
    if hismoves >= 4 then
	x = hisptr
	l2 = 1
	while x do
	    if lines[x][COUNT] = 2 then
		m = Find2()
		if found then
		    return {m, 5}
		end if
	    end if
	    x = lines[x][NEXTL]
	end while

	-- does the other guy have a 3-2-2-1 force?
	x = eptr
	l2 = him
	while x do
	    m = FindA()
	    if found then
		return {m, 6}
	    end if
	    x = lines[x][NEXTL]
	end while

	-- does the other guy have a 3-2-2 force?
	if hismoves >= 5 then
	    x = hisptr
	    while x do
		if lines[x][COUNT] = 1 then
		    m = FindB()
		    if found then
			return {m, 7}
		    end if
		end if
		x = lines[x][NEXTL]
	    end while
	end if
    end if
    -- just pick the move with the most possibilities
    return {FindMax(), 8}
end function


procedure Setup()
-- create major sequences
    object name

    positions = repeat(repeat(0, 12), NPOSITIONS)
    lines = repeat(repeat(0, 8), NLINES)
    lp = repeat(0, 444)
    pl = repeat(0, 64)
    dbl = repeat(0, 52)
    ptype = repeat(0, 4)
    pname = ptype
    ptype[1] = COMPUTER
    ptype[2] = COMPUTER
    pname[1] = "DEFENDO"
    pname[2] = "AGGRESSO"
    position(15, 1)
    puts(SCREEN, " Name of player 1? (cr for DEFENDO) ")
    name = gets(KEYB)
    if atom(name) then
	name = ""
    else
	name = name[1..length(name)-1]
    end if
    humans = 0
    if length(name) > 0 then
	pname[1] = name
	ptype[1] = HUMAN
	humans += 1
    end if
    puts(SCREEN, "\n Name of player 2? (cr for AGGRESSO) ")
    name = gets(KEYB)
    if atom(name) then
	name = ""
    else
	name = name[1..length(name)-1]
    end if
    if (length(name) > 0) then
	pname[2] = name
	ptype[2] = HUMAN
	humans += 1
    end if
end procedure

procedure draw_plane(integer color, integer x, integer y)
-- draw one plane of the board
     for i = 0 to 4 do
	draw_line(color, {{x, y+i*SQUARE_SIZE}, 
			  {x+4*SQUARE_SIZE, y+i*SQUARE_SIZE}})
     end for
     for i = 0 to 4 do
	draw_line(color, {{x+i*SQUARE_SIZE, y},
			  {x+i*SQUARE_SIZE, y+4*SQUARE_SIZE}})
     end for
end procedure

procedure make_board(sequence top_left)
-- display the board
    bk_color(8)
    for i = 0 to 3 do
	draw_plane(COLORS[i+1], top_left[1]+2.5*SQUARE_SIZE*i, 
				top_left[2]+4.5*SQUARE_SIZE*i)
    end for
end procedure

procedure ttt()
-- this is the main routine
    sequence m
    object answer
    
    Setup()
    player = rand(2) -- first game is random 
		     -- loser goes first in subsequent games
    while TRUE do
	mouse_pointer(OFF)
	init()
	make_board(TOP_LEFT)
	mouse_pointer(ON)
	text_color(YELLOW)
	mouse_events(LEFT_DOWN)
	while endgame = FALSE do
	    if fptr then
		if ptype[player] = HUMAN then
		    m = {GetMove()}
		else
		    m = Think()
		    Why(m[2])
		end if
		PrintMove(m[1])
		UpdateMove(m[1])
		player = 3 - player
	    else
		position(18,1)
		puts(SCREEN, " A DRAW             ")
		Delay(500)
		exit
	    end if
	end while
	position(19, 1)
	text_color(BRIGHT_MAGENTA)
	puts(SCREEN, " Another game? (y or n) ")
	text_color(YELLOW)
	answer = gets(KEYB)
	if atom(answer) or not find('y', lower(answer)) then
	    exit
	end if
    end while
end procedure

if graphics_mode(18) then -- VGA
    puts(1, "VGA graphics is required\n")
else
    ttt()
end if

if graphics_mode(-1) then
end if

