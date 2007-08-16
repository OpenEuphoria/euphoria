-- (c) Copyright 2007 Rapid Deployment Software - See License.txt
--
-- Translator initialization
include get.e

global boolean wat_option, djg_option, bor_option, lcc_option
wat_option = FALSE
djg_option = FALSE
bor_option = FALSE
lcc_option = FALSE 

global function extract_options(sequence s)
-- dummy    
    return s
end function

function upper(sequence s)
    return and_bits(s,#DF)
end function

global procedure transoptions()
-- set translator command-line options  
    integer i
    sequence uparg
    object s
    
    -- put file first, strip out the options
    i = 1
    while i <= Argc do
	if Argv[i][1] = '-' then
	    uparg = upper(Argv[i])
		
	    if ELINUX and 
	    (match("-DLL", uparg) or
	    match("-SO", uparg)) then
		dll_option = TRUE
		
	    elsif EWINDOWS and match("-DLL", uparg) then
		dll_option = TRUE
		    
	    elsif EWINDOWS and match("-CON", uparg) then
		con_option = TRUE
		
	    elsif (EWINDOWS or EDOS) and match("-WAT", uparg) then
		wat_option = TRUE
		
	    elsif match("-KEEP", uparg) then
		keep = TRUE
		
	    elsif EDOS and match("-DJG", uparg) then
		djg_option = TRUE
		
	    elsif EDOS and match("-FASTFP", uparg) then
		fastfp = TRUE
		
	    elsif EWINDOWS and match("-LCC", uparg) then
		lcc_option = TRUE
		
	    elsif EWINDOWS and match("-BOR", uparg) then
		bor_option = TRUE
		
	    elsif match("-STACK", uparg) then
		if i < Argc then
		    s = value(Argv[i+1])
		    if s[1] = GET_SUCCESS then
			if s[2] >= 16384 then
			    total_stack_size = floor(s[2] / 4) * 4
			end if
		    end if
		    Argc -= 1
		    for j = i to Argc do
			Argv[j] = Argv[j+1]
		    end for
		end if
	    else
		OpWarning = TRUE
		Warning("unknown option: " & Argv[i])
	    end if
	    -- delete "-" option from the list of args */
	    Argc -= 1
	    for j = i to Argc do
		Argv[j] = Argv[j+1]
	    end for
	else 
	    i += 1 -- ignore non "-" items
	end if      
    end while
end procedure
    
function get_bor_path()
-- return the path to the Borland C++ files, e.g. c:\borland\bcc55 
    object p
    integer b, c
    sequence path
    
    p = getenv("PATH")
    if atom(p) then
	return 0
    end if
    
    path = upper(p)
    
    for i = 1 to length(path) do
	if path[i] = '/' then
	    path[i] = '\\'
	end if
    end for
    
    b = match("BORLAND\\BCC", path)
    if b = 0 then
	b = match("\\BCC", path)
	if b = 0 then
	    b = match("BORLAND\\", path)
	    if b = 0 then
		return 0
	    else 
		c = b+length("BORLAND\\")
	    end if
	else 
	    c = b+length("\\BCC")
	end if
    else 
	c = b+length("BORLAND\\BCC")
    end if
    
    -- move forward to backslash
    while c <= length(path) and not find(path[c], SLASH_CHARS) do
	c += 1
    end while
    path = path[1..c-1]
    
    -- move backward to ; or start
    while b and path[b] != ';' do
	b -= 1
    end while
    if b and path[b] = ';' then
	b += 1
    end if
    
    return path[b..$]
end function
--END PRIVATE

procedure OpenCFiles()
-- open and initialize translator output files
    c_code = open("init-.c", "w")
    if c_code = -1 then
	CompileErr("Can't open init-.c for output\n")
    end if
    
    emit_c_output = TRUE

    c_puts("#include \"")
    c_puts(eudir)
    c_puts(SLASH & "include" & SLASH & "euphoria.h\"\n")
    c_puts("#include \"main-.h\"\n\n")
    
    c_h = open("main-.h", "w")
    if c_h = -1 then
	CompileErr("Can't open main-.h file for output\n")
    end if
end procedure

global procedure InitBackEnd(integer c)
-- Initialize special stuff for the translator
    
    if c = 1 then
	OpenCFiles()
	return
    end if
    
    init_opcodes()
    
    transoptions()
    
    if EDOS then
	wat_path = 0
	dj_path = getenv("DJGPP")
	if atom(dj_path) or wat_option then
	    wat_path = getenv("WATCOM")
	    if atom(wat_path) then
		wat_path = "C:\\WATCOM"
	    end if
	    dj_path = 0
	end if
	if djg_option and atom(dj_path) then
	    CompileErr("DJGPP environment variable is not set")
	end if
	if wat_option and atom(wat_path) then
	    CompileErr("WATCOM environment variable is not set")
	end if
    end if

    if EWINDOWS then
	bor_path = 0
	wat_path = 0
	if not lcc_option then
	    if not bor_option then
		wat_path = getenv("WATCOM")
	    end if
	    bor_path = get_bor_path()
	    if sequence(wat_path) then
		bor_path = 0
	    end if
	    if sequence(bor_path) then
		wat_path = 0
	    end if
	end if
    
	if bor_option and atom(bor_path) then
	    CompileErr("Can't find Borland installation directory")
	end if
	if wat_option and atom(wat_path) then
	    CompileErr("WATCOM environment variable is not set")
	end if
    end if
end procedure


