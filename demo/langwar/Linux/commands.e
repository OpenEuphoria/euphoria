-- commands.e
-- process user commands
include screen.e
include soundeff.e
include display.e
include weapons.e
include damage.e
include std/graphics.e
constant ESC = 27

global natural nchars

natural pen

type keycode(integer x)  
-- a keyboard code
    return x >= -1 and x < 512
end type

keycode curcom

direction Dir

type digit_char(integer x)
    return x >= '0' and x <= '9'
end type

procedure echo(char com)
-- echo first char of new command
    set_bk_color(WHITE)
    set_color(BLUE)
    position(CMD_LINE, CMD_POS)
    puts(CRT, com)
    puts(CRT, "        ")
    position(CMD_LINE, CMD_POS + 2)
end procedure

procedure dircom(digit_char dir)
-- process direction change commands
    nchars = 0
    if reptime[GUIDANCE] then
	errbeep()
	msg("GUIDANCE SYSTEM DAMAGED")
	return
    end if

    if dir = '9' then
	dir = '1'
    elsif dir = '0' then
	dir = '8'
    end if  

    echo(dir)
    curdir = dir - '0'
    dir_box()

    if dir = '1' then
	exi = 3
	eyi = 0
	esym = esymr
    elsif dir = '2' then
	exi = 3
	eyi = -1
	esym = esymr
    elsif dir = '3' then
	exi = 0
	eyi = -1
    elsif dir = '4' then
	exi = -3
	eyi = -1
	esym = esyml
    elsif dir = '5' then
	exi = -3
	eyi = 0
	esym = esyml
    elsif dir = '6' then
	exi = -3
	eyi = 1
	esym = esyml
    elsif dir = '7' then
	exi = 0
	eyi = 1
    elsif dir = '8' then
	exi = 3
	eyi = 1
	esym = esymr
    end if
end procedure

function docom(keycode com, keycode chr)
-- process commands
    natural t
    positive_atom t_stop

    set_bk_color(WHITE)
    set_color(BLUE)
    if com = 'p' then      -- phasor
	if nchars = 0 then
	    echo(chr)
	    set_color(BLUE+BLINKING)
	    puts(CRT, '_')
	    set_color(BLUE)
	    puts(CRT, "00 _._ ")
	    nchars = 1
	elsif nchars = 1 then
	    position(CMD_LINE, CMD_POS+2)
	    pen = 100 * (chr - '0')
	    puts(CRT, chr)
	    position(CMD_LINE, CMD_POS+6)
	    set_color(BLUE+BLINKING)
	    puts(CRT, '_')
	    nchars = 2
	elsif nchars = 2 then
	    position(CMD_LINE, CMD_POS+6)
	    if chr = '0' then
		chr = '8'
	    elsif chr = '9' then
		chr = '1'
	    end if
	    puts(CRT, chr)
	    position(CMD_LINE, CMD_POS+8)
	    set_color(BLUE+BLINKING)
	    puts(CRT, '_')
	    Dir = chr - '0'
	    nchars = 3
	else
	    position(CMD_LINE, CMD_POS+8)
	    puts(CRT, chr)
	    if reptime[PHASORS] then
		errbeep()
		msg("PHASORS DAMAGED")
	    elsif quadrant[EUPHORIA][Q_EN] <= pen then
		errbeep()
		msg("NOT ENOUGH ENERGY")
	    else
		Dir = Dir + (chr - '0')/10
		p_energy(-pen)
		esetpt(Dir)
		weapon(W_PHASOR, pen)
	    end if
	    nchars = 0
	end if

    elsif com = 'w' then    -- warp change
	if nchars = 0 then
	    echo(chr)
	    nchars = 1
	    set_color(BLUE+BLINKING)
	    puts(CRT, '_')
	else
	    if chr < '6' then
		position(CMD_LINE, CMD_POS+2)
		puts(CRT, chr)
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
	    echo(chr)
	    nchars = 1
	    set_color(BLUE+BLINKING)
	    puts(CRT, '_')
	    set_color(BLUE)
	    puts(CRT, "._")
	elsif nchars = 1 then
	    position(CMD_LINE, CMD_POS+2)
	    if chr = '0' then
		chr = '8'
	    elsif chr = '9' then
		chr = '1'
	    end if
	    puts(CRT, chr)
	    position(CMD_LINE, CMD_POS+4)
	    set_color(BLUE+BLINKING)
	    puts(CRT, '_')
	    Dir = chr - '0'
	    nchars = 2
	else
	    position(CMD_LINE, CMD_POS+4)
	    puts(CRT, chr)
	    Dir = Dir + (chr - '0')/10
	    if reptime[TORPEDOS] then
		errbeep()
		msg("TORPEDO LAUNCHER DAMAGED")
	    else
		t = quadrant[EUPHORIA][Q_TORP]
		if t then
		    t = t - 1
		    quadrant[EUPHORIA][Q_TORP] = t
		    ts = ts[2..length(ts)]
		    wtext()
		    esetpt(Dir)
		    weapon(W_TORPEDO, 4000)
		else
		    errbeep()
		    msg("OUT OF TORPEDOS")
		end if
	    end if
	    nchars = 0
	end if

    elsif com = 'g' then    -- galaxy scan
	echo(chr)
	if scanon then
	    setg1()
	else
	    if reptime[GALAXY_SENSORS] then
		errbeep()
		msg("SENSORS DAMAGED")
	    else
		set_bk_color(BLUE)
		set_color(WHITE)
		BlankScreen(FALSE)
		scanon = TRUE
		for r = 1 to G_SIZE do
		    for c = 1 to G_SIZE do
			gquad(r, c)
		    end for
		end for
		gtext()
		gsbox(qrow, qcol)
		set_bk_color(BLACK)
	    end if
	end if
	nchars = 0

    elsif com = 'a' then   -- antimatter pod
	if nchars = 0 then
	    echo(chr)
	    nchars = 1
	    set_color(BLUE+BLINKING)
	    puts(CRT, '_')
	    set_color(BLUE)
	    puts(CRT, "._")
	elsif nchars = 1 then
	    position(CMD_LINE, CMD_POS+2)
	    if chr = '0' then
		chr = '8'
	    elsif chr = '9' then
		chr = '1'
	    end if
	    puts(CRT, chr)
	    position(CMD_LINE, CMD_POS+4)
	    set_color(BLUE+BLINKING)
	    puts(CRT, '_')
	    Dir = chr - '0'
	    nchars = 2
	else
	    position(CMD_LINE, CMD_POS+4)
	    puts(CRT, chr)
	    if length(ps) > 0 then
		set_color(BLUE+BLINKING)
		puts(CRT, " Enter")
		Dir = Dir + (chr - '0')/10
		ps = ps[2..length(ps)]
		wtext()
		esetpt(Dir)
		weapon(W_POD, 1500)
		position(CMD_LINE, CMD_POS+6)
		set_bk_color(WHITE)
		puts(CRT, "     ") 
	    else
		errbeep()
		msg("OUT OF PODS")
	    end if
	    nchars = 0
	end if

    elsif com = '$' then   -- shuttlecraft
	echo(chr)
	if not shuttle then
	    if esym[1] = esymr[1] then
		esym = SHUTTLE_R
	    else
		esym = SHUTTLE_L
	    end if
	    esyml = SHUTTLE_L
	    esymr = SHUTTLE_R
	    otype[G_EU] = "SHUTTLE"
	    write_screen(quadrant[EUPHORIA][Q_X], 
			 quadrant[EUPHORIA][Q_Y], esym)
	    for r = 1 to NSYS do
		if reptime[r] then
		    reptime[r] = 0
		    repair(r)
		end if
	    end for
	    quadrant[EUPHORIA][Q_DEFL] = 1
	    ds = repeat(DEFLECTOR, 1)
	    quadrant[EUPHORIA][Q_TORP] = 0
	    quadrant[EUPHORIA][Q_EN] = 5000
	    ts = ""
	    ps = ""
	    wtext()
	    puts(CRT, "         ")
	    shuttle = TRUE
	    p_energy(0)
	end if

    elsif com = 'x' then   -- cancel
	chr = ' '
	echo(chr)
	nchars = 0

    elsif com = '!' then   -- pause
	echo(chr)
	t_stop = time()
	while get_key() != 'x' do
	end while
	tcb = tcb + time() - t_stop -- adjust all task activation times
	echo(' ')
	nchars = 0

    elsif com = ESC then
	set_color(7)
	set_bk_color(0)
	clear_screen()
	cursor(UNDERLINE_CURSOR)
	abort(0)
	
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

    while TRUE do
	chr = get_key()
	if not char(chr) and chr != ESC then
	    exit
	end if
	if chr >= '0' and chr <= '9' then
	    if nchars then
		x = docom(curcom, chr)
	    else
		dircom(chr)
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

