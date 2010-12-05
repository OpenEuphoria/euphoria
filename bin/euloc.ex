--****
-- === lines.ex - Source Code Line Tally
--

include std/cmdline.e
include std/filesys.e
include std/io.e
include std/map.e
include std/regex.e as re
include std/search.e
include std/sequence.e
include std/text.e
include std/utils.e
include std/wildcard.e

constant inc_line = re:new(`^\s*(public\s*)?include\s+("[^"]+"|[^ ]+)`)
constant SCREEN = 1
sequence INC_PATHS = include_paths(1)
sequence global_program = ""

-- count lines, non-blank lines, characters
function scan(integer fh, integer size) 
	integer lines = 0, nb_lines = 0, nb_nc_lines = 0
	object line

	while sequence(line) with entry do
		line = trim(line)
		lines += 1
		if length(line) then
			nb_lines += 1
			if not begins("--", line) then
				nb_nc_lines += 1
			end if
		end if
	entry
		line = gets(fh)
	end while
	
	return { lines, nb_lines, nb_nc_lines, 100 * ((nb_lines - nb_nc_lines) / lines), size }
end function

procedure process_all_files(sequence file_names)
	sequence count, total_count = { 0, 0, 0, 0, 0 }

	puts(SCREEN, " lines non-blank      code  cmt     chars filename\n")
	puts(SCREEN, "--------------------------------------------------\n")
	for i = 1 to length(file_names) do
		integer fileNum = open(file_names[i], "r")   
		if fileNum = -1 then
			printf(SCREEN, "cannot open %s\n", {file_names[i]})
		else
			count = scan(fileNum, file_length(file_names[i]))
			total_count = total_count + count
			printf(SCREEN, "%6d %9d %9d %3d%% %9d %s\n", count & { 
				abbreviate_path(file_names[i]) })
			close(fileNum)
		end if
	end for

	if length(file_names) > 1 then
		total_count[4] = 100 * ((total_count[2] - total_count[3]) / total_count[1])
		puts(SCREEN, "--------------------------------------------------\n")
		printf(SCREEN, "%6d %9d %9d %3d%% %9d total\n", total_count)
	end if
end procedure

procedure lines(sequence file_spec)
	sequence dir_names = dir(current_dir())
	sequence file_names = {}

	if length(file_spec) = 0 then
		file_spec = {"*.*"}
	end if

	for f = 1 to length(file_spec) do
		for i = 1 to length(dir_names) do
			if not find('d', dir_names[i][D_ATTRIBUTES]) then
				sequence name = dir_names[i][D_NAME]
				if wildcard:is_match(file_spec[f], name) and not find(name, file_names) then 
					file_names = append(file_names, name)
				end if
			end if
		end for
	end for

	process_all_files(file_names)   
end procedure

function scan_file_for_includes(sequence file_name)
	sequence include_list = {}, lines = read_lines(file_name)

	for i = 1 to length(lines) do
		object inc = re:matches(inc_line, lines[i])
		if sequence(inc) then
			include_list = append(include_list, inc[3])
		end if
	end for

	return include_list
end function

function find_file(sequence base_filename)
	for i = 1 to length(INC_PATHS) do
		sequence fname = INC_PATHS[i] & SLASH & base_filename
		if file_exists(fname) then
			return fname
		end if
	end for

	return base_filename
end function

-- this checks the include name for the presence of the real file
-- then scans the file for a list of includes within that file.
function check_includes(sequence file_name)
	file_name = find_file(file_name)
	if file_exists(file_name) then
		return scan_file_for_includes(file_name)
	end if
	
	puts(1, "Warning -  Couldn't find " & file_name & " listed in " & global_program & "\n")

	return {}
end function

-- converts list of includes to real file names, and send to processing
procedure real_file_names(sequence file_names)
	for i = 1 to length(file_names) do
		file_names[i] = find_file(file_names[i])
	end for

	process_all_files(file_names)
end procedure

procedure scan_program(sequence file_name)
	object line
	sequence include_table, program_name = {}, new_includes
	integer table_count, table_size

	program_name = file_name

	--do we have a valid program to scan?
	if not file_exists(program_name) then
		puts(1, "Cannot find a valid program file name!\n")
		return 
	end if

	--add the program name to the list of files
	include_table = {program_name}

	--scan the file for includes, add them to the include_table
	include_table &= scan_file_for_includes(program_name)
	global_program = program_name
	table_size = length(include_table)

	--now go for lower level includes
	table_count = 2
	if length(include_table) > 1 then
		loop do
			--open each file in include table in turn, get list of includes, add them to the include table
			new_includes = check_includes(include_table[table_count])
			include_table &= new_includes

			--do this everytime to avoid the (low) probablity of cyclical includes
			include_table = remove_dups(include_table, RD_INPLACE)

			table_count += 1
			if table_count > table_size then
				program_name = include_table[table_size]
				table_size = length(include_table)
			end if

			until table_count > length(include_table)
		end loop
	end if

	real_file_names(include_table)
end procedure

procedure main()
	sequence opts = {{ "i", 0, "Include 'included' files in LOC output", { NO_PARAMETER }}}
	map:map cmdopts = cmd_parse(opts, { HELP_RID, 
		"Count the lines, non-blank lines, non-blank/non-comment lines and\n" & 
		"characters of all files given on the command line. If the optional -i\n" &
		"switch is used, the first filename is treated as a Euphoria program. It\n" &
		"and all include files are then tallied."
	})
	sequence files = map:get(cmdopts, cmdline:EXTRAS)

	if map:get(cmdopts, "i", 0) then
		INC_PATHS = prepend(INC_PATHS, pathname(canonical_path(files[1])))
		scan_program(files[1])
	else
		lines(files)
	end if
end procedure

main()
