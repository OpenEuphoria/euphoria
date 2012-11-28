--****
-- == Command Line Handling
--
-- <<LEVELTOC level=2 depth=4>>
--

namespace cmdline

include std/console.e
include std/error.e
include std/io.e
include std/map.e
include std/os.e
include std/sequence.e
include std/text.e
include std/types.e


--****
-- === Constants

public constant
	--** This option switch does not have a parameter. See [[:cmd_parse]]
	NO_PARAMETER  = 'n',

	--** This option switch does have a parameter. See [[:cmd_parse]]
	HAS_PARAMETER = 'p',

	--** This option switch is not case sensitive. See [[:cmd_parse]]
	NO_CASE       = 'i',

	--** This option switch is case sensitive. See [[:cmd_parse]]
	HAS_CASE      = 'c',

	--** This option switch must be supplied on command line. See [[:cmd_parse]]
	MANDATORY     = 'm',

	--** This option switch does not have to be on command line. See [[:cmd_parse]]
	OPTIONAL      = 'o',

	--** This option switch must only occur once on the command line. See [[:cmd_parse]]
	ONCE          = '1',

	--** This option switch may occur multiple times on a command line. See [[:cmd_parse]]
	MULTIPLE      = '*',

	--** 
	-- This option switch triggers the 'help' display. See [[:cmd_parse]]
	HELP          = 'h',
	
	--** 
	-- This option switch is simply a help display header to group like options together.
	-- See [[:cmd_parse]]
	HEADER        = 'H',

    --** 
    -- This option switch sets the program version information. If this option
    -- is chosen by the user ##cmd_parse## will display the program version information
    -- and then end the program with a zero error code.
    VERSIONING    = 'v'


public enum
	--**
	-- Additional help routine id. See [[:cmd_parse]]
	HELP_RID,

	--**
	-- Validate all parameters (default). See [[:cmd_parse]]
	VALIDATE_ALL,

	--**
	-- Do not cause an error for an invalid parameter. See [[:cmd_parse]]
	NO_VALIDATION,

	--**
	-- Do not cause an error for an invalid parameter after the
	-- first extra item has been found. This can be helpful for
	-- processes such as the Interpreter itself that must deal
	-- with command line parameters that it is not meant to
	-- handle.  At expansions after the first extra are also disabled.
	--
	-- For instance~:
	--
	-- ##eui -D TEST greet.ex -name John -greeting Bye##
	--
	-- ##-D TEST## is meant for ##eui##, but ##-name## and ##-greeting## options
	-- are meant for ##greet.ex##. See [[:cmd_parse]]
	--
	-- ##eui @euopts.txt greet.ex @hotmail.com##
	--
	-- here 'hotmail.com' is not expanded into the command line but
	-- 'euopts.txt' is.
	NO_VALIDATION_AFTER_FIRST_EXTRA,

	--**
	-- Only display the option list in ##show_help##. Do not display other
	-- information (such as program name, options, and so on) See [[:cmd_parse]]
	SHOW_ONLY_OPTIONS,

	--**
	-- Expand arguments that begin with ##'@'## into the command line. (default)
	-- For example, ##@filename## will expand the contents of file named 'filename'
	-- as if the file's contents were passed in on the command line.  Arguments
	-- that come after the first extra will not be expanded when
	-- ##NO_VALIDATION_AFTER_FIRST_EXTRA## is specified.
	AT_EXPANSION,

	--**
	-- Do not expand arguments that begin with ##'@'## into the command line.
	-- Normally ##@filename## will expand the file names contents as if the
	-- file's contents were passed in on the command line.  This option
	-- supresses this behavior.
	NO_AT_EXPANSION,

	--**
	-- Supply a message to display and pause just prior to ##abort## being called.
	PAUSE_MSG,

	--**
	-- Disable the automatic inclusion of ##-h##, ##-?##, and ##~--help## as help switches.
	NO_HELP,
	
	--**
	-- Disable the automatic display of all of the possible options on error.
	NO_HELP_ON_ERROR,
	
	$

public enum
	--**
	--   An index into the ##opts## list. See [[:cmd_parse]]
	OPT_IDX,

	--**
	--   The number of times that the routine has been called
	--   by ##cmd_parse## for this option. See [[:cmd_parse]]
	OPT_CNT,

	--**
	--  The option's value as found on the command line. See [[:cmd_parse]]
	OPT_VAL,

	--**
	--  The value ##1## if the command line indicates that this option is to remove
	--  any earlier occurrences of it. See [[:cmd_parse]]
	OPT_REV

public constant
	--**
	--   The extra parameters on the cmd line, not associated with any
	--   specific option. See [[:cmd_parse]]
	EXTRAS = {{"extras"}},
	
	--**
	-- @nodoc@
	OPT_EXTRAS = EXTRAS

-- Record fields in 'opts' argument.
enum
	SHORTNAME   = 1,
	LONGNAME    = 2,
	DESCRIPTION = 3,
	OPTIONS     = 4,
	CALLBACK    = 5,
	MAPNAME     = 6

sequence pause_msg = ""

procedure local_abort(integer lvl)
	if length(pause_msg) != 0 then
		console:maybe_any_key(pause_msg, 1)
	end if

	abort(lvl)
end procedure

procedure check_for_bad_combos( sequence opts, integer opt1, integer opt2, sequence error_message )
	-- Checks for illegal combinations of options, and crashes if found
	if find( opt1, opts[OPTIONS]) then
		if find( opt2, opts[OPTIONS]) then
			error:crash( error_message )
		end if
	end if
end procedure

function has_duplicate( sequence opts, sequence opt, integer name_type, integer start_from )
	if sequence( opt[name_type] ) then
		sequence opt_name = opt[name_type]
		for i = start_from + 1 to length( opts ) do
			if equal( opt_name, opts[i][name_type] ) then
				return 1
			end if
		end for
	end if
	return 0
end function

procedure check_for_duplicates( sequence opts )
	-- Check for duplicate option records.
	for i = 1 to length(opts) do
		sequence opt
		opt = opts[i]
		if has_duplicate( opts, opt, SHORTNAME, i ) then
			
			error:crash("cmd_opts: Duplicate Short Names (%s) are not allowed in an option record.\n",
				{ opt[SHORTNAME]})
			
		elsif has_duplicate( opts, opt, LONGNAME, i ) then
			
			error:crash("cmd_opts: Duplicate Long Names (%s) are not allowed in an option record.\n",
				{opt[LONGNAME]})
		end if
	end for

end procedure

function update_opts( sequence opts )
	-- Cleans up the options, making sure they're appropriate size,
	-- adds default values where appropriate, and checks for 
	-- some illegal combinations.
	
	integer lExtras = 0 -- Ensure that there is zero or one 'extras' record only.
	for i = 1 to length(opts) do
		sequence opt = opts[i]
		opts[i] = 0

		if length(opt) < MAPNAME then
			opt &= repeat(-1, MAPNAME - length(opt))
		end if

		if sequence(opt[SHORTNAME]) and length(opt[SHORTNAME]) = 0 then
			opt[SHORTNAME] = 0
		end if

		if sequence(opt[LONGNAME]) and length(opt[LONGNAME]) = 0 then
			opt[LONGNAME] = 0
		end if

		if atom(opt[LONGNAME]) and atom(opt[SHORTNAME]) then
			if lExtras != 0 then
				error:crash("cmd_opts: There must be less than two 'extras' option records.\n")
			else
				lExtras = i
				if atom(opt[MAPNAME]) then
					opt[MAPNAME] = EXTRAS
				end if
			end if
		end if

		if atom(opt[DESCRIPTION]) then
			opt[DESCRIPTION] = ""
		end if


		if atom(opt[OPTIONS]) then
			if equal(opt[OPTIONS], HAS_PARAMETER) then
				opt[OPTIONS] = {HAS_PARAMETER,"x"}
			else
				opt[OPTIONS] = {}
			end if
		else
			for j = 1 to length(opt[OPTIONS]) do
				if find(opt[OPTIONS][j], opt[OPTIONS], j + 1) != 0 then
					error:crash("cmd_opts: Duplicate processing options are not allowed in an option record.\n")
				end if
			end for

			check_for_bad_combos( opt, HAS_PARAMETER, NO_PARAMETER, 
				"cmd_opts: Cannot have both HAS_PARAMETER and NO_PARAMETER in an option record.\n")
			
			check_for_bad_combos( opt, HAS_CASE, NO_CASE, 
				"cmd_opts: Cannot have both HAS_CASE and NO_CASE in an option record.\n")
			
			check_for_bad_combos( opt, MANDATORY, OPTIONAL, 
				"cmd_opts: Cannot have both MANDATORY and OPTIONAL in an option record.\n")
			
			check_for_bad_combos( opt, ONCE, MULTIPLE, 
				"cmd_opts: Cannot have both ONCE and MULTIPLE in an option record.\n")
			
		end if

		if sequence(opt[CALLBACK]) then
			opt[CALLBACK] = -1
		elsif not integer(opt[CALLBACK]) then
			opt[CALLBACK] = -1
		elsif opt[CALLBACK] < 0 then
			opt[CALLBACK] = -1
		end if

		if sequence(opt[MAPNAME]) and length(opt[MAPNAME]) = 0 then
			opt[MAPNAME] = 0
		end if

		if atom(opt[MAPNAME]) then
			if sequence(opt[LONGNAME]) then
				opt[MAPNAME] = opt[LONGNAME]
			elsif sequence(opt[SHORTNAME]) then
				opt[MAPNAME] = opt[SHORTNAME]
			else
				opt[MAPNAME] = EXTRAS
			end if
		end if

		opts[i] = opt
	end for
	return opts
end function

function standardize_help_options( sequence opts, integer auto_help_switches )
	
	-- Insert the default 'help' options if one is not already being used.
	integer has_h = 0, has_help = 0, has_question = 0
	for i = 1 to length(opts) do
		if equal(opts[i][SHORTNAME], "h") then
			has_h = 1
		elsif equal(opts[i][SHORTNAME], "?") then
			has_question = 1
		end if
		
		if equal(opts[i][LONGNAME], "help") then
			has_help = 1
		end if
	end for
	
	if auto_help_switches then
		integer appended_opts = 0
		if not has_h and not has_help then
			opts = append(opts, {"h", "help", "Display the command options", {HELP}, -1})
			appended_opts = 1
			
		elsif not has_h then
			opts = append(opts, {"h", 0, "Display the command options", {HELP}, -1})
			appended_opts = 1
			
		elsif not has_help then
			opts = append(opts, {0, "help", "Display the command options", {HELP}, -1})
			appended_opts = 1
			
		end if
		
		if not has_question then			
			opts = append(opts, {"?", 0, "Display the command options", {HELP}, -1})
			appended_opts = 1
		end if

		if appended_opts then
			-- We have to standardize the above additions
			opts = standardize_opts(opts, 0)
		end if
	end if
	return opts
end function
-- Local routine to validate and reformat option records if they are not in the standard format.
function standardize_opts(sequence opts, integer auto_help_switches)
	
	opts = update_opts( opts )
	
	check_for_duplicates( opts )
	
	opts = standardize_help_options( opts, auto_help_switches )
	
	-- Patch a few either/or cases
	for i = 1 to length(opts) do
		if not find(HAS_PARAMETER, opts[i][OPTIONS]) then
			opts[i][OPTIONS] &= NO_PARAMETER
		end if
		
		if not find(MULTIPLE, opts[i][OPTIONS]) and not find(ONCE, opts[i][OPTIONS]) then
			opts[i][OPTIONS] &= ONCE
		end if
		
		if not find(HAS_CASE, opts[i][OPTIONS]) and not find(NO_CASE, opts[i][OPTIONS]) then
			opts[i][OPTIONS] &= NO_CASE
		end if
	end for
	
	return opts
end function

function print_help( sequence opts, sequence cmds )
	-- Calculate the size of the padding required to keep option text aligned.
	-- Prints help for each option and the extras.
	integer pad_size = 0
	integer this_size
	integer extras_mandatory = 0
	integer extras_opt = 0
	sequence param_name
	integer has_param
	
	for i = 1 to length(opts) do
		this_size = 0
		param_name = ""
		
		if atom(opts[i][SHORTNAME]) and opts[i][SHORTNAME] = HEADER then
			continue
		end if

		if atom(opts[i][SHORTNAME]) and atom(opts[i][LONGNAME]) then
			extras_opt = i
			if find(MANDATORY, opts[i][OPTIONS]) then
				extras_mandatory = 1
			end if
			-- Ignore 'extras' record
			continue
		end if

		if sequence(opts[i][SHORTNAME]) then
			this_size += length(opts[i][SHORTNAME]) + 1 -- Allow for "-"
			if find(MANDATORY, opts[i][OPTIONS]) = 0 then
				this_size += 2 -- Allow for '[' ']'
			end if
		end if

		if sequence(opts[i][LONGNAME]) then
			this_size += length(opts[i][LONGNAME]) + 2 -- Allow for "--"
			if find(MANDATORY, opts[i][OPTIONS]) = 0 then
				this_size += 2 -- Allow for '[' ']'
			end if
		end if

		if sequence(opts[i][SHORTNAME]) and sequence(opts[i][LONGNAME]) then
			this_size += 2 -- Allow for ", " between short and long names
		end if

		has_param = find(HAS_PARAMETER, opts[i][OPTIONS])
		if has_param != 0 then
			this_size += 1 -- Allow for " "
			if has_param < length(opts[i][OPTIONS]) then
				--has_param += 1
				if sequence(opts[i][OPTIONS][has_param]) then
					param_name = opts[i][OPTIONS][has_param]
				else
					param_name = "x"
				end if
			else
				param_name = "x"
			end if
			this_size += 2 + length(param_name)
		end if

		if pad_size < this_size then
			pad_size = this_size
		end if
	end for
	pad_size += 3 -- Allow for minimum gap between cmd and its description
	
	printf(1, "%s options:\n", {cmds[2]})

	for i = 1 to length(opts) do
		if atom(opts[i][1]) and opts[i][1] = HEADER then
			if i > 1 then
				printf(1, "\n")
			end if
			
			printf(1, "%s\n", { opts[i][2] })
			continue
		end if
		
		print_option_help( opts[i], pad_size )
	end for
	
	print_extras_help( opts, extras_mandatory, extras_opt )
	
	return pad_size
end function

procedure print_extras_help( sequence opts, integer extras_mandatory, integer extras_opt )
	-- Print help about the extras
	if extras_mandatory != 0 then
		if length(opts[extras_opt][DESCRIPTION]) > 0 then
			puts(1, "\n" & opts[extras_opt][DESCRIPTION])
			puts(1, '\n')
		else
			puts(1, "One or more additional arguments are also required\n")
		end if
	elsif extras_opt > 0 then
		if length(opts[extras_opt][DESCRIPTION]) > 0 then
			puts(1, "\n" & opts[extras_opt][DESCRIPTION])
			puts(1, '\n')
		else
			puts(1, "One or more additional arguments can be supplied.\n")
		end if
	end if
end procedure

procedure local_help(sequence opts, object add_help_rid = -1, sequence cmds = command_line(), 
		integer std = 0, object parse_options = {})
	
	sequence cmd
	integer is_mandatory
	integer extras_mandatory = 0
	integer extras_opt = 0
	integer auto_help = 1

	integer po = 1
	if atom(parse_options) then
		parse_options = {parse_options}
	end if

	while po <= length(parse_options) do
		switch parse_options[po] do
			case HELP_RID then
				if po < length(parse_options) then
					po += 1
					add_help_rid = parse_options[po]
				else
					error:crash("HELP_RID was given to cmd_parse with no routine_id")
				end if
			
			case NO_HELP then
				auto_help = 0
		
			case else
			-- do nothing as we don't care about other options at this point.
				
		end switch
		po += 1
	end while
	
	if std = 0 then
		opts = standardize_opts(opts, auto_help)
	end if

	integer pad_size = print_help( opts, cmds )
	
	call_user_help( add_help_rid )
	
end procedure

procedure call_user_help( object add_help_rid )
	if atom(add_help_rid) then
		if add_help_rid >= 0 then
			puts(1, "\n")
			call_proc(add_help_rid, {})
			puts(1, "\n")
		end if
	else
		if length(add_help_rid) > 0 then
			puts(1, "\n")
			if types:t_display(add_help_rid) then
				add_help_rid = {add_help_rid}
			end if
			
			for i = 1 to length(add_help_rid) do
				puts(1, add_help_rid[i])
				if length(add_help_rid[i]) = 0 or add_help_rid[i][$] != '\n' then
					puts(1, '\n')
				end if
			end for

			puts(1, "\n")
		end if
	end if
end procedure

procedure print_option_help( sequence opt, integer pad_size )
	if atom(opt[SHORTNAME]) and atom(opt[LONGNAME]) then
		-- Ignore 'extras' record
		return
	end if
	
	integer has_param = find(HAS_PARAMETER, opt[OPTIONS])
	sequence param_name
	if has_param != 0 then
		if has_param < length(opt[OPTIONS]) then
			has_param += 1
			if sequence(opt[OPTIONS][has_param]) then
				param_name = opt[OPTIONS][has_param]
			else
				param_name = "x"
			end if
		else
			param_name = "x"
		end if
	end if
	integer is_mandatory = (find(MANDATORY, opt[OPTIONS]) != 0)
	sequence cmd = ""

	if sequence(opt[SHORTNAME]) then
		if not is_mandatory then
			cmd &= '['
		end if
		cmd &= '-' & opt[SHORTNAME]
		if has_param != 0 then
			cmd &= ' ' & param_name
		end if
		if not is_mandatory then
			cmd &= ']'
		end if
	end if

	if sequence(opt[LONGNAME]) then
		if length(cmd) > 0 then cmd &= ", " end if
		if not is_mandatory then
			cmd &= '['
		end if
		cmd &= "--" & opt[LONGNAME]
		if has_param != 0 then
			cmd &= '=' & param_name
		end if
		if not is_mandatory then
			cmd &= ']'
		end if
	end if
	
	-- If command is longer than the pad_size, display the command and it's 
	-- description on seperate lines
	
	if length(cmd) > pad_size then
		puts(1, "   " & cmd & '\n')
		puts(1, repeat(' ', pad_size + 3))
	else
		puts(1, "   " & stdseq:pad_tail(cmd, pad_size))
	end if
	
	puts(1, opt[DESCRIPTION] & '\n')
end procedure

--****
-- === Routines

--****
-- Signature:
-- <built-in> function command_line()
--
-- Description:
-- returns sequence of strings containing each word entered at the command-line that started your program.
--
-- Returns:
-- # The ##path##, to either the Euphoria executable (##eui##, ##eui.exe##, ##euid.exe##, ##euiw.exe##) or to your bound
--   executable file.
-- # The ##next word##, is either the name of your Euphoria main file or
-- (again) the path to your bound executable file.
-- # Any ##extra words##, typed by the user. You can use these words in your program.
--
-- There are as many entries as words, plus the two mentioned above.
--
-- The Euphoria interpreter itself does not use any command-line options. You are free to use
-- any options for your own program. The interpreter does have [[:command line switches]] though.
--
-- The user can put quotes around a series of words to make them into a single argument.
--
-- If you convert your program into an executable file, either by binding it, or translationg it to C,
-- you will find that all command-line arguments remain the same, except for the first two,
-- even though your user no longer types "eui" on the command-line (see examples below).
--
-- Example 1:
-- <eucode>
--  -- The user types:  eui myprog myfile.dat 12345 "the end"
--
-- cmd = command_line()
--
-- -- cmd will be:
--       {"C:\EUPHORIA\BIN\EUI.EXE",
--        "myprog",
--        "myfile.dat",
--        "12345",
--        "the end"}
-- </eucode>
--
-- Example 2:
-- <eucode>
-- -- Your program is bound with the name "myprog.exe"
-- -- and is stored in the directory c:\myfiles
-- -- The user types:  myprog myfile.dat 12345 "the end"
--
-- cmd = command_line()
--
-- -- cmd will be:
--        {"C:\MYFILES\MYPROG.EXE",
--         "C:\MYFILES\MYPROG.EXE", -- place holder
--         "myfile.dat",
--         "12345",
--         "the end"
--         }
--
-- -- Note that all arguments remain the same as in Example 1
-- -- except for the first two. The second argument is always
-- -- the same as the first and is inserted to keep the numbering
-- -- of the subsequent arguments the same, whether your program
-- -- is bound or translated as a .exe, or not.
-- </eucode>
--
-- See Also:
-- [[:build_commandline]], [[:option_switches]],  [[:getenv]], [[:cmd_parse]], [[:show_help]]

--****
-- Signature:
-- <built-in> function option_switches()
--
-- Description:
-- retrieves the list of switches passed to the interpreter on the command line.
--
-- Returns:
-- A **sequence**, of strings, each containing a word related to switches.
--
-- Comments:
--
-- All switches are recorded in upper case.
--
-- Example 1:
-- <eucode>
-- euiw -d helLo
-- -- will result in
-- -- option_switches() being {"-D","helLo"}
-- </eucode>
--
-- See Also:
-- [[:Command line switches]]

--**
-- shows the help message for the given opts.
--
-- Parameters:
-- # ##opts## : a sequence of options. See the [[:cmd_parse]] for details.
-- # ##add_help_rid## : an object. Either a routine_id or a set of text strings.
-- The default is -1 meaning that no additional help text will be used.
-- # ##cmds## : a sequence of strings. By default this is the output from [[:command_line]]
-- # ##parse_options## : An option set of behavior modifiers.  See the [[:cmd_parse]] for details.
--
-- Comments:
-- * ##opts## is identical to the one used by [[:cmd_parse]]
-- * ##add_help_rid## can be used to provide additional help text. By default, just
-- the option switches and their descriptions will be displayed. However you can
-- provide additional text by either supplying a routine_id of a procedure that
-- accepts no parameters; this procedure is expected to write text to the stdout
-- device. Or you can supply one or more lines of text that will be displayed.
--
-- Example 1:
-- <eucode>
-- -- in myfile.ex
-- constant description = {
--        "Creates a file containing an analysis of the weather.",
--        "The analysis includes temperature and rainfall data",
--        "for the past week."
--     }
--
-- show_help({
--     {"q", "silent", "Suppresses any output to console", NO_PARAMETER, -1},
--     {"r", 0, "Sets how many lines the console should display", 
--     {HAS_PARAMETER,"lines"}, -1}}, description)
-- </eucode>
-- Outputs~:
-- {{{
-- myfile.ex options:
--   -q, --silent      Suppresses any output to console
--   -r lines          Sets how many lines the console should display
--
-- Creates a file containing an analysis of the weather.
-- The analysis includes temperature and rainfall data
-- for the past week.
-- }}}
--
-- Example 2:
-- <eucode>
-- -- in myfile.ex
-- constant description = {
--        "Creates a file containing an analysis of the weather.",
--        "The analysis includes temperature and rainfall data",
--        "for the past week."
--     }
-- procedure sh()
--   for i = 1 to length(description) do
--      printf(1, " >> %s <<\n", {description[i]})
--   end for
-- end procedure
--
-- show_help({
--     {"q", "silent", "Suppresses any output to console", NO_PARAMETER, -1},
--     {"r", 0, "Sets how many lines the console should display", 
--      {HAS_PARAMETER,"lines"}, -1}}, routine_id("sh"))
-- </eucode>
-- Outputs~:
-- {{{
-- myfile.ex options:
--   -q, --silent      Suppresses any output to console
--   -r lines          Sets how many lines the console should display
--
--   >> Creates a file containing an analysis of the weather. <<
--   >> The analysis includes temperature and rainfall data  <<
--   >> for the past week.  <<
-- }}}
--

public procedure show_help(sequence opts, object add_help_rid=-1, sequence cmds = command_line(), object parse_options = {})
    local_help(opts, add_help_rid, cmds, 0, parse_options)
end procedure

function find_opt(sequence opts, sequence opt_style, object cmd_text)
	sequence opt_name
	object opt_param
	integer param_found = 0
	integer reversed = 0

	if length(cmd_text) >= 2 then
		-- Strip off any enclosing quotes
		if cmd_text[1] = '\'' or cmd_text[1] = '"' then
			if cmd_text[$] = cmd_text[1] then
				cmd_text = cmd_text[2 .. $-1]
			end if
		end if
	end if

	if length(cmd_text) > 0 then
		if find(cmd_text[1], "!-") then
			reversed = 1
			cmd_text = cmd_text[2 .. $]
		end if
	end if

	if length(cmd_text) < 1 then
		return {-1, "Empty command text"}
	end if

	opt_name = repeat(' ', length(cmd_text))
	opt_param = 0
	for i = 1 to length(cmd_text) do
		if find(cmd_text[i], ":=") then
			opt_name = opt_name[1 .. i - 1]
			opt_param = cmd_text[i + 1 .. $]
			if length(opt_param) >= 2 then
				-- Strip off any enclosing quotes
				if opt_param[1] = '\'' or opt_param[1] = '"' then
					if opt_param[$] = opt_param[1] then
						opt_param = opt_param[2 .. $-1]
					end if
				end if
			end if

			if length(opt_param) > 0 then
				param_found = 1
			end if

			exit
		else
			opt_name[i] = cmd_text[i]
		end if
	end for

	if param_found then
		if find( text:lower(opt_param), {"1", "on", "yes", "y", "true", "ok", "+"}) then
			opt_param = 1
		elsif find( text:lower(opt_param), {"0", "off", "no", "n", "false", "-"}) then
			opt_param = 0
		end if
	end if

	for i = 1 to length(opts) do
		if find(NO_CASE,  opts[i][OPTIONS]) then
			if not equal( text:lower(opt_name), text:lower(opts[i][opt_style[1]])) then
				continue
			end if
		else
			if not equal(opt_name, opts[i][opt_style[1]]) then
				continue
			end if
		end if

		if find(HAS_PARAMETER,  opts[i][OPTIONS]) = 0 then
			if param_found then
				return {0, "Option should not have a parameter"}
			end if
		end if

		if param_found then
			return {i, opt_name, reversed, opt_param}
		else
			if find(HAS_PARAMETER, opts[i][OPTIONS]) = 0 then
				return {i, opt_name, reversed, 1 }
			end if

			return {i, opt_name, reversed}
		end if
	end for

	return {0, "Unrecognised"}
end function

function get_help_options( sequence opts )
	sequence help_opts = {}
	
	for i = 1 to length(opts) do
		if find(HELP, opts[i][OPTIONS]) then
			if sequence(opts[i][SHORTNAME]) then
				help_opts = append(help_opts, opts[i][SHORTNAME])
			end if
			
			if sequence(opts[i][LONGNAME]) then
				help_opts = append(help_opts, opts[i][LONGNAME])
			end if
			
			if find(NO_CASE, opts[i][OPTIONS]) then
				help_opts = text:lower(help_opts)
				for j = 1 to length(help_opts) do
					help_opts = append( help_opts, text:upper(help_opts[j]) )
				end for
			end if
		end if
	end for
	return help_opts
end function

function parse_at_cmds( sequence cmd, sequence cmds, sequence opts, integer arg_idx, object add_help_rid,
						object parse_options, integer help_on_error, integer auto_help )
	-- Called to parse out a command option that's an @file
	-- returns the new list of commands after expansion
	
	object at_cmds
	integer j

	if length(cmd) > 2 and cmd[2] = '@' then
		-- Read in the lines from the optional file.
		at_cmds = io:read_lines(cmd[3..$])
		if equal(at_cmds, -1) then
			-- File didn't exist but this is not an error, so just
			-- remove it from the commands.
			cmds = eu:remove(cmds, arg_idx)
			return cmds
		end if
	else
		-- Read in the lines from the file.
		at_cmds = io:read_lines(cmd[2..$])
		if equal(at_cmds, -1) then
			printf(2, "Cannot access '@' argument file '%s'\n", {cmd[2..$]})
			if help_on_error then
				local_help(opts, add_help_rid, cmds, 1, parse_options)
			elsif auto_help then
				printf(2,"Try '--help' for more information.\n",{})          
			end if
			local_abort(1)
		end if
	end if
	-- Parse the 'at' commands removing comment lines and empty lines,
	-- and stripping off any enclosing quotes from lines.
	j = 0
	while j < length(at_cmds) do
		j += 1
		at_cmds[j] = text:trim(at_cmds[j])
		if length(at_cmds[j]) = 0 then
			at_cmds = at_cmds[1 .. j-1] & at_cmds[j+1 ..$]
			j -= 1

		elsif at_cmds[j][1] = '#' then
			at_cmds = at_cmds[1 .. j-1] & at_cmds[j+1 ..$]
			j -= 1

		elsif at_cmds[j][1] = '"' and at_cmds[j][$] = '"' and length(at_cmds[j]) >= 2 then
			at_cmds[j] = at_cmds[j][2 .. $-1]

		elsif at_cmds[j][1] = '\'' and at_cmds[j][$] = '\'' and length(at_cmds[j]) >= 2 then
			sequence cmdex = stdseq:split(at_cmds[j][2 .. $-1],' ', 1) -- Empty words removed.

			at_cmds = replace(at_cmds, cmdex, j)
			j = j + length(cmdex) - 1

		end if
	end while

	-- Replace the '@' argument with the contents of the file.
	cmds = replace(cmds, at_cmds, arg_idx)
	return cmds
end function


procedure check_mandatory( sequence opts, map parsed_opts, object add_help_rid, sequence cmds, object parse_options,
	integer help_on_error, integer auto_help )
	-- Check options to make sure all the manadory options are covered
	for i = 1 to length(opts) do
		if find(MANDATORY, opts[i][OPTIONS]) then
			if atom(opts[i][SHORTNAME]) and atom(opts[i][LONGNAME]) then
				if length(map:get(parsed_opts, opts[i][MAPNAME])) = 0 then
					puts(1, "Additional arguments were expected.\n\n")
					if help_on_error then
						local_help(opts, add_help_rid, cmds, 1, parse_options)
					elsif auto_help then
						printf(2,"Try '--help' for more information.\n",{})          
					end if
					local_abort(1)
				end if
			else
				if not map:has(parsed_opts, opts[i][MAPNAME]) then
					printf(1, "option '%s' is mandatory but was not supplied.\n\n", {opts[i][MAPNAME]})
					if help_on_error then
						local_help(opts, add_help_rid, cmds, 1, parse_options)
					elsif auto_help then
						printf(2,"Try '--help' for more information.\n",{})          
					end if
					local_abort(1)
				end if
			end if
		end if
	end for
end procedure

procedure parse_abort( sequence format_msg, sequence msg_data,
		sequence opts, object add_help_rid, sequence cmds, object parse_options, integer help_on_error, integer auto_help )
-- something is wrong with the option
	printf(1, format_msg, msg_data)
	if help_on_error then
		local_help(opts, add_help_rid, cmds, 1, parse_options)
	elsif auto_help then
		printf(2,"Try '--help' for more information.\n",{})          
	end if
	local_abort(1)
end procedure

function parse_commands( sequence cmds, sequence opts, map parsed_opts, sequence help_opts, 
		object add_help_rid, object parse_options, integer use_at, integer validation, 
		integer has_extra, sequence call_count, integer help_on_error, integer auto_help )
	-- Parses the actual command line vs the options
	-- Returns a two element sequence:
	--  1: the list of command line options (may be altered due to @file expansion)
	--  2: the option call_count tally
	
	integer arg_idx = 2
	integer opts_done = 0
	sequence find_result
	sequence type_
	integer from_
	sequence cmd
	
	while arg_idx < length(cmds) do
		arg_idx += 1

		cmd = cmds[arg_idx]
		if length(cmd) = 0 then
			continue
		end if

		if cmd[1] = '@' and use_at then
			cmds = parse_at_cmds( cmd, cmds, opts, arg_idx, add_help_rid, parse_options, help_on_error, auto_help )
			arg_idx -= 1
			continue
		end if

		if (opts_done or find(cmd[1], os:CMD_SWITCHES) = 0 or length(cmd) = 1)
		then
			map:put(parsed_opts, EXTRAS, cmd, map:APPEND)
			has_extra = 1
			if validation = NO_VALIDATION_AFTER_FIRST_EXTRA then
				for i = arg_idx + 1 to length(cmds) do
					map:put(parsed_opts, EXTRAS, cmds[i], map:APPEND)
				end for
				
				exit
			else
				continue
			end if
		end if

		if equal(cmd, "--") then
			opts_done = 1
			continue
		end if

		if equal(cmd[1..2], "--") then	  -- found --opt-name
			type_ = {LONGNAME, "--"}
			from_ = 3
		elsif cmd[1] = '-' then -- found -opt
			type_ = {SHORTNAME, "-"}
			from_ = 2
		else  -- found /opt
			type_ = {SHORTNAME, "/"}
			from_ = 2
		end if

		if find(cmd[from_..$], help_opts) then
			local_help(opts, add_help_rid, cmds, 1, parse_options)
			ifdef UNITTEST then
				return 0
			end ifdef
			local_abort(0)
		end if

		find_result = find_opt(opts, type_, cmd[from_..$])

		if find_result[1] < 0 then
			continue -- Couldn't use this command argument for anything.
		end if

		if find_result[1] = 0 then
			if validation = VALIDATE_ALL or
				(validation = NO_VALIDATION_AFTER_FIRST_EXTRA and has_extra = 0)
			then
				-- something is wrong with the option
				parse_abort( "option '%s': %s\n\n", {cmd, find_result[2]}, 
					opts, add_help_rid, cmds, parse_options, help_on_error, auto_help )
			end if

			continue
		end if

		sequence handle_result = handle_opt( find_result, arg_idx, opts, parsed_opts, cmds, add_help_rid,
			parse_options, call_count, validation, help_on_error, auto_help )
		arg_idx     = handle_result[1]
		call_count = handle_result[2]
	end while
	return { cmds, call_count }
end function

function handle_opt( sequence find_result, integer arg_idx, sequence opts, map parsed_opts,
		sequence cmds, object add_help_rid, object parse_options, sequence call_count,
		integer validation, integer help_on_error, integer auto_help )
	-- Called to deal with an option found on the command line
	-- Returns 2 element sequence:
	--  1: the new arg_idx
	--  2: the call_count tally
	
	integer map_add_operation = map:ADD
	sequence opt = opts[find_result[1]]
	object param
	
	if find(HAS_PARAMETER, opt[OPTIONS]) != 0 then
		map_add_operation = map:APPEND
		if length(find_result) < 4 then
			arg_idx += 1
			if arg_idx <= length(cmds) then
				param = cmds[arg_idx]
				if length(param) = 2 and find(param[1], "-/") then
					param = ""
				end if
			else
				param = ""
			end if

			if length(param) = 0 and (validation = VALIDATE_ALL or (
				validation = NO_VALIDATION_AFTER_FIRST_EXTRA))
			then
				parse_abort( "option '%s' must have a parameter\n\n", {find_result[2]}, 
					opts, add_help_rid, cmds, parse_options, help_on_error, auto_help )
			end if
		else
			param = find_result[4]
		end if
	else
		param = find_result[4]
	end if

	if opt[CALLBACK] >= 0 then
		integer pos = find_result[1]
		call_count[pos] += 1
		--                              OPT_IDX        OPT_CNT         OPT_VAL  OPT_REV
		if call_func(opt[CALLBACK], {{find_result[1], call_count[pos], param,  find_result[3]}}) = 0 then
			return { arg_idx, call_count }
		end if
	end if

	if find_result[3] = 1 then
		map:remove(parsed_opts, opt[MAPNAME])
	else
		if find(MULTIPLE, opt[OPTIONS]) = 0 then
			if map:has(parsed_opts, opt[MAPNAME]) and (validation = VALIDATE_ALL or
				(validation = NO_VALIDATION_AFTER_FIRST_EXTRA))
			then
				if find(HAS_PARAMETER, opt[OPTIONS]) or find(ONCE, opt[OPTIONS]) then
					parse_abort( "option '%s' must not occur more than once in the command line.\n\n", 
						{find_result[2]}, opts, add_help_rid, cmds, parse_options, help_on_error, auto_help )
				end if
			else
				map:put(parsed_opts, opt[MAPNAME], param)
			end if
		else
			map:put(parsed_opts, opt[MAPNAME], param, map_add_operation)
		end if
	end if

	if find(VERSIONING, opt[OPTIONS]) then
		integer ver_pos = find(VERSIONING, opt[OPTIONS]) + 1
		if length(opt[OPTIONS]) >= ver_pos then
			printf(1, "%s\n", { opt[OPTIONS][ver_pos] })
			abort(0)
		else
			error:crash("help options are incorrect,\n" &
				"VERSIONING was used with no version string supplied")
		end if
	end if
	return {arg_idx, call_count}
end function

--**
-- parses command line options and optionally calls procedures based on these options.
--
-- Parameters:
-- # ##opts## : a sequence of records that define the various command line
-- //switches// and //options// that are valid for the application: See Comments: section for details
-- # ##parse_options## : an optional list of special behavior modifiers: See Parse Options section for details
-- # ##cmds## : an optional sequence of command line arguments. If omitted the output from
--              ##command_line## is used.
--
-- Returns:
-- A **map**, containing the set of actual options used in ##cmds##. The returned
-- map has one special key, ##EXTRAS## that are values passed on the
-- command line that are not part of any of the defined options. This is commonly
-- used to get the list of files entered on the command line. For instance, if
-- the command line used was //##myprog -verbose file1.txt file2.txt##// then
-- the ##EXTRAS## data value would be ##{"file1.txt", "file2.txt"}##.
--
-- When any command item begins with an **##@##** symbol then it is assumed
-- that it prefixes a file name. That file will then be opened and its contents used
-- to add to the command line, as if the file contents had actually been entered as 
-- part of the original command line.
--
-- Parse Options~:
-- ##parse_options## is used to provide a set of behavior modifiers that change the
-- default rules for parsing the command line. If used, it is a list of values
-- that will affect the parsing of the command line options. 
--
-- These modifers can be any combination of~:
--
-- # ##VALIDATE_ALL## ~-- The default. All options will be validated for all possible errors.
-- # ##NO_VALIDATION## ~-- Do not validate any parameter.
-- # ##NO_VALIDATION_AFTER_FIRST_EXTRA## ~-- Do not validate any parameter after the first extra
--   was encountered. This is helpful for programs such as the Interpreter itself:
--   ##eui -D TEST greet.ex -name John##. -D TEST should be validated but anything after
--   "greet.ex" should not as it is meant for greet.ex to handle, not eui.
-- # ##HELP_RID## ~-- The next Parse Option must either a routine id or a set of
--   text strings. The routine is called or the text is displayed when a parse error
--  (invalid option given, mandatory option not given, no parameter given for an option that requires a
--   parameter, etc...) occurs. This can be used to provide additional
--   help text. By default, just the option switches and their descriptions will be
--   displayed. However you can provide additional text by either supplying a
--   routine_id of a procedure that accepts no parameters, or a sequence containing
--   lines of text (one line per element).  The procedure is expected
--   to write text to the stdout device.
-- # ##NO_HELP_ON_ERROR## ~-- Do not show a list of options on a command line error.
-- # ##NO_HELP## ~-- Do not automatically add the switches '-h', '-?', and '--help'
--   to display the help text (if any).
-- # ##NO_AT_EXPANSION## ~-- Do not expand arguments that begin with '@.'
-- # ##AT_EXPANSION## ~-- Expand arguments that begin with '@'.  The name that follows @ will be
--   opened as a file, read, and each trimmed non-empty line that does not begin with a
--   '#' character will be inserted as arguments in the command line. These lines
--   replace the original '@' argument as if they had been entered on the original
--   command line. \\
--   ** If the name following the '@' begins with another '@', the extra
--   '@' is removed and the remainder is the name of the file. However, if that
--   file cannot be read, it is simply ignored. This allows //optional// files
--   to be included on the command line. Normally, with just a single '@', if the
--   file cannot be found the program aborts.
--   ** Lines whose first non-whitespace character is '#' are treated as a comment
--   and thus ignored.
--   ** Lines enclosed with double quotes will have the quotes stripped off and the
--   result is used as an argument. This can be used for arguments that begin with
--   a '#' character, for example.
--   ** Lines enclosed with single quotes will have the quotes stripped off and
--   the line is then further split up use the space character as a delimiter. The
--   resulting 'words' are then all treated as individual arguments on the command
--   line.
--
-- An example of parse options~:
-- <eucode>
-- { HELP_RID, routine_id("my_help"), NO_VALIDATION }
-- </eucode>
--
-- Comments:
-- Token types recognized on the command line~:
-- 
-- # a single '-'. Simply added to the 'extras' list
-- # a single "~-~-". This signals the end of command line options. What remains of the command
--   line is added to the 'extras' list, and the parsing terminates.
-- # -shortName. The option will be looked up in the short name field of ##opts##.
-- # /shortName. Same as -shortName.
-- # -!shortName. If the 'shortName' has already been found the option is removed.
-- # /!shortName. Same as -!shortName
-- # ~-~-longName. The option will be looked up in the long name field of ##opts##.
-- # ~-~-!longName. If the 'longName' has already been found the option is removed.
-- # anything else. The word is simply added to the 'extras' list.
--
-- For those options that require a parameter to also be supplied, the parameter
-- can be given as either the next command line argument, or by appending '=' or ':'
-- to the command option then appending the parameter data. \\
-- For example, **##-path=/usr/local##** or as **##-path /usr/local##**.
--
-- On a failed lookup, the program shows the help by calling [[:show_help]](##opts##,
-- ##add_help_rid##, ##cmds##) and terminates with status code 1.
--
-- If you do not explicitly define the switches ##-h##, ##-?##, or ##--help##,
-- these will be automatically added to the list of valid switches and will be
-- set to call the [[:show_help]] routine. 
--
-- You can remove any of these as default 'help' switches simply by explicitly 
-- using them for something else.
--
-- You can also remove all of these switches as //automatic// help switches by
-- using the ##NO_HELP## parsing option. This just means that these switches are
-- not automatically used as 'help' switches, regardless of whether they are used
-- explicitly or not. So if ##NO_HELP## is used, and you want to give the user
-- the ability to display the 'help' then you must explicitly set up your own
-- switch to do so. **N.B**, the 'help' is still displayed if an invalid command
-- line switch is used at runtime, regardless of whether ##NO_HELP## is used or not.
--
-- Option records have the following structure~:
-- # a sequence representing the (short name) text that will follow the "-" option format.
--  Use an atom if not relevant
-- # a sequence representing the (long name) text that will follow the "~-~-" option format.
--  Use an atom if not relevant
-- # a sequence, text that describes the option's purpose. Usually short as it is
--   displayed when "-h"/"--help" is on the command line. Use an atom if not required.
-- # An object ...
--  ** If an **atom** then it can be either ##HAS_PARAMETER## or anything
--     else if there is no parameter for this option. This format also implies that
--     the option is optional, case-sensitive and can only occur once.
--  ** If a **sequence**, it can containing zero or more processing flags in any order ...
--   *** ##MANDATORY## to indicate that the option must always be supplied.
--   *** ##HAS_PARAMETER## to indicate that the option must have a parameter following it.
--      You can optionally have a name for the parameter immediately follow the ##HAS_PARAMETER##
--      flag. If one isn't there, the help text will show "x" otherwise it shows the
--      supplied name.
--   *** ##NO_CASE## to indicate that the case of the supplied option is not significant.
--   *** ##ONCE## to indicate that the option must only occur once on the command line.
--   *** ##MULTIPLE## to indicate that the option can occur any number of times on the command line.
--  ** If both ##ONCE## and ##MULTIPLE## are omitted then switches that also have
--     ##HAS_PARAMETER## are only allowed once but switches without ##HAS_PARAMETER##
--     can have multuple occurances but only one is recorded in the output map.
-- # an integer; a [[:routine_id]]. This function will be called when the option is located
--   on the command line and before it updates the map. \\
--   Use -1 if cmd_parse is not to invoke a function for this option.\\
--   The user defined function must accept a single sequence parameter containing four values.
--   If the function returns ##1## then the command option does not update the map.
--   You can use the predefined index values ##OPT_IDX##, ##OPT_CNT##, ##OPT_VAL##, ##OPT_REV## when
--   referencing the function's parameter elements.
--   ## An index into the ##opts## list.
--   ## The number of times that the routine has been called
--      by cmd_parse for this option
--   ## The option's value as found on the command line
--   ## 1 if the command line indicates that this option is to remove any earlier occurrences of it.
--
-- One special circumstance exists and that is an option group header. It should contain only
-- two elements~:
--   # The header constant: HEADER
--   # A sequence to display as the option group header
--
-- When assigning a value to the resulting map, the key is the long name if present,
-- otherwise it uses the short name. For options, you must supply a short name,
-- a long name or both.
--
-- If you want ##cmd_parse## to call a user routine for the extra command line values,
-- you need to specify an Option Record that has neither a short name or a long name,
-- in which case only the routine_id field is used.
--
-- For more details on how the command line is being pre-parsed, see [[:command_line]].
--
-- Example 1:
-- <eucode>
--    -- simple usage
--
-- map args = cmd_parse({  
--     { "o", 0, "Output directory", { HAS_PARAMETER } },  
--     { "v", 0, "Verbose mode" }  
-- })
--
-- if map:get(args, "v") then
--     printf(1, "Output directory is %s\n", { map:get(args, "o") })
-- end if
-- </eucode>
--
-- Example 2:
-- <eucode>
--     -- complex usage
--
-- sequence option_definition
-- integer gVerbose = 0
-- sequence gOutFile = {}
-- sequence gInFile = {}
-- function opt_verbose( sequence value)
--    if value[OPT_VAL] = -1 then -- (-!v used on command line)
--    	gVerbose = 0
--    else
--      if value[OPT_CNT] = 1 then
--         gVerbose = 1
--      else
--         gVerbose += 1
--      end if
--    end if
-- 	return 1
-- end function
--
-- function opt_output_filename( sequence value)
--    gOutFile = value[OPT_VAL]
-- 	return 1
-- end function
--
-- function extras( sequence value)
--    if not file_exists(value[OPT_VAL]) then
--        show_help(option_definition, sprintf("Cannot find '%s'", 
--                  {value[OPT_VAL]}) )
--        abort(1)
--    end if
--    gInFile = append(gInFile, value[OPT_VAL])
-- 	return 1
-- end function
--
-- option_definition = {
--     { HEADER,         "General options" },
--     { "h", "hash",    "Calc hash values", { NO_PARAMETER }, -1 },
--     { HEADER,         "Input and output" },
--     { "o", "output",  "Output filename",  { MANDATORY, HAS_PARAMETER, ONCE } , 
--                                             routine_id("opt_output_filename") },
--     { "i", "import",  "An import path",   { HAS_PARAMETER, MULTIPLE}, -1 },
--     { HEADER,         "Miscellaneous" },
--     { "v", "verbose", "Verbose output",   { NO_PARAMETER }, routine_id("opt_verbose") },
--     { "e", "version", "Display version",  { VERSIONING, "myprog v1.0" } },
--     {  0, 0, 0, 0, routine_id("extras")}
-- }
--
-- map:map opts = cmd_parse(option_definition, NO_HELP)
--
-- -- When run as: 
-- --             eui myprog.ex -v @output.txt -i /etc/app input1.txt input2.txt
-- -- and the file "output.txt" contains the two lines ...
-- --   --output=john.txt
-- --   '-i /usr/local'
-- --
-- -- map:get(opts, "verbose") --> 1
-- -- map:get(opts, "hash") --> 0 (not supplied on command line)
-- -- map:get(opts, "output") --> "john.txt"
-- -- map:get(opts, "import") --> {"/usr/local", "/etc/app"}
-- -- map:get(opts, EXTRAS) --> {"input1.txt", "input2.txt"}
-- </eucode>
--
-- See Also:
--   [[:show_help]], [[:command_line]]

public function cmd_parse(sequence opts, object parse_options = {}, sequence cmds = command_line())
	sequence cmd
	sequence help_opts
	sequence call_count
	object add_help_rid = -1
	integer validation = VALIDATE_ALL
	integer has_extra = 0
	integer use_at = 1
	integer auto_help = 1
	integer help_on_error = 1

	integer po = 1
	if atom(parse_options) then
		parse_options = {parse_options}
	end if
	
	-- set flags based on the parse options
	while po <= length(parse_options) do
		switch parse_options[po] do
		
			case NO_HELP then                         auto_help = 0
			case VALIDATE_ALL then                    validation = VALIDATE_ALL
			case NO_VALIDATION then                   validation = NO_VALIDATION
			case NO_VALIDATION_AFTER_FIRST_EXTRA then validation = NO_VALIDATION_AFTER_FIRST_EXTRA
			case NO_AT_EXPANSION then                 use_at = 0
			case AT_EXPANSION then                    use_at = 1
			
			case HELP_RID then
				if po < length(parse_options) then
					po += 1
					add_help_rid = parse_options[po]
				else
					error:crash("HELP_RID was given to cmd_parse with no routine_id")
				end if

			case NO_HELP_ON_ERROR then
				-- if this is not from show_
				help_on_error = 0

			case PAUSE_MSG then
				if po < length(parse_options) then
					po += 1
					pause_msg = parse_options[po]
				else
					error:crash("PAUSE_MSG was given to cmd_parse with no actual message text")
				end if
				
			case else
				error:crash(sprintf("Unrecognised cmdline PARSE OPTION - %d", parse_options[po]) )
				
		end switch
		po += 1
	end while

	opts = standardize_opts(opts, auto_help)
	call_count = repeat(0, length(opts))

	map:map parsed_opts = map:new()
	map:put(parsed_opts, EXTRAS, {})

	-- Find if there are any help options.
	help_opts = get_help_options( opts )
	
	object cmds_ok = parse_commands( cmds, opts, parsed_opts, help_opts, add_help_rid, parse_options, 
		use_at, validation, has_extra, call_count, help_on_error, auto_help )
	if atom( cmds_ok ) then
		return 0
	end if
	cmds       = cmds_ok[1]
	call_count = cmds_ok[2]
	
	-- Check that all mandatory options have been supplied. (may abort)
	check_mandatory( opts, parsed_opts, add_help_rid, cmds, parse_options, help_on_error, auto_help )
	
	return parsed_opts
end function


--**
-- returns a text string based on the set of supplied strings. 
--
-- Parameters:
--   # ##cmds## : A sequence. Contains zero or more strings.
--
-- Returns:
--	A **sequence**, which is a text string. Each of the strings in ##cmds## is
--  quoted if they contain spaces, and then concatenated to form a single
--  string.
--
-- Comments:
-- Typically, this
-- is used to ensure that arguments on a command line are properly formed
-- before submitting it to the shell.
--
--   Though this function does the quoting for you it is not going to protect
--   your programs from globing ##*##, ##?## .  And it is not specied here what happens if you
--   pass redirection or piping characters.
--
--   When passing a result from with build_commandline to [[:system_exec]],
--   file arguments will benefit from using [[:canonical_path]] with the [[:TO_SHORT]].
--   On //Windows// this is required for file arguments to always work.  There is a complication
--   with files that contain spaces.  On //Unix// 
--   this call will also return a useable filename. 
--
--   Alternatively, you can leave out calls to [[:canonical_path]] and use [[:system]] instead.
--
-- Example 1:
-- <eucode>
-- s = build_commandline( { "-d", canonical_path("/usr/my docs/",,TO_SHORT)} )
-- -- s now contains a short name equivalent to '-d "/usr/my docs/"'
-- </eucode>
--
-- Example 2:
--     You can use this to run things that might be difficult to quote out.
--     Suppose you want to run a program that requires quotes on its
--     command line?  Use this function to pass quotation marks~:
--
-- <eucode>
-- s = build_commandline( { "awk", "-e", "'{ print $1"x"$2; }'" } )
-- system(s,0)
-- </eucode>
--
-- See Also:
--   [[:parse_commandline]], [[:system]], [[:system_exec]], [[:command_line]], 
--   [[:canonical_path]],  [[:TO_SHORT]] 

public function build_commandline(sequence cmds)
	return stdseq:flatten( text:quote( cmds,,'\\'," " ), " ")
end function

--**
-- parses a command line string breaking it into a sequence of command line
-- options.
--
-- Parameters:
--   # ##cmdline## : Command line sequence (string)
--
-- Returns:
--   A **sequence**, of command line options
--
-- Example 1:
-- <eucode>
-- sequence opts = parse_commandline("-v -f '%Y-%m-%d %H:%M'")
-- -- opts = { "-v", "-f", "%Y-%m-%d %H:%M" }
-- </eucode>
--
-- See Also:
--   [[:build_commandline]]
--

public function parse_commandline(sequence cmdline)
	return keyvalues(cmdline, " ", ":=", "\"'`", " \t\r\n", 0)
end function
