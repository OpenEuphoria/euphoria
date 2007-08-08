-- (c) Copyright 2007 Rapid Deployment Software - See License.txt
--
-- Euphoria 3.1
-- Euphoria Database System (EDS)
--
-- Database File Format
-- Header
--    byte 0: magic number for this file-type: 77
--    byte 1: version number (major)
--    byte 2: version number (minor)
--    byte 3: 4-byte pointer to block of table headers
--    byte 7: number of free blocks
--    byte 11: 4-byte pointer to block of free blocks
--    
--    block of table headers: 
--                 -4: allocated size of this block (for possible reallocation) 
--                  0: number of table headers currently in use
--                  4: table header1
--                 16: table header2
--                 28: etc. 
--    
--    table header: 0: pointer to the name of this table
--                  4: total number of records in this table
--                  8: number of blocks of records
--                 12: pointer to the index block for this table
--
--    There are two levels of pointers. The logical array of key pointers 
--    is split up across many physical blocks. A single index block 
--    is used to select the correct small block. This allows 
--    inserts and deletes to be made without having to shift a 
--    large number of key pointers. Only one small block needs to 
--    be adjusted. This is particularly helpful when the table contains 
--    many thousands of records.
--
--    index block (one per table):
--                 -4: allocated size of index block
--                  0: number of records in 1st block of key pointers
--                  4: pointer to 1st block
--                  8: number of records in 2nd "                   "
--                 12: pointer to 2nd block
--                 16: etc.
--
--    block of key pointers (many per table): 
--                 -4: allocated size of this block in bytes
--                  0: key pointer 1
--                  4: key pointer 2
--                  8: etc.
--
--    free list - in ascending order of address
--                 -4: allocated size of block of free blocks
--                  0: address of 1st free block
--                  4: size of 1st free block
--                  8: address of 2nd free block
--                 12: size of 2nd free block
--                 16: etc.
--
--    The key value and the data value for a record are allocated space
--    as needed. A pointer to the data value is stored just before the 
--    key value. Euphoria objects, key and data, are stored in a compact form.
--    All allocated blocks have the size of the block in bytes, stored just 
--    before the address.

include machine.e
include file.e
include misc.e
include get.e

-- ERROR STATUS
global constant DB_OK = 0,
		DB_OPEN_FAIL = -1, 
		DB_EXISTS_ALREADY = -2,
		DB_LOCK_FAIL = -3
		
-- LOCK TYPES           
global constant DB_LOCK_NO = 0,       -- don't bother with file locking 
		DB_LOCK_SHARED = 1,   -- read the database
		DB_LOCK_EXCLUSIVE = 2 -- read and write the database
		 
constant DB_MAGIC = 77
constant DB_MAJOR = 3, DB_MINOR = 0   -- database created with Euphoria v3.0 
constant SIZEOF_TABLE_HEADER = 16
constant TABLE_HEADERS = 3, FREE_COUNT = 7, FREE_LIST = 11
constant SCREEN = 1

-- initial sizes for various things:
constant INIT_FREE = 5,
	 INIT_TABLES = 5,
	 INIT_INDEX = 10, 
	 INIT_RECORDS = 50

constant TRUE = 1

integer current_db
atom current_table
sequence db_names, db_file_nums, db_lock_methods
integer current_lock
sequence SLASH_CHAR
if platform() = LINUX then
    SLASH_CHAR = "/"
else
    SLASH_CHAR = "\\/"
end if
 
current_db = -1
current_table = -1

db_names = {}
db_file_nums = {}
db_lock_methods = {}

sequence key_pointers

procedure default_fatal(sequence msg)
-- default fatal error handler - you can override this
    puts(SCREEN, "Fatal Database Error: " & msg & '\n')
    ?1/0 -- to see call stack
end procedure

-- exception handler
global integer db_fatal_id
db_fatal_id = routine_id("default_fatal") -- you can set it to your own handler

procedure fatal(sequence msg)
    call_proc(db_fatal_id, {msg})
end procedure

function get1()
-- read 1-byte value at current position in database file
    return getc(current_db)
end function

atom mem0, mem1, mem2, mem3
mem0 = allocate(4)
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
    
    s = ""
    while TRUE do
	c = getc(current_db)
	if c = -1 then
	    fatal("string is missing 0 terminator")
	elsif c = 0 then
	    exit
	end if
	s &= c
    end while
    return s
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
    
    if c = I2B then
	return getc(current_db) + 
	       #100 * getc(current_db) +
	       MIN2B
    
    elsif c = I3B then
	return getc(current_db) + 
	       #100 * getc(current_db) + 
	       #10000 * getc(current_db) +
	       MIN3B
    
    elsif c = I4B then
	return get4() + MIN4B
    
    elsif c = F4B then
	return float32_to_atom({getc(current_db), getc(current_db), 
				getc(current_db), getc(current_db)})
    elsif c = F8B then
	return float64_to_atom({getc(current_db), getc(current_db),
				getc(current_db), getc(current_db),
				getc(current_db), getc(current_db),
				getc(current_db), getc(current_db)})
    else
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
    end if
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
	    return I4B & int_to_bytes(x-MIN4B)    
	    
	end if
    
    elsif atom(x) then
	-- floating point
	x4 = atom_to_float32(x)
	if x = float32_to_atom(x4) then
	    -- can represent as 4-byte float
	    return F4B & x4
	else
	    return F8B & atom_to_float64(x)
	end if

    else
	-- sequence
	if length(x) <= 255 then
	    s = {S1B, length(x)}
	else
	    s = S4B & int_to_bytes(length(x))
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

procedure safe_seek(atom pos)
-- seek to a position in the current db file    
    if seek(current_db, pos) != 0 then
	fatal(sprintf("seek to position %d failed!\n", pos))
    end if
end procedure

global procedure db_dump(integer fn, integer low_level_too)
-- print an open database in readable form to file fn
-- (Note: If you turn database.e into a .dll or .so, you will
-- have to change this routine to accept a file name, rather than
-- an open file number. All other database.e routines are ok as they are.)
    integer magic, minor, major
    atom tables, ntables, tname, trecords, t_header, tnrecs, 
	 key_ptr, data_ptr, size, addr, tindex
    object key, data
    integer c, n, tblocks
    atom a
    
    if low_level_too then
	-- low level dump: show all bytes in the file
	safe_seek(0)
	a = 0
	while TRUE do
	    c = getc(current_db)
	    if c = -1 then
		exit
	    end if
	    if remainder(a, 10) = 0 then
		printf(SCREEN, "\n%d: ", a)
	    end if
	    printf(SCREEN, "%d, ", c)
	    a += 1
	end while
    end if
    
    -- high level dump
    puts(fn, '\n')
    safe_seek(0)
    magic = get1()
    if magic != DB_MAGIC then
	puts(fn, "This is not a Euphoria Database file\n")
	return
    end if
    major = get1()
    minor = get1()
    printf(fn, "Euphoria Database System Version %d.%d\n\n", {major, minor})
    tables = get4()
    safe_seek(tables)
    ntables = get4()
    printf(fn, "The \"%s\" database has %d table", 
	   {db_names[find(current_db, db_file_nums)], ntables})
    if ntables = 1 then
	puts(fn, "\n")
    else
	puts(fn, "s\n")
    end if
    t_header = where(current_db)
    for t = 1 to ntables do
	-- display the next table
	tname = get4()
	tnrecs = get4() -- ignore
	tblocks = get4()
	tindex = get4()
	safe_seek(tname)
	printf(fn, "\ntable \"%s\":\n", {get_string()})
	for b = 1 to tblocks do
	    printf(fn, "\nblock #%d\n\n", b)
	    safe_seek(tindex+(b-1)*8)
	    tnrecs = get4()
	    trecords = get4()
	    for r = 1 to tnrecs do
		-- display the next record
		safe_seek(trecords+(r-1)*4)
		key_ptr = get4()
		safe_seek(key_ptr)
		data_ptr = get4()
		key = decompress(0)
		puts(fn, "  key: ")
		pretty_print(fn, key, {1, 2, 8})
		puts(fn, '\n')
		safe_seek(data_ptr)
		data = decompress(0)
		puts(fn, "  data: ")
		pretty_print(fn, data, {1, 2, 9})
		puts(fn, "\n\n")
	    end for
	end for
	t_header += SIZEOF_TABLE_HEADER
	safe_seek(t_header)
    end for
    -- show the free list
    puts(fn, "List of free blocks:\n")
    safe_seek(FREE_COUNT)
    n = get4()
    safe_seek(get4())
    for i = 1 to n do
	addr = get4()
	size = get4()
	printf(fn, "%d: %d bytes\n", {addr, size})
    end for
end procedure

global procedure check_free_list()
-- This is a debug routine used by RDS to detect corruption of the free list.
-- Users do not normally call this.
    atom free_count, free_list, addr, size, free_list_space
    atom max
  
    safe_seek(-1)
    max = where(current_db)
    safe_seek(FREE_COUNT)
    free_count = get4()
    if free_count > max/13 then
	fatal("free count is too high")
    end if
    free_list = get4()
    if free_list > max then
	fatal("bad free list pointer")
    end if
    safe_seek(free_list-4)
    free_list_space = get4()
    if free_list_space > max or free_list_space < INIT_FREE * 8 then
	fatal("free list space is bad")  
    end if
    for i = 1 to free_count do
	safe_seek(free_list+(i-1)*8)
	addr = get4()
	if addr > max then
	    fatal("bad block address")
	end if
	size = get4()
	if size > max then
	    fatal("block size too big")
	end if
	safe_seek(addr-4)
	if get4() > size then
	    fatal("bad size in front of free block")
	end if
    end for
end procedure

function db_allocate(atom n)
-- Allocate (at least) n bytes of space in the database file.
-- The usable size + 4 is stored in the 4 bytes before the returned address.
-- Upon return, the file pointer points at the allocated space, so data
-- can be stored into the space immediately without a seek.
-- When space is allocated at the end of the file, it will be exactly
-- n bytes in size, and the caller must fill up all the space immediately.
    atom free_list, size, size_ptr, addr
    integer free_count
    sequence remaining

    safe_seek(FREE_COUNT)
    free_count = get4()
    if free_count > 0 then
	free_list = get4()
	safe_seek(free_list)
	size_ptr = free_list + 4
	for i = 1 to free_count do
	    addr = get4()
	    size = get4()
	    if size >= n+4 then
		-- found a big enough block
		if size >= n+16 then 
		    -- loose fit: shrink first part, return 2nd part
		    safe_seek(addr-4)
		    put4(size-n-4) -- shrink the block
		    safe_seek(size_ptr)
		    put4(size-n-4) -- update size on free list too
		    addr += size-n-4
		    safe_seek(addr-4)
		    put4(n+4)
		else    
		    -- close fit: remove whole block from list and return it
		    remaining = get_bytes(current_db, (free_count-i) * 8)
		    safe_seek(free_list+8*(i-1))
		    putn(remaining)
		    safe_seek(FREE_COUNT)
		    put4(free_count-1)
		    safe_seek(addr-4)
		    put4(size) -- in case size was not updated by db_free()
		end if
		return addr
	    end if
	    size_ptr += 8
	end for
    end if
    -- no free block available - point to end of file
    safe_seek(-1) -- end of file
    put4(n+4)
    return where(current_db)
end function

procedure db_free(atom p)
-- Put a block of storage onto the free list in order of address.
-- Combine the new free block with any adjacent free blocks.
    atom psize, i, size, addr, free_list, free_list_space
    atom new_space, to_be_freed, prev_addr, prev_size
    integer free_count
    sequence remaining

    safe_seek(p-4)
    psize = get4()
    
    safe_seek(FREE_COUNT)
    free_count = get4()
    free_list = get4()
    safe_seek(free_list-4)
    free_list_space = get4()-4
    if free_list_space < 8 * (free_count+1) then
	-- need more space for free list
	new_space = floor(free_list_space * 3 / 2)
	to_be_freed = free_list
	free_list = db_allocate(new_space)
	safe_seek(free_list-4)
	safe_seek(FREE_COUNT)
	free_count = get4() -- db_allocate may have changed it
	safe_seek(FREE_LIST)
	put4(free_list)
	safe_seek(to_be_freed)
	remaining = get_bytes(current_db, 8*free_count)
	safe_seek(free_list)
	putn(remaining)
	putn(repeat(0, new_space-length(remaining)))
	safe_seek(free_list)
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
	safe_seek(free_list+(i-2)*8+4)
	if i < free_count and p + psize = addr then
	    -- combine space for all 3, delete the following block
	    put4(prev_size+psize+size) -- update size on free list (only)
	    safe_seek(free_list+i*8)
	    remaining = get_bytes(current_db, (free_count-i)*8)
	    safe_seek(free_list+(i-1)*8)
	    putn(remaining)
	    free_count -= 1
	    safe_seek(FREE_COUNT)
	    put4(free_count)
	else
	    put4(prev_size+psize) -- increase previous size on free list (only)
	end if
    elsif i < free_count and p + psize = addr then
	-- combine with following block - only size on free list is updated
	safe_seek(free_list+(i-1)*8)
	put4(p)
	put4(psize+size)
    else
	-- insert a new block, shift the others down
	safe_seek(free_list+(i-1)*8)
	remaining = get_bytes(current_db, (free_count-i+1)*8)
	free_count += 1
	safe_seek(FREE_COUNT)
	put4(free_count)
	safe_seek(free_list+(i-1)*8)
	put4(p)
	put4(psize)
	putn(remaining)
    end if

    if new_space then
	db_free(to_be_freed) -- free the old space
    end if
end procedure

global function db_create(sequence path, integer lock_method)
-- Create a new database in the file given by path.
-- It becomes the current database.
    
    integer db
    
    if not find('.', path) then
	path &= ".edb"
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
	if not lock_file(db, LOCK_EXCLUSIVE,{}) then
	    return DB_LOCK_FAIL
	end if
    end if
    current_db = db
    current_lock = lock_method
    current_table = -1
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
    put4(23 + INIT_TABLES * SIZEOF_TABLE_HEADER + 4)   -- pointer to free list
    -- 15: initial table block:
    put4( 8 + INIT_TABLES * SIZEOF_TABLE_HEADER)  -- allocated size
    -- 19:
    put4(0)   -- number of tables that currently exist
    -- 23: initial space for tables
    putn(repeat(0, INIT_TABLES * SIZEOF_TABLE_HEADER)) 
    -- initial space for free list
    put4(4+INIT_FREE*8)   -- allocated size
    putn(repeat(0, INIT_FREE * 8))
    return DB_OK
end function

global function db_open(sequence path, integer lock_method)
-- Open an existing database file.
-- It becomes the current database.
-- If the lock fails, the caller should wait a few seconds 
-- and then call again. 
    integer db, magic
    
    if not find('.', path) then
	path &= ".edb"
    end if
    
    if lock_method = DB_LOCK_NO or 
       lock_method = DB_LOCK_EXCLUSIVE then
	-- get read and write access, "ub"
	db = open(path, "ub")
    else
	-- DB_LOCK_SHARED
	db = open(path, "rb")
    end if
    if db = -1 then
	return DB_OPEN_FAIL
    end if
    if lock_method = DB_LOCK_EXCLUSIVE then
	if not lock_file(db, LOCK_EXCLUSIVE, {}) then
	    close(db)
	    return DB_LOCK_FAIL
	end if
    elsif lock_method = DB_LOCK_SHARED then
	if not lock_file(db, LOCK_SHARED, {}) then
	    close(db)
	    return DB_LOCK_FAIL
	end if
    end if
    magic = getc(db)
    if magic != DB_MAGIC then
	close(db)
	return DB_OPEN_FAIL
    end if
    current_db = db
    current_table = -1
    current_lock = lock_method
    db_names = append(db_names, path)
    db_lock_methods = append(db_lock_methods, lock_method)
    db_file_nums = append(db_file_nums, db)
    return DB_OK
end function

global function db_select(sequence path)
-- Choose a new, already open, database to be the current database. 
    integer index
    
    if not find('.', path) then
	path &= ".edb"
    end if
    
    index = find(path, db_names)
    if index = 0 then 
	return DB_OPEN_FAIL 
    end if
    current_db = db_file_nums[index]
    current_lock = db_lock_methods[index]
    current_table = -1
    return DB_OK
end function

global procedure db_close()
-- close the current database
    integer index
    
    if current_db = -1 then
	return
    end if
    -- unlock the database
    if current_lock then
	unlock_file(current_db, {})
    end if
    close(current_db)
    -- delete info for current_db
    index = find(current_db, db_file_nums)
	   db_names = db_names[1..index-1] & db_names[index+1..$]
       db_file_nums = db_file_nums[1..index-1] & db_file_nums[index+1..$]
    db_lock_methods = db_lock_methods[1..index-1] & db_lock_methods[index+1..$]
    current_db = -1 
end procedure

function table_find(sequence name)
-- find a table, given its name 
-- return table pointer
    atom tables, nt, t_header, name_ptr
    sequence tname
    
    safe_seek(TABLE_HEADERS)
    tables = get4()
    safe_seek(tables)
    nt = get4()
    t_header = tables+4
    for i = 1 to nt do
	safe_seek(t_header)
	name_ptr = get4()
	safe_seek(name_ptr)
	tname = get_string()
	if equal(tname, name) then
	    -- found it
	    return t_header
	end if
	t_header += SIZEOF_TABLE_HEADER
    end for
    return -1
end function

global function db_select_table(sequence name)
-- let table with the given name be the current table
    atom table, nkeys, index
    atom block_ptr, block_size
    integer blocks, k
    
    table = table_find(name)
    if table = -1 then
	return DB_OPEN_FAIL
    end if  
    if current_table = table then
	return DB_OK -- nothing to do
    end if
    current_table = table
    -- read in all the key pointers for the current table
    safe_seek(table+4)
    nkeys = get4()
    blocks = get4()
    index = get4()
    key_pointers = repeat(0, nkeys)
    k = 1
    for b = 0 to blocks-1 do
	safe_seek(index)
	block_size = get4()
	block_ptr = get4()
	safe_seek(block_ptr)
	for j = 1 to block_size do
	    key_pointers[k] = get4()
	    k += 1
	end for
	index += 8
    end for
    return DB_OK
end function

global function db_create_table(sequence name)
-- create a new table in the current database file
    atom name_ptr, nt, tables, newtables, table, records_ptr
    atom size, newsize, index_ptr
    sequence remaining
    
    table = table_find(name)
    if table != -1 then
	return DB_EXISTS_ALREADY
    end if
    
    -- increment number of tables
    safe_seek(TABLE_HEADERS)
    tables = get4()
    safe_seek(tables-4)
    size = get4()
    nt = get4()+1
    if nt*SIZEOF_TABLE_HEADER + 8 > size then
	-- enlarge the block of table headers
	newsize = floor(size * 3 / 2)
	newtables = db_allocate(newsize)
	put4(nt)
	-- copy all table headers to the new block
	safe_seek(tables+4)
	remaining = get_bytes(current_db, (nt-1)*SIZEOF_TABLE_HEADER)
	safe_seek(newtables+4)
	putn(remaining)
	-- fill the rest
	putn(repeat(0, newsize - 4 - (nt-1)*SIZEOF_TABLE_HEADER))
	db_free(tables)
	safe_seek(TABLE_HEADERS)
	put4(newtables)
	tables = newtables
    else
	safe_seek(tables)
	put4(nt)
    end if
    
    -- allocate initial space for 1st block of record pointers
    records_ptr = db_allocate(INIT_RECORDS * 4)
    putn(repeat(0, INIT_RECORDS * 4))

    -- allocate initial space for the index
    index_ptr = db_allocate(INIT_INDEX * 8)
    put4(0)  -- 0 records 
    put4(records_ptr) -- point to 1st block
    putn(repeat(0, (INIT_INDEX-1) * 8))
	
    -- store new table
    name_ptr = db_allocate(length(name)+1)
    putn(name & 0)
    
    safe_seek(tables+4+(nt-1)*SIZEOF_TABLE_HEADER)
    put4(name_ptr)
    put4(0)  -- start with 0 records total
    put4(1)  -- start with 1 block of records in index
    put4(index_ptr)
    if db_select_table(name) then
    end if
    return DB_OK
end function

global procedure db_delete_table(sequence name)
-- delete an existing table and all of its records
    atom table, tables, nt, nrecs, records_ptr, blocks
    atom p, data_ptr, index
    sequence remaining
    
    table = table_find(name)
    if table = -1 then
	return 
    end if
    
    -- free the table name 
    safe_seek(table)
    db_free(get4())
    
    safe_seek(table+4)
    nrecs = get4()
    blocks = get4()
    index = get4()
    
    -- free all the records
    for b = 0 to blocks-1 do
	safe_seek(index+b*8)
	nrecs = get4()
	records_ptr = get4()
	for r = 0 to nrecs-1 do
	    safe_seek(records_ptr + r*4)
	    p = get4()
	    safe_seek(p)
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
    safe_seek(TABLE_HEADERS)
    tables = get4()
    safe_seek(tables)
    nt = get4()
    
    -- shift later tables up
    safe_seek(table+SIZEOF_TABLE_HEADER)
    remaining = get_bytes(current_db, 
			  tables+4+nt*SIZEOF_TABLE_HEADER-
			  (table+SIZEOF_TABLE_HEADER))
    safe_seek(table)
    putn(remaining)

    -- decrement number of tables
    nt -= 1
    safe_seek(tables)
    put4(nt)
    
    if table = current_table then
	current_table = -1
    elsif table < current_table then
	current_table -= SIZEOF_TABLE_HEADER
    end if
end procedure

global procedure db_rename_table(sequence name, sequence new_name)
-- rename an existing table - written by Jordah Ferguson
    atom table,table_ptr 
    
    table = table_find(name)
    if table = -1 then 
	fatal("Source table doesn't exist")
    end if
    
    if table_find(new_name) != -1 then
	fatal("Target table name already exists")
    end if
    
    safe_seek(table)
    db_free(get4())
    
    table_ptr = db_allocate(length(new_name)+1)
    putn(new_name & 0)
    
    safe_seek(table)
    put4(table_ptr)
end procedure

global function db_table_list()
-- return a sequence of all the table names in the current database
    sequence table_names
    atom tables, nt, name
    
    safe_seek(TABLE_HEADERS)
    tables = get4()
    safe_seek(tables)
    nt = get4()
    table_names = repeat(0, nt)
    for i = 0 to nt-1 do
	safe_seek(tables + 4 + i*SIZEOF_TABLE_HEADER)
	name = get4()
	safe_seek(name)
	table_names[i+1] = get_string()
    end for
    return table_names
end function

function key_value(atom ptr)
-- return the value of a key, 
-- given a pointer to the key in the database
    safe_seek(ptr+4) -- skip ptr to data
    return decompress(0)
end function

global function db_find_key(object key)
-- Find the record in the current table that contains the given key.
-- If the key is not found, the place in the table where the key would go 
-- if it were inserted is returned as a negative record number.
-- A binary search is used.
    integer lo, hi, mid, c  -- works up to 1.07 billion records
    
    if current_table = -1 then
	fatal("no table selected")
    end if
    lo = 1
    hi = length(key_pointers)
    mid = 1
    c = 0
    while lo <= hi do
	mid = floor((lo + hi) / 2)
	c = compare(key, key_value(key_pointers[mid]))
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

global function db_insert(object key, object data)
-- insert a new record into the current table 
-- of the current database file
    
    sequence key_string, data_string, last_part, remaining
    atom key_ptr, data_ptr, records_ptr, nrecs, current_block, size, new_size
    atom key_location, new_block, index_ptr, new_index_ptr, total_recs
    integer r, blocks, new_recs, n
    
    key_location = db_find_key(key)
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
    safe_seek(current_table+4)
    total_recs = get4()+1
    blocks = get4()
    safe_seek(current_table+4)
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
   
    safe_seek(current_table+12) -- get after put - seek is necessary
    index_ptr = get4()
    
    safe_seek(index_ptr)
    r = 0
    while TRUE do
	nrecs = get4()
	records_ptr = get4()
	r += nrecs
	if r + 1 >= key_location then
	    exit
	end if
    end while
    
    current_block = where(current_db)-8
    
    key_location -= (r-nrecs)
    
    safe_seek(records_ptr+4*(key_location-1))
    for i = key_location to nrecs+1 do
	put4(key_pointers[i+r-nrecs])
    end for
    
    -- increment number of records in this block
    safe_seek(current_block)
    nrecs += 1
    put4(nrecs)
    
    -- check allocated size for this block
    safe_seek(records_ptr - 4)
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
	safe_seek(records_ptr + (nrecs-new_recs)*4)
	last_part = get_bytes(current_db, new_recs*4)
	new_block = db_allocate(new_size)
	putn(last_part)
	-- fill the rest
	putn(repeat(0, new_size-length(last_part)))
	
	-- change nrecs for this block in index
	safe_seek(current_block)
	put4(nrecs-new_recs)
	
	-- insert new block into index after current block
	safe_seek(current_block+8)
	remaining = get_bytes(current_db, index_ptr+blocks*8-(current_block+8))
	safe_seek(current_block+8)
	put4(new_recs)
	put4(new_block)
	putn(remaining)
	safe_seek(current_table+8)
	blocks += 1
	put4(blocks)
	-- enlarge index if full
	safe_seek(index_ptr-4)
	size = get4() - 4
	if blocks*8 > size-8 then
	    -- grow the index
	    remaining = get_bytes(current_db, blocks*8)
	    new_size = floor(size*3/2)
	    new_index_ptr = db_allocate(new_size)
	    putn(remaining)
	    putn(repeat(0, new_size-blocks*8))
	    db_free(index_ptr)
	    safe_seek(current_table+12)
	    put4(new_index_ptr)
	end if
    end if
    return DB_OK
end function

global procedure db_delete_record(integer key_location)
-- delete record number rn in the current table
    atom key_ptr, nrecs, records_ptr, data_ptr, index_ptr, current_block
    integer r, blocks, n
    sequence remaining
    
    if current_table = -1 then
	fatal("no table selected")
    end if
    if key_location < 1 or key_location > length(key_pointers) then
	fatal("bad record number")
    end if
    key_ptr = key_pointers[key_location]
    safe_seek(key_ptr)
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
    safe_seek(current_table+4)
    nrecs = get4()-1
    blocks = get4()
    safe_seek(current_table+4)
    put4(nrecs)
    
    safe_seek(current_table+12)
    index_ptr = get4()
    
    safe_seek(index_ptr)
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
    current_block = where(current_db)-8
    nrecs -= 1
    
    if nrecs = 0 and blocks > 1 then
	-- delete this block from the index (unless it's the very last block)
	remaining = get_bytes(current_db, index_ptr+blocks*8-(current_block+8))
	safe_seek(current_block)
	putn(remaining)
	safe_seek(current_table+8)
	put4(blocks-1)
	db_free(records_ptr)
    else
	key_location -= r
	-- decrement the record count in the index
	safe_seek(current_block)
	put4(nrecs)
	-- delete one record
	safe_seek(records_ptr+4*(key_location-1))
	for i = key_location to nrecs do
	    put4(key_pointers[i+r])
	end for
    end if
end procedure

global procedure db_replace_data(integer rn, object data) 
-- replace the data for a record
-- faster than delete + insert
    atom old_size, new_size, key_ptr, data_ptr
    sequence data_string
    
    if current_table = -1 then
	fatal("no table selected")
    end if
    if rn < 1 or rn > length(key_pointers) then
	fatal("bad record number")
    end if
    key_ptr = key_pointers[rn]
    safe_seek(key_ptr)
    data_ptr = get4()
    safe_seek(data_ptr-4)
    old_size = get4()-4
    data_string = compress(data)
    new_size = length(data_string)
    if new_size <= old_size and 
       new_size >= old_size - 8 then
	-- keep the same data block
	safe_seek(data_ptr)
    else
	-- free the old block
	db_free(data_ptr)
	-- get a new data block
	data_ptr = db_allocate(new_size)
	safe_seek(key_ptr)
	put4(data_ptr)
	safe_seek(data_ptr)
    end if
    putn(data_string)
end procedure

global function db_table_size()
-- return the number of records in the current table
    if current_table = -1 then
	fatal("no table selected")
    end if
    return length(key_pointers)
end function

global function db_record_data(integer rn) 
-- return data value for record number rn
-- records are numbered 1..db_table_size
    atom data_ptr
    object data_value
    
    if current_table = -1 then
	fatal("no table selected")
    end if
    if rn < 1 or rn > length(key_pointers) then
	fatal("bad record number")
    end if
    safe_seek(key_pointers[rn])
    data_ptr = get4()
    safe_seek(data_ptr)
    data_value = decompress(0)
    return data_value
end function

global function db_record_key(integer rn) 
-- return key value for record number i 
-- records are numbered 1..db_table_size
    object key_value
    
    if current_table = -1 then
	fatal("no table selected")
    end if
    if rn < 1 or rn > length(key_pointers) then
	fatal("bad record number")
    end if
    safe_seek(key_pointers[rn]+4)
    key_value = decompress(0)
    return key_value
end function

function name_only(sequence s)
-- return the file name only, without the path
    sequence filename
    
    filename = ""
    for i = length(s) to 1 by -1 do
	if find(s[i], SLASH_CHAR) then
	    exit
	end if
	filename = s[i] & filename
    end for
    return filename
end function

function delete_whitespace(sequence text)
-- remove leading and trailing whitespace
    while length(text) > 0 and find(text[1], " \t\r\n") do
	text = text[2..$]
    end while
    while length(text) > 0 and find(text[length(text)], " \t\r\n") do
	text = text[1..$-1]
    end while
    return text
end function

global function db_compress()
-- Copy the current database to a new file, 
-- thereby eliminating any patches of unused space.
-- Thanks to Mike Nelson
   
    integer index, chunk_size, nrecs, r, fn
    sequence new_path, old_path, table_list, record, chunk
   
    if current_db = -1 then
	fatal("no current database")
    end if
    
    index = find(current_db, db_file_nums)
    new_path = delete_whitespace(db_names[index])
    db_close()
    
    fn = -1
    for i = 0 to 99 do
	-- try to find a temp name that isn't in use
	old_path = new_path[1..$-3] & sprintf("t%d", i)
	fn = open(old_path, "r") 
	if fn = -1 then
	    exit
	else
	    -- file exists, can't use it
	    close(fn)
	end if
    end for
    if fn != -1 then
	return DB_EXISTS_ALREADY -- you better delete some temp files
    end if
    
    -- rename database as .tmp
    if platform() = LINUX then
	system( "mv \"" & new_path & "\" \"" & old_path & '"', 2)
    elsif platform() = WIN32 then
	system("ren \"" & new_path & "\" \"" & name_only(old_path) & '"', 2)
    else    
	-- DOS
	system("ren " & new_path & " " & name_only(old_path), 2)
    end if
    
    -- create a new database
    index = db_create(new_path, DB_LOCK_NO)
    if index != DB_OK then
	-- failed, move it back to .edb
	if platform() = LINUX then
	    system( "mv \"" & old_path & "\" \"" & new_path & '"', 2)
	elsif platform() = WIN32 then
	    system("ren \"" & old_path & "\" \"" & name_only(new_path) & '"', 2)
	else    
	    -- DOS
	    system("ren " & old_path & " " & name_only(new_path), 2)
	end if
	return index
    end if
    
    index = db_open(old_path, DB_LOCK_NO)
    table_list = db_table_list()
    
    for i = 1 to length(table_list) do
	index = db_select(new_path)
	index = db_create_table(table_list[i])
	
	index = db_select(old_path)
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
		    fatal("couldn't insert into new database")
		end if
	    end for
	    -- switch back to old table
	    index = db_select(old_path)
	    index = db_select_table(table_list[i])        
	end while
    end for
    db_close()
    index = db_select(new_path)
    return DB_OK
end function

