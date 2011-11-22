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
	{ "debug",            0, GetMsgText(189,0), { } },
	{ "plat",             0, GetMsgText(185,0), { HAS_PARAMETER, "platform" } },
	{ "con",              0, GetMsgText(182,0), { } },
	{ "dll",              0, GetMsgText(183,0), { } },
	{ "so",               0, GetMsgText(184,0), { } },
	{ "o",                0, GetMsgText(198,0), { HAS_PARAMETER, "filename" } },
	{ "build-dir",        0, GetMsgText(197,0), { HAS_PARAMETER, "dir" } },
	{ "rc-file",          0, GetMsgText(171,0), { HAS_PARAMETER, "filename" } },
	{ "wat",              0, GetMsgText(178,0), { } },
	{ "gcc",              0, GetMsgText(180,0), { } },
	{ "com",              0, GetMsgText(181,0), { HAS_PARAMETER, "dir" } },
	{ "cflags", 	      0, GetMsgText(323,0), { HAS_PARAMETER, "flags" } },
	{ "lflags", 	      0, GetMsgText(324,0), { HAS_PARAMETER, "flags" } },
	{ "lib",              0, GetMsgText(186,0), { HAS_PARAMETER, "filename" } },
	{ "stack",            0, GetMsgText(188,0), { HAS_PARAMETER, "size" } },
	{ "maxsize",          0, GetMsgText(190,0), { HAS_PARAMETER, "size" } },
	{ "keep",             0, GetMsgText(191,0), { } },
	{ "nobuild",          0, GetMsgText(196,0), { } },
	{ "force-build",      0, GetMsgText(326,0), { } },
	{ "makefile",         0, GetMsgText(193,0), { } },
	{ "makefile-partial", 0, GetMsgText(192,0), { } },
	{ "silent",           0, GetMsgText(177,0), { } },
	{ "verbose",	      0, GetMsgText(319,0), { } },
	{ "no-cygwin",        0, GetMsgText(351,0), { } },
	$
}

add_options( trans_opt_def )

--**
-- Process the translator command-line options

export procedure transoptions()
	sequence tranopts = get_options()
	
	Argv = expand_config_options( Argv )
	Argc = length(Argv)
	
	map:map opts = cmd_parse( tranopts, , Argv)

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
				
			case "rc-file" then
				rc_file[D_NAME] = canonical_path(val)
				rc_file[D_ALTNAME] = adjust_for_command_line_passing((rc_file[D_NAME]))
				if not file_exists(rc_file[D_NAME]) then
					ShowMsg(2, 349, { val })
					abort(1)
				end if

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
				OpDefines &= { "CONSOLE" }

			case "dll", "so" then
				dll_option = TRUE
				OpDefines &= { "EUC_DLL" }

			case "plat" then
				switch upper(val) do
					-- please update comments in Makefile.gnu, Makefile.wat, configure and
					-- configure.bat; and the help section in configure and configure.bat; and
					-- the message 201 in msgtext.e if you add another platform.
					case "WINDOWS" then
						set_host_platform( WIN32 )

					case "LINUX" then
						set_host_platform( ULINUX )

					case "FREEBSD" then
						set_host_platform( UFREEBSD )

					case "OSX" then
						set_host_platform( UOSX )

					case "OPENBSD" then
						set_host_platform( UOPENBSD )

					case "NETBSD" then
						set_host_platform( UNETBSD )

					case else
						ShowMsg(2, 201, { val, "WINDOWS, LINUX, FREEBSD, OSX, OPENBSD, NETBSD" })
						abort(1)
				end switch

			case "lib" then
				user_library = val

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

			case "makefile-partial" then
				build_system_type = BUILD_MAKEFILE_PARTIAL

			case "makefile" then
				build_system_type = BUILD_MAKEFILE_FULL

			case "nobuild" then
				build_system_type = BUILD_NONE

			case "build-dir" then
				output_dir = val
				if find(output_dir[$], "/\\") = 0 then
					output_dir &= '/'
				end if

			case "force-build" then
				force_build = 1

			case "o" then
				exe_name[D_NAME] = val
			
			case "no-cygwin" then
				mno_cygwin = 1
			
		end switch
	end for

	if compiler_type != COMPILER_GCC and not equal(user_library,"") then
		if not file_exists(canonical_path(user_library)) then
			ShowMsg(2, 348, { user_library })
			if force_build or build_system_type = BUILD_DIRECT then
				abort(1)
			end if
		else
			user_library = canonical_path(user_library)
		end if
	end if
	if length(exe_name[D_NAME]) and not absolute_path(exe_name[D_NAME]) then
		exe_name[D_NAME] = current_dir() & SLASH & exe_name[D_NAME]
	end if
	exe_name[D_ALTNAME] = adjust_for_command_line_passing(exe_name[D_NAME])
	
	if length(map:get(opts, OPT_EXTRAS)) = 0 then
		-- No source supplied on command line
		show_banner()
		ShowMsg(2, 203)
		-- translator_help()
		show_help(tranopts,, Argv)

		abort(1)
	end if
	
	OpDefines &= { "EUC" }

	if host_platform() = WIN32 and not con_option then
		OpDefines = append( OpDefines, "GUI" )
	elsif not find( "CONSOLE", OpDefines ) then
		OpDefines = append( OpDefines, "CONSOLE" )
	end if

	ifdef not EUDIS then
		if build_system_type = BUILD_DIRECT and length(output_dir) = 0 then
			output_dir = temp_file("." & SLASH, "build-", "")
			if find(output_dir[$], "/\\") = 0 then
				output_dir &= '/'
			end if
	
			if not silent then
				printf(1, "Build directory: %s\n", { abbreviate_path(output_dir) })
			end if
			
			remove_output_dir = 1
		end if
	end ifdef
	
	if length(rc_file[D_NAME]) then
		res_file[D_NAME] = canonical_path(output_dir & filebase(rc_file[D_NAME]) & ".res")
		res_file[D_ALTNAME] = adjust_for_command_line_passing(res_file[D_NAME])
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
	
	if c = 1 then
		OpenCFiles()

		return
	end if
	
	init_opcodes()
	transoptions()
	
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
			wat_path = getenv("WATCOM")

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
			elsif not file_exists(wat_path & SLASH & "binnt" & SLASH & "wcc386.exe") then
				if build_system_type = BUILD_DIRECT then
					CompileErr( 352, {wat_path})
				else
					Warning( 352, translator_warning_flag, {wat_path})
				end if
			elsif match(upper(wat_path & "\\H;" & wat_path & "\\H\\NT"),
				upper(getenv("INCLUDE"))) != 1
			then
				Warning( 216, translator_warning_flag, {wat_path,getenv("INCLUDE")} )
			end if

		case else
			CompileErr(150)

	end switch
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
