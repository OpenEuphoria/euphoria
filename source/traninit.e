--
-- (c) Copyright - See License.txt
--
--****
-- == traninit.e: Initialize the translator
--
-- This module sets one of wat_path, or dj_path or none at all
-- to indicate gcc.  Using the command line options or environment variables
-- as hints it checks for command line sanity and sets the said environment
-- variables.
--
-- If the user selects the compiler at the command line and it cannot
-- find its environment variable the translator will exit with an error.
-- If the user doesn't select it then it will try all of the environment
-- variables and use the selected platform to determine which compiler must
-- be used.

-- If you are translating to another platform, we expect you to take the
-- C files and compile natively rather than using a cross compiler
--
-- From the GNU terminology there are three platforms ##target##, ##host##, and ##build##.
-- For the translator that will be built using this file there are four:
--
-- |= GNU platform name |= Description |= Variable Names |
-- |##target##   | The newly translated and compiled translator will translate to
--                 any target platform for this translator... | none|
-- |##host##     | The platform of the host this translated compiled translator will run on.|
--                 ##TUNIX##, TLINUX, TWINDOWS, ##T/osname/## |
-- |##build##    | The platform where the building utilities make, wmake, compiler
--                 and assembler are run.| ##TUNIX##, TLINUX, TWINDOWS, ##T/osname/##|
-- |##translate##| The platform where the current translator is run on|platform()|
--
-- ifdef OSNAME and platform() is for our translation platform,
-- TOSNAME is for the target platform.
-- We assume that the target platform is the same as our build platform.
-- Thus, no cross compilers.


ifdef ETYPE_CHECK then
	with type_check
elsedef
	without type_check
end ifdef

include std/cmdline.e
include std/error.e
include std/filesys.e
include std/get.e
include std/map.e
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
include pathopen.e
include error.e
include platform.e
include buildsys.e
include msgtext.e

function extract_options(sequence s)
	return s
end function
set_extract_options( routine_id("extract_options") )

sequence trans_opt_def = {
	{ "silent",        0, GetMsgText(177,0), { NO_CASE } },
	{ "verbose",	   0, GetMsgText(319,0), { NO_CASE } },
	{ "wat",           0, GetMsgText(178,0), { NO_CASE } },
	{ "gcc",           0, GetMsgText(180,0), { NO_CASE } },
	{ "cflags", 	   0, GetMsgText(323,0), { NO_CASE, HAS_PARAMETER, "flags" } },
	{ "lflags", 	   0, GetMsgText(324,0), { NO_CASE, HAS_PARAMETER, "flags" } },
	{ "com",           0, GetMsgText(181,0), { NO_CASE, HAS_PARAMETER, "dir" } },
	{ "con",           0, GetMsgText(182,0), { NO_CASE } },
	{ "dll",           0, GetMsgText(183,0), { NO_CASE } },
	{ "so",            0, GetMsgText(184,0), { NO_CASE } },
	{ "plat",          0, GetMsgText(185,0), { NO_CASE, HAS_PARAMETER, "platform" } },
	{ "lib",           0, GetMsgText(186,0), { NO_CASE, HAS_PARAMETER, "filename" } },
	{ "fastfp",        0, GetMsgText(187,0), { NO_CASE } },
	{ "stack",         0, GetMsgText(188,0), { NO_CASE, HAS_PARAMETER, "size" } },
	{ "debug",         0, GetMsgText(189,0), { NO_CASE } },
	{ "maxsize",       0, GetMsgText(190,0), { NO_CASE, HAS_PARAMETER, "size" } },
	{ "keep",          0, GetMsgText(191,0), { NO_CASE } },
	{ "makefile",      0, GetMsgText(192,0), { NO_CASE } },
	{ "makefile-full", 0, GetMsgText(193,0), { NO_CASE } },
	{ "emake",         0, GetMsgText(195,0), { NO_CASE } },
	{ "nobuild",       0, GetMsgText(196,0), { NO_CASE } },
	{ "force-build",   0, GetMsgText(326,0), { NO_CASE } },
	{ "builddir",      0, GetMsgText(197,0), { NO_CASE, HAS_PARAMETER, "dir" } },
	{ "o",             0, GetMsgText(198,0), { NO_CASE, HAS_PARAMETER, "filename" } }
}

add_options( trans_opt_def )

procedure translator_help()
	ShowMsg(1, 199)
	show_help( get_common_options(), NO_HELP)
	ShowMsg(1, 200)
	show_help(trans_opt_def, NO_HELP)
end procedure

--**
-- Process the translator command-line options

export procedure transoptions()
	Argv &= GetDefaultArgs()

	Argv = expand_config_options(Argv)
	Argc = length(Argv)
	map:map opts = cmd_parse( get_options(), routine_id("translator_help"), Argv)

	handle_common_options(opts)

	sequence opt_keys = map:keys(opts)
	integer option_w = 0

	for idx = 1 to length(opt_keys) do
		sequence key = opt_keys[idx]
		object val = map:get(opts, key)

		switch key do
			case "silent" then
				silent = TRUE

			case "verbose" then
				verbose = TRUE

			case "cflags" then
				cflags = val

			case "lflags" then
				lflags = val

			case "wat" then
				compiler_type = COMPILER_WATCOM

			case "gcc" then
				compiler_type = COMPILER_GCC

			case "com" then
				compiler_dir = val

			case "con" then
				con_option = TRUE
				OpDefines &= { "EUC_CON" }

			case "dll", "so" then
				dll_option = TRUE
				OpDefines &= { "EUC_DLL" }

			case "plat" then
				switch upper(val) do
					-- please update comments in Makefile.gnu, Makefile.wat, configure and
					-- configure.bat; and the help section in configure and configure.bat; and
					-- the message 201 in msgtext.e if you add another platform.
					case "WIN" then
						set_host_platform( WIN32 )

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
						ShowMsg(2, 201, { val, "WIN, LINUX, FREEBSD, OSX, SUNOS, OPENBSD, NETBSD" })
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

			case "maxsize" then
				sequence tmp = value(val)
				if tmp[1] = GET_SUCCESS then
					max_cfile_size = tmp[2]
				else
					ShowMsg(2, 202)
					abort(1)
				end if

			case "keep" then
				keep = TRUE

			case "makefile" then
				build_system_type = BUILD_MAKEFILE

			case "makefile-full" then
				build_system_type = BUILD_MAKEFILE_FULL

			case "emake" then
				build_system_type = BUILD_EMAKE

			case "nobuild" then
				build_system_type = BUILD_NONE

			case "builddir" then
				output_dir = val
				if find(output_dir[$], "/\\") = 0 then
					output_dir &= '/'
				end if

			case "force-build" then
				force_build = 1

			case "o" then
				exe_name = val
		end switch
	end for

	if length(map:get(opts, "extras")) = 0 then
		-- No source supplied on command line
		show_banner()
		ShowMsg(2, 203)
		translator_help()

		abort(1)
	end if

	OpDefines &= { "EUC" }

	if host_platform() = WIN32 and not con_option then
		OpDefines = append( OpDefines, "WIN32_GUI" )
	end if

	finalize_command_line(opts)
end procedure

--**
-- open and initialize translator output files
procedure OpenCFiles()
	if sequence(output_dir) and length(output_dir) > 0 then
		create_directory(output_dir)
	end if

	c_code = open(output_dir & "init-.c", "w")
	if c_code = -1 then
		CompileErr(55)
	end if

	add_file("init-.c")

	emit_c_output = TRUE

	c_puts("#include \"")
	c_puts("include/euphoria.h\"\n")

	c_puts("#include \"main-.h\"\n\n")
	c_h = open(output_dir & "main-.h", "w")
	if c_h = -1 then
		CompileErr(47)
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
		if TWINDOWS then
			compiler_type = COMPILER_WATCOM
		elsif TUNIX then
			compiler_type = COMPILER_GCC
		end if
	end if

	switch compiler_type do
	  	case COMPILER_GCC then
			-- Nothing special we have to do for gcc
			break -- to avoid empty block warning

		case COMPILER_WATCOM then
			if length(compiler_dir) then
				wat_path = compiler_dir
			else
				wat_path = getenv("WATCOM")
			end if

			if atom(wat_path) then
				if build_system_type = BUILD_DIRECT then
					-- We know the building process will fail when the translator starts
					-- calling the compiler.  So, the process fails here.
					CompileErr(159)
				else
					-- In this case, the user has to call something to compile after the
					-- translation.  The user may set up the environment after the translation or
					-- the environment may be on another machine on the network.
					Warning(159, translator_warning_flag)
				end if
			elsif find(' ', wat_path) then
				Warning( 214, translator_warning_flag)
			elsif atom(getenv("INCLUDE")) then
				Warning( 215, translator_warning_flag )
			elsif match(upper(wat_path & "\\H;" & getenv("WATCOM") & "\\H\\NT"),
				upper(getenv("INCLUDE"))) != 1
			then
				Warning( 216, translator_warning_flag )
				--http://openeuphoria.org/EUforum/index.cgi?module=forum&action=message&id=101301#101301
			end if

		case else
			CompileErr(150)

	end switch

	if fastfp then
		CompileErr(93)
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
