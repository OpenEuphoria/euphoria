-- enemy.e
-- operate the enemy ships
include std/graphcst.e
include vars.e
include screen.e
include emove.e
include display.e
include pictures.e
include weapons.e
include soundeff.e
include damage.e

procedure set_basic_color()
-- set new color and "shape" for BASIC ships after truce/hostile change
    sequence shape, new_shape

    for i = 2 to length(quadrant) do
    if quadrant[i][Q_TYPE] = G_BAS then
        shape = read_screen(quadrant[i][Q_X], quadrant[i][Q_Y], BASIC_L)
        -- reprint with new shape & color
        if equal(shape, BASIC_L) then
        new_shape = oshape[G_BAS][1]
        else
        new_shape = oshape[G_BAS][2]
        end if
        write_screen(quadrant[i][Q_X], quadrant[i][Q_Y], new_shape)
    end if
    end for
end procedure

global procedure task_bstat()
-- independent task: BASIC status change

    positive_atom w
    natural prevstat

    while not gameover do
    prevstat = bstat
    w = rand(200) + rand(200) + 20
    if bstat = TRUCE then
        if truce_broken then
        truce_broken = FALSE
        msg("TRUCE BROKEN!")
        else
        msg("BASIC STATUS: HOSTILE")
        end if
        if rand(20) < 16 then
        -- switch to hostile
        w *= 1.2
        oshape[G_BAS] = {BASIC_L, BASIC_R}
        oshape[G_BAS] = BLUE * (and_bits(oshape[G_BAS], #F) != 0)
                + 32 * (oshape[G_BAS] = 32)
        bstat = HOSTILE
        else
        -- switch to cloaking
        w *= .6
        oshape[G_BAS] = INVISIBLE_CHAR * (oshape[G_BAS] = oshape[G_BAS])
        bstat = CLOAKING
        end if
    else
        -- hostile/cloaking
        if rand(20) < 10 then
        -- switch to truce
        bstat = TRUCE
        msg("BASIC STATUS: TRUCE")
        w *= .83
        oshape[G_BAS] = {BASIC_L, BASIC_R}
        else
        if bstat = HOSTILE then
            -- hostile --> cloaking
            w *= .6
            bstat = CLOAKING
            oshape[G_BAS] = INVISIBLE_CHAR * (oshape[G_BAS] = oshape[G_BAS])
        else
            -- cloaking --> hostile
            w *= 1.2
            bstat = HOSTILE
            oshape[G_BAS] = {BASIC_L, BASIC_R}
            oshape[G_BAS] = BLUE * (and_bits(oshape[G_BAS], #F) != 0)
                    + 32 * (oshape[G_BAS] = 32)
        end if
        end if
    end if
    set_basic_color()
    if scanon then
        gtext()
        if bstat = CLOAKING or prevstat = CLOAKING then
        refresh_scan()
        end if
    end if
    task_schedule(task_self(), {w - 0.2, w})
    task_yield()
    end while
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
    if rowx < targx-4 then
    write_screen(rowx, rowy, oshape[t][2])
    elsif rowx > targx+4 then
    write_screen(rowx, rowy, oshape[t][1])
    end if
end procedure

procedure shoot(valid_quadrant_row shooter)
-- select torpedo or phasor for enemy shot

    natural torp
    positive_atom pen
    boolean w

    torp = quadrant[shooter][Q_TORP]
    w = torp > 0 and rand(4) = 1
    setpt(shooter, w)
    if w then
    quadrant[shooter][Q_TORP] = torp - 1
    torpedo(shooter)
    else
    pen = quadrant[shooter][Q_EN] / 8
    if quadrant[shooter][Q_TYPE] = G_JAV then
        Java_phasor(shooter, pen)
    else
        phasor(shooter, pen)
    end if
    quadrant[shooter][Q_EN] -= pen
    end if
end procedure

global procedure task_fire()
-- independent task: select an enemy ship for firing

    quadrant_row row
    natural rate
    quadrant_row targ

    while not gameover do
    if length(quadrant) > 1 then
        row = rand(length(quadrant)-1) + EUPHORIA  -- choose a random ship
        if quadrant[row][Q_TYPE] = DEAD then
        row = rand(length(quadrant)-1) + EUPHORIA  -- try once more
        end if

        if quadrant[row][Q_TYPE] != DEAD then
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
        end if
    end if
    task_schedule(task_self(), {fire_time-.2, fire_time})
    task_yield()
    end while
end procedure

global procedure task_move()
-- independent task: select an enemy ship for moving

    quadrant_row row
    natural mrate
    h_coord fx
    v_coord fy
    extended_h_coord xtry
    extended_v_coord ytry
    image fchar, schar
    natural t
    object direction

    while not gameover do
    if length(quadrant) > 1 then
        row = rand(length(quadrant)-1) + EUPHORIA  -- choose a random ship
        t = quadrant[row][Q_TYPE]
        if t != DEAD then
        mrate = quadrant[row][Q_MRATE]
        if mrate > rand(256) then
            -- try to move
            fx = quadrant[row][Q_X]
            fy = quadrant[row][Q_Y]
            direction = quadrant[row][Q_DIRECTION]
            if atom(direction) or rand(25) = 1 then
            -- pick a new direction
            xtry = fx + rand(7) - 4
            ytry = fy + rand(7) - 4
            else
            xtry = fx + direction[1]
            ytry = fy + direction[2]
            end if
            if xtry >= 2 and xtry <= HSIZE - length(oshape[t][1][1]) and
            ytry >= 1 and ytry <= VSIZE - length(oshape[t][1]) then
            fchar = read_screen(fx, fy, oshape[t][1])
            write_screen(fx, fy, quadrant[row][Q_UNDER])
            schar = read_screen(xtry, ytry, oshape[t][1])
            if all_clear(schar) then
                -- keep stars, lose phasor/torpedo dust
                schar *= (schar > 64)
                quadrant[row][Q_UNDER] = schar
                write_screen(xtry , ytry, fchar)
                quadrant[row][Q_X] = xtry
                quadrant[row][Q_Y] = ytry
                quadrant[row][Q_DIRECTION] = {xtry-fx, ytry-fy}
            else
                write_screen(fx, fy, fchar) -- put it back
            end if
            else
            -- direction is bad
            quadrant[row][Q_DIRECTION] = 0
            end if
            orient(row)
        end if
        end if
    end if

    task_yield()
    end while
end procedure

function add2quadrant(object_type t, h_coord x, v_coord y)
-- add a ship to the quadrant sequence

    quadrant_row targ
    valid_quadrant_row row
    image c

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
    c = read_screen(x, y, oshape[t][1])
    c *= (c > 64)
    quadrant[row][Q_UNDER] = c
    quadrant[row][Q_TARG] = targ
    if x < quadrant[EUPHORIA][Q_X] then
    c = oshape[t][2]
    else
    c = oshape[t][1]
    end if
    write_screen(x, y, c)
    return TRUE
end function

global procedure task_enter()
-- independent task: enemy ship enters quadrant

    natural q
    h_coord enterx, max_h
    v_coord entery, max_v
    natural entert
    sequence enterc
    g_index randcol, randrow, fromcol, fromrow
    image shape
    atom t

    while not gameover do
    t = 3 + rand(30) * (curwarp > 2) +
        quadrant[EUPHORIA][Q_EN]/(3000 + rand(6000))
    task_schedule(task_self(), {t-0.5, t})
    if rand(3+7*(level = 'n')) = 1 then
        for i = 1 to 2 do
        entert = 0
        q = rand(8)
        if q = 1 then     -- left
            fromrow = qrow
            fromcol = gmod(qcol-1)

        elsif q = 2 then  -- top left
            fromrow = gmod(qrow-1)
            fromcol = gmod(qcol-1)

        elsif q = 3 then  -- top
            fromrow = gmod(qrow-1)
            fromcol = qcol

        elsif q = 4 then  -- top right
            fromrow = gmod(qrow-1)
            fromcol = gmod(qcol+1)

        elsif q = 5 then  -- right
            fromrow = qrow
            fromcol = gmod(qcol+1)

        elsif q = 6 then  -- bottom right
            fromrow = gmod(qrow+1)
            fromcol = gmod(qcol+1)

        elsif q = 7 then  -- bottom
            fromrow = gmod(qrow+1)
            fromcol = qcol

        else              -- bottom left
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
            enterx = rand(HSIZE-length(oshape[G_JAV][1][1]))
            entery = rand(VSIZE-length(oshape[G_JAV][1])+1)
            entert = G_JAV
            end if
        end if
        end if

        if entert = 0 then
        if galaxy[fromrow][fromcol][G_BAS] then
            entert = G_BAS
        end if
        end if

        if entert then
        shape = oshape[entert][1]

        if entert != G_JAV then
            max_v = VSIZE - length(shape) + 1
            max_h = HSIZE - length(shape[1]) + 1
            if q = 1 then     -- left
            enterx = 1
            entery = rand(max_v)

            elsif q = 2 then  -- top left
            enterx = 1
            entery = 1

            elsif q = 3 then  -- top
            enterx = rand(max_h)
            entery = 1

            elsif q = 4 then  -- top right
            enterx = max_h
            entery = 1

            elsif q = 5 then  -- right
            enterx = max_h
            entery = rand(max_v)

            elsif q = 6 then  -- bottom right
            enterx = max_h
            entery = max_v

            elsif q = 7 then  -- bottom
            enterx = rand(max_h)
            entery = max_v

            else              -- bottom left
            enterx = 1
            entery = max_v

            end if
        end if

        enterc = read_screen(enterx, entery, shape)
        if all_clear(enterc) then
            if add2quadrant(entert, enterx, entery) then
            galaxy[qrow][qcol][entert] += 1
            galaxy[fromrow][fromcol][entert] -= 1
            upg(qrow, qcol)
            upg(fromrow, fromcol)
            if entert = G_JAV then
                Java_enter_sound()
            end if
            fmsg("%s HAS ENTERED QUADRANT", {otype[entert]})
            sched_move_fire()
            end if
        end if
        end if
    end if

    task_yield()
    end while
end procedure

