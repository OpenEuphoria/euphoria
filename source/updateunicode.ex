-- get a directory from https://www.unicode.org/Public/zipped/12.1.0/UCD.zip
include std/convert.e
include std/net/http.e
include std/types.e
include std/filesys.e
include std/get.e
include std/sequence.e as sequence
include std/console.e
include std/regex.e
include std/pretty.e
include std/io.e
include std/search.e as search

constant MAX_UNICODE_VAL = #10_FFFF
constant cl = command_line()
sequence seek_dir = "."

procedure eputsln(sequence s)
   puts(2, s & '\n')
end procedure

procedure eprintfln(string fmt, sequence s)
   printf(2, fmt & '\n', s)
end procedure

if length(cl) > 3 then
    eputsln("Error:  More than one directory specified.")
end if

for i = 3 to length(cl) do
   sequence argument = cl[i]
   seek_dir = argument
end for

object file_list = dir(seek_dir)
if atom(file_list) then
    eputsln("Cannot open " & seek_dir)
end if

sequence unicode = repeat(0, MAX_UNICODE_VAL)
sequence used_names = {}

constant dont_use_list = {"CaseFolding.txt", "CompositionExclusions.txt"}
constant name_with_other = regex:new(`([A-Z][-A-Z0-9_ ]+) +\(([A-Z][A-Z0-9_ ]*)\)`)

function get_names(ascii_string s)
	if length(s) < 2 then
		return {}
	end if
	integer word_count = 1
	if not t_alpha(s[1]) then
		return {}
	end if
	for si = 1 to length(s) do
		if t_alpha(s[si]) or t_space(s[si]) or t_digit(s[si]) or s[si] = '-' then
			continue
		end if
		if s[si] = '(' then
			object buffer = regex:matches(name_with_other, s)
			if atom(buffer) then
				eputsln("Erroneous data:")
				pretty_print(2, s, {3})
				abort(0)
			end if
			return buffer[2..$]
		end if
		return {}
	end for
	return {s}
end function	

function set_cp(sequence unicode, integer cp, sequence record)
	if cp < 1 then
		return unicode
	end if
	
	sequence names
	if equal(record[name_index],"<control>") then
		-- In order to distinguish between #1F514 which is a drawing of a BELL
		-- and 7 which makes the sound of a BELL.  Control characters names
		-- have the word CONTROL in their names.		
		names = get_names(record[name_control_index])
		record[name_control_index] = names
		for ni = 1 to length(names) do
			sequence name = "CONTROL " & names[ni]
			names[ni] = name
		end for
		record[name_index] = names
	else
		names = get_names(record[name_index])
		record[name_index] = names
	end if
	if length(names) then
		unicode[cp] = record
	end if
	return unicode
end function

integer rmfn = open(seek_dir & SLASH & "ReadMe.txt", "r") -- UTF8 of course
object rm_data = read_file(rmfn)
if atom(rm_data) then
    eprintfln("Cannot open 'ReadMe.txt' in the directory '%s'", {seek_dir})
    abort(1)
end if

sequence version_message_x = regex:new("Version ([0-9\\.]+)")
sequence version_data = regex:matches(version_message_x, rm_data)
sequence version = version_data[2]

sequence null_record
constant name_index = 2
constant name_control_index = 11
for fi = 1 to length(file_list) label "fileloop" do
    sequence file_entry = file_list[fi]
    if not eu:find('d', file_entry[D_ATTRIBUTES]) and not eu:find(file_entry[D_NAME], dont_use_list) and equal(file_entry[D_NAME],"UnicodeData.txt") then
    	-- good a file
    	integer fn = open(seek_dir & SLASH & file_entry[D_NAME],"r")
    	integer line_no = 0
    	integer no_comment_line_no = 0
    	object line
    	while sequence(line) with entry do
    	    if length(line) > 1 and line[1] != '#' then
    	    	line = line[1..$-1]
    	    	no_comment_line_no += 1
    	    	sequence record
    	    	if equal(file_entry[D_NAME], "UnicodeData.txt") = 0 then
    	    		continue
    	    	end if
    	    	record = sequence:split(line, ";")
    	    	if 0 and no_comment_line_no < 5 then
    	    		printf(2, "'%s':", file_entry[D_NAME..D_NAME])
    	    		if length(record) = 0 then
    	    			eputsln("Datum {}")
    	    		elsif length(record) = 1 then
    	    			eprintfln("Datum {'%s'}", record)
    	    		elsif length(record) = 2 then
	    	    		eprintfln("Datum {'%s', '%s'}", record[1..2])
	    	    	else
	    	    		eprintfln("Datum {'%s', '%s', ...}", record[1..2])
	    	    	end if
	    	    	if no_comment_line_no = 4 then
	    	    		any_key()
	    	    	end if
    	    	end if
    	    	if equal(record[name_index],"<control>") and
     	    	  compare("NULL",record[name_control_index]) = 0 then
    	    		null_record = record
    	    	end if
    	    	if length(record) and t_xdigit(record[1]) then
    	    		object code_point
    	    		integer error
    	    		code_point = hex_text(record[1])
    	    		if code_point > MAX_UNICODE_VAL then
    	    			exit
    	    		end if
    	    		if integer(code_point) and length(record) > 9 then
	    	    		unicode = set_cp(unicode, code_point, record)
	    	    		if code_point >0 and code_point <= length(unicode) and 
	    	    			length(unicode[code_point]) >= name_index then
							for ni = 1 to length(unicode[code_point][name_index]) do
								sequence name = unicode[code_point][name_index][ni]
								if eu:find(name, used_names) then
									integer ol = code_point
									for k = 1 to length(unicode) do
										object r = unicode[k]
										if atom(r) then
											continue
										end if
										if eu:find(name, r[name_index]) then
											ol = k
											if ol != code_point then
												exit
											end if
										end if
									end for --k
									eprintfln("Error: character name used twice.\n" &
									"The name is '%s' at code point #%4x and #%4x", {name, code_point, ol})
									unicode[code_point] = 0
									goto "getnew"
								end if
							end for -- ni
							used_names &= unicode[code_point][name_index]
						end if
    	    		end if
    	    	end if -- t_xdigit
    	    end if
    	entry
    		label "getnew"
    		line_no += 1
    	    line = gets(fn)
    	end while
    	close(fn)
    	eputsln(file_entry[D_NAME])
    end if
end for



integer cpfn = open("codepoints.e", "w")

procedure oprintfln(sequence fmt, sequence s)
	printf(1, fmt & '\n', s)
end procedure

printf(cpfn,
`
-- This is our database for unicode characters 
-- from Version %s of the Unicode Standard.

--****
-- === Information
--
-- Every code_point in the enum other than NULL can get a sequence of names for 
-- it by indexing unicode_names.   For example, unicode_names[CENT_SIGN] is
-- {"CENT SIGN"}.  And unicode_names[CONTROL_LF] is {"CONTROL LINE FEED", 
-- "CONTROL LF"}.
--
-- In order to distinguish between #1F514 which is a drawing of a BELL
-- and 7 which makes the sound of a BELL.  Control characters names have
-- the word CONTROL in their names.
--
-- To compose Unicode Strings siply use & :
-- "35" & CENT_SIGN is 35 with the cent symbol in unicode
`, {version})
puts(cpfn, "export enum NULL = 0,\n")
integer last_rec_no = 0

for i = 1 to length(unicode) do
    object record = unicode[i]
    if atom(record) then
    	continue
    end if
    if length(record)=0 then
    	unicode[i] = 0
    	continue
    end if
    if length(record) < name_index then
    	eputsln("Bad record look:")
    	? record
    	any_key()
    end if
    sequence new_names = record[name_index]
    sequence underscored
	for j = 1 to length(new_names) do
		sequence name = new_names[j]
		name = search:find_replace(' ', name, '_')
		name = search:find_replace('-', name, '_')
		
		if j = 1 then
			underscored = name
		end if
		if i = last_rec_no + 1 and j = 1 then
			printf(cpfn, "    %s,\n", {name})
		elsif j > 1 then
			printf(cpfn, "    %s = %s,\n", {name, underscored})
		else
			printf(cpfn, "    %s = #%x,\n", {name, i})
		end if
		flush(cpfn)
	end for
	last_rec_no = i
end for
puts(cpfn, "    $\n")

while atom(unicode[$]) do
	unicode = unicode[1..$-1]
end while
for ui = 1 to length(unicode) do
	if atom(unicode[ui]) then
		continue
	end if
	unicode[ui] = unicode[ui][name_index]
end for

puts(cpfn,"export constant unicode_names = ")
pretty_print(cpfn, unicode, {3,4,1})
puts(cpfn, "\n")

close(cpfn)