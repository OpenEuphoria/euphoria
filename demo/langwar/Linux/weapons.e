-- weapons.e
-- phasors, torpedos, antimatter pods

global constant W_PHASOR = 1,
		W_TORPEDO = 2,
		W_POD = 3

type weapon_system(integer x)
    return find(x, {W_PHASOR, W_TORPEDO, W_POD})
end type

extended_h_coord x0
extended_v_coord y0
atom xinc
atom yinc

function diftype(valid_quadrant_row shooter, valid_quadrant_row victim)
-- return TRUE if shooter and victim are on opposing sides

    if quadrant[shooter][Q_TYPE] = G_BS then
	return victim != EUPHORIA
    else
	if find(quadrant[shooter][Q_TYPE], {G_KRC, G_ANC, G_CPP}) and
	   find(quadrant[victim][Q_TYPE] , {G_KRC, G_ANC, G_CPP}) then
	    -- both are C ships
	    return FALSE
	else
	    return quadrant[shooter][Q_TYPE] != quadrant[victim][Q_TYPE]
	end if
    end if
end function

procedure pod_effect(h_coord rx,v_coord ry)
-- Detonate an antimatter pod. All objects in the quadrant are
-- affected. It's like a 1000-unit phasor blast directed toward everyone
-- *including* the Euphoria and all planets and bases in the quadrant.
-- The closer an object is to the pod when it explodes, the more
-- of a blast that object will feel.

    position(CMD_LINE, CMD_POS+6)
    set_bk_color(WHITE)
    puts(CRT, "     ")
    for c = 0 to 15 do
	set_bk_color(c)
	BlankScreen(FALSE)
	delay(.03)
    end for
    set_bk_color(BLACK)
    scanon = TRUE
    setg1()
    -- add POD to the quadrant temporarily
    quadrant = append(quadrant, repeat(0, length(quadrant[1]))) 
    shooter = length(quadrant)    
    quadrant[shooter][Q_TYPE] = G_POD
    quadrant[shooter][Q_X] = rx
    quadrant[shooter][Q_Y] = ry
    
    for i = length(quadrant)-1 to 1 by -1 do
	if quadrant[i][Q_TYPE] != DEAD then
	    victim = i
	    dodmg(bcalc(1000), FALSE)
	end if
    end for
    quadrant = quadrant[1..length(quadrant)-1] -- delete POD
end procedure

global procedure weapon(weapon_system w, positive_atom strength)
-- fire a phasor, torpedo or pod from shooter starting from (x0,y0) and
-- proceeding in steps of xinc, yinc until something is hit or the
-- edge of the screen is reached

    extended_h_coord x
    extended_v_coord y
    h_coord rx
    v_coord ry
    extended_h_coord prev_rx
    extended_v_coord prev_ry
    boolean ahit
    char c
    natural freq
    positive_atom units
    sequence under

    prev_rx = 0
    prev_ry = 0
    x = x0
    y = y0
    ahit = FALSE
    under = {}
    if w = W_TORPEDO then
	freq = 3500
	sound(freq)
    end if
    while x >= .5 and x < HSIZE + 0.5 and
	  y >= .5 and y < VSIZE + 0.5 do
	rx = floor(x + 0.5)
	ry = floor(y + 0.5)
	if rx != prev_rx or ry != prev_ry then
	    c = read_screen(rx, ry)
	    if c = ' ' or c = STAR or w = W_POD then
		prev_rx = rx
		prev_ry = ry
		if w = W_PHASOR then
		    under = prepend(under, {rx, ry, c})
		    write_screen(rx, ry, '*')
		    delay(0.003)
		else
		    -- POD or TORPEDO
		    if length(under) != 0 then
			write_screen(under[1][1], under[1][2], under[1][3])
		    end if
		    if w = W_TORPEDO then
			under = {{rx, ry, c}}
			write_screen(rx, ry, '*')
			delay(0.008)
			sound(freq)
			if freq > 600 then
			    freq = freq - 50
			end if
		    else
			-- POD
			if c = ' ' or c = STAR then
			    under = {{rx, ry, c}}
			    write_screen(rx, ry, POD)
			else
			    under = {} -- don't overwrite other objects 
			end if
			if get_key() = '\n' then  -- was 13
			    pod_effect(rx, ry)
			    exit
			end if
			sound(290)
			delay(0.06)
			sound(0)
			delay(0.06)
		    end if
		end if
	    else
		ahit = TRUE
		exit
	    end if
	end if
	x = x + xinc
	y = y + yinc
    end while

    if w != W_PHASOR then
	sound(0)
    end if
    if w != W_POD then
	if ahit then
	    victim = who_is_it(rx, ry, FALSE)
	    if diftype(shooter, victim) then
		if w = W_TORPEDO then
		    dodmg(strength, TRUE)
		else
		    units = bcalc(strength)
		    phasor_sound(units)
		    dodmg(units, FALSE)
		end if
	    end if
	end if
    end if
    for i = length(under) to 1 by -1 do
	write_screen(under[i][1], under[i][2], under[i][3])
    end for
end procedure

type object_height(integer x)
    return x >= 1 and x <= 3
end type

global procedure Java_phasor(positive_atom pen)
-- perform Java phasor: no phasor drawn, can't miss

    positive_atom blast
    h_coord targx
    v_coord targy
    sequence c
    natural len
    object_type t
    object_height height

    victim = quadrant[shooter][Q_TARG]
    targx = quadrant[victim][Q_X]
    targy = quadrant[victim][Q_Y]
    t = quadrant[victim][Q_TYPE]
    if victim = EUPHORIA then
	len = length(esym)
	height = 1
    elsif t = G_BS then
	len = length(BASE)
	height = 2
    elsif t = G_PL then
	len = length(PLANET_MIDDLE)
	height = 3
    else
	len = length(ship[quadrant[victim][Q_TYPE]][1])
	height = 1
    end if
    blast = bcalc(pen)
    for i = -2 to blast / 300 do
	sound(500 + 500 * (integer(i / 2)))
	write_screen(quadrant[shooter][Q_X]+1, quadrant[shooter][Q_Y], '-')
	c = repeat(0, height)
	for j = 0 to height - 1 do
	    c[j+1] = read_screen({targx, len}, targy + j)
	    write_screen(targx, targy + j, repeat(' ', len))
	end for
	delay(0.07)
	write_screen(quadrant[shooter][Q_X]+1, quadrant[shooter][Q_Y], '+')
	for j = 0 to height - 1 do
	    write_screen(targx, targy + j, c[j+1])
	end for
	delay(0.07)
    end for
    sound(0)
    dodmg(blast, FALSE)
end procedure

global procedure setpt(valid_quadrant_row r)
-- set up enemy (or base) phasor or torpedo

    positive_atom dist
    valid_quadrant_row targ
    h_coord targx
    v_coord targy
    object_type t

    x0 = quadrant[r][Q_X]
    y0 = quadrant[r][Q_Y]
    targ = quadrant[r][Q_TARG]
    targx = quadrant[targ][Q_X]
    targy = quadrant[targ][Q_Y]
    t = quadrant[r][Q_TYPE]

    -- decide which side to shoot from
    if t = G_BS then
	if x0 < targx then
	    x0 = x0 + length(BASE)
	else
	    x0 = x0 - 1
	end if
	if y0 < targy then
	    y0 = y0 + 2
	else
	    y0 = y0 - 1
	end if
    else
	if x0 < targx  then
	    x0 = x0 + length(ship[t][1])
	else
	    x0 = x0 - 1
	end if
    end if

    -- add a bit of randomness so they might miss
    xinc = targx - x0 + rand(5) - 3
    yinc = targy - y0 + rand(3) - 2
    if xinc = 0 and yinc = 0 then
	xinc = 1 -- prevent infinite loop
    end if
    dist = sqrt(1 + xinc * xinc + yinc * yinc)
    xinc = xinc/dist
    yinc = yinc/dist
end procedure

--constant PI = 3.14159265

type angle(atom x)
    return x >= 0 and x < 2 * PI
end type

global procedure esetpt(direction dir)
-- set up for euphoria phasor/torpedo/pod firing

    angle theta

    shooter = EUPHORIA
    x0 = quadrant[EUPHORIA][Q_X]
    y0 = quadrant[EUPHORIA][Q_Y]
    theta = (dir - 1)/8.0 * 2 * PI
    xinc = cos(theta)
    yinc = -sin(theta) / ASPECT_RATIO
    if xinc < -0.00001 then
	write_screen(x0, y0, esyml)
    elsif xinc > 0.00001 then
	write_screen(x0, y0, esymr)
    end if
    if read_screen(x0, y0) = esyml[1] then
	x0 = x0 - 1
    else
	x0 = x0 + length(esym)
    end if
end procedure
