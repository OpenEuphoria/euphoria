-- damage.e
-- compute effects of damage
include std/graphcst.e
include vars.e
include screen.e
include display.e
include soundeff.e
include pictures.e

public function Java_target(valid_quadrant_row r)
-- select target for Java ship at row r
    sequence flive

    flive = {}
    for i = 1 to length(quadrant) do
    if i != r and quadrant[i][Q_TYPE] != DEAD then
        flive &= i
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
        task_schedule(t_bstat, {2.3, 2.5})
    end if
    end if
    for row = 2 to length(quadrant) do
    if quadrant[row][Q_TYPE] = G_BAS then
        quadrant[row][Q_TARG] = basic_targ
    end if
    end for
end procedure

procedure setnt(quadrant_row victim)
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

public procedure repair(subsystem sys)
-- repair a subsystem
    if sys = ENGINES then
    wlimit = 5
    set_bk_color(WHITE)
    set_color(BLACK)
    position(WARP_LINE, WARP_POS+5)
    console_printf("%d   ", curwarp)
    end if
    ndmg -= 1
end procedure

procedure edmg(positive_atom blast)
-- Euphoria damage
    subsystem sys

    if blast > rand(256) * 80 then
    sys = rand(NSYS)
    if reptime[sys] = 0 then
        reptime[sys] = rand(81) + 9
        if sys = GALAXY_SENSORS then
        end_scan()
        end if
        if sys = ENGINES then
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
        ndmg += 1
        task_schedule(t_damage_report, {1.4, 1.5})
    end if
    end if
end procedure

boolean drep_on
drep_on = FALSE

procedure drep_blank()
-- clear the damage report area
    position(WARP_LINE, DREP_POS)
    console_puts(repeat(' ', 13))
    position(WARP_LINE+1, DREP_POS)
    console_puts(repeat(' ', 13))
end procedure

public procedure drep()
-- damage report update
    set_bk_color(RED)
    set_color(BLACK)
    if not drep_on then
    drep_blank()
    drep_on = TRUE
    end if
    position(WARP_LINE, DREP_POS+1)
    console_printf("P%-2d T%-2d S%-2d", {reptime[PHASORS],
                reptime[TORPEDOS],
                reptime[GALAXY_SENSORS]})
    position(CMD_LINE, DREP_POS+1)
    console_printf("G%-2d E%d", {reptime[GUIDANCE], reptime[ENGINES]})
    if reptime[ENGINES] > 0 then
    console_printf(":%d ", wlimit)
    else
    console_puts("   ")
    end if
end procedure

public procedure task_damage_report()
-- independent task: damage countdown

    while not gameover do
    if ndmg = 0 then
        task_suspend(task_self())
        set_bk_color(WHITE)
        drep_blank()
        drep_on = FALSE
    else
        for i = 1 to NSYS do
        if reptime[i] then
            reptime[i] -= 1
            if reptime[i] = 0 then
            repair(i)
            fmsg("%s REPAIRED", {dtype[i]})
            end if
        end if
        end for
        drep()
    end if
    task_yield()
    end while
end procedure

public procedure task_dead()
-- independent task: clean dead bodies off the screen
    integer c
    image r
    sequence ri
    boolean all_zero

    while TRUE do
    c = 1
    while c <= length(wipeout) do
        r = read_screen(wipeout[c][1], wipeout[c][2], wipeout[c][3])
        if all_clear(r) then
        all_zero = TRUE
        for i = 1 to length(r) do
            ri = r[i]
            for j = 1 to length(ri) do
            if and_bits(ri[j], #F) != 0 then
                if rand(2) = 1 then
                ri[j] = 0
                else
                all_zero = FALSE
                end if
            end if
            end for
            r[i] = ri
        end for
        write_screen(wipeout[c][1], wipeout[c][2], r)
        if all_zero then
            -- finished, delete this one
            wipeout = wipeout[1..c-1] & wipeout[c+1..$]
        else
            -- more clearing to do later
            c += 1
        end if
        else
        -- another object is in the way, skip it
        c += 1
        end if
    end while

    if c > 1 then
        -- we skipped something - finish later
        task_schedule(task_self(), {0.8, 1.0})
    else
        task_suspend(task_self())
    end if

    task_yield()
    end while
end procedure

public procedure task_explosion(sequence dots)
-- Plays out an explosion on the screen.
-- Accesses screen variable directly for maximum speed.
    integer p, c, x, y, half_way, my_quad
    boolean draw

    draw = TRUE

    my_quad = quad_count
    while my_quad = quad_count and draw do
    draw = FALSE
    half_way = floor(length(dots)/2)
    for i = 1 to length(dots) do
        if sequence(dots[i]) then
        x = floor(dots[i][2])
        y = floor(dots[i][3])
        p = screen[y][x]
        if p >= 33 and p <= 64 then
            screen[y][x] = 48 -- blank out old position
            if not scanon then
            pixel(48, {x-1, y-1})
            end if
        end if
        dots[i][2..3] += dots[i][4..5]
        x = floor(dots[i][2])
        y = floor(dots[i][3])
        -- draw at new position
        if rand(15) = 1 or
           x < 1 or x > HSIZE or
           y < 1 or y > VSIZE then
            -- delete this dot
            dots[i] = 0
        else
            -- draw it at new position
            draw = TRUE
            c = dots[i][1]
            p = screen[y][x]
            if p != c and (p = 0 or (p >= 33 and p <= 64)) then
            screen[y][x] = c
            if not scanon then
                pixel(c, {x-1, y-1})
            end if
            end if
        end if
        end if
        if i = half_way then
        task_yield() -- make things a bit smoother on slow machines
        if my_quad != quad_count then
            exit
        end if
        end if
    end for
    task_yield()
    end while

    task_schedule(t_dead, {0.2, 1})
end procedure

procedure explosion(h_coord x, v_coord y, natural xsize, natural ysize,
            natural ndots,
            natural color)
-- initiate an explosion on the screen centered at x, y
-- xsize and ysize must be at least 3
    sequence dots
    task t
    atom st
    natural tempx, tempy

    -- create initial set of colored dots
    dots = repeat(0, ndots)
    tempx = floor(xsize/2)-1
    tempy = floor(ysize/2)-1
    color += 32
    for i = 1 to ndots do
    dots[i] = {color,
           x+rand(tempx)+rand(tempx),
           y+rand(tempy)+rand(tempy),
           rand(400)/100 * (rand(2)*2-3),
           rand(400)/100 * (rand(2)*2-3)}
    end for
    t = task_create(routine_id("task_explosion"), {dots})
    st = .07+.00002*ndots
    task_schedule(t, {st-.03, st})
end procedure

public atom fire_time

public procedure sched_move_fire()
-- schedule enemy move and fire tasks according to number of
-- ships in the quadrant
    atom move_time, t
    integer enemy

    enemy = 0
    for i = 2 to length(quadrant) do
    if quadrant[i][Q_TYPE] != DEAD then
        enemy += 1
    end if
    end for

    move_time = .01 + .20 / (1+enemy)
    fire_time = .50 + 3 / (4+enemy)
    if level = 'n' then
    move_time *= 3
    fire_time *= 3
    end if
    task_schedule(t_move, {move_time-.02, move_time})

    t = rand(1+floor(fire_time))
    task_schedule(t_fire, {t-.10, t})
end procedure

-- bright version of object color for better-looking explosion
sequence ocolor
ocolor = {YELLOW,
      BRIGHT_RED,
      BRIGHT_RED,
      BRIGHT_MAGENTA,
      BRIGHT_BLUE,
      BRIGHT_GREEN,
      YELLOW,
      YELLOW}

procedure dead(valid_quadrant_row row)
-- process a dead object

    object_type t
    pb_row pbx
    h_coord x
    v_coord y
    natural lenx, leny
    image dead_body

    if row = EUPHORIA then
    -- Euphoria destroyed !
    quadrant[EUPHORIA][Q_EN] = 0
    p_energy(-1)
    end if
    t = quadrant[row][Q_TYPE]
    nobj[t] -= 1
    x = quadrant[row][Q_X]
    y = quadrant[row][Q_Y]
    dead_body = (read_screen(x, y, oshape[t][1]) != 32) * (ocolor[t]+32)
    lenx = length(oshape[t][1][1])
    leny = length(oshape[t][1])
    write_screen(x, y, dead_body)
    wipeout = append(wipeout, {x, y, dead_body})
    explosion(floor(quadrant[row][Q_X]),
          floor(quadrant[row][Q_Y]),
          lenx,
          leny,
          floor(lenx*leny+5),
          ocolor[t])
    explosion_sound(lenx)
    if t >= G_PL then
    pbx = quadrant[row][Q_PBX]
    pb[pbx][P_TYPE] = DEAD
    else
    if c_remaining() = 0 then
        stop_game()
    end if
    end if
    quadrant[row][Q_TYPE] = DEAD
    quadrant[row][Q_X] = HSIZE + 1
    quadrant[row][Q_Y] = VSIZE + 1
    if not gameover then
    setnt(row)
    galaxy[qrow][qcol][t] -= 1
    end if
    fmsg("%s DESTROYED!", {otype[t]})
    sched_move_fire()
    if scanon then
    upg(qrow, qcol)
    gtext()
    end if
end procedure

public procedure dodmg(positive_atom blast, boolean wtorp,
               valid_quadrant_row shooter, valid_quadrant_row victim)
-- damage a struck object
    object_type t
    natural d
    positive_atom ven

    t = quadrant[victim][Q_TYPE]
    if quadrant[shooter][Q_TYPE] = G_POD then
    if t = G_BAS then
        setrmt(EUPHORIA)
    elsif t != G_BS then
        quadrant[victim][Q_TARG] = EUPHORIA
    end if
    else
    -- note: shooter may have launched weapon just before he died
    if quadrant[shooter][Q_TYPE] != DEAD then
        if t = G_BAS then
        setrmt(shooter)
        elsif t = G_BS and shooter = EUPHORIA then
        -- do nothing if EUPHORIA hits base
        else
        quadrant[victim][Q_TARG] = shooter
        end if
    end if
    end if
    if wtorp then
    -- torpedo
    d = quadrant[victim][Q_DEFL]
    if d then
        deflected_sound()
        msg("DEFLECTED")
        quadrant[victim][Q_DEFL] = d-1
        ds = repeat(DEFL_SYM, quadrant[EUPHORIA][Q_DEFL])
        wtext()
        blast = 0
    else
        torpedo_hit()
    end if
    end if
    if blast then
    fmsg("%d UNIT HIT ON %s", {blast, otype[t]})
    ven = quadrant[victim][Q_EN]
    if blast >= ven then
        dead(victim)
    else
        ven -= blast
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

-- public constant ASPECT_RATIO = 1.0 -- vertical vs. horizontal pixel size

public function bcalc(positive_atom energy, valid_quadrant_row shooter,
              valid_quadrant_row victim)
-- calculate amount of phasor blast
    atom xdiff, ydiff

    xdiff = quadrant[victim][Q_X] - quadrant[shooter][Q_X]
    ydiff = (quadrant[victim][Q_Y] - quadrant[shooter][Q_Y]) --* ASPECT_RATIO
    return 1500 * energy / (50 + sqrt(xdiff * xdiff + ydiff * ydiff))
end function

