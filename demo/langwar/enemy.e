-- enemy.e
-- operate the enemy ships
include std/graphics.e
include damage.e
include emove.e
include screen.e
include display.e

procedure set_basic_color(natural c)
-- set new color and "shape" for BASIC ships after truce/hostile change
    sequence shape, new_shape

    object_color[BASIC_COL] = c
    object_color[BASIC_COL+1] = c
    for i = 2 to length(quadrant) do
	if quadrant[i][Q_TYPE] = G_BAS then
	    shape = read_screen({quadrant[i][Q_X], length(BASIC_L)}, 
				 quadrant[i][Q_Y])
	    -- reprint with new shape & color
	    if compare(shape, BASIC_L) = 0 then
		new_shape = ship[G_BAS][1]
	    else
		new_shape = ship[G_BAS][2]
	    end if
	    write_screen(quadrant[i][Q_X], quadrant[i][Q_Y], new_shape)
	end if
    end for
end procedure

global procedure task_bstat()
-- independent task: BASIC status change

    positive_atom w

    w = rand(400) + rand(400) + 20
    if bstat = TRUCE then
	if truce_broken then
	    truce_broken = FALSE
	    msg("TRUCE BROKEN!")
	else
	    msg("BASIC STATUS: HOSTILE")
	end if
	if rand(20) < 16 then
	    w = w * 1.2
	    ship[G_BAS] = {BASIC_L, BASIC_R}
	    bstat = HOSTILE
	else
	    w = w * .6
	    ship[G_BAS] = repeat(repeat(INVISIBLE_CHAR, length(BASIC_L)), 2)
	    bstat = CLOAKING
	end if
	set_basic_color(BLUE)
    else
	if rand(20) < 10 then
	    bstat = TRUCE
	    msg("BASIC STATUS: TRUCE")
	    w = w * .83
	    ship[G_BAS] = {BASIC_L, BASIC_R}
	    set_basic_color(BRIGHT_BLUE)
	else
	    if bstat = HOSTILE then
		w = w * .6
		bstat = CLOAKING
		ship[G_BAS] = repeat(repeat(INVISIBLE_CHAR, length(BASIC_L)), 2)
	    else
		w = w * 1.2
		bstat = HOSTILE
		ship[G_BAS] = {BASIC_L, BASIC_R}
	    end if
	    set_basic_color(BLUE)
	end if
    end if
    wait[TASK_BSTAT] = w
    if scanon then
	gtext()
    end if
end procedure

procedure orient(valid_quadrant_row row)
-- point the ship toward its target

    quadrant_row targ
    h_coord targx, rowx
    v_coord rowy
    object_type t

    targ = quadrant[row][Q_TARG]
    if targ = -1 then
	-- no target
	return
    end if
    targx = quadrant[targ][Q_X]
    rowx = quadrant[row][Q_X]
    rowy = quadrant[row][Q_Y]
    t = quadrant[row][Q_TYPE]
    if rowx < targx then
	write_screen(rowx, rowy, ship[t][2])
    else
	write_screen(rowx, rowy, ship[t][1])
    end if
end procedure

procedure shoot(valid_quadrant_row row)
-- select torpedo or phasor for enemy shot

    natural torp
    positive_atom pen

    shooter = row
    if quadrant[shooter][Q_TYPE] != G_BS then
	orient(shooter)
    end if
    setpt(shooter)
    torp = quadrant[shooter][Q_TORP]
    if torp > 0 and rand(4) = 1 then
	quadrant[shooter][Q_TORP] = torp - 1
	weapon(W_TORPEDO, 4000)
    else
	pen = quadrant[shooter][Q_EN] / 8
	if quadrant[shooter][Q_TYPE] = G_JAV then
	    Java_phasor(pen)
	else
	    weapon(W_PHASOR, pen)
	end if
	quadrant[shooter][Q_EN] = quadrant[shooter][Q_EN] - pen
    end if
end procedure


global procedure task_fire()
-- independent task: select an enemy ship for firing

    quadrant_row row
    natural rate
    quadrant_row targ

    if length(quadrant) = 1 then
	return -- nobody in the quadrant
    end if

    row = rand(length(quadrant)-1) + EUPHORIA  -- choose a random ship
    if quadrant[row][Q_TYPE] = DEAD then
	row = rand(length(quadrant)-1) + EUPHORIA  -- try again
	if quadrant[row][Q_TYPE] = DEAD then
	    return
	end if
    end if
    rate = quadrant[row][Q_FRATE]
    if rate > rand(256) then
	-- shoot
	if quadrant[row][Q_TYPE] = G_BAS then
	    if bstat != TRUCE then
		shoot(row)
	    else
		if basic_targ != EUPHORIA then
		    if quadrant[basic_targ][Q_TYPE] != G_BS then
			shoot(row)
		    end if
		end if
	    end if

	elsif quadrant[row][Q_TYPE] = G_BS then
	    targ = quadrant[row][Q_TARG]
	    if targ != -1 then
		if bstat != TRUCE then
		    shoot(row)
		elsif quadrant[targ][Q_TYPE] != G_BAS then
		    shoot(row)
		end if
	    end if

	else
	    shoot(row)
	end if
    end if
end procedure


global procedure task_move()
-- independent task: select an enemy ship for moving

    quadrant_row row
    natural mrate
    h_coord fx
    v_coord fy
    extended_h_coord xtry
    extended_v_coord ytry
    sequence uchar, schar
    natural t
    natural len

    if length(quadrant) = 1 then
	return -- nobody in the quadrant
    end if

    row = rand(length(quadrant)-1) + EUPHORIA  -- choose a random ship
    t = quadrant[row][Q_TYPE]
    if t = DEAD then
	return
    end if
    mrate = quadrant[row][Q_MRATE]
    if mrate > rand(256) then
	-- try to move
	fx = quadrant[row][Q_X]
	xtry = fx + rand(5) - 3
	len = length(ship[t][1])
	if xtry >= 2 and xtry <= HSIZE - len then
	    fy = quadrant[row][Q_Y]
	    ytry = fy + rand(3) - 2
	    if ytry >= 1 and ytry <= VSIZE then
		schar = read_screen({xtry, len}, ytry)
		if not find(FALSE, schar = ' ' or schar = STAR) then
		    uchar = quadrant[row][Q_UNDER]
		    quadrant[row][Q_UNDER] = schar
		    schar = read_screen({fx, len}, fy)
		    write_screen(fx, fy, uchar)
		    write_screen(xtry , ytry, schar)
		    quadrant[row][Q_X] = xtry
		    quadrant[row][Q_Y] = ytry
		end if
	    end if
	end if
	orient(row)
    end if
end procedure

function add2quadrant(object_type t, h_coord x, v_coord y)
-- add a ship to the quadrant sequence 

    quadrant_row targ
    valid_quadrant_row row
    sequence c

    -- try to reuse a place in quadrant sequence
    row = 1
    for i = 2 to length(quadrant) do
	if quadrant[i][Q_TYPE] = DEAD then
	   row = i
	   exit
	end if
    end for
    if row = 1 then
	-- all slots in use - add a new row
	quadrant = append(quadrant, repeat(0, length(quadrant[1])))
	row = length(quadrant)
    end if

    -- choose his target
    if t < G_BAS then
	if galaxy[qrow][qcol][G_BS] then
	    for r = 2 to length(quadrant) do
		if quadrant[r][Q_TYPE] = G_BS then
		    targ = r
		    exit
		end if
	    end for
	else
	    targ = EUPHORIA
	end if
    elsif t = G_BAS then
	if basic_targ = -1 then
	    if galaxy[qrow][qcol][G_BS] then
		for r = 2 to length(quadrant) do
		    if quadrant[r][Q_TYPE] = G_BS then
			basic_targ = r
			exit
		    end if
		end for
	    else
		basic_targ = EUPHORIA
	    end if
	end if
	targ = basic_targ
    else
	targ = Java_target(row)
    end if

    quadrant[row] = stdtype[t]
    quadrant[row][Q_X] = x
    quadrant[row][Q_Y] = y
    quadrant[row][Q_UNDER] = read_screen({x, length(ship[t][1])}, y)
    quadrant[row][Q_TARG] = targ
    if x < quadrant[EUPHORIA][Q_X] then
	c = ship[t][2]
    else
	c = ship[t][1]
    end if
    write_screen(x, y, c)
    return TRUE
end function

global procedure task_enter()
-- independent task: enemy ship enters quadrant

    natural q
    h_coord enterx
    v_coord entery
    natural entert
    sequence enterc
    g_index randcol, randrow, fromcol, fromrow

    wait[TASK_ENTER] = 3 + rand(20) * (curwarp > 2) + 
		       quadrant[EUPHORIA][Q_EN]/(2000 + rand(6000))
    if rand(4+8*(level = 'n')) != 1 then
	return -- adjust wait time only
    end if

    for i = 1 to 2 do
	entert = 0
	fromrow = qrow
	fromcol = qcol
	enterx = 2
	entery = 1
	q = rand(8)
	if q = 1 then     -- left
	    fromcol = gmod(qcol-1)
	    entery = rand(VSIZE)
	elsif q = 2 then  -- top left
	    fromrow = gmod(qrow-1)
	    fromcol = gmod(qcol-1)
	elsif q = 3 then  -- top
	    enterx = 1 + rand(HSIZE - MAX_SHIP_WIDTH)
	    fromrow = gmod(qrow-1)
	elsif q = 4 then  -- top right
	    enterx = HSIZE - MAX_SHIP_WIDTH
	    fromrow = gmod(qrow-1)
	    fromcol = gmod(qcol+1)
	elsif q = 5 then  -- right
	    enterx = HSIZE - MAX_SHIP_WIDTH
	    entery = rand(VSIZE)
	    fromcol = gmod(qcol+1)
	elsif q = 6 then  -- bottom right
	    enterx = HSIZE - MAX_SHIP_WIDTH
	    entery = VSIZE
	    fromrow = gmod(qrow+1)
	    fromcol = gmod(qcol+1)
	elsif q = 7 then  -- bottom
	    enterx = 1 + rand(HSIZE - MAX_SHIP_WIDTH)
	    entery = VSIZE
	    fromrow = gmod(qrow+1)
	else              -- bottom left
	    entery = VSIZE
	    fromrow = gmod(qrow+1)
	    fromcol = gmod(qcol-1)
	end if
	if galaxy[fromrow][fromcol][G_CPP] then
	    entert = G_CPP -- two tries to pick C++ to enter
	    exit
	end if
    end for
    if entert = G_CPP then
	-- C++
    elsif galaxy[fromrow][fromcol][G_ANC] then
	entert = G_ANC
    elsif galaxy[fromrow][fromcol][G_KRC] then
	entert = G_KRC
    else
	randcol = rand(G_SIZE)
	randrow = rand(G_SIZE)
	if randcol != qrow or randcol != qcol then
	    if galaxy[randrow][randcol][G_JAV] then
		fromrow = randrow
		fromcol = randcol
		enterx = 1 + rand(HSIZE-MAX_SHIP_WIDTH)
		entery = rand(VSIZE)
		entert = G_JAV
	    end if
	end if
    end if
    if entert = 0 then
	if galaxy[fromrow][fromcol][G_BAS] then
	    entert = G_BAS
	end if
    end if
    enterc = read_screen({enterx, MAX_SHIP_WIDTH}, entery)
    if find(TRUE, enterc != ' ' and enterc != STAR) then
	entert = 0
    end if
    if entert then
	if add2quadrant(entert, enterx, entery) then
	    galaxy[qrow][qcol][entert] = galaxy[qrow][qcol][entert] + 1
	    galaxy[fromrow][fromcol][entert] = galaxy[fromrow][fromcol][entert]
						 - 1
	    if entert < G_BAS then
		upg(qrow, qcol)
		gsbox(qrow, qcol)
		upg(fromrow, fromcol)
	    end if
	    fmsg("%s HAS ENTERED QUADRANT", {otype[entert]})
	end if
    end if
end procedure

