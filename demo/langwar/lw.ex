               ------------------
               -- Language War --
               ------------------
-- Run with:  ex lw
-- in pure DOS, or a full-screen DOS window. (press Alt+Enter)

-- See lw.doc for a complete description of how to play.
-- See lw.sum for a brief summary of the commands that you can print.

-- This is based on a space war game developed in 1979 for the TRS-80 by
-- David A. Craig with assistance from Robert H. Craig.

-- Language War uses graphics mode 18 and PC speaker sound effects.
-- Standard Euphoria routines, such as pixel(), display_image() etc. are used.
-- There are no calls to low-level routines such as peek(), poke(), or
-- mem_copy(). See the Euphoria Web site for examples of really fast graphics.

-- Language War is organized as a loose collection of independent "tasks"
-- that run in "parallel" with each other. The Euphoria multitasking scheduler
-- decides which task to run next. This cooperative, non-preemptive
-- tasking approach could be applied to other kinds of programs as well.

include std/error.e
include std/console.e
include std/os.e
include std/dos/image.e
include std/image.e
include std/graphics.e
include std/get.e
include vars.e
include screen.e
include putsxy.e
include pictures.e
include soundeff.e
include display.e
include damage.e
include weapons.e
include commands.e
include emove.e
include enemy.e

without type_check -- makes it a bit faster

type file_number(integer x)
    return x >= -1
end type

file_number sum_no
object line


if graphics_mode(18) then
    puts(1, "you need mode 18\n")
    abort(0)
end if

text_color(7)


set_bk_color(BLUE)
bk_color(BLUE)
set_color(WHITE)
clear_screen()

-- display summary file
sum_no = open("lw.sum", "r")
if sum_no != -1 then
    for i = 2 to 26 do
    line = gets(sum_no)
    if atom(line) then
        exit
    end if
    line = line[1..$-1]
    position(i, 1)
    console_puts(line)
    end for
    close(sum_no)
end if

type valid_routine_id(integer id)
    return id >= 0 and id <= 1000
end type


type energy_source(integer x)
    return x = G_PL or x = G_BS
end type

procedure setpb(pb_row row, energy_source stype)
-- initialize a planet or a base

    g_index r, c, ri, ci
    h_coord x, xi
    v_coord y, yi
    boolean unique
    natural e_height, e_width

    -- choose a quadrant
    pb[row][P_TYPE] = stype
    r = rand(G_SIZE)
    c = rand(G_SIZE)
    pb[row][P_QR] = r
    pb[row][P_QC] = c

    pb[row][P_EN] = (rand(250) + rand(250)) * 70 + 60000
    galaxy[r][c][stype] += 1
    e_height = length(EUPHORIA_L)
    e_width  = length(EUPHORIA_L[1])
    -- choose a position in the quadrant

    if atom(PLANET) then
        if graphics_mode(-1) then end if
        puts(2, "BAD PLANET\n")
        abort(0)
    end if

    while TRUE do
    if stype = G_PL then
        x = e_width  + rand(HSIZE - length(PLANET[1]) - 2*e_width)
        y = e_height + rand(VSIZE - length(PLANET)    - 2*e_height)
    else
        x = e_width  + rand(HSIZE - length(BASE[1]) - 2*e_width)
        y = e_height + rand(VSIZE - length(BASE)    - 2*e_height)
        pb[row][P_POD] = 1
        pb[row][P_TORP] = rand(14) + 16
    end if
    pb[row][P_X] = x
    pb[row][P_Y] = y

    -- make sure position doesn't overlap another planet or base
    unique = TRUE
    for i = 1 to row - 1 do
        ri = pb[i][P_QR]
        ci = pb[i][P_QC]
        if r = ri and c = ci then
        -- in the same quadrant
        xi = pb[i][P_X]
        -- allow enough room for a planet - bigger than a base
        if x >= xi - length(PLANET[1]) and
           x <= xi + length(PLANET[1]) then
            yi = pb[i][P_Y]
            if y >= yi-length(PLANET) and y <= yi+length(PLANET) then
            unique = FALSE
            exit
            end if
        end if
        end if
    end for
    if unique then
        exit
    end if
    end while

end procedure

procedure init()
-- initialize
    g_index r, c
    wrap(0)

    -- objects in the Galaxy (facing left and right):

    oshape = {{EUPHORIA_L, EUPHORIA_R},  -- Euphoria
          {KRC_L,       KRC_R},      -- K&R C
          {ANC_L,       ANC_R},      -- ANSI C
          {CPP_L,       CPP_R},      -- C++
          {BASIC_L,     BASIC_R},    -- BASIC
          {JAVA_L,      JAVA_R},     -- Java
          {PLANET,      PLANET},     -- Planet
          {BASE,        BASE}}       -- Base

    otype = {"EUPHORIA",
         "C",
         "ANSI C",
         "C++",
         "BASIC",
         "Java",
         "PLANET",
         "BASE"}

    -- set number of objects in the galaxy
    nobj = {1,  -- Euphoria (must be 1)
       40,  -- regular K&R C ships
        9,  -- ANSI C ships
        1,  -- C++
       50,  -- BASIC ships
       20,  -- Java ships
       NPLANETS,  -- planets
       NBASES}    -- bases

    -- create the standard, initially-active tasks
    t_emove = task_create(routine_id("task_emove"), {})
    t_keyb  = task_create(routine_id("task_keyb"), {})
    t_life  = task_create(routine_id("task_life"), {})
    t_bstat = task_create(routine_id("task_bstat"), {})
    t_enter = task_create(routine_id("task_enter"), {})

    -- initially inactive tasks:
    t_fire  = task_create(routine_id("task_fire"), {})
    t_move  = task_create(routine_id("task_move"), {})
    t_docking = task_create(routine_id("task_docking"), {})
    t_message = task_create(routine_id("task_message"), {})
    t_sound_effect = task_create(routine_id("task_sound_effect"), {})
    t_dead  = task_create(routine_id("task_dead"), {})
    t_damage_report = task_create(routine_id("task_damage_report"), {})
    t_gquad = task_create(routine_id("task_gquad"), {})
    scanon = FALSE
    -- start moving at warp 4
    task_schedule(t_emove, warp_time[1+4])
    task_schedule(t_keyb, {0.04, 0.15})
    task_schedule(t_life, {1.7, 1.8})
    task_schedule(t_bstat, {150, 150 + rand(150)})
    task_schedule(t_enter, {15, 15+rand(15)})

    if video_file != -1 then
    t_video_snapshot = task_create(routine_id("task_video_snapshot"), {})
    task_schedule(t_video_snapshot, {.9*frame_rate, frame_rate})
    t_video_save = task_create(routine_id("task_video_save"), {})
    task_schedule(t_video_save, 1)  -- time shared
    end if

    -- blank lower portion

    set_bk_color(WHITE)
    for i = WARP_LINE to WARP_LINE + 2 do
    position(i, 1)

    console_puts(BLANK_LINE)
    end for

    quadrant[EUPHORIA][Q_TYPE] = G_EU
    quadrant[EUPHORIA][Q_DEFL] = 3
    ds = repeat(DEFL_SYM, 3)
    quadrant[EUPHORIA][Q_TORP] = 10
    ts = repeat(TORP_SYM, 10)
    ps = repeat(POD_SYM, 1)

    quadrant[EUPHORIA][Q_EN] = 50000

    wlimit = 5
    curwarp = 4
    curdir = 1
    exi = 1
    eyi = 0
    truce_broken = FALSE
    qrow = 1
    qcol = 1

    stext()

    -- initialize galaxy sequence
    galaxy = repeat(repeat(repeat(0, NTYPES), G_SIZE), G_SIZE)
    for i = G_KRC to G_JAV do
    for j = 1 to nobj[i] do
        r = rand(G_SIZE)
        c = rand(G_SIZE)
        galaxy[r][c][i] += 1
    end for
    end for

    -- initialize planet/base sequence

    for i = 1 to nobj[G_BS] do
    setpb(i, G_BS)
    end for

    for i = nobj[G_BS]+1 to PROWS do
    setpb(i, G_PL)
    end for

    esymr = EUPHORIA_R
    esyml = EUPHORIA_L
    esym = EUPHORIA_R
    quadrant[EUPHORIA][Q_X] = HSIZE - length(esym[1]) + 1
    quadrant[EUPHORIA][Q_Y] = floor(VSIZE/2) - length(esym) + 1
    quadrant[EUPHORIA][Q_UNDER] = 0 * esym
    qrow = pb[1][P_QR]

    qcol = gmod(pb[1][P_QC] - 1)
    bstat = TRUCE
    reptime[1..NSYS] = 0
    ndmg = 0
    shuttle = FALSE
    set_bk_color(BLACK)
    bk_color(BLACK)
    set_color(WHITE)
    BlackScreen()  -- blank upper portion
    normal_palette = get_all_palette()
end procedure

procedure trek()
-- Language War Main Routine
    natural nk
    sequence new_name
    integer fn

    init()

    gameover = FALSE

    task_suspend(task_self())
    task_yield() -- the other tasks can now start, wait here until end of game

    nk = c_remaining()

    position(WARP_LINE+1, ENERGY_POS)
    if level = 'e' then
    console_puts("expert")
    else
    console_puts("novice")
    end if
    console_puts(" level")

    if nk = 0 then
    victory_sound()
    for i = 1 to 13 do
        set_color(RED)
        if remainder(i,2) then
        display_msg("PROGRAMMERS THROUGHOUT THE GALAXY ARE EUPHORIC!!!!!")
        else
        display_msg("                                                   ")
        end if
        task_yield()
    end for
    else
    display_msg(sprintf(
        "%d C SHIPS REMAIN. YOU ARE DEAD. C RULES THE GALAXY!", nk))
    end if

    if video_file != -1 then
    task_schedule(task_self(), {3, 4})
    task_yield() -- gives task_video_snapshot time to get last picture,
             -- and task_video_save some time to catch up if required
    recording = FALSE -- stop taking snapshots
    end if

    set_color(BLUE)
    set_bk_color(WHITE)

    -- make sure he sees his failure (or victory)
    while get_key() != -1 do
    -- clear any queued keystrokes
    end while
    while get_key() = -1 do
    task_yield() -- more video_save time
    end while

    if video_file != -1 then
    close(video_file)
    if nk = 0 then
        -- rename winning game
        for i = 1 to 99 do
        new_name = sprintf("win%d.vid", i)
        fn = open(new_name, "r")
        if fn = -1 then
            system("rename lastgame.vid " & new_name, 2)
            exit
        else
            close(fn)
        end if
        end for
    end if
    end if

    quit()
end procedure

function ask_player( sequence screen_location, sequence question_text, sequence true_chars, integer false_char)
    integer resp
    sequence full_text

    position(screen_location[1], screen_location[2])

    full_text = sprintf("%s? (%s or %s): _", {question_text, true_chars[1], false_char})
    console_puts(full_text)

    resp = wait_key()

    position(screen_location[1], screen_location[2] + length(full_text) - 1)
    if find(resp, true_chars) then
        resp = true_chars[1]
    else
        resp = false_char
    end if
    console_puts(resp)

    return resp
end function

procedure pause_msg( sequence screen_location, sequence msg_text, integer wait = TRUE)
    integer resp

    position(screen_location[1], screen_location[2])

    console_puts(msg_text)

    if wait then
        resp = wait_key()
    end if

end procedure

tick_rate(TICK_RATE) -- this helps with tasking by improving the time resolution

set_color(YELLOW)

pause_msg( {26,5}, "Language Wars v4.0", FALSE)

level = ask_player({27,5}, "novice or expert level", "nN", 'e')

if ask_player({28,5}, "record a video of the game", "nN", 'y') =  'n' then
    video_file = -1
else
    video_file = open("lastgame.vid", "wb")
end if

set_sound( ask_player({29,5}, "turn sound off", "yY", 'n') = 'y')

pause_msg( {30,5}, "Take a deep breath, then press any key when ready to start ...")

trek()


