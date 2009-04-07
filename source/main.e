-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
-- main.e
-- Front End - main routine

include std/filesys.e
include std/io.e
include std/get.e
include std/error.e
include std/console.e

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

function GetSourceName()
-- record command line options, return source file number
	integer src_file
	boolean dot_found
	sequence src_name
	sequence SVN_REVISION

	if Argc >= 3 then
		src_name = Argv[3]
	else
		if INTERPRET and not BIND then
			screen_output(STDERR, "Euphoria Interpreter ")

		elsif TRANSLATE then
			screen_output(STDERR, "Euphoria to C Translator ")
		elsif BIND then
			screen_output(STDERR, "Euphoria Binder ")
		end if
		screen_output(STDERR, version_string_long() & "\n")

		ifdef EU_MANAGED_MEM then
			screen_output(STDERR, "Using Managed Memory")
		elsedef
			screen_output(STDERR, "Using System Memory")
		end ifdef
		object EuConsole = getenv("EUCONS")
		if equal(EuConsole, "1") then
			screen_output(STDERR, ", EuConsole")
		end if
		screen_output(STDERR, "\n")

		return -2 -- No source file
	end if

	-- check src_name for last '.'
	dot_found = FALSE
	for p = length(src_name) to 1 by -1 do
		if src_name[p] = '.' then
		   dot_found = TRUE
		   exit
		elsif find(src_name[p], SLASH_CHARS) then
		   exit
		end if
	end for

	if not dot_found then
		-- no dot found --
		-- N.B. The list of default extentions must always end with the first one again.
		-- Add a placeholder in the file list.
		file_name = append(file_name, "")

		-- test each ext until you find the file.
		for i = 1 to length( DEFAULT_EXTS ) do
			file_name[$] = src_name & DEFAULT_EXTS[i]
			src_file = e_path_open(file_name[$], "r")
			if src_file != -1 then
				exit
			end if
		end for
	else
		file_name = append(file_name, src_name)
		src_file = e_path_open(src_name, "r")
	end if

	return src_file
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

	eudir = getenv("EUDIR")
	if atom(eudir) then
		ifdef UNIX then
			-- should check search PATH for euphoria/bin ?
			eudir = getenv("HOME")
			if atom(eudir) then
				eudir = "euphoria"
			else
				eudir = eudir & "/euphoria"
			end if
		elsedef
			eudir = getenv("HOMEPATH")
			if atom(eudir) then
				eudir = "\\EUPHORIA"
			else
				eudir = getenv("HOMEDRIVE") & eudir & "EUPHORIA"
			end if
		end ifdef

	else
		-- This is a special RDS hack because the RapidEuphoria shared
		-- host machine does not provide enough memory to complete a
		-- normal build.
		mybsd = match("/usr231/home/r/h/rhc", eudir) > 0 --RapidEuphoria.com

	end if
	TempErrName = "ex.err"
	TempWarningName = STDERR
	display_warnings = 1

	if TRANSLATE or BIND or INTERPRET then
		InitBackEnd(0)
	end if

	src_file = GetSourceName()

	if src_file = -1 then
		-- too early for normal error processing
		screen_output(STDERR, sprintf("Can't open %s\n", {file_name[$]}))
		any_key("\nPress any key", STDERR)
		Cleanup(1)
	elsif src_file >= 0 then
		main_path = full_path(file_name[$])
	end if


	if TRANSLATE then
		InitBackEnd(1)
	end if

	InitGlobals()
	CheckPlatform()
	
	InitSymTab()
	InitEmit()
	InitParser()
	InitLex()
	
	-- sets up the internal namespace
	eu_namespace()

	if src_file = -2 then	
		-- No source supplied on command line
		show_usage()
		if find("WIN32_GUI", OpDefines) then
			any_key("(press any key and window will close ...)", STDERR)
		end if
		Cleanup(1)
	end if
	
	-- starts reading and checks for a default namespace
	main_file()

	parser()
	
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
