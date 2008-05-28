-- (c) Copyright 2007 Rapid Deployment Software - See License.txt

-- Store front-end data structures in memory
-- Called from (a) interpreter front-end
--          or (b) backend.ex (using different s.t. offsets)
include mode.e as mode
include intinit.e
procedure InitBackEnd(integer x)
	if not BIND then
		intoptions()	
	end if
	
end procedure
mode:set_init_backend( routine_id("InitBackEnd") )

constant ST_ENTRY_SIZE = 52  -- size (bytes) of back-end symbol table entry
							 -- for interpreter. Fixed size for all entries.

constant SOURCE_CHUNK = 10000 -- copied from scanner.e !!

without warning

procedure BackEnd(integer il_file)
-- Store the required front-end data structures in memory.
-- Offsets are used in some places rather than pointers.
-- They will be replaced in the back-end.
	atom addr, st, tc, sc, nm, ms, tlt, slt, sl, src, lit, fn, entry_addr
	atom e_addr, l_addr, no_name, sli, include_info, include_node, include_array
	integer string_size, short, size, repcount
	sequence lit_string, other_strings
	object eentry
	
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
		eentry = SymTab[i]
		-- common to temps, vars, routines
		-- +0 (OBJ) is set to literal value by back-end
		-- "constant" variables are initialized with executable code
		if atom(eentry) then
			-- deleted
			poke4(addr+4, eentry) -- NEXT
			poke(addr+8, M_TEMP) -- MODE
			poke(addr+9, SC_UNDEFINED)  -- SCOPE, must be > S_PRIVATE 
		
		else
			poke4(addr+4, eentry[S_NEXT])
			poke(addr+8, eentry[S_MODE])
			poke(addr+9, eentry[S_SCOPE])

			if length(eentry) >= S_NAME and sequence(eentry[S_NAME]) then
				-- temps and literals have no NAME field
				poke(addr+10, eentry[S_FILE_NO])
				poke4(addr+16, eentry[S_TOKEN])
				string_size += length(eentry[S_NAME])+1
			end if
		
			if eentry[S_MODE] = M_NORMAL then
				-- vars and routines
				
				if find(eentry[S_TOKEN], {PROC, FUNC, TYPE}) then
					-- routines only
					if sequence(eentry[S_CODE]) then  
						-- routines with code
						e_addr = allocate(4+4*length(eentry[S_CODE])) -- IL code
						poke4(e_addr, length(eentry[S_CODE]))
						poke4(e_addr+4, eentry[S_CODE])
						poke4(addr+20, e_addr)
					
						if sequence(eentry[S_LINETAB]) then
							-- line table
							l_addr = allocate(4*length(eentry[S_LINETAB])) 
							poke4(l_addr, eentry[S_LINETAB])
							poke4(addr+24, l_addr)
						else
							-- pointer to linetable will be NULL
						end if
					end if
					poke4(addr+28, eentry[S_FIRSTLINE])
					poke4(addr+32, eentry[S_TEMPS])
					poke4(addr+36, eentry[S_NUM_ARGS])
					--
					--
					poke4(addr+48, eentry[S_STACK_SPACE])
				end if
			
			elsif (length(eentry) >= S_TOKEN and eentry[S_TOKEN] = NAMESPACE) or 
				  (length(eentry) < S_NAME and eentry[S_MODE] = M_CONSTANT) then
				-- compress literal values in memory
				poke4(addr, length(lit_string))  -- record the current offset
				lit_string &= compress(eentry[S_OBJ])
		
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
		eentry = SymTab[i]
		entry_addr += ST_ENTRY_SIZE
		if sequence(eentry) then 
			if length(eentry) >= S_NAME then
				if sequence(eentry[S_NAME]) then
					-- record the address of the name string
					poke4(entry_addr+12, addr) 
					-- store the name string
					poke(addr, eentry[S_NAME])
					addr += length(eentry[S_NAME])
					poke(addr, 0)  -- 0-delimited string
					addr += 1
				
					if eentry[S_TOKEN] = NAMESPACE then
						-- convert offset to address
						poke4(entry_addr, peek4u(entry_addr)+lit) 
					end if
				else
					-- no name
					poke4(entry_addr+12, no_name)
				end if  
			
			elsif eentry[S_MODE] = M_CONSTANT then
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
			eentry = slist[i]
			repcount = 1
		else
			eentry = slist[i-1]
			if length(eentry) < 4 then
				eentry[1] += 1
			else
				eentry[LINE] += 1
			end if
			repcount = slist[i]
		end if
		
		short = length(eentry) < 4
		for j = 1 to repcount do
			poke4(addr+4, eentry[LINE-short])  -- hits 4,5,6,7 
											  -- 7 should be 0 unless 16 million
			poke(addr+6, eentry[LOCAL_FILE_NO-short])
			if not short then
				if eentry[SRC] then
					poke4(addr, all_source[1+floor(eentry[SRC]/SOURCE_CHUNK)]
					+remainder(eentry[SRC], SOURCE_CHUNK)) -- store actual address
				end if
				poke(addr+7, eentry[OPTIONS]) -- else leave it 0
			end if
			addr += 8
			eentry[LINE-short] += 1
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
	
	-- include info
	include_info = allocate( 8 )
	include_node = allocate( 8 * (1 + length( file_include ) )) 
	poke4( include_info, length( file_include ) & include_node )
	include_node += 8
	for i = 1 to length( file_include ) do
		
		include_array = allocate( 4 * length( file_include[i] ) )
		poke4( include_array, (file_include[i] ) )
		poke4( include_node, {length(file_include[i]), include_array })
		
		include_node += 8
	end for
	
	machine_proc(65, {st, sl, ms, lit, include_info, get_switches()})
end procedure
mode:set_backend( routine_id("BackEnd") )
