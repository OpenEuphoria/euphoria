-- (c) Copyright - See License.txt
--
-- main.e
-- Front End - main routine

ifdef ETYPE_CHECK then
	with type_check
elsedef
	without type_check
end ifdef

include std/filesys.e
include std/io.e
include std/get.e
include std/error.e
include std/console.e
include std/search.e
include std/hash.e
include euphoria/info.e

include global.e
include pathopen.e
include parser.e
include mode.e
include common.e
include platform.e
include cominit.e
include emit.e
include symtab.e
include scanner.e
include error.e
include preproc.e
include msgtext.e
include coverage.e

ifdef TRANSLATOR then
	include buildsys.e
	include c_decl.e
end ifdef

--**
-- record command line options, return source file number

function GetSourceName()
	object real_name
	integer fh
	boolean has_extension = FALSE

	if length(src_name) = 0 then
		show_banner()
		return -2 -- No source file
	end if

	ifdef WINDOWS then
		src_name = match_replace("/", src_name, "\\")
	end ifdef
	-- check src_name for last '.'
	for p = length(src_name) to 1 by -1 do
		if src_name[p] = '.' then
		   has_extension = TRUE
		   exit
		elsif find(src_name[p], SLASH_CHARS) then
		   exit
		end if
	end for

	if not has_extension then
		-- no extension was found
		-- N.B. The list of default extentions must always end with the first one again.
		-- Add a placeholder in the file list.
		known_files = append(known_files, "")

		-- test each ext until you find the file.
		for i = 1 to length( DEFAULT_EXTS ) do
			known_files[$] = src_name & DEFAULT_EXTS[i]
			real_name = e_path_find(known_files[$])
			if sequence(real_name) then
				exit
			end if
		end for

		if atom(real_name) then
			return -1
		end if
	else
		known_files = append(known_files, src_name)
		real_name = e_path_find(src_name)
		if atom(real_name) then
			return -1
		end if
	end if
	known_files[$] = canonical_path(real_name,,CORRECT)
	known_files_hash &= hash(known_files[$], stdhash:HSIEH32)
	finished_files &= 0
	file_include_depend = append( file_include_depend, { length( known_files ) } )

	if file_exists(real_name) then
		real_name = maybe_preprocess(real_name)
		fh = open_locked(real_name)
		return fh
	end if

	return -1
end function

function full_path(sequence filename)
-- return the full path for a file
	for p = length(filename) to 1 by -1 do
		if find(filename[p], SLASH_CHARS) then
			return filename[1..p]
		end if
	end for
	return '.' & SLASH
end function


procedure main()
-- Main routine
	integer argc
	sequence argv

	-- we have our own, possibly different, idea of argc and argv
	argv = command_line()

	if BIND then
		argv = extract_options(argv)
	end if

	argc = length(argv)

	Argv = argv
	Argc = argc

	TempErrName = "ex.err"
	TempWarningName = STDERR
	display_warnings = 1

	InitGlobals()

	if TRANSLATE or BIND or INTERPRET then
		InitBackEnd(0)
	end if

	src_file = GetSourceName()

	if src_file = -1 then
		-- too early for normal error processing
		screen_output(STDERR, GetMsgText(51, 0, {known_files[$]}))
		if not batch_job and not test_only then
			maybe_any_key(GetMsgText(277,0), STDERR)
		end if
		Cleanup(1)

	elsif src_file >= 0 then
		main_path = known_files[$]
		if length(main_path) = 0 then
			main_path = '.' & SLASH
		end if

	end if


	if TRANSLATE then
		InitBackEnd(1)
	end if

	CheckPlatform()

	InitSymTab()
	InitEmit()
	InitLex()
	InitParser()
	

	-- sets up the internal namespace
	eu_namespace()

	ifdef TRANSLATOR then
		if keep and build_system_type = BUILD_DIRECT then
			if 0 and not quick_has_changed(known_files[$]) then
				build_direct(1, known_files[$])
				Cleanup(0)
				return
			end if
		end if
	end ifdef

	-- starts reading and checks for a default namespace
	main_file()
	
	check_coverage()
	
	parser()
	
	init_coverage()
	-- we've parsed successfully
	-- now run the appropriate back-end
	if TRANSLATE then
		BackEnd(0) -- translate IL to C

	elsif BIND then
		OutputIL()

	elsif INTERPRET and not test_only then
		ifdef not STDDEBUG then
			BackEnd(0) -- execute IL using Euphoria-coded back-end
		end ifdef
	end if
	
	Cleanup(0) -- does warnings
end procedure

main()
