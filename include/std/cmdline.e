--****
-- == Command Line Handling
--
-- <<LEVELTOC depth=2>>

include std/text.e
include std/sequence.e as seq
include std/map.e as map
include std/error.e
include std/os.e
include std/io.e as io

ifdef UNIX then
	constant valid_switches = "-"
elsedef
	constant valid_switches = "-/"
end ifdef

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
	
	--** This option switch triggers the 'help' display. See [[:cmd_parse]]
	HELP          = 'h'
	
public constant
	NO_HELP       = -2

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
	-- For instance:
	-- ##eui -D TEST greet.ex -name John -greeting Bye##
	-- -D TEST is meant for ##eui##, but -name and -greeting options
	-- are meant for ##greet.ex##. See [[:cmd_parse]]
	--
	--
	-- ##eui @euopts.txt greet.ex @hotmail.com##
	-- here 'hotmail.com' is not expanded into the command line but
	-- 'euopts.txt' is.
	NO_VALIDATION_AFTER_FIRST_EXTRA,

	--**
	-- Only display the option list in show_help. Do not display other
	-- information such as program name, options, etc... See [[:cmd_parse]]
	SHOW_ONLY_OPTIONS,
	
	--**
	-- Expand arguments that begin with '@' into the command line. (default)
	-- For example, @filename will expand the contents of file named 'filename' 
	-- as if the file's contents were passed in on the command line.  Arguments
	-- that come after the first extra will not be expanded when 
	-- NO_VALIDATION_AFTER_FIRST_EXTRA is specified.
	AT_EXPANSION,
	
	--**
	-- Do not expand arguments that begin with '@' into the command line.
	-- Normally @filename will expand the file names contents as if the
	-- file's contents were passed in on the command line.  This option 
	-- supresses this behavior.
	NO_AT_EXPANSION
	
--

public enum
	--**
	--   An index into the ##opts## list. See [[:cmd_parse]]
	OPT_IDX,
	
	--**
	--   The number of times that the routine has been called
	--   by cmd_parse for this option. See [[:cmd_parse]]
	OPT_CNT,
	
	--**
	--  The option's value as found on the command line. See [[:cmd_parse]]
	OPT_VAL,
	
	--**
	--  The value ##1## if the command line indicates that this option is to remove
	--  any earlier occurrences of it. See [[:cmd_parse]]
	OPT_REV
	
	
-- Record fields in 'opts' argument.
enum
	SHORTNAME = 1,
	LONGNAME = 2,
	DESCRIPTION = 3,
	OPTIONS = 4,
	CALLBACK = 5,
	MAPNAME = 6


-- Local routine to validate and reformat option records if they are not in the standard format.
function standardize_opts(sequence opts, integer add_help_options=1)
	integer lExtras = 0 -- Ensure that there is zero or one 'extras' record only.
	
	for i = 1 to length(opts) do
		sequence opt = opts[i]
		integer updated = 0
		
		if length(opt) < MAPNAME then
			opt &= repeat(-1, MAPNAME - length(opt))
			updated = 1
		end if
		
		if sequence(opt[SHORTNAME]) and length(opt[SHORTNAME]) = 0 then
			opt[SHORTNAME] = 0
			updated = 1
		end if
		
		if sequence(opt[LONGNAME]) and length(opt[LONGNAME]) = 0 then
			opt[LONGNAME] = 0
			updated = 1
		end if
		
		if atom(opt[LONGNAME]) and atom(opt[SHORTNAME]) then
			if lExtras != 0 then
				crash("cmd_opts: There must be less than two 'extras' option records.\n")
			else
				lExtras = i
				if atom(opt[MAPNAME]) then
					opt[MAPNAME] = "extras"
					updated = 1
				end if
			end if
		end if
		
		if atom(opt[DESCRIPTION]) then
			opt[DESCRIPTION] = ""
			updated = 1
		end if
		

		if atom(opt[OPTIONS]) then
			if equal(opt[OPTIONS], HAS_PARAMETER) then
				opt[OPTIONS] = {HAS_PARAMETER,"x"}
			else
				opt[OPTIONS] = {}
			end if
			updated = 1
		else
			for j = 1 to length(opt[OPTIONS]) do
				if find_from(opt[OPTIONS][j], opt[OPTIONS], j + 1) != 0 then
					crash("cmd_opts: Duplicate processing options are not allowed in an option record.\n")
				end if
			end for
			
			if find(HAS_PARAMETER, opt[OPTIONS]) then
				if find(NO_PARAMETER, opt[OPTIONS]) then
					crash("cmd_opts: Cannot have both HAS_PARAMETER and NO_PARAMETER in an option record.\n")
				end if
			end if

			if find(HAS_CASE, opt[OPTIONS]) then
				if find(NO_CASE, opt[OPTIONS]) then
					crash("cmd_opts: Cannot have both HAS_CASE and NO_CASE in an option record.\n")
				end if
			end if

			if find(MANDATORY, opt[OPTIONS]) then
				if find(OPTIONAL, opt[OPTIONS]) then
					crash("cmd_opts: Cannot have both MANDATORY and OPTIONAL in an option record.\n")
				end if
			end if
			
			if find(ONCE, opt[OPTIONS]) then
				if find(MULTIPLE, opt[OPTIONS]) then
					crash("cmd_opts: Cannot have both ONCE and MULTIPLE in an option record.\n")
				end if
			end if
			
		end if
		
		if sequence(opt[CALLBACK]) then
			opt[CALLBACK] = -1
			updated = 1
		elsif not integer(opt[CALLBACK]) then
			opt[CALLBACK] = -1
			updated = 1
		elsif opt[CALLBACK] < 0 then
			opt[CALLBACK] = -1
			updated = 1
		end if
		
		if sequence(opt[MAPNAME]) and length(opt[MAPNAME]) = 0 then
			opt[MAPNAME] = 0
			updated = 1
		end if
		
		if atom(opt[MAPNAME]) then
			if sequence(opt[LONGNAME]) then
				opt[MAPNAME] = opt[LONGNAME]
			elsif sequence(opt[SHORTNAME]) then
				opt[MAPNAME] = opt[SHORTNAME]
			else
				opt[MAPNAME] = "extras"
			end if
			updated = 1
		end if
		
		if updated then
			opts[i] = opt
		end if
	end for
	
	-- Check for duplicate option records.
	for i = 1 to length(opts) do
		sequence opt
		opt = opts[i]
		if sequence(opt[SHORTNAME]) then
			for j = i + 1 to length(opts) do
				if equal(opt[SHORTNAME], opts[j][SHORTNAME]) then
					crash("cmd_opts: Duplicate Short Names (%s) are not allowed in an option record.\n", 
						{ opt[SHORTNAME]})
				end if
			end for
		end if
		
		if sequence(opt[LONGNAME]) then
			for j = i + 1 to length(opts) do
				if equal(opt[LONGNAME], opts[j][LONGNAME]) then
					crash("cmd_opts: Duplicate Long Names (%s) are not allowed in an option record.\n",
						{opt[LONGNAME]})
				end if
			end for
		end if
	end for

	-- Insert the default 'help' option	if one is not already there.
	integer has_help = 0
	for i = 1 to length(opts) do
		if find(HELP, opts[i][OPTIONS]) then
			has_help = 1
			exit
		end if
	end for

	if not has_help and add_help_options then
		opts = append(opts, {"h", "help", "Display the command options", {HELP}, -1})
		opts = append(opts, {"?", 0, "Display the command options", {HELP}, -1})

		-- We have to standardize the above additions
		opts = standardize_opts(opts, 0)
	end if
	
	return opts
end function

procedure local_help(sequence opts, object add_help_rid=-1, sequence cmds = command_line(), integer std = 0)
	if add_help_rid > -1 then
		call_proc(add_help_rid, {})
		return
	end if

	integer pad_size
	integer this_size
	sequence cmd
	sequence param_name
	integer has_param
	integer is_mandatory
	integer extras_mandatory = 0
	integer extras_opt = 0

	if std = 0 then
		opts = standardize_opts(opts, add_help_rid != NO_HELP)
	end if
	
	-- Calculate the size of the padding required to keep option text aligned.
	pad_size = 0
	for i = 1 to length(opts) do
		this_size = 0
		param_name = ""

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

	if add_help_rid != NO_HELP then
		printf(1, "%s options:\n", {cmds[2]})
	end if

	for i = 1 to length(opts) do
		if atom(opts[i][SHORTNAME]) and atom(opts[i][LONGNAME]) then
			-- Ignore 'extras' record
			continue
		end if
		
		has_param    = find(HAS_PARAMETER, opts[i][OPTIONS])
		if has_param != 0 then
			if has_param < length(opts[i][OPTIONS]) then
				has_param += 1
				if sequence(opts[i][OPTIONS][has_param]) then
					param_name = opts[i][OPTIONS][has_param]
				else
					param_name = "x"
				end if
			else
				param_name = "x"
			end if
		end if
		is_mandatory = (find(MANDATORY,     opts[i][OPTIONS]) != 0)
		cmd = ""
		
		if sequence(opts[i][SHORTNAME]) then
			if not is_mandatory then
				cmd &= '['
			end if
			cmd &= '-' & opts[i][SHORTNAME]
			if has_param != 0 then
				cmd &= ' ' & param_name
			end if
			if not is_mandatory then
				cmd &= ']'
			end if
		end if
		
		if sequence(opts[i][LONGNAME]) then
			if length(cmd) > 0 then cmd &= ", " end if
			if not is_mandatory then
				cmd &= '['
			end if
			cmd &= "--" & opts[i][LONGNAME]
			if has_param != 0 then
				cmd &= '=' & param_name
			end if
			if not is_mandatory then
				cmd &= ']'
			end if
		end if
		puts(1, "   " & pad_tail(cmd, pad_size))
		puts(1, opts[i][DESCRIPTION] & '\n')
	end for

	if extras_mandatory != 0 then
		if length(opts[extras_opt][DESCRIPTION]) > 0 then
			puts(1, opts[extras_opt][DESCRIPTION])
			puts(1, '\n')
		else
			puts(1, "One or more additional arguments are also required\n")
		end if
	elsif extras_opt > 0 then
		if length(opts[extras_opt][DESCRIPTION]) > 0 then
			puts(1, opts[extras_opt][DESCRIPTION])
			puts(1, '\n')
		else
			puts(1, "One or more additional arguments can be supplied.\n")
		end if
	end if
	
	if atom(add_help_rid) then
		if add_help_rid >= 0 then
			puts(1, "\n")
			call_proc(add_help_rid, {})
			puts(1, "\n")
		end if
	else
		if length(add_help_rid) > 0 then
			puts(1, "\n")
			if atom(add_help_rid[1]) then
				puts(1, add_help_rid)
				if add_help_rid[$] != '\n' then
					puts(1, '\n')
				end if
			else
				for i = 1 to length(add_help_rid) do
					puts(1, add_help_rid[i])
					if add_help_rid[i][$] != '\n' then
						puts(1, '\n')
					end if		
				end for
			end if
			puts(1, "\n")
		end if
	end if
	
end procedure


--****
-- === Routines

--****
-- Signature:
-- <built-in> function command_line()
--
-- Description:
-- A **sequence** of strings, where each string is a word from the command-line that started your program.
--
-- Comments:
--
-- The returned sequence contains the following information:
-- # The path to either the Euphoria executable, (eui, eui.exe, euid.exe euiw.exe) or to your bound
--   executable file.
-- # The next word is either the name of your Euphoria main file, or 
-- (again) the path to your bound executable file.
-- # Any extra words typed by the user. You can use these words in your program.
--
-- There are as many entries as words, plus the two mentioned above.
--
-- The Euphoria interpreter itself does not use any command-line options. You are free to use
-- any options for your own program. It does have [[:command line switches]] though.
--
-- The user can put quotes around a series of words to make them into a single argument.
--
-- If you convert your program into an executable file, either by binding it, or translating it to C, 
-- you will find that all command-line arguments remain the same, except for the first two, 
-- even though your user no longer types "ex" on the command-line (see examples below).
--  
-- Example 1:
-- <eucode>  
--  -- The user types:  ex myprog myfile.dat 12345 "the end"
-- 
-- cmd = command_line()
-- 
-- -- cmd will be:
--       {"C:\EUPHORIA\BIN\EX.EXE",
--        "myprog",
--        "myfile.dat",
--        "12345",
--        "the end"}
-- </eucode>
--
-- Example 2:  
-- <eucode>  
--  -- Your program is bound with the name "myprog.exe"
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
-- -- Note that all arguments remain the same as example 1
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
-- Retrieves the list of switches passed to the interpreter on the command line.
--
-- Returns:
-- A **sequence** of strings, each containing a word related to switches.
--
-- Comments:
--
-- All switches are recorded in upper case.
--
-- Example 1:
-- euiw -d helLo will result in ##option_switches##() being ##{"-D","helLo"}##.
--
-- See Also:
-- [[:Command line switches]]

--**
-- Show help message for the given opts.
--
-- Parameters:
-- # ##opts##: a sequence of options. See the [[:cmd_parse]] for details.
-- # ##add_help_rid##: an object. See the [[:cmd_parse]] for details.
--
-- Comments:
-- The parameters ##opts## and ##add_help_rid## are identical to the same ones
-- used by [[:cmd_parse]]
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
--     {"r", 0, "Sets how many lines the console should display", {HAS_PARAMETER,"lines"}, -1}},
--     description)
-- </eucode>
-- Outputs:
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

public procedure show_help(sequence opts, object add_help_rid=-1, sequence cmds = command_line())
	local_help(opts, add_help_rid, cmds, 0)
end procedure

---
function find_opt(sequence opts, sequence opt_style, object cmd_text)
	integer slash
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
		if find(lower(opt_param), {"1", "on", "yes", "y", "true", "ok", "+"}) then
			opt_param = 1
		elsif find(lower(opt_param), {"0", "off", "no", "n", "false", "-"}) then
			opt_param = 0
		end if
	end if

	for i = 1 to length(opts) do
		if find(NO_CASE,  opts[i][OPTIONS]) then
			if not equal(lower(opt_name), lower(opts[i][opt_style[1]])) then
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

--**
-- Parse command line options, and optionally call procedures that relate to these options
--
-- Parameters:
-- # ##opts## - a sequence of valid option records: See Comments: section for details
-- # ##parse_options##: an optional sequence of parse options: See Parse Options section for details
-- # ##cmds## - an optional sequence of command line arguments. If omitted the output from 
--              command_line() is used.
--
-- Returns:
-- A map containing the options set. The returned map has one special key named "extras"
-- which are values passed on the command line that are not part of any option, for instance
-- a list of files ##myprog -verbose file1.txt file2.txt##.  If any command element begins
-- with an @ symbol then that file will be opened and its contents used to add to the command line.
-- 
-- Parse Options:
-- ##parse_options## can be a sequence of options that will affect the parsing of
-- the command line options. Options can be:
--
-- # VALIDATE_ALL - The default. All options will be validated for all possible errors.
-- # NO_VALIDATION - Do not validate any parameter.
-- # NO_VALIDATION_AFTER_FIRST_EXTRA - Do not validate any parameter after the first extra
--   was encountered. This is helpful for programs such as the Interpreter itself:
--   ##eui -D TEST greet.ex -name John##. -D TEST should be validated but anything after
--   "greet.ex" should not as it is meant for greet.ex to handle, not eui.
-- # HELP_RID - Specify a routine id to call in the event of a parse error (invalid option
--   given, mandatory option not given, no parameter given for an option that requires a
--   parameter, etc...).
-- # NO_AT_EXPANSION - Do not expand arguments that begin with '@.'  
-- # AT_EXPANSION - Expand arguments that begin with '@'.  The name that follows @ will be
--   opened as a file, read, and each trimmed non-empty line that does not begin with a
--   '#' character will be inserted as arguments in the command line. These lines
--   replace the original '@' argument as if they had been entered on the original
--   command line.
--
-- An example of parse options:
-- <eucode>
-- { HELP_RID, routine_id("my_help"), NO_VALIDATION }
-- </eucode>
--
-- Comments:
-- Token types recognized on the command line:
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
-- Option records have the following structure:
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
-- # an integer; a [[:routine_id]]. This function will be called when the option is located
--   on the command line and before it updates the map. \\
--   Use -1 if cmd_parse is not to invoke a function for this option.\\
--   The user defined function must accept a single sequence parameter containing four values. 
--   If the function returns ##1## then the command option does not update the map.
--   You can use the predefined index values OPT_IDX, OPT_CNT, OPT_VAL, OPT_REV when
--   referencing the function's parameter elements.
--   ## An index into the ##opts## list.
--   ## The number of times that the routine has been called
--      by cmd_parse for this option
--   ## The option's value as found on the command line
--   ## 1 if the command line indicates that this option is to remove any earlier occurrences of it.
--
-- When assigning a value to the resulting map, the key is the long name if present,
-- otherwise it uses the short name. For options, you must supply a short name,
-- a long name or both.
--
-- If you want cmd_parse to call a user routine for the extra command line values,
-- you need to specify an Option Record that has neither a short name or a long name,
-- in which case only the routine_id field is used.
--
-- For more details on how the command line is being pre parsed, see [[:command_line]].
--
-- Example:
-- <eucode>
-- sequence option_definition
-- integer gVerbose = 0
-- sequence gOutFile = {}
-- sequence gInFile = {}
-- procedure opt_verbose( sequence value)
--    if value[OPT_VAL] = -1 then -- (-!v used on command line)
--    	gVerbose = 0
--    else
--      if value[OPT_CNT] = 1 then
--         gVerbose = 1
--      else
--         gVerbose += 1
--      end if
--    end if
-- end procedure
--
-- procedure opt_output_filename( sequence value)
--    gOutFile = value[OPT_VAL]
-- end procedure
--
-- procedure opt_extras( sequence value)
--    if not file_exists(value[OPT_VAL]) then
--        show_help(option_definitions, sprintf("Cannot find '%s'", value[OPT_VAL]))
--        abort(1)
--    end if
--    gInFile = append(gInFile, value[OPT_VAL])
-- end procedure
--
-- option_definition = {
--     { "v", "verbose", "Verbose output",{NO_PARAMETER}, routine_id("opt_verbose")},
--     { "h", "hash", "Calculate hash values",{NO_PARAMETER}, -1},
--     { "o", "output",  "Output filename",{MANDATORY, HAS_PARAMETER, ONCE} , routine_id("opt_output_filename") },
--     { "i", "import",  "An import path", {HAS_PARAMETER, MULTIPLE}, -1 },
--     {  0,  0, 0, 0, routine_id("opt_extras")}
-- }
--
-- map:map opts = cmd_parse(option_definition)
--
-- -- When run as: eui myprog.ex -v -o john.txt -i /usr/local -i /etc/app input1.txt input2.txt
-- --
-- -- map:get(opts, "verbose") --> 1
-- -- map:get(opts, "hash") --> 0 (not supplied on command line)
-- -- map:get(opts, "output") --> "john.txt"
-- -- map:get(opts, "import") --> {"/usr/local", "/etc/app"}
-- -- map:get(opts, "extras") --> {"input1.txt", "input2.txt"}
-- </eucode>
--
-- See Also:
--   [[:show_help]], [[:command_line]]

public function cmd_parse(sequence opts, object parse_options={}, sequence cmds = command_line())
	integer arg_idx, opts_done
	sequence cmd
	object param
	sequence find_result
	sequence type_
	integer from_
	sequence help_opts
	sequence call_count
	integer add_help_rid = -1
	integer validation = VALIDATE_ALL
	integer has_extra = 0
	integer use_at = 1
	
	if sequence(parse_options) then
		integer i = 1

		while i <= length(parse_options) do
			switch parse_options[i] do
				case HELP_RID then
					if i < length(parse_options) then
						i += 1
						add_help_rid = parse_options[i]
					else
						crash("HELP_RID was given to cmd_parse with no routine_id")
					end if

				case VALIDATE_ALL then
					validation = VALIDATE_ALL

				case NO_VALIDATION then
					validation = NO_VALIDATION

				case NO_VALIDATION_AFTER_FIRST_EXTRA then
					validation = NO_VALIDATION_AFTER_FIRST_EXTRA
					
				case NO_AT_EXPANSION then
					use_at = 0
					
				case AT_EXPANSION then
					use_at = 1
			end switch
			i += 1
		end while

	elsif atom(parse_options) then
		add_help_rid = parse_options
	end if

	opts = standardize_opts(opts)

	call_count = repeat(0, length(opts))
	
	map:map parsed_opts = map:new()

	map:put(parsed_opts, "extras", {})

	arg_idx = 2
	opts_done = 0
	
	-- Find if there are any user-defined help options.
	help_opts = { "h", "?", "help" }
	for i = 1 to length(opts) do
		if find(HELP, opts[i][OPTIONS]) then
			if sequence(opts[i][SHORTNAME]) then
				help_opts = append(help_opts, opts[i][SHORTNAME])
			end if
			if sequence(opts[i][LONGNAME]) then
				help_opts = append(help_opts, opts[i][LONGNAME])
			end if
			if find(NO_CASE, opts[i][OPTIONS]) then
				help_opts = lower(help_opts)
				arg_idx = length(help_opts)
				for j = 1 to arg_idx do
					help_opts = append(help_opts, upper(help_opts[j]))
				end for
			end if
		end if
	end for		

	while arg_idx < length(cmds) do
		arg_idx += 1

		cmd = cmds[arg_idx]
		if length(cmd) = 0 then
			continue
		end if
		
		if cmd[1] = '@' and use_at then
			object at_cmds
			integer j

			-- Read in the lines from the file.
			at_cmds = io:read_lines(cmd[2..$])
			if equal(at_cmds, -1) then
				printf(2, "Cannot access '@' argument file '%s'\n", {cmd[2..$]})
				local_help(opts, add_help_rid, cmds, 1)
				abort(1)
			end if	
			-- Parse the 'at' commands removing comment lines and empty lines,
			-- and stripping off any enclosing quotes from lines.
			j = 0
			while j < length(at_cmds) do
				j += 1
				at_cmds[j] = trim(at_cmds[j])
				if length(at_cmds[j]) = 0 then
					at_cmds = at_cmds[1 .. j-1] & at_cmds[j+1 ..$]
					j -= 1
				elsif at_cmds[j][1] = '#' then
					at_cmds = at_cmds[1 .. j-1] & at_cmds[j+1 ..$]
					j -= 1
				elsif at_cmds[j][1] = '"' and at_cmds[j][$] = '"' and length(at_cmds[j]) >= 2 then
					at_cmds[j] = at_cmds[j][2 .. $-1]
				end if
			end while
			
			-- Replace the '@' argument with the contents of the file.
			cmds = cmds[1..arg_idx-1] & at_cmds & cmds[arg_idx+1..$]
			arg_idx -= 1
			continue
		end if
		
		if (opts_done or find(cmd[1], valid_switches) = 0 or length(cmd) = 1) 
		then
			map:put(parsed_opts, "extras", cmd, map:APPEND)
			has_extra = 1
			if validation = NO_VALIDATION_AFTER_FIRST_EXTRA then
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
			local_help(opts, add_help_rid, cmds, 1)
			ifdef UNITTEST then
				return 0
			end ifdef
			abort(0)
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
				printf(1, "option '%s': %s\n\n", {cmd, find_result[2]})
				local_help(opts, add_help_rid, cmds, 1)
				abort(1)
			end if

			continue
		end if
		
		sequence opt = opts[find_result[1]]
		
		if find(HAS_PARAMETER, opt[OPTIONS]) != 0 then
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
					printf(1, "option '%s' must have a parameter\n\n", {find_result[2]})
					local_help(opts, add_help_rid, cmds, 1)
					abort(1)
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
				continue
			end if
		end if
		
		if find_result[3] = 1 then
			map:remove(parsed_opts, opt[MAPNAME])
		else
			if find(MULTIPLE, opt[OPTIONS]) = 0 then
				if map:has(parsed_opts, opt[MAPNAME]) and (validation = VALIDATE_ALL or
					(validation = NO_VALIDATION_AFTER_FIRST_EXTRA))
				then
					printf(1, "option '%s' must not occur more than once in the command line.\n\n", {find_result[2]})
					local_help(opts, add_help_rid, cmds, 1)
					abort(1)
				else
					map:put(parsed_opts, opt[MAPNAME], param)
				end if
			else
				map:put(parsed_opts, opt[MAPNAME], param, map:APPEND)
			end if
		end if
	end while

	-- Check that all mandatory options have been supplied.
	for i = 1 to length(opts) do
		if find(MANDATORY, opts[i][OPTIONS]) then
			if atom(opts[i][SHORTNAME]) and atom(opts[i][LONGNAME]) then
				if length(map:get(parsed_opts, opts[i][MAPNAME])) = 0 then
					puts(1, "Additional arguments were expected.\n\n")
					local_help(opts, add_help_rid, cmds, 1)
					abort(1)
				end if
			else
				if not map:has(parsed_opts, opts[i][MAPNAME]) then
					printf(1, "option '%s' is mandatory but was not supplied.\n\n", {opts[i][MAPNAME]})
					local_help(opts, add_help_rid, cmds, 1)
					abort(1)
				end if
			end if
		end if
	end for
	
	return parsed_opts
end function

--**
-- Returns a text string based on the set of supplied strings. Typically, this
-- is used to ensure that arguments on a command line are properly formed
-- before submitting it to the shell.
--
-- Parameters:
--   # ##cmds##: A sequence. Contains zero or more strings.
--
-- Returns:
--	A **sequence** which is a text string. Each of the strings in ##cmds## is
--  quoted if they contain spaces, and then concatenated to form a single
--  string.
--
-- Comments:
--   Though this function does the quoting for you it is not going to protect
--   your programs from globing *, ?.  And it is not specied here what happens if you
--   pass redirection or piping characters.
--
-- Example 1:
-- <eucode>
-- s = build_commandline( { "-d", "/usr/my docs/"} )
-- -- s now contains '-d "/usr/my docs/"' 
-- </eucode>
--
-- Example 2:
--     You can use this to run things that might be difficult to quote out:
--     Suppose you want to run a program that requires quotes on its
--     command line?  Use this function to pass quotation marks:
--
-- <eucode>
-- s = build_commandline( { "awk", "-e", "'{ print $1"x"$2; }'" } )
-- system(s,0)
-- </eucode>
--     
-- See Also:
--   [[:system]], [[:system_exec]], [[:command_line]]

public function build_commandline(sequence cmds)
	return flatten(quote( cmds,,'\\'," " ), " ") 		
end function
