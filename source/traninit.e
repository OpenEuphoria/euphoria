-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--

include std/os.e
include std/filesys.e

-- Translator initialization
include std/get.e
include common.e
include global.e
include mode.e as mode
include c_out.e
include c_decl.e
include std/error.e
include compile.e
include cominit.e
include tranplat.e

global boolean wat_option, djg_option, bor_option, lcc_option
wat_option = FALSE
djg_option = FALSE
bor_option = FALSE
lcc_option = FALSE 

sequence compile_dir
compile_dir = ""

function extract_options(sequence s)
-- dummy    
	return s
end function
set_extract_options( routine_id("extract_options") )

function upper(sequence s)
	for i=1 to length(s) do
		if s[i]>='a' and s[i]<='z' then
			s[i]-=('a'-'A')
		end if
	end for
	return s
end function


global procedure transoptions()
-- set translator command-line options  
	integer i, option
	sequence uparg
	object s
	
	-- put file first, strip out the options
	i = 1
	while i <= Argc do
		if Argv[i][1] = '-' then
			uparg = upper(Argv[i])
			
			if (equal("-DLL", uparg) or equal("-SO", uparg)) then
				dll_option = TRUE
				
			elsif equal("-CON", uparg) then
				con_option = TRUE
				
			elsif equal("-WAT", uparg) then
				wat_option = TRUE
				
			elsif equal("-KEEP", uparg) then
				keep = TRUE
				
			elsif equal("-DJG", uparg) then
				djg_option = TRUE
				
			elsif equal("-FASTFP", uparg) then
				fastfp = TRUE
				
			elsif equal("-LCCOPT-OFF", uparg) then
				lccopt_option = FALSE
				
			elsif equal("-LCC", uparg) then
				lcc_option = TRUE

			elsif equal("-BOR", uparg) then
				bor_option = TRUE
				
			elsif equal("-STACK", uparg) then
				if i < Argc then
					s = value(Argv[i+1])
					add_switch( Argv[i+1], 1 )
					if s[1] = GET_SUCCESS then
						if s[2] >= 16384 then
							total_stack_size = floor(s[2] / 4) * 4
						end if
					end if
					move_args( i+1, 1 )
				else
					Warning("-stack option missing stack size",translator_warning_flag)
				end if
				
			elsif equal("-DEBUG", uparg) then
				debug_option = TRUE
				
			elsif equal("-LIB", uparg ) then
				if i < Argc then
					user_library = Argv[i+1]
					add_switch( user_library, 1 )
					move_args( i+1, 1 )
				else
					Warning("-lib option missing library name",translator_warning_flag)
				end if
			
			elsif equal("-PLAT", uparg ) then
				if i < Argc then
					s = upper(Argv[i+1])
					add_switch( Argv[i+1], 1 )
					move_args( i+1, 1 )
					if equal( s, "WIN" ) then
						set_host_platform( WIN32 )
					elsif equal( s, "DOS" ) then
						set_host_platform( DOS32 )
					elsif equal( s, "LINUX" ) then
						set_host_platform( ULINUX )
					elsif equal( s, "FREEBSD" ) then
						set_host_platform( UFREEBSD )
					elsif equal( s, "OSX" ) then
						set_host_platform( UOSX )
					else
						Warning("unknown platform: %s", translator_warning_flag,{ Argv[i]})
					end if
				end if
			
			elsif equal("-COM", uparg ) then
				if i < Argc then
					compile_dir = Argv[i+1]
					add_switch( compile_dir, 1 )
					move_args( i+1, 1 )
				else
					Warning("-com option missing compile directory",translator_warning_flag)
				end if
			else
				option = find( uparg, COMMON_OPTIONS )
				if option then
					common_options( option, i )
				else
					Warning("unknown option: %s", translator_warning_flag, {Argv[i]})
				end if

			end if
			-- delete "-" option from the list of args */
			add_switch( Argv[i], 0 )
			move_args( i, 1 )
		else 
			i += 1 -- ignore non "-" items
		end if      
	end while
	
	-- The platform might have changed, so clean up in case of inconsistent options
	if dll_option and (TDOS) then
		dll_option = FALSE
		Warning( "cannot build a dll for DOS",translator_warning_flag )
	end if
	
	if con_option and not TWINDOWS then
		con_option = FALSE
		Warning( "console option only available for Windows",translator_warning_flag )
	end if
	
	if wat_option and not (TWINDOWS or TDOS) then
		wat_option = FALSE
		Warning( "Watcom option only available for Windows or DOS",translator_warning_flag )
	end if
	
	if djg_option and not TDOS then
		djg_option = FALSE
		Warning( "DJGPP option only available for DOS",translator_warning_flag )
	end if

	if bor_option and not TWINDOWS then
		bor_option = FALSE
		Warning( "Borland option only available for Windows", translator_warning_flag)
	end if
	
	if lcc_option and not TWINDOWS then
		lcc_option = FALSE
		Warning( "LCC option only available for Windows",translator_warning_flag )
	end if
	
	if not lccopt_option and not TWINDOWS then
		lccopt_option = FALSE
		Warning( "LCC Opt-Off only available for Windows" ,translator_warning_flag)
	end if
	
	if fastfp and not TDOS then
		fastfp = FALSE
		Warning( "Fast FP option only available for DOS",translator_warning_flag )
	end if
	
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

	if TDOS and sequence(dj_path) then
		c_puts("#include <go32.h>\n")
	end if
	c_puts("#include \"")
	c_puts("include" & SLASH & "euphoria.h\"\n")
	c_puts("#include \"main-.h\"\n\n")
	
	c_h = open("main-.h", "w")
	if c_h = -1 then
		CompileErr("Can't open main-.h file for output\n")
	end if
end procedure

procedure InitBackEnd(integer c)
-- Initialize special stuff for the translator
	
	if c = 1 then
		OpenCFiles()
		return
	end if
	
	init_opcodes()
	
	transoptions()
	
	if TDOS then
		wat_path = 0
		if length(compile_dir) then
			if djg_option then
				dj_path  = compile_dir
			else
				wat_path = compile_dir
			end if
			return
		end if
			
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

	if TWINDOWS then
		bor_path = 0
		wat_path = 0
		if not lcc_option then
			if not bor_option then
				if length(compile_dir) then
					wat_path = compile_dir
					return
				else
					wat_path = getenv("WATCOM")
				end if
			else
				bor_path = get_bor_path()
				if sequence(wat_path) then
					bor_path = 0
				end if
				if sequence(bor_path) then
					wat_path = 0
				end if
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
mode:set_init_backend( routine_id("InitBackEnd") )

procedure CheckPlatform()
-- make sure the defines reflect the target platform
	
	if TLINUX or TBSD or TOSX then
		OpDefines = OpDefines[1..$-2]
	else
		OpDefines = OpDefines[1..$-1]
	end if
	
	if TWINDOWS then
		OpDefines &= {"WIN32"}
	elsif TOSX then
		OpDefines &= {"UNIX", "OSX"}
	elsif TBSD then
		OpDefines &= {"UNIX", "FREEBSD"}
	elsif TLINUX then
		OpDefines &= {"LINUX", "UNIX"}
	elsif TUNIX then --right now this can never happen
		OpDefines &= {"UNIX"}
	elsif TDOS then
		OpDefines &= {"DOS32"}
	end if
end procedure
mode:set_check_platform( routine_id("CheckPlatform") )
