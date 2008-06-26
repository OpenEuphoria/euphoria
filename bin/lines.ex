-- lines.ex
-- Count the number of lines, non-blank lines, non-blank/non-comment lines,
-- and characters in a text file or bunch of text files in the 
-- current directory.

-- usage:  lines.bat [file-spec ...]

-- example:  lines *.e *.ex

without warning

include wildcard.e
include file.e
include sequence.e

constant SCREEN = 1
constant TRUE = 1, FALSE = 0

object EUDIR, PATH, EUINC
EUDIR = getenv("EUDIR")
PATH = getenv("PATH")
EUINC = getenv("EUINC")

integer ENTER
ifdef UNIX then
        ENTER = 10
else    
        ENTER = 13
end ifdef

integer DETAIL
DETAIL = 0
sequence global_program
global_program = ""


-------------------------------------------------------------------------------------
function remove_trailing_spaces(sequence str)
-------------------------------------------------------------------------------------
integer x

    x = length(str)
    if x = 0 then return "" end if

    while str[x] = 32 or str[x] = '\n' or str[x] = 0 or str[x] = '\t' or str[x] = '\r' do
        x = x-1
        if x <= 1 then exit
        end if
    end while

    if x < 1 then x = 1 end if
    str = str[1..x]

    if length(str) = 1 and (str[1] = 32 or str[1] = ENTER) then
        str = ""
    end if

return str
end function

-------------------------------------------------------------------------------------
function parse_path(sequence path)
--though it says path, resolves EUINC too
--separator can be either : or ;
-------------------------------------------------------------------------------------
sequence sep_path, temp

sep_path = {}

if length(path) = 0 then return {} end if

temp = ""
for i = 1 to length(path) do
        if path[i] = ':' or path[i] = ';' then
                if length(temp) > 0 then
                        sep_path = append(sep_path, temp)
                end if
                temp = ""
        else
                temp &= path[i]
        end if
end for

if length(temp) > 0 then
        sep_path = append(sep_path, temp)
end if

return sep_path
end function

-------------------------------------------------------------------
function blank_line(sequence line)
-------------------------------------------------------------------
-- TRUE if line is empty or all whitespace
    for i = 1 to length(line) do
	if not find(line[i], " \t\n") then
	    return FALSE
	end if
    end for
    return TRUE
end function

-------------------------------------------------------------------
function scan(integer fileNum) 
-------------------------------------------------------------------
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
		    ifdef !UNIX then
				chars += 1  -- line in file contains an extra \r
	    	end ifdef
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

-------------------------------------------------------------------
procedure process_all_files(sequence file_names)
-------------------------------------------------------------------
integer fileNum
sequence count, total_count

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



-------------------------------------------------------------------
procedure lines()
-------------------------------------------------------------------
-- main procedure 
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
    
    process_all_files(file_names)   
end procedure

-------------------------------------------------------------------------
procedure help()
-------------------------------------------------------------------------
sequence prog_help
prog_help =     "Usage : lines [/l] [file specs]\n" &
                "       Counts the lines in all files in the current directory\n" &
                "       with [file specs]\n" &
                "       eg lines *.e *.exu\n" &
                --"       /d turns some more details on\n" &
                "       /l counts the lines in the program named in [file specs]\n" &
                "       eg lines /l prog.exw\n" &
                "       Counts all the lines in the named program, including the include files\n" &
                "       For each file in [file specs], a count will be produced\n"
puts(1, prog_help)
end procedure


-------------------------------------------------------------------------
function scan_file_for_includes(sequence file_name)
-------------------------------------------------------------------------
sequence include_list
object line
integer fp, c, ws_ok

include_list = {}
ws_ok = 1

fp = open(file_name, "r")
while 1 do
        line = gets(fp)
        ws_ok = 1
        if sequence(line) then
                if match("include", line) > 0 then
                        --is include a word, or just part of a word
                        --the beginning
                        --puts(1, line)
                        if match("include", line) > 1 then
                                --not at the beginning of thr line
                                c = line[match("include", line) - 1]
                                if c != 0 and c != ' ' and c != '\t' then
                                        --it must be a non whitespace character not a vilid include line
                                        ws_ok = 0
                                end if
                        end if

                        if ws_ok = 1 then
                                --is the inclood between ""s
                                for i = 1 to length(line) do
                                        if line[i] = '"' then
                                                if i < match("include", line) then
                                                        --there's a quote before match
                                                        ws_ok = 0
                                                        exit
                                                end if
                                        end if
                                end for
                        end if

                        if ws_ok = 1 then
                                --check the end of the include
                                c = line[match("include", line) + 7]
                                if c != 0 and c != ' ' and c != '\t' then
                                        ws_ok = 0
                                end if
                        end if

                        if ws_ok = 1 then
                                --is the line commented?
                                if match("--", line) = 0 then
                                        include_list = append(include_list, remove_trailing_spaces(line[match("include", line) + 8 .. $ ]) )
                                elsif match("--", line) > match("include", line) then
                                        include_list = append(include_list, remove_trailing_spaces(line[match("include", line) + 8 .. match("--", line) - 1 ]) )
                                end if
                                --is the include namespaced (include x as y)
                                if length(include_list) > 0 and match(" as", include_list[$]) > 0 then
                                        include_list[$] = include_list[$][1.. match(" as", include_list[$]) - 1]
                                end if
                        end if
                end if
        else
                close(fp)
                exit
        end if
end while


return include_list
end function

-------------------------------------------------------------------------
function check_includes(sequence file_name)
--this checks the include name for the presence of the real file
--then scans the file for a list of includes within that file.
--going to have to look in standard places for includes!
--check everywhere in the path, and in EUDIR/include
--and now the conf file too
-------------------------------------------------------------------------
integer fp
sequence include_list
integer found_flag

include_list = {}
found_flag = 0

--try current directory
fp = open(file_name, "r")
if fp > 0 then
        close(fp)
        return scan_file_for_includes(file_name)
end if

--hmm, try eudir/include
fp = open(EUDIR & PATHSEP & "include" & PATHSEP & file_name, "r")
if fp > 0 then
        close(fp)
        return scan_file_for_includes(EUDIR & PATHSEP & "include" & PATHSEP & file_name)
end if

--hmmm, try EUINC
if length(EUINC) > 0 then
        for i = 1 to length(EUINC) do
                fp = open(EUINC[i] & PATHSEP & file_name, "r")
                if fp > 0 then
                        close(fp)
                        return scan_file_for_includes(EUINC[i] & PATHSEP & file_name)
                end if
        end for
end if

--still no joy! - try the path
if length(PATH) > 0 then
        for i = 1 to length(PATH) do
                fp = open(PATH[i] & PATHSEP & file_name, "r")
                if fp > 0 then
                        close(fp)
                        return scan_file_for_includes(PATH[i] & PATHSEP & file_name)
                end if
        end for
end if


--puts(1, EUDIR & PATHSEP & "include" & PATHSEP & file_name & "-\n")
puts(1, "Warning -  Couldn't find " & file_name & " listed in " & global_program & "\n")

--ok, still not found, where else
-- try the conf file - new to 4.0

return include_list
end function

-------------------------------------------------------------------------
function duplicate_check(sequence include_table)
-------------------------------------------------------------------------
sequence new_inc
integer match_flag

match_flag = 0
new_inc = {}

for i = 1 to length(include_table) do
        if i = 1 then
                new_inc = append(new_inc, include_table[i])
        else
                match_flag = 0
                for j = 1 to length(new_inc) do
                        if equal(new_inc[j], include_table[i]) then
                                match_flag = 1
                                exit
                        end if
                end for
                if match_flag = 0 then
                        new_inc = append(new_inc, include_table[i])
                end if
        end if
end for

return new_inc
end function

-------------------------------------------------------------------------
function real_file_names(sequence file_names)
--converts list of includes to real file names, and send to processing
-------------------------------------------------------------------------
integer fp
sequence include_list
integer found_flag

include_list = {}
found_flag = 0

for i = 1 to length(file_names) do
        found_flag = 0

        --try current directory
        fp = open(file_names[i], "r")
        if fp > 0 then
                close(fp)
                found_flag = 1
        end if

        if found_flag = 0 then
                --hmm, try eudir/include
                fp = open(EUDIR & PATHSEP & "include" & PATHSEP & file_names[i], "r")
                if fp > 0 then
                        close(fp)
                        file_names[i] = EUDIR & PATHSEP & "include" & PATHSEP & file_names[i]
                        found_flag = 1
                end if
        end if

        if found_flag = 0 and length(EUINC) > 0 then
                --try EUINC
                for j = 1 to length(EUINC) do
                        fp = open(EUINC[j] & PATHSEP & file_names[i], "r")
                        if fp > 0 then
                                close(fp)
                                file_names[i] = EUINC[j] & PATHSEP & file_names[i]
                                found_flag = 1
                        end if
                end for
        end if

        if found_flag = 0 and length(PATH) > 0 then
                --try PATH
                for j = 1 to length(PATH) do
                        fp = open(PATH[j] & PATHSEP & file_names[i], "r")
                        if fp > 0 then
                                close(fp)
                                file_names[i] = PATH[j] & PATHSEP & file_names[i]
                                found_flag = 1
                        end if
                end for
        end if


        --ok, still not found, where else
        -- try the conf file - new to 4.0

end for

process_all_files(file_names)

return 0
end function

-------------------------------------------------------------------------
function scan_program(sequence cl_params)
-------------------------------------------------------------------------
integer fp
sequence include_table, program_name, new_includes
object line
integer table_count, table_size

fp = -1
program_name = {}

--do we have a valid program to scan?
for i = 1 to length(cl_params) do
        if cl_params[i][1] != '/' and cl_params[i][1] != '-' then
                fp = open(cl_params[i], "r")
                if fp > 0 then
                        program_name = cl_params[i]
                        exit
                end if
        end if
end for

if fp < 0 then 
        puts(1, "Cannot find a valid program file name!\n")
        return 0 
end if

close(fp)

--add the program name to the list of files
include_table = {program_name}

--scan the file for includes, add them to the include_table
include_table &= scan_file_for_includes(program_name)
global_program = program_name
table_size = length(include_table)

--now go for lower level includes
table_count = 2
if length(include_table) > 1 then
        while 1 do
                --open each file in include table in turn, get list of includes, add them to the include table
                new_includes = check_includes(include_table[table_count])
                include_table &= new_includes

                --do this everytime to avoid the (low) probablity of cyclical includes
                include_table = duplicate_check(include_table)

                table_count += 1
                if table_count > table_size then
                        program_name = include_table[table_size]
                        table_size = length(include_table)
                end if                

                if table_count > length(include_table) then exit end if
        end while
end if

--debugging - where's my ifdef!
--for i = 1 to length(include_table) do
--         puts(1, include_table[i] & "\n")
--end for

if real_file_names(include_table) then end if

return 0
end function


-------------------------------------------------------------------------
function switch_scan()
--main()
-------------------------------------------------------------------------
sequence cl, cl_params
integer flag
sequence switch_list

flag = 0
cl_params = {}
switch_list = {}

if atom(PATH) then PATH = {} end if
if atom(EUINC) then EUINC = {} end if
if atom(EUDIR) then EUDIR = {} end if

PATH = parse_path(PATH)
EUINC = parse_path(EUINC)

cl = command_line()
for i = 3 to length(cl) do
        cl_params = append(cl_params, cl[i])
end for

--check for no command line additions
if length(cl_params) = 0 then
        lines()
        return 0
end if

--check for legal command line switches
for i = 1 to length(cl_params) do
        if cl_params[i][1] = '-' or cl_params[i][1] = '/' then
                flag = 1
        end if
end for
if flag = 0 then 
        lines()
        return 0
end if

--check for which command line switches exist, and react appropriately
--gives scope for additional ones at some later date
for i = 1 to length(cl_params) do
        if cl_params[i][1] = '-' or cl_params[i][1] = '/' then
                if length(cl_params[i]) = 1 then
                        puts(1, "Switches need a value!\n")
                        help()
                        return 0
                end if
                switch_list = append(switch_list, cl_params[i][2])                
        end if        
end for

--check for detail switch
-- for i = 1 to length(switch_list) do
--         if upper(switch_list[i]) = 'D' then 
--                 DETAIL = 1
--         end if       
-- end for

--check other switches
for i = 1 to length(switch_list) do
        if switch_list[i] = '?' then
                help()
                return 0
        elsif upper(switch_list[i]) = 'L' then
                if scan_program(cl_params) then end if
                return 0
        end if

end for


return 0
end function

if switch_scan() then end if



