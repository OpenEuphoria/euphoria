-- (c) Copyright - See License.txt

-- Store front-end data structures in memory
-- Called from (a) interpreter front-end
--          or (b) backend.ex (using different s.t. offsets)

ifdef ETYPE_CHECK then
	with type_check
elsedef
	without type_check
end ifdef

include std/machine.e
include std/os.e

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

procedure InitBackEnd(integer x)
	if not BIND then
		intoptions()	
	end if
	
end procedure
mode:set_init_backend( routine_id("InitBackEnd") )

constant ST_ENTRY_SIZE_32 = 60 -- size (bytes) of back-end symbol table entry
							   -- for interpreter. Fixed size for all entries.
							   -- assumes 32-bit word size
-- struct sline {      /* source line table entry */
-- 	char *src;               /* text of line, 
-- 								first 4 bytes used for count when profiling */
-- 	unsigned short line;     /* line number within file */
-- 	unsigned char file_no;   /* file number */
-- 	unsigned char options;   /* options in effect: */
integer 
	SIZEOF_POINTER = 4,
	SIZEOF_SLINE  = 8,
	SLINE_SRC     = 0,
	SLINE_LINE    = 4,
	SLINE_FILE_NO = 6,
	SLINE_OPTIONS = 7
	

ifdef UNIX then
	integer ST_ENTRY_SIZE = ST_ENTRY_SIZE_32
	
	integer
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
	
	-- hack until we have a defined word for the architecture
	if find( "x86_64", uname() ) then
		SIZEOF_POINTER = 8
		
		SIZEOF_SLINE  = 16
		SLINE_LINE    = 8
		SLINE_FILE_NO = 10
		SLINE_OPTIONS = 11
		
		ST_ENTRY_SIZE = 120
		
		ST_NEXT           = 8
		ST_NEXT_IN_BLOCK  = 16
		ST_MODE           = 24
		ST_SCOPE          = 25
		ST_FILE_NO        = 26
		ST_DUMMY          = 27
		ST_NAME           = 32
		ST_TOKEN          = 40 -- int
		ST_CODE           = 48
		ST_LINETAB        = 56
		ST_FIRSTLINE      = 64
		ST_TEMPS          = 72
		ST_NUM_ARGS       = 80
		ST_RESIDENT_TASK  = 88
		ST_SAVED_PRIVATES = 96
		ST_STACK_SPACE    = 104
		ST_BLOCK          = 112
	end if
	
	-- this is a hack for 64-bit systems until the infrastructure catches up
	-- to make this more elegant
	procedure poke_pointer( atom addr, object val )
		if ST_ENTRY_SIZE = ST_ENTRY_SIZE_32 then
			poke4( addr, val )
			return
		end if
		
		if sequence(val) then
			for i = 1 to length(val) do
				poke_pointer( addr, val[i] )
				addr += SIZEOF_POINTER
			end for
			return
		end if
		poke4( addr, val )
		poke4( addr + 4, floor( val / 0x100000000 ) )
	end procedure

	function peek_pointer( object addr )
		if ST_ENTRY_SIZE = ST_ENTRY_SIZE_32 then
			return peek4u( addr )
		end if
		
		if sequence(addr) then
			sequence val = {}
			
			return val
		end if
		return peek4u( addr ) + peek4u( addr + 4 ) * power( 2, 32 )
	end function
	
elsedef
	constant ST_ENTRY_SIZE = ST_ENTRY_SIZE_32
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

	procedure poke_pointer( atom addr, object val )
		poke4( addr, val )
	end procedure
	
	function peek_pointer( object addr )
		return peek4u( addr )
	end function
	

end ifdef



constant SOURCE_CHUNK = 10000 -- copied from scanner.e !!



function get_next( symtab_index sym )
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
				poke4(addr + ST_TOKEN, eentry[S_TOKEN]) -- C int
				string_size += length(eentry[S_NAME])+1
			end if
		
			if eentry[S_MODE] = M_NORMAL then
				-- vars and routines
				
				if find(eentry[S_TOKEN], RTN_TOKS) then
					-- routines only
					if sequence(eentry[S_CODE]) and (get_backend() or eentry[S_OPCODE]=0) then  
						-- routines with code
						e_addr = allocate( SIZEOF_POINTER + SIZEOF_POINTER * length(eentry[S_CODE])) -- IL code
						poke_pointer(e_addr, length(eentry[S_CODE]))
						poke_pointer(e_addr + SIZEOF_POINTER, eentry[S_CODE])
						poke_pointer(addr + ST_CODE, e_addr)
					
						if sequence(eentry[S_LINETAB]) then
							-- line table
							l_addr = allocate( SIZEOF_POINTER * length(eentry[S_LINETAB])) 
							poke_pointer(l_addr, eentry[S_LINETAB])
							poke_pointer(addr + ST_LINETAB, l_addr)
						else
							-- pointer to linetable will be NULL
						end if
					end if
					poke_pointer(addr + ST_FIRSTLINE, eentry[S_FIRSTLINE])
					poke_pointer(addr + ST_TEMPS, eentry[S_TEMPS])
					poke_pointer(addr + ST_NUM_ARGS, eentry[S_NUM_ARGS])
					--
					--
					poke_pointer(addr + ST_STACK_SPACE, eentry[S_STACK_SPACE])
					poke_pointer(addr + ST_BLOCK, eentry[S_BLOCK])
					
				end if
				
			elsif eentry[S_MODE] = M_BLOCK then
				poke_pointer(addr + ST_NEXT_IN_BLOCK, eentry[S_NEXT_IN_BLOCK] )
				poke_pointer(addr + ST_BLOCK, eentry[S_BLOCK])
				
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
					poke_pointer(entry_addr, peek_pointer(entry_addr) + lit)
				end if
			elsif eentry[S_MODE] = M_CONSTANT then
				-- literals - convert offset of literal value to address
				poke_pointer(entry_addr, peek_pointer(entry_addr)+lit) 
			
			end if
		end if
	end for
	
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
	
-- 	struct sline {      /* source line table entry */
-- 	char *src;               /* text of line, 
-- 								first 4 bytes used for count when profiling */
-- 	unsigned short line;     /* line number within file */
-- 	unsigned char file_no;   /* file number */
-- 	unsigned char options; 
	sl = allocate((size+1) * SIZEOF_SLINE)
	mem_set(sl, 0, (size + 1 ) * SIZEOF_SLINE)
	
	poke_pointer(sl, size)
	addr = sl + SIZEOF_SLINE -- 0th element is ignored - origin 1
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
			poke2(addr + SLINE_LINE, eentry[LINE-short])  -- hits 4,5,6,7 
											  -- 7 should be 0 unless 16 million
			poke(addr + SLINE_FILE_NO, eentry[LOCAL_FILE_NO-short])
			if not short then
				if eentry[SRC] then
					poke_pointer(addr, 
						all_source[1 + floor( eentry[SRC] / SOURCE_CHUNK)]
						+ remainder( eentry[SRC], SOURCE_CHUNK) ) -- store actual address
					
				end if
				poke(addr + SLINE_OPTIONS, eentry[OPTIONS]) -- else leave it 0
			end if
			addr += SIZEOF_SLINE
			eentry[LINE-short] += 1
		end for
	end for
	
	if not has_coverage() then
		slist = {}  -- free up some space
	end if
	
	-- store file names and other variables
	other_strings = append(file_name, file_name_entered) & warning_list
	string_size = 0
	for i = 1 to length(other_strings) do
		string_size += length(other_strings[i])+1
	end for
	
	ms = allocate( SIZEOF_POINTER * ( 10 + length(other_strings))) -- miscellaneous
	poke_pointer(ms, max_stack_per_call)
	poke_pointer(ms + SIZEOF_POINTER, AnyTimeProfile)
	poke_pointer(ms + SIZEOF_POINTER * 2, AnyStatementProfile)
	poke_pointer(ms + SIZEOF_POINTER * 3, sample_size)
	poke_pointer(ms+ SIZEOF_POINTER * 4, gline_number)
	poke_pointer(ms+ SIZEOF_POINTER * 5, il_file)
	poke_pointer(ms + SIZEOF_POINTER * 6, length(warning_list))
	poke_pointer(ms + SIZEOF_POINTER * 7, length(file_name)) -- stored in 0th position
	
	fn = allocate(string_size)
	
	for i = 1 to length(other_strings) do
		poke_pointer(ms + (i + 7) * SIZEOF_POINTER, fn)
			
		poke(fn, other_strings[i])
		fn += length(other_strings[i])
		poke(fn, 0)
		fn += 1
	end for
	
	include_info = allocate( SIZEOF_POINTER * (1 + length( include_matrix )) ) 
	include_node = include_info
	poke_pointer( include_info, 0 )
	include_node += SIZEOF_POINTER
	
	for i = 1 to length( include_matrix ) do
		
		include_array = allocate( 1 + length( include_matrix ) )
		poke( include_array, i & include_matrix[i] )
		poke_pointer( include_node, include_array )
		
		include_node += SIZEOF_POINTER
	end for

	if Argc > 2 then
		Argv = {Argv[1]} & Argv[3 .. Argc]
	end if
	
	machine_proc(65, {st, sl, ms, lit, include_info, get_switches(), Argv })
end procedure
mode:set_backend( routine_id("BackEnd") )
