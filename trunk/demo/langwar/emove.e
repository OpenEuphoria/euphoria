-- emove.e
-- move the Euphoria

-- Energy consumed per ship movement at warp 0 thru 5.
-- WARP 4 is the most efficient after you take life support
-- energy into account. WARP 5 is good if you can use it to avoid
-- getting blasted.

constant fuel = {0, 0.5, 1, 2, 4, 9}

global function gmod(natural x)
-- quadrant wraparound
    if x = 0 then
	return G_SIZE
    elsif x > G_SIZE then
	return 1
    else
	return x
    end if
end function

constant ZERO_FILL = repeat(0, QCOLS-7)

-- standard row in quadrant sequence for a type
global constant stdtype =
-- TYPE    EN    TORP    DEFL  FRATE  MRATE   TARG
{{}, -- dummy (Euphoria)
 {G_KRC,  4000,  2,       0,   100,   160,  EUPHORIA} & ZERO_FILL, -- K&R C
 {G_ANC,  8000,  4,       0,   100,   200,  EUPHORIA} & ZERO_FILL, -- ANSI C
 {G_CPP, 25000, 10,       0,   200,   250,  EUPHORIA} & ZERO_FILL, -- C++
 {G_BAS,  2000,  2,       0,    70,   150,  EUPHORIA} & ZERO_FILL, -- BASIC
 {G_JAV,  3000,  0,       0,    40,    90,   -1}      & ZERO_FILL, -- Java
 {G_PL,   7000,  0,       0,     0,     0,   -1}      & ZERO_FILL, -- planet
 {G_BS,   6000,  5,       1,   120,     0,   -1}      & ZERO_FILL  -- base
}

procedure setup_quadrant()
-- set up quadrant sequence for a new quadrant

    sequence g_info

    g_info = galaxy[qrow][qcol]
    quadrant = quadrant[EUPHORIA..EUPHORIA]

    for i = 1 to g_info[G_ANC] do
	quadrant = append(quadrant, stdtype[G_ANC])
	quadrant[$][Q_UNDER] = oshape[G_ANC] * 0
    end for

    for i = 1 to g_info[G_KRC] do
	quadrant = append(quadrant, stdtype[G_KRC])
	quadrant[$][Q_UNDER] = oshape[G_KRC] * 0
    end for
    
    for i = 1 to g_info[G_CPP] do
	quadrant = append(quadrant, stdtype[G_CPP])
	quadrant[$][Q_UNDER] = oshape[G_CPP] * 0
    end for

    for i = 1 to g_info[G_BS] do
	quadrant = append(quadrant, stdtype[G_BS])
    end for

    for i = 1 to g_info[G_PL] do
	quadrant = append(quadrant, stdtype[G_PL])
    end for

    basic_targ = -1
    for i = 1 to g_info[G_BAS] do
	quadrant = append(quadrant, stdtype[G_BAS])
	quadrant[$][Q_UNDER] = oshape[G_BAS] * 0
	basic_targ = EUPHORIA
    end for

    for i = 1 to g_info[G_JAV] do
	quadrant = append(quadrant, stdtype[G_JAV])
	quadrant[$][Q_UNDER] = oshape[G_JAV] * 0
    end for

end procedure

boolean contacted
contacted = FALSE

function dock(h_coord x, v_coord y)
-- Euphoria docks with a base or planet at (x,y)

    object_type t
    valid_quadrant_row r
    pb_row pbr
    natural maxen, torp, availtorp, xdiff, ydiff
    positive_atom energy, availen
    extended_h_coord newx 
    extended_v_coord newy
    
    r = hit_pb(x, y)
    t = quadrant[r][Q_TYPE]
    if t = G_PL or t = G_BS then
	if curwarp != 1 then
	    if not contacted then
		contacted = TRUE
		if t = G_PL then
		    fmsg("PLANET TO %s: PLEASE DOCK AT WARP 1", {otype[G_EU]})
		else
		    fmsg("BASE TO %s: PLEASE DOCK AT WARP 1", {otype[G_EU]})
		end if
	    end if
	    return FALSE
	end if
	
	if not allowed_to_dock then
	    return FALSE
	end if
	
	-- perform the docking
	pbr = quadrant[r][Q_PBX]
	if pb[pbr][P_POD] > 0 then
	    pb[pbr][P_POD] -= 1
	    ps &= POD_SYM
	end if
	torp = 10 - quadrant[EUPHORIA][Q_TORP]
	availtorp = pb[pbr][P_TORP]
	if torp > availtorp then
	    torp = availtorp
	end if
	pb[pbr][P_TORP] = availtorp - torp
	torp += quadrant[EUPHORIA][Q_TORP]
	quadrant[EUPHORIA][Q_TORP] = torp
	ts = repeat(TORP_SYM, torp)
	if t = G_BS then
	    -- extra stuff you get at a base
	    for i = 1 to NSYS do
		-- fix each subsystem
		if reptime[i] then
		    reptime[i] = 0
		    repair(i)
		end if
	    end for
	    if shuttle then
		-- if there's room, restore larger EUPHORIA ship
		newx = quadrant[EUPHORIA][Q_X]
		newy = quadrant[EUPHORIA][Q_Y]
		if quadrant[r][Q_X] > quadrant[EUPHORIA][Q_X] then
		    xdiff = length(EUPHORIA_L[1]) - length(SHUTTLE_L[1])
		    newx -= xdiff
		end if
		if quadrant[r][Q_Y] > quadrant[EUPHORIA][Q_Y] then
		    ydiff = length(EUPHORIA_L) - length(SHUTTLE_L)
		    newy -= ydiff
		end if
		if h_coord(newx) and 
		   v_coord(newy) and 
		   -- short circuit avoids error:
		    all_clear(read_screen(newx, newy, EUPHORIA_L)) then 
		    -- restore larger ship
		    quadrant[EUPHORIA][Q_X] = newx
		    quadrant[EUPHORIA][Q_Y] = newy
		    esyml = EUPHORIA_L
		    esymr = EUPHORIA_R
		    if equal(esym[1], SHUTTLE_L[1]) then
			esym = EUPHORIA_L
		    else
			esym = EUPHORIA_R
		    end if
		    otype[G_EU] = "EUPHORIA"
		    oshape[G_EU] = {EUPHORIA_L, EUPHORIA_R}
		    shuttle = FALSE
		end if
	    end if
	    quadrant[EUPHORIA][Q_DEFL] = 3
	    ds = repeat(DEFL_SYM, 3)
	end if
	if shuttle then
	    maxen = 5000
	else
	    maxen = 50000
	end if
	energy = maxen - quadrant[EUPHORIA][Q_EN]
	availen = pb[pbr][P_EN]
	if energy > availen then
	    energy = availen
	end if
	pb[pbr][P_EN] = availen - energy
	quadrant[EUPHORIA][Q_EN] += energy
	p_energy(0)
	wtext()
	docking_sound()
	upg(qrow, qcol)
	msg("DOCKING COMPLETED")
	allowed_to_dock = FALSE -- until it moves free again
	return TRUE
    end if
    return FALSE
end function

procedure progress_puts(sequence text, atom p)
-- show text with progress bar as background    
    
    integer nchars
    
    nchars = floor(p * length(text))
    set_color(GREEN)
    set_bk_color(RED)
    console_puts(text[1..nchars])
    set_bk_color(BLUE)
    console_puts(text[nchars+1..$])
end procedure

constant BLINK_SPEED = 50

global procedure task_docking()
-- show that docking is occuring
    
    integer max
    
    max = BLINK_SPEED+2
    while not gameover do
	msg("DOCKING INITIATED")
	for i = 1 to max do
	    position(CMD_LINE, DOCKING_POS)
	    if remainder(i, 2) then
		if docking then
		    progress_puts(" DOCKING IN PROGRESS ", i/BLINK_SPEED)
		end if
	    else
		if docking then
		    progress_puts("                     ", i/BLINK_SPEED)
		else
		    set_bk_color(WHITE)
		    console_puts("                     ") 
		end if
	    end if
	    if curwarp != 1 then
		exit -- the time will have to start over again
	    end if
	    check_dock()
	    -- we might get scheduled again by another task
	    task_schedule(task_self(), warp_time[1+1]/BLINK_SPEED) 
	    task_yield()
	end for
	
	position(CMD_LINE, DOCKING_POS)
	set_bk_color(WHITE)
	console_puts("                     ")
	
	task_suspend(task_self())
	task_yield()
    end while
end procedure

type increment(integer x)
    return x = -1 or x = 0 or x = +1
end type

global procedure task_emove()
-- independent task: move the Euphoria
    h_coord x, exold
    v_coord y, eyold
    increment eqx, eqy
    sequence c
    
    while not gameover do
	if curwarp - wlimit >= rand(50) then
	    msg("ALL ENGINES DAMAGED")
	    wlimit = 0
	    reptime[ENGINES] += rand(11)
	    setwarp(0)
	else
	    eqx = 0
	    eqy = 0
	    exold = quadrant[EUPHORIA][Q_X]
	    eyold = quadrant[EUPHORIA][Q_Y]
	    quadrant[EUPHORIA][Q_X] += exi
	    quadrant[EUPHORIA][Q_Y] += eyi
	
	    -- check for switching quadrants:
	
	    if quadrant[EUPHORIA][Q_X] > HSIZE - length(esym[1]) + 1 then
		quadrant[EUPHORIA][Q_X] = 1
		eqx = 1
	    elsif quadrant[EUPHORIA][Q_X] < 1 then
		quadrant[EUPHORIA][Q_X] = HSIZE - length(esym[1]) + 1
		eqx = -1
	    end if
	
	    if quadrant[EUPHORIA][Q_Y] > VSIZE - length(esym) + 1 then
		quadrant[EUPHORIA][Q_Y] = 1
		eqy = 1
	    elsif quadrant[EUPHORIA][Q_Y] < 1 then
		quadrant[EUPHORIA][Q_Y] = VSIZE - length(esym) + 1
		eqy = -1
	    end if
	
	    if shuttle then
		quadrant[EUPHORIA][Q_EN] -= fuel[curwarp+1]/6
	    else
		quadrant[EUPHORIA][Q_EN] -= fuel[curwarp+1]
	    end if
	    if quadrant[EUPHORIA][Q_EN] <= 0 then
		p_energy(0)
	    end if
	    
	    c = quadrant[EUPHORIA][Q_UNDER]
	    delayed_write_screen(exold, eyold, c) -- avoid flicker
	    
	    if eqx != 0 or eqy != 0 then
		-- entering new quadrant
		flush_screen()
		quad_count += 1
		euphoria_color(YELLOW)  
		wipeout = {}
		qcol = gmod(qcol + eqx)
		qrow = gmod(qrow + eqy)
		BlackScreen()
		setup_quadrant()
		for i = 2 to length(quadrant) do
		    if quadrant[i][Q_TYPE] = G_JAV then
			quadrant[i][Q_TARG] = Java_target(i)
		    end if
		end for
		sched_move_fire()
		galaxy[qrow][qcol][G_EU] = TRUE -- visited
		msg("")
	    end if
	    
	    x = quadrant[EUPHORIA][Q_X]
	    y = quadrant[EUPHORIA][Q_Y]
	    c = read_screen(x, y, esym)
	    if all_clear(c) then
		contacted = FALSE -- no longer bumping a base/planet
		allowed_to_dock = TRUE
	    else    
		-- there's something in our way
		quadrant[EUPHORIA][Q_X] = exold -- stay where we are
		quadrant[EUPHORIA][Q_Y] = eyold
		if not dock(x, y) then -- docking could change esym
		    end_scan() -- show what we're hitting
		end if
		x = quadrant[EUPHORIA][Q_X]
		y = quadrant[EUPHORIA][Q_Y]
		c = read_screen(x, y, esym)
	    end if
	    delayed_write_screen(x, y, esym)
	    flush_screen()
	    if eqx != 0 or eqy != 0 then
		-- print other guys after EUPHORIA is in new quadrant
		pobj()
		gsbox(qrow, qcol)
	    end if
	    c *= (c > 64) -- keep stars, discard phasor/torpedo dust
	    quadrant[EUPHORIA][Q_UNDER] = c
	
	    -- look ahead to see if we are about to dock
	    check_dock()
	end if
	
	task_yield()
    end while
end procedure
    
