-- (c) Copyright - See License.txt

ifdef ETYPE_CHECK then
with type_check
elsedef
without type_check
end ifdef

include std/filesys.e
include std/text.e

include c_decl.e
include c_out.e
include error.e
include global.e
include platform.e
include reswords.e
include msgtext.e

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
	BUILD_DIRECT

--**
-- Build system type. This defaults to the BUILD_DIRECT

export integer build_system_type = BUILD_DIRECT

--**
-- Known/Supported compiler types
export enum
	COMPILER_UNKNOWN = 0,
	COMPILER_GCC,
	COMPILER_WATCOM

--**
-- Compiler type flag for this invocation
export integer compiler_type = COMPILER_UNKNOWN

--**
-- Compiler directory (only used for a few compilers)
export sequence compiler_dir = ""

--**
-- Resulting executable name
export sequence exe_name = ""

--**
-- Maximum C file size before splitting the file into multiple chunks

export integer max_cfile_size = 100_000

--**
-- Optional flags to pass to the compiler

export sequence cflags = ""

--**
-- Optional flags to pass to the linker

export sequence lflags = ""

enum SETUP_CEXE, SETUP_CFLAGS, SETUP_LEXE, SETUP_LFLAGS, SETUP_OBJ_EXT, SETUP_EXE_EXT,
	SETUP_LFLAGS_BEGIN

--**
-- Setup the build environment. This includes things such as the
-- compiler/linker executable, c flags, linker flags, debug settings,
-- etc...

function setup_build()
	sequence c_exe   = "", c_flags = "", l_exe   = "", l_flags = "", obj_ext = "",
		exe_ext = "", l_flags_begin = ""

	if length(user_library) = 0 then
		if TUNIX or compiler_type = COMPILER_GCC then
			ifdef UNIX then
				sequence eudir = get_eudir()
				if match( "/share/euphoria", eudir ) then
					-- EUDIR probably not set, look in /usr/local/lib or /usr/lib
					if file_exists( "/usr/lib/eu.a" ) then
						user_library = "/usr/lib/eu.a"
						
					elsif file_exists( "/usr/local/lib/eu.a" ) then
						user_library = "/usr/local/lib/eu.a"
					
					else
						-- It's not in the 'standard' location, so try EUDIR
						user_library = eudir & "/bin/eu.a"
					end if
				else
					user_library = eudir & "/bin/eu.a"
				end if
			elsedef
				user_library = get_eudir() & "/bin/eu.a"
			end ifdef
		else
			user_library = get_eudir() & "\\bin\\eu"
			user_library &= ".lib"
		end if
	end if

	if TWINDOWS then
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
				c_flags &= " -fPIC "
		   	end if

			c_flags &= sprintf(" -c -w -fsigned-char -O2 -m32 -I%s -ffast-math", 
				{ get_eudir()  })

			if TWINDOWS then
				c_flags &= " -mno-cygwin"
				if not con_option then
					c_flags &= " -mwindows"
				end if
			end if

			l_flags = user_library

			if dll_option then
				l_flags &= " -shared "
			end if

			if TLINUX then
				l_flags &= " -ldl -lm"
			elsif TOSX then
				l_flags &= " -lresolv"
			elsif TSUNOS then
				l_flags &= " -lsocket -lresolv -lnsl"
			elsif TWINDOWS then
				l_flags &= " -lws2_32"
			end if

		case COMPILER_WATCOM then
			c_exe = "wcc386"
			l_exe = "wlink"
			obj_ext = "obj"

			if debug_option then
				c_flags = " /d3"
				l_flags_begin &= " DEBUG ALL "
			end if

			l_flags &= sprintf(" OPTION STACK=%d ", { total_stack_size })
			l_flags &= sprintf(" COMMIT STACK=%d ", { total_stack_size })
			l_flags &= " OPTION QUIET OPTION ELIMINATE OPTION CASEEXACT"

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

		case else
			CompileErr(43)
	end switch
	
	if length(cflags) then
		c_flags = cflags
	end if
	
	if length(lflags) then
		l_flags = lflags
		l_flags_begin = ""
	end if
	
	return { c_exe, c_flags, l_exe, l_flags, obj_ext, exe_ext, l_flags_begin }
end function

--**
-- Ensure exe_name contains data, if not copy file0

procedure ensure_exename(sequence ext)
	if length(exe_name) = 0 then
		exe_name = file0 & ext
	end if
end procedure

--**
-- Write a objlink.lnk file for Watcom

procedure write_objlink_file()
	sequence settings = setup_build()
	integer fh = open(output_dir & file0 & ".lnk", "wb")

	ensure_exename(settings[SETUP_EXE_EXT])

	if length(settings[SETUP_LFLAGS_BEGIN]) > 0 then
		puts(fh, settings[SETUP_LFLAGS_BEGIN] & HOSTNL)
	end if

	for i = 1 to length(generated_files) do
		if match(".o", generated_files[i]) then
			if compiler_type = COMPILER_WATCOM then
				puts(fh, "FILE ")
			end if

			puts(fh, generated_files[i] & HOSTNL)
		end if
	end for

	if compiler_type = COMPILER_WATCOM then
		printf(fh, "NAME %s" & HOSTNL, { exe_name })
	end if

	puts(fh, trim(settings[SETUP_LFLAGS] & HOSTNL))

	if compiler_type = COMPILER_WATCOM and dll_option then
		puts(fh, HOSTNL)

		object s = SymTab[TopLevelSub][S_NEXT]
		while s do
			if eu:find(SymTab[s][S_TOKEN], RTN_TOKS) then
				if is_exported( s ) then
					printf(fh, "EXPORT %s='__%d%s@%d'" & HOSTNL,
						   {SymTab[s][S_NAME], SymTab[s][S_FILE_NO], 
							SymTab[s][S_NAME], SymTab[s][S_NUM_ARGS] * 4})
				end if
			end if
			s = SymTab[s][S_NEXT]
		end while
	end if

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
	puts(fh, " )" & HOSTNL & HOSTNL)

	printf(fh, "SET( %s_OBJECTS", { upper(file0) })
	for i = 1 to length(generated_files) do
		if match(".o", generated_files[i]) then
			puts(fh, " " & generated_files[i])
		end if
	end for
	puts(fh, " )" & HOSTNL & HOSTNL)

	printf(fh, "SET( %s_GENERATED_FILES", { upper(file0) })
	for i = 1 to length(generated_files) do
		puts(fh, " " & generated_files[i])
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

	printf(fh, "%s_GENERATED_FILES = ", { upper(file0) })
	for i = 1 to length(generated_files) do
		puts(fh, " " & generated_files[i])
	end for
	puts(fh, HOSTNL)
end procedure

--**
-- Write a full Makefile

procedure write_makefile_full()
	sequence settings = setup_build()

	ensure_exename(settings[SETUP_EXE_EXT])

	integer fh = open(output_dir & file0 & ".mak", "wb")

	printf(fh, "CC     = %s" & HOSTNL, { settings[SETUP_CEXE] })
	printf(fh, "CFLAGS = %s" & HOSTNL, { settings[SETUP_CFLAGS] })
	printf(fh, "LINKER = %s" & HOSTNL, { settings[SETUP_LEXE] })

	if compiler_type = COMPILER_GCC and not TWINDOWS then
		printf(fh, "LFLAGS = %s" & HOSTNL, { settings[SETUP_LFLAGS] })
	else
		write_objlink_file()
	end if

	write_makefile_srcobj_list(fh)
	puts(fh, HOSTNL)

	if compiler_type = COMPILER_WATCOM then
		printf(fh, "%s: $(%s_OBJECTS)" & HOSTNL, { exe_name, upper(file0) })
		printf(fh, "\t$(LINKER) @%s.lnk" & HOSTNL, { file0 })
		puts(fh, HOSTNL)
		printf(fh, "%s-clean: .SYMBOLIC" & HOSTNL, { file0 })
		for i = 1 to length(generated_files) do
			if match(".o", generated_files[i]) then
				printf(fh, "\tdel %s" & HOSTNL, { generated_files[i] })
			end if
		end for
		puts(fh, HOSTNL)
		printf(fh, "%s-clean-all: .SYMBOLIC" & HOSTNL, { file0 })
		printf(fh, "\tdel %s" & HOSTNL, { exe_name })
		for i = 1 to length(generated_files) do
			printf(fh, "\tdel %s" & HOSTNL, { generated_files[i] })
		end for
		puts(fh, HOSTNL)
		puts(fh, ".c.obj: .autodepend" & HOSTNL)
		puts(fh, "\t$(CC) $(CFLAGS) $<" & HOSTNL)
		puts(fh, HOSTNL)

	else
		printf(fh, "%s: $(%s_OBJECTS)" & HOSTNL, { exe_name, upper(file0) })
		printf(fh, "\t$(LINKER) -o %s%s $(%s_OBJECTS) $(LFLAGS)" & HOSTNL, {
			file0, settings[SETUP_EXE_EXT], upper(file0) })
		puts(fh, HOSTNL)
		printf(fh, ".PHONY: %s-clean %s-clean-all" & HOSTNL, { file0, file0 })
		puts(fh, HOSTNL)
		printf(fh, "%s-clean:" & HOSTNL, { file0 })
		printf(fh, "\trm -rf $(%s_OBJECTS)" & HOSTNL, { upper(file0) })
		puts(fh, HOSTNL)
		printf(fh, "%s-clean-all: %s-clean" & HOSTNL, { file0, file0 })
		printf(fh, "\trm -rf $(%s_SOURCES) %s" & HOSTNL, { upper(file0), exe_name })
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

	ensure_exename(settings[SETUP_EXE_EXT])

	if TWINDOWS then
		fname &= ".bat"
	end if

	if not silent then
		ShowMsg(1, 162, { output_dir, fname })
	end if

	integer fh = open(output_dir & fname, "wb")
	if fh = -1 then
		CompileErr(45, {output_dir, fname})
	end if

	if compiler_type != COMPILER_GCC then
		puts(fh, "@echo off" & HOSTNL)
		puts(fh, "if not exist " & file0 & ".c goto nofiles" & HOSTNL)
	end if

	switch compiler_type do
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

	printf(fh, "echo Linking 100%%%% %s" & HOSTNL, { exe_name })
	puts(fh, settings[SETUP_LEXE])

	switch compiler_type do
		case COMPILER_WATCOM then
			printf(fh, " @%s.lnk" & HOSTNL, { file0 })

		case else
			printf(fh, " -o %s ", { exe_name })
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
		printf(fh, "if not exist %s goto done" & HOSTNL, { exe_name })
	end if

	printf(fh, "echo You can now use %s" & HOSTNL, { exe_name })

	if not keep then
		for i = 1 to length(generated_files) do
			if TWINDOWS then
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
-- Build the translated code directly from this process

procedure build_direct()
	sequence cmd, objs = "", settings = setup_build(), cwd = current_dir()
	integer status

	ensure_exename(settings[SETUP_EXE_EXT])

	switch compiler_type do
		case COMPILER_GCC then
			if not silent then
				ShowMsg(1, 176, {"GCC"})
			end if

		case COMPILER_WATCOM then
			write_objlink_file()

			if not silent then
				ShowMsg(1, 176, {"Watcom"})
			end if
	end switch

	if sequence(output_dir) and length(output_dir) > 0 then
		chdir(output_dir)
	end if

	for i = 1 to length(generated_files) do
		if generated_files[i][$] = 'c' then
			cmd = sprintf("%s %s %s", { settings[SETUP_CEXE], settings[SETUP_CFLAGS],
				generated_files[i] })

			if not silent then
				atom pdone = 100 * (i / length(generated_files))
				if not verbose then
					ShowMsg(1, 163, { pdone, generated_files[i] })
				else
					ShowMsg(1, 163, { pdone, cmd })
				end if
					
			end if

			status = system_exec(cmd, 0)
			if status != 0 then
				ShowMsg(2, 164, { generated_files[i] })
				ShowMsg(2, 165, { status, cmd })
				abort(1)
			end if
		elsif match(".o", generated_files[i]) then
			objs &= " " & generated_files[i]
		end if
	end for

	switch compiler_type do
		case COMPILER_WATCOM then
			cmd = sprintf("%s @%s.lnk", { settings[SETUP_LEXE], file0 })

		case COMPILER_GCC then
			cmd = sprintf("%s -o %s %s %s", { settings[SETUP_LEXE], exe_name, objs, settings[SETUP_LFLAGS] })

		case else
			ShowMsg(2, 167, { compiler_type })
			abort(1)
	end switch

	if not silent then
		if not verbose then
			ShowMsg(1, 166, { exe_name })
		else
			ShowMsg(1, 166, { cmd })
		end if
	end if

	status = system_exec(cmd, 0)
	if status != 0 then
		ShowMsg(2, 168, { exe_name })
		ShowMsg(2, 169, { status, cmd })
		abort(1)
	end if

	if keep = 0 then
		for i = 1 to length(generated_files) do
			delete_file(generated_files[i])
		end for
	end if

	chdir(cwd)
end procedure

--**
-- Call's a write_BUILDSYS procedure based on the compiler setting enum
--
-- See Also:
--   [[:build_system_type]], [[:BUILD_NONE]], [[:BUILD_CMAKE]],
--   [[:BUILD_MAKEFILE_FULL]], [[:BUILD_MAKEFILE]], [[:BUILD_EMAKE]]

export procedure write_buildfile()
	switch build_system_type do
		case BUILD_CMAKE then
			write_cmake()

			if not silent then
				ShowMsg(1, 170, { cfile_count + 2 })
				ShowMsg(1, 171,	{ file0 })
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

				ShowMsg(1, 170, { cfile_count + 2 })
				ShowMsg(1, 172, { make_command, file0 })
			end if

		case BUILD_MAKEFILE then
			write_makefile()

			if not silent then
				ShowMsg(1, 170, { cfile_count + 2 })
				ShowMsg(1, 173, { file0 })
			end if

		case BUILD_EMAKE then
			write_emake()

			if not silent then
				sequence fname = "emake"
				if TWINDOWS then
					fname &= ".bat"
				end if

				ShowMsg(1, 170, { cfile_count + 2 })
				ShowMsg(1, 174, { fname })
			end if

		case BUILD_DIRECT then
			build_direct()

			if not silent then
				sequence settings = setup_build()
				ShowMsg(1, 175, { exe_name })
			end if

		case BUILD_NONE then
			if not silent then
				ShowMsg(1, 170, { cfile_count + 2 })
			end if

			-- Do not write any build file

		case else
			CompileErr(151)
	end switch
end procedure
