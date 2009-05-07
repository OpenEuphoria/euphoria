--****
-- == traninit.e: Initialize the translator
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

include std/cmdline.e
include std/error.e
include std/filesys.e
include std/get.e
include std/map.e as m
include std/os.e
include std/sort.e
include std/text.e

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

function extract_options(sequence s)
	return s
end function
set_extract_options( routine_id("extract_options") )

sequence trans_opt_def = {
	{ "silent", 0, "Do not display status messages", { NO_CASE } },
	{ "wat", 0, "Set the compiler to Watcom", { NO_CASE } },
	{ "djg", 0, "Set the compiler to DJGPP", { NO_CASE } },
	{ "gcc", 0, "Set the compiler to GCC", { NO_CASE } },
	{ "com", 0, "Set the compiler directory", { NO_CASE, HAS_PARAMETER, "dir" } },
	{ "con", 0, "Create a console application", { NO_CASE } },
	{ "dll", 0, "Create a shared library", { NO_CASE } },
	{ "so", 0, "Create a shared library", { NO_CASE } },
	{ "plat", 0, "Set the platform for the translated code", { NO_CASE, HAS_PARAMETER, "platform" } },
	{ "lib", 0, "Use a non-standard library", { NO_CASE, HAS_PARAMETER, "filename" } },
	{ "fastfp", 0, "Enable hardware FPU (DOS option only)", { NO_CASE } },
	{ "stack", 0, "Set the stack size (Watcom)", { NO_CASE, HAS_PARAMETER, "size" } },
	{ "debug", 0, "Enable debug mode for generated code", { NO_CASE } },
	{ "keep", 0, "Keep the generated files", { NO_CASE } },
	{ "makefile", 0, "Generate a project Makefile", { NO_CASE } },
	{ "makefile-full", 0, "Generate a full project Makefile", { NO_CASE } },
	{ "cmakefile", 0, "Generate a project CMake file", { NO_CASE } },
	{ "emake", 0, "Generate a emake/emake.bat file to build project", { NO_CASE } },
	{ "nobuild", 0, "Do not build the project nor write a build file", { NO_CASE } },
	{ "builddir", 0, "Generate/compile all files in 'builddir'", { NO_CASE, HAS_PARAMETER, "dir" } },
	{ "o", 0, "Set the output filename", { NO_CASE, HAS_PARAMETER, "filename" } }
}

procedure translator_help()
	printf(1, "euc.exe [options] file.ex...\n", {})
	printf(1, " common options:\n", {})
	show_help(common_opt_def, NO_HELP)
	printf(1, "\n", {})
	printf(1, " translator options:\n", {})
	show_help(trans_opt_def, NO_HELP)
end procedure

--**
-- Process the translator command-line options

export procedure transoptions()
	Argv &= GetDefaultArgs()
	Argc = length(Argv)

	expand_config_options()
	m:map opts = cmd_parse(common_opt_def & trans_opt_def, routine_id("translator_help"), Argv)

	handle_common_options(opts)

	sequence opt_keys = m:keys(opts)
	integer option_w = 0

	for idx = 1 to length(opt_keys) do
		sequence key = opt_keys[idx]
		object val = m:get(opts, key)

		switch key do
			case "silent" then
				silent = TRUE

			case "wat" then
				compiler_type = COMPILER_WATCOM

			case "djg" then
				compiler_type = COMPILER_DJGPP

			case "gcc" then
				compiler_type = COMPILER_GCC

			case "com" then
				compiler_dir = val

			case "con" then
				con_option = TRUE

			case "dll", "so" then
				dll_option = TRUE

			case "plat" then
				switch upper(val) do
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
						printf(2, "Unknown platform: %s\n", { val })
						abort(1)
				end switch

			case "lib" then
				user_library = val

			case "fastfp" then
				fastfp = TRUE

			case "stack" then
				sequence tmp = value(val)
				if tmp[1] = GET_SUCCESS then
					if tmp[2] >= 16384 then
						total_stack_size = floor(tmp[2] / 4) * 4
					end if
				end if

			case "debug" then
				debug_option = TRUE
				keep = TRUE -- you'll need the sources to debug

			case "keep" then
				keep = TRUE

			case "makefile" then
				build_system_type = BUILD_MAKEFILE

			case "makefile-full" then
				build_system_type = BUILD_MAKEFILE_FULL

			case "cmakefile" then
				build_system_type = BUILD_CMAKE

			case "emake" then
				build_system_type = BUILD_EMAKE

			case "nobuild" then
				build_system_type = BUILD_NONE

			case "builddir" then
				output_dir = val
				if find(output_dir[$], "/\\") = 0 then
					output_dir &= '/'
				end if

			case "o" then
				exe_name = val
		end switch
	end for

	if length(m:get(opts, "extras")) = 0 then
		show_banner()
		puts(2, "\nERROR: Must specify the file to be translated on the command line\n\n")
		translator_help()

		abort(1)
	end if

	finalize_command_line(opts)
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
	
	if fastfp and not TDOS then
		CompileErr("Fast FP option only available for DOS")
	end if
end procedure
mode:set_init_backend( routine_id("InitBackEnd") )

--**
-- make sure the defines reflect the target platform
procedure CheckPlatform()
	OpDefines = eu:remove(OpDefines,
		find("_PLAT_START", OpDefines),
		find("_PLAT_STOP", OpDefines))
	OpDefines &= GetPlatformDefines(1)
end procedure
mode:set_check_platform( routine_id("CheckPlatform") )
