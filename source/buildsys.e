--
-- Copyright (c) 2009 by The OpenEuphoria Group.
--

include std/filesys.e

include c_decl.e
include c_out.e
--include compile.e
include error.e
include global.e
include platform.e
--include reswords.e
--include symtab.e

--****
-- = buildsys.e
--
-- Deals with writting files for various build systems:
--   * emake/emake.bat
--   * Makefile - full
--   * Makefile - partial (for inclusion into a parent Makefile)
--   * CMake
--   * None
--

export enum
	--**
	-- No build system will be written (C/H files written only).
	BUILD_NONE=0,

	--**
	-- Standard emake/emake.bat file
	BUILD_EMAKE,

	--**
	-- Makefile containing only ##PRGNAME_SOURCES## and ##PRGNAME_OBJECTS##
	-- Makefile that is for inclusion into a parent Makefile.
	BUILD_MAKEFILE,

	--**
	-- A full Makefile project suitable for building the resulting project
	-- entirely.
	BUILD_MAKEFILE_FULL,

	--**
	-- prgname.cmake file for inclusion into a parent CMake project.
	BUILD_CMAKE

--**
-- Build system type. This defaults to the BUILD_EMAKE process for
-- backward compatability.

export integer build_system_type = BUILD_EMAKE

export enum
	COMPILER_UNKNOWN = 0,
	COMPILER_GCC,
	COMPILER_DJGPP,
	COMPILER_WATCOM,
	COMPILER_LCC

export integer compiler_type = COMPILER_UNKNOWN
export sequence compiler_dir = ""

enum SETUP_CEXE, SETUP_CFLAGS, SETUP_LEXE, SETUP_LFLAGS, SETUP_OBJ_EXT

--**
-- Setup the build environment. This includes things such as the
-- compiler/linker executable, c flags, linker flags, debug settings,
-- etc...

function setup_build()
	sequence c_exe   = "", c_flags = "", l_exe   = "", l_flags = "", obj_ext = ""

	switch compiler_type do
		case COMPILER_GCC then
			c_exe = "gcc"
			l_exe = "gcc"
			obj_ext = "o"

			if debug_option then
				c_flags = " -g3"
			else
				c_flags = " -fomit-frame-pointer"
			end if

			if dll_option then
				c_flags &= " -fPIC"
		   	end if

			c_flags &= sprintf(" -c -w -fsigned-char -O2 -I%s -ffast-math", { get_eudir()  })

			if TWINDOWS then
				c_flags &= " -mno-cygwin"
				if not con_option then
					c_flags &= " -mwindows"
				end if
			end if

		case COMPILER_DJGPP then
			c_exe = "gcc"
			l_exe = "gcc"
			obj_ext = "o"

			if debug_option then
				c_flags = " -g3"
			else
				c_flags = " -fomit-frame-pointer -g0"
			end if

			c_flags &= " -c -w -fsigned-char -O2 -ffast-math"

		case COMPILER_WATCOM then
			c_exe = "wcc386"
			l_exe = "wlink"
			obj_ext = "obj"

			if debug_option then
				c_flags = " /d3"
				l_flags = " DEBUG ALL "
			end if

			l_flags &= sprintf(" OPTION STACK=%d ", { total_stack_size })
			l_flags &= sprintf(" COMMIT STACK=%d ", { total_stack_size })
			l_flags &= " OPTION QUIET OPTION ELIMINATE OPTION CASEEXACT"

			if TDOS then
				l_flags &= " option osname='CauseWay'"
				l_flags &= sprintf(" libpath %s\\lib386", { wat_path })
				l_flags &= sprintf(" libpath %s\\lib386\\dos", { wat_path })
				l_flags &= sprintf(" OPTION stub=%s\\bin\\cwstub.exe", { shrink_to_83(get_eudir()) })
				l_flags &= " format os2 le ^"
				if fastfp then
					c_flags &= " /w0 /zq /j /zp4 /fp5 /fpi87 /5r /otimra /s"
				else
					c_flags &= " /w0 /zq /j /zp4 /fpc /5r /otimra /s"
				end if
			else
				if dll_option then
					c_flags &= " /bd /bt=nt /mf /w0 /zq /j /zp4 /fp5 /fpi87 /5r /otimra /s /I" & get_eudir()
					l_flags &= " SYSTEM NT_DLL initinstance terminstance"
				else
					c_flags &= " /bt=nt /mf /w0 /zq /j /zp4 /fp5 /fpi87 /5r /otimra /s /I" & get_eudir()
				end if
				if con_option then
					l_flags &= " SYSTEM NT"
				else
					l_flags &= " SYSTEM NT_WIN RUNTIME WINDOWS=4.0"
				end if
			end if

		case COMPILER_LCC then
			c_exe = "lcc"
			l_exe = "lcclnk"
			obj_ext = "obj"

			if debug_option then
				c_flags &= " -g"
			end if

			c_flags &= sprintf(" -w -Zp4 -I%s", { get_eudir() })
			l_flags &= sprintf(" -s -stack-reserve %d -stack-commit %d", { total_stack_size,
				total_stack_size })

			if lccopt_option then
				c_flags &= " -O"
			end if

			if con_option then
				l_flags &= " -subsystem console"
			else
				l_flags &= " -subsystem windows"
			end if

		case else
			CompileErr("Compiler is unknown")
	end switch

	return { c_exe, c_flags, l_exe, l_flags, obj_ext }
end function

--**
-- Write a CMake build file

procedure write_cmake()
	sequence settings = setup_build()
	integer fh = open(output_dir & file0 & ".cmake", "wb")



	close(fh)
end procedure

--**
-- Write a full Makefile

procedure write_makefile_full()
	sequence settings = setup_build()
	integer fh = open(output_dir & file0 & ".mak", "wb")



	close(fh)
end procedure

--**
-- Write a partial Makefile

procedure write_makefile()
	sequence settings = setup_build()
	integer fh = open(output_dir & file0 & ".mak", "wb")



	close(fh)
end procedure

--**
-- Write an emake build file

procedure write_emake()
	sequence settings = setup_build()
	sequence fname = "emake"
	if TWINDOWS or TDOS then
		fname &= ".bat"
	end if

	printf(1, "Writing emake file %s%s\n", { output_dir, fname })

	integer fh = open(output_dir & fname, "wb")
	if fh = -1 then
		CompileErr("Couldn't open " & output_dir & fname & " for writing")
	end if

	if compiler_type != COMPILER_GCC then
		puts(fh, "@echo off" & HOSTNL)
		puts(fh, "if not exist " & file0 & ".c goto nofiles" & HOSTNL)
	end if

	switch compiler_type do
		case COMPILER_DJGPP then
			puts(fh, "echo Compiling with DJGPP" & HOSTNL)
		case COMPILER_GCC then
			puts(fh, "echo Compiling with GCC" & HOSTNL)
		case COMPILER_LCC then
			puts(fh, "echo Compiling with LCC" & HOSTNL)
		case COMPILER_WATCOM then
			puts(fh, "echo Compiling with Watcom" & HOSTNL)
	end switch

	for i = 1 to length(generated_files) do
		if generated_files[i][$] = 'c' then
			printf(fh, "echo Compiling %s" & HOSTNL, { generated_files[i] })
			printf(fh, "%s %s %s" & HOSTNL, { settings[SETUP_CEXE], settings[SETUP_CFLAGS],
				generated_files[i] })
		end if
	end for

	printf(fh, "echo Linking %s" & HOSTNL, { file0 })
	printf(fh, "%s %s ", { settings[SETUP_LEXE], settings[SETUP_LFLAGS] })

	for i = 1 to length(generated_files) do
		if generated_files[i][$] != 'c' then
			continue
		end if

		if compiler_type = COMPILER_WATCOM or compiler_type = COMPILER_LCC then
			puts(fh, " FILE ")
		end if

		printf(fh, " %s.%s ", { filebase(generated_files[i]), settings[SETUP_OBJ_EXT] })
	end for

	if length(user_library) then
		if compiler_type = COMPILER_WATCOM or compiler_type = COMPILER_LCC then
			puts(fh, " FILE ")
		end if

		puts(fh, user_library)
	else
		if compiler_type = COMPILER_WATCOM or compiler_type = COMPILER_LCC then
			puts(fh, " FILE ")
		end if

		puts(fh, get_eudir() & "\\bin\\eu")
	end if

	if TDOS then
		puts(fh, "d")
	end if

	if TUNIX or compiler_type = COMPILER_GCC or compiler_type = COMPILER_DJGPP then
		puts(fh, ".a")
	else
		puts(fh, ".lib")
	end if

	if compiler_type = COMPILER_WATCOM then
		puts(fh, " LIBRARY ws2_32 ")
		printf(fh, " NAME %s.exe", { file0 })
	end if

	puts(fh, HOSTNL)

	if compiler_type = COMPILER_GCC then
		printf(fh, "# TODO: check for executable, jump to done" & HOSTNL, {})
	else
		printf(fh, "if not exist %s.exe goto done" & HOSTNL, { file0 })
	end if

	printf(fh, "echo You can now execute %s", { file0 })
	if TWINDOWS or TDOS then
		puts(fh, ".exe")
	end if
	puts(fh, HOSTNL)

	if not keep then
		for i = 1 to length(generated_files) do
			if TWINDOWS or TDOS then
				puts(fh, "del ")
			else
				puts(fh, "rm ")
			end if

			puts(fh, generated_files[i] & HOSTNL)
		end for
	end if

	if compiler_type != COMPILER_GCC then
		puts(fh, ":done" & HOSTNL)
	end if

	close(fh)

	ifdef UNIX then
		if TUNIX then
			system("chmod +x emake", 2)
		end if
	end ifdef
end procedure

--**
-- Call's a write_BUILDSYS procedure based on the compiler setting enum
--
-- See Also:
--   [[:build_system_type]], [[:BUILD_NONE]], [[:BUILD_CMAKE]],
--   [[:BUILD_MAKEFILE_FULL]], [[:BUILD_MAKEFILE]], [[:BUILD_EMAKE]]

export procedure write_buildfile()
	/*
	switch build_system do
		case BUILD_CMAKE then
			write_cmake()

		case BUILD_MAKEFILE_FULL then
			write_makefile_full()

		case BUILD_MAKEFILE then
			write_makefile()

		case BUILD_EMAKE then
			write_emake()

		case else
			CompileErr("Unknown build file type")
	end switch
	*/

	if build_system_type = BUILD_CMAKE then
		write_cmake()
	elsif build_system_type = BUILD_MAKEFILE_FULL then
		write_makefile_full()
	elsif build_system_type = BUILD_MAKEFILE then
		write_makefile()
	elsif build_system_type = BUILD_EMAKE then
		write_emake()
	else
		CompileErr("Unknown build file type")
	end if
end procedure
