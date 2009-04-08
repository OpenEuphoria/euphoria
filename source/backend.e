-- (c) Copyright 2007 Rapid Deployment Software - See License.txt

-- Store front-end data structures in memory
-- Called from (a) interpreter front-end
--          or (b) backend.ex (using different s.t. offsets)

include std/machine.e

include global.e
include common.e
include mode.e as mode
include intinit.e
include reswords.e
include error.e
include cominit.e
include compress.e

procedure InitBackEnd(integer x)
	if not BIND then
		intoptions()	
	end if
	
end procedure
mode:set_init_backend( routine_id("InitBackEnd") )

constant ST_ENTRY_SIZE = 60  -- size (bytes) of back-end symbol table entry
							 -- for interpreter. Fixed size for all entries.

constant SOURCE_CHUNK = 10000 -- copied from scanner.e !!

without warning

constant
	ST_OBJ            = 0,
	ST_NEXT           = 4,
	ST_NEXT_IN_BLOCK  = 8,
	ST_MODE           = 12,
	ST_SCOPE          = 13,
	ST_FILE_NO        = 14,
	ST_DUMMY          = 15,
	ST_NAME           = 16,
	ST_TOKEN          = 20,
	ST_CODE           = 24,
	ST_LINETAB        = 28,
	ST_FIRSTLINE      = 32,
	ST_TEMPS          = 36,
	ST_NUM_ARGS       = 40,
	ST_RESIDENT_TASK  = 44,
	ST_SAVED_PRIVATES = 48,
	ST_STACK_SPACE    = 52,
	ST_BLOCK          = 56
	
procedure BackEnd(integer il_file)
-- Store the required front-end data structures in memory.
-- Offsets are used in some places rather than pointers.
-- They will be replaced in the back-end.
	atom addr, st, nm, ms, sl, lit, fn, entry_addr
	atom e_addr, l_addr, no_name, include_info, include_node, include_array
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
			poke4(addr + ST_NEXT, eentry) -- NEXT
			poke(addr + ST_MODE, M_TEMP) -- MODE
			poke(addr + ST_SCOPE, SC_UNDEFINED)  -- SCOPE, must be > S_PRIVATE 
			
		
		else
			poke4(addr + ST_NEXT, eentry[S_NEXT])
			poke4(addr + ST_NEXT_IN_BLOCK, eentry[S_NEXT_IN_BLOCK])
			poke(addr + ST_MODE, eentry[S_MODE])
			poke(addr + ST_SCOPE, eentry[S_SCOPE])

			if length(eentry) >= S_NAME and sequence(eentry[S_NAME]) then
				-- temps and literals have no NAME field
				poke(addr + ST_FILE_NO, eentry[S_FILE_NO])
				poke4(addr + ST_TOKEN, eentry[S_TOKEN])
				string_size += length(eentry[S_NAME])+1
			end if
		
			if eentry[S_MODE] = M_NORMAL then
				-- vars and routines
				
				if find(eentry[S_TOKEN], {PROC, FUNC, TYPE}) then
					-- routines only
					if sequence(eentry[S_CODE]) and (get_backend() or eentry[S_OPCODE]=0) then  
						-- routines with code
						e_addr = allocate(4+4*length(eentry[S_CODE])) -- IL code
						poke4(e_addr, length(eentry[S_CODE]))
						poke4(e_addr+4, eentry[S_CODE])
						poke4(addr + ST_CODE, e_addr)
					
						if sequence(eentry[S_LINETAB]) then
							-- line table
							l_addr = allocate(4*length(eentry[S_LINETAB])) 
							poke4(l_addr, eentry[S_LINETAB])
							poke4(addr + ST_LINETAB, l_addr)
						else
							-- pointer to linetable will be NULL
						end if
					end if
					poke4(addr + ST_FIRSTLINE, eentry[S_FIRSTLINE])
					poke4(addr + ST_TEMPS, eentry[S_TEMPS])
					poke4(addr + ST_NUM_ARGS, eentry[S_NUM_ARGS])
					--
					--
					poke4(addr + ST_STACK_SPACE, eentry[S_STACK_SPACE])
					poke4(addr + ST_BLOCK, eentry[S_BLOCK])
					
				end if
				
			elsif eentry[S_MODE] = M_BLOCK then
				poke4(addr + ST_NEXT_IN_BLOCK, eentry[S_NEXT_IN_BLOCK] )
				poke4(addr + ST_BLOCK, eentry[S_BLOCK])
				
			elsif (length(eentry) < S_NAME and eentry[S_MODE] = M_CONSTANT) or
			(length(eentry) >= S_TOKEN and compare( eentry[S_OBJ], NOVALUE )) then
				-- compress constants and literal values in memory
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
					poke4(entry_addr + ST_NAME, addr) 
					-- store the name string
					poke(addr, eentry[S_NAME])
					addr += length(eentry[S_NAME])
					poke(addr, 0)  -- 0-delimited string
					addr += 1
				
				else
					-- no name
					poke4(entry_addr + ST_NAME, no_name)
				end if
				
				if eentry[S_TOKEN] = NAMESPACE or compare( eentry[S_OBJ], NOVALUE ) then
					-- convert offset to address
					poke4(entry_addr, peek4u(entry_addr)+lit)
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
	
	include_info = allocate( 4 * (1 + length( include_matrix )) ) 
	include_node = include_info
	poke4( include_info, 0 )
	include_node += 4
	
	for i = 1 to length( include_matrix ) do
		
		include_array = allocate( 1 + length( include_matrix ) )
		poke( include_array, i & include_matrix[i] )
		poke4( include_node, include_array )
		
		include_node += 4
	end for

	if Argc > 2 then
		Argv = {Argv[1]} & Argv[3 .. Argc]
	end if
	
	machine_proc(65, {st, sl, ms, lit, include_info, get_switches(), Argv})
end procedure
mode:set_backend( routine_id("BackEnd") )
