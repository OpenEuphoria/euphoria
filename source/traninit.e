-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
-- This module sets one of wat_path, bor_path, or dj_path or none at all 
-- to indicate lcc or gcc.  Using the command line options or environment variables
-- as hints it checks for command line sanity and sets the said environment
-- variables.
-- 
-- If the user selects the compiler at the command line and it cannot
-- find its envinronment variable the translator will exit with an error.
-- If the user doesn't select it then it will try all of the environment
-- variables and use the selected platform to determine which compiler must
-- be used.

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
include std/sort.e
include compile.e
include cominit.e
include tranplat.e
include pathopen.e

-- true if we want to force the user to choose the compiler
constant FORCE_CHOOSE = FALSE

boolean help_option = FALSE
wat_option = FALSE
djg_option = FALSE
bor_option = FALSE
lcc_option = FALSE
gcc_option = FALSE

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
	
	Argv &= GetDefaultArgs()
	Argc = length(Argv)

	-- put file first, strip out the options
	i = 1
	while i <= Argc do
		if Argv[i][1] = '-' then
			uparg = upper(Argv[i])
			
			if find(uparg,{"-HELP","-?"}) then
				help_option = TRUE
			
			elsif (equal("-SILENT", uparg)) then
				silent = TRUE
				
			elsif (equal("-DLL", uparg) or equal("-SO", uparg)) then
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
				
			elsif equal("-GCC", uparg) then
				-- on windows this is MinGW
				-- cygwin should get its own option
				-- probably -CYG
				gcc_option = TRUE
				
			elsif equal("-STACK", uparg) then
				if i < Argc then
					s = value(Argv[i+1])
					add_switch( Argv[i+1], 1 )
					if s[1] = GET_SUCCESS then
						if s[2] >= 16384 then
							total_stack_size = floor(s[2] / 4) * 4
						end if
					end if
					move_args( i+1 )
				else
					Warning("-stack option missing stack size",translator_warning_flag)
				end if
				
			elsif equal("-DEBUG", uparg) then
				debug_option = TRUE
				keep = TRUE -- you'll need the sources to debug
				
			elsif equal("-LIB", uparg ) then
				if i < Argc then
					user_library = Argv[i+1]
					add_switch( user_library, 1 )
					move_args( i+1 )
				else
					Warning("-lib option missing library name",translator_warning_flag)
				end if
			
			elsif equal("-PLAT", uparg ) then
				if i < Argc then
					s = upper(Argv[i+1])
					add_switch( Argv[i+1], 1 )
					move_args( i+1 )
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
					move_args( i+1 )
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
			move_args( i )
		else 
			i += 1 -- ignore non "-" items
		end if      
	end while
	
	if help_option then
		CompileErr(
"Usage: ec [-plat win|dos|linux|freebsd|osx] [-wat|-djg|-lcc|-bor|-gcc]\n"&
"          [-com /compile_directory/] [-keep] [-debug] [-silent]\n"&
"          [-lib /library relative to %EUDIR%\\bin/] [-stack /stack size/]\n"&
"          [/os specific options/]:\n" &
"\n"&
"OS Specific Options:\n"&
"       Windows:  [-con] [-wat|-djg|-lcc|-bor] [-dll]\n" &
"       DOS    :  [-djg|-wat] [-fastfp]\n" &
"       Linux  :  [-gcc] [-dll]\n" &
"       FreeBSD:  [-gcc] [-dll]\n" &
"       OSX    :  [-gcc] [-dll]\n" &
"\n"&
"LCC Only: -lccopt-off\n\n"&
"Explainations:\n" &
"       -CON : Don't create a new window when using the console.\n"
			   
			   
			   )	
	end if
	
	if FORCE_CHOOSE and (TWINDOWS or TDOS) and compare( {wat_option,  djg_option,  lcc_option,  bor_option}, {0,0,0,0} ) = 0 then
		Warning( "No compiler specified for Windows or DOS (Watcom (-wat), DJG (-djg), LCC (-lcc), or Borland (-bor)).\n", translator_warning_flag  )
	end if
	
	if (TWINDOWS or TDOS) and compare( sort({wat_option,  djg_option,  lcc_option,  bor_option}), {0,0,0,1} ) > 0 then
		Warning( "You should specify one and only one compiler you want to use: Watcom (-wat), DJG (-djg), LCC (-lcc), or Borland (-bor).", translator_warning_flag )
	end if
	
	-- The platform might have changed, so clean up in case of inconsistent options
	if dll_option and (TDOS) then
		dll_option = FALSE
		Warning( "cannot build a dll for DOS",translator_warning_flag )
	end if
	
	if con_option and not TWINDOWS then
		Warning( "console option only available for Windows",translator_warning_flag )
	end if
	
	if wat_option then
		if not (TWINDOWS or TDOS) then
			set_host_platform( WIN32 )
			Warning( "Watcom option only available for Windows or DOS... Choosing Windows", translator_warning_flag )
		end if
	
		if atom( getenv( "WATCOM" ) ) then
	    		-- let this die later..
		elsif find( ' ', getenv("WATCOM" ) ) != 0 then
			Warning( "Watcom cannot build translated files when there is a space in its parent folders", translator_warning_flag )
		elsif atom( getenv( "INCLUDE" ) ) then
			Warning( "Watcom needs to have an INCLUDE variable set to its included directories",
				translator_warning_flag )
		elsif match( upper(getenv("WATCOM") & "\\H;" 
			& getenv("WATCOM") & "\\H\\NT"),
			upper(getenv("INCLUDE")) ) != 1 then
				Warning( "Watcom should have the H and the H\\NT includes at the front of the INCLUDE variable.", translator_warning_flag )
			--http://openeuphoria.org/EUforum/index.cgi?module=forum&action=message&id=101301#101301
		end if
	
	end if
	
	if djg_option and not TDOS then
		CompileErr( "DJGPP option only available for DOS." )
	end if

	if bor_option and not TWINDOWS then
		CompileErr( "Borland option only available for Windows." )
	end if
	
	if lcc_option and not TWINDOWS then
		CompileErr( "LCC option only available for Windows." )
	end if
	
	if not lccopt_option and not TWINDOWS then
		CompileErr( "LCC Opt-Off only available for Windows." )
	end if
	
	if fastfp and not TDOS then
		fastfp = FALSE
		CompileErr( "Fast FP option only available for DOS" )
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
	while b > 1 and path[b] != ';' do
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

	-- If no compiler has been chosen test the variables to
	-- see which is installed.  If a UNIX system choose gcc.
	-- If Windows or DOS
	-- Try in the order: WATCOM, DJGPP, or Borland
	
	
	if TDOS then
		if gcc_option then
			djg_option = 1
		end if
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
				CompileErr("WATCOM environment variable is not set")
			end if
			dj_path = 0
		end if
		if djg_option and atom(dj_path) then
			CompileErr("DJGPP environment variable is not set")
		end if
		bor_path = 0
	end if

	if TWINDOWS then
		dj_path = 0
		bor_path = 0
		wat_path = 0
		if not lcc_option then
			if not bor_option then
				if length(compile_dir) then
					wat_path = compile_dir
				else
					wat_path = getenv("WATCOM")
				end if
			else
				if length(compile_dir) then
					bor_path = compile_dir
				else
					bor_path = get_bor_path()
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
	
	if TUNIX then
		dj_path = 0
		gcc_option = 1
		wat_path = 0
		bor_path = 0
	end if
	
	if sequence(wat_path)+gcc_option+sequence(dj_path)+sequence(bor_path)+lcc_option = 0 then
		CompileErr( "Cannot determine for which compiler to translate for." ) 
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
