-- (c) Copyright 2007 Rapid Deployment Software - See License.txt
--
-- Euphoria 3.1
-- Front End - main routine 

include file.e
include get.e
include pathopen.e
include error.e
include parser.e
include mode.e

function ProcessOptions()
-- record command line options, return source file number
    integer src_file
    boolean dot_found
    sequence src_name, raw_name, exts
    
    if Argc >= 3 then
	src_name = Argv[3]
    else 
	if INTERPRET and not BIND then
	    screen_output(STDERR, "Euphoria Interpreter " & 
				  INTERPRETER_VERSION & " ")
       
	elsif TRANSLATE then
	    screen_output(STDERR, "Euphoria to C Translator " & 
				  TRANSLATOR_VERSION & " ")
	elsif BIND then
	    screen_output(STDERR, "Euphoria Binder " & 
				  INTERPRETER_VERSION & " ")
	end if

	if ELINUX then
	    if BIND then
		screen_output(STDERR, "for Linux/FreeBSD.\n")
	    else    
		if EBSD then
		    screen_output(STDERR, "for FreeBSD.\n")
		else
		    screen_output(STDERR, "for Linux.\n")
		end if
	    end if
	    
	else
	    if BIND then
		screen_output(STDERR, "for DOS/Windows.\n")
	    elsif EWINDOWS then
		screen_output(STDERR, "for 32-bit Windows.\n")
	    else
		screen_output(STDERR, "for 32-bit DOS.\n")
	    end if
	end if

	screen_output(STDERR, "Copyright (c) Rapid Deployment Software 2007 \n")

	screen_output(STDERR, 
	    "See http://www.RapidEuphoria.com/License.txt \n")

	if BIND then
	    screen_output(STDERR, "\nfile name to bind/shroud? ")
	
	elsif INTERPRET then
	    screen_output(STDERR, "\nfile name to execute? ")

	elsif TRANSLATE then
	    screen_output(STDERR, "\nfile name to translate to C? ")
	
	end if

	src_name = gets(STDIN)
	
	screen_output(STDERR, "\n")
    
	-- remove leading blanks
	while length(src_name) and find(src_name[1], " \t\n") do
	    src_name = src_name[2..$]
	end while
	
	if length(src_name) = 0 then
	    Cleanup(1)
	end if
	
	-- remove trailing blanks
	while length(src_name) and find(src_name[$], " \t\n") do
	    src_name = src_name[1..$-1]
	end while
	
	-- add src_name as 2nd arg for command_line()
	Argc = 2
	Argv = {Argv[1], src_name}
	
	file_name_entered = src_name -- passed to back-end for command_line()
	
	-- .ex or .exw might be added to src_name below
    end if
    
    -- check src_name for '.' */
    dot_found = FALSE
    for p = 1 to length(src_name) do
	if src_name[p] = '.' then
	   dot_found = TRUE
	elsif find(src_name[p], SLASH_CHARS) then
	   dot_found = FALSE
	end if
    end for 
    
    raw_name = src_name
    
    if not dot_found then
	-- no dot found */
	if ELINUX then
	    exts = { ".exu", ".exw", ".ex", "" }
	
	elsif BIND then
	    if w32 then
		exts = { ".exw", ".ex", ".exu" }
	    else
		exts = { ".ex", ".exw", ".exu" }
	    end if
	
	else    
	    if EWINDOWS then
		exts = { ".exw", ".ex", ".exu" }
	    else
		exts = { ".ex", ".exw", ".exu" }
	    end if
	end if
	file_name = append(file_name, src_name)
	for i = 1 to length( exts ) do
	    file_name[$] = src_name & exts[i]
	    src_file = e_path_open(src_name & exts[i], "r")
	    if src_file != -1 then
		src_name &= exts[i]
		exit
	    end if
	end for
	if src_file = -1 then
	    file_name[$] = src_name & exts[1]	
	end if
	else
	file_name = append(file_name, src_name)
	src_file = e_path_open(src_name, "r")
    end if
  
    return src_file
end function

function full_path(sequence filename)
-- return the full path for a file
    integer p
    p = length(filename)
    while p >= 1 do
	if find(filename[p], SLASH_CHARS) then
	    return filename[1..p]
	end if
	p -= 1
    end while
    return '.' & SLASH  
end function

procedure main()
-- Main routine 
    integer argc
    sequence argv
    
    -- we have our own, possibly different, idea of argc and argv
    argv = command_line()

    if BIND then
	argv = extract_options(argv)
    end if

    argc = length(argv)  

    Argv = argv
    Argc = argc
    
    eudir = getenv("EUDIR")
    if atom(eudir) then
	if ELINUX then
	    -- should check search PATH for euphoria/bin ?
	    eudir = getenv("HOME")
	    if atom(eudir) then
		eudir = "euphoria"  
	    else 
		eudir = eudir & "/euphoria"
	    end if
	else
	    eudir = "\\EUPHORIA"
	end if

    else
	-- This is a special RDS hack because the RapidEuphoria shared 
	-- host machine does not provide enough memory to complete a
	-- normal build.
	mybsd = match("/usr231/home/r/h/rhc", eudir) > 0 --RapidEuphoria.com

    end if
    TempErrName = "ex.err"           

    if TRANSLATE then
	InitBackEnd(0)
    end if
    
    src_file = ProcessOptions()

    if src_file = -1 then
	-- too early for normal error processing
	screen_output(STDERR, sprintf("Can't open %s\n", {file_name[1]}))
	if BIND or EWINDOWS or ELINUX then
	    screen_output(STDERR, "\nPress Enter\n")
	    if getc(0) then
	    end if
	end if
	Cleanup(1)
    end if
    
    main_path = full_path(file_name[1])  

    if TRANSLATE then
	InitBackEnd(1)
    end if

    InitGlobals()

    InitSymTab()
    InitEmit()
    InitParser()
    InitLex()
    read_line()
    parser()

    -- we've parsed successfully
    -- now run the appropriate back-end 
    if TRANSLATE then
	BackEnd(0) -- translate IL to C
    
    elsif BIND then
	OutputIL()
    
    elsif INTERPRET then
	InitBackEnd(0)
	BackEnd(0) -- execute IL using Euphoria-coded back-end
    end if

    Cleanup(0) -- does warnings
end procedure

main()

