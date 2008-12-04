-- display.e
-- graphics, sound and text display on screen
include std/graphcst.e
include std/dos/pixels.e
include vars.e
include screen.e
include pictures.e

public sequence oshape -- images for all objects

public sequence ds -- Euphoria deflectors
public sequence ts -- Euphoria torpedos
public sequence ps -- Euphoria anti-matter pods

public boolean gameover
public integer quad_count
quad_count = 0 -- counter for number of quadrants entered (so tasks know
           -- when we've switched quadrants)

public function c_remaining()
-- number of C ships (of all types) left
    return nobj[G_KRC] + nobj[G_ANC] + nobj[G_CPP]
end function

public procedure euphoria_color(natural c)
-- change color of EUPHORIA
    esym  += (esym != 32) * (c - esym)
    esyml += (esyml != 32) * (c - esyml)
    esymr += (esymr != 32) * (c - esymr)
end procedure

public procedure stop_game()
-- the game is over - Euphoria ship is dead, or all C's are dead

    euphoria_color(YELLOW)
    gameover = TRUE -- will shut down most tasks

    -- schedule top-level task
    -- while explosions, messages etc. die down
    task_schedule(0, {2, 3})
end procedure

type negative_atom(atom x)
    return x <= 0
end type

public procedure p_energy(negative_atom delta)
-- print Euphoria energy
    atom energy

    energy = quadrant[EUPHORIA][Q_EN] + delta
    quadrant[EUPHORIA][Q_EN] = energy
    if energy < 0 then
    energy = 0
    stop_game()
    end if

    position(WARP_LINE, ENERGY_POS+7)
    set_bk_color(WHITE)
    if energy < 5000 then
    set_color(RED)
    else
    set_color(BLACK)
    end if

    console_printf("%d    ", floor(energy))
end procedure

public procedure task_life()
-- independent task: update energy on console, including "life support" energy

    while not gameover do

    if shuttle then
        p_energy(-3)
    else
        p_energy(-13)
    end if
    task_yield()
    end while
end procedure

------------------------- message handler -----------------------------
-- All messages come here. A task ensures that messages will be displayed
-- on the screen for at least a second or so, before being overwritten by
-- the next message. If there is no queue, a message will be printed
-- immediately, otherwise it is added to the queue.

constant MESSAGE_GAP = 1.2  -- seconds between messages for readability

sequence message_queue
message_queue = {}

constant MAX_MSG_LEN = 55

public procedure display_msg(sequence text)
-- print a message immediately
    set_bk_color(WHITE)
    set_color(RED)
    position(MSG_LINE, MSG_POS)
    if length(text) > MAX_MSG_LEN then
    text = text[1..MAX_MSG_LEN]
    end if
    console_puts(text)
    console_puts(BLANK_LINE[1..MAX_MSG_LEN-length(text)])
end procedure

public procedure msg(sequence text)
-- print a plain text message on the message line

    if length(message_queue) = 0 then
    -- print it right away
    display_msg(text)
    task_schedule(t_message, {MESSAGE_GAP-0.2, MESSAGE_GAP})
    end if
    message_queue = append(message_queue, text)
end procedure

public procedure fmsg(sequence format, object values)
-- print a formatted message on the message line
    msg(sprintf(format, values))
end procedure

public procedure task_message()
-- task to display next message in message queue

    while TRUE do
    -- first message is already on the screen - delete it
    message_queue = message_queue[2..$]
    if length(message_queue) = 0 then
        task_suspend(task_self()) -- no more messages
    else
        display_msg(message_queue[1])
        -- speed up a bit when there's a queue
        task_schedule(task_self(), {MESSAGE_GAP-0.6, MESSAGE_GAP-0.4})
    end if
    task_yield()
    end while
end procedure

----------------------------------------------------------------------------

public procedure show_warp()
-- show current speed (with warning)
    set_bk_color(WHITE)
    set_color(BLACK)
    position(WARP_LINE, WARP_POS)
    console_puts("WARP:")
    if curwarp > wlimit then
    set_color(RED)
    end if
    console_printf("%d", curwarp)
end procedure

public boolean allowed_to_dock
allowed_to_dock = TRUE

public boolean docking -- are we flashing "* DOCKING *" ?
docking = FALSE

public function who_is_it(h_coord x1, v_coord y1, sequence shape)
-- map a rectangular region of the screen to the quadrant sequence rows
-- of the object(s) that occupy it (or return {} if it's just a POD)

    extended_h_coord x2, ix1, ix2
    extended_v_coord y2, iy1, iy2
    natural t, bestover, iover
    sequence who

    x2 = x1 + length(shape[1]) - 1
    y2 = y1 + length(shape) - 1
    bestover = 0
    who = {}

    for i = EUPHORIA to length(quadrant) do
    t = quadrant[i][Q_TYPE]

    if t then
        ix1 = quadrant[i][Q_X]
        ix2 = ix1 + length(oshape[t][1][1]) - 1

        iy1 = quadrant[i][Q_Y]
        iy2 = iy1 + length(oshape[t][1]) - 1

        -- compute amount of overlap
        iover = 0
        if (ix2 >= x1 and ix1 <= x2) and
           (iy2 >= y1 and iy1 <= y2) then
        -- there is some overlap
        who = append(who, i)
        end if
    end if
    end for
    if length(who) = 0 then
    -- check for POD
    if is_pod(read_screen(x1, y1, shape)) then
        return {}
    else
        -- something is wrong: we must always know who's there
        return 1/(who-who)
    end if
    else
    return who
    end if
end function

public function hit_pb(extended_h_coord x, extended_v_coord y)
-- returns planet or base row (if any) that we are hitting or would hit at x, y
-- else returns EUPHORIA row
    sequence who

    who = who_is_it(x, y, esym)
    for i = 1 to length(who) do
    -- if any base or planet, then we are/will bump it (docking)
    if find(quadrant[who[i]][Q_TYPE], {G_BS, G_PL}) then
        return who[i]
    end if
    end for
    return EUPHORIA
end function

public procedure check_dock()
-- check if Euphoria is expected to dock on its next move
    valid_quadrant_row r

    docking = FALSE
    if curwarp = 1 and allowed_to_dock then
    r = hit_pb(quadrant[EUPHORIA][Q_X]+exi,
           quadrant[EUPHORIA][Q_Y]+eyi)
    if find(quadrant[r][Q_TYPE], {G_PL, G_BS}) then
        -- Euphoria is expected to dock on next move - start blinking
        task_schedule(t_docking, {0.1, 0.2})
        docking = TRUE
    end if
    end if
end procedure

-- how long it takes Euphoria to move at warp 0 thru 5:
public constant warp_time = {{1e8, 1e9}, {20, 20.5}, {.57, .60},
                 {.12, .13}, {.04, .04}, {.015, .015}}

public procedure setwarp(warp new)
-- establish a new warp speed for the Euphoria

    sequence t

    if new != curwarp then
    t = warp_time[new+1]
    task_schedule(t_emove, t)
    curwarp = new
    show_warp()
    check_dock()
    end if
end procedure

public procedure gtext()
-- print text portion of galaxy scan
    set_bk_color(BLUE)
    position(22, 37)
    set_color(BRIGHT_RED)
    console_printf("C: %d ", c_remaining())
    position(23, 24)
    set_color(BROWN)
    console_printf("Planets: %d", nobj[G_PL])
    set_color(BRIGHT_CYAN)
    console_printf("   BASIC: %d", nobj[G_BAS])
    if bstat = TRUCE then
    console_puts(" TRUCE   ")
    elsif bstat = HOSTILE then
    console_puts(" HOSTILE ")
    else
    console_puts(" CLOAKING")
    end if
    position(24, 24)
    set_color(YELLOW)
    console_printf("Bases: %d", nobj[G_BS])
    set_color(BRIGHT_GREEN)
    console_printf("     Java: %d ", nobj[G_JAV])
    position(25, 67)
    set_color(BLUE)
    set_bk_color(WHITE)
    if level = 'n' then
    console_puts("novice level")
    else
    console_puts("expert level")
    end if
end procedure

constant XSCALE = QXSIZE/HSIZE,
     YSCALE = (QYSIZE-1)/VSIZE  -- -1 or CPP might protrude below quad

constant KNOWN_QUAD = repeat(repeat(GRAY, QXSIZE), QYSIZE),
       CURRENT_QUAD = repeat(repeat(WHITE, QXSIZE), QYSIZE)

constant C_ICON = repeat(repeat(BRIGHT_RED, 3), 2),
       CPP_ICON = repeat(repeat(BRIGHT_MAGENTA, 3), 3),
     BASIC_ICON = repeat(repeat(BRIGHT_BLUE, 2), 2),
      JAVA_ICON = repeat(repeat(BRIGHT_GREEN, 2), 2),
  EUPHORIA_ICON = repeat(repeat(YELLOW, 2), 2),
      BASE_ICON = repeat(repeat(YELLOW, 4), 4),
    PLANET_ICON = repeat(repeat(BROWN, 6), 6)

function display_rand(image quad, image icon, natural count)
-- display ships in random positions for non-current quadrant
    natural xpos, ypos, xlen, ylen, xrange, yrange, back, y
    boolean collide
    sequence qy

    back = KNOWN_QUAD[1][1]
    xlen = length(icon[1])
    ylen = length(icon)
    xrange = QXSIZE-xlen-1 -- avoid the edges
    yrange = QYSIZE-ylen-1
    for i = 1 to count do
    for j = 1 to 10 do -- avoid infinite loop
        xpos = 1+rand(xrange)
        ypos = 1+rand(yrange)
        collide = FALSE
        y = ypos
        while y < ypos+ylen and not collide do
        qy = quad[y]
        for x = xpos to xpos+xlen-1 do
            if qy[x] != back then
            collide = TRUE
            exit
            end if
        end for
        y += 1
        end while
        if not collide then
        quad = update_image(quad, xpos, ypos, icon)
        exit
        end if
    end for
    end for
    return quad
end function

public procedure gquad(g_index r, g_index c)
-- print one galaxy scan quadrant

    natural qx, qy, qt, back
    sequence quad_info
    h_coord x
    v_coord y
    object icon
    image this_quad

    quad_info = galaxy[r][c]
    if quad_info[1] = 0 then
    return -- unknown quadrant (screen is already black)
    end if
    x = c * QXSIZE + QXBASE
    y = r * QYSIZE - 8
    if r = qrow and c = qcol then
    -- the current quadrant
    this_quad = CURRENT_QUAD
    for i = length(quadrant) to 1 by -1 do
        qt = quadrant[i][Q_TYPE]
        if qt = EUPHORIA then
        icon = EUPHORIA_ICON
        elsif qt = G_KRC or qt = G_ANC then
        icon = C_ICON
        elsif qt = G_CPP then
        icon = CPP_ICON
        elsif qt = G_BAS and bstat != CLOAKING then
        icon = BASIC_ICON
        elsif qt = G_JAV then
        icon = JAVA_ICON
        elsif qt = G_PL then
        -- round the edges (assumes size 6)
        back = CURRENT_QUAD[1][1]
        icon = PLANET_ICON
        icon[1][1] = back
        icon[1][6] = back
        icon[6][1] = back
        icon[6][6] = back
        if pb[quadrant[i][Q_PBX]][P_EN] <= 0 then
            -- make it white if it's out of energy
            icon += (icon != back) * (BRIGHT_WHITE-icon)
        end if
        elsif qt = G_BS then
        icon = BASE_ICON
        if pb[quadrant[i][Q_PBX]][P_EN] <= 0 then
            -- make it white if out of energy
            icon += (BRIGHT_WHITE-icon)
        end if
        else
        icon = DEAD
        end if

        if sequence(icon) then
        -- scaling assumes icons have reasonable proportions
        -- compared to real objects
        qx = 1+floor(quadrant[i][Q_X]*XSCALE)
        qy = 1+floor(quadrant[i][Q_Y]*YSCALE)
        -- avoids flicker
        this_quad = update_image(this_quad, qx, qy, icon)
        end if
    end for
    else
    -- other known quadrants
    this_quad = KNOWN_QUAD
    if quad_info[G_BS] or quad_info[G_PL] then
        back = KNOWN_QUAD[1][1]
        for i = 1 to length(pb) do
        if pb[i][P_TYPE] != DEAD and pb[i][P_QR] = r and
                         pb[i][P_QC] = c then
            if pb[i][P_TYPE] = G_PL then
            -- round the edges
            icon = PLANET_ICON
            icon[1][1] = back
            icon[1][6] = back
            icon[6][1] = back
            icon[6][6] = back
            else
            icon = BASE_ICON
            end if
            if pb[i][P_EN] <= 0 then
            -- make it white if it's out of energy
            icon += (icon != back) * (BRIGHT_WHITE-icon)
            end if
            qx = 1+floor(pb[i][P_X]*XSCALE)
            qy = 1+floor(pb[i][P_Y]*YSCALE)
            this_quad = update_image(this_quad, qx, qy, icon)
        end if
        end for
    end if

    if bstat != CLOAKING then
        this_quad = display_rand(this_quad, BASIC_ICON, quad_info[G_BAS])
    end if
    this_quad = display_rand(this_quad, JAVA_ICON, quad_info[G_JAV])
    this_quad = display_rand(this_quad, C_ICON, quad_info[G_KRC] +
                            quad_info[G_ANC])
    this_quad = display_rand(this_quad, CPP_ICON, quad_info[G_CPP])
    end if
    -- display final picture of this quadrant
    display_image({x,y}, this_quad)
end procedure

public procedure task_gquad()
-- update the current quadrant display on the galaxy scan
    while not gameover do
    gquad(qrow, qcol)
    task_yield()
    end while
end procedure

public procedure upg(g_index qrow, g_index qcol)
-- update galaxy scan quadrant
    if scanon then
    gquad(qrow, qcol)
    end if
end procedure

sequence prev_box
prev_box = {}

public procedure gsbox(g_index qrow, g_index qcol)
-- indicate current quadrant on galaxy scan
    if scanon then
    if length(prev_box) = 2 then
        -- clear the previous "box" (could be gone already)
        gquad(prev_box[1], prev_box[2])
    end if
    gquad(qrow, qcol)
    prev_box = {qrow, qcol}
    end if
end procedure

constant dir_places = {{1, 6},{0, 6},{0, 3},{0, 0},{1, 0},{2, 0},{2, 3},{2, 6}}

public procedure dir_box()
    -- direction box
    sequence place

    set_bk_color(BLUE)
    set_color(BRIGHT_WHITE)
    position(WARP_LINE, DIRECTIONS_POS)
    console_puts("4  3  2")
    position(CMD_LINE, DIRECTIONS_POS)
    console_puts("5  @  1")  -- @ redefined as big '+'
    position(MSG_LINE, DIRECTIONS_POS)
    console_puts("6  7  8")
    place = dir_places[curdir]
    position(place[1]+WARP_LINE,place[2]+DIRECTIONS_POS)
    set_bk_color(GREEN)
    console_printf("%d", curdir)
    set_bk_color(WHITE)
end procedure

public procedure wtext()
-- print torpedos, pods, deflectors in text window
    sequence s
    set_bk_color(WHITE)
    set_color(BLACK)
    position(WARP_LINE, WEAPONS_POS)
    s = sprintf("%s %s %s", {ts, ds, ps})
    console_puts(s)
    -- max 10 torps, blank, 3 def, blank, 4 pods
    console_puts(repeat(' ', 20-length(s)))
end procedure

public procedure stext()
-- print text window info

    position(QUAD_LINE, 1)
    set_bk_color(GREEN)
    set_color(BRIGHT_WHITE)
    console_puts("  1-8  w")
    set_color(BLACK)
    console_puts("arp  ")
    set_color(BRIGHT_WHITE)
    console_puts("p")
    set_color(BLACK)
    console_puts("hasor  ")
    set_color(BRIGHT_WHITE)
    console_puts("t")
    set_color(BLACK)
    console_puts("orpedo  ")
    set_color(BRIGHT_WHITE)
    console_puts("a")
    set_color(BLACK)
    console_puts("ntimatter  ")
    set_color(BRIGHT_WHITE)
    console_puts("g")
    set_color(BLACK)
    console_puts("alaxy  ")
    set_color(BRIGHT_WHITE)
    console_puts("s")
    set_color(BLACK)
    console_puts("huttle  ")
    set_color(BRIGHT_WHITE)
    console_puts("f")
    set_color(BLACK)
    console_puts("reeze  ")
    set_color(BRIGHT_WHITE)
    console_puts("c")
    set_color(BLACK)
    console_puts("ancel  ")
    set_color(BRIGHT_WHITE)
    console_puts("Esc  ")
    set_bk_color(WHITE)
    set_color(BLACK)
    show_warp()
    wtext()
    position(WARP_LINE, ENERGY_POS)
    console_printf("ENERGY:%d    ", floor(quadrant[EUPHORIA][Q_EN]))
    position(CMD_LINE, CMD_POS-9)
    console_puts("COMMAND: ")

    dir_box()
end procedure

procedure p_source(valid_quadrant_row row)
-- print a base or planet
    h_coord x
    v_coord y

    x = quadrant[row][Q_X]
    y = quadrant[row][Q_Y]
    if quadrant[row][Q_TYPE] = G_PL then
    write_screen(x, y, PLANET)
    else
    write_screen(x, y, BASE)
    end if
end procedure

public procedure end_scan()
-- end display of galaxy scan
    if scanon then
    scanon = FALSE
    ShowScreen()
    task_suspend(t_gquad)
    end if
end procedure

public procedure refresh_scan()
    for r = 1 to G_SIZE do
    for c = 1 to G_SIZE do
        gquad(r, c)
    end for
    end for
end procedure

public procedure pobj()
-- print objects in a new quadrant
    h_coord x
    v_coord y
    sequence c
    natural len, height
    object_type t
    sequence taken

    -- print dull stars
    for i = 1 to 40 do
    x = rand(HSIZE)
    y = rand(VSIZE)
    screen[y][x] = STAR2
    if not scanon then
        pixel(STAR2, {x-1, y-1})
    end if
    end for

    -- print brighter stars
    for i = 1 to 15 do
    x = rand(HSIZE)
    y = rand(VSIZE)
    screen[y][x] = STAR1
    if not scanon then
        pixel(STAR1, {x-1, y-1})
    end if
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
                taken &= pbi
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
        height = length(oshape[quadrant[row][Q_TYPE]][1])
        len =    length(oshape[quadrant[row][Q_TYPE]][1][1])
        -- look for an empty place to put the ship.
        -- Euphoria is already in the quadrant.
        while TRUE do
        x = rand(HSIZE - len + 1)
        y = rand(VSIZE - height + 1)
        c = read_screen(x, y, oshape[quadrant[row][Q_TYPE]][1])
        if all_clear(c) then
            exit -- found a good place
        end if
        end while
        quadrant[row][Q_UNDER] = c
        quadrant[row][Q_X] = x
        quadrant[row][Q_Y] = y
        t = quadrant[row][Q_TYPE]
        if x < quadrant[EUPHORIA][Q_X] then
        c = oshape[t][2]
        else
        c = oshape[t][1]
        end if
        write_screen(x, y, c)
    end if
    end for
end procedure
