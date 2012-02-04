-- (c) Copyright - See License.txt
--
--****
-- == cominit.e: Common command line initialization

ifdef ETYPE_CHECK then
	with type_check
elsedef
	without type_check
end ifdef

include euphoria/info.e

include std/cmdline.e
include std/console.e
include std/error.e as error
include std/filesys.e
include std/io.e
include std/map.e as m
include std/search.e
include std/sequence.e
include std/text.e

include common.e
include error.e
include global.e
include pathopen.e
include platform.e
include preproc.e
include msgtext.e

export sequence src_name = ""
export sequence switches = {}

constant COMMON_OPTIONS = {
	{ "eudir",     0, GetMsgText(328,0), { HAS_PARAMETER, "dir" } },
	{ "c",         0, GetMsgText(280,0), { MULTIPLE, HAS_PARAMETER, "filename" } },
	{ "i",         0, GetMsgText(283,0), { MULTIPLE, HAS_PARAMETER, "dir" } },
	{ "d",         0, GetMsgText(282,0), { MULTIPLE, HAS_PARAMETER, "word" } },
	{ "l",         0, GetMsgText(284,0), { MULTIPLE, HAS_PARAMETER, "local" } },
	{ "ldb",       0, GetMsgText(285,0), { HAS_PARAMETER, "localdb" } },
	{ "p",         0, GetMsgText(286,0), { MULTIPLE, HAS_PARAMETER, "file_ext:command" } },
	{ "pf",        0, GetMsgText(287,0), { } },
	{ "w",         0, GetMsgText(291,0), { MULTIPLE, HAS_PARAMETER, "name" } },
	{ "wf",        0, GetMsgText(292,0), { HAS_PARAMETER, "filename" } },
	{ "x",         0, GetMsgText(293,0), { MULTIPLE, HAS_PARAMETER, "name" } },
	{ "batch",     0, GetMsgText(279,0), { } },
	{ "strict",    0, GetMsgText(288,0), { } },
	{ "test",      0, GetMsgText(289,0), { } },
	{ "copyright", 0, GetMsgText(281,0), { } },
	{ "v", "version", GetMsgText(290,0), { } },
 	$
}

constant COMMON_OPTIONS_SPLICE_IDX = length(COMMON_OPTIONS) - 1

sequence options = {}
add_options( COMMON_OPTIONS )

--**
-- Add options to be parsed.
export procedure add_options( sequence new_options )
	options = splice(options, new_options, COMMON_OPTIONS_SPLICE_IDX)
	--options &= new_options
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
		printf(2, "%s\n  %s\n\n", { notices[i][1], match_replace("\n", notices[i][2], "\n  ") })
	end for
end procedure

--**
-- Show the Euphoria banner message stating product name,
-- platform, version and other miscellaneous information
-- about the compilation
--

export procedure show_banner()
	sequence prod_name, memory_type

	if INTERPRET and not BIND then
		prod_name = GetMsgText(270,0)

	elsif TRANSLATE then
		prod_name = GetMsgText(271,0)

	elsif BIND then
		prod_name = GetMsgText(272,0)
	end if

	ifdef EU_MANAGED_MEM then
		memory_type = GetMsgText(273,0)
	elsedef
		memory_type = GetMsgText(274,0)
	end ifdef

	sequence misc_info = {
		info:arch_bits(),
		info:platform_name(), 
		memory_type, 
		"", 
		info:version_date(),
		info:version_node()
	}

	if info:is_developmental then
		misc_info[$] = sprintf("%d:%s", { info:version_revision(), info:version_node() })
	end if

	object EuConsole = getenv("EUCONS")
	if equal(EuConsole, "1") then
		misc_info[4] = GetMsgText(275,0)
	else
		misc_info = remove(misc_info, 4)
	end if

	screen_output(STDERR, sprintf("%s v%s %s\n   %s %s, %s\n   Revision Date: %s, Id: %s\n", {
		prod_name, info:version_string_short(), info:version_type() } & misc_info ) )
end procedure

-- Taken from std/cmdline.e :-(
-- Record fields in 'opts' argument.
enum
	SHORTNAME   = 1,
	LONGNAME    = 2,
	DESCRIPTION = 3,
	OPTIONS     = 4,
	CALLBACK    = 5,
	MAPNAME     = 6

--**
-- Find a given option from the command line in the possible options sequence
--
-- Parameters:
--   * ##name_type## - type of parameter, SHORTNAME or LONGNAME
--   * ##opt## - actual option, text only no preceding - or / characters
--   * ##opts## - possible options (as sent to cmd_parse())
--
-- Returns:
--   Matching sequence in ##opts## or an empty sequence if the option was not found
--

function find_opt(integer name_type, sequence opt, sequence opts)
	for i = 1 to length(opts) do
		sequence o = opts[i]		
		integer has_case = find(HAS_CASE, o[OPTIONS])
		
		if has_case and equal(o[name_type], opt) then
			return o
		elsif not has_case and equal(text:lower(o[name_type]), text:lower(opt)) then
			return o
		end if
	end for
	
	return {}
end function

--**
-- Merge ##a## into ##b## keeping ##b## when there are conflicts in accordance with
-- ##opts##
--
-- Parameters:
--   * ##a## - A set of command line parameters
--   * ##b## - B set of command line parameters (steady)
--   * ##opts## - options sequence as normally passed to cmd_parse
--
-- Returns:
--   A new harmonized command line sequence in accordance with 

export function merge_parameters(sequence a, sequence b, sequence opts, integer dedupe = 0)
	integer i = 1
	
	while i <= length(a) do
		sequence opt = a[i]
		if length(opt) < 2 then
			i += 1
			continue
		end if
		
		sequence this_opt = {}
		integer bi = 0
		
		if opt[2] = '-' then
			-- We have a long option
			-- Look to see if b has this option
			this_opt = find_opt(LONGNAME, opt[3..$], opts)
			
			for j = 1 to length(b) do
				if equal(text:lower(b[j]), text:lower(opt)) then
					bi = j
					exit
				end if
			end for
			
		elsif opt[1] = '-' or opt[1] = '/' then
			-- We have a short option
			-- Look to see if b has this option
			this_opt = find_opt(SHORTNAME, opt[2..$], opts)
			
			for j = 1 to length(b) do
				if equal(text:lower(b[j]), '-' & text:lower(opt[2..$])) or 
							equal(text:lower(b[j]), '/' & text:lower(opt[2..$]))
				then
					bi = j
					exit
				end if
			end for
			
		end if
		
		--
		-- If we have it in b also, is a valid option and contains the ONCE parameter
		--
	
		if length(this_opt) and not find(MULTIPLE, this_opt[OPTIONS]) then
			if bi then
				if find(HAS_PARAMETER, this_opt[OPTIONS]) then
					-- remove the option and it's parameter as well
					a = remove(a, i, i + 1)
				else
					-- remove only the option
					a = remove(a, i)
				end if
				
				-- no need to increment the parameter index as we have removed options 
				-- which has the same effect as incrementing the parameter index
				
			else
				
				--
				-- Dedupe a w/in itself (eu.cfg args)
				--
				--   * i < length(a) makes sure we are not at the end of the list
				--     nothing to do if so and slicing would err.
				--

				integer beginLen = length(a)
				
				if dedupe = 0 and i < beginLen then
					a = merge_parameters( a[i + 1..$], a[1..i], opts, 1)
					
					if beginLen = length(a) then
						-- nothing removed, increment the parameter index
						i += 1
					end if
				else
					-- nothing removed, increment the parameter index
					i += 1
				end if
			end if			
			
		else
			-- nothing processed, increment the parameter index
			i += 1
		end if
	end while
	
	if dedupe then
		return b & a
	end if
	
	integer first_extra = 0
	
	i = 1
	
	-- We know the first extra is not in a (DefaultArgs)
	while i <= length(b) do
		sequence opt = b[i]
		
		-- can't be a parameter
		if length(opt) <= 1 then
			first_extra = i
			exit
		end if
		
		sequence this_opt = {}
		if opt[2] = '-' and opt[1] = '-' then
			this_opt = find_opt(LONGNAME, opt[3..$], opts)
		elsif opt[1] = '-' or opt[1] = '/' then
			this_opt = find_opt(SHORTNAME, opt[2..$], opts)
		end if
		
		if length(this_opt) then
			if find(HAS_PARAMETER, this_opt[OPTIONS]) then
				i += 1
			end if
		else
			first_extra = i
			exit
		end if
		
		i += 1
	end while
	
	if first_extra then
		return splice(b, a, first_extra)
	end if
	
	-- No extras, system will prob fail w/a help message later
	return b & a
end function

--**
-- Validates that the apparent option is valid, and that it has a parameter
-- if required.  Raises a [[:CompileErr]] if a required parameter is missing.
function validate_opt( integer opt_type, sequence arg, sequence args, integer ix )
	sequence opt
	if opt_type = SHORTNAME then
		opt = arg[2..$]
	else
		opt = arg[3..$]
	end if
	
	sequence this_opt = find_opt( opt_type, opt, options )
	if not length( this_opt ) then
		-- not a valid option
		return { 0, 0 }
	end if
	
	if find( HAS_PARAMETER, this_opt[OPTIONS] ) then
		if ix = length( args ) - 1 then
			-- missing parameter
			CompileErr( MISSING_CMD_PARAMETER, { arg } )
		else
			return { ix, ix + 2 }
		end if
	else
		return { ix, ix + 1 }
	end if
end function

--**
-- Finds the next valid option, if any, stopping at the
-- end of euphoria options, when the user's file is encountered.
-- Prevents mistaking command line arguments meant for the user's
-- program from being used by euphoria.
--
-- Returns a sequence with the index of the argument as the 
-- first element, and the next index to continue checking after 
-- validating that option.
--
-- Returns ##{0,0}## when it is finished checking options.
-- It does not check the entire argument list, as at least
-- the last argument is assumed to be 
function find_next_opt( integer ix, sequence args )
	while ix < length( args ) do
		sequence arg = args[ix]
		if length( arg ) > 1 then
			if arg[1] = '-' then
				if arg[2] = '-' then
					-- long option?
					if length( arg ) = 2 then
						-- explicit 'extras' delimiter
						return { 0, ix - 1 }
					end if
					
					return validate_opt( LONGNAME, arg, args, ix )
					
				else
					-- short opt
					return validate_opt( SHORTNAME, arg, args, ix )
				end if
			else
				-- done
				return {0, ix-1}
			end if
		else
			-- done
			return { 0, ix-1 }
		end if
		
		ix += 1
	end while
	return {0, ix-1}
end function

--**
-- Expand any config file options on the command line adding
-- their content to the supplied arguments.

export function expand_config_options(sequence args)
	integer idx = 1
	sequence next_idx
	sequence files = {}
	sequence cmd_1_2 = args[1..2]
	args = remove( args, 1, 2 )
	
	while idx with entry do
		if equal(upper(args[idx]), "-C") then
			files = append( files, args[idx+1] )
			args = remove( args, idx, idx + 1 )
		else
			-- jump over the option and parameter, if any
			idx = next_idx[2]
		end if
	entry
		next_idx = find_next_opt( idx, args )
		idx = next_idx[1]
	end while
	return cmd_1_2 & merge_parameters( GetDefaultArgs( files ), args[1..next_idx[2]], options, 1 ) & args[next_idx[2]+1..$]
end function

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
				for i = 1 to length(val) do
					sequence this_warn = val[i]
					integer auto_add_warn = 0
					if this_warn[1] = '+' then
						auto_add_warn = 1
						this_warn = this_warn[2 .. $]
					end if
					integer n = find(this_warn, warning_names)
					if n != 0 then
						if auto_add_warn or option_w = 1 then
							OpWarning = or_bits(OpWarning, warning_flags[n])
						else
							option_w = 1
							OpWarning = warning_flags[n]
						end if
	
						prev_OpWarning = OpWarning
					end if
				end for
				
			case "x" then
				for i = 1 to length(val) do
					sequence this_warn = val[i]
					integer auto_add_warn = 0
					if this_warn[1] = '+' then
						auto_add_warn = 1
						this_warn = this_warn[2 .. $]
					end if
					integer n = find(this_warn, warning_names)
					if n != 0 then
						if auto_add_warn or option_w = -1 then
							OpWarning = and_bits(OpWarning, not_bits(warning_flags[n]))
						else
							option_w = -1
							OpWarning = all_warning_flag - warning_flags[n]
						end if
	
						prev_OpWarning = OpWarning
					end if
				end for

			case "wf" then
				TempWarningName = val
			  	error:warning_file(TempWarningName)

			case "v", "version" then
				show_banner()
				if not batch_job and not test_only then
					console:maybe_any_key(GetMsgText(278,0), 2)
				end if

				abort(0)

			case "copyright" then
				show_copyrights()
				if not batch_job and not test_only then
					console:maybe_any_key(GetMsgText(278,0), 2)
				end if
				abort(0)
			
			case "eudir" then
				set_eudir( val )
				
		end switch
	end for

	if length(LocalizeQual) = 0 then
		LocalizeQual = {"en"}
	end if
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
	sequence extras = m:get(opts, cmdline:EXTRAS)
	if length(extras) > 0 then
		sequence pairs = m:pairs( opts )
		
		for i = 1 to length( pairs ) do
			sequence pair = pairs[i]
			if equal( pair[1], cmdline:EXTRAS ) then
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

		Argv = Argv[2..3] & extras
		Argc = length(Argv)

		src_name = extras[1]
	end if
end procedure
