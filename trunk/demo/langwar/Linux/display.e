-- display.e
-- graphics, sound and text display on screen

global sequence ship

global sequence ds -- Euphoria deflectors
global sequence ts -- Euphoria torpedos
global sequence ps -- Euphoria anti-matter pods 

global function c_remaining()
-- number of C ships (of all types) left
    return nobj[G_KRC] + nobj[G_ANC] + nobj[G_CPP]
end function

type negative_atom(atom x)
    return x <= 0
end type

global procedure p_energy(negative_atom delta)
-- print Euphoria energy
    atom energy

    energy = quadrant[EUPHORIA][Q_EN] + delta
    quadrant[EUPHORIA][Q_EN] = energy
    if energy < 0 then
	energy = 0
	gameover = TRUE
    end if
    position(WARP_LINE, ENERGY_POS+7)
    set_bk_color(WHITE)
    if energy < 5000 then
	set_color(RED+BLINKING)
    else
	set_color(BLACK)
    end if
    printf(CRT, "%d    ", floor(energy))
end procedure

global procedure task_life()
-- independent task: life support energy 
    if shuttle then
	p_energy(-3)
    else
	p_energy(-17)
    end if
end procedure

------------------------- message handler -----------------------------
-- All messages come here. A task ensures that messages will be displayed
-- on the screen for at least a second or so, before being overwritten by
-- the next message. If there is no queue, a message will be printed 
-- immediately, otherwise it is added to the queue. 
 
constant MESSAGE_GAP = 1.2  -- seconds between messages for readability

sequence message_queue
message_queue = {}

global procedure set_msg()
-- prepare to print a message
    set_bk_color(WHITE)
    set_color(RED)
    position(MSG_LINE, MSG_POS)
    puts(CRT, BLANK_LINE[1..50])
    position(MSG_LINE, MSG_POS)
end procedure

global procedure msg(sequence text)
-- print a plain text message on the message line
    if length(message_queue) = 0 then
	-- print it right away
	set_msg()
	puts(CRT, text)
	sched(TASK_MESSAGE, MESSAGE_GAP)        
    end if
    message_queue = append(message_queue, text)
end procedure

global procedure fmsg(sequence format, object values)
-- print a formatted message on the message line
    msg(sprintf(format, values))
end procedure

global procedure task_message()
-- task to display next message in message queue

    -- first message is already on the screen - delete it
    message_queue = message_queue[2..length(message_queue)]
    if length(message_queue) = 0 then
	wait[TASK_MESSAGE] = INACTIVE   -- deactivate this task
    else
	set_msg()
	puts(CRT, message_queue[1])
	wait[TASK_MESSAGE] = MESSAGE_GAP
    end if
end procedure

----------------------------------------------------------------------------

global procedure show_warp()
-- show current speed (with warning)
    set_bk_color(WHITE)
    set_color(BLACK)
    position(WARP_LINE, WARP_POS)
    puts(CRT, "WARP:")
    if curwarp > wlimit then
	set_color(RED+BLINKING)
    end if
    printf(CRT, "%d", curwarp)
end procedure

-- how long it takes Euphoria to move at warp 0 thru 5:
constant warp_time = {0, 20, 4.5, 1.5, .7, .25}

global procedure setwarp(warp new)
-- establish a new warp speed for the Euphoria

    if new != curwarp then
	wait[TASK_EMOVE] = warp_time[new+1]
	eat[TASK_EMOVE] = (5-new)/20 + 0.05
	sched(TASK_EMOVE, wait[TASK_EMOVE])
	curwarp = new
	show_warp()
    end if
end procedure

global procedure gtext()
-- print text portion of galaxy scan
    set_bk_color(BLUE)
    position(2, 37)
    set_color(BRIGHT_RED)
    puts(CRT, "C ")
    set_color(BROWN)
    puts(CRT, "P ")
    set_color(YELLOW)
    puts(CRT, "B")
    set_color(WHITE)
    position(3, 15)
    puts(CRT, "1       2       3       4       5       6       7")
    for i = 1 to 7 do
	position(2*i + 2, 10)
	printf(CRT, "%d.", i)
    end for
    position(18, 37)
    set_color(BRIGHT_WHITE)
    printf(CRT, "C: %d ", c_remaining())
    position(19, 24)
    set_color(WHITE)
    printf(CRT, "Planets: %d   BASIC: %d", {nobj[G_PL], nobj[G_BAS]})
    if bstat = TRUCE then
	puts(CRT, " TRUCE   ")
    elsif bstat = HOSTILE then
	puts(CRT, " HOSTILE ")
    else
	set_color(WHITE+BLINKING)
	puts(CRT, " CLOAKING")
	set_color(WHITE)
    end if
    position(20, 24)
    printf(CRT, "Bases: %d     Java: %d ", {nobj[G_BS], nobj[G_JAV]})
    position(20, 67)
    set_color(BLUE)
    set_bk_color(WHITE)
    if level = 'n' then
	puts(CRT, "NOVICE LEVEL")
    else
	puts(CRT, "EXPERT LEVEL")
    end if
end procedure

function source_of_energy(g_index qrow, g_index qcol, object_type t)
-- see if there is any energy left from planets / bases in this quadrant
    pb_row start, stop

    if t = G_BS then
	start = 1
	stop = NBASES
    else
	start = NBASES + 1
	stop = length(pb)
    end if
    for pbi = start to stop do
	if pb[pbi][P_TYPE] != DEAD then
	    if pb[pbi][P_QR] = qrow then
		if pb[pbi][P_QC] = qcol then
		    if pb[pbi][P_EN] > 0 then
			return TRUE
		    end if
		end if
	    end if
	end if
    end for
    return FALSE
end function

function g_screen_pos(g_index qrow, g_index qcol)
-- compute position on screen to display a galaxy scan quadrant
    return {5 + qcol * 8, qrow * 2 + 2}
end function

global procedure gquad(g_index qrow, g_index qcol)
-- print one galaxy scan quadrant

    natural nk, np, nb
    sequence quad_info
    screen_pos gpos

    gpos = g_screen_pos(qrow, qcol)
    position(gpos[2], gpos[1])
    quad_info = galaxy[qrow][qcol]
    if quad_info[1] then
	nk = quad_info[G_KRC] + quad_info[G_ANC] + quad_info[G_CPP]
	set_color(BRIGHT_RED)
	printf(CRT, "%d ", nk)

	np = quad_info[G_PL]
	if np = 0 then
	    set_color(BROWN)
	elsif source_of_energy(qrow, qcol, G_PL) then
	    set_color(BROWN)
	else
	    set_color(GRAY)
	end if
	printf(CRT, "%d ", np)

	nb = quad_info[G_BS]
	if nb = 0 then
	    set_color(YELLOW)
	elsif source_of_energy(qrow, qcol, G_BS) then
	    set_color(YELLOW)
	else
	    set_color(GRAY)
	end if
	printf(CRT, "%d",  nb)

	set_color(WHITE)
    else
	puts(CRT, "*****")
    end if
end procedure

global procedure upg(g_index qrow, g_index qcol)
-- update galaxy scan quadrant
    if scanon then
	set_bk_color(BLUE)
	set_color(WHITE)
	gquad(qrow, qcol)
    end if
end procedure

sequence prev_box
prev_box = {}

global procedure gsbox(g_index qrow, g_index qcol)
-- indicate current quadrant on galaxy scan
    screen_pos gpos

    if scanon then
	set_bk_color(BLUE)
	if length(prev_box) = 2 then
	    -- clear the previous "box" (could be gone already)
	    position(prev_box[2], prev_box[1]-1)
	    puts(CRT, ' ')
	    position(prev_box[2], prev_box[1]+5)
	    puts(CRT, ' ')
	end if
	set_color(WHITE)
	gquad(qrow, qcol)
	gpos = g_screen_pos(qrow, qcol)
	position(gpos[2], gpos[1]-1)
	set_color(BRIGHT_WHITE)
	puts(CRT, '[')
	position(gpos[2], gpos[1]+5)
	puts(CRT, ']')
	prev_box = gpos
    end if
end procedure

constant dir_places = {{1, 6},{0, 6},{0, 3},{0, 0},{1, 0},{2, 0},{2, 3},{2, 6}}

global procedure dir_box()
    -- direction box
    sequence place

    set_bk_color(RED)
    set_color(BLACK)
    position(WARP_LINE, DIRECTIONS_POS)
    puts(CRT, "4  3  2")
    position(CMD_LINE, DIRECTIONS_POS)
    puts(CRT, "5  +  1")
    position(MSG_LINE, DIRECTIONS_POS)
    puts(CRT, "6  7  8")
    place = dir_places[curdir]
    position(place[1]+WARP_LINE,place[2]+DIRECTIONS_POS) 
    set_bk_color(GREEN)
    printf(CRT, "%d", curdir)
    set_bk_color(WHITE)
end procedure

global procedure wtext()
-- print torpedos, pods, deflectors in text window
    set_bk_color(WHITE)
    set_color(BLACK)
    position(WARP_LINE, WEAPONS_POS)
    printf(CRT, "%s %s %s ", {ts, ds, ps}) 
end procedure

global procedure stext()
-- print text window info
    position(QUAD_LINE, 1)
    set_bk_color(CYAN)
    set_color(MAGENTA)
    printf(CRT,
    "--------------------------------- QUADRANT %d.%d ---------------------------------"
       ,{qrow, qcol})
    set_bk_color(WHITE)
    set_color(BLACK)
    show_warp()
    wtext()
    position(WARP_LINE, ENERGY_POS)
    printf(CRT, "ENERGY:%d    ", floor(quadrant[EUPHORIA][Q_EN]))
    position(CMD_LINE, CMD_POS-30)
    puts(CRT, "COMMAND(1-8 w p t a g $ ! x): ")
    dir_box()
end procedure

procedure p_source(valid_quadrant_row row)
-- print a base or planet
    h_coord x
    v_coord y

    x = quadrant[row][Q_X]
    y = quadrant[row][Q_Y]
    if quadrant[row][Q_TYPE] = G_PL then
	write_screen(x, y, PLANET_TOP)
	write_screen(x, y+1, PLANET_MIDDLE)
	write_screen(x, y+2, PLANET_BOTTOM)
    else
	write_screen(x, y, BASE)
	write_screen(x, y+1, BASE)
    end if
end procedure

procedure p_ship(valid_quadrant_row row)
-- reprint a ship to get color
    h_coord x
    v_coord y
    object_type t
    sequence shape

    x = quadrant[row][Q_X]
    y = quadrant[row][Q_Y]
    t = quadrant[row][Q_TYPE]
    shape = read_screen({x, length(ship[t][1])},  y)
    write_screen(x, y, shape)
end procedure

procedure refresh_obj()
-- reprint objects after a galaxy scan
    for i = 1 to length(quadrant) do
	if quadrant[i][Q_TYPE] = G_BS or quadrant[i][Q_TYPE] = G_PL then
	    p_source(i)
	elsif quadrant[i][Q_TYPE] != DEAD then
	    p_ship(i)
	end if
    end for
end procedure

global procedure setg1()
-- end display of galaxy scan
    if scanon then
	scanon = FALSE
	ShowScreen()
	refresh_obj()
    end if
end procedure


global procedure pobj()
-- print objects in a new quadrant
    h_coord x
    v_coord y
    sequence c
    natural len
    object_type t
    sequence taken

    set_bk_color(BLACK)
    set_color(WHITE)
    BlankScreen(TRUE)

    -- print stars
    for i = 1 to 15 do
	write_screen(rand(HSIZE), rand(VSIZE), STAR)
    end for

    -- print planets and bases
    taken = {}
    for row = 2 to length(quadrant) do
	if find(quadrant[row][Q_TYPE], {G_PL, G_BS}) then
	    -- look it up in pb sequence
	    for pbi = 1 to length(pb) do
		if pb[pbi][P_TYPE] = quadrant[row][Q_TYPE] then
		    if pb[pbi][P_QR] = qrow and pb[pbi][P_QC] = qcol then
			if not find(pbi, taken) then
			    quadrant[row][Q_X] = pb[pbi][P_X]
			    quadrant[row][Q_Y] = pb[pbi][P_Y]
			    quadrant[row][Q_PBX] = pbi
			    taken = taken & pbi
			    exit
			end if
		    end if
		end if
	    end for
	    p_source(row)
	end if
    end for

    -- print ships
    for row = 2 to length(quadrant) do
	if not find(quadrant[row][Q_TYPE], {G_PL, G_BS})  then
	    len = length(ship[quadrant[row][Q_TYPE]][1])
	    while TRUE do
		-- look for an empty place to put the ship
		x = rand(HSIZE - len - 5) + 3 -- allow space for Euphoria to enter
		y = rand(VSIZE - 2) + 1
		c = read_screen({x, len}, y)
		if not find(FALSE, c = ' ' or c = STAR) then
		    exit
		end if
	    end while
	    quadrant[row][Q_UNDER] = c
	    quadrant[row][Q_X] = x
	    quadrant[row][Q_Y] = y
	    t = quadrant[row][Q_TYPE]
	    if x < quadrant[EUPHORIA][Q_X] then
		c = ship[t][2]
	    else
		c = ship[t][1]
	    end if
	    write_screen(x, y, c)
	end if
    end for
end procedure
