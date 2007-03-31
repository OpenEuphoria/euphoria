-- lines.ex
-- Count the number of lines, non-blank lines, non-blank/non-comment lines,
-- and characters in a text file or bunch of text files in the 
-- current directory.

-- usage:  lines.bat [file-spec ...]

-- example:  lines *.e *.ex

include misc.e
include wildcard.e
include file.e

constant SCREEN = 1
constant TRUE = 1, FALSE = 0

function blank_line(sequence line)
-- TRUE if line is empty or all whitespace
    for i = 1 to length(line) do
	if not find(line[i], " \t\n") then
	    return FALSE
	end if
    end for
    return TRUE
end function

function scan(integer fileNum) 
-- count lines, non-blank lines, characters
    object line
    integer lines, nb_lines, nb_nc_lines, chars, c

    lines = 0
    nb_lines = 0
    nb_nc_lines = 0
    chars = 0
    while TRUE do
	line = gets(fileNum)
	if atom(line) then   
	    -- end of file
	    return {lines, nb_lines, nb_nc_lines, chars}
	else
	    lines += 1
	    chars += length(line) 
	    if platform() != LINUX then
		chars += 1  -- line in file contains an extra \r
	    end if
	    if not blank_line(line) then
		nb_lines += 1
		c = match("--", line)
		if not c or not blank_line(line[1..c-1]) then
		    nb_nc_lines += 1
		end if
	    end if
	end if
    end while
end function

procedure lines()
-- main procedure 
    integer fileNum
    sequence count, total_count
    sequence file_names, dir_names
    sequence cl, file_spec, name
    
    -- gather eligible file names
    cl = command_line()
    file_spec = {}
    for i = 3 to length(cl) do
	file_spec = append(file_spec, cl[i])
    end for
    if length(file_spec) = 0 then
	file_spec = {"*.*"}
    end if
    dir_names = dir(current_dir())
    file_names = {}
    for f = 1 to length(file_spec) do
	for i = 1 to length(dir_names) do
	    if not find('d', dir_names[i][D_ATTRIBUTES]) then
		name = dir_names[i][D_NAME]
		if wildcard_file(file_spec[f], name) then 
		    if not find(name, file_names) then
			file_names = append(file_names, name)
		    end if
		end if
	    end if
	end for
    end for
    
    -- process all files    
    total_count = {0, 0, 0, 0}
    puts(SCREEN, "lines  nb-lines  nb-nc-lines  chars\n")
    for i = 1 to length(file_names) do
	fileNum = open(file_names[i], "r")   
	if fileNum = -1 then
	    printf(SCREEN, "cannot open %s\n", {file_names[i]})
	else
	    count = scan(fileNum)
	    total_count = total_count + count
	    printf(SCREEN, "%5d%8d   %8d   %8d   %s\n", count & {file_names[i]})
	    close(fileNum)
	end if
    end for
    if length(file_names) > 1 then
	printf(SCREEN, "%5d%8d   %8d   %8d   total\n", total_count)
    end if
end procedure

lines()

