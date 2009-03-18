-- buildcpdb.ex Build Codepage Database
include std/serialize.e
include std/error.e
include std/io.e
include std/filesys.e
include std/text.e
include std/sequence.e
include std/convert.e
include std/search.e
include std/sort.e
include std/datetime.e

constant current_version = {1,0,0}

object void
sequence cmdline = command_line()
sequence ecp_path = ""
sequence db_path = ""
sequence new_db_name
sequence backup_db_name
sequence current_db_name
integer silent_running = 0

object v_ECP_List
sequence unicode_list = {}

sequence name_list = {}
sequence posn_list = {}

-- Get command line options
for i = 3 to length(cmdline) do
	if begins("-p", cmdline[i]) then
		if length(cmdline[i]) = 2 then
			if i != length(cmdline) and cmdline[i + 1][1] != '-' then
				ecp_path = trim(cmdline[i + 1])
			end if
		else
			ecp_path = trim(cmdline[i][3 .. $])
		end if
	elsif begins("-o", cmdline[i]) then
		if length(cmdline[i]) = 2 then
			if i != length(cmdline) and cmdline[i + 1][1] != '-' then
				db_path = trim(cmdline[i + 1])
			end if
		else
			db_path = trim(cmdline[i][3 .. $])
		end if
	elsif begins("-?", cmdline[i]) then
		sequence self_name
		self_name = filebase(cmdline[1])
		if not equal(cmdline[1], cmdline[2]) then
			self_name &= ' ' & cmdline[2]
		end if
		printf(1, "\n\nUSAGE:\n  %s [-p<sourcepath>] [-o<outpath>] [-q]\n", {self_name})
		puts(  1, "      where <sourcepath> is the location of the code page source files\n")
		puts(  1, "            <outpath> is the location to receive the new code page database\n")
		puts(  1, "            -q will do a 'quiet' run.\n")
		puts(  1, "      The default for these is the current directory.\n")
		abort(0)
	elsif begins("-q", cmdline[i]) then	
		silent_running = 1
	end if
end for

if length(ecp_path) = 0 then
	ecp_path = '.' & SLASH
	
elsif ecp_path[$] != SLASH then
	ecp_path &= SLASH
	
end if

if length(db_path) = 0 then
	db_path = '.' & SLASH

elsif db_path[$] != SLASH then
	db_path &= SLASH
	
end if

-- Get list of .ecp files
v_ECP_List = dir(ecp_path & "*.ecp")
if atom(v_ECP_List) then
	printf(2, "No code page files found in directory '%s'.\n", {ecp_path})
	abort(1)
end if


-- Create empty database
new_db_name = db_path & "new_ecp.dat"
current_db_name = db_path & "ecp.dat"
backup_db_name = db_path & "backup_ecp.dat"
void = delete_file(new_db_name)

integer db = open(new_db_name, "wb")
if db = -1 then
	printf(2,"Failed to create new codepage database '%s'\n", {new_db_name})
	abort(2)
end if

puts(db, serialize({1, -- ECP Databse format version
          format(now_gmt(), "%Y%m%d%H%M%S" ), -- date
          {4,0,0,0}, -- eu:version()
          {filebase(cmdline[2]), current_version } -- creation tool identity
         })
    )
integer idxoffset = where(db) -- Remember where we are in the file.
puts(db, repeat(0, 9)) -- Reserve some space in the file at this position.

-- For each file in the list, add it to the database.
for i = 1 to length(v_ECP_List) do
	if find('d', v_ECP_List[i][D_ATTRIBUTES]) = 0 then
		load_file(ecp_path & v_ECP_List[i][D_NAME])
	end if
end for

-- Add unicode table to database
name_list = append(name_list, "unicode")
posn_list &= 0
posn_list[$] = where(db)

unicode_list = sort(unicode_list)
puts(db, serialize( vslice(unicode_list, 1) ) ) -- "code points"
puts(db, serialize( vslice(unicode_list, 2) ) ) -- "names "


integer indx_pos = where(db)

puts(db, serialize( {name_list, posn_list}))

-- Go back to the 'reserved' area in the file.
void = seek(db, idxoffset)
puts(db, serialize( indx_pos) )

close(db)

-- Rename old databse
void = delete_file(backup_db_name)
void = rename_file(current_db_name, backup_db_name)

-- Rename new database
void = rename_file(new_db_name, current_db_name)

-- if ok Delete old database otherwise restore old database
if file_exists(new_db_name) then
	if not file_exists(current_db_name) then
		void = rename_file(backup_db_name, current_db_name)
	end if
	printf(2, "FAILED: The new Code Page table '%s' could not be renamed as '%s'.\n",
				{new_db_name, current_db_name})
elsif not silent_running then
	printf(1, "The Code Page table '%s' has been built.\n", {current_db_name})
end if
void = delete_file(backup_db_name)
	

procedure load_file(sequence file_path)
	integer pos
	object file_text
	sequence line
	sequence upper_line
	sequence kv
	sequence key
	sequence value
	integer key_num
	integer unicode
	sequence vl_title = {}
	sequence vl_bpc = {}
	sequence vl_codes = {}
	sequence vl_unicodes = {}
	sequence vl_uppercase = {}
	sequence vl_lowercase = {}
	
	if not silent_running then
		printf(1, "Loading %s ...", {file_path})
	end if

	file_text = read_lines(file_path)
	if atom(file_text) then
		puts(2, " failed; could not read file\n")
	end if
	
	pos = 0
	-- Find first section 
	while pos < length(file_text) do
		pos += 1
		line = next_line(file_text, pos)
		upper_line = upper(line)
	
		if length(line) >= 8 then
			if equal(upper_line[1..8], "--HEAD--") then
				exit
			end if
		end if
		
	end while
		
	-- Process 'head' section
	while pos < length(file_text) do
		pos += 1
		line = next_line(file_text, pos)
		upper_line = upper(line)
		
		if length(line) >= 8 then
			if equal(upper_line[1..8], "--CODE--") then
				exit
			end if
		end if
		kv = split(line, "=", 1)
		if length(kv) != 2 then
		    continue
		end if
		
		key = upper(trim(kv[1]))
		value = trim(kv[2])
		if equal(key, "TITLE") then
			vl_title = value
		elsif equal(key, "BPC") then
			vl_bpc = value
		end if
		
	end while
	-- Process 'code' section
	while pos < length(file_text) do
		pos += 1
		line = next_line(file_text, pos)
		upper_line = upper(line)

		if length(line) >= 8 then
			if equal(upper_line[1..8], "--CASE--") then
				exit
			end if
		end if
		
		kv = split(line, "=", 1)
		if length(kv) != 2 then
		    continue
		end if
		
		value = trim(kv[2])
		if begins("U+", value) = 0 then
			continue
		end if
		key_num = hex_text(trim(kv[1]))
		kv = split(value[3..$], ":", 1)
		if length(kv) != 2 then
		    continue
		end if
		unicode = hex_text(trim(kv[1]))
		value = trim(kv[2])
		vl_codes &= key_num
		vl_unicodes &= unicode
		for i = 1 to length(unicode_list) do
			if unicode = unicode_list[i][1] then
				unicode = -1
				exit
			end if
		end for
		if unicode >= 0 then
			unicode_list = append(unicode_list, {unicode, value})
		end if
				
		
	end while
	
	-- Process 'case' section
	while pos < length(file_text) do
		pos += 1
		line = next_line(file_text, pos)
		upper_line = upper(line)

		if length(line) > 2 then
			if equal(upper_line[1..2], "--") then
				exit
			end if
		end if
		
		kv = split(line, "=", 1)
		if length(kv) != 2 then
		    continue
		end if
		vl_uppercase &= hex_text(trim(kv[1]))
		vl_lowercase &= hex_text(trim(kv[2]))
		
	end while

	-- Build this table.
	name_list = append(name_list, filebase(file_path))
	posn_list &= 0
	posn_list[$] = where(db)
	
	puts(db, serialize( vl_uppercase)) -- "uppercase"
	puts(db, serialize( vl_lowercase)) -- "lowercase"
	puts(db, serialize( vl_title)) -- "title"
	puts(db, serialize( vl_bpc)) -- "bpc"
	puts(db, serialize( vl_codes)) -- "codes"
	puts(db, serialize( vl_unicodes)) -- "unicodes"
	
	
	if not silent_running then
		puts(1, " done.\n")	
	end if

end procedure

function next_line(sequence lines, integer lineno)
	sequence line
	integer c
	integer quoted = -1
	
	line = trim(lines[lineno])
	for i = length(line) to 1 by -1 do
		c = line[i]
		if quoted = -1 then -- Not in a quoted string
			if c = ';' then
				return trim(line[1..i-1])
			end if
		end if
		
		if find(c, "'`\"") then
			if c = quoted then
				quoted = -1 -- No longer in a string
			elsif quoted = -1 then
				quoted = c -- Start of a quoted string
			end if
		end if
	end for
	
	return line
end function
			