-- damage.e
-- compute effects of damage

global function Java_target(valid_quadrant_row r)
-- select target for Java ship at row r
    sequence flive

    flive = {}
    for i = 1 to length(quadrant) do
	if i != r and quadrant[i][Q_TYPE] != DEAD then
	    flive = flive & i
	end if
    end for
    return flive[rand(length(flive))]
end function

procedure setrmt(valid_quadrant_row newtarg)
-- set BASIC group target

    basic_targ = newtarg
    if bstat = TRUCE then
	if basic_targ = EUPHORIA or quadrant[basic_targ][Q_TYPE] = G_BS then
	    truce_broken = TRUE
	    sched(TASK_BSTAT, 2.5)
	end if
    end if
    for row = 2 to length(quadrant) do
	if quadrant[row][Q_TYPE] = G_BAS then
	    quadrant[row][Q_TARG] = basic_targ
	end if
    end for
end procedure

procedure setnt()
-- target is dead 
-- set new target for everyone that was shooting at him
    natural t -- type or 0
    valid_quadrant_row targ

    for row = 2 to length(quadrant) do
	if quadrant[row][Q_TARG] = victim then
	    t = quadrant[row][Q_TYPE]
	    if t = G_BS then
		quadrant[row][Q_FRATE] = 0
	    else
		if t = G_JAV then
		    targ = Java_target(row)
		else
		    targ = EUPHORIA
		end if
		quadrant[row][Q_TARG] = targ
	    end if
	end if
    end for
    if victim = basic_targ then
	basic_targ = EUPHORIA
    end if
end procedure

global procedure repair(subsystem sys)
-- repair a subsystem
    if sys = ENGINES then
	wlimit = 5
	set_bk_color(WHITE)
	set_color(BLACK)
	position(WARP_LINE, WARP_POS+5)
	printf(CRT, "%d   ", curwarp)
    end if
    ndmg = ndmg - 1
end procedure

procedure edmg(positive_atom blast)
-- Euphoria damage
    subsystem sys

    if blast > rand(256) * 70 then
	sys = rand(NSYS)
	if reptime[sys] = 0 then
	    reptime[sys] = rand(81) + 9
	    if sys = GALAXY_SENSORS then
		setg1()
	    elsif sys = ENGINES then
		wlimit = rand(4) - 1
		if wlimit = 0 then
		    msg("ALL ENGINES DAMAGED")
		else
		    msg("ENGINES DAMAGED")
		end if
		if curwarp > wlimit then
		    setwarp(wlimit)
		end if
	    else
		fmsg("%s DAMAGED", {dtype[sys]})
	    end if
	    wait[TASK_DAMAGE] = 1.5
	    ndmg = ndmg + 1
	    sched(TASK_DAMAGE, 1.5)
	end if
    end if
end procedure

boolean drep_on
drep_on = FALSE

procedure drep_blank()
-- clear the damage report area
    position(WARP_LINE, DREP_POS)
    puts(CRT, repeat(' ', 13))
    position(WARP_LINE+1, DREP_POS)
    puts(CRT, repeat(' ', 13))
end procedure

global procedure drep()
-- damage report update
    set_bk_color(GREEN)
    set_color(BRIGHT_WHITE)
    if not drep_on then
	drep_blank()
	drep_on = TRUE
    end if
    position(WARP_LINE, DREP_POS+1)
    printf(CRT, "P%-2d T%-2d S%-2d", {reptime[PHASORS],
				reptime[TORPEDOS],
				reptime[GALAXY_SENSORS]})
    position(CMD_LINE, DREP_POS+1)
    printf(CRT, "G%-2d E%d", {reptime[GUIDANCE], reptime[ENGINES]})
    if reptime[ENGINES] > 0 then
	printf(CRT, ":%d ", wlimit)
    else
	puts(CRT, "   ")
    end if
end procedure

global procedure task_dmg()
-- independent task: damage countdown

    if ndmg = 0 then
	wait[TASK_DAMAGE] = INACTIVE
	set_bk_color(WHITE)
	drep_blank()
	drep_on = FALSE
    else
	for i = 1 to NSYS do
	    if reptime[i] then
		reptime[i] = reptime[i] - 1
		if reptime[i] = 0 then
		    repair(i)
		    fmsg("%s REPAIRED", {dtype[i]})
		end if
	    end if
	end for
	drep()
    end if
end procedure

global procedure task_dead()
-- independent task: clean dead bodies off the screen
    set_bk_color(BLACK)
    set_color(WHITE)
    for c = 1 to length(wipeout) do
	for i = 0 to wipeout[c][3]-1 do
	    if read_screen(wipeout[c][1] + i, wipeout[c][2]) = ' ' then
		display_screen(wipeout[c][1] + i, wipeout[c][2], ' ')
	    end if
	end for
    end for
    wipeout = {}
end procedure

global function who_is_it(h_coord x, v_coord y, boolean src_chk)
-- map (x,y) screen coordinate to quadrant sequence row
-- src_chk is true when we just want to see if we are docking

    extended_h_coord ix
    extended_v_coord iy
    natural t, len, xend

    xend = x + length(esym) - 1
    for i = EUPHORIA + src_chk to length(quadrant) do
	ix = quadrant[i][Q_X]
	iy = quadrant[i][Q_Y]
	t = quadrant[i][Q_TYPE]

	if t = G_BS then
	    if x >= ix and x < ix + length(BASE) and
	       y >= iy and y < iy + 2 then
		   return i
	    end if
	    if src_chk then
		-- check other end of Euphoria too
		-- (assumes base is reasonably wide)
		if xend >= ix and xend < ix + length(BASE) and
		   y >= iy and y < iy + 2 then
		    return i
		end if
	    end if

	elsif t = G_PL then
	    if x >= ix and x < ix + length(PLANET_MIDDLE) and
	       y >= iy and y < iy + 3 then
		return i
	    end if
	    if src_chk then
		-- check other end of Euphoria too
		-- (assumes planet is reasonably wide)
		if xend >= ix and xend < ix + length(PLANET_MIDDLE) and
		   y >= iy and y < iy + 3 then
		    return i
		end if
	    end if

	elsif t then
	    if i = EUPHORIA then
		len = length(esym)
	    else
		len = length(ship[t][1])
	    end if
	    if x >= ix and x < ix + len and y = iy then
		return i
	    end if
	    if src_chk then
		-- check other end too
		if xend >= ix and xend < ix + len and y = iy then
		    return i
		end if
	    end if
	end if
    end for
end function

procedure dead(valid_quadrant_row row)
-- process a dead object

    object_type t
    h_coord x
    v_coord y
    pb_row pbx
    natural len
    
    t = quadrant[row][Q_TYPE]
    if row = EUPHORIA then
	-- Euphoria destroyed !
	quadrant[EUPHORIA][Q_EN] = 0
	p_energy(-1)
    else
	nobj[t] -= 1
	galaxy[qrow][qcol][t] -= 1
	x = quadrant[row][Q_X]
	y = quadrant[row][Q_Y]
	set_bk_color(BLACK)
	set_color(BRIGHT_WHITE)
	if t >= G_PL then
	    pbx = quadrant[row][Q_PBX]
	    pb[pbx][P_TYPE] = DEAD
	    if t = G_BS then
		len = length(BASE)
		for i = 0 to 1 do
		    display_screen(x, y + i, repeat('*', len))
		    wipeout = append(wipeout, {x, y + i, len})
		end for
	    else
		len = length(PLANET_MIDDLE)
		for i = 0 to 2 do
		    display_screen(x, y + i, repeat('*', len))
		    wipeout = append(wipeout, {x, y + i, len})
		end for
	    end if
	else
	    len = length(ship[t][1])
	    display_screen(x, y, repeat('*', len))
	    wipeout = append(wipeout, {x, y, len})
	    if c_remaining() = 0 then
		gameover = TRUE
	    end if
	end if
	quadrant[row][Q_TYPE] = DEAD
	quadrant[row][Q_X] = HSIZE + 1
	quadrant[row][Q_Y] = VSIZE + 1
	setnt()
	fmsg("%s DESTROYED!", {otype[t]})
	sched(TASK_DEAD, 1.6)
    end if
    explosion_sound()
    if scanon then
	upg(qrow, qcol)
	gsbox(qrow, qcol)
	gtext()
    end if
end procedure

global procedure dodmg(positive_atom blast, boolean wtorp)
-- damage a struck object
    object_type t
    natural d
    positive_atom ven

    t = quadrant[victim][Q_TYPE]
    if quadrant[shooter][Q_TYPE] = G_POD then
	if t = G_BAS then
	    setrmt(EUPHORIA)
	else
	    quadrant[victim][Q_TARG] = EUPHORIA
	end if
    else
	if t = G_BAS then
	    setrmt(shooter)
	else
	    quadrant[victim][Q_TARG] = shooter
	end if
    end if
    if wtorp then
	-- torpedo
	d = quadrant[victim][Q_DEFL]
	if d then
	    deflected_sound()
	    msg("DEFLECTED")
	    quadrant[victim][Q_DEFL] = d-1
	    ds = repeat(DEFLECTOR, quadrant[EUPHORIA][Q_DEFL])
	    wtext()
	    blast = 0
	else
	    torpedo_sound()
	end if
    end if
    if blast then
	fmsg("%d UNIT HIT ON %s", {blast, otype[t]})
	ven = quadrant[victim][Q_EN]
	if blast >= ven then
	    dead(victim)
	else
	    ven = ven - blast
	    quadrant[victim][Q_EN] = ven
	    if t <= G_JAV then
		if victim = EUPHORIA then
		    p_energy(0)
		    edmg(blast)
		else
		    fmsg("%d UNITS REMAIN", ven)
		end if
	    end if
	end if
    end if
end procedure

global constant ASPECT_RATIO = 2.6 -- roughly (distance of one line up/down = 
				   -- how many chars left-right) 

global function bcalc(positive_atom energy)
-- calculate amount of phasor blast
    atom xdiff, ydiff

    xdiff = quadrant[victim][Q_X] - quadrant[shooter][Q_X]
    ydiff = (quadrant[victim][Q_Y] - quadrant[shooter][Q_Y]) * ASPECT_RATIO
    return 200 * energy / (5 + sqrt(xdiff * xdiff + ydiff * ydiff))
end function
