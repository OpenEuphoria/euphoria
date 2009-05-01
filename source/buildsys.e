--
-- Copyright (c) 2009 by The OpenEuphoria Group.
--

include std/filesys.e
include std/text.e

include c_decl.e
include c_out.e
include error.e
include global.e
include platform.e

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
	BUILD_CMAKE,

	--**
	-- build directly from the translator
	BUILD_BUILD

--**
-- Build system type. This defaults to the BUILD_EMAKE process for
-- backward compatability.

export integer build_system_type = BUILD_EMAKE

export enum
	COMPILER_UNKNOWN = 0,
	COMPILER_GCC,
	COMPILER_DJGPP,
	COMPILER_WATCOM

export integer compiler_type = COMPILER_UNKNOWN
export sequence compiler_dir = ""

enum SETUP_CEXE, SETUP_CFLAGS, SETUP_LEXE, SETUP_LFLAGS, SETUP_OBJ_EXT, SETUP_EXE_EXT

--**
-- Setup the build environment. This includes things such as the
-- compiler/linker executable, c flags, linker flags, debug settings,
-- etc...

function setup_build()
	sequence c_exe   = "", c_flags = "", l_exe   = "", l_flags = "", obj_ext = "", exe_ext = ""

	if length(user_library) = 0 then
		if TUNIX or compiler_type = COMPILER_GCC or compiler_type = COMPILER_DJGPP then
			user_library = get_eudir() & "/bin/eu.a"
		else
			user_library = get_eudir() & "\\bin\\eu"
			if TDOS then
				user_library &= "d"
			end if
			user_library &= ".lib"
		end if
	end if

	if TDOS or TWINDOWS then
		if dll_option then
			exe_ext = ".dll"
		else
			exe_ext = ".exe"
		end if
	elsif TOSX then
		if dll_option then
			exe_ext = ".dylib"
		end if
	else
		if dll_option then
			exe_ext = ".so"
		end if
	end if

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

			l_flags = user_library

			if TLINUX then
				l_flags &= " -ldl -lm"
			elsif TOSX then
				l_flags &= " -lresolv"
			elsif TSUNOS then
				l_flags &= " -lsocket -lresolv -lnsl"
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

			l_flags = user_library

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
					if con_option then
						-- SYSTEM NT *MUST* come first, otherwise memory dump
						l_flags = " SYSTEM NT" & l_flags
					else
						l_flags = " SYSTEM NT_WIN RUNTIME WINDOWS=4.0" & l_flags
					end if
				end if

				l_flags &= sprintf(" FILE %s LIBRARY ws2_32", { user_library })
			end if

		case else
			CompileErr("Compiler is unknown")
	end switch

	return { c_exe, c_flags, l_exe, l_flags, obj_ext, exe_ext }
end function

--**
-- Write a objlink.lnk file for Watcom

procedure write_objlink_file()
	sequence settings = setup_build()
	integer fh = open(output_dir & file0 & ".lnk", "wb")

	for i = 1 to length(generated_files) do
		if match(".o", generated_files[i]) then
			if compiler_type = COMPILER_WATCOM then
				puts(fh, "FILE ")
			end if

			puts(fh, generated_files[i] & HOSTNL)
		end if
	end for

	if compiler_type = COMPILER_WATCOM then
		printf(fh, "NAME %s.exe" & HOSTNL, { file0 })
	end if

	puts(fh, trim(settings[SETUP_LFLAGS] & HOSTNL))

	close(fh)

	generated_files = append(generated_files, file0 & ".lnk")
end procedure

--**
-- Write a CMake build file

procedure write_cmake()
	sequence settings = setup_build()
	integer fh = open(output_dir & file0 & ".cmake", "wb")

	printf(fh, "SET( %s_SOURCES", { upper(file0) })
	for i = 1 to length(generated_files) do
		if generated_files[i][$] = 'c' then
			puts(fh, " " & generated_files[i])
		end if
	end for
	puts(fh, " )" & HOSTNL)

	printf(fh, "SET( %s_OBJECTS", { upper(file0) })
	for i = 1 to length(generated_files) do
		if match(".o", generated_files[i]) then
			puts(fh, " " & generated_files[i])
		end if
	end for
	puts(fh, " )" & HOSTNL)

	close(fh)
end procedure


procedure write_makefile_srcobj_list(integer fh)
	printf(fh, "%s_SOURCES =", { upper(file0) })
	for i = 1 to length(generated_files) do
		if generated_files[i][$] = 'c' then
			puts(fh, " " & generated_files[i])
		end if
	end for
	puts(fh, HOSTNL)

	printf(fh, "%s_OBJECTS =", { upper(file0) })
	for i = 1 to length(generated_files) do
		if match(".o", generated_files[i]) then
			puts(fh, " " & generated_files[i])
		end if
	end for
	puts(fh, HOSTNL)
end procedure

--**
-- Write a full Makefile

procedure write_makefile_full()
	sequence settings = setup_build()

	write_objlink_file()

	integer fh = open(output_dir & file0 & ".mak", "wb")

	printf(fh, "CC     = %s" & HOSTNL, { settings[SETUP_CEXE] })
	printf(fh, "CFLAGS = %s" & HOSTNL, { settings[SETUP_CFLAGS] })
	printf(fh, "LINKER = %s" & HOSTNL, { settings[SETUP_LEXE] })
	puts(fh, HOSTNL)

	write_makefile_srcobj_list(fh)
	puts(fh, HOSTNL)

	if compiler_type = COMPILER_WATCOM then
		printf(fh, "%s%s: $(%s_OBJECTS)" & HOSTNL, { file0, settings[SETUP_EXE_EXT], upper(file0) })
		printf(fh, "\t$(LINKER) @%s.lnk" & HOSTNL, { file0 })
		puts(fh, HOSTNL)
		printf(fh, "%s-clean: .SYMBOLIC" & HOSTNL, { file0 })
		for i = 1 to length(generated_files) do
			if match(".o", generated_files[i]) then
				printf(fh, "\tdel /q %s" & HOSTNL, { generated_files[i] })
			end if
		end for
		puts(fh, HOSTNL)
		printf(fh, "%s-clean-all: .SYMBOLIC" & HOSTNL, { file0, file0 })
		printf(fh, "\tdel /q %s%s" & HOSTNL, { file0, settings[SETUP_EXE_EXT] })
		for i = 1 to length(generated_files) do
			printf(fh, "\tdel /q %s" & HOSTNL, { generated_files[i] })
		end for
		puts(fh, HOSTNL)
		puts(fh, ".c.obj: .autodepend" & HOSTNL)
		puts(fh, "\t$(CC) $(CFLAGS) $<" & HOSTNL)
		puts(fh, HOSTNL)

	else
		printf(fh, "%s%s: $(%s_OBJECTS)" & HOSTNL, { file0, settings[SETUP_EXE_EXT], upper(file0) })
		printf(fh, "\t$(LINKER) -o %s%s $(%s_OBJECTS) $(LFLAGS)" & HOSTNL, {
			file0, settings[SETUP_EXE_EXT], upper(file0) })
		puts(fh, HOSTNL)
		printf(fh, ".PHONY: %s-clean %s-clean-all" & HOSTNL, { file0, file0 })
		puts(fh, HOSTNL)
		printf(fh, "%s-clean:" & HOSTNL, { file0 })
		printf(fh, "\trm -rf $(%s_OBJECTS)" & HOSTNL, { upper(file0) })
		puts(fh, HOSTNL)
		printf(fh, "%s-clean-all: %s-clean" & HOSTNL, { file0, file0 })
		printf(fh, "\trm -rf $(%s_SOURCES) %s%s" & HOSTNL, { upper(file0), file0, settings[SETUP_EXE_EXT] })
		puts(fh, HOSTNL)
		puts(fh, "%.o: %.c" & HOSTNL)
		puts(fh, "\t$(CC) $(CFLAGS) $*.c -o $*.o" & HOSTNL)
		puts(fh, HOSTNL)
	end if

	close(fh)
end procedure

--**
-- Write a partial Makefile

procedure write_makefile()
	sequence settings = setup_build()
	integer fh = open(output_dir & file0 & ".mak", "wb")

	write_makefile_srcobj_list(fh)

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
			write_objlink_file()
			puts(fh, "echo Compiling with DJGPP" & HOSTNL)
		case COMPILER_GCC then
			puts(fh, "echo Compiling with GCC" & HOSTNL)
		case COMPILER_WATCOM then
			write_objlink_file()
			puts(fh, "echo Compiling with Watcom" & HOSTNL)
	end switch

	for i = 1 to length(generated_files) do
		if generated_files[i][$] = 'c' then
			printf(fh, "echo Compiling %2.0f%%%% %s" & HOSTNL, { 100 * (i / length(generated_files)),
				generated_files[i] })
			printf(fh, "%s %s %s" & HOSTNL, { settings[SETUP_CEXE], settings[SETUP_CFLAGS],
				generated_files[i] })
		end if
	end for

	printf(fh, "echo Linking 100%%%% %s" & HOSTNL, { file0 })
	puts(fh, settings[SETUP_LEXE])

	switch compiler_type do
		case COMPILER_WATCOM then
			printf(fh, " @%s.lnk" & HOSTNL, { file0 })

		case COMPILER_DJGPP then
			printf(fh, " -o%s.exe @%s.lnk" & HOSTNL, { file0, file0 })

		case else
			printf(fh, " -o %s%s ", { file0, settings[SETUP_EXE_EXT] })
			for i = 1 to length(generated_files) do
				if generated_files[i][$] != 'c' then
					continue
				end if


				printf(fh, " %s.%s ", { filebase(generated_files[i]), settings[SETUP_OBJ_EXT] })
			end for

			puts(fh, " " & settings[SETUP_LFLAGS] & HOSTNL)
	end switch

	if compiler_type = COMPILER_GCC then
		printf(fh, "# TODO: check for executable, jump to done" & HOSTNL, {})
	else
		printf(fh, "if not exist %s%s goto done" & HOSTNL, { file0, settings[SETUP_EXE_EXT] })
	end if

	printf(fh, "echo You can now use %s", { file0 })
	puts(fh, settings[SETUP_EXE_EXT] & HOSTNL)

	if not keep then
		for i = 1 to length(generated_files) do
			if TWINDOWS or TDOS then
				puts(fh, "del /q ")
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
-- Build the translated code directly from this process

procedure build_build()
	sequence cmd, objs = "", settings = setup_build()
	integer status

	switch compiler_type do
		case COMPILER_DJGPP then
			write_objlink_file()
			puts(1, "Compiling with DJGPP\n")
		case COMPILER_GCC then
			puts(1, "Compiling with GCC\n")
		case COMPILER_WATCOM then
			write_objlink_file()
			puts(1, "Compiling with Watcom\n")
	end switch

	for i = 1 to length(generated_files) do
		if generated_files[i][$] = 'c' then
			printf(1, "Compiling %2.0f%% %s" & HOSTNL, { 100 * (i / length(generated_files)),
				generated_files[i] })
			cmd = sprintf("%s %s %s", { settings[SETUP_CEXE], settings[SETUP_CFLAGS],
				generated_files[i] })

			status = system_exec(cmd, 0)
			if status != 0 then
				printf(2, "Couldn't compile file '%s'\n", { generated_files[i] })
				printf(2, "Status: %d Command: %s\n", { status, cmd })
				abort(1)
			end if
		elsif match(".o", generated_files[i]) then
			objs &= " " & generated_files[i]
		end if
	end for

	printf(1, "Linking 100%% %s\n", { file0 })
	switch compiler_type do
		case COMPILER_WATCOM, COMPILER_DJGPP then
			cmd = sprintf("%s @%s.lnk", { settings[SETUP_LEXE], file0 })

		case COMPILER_GCC then
			cmd = sprintf("%s -o%s%s %s %s", { settings[SETUP_LEXE], file0, settings[SETUP_EXE_EXT],
				objs, settings[SETUP_LFLAGS] })

		case else
			printf(2, "Unknown compiler type: %d\n", { compiler_type })
			abort(1)
	end switch

	status = system_exec(cmd, 0)
	if status != 0 then
		printf(2, "Unable to link %s%s\n", { file0, settings[SETUP_EXE_EXT] })
		printf(2, "Status: %d Command: %s\n", { status, cmd })
		abort(1)
	end if

	if keep = 0 then
		for i = 1 to length(generated_files) do
			delete_file(generated_files[i])
		end for
	end if
end procedure

--**
-- Call's a write_BUILDSYS procedure based on the compiler setting enum
--
-- See Also:
--   [[:build_system_type]], [[:BUILD_NONE]], [[:BUILD_CMAKE]],
--   [[:BUILD_MAKEFILE_FULL]], [[:BUILD_MAKEFILE]], [[:BUILD_EMAKE]]

/*
	if not silent then
		screen_output(STDERR, sprintf("\n%d .c files were created.\n", cfile_count+2))
		if TUNIX then
			if dll_option then
				screen_output(STDERR, "To build your shared library, type: ./emake\n")
			else
				screen_output(STDERR, "To build your executable file, type: ./emake\n")
			end if
		else
			if dll_option then
				screen_output(STDERR, "To build your .dll file, type: emake\n")
			else
				screen_output(STDERR, "To build your .exe file, type: emake\n")
			end if
		end if
	end if
*/

export procedure write_buildfile()
	switch build_system_type do
		case BUILD_CMAKE then
			write_cmake()

			if not silent then
				printf(1, "\n%d.c files were created.\n", { cfile_count + 2 })
				printf(1, "To build your project, include %s.cmake into a parent CMake project\n", {})
			end if

		case BUILD_MAKEFILE_FULL then
			write_makefile_full()

			if not silent then
				sequence make_command
				if compiler_type = COMPILER_WATCOM then
					make_command = "wmake /f "
				else
					make_command = "make -f "
				end if

				printf(1, "\n%d.c files were created.\n", { cfile_count + 2 })
				printf(1, "To build your project, type %s%s.mak\n", { make_command, file0 })
			end if

		case BUILD_MAKEFILE then
			write_makefile()

			if not silent then
				printf(1, "\n%d.c files were created.\n", { cfile_count + 2 })
				printf(1, "To build your project, include %s.mak into a larger Makefile project\n",
					{ file0 })
			end if

		case BUILD_EMAKE then
			write_emake()

			if not silent then
				sequence fname = "emake"
				if TWINDOWS or TDOS then
					fname &= ".bat"
				end if

				printf(1, "\n%d.c files were created.\n", { cfile_count + 2 })
				printf(1, "To build your project, type %s\n", { fname })
			end if

		case BUILD_BUILD then
			build_build()

			sequence settings = setup_build()
			printf(1, "\nTo run your project, type %s%s\n", { file0, settings[SETUP_EXE_EXT] })

		case else
			CompileErr("Unknown build file type")
	end switch
end procedure
