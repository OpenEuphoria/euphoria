--****
-- === search.ex
--
-- This program searches for a string in files of the current directory 
-- and subdirectories.
--
-- 
-- ==== Usage
-- {{{
-- search [string] 
-- }}}
--
-- If you don't supply a string on the command line you will be prompted 
-- for it. The string may contain * and ? wildcard characters and so may 
-- the list of file specifications. Lines containing the string are 
-- displayed on the screen, and also recorded in %EUDIR%/SEARCH.OUT 
-- (DOS/Windows), or in $HOME/search.out (Linux).
-- Some statistics are printed at the end.
--
-- ==== Example
-- {{{
-- C:\> search
-- string: p?oc*re
-- match case? (n)
-- file-spec (*.*): *.e *.ex
-- scan subdirectories? (y)
-- }}}
--
-- ==== Note
--
-- If you just hit Enter instead of supplying a string to search for,
-- the program will simply print any file names that match your file-spec.
-- This is a good way to search for a file, when you can't remember which
-- directory you put it in.
--

--- some user-modifiable parameters: 
--
-- when you search "*.*" the following files 
-- will be skipped (to save time):

include std/get.e

-- patch for Linux screen positioning
procedure get_real_text_starting_position() 
                sequence sss = "" 
                integer ccc 
                puts(1, 27&"[6n") 
                while 1 do 
                        ccc = get_key() 
                        if ccc = 'R' then 
                                exit 
                        end if 
                        if ccc != -1 then 
                                sss &= ccc 
                        end if 
                end while 
                sss = sss[3..$] 
                sequence aa, bb 
                aa = value(sss[1..find(';', sss)-1]) 
                bb = value(sss[find(';', sss)+1..$]) 
                position(aa[2], bb[2]) 
end procedure 
ifdef LINUX then 
	get_real_text_starting_position() 
end ifdef 

get_real_text_starting_position()


sequence skip_list 
ifdef UNIX then
    skip_list = {
		"*.so", "*.lib", "*.tar", "*.o", "*.zip", "*.gz", "*.dylib"
    }
elsedef
    skip_list = {
		"*.EXE", "*.ZIP", "*.BMP", "*.GIF", "*.OBJ",
		"*.DLL", "*.OBJ", "*.SWP", "*.PAR", "*.JPG", 
		"*.WAV"
    }
end ifdef

-------- end of user-modifiable parameters 

without type_check

include std/filesys.e
include std/wildcard.e
include std/sort.e
include std/graphics.e
include std/sequence.e
include std/text.e

constant KEYB = 0, SCREEN = 1, ERR = 2
constant TRUE = 1, FALSE = 0
constant EOF = -1, ESC = 27

type boolean(integer x)
    return x = 0 or x = 1
end type

integer SLASH
sequence log_name, log_path, home

log_name = "search.out"
ifdef UNIX then
    SLASH='/'
    home = getenv("HOME") & ""
elsedef
    SLASH='\\'
    home = getenv("HOMEDRIVE") & getenv("HOMEPATH")
end ifdef

if find(-1, home) then
	log_path = log_name
else
	log_path = home & SLASH & log_name
end if

sequence pos, cmd, string, orig_string, file_spec

boolean match_case, scan_subdirs, wild_string, abort_now
abort_now = FALSE

integer scanned, skipped, no_open, file_hits, line_hits
scanned = 0
skipped = 0
no_open = 0
file_hits = 0
line_hits = 0

atom start_time
integer log_file

function alphabetic(object s)
-- does s contain alphabetic characters?
    return find(TRUE, (s >= 'A' and s <= 'Z') or
		      (s >= 'a' and s <= 'z')) 
end function

constant TO_LOWER = 'a' - 'A' 

function fast_lower(sequence s)
-- Faster than the standard lower().
-- Speed of lower() is very important for "any-case" search.
    integer c
    
    for i = 1 to length(s) do
	c = s[i]
	if c <= 'Z' then
	    if c >= 'A' then
		s[i] = c + TO_LOWER
	    end if
	end if
    end for
    return s
end function

function lcompare(object a, object b)
    return compare(lower(a), lower(b))
end function

function lower_dir(sequence path)
-- Default directory sorting function for walk_dir().
-- * sorts by name *
    object d
    
    d = dir(path)
    if atom(d) then
	return d
    else
	-- sort by name
	return custom_sort(routine_id("lcompare"), d)
    end if
end function

my_dir = routine_id("lower_dir")

constant LINE_WIDTH = 79

function clean(sequence line)
-- replace any funny control characters 
-- and put in \n's to help break up long lines
    sequence new_line
    integer c, col
    
    new_line = ""
    col = 1
    for i = 1 to length(line) do
	if col > LINE_WIDTH then
	    new_line = append(new_line, '\n')
	    col = 1
	end if
	c = line[i]
	col = col + 1
	if c < 14 or c = 26 then
	    if c = '\t' or c = '\r' then
		c = ' '
	    elsif c = '\n' then
		col = 1
	    else    
		c = '.'
	    end if
	end if
	new_line = append(new_line, c)
    end for
    if length(line) > 1.5 * LINE_WIDTH then
	new_line &= '\n'
    end if
    return new_line
end function

procedure both_puts(object text)
    puts(SCREEN, text)
    puts(log_file, text)
end procedure

procedure both_printf(sequence format, object values)
    printf(SCREEN, format, values)
    printf(log_file, format, values)
end procedure

function plural(integer n)
-- Yes, this is a bit obsessive...
    if n = 1 then
	return ""
    else
	return "s"
    end if
end function

procedure list_file_spec()
    for i = 1 to length(file_spec) do
	both_puts(file_spec[i])
	if i != length(file_spec) then
	    both_puts(" ")
	end if
    end for
end procedure

procedure final_stats(boolean aborted)
-- show final statistics    
    sequence cm
    
    puts(SCREEN, repeat(' ', 80))
    if aborted then
	both_puts("=== SEARCH WAS ABORTED ===\n")
    end if
    if length(string) = 0 then
	both_printf("%d file name" & plural(file_hits) & " matched (", 
		     file_hits)
	list_file_spec()
	both_puts(")\n")
	both_printf("%d names did not match\n", skipped)
    else
	both_printf("\n%5d file" & plural(scanned) & " scanned (", scanned)
	list_file_spec()
	both_printf(")\n%5d file" & plural(skipped) & " skipped\n", skipped)
	cm = ""
	if alphabetic(orig_string) then
	    if match_case then
		cm = "(case must match)"
	    else
		cm = "(any case)"
	    end if
	end if
	if line_hits then
	    both_printf("%5d line" & plural(line_hits) & 
			" in %d file", {line_hits, file_hits}) 
	else
	    both_printf("%5d file", file_hits)
	end if
	both_printf(plural(file_hits) & 
		    " contained \"%s\" " & cm & "\n", 
		    {orig_string})
	both_puts('\n')
	if no_open then
	    both_printf("couldn't open %d file" & plural(no_open) & '\n', 
			 no_open)
	end if
    end if
    printf(SCREEN, "search time: %.1f seconds\n", time()-start_time)
    if file_hits then
	puts(SCREEN, "\nSee " & log_path & '\n')
    end if
    close(log_file)
end procedure

constant MAX_LINE = 500 

-- space for largest line
sequence buff
buff = repeat(0, MAX_LINE)

function safe_gets(integer fn)
-- Return the next line of text.
-- Lines are split at MAX_LINE to prevent
-- "out of memory" problems on humongous lines
-- and to reduce the amount of extraneous output.
    integer c
    
    for b = 1 to MAX_LINE-1 do
	c = getc(fn)
	if c <= '\n' then
	    if c = '\n' then
		buff[b] = c
		return buff[1..b]
	    elsif c = EOF then
		if b = 1 then
		    return EOF
		else
		    exit
		end if
	    end if
	end if
	buff[b] = c
    end for
    buff[MAX_LINE] = '\n'
    return buff[1..MAX_LINE]
end function

constant SAFE_FILE_SIZE = 100000

function scan(sequence file_name, atom file_size, sequence string)
-- print all lines in current file containing the string
    object line
    sequence match_line
    integer fileNum, found
    boolean found_in_file
    
    graphics:wrap(FALSE)
    puts(SCREEN, file_name & ':' & repeat(' ', 80) & '\r')
    graphics:wrap(TRUE)
    fileNum = open(file_name, "rb")   
    if fileNum = -1 then
	no_open += 1
	both_puts(file_name & ": Couldn't open. Probably locked.\t\t\t\n")
	return 0
    end if
    found_in_file = FALSE
    while TRUE do
	if file_size > SAFE_FILE_SIZE then
	    if get_key() >= ESC then
		abort_now = TRUE
		exit
	    end if
	    line = safe_gets(fileNum)
	else
	    line = gets(fileNum)    
	end if
	if atom(line) then
	    exit -- end of file
	else
	    if match_case then
		match_line = line
	    else
		match_line = fast_lower(line)
	    end if
	    if wild_string then
		found = wildcard:is_match(string, match_line) 
	    else        
		found = match(string, match_line) 
	    end if
	    if found then
		both_puts(clean(file_name & ": " & line))
		line_hits += 1
		found_in_file = TRUE
	    end if
	end if
    end while
    
    scanned += 1
    close(fileNum)
    return found_in_file
end function

function look_at(sequence path_name, sequence dir_entry)
-- see if a file name qualifies for searching
    boolean matched_one
    sequence file_name
    
    if find('d', dir_entry[D_ATTRIBUTES]) then
		return 0 -- a directory
    end if
    file_name = dir_entry[D_NAME]
    
    if equal(file_name, log_name) then
		return 0 -- avoid circularity
    end if
    if equal(file_spec[1], "*.*") then
		-- check skip list
		for i = 1 to length(skip_list) do
	    	if wildcard:is_match(skip_list[i], file_name) then
				skipped += 1
				return get_key() >= ESC
		    end if
		end for
    else
		-- go through list of file specs
		matched_one = FALSE
		for i = 1 to length(file_spec) do
		    if wildcard:is_match(file_spec[i], file_name) then
				matched_one = TRUE
				exit
	    	end if
		end for
		if not matched_one then
	    	skipped += 1
		    return get_key() >= ESC
		end if
    end if

    path_name &= SLASH
    if equal(path_name[1..2], '.' & SLASH) then
		path_name = path_name[3..length(path_name)]
    end if
    path_name &= file_name
    if length(string) = 0 then
		-- just looking for file names
		both_printf("%4d-%02d-%02d %2d:%02d", dir_entry[D_YEAR..D_MINUTE])
		both_printf(" %7d  %s\n", {dir_entry[D_SIZE], path_name})
		file_hits += 1
    else
		file_hits += scan(path_name, dir_entry[D_SIZE], string)
    end if
    return abort_now or get_key() >= ESC
end function

function blank_delim(sequence s)
-- break up a blank-delimited string
    sequence list, segment
    integer i
    list = {}
    i = 1
    while i < length(s) do
		while find(s[i], " \t\r") do
		    i += 1
		end while
		if s[i] = '\n' then
	    	exit
		end if
		segment = ""
		while not find(s[i], " \t\n\r") do
		    segment &= s[i]
	    	i += 1
		end while
		list = append(list, segment)
    end while
    return list
end function

procedure get_file_spec()
-- read in a list of file specifications from user
-- result is stored in file_spec sequence of strings
    sequence spec
    
    puts(SCREEN, "file-spec (*.*): ")
    spec = gets(KEYB)
    puts(SCREEN, '\n')
    file_spec = blank_delim(spec)
    if length(file_spec) = 0 then
		file_spec = {"*.*"}
    end if
end procedure

ifdef UNIX then
	-- do nothing
elsedef
    log_name = upper(log_name)
end ifdef

clear_screen()

cmd = command_line()   -- eui search.ex [string]

if length(cmd) >= 3 then
    orig_string = cmd[3]
else
    puts(SCREEN, "string (* and ? may be used): ")
    orig_string = gets(KEYB)
    orig_string = orig_string[1..length(orig_string)-1] -- remove \n
    puts(SCREEN, '\n')
end if

if alphabetic(orig_string) then
    puts(SCREEN, "match case? (n)")
    get_real_text_starting_position()
    pos = get_position()
    position(pos[1], pos[2] - 2)
    match_case = find('y', gets(KEYB))
    puts(SCREEN, '\n')
else
    match_case = TRUE   
end if

string = orig_string
if not match_case then
    string = fast_lower(string)
end if

wild_string = find('?', string) or find('*', string) 
if wild_string then
    string = '*' & string & '*' -- to match whole line
end if

get_file_spec()

object d
d = dir(current_dir())
if atom(d) then
    puts(SCREEN, "network drive not available\n")
    abort(1)
end if

-- avoid asking about subdirectories 
-- when there aren't any...
scan_subdirs = FALSE
for i = 1 to length(d) do
    if find('d', d[i][D_ATTRIBUTES]) then
	if not find(d[i][D_NAME], {".", ".."}) then
	    puts(SCREEN, "scan subdirectories? (y)")
	    get_real_text_starting_position()
	    pos = get_position()
	    position(pos[1], pos[2] - 2)
	    scan_subdirs = not match("n", gets(KEYB))
	    exit
	end if          
    end if
end for

puts(SCREEN, "\npress q to quit\n\n")

log_file = open(log_path, "w")
if log_file = -1 then
    puts(ERR, "Couldn't open " & log_path & '\n')
    abort(1)
end if

sequence top_dir
start_time = time()
if sequence(dir(".")) then
    puts(log_file, "Searching " & current_dir() & "\n\n")
    top_dir = "."
else
    top_dir = current_dir()
end if

if walk_dir(top_dir, routine_id("look_at"), scan_subdirs) then
end if

final_stats(FALSE)

-- without warning


