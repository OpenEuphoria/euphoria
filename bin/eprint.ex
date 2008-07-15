		------------------------------------
		-- Print a Euphoria program       --
		-- (doesn't work yet under Linux) --
		------------------------------------

-- This works with HP PCL printers.
-- You can change control codes (bold, italics etc) for other printers.
-- If you have a color printer you can choose colors,
-- otherwise you will simply get keywords in bold, comments in italics.
-- You can print non-Euphoria files too.

-- usage: eprint filename
--   You will be asked if you want to print in color, 
--   and if you want to print in condensed mode.

include std/wildcard.e

constant TRUE = 1, FALSE = 0
constant KEYB = 0, DISPLAY = 1, ERROR = 2
constant M_GET_POSITION   = 25

integer syntax, color_printer
syntax = TRUE                -- to highlight syntax in .e/.ex/.pro files

constant ESC = 27

constant hp550c = {"2", "8", "1", "12", "4", "10", "1", "1"}

integer printer

procedure bold_on()
    puts(printer, ESC & "(s3B")
end procedure

procedure bold_off()
    puts(printer, ESC & "(s0B")
end procedure

procedure italics_on()
    puts(printer, ESC & "(s1S")
end procedure

procedure italics_off()
    puts(printer, ESC & "(s0S")
end procedure

procedure second_column()
    puts(printer, ESC & "&a80C")
end procedure

procedure form_feed()
    puts(printer, 12)
end procedure

procedure reset()
    puts(printer, ESC & 'E')   -- reset
end procedure

procedure colorMode()
    puts(printer, ESC & "*r-4U")  -- CYMK
end procedure

procedure small()
    puts(printer, ESC & "(s20H")    -- Print Pitch (width)
    puts(printer, ESC & "(s8V")     -- Point Size (height)
    puts(printer, ESC & "&l4C")     -- vertical motion
end procedure

-- symbols needed by syncolor.e:
global constant  NORMAL_COLOR = 8,
		COMMENT_COLOR = 4,
		KEYWORD_COLOR = 1,
		BUILTIN_COLOR = 5,
		 STRING_COLOR = 6,
		BRACKET_COLOR = {NORMAL_COLOR}

include euphoria/syncolor.e

procedure set_printer_color(integer color)
-- set the printer color (or mono effect)
    sequence color_code

    if not syntax then
	return
    end if

    if color_printer then
	color_code = hp550c[color]
	puts(printer, ESC & "*v" & color_code & "S")
    else
	-- normal mono printer
	if color = KEYWORD_COLOR then
	    italics_off()
	    bold_on()
	elsif color = COMMENT_COLOR then
	    bold_off()
	    italics_on()
	else
	    italics_off()
	    bold_off()
	end if
    end if
end procedure

procedure DisplayColorLine(sequence line)
-- display one line of text on the printer
    sequence color_line
    
    color_line = SyntaxColor(line)
    for i = 1 to length(color_line) do
	set_printer_color(color_line[i][1])
	puts(printer, color_line[i][2])     
    end for
end procedure

procedure try_colors()
-- utility routine to display colors on hp550c
    for i = '0' to '6' do
	for j = '0' to '9' do
	    puts(printer, ESC & "*v" & i & j & "S")
	    printf(printer, "%s:", {i&j})
	    puts(printer, "Testing Colors ...\n")
	end for
    end for
end procedure

function get_position()
-- return {line, column} of current cursor position
    return machine_func(M_GET_POSITION, 0)
end function

function get_response(sequence query, integer letterToSearch)
    integer matchOrNot
    sequence pos
    
    puts(DISPLAY, query)
    pos = get_position()
    position(pos[1], pos[2] - 2)
    matchOrNot = find(letterToSearch, lower(gets(KEYB)))
    puts(DISPLAY, '\n')
    return matchOrNot
end function

procedure eprint()
    integer  efile
    sequence command, matchname
    object   line
    sequence buffer
    integer  base_line, condensed, nColumns, page_length

    command = command_line()
    if length(command) != 3 then
	puts(ERROR, "usage: eprint filename\n")
	return
    end if
    efile = open(command[3], "r")
    if efile = -1 then
	puts(ERROR, "couldn't open " & command[3] & '\n')
	return
    end if
    matchname = command[3] & '&'
    if not match(".e&", matchname) and
       not match(".ex&", matchname) and
       not match(".pro&", matchname) then
	syntax = FALSE
    end if
    printer = open("PRN", "w")
    if printer = -1 then
	puts(ERROR, "Can't open printer\n")
	return
    end if
    init_class()
    reset()
    
    if syntax then
	color_printer = get_response("print in color? (n)", 'y')
	if color_printer then
	    colorMode()
	end if
    else
	color_printer = FALSE
    end if
    
    condensed = not get_response("condensed print? (y)", 'n')
    if condensed then
	nColumns = 2
	small()
    else
	nColumns = 1
    end if
    page_length = 59 * nColumns    -- (upper bound) 118 for condensed

    -- read in whole file
    buffer = {}
    while TRUE do
	line = gets(efile)
	if atom(line) then
	    exit
	end if
	if line[length(line)] != '\n' then
	    line &= '\n' -- need end marker
	end if
	buffer = append(buffer, line)
    end while
    base_line = 1
    while base_line <= length(buffer) do
	for i = base_line to base_line + page_length - 1 do
	    if i <= length(buffer) then
		DisplayColorLine(buffer[i])
		if nColumns = 2 and i + page_length <= length(buffer) then
		    second_column()
		    DisplayColorLine(buffer[i + page_length])
		end if
		puts(printer, '\n')
	    end if
	end for
	base_line += page_length * nColumns
	form_feed()
    end while
    close(efile)
    reset()
    close(printer)
end procedure

eprint()

