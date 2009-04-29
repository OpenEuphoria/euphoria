-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
-- This module sets one of wat_path, or dj_path or none at all 
-- to indicate gcc.  Using the command line options or environment variables
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
include std/get.e
include std/error.e
include std/sort.e

-- Translator initialization
include global.e
include platform.e
include mode.e as mode
include c_out.e
include c_decl.e
include compile.e
include cominit.e
include buildsys.e
include pathopen.e
include error.e
include platform.e

-- true if we want to force the user to choose the compiler
constant FORCE_CHOOSE = FALSE

boolean help_option = FALSE

sequence compile_dir = ""

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

export procedure transoptions()
-- set translator command-line options  
	integer i, option
	sequence uparg
	object s
	
	-- Preprocess real command line args for host platform
	for j = 1 to length(Argv) do
		if equal("-PLAT", upper(Argv[j]) ) then
			if j < length(Argv) then
				switch upper(Argv[j+1]) do
					case "WIN" then
						set_host_platform( WIN32 )
					
					case "DOS" then
						set_host_platform( DOS32 )
						
					case "LINUX" then
						set_host_platform( ULINUX )
						
					case "FREEBSD" then
						set_host_platform( UFREEBSD )
						
					case "OSX" then
						set_host_platform( UOSX )
						
					case "SUNOS" then
						set_host_platform( USUNOS )
						
					case "OPENBSD" then
						set_host_platform( UOPENBSD )
						
					case "NETBSD" then
						set_host_platform( UNETBSD )
						
				end switch
			end if
		end if
	end for
				
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
				compiler_type = COMPILER_WATCOM
				
			elsif equal("-KEEP", uparg) then
				keep = TRUE
				
			elsif equal("-DJG", uparg) then
				compiler_type = COMPILER_DJGPP
				
			elsif equal("-FASTFP", uparg) then
				fastfp = TRUE
				
			elsif equal("-GCC", uparg) then
				compiler_type = COMPILER_GCC
				
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
					switch s do
						case "WIN" then
							set_host_platform( WIN32 )
						
						case "DOS" then
							set_host_platform( DOS32 )
							
						case "LINUX" then
							set_host_platform( ULINUX )
							
						case "FREEBSD" then
							set_host_platform( UFREEBSD )
							
						case "OSX" then
							set_host_platform( UOSX )
							
						case "SUNOS" then
							set_host_platform( USUNOS )
							
						case "OPENBSD" then
							set_host_platform( UOPENBSD )
							
						case "NETBSD" then
							set_host_platform( UNETBSD )
							
						case else
							Warning("unknown platform: %s", translator_warning_flag,{ Argv[i]})
					end switch
				end if
			
			elsif equal("-COM", uparg ) then
				if i < Argc then
					compile_dir = Argv[i+1]
					add_switch( compile_dir, 1 )
					move_args( i+1 )
				else
					Warning("-com option missing compile directory",translator_warning_flag)
				end if

			elsif equal("-MAKEFILE", uparg) then
				build_system_type = BUILD_MAKEFILE

			elsif equal("-MAKEFILE-FULL", uparg) then
				build_system_type = BUILD_MAKEFILE_FULL

			elsif equal("-CMAKEFILE", uparg) then
				build_system_type = BUILD_CMAKE

			elsif equal("-O", uparg) then
				if i < Argc then
					output_dir = Argv[i+1]
					add_switch( output_dir, 1 )
					move_args( i+1)
					create_directory( output_dir )
					output_dir &= '/'
				else
					puts(1, "-o expects a directory name\n")
					abort(1)
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
		show_usage()
		CompileErr( "" )	
	end if
end procedure

--**
-- open and initialize translator output files
procedure OpenCFiles()
	c_code = open(output_dir & "init-.c", "w")
	if c_code = -1 then
		CompileErr("Can't open init-.c for output\n")
	end if

	add_file("init-.c")

	emit_c_output = TRUE

	if TDOS and sequence(dj_path) then
		c_puts("#include <go32.h>\n")
	end if

	c_puts("#include \"")
	c_puts("include" & SLASH & "euphoria.h\"\n")

	c_puts("#include \"main-.h\"\n\n")
	c_h = open(output_dir & "main-.h", "w")
	if c_h = -1 then
		CompileErr("Can't open main-.h file for output\n")
	end if

	add_file("main-.h")
end procedure

--**
-- Initialize special stuff for the translator
procedure InitBackEnd(integer c)
	init_opcodes()
	transoptions()

	if c = 1 then
		OpenCFiles()

		return
	end if

	if compiler_type = COMPILER_UNKNOWN then
		if TWINDOWS or TDOS then
			compiler_type = COMPILER_WATCOM
		elsif TUNIX then
			compiler_type = COMPILER_GCC
		end if
	end if

	if TDOS and compiler_type = COMPILER_GCC then
		compiler_type = COMPILER_DJGPP
	end if

	switch compiler_type do
	  	case COMPILER_GCC then
			-- Nothing special we have to do for gcc
			break -- to avoid empty block warning

		case COMPILER_DJGPP then
			if length(compiler_dir) then
				dj_path = compiler_dir
			else
				dj_path = getenv("DJGPP")
			end if

			if atom(dj_path) then
				CompileErr("DJGPP environment variable is not set")
			end if

			if not TDOS then
				CompileErr( "DJGPP option only available for DOS." )
			end if

		case COMPILER_WATCOM then
			if length(compiler_dir) then
				wat_path = compiler_dir
			else
				wat_path = getenv("WATCOM")
			end if
		
			if atom(wat_path) then
				CompileErr("WATCOM environment variable is not set")
			elsif find(' ', wat_path) then
				Warning( "Watcom cannot build translated files when there is a space in its parent folders",
					translator_warning_flag)
			elsif atom(getenv("INCLUDE")) then
				Warning( "Watcom needs to have an INCLUDE variable set to its included directories",
					translator_warning_flag )
			elsif match(upper(wat_path & "\\H;" & getenv("WATCOM") & "\\H\\NT"),
				upper(getenv("INCLUDE"))) != 1
			then
				Warning( "Watcom should have the H and the H\\NT includes at the front " &
					"of the INCLUDE variable.", translator_warning_flag )
				--http://openeuphoria.org/EUforum/index.cgi?module=forum&action=message&id=101301#101301
			end if

		case else
			CompileErr("Unknown compiler")

	end switch

	if dll_option and TDOS then
		CompileErr("cannot build a dll for DOS")
	end if
	
	if con_option and not TWINDOWS then
		CompileErr("console option only available for Windows")
	end if
	
	if fastfp and not TDOS then
		CompileErr("Fast FP option only available for DOS")
	end if
end procedure
mode:set_init_backend( routine_id("InitBackEnd") )

procedure CheckPlatform()
	-- make sure the defines reflect the target platform
	OpDefines = remove(OpDefines,
		find("_PLAT_START", OpDefines),
		find("_PLAT_STOP", OpDefines))
	OpDefines &= GetPlatformDefines(1)
end procedure
mode:set_check_platform( routine_id("CheckPlatform") )
