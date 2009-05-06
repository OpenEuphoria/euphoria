--****
-- == cominit.e: Common command line initialization

include euphoria/info.e

include std/cmdline.e
include std/filesys.e
include std/io.e
include std/search.e
include std/text.e
include std/map.e as m

include common.e
include error.e
include global.e
include pathopen.e
include platform.e

export sequence src_name = ""
export sequence switches = {}

export sequence common_opt_def = {
	{ "c", 0, "Specify a configuration file",
				{ NO_CASE, MULTIPLE, HAS_PARAMETER, "filename" } },
	{ "i", 0, "Add a directory to be searched for include files",
				{ NO_CASE, MULTIPLE, HAS_PARAMETER, "dir" } },
	{ "d", 0, "Define a preprocessor word",
				{ NO_CASE, MULTIPLE, HAS_PARAMETER, "word" } },
	{ "batch", 0, "Turn on batch processing (do not \"Press Enter\" on error",
				{ NO_CASE } },
	{ "test", 0, "Test syntax only, do not execute",
				{ NO_CASE } },
	{ "strict", 0, "Enable all warnings",
				{ NO_CASE } },
	{ "w", 0, "Defines warning level",
				{ NO_CASE, MULTIPLE, HAS_PARAMETER, "name" } },
	{ "x", 0, "Defines warning level by exclusion",
				{ NO_CASE, MULTIPLE, HAS_PARAMETER, "name" } },
	{ "wf", 0, "Write all warnings to the given file instead of STDOUT",
				{ NO_CASE, HAS_PARAMETER, "filename" } },
	{ "version", 0, "Display the version number",
				{ NO_CASE } },
	{ "copyright", 0, "Display all copyright notices",
				{ NO_CASE } }
}

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

			case "warning" then
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

			case "exclude-warning" then
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

			case "warning-file" then
				TempWarningName = val

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

	-- Split of Argv and switches
	sequence extras = m:get(opts, "extras")
	if length(extras) > 0 then
		integer eufile_pos = find(extras[1], Argv)
		if eufile_pos > 3 then
			switches = Argv[3..eufile_pos - 1]
			Argv = Argv[1..2] & Argv[eufile_pos..$]
			Argc = length(Argv)
		end if

		src_name = extras[1]
	end if
end procedure
