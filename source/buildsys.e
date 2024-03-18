ifdef ETYPE_CHECK then
	with type_check
elsedef
	without type_check
end ifdef

include std/datetime.e
include std/dll.e
include std/filesys.e as filesys
include std/io.e
include std/regex.e as regex
include std/text.e
include std/hash.e
include std/search.e as search
include std/utils.e
include c_decl.e
include c_out.e
include error.e
include global.e
include platform.e
include reswords.e
include msgtext.e
include std/math.e as math

constant
	re_include = regex:new(`^[ ]*(public)*[ \t]*include[ \t]+([A-Za-z0-9_/.]+)`),
	inc_dirs = { "." } & include_paths(0)

function find_file(sequence fname)
	for i = 1 to length(inc_dirs) do
		if file_exists(inc_dirs[i] & "/" & fname) then
			return inc_dirs[i] & "/" & fname
		end if
	end for

	return 0
end function

function find_all_includes(sequence fname, sequence includes = {})
	sequence lines = read_lines(fname)

	for i = 1 to length(lines) do
		object m = regex:matches(re_include, lines[i])
		if sequence(m) then
			object full_fname = find_file(m[3])
			if sequence(full_fname) then
				if eu:find(full_fname, includes) = 0 then
					includes &= { full_fname }
					includes = find_all_includes(full_fname, includes)
				end if
			end if
		end if
	end for

	return includes
end function

export function quick_has_changed(sequence fname)
	object d1 = file_timestamp(output_dir & filebase(fname) & ".bld")

	if atom(d1) then
		return 1
	end if

	sequence all_files = append(find_all_includes(fname), fname)
	for i = 1 to length(all_files) do
		object d2 = file_timestamp(all_files[i])
		if atom(d2) then
			return 1
		end if
		if datetime:diff(d1, d2) > 0 then
			return 1
		end if
	end for

	return 0
end function

--****
-- = buildsys.e
--
-- Deals with writing files for various build systems:
--   * Makefile - full
--   * Makefile - partial (for inclusion into a parent Makefile)
--   * None
--

export enum
	--**
	-- No build system will be written (C/H files written only).

	BUILD_NONE = 0,

	--**
	-- Makefile containing only ##PRGNAME_SOURCES## and ##PRGNAME_OBJECTS##
	-- Makefile that is for inclusion into a parent Makefile.

	BUILD_MAKEFILE_PARTIAL,

	--**
	-- A full Makefile project suitable for building the resulting project
	-- entirely.

	BUILD_MAKEFILE_FULL,

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
-- Prefix for the compiler and other related binaries.
export sequence compiler_prefix = ""

--**
-- Compiler directory (only used for a few compilers)

export sequence compiler_dir = ""

--**
-- Resulting executable names
-- exe_name[D_NAME] is what we show to the user in error and warning messages
-- exe_name[D_ALTNAME] is what we show to the compiler in command scripts
-- both of these names open to the same data.
-- 
export sequence exe_name = repeat("", math:max(D_NAME&D_ALTNAME))

--**
-- Resource file to link into executable
-- rc_file[D_NAME] is the passed name
-- rc_file[D_ALTNAME] is what is passed to the command line tools
-- which is possibily a different form but will always point to the
-- same data as rc_file[D_NAME]
export sequence rc_file = repeat("", math:max(D_NAME&D_ALTNAME))

--**
-- Compiled resource file
-- res_file[D_NAME] is the passed name
-- res_file[D_ALTNAME] is what is passed to the command line tool
-- which is possibily a different form but will always point to the
-- same data as res_file[D_NAME]

export sequence res_file = rc_file

--**
-- Maximum C file size before splitting the file into multiple chunks

export integer max_cfile_size = 100_000

--**
-- Calculated value for detecting when c files have changed

atom cfile_check = 0

--**
-- Optional flags to pass to the compiler

export sequence cflags = ""

--**
-- Optional flags to append to default compiler options

export sequence extra_cflags = ""

--**
-- Optional flags to pass to the linker

export sequence lflags = ""

--**
-- Optional flags to append to default linker options

export sequence extra_lflags = ""

--**
-- Force the build of even up-to-date source files

export integer force_build = 0

--**
-- Output directory was a system generated name, remove when done

export integer remove_output_dir = 0

--**
-- Use the -mno-cygwin flag with MinGW.
export integer mno_cygwin = 0

enum SETUP_CEXE, SETUP_CFLAGS, SETUP_LEXE, SETUP_LFLAGS, SETUP_OBJ_EXT, SETUP_EXE_EXT,
	SETUP_LFLAGS_BEGIN, SETUP_RC_COMPILER, SETUP_RUNTIME_LIBRARY

--**
-- Calculate a checksum to be used for detecting changes to generated c files.
export procedure update_checksum( object raw_data )
	cfile_check = xor_bits(cfile_check, hash( raw_data, stdhash:HSIEH32))
end procedure

--**
-- Writes the checksum to the file and resets the checksum to zero.
export procedure write_checksum( integer file )
	printf( file, "\n// 0x%08x\n", cfile_check )
	cfile_check = 0
end procedure

-- searches for the file name needle in a list of files
-- returned by dir().  First a case-sensitive search and
-- then a case-insensitive search.  To handle the case when
-- we use case-sensitive file systems under WINDOWS
function find_file_element(sequence needle, sequence files)
	for j = 1 to length(files) do
		if equal(files[j][D_NAME],needle) then
			return j
		end if
	end for
	for j = 1 to length(files) do
		if equal(lower(files[j][D_NAME]),lower(needle)) then
			return j
		end if
	end for
	-- check to see if it is already a short name
	for j = 1 to length(files) do
		if equal(lower(files[j][D_ALTNAME]),lower(needle)) then
			return j
		end if
	end for
	return 0
end function

-- A pattern for valid file seperators
ifdef WINDOWS then
    constant slash_pattern = regex:new(`[\\/]`) 
elsedef
    constant slash_pattern = regex:new("/")
end ifdef
constant quote_pattern = regex:new("[\"\'`]")
constant space_pattern = regex:new(" ")
-- cannot use SLASHES here because
-- we need the colon to be left in the list.

-- Change paths and filenmames into values that do not have
-- any spaces.  In Windows this means to use the short-name.   
-- In UNIX, this should return the same path, but with spaces
-- preceeded with backslashes.
-- This is a necessary work-around for WATCOM C but any command line
-- but it could also be needed for any compiler and environment
-- that is using spaces and build_commandline() will not work 
-- in place of this.
--
-- Now, we will say that a folder is adjusted if it undergoes the
-- above transformation.  
--
-- An ancestor directory of a file or directory, is a either a parent of the 
-- the said file or a parent of another ancestor.
--
-- Return Value:
--
-- If the path passed in does exist, the entire passed parameter is
-- adjusted as described above.
--
-- If the path passed in doesn't exist but an ancestor directory does,
-- that ancestor is adjusted in the return value and the non-existent
-- version is left unchanged.
--
-- If the path passed in doesn't exist and the only ancestor directory that
-- does is a root directory, then his routine returns 0.
--
-- Examples:
--
-- Consider: 
-- <eucode>
--  x = adjust_for_command_line_passing(`C:\Program Files\Euphoria\winlib-70.1`)
-- </eucode>
--
-- Suppose 'C:\Program Files\Euphoria' exists but not
-- 'C:\Program Files\Euphoria\winlib-70.1'.  Now, winlib-70.1 contains no
-- no spaces.  x probably will be "C:\Progra~1\EUPHORIA\winlib-70.1".  This
-- string will allow access to the same as the passed path.
--
-- Suppose this is run on a Spanish distribution of Windows where 
-- 'C:\Program Files' does not exist.  x will be 0.
--
-- 
export function adjust_for_command_line_passing(sequence long_path)
-- UNIX hands things to programs as an array of strings
-- so all we need to do is protect it from the shell.  This should
-- just return what is passed in the UNIX case.
--
-- WINDOWS sends all parameters as one string so and programs have to 
-- split the command line string up itself.  So, we need this
-- for programs that do not use escape characters for spaces.
	integer slash
	if compiler_type = COMPILER_GCC then
		slash = '/'
	elsif compiler_type = COMPILER_WATCOM then
		slash = '\\'
	else
		slash = SLASH
	end if
	ifdef UNIX then
		return long_path
	elsifdef WINDOWS then
		long_path = regex:find_replace(quote_pattern, long_path, "")
		sequence longs = split( slash_pattern, long_path )
		if length(longs)=0 then
			return long_path
		end if
		sequence short_path = longs[1] & slash
		for i = 2 to length(longs) do
			object files = dir(short_path)
			integer file_location = 0
			if sequence(files) then
				file_location = find_file_element(longs[i], files)
			end if
			if file_location then
				if sequence(files[file_location][D_ALTNAME]) then
					short_path &= files[file_location][D_ALTNAME]
				else
					short_path &= files[file_location][D_NAME]
				end if
				short_path &= slash
			else
				if not eu:find(' ',longs[i]) then
					short_path &= longs[i] & slash
					continue
				end if
				return 0
			end if
		end for -- i
		if short_path[$] = slash then
			short_path = short_path[1..$-1]
		end if
		return short_path
	end ifdef
end function

function adjust_for_build_file(sequence long_path)
    object short_path = adjust_for_command_line_passing(long_path)
    if atom(short_path) then
    	return short_path
    end if
	if compiler_type = COMPILER_GCC and build_system_type != BUILD_DIRECT and TWINDOWS then
		return windows_to_mingw_path(short_path)
	else
		return short_path
	end if
end function

--**
-- Setup the build environment. This includes things such as the
-- compiler/linker executable, c flags, linker flags, debug settings,
-- etc...

function setup_build()
	sequence
		c_exe   = "",
		c_flags = "",
		l_exe   = "",
		l_flags = "",
		obj_ext = "",
		exe_ext = "",
		l_flags_begin = "",
		rc_comp = "",
		l_names,
		l_ext,
		t_slash

	if dll_option
	and length( user_pic_library ) > 0
	and not TWINDOWS then
		user_library = user_pic_library
	end if
	
	if length(user_library) = 0 then
		if debug_option then
			l_names = { "eudbg", "eu" }
		else
			l_names = { "eu", "eudbg" }
		end if

		-- We assume the platform the compiler will **build on** is the same
		-- as the platform the compiler will **build for*.
		if TUNIX or compiler_type = COMPILER_GCC then
			l_ext = "a"
			t_slash = "/"
			if dll_option and not TWINDOWS then
				for i = 1 to length( l_names ) do
					-- use the -fPIC compiled library
					l_names[i] &= "so"
				end for
			end if
		elsif TWINDOWS then
			l_ext = "lib"
			t_slash = "\\"
		end if

		object eudir = get_eucompiledir()
		if not file_exists(eudir) then
			printf(2,"Supplied directory \'%s\' is not a valid EUDIR\n",{get_eucompiledir()})
			abort(1)
		end if
		for tk = 1 to length(l_names) label "translation kind" do
			user_library = eudir & sprintf("%sbin%s%s.%s",{t_slash, t_slash, l_names[tk],l_ext})
			if TUNIX or compiler_type = COMPILER_GCC then
				ifdef UNIX then
					sequence locations = { "/usr/local/lib/%s.a", "/usr/lib/%s.a"}
					if match( "/share/euphoria", eudir ) then
						-- EUDIR probably not set, look in /usr/local/lib or /usr/lib
						for i = 1 to length(locations) do
							if file_exists( sprintf(locations[i],{l_names[tk]}) ) then
								user_library = sprintf(locations[i],{l_names[tk]})
								exit "translation kind"
							end if
						end for
					end if
				end ifdef -- The translation or interpretation of the translator
				          -- is done on a UNIX computer
			end if -- compiling for UNIX and/or with GCC
			if file_exists(user_library) then
				exit "translation kind"
			end if
		end for -- tk
	end if -- user_library = 0
	user_library = adjust_for_build_file(user_library)
	
	if TWINDOWS then
		if compiler_type = COMPILER_WATCOM then
			c_flags &= " /dEWINDOWS"
		else
			c_flags &= " -DEWINDOWS"
		end if
		
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

	object compile_dir = get_eucompiledir()
	if not file_exists(compile_dir) then
		printf(2,"Couldn't get include directory '%s'",{get_eucompiledir()})
		abort(1)
	end if
	
	integer bits = 32
	if TX86_64 then
		bits = 64
	end if
	
	
	switch compiler_type do
		case COMPILER_GCC then
			c_exe = compiler_prefix & "gcc"
			l_exe = compiler_prefix & "gcc"
			obj_ext = "o"

			sequence m_flag = ""
			sequence ctl_flags = ""
			if not TARM then
				-- current gcc for ARM does not support -m32
				m_flag = sprintf( "-m%d", bits )
			end if
			
			if TWINDOWS then
				m_flag &= " -lws2_32"
			end if
			
			-- compiling object flags
			if debug_option then
				c_flags &= " -g3"
			else
				c_flags &= " -fomit-frame-pointer"
			end if

			if dll_option and not TWINDOWS then
				c_flags &= " -fPIC"
			end if
			
			
              c_flags &= sprintf(" -c -w -fsigned-char -O2 %s -I%s -ffast-math",
                      { iif(build_system_type!=BUILD_DIRECT, "", m_flag) , adjust_for_build_file(get_eucompiledir()) })
			
			if TWINDOWS and mno_cygwin then
				-- we must use this compile flag here to ensure that we load the MINGW include
				-- files when compiling under a cygwin environment.
				c_flags &= " -mno-cygwin"
			end if

			if dll_option then
				l_flags &= " -shared "
			end if
			
			if build_system_type != BUILD_DIRECT then
				l_flags = sprintf( " $(RUNTIME_LIBRARY)", {})
			else
				l_flags = sprintf( " %s %s",
								   { adjust_for_command_line_passing( user_library ), m_flag })
			end if

			if build_system_type = BUILD_DIRECT then
			  -- in the case of full makefiles these will be
			  -- setup after translation via a -- configure script.
              if TLINUX then
                  l_flags &= " -ldl -lm -lpthread"
              elsif TBSD then
                  l_flags &= " -lm -lpthread"
              elsif TOSX then
                  l_flags &= " -lresolv"
              elsif TWINDOWS then
                  if mno_cygwin then
                      -- we must use this option to avoid linking to the cygwin dll.
                      l_flags &= " -mno-cygwin"
                  end if				
                  if not con_option then
                      -- we must use this flag to prevent a new console from appearing
                      -- when running this program from explorer (the GUI)
                      l_flags &= " -mwindows"
                  end if
              end if
			
			end if
			
			-- input/output
			rc_comp = compiler_prefix & "windres -DSRCDIR=\"" & adjust_for_build_file(current_dir()) & "\" [1] -O coff -o [2]"
			
		case COMPILER_WATCOM then
			c_exe = compiler_prefix & "wcc386"
			l_exe = compiler_prefix & "wlink"
			obj_ext = "obj"

			if debug_option then
				c_flags = " /d3"
				l_flags_begin &= " DEBUG ALL "
			end if

			l_flags &= sprintf(" OPTION STACK=%d ", { total_stack_size })
			l_flags &= sprintf(" COMMIT STACK=%d ", { total_stack_size })
			l_flags &= " OPTION QUIET OPTION ELIMINATE OPTION CASEEXACT"

			if dll_option then
				c_flags &= " /bd /bt=nt /mf /w0 /zq /j /zp4 /fp5 /fpi87 /5r /otimra /s /I" & adjust_for_build_file(compile_dir) 
				l_flags &= " SYSTEM NT_DLL initinstance terminstance"
			else
				c_flags &= " /bt=nt /mf /w0 /zq /j /zp4 /fp5 /fpi87 /5r /otimra /s /I" & adjust_for_build_file(compile_dir)
				if con_option then
					-- SYSTEM NT *MUST* come first, otherwise memory dump
					l_flags = " SYSTEM NT" & l_flags
				else
					l_flags = " SYSTEM NT_WIN RUNTIME WINDOWS=4.0" & l_flags
				end if
			end if

			l_flags &= sprintf(" FILE %s", { (user_library) })
			
			
			-- resource file, executable file
			rc_comp = compiler_prefix &"wrc -DSRCDIR=\"" & adjust_for_build_file(current_dir()) & "\" -q -fo=[2] -ad [1] [3]"
		case else
			CompileErr(COMPILER_IS_UNKNOWN)
	end switch

	if length(cflags) then
		-- if the user supplied flags, use those instead
		c_flags = cflags
	end if

	if length(extra_cflags) then
		c_flags &= " " & extra_cflags
	end if

	if length(lflags) then
		l_flags = lflags
		l_flags_begin = ""
	end if

	if length(extra_lflags) then
		l_flags &= " " & extra_lflags
	end if

	return { 
		c_exe, c_flags, l_exe, l_flags, obj_ext, exe_ext, l_flags_begin, rc_comp, user_library
	}
end function

--**
-- Ensure exe_name[D_ALTNAME] contains data, if not copy file0

procedure ensure_exename(sequence ext)
	if length(exe_name[D_ALTNAME]) = 0 then
		exe_name[D_NAME] = current_dir() & SLASH & file0 & ext
		exe_name[D_ALTNAME] = adjust_for_command_line_passing(exe_name[D_NAME])
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
		printf(fh, "NAME '%s'" & HOSTNL, { exe_name[D_ALTNAME] })
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


constant CONTCHAR = iif(compiler_type = COMPILER_WATCOM, '&', '\\')
procedure write_makefile_srcobj_list(integer fh)
	printf(fh, "%s_SOURCES =", { upper(file0) })
	for i = 1 to length(generated_files) do
		if generated_files[i][$] = 'c' then
			if i > 1 then
				printf(fh, " %s%s\t", { CONTCHAR, HOSTNL }  )
			end if
			puts(fh, " " & generated_files[i])
		end if
	end for
	puts(fh, HOSTNL)

	printf(fh, "%s_OBJECTS =", { upper(file0) })
	integer file_count = 0
	for i = 1 to length(generated_files) do
		if match(".o", generated_files[i]) then
			if file_count then
				printf(fh, " %s%s\t", { CONTCHAR, HOSTNL }  )
			end if
			file_count += 1
			puts(fh, " " & generated_files[i])
		end if
	end for
	puts(fh, HOSTNL)

	printf(fh, "%s_GENERATED_FILES = ", { upper(file0) })
	for i = 1 to length(generated_files) do
		if i > 1 then
			printf(fh, " %s%s\t", { CONTCHAR, HOSTNL }  )
		end if
		puts(fh, " " & generated_files[i])
	end for
	puts(fh, HOSTNL)
end procedure

--** 
-- Convert to Mingw/Cygwin style from Windows style path
-- Windows OS accepts forward slashes as back-slashes but
-- be careful not to pass this into file_exists() and friends
-- for it could cause problems with some older versions of
-- Windows.
function windows_to_mingw_path(sequence s)
	ifdef TEST_FOR_WIN9X_ON_MING then
		-- Define the above word, to make sure we are not
		-- passing ming like paths to OS functions like file_exists().
		-- Normally, these will pass anyway but not in all Windows versions,
		-- this conversion breaks this yet it also breaks cygwin so
		-- we leave this off in production.
		if length(s)>3 and s[2] = ':' and eu:find(s[3],"/\\") then
			s = '/' & s[1] & '/' & s[4..$]
		end if
	end ifdef
	return search:find_replace('\\',s,'/')
end function

--**
-- Write a full Makefile

procedure write_makefile_full()
	sequence settings = setup_build()

	ensure_exename(settings[SETUP_EXE_EXT])
	
	integer cf = open(output_dir & "configure", "wb")
	puts(cf, """#!/bin/sh

CONFIG_FILE=config.gnu
PLAT="default_platform"
ARCH="default_arch"

UNAME_SYSTEM=`(uname -s) 2>/dev/null`  || UNAME_SYSTEM=unknown
UNAME_MACHINE=`(uname -m) 2>/dev/null` || UNAME_MACHINE=unknown
UNAME_REL=`(uname -r) 2>/dev/null` || UNAME_REL=unknown

# If under Cygwin or Mingw, we have 2 sets of paths: the normal TRUNKDIR/BUILDDIR/INCDIR defined by
# the Cygwin path (/cygdrive/c/dir/file) or under Mingw the Mingw path (/c/dir/file); as well as the
# CYP- versions (c:/dir/file). The normal variables are used by make itself, which can't handle the
# mixed-mode path and can only deal with pure Cygwin or Mingw ones. (These are also used by the
# various utilities ike cp, gcc, etc, even though they can handle either format). The CYP- versions
# are used whenever we call eui, euc, or an euphoria program, as these can only handle mixed-mode
# paths.

USECYPPATH="false"

# argument sent to the pwd command.  Most platforms no arguments.
PWDARG=
if echo "$UNAME_SYSTEM" | grep CYGWIN > /dev/null; then
    # for now, we build with -mno-cygwin under cygwin, so this is treated
    # identically to MinGW
    # A true exu.exe should probably set UNAME_SYSTEM="CYGWIN"
    UNAME_SYSTEM=WINDOWS
    # However, since we use absolute paths and Cygwin's make can't deal with
    # mixed-mode paths (C:/dir/file) the way MSYS's make can, we turn
    # CYPPATH on
    USECYPPATH="true"
    PWDARG=
    EXE=.exe

elif echo "$UNAME_SYSTEM" | grep MINGW > /dev/null; then
    UNAME_SYSTEM=WINDOWS
    USEMINGPATH="true"
    PWDARG=
    EXE=.exe
else
    PWDARG=
fi

# gcc doesn't seem to like -m32 on 32-bit machines when there are 
# no 64-bit machines 
# with an instruction super set of the 32-bit machine.  This means,
# -m32 is fine for ix86 32bit machines but bad for ARM and Motorola based
# machines.

MSIZE="-m32"

if echo "$UNAME_MACHINE" | grep "i[1-7]86" > /dev/null; then
    HOST_ARCH=ix86
    MSIZE=-m32
    
elif echo "$UNAME_MACHINE" | egrep "x86_64|amd64" > /dev/null; then
    HOST_ARCH=ix86_64
    MSIZE=-m64
    
elif echo "$UNAME_MACHINE" | grep -i ARM > /dev/null; then
    HOST_ARCH=ARM
    MSIZE=
fi
ARCH=$HOST_ARCH

if test $UNAME_SYSTEM = "Linux"; then
    EHOST=ELINUX
    TARGET=ELINUX
    LFLAGS="-ldl -lm -lpthread"
elif test $UNAME_SYSTEM = "WINDOWS"; then
    EHOST=EWINDOWS
    TARGET=EWINDOWS""" & HOSTNL &
    "    LFLAGS=\" -lws2_32 " & 
    iif(con_option,""," -mwindows") & "\"" & HOSTNL &
"""    
    if [ "$USECYPPATH" = "true" ]; then
       LFLAGS="$LFLAGS  -mno-cygwin"
    fi
elif test $UNAME_SYSTEM = "OpenBSD"; then
    EHOST=OPENBSD
    TARGET=EOPENBSD
    EBSD=1
    LFLAGS=" -lm -lpthread"
elif test $UNAME_SYSTEM = "NetBSD"; then
    EHOST=NETBSD
    TARGET=EBSD
    EBSD=1
    LFLAGS=" -lm -lpthread"
elif test $UNAME_SYSTEM = "FreeBSD"; then
    EHOST=FREEBSD
    TARGET=EFREEBSD
    EBSD=1
    LFLAGS=" -lm -lpthread"
# OS X > 10.4 (Darwin version 8 and up) supports 64-bit applications.
elif test $UNAME_SYSTEM = "Darwin"; then
    EHOST=EOSX
    TARGET=EOSX
    EBSD=1
    VAL=`echo "$UNAME_REL" | cut -d \. -f 1`
    if test $VAL -gt 8; then
        ARCH=ix86_64
        MSIZE=-m64
        
    # PPC will have to be supported manually; Euphoria doesn't currently support PPC.
    else 
        ARCH=x86
        MSIZE=-m32
        
    fi
    LFLAGS = " -lresolv"
else
    EHOST=EBSD
    TARGET=EBSD
    LFLAGS=" -lm -lpthread"
fi
[ -n "$MSIZE" ] && echo "MSIZE=$MSIZE" >> ${CONFIG_FILE}
[ -n "$LFLAGS" ] && echo "CTLFLAGS=$LFLAGS" >> ${CONFIG_FILE}
echo >> ${CONFIG_FILE}
	""")
	close(cf)

	integer GNUMakefile = open(output_dir & "GNUmakefile", "wb")
	integer WatcomMakefile = open(output_dir & "Makefile", "wb")
	printf(GNUMakefile, "CC     = %s" & HOSTNL, { settings[SETUP_CEXE] })
	
	printf(GNUMakefile, "CFLAGS = %s ${MSIZE}" & HOSTNL, { settings[SETUP_CFLAGS] })
	printf(GNUMakefile, "LINKER = %s" & HOSTNL, { settings[SETUP_LEXE] })
	printf(GNUMakefile, "LFLAGS = %s ${CTLFLAGS} ${MSIZE}" & HOSTNL, { settings[SETUP_LFLAGS] })
	

	printf(WatcomMakefile, "CC     = %s" & HOSTNL, { settings[SETUP_CEXE] })
	
	printf(WatcomMakefile, "CFLAGS = %s" & HOSTNL, { settings[SETUP_CFLAGS] })
	printf(WatcomMakefile, "LINKER = %s" & HOSTNL, { settings[SETUP_LEXE] })
		
	write_objlink_file()	

	write_makefile_srcobj_list(GNUMakefile)	
	write_makefile_srcobj_list(WatcomMakefile)
	puts(GNUMakefile, HOSTNL)
	puts(WatcomMakefile, HOSTNL)
	
    printf(WatcomMakefile, "\"%s\" : $(%s_OBJECTS) %s" & HOSTNL, { 
        exe_name[D_ALTNAME], upper(file0), user_library
    })
    printf(WatcomMakefile, "\t$(LINKER) @%s.lnk" & HOSTNL, { file0 })
    if length(rc_file[D_ALTNAME]) and length(settings[SETUP_RC_COMPILER]) then
        writef(WatcomMakefile, "\t" & settings[SETUP_RC_COMPILER], { rc_file[D_ALTNAME], res_file[D_ALTNAME], exe_name[D_ALTNAME] })
    end if
    puts(WatcomMakefile, HOSTNL)
    printf(WatcomMakefile, "%s-clean : .SYMBOLIC" & HOSTNL, { file0 })
    if length(res_file[D_ALTNAME]) then
        printf(WatcomMakefile, "\tdel \"%s\"" & HOSTNL, { res_file[D_ALTNAME] })
    end if
    for i = 1 to length(generated_files) do
        if match(".o", generated_files[i]) then
            printf(WatcomMakefile, "\tdel \"%s\"" & HOSTNL, { generated_files[i] })
        end if
    end for
    puts(WatcomMakefile, HOSTNL)
    printf(WatcomMakefile, "%s-clean-all : .SYMBOLIC" & HOSTNL, { file0 })
    printf(WatcomMakefile, "\tdel \"%s\"" & HOSTNL, { exe_name[D_ALTNAME] })
    if length(res_file[D_ALTNAME]) then
        printf(WatcomMakefile, "\tdel \"%s\"" & HOSTNL, { res_file[D_ALTNAME] })
    end if
    for i = 1 to length(generated_files) do
        printf(WatcomMakefile, "\tdel \"%s\"" & HOSTNL, { generated_files[i] })
    end for
    puts(WatcomMakefile, HOSTNL)
    puts(WatcomMakefile, "distclean : .SYMBOLIC" & HOSTNL)
    if length(res_file[D_ALTNAME]) then
        printf(WatcomMakefile, "\tdel \"%s\"" & HOSTNL, { res_file[D_ALTNAME] })
    end if
    for i = 1 to length(generated_files) do
        printf(WatcomMakefile, "\tdel \"%s\"" & HOSTNL, { generated_files[i] })
    end for
    printf(WatcomMakefile, "\tdel \"%s.mak\"" & HOSTNL, { file0 })
    printf(WatcomMakefile, "\tdel \"%s\"" & HOSTNL, { "Makefile" })
    printf(WatcomMakefile, "\tdel \"%s\"" & HOSTNL, { "GNUmakefile" })
    printf(WatcomMakefile, "\tdel \"%s\"" & HOSTNL, { "configure" })
    printf(WatcomMakefile, "\tdel \"%s\"" & HOSTNL, { "config.gnu" })
    printf(WatcomMakefile, "\tdel \"%s\"" & HOSTNL, { file0 })
    puts(WatcomMakefile, HOSTNL)
    
    
    puts(WatcomMakefile, ".c.obj : .autodepend" & HOSTNL)
    puts(WatcomMakefile, "\t$(CC) $(CFLAGS) $<" & HOSTNL)
    puts(WatcomMakefile, HOSTNL)

    puts(GNUMakefile,   "include config.gnu\n")
    printf(GNUMakefile, "RUNTIME_LIBRARY=%s\n", { settings[SETUP_RUNTIME_LIBRARY] } )
    printf(GNUMakefile, "%s: $(%s_OBJECTS) $(RUNTIME_LIBRARY) %s " & HOSTNL, { adjust_for_build_file(exe_name[D_ALTNAME]), upper(file0), rc_file[D_ALTNAME] })
    if length(rc_file[D_ALTNAME]) then
        writef(GNUMakefile, "\t" & settings[SETUP_RC_COMPILER] & HOSTNL, { rc_file[D_ALTNAME], res_file[D_ALTNAME] })
    end if
    printf(GNUMakefile, "\t$(LINKER) -o %s $(%s_OBJECTS) %s $(LFLAGS)" & HOSTNL, {
        exe_name[D_ALTNAME], upper(file0), iif(length(res_file[D_ALTNAME]), res_file[D_ALTNAME], "") })
    puts(GNUMakefile, HOSTNL)
    printf(GNUMakefile, ".PHONY: %s-clean %s-clean-all" & HOSTNL, { file0, file0 })
    puts(GNUMakefile, HOSTNL)
    printf(GNUMakefile, "%s-clean:" & HOSTNL, { file0 })
    printf(GNUMakefile, "\trm -rf $(%s_OBJECTS) %s" & HOSTNL, { upper(file0), res_file[D_ALTNAME] })
    puts(GNUMakefile, HOSTNL)
    printf(GNUMakefile, "%s-clean-all: %s-clean" & HOSTNL, { file0, file0 })
    printf(GNUMakefile, "\trm -rf $(%s_SOURCES) %s %s" & HOSTNL, { upper(file0), res_file[D_ALTNAME], exe_name[D_ALTNAME] })
    puts(GNUMakefile, HOSTNL)
    puts(GNUMakefile, "distclean:" & HOSTNL)
    printf(GNUMakefile, "\trm -fr $(HELLO_GENERATED_FILES) $(HELLO_SOURCES) %s.mak Makefile GNUmakefile configure config.gnu %s%s%s",
               { file0, file0, HOSTNL, HOSTNL })
    puts(GNUMakefile, "%.o: %.c" & HOSTNL)
    puts(GNUMakefile, "\t$(CC) $(CFLAGS) $*.c -c -o $*.o" & HOSTNL)
    puts(GNUMakefile, HOSTNL)

	close(GNUMakefile)
	close(WatcomMakefile)
end procedure

--**
-- Write a partial Makefile

procedure write_makefile_partial()
	sequence settings = setup_build()
	integer fh = open(output_dir & file0 & ".mak", "wb")

	write_makefile_srcobj_list(fh)

	close(fh)
end procedure

--**
-- Build the translated code directly from this process

export procedure build_direct(integer link_only=0, sequence the_file0="")
	if length(the_file0) then
		file0 = filebase(the_file0)
	end if
	sequence cmd, objs = "", settings = setup_build(), cwd = current_dir()
	integer status

	ensure_exename(settings[SETUP_EXE_EXT])

	if not link_only then
		switch compiler_type do
			case COMPILER_GCC then
				if not silent then
					ShowMsg(1, COMPILING_WITH_1, {"GCC"})
				end if

			case COMPILER_WATCOM then
				write_objlink_file()

				if not silent then
					ShowMsg(1, COMPILING_WITH_1, {"Watcom"})
				end if
		end switch
	end if

	if sequence(output_dir) and length(output_dir) > 0 then
		chdir(output_dir)
	end if

	sequence link_files = {}

	if not link_only then
		for i = 1 to length(generated_files) do
			if generated_files[i][$] = 'c' then
				cmd = sprintf("%s %s %s", { settings[SETUP_CEXE], settings[SETUP_CFLAGS],
					generated_files[i] })

				link_files = append(link_files, generated_files[i])

				if not silent then
					atom pdone = 100 * (i / length(generated_files))
					if not verbose then
						-- disabled until ticket:59 can be fixed
						-- results in longer build times, but output is correct
						if 0 and outdated_files[i] = 0 and force_build = 0 then
							ShowMsg(1, SKIPPING__130_2_UPTODATE, { pdone, generated_files[i] })
							continue
						else
							ShowMsg(1, COMPILING_130_2, { pdone, generated_files[i] })
						end if
					else
						ShowMsg(1, COMPILING_130_2, { pdone, cmd })
					end if

				end if

				status = system_exec(cmd, 0)
				if status != 0 then
					ShowMsg(2, COULDNT_COMPILE_FILE_1, { generated_files[i] })
					ShowMsg(2, STATUS_1_COMMAND_2, { status, cmd })
					goto "build_direct_cleanup"
				end if
			elsif match(".o", generated_files[i]) then
				objs &= " " & generated_files[i]
			end if
		end for
	else
		object files = read_lines(file0 & ".bld")
		for i = 1 to length(files) do
			objs &= " " & filebase(files[i]) & "." & settings[SETUP_OBJ_EXT]
		end for
	end if

	if keep and not link_only and length(link_files) then
		write_lines(file0 & ".bld", link_files)
	elsif keep = 0 then
		-- Delete a .bld file that may be left over from a previous -keep invocation
		delete_file(file0 & ".bld")
	end if

	-- For MinGW the RC file gets compiled to a .res file and then put in the normal link line
	if length(rc_file[D_ALTNAME]) and length(settings[SETUP_RC_COMPILER]) and compiler_type = COMPILER_GCC then
		cmd = text:format(settings[SETUP_RC_COMPILER], { rc_file[D_ALTNAME], res_file[D_ALTNAME] })
		status = system_exec(cmd, 0)
		if status != 0 then
			ShowMsg(2, UNABLE_TO_COMPILE_RESOURCE_FILE_1, { rc_file[D_NAME] })
			ShowMsg(2, STATUS_1_COMMAND_2_A, { status, cmd })
			
			goto "build_direct_cleanup"
		end if
	end if

	switch compiler_type do
		case COMPILER_WATCOM then
			cmd = sprintf("%s @%s.lnk", { settings[SETUP_LEXE], file0 })

		case COMPILER_GCC then
			cmd = sprintf("%s -o %s %s %s %s", { 
				settings[SETUP_LEXE],
				-- MINGW requires forward slashes 
				adjust_for_build_file( exe_name[D_ALTNAME] ),
				objs, 
				res_file[D_ALTNAME],
				settings[SETUP_LFLAGS]
			})
			
		case else
			ShowMsg(2, UNKNOWN_COMPILER_TYPE_1, { compiler_type })
			
			goto "build_direct_cleanup"
	end switch

	if not silent then
		if not verbose then
			ShowMsg(1, LINKING_100_1, { abbreviate_path(exe_name[D_NAME]) })
		else
			ShowMsg(1, LINKING_100_1, { cmd })
		end if
	end if

	status = system_exec(cmd, 0)
	if status != 0 then
		ShowMsg(2, UNABLE_TO_LINK_1, { exe_name[D_NAME] })
		ShowMsg(2, STATUS_1_COMMAND_2_A, { status, cmd })
		
		goto "build_direct_cleanup"
	end if
	
	-- For Watcom the rc file links in after the fact	
	if length(rc_file[D_ALTNAME]) and length(settings[SETUP_RC_COMPILER]) and compiler_type = COMPILER_WATCOM then
		cmd = text:format(settings[SETUP_RC_COMPILER], { rc_file[D_ALTNAME], res_file[D_ALTNAME], exe_name[D_ALTNAME] })
		status = system_exec(cmd, 0)
		if status != 0 then
			ShowMsg(2, UNABLE_TO_LINK_RESOURCE_FILE_1_INTO_EXECUTABLE_2, { rc_file[D_NAME], exe_name[D_NAME] })
			ShowMsg(2, STATUS_1_COMMAND_2_A, { status, cmd })
			
			goto "build_direct_cleanup"
		end if
	end if

label "build_direct_cleanup"
	if keep = 0 then
		for i = 1 to length(generated_files) do
			if verbose then
				ShowMsg(1, DELETING_1, { generated_files[i] })
			end if
			delete_file(generated_files[i])
		end for
		
		if length(res_file[D_ALTNAME]) then
			delete_file(res_file[D_ALTNAME])
		end if

		if remove_output_dir then
			chdir(cwd)

			-- remove the trailing slash
			if not remove_directory(output_dir) then
				ShowMsg(2, COULD_NOT_REMOVE_DIRECTORY_1, { abbreviate_path(output_dir) })
			end if
		end if
	end if

	chdir(cwd)
end procedure

--**
-- Call's a write_BUILDSYS procedure based on the compiler setting enum
--
-- See Also:
--   [[:build_system_type]], [[:BUILD_NONE]], [[:BUILD_MAKEFILE_FULL]],
--   [[:BUILD_MAKEFILE_PARTIAL]]
export procedure write_buildfile()
	switch build_system_type do
		case BUILD_MAKEFILE_FULL then
			write_makefile_full()
			
			if not silent then
				sequence make_command
				if compiler_type = COMPILER_WATCOM then				    
					make_command = "\'wmake\'"
				else
					make_command = "\'sh configure; make\'"
				end if

				ShowMsg(1, MSG_1C_FILES_WERE_CREATED, { cfile_count + 2 })
					
				if sequence(output_dir) and length(output_dir) > 0 then
					ShowMsg(1, TO_BUILD_YOUR_PROJECT_CHANGE_DIRECTORY_TO_1_AND_TYPE_23MAK, { output_dir, make_command, file0 })
				else
					ShowMsg(1, TO_BUILD_YOUR_PROJECT_TYPE_12MAK, { make_command })
				end if
			end if

		case BUILD_MAKEFILE_PARTIAL then
			write_makefile_partial()

			if not silent then
				ShowMsg(1, MSG_1C_FILES_WERE_CREATED, { cfile_count + 2 })
				ShowMsg(1, TO_BUILD_YOUR_PROJECT_INCLUDE_1MAK_INTO_A_LARGER_MAKEFILE_PROJECT, { file0 })
			end if

		case BUILD_DIRECT then
			build_direct()

			if not silent then
				sequence settings = setup_build()
				--ShowMsg(1, TO_RUN_YOUR_PROJECT_TYPE_1, { exe_name[D_NAME] })
			end if

		case BUILD_NONE then
			if not silent then
				ShowMsg(1, MSG_1C_FILES_WERE_CREATED, { cfile_count + 2 })
			end if

			-- Do not write any build file

		case else
			CompileErr(UNKNOWN_BUILD_FILE_TYPE)
	end switch
end procedure
