-- (c) Copyright - See License.txt

-- Store front-end data structures in memory
-- Called from (a) interpreter front-end
--          or (b) backend.ex (using different s.t. offsets)

ifdef ETYPE_CHECK then
	with type_check
elsedef
	without type_check
end ifdef

include std/dll.e
include std/machine.e
include std/map.e

include global.e
include common.e
include mode.e as mode
include intinit.e
include reswords.e
include error.e
include cominit.e
include compress.e
include symtab.e
include coverage.e
include syncolor.e
include euphoria/symstruct.e

procedure InitBackEnd(integer x)
	if not BIND then
		intoptions()	
	end if
	
end procedure
mode:set_init_backend( routine_id("InitBackEnd") )

constant SOURCE_CHUNK = 10000 -- copied from scanner.e !!


public function get_next( symtab_index sym )
	if get_backend() then
		while sym and 
		((sequence(SymTab[sym]) and sym_scope( sym ) = SC_UNDEFINED) or atom( SymTab[sym] ) ) do
			if sequence(SymTab[sym]) then
				sym = SymTab[sym][S_NEXT]
			else
				sym = SymTab[sym]
			end if
		end while
	else
		while sym and sym_scope( sym ) = SC_UNDEFINED do
			sym = SymTab[sym][S_NEXT]
			
		end while
	end if
	return sym
end function


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
	poke_pointer(st, length(SymTab))
		
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
			poke_pointer(addr + ST_NEXT, get_next( eentry) ) -- NEXT
			poke(addr + ST_MODE, M_TEMP) -- MODE
			poke(addr + ST_SCOPE, SC_UNDEFINED)  -- SCOPE, must be > S_PRIVATE 
			
		
		else
			poke_pointer(addr + ST_NEXT, get_next( eentry[S_NEXT]) )
			poke_pointer(addr + ST_NEXT_IN_BLOCK, eentry[S_NEXT_IN_BLOCK])
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
				
				if find(eentry[S_TOKEN], RTN_TOKS) then
					-- routines only
					if sequence(eentry[S_CODE]) and (get_backend() or eentry[S_OPCODE]=0) then  
						-- routines with code
						e_addr = allocate( sizeof( C_POINTER ) * (length(eentry[S_CODE]) + 1 ) ) -- IL code
						poke_pointer(e_addr, length(eentry[S_CODE]))
						poke_pointer(e_addr + sizeof( C_POINTER ), eentry[S_CODE])
						poke_pointer(addr + ST_CODE, e_addr)
					
						if sequence(eentry[S_LINETAB]) then
							-- line table
							l_addr = allocate( 4 * length(eentry[S_LINETAB])) 
							poke4(l_addr, eentry[S_LINETAB])
							poke_pointer(addr + ST_LINETAB, l_addr)
						else
							-- pointer to linetable will be NULL
						end if
					end if
					poke4(addr + ST_FIRSTLINE, eentry[S_FIRSTLINE])
					poke_pointer(addr + ST_TEMPS, eentry[S_TEMPS])
					poke4(addr + ST_NUM_ARGS, eentry[S_NUM_ARGS])
					--
					--
					poke4(addr + ST_STACK_SPACE, eentry[S_STACK_SPACE])
					poke_pointer(addr + ST_BLOCK, eentry[S_BLOCK])
					
				else
					poke_pointer(addr + ST_DECLARED_IN, eentry[S_BLOCK] )
				end if
				
			elsif eentry[S_MODE] = M_BLOCK then
				poke_pointer(addr + ST_NEXT_IN_BLOCK, eentry[S_NEXT_IN_BLOCK] )
				poke_pointer(addr + ST_BLOCK, eentry[S_BLOCK])
				if length(eentry) >= S_FIRST_LINE then
					poke4(addr + ST_FIRST_LINE, eentry[S_FIRST_LINE] )
					poke4(addr + ST_LAST_LINE, eentry[S_LAST_LINE] )
				end if
				
			elsif (length(eentry) < S_NAME and eentry[S_MODE] = M_CONSTANT) or
			(length(eentry) >= S_TOKEN and compare( eentry[S_OBJ], NOVALUE )) then
				-- compress constants and literal values in memory
				poke_pointer(addr, length(lit_string))  -- record the current offset
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
	nm = alloc_symbol_names( st, lit, string_size )
	poke_pointer( st + ST_NAME, nm )
	
	if not has_coverage() then
		SymTab = {}  -- free up some space
	end if
	
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
		
	sl = allocate( (size + 1) * SL_SIZE )
	mem_set(sl, 0, (size + 1) * SL_SIZE )
	
	poke_pointer(sl, size)
	addr = sl + SL_SIZE -- 0th element is ignored - origin 1
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
		sequence started_file = repeat( 0, length( known_files ) )
		for j = 1 to repcount do
			poke2(addr + SL_LINE, eentry[LINE-short])  -- hits 4,5,6,7 
											  -- 7 should be 0 unless 16 million
			poke(addr + SL_FILE_NO, eentry[LOCAL_FILE_NO-short])
			if not short then
				if eentry[SRC] then
					poke_pointer(addr, all_source[1+floor(eentry[SRC]/SOURCE_CHUNK)]
						+ remainder(eentry[SRC], SOURCE_CHUNK)) -- store actual address
				end if
				poke(addr + SL_OPTIONS, eentry[OPTIONS]) -- else leave it 0
			end if
			if started_file[eentry[LOCAL_FILE_NO-short]] then
				poke4( addr + SL_MULTILINE, -1 )
			else
				poke4( addr + SL_MULTILINE, 0 )
				started_file[eentry[LOCAL_FILE_NO-short]] = 1
			end if
			addr += SL_SIZE
			eentry[LINE-short] += 1
		end for
	end for
	
	if not has_coverage() then
		slist = {}  -- free up some space
	end if
	
	-- store file names and other variables
	other_strings = append(known_files, file_name_entered) & warning_list
	string_size = 0
	for i = 1 to length(other_strings) do
		string_size += length(other_strings[i])+1
	end for
	
	ms = allocate( sizeof( C_POINTER ) * (10 + length(other_strings) ) ) -- miscellaneous
	poke_pointer( ms, {
						max_stack_per_call,
						AnyTimeProfile,
						AnyStatementProfile,
						sample_size,
						gline_number,
						il_file,
						length(warning_list),
						length(known_files),   -- stored in 0th position
						$
						}
				)
	
	fn = allocate(string_size)
	
	for i = 1 to length(other_strings) do
		poke_pointer(ms + 8 * sizeof( C_POINTER ) + (i-1) * sizeof( C_POINTER ), fn)
			
		poke(fn, other_strings[i])
		fn += length(other_strings[i])
		poke(fn, 0)
		fn += 1
	end for
	
	include_info = alloc_include_matrix()

	if Argc > 2 then
		Argv = {Argv[1]} & Argv[3 .. Argc]
	end if

	atom external_debugger_ptr = 0
	if sequence( external_debugger ) then
		external_debugger_ptr = allocate_string( external_debugger )
	end if

	-- M_BACKEND:
	machine_proc(65, 
		{
			st, 
			sl, 
			ms, 
			lit, 
			include_info, 
			get_switches(), 
			Argv,
			routine_id( "cover_line" ),
			routine_id( "cover_routine" ),
			routine_id( "write_coverage_db" ),
			routine_id( "DisplayColorLine" ),
			external_debugger_ptr,
			routine_id( "map:new" ),
			routine_id( "map:put" ),
			routine_id( "map:get" ),
			trace_lines,
			$
		})
end procedure
mode:set_backend( routine_id("BackEnd") )

function alloc_include_matrix()
	atom include_info = allocate( sizeof( C_POINTER ) * (1 + length( include_matrix )) ) 
	atom include_node = include_info
	poke_pointer( include_info, 0 )
	include_node += sizeof( C_POINTER )
	
	for i = 1 to length( include_matrix ) do
		atom include_array = allocate( 1 + length( include_matrix ) )
		poke( include_array, i & include_matrix[i] )
		poke_pointer( include_node, include_array )
		
		include_node += sizeof( C_POINTER )
	end for
	return include_info
end function

function alloc_symbol_names( atom st, atom lit, integer string_size)
-- convert symbol names to C strings in memory
	atom nm = allocate(1+string_size)  
	atom addr = nm
	atom entry_addr = st
	atom no_name = allocate_string("<no-name>")
	for i = 1 to length(SymTab) do
		object eentry = SymTab[i]
		entry_addr += ST_ENTRY_SIZE
		if sequence(eentry) then 
			if length(eentry) >= S_NAME then
				if sequence(eentry[S_NAME]) then
					-- record the address of the name string
					poke_pointer(entry_addr + ST_NAME, addr) 
					-- store the name string
					poke(addr, eentry[S_NAME])
					addr += length(eentry[S_NAME])
					poke(addr, 0)  -- 0-delimited string
					addr += 1
				
				else
					-- no name
					poke_pointer(entry_addr + ST_NAME, no_name)
				end if
				
				if eentry[S_TOKEN] = NAMESPACE or compare( eentry[S_OBJ], NOVALUE ) then
					-- convert offset to address
					poke_pointer(entry_addr, peek_pointer( entry_addr ) + lit )
				end if
			elsif eentry[S_MODE] = M_CONSTANT then
				-- literals - convert offset of literal value to address
				poke_pointer(entry_addr, peek_pointer( entry_addr ) + lit) 
			
			end if
		end if
	end for
	return nm
end function
