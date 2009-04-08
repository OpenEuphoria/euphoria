--**
-- == Command Line Handling
--

include std/text.e
include std/sequence.e
include std/map.e as map

--****
-- == Constants

public constant
	NO_PARAMETER  = 0,
	HAS_PARAMETER = 1,
	NO_CASE       = 0,
	HAS_CASE      = 1

enum
	SINGLE,
	DOUBLE,
	HELP,
	PARAM

--****
-- == Routines

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
-- # Tthe path to either the Euphoria executable, ex.exe, exw.exe or exu, or to your bound executable file.
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
-- [[:build_commandline]], [[::option_switches]],  [[:getenv]], [[:cmd_parse]], [[:show_help]]

--****
-- Signature:
-- <built-in> function option_switches()
--
-- Description:
-- Retrieves the list of switches passed to the interpreter on the comand line.
--
-- Returns:
-- A **sequence** of strings, each containing a word related to switches.
--
-- Comments:
--
-- All switches are recorded in upper case.
--
-- Example 1:
-- exw -d helLo will result in ##option_switches##() being ##{"-D","helLo"}##.
--
-- See Also:
-- [[:Command line switches]]

--**
-- Show help message for the given opts.
--
-- Parameters:
-- # ##opts##: a sequence of options. See the Comments: section for details
-- # ##add_help_rid##: an integer, the routine_id of a procedure that will be called on
--     completion. Defaults to -1 (no call).
--
-- Comments:
-- If ##add_help_rid## is specified, it must be the id of a procedure that takes no arguments.
--
-- ##opts## is a sequence of records, each of which describes a command line option for a program.
-- The name of the program is fetched from the command line. Each option record is a 5 element
-- sequence
-- # a sequence representing some text following a "-". Use an atom if not relevant;
-- # a sequence representing some text following a "--". Use an atom if not relevant;
-- # a sequence, some help text which concerns the above synonymous options.
-- # either 1 to denote a parameter of the options, or anything else if none.
-- # an integer, a routine_id. Currently not used by this procedure.
--
-- When the second element is specified and there is a parameter, the syntax "=x" is used. When
-- the first element is specified, the " x" syntax is used.
--
-- Example 1:
-- <eucode>
-- -- in myfile.ex
-- show_help({
--      {"q", "silent", "Suppresses any output to console", NO_PARAMETER, 0},
--      {"r", 0, "Sets how many lines the console should display", HAS_PARAMETER, 1}})
-- </eucode>
--
-- myfile.ex options:
-- -q, ~--silent		Suppresses any output to console
-- -r x				Sets how many lines the console should display

public procedure show_help(sequence opts, integer add_help_rid=-1)
	integer pad_size, this_size
	sequence cmds, cmd

	cmds = command_line()

	pad_size = 0
	for i = 1 to length(opts) do
		this_size = 0

		if sequence(opts[i][SINGLE]) then
			this_size += length(opts[i][SINGLE]) + 1
		end if
		if sequence(opts[i][DOUBLE]) then
			this_size += length(opts[i][DOUBLE]) + 2
		end if
		if sequence(opts[i][SINGLE]) and sequence(opts[i][DOUBLE]) then
			this_size += 2
		end if

		if sequence(opts[i][PARAM]) then
			this_size += 4 + length(opts[i][PARAM])
		elsif equal(opts[i][PARAM], HAS_PARAMETER) then
			this_size += 4
		end if

		if pad_size < this_size + 6 then
			pad_size = this_size + 6
		end if
	end for

	printf(1, "%s options:\n", {cmds[2]})
	for i = 1 to length(opts) do
		cmd = ""
		if sequence(opts[i][SINGLE]) then
			cmd &= '-' & opts[i][SINGLE]
			if sequence(opts[i][PARAM]) then
				cmd &= " " & opts[i][PARAM]
			elsif equal(opts[i][PARAM],HAS_PARAMETER) then
				cmd &= " x"
			end if
		end if
		if sequence(opts[i][DOUBLE]) then
			if length(cmd) > 0 then cmd &= ", " end if
			cmd &= "--" & opts[i][DOUBLE]
			if sequence(opts[i][PARAM]) then
				cmd &= "=" & opts[i][PARAM]
			elsif equal(opts[i][PARAM], HAS_PARAMETER) then
				cmd &= "=x"
			end if
		end if
		puts(1, "     " & pad_tail(cmd, pad_size))
		puts(1, " " & opts[i][HELP] & '\n')
	end for

	if add_help_rid >= 0 then
		puts(1, "\n")
		call_proc(add_help_rid, {})
	end if
end procedure

function find_opt(sequence opts, integer typ, object name)
	integer slash
	integer posn = 0
	sequence opt_name
	object opt_param

	opt_name = repeat(' ', length(name))
	opt_param = 0
	for i = 1 to length(name) do
		if name[i] = '"' then
			posn = i
		elsif find(name[i], ":=") then
			if posn = 0 then
				posn = i
				opt_name = opt_name[1 .. posn - 1]
				opt_param = name[posn + 1 .. $]
				exit
			end if
		end if

		opt_name[i] = name[i]
	end for


	slash = 0 -- should we check both single char and words?
	if typ = 3 then
		slash = 1
		typ = 2
	end if

	for i = 1 to length(opts) do
		if length(opts[i]) > 5 then
			if equal(opts[i][6], NO_CASE) then
				if equal(lower(opt_name), lower(opts[i][typ])) or 
					(slash and equal(lower(opt_name), lower(opts[i][1]))) 
				then
					return {i, opt_param}
				end if
			end if
		end if

		if equal(opt_name, opts[i][typ]) or (slash and equal(opt_name, opts[i][1])) then
			return {i, opt_param}
		end if
	end for

	return {0, "Unrecognised"}
end function

--**
-- Parse command line options, and optionally call procedures that relate to these options
--
-- Parameters:
-- # ##opts## - a sequence of valid option records: See Comments: section for details
-- # ##add_help_rid## - an integer, the id of ???. Defaults to -1.
--
-- Returns:
-- A map containing the options set. The returned map has one special key named "extras"
-- which are values passed on the command line that are not part of any option, for instance
-- a list of files ##myprog -verbose file1.txt file2.txt##.
--
-- Comments:
--
-- 6 sorts of tokens are recognized on the command line:
-- # a single '-'. Simply added to the option list
-- # a single "~-~-". This signals the end of command line options. What remains of the command
--   line is added to the option list, and the parsing terminates.
-- # -something. The option will be looked up in ##opts##.
-- # ~-~-something. Ditto.
-- # /something. Ditto.
-- # anything else. The word is simply added to the option list.
--
-- On a failed lookup, the program shows the help by calling [[:show_help]](##opts##,
-- ##add_help_rid##) and terminates with status code 1.
--
-- Option records have the following structure:
-- # a sequence representing some text following a "-". Use an atom if not relevant;
-- # a sequence representing some text following a "~-~-". Use an atom if not relevant;
-- # a sequence, some help text which concerns the above synonymous options.
-- # either ##HAS_PARAMETER## to denote a parameter of the options, or anything else if none.
-- # an integer, a [[:routine_id]]. This id will be called when a lookup he this entry.
-- # an integer, a value of ##NO_CASE## to indicate that the case of the supplied option
--   is not significant.
--
-- When assigning a value to the resulting map, the key is first the long name. If the long
-- name is not present, then it reverts to the short name.
--
-- For more details on how the command line is being pre parsed, see [[:command_line]].
--
-- Example:
-- <eucode>
-- sequence option_definition = {
--     { "v", "verbose", "Verbose output",	NO_PARAMETER, routine_id("opt_verbose") },
--     { "o", "output",  "Output filename", HAS_PARAMETER, routine_id("opt_output_filename") }
-- }
--
-- map:map opts = cmd_parse(option_definition)
--
-- -- When run as: eui myprog.ex -v -o john.txt input1.txt input2.txt
--
-- -- map:get(opts, "verbose") -- 1
-- -- map:get(opts, "output") -- john.txt
-- -- map:get(opts, "extras") -- { "input1.txt", "input2.txt" }
-- </eucode>
--
-- See Also:
--   [[:show_help]], [[command_line]]

public function cmd_parse(sequence opts, integer add_help_rid=-1, sequence cmds = command_line())
	integer idx, opts_done
	sequence cmd
	object param
	sequence find_result
	integer lType
	integer from_
	map:map parsed_opts = map:new()

	map:put(parsed_opts, "extras", {})

	idx = 2
	opts_done = 0

	while idx < length(cmds) do
		idx += 1

		cmd = cmds[idx]
		if opts_done or find(cmd[1], "-/") = 0 or length(cmd) = 1 then
			map:put(parsed_opts, "extras", cmd, map:APPEND)
			continue
		end if

		if equal(cmd, "--") then
			opts_done = 1
			continue
		end if

		if equal(cmd[1..2], "--") then	  -- found --opt-name
			lType = 2
			from_ = 3
		elsif cmd[1] = '-' then -- found -opt
			lType = 1
			from_ = 2
		else  -- found /opt
			lType = 3
			from_ = 2
		end if

		if find(cmd[from_..$], { "h", "?", "help" }) then
			show_help(opts, add_help_rid)
			abort(0)
		end if

		find_result = find_opt(opts, lType, cmd[from_..$])

		if find_result[1] = 0 then
			-- something is wrong with the option
			printf(1, "%s option: %s\n\n", {find_result[2], cmd})
			show_help(opts, add_help_rid)
			abort(1)
		elsif find_result[1] > 0 then
			sequence opt = opts[find_result[1]]

			if sequence(opt[PARAM]) or equal(opt[PARAM], HAS_PARAMETER) then
				idx += 1
				if idx <= length(cmds) then
					param = cmds[idx]
				else
					param = ""
				end if

			elsif atom(opt[PARAM]) and equal(opt[PARAM], NO_PARAMETER) then
				param = 1

			elsif sequence(opt[PARAM]) then
				if atom(find_result[2]) then
					idx += 1
					if idx <= length(cmds) then
						param = cmds[idx]
					else
						param = ""
					end if
				else
					param = find_result[2]
				end if
			end if

			-- try to use the long name for the var storage into the map first
			if sequence(opt[DOUBLE]) and length(opt[DOUBLE]) then
				map:put(parsed_opts, opt[DOUBLE], param)
			else
				map:put(parsed_opts, opt[SINGLE], param)
			end if
		end if
	end while

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
--     You can use this to run things that might be diffucult to quote out:
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
