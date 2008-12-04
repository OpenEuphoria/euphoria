-- weapons.e
-- phasors, torpedos, antimatter pods

include std/math.e
include std/graphcst.e
include std/dos/image.e
include vars.e
include screen.e
include display.e
include pictures.e
include damage.e
include soundeff.e

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

public sequence normal_palette

procedure task_pod_effect()
-- make the pod explosion effect (random colors)

    for i = 1 to 24 do
    all_palette(rand(repeat({63, 63, 63}, 16)))
    task_yield()
    end for
    all_palette(normal_palette)
end procedure

procedure pod_effect(h_coord rx,v_coord ry)
-- Detonate an antimatter pod. All objects in the quadrant are
-- affected. It's like a 1000-unit phasor blast directed toward everyone
-- *including* the Euphoria and all planets and bases in the quadrant.
-- The closer an object is to the pod when it explodes, the more
-- of a blast that object will feel.
    task t
    valid_quadrant_row shooter

    end_scan()

    -- add POD to the quadrant temporarily
    quadrant = append(quadrant, repeat(0, length(quadrant[1])))
    shooter = length(quadrant)
    quadrant[shooter][Q_TYPE] = G_POD
    quadrant[shooter][Q_X] = rx
    quadrant[shooter][Q_Y] = ry

    for i = length(quadrant)-1 to 1 by -1 do
    if quadrant[i][Q_TYPE] != DEAD then
        dodmg(bcalc(1000, shooter, i), FALSE, shooter, i)
    end if
    end for
    quadrant = quadrant[1..$-1] -- delete POD
    t = task_create(routine_id("task_pod_effect"), {})
    task_schedule(t, {.08, .10})
end procedure

public boolean EnterPressed

procedure task_pod(extended_h_coord prev_rx,
          extended_v_coord prev_ry,
          extended_h_coord x,
          extended_v_coord y,
          extended_h_coord rx,
          extended_v_coord ry,
          atom xinc,
          atom yinc,
          sequence under)
-- Independent task to run one iteration of an antimatter pod.
-- There can be many "instances" of this task active simultaneously.
    image c
    integer my_quad_count

    my_quad_count = quad_count
    while my_quad_count = quad_count and
      rx >= 1 and rx <= HSIZE-length(POD[1]) and
      ry >= 1 and ry <= VSIZE-length(POD) do
    if length(under) != 0 then
        write_screen(under[1][1], under[1][2], under[1][3])
    end if
    c = read_screen(rx, ry, POD)
    prev_rx = rx
    prev_ry = ry
    if all_clear(c) then
        -- keep stars, lose phasor/torpedo dust
        write_screen(rx, ry, POD)
        c = c * (c > 64)
        under = {{rx, ry, c}}
    else
        under = {}
    end if
    if EnterPressed then
        pod_effect(rx, ry)
        exit
    end if
    pod_sound(290, .01)
    while TRUE do
        x += xinc
        y += yinc
        rx = floor(x+0.5)
        ry = floor(y+0.5)
        if rx != prev_rx or ry != prev_ry then
        exit
        end if
    end while
    task_yield()
    end while

    if my_quad_count = quad_count and length(under) then
    write_screen(under[1][1], under[1][2], under[1][3])
    end if
end procedure

public procedure pod()
-- fire a pod from shooter starting from (x0,y0) and
-- proceeding in steps of xinc, yinc until Enter is pressed,
-- or the edge of the screen is reached

    task t

    t = task_create(routine_id("task_pod"),
            {0, 0, x0, y0, x0, y0, xinc, yinc, {}})
    -- start right away
    task_schedule(t, {0.02, .03})
    msg("PRESS Enter TO DETONATE!")
    msg("PRESS Enter TO DETONATE!") -- so it won't disappear too soon
end procedure

constant TORPEDO_ZERO = TORPEDO * 0

procedure task_phasor(extended_h_coord prev_rx,
              extended_v_coord prev_ry,
              extended_h_coord x,
              extended_v_coord y,
              extended_h_coord rx,
              extended_v_coord ry,
              atom xinc,
              atom yinc,
              sequence under,
              positive_atom strength,
              valid_quadrant_row my_shooter
)
-- Independent task to display a phasor beam.
-- There can be many "instances" of this task active simultaneously.

    sequence who
    positive_atom units
    image c
    object u
    atom t
    quadrant_row victim
    integer my_quad_count

    my_quad_count = quad_count
    task_schedule(task_self(), {0.0010, 0.0015}) --{0.0005, 0.0015})
    victim = -1

    while my_quad_count = quad_count and
      rx >= 1 and rx <= HSIZE-TORPEDO_WIDTH and
      ry >= 1 and ry <= VSIZE-TORPEDO_HEIGHT do
    c = read_torp(rx, ry)
    if all_clear(c) then
        prev_rx = rx
        prev_ry = ry
        c *= (c > 64)
        if equal(c, TORPEDO_ZERO) then
        under = append(under, {rx, ry, 0})
        else
        under = append(under, {rx, ry, c})
        end if
        write_torp(rx, ry, TORPEDO)
    else
        who = who_is_it(rx, ry, TORPEDO)
        if find(FALSE, who = my_shooter) then
        -- if anyone other than the shooter
        for i = 1 to length(who) do
            if who[i] != my_shooter then
            victim = who[i]
            exit
            end if
        end for
        if diftype(my_shooter, victim) then
            units = bcalc(strength, my_shooter, victim)
            phasor_sound(units)
            dodmg(units, FALSE, my_shooter, victim)
        end if
        exit
        end if
    end if

    -- skip to next location on path
    while TRUE do
        x += xinc
        y += yinc
        rx = floor(x+0.5)
        ry = floor(y+0.5)
        if rx != prev_rx or ry != prev_ry then
        exit
        end if
    end while

    task_yield()
    end while

    -- leave phasor showing for an instant
    -- (a bit longer if we hit something)
    if gameover then
    -- We're going to be killed. Do delay right here
    -- so last phasor shows clearly.
    t = time()
    while time() < t+.2 do
    end while
    else
    task_schedule(task_self(), {.05, .07} + (victim != -1) * {.08, .10})
    task_yield()
    end if

    -- Erase the phasor, most recent first.
    -- Looks better when it's done quickly.
    if my_quad_count != quad_count then
    return -- we switched quadrants during a yield
    end if

    for i = length(under) to 1 by -1 do
    x = under[i][1]
    y = under[i][2]
    c = read_torp(x, y)
    -- Some care is required,
    -- a solid object may have moved across the phasor path.
    if c[1][1] >= 33 then c[1][1] = 0 end if
    if c[1][2] >= 33 then c[1][2] = 0 end if
    if c[2][1] >= 33 then c[2][1] = 0 end if
    if c[2][2] >= 33 then c[2][2] = 0 end if
    u = under[i][3]
    if sequence(u) then
        -- star(s) to replace
        for r = 1 to TORPEDO_HEIGHT do
        for s = 1 to TORPEDO_WIDTH do
            if c[r][s] = 0 and u[r][s] > 64 then
            c[r][s] = u[r][s]  -- replace star
            end if
        end for
        end for
    end if
    write_torp(x, y, c)
    end for
end procedure

public procedure phasor(valid_quadrant_row shooter, positive_atom strength)
-- fire a phasor from shooter starting from (x0,y0) and
-- proceeding in steps of xinc, yinc until something is hit or the
-- edge of the screen is reached
    task t

    t = task_create(routine_id("task_phasor"),
            {0, 0, x0, y0, x0, y0, xinc, yinc, {}, strength, shooter})
    -- Start right away.
    task_schedule(t, {0.009, .010})
end procedure

procedure task_torpedo(extended_h_coord x,
               extended_v_coord y,
               atom xinc,
               atom yinc,
               integer freq,
               valid_quadrant_row my_shooter)
-- Independent task to run one iteration of a torpedo.
-- There can be many "instances" of this task active simultaneously.

    extended_h_coord prev_rx, rx
    extended_v_coord prev_ry, ry
    sequence under
    sequence who
    image c, u
    quadrant_row victim
    integer my_quad_count

    under = {}
    prev_rx = 0
    prev_ry = 0
    rx = x
    ry = y
    my_quad_count = quad_count

    while my_quad_count = quad_count and
      rx >= 1 and rx <= HSIZE-TORPEDO_WIDTH and
      ry >= 1 and ry <= VSIZE-TORPEDO_HEIGHT do

    if length(under) = 7 then
        c = read_torp(under[1][1], under[1][2])
        c *= (c < 33)
        -- merge in any stars that were hidden
        u = under[1][3]
        c += ((c = 0) and (u > 64)) * u
        write_torp(under[1][1], under[1][2], c)
        under = under[2..$]
    end if

    c = read_torp(rx, ry)

    if all_clear(c) then
        prev_rx = rx
        prev_ry = ry
        write_torp(rx, ry, TORPEDO)
        c *= (c > 64) -- only keep stars
        under = append(under, {rx, ry, c})
        torpedo_sound(freq, .02)
        if freq > 600 then
        freq -= 50
        end if

    else
        -- did we hit something?
        who = who_is_it(rx, ry, TORPEDO)
        if find(FALSE, who = my_shooter) then
        -- hit something other than the shooter himself
        for i = 1 to length(who) do
            if who[i] != my_shooter then
            victim = who[i]
            exit
            end if
        end for
        if diftype(my_shooter, victim) then
            dodmg(4000, TRUE, my_shooter, victim)
        end if
        if not gameover then
            -- display for a fraction of a second before erasing
            task_schedule(task_self(), {.02, .04})
            task_yield()
        end if
        exit
        end if
    end if

    while TRUE do
        x += xinc
        y += yinc
        rx = floor(x+0.5)
        ry = floor(y+0.5)
        if rx != prev_rx or ry != prev_ry then
        exit
        end if
    end while

    task_yield()
    end while

    if my_quad_count != quad_count then
    return -- we switched quadrants during a yield
    end if

    -- erase
    for i = length(under) to 1 by -1 do
    x = under[i][1]
    y = under[i][2]
    c = read_torp(x, y)
    c *= c < 33
    u = under[i][3]
    c += ((c = 0) and (u > 64)) * u
    write_torp(x, y, c)
    end for
end procedure

public procedure torpedo(valid_quadrant_row shooter)
-- fire a torpedo from shooter starting from (x0,y0) and
-- proceeding in steps of xinc, yinc until something is hit or the
-- edge of the screen is reached

    task t

    t = task_create(routine_id("task_torpedo"),
            {x0, y0, xinc, yinc, 3500, shooter})
    task_schedule(t, {.005, .007}) --{.004, .008})
end procedure

procedure task_Java_phasor(positive_atom blast,
               image v,
               image j,
               valid_quadrant_row shooter,
               valid_quadrant_row victim)
    h_coord targx
    v_coord targy
    natural c
    integer i, my_quad_count

    task_schedule(task_self(), {.12, .15})
    i = 1
    my_quad_count = quad_count

    while my_quad_count = quad_count and quadrant[victim][Q_TYPE] != DEAD do
    targx = quadrant[victim][Q_X]
    targy = quadrant[victim][Q_Y]
    if i <= blast / 300 + 9 then
        Java_phasor_sound(1500 + 1000 * (integer(i / 2)), .08)
        if remainder(i, 2) then
        c = BRIGHT_WHITE
        else
        c = GREEN
        end if
        write_screen(targx, targy, v + (v != 32) * (c - v))
        if victim = EUPHORIA then
        euphoria_color(c)
        end if
        i = i + 1
        task_yield()
    else
        -- make sure right color is restored
        if quadrant[victim][Q_TYPE] = G_BS then
        v = BASE
        elsif quadrant[victim][Q_TYPE] = G_PL then
        v = PLANET
        end if
        write_screen(targx, targy, v)
        dodmg(blast, FALSE, shooter, victim)
        if victim = EUPHORIA then
        euphoria_color(YELLOW)
        end if
        exit
    end if
    end while

    if my_quad_count = quad_count and quadrant[shooter][Q_TYPE] != DEAD then
    write_screen(quadrant[shooter][Q_X], quadrant[shooter][Q_Y], j)
    quadrant[shooter][Q_MRATE] = 90
    quadrant[shooter][Q_FRATE] = 40
    end if
end procedure

public procedure Java_phasor(valid_quadrant_row shooter, positive_atom pen)
-- perform Java phasor: no phasor drawn, can't miss

    positive_atom blast
    h_coord targx
    v_coord targy
    image v, j
    natural len
    task t
    quadrant_row victim

    quadrant[shooter][Q_MRATE] = 0 -- don't move or fire until it's over
    quadrant[shooter][Q_FRATE] = 0
    j = read_screen(quadrant[shooter][Q_X], quadrant[shooter][Q_Y], JAVA_L)
    if equal(j, JAVA_L) then
    write_screen(quadrant[shooter][Q_X], quadrant[shooter][Q_Y],
             JAVA_LS)
    else
    write_screen(quadrant[shooter][Q_X], quadrant[shooter][Q_Y],
             JAVA_RS)
    end if
    victim = quadrant[shooter][Q_TARG]
    targx = quadrant[victim][Q_X]
    targy = quadrant[victim][Q_Y]
    len   = length(oshape[quadrant[victim][Q_TYPE]][1][1])
    blast = bcalc(pen, shooter, victim)
    v = read_screen(targx, targy, oshape[quadrant[victim][Q_TYPE]][1])
    t = task_create(routine_id("task_Java_phasor"),
            {blast, v, j, shooter, victim})
    task_schedule(t, {0.01, .15})
end procedure

public procedure setpt(valid_quadrant_row r, boolean torp)
-- set up enemy (or base) phasor or torpedo

    positive_atom dist, rough_dist, lead, fuzz
    valid_quadrant_row targ
    extended_h_coord targx
    extended_v_coord targy
    object_type t

    x0 = quadrant[r][Q_X]
    y0 = quadrant[r][Q_Y]
    targ = quadrant[r][Q_TARG]
    -- aim roughly at center
    targx = quadrant[targ][Q_X] + 10
    targy = quadrant[targ][Q_Y] + 3

    rough_dist = sqrt(power(x0-targx, 2) + power(y0-targy, 2))
    if targ = EUPHORIA and curwarp > 2 then
    -- Make a leading shot for better results.
    -- This is a rough adjustment for phasor or torpedo shot.
    lead = rough_dist / (830 * warp_time[1+curwarp][2]) * (1 + torp*4)
    targx += exi * lead
    targy += eyi * lead
    end if
    t = quadrant[r][Q_TYPE]

    -- decide which side to shoot from
    if x0 + 8 < targx then
    if t != G_BS then
        write_screen(x0, y0, oshape[t][2])
    end if
    x0 += length(oshape[t][1][1])
    else
    if t != G_BS then
        write_screen(x0, y0, oshape[t][1])
    end if
    x0 -= TORPEDO_WIDTH
    end if
    if y0 < targy then
    y0 += length(oshape[t][1])
    else
    y0 -= TORPEDO_HEIGHT
    end if

    -- add a bit of randomness so they might miss
    fuzz = 20 + rough_dist/10
    xinc = targx - x0 + rand(fuzz) - fuzz/2
    yinc = targy - y0 + rand(fuzz) - fuzz/2
    if xinc = 0 and yinc = 0 then
    xinc = 1 -- prevent infinite loop
    end if
    dist = sqrt(0.1 + xinc * xinc + yinc * yinc) / TORPEDO_HEIGHT
    xinc /= dist
    yinc /= dist
    -- make it a bit thicker
    xinc *= 0.8
    yinc *= 0.8
end procedure

type angle(atom x)
    return x >= -2 * PI and x <= 2 * PI
end type

public procedure esetpt(direction dir, integer dir_adjust)
-- set up for euphoria phasor/torpedo/pod firing

    angle theta
    atom xdir

    xdir = dir - 1
    if dir_adjust = '>' then
    xdir += .03333
    elsif dir_adjust = '<' then
    xdir -= .03333
    end if
    theta = xdir/8.0 * 2 * PI
    xinc = cos(theta) * TORPEDO_WIDTH
    yinc = -sin(theta) * TORPEDO_HEIGHT -- / ASPECT_RATIO

    -- make it a bit thicker:
    xinc *= 0.7
    yinc *= 0.7

    x0 = quadrant[EUPHORIA][Q_X]
    y0 = quadrant[EUPHORIA][Q_Y]
    if curdir = 3 or curdir = 7 then
    -- Euphoria can face either way
    if xinc < -0.001 then
        esym = esyml
        write_screen(x0, y0, esym)
    elsif xinc > 0.001 then
        esym = esymr
        write_screen(x0, y0, esym)
    end if
    end if
    -- start in middle
    x0 += floor(length(esym[1])/2)
    y0 += floor(length(esym)/2)
    -- skip first two iterations (inside the ship image)
    x0 = floor(x0 + 2*xinc + 0.5)
    y0 = floor(y0 + 2*yinc + 0.5)
end procedure


