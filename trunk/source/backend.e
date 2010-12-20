-- (c) Copyright 2007 Rapid Deployment Software - See License.txt

-- Store front-end data structures in memory
-- Called from (a) interpreter front-end
--          or (b) backend.ex (using different s.t. offsets)

global procedure InitBackEnd(integer x)
-- not needed by Interpreter or Binder
end procedure

constant ST_ENTRY_SIZE = 52  -- size (bytes) of back-end symbol table entry
			     -- for interpreter. Fixed size for all entries.

constant SOURCE_CHUNK = 10000 -- copied from scanner.e !!

without warning
global procedure BackEnd(integer il_file)
-- Store the required front-end data structures in memory.
-- Offsets are used in some places rather than pointers.
-- They will be replaced in the back-end.
    atom addr, st, tc, sc, nm, ms, tlt, slt, sl, src, lit, fn, entry_addr
    atom e_addr, l_addr, no_name, sli
    integer string_size, short, size, repcount
    sequence lit_string, other_strings
    object entry

    -- create a smaller back-end version of symbol table 
    
    -- allow extra for storing size 
    size = (1+length(SymTab)) * ST_ENTRY_SIZE 
    st = allocate(size)  -- symbol table
    mem_set(st, 0, size) -- all fields are 0 (NULL) by default
    
    -- unused 0th entry contains the length:
    poke4(st, length(SymTab))
	
    lit_string = "" -- literal values are stored in a string like EDS
    string_size = 0 -- precompute total space needed for symbol names
    
    addr = st + ST_ENTRY_SIZE
    for i = 1 to length(SymTab) do
	entry = SymTab[i]
	-- common to temps, vars, routines
	-- +0 (OBJ) is set to literal value by back-end
	-- "constant" variables are initialized with executable code
	if atom(entry) then
	    -- deleted
	    poke4(addr+4, entry) -- NEXT
	    poke(addr+8, M_TEMP) -- MODE
	    poke(addr+9, SC_UNDEFINED)  -- SCOPE, must be > S_PRIVATE 
	
	else
	    poke4(addr+4, entry[S_NEXT])
	    poke(addr+8, entry[S_MODE])
	    poke(addr+9, entry[S_SCOPE])

	    if length(entry) >= S_NAME and sequence(entry[S_NAME]) then
		-- temps and literals have no NAME field
		poke(addr+10, entry[S_FILE_NO])
		poke4(addr+16, entry[S_TOKEN])
		string_size += length(entry[S_NAME])+1
	    end if
	
	    if entry[S_MODE] = M_NORMAL then
		-- vars and routines
		
		if find(entry[S_TOKEN], {PROC, FUNC, TYPE}) then
		    -- routines only
		    if sequence(entry[S_CODE]) then
			-- routines with code
			e_addr = allocate(4+4*length(entry[S_CODE])) -- IL code
			poke4(e_addr, length(entry[S_CODE]))
			poke4(e_addr+4, entry[S_CODE])
			poke4(addr+20, e_addr)
		    
			if sequence(entry[S_LINETAB]) then
			    -- line table
			    l_addr = allocate(4*length(entry[S_LINETAB])) 
			    poke4(l_addr, entry[S_LINETAB])
			    poke4(addr+24, l_addr)
			else
			    -- pointer to linetable will be NULL
			end if
		    end if
		    poke4(addr+28, entry[S_FIRSTLINE])
		    poke4(addr+32, entry[S_TEMPS])
		    poke4(addr+36, entry[S_NUM_ARGS])
		    --
		    --
		    poke4(addr+48, entry[S_STACK_SPACE])
		end if
	    
	    elsif (length(entry) >= S_TOKEN and entry[S_TOKEN] = NAMESPACE) or 
		  (length(entry) < S_NAME and entry[S_MODE] = M_CONSTANT) then
		-- compress literal values in memory
		poke4(addr, length(lit_string))  -- record the current offset
		lit_string &= compress(entry[S_OBJ])
	
	    end if

	end if

	addr += ST_ENTRY_SIZE  -- could save some bytes by changing st structure
    end for
    
    -- save literals and declared constant values in memory
    lit = allocate(length(lit_string))
    poke(lit, lit_string) -- shouldn't need 0
    
    -- free lit_string
    lit_string = {}
    
    -- convert symbol names to C strings in memory
    nm = allocate(1+string_size)  
    addr = nm
    entry_addr = st
    no_name = allocate_string("<no-name>")
    for i = 1 to length(SymTab) do
	entry = SymTab[i]
	entry_addr += ST_ENTRY_SIZE
	
	if sequence(entry) then 
	    if length(entry) >= S_NAME then
		if sequence(entry[S_NAME]) then
		    -- record the address of the name string
		    poke4(entry_addr+12, addr) 
		    -- store the name string
		    poke(addr, entry[S_NAME])
		    addr += length(entry[S_NAME])
		    poke(addr, 0)  -- 0-delimited string
		    addr += 1
		
		    if entry[S_TOKEN] = NAMESPACE then
			-- convert offset to address
			poke4(entry_addr, peek4u(entry_addr)+lit) 
		    end if
		else
		    -- no name
		    poke4(entry_addr+12, no_name)
		end if  
	    
	    elsif entry[S_MODE] = M_CONSTANT then
		-- literals - convert offset of literal value to address
		poke4(entry_addr, peek4u(entry_addr)+lit) 
	    
	    end if
	end if
    end for
    
    SymTab = {}  -- free up some space
    
    -- slist is in run-length compressed form
    -- elements might be atoms (rep count), or 2 or 4 wide sequences
    -- 2-wide means no SRC or OPTIONS (IL from disk)
    
    size = 0
    for i = 1 to length(slist) do
	if sequence(slist[i]) then
	    size += 1
	else
	    size += slist[i]
	end if
    end for
	
    sl = allocate((size+1)*8)
    mem_set(sl, 0, (size+1)*8)
    
    poke4(sl, size)
    addr = sl+8 -- 0th element is ignored - origin 1
    string_size = 0
    
    for i = 1 to length(slist) do
	if sequence(slist[i]) then
	    entry = slist[i]
	    repcount = 1
	else
	    entry = slist[i-1]
	    if length(entry) < 4 then
		entry[1] += 1
	    else
		entry[LINE] += 1
	    end if
	    repcount = slist[i]
	end if
	
	short = length(entry) < 4
	for j = 1 to repcount do
	    poke4(addr+4, entry[LINE-short])  -- hits 4,5,6,7 
					      -- 7 should be 0 unless 16 million
	    poke(addr+6, entry[LOCAL_FILE_NO-short])
	    if not short then
		if entry[SRC] then
		    poke4(addr, all_source[1+floor(entry[SRC]/SOURCE_CHUNK)]
		    +remainder(entry[SRC], SOURCE_CHUNK)) -- store actual address
		end if
		poke(addr+7, entry[OPTIONS]) -- else leave it 0
	    end if
	    addr += 8
	    entry[LINE-short] += 1
	end for
    end for

    slist = {}  -- free up some space
    
    -- store file names and other variables
    other_strings = append(file_name, file_name_entered) & warning_list
    string_size = 0
    for i = 1 to length(other_strings) do
	string_size += length(other_strings[i])+1
    end for
    
    ms = allocate(4*(10+length(other_strings))) -- miscellaneous
    poke4(ms, max_stack_per_call)
    poke4(ms+4, AnyTimeProfile)
    poke4(ms+8, AnyStatementProfile)
    poke4(ms+12, sample_size)
    poke4(ms+16, gline_number)
    poke4(ms+20, il_file)
    poke4(ms+24, length(warning_list))
    poke4(ms+28, length(file_name)) -- stored in 0th position
    
    fn = allocate(string_size)
    
    for i = 1 to length(other_strings) do
	poke4(ms+32+(i-1)*4, fn)
	    
	poke(fn, other_strings[i])
	fn += length(other_strings[i])
	poke(fn, 0)
	fn += 1
    end for

    machine_proc(65, {st, sl, ms, lit})
end procedure

