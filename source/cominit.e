--****
-- == cominit.e: Common command line initialization

include euphoria/info.e

include std/cmdline.e
include std/error.e as error
include std/filesys.e
include std/io.e
include std/search.e
include std/text.e
include std/map.e as m
include std/sequence.e

include common.e
include error.e
include global.e
include pathopen.e
include platform.e
include preproc.e

export sequence src_name = ""
export sequence switches = {}

constant COMMON_OPTIONS = {
	{ "batch", 0, "Turn on batch processing (do not \"Press Enter\" on error",
				{ NO_CASE } },
	{ "c", 0, "Specify a configuration file",
				{ NO_CASE, MULTIPLE, HAS_PARAMETER, "filename" } },
	{ "copyright", 0, "Display all copyright notices",
				{ NO_CASE } },
	{ "d", 0, "Define a preprocessor word",
				{ NO_CASE, MULTIPLE, HAS_PARAMETER, "word" } },
	{ "i", 0, "Add a directory to be searched for include files",
				{ NO_CASE, MULTIPLE, HAS_PARAMETER, "dir" } },
	{ "l", 0, "Defines a localization qualifier",
				{ NO_CASE, MULTIPLE, HAS_PARAMETER, "local" } },
	{ "ldb", 0, "Defines the base name for localization databases",
				{ NO_CASE, HAS_PARAMETER, "localdb" } },
	{ "p", 0, "Setup a pre-processor",
				{ NO_CASE, MULTIPLE, HAS_PARAMETER, "file_ext:command" } },
	{ "pf", 0, "Force pre-processing regardless of cache state",
				{ NO_CASE } },
	{ "strict", 0, "Enable all warnings",
				{ NO_CASE } },
	{ "test", 0, "Test syntax only, do not execute",
				{ NO_CASE } },
	{ "version", 0, "Display the version number",
				{ NO_CASE } },
	{ "w", 0, "Defines warning level",
				{ NO_CASE, MULTIPLE, HAS_PARAMETER, "name" } },
	{ "wf", 0, "Write all warnings to the given file instead of STDOUT",
				{ NO_CASE, HAS_PARAMETER, "filename" } },
	{ "x", 0, "Defines warning level by exclusion",
				{ NO_CASE, MULTIPLE, HAS_PARAMETER, "name" } },
	$
}

sequence options = {}
add_options( COMMON_OPTIONS )

--**
-- Add options to be parsed.
export procedure add_options( sequence new_options )
	options &= new_options
end procedure

--**
-- Get the sequence containing all the command line options
-- to be parsed.
export function get_options()
	return options
end function

--**
-- Returns the options that are common to all methods of invoking
-- euphoria.
export function get_common_options()
	return COMMON_OPTIONS
end function

--**
-- Get the switches sequence

export function get_switches()
	return switches
end function

--**
-- Show all copyright statements

procedure show_copyrights()
	sequence notices = all_copyrights()
	for i = 1 to length(notices) do
		printf(2, "%s\n  %s\n\n", { notices[i][1], find_replace("\n", notices[i][2], "\n  ") })
	end for
end procedure

--**
export procedure show_banner()
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
end procedure

--**
-- Expand any config file options on the command line adding
-- their content to Argv

export procedure expand_config_options()
	integer idx = 1
	while idx < length(Argv) do
		if equal(upper(Argv[idx]), "-C") then
			idx += 1
			sequence new_args = load_euinc_conf(Argv[idx])
			Argv = Argv[1..idx] & new_args & Argv[idx + 1..$]
		end if

		idx += 1
	end while

	Argc = length(Argv)
end procedure

--**
-- Process options that are common to the Interpreter and Translator.

export procedure handle_common_options(m:map opts)
	sequence opt_keys = m:keys(opts)
	integer option_w = 0

	for idx = 1 to length(opt_keys) do
		sequence key = opt_keys[idx]
		object val = m:get(opts, key)

		switch key do
			case "i" then
				for i = 1 to length(val) do
					add_include_directory(val[i])
				end for

			case "d" then
				OpDefines &= val

			case "batch" then
				batch_job = 1

			case "test" then
				test_only = 1
				batch_job = 1

			case "strict" then
				Strict_is_on = 1
			
			case "p" then
				for i = 1 to length(val) do
					add_preprocessor(val[i])
				end for
				
			case "pf" then
				force_preprocessor = 1

			case "l" then
				for i = 1 to length(val) do
					LocalizeQual = append(LocalizeQual, (filter(lower(val[i]), STDFLTR_ALPHA)))
				end for

			case "ldb" then
				LocalDB = val

			case "w" then
				integer n = find(val, warning_names)
				if n != 0 then
					if option_w = 1 then
						OpWarning = or_bits(OpWarning, warning_flags[n])
					else
						option_w = 1
						OpWarning = warning_flags[n]
					end if

					prev_OpWarning = OpWarning
				end if

			case "x" then
				integer n = find(val, warning_names)
				if n != 0 then
					if option_w = -1 then
						OpWarning = and_bits(OpWarning, not_bits(warning_flags[n]))
					else
						option_w = -1
						OpWarning = all_warning_flag - warning_flags[n]
					end if

					prev_OpWarning = OpWarning
				end if

			case "wf" then
				TempWarningName = val
			  	error:warning_file(TempWarningName)

			case "version" then
				show_banner()
				abort(0)

			case "copyright" then
				show_copyrights()
				abort(0)
		end switch
	end for
end procedure

--**
-- Finalize the command line processing by splitting Argv into
-- Argv and switches sequences as well as handling any special
-- cleanup cases such as -strict overriding any -W/-X switches.

export procedure finalize_command_line(m:map opts)
	if Strict_is_on then -- overrides any -W/-X switches
		OpWarning = all_warning_flag
		prev_OpWarning = OpWarning
	end if

	-- Initialize the option_switches and remove them
	-- from the command line
	sequence extras = m:get(opts, "extras")
	if length(extras) > 0 then
		integer eufile_pos = find(extras[1], Argv)
		sequence pairs = m:pairs( opts )
		for i = 1 to length( pairs ) do
			sequence pair = pairs[i]
			if equal( pair[1], "extras" ) then
				continue
			end if
			pair[1] = prepend( pair[1], '-' )
			if sequence( pair[2] ) then
				if length( pair[2] ) and sequence( pair[2][1] ) then
					for j = 1 to length( pair[2] ) do
						switches &= { pair[1], pair[2][j] }
					end for
				else
					switches &= pair
				end if
			else
				switches = append( switches, pair[1] )
			end if
		end for
		if eufile_pos > 3 then
			Argv = Argv[1..2] & Argv[eufile_pos..$]
			Argc = length(Argv)
		end if

		src_name = extras[1]
	end if
end procedure
