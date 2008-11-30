-- commands.e
-- process user commands
include std/graphcst.e
include std/os.e
include std/graphics.e

constant ESC = 27

type keycode(integer x)  
-- a keyboard code
    return x >= -1 and x < 512
end type

natural nchars
nchars = 0

natural pen

keycode curcom

direction wdir -- weapons direction

integer dir_adjust

type digit_char(integer x)
    return (x >= '0' and x <= '9')
end type

global procedure quit()
-- end the game and tidy up the screen
    sound(0)
    if graphics_mode(-1) then
    end if
    
    abort(0)
end procedure

procedure echo(char com)
-- echo first char of new command
    set_bk_color(WHITE)
    set_color(BLUE)
    position(CMD_LINE, CMD_POS)
    console_puts(com)
    console_puts("         ")
    position(CMD_LINE, CMD_POS + 2)
end procedure

procedure dircom(digit_char d)
-- process direction change commands
    nchars = 0
    if reptime[GUIDANCE] then
	errbeep()
	msg("GUIDANCE SYSTEM DAMAGED")
	return
    end if

    if d = '9' then
	d = '1'
    elsif d = '0' then
	d = '8'
    end if  

    echo(d)
    curdir = d - '0'
    dir_box()

    if d = '1' then
	exi = 1
	eyi = 0
	esym = esymr
    elsif d = '2' then
	exi = 1
	eyi = -1
	esym = esymr
    elsif d = '3' then
	exi = 0
	eyi = -1
    elsif d = '4' then
	exi = -1
	eyi = -1
	esym = esyml
    elsif d = '5' then
	exi = -1
	eyi = 0
	esym = esyml
    elsif d = '6' then
	exi = -1
	eyi = 1
	esym = esyml
    elsif d = '7' then
	exi = 0
	eyi = 1
    elsif d = '8' then
	exi = 1
	eyi = 1
	esym = esymr
    end if
    check_dock()
end procedure

integer freezes 
freezes = 0

function docom(keycode com, keycode chr)
-- process commands
    natural t

    set_bk_color(WHITE)
    set_color(BLUE)
    if com = 'p' then      -- phasor
	if nchars = 0 then
	    dir_adjust = ' '
	    echo(chr)
	    set_color(BLUE)
	    console_puts('_')
	    set_color(BLUE)
	    console_puts("00 _._ ")
	    nchars = 1
	elsif nchars = 1 then
	    position(CMD_LINE, CMD_POS+2)
	    pen = 100 * (chr - '0')
	    console_puts(chr)
	    position(CMD_LINE, CMD_POS+6)
	    set_color(BLUE)
	    console_puts('_')
	    nchars = 2
	elsif nchars = 2 then
	    if chr = '<' or chr = '>' then
		dir_adjust = chr
		position(CMD_LINE, CMD_POS+5)
		console_puts(chr)
	    else
		position(CMD_LINE, CMD_POS+6)
		if chr = '0' then
		    chr = '8'
		elsif chr = '9' then
		    chr = '1'
		end if
		console_puts(chr)
		position(CMD_LINE, CMD_POS+8)
		set_color(BLUE)
		console_puts('_')
		wdir = chr - '0'
		nchars = 3
	    end if
	else
	    -- nchars is 3 or 4
	    if (chr = '<' or chr = '>') then
		if nchars = 3 then
		    dir_adjust = chr
		    position(CMD_LINE, CMD_POS+8)
		    console_puts(chr)
		    nchars += 1
		end if
	    else
		position(CMD_LINE, CMD_POS+5+nchars)
		console_puts(chr)
		if reptime[PHASORS] then
		    errbeep()
		    msg("PHASORS DAMAGED")
		elsif quadrant[EUPHORIA][Q_EN] <= pen then
		    errbeep()
		    msg("NOT ENOUGH ENERGY")
		else
		    wdir += (chr - '0')/10
		    p_energy(-pen)
		    esetpt(wdir, dir_adjust)
		    phasor(EUPHORIA, pen)
		end if
		nchars = 0
	    end if
	end if

    elsif com = 'w' then    -- warp change
	if nchars = 0 then
	    echo(chr)
	    nchars = 1
	    set_color(BLUE)
	    console_puts('_')
	else
	    if chr < '6' then
		position(CMD_LINE, CMD_POS+2)
		console_puts(chr)
		nchars = 0
		if wlimit then
		    setwarp(chr - '0')
		else
		    errbeep()
		    msg("ALL ENGINES DAMAGED")
		end if
	    end if
	end if

    elsif com = 't' then    -- torpedo
	if nchars = 0 then
	    dir_adjust = ' '
	    echo(chr)
	    nchars = 1
	    set_color(BLUE)
	    console_puts('_')
	    set_color(BLUE)
	    console_puts("._")
	elsif nchars = 1 then
	    if chr = '<' or chr = '>' then
		dir_adjust = chr
		position(CMD_LINE, CMD_POS+1)
		console_puts(chr)
	    else
		position(CMD_LINE, CMD_POS+2)
		if chr = '0' then
		    chr = '8'
		elsif chr = '9' then
		    chr = '1'
		end if
		console_puts(chr)
		position(CMD_LINE, CMD_POS+4)
		set_color(BLUE)
		console_puts('_')
		wdir = chr - '0'
		nchars = 2
	    end if
	else
	    -- nchars is 2 or 3
	    if (chr = '<' or chr = '>') then
		if nchars = 2 then
		    dir_adjust = chr
		    position(CMD_LINE, CMD_POS+4)
		    console_puts(chr)
		    nchars += 1
		end if
	    else
		position(CMD_LINE, CMD_POS+2+nchars)
		console_puts(chr)
		wdir += (chr - '0')/10
		if reptime[TORPEDOS] then
		    errbeep()
		    msg("TORPEDO LAUNCHER DAMAGED")
		else
		    t = quadrant[EUPHORIA][Q_TORP]
		    if t then
			t -= 1
			quadrant[EUPHORIA][Q_TORP] = t
			ts = ts[2..$]
			wtext()
			esetpt(wdir, dir_adjust)
			torpedo(EUPHORIA)
		    else
			errbeep()
			msg("OUT OF TORPEDOS")
		    end if
		end if
		nchars = 0
	    end if
	end if

    elsif com = 'g' then    -- galaxy scan
	echo(chr)
	if scanon then
	    end_scan()
	else
	    if reptime[GALAXY_SENSORS] then
		errbeep()
		msg("SENSORS DAMAGED")
	    else
		BlueScreen()
		scanon = TRUE
		refresh_scan()
		gtext()
		gsbox(qrow, qcol)
		task_schedule(t_gquad, {0.35, 0.40})
	    end if
	end if
	nchars = 0

    elsif com = 13 then
	EnterPressed = TRUE
	
    elsif com = 'a' then   -- antimatter pod
	if nchars = 0 then
	    dir_adjust = ' '
	    echo(chr)
	    nchars = 1
	    set_color(BLUE)
	    console_puts('_')
	    set_color(BLUE)
	    console_puts("._")
	elsif nchars = 1 then
	    if chr = '<' or chr = '>' then
		dir_adjust = chr
		position(CMD_LINE, CMD_POS+1)
		console_puts(chr)
	    else
		position(CMD_LINE, CMD_POS+2)
		if chr = '0' then
		    chr = '8'
		elsif chr = '9' then
		    chr = '1'
		end if
		console_puts(chr)
		position(CMD_LINE, CMD_POS+4)
		set_color(BLUE)
		console_puts('_')
		wdir = chr - '0'
		nchars = 2
	    end if
	else
	    -- nchars is 2 or 3
	    if (chr = '<' or chr = '>') then
		if nchars = 2 then
		    dir_adjust = chr
		    position(CMD_LINE, CMD_POS+4)
		    console_puts(chr)
		    nchars += 1
		end if
	    else
		position(CMD_LINE, CMD_POS+2+nchars)
		console_puts(chr)
		if length(ps) > 0 then
		    wdir += (chr - '0')/10
		    ps = ps[2..$]
		    wtext()
		    esetpt(wdir, dir_adjust)
		    EnterPressed = FALSE
		    pod()
		else
		    errbeep()
		    msg("OUT OF PODS")
		end if
		nchars = 0
	    end if
	end if

    elsif com = 's' then   -- shuttlecraft
	echo(chr)
	if not shuttle then
	    if equal(esym[1], esymr[1]) then
		esym = SHUTTLE_R
	    else
		esym = SHUTTLE_L
	    end if
	    esyml = SHUTTLE_L
	    esymr = SHUTTLE_R
	    otype[G_EU] = "SHUTTLE"
	    oshape[G_EU] = {SHUTTLE_L, SHUTTLE_R}
	    write_screen(quadrant[EUPHORIA][Q_X], 
			 quadrant[EUPHORIA][Q_Y], quadrant[EUPHORIA][Q_UNDER])
	    quadrant[EUPHORIA][Q_UNDER] = read_screen(quadrant[EUPHORIA][Q_X],
						      quadrant[EUPHORIA][Q_Y],
						      esym)
	    write_screen(quadrant[EUPHORIA][Q_X], 
			 quadrant[EUPHORIA][Q_Y], esym)
	    for r = 1 to NSYS do
		if reptime[r] then
		    reptime[r] = 0
		    repair(r)
		end if
	    end for
	    quadrant[EUPHORIA][Q_DEFL] = 1
	    ds = "d"
	    quadrant[EUPHORIA][Q_TORP] = 0
	    quadrant[EUPHORIA][Q_EN] = 5000
	    ts = ""
	    ps = ""
	    wtext()
	    shuttle = TRUE
	    p_energy(0)
	end if

    elsif com = 'c' or com = BS then   -- cancel
	chr = ' '
	echo(chr)
	nchars = 0

    elsif com = 'f' then   -- freeze the game (pause until cancelled)
	freezes += 1
	if freezes > 3 then
	    errbeep()
	    msg("NO MORE TIME-OUTS ALLOWED!")
	else
	    echo(chr)
	    task_clock_stop()
	    while not find(get_key() , {'c', BS, ESC}) do
	    end while
	    task_clock_start()
	    echo(' ')
	    nchars = 0
	end if

    elsif com = ESC then
	stop_game()
	if video_file != -1 then
	    close(video_file)
	end if
	quit()
	
    else
	return FALSE

    end if

    return TRUE
end function

global procedure task_keyb()
-- independent task: check the keyboard for command input
    boolean x
    natural tempchars
    keycode chr

    while not gameover do
	chr = get_key()
	if not char(chr) then
	    task_yield()
	elsif (chr >= '0' and chr <= '9') or chr = '<' or chr = '>' then
	    if nchars then
		x = docom(curcom, chr)
	    else
		if chr >= '0' and chr <= '9' then
		    dircom(chr)
		end if
	    end if
	else
	    tempchars = nchars
	    nchars = 0
	    if docom(chr, chr) then
		curcom = chr
	    else
		nchars = tempchars
	    end if
	end if
    end while
end procedure

