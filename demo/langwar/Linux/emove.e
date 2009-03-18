-- emove.e
-- move the Euphoria

-- Energy consumed per ship movement at warp 0 thru 5.
-- WARP 4 is the most efficient after you take life support
-- energy into account. WARP 5 is good if you can use it to avoid
-- getting blasted.
include weapons.e
include soundeff.e
include display.e
include std/graphics.e

constant fuel = {0, 5, 8, 12, 25, 70}

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
 {G_KRC,  4000,  1,       0,   100,   140,  EUPHORIA} & ZERO_FILL, -- K&R C
 {G_ANC,  8000,  2,       0,   100,   180,  EUPHORIA} & ZERO_FILL, -- ANSI C
 {G_CPP, 20000,  4,       0,   150,   250,  EUPHORIA} & ZERO_FILL, -- C++
 {G_BAS,  2000,  1,       0,    70,   150,  EUPHORIA} & ZERO_FILL, -- BASIC
 {G_JAV,  3000,  0,       0,    40,    80,   -1}      & ZERO_FILL, -- Java
 {G_PL,   5000,  0,       0,     0,     0,   -1}      & ZERO_FILL, -- planet
 {G_BS,   6000,  3,       1,   120,     0,   -1}      & ZERO_FILL  -- base
}
procedure setup_quadrant()
-- set up quadrant sequence for a new quadrant

    sequence g_info

    g_info = galaxy[qrow][qcol]
    quadrant = quadrant[EUPHORIA..EUPHORIA]

    for i = 1 to g_info[G_PL] do
	quadrant = append(quadrant, stdtype[G_PL])
    end for

    for i = 1 to g_info[G_BS] do
	quadrant = append(quadrant, stdtype[G_BS])
    end for

    basic_targ = -1
    for i = 1 to g_info[G_BAS] do
	quadrant = append(quadrant, stdtype[G_BAS])
	quadrant[length(quadrant)][Q_UNDER] = 
				repeat(' ', length(ship[G_BAS][1]))
	basic_targ = EUPHORIA
    end for

    for i = 1 to g_info[G_JAV] do
	quadrant = append(quadrant, stdtype[G_JAV])
	quadrant[length(quadrant)][Q_UNDER] = 
				repeat(' ', length(ship[G_JAV][1]))
    end for

    for i = 1 to g_info[G_CPP] do
	quadrant = append(quadrant, stdtype[G_CPP])
	quadrant[length(quadrant)][Q_UNDER] = 
				repeat(' ', length(ship[G_CPP][1]))
    end for

    for i = 1 to g_info[G_ANC] do
	quadrant = append(quadrant, stdtype[G_ANC])
	quadrant[length(quadrant)][Q_UNDER] = 
				repeat(' ', length(ship[G_ANC][1]))
    end for

    for i = 1 to g_info[G_KRC] do
	quadrant = append(quadrant, stdtype[G_KRC])
	quadrant[length(quadrant)][Q_UNDER] = 
				repeat(' ', length(ship[G_KRC][1]))
    end for
end procedure

function dock(h_coord x, v_coord y)
-- Euphoria docks with a base or planet at (x,y)

    object_type t
    valid_quadrant_row r
    pb_row pbr
    natural maxen, torp, availtorp
    positive_atom energy, availen

    if curwarp != 1 then
	return FALSE
    else
	r = who_is_it(x, y, TRUE)
	t = quadrant[r][Q_TYPE]
	if t = G_PL or t = G_BS then
	    if not quadrant[r][Q_DOCK] then
		quadrant[r][Q_DOCK] = TRUE
		pbr = quadrant[r][Q_PBX]
		if pb[pbr][P_POD] > 0 then
		    pb[pbr][P_POD] = pb[pbr][P_POD] - 1
		    ps = ps & POD
		end if
		torp = 5 - quadrant[EUPHORIA][Q_TORP]
		availtorp = pb[pbr][P_TORP]
		if torp > availtorp then
		    torp = availtorp
		end if
		pb[pbr][P_TORP] = availtorp - torp
		torp = torp + quadrant[EUPHORIA][Q_TORP]
		quadrant[EUPHORIA][Q_TORP] = torp
		ts = repeat(TORPEDO, torp)
		if t = G_BS then
		    for i = 1 to NSYS do
			if reptime[i] then
			    reptime[i] = 0
			    repair(i)
			end if
		    end for
		    if shuttle then
			esyml = EUPHORIA_L
			esymr = EUPHORIA_R
			if esym[1] = SHUTTLE_L[1] then
			    esym = EUPHORIA_L
			else
			    esym = EUPHORIA_R
			end if
			otype[G_EU] = "EUPHORIA"
			shuttle = FALSE
		    end if
		end if
		if shuttle then
		    maxen = 5000
		else
		    maxen = 30000
		end if
		energy = maxen - quadrant[EUPHORIA][Q_EN]
		availen = pb[pbr][P_EN]
		if energy > availen then
		    energy = availen
		end if
		pb[pbr][P_EN] = availen - energy
		quadrant[EUPHORIA][Q_EN] = quadrant[EUPHORIA][Q_EN] + energy
		p_energy(0)
		if t = G_BS then
		    quadrant[EUPHORIA][Q_DEFL] = 3
		    ds = repeat(DEFLECTOR, 3)
		end if
		wtext()
		docking_sound()
		upg(qrow, qcol)
		msg("DOCKING COMPLETED")
		return TRUE
	    end if
	end if
    end if
    return FALSE
end function

type increment(integer x)
    return x = -1 or x = 0 or x = +1
end type

global procedure task_emove()
-- independent task: move the Euphoria
    h_coord x, exold
    v_coord y, eyold
    increment eqx, eqy
    sequence c, sc1

    if curwarp > wlimit then
	if curwarp - wlimit > rand(12) then
	    msg("ALL ENGINES DAMAGED")
	    wlimit = 0
	    reptime[ENGINES] = reptime[ENGINES] + rand(11)
	    setwarp(0)
	    return
	end if
    end if
    eqx = 0
    eqy = 0
    exold = quadrant[EUPHORIA][Q_X]
    eyold = quadrant[EUPHORIA][Q_Y]
    quadrant[EUPHORIA][Q_X] = quadrant[EUPHORIA][Q_X] + exi
    quadrant[EUPHORIA][Q_Y] = quadrant[EUPHORIA][Q_Y] + eyi

    -- check for switching quadrants:

    if quadrant[EUPHORIA][Q_X] > HSIZE - length(esym) + 1 then
	quadrant[EUPHORIA][Q_X] = 1
	eqx = 1
    elsif quadrant[EUPHORIA][Q_X] < 1 then
	quadrant[EUPHORIA][Q_X] = HSIZE - length(esym) + 1
	eqx = -1
    end if

    if quadrant[EUPHORIA][Q_Y] = VSIZE + 1 then
	quadrant[EUPHORIA][Q_Y] = 1
	eqy = 1
    elsif quadrant[EUPHORIA][Q_Y] = 0 then
	quadrant[EUPHORIA][Q_Y] = VSIZE
	eqy = -1
    end if

    if shuttle then
	p_energy(-fuel[curwarp+1]/6)
    else
	p_energy(-fuel[curwarp+1])
    end if

    c = quadrant[EUPHORIA][Q_UNDER]
    write_screen(exold, eyold, c)
    if eqx != 0 or eqy != 0 then
	-- new quadrant
	qcol = gmod(qcol + eqx)
	qrow = gmod(qrow + eqy)
	setup_quadrant()
	for i = 2 to length(quadrant) do
	    if quadrant[i][Q_TYPE] = G_JAV then
		quadrant[i][Q_TARG] = Java_target(i)
	    end if
	end for
	position(QUAD_LINE, 44)
	set_bk_color(CYAN)
	set_color(MAGENTA)
	printf(CRT, "%d.%d", {qrow, qcol})
	galaxy[qrow][qcol][1] = TRUE
	msg("")
	gsbox(qrow, qcol)
	pobj()
    end if
    x = quadrant[EUPHORIA][Q_X]
    y = quadrant[EUPHORIA][Q_Y]
    sc1 = read_screen({x, length(esym)}, y)
    if find(TRUE, sc1 != ' ' and sc1 != STAR) then
	-- there's something in our way
	if not dock(x, y) then
	    if scanon then
		setg1()
	    end if
	end if
	quadrant[EUPHORIA][Q_X] = exold
	quadrant[EUPHORIA][Q_Y] = eyold
    end if
    c = read_screen({quadrant[EUPHORIA][Q_X], length(esym)}, 
		     quadrant[EUPHORIA][Q_Y])
    quadrant[EUPHORIA][Q_UNDER] = c
    write_screen(quadrant[EUPHORIA][Q_X], quadrant[EUPHORIA][Q_Y], esym)
end procedure

