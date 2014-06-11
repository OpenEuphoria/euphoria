--****
-- == Euphoria Database (EDS)
--
-- <<LEVELTOC level=2 depth=4>>

namespace eds

include std/types.e
include std/convert.e
include std/datetime.e
include std/error.e
include std/filesys.e
include std/io.e
include std/machine.e
include std/math.e
include std/pretty.e
include std/text.e

-- === Database File Format
--
-- ==== Header
-- * byte 0: magic number for this file-type: 77
-- * byte 1: version number (major)
-- * byte 2: version number (minor)
-- * byte 3: 4-byte pointer to block of table headers
-- * byte 7: number of free blocks
-- * byte 11: 4-byte pointer to block of free blocks
--
-- ==== Block of Table Headers
-- * -4: allocated size of this block (for possible reallocation)
-- *  0: number of table headers currently in use
-- *  4: table header1
-- * 16: table header2
-- * 28: etc.
--
-- ==== Table Header
-- * 0: pointer to the name of this table
-- * 4: total number of records in this table
-- * 8: number of blocks of records
-- * 12: pointer to the index block for this table
--
-- There are two levels of pointers. The logical array of key pointers
-- is split up across many physical blocks. A single index block
-- is used to select the correct small block. This allows
-- inserts and deletes to be made without having to shift a
-- large number of key pointers. Only one small block needs to
-- be adjusted. This is particularly helpful when the table contains
-- many thousands of records.
--
-- ==== Index Block
-- one per table
--
-- * -4: allocated size of index block
-- * 0: number of records in 1st block of key pointers
-- * 4: pointer to 1st block
-- * 8: number of records in 2nd "                   "
-- * 12: pointer to 2nd block
-- * 16: etc.
--
-- ==== Block of Key Pointers
-- many per table
--
-- * -4: allocated size of this block in bytes
-- * 0: key pointer 1
-- * 4: key pointer 2
-- * 8: etc.
--
-- ==== Free List
-- in ascending order of address
--
-- * -4: allocated size of block of free blocks
-- * 0: address of 1st free block
-- * 4: size of 1st free block
-- * 8: address of 2nd free block
-- * 12: size of 2nd free block
-- * 16: etc.
--
-- The key value and the data value for a record are allocated space
-- as needed. A pointer to the data value is stored just before the
-- key value. Euphoria objects, key and data, are stored in a compact form.
--
-- All allocated blocks have the size of the block in bytes, stored in the 
-- four bytes just before the address.

--****
-- === Error Status Constants

public enum
	--** Database is OK, not error has occurred.
	DB_OK = 0,
	--** The database could not be opened.
	DB_OPEN_FAIL = -1,
	--** The database could not be created, it already exists.
	DB_EXISTS_ALREADY = -2,
	--** A lock could not be gained on the database.
	DB_LOCK_FAIL = -3,
	--** An invalid name suppled when creating a table.
	DB_BAD_NAME = -4,
	--** A fatal error has occurred.
	DB_FATAL_FAIL = -404,
	$

--****
-- === Lock Type Constants

public enum
	--** Do not lock the file.
	DB_LOCK_NO = 0,
	
	--** Open the database with read-only access but allow others to update it.
	DB_LOCK_SHARED,
	
	--** Open the database with read and write access.
	DB_LOCK_EXCLUSIVE,
	
	--** Open the database with read-only access and ignore others updating it
	DB_LOCK_READ_ONLY,
	
	$

--****
-- === Error Code Constants

public enum
	--** Missing 0 terminator
	MISSING_END = 900,
	--** current_db is not set
	NO_DATABASE,
	--** ##io:seek## failed.
	BAD_SEEK,
	--** no table was found.
	NO_TABLE,
	--** this table already exists.
	DUP_TABLE,
	--** unknown key_location index was supplied.
	BAD_RECNO,
	--** could not insert a new record.
	INSERT_FAILED,
	--** last error code
	LAST_ERROR_CODE,
	--** bad file
	BAD_FILE,
	$

constant DB_MAGIC = 77
constant DB_MAJOR = 4, DB_MINOR = 0   -- database created with Euphoria v4.0
constant SIZEOF_TABLE_HEADER = 16
constant TABLE_HEADERS = 3, FREE_COUNT = 7, FREE_LIST = 11 --, SIZEOF_DATABASE_HEADER = 14


-- initial sizes for various things:
constant DEF_INIT_FREE = 5,
		 DEF_INIT_TABLES = 5,
		 MAX_INDEX = 10,
		 DEF_INIT_RECORDS = 50

-- 
--****
-- === Indexes for Connection Option Structure.

public enum 
	--** Locking method
	CONNECT_LOCK,
	
	--** Initial number of tables to create
	CONNECT_TABLES,
	
	--** Initial number of free pointers to create
	CONNECT_FREE,
	$
	
constant TRUE = 1

integer  current_db = -1
atom     current_table_pos = -1
sequence current_table_name = ""
sequence db_names = {}
sequence db_file_nums = {}
sequence db_lock_methods = {}
integer  current_lock = 0
sequence key_pointers = {}
sequence key_cache = {}
sequence cache_index = {}
integer  caching_option = 1

--****
-- === Database Connection Options

public constant
	--** Disconnect a connected database
	DISCONNECT   = "!disconnect!",
	
	--** Locking method to use
	LOCK_METHOD  = "lock_method",
	
	--** The initial number of tables to reserve space for when creating a database.
	INIT_TABLES  = "init_tables",
	
	--** The initial number of free space pointers to reserve space for when creating a database.
	INIT_FREE    = "init_free",
	
	--** Fetch the details about the alias
	CONNECTION   = "?connection?",
	
	$
	
sequence Known_Aliases = {}
sequence Alias_Details = {}

--****
-- === Variables

--**
-- This is an //Exception handler//.
--
-- Set this to a valid routine_id value for a procedure that
-- will be called whenever the library detects a serious error. Your procedure
-- will be passed a single text string that describes the error. It may also
-- call [[:db_get_errors]] to get more detail about the cause of the error.

public integer db_fatal_id 

db_fatal_id = DB_FATAL_FAIL	-- Initialized separately from declaration so
                            -- the initial value doesn't show up in docs.


sequence vLastErrors = {}


procedure fatal(integer errcode, sequence msg, sequence routine_name, sequence parms)
	vLastErrors = append(vLastErrors, {errcode, msg, routine_name, parms})
	if db_fatal_id >= 0 then
		call_proc(db_fatal_id, {sprintf("Error Code %d: %s, from %s", {errcode, msg, routine_name})})
	end if
end procedure

function get1()
-- read 1-byte value at current position in database file
	return getc(current_db)
end function

atom mem0, mem1, mem2, mem3
mem0 = machine:allocate(4)
mem1 = mem0 + 1
mem2 = mem0 + 2
mem3 = mem0 + 3

function get4()
-- read 4-byte value at current position in database file
	poke(mem0, getc(current_db))
	poke(mem1, getc(current_db))
	poke(mem2, getc(current_db))
	poke(mem3, getc(current_db))
	return peek4u(mem0)
end function

function get_string()
-- read a 0-terminated string at current position in database file
	sequence s
	integer c
	integer i

	s = repeat(0, 256)
	i = 0
	while c with entry do
		if c = -1 then
			fatal(MISSING_END, "string is missing 0 terminator", "get_string", {io:where(current_db)})
			exit
		end if
		i += 1
		if i > length(s) then
			s &= repeat(0, 256)
		end if
		s[i] = c
	  entry
		c = getc(current_db)
	end while
	return s[1..i]
end function

function equal_string(sequence target)
-- test if string at current position in database file equals given string
	integer c
	integer i

	i = 0
	while c with entry do
		if c = -1 then
			fatal(MISSING_END, "string is missing 0 terminator", "equal_string", {io:where(current_db)})
			return DB_FATAL_FAIL
		end if
		i += 1
		if i > length(target) then
			return 0
		end if
		if target[i] != c then
			return 0
		end if
	  entry
		c = getc(current_db)
	end while
	return (i = length(target))
end function

-- Compressed format of Euphoria objects on disk
--
-- First byte:
--          0..248    -- immediate small integer, -9 to 239
					  -- since small negative integers -9..-1 might be common
constant I2B = 249,   -- 2-byte signed integer follows
		 I3B = 250,   -- 3-byte signed integer follows
		 I4B = 251,   -- 4-byte signed integer follows
		 F4B = 252,   -- 4-byte f.p. number follows
		 F8B = 253,   -- 8-byte f.p. number follows
		 S1B = 254,   -- sequence, 1-byte length follows, then elements
		 S4B = 255    -- sequence, 4-byte length follows, then elements

constant MIN1B = -9,
		 MAX1B = 239,
		 MIN2B = -power(2, 15),
		 MAX2B =  power(2, 15)-1,
		 MIN3B = -power(2, 23),
		 MAX3B =  power(2, 23)-1,
		 MIN4B = -power(2, 31)

function decompress(integer c)
-- read a compressed Euphoria object from disk
-- if c is set, then c is not <= 248
	sequence s
	integer len

	if c = 0 then
		c = getc(current_db)
		if c < I2B then
			return c + MIN1B
		end if
	end if

	switch c with fallthru do
		case I2B then
			return getc(current_db) +
				#100 * getc(current_db) +
				MIN2B

		case I3B then
			return getc(current_db) +
				#100 * getc(current_db) +
				#10000 * getc(current_db) +
				MIN3B

		case I4B then
			return get4() + MIN4B

		case F4B then
			return convert:float32_to_atom({getc(current_db), getc(current_db),
				getc(current_db), getc(current_db)})

		case F8B then
			return convert:float64_to_atom({getc(current_db), getc(current_db),
				getc(current_db), getc(current_db),
				getc(current_db), getc(current_db),
				getc(current_db), getc(current_db)})

		case else
			-- sequence
			if c = S1B then
				len = getc(current_db)
			else
				len = get4()
			end if
			s = repeat(0, len)
			for i = 1 to len do
				-- in-line small integer for greater speed on strings
				c = getc(current_db)
				if c < I2B then
					s[i] = c + MIN1B
				else
					s[i] = decompress(c)
				end if
			end for
			return s
	end switch
end function

function compress(object x)
-- return the compressed representation of a Euphoria object
-- as a sequence of bytes
	sequence x4, s

	if integer(x) then
		if x >= MIN1B and x <= MAX1B then
			return {x - MIN1B}

		elsif x >= MIN2B and x <= MAX2B then
			x -= MIN2B
			return {I2B, and_bits(x, #FF), floor(x / #100)}

		elsif x >= MIN3B and x <= MAX3B then
			x -= MIN3B
			return {I3B, and_bits(x, #FF), and_bits(floor(x / #100), #FF), floor(x / #10000)}

		else
			return I4B & convert:int_to_bytes(x-MIN4B)

		end if

	elsif atom(x) then
		-- floating point
		x4 = convert:atom_to_float32(x)
		if x = convert:float32_to_atom(x4) then
			-- can represent as 4-byte float
			return F4B & x4
		else
			return F8B & convert:atom_to_float64(x)
		end if

	else
		-- sequence
		if length(x) <= 255 then
			s = {S1B, length(x)}
		else
			s = S4B & convert:int_to_bytes(length(x))
		end if
		for i = 1 to length(x) do
			s &= compress(x[i])
		end for
		return s
	end if
end function

procedure put1(integer x)
-- write 1 byte to current database file
	puts(current_db, x)
end procedure

sequence memseq
memseq = {mem0, 4}

procedure put4(atom x)
-- write 4 bytes to current database file
-- x is 32-bits max
	poke4(mem0, x) -- faster than doing divides etc.
	puts(current_db, peek(memseq))
end procedure

procedure putn(sequence s)
-- write a sequence of bytes to current database file
	puts(current_db, s)
end procedure

procedure safe_seek(atom pos, sequence msg = "")
-- Seek to a position in the current db file, but do it with care.
	atom eofpos
	if current_db = -1 then
		fatal(NO_DATABASE, "no current database defined", "safe_seek", {pos})
		return
	end if
	
	io:seek(current_db, -1)
	eofpos = io:where(current_db)
	if pos > eofpos then
		fatal(BAD_SEEK, "io:seeking past EOF", "safe_seek", {pos})
		return
	end if
	if io:seek(current_db, pos) != 0 then
		fatal(BAD_SEEK, "io:seek to position failed", "safe_seek", {pos})
		return
	end if
	if pos != -1 then
		if io:where(current_db) != pos then
			fatal(BAD_SEEK, "io:seek not in position", "safe_seek", {pos})
			return
		end if
	end if
end procedure

--****
-- === Routines

--**
-- fetches the most recent set of errors recorded by the library.
--
-- Parameters:
--		# ##clearing## : if zero the set of errors is not reset, otherwise
--      it will be cleared out. The default is to clear the set.
--
-- Returns:
--   A **sequence**, each element is a set of four fields.
--     	# Error Code.
--		# Error Text.
--		# Name of library routine that recorded the error.
--      # Parameters passed to that routine.
--
-- Comments:
--  * A number of library routines can detect errors. If the routine is a 
--    function, it usually returns an error code. However, procedures that
--    detect an error can not do that. Instead, they record the error details
--    and you can query that after calling the library routine. 
--	* Both functions and procedures that detect errors record the details
--    in the ##Last Error Set##, which is fetched by this function.
--
--
-- Example 1:
-- <eucode>
-- db_replace_data(recno, new_data)
-- errs = db_get_errors()
-- if length(errs) != 0 then
--     display_errors(errs)
--     abort(1)
-- end if
-- </eucode>

public function db_get_errors(integer clearing = 1)
	sequence lErrors
	
	lErrors = vLastErrors
	if clearing then
		vLastErrors = {}
	end if
	
	return lErrors
end function

--**
-- prints the current database in readable form to file ##fn##.
--
-- Parameters:
--		# ##fn## : the destination file for printing the current Euphoria database;
--		# ##low_level_too## : a boolean. If //true//, a byte-by-byte binary dump
--              is presented as well; otherwise this step is skipped. If omitted,
--              //false// is assumed.
--
-- Errors:
-- 		If the current database is not defined, an error will occur.
--
-- Comments:
--  * All records in all tables are shown.
--	* If low_level_too is non-zero,
--   then a low-level byte-by-byte dump is also shown. The low-level
--   dump will only be meaningful to someone who is familiar
--   with the internal format of a Euphoria database.
--
-- Example 1:
-- <eucode>
-- if db_open("mydata", DB_LOCK_SHARED) != DB_OK then
--     puts(2, "Couldn't open the database!\n")
--     abort(1)
-- end if
-- fn = open("db.txt", "w")
-- db_dump(fn) -- Simple output
-- db_dump("lowlvl_db.txt", 1) -- Full low-level dump created.
-- </eucode>

public procedure db_dump(object file_id, integer low_level_too = 0)
-- print an open database in readable form to file fn
-- (Note: If you turn database.e into a .dll or .so, you will
-- have to use a file name, rather than an open file number.
-- All other database.e routines are ok as they are.)
	integer magic, minor, major
	integer fn
	atom tables, ntables, tname, trecords, t_header, tnrecs,
		 key_ptr, data_ptr, size, addr, tindex, fbp
	object key, data
	integer c, n, tblocks
	atom a
	sequence ll_line
	integer hi, ci

	if sequence(file_id) then
		fn = open(file_id, "w")
	elsif file_id > 0 then
		fn = file_id
		puts(fn, '\n')
	else
		fn = file_id
	end if
	if fn <= 0 then
		fatal( BAD_FILE, "bad file", "db_dump", {file_id, low_level_too})
		return
	end if

	printf(fn, "Database dump as at %s\n", {datetime:format( datetime:now(), "%Y-%m-%d %H:%M:%S")})
	io:seek(current_db, 0)
	if length(vLastErrors) > 0 then return end if
	magic = get1()
	if magic != DB_MAGIC then
		puts(fn, "This is not a Euphoria Database file.\n")
	else
		major = get1()
		minor = get1()
		printf(fn, "Euphoria Database System Version %d.%d\n\n", {major, minor})
		tables = get4()
		io:seek(current_db, tables)
		ntables = get4()
		printf(fn, "The \"%s\" database has %d table",
			   {db_names[eu:find(current_db, db_file_nums)], ntables})
		if ntables = 1 then
			puts(fn, "\n")
		else
			puts(fn, "s\n")
		end if
	end if

	if low_level_too then
		-- low level dump: show all bytes in the file
		puts(fn, "            Disk Dump\nDiskAddr " & repeat('-', 58))
		io:seek(current_db, 0)
		a = 0
		while c >= 0 with entry do

			if c = -1 then
				exit
			end if
			if remainder(a, 16) = 0 then
				if a > 0 then
					printf(fn, "%s\n", {ll_line})
				else
					puts(fn, '\n')
				end if
				ll_line = repeat(' ', 67)
				ll_line[9] = ':'
				ll_line[48] = '|'
				ll_line[67] = '|'
				hi = 11
				ci = 50
				ll_line[1..8] = sprintf("%08x", a)
			end if
			ll_line[hi .. hi + 1] = sprintf("%02x", c)
			hi += 2
			if eu:find(hi, {19, 28, 38}) then
				hi += 1
				if hi = 29 then
					hi = 30
				end if
			end if
			if c > ' ' and c < '~' then
				ll_line[ci] = c
			else
				ll_line[ci] = '.'
			end if
			ci += 1

			a += 1
		  entry
			c = getc(current_db)
		end while
		printf(fn, "%s\n", {ll_line})
		puts(fn, repeat('-', 67) & "\n\n")
	end if

	-- high level dump
	io:seek(current_db, 0)
	magic = get1()
	if magic != DB_MAGIC then
		if sequence(file_id) then
			close(fn)
		end if
		return
	end if

	major = get1()
	minor = get1()

	tables = get4()
	if low_level_too then printf(fn, "[tables:#%08x]\n", tables) end if
	io:seek(current_db, tables)
	ntables = get4()
	t_header = io:where(current_db)
	for t = 1 to ntables do
		if low_level_too then printf(fn, "\n---------------\n[table header:#%08x]\n", t_header) end if
		-- display the next table
		tname = get4()
		tnrecs = get4()
		tblocks = get4()
		tindex = get4()
		if low_level_too then printf(fn, "[table name:#%08x]\n", tname) end if
		io:seek(current_db, tname)
		printf(fn, "\ntable \"%s\", records:%d    indexblks: %d\n\n\n", {get_string(), tnrecs, tblocks})
		if tnrecs > 0 then
			for b = 1 to tblocks do
				if low_level_too then printf(fn, "[table block %d:#%08x]\n", {b, tindex+(b-1)*8}) end if
				io:seek(current_db, tindex+(b-1)*8)
				tnrecs = get4()
				trecords = get4()
				if tnrecs > 0 then
					printf(fn, "\n--------------------------\nblock #%d, ptrs:%d\n--------------------------\n", {b, tnrecs})
					for r = 1 to tnrecs do
						-- display the next record
						if low_level_too then printf(fn, "[record %d:#%08x]\n", {r, trecords+(r-1)*4}) end if
						io:seek(current_db, trecords+(r-1)*4)
						key_ptr = get4()
						if low_level_too then printf(fn, "[key %d:#%08x]\n", {r, key_ptr}) end if
						io:seek(current_db, key_ptr)
						data_ptr = get4()
						key = decompress(0)
						puts(fn, "  key: ")
						pretty:pretty_print(fn, key, {2, 2, 8})
						puts(fn, '\n')
						if low_level_too then printf(fn, "[data %d:#%08x]\n", {r, data_ptr}) end if
						io:seek(current_db, data_ptr)
						data = decompress(0)
						puts(fn, "  data: ")
						pretty:pretty_print(fn, data, {2, 2, 9})
						puts(fn, "\n\n")
					end for
				else
					printf(fn, "\nblock #%d (empty)\n\n", b)
				end if
			end for
		end if
		t_header += SIZEOF_TABLE_HEADER
		io:seek(current_db, t_header)
	end for
	-- show the free list
	if low_level_too then printf(fn, "[free blocks:#%08x]\n", FREE_COUNT) end if
	io:seek(current_db, FREE_COUNT)
	n = get4()
	puts(fn, '\n')
	if n > 0 then
		fbp = get4()
		printf(fn, "Number of Free blocks: %d ", n)
		if low_level_too then printf(fn, " [#%08x]:", fbp) end if
		puts(fn, '\n')
		io:seek(current_db, fbp)
		for i = 1 to n do
			addr = get4()
			size = get4()
			printf(fn, "%08x: %6d bytes\n", {addr, size})
		end for
	else
		puts(fn, "No free blocks available.\n")
	end if
	if sequence(file_id) then
		close(fn)
	end if

end procedure

--**
-- detects corruption of the free list in a Euphoria database.
--
-- Comments:
-- This is a debug routine used by RDS to detect corruption of the free list.
-- Users do not normally call this.
--
public procedure check_free_list()
	atom free_count, free_list, addr, size, free_list_space
	atom max

	safe_seek(-1)
	if length(vLastErrors) > 0 then return end if
	max = io:where(current_db)
	safe_seek( FREE_COUNT)
	free_count = get4()
	if free_count > max/13 then
		error:crash("free count is too high")
	end if
	free_list = get4()
	if free_list > max then
		error:crash("bad free list pointer")
	end if
	safe_seek( free_list - 4)
	free_list_space = get4()
	if free_list_space > max or free_list_space < 0 then
		error:crash("free list space is bad")
	end if
	for i = 0 to free_count - 1 do
		safe_seek( free_list + i * 8)
		addr = get4()
		if addr > max then
			error:crash("bad block address")
		end if
		size = get4()
		if size > max then
			error:crash("block size too big")
		end if
		safe_seek( addr - 4)
		if get4() > size then
			error:crash("bad size in front of free block")
		end if
	end for
end procedure

function db_allocate(atom n)
-- Allocate (at least) n bytes of space in the database file.
-- The usable size + 4 is stored in the 4 bytes before the returned address.
-- Upon return, the file pointer points at the allocated space, so data
-- can be stored into the space immediately without a safe_seek.
-- When space is allocated at the end of the file, it will be exactly
-- n bytes in size, and the caller must fill up all the space immediately.
	atom free_list, size, size_ptr, addr
	integer free_count
	sequence remaining

	io:seek(current_db, FREE_COUNT)
	free_count = get4()
	if free_count > 0 then
		free_list = get4()
		io:seek(current_db, free_list)
		size_ptr = free_list + 4
		for i = 1 to free_count do
			addr = get4()
			size = get4()
			if size >= n+4 then
				-- found a big enough block
				if size >= n+16 then
					-- loose fit: shrink first part, return 2nd part
					io:seek(current_db, addr - 4)
					put4(size-n-4) -- shrink the block
					io:seek(current_db, size_ptr)
					put4(size-n-4) -- update size on free list too
					addr += size-n-4
					io:seek(current_db, addr - 4) 
					put4(n+4)
				else
					-- close fit: remove whole block from list and return it
					remaining = io:get_bytes(current_db, (free_count-i) * 8)
					io:seek(current_db, free_list+8*(i-1))
					putn(remaining)
					io:seek(current_db, FREE_COUNT)
					put4(free_count-1)
					io:seek(current_db, addr - 4)
					put4(size) -- in case size was not updated by db_free()
				end if
				return addr
			end if
			size_ptr += 8
		end for
	end if
	-- no free block available - point to end of file
	io:seek(current_db, -1)
	put4(n+4)
	return io:where(current_db)
end function

procedure db_free(atom p)
-- Put a block of storage onto the free list in order of address.
-- Combine the new free block with any adjacent free blocks.
	atom psize, i, size, addr, free_list, free_list_space
	atom new_space, to_be_freed, prev_addr, prev_size
	integer free_count
	sequence remaining

	io:seek(current_db, p-4)
	psize = get4()

	io:seek(current_db, FREE_COUNT)
	free_count = get4()
	free_list = get4()
	io:seek(current_db, free_list - 4)
	free_list_space = get4()-4
	if free_list_space < 8 * (free_count+1) then
		-- need more space for free list
		new_space = floor(free_list_space + free_list_space / 2)
		to_be_freed = free_list
		free_list = db_allocate(new_space)
		io:seek(current_db, FREE_COUNT)
		free_count = get4() -- db_allocate may have changed it
		io:seek(current_db, FREE_LIST)
		put4(free_list)
		io:seek(current_db, to_be_freed)
		remaining = io:get_bytes(current_db, 8*free_count)
		io:seek(current_db, free_list)
		putn(remaining)
		putn(repeat(0, new_space-length(remaining)))
		io:seek(current_db, free_list)
	else
		new_space = 0
	end if

	i = 1
	prev_addr = 0
	prev_size = 0
	while i <= free_count do
		addr = get4()
		size = get4()
		if p < addr then
			exit
		end if
		prev_addr = addr
		prev_size = size
		i += 1
	end while

	if i > 1 and prev_addr + prev_size = p then
		-- combine with previous block
		io:seek(current_db, free_list+(i-2)*8+4)
		if i < free_count and p + psize = addr then
			-- combine space for all 3, delete the following block
			put4(prev_size+psize+size) -- update size on free list (only)
			io:seek(current_db, free_list+i*8)
			remaining = io:get_bytes(current_db, (free_count-i)*8)
			io:seek(current_db, free_list+(i-1)*8)
			putn(remaining)
			free_count -= 1
			io:seek(current_db, FREE_COUNT)
			put4(free_count)
		else
			put4(prev_size+psize) -- increase previous size on free list (only)
		end if
	elsif i < free_count and p + psize = addr then
		-- combine with following block - only size on free list is updated
		io:seek(current_db, free_list+(i-1)*8)
		put4(p)
		put4(psize+size)
	else
		-- insert a new block, shift the others down
		io:seek(current_db, free_list+(i-1)*8)
		remaining = io:get_bytes(current_db, (free_count-i+1)*8)
		free_count += 1
		io:seek(current_db, FREE_COUNT)
		put4(free_count)
		io:seek(current_db, free_list+(i-1)*8)
		put4(p)
		put4(psize)
		putn(remaining)
	end if

	if new_space then
		db_free(to_be_freed) -- free the old space
	end if
end procedure

procedure save_keys()
	integer k
	if caching_option = 1 then
		if current_table_pos > 0 then
			k = eu:find({current_db, current_table_pos}, cache_index)
			if k != 0 then
				key_cache[k] = key_pointers
			else
				key_cache = append(key_cache, key_pointers)
				cache_index = append(cache_index, {current_db, current_table_pos})
			end if
		end if
	end if
end procedure

--****
-- === Managing Databases

--**
-- defines a symbolic name for a database and its default attributes.
--
-- Parameters:
--		# ##dbalias## : a sequence. This is the symbolic name that the database can
--                      be referred to by.
--		# ##path## : a sequence, the path to the file that will contain the database.
--      # ##dboptions##: a sequence. Contains the set of attributes for the database.
--                      The default is ##{}## meaning it will use the various EDS default values.
--
-- Returns:
--		An **integer**, status code, either ##DB_OK## if creation successful or anything else on an error.
--
-- Comments:
--
-- * This does not create or open a database. It only associates a symbolic name with
--   a database path. This name can then be used in the calls to ##db_create##, ##db_open##,
--   and ##db_select## instead of the physical database name.
-- * If the file in the path does not have an extention, ##".edb"## will be added automatically.
-- * The ##dboptions## can contain any of the options detailed below. These can be
-- given as a single string of the form ##"option=value, option=value, ..."## or as
-- as sequence containing option-value pairs, ##{ {option,value}, {option,value}, ... }##
-- //Note:// The options can be in any order.
-- * The options are~:
-- ** ##LOCK_METHOD## : an integer specifying which type of access can be granted to the database.
--                      This must be one of ##DB_LOCK_NO##, ##DB_LOCK_EXCLUSIVE##,
--                      ##DB_LOCK_SHARDED## or ##DB_LOCK_READ_ONLY##.
-- ** ##INIT_TABLES## : an integer giving the initial number of tables to
--                         reserve space for. The default is 5 and the minimum is 1.
-- ** ##INIT_FREE## : an integer giving the initial amount of free space pointers to
--                         reserve space for. The default is 5 and the minimum is 0.
-- * If a symbolic name has already been defined for a database, you can get it's 
--   full path and options by calling this function with ##dboptions## set to ##CONNECTION##.
--   The returned value is a sequence of two elements. The first is the full path name
--   and the second is a list of the option values. These options are indexed by
--   ##[CONNECT_LOCK]##, ##[CONNECT_TABLES]##, and ##[CONNECT_FREE]##.
-- * If a symbolic name has already been defined for a database, you remove the
--   symbolic name by calling this function with ##dboptions## set to ##DISCONNECT##.
--
-- Example 1:
-- <eucode>
-- db_connect("myDB", "/usr/data/myapp/customer.edb", {{LOCK_METHOD,DB_LOCK_NO},
--                                                             {INIT_TABLES,1}})
-- db_open("myDB")
-- </eucode>
--
-- Example 2:
-- <eucode>
-- db_connect("myDB", "/usr/data/myapp/customer.edb", 
--                           sprintf("init_tables=1,lock_method=%d",DB_LOCK_NO))
-- db_open("myDB")
-- </eucode>
--
-- Example 3:
-- <eucode>
-- db_connect("myDB", "/usr/data/myapp/customer.edb", 
--                           sprintf("init_tables=1,lock_method=%d",DB_LOCK_NO))
-- db_connect("myDB",,CONNECTION) --> {"/usr/data/myapp/customer.edb", {0,1,1}}
-- db_connect("myDB",,DISCONNECT) -- The name 'myDB' is removed from EDS.
-- </eucode>
--
-- See Also:
-- 		[[:db_create]], [[:db_open]], [[:db_select]]

public function db_connect(sequence dbalias, sequence path="", sequence dboptions = {})
	integer lPos
	sequence lOptions

	-- See if I know about this one already.	
	lPos = find(dbalias, Known_Aliases)
	if lPos then
		-- I do, so only disconnect and connection options are allowed.
		if equal(dboptions, DISCONNECT) or find(DISCONNECT, dboptions) then
			Known_Aliases = remove(Known_Aliases, lPos)
			Alias_Details = remove(Alias_Details, lPos)
			return DB_OK
		end if
		if equal(dboptions, CONNECTION) or find(CONNECTION, dboptions) then
			return Alias_Details[lPos]
		end if
		return DB_OPEN_FAIL
	else
		-- I don't so disallow disconnect and connection options.
		if equal(dboptions, DISCONNECT) or find(DISCONNECT, dboptions) or
		   equal(dboptions, CONNECTION) or find(CONNECTION, dboptions) then
			return DB_OPEN_FAIL
		end if
	end if

	-- A path is mandatory at this point.	
	if length(path) = 0 then
		return DB_OPEN_FAIL
	end if
	
	-- If the options are in a single string, convert it to a list of key-value pairs.
	if types:string(dboptions) then
		dboptions = text:keyvalues(dboptions)
		for i = 1 to length(dboptions) do
			if types:string(dboptions[i][2]) then
				dboptions[i][2] = convert:to_number(dboptions[i][2])
			end if
		end for
	end if
	
	-- Assume default options for now.
	lOptions = {DB_LOCK_NO, DEF_INIT_TABLES, DEF_INIT_TABLES}
	
	-- Extract the supplied values.
	for i = 1 to length(dboptions) do
		switch dboptions[i][1] do
			case LOCK_METHOD then
				lOptions[CONNECT_LOCK] = dboptions[i][2]
				
			case INIT_TABLES then
				lOptions[CONNECT_TABLES] = dboptions[i][2]
				
			case INIT_FREE then
				lOptions[CONNECT_FREE] = dboptions[i][2]
				
			case else				
				return DB_OPEN_FAIL
				
		end switch
	end for
	
	-- Do some validation on the supplied values.
	if lOptions[CONNECT_TABLES] < 1 then
		lOptions[CONNECT_TABLES] = DEF_INIT_TABLES
	end if
	
	lOptions[CONNECT_FREE] = math:min({lOptions[CONNECT_TABLES], MAX_INDEX})
	
	if lOptions[CONNECT_FREE] < 1 then
		lOptions[CONNECT_FREE] = math:min({DEF_INIT_TABLES, MAX_INDEX})
	end if
	
	-- Save the alias.
	Known_Aliases = append(Known_Aliases, dbalias)
	Alias_Details = append(Alias_Details, { filesys:canonical_path( filesys:defaultext(path, "edb") ) , lOptions})
	
	return DB_OK
	
end function


--**
-- creates a new database given a file path and a lock method.
--
-- Parameters:
--		# ##path## : a sequence, the path to the file that will contain the database.
--		# ##lock_method## : an integer specifying which type of access can be
--                         granted to the database. The value of ##lock_method##
--                         can be either ##DB_LOCK_NO## (no lock) or 
--                         ##DB_LOCK_EXCLUSIVE## (exclusive lock).
--      # ##init_tables## : an integer giving the initial number of tables to
--                         reserve space for. The default is ##5## and the minimum is ##1## .
--      # ##init_free## : an integer giving the initial amount of free space pointers to
--                         reserve space for. The default is ##5## and the minimum is ##0## .
--
-- Returns:
--		An **integer**, status code, either ##DB_OK## if creation successful or anything else on an error.
--
-- Comments:
--
-- On success, the newly created database
-- becomes the **current database** to which
-- all other database operations will apply.
--
-- If the file in the path does not have an extention, ##.edb## will be added automatically.
--
-- A version number is stored in the database file so future
-- versions of the database software can recognize the format, and
-- possibly read it and deal with it in some way.
--
-- If the database already exists, it will not be overwritten.
-- ##db_create## will return ##DB_EXISTS_ALREADY##.
--
-- Example 1:
-- <eucode>
-- if db_create("mydata", DB_LOCK_NO) != DB_OK then
--     puts(2, "Couldn't create the database!\n")
--     abort(1)
-- end if
-- </eucode>
--
-- See Also:
-- 		[[:db_open]], [[:db_select]]

public function db_create(sequence path, integer lock_method = DB_LOCK_NO, integer init_tables = DEF_INIT_TABLES, integer init_free = DEF_INIT_FREE )
	integer db

	db = find(path, Known_Aliases)
	if db then
		-- Fetch parameters from connection details.
		path = Alias_Details[db][1]
		lock_method = Alias_Details[db][2][CONNECT_LOCK]
		init_tables = Alias_Details[db][2][CONNECT_TABLES]
		init_free = Alias_Details[db][2][CONNECT_FREE]
	else		
		path = filesys:canonical_path( defaultext(path, "edb") )
	
		if init_tables < 1 then
			init_tables = 1
		end if
		
		if init_free < 0 then
			init_free = 0
		end if
	end if


	-- see if it already exists
	db = open(path, "rb")
	if db != -1 then
		-- don't destroy an existing db - let user delete himself
		close(db)
		return DB_EXISTS_ALREADY
	end if

	-- file must exist before "ub" can be used
	db = open(path, "wb")
	if db = -1 then
		return DB_OPEN_FAIL
	end if
	close(db)

	-- get read and write access, "ub"
	db = open(path, "ub")
	if db = -1 then
		return DB_OPEN_FAIL
	end if
	if lock_method = DB_LOCK_SHARED then
		-- shared lock doesn't make sense for create
		lock_method = DB_LOCK_NO
	end if
	if lock_method = DB_LOCK_EXCLUSIVE then
		if not io:lock_file(db, io:LOCK_EXCLUSIVE, {}) then
			return DB_LOCK_FAIL
		end if
	end if
	save_keys()
	current_db = db
	current_lock = lock_method
	current_table_pos = -1
	current_table_name = ""
	db_names = append(db_names, path)
	db_lock_methods = append(db_lock_methods, lock_method)
	db_file_nums = append(db_file_nums, db)

	-- initialize the header
	put1(DB_MAGIC) -- so we know what type of file it is
	put1(DB_MAJOR) -- major version
	put1(DB_MINOR) -- minor version
	-- 3:
	put4(19)  -- pointer to tables
	-- 7:
	put4(0)   -- number of free blocks
	-- 11:
	put4(23 + init_tables * SIZEOF_TABLE_HEADER + 4)   -- pointer to free list
	-- 15: initial table block:
	put4( 8 + init_tables * SIZEOF_TABLE_HEADER)  -- allocated size
	-- 19:
	put4(0)   -- number of tables that currently exist
	-- 23: initial space for tables
	putn(repeat(0, init_tables * SIZEOF_TABLE_HEADER))
	-- initial space for free list
	put4(4+init_free*8)   -- allocated size
	putn(repeat(0, init_free * 8))
	return DB_OK
end function

--**
-- opens an existing Euphoria database.
--
-- Parameters:
--		# ##path## : a sequence, the path to the file containing the database
--		# ##lock_method## : an integer specifying which sort of access can
--           be granted to the database. The types of lock that you can use are:
--      ## ##DB_LOCK_NO## : (no lock) ~-- The default
--      ## ##DB_LOCK_SHARED## : (shared lock for read-only access) 
--      ## ##DB_LOCK_EXCLUSIVE## : (for read and write access).
--
-- Returns:
--		An **integer**, status code, either ##DB_OK## if creation successful or anything else on an error.
--
-- The return codes are~:
--
-- <eucode>
-- public constant
--     DB_OK = 0          -- success
--     DB_OPEN_FAIL = -1  -- could not open the file
--     DB_LOCK_FAIL = -3  -- could not lock the file in the
--                        -- manner requested
-- </eucode>
--
-- Comments:
--   ##DB_LOCK_SHARED## is only supported on //Unix// platforms. It allows you to read the database, 
--   but not write anything to it. If you request ##DB_LOCK_SHARED## on //Windows// it will be 
--   treated as if you had asked for ##DB_LOCK_EXCLUSIVE##.
--
--   If the lock fails, your program should wait a few seconds and try again.
--   Another process might be currently accessing the database.
--
-- Example 1:
-- <eucode>
-- tries = 0
-- while 1 do
--     err = db_open("mydata", DB_LOCK_SHARED)
--     if err = DB_OK then
--         exit
--     elsif err = DB_LOCK_FAIL then
--         tries += 1
--         if tries > 10 then
--             puts(2, "too many tries, giving up\n")
--             abort(1)
--         else
--             sleep(5)
--         end if
--     else
--         puts(2, "Couldn't open the database!\n")
--         abort(1)
--     end if
-- end while
-- </eucode>
--
-- See Also:
--   [[:db_create]], [[:db_select]]

public function db_open(sequence path, integer lock_method = DB_LOCK_NO)
	integer db, magic

	db = find(path, Known_Aliases)
	if db then
		-- Fetch parameters from connection details.
		path = Alias_Details[db][1]
		lock_method = Alias_Details[db][2][CONNECT_LOCK]
	else		
		path = filesys:canonical_path( filesys:defaultext(path, "edb") )
	end if

	if lock_method = DB_LOCK_NO or
	   lock_method = DB_LOCK_EXCLUSIVE then
		-- get read and write access, "ub"
		db = open(path, "ub")
	else
		-- DB_LOCK_SHARED, DB_LOCK_READ_ONLY
		db = open(path, "rb")
	end if

ifdef WINDOWS then
	if lock_method = DB_LOCK_SHARED then
		lock_method = DB_LOCK_EXCLUSIVE
	end if

end ifdef

	if db = -1 then
		return DB_OPEN_FAIL
	end if
	if lock_method = DB_LOCK_EXCLUSIVE then
		if not io:lock_file(db, io:LOCK_EXCLUSIVE, {}) then
			close(db)
			return DB_LOCK_FAIL
		end if
	elsif lock_method = DB_LOCK_SHARED then
		if not io:lock_file(db, io:LOCK_SHARED, {}) then
			close(db)
			return DB_LOCK_FAIL
		end if
	end if
	magic = getc(db)
	if magic != DB_MAGIC then
		close(db)
		return DB_OPEN_FAIL
	end if
	save_keys()
	current_db = db 
	current_table_pos = -1
	current_table_name = ""
	current_lock = lock_method
	db_names = append(db_names, path)
	db_lock_methods = append(db_lock_methods, lock_method)
	db_file_nums = append(db_file_nums, db)
	return DB_OK
end function

--**
-- chooses a new, already open, database to be the current database.
--
-- Parameters:
--	# ##path## : a sequence, the path to the database to be the new current database.
--  # ##lock_method## : an integer. Optional locking method. 
--
-- Returns:
-- 		An **integer**, ##DB_OK## on success or an error code.
--
-- Comments:
-- * Subsequent database operations will apply to this database. ##path## is the
-- path of the database file as it was originally opened with ##db_open##
-- or ##db_create##.
-- * When you create (##db_create##) or open (##db_open##) a database, it automatically
-- becomes the current database. Use ##db_select## when you want to switch back
-- and forth between open databases, perhaps to copy records from one to the
-- other. After selecting a new database, you should select a table within
-- that database using ##db_select_table##.
-- * If the ##lock_method## is omitted and the database has not already been opened,
-- this function will fail. However, if ##lock_method## is a valid lock type for
-- [[:db_open]]  and the database is not open yet, this function will attempt to
-- open it. It may still fail if the database cannot be opened.
--
-- Example 1:
-- <eucode>
-- if db_select("employees") != DB_OK then
--     puts(2, "Could not select employees database\n")
-- end if
-- </eucode>
--
-- Example 2:
-- <eucode>
-- if db_select("customer", DB_LOCK_SHARED) != DB_OK then
--     puts(2, "Could not open or select Customer database\n")
-- end if
-- </eucode>
--
-- See Also:
--   [[:db_open]], [[:db_select]]

public function db_select(sequence path, integer lock_method = -1)
	integer index

	index = find(path, Known_Aliases)
	if index then
		-- Fetch parameters from connection details.
		path = Alias_Details[index][1]
		lock_method = Alias_Details[index][2][CONNECT_LOCK]
	else		
		path = filesys:canonical_path( filesys:defaultext(path, "edb") )
	end if

	index = eu:find(path, db_names)
	if index = 0 then
		if lock_method = -1 then
			return DB_OPEN_FAIL
		end if
		index = db_open(path, lock_method)
		if index != DB_OK then
			return index
		end if
		index = eu:find(path, db_names)
	end if
	save_keys()
	current_db = db_file_nums[index]
	current_lock = db_lock_methods[index]
	current_table_pos = -1
	current_table_name = ""
	key_pointers = {}
	return DB_OK
end function

--**
-- unlocks and closes the current database.
--
-- Comments:
-- Call this procedure when you are finished with the current database. 
-- Any lock will be removed, allowing other processes to access the 
-- database file. The current database becomes undefined.

public procedure db_close()
-- close the current database
	integer index

	if current_db = -1 then
		return
	end if
	-- unlock the database
	if current_lock then
		io:unlock_file(current_db, {})
	end if
	close(current_db)
	-- delete info for current_db
	index = eu:find(current_db, db_file_nums)
	db_names = remove(db_names, index)
	db_file_nums = remove(db_file_nums, index)
	db_lock_methods = remove(db_lock_methods, index)
	-- delete each cache entry for this database
	for i = length(cache_index) to 1 by -1 do
		if cache_index[i][1] = current_db then
			cache_index = remove(cache_index, i)
			key_cache = remove(key_cache, i)
		end if
	end for
	current_table_pos = -1
	current_table_name = ""	
	current_db = -1
	key_pointers = {}
end procedure

function table_find(sequence name)
-- find a table, given its name
-- return table pointer
	atom tables
	atom nt
	atom t_header, name_ptr

	io:seek(current_db, TABLE_HEADERS)
	if length(vLastErrors) > 0 then return -1 end if
	tables = get4()
	io:seek(current_db, tables)
	nt = get4()
	t_header = tables+4
	for i = 1 to nt do
		io:seek(current_db, t_header)
		name_ptr = get4()
		io:seek(current_db, name_ptr)
		if equal_string(name) > 0 then
			-- found it
			return t_header
		end if
		t_header += SIZEOF_TABLE_HEADER
	end for
	return -1
end function

--****
-- === Managing Tables

--**
-- Parameters:
-- 		# ##name## : a sequence which defines the name of the new current table.
--
-- Description:
-- 		On success, the table with name given by name becomes the current table.
--
-- Returns:
-- 		An **integer**, either ##DB_OK## on success or ##DB_OPEN_FAIL## otherwise.
--
-- Errors:
-- 		An error occurs if the current database is not defined.
--
-- Comments:
-- 		All record-level database operations apply automatically to the current table.
--
-- Example 1:
-- <eucode>
-- if db_select_table("salary") != DB_OK then
--     puts(2, "Couldn't find salary table!\n")
--     abort(1)
-- end if
-- </eucode>
--
-- See Also:
--   [[:db_table_list]]

public function db_select_table(sequence name)
-- let table with the given name be the current table
	atom table, nkeys, index
	atom block_ptr, block_size
	integer blocks, k

	if equal(current_table_name, name) then
		return DB_OK
	end if
	table = table_find(name)
	if table = -1 then
		return DB_OPEN_FAIL
	end if

	save_keys()

	current_table_pos = table
	current_table_name = name

	k = 0
	if caching_option = 1 then
		k = eu:find({current_db, current_table_pos}, cache_index)
		if k != 0 then
			key_pointers = key_cache[k]
		end if
	end if
	if k = 0 then
		-- read in all the key pointers for the current table
		io:seek(current_db, table+4)
		nkeys = get4()
		blocks = get4()
		index = get4()
		key_pointers = repeat(0, nkeys)
		k = 1
		for b = 0 to blocks-1 do
			io:seek(current_db, index)
			block_size = get4()
			block_ptr = get4()
			io:seek(current_db, block_ptr)
			for j = 1 to block_size do
				key_pointers[k] = get4()
				k += 1
			end for
			index += 8
		end for
	end if
	return DB_OK
end function

--**
-- gets the name of currently selected table.
--
-- Parameters:
--		# None.
--
-- Returns:
--   A **sequence**, the name of the current table. An empty string means
--   that no table is currently selected.
--
-- Example 1:
-- <eucode>
-- s = db_current_table()
-- </eucode>
--
-- See Also:
--   [[:db_select_table]], [[:db_table_list]]

public function db_current_table()
	return current_table_name
end function

--**
-- creates a new table within the current database.
--
-- Parameters:
--		# ##name## : a sequence, the name of the new table.
--      # ##init_records## : The number of records to initially reserve space for.
--          (Default is 50)
--
-- Returns:
-- 		An **integer**, either ##DB_OK## on success or ##DB_EXISTS_ALREADY## on failure.
--
-- Errors:
-- 		An error occurs if the current database is not defined.
--
-- Comments:
-- 		* The supplied name must not exist already on the current database.
-- 		* The table that you create will initially have zero records. However
--        it will reserve some space for a number of records, which will
--        improve the initial data load for the table.
--      * It becomes the current table.
--
-- Example 1:
-- <eucode>
-- if db_create_table("my_new_table") != DB_OK then
--     puts(2, "Could not create my_new_table!\n")
-- end if
-- </eucode>
--
-- See Also:
--   [[:db_select_table]], [[:db_table_list]]

public function db_create_table(sequence name, integer init_records = DEF_INIT_RECORDS)
	atom name_ptr, nt, tables, newtables, table, records_ptr
	atom size, newsize, index_ptr
	sequence remaining
	integer init_index

	if not cstring(name) then
		return DB_BAD_NAME
	end if
	
	table = table_find(name)
	if table != -1 then
		return DB_EXISTS_ALREADY
	end if

	if init_records < MAX_INDEX then
		init_records = MAX_INDEX
	end if
	init_index = MAX_INDEX
	
	-- increment number of tables
	io:seek(current_db, TABLE_HEADERS)
	tables = get4()
	io:seek(current_db, tables-4)
	size = get4()
	nt = get4()+1
	if nt*SIZEOF_TABLE_HEADER + 8 > size then
		-- enlarge the block of table headers
		newsize = floor(size + size / 2)
		newtables = db_allocate(newsize)
		put4(nt)
		-- copy all table headers to the new block
		io:seek(current_db, tables+4)
		remaining = io:get_bytes(current_db, (nt-1)*SIZEOF_TABLE_HEADER)
		io:seek(current_db, newtables+4)
		putn(remaining)
		-- fill the rest
		putn(repeat(0, newsize - 4 - (nt-1)*SIZEOF_TABLE_HEADER))
		db_free(tables)
		io:seek(current_db, TABLE_HEADERS)
		put4(newtables)
		tables = newtables
	else
		io:seek(current_db, tables)
		put4(nt)
	end if

	-- allocate initial space for 1st block of record pointers
	records_ptr = db_allocate(init_records * 4)
	putn(repeat(0, init_records * 4))

	-- allocate initial space for the index
	index_ptr = db_allocate(init_index * 8)
	put4(0)  -- 0 records
	put4(records_ptr) -- point to 1st block
	putn(repeat(0, (init_index-1) * 8))

	-- store new table
	name_ptr = db_allocate(length(name)+1)
	putn(name & 0)

	io:seek(current_db, tables+4+(nt-1)*SIZEOF_TABLE_HEADER)
	put4(name_ptr)
	put4(0)  -- start with 0 records total
	put4(1)  -- start with 1 block of records in index
	put4(index_ptr)
	if db_select_table(name) then
	end if
	return DB_OK
end function

--**
-- deletes a table in the current database.
--
-- Parameters:
-- 		# ##name## : a sequence, the name of the table to delete.
--
-- Errors:
-- 		An error occurs if the current database is not defined.
--
-- Comments:
-- 		If there is no table with the name given by name, then nothing happens.
--		On success, all records are deleted and all space used by the table
--      is freed up. If the table was the current table, the current table
--      becomes undefined.
--
-- See Also:
--		[[:db_table_list]], [[:db_select_table]], [[:db_clear_table]]

public procedure db_delete_table(sequence name)
-- delete an existing table and all of its records
	atom table, tables, nt, nrecs, records_ptr, blocks
	atom p, data_ptr, index
	sequence remaining
	integer k

	table = table_find(name)
	if table = -1 then
		return
	end if

	-- free the table name
	io:seek(current_db, table)
	db_free(get4())

	io:seek(current_db, table+4)
	nrecs = get4()
	blocks = get4()
	index = get4()

	-- free all the records
	for b = 0 to blocks-1 do
		io:seek(current_db, index+b*8)
		nrecs = get4()
		records_ptr = get4()
		for r = 0 to nrecs-1 do
			io:seek(current_db, records_ptr + r*4)
			p = get4()
			io:seek(current_db, p)
			data_ptr = get4()
			db_free(data_ptr)
			db_free(p)
		end for
		-- free the block
		db_free(records_ptr)
	end for

	-- free the index
	db_free(index)

	-- get tables & number of tables
	io:seek(current_db, TABLE_HEADERS)
	tables = get4()
	io:seek(current_db, tables)
	nt = get4()

	-- shift later tables up
	io:seek(current_db, table+SIZEOF_TABLE_HEADER)
	remaining = io:get_bytes(current_db,
						  tables+4+nt*SIZEOF_TABLE_HEADER-
						  (table+SIZEOF_TABLE_HEADER))
	io:seek(current_db, table)
	putn(remaining)

	-- decrement number of tables
	nt -= 1
	io:seek(current_db, tables)
	put4(nt)

	k = eu:find({current_db, current_table_pos}, cache_index)
	if k != 0 then
		cache_index = remove(cache_index, k)
		key_cache = remove(key_cache, k)
	end if
	if table = current_table_pos then
		current_table_pos = -1
		current_table_name = ""
	elsif table < current_table_pos then
		current_table_pos -= SIZEOF_TABLE_HEADER
		io:seek(current_db, current_table_pos)
		data_ptr = get4()
		io:seek(current_db, data_ptr)
		current_table_name = get_string()
	end if
end procedure

--**
-- clears a table of all its records, in the current database.
--
-- Parameters:
-- 		# ##name## : a sequence, the name of the table to clear.
--
-- Errors:
-- 		An error occurs if the current database is not defined.
--
-- Comments:
-- 		If there is no table with the name given by name, then nothing happens.
--		On success, all records are deleted and all space used by the table
--      is freed up. If this is the current table, after this operation
--      it will still be the current table.
--
-- See Also:
--		[[:db_table_list]], [[:db_select_table]], [[:db_delete_table]]

public procedure db_clear_table(sequence name, integer init_records = DEF_INIT_RECORDS)
-- delete all of records in the table
	atom table, nrecs, records_ptr, blocks
	atom p, data_ptr, index_ptr
	integer k
	integer init_index

	table = table_find(name)
	if table = -1 then
		return
	end if

	if init_records < MAX_INDEX then
		init_records = MAX_INDEX
	end if
	init_index = MAX_INDEX

	io:seek(current_db, table + 4)
	nrecs = get4()
	blocks = get4()
	index_ptr = get4()

	-- free all the records
	for b = 0 to blocks-1 do
		io:seek(current_db, index_ptr + b*8)
		nrecs = get4()
		records_ptr = get4()
		for r = 0 to nrecs-1 do
			io:seek(current_db, records_ptr + r*4)
			p = get4()
			io:seek(current_db, p)
			data_ptr = get4()
			db_free(data_ptr)
			db_free(p)
		end for
		-- free the block
		db_free(records_ptr)
	end for

	-- free the index
	db_free(index_ptr)

	-- allocate initial space for 1st block of record pointers
	data_ptr = db_allocate(init_records * 4)
	putn(repeat(0, init_records * 4))

	-- allocate initial space for the index block
	index_ptr = db_allocate(init_index * 8)
	put4(0)  -- 0 records
	put4(data_ptr) -- point to 1st block
	putn(repeat(0, (init_index-1) * 8))

	io:seek(current_db, table + 4)
	put4(0)  -- start with 0 records total
	put4(1)  -- start with 1 block of records in index
	put4(index_ptr)

	-- Clear cache and RAM pointers
	k = eu:find({current_db, current_table_pos}, cache_index)
	if k != 0 then
		cache_index = remove(cache_index, k)
		key_cache = remove(key_cache, k)
	end if
	if table = current_table_pos then
		key_pointers = {}
	end if

end procedure

--**
-- renames a table in the current database.
--
-- Parameters:
-- 		# ##name## : a sequence, the name of the table to rename
-- 		# ##new_name## : a sequence, the new name for the table
--
-- Errors:
-- 		* An error occurs if the current database is not defined.
-- 		* If ##name## does not exist on the current database, 
--        or if ##new_name## does exist on the current database,
--        an error will occur.
--
-- Comments:
-- 		The table to be renamed can be the current table, or some other table
-- in the current database.
--
-- See Also:
--		[[:db_table_list]]

public procedure db_rename_table(sequence name, sequence new_name)
-- rename an existing table - written by Jordah Ferguson
	atom table, table_ptr

	table = table_find(name)
	if table = -1 then
		fatal(NO_TABLE, "source table doesn't exist", "db_rename_table", {name, new_name})
		return
	end if

	if table_find(new_name) != -1 then
		fatal(DUP_TABLE, "target table name already exists", "db_rename_table", {name, new_name})
		return
	end if

	io:seek(current_db, table)
	db_free(get4())

	table_ptr = db_allocate(length(new_name)+1)
	putn(new_name & 0)

	io:seek(current_db, table)
	put4(table_ptr)
	if equal(current_table_name, name) then
		current_table_name = new_name
	end if
end procedure

--**
-- lists all tables in the current database.
--
-- Returns:
--	A **sequence**, of all the table names in the current database. Each element of this
-- sequence is a sequence, the name of a table.
--
-- Errors:
-- An error occurs if the current database is undefined.
--
-- Example 1:
-- <eucode>
-- sequence names = db_table_list()
-- for i = 1 to length(names) do
--     puts(1, names[i] & '\n')
-- end for
-- </eucode>
--
-- See Also:
-- 		[[:db_select_table]], [[:db_create_table]]

public function db_table_list()
	sequence table_names
	atom tables, nt, name

	io:seek(current_db, TABLE_HEADERS)
	if length(vLastErrors) > 0 then return {} end if
	tables = get4()
	io:seek(current_db, tables)
	nt = get4()
	table_names = repeat(0, nt)
	for i = 0 to nt-1 do
		io:seek(current_db, tables + 4 + i*SIZEOF_TABLE_HEADER)
		name = get4()
		io:seek(current_db, name)
		table_names[i+1] = get_string()
	end for
	return table_names
end function

function key_value(atom ptr)
-- return the value of a key,
-- given a pointer to the key in the database
	io:seek(current_db, ptr+4) -- skip ptr to data
	return decompress(0)
end function

--****
-- === Managing Records

--**
-- finds the record in the current table with supplied key.
--
-- Parameters:
-- 		# ##key## : the identifier of the record to be looked up.
--      # ##table_name## : optional name of table to find key in
--
-- Returns:
--		An **integer**, either greater or less than zero:
-- 		* If above zero, the record identified by ##key## was found on the
--        current table, and the returned integer is its record number.
--		* If less than zero, the record was not found. The returned integer
--        is the opposite of what the record number would have been, had
--        the record been found.
--      * If equal to zero, an error occured.
--
-- Errors:
-- 		If the current table is not defined, it returns ##0## .
--
-- Comments:
--
-- 		A fast binary search is used to find the key in the current table.
-- The number of comparisons is proportional to the log of the number of
-- records in the table. The key is unique~--a table is more like a dictionary than like a spreadsheet.
--
--		You can select a range of records by searching
-- for the first and last key values in the range. If those key values don't
-- exist, you'll at least get a negative value showing ##io:where## they would be,
-- if they existed. 
--
-- For example, suppose you want to know which records have keys
-- greater than ##"GGG"## and less than ##"MMM"##. If ##-5## is returned for key ##"GGG"##,
-- it means a record with ##"GGG"## as a key would be inserted as record number ##5## .
-- ##-27## for ##"MMM"## means a record with ##"MMM"## as its key would be inserted as record
-- number ##27##. This quickly tells you that all records, ##>= 5## and ##< 27## qualify.
--
-- Example 1:
-- <eucode>
-- rec_num = db_find_key("Millennium")
-- if rec_num > 0 then
--     ? db_record_key(rec_num)
--     ? db_record_data(rec_num)
-- else
--     puts(2, "Not found, but if you insert it,\n")
--
--     printf(2, "it will be #%d\n", -rec_num)
-- end if
-- </eucode>
--
-- See Also:
-- 		[[:db_insert]], [[:db_replace_data]], [[:db_delete_record]], [[:db_get_recid]]

public function db_find_key(object key, object table_name=current_table_name)
	integer lo, hi, mid, c  -- works up to 1.07 billion records

	if not equal(table_name, current_table_name) then
		if db_select_table(table_name) != DB_OK then
			fatal(NO_TABLE, "invalid table name given", "db_find_key", {key, table_name})
			return 0
		end if
	end if

	if current_table_pos = -1 then
		fatal(NO_TABLE, "no table selected", "db_find_key", {key, table_name})
		return 0
	end if

	lo = 1
	hi = length(key_pointers)
	mid = 1
	c = 0
	while lo <= hi do
		mid = floor((lo + hi) / 2)
		c = eu:compare(key, key_value(key_pointers[mid]))
		if c < 0 then
			hi = mid - 1
		elsif c > 0 then
			lo = mid + 1
		else
			return mid
		end if
	end while
	-- return the position it would have, if inserted now
	if c > 0 then
		mid += 1
	end if
	return -mid
end function

--**
-- inserts a new record into the current table.
--
-- Parameters:
--		# ##key## : an object, the record key, which uniquely identifies it inside the current table
--		# ##data## : an object, associated to ##key##.
--      # ##table_name## : optional table name to insert record into
--
-- Returns:
-- 		An **integer**, either ##DB_OK## on success or an error code on failure.
--
-- Comments:
-- Within a table, all keys must be unique. ##db_insert## will fail with
-- ##DB_EXISTS_ALREADY## if a record already exists on current table with the same key value.
--
-- Both key and data can be any Euphoria data objects, atoms or sequences.
--
-- Example 1:
-- <eucode>
-- if db_insert("Smith", {"Peter", 100, 34.5}) != DB_OK then
--     puts(2, "insert failed!\n")
-- end if
-- </eucode>
--
-- See Also:
--   [[:db_replace_data]], [[:db_delete_record]]
--

public function db_insert(object key, object data, object table_name=current_table_name)
	sequence key_string, data_string, last_part, remaining
	atom key_ptr, data_ptr, records_ptr, nrecs, current_block, size, new_size
	atom key_location, new_block, index_ptr, new_index_ptr, total_recs
	integer r, blocks, new_recs, n

	key_location = db_find_key(key, table_name) -- Let it set the current table if necessary
	
	if key_location > 0 then
		-- key is already in the table
		return DB_EXISTS_ALREADY
	end if
	key_location = -key_location

	data_string = compress(data)
	key_string  = compress(key)

	data_ptr = db_allocate(length(data_string))
	putn(data_string)

	key_ptr = db_allocate(4+length(key_string))
	put4(data_ptr)
	putn(key_string)

	-- increment number of records in whole table

	io:seek(current_db, current_table_pos+4)
	total_recs = get4()+1
	blocks = get4()
	io:seek(current_db, current_table_pos+4)
	put4(total_recs)

	n = length(key_pointers)
	if key_location >= floor(n/2) then
		-- add space at end
		key_pointers = append(key_pointers, 0)
		-- shift up
		key_pointers[key_location+1..n+1] = key_pointers[key_location..n]
	else
		-- add space at beginning
		key_pointers = prepend(key_pointers, 0)
		-- shift down
		key_pointers[1..key_location-1] = key_pointers[2..key_location]
	end if
	key_pointers[key_location] = key_ptr

	io:seek(current_db, current_table_pos+12) -- get after put - seek is necessary
	index_ptr = get4()

	io:seek(current_db, index_ptr)
	r = 0
	while TRUE do
		nrecs = get4()
		records_ptr = get4()
		r += nrecs
		if r + 1 >= key_location then
			exit
		end if
	end while

	current_block = io:where(current_db)-8

	key_location -= (r-nrecs)

	io:seek(current_db, records_ptr+4*(key_location-1))
	for i = key_location to nrecs+1 do
		put4(key_pointers[i+r-nrecs])
	end for

	-- increment number of records in this block
	io:seek(current_db, current_block)
	nrecs += 1
	put4(nrecs)

	-- check allocated size for this block
	io:seek(current_db, records_ptr - 4)
	size = get4() - 4
	if nrecs*4 > size-4 then
		-- This block is now full - split it into 2 pieces.
		-- Magic formula: On average we'd like to have N blocks with
		-- N records in each block and space for 2N records,
		-- with N-squared total records in the table. We should also
		-- avoid allocating extremely small blocks, and we should
		-- anticipate some future growth of the database.

		new_size = 8 * (20 + floor(sqrt(1.5 * total_recs)))

		new_recs = floor(new_size/8)
		if new_recs > floor(nrecs/2) then
			new_recs = floor(nrecs/2)
		end if

		-- copy last portion to the new block
		io:seek(current_db, records_ptr + (nrecs-new_recs)*4)
		last_part = io:get_bytes(current_db, new_recs*4)
		new_block = db_allocate(new_size)
		putn(last_part)
		-- fill the rest
		putn(repeat(0, new_size-length(last_part)))

		-- change nrecs for this block in index
		io:seek(current_db, current_block)
		put4(nrecs-new_recs)

		-- insert new block into index after current block
		io:seek(current_db, current_block+8)
		remaining = io:get_bytes(current_db, index_ptr+blocks*8-(current_block+8))
		io:seek(current_db, current_block+8)
		put4(new_recs)
		put4(new_block)
		putn(remaining)
		io:seek(current_db, current_table_pos+8)
		blocks += 1
		put4(blocks)
		-- enlarge index if full
		io:seek(current_db, index_ptr-4)
		size = get4() - 4
		if blocks*8 > size-8 then
			-- grow the index
			remaining = io:get_bytes(current_db, blocks*8)
			new_size = floor(size + size/2)
			new_index_ptr = db_allocate(new_size)
			putn(remaining)
			putn(repeat(0, new_size-blocks*8))
			db_free(index_ptr)
			io:seek(current_db, current_table_pos+12)
			put4(new_index_ptr)
		end if
	end if
	return DB_OK
end function

--**
-- deletes record number ##key_location## from the current table.
--
-- Parameters:
-- 		# ##key_location## : a positive integer, designating the record to delete.
--      # ##table_name## : optional table name to delete record from.
--
-- Errors:
-- 	If the current table is not defined, or ##key_location## is not a 
-- valid record index, an error will occur. Valid record indexes are 
-- between 1 and the number of records in the table.
--
-- Example 1:
-- <eucode>
-- db_delete_record(55)
-- </eucode>
--
-- See Also:
-- 		[[:db_find_key]]

public procedure db_delete_record(integer key_location, object table_name=current_table_name)
	atom key_ptr, nrecs, records_ptr, data_ptr, index_ptr, current_block
	integer r, blocks, n
	sequence remaining

	if not equal(table_name, current_table_name) then
		if db_select_table(table_name) != DB_OK then
			fatal(NO_TABLE, "invalid table name given", "db_delete_record", {key_location, table_name})
			return
		end if
	end if

	if current_table_pos = -1 then
		fatal(NO_TABLE, "no table selected", "db_delete_record", {key_location, table_name})
		return
	end if
	if key_location < 1 or key_location > length(key_pointers) then
		fatal(BAD_RECNO, "bad record number", "db_delete_record", {key_location, table_name})
		return
	end if
	key_ptr = key_pointers[key_location]
	io:seek(current_db, key_ptr)
	if length(vLastErrors) > 0 then return end if
	data_ptr = get4()
	db_free(key_ptr)
	db_free(data_ptr)

	n = length(key_pointers)
	if key_location >= floor(n/2) then
		-- shift down
		key_pointers[key_location..n-1] = key_pointers[key_location+1..n]
		key_pointers = key_pointers[1..n-1]
	else
		-- shift up
		key_pointers[2..key_location] = key_pointers[1..key_location-1]
		key_pointers = key_pointers[2..n]
	end if

	-- decrement number of records in whole table
	io:seek(current_db, current_table_pos+4)
	nrecs = get4()-1
	blocks = get4()
	io:seek(current_db, current_table_pos+4)
	put4(nrecs)

	io:seek(current_db, current_table_pos+12)
	index_ptr = get4()

	io:seek(current_db, index_ptr)
	r = 0
	while TRUE do
		nrecs = get4()
		records_ptr = get4()
		r += nrecs
		if r >= key_location then
			exit
		end if
	end while

	r -= nrecs
	current_block = io:where(current_db)-8
	nrecs -= 1

	if nrecs = 0 and blocks > 1 then
		-- delete this block from the index (unless it's the very last block)
		remaining = io:get_bytes(current_db, index_ptr+blocks*8-(current_block+8))
		io:seek(current_db, current_block)
		putn(remaining)
		io:seek(current_db, current_table_pos+8)
		put4(blocks-1)
		db_free(records_ptr)
	else
		key_location -= r
		-- decrement the record count in the index
		io:seek(current_db, current_block)
		put4(nrecs)
		-- delete one record
		io:seek(current_db, records_ptr+4*(key_location-1))
		for i = key_location to nrecs do
			put4(key_pointers[i+r])
		end for
	end if
end procedure

--**
-- replaces, the current table, the data portion of a record  with new data.
--
-- Parameters:
-- 		# ##key_location##: an integer, the index of the record the data is to be altered.
-- 		# ##data##: an object , the new value associated to the key of the record.
--      # ##table_name##: optional table name of record to replace data in.
--
-- Comments:
--##key_location## must be from ##1## to the number of records in the
-- current table.
-- ##data## is an Euphoria object of any kind, atom or sequence.
--
-- Example 1:
-- <eucode>
-- db_replace_data(67, {"Peter", 150, 34.5})
-- </eucode>
--
-- See Also:
-- 		[[:db_find_key]]

public procedure db_replace_data(integer key_location, object data, object table_name=current_table_name)
	if not equal(table_name, current_table_name) then
		if db_select_table(table_name) != DB_OK then
			fatal(NO_TABLE, "invalid table name given", "db_replace_data", {key_location, data, table_name})
			return
		end if
	end if

	if current_table_pos = -1 then
		fatal(NO_TABLE, "no table selected", "db_replace_data", {key_location, data, table_name})
		return
	end if
	if key_location < 1 or key_location > length(key_pointers) then
		fatal(BAD_RECNO, "bad record number", "db_replace_data", {key_location, data, table_name})
		return
	end if
	db_replace_recid(key_pointers[key_location], data)
end procedure

--**
-- gets the size (number of records) of the default table.
--
-- Parameters:
--     # ##table_name## : optional table name to get the size of.
--
-- Returns
--		An **integer**, the current number of records in the current table.
--      If a value less than zero is returned, it means that an error occured.
--
-- Errors:
-- 		If the current table is undefined, an error will occur.
--
-- Example 1:
-- <eucode>
-- -- look at all records in the current table
-- for i = 1 to db_table_size() do
--     if db_record_key(i) = 0 then
--     	puts(1, "0 key found\n")
--     	exit
--     end if
-- end for
-- </eucode>
--
-- See Also:
-- 		[[:db_replace_data]]

public function db_table_size(object table_name=current_table_name)
	if not equal(table_name, current_table_name) then
		if db_select_table(table_name) != DB_OK then
			fatal(NO_TABLE, "invalid table name given", "db_table_size", {table_name})
			return -1
		end if
	end if

	if current_table_pos = -1 then
		fatal(NO_TABLE, "no table selected", "db_table_size", {table_name})
		return -1
	end if
	return length(key_pointers)
end function

--**
-- returns the data in a record queried by position.
--
-- Parameters:
-- 		# ##key_location## : the index of the record the data of which is being fetched.
--      # ##table_name## : optional table name to get record data from.
--
-- Returns:
--		An **object**, the data portion of requested record.
--
-- Note:
--  This function calls ##fatal## and returns a value of ##-1## if an error prevented
--      the correct data being returned. 
--
-- Comments:
-- Each record in a Euphoria database consists of a key portion and a data
-- portion. Each of these can be any Euphoria atom or sequence.
--
-- Errors:
--		If the current table is not defined, or if the record index is invalid, an error will occur.
--
-- Example 1:
-- <eucode>
-- puts(1, "The 6th record has data value: ")
-- ? db_record_data(6)
-- </eucode>
--
-- See Also:
-- 		[[:db_find_key]], [[:db_replace_data]]

public function db_record_data(integer key_location, object table_name=current_table_name)
	atom data_ptr
	object data_value

	if not equal(table_name, current_table_name) then
		if db_select_table(table_name) != DB_OK then
			fatal(NO_TABLE, "invalid table name given", "db_record_data", {key_location, table_name})
			return -1
		end if
	end if

	if current_table_pos = -1 then
		fatal(NO_TABLE, "no table selected", "db_record_data", {key_location, table_name})
		return -1
	end if
	if key_location < 1 or key_location > length(key_pointers) then
		fatal(BAD_RECNO, "bad record number", "db_record_data", {key_location, table_name})
		return -1
	end if

	io:seek(current_db, key_pointers[key_location])
	if length(vLastErrors) > 0 then return -1 end if
	data_ptr = get4()
	io:seek(current_db, data_ptr)
	data_value = decompress(0)

	return data_value
end function

--**
-- returns the data for the record with supplied key.
--
-- Parameters:
-- 		# ##key## : the identifier of the record to be looked up.
--      # ##table_name## : optional name of table to find key in
--
-- Returns:
--		An **integer**,
--		* If less than zero, the record was not found. The returned integer
--        is the opposite of what the record number would have been, had
--        the record been found.
--      * If equal to zero, an error occured.
--      A sequence, the data for the record.
--
-- Errors:
-- 		If the current table is not defined, it returns 0.
--
-- Comments:
-- Each record in a Euphoria database consists of a key portion and a data
-- portion. Each of these can be any Euphoria atom or sequence. 
--
-- Note:
-- This
-- function does not support records that data consists of a single non-sequence value.
-- In those cases you will need to use [[:db_find_key]] and [[:db_record_data]].
--
-- Example 1:
-- <eucode>
-- printf(1, "The record['%s'] has data value:\n", {"foo"})
-- ? db_fetch_record("foo")
-- </eucode>
--
-- See Also:
-- 		[[:db_find_key]], [[:db_record_data]]

public function db_fetch_record(object key, object table_name=current_table_name)
	integer pos
	
	pos = db_find_key(key, table_name)
	if pos > 0 then
		return db_record_data(pos, table_name)
	else
		return pos
	end if
end function

--**
-- returns the key of a record given an index. 
-- Parameters:
-- 		# ##key_location## : an integer, the index of the record the key is being requested.
--      # ##table_name## : optional table name to get record key from.
--
-- Returns
-- 		An **object**, the key of the record being queried by index.
--
-- Note: 
-- This function calls ##fatal## and returns a value of ##-1## if an error prevented
--      the correct data being returned. 
--
-- Errors:
--		If the current table is not defined, or if the record index is invalid, an error will occur.
--
-- Comments:
-- Each record in a Euphoria database consists of a key portion and a
-- data portion. Each of these can be any Euphoria atom or sequence.
--
-- Example 1:
-- <eucode>
-- puts(1, "The 6th record has key value: ")
-- ? db_record_key(6)
-- </eucode>
--
-- See Also:
-- 		[[:db_record_data]]

public function db_record_key(integer key_location, object table_name=current_table_name)
	if not equal(table_name, current_table_name) then
		if db_select_table(table_name) != DB_OK then
			fatal(NO_TABLE, "invalid table name given", "db_record_key", {key_location, table_name})
			return -1
		end if
	end if

	if current_table_pos = -1 then
		fatal(NO_TABLE, "no table selected", "db_record_key", {key_location, table_name})
		return -1
	end if
	if key_location < 1 or key_location > length(key_pointers) then
		fatal(BAD_RECNO, "bad record number", "db_record_key", {key_location, table_name})
		return -1
	end if
	return key_value(key_pointers[key_location])
end function

--**
-- compresses the current database.
--
-- Returns:
-- 		An **integer**, either DB_OK on success or an error code on failure.
--
-- Comments:
-- The current database is copied to a new
-- file such that any blocks of unused space are eliminated. If successful,
-- the return value will be set to ##DB_OK##, and the new compressed database
-- file will retain the same name. The current table will be undefined. As
-- a backup, the original, uncompressed file will be renamed with an extension
-- of ##.t0 (or .t1, .t2, ..., .t99)##. In the highly unusual case that the
-- compression is unsuccessful, the database will be left unchanged, and no
-- backup will be made.
--
-- When you delete items from a database, you create blocks of free space within
-- the database file. The system keeps track of these blocks and tries to use them
-- for storing new data that you insert. ##db_compress## will copy the current
-- database without copying these free areas. The size of the database file may
-- therefore be reduced. If the backup filenames reach ##.t99## you will have to
-- delete some of them.
--
-- Example 1:
-- <eucode>
-- if db_compress() != DB_OK then
--     puts(2, "compress failed!\n")
-- end if
-- </eucode>

public function db_compress()
	integer index, chunk_size, nrecs, r, fn
	sequence new_path, table_list, record, chunk

	if current_db = -1 then
		fatal(NO_DATABASE, "no current database", "db_compress", {})
		return -1
	end if

	index = eu:find(current_db, db_file_nums)
	new_path = text:trim(db_names[index])
	db_close()

	fn = -1
	sequence temp_path = filesys:temp_file()
	fn = open( temp_path, "r" )
	if fn != -1 then
		return DB_EXISTS_ALREADY -- you better delete some temp files
	end if

	filesys:move_file( new_path, temp_path )
	
	-- create a new database
	index = db_create(new_path, DB_LOCK_NO)
	if index != DB_OK then
		filesys:move_file( temp_path, new_path )
		return index
	end if

	index = db_open(temp_path, DB_LOCK_NO)
	table_list = db_table_list()

	for i = 1 to length(table_list) do
		index = db_select(new_path)
		index = db_create_table(table_list[i])

		index = db_select(temp_path)
		index = db_select_table(table_list[i])

		nrecs = db_table_size()
		r = 1
		while r <= nrecs do
			chunk_size = nrecs - r + 1
			if chunk_size > 20 then
				chunk_size = 20  -- copy up to 20 records at a time
			end if
			-- read a bunch of records
			chunk = {}
			for j = 1 to chunk_size do
				record = {db_record_key(r), db_record_data(r)}
				r += 1
				chunk = append(chunk, record)
			end for
			-- switch to new table
			index = db_select(new_path)
			index = db_select_table(table_list[i])
			-- insert a bunch of records
			for j = 1 to chunk_size do
				if db_insert(chunk[j][1], chunk[j][2]) != DB_OK then
					fatal(INSERT_FAILED, "couldn't insert into new database", "db_compress", {})
					return DB_FATAL_FAIL
				end if
			end for
			-- switch back to old table
			index = db_select(temp_path)
			index = db_select_table(table_list[i])
		end while
	end for
	db_close()
	index = db_select(new_path)
	return DB_OK
end function

--**
-- gets name of currently selected database.
--
-- Parameters:
--		# None.
--
-- Returns:
-- A **sequence**, the name of the current database. An empty string means
-- that no database is currently selected.
--
-- Comments:
-- The actual name returned is the //path// as supplied to the ##db_open## routine.
--
-- Example 1:
-- <eucode>
-- s = db_current_database()
-- </eucode>
--
-- See Also:
--   [[:db_select]]

public function db_current ()
	integer index

	index = find (current_db, db_file_nums)
	if index != 0 then
		return db_names [index]
	else
		return ""
	end if
end function

--**
-- forces the database index cache to be cleared.
--
-- Parameters:
--  # None
--
-- Comments:
-- * This is not normally required to the run. You might run it to set up a
-- predetermined state for performance timing, or to release some memory back to the
-- application.
--
-- Example 1:
-- <eucode>
-- db_cache_clear() -- Clear the cache.
-- </eucode>

public procedure db_cache_clear()
	cache_index = {}
	key_cache = {}
end procedure

--**
-- sets the key cache behavior.
--
-- Parameters:
--		# ##integer## : ##0## will turn of caching, ##1## will turn it back on.
--
-- Returns:
-- 		An **integer**, the previous setting of the option.
--
-- Comments:
-- Initially, the cache option is turned on. This means that when possible, the
-- keys of a table are kept in RAM rather than read from disk each time
-- ##db_select_table## is called. For most databases, this will improve performance
-- when you have more than one table in it.
--
-- When caching is turned off, the current cache contents is totally cleared.
--
-- Example 1:
-- <eucode>
-- x = db_set_caching(0) -- Turn off key caching.
-- </eucode>

public function db_set_caching(atom new_setting)
	integer lOldVal

	lOldVal = caching_option
	caching_option = (new_setting != 0)

	if caching_option = 0 then
		-- Wipe existing cache data.
		db_cache_clear()
	end if
	return lOldVal
end function

--**
-- replaces, in the current database, the data portion of a record with new data.
--
-- Parameters:
-- 		# ##recid## : an atom, the ##recid## of the record to be updated.
-- 		# ##data## : an object, the new value of the record.
--
-- Comments:
-- This can be used to quickly update records that have already been located
-- by calling [[:db_get_recid]]. This operation is faster than using
-- [[:db_replace_data]]
--
-- * ##recid## must be fetched using [[:db_get_recid]] first.
-- * ##data## is an Euphoria object of any kind, atom or sequence.
-- * The ##recid## does not have to be from the current table.
-- * This does no error checking. It assumes the database is open and valid.
--
-- Example 1:
-- <eucode>
-- rid = db_get_recid("Peter")
-- rec = db_record_recid(rid)
-- rec[2][3] *= 1.10
-- db_replace_recid(rid, rec[2])
-- </eucode>
--
-- See Also:
-- 		[[:db_replace_data]], [[:db_find_key]], [[:db_get_recid]]

public procedure db_replace_recid(integer recid, object data)
	atom old_size, new_size, data_ptr
	sequence data_string

	seek(current_db, recid)
	data_ptr = get4()
	seek(current_db, data_ptr-4)
	old_size = get4()-4
	data_string = compress(data)
	new_size = length(data_string)
	if new_size <= old_size and
	   new_size >= old_size - 16 then
		-- keep the same data block
		seek(current_db, data_ptr)
	else
		-- free the old block
		db_free(data_ptr)
		-- get a new data block
		data_ptr = db_allocate(new_size + 8)
		seek(current_db, recid)
		put4(data_ptr)
		seek(current_db, data_ptr)
		
		-- if the data comes from the end of the file, we need to 
		-- make sure it gets filled
		data_string &= repeat( 0, 8 )
		
	end if
	putn(data_string)
end procedure

--**
-- returns the key and data in a record queried by ##recid##.
--
-- Parameters:
-- 		# ##recid## : the ##recid## of the required record, which has been
--         previously fetched using [[:db_get_recid]].
--
-- Returns:
--		An **sequence**, the first element is the key and the second element
--      is the data portion of requested record.
--
-- Comments:
-- * This is much faster than calling [[:db_record_key]] and [[:db_record_data]].
-- * This does no error checking. It assumes the database is open and valid.
-- * This function does not need the requested record to be from the current
-- table. The ##recid## can refer to a record in any table.
--
-- Example 1:
-- <eucode>
-- rid = db_get_recid("SomeKey")
-- ? db_record_recid(rid)
-- </eucode>
--
-- See Also:
-- 		[[:db_get_recid]], [[:db_replace_recid]]

public function db_record_recid(integer recid)
	atom data_ptr
	object data_value
	object key_value

	seek(current_db, recid)
	data_ptr = get4()
	key_value = decompress(0)
	seek(current_db, data_ptr)
	data_value = decompress(0)

	return {key_value, data_value}
end function

--**
-- returns the unique record identifier (##recid##) value for the record.
--
-- Parameters:
-- 		# ##key## : the identifier of the record to be looked up.
--      # ##table_name## : optional name of table to find key in
--
-- Returns:
--		An **atom**, either greater or equal to zero:
-- 		* If above zero, it is a ##recid##.
--		* If less than zero, the record wasn't found.
--      * If equal to zero, an error occured.
--
-- Errors:
-- 		If the table is not defined, an error is raised.
--
-- Comments:
-- A **##recid##** is a number that uniquely identifies a record in the database. 
-- No two records in a database has the same ##recid## value. They can be used
-- instead of keys to //quickly// refetch a record, as they avoid the overhead of
-- looking for a matching record key. They can also be used without selecting
-- a table first, as the ##recid## is unique to the database and not just a table.
-- However, they only remain valid while a database is open and so long as it
-- does not get compressed. Compressing the database will give each record a
-- new ##recid## value. 
--
-- Because it is faster to fetch a record with a ##recid## rather than with its key,
-- these are used when you know you have to //refetch// a record. 
--
-- Example 1:
-- <eucode>
-- rec_num = db_get_recid("Millennium")
-- if rec_num > 0 then
--     ? db_record_recid(rec_num) -- fetch key and data.
-- else
--     puts(2, "Not found\n")
-- end if
-- </eucode>
--
-- See Also:
-- 		[[:db_insert]], [[:db_replace_data]], [[:db_delete_record]], [[:db_find_key]]

public function db_get_recid(object key, object table_name=current_table_name)
	integer lo, hi, mid, c  -- works up to 1.07 billion records

	if not equal(table_name, current_table_name) then
		if db_select_table(table_name) != DB_OK then
			fatal(NO_TABLE, "invalid table name given", "db_get_recid", {key, table_name})
			return 0
		end if
	end if

	if current_table_pos = -1 then
		fatal(NO_TABLE, "no table selected", "db_get_recid", {key, table_name})
		return 0
	end if
	lo = 1
	hi = length(key_pointers)
	mid = 1
	c = 0
	while lo <= hi do
		mid = floor((lo + hi) / 2)
		c = eu:compare(key, key_value(key_pointers[mid]))
		if c < 0 then
			hi = mid - 1
		elsif c > 0 then
			lo = mid + 1
		else
			return key_pointers[mid]
		end if
	end while
	return -1
end function

