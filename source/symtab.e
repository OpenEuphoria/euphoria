-- (c) Copyright - See License.txt
--
-- Symbol Table Routines

ifdef ETYPE_CHECK then
	with type_check
elsedef
	without type_check
end ifdef

include std/search.e
include std/filesys.e

include global.e
include c_out.e
include keylist.e
include error.e
include fwdref.e
include reswords.e
include block.e
include msgtext.e
include error.e

export constant NBUCKETS = 2003  -- prime helps

export sequence buckets = repeat(0, NBUCKETS + 1)  -- hash buckets
export symtab_index object_type       -- s.t. index of object type
export symtab_index atom_type         -- s.t. index of atom type
export symtab_index sequence_type     -- s.t. index of sequence type
export symtab_index integer_type      -- s.t. index of integer type

ifdef EUDIS then
export sequence bucket_hits = repeat( 0, NBUCKETS ) -- count how many times we look at each bucket
end ifdef

export symtab_index literal_init = 0
export integer last_sym = 0

sequence lastintval = {}, lastintsym = {}
sequence e_routine  = {}  -- sequence of symbol table pointers for routine_id

export function hashfn(sequence name)
-- hash function for symbol table
	integer len
	integer val -- max is 268,448,190+len
	integer int

	len = length(name)
	
	val = name[1]
	int = name[$]
	int *= 256
	val *= 2
	val += int + len
	
	if len = 3 then
		val *= 32
		int = name[2]
		val += int
	elsif len > 3 then
		val *= 32
		int = name[2]
		val += int
		
		val *= 32
		int = name[$-1]
		val += int
	end if
	return remainder(val, NBUCKETS) + 1
end function

-- take a symbol out of the chain of hashes, which effectively hides it from
-- ever being found
export procedure remove_symbol( symtab_index sym )
	integer hash
	integer st_ptr
	
	hash = SymTab[sym][S_HASHVAL]
	st_ptr = buckets[hash]
	
	while st_ptr and st_ptr != sym do
		st_ptr = SymTab[st_ptr][S_SAMEHASH]
	end while
	
	if st_ptr then
		if st_ptr = buckets[hash] then
			-- it was the last one, and in the bucket
			buckets[hash] = SymTab[st_ptr][S_SAMEHASH]
		else
			-- we're somewhere in the chain
			SymTab[st_ptr][S_SAMEHASH] = SymTab[sym][S_SAMEHASH]
		end if
	end if
end procedure

-- creates a new symbol entry, but does not add it to the hash table,
-- nor connect it in the S_NEXT chain
export function NewBasicEntry(sequence name, integer varnum, integer scope,
				  integer token, integer hashval, symtab_index samehash,
				  symtab_index type_sym )
	
	sequence new
	
	if TRANSLATE then
		new = repeat(0, SIZEOF_ROUTINE_ENTRY)
	else
		new = repeat(0, SIZEOF_VAR_ENTRY)
	end if

	new[S_NEXT] = 0
	new[S_NAME] = name
	new[S_SCOPE] = scope
	new[S_MODE] = M_NORMAL
	new[S_USAGE] = U_UNUSED
	new[S_FILE_NO] = current_file_no

	if TRANSLATE then
		-- initialize extra fields for Translator
		new[S_GTYPE] = TYPE_OBJECT
		new[S_GTYPE_NEW] = TYPE_NULL

		new[S_SEQ_ELEM] = TYPE_OBJECT
		new[S_SEQ_ELEM_NEW] = TYPE_NULL -- starting point for ORing

		new[S_ARG_TYPE] = TYPE_OBJECT
		new[S_ARG_TYPE_NEW] = TYPE_NULL
		new[S_ARG_SEQ_ELEM] = TYPE_OBJECT
		new[S_ARG_SEQ_ELEM_NEW] = TYPE_NULL

		new[S_ARG_MIN] = NOVALUE
		new[S_ARG_MIN_NEW] = -NOVALUE

		new[S_ARG_SEQ_LEN] = NOVALUE
		new[S_ARG_SEQ_LEN_NEW] = -NOVALUE

		new[S_SEQ_LEN] = NOVALUE
		new[S_SEQ_LEN_NEW] = -NOVALUE -- no idea yet

		new[S_NREFS] = 0
		new[S_ONE_REF] = TRUE          -- assume TRUE until we find otherwise
		new[S_RI_TARGET] = 0

		new[S_OBJ_MIN] = MININT
		new[S_OBJ_MIN_NEW] = -NOVALUE -- no idea yet

		new[S_OBJ_MAX] = MAXINT
		new[S_OBJ_MAX_NEW] = -NOVALUE -- missing from C code? (not needed)
	end if

	new[S_TOKEN] = token
	new[S_VARNUM] = varnum
	new[S_INITLEVEL] = -1
	new[S_VTYPE] = type_sym
	
	new[S_HASHVAL] = hashval
	new[S_SAMEHASH] = samehash
	
	new[S_OBJ] = NOVALUE -- important

	-- add new symbol to the end of the symbol table
	SymTab = append(SymTab, new)
	
	return length(SymTab)
end function

export function NewEntry(sequence name, integer varnum, integer scope,
				  integer token, integer hashval, symtab_index samehash,
				  symtab_index type_sym )
-- Enter a symbol into the table at the next available position
	symtab_index new = NewBasicEntry( name, varnum, scope, token, hashval, samehash, type_sym )

	
	if last_sym then
		SymTab[last_sym][S_NEXT] = new
	end if
	last_sym = new
	if type_sym < 0 then
		register_forward_type( last_sym, type_sym )
	end if
	return last_sym
end function

constant BLANK_ENTRY = repeat(0, SIZEOF_TEMP_ENTRY)

export function tmp_alloc()
-- return SymTab index for a new temporary var/literal constant
	sequence new_entry = repeat( 0, SIZEOF_TEMP_ENTRY )
	
	
	
	new_entry[S_USAGE] = T_UNKNOWN

	if TRANSLATE then
		new_entry[S_GTYPE] = TYPE_OBJECT
		new_entry[S_OBJ_MIN] = MININT
		new_entry[S_OBJ_MAX] = MAXINT
		new_entry[S_SEQ_LEN] = NOVALUE
		new_entry[S_SEQ_ELEM] = TYPE_OBJECT  -- other fields set later
		if length(temp_name_type)+1 = 8087 then
			-- don't use _8087 - it conflicts with WATCOM
			temp_name_type = append(temp_name_type, {0, 0})
		end if
		temp_name_type = append(temp_name_type, TYPES_OBNL)
		new_entry[S_TEMP_NAME] = length(temp_name_type)
	end if
	
	SymTab = append(SymTab, new_entry )

	return length( SymTab )
end function

function PrivateName(sequence name, symtab_index proc)
-- does name match that of a private in the current active proc?
	symtab_index s

	s = proc[S_NEXT] -- start at next entry
	while s and s[S_SCOPE] <= SC_PRIVATE do
		if equal(name, SymTab[s][S_NAME]) then
			return TRUE
		end if
		s = SymTab[s][S_NEXT]
	end while
	return FALSE
end function

export procedure DefinedYet(symtab_index sym)
-- make sure sym has not been defined yet, except possibly as
-- a predefined symbol, or a global in a previous file
	if not find(SymTab[sym][S_SCOPE],
				{SC_UNDEFINED, SC_MULTIPLY_DEFINED, SC_PREDEF}) then
		if SymTab[sym][S_FILE_NO] = current_file_no then
			CompileErr(31, {SymTab[sym][S_NAME]})
		end if
	end if
end procedure

export function name_ext(sequence s)
-- Returns the file name & extension part of a path.
-- Note: both forward slash and backslash are handled for all platforms.
	for i = length(s) to 1 by -1 do
		if find(s[i], "/\\:") then
			return s[i+1 .. $]
		end if
	end for

	return s
end function

constant SEARCH_LIMIT = 20 + 500 * (TRANSLATE or BIND)

export function NewStringSym(sequence s)
-- create a new temp that holds a string
	symtab_index p, tp, prev
	integer search_count

	-- check if it exists already
	tp = literal_init
	prev = 0
	search_count = 0
	while tp != 0 do
		search_count += 1
		if search_count > SEARCH_LIMIT then  -- avoid n-squared algorithm
			exit
		end if
		if equal(s, SymTab[tp][S_OBJ]) then
			-- move it to first on list
			if tp != literal_init then
				SymTab[prev][S_NEXT] = SymTab[tp][S_NEXT]
				SymTab[tp][S_NEXT] = literal_init
				literal_init = tp
			end if
			return tp
		end if
		prev = tp
		tp = SymTab[tp][S_NEXT]
	end while

	p = tmp_alloc()
	SymTab[p][S_OBJ] = s

	if TRANSLATE then
		SymTab[p][S_MODE] = M_TEMP    -- override CONSTANT for compile
		SymTab[p][S_GTYPE] = TYPE_SEQUENCE
		SymTab[p][S_SEQ_LEN] = length(s)
		if SymTab[p][S_SEQ_LEN] > 0 then
			SymTab[p][S_SEQ_ELEM] = TYPE_INTEGER
		else
			SymTab[p][S_SEQ_ELEM] = TYPE_NULL
		end if
		c_printf("int _%d;\n", SymTab[p][S_TEMP_NAME])
		c_hprintf("extern int _%d;\n", SymTab[p][S_TEMP_NAME])

	else
		SymTab[p][S_MODE] = M_CONSTANT

	end if

	SymTab[p][S_NEXT] = literal_init
	literal_init = p
	return p
end function

export function NewIntSym(integer int_val)
-- New integer symbol
-- int_val must not be too big for a Euphoria int
	symtab_index p
	integer x

	x = find(int_val, lastintval)
	if x then
		return lastintsym[x]  -- saves space, helps Translator reduce code size

	else
		p = tmp_alloc()
		SymTab[p][S_MODE] = M_CONSTANT
		SymTab[p][S_OBJ] = int_val

		if TRANSLATE then
			SymTab[p][S_OBJ_MIN] = int_val
			SymTab[p][S_OBJ_MAX] = int_val
			SymTab[p][S_GTYPE] = TYPE_INTEGER
		end if

		lastintval = prepend(lastintval, int_val)
		lastintsym = prepend(lastintsym, p)
		if length(lastintval) > SEARCH_LIMIT then
			lastintval = lastintval[1..floor(SEARCH_LIMIT/2)]
		end if
		return p
	end if
end function

export function NewDoubleSym(atom d)
-- allocate space for a new double literal value at compile-time
	symtab_index p, tp, prev
	integer search_count

	-- check if it exists already
	tp = literal_init
	prev = 0
	search_count = 0
	while tp != 0 do
		search_count += 1
		if search_count > SEARCH_LIMIT then  -- avoid n-squared algorithm
			exit
		end if
		if equal(d, SymTab[tp][S_OBJ]) then
			-- found it
			if tp != literal_init then
				-- move it to first on list
				SymTab[prev][S_NEXT] = SymTab[tp][S_NEXT]
				SymTab[tp][S_NEXT] = literal_init
				literal_init = tp
			end if
			return tp
		end if
		prev = tp
		tp = SymTab[tp][S_NEXT]
	end while

	p = tmp_alloc()
	SymTab[p][S_MODE] = M_CONSTANT
	SymTab[p][S_OBJ] = d

	if TRANSLATE then
		SymTab[p][S_MODE] = M_TEMP  -- override CONSTANT for compile
		SymTab[p][S_GTYPE] = TYPE_DOUBLE
		c_printf("int _%d;\n", SymTab[p][S_TEMP_NAME])
		c_hprintf("extern int _%d;\n", SymTab[p][S_TEMP_NAME])
	end if

	SymTab[p][S_NEXT] = literal_init
	literal_init = p
	return p
end function

export integer temps_allocated   -- number of temps allocated for CurrentSub
temps_allocated = 0

export function NewTempSym( integer inlining = 0)
-- allocate a new temp and link it with the list of temps
-- for the current subprogram
	symtab_index p, q
	
	if inlining then
		p = SymTab[CurrentSub][S_TEMPS]
		while p != 0 and SymTab[p][S_SCOPE] != FREE do
			p = SymTab[p][S_NEXT]
		end while
	else
		p = 0
	end if
	
	if p = 0 then
		-- no free temps available
		temps_allocated += 1
		p = tmp_alloc()
		SymTab[p][S_MODE] = M_TEMP
		SymTab[p][S_NEXT] = SymTab[CurrentSub][S_TEMPS]
		SymTab[CurrentSub][S_TEMPS] = p
		
		if inlining then
			SymTab[CurrentSub][S_STACK_SPACE] += 1
		end if

	elsif TRANSLATE then
		-- found a free temp - make another with same name,
		-- add it to the list, and "delete" the first one

		-- remove p from the list
		SymTab[p][S_SCOPE] = DELETED

		q = tmp_alloc()
		SymTab[q][S_MODE] = M_TEMP
		SymTab[q][S_TEMP_NAME] = SymTab[p][S_TEMP_NAME]
		SymTab[q][S_NEXT] = SymTab[CurrentSub][S_TEMPS]
		SymTab[CurrentSub][S_TEMPS] = q
		p = q
	end if

	if TRANSLATE then
		SymTab[p][S_GTYPE] = TYPE_OBJECT
		SymTab[p][S_SEQ_ELEM] = TYPE_OBJECT
	end if

	SymTab[p][S_OBJ] = NOVALUE
	SymTab[p][S_USAGE] = T_UNKNOWN
	SymTab[p][S_SCOPE] = IN_USE
--	Block_var( p )
	return p
end function

export procedure InitSymTab()
-- Initialize the Symbol Table
	integer hashval, len
	--register symtab_index *bptr
	symtab_index s,st_index
	sequence kname, fixups = {}

	for k = 1 to length(keylist) do
		kname = keylist[k][K_NAME]
		len = length(kname)
		hashval = hashfn(kname)
		st_index = NewEntry(kname,
							0,
							keylist[k][K_SCOPE],
							keylist[k][K_TOKEN],
							hashval, 0, 0)
		if find(keylist[k][K_TOKEN], RTN_TOKS) then
			SymTab[st_index] = SymTab[st_index] &
						repeat(0, SIZEOF_ROUTINE_ENTRY -
								  length(SymTab[st_index]))
			SymTab[st_index][S_NUM_ARGS] = keylist[k][K_NUM_ARGS]
			SymTab[st_index][S_OPCODE] = keylist[k][K_OPCODE]
			SymTab[st_index][S_EFFECT] = keylist[k][K_EFFECT]
			SymTab[st_index][S_REFLIST] = {}
			if length(keylist[k]) > K_EFFECT then
			    SymTab[st_index][S_CODE] = keylist[k][K_CODE]
			    SymTab[st_index][S_DEF_ARGS] = keylist[k][K_DEF_ARGS]
			    fixups &= st_index
			end if
		end if
		if keylist[k][K_TOKEN] = PROC then
			if equal(kname, "<TopLevel>") then
				TopLevelSub = st_index
			end if
		elsif keylist[k][K_TOKEN] = TYPE then
			if equal(kname, "object") then
				object_type = st_index
			elsif equal(kname, "atom") then
				atom_type = st_index
			elsif equal(kname, "integer") then
				integer_type = st_index
			elsif equal(kname, "sequence") then
				sequence_type = st_index
			end if
		end if
		if buckets[hashval] = 0 then
			buckets[hashval] = st_index
		else
			s = buckets[hashval]
			while SymTab[s][S_SAMEHASH] != 0 do
				s = SymTab[s][S_SAMEHASH]
			end while
			SymTab[s][S_SAMEHASH] = st_index
		end if
	end for
	file_start_sym = length(SymTab)
	-- interpret token sequences for builtin defparms
	sequence si, sj
	CurrentSub = TopLevelSub
	for i=1 to length(fixups) do
	    si = SymTab[fixups[i]][S_CODE] -- seq of either 0's or sequences of tokens
	    for j=1 to length(si) do
	        if sequence(si[j]) then
	            sj = si[j] -- a sequence of tokens
				for ij=1 to length(sj) do
	                switch sj[ij][T_ID] with fallthru do
	                    case ATOM then -- must create a lasting temp
	                    	if integer(sj[ij][T_SYM]) then
								st_index = NewIntSym(sj[ij][T_SYM])
							else
								st_index = NewDoubleSym(sj[ij][T_SYM])
							end if
							SymTab[st_index][S_SCOPE] = IN_USE -- TempKeep()
							sj[ij][T_SYM] = st_index
							break
						case STRING then -- same
	                    	st_index = NewStringSym(sj[ij][T_SYM])
							SymTab[st_index][S_SCOPE] = IN_USE -- TempKeep()
							sj[ij][T_SYM] = st_index
							break
						case BUILT_IN then -- name of a builtin in econd field
                            sj[ij] = keyfind(sj[ij][T_SYM],-1)
							break
						case DEF_PARAM then
							sj[ij][T_SYM] &= fixups[i]
					end switch
				end for
				si[j] = sj
			end if
		end for
		SymTab[fixups[i]][S_CODE] = si
	end for
end procedure

export procedure add_ref(token tok)
-- BIND only: add a reference to a symbol from the current routine
	symtab_index s

	s = tok[T_SYM]
	if s != CurrentSub and -- ignore self-ref's
		  not find(s,  SymTab[CurrentSub][S_REFLIST]) then
		-- new reference
		SymTab[s][S_NREFS] += 1
		SymTab[CurrentSub][S_REFLIST] &= s
	end if
end procedure

integer just_mark_everything_from = 0
procedure mark_all( integer attribute )
	-- mark all visible routines parsed so far
	if just_mark_everything_from then
		symtab_pointer p = SymTab[just_mark_everything_from][S_NEXT]
		while p != 0 do
			integer sym_file = SymTab[p][S_FILE_NO]
			just_mark_everything_from = p
			if sym_file = current_file_no or find( sym_file, recheck_files ) then
				SymTab[p][attribute] += 1
			else
				integer scope = SymTab[p][S_SCOPE]
				switch scope with fallthru do
					case SC_PUBLIC then
						if and_bits( DIRECT_OR_PUBLIC_INCLUDE, include_matrix[current_file_no][sym_file] ) then
							SymTab[p][attribute] += 1
						end if
						break
					case SC_EXPORT then
						if not and_bits( DIRECT_INCLUDE, include_matrix[current_file_no][sym_file] ) then
							break
						end if
						-- fallthrough
					case SC_GLOBAL then
						SymTab[p][attribute] += 1
						
				end switch
			end if
			p = SymTab[p][S_NEXT]
		end while
	end if
end procedure

sequence recheck_targets = {}
sequence recheck_files = {}

export procedure mark_final_targets()
	if just_mark_everything_from then
		if TRANSLATE then
			mark_all( S_RI_TARGET )
		elsif BIND then
			mark_all( S_NREFS )
		end if
	elsif length( recheck_targets ) then
		
		for i = length( recheck_targets ) to 1 by -1 do
			integer marked = 0
			if TRANSLATE then
				marked = MarkTargets( recheck_targets[i], S_RI_TARGET )
			elsif BIND then
				marked = MarkTargets( recheck_targets[i], S_NREFS )
			end if
			
			if marked then
				recheck_targets = remove( recheck_targets, i )
			end if
		end for
	end if
end procedure

function is_routine( symtab_index sym )
	integer tok = sym_token( sym )
	switch tok do
		case FUNC, PROC, TYPE then
			return 1
		case else
			return 0
	end switch
end function

function is_visible( symtab_index sym, integer from_file )
	integer scope = sym_scope( sym )
	integer sym_file = SymTab[sym][S_FILE_NO]
	integer visible_mask
	switch scope do
		case SC_PUBLIC then
			visible_mask = DIRECT_OR_PUBLIC_INCLUDE
		case SC_EXPORT then
			visible_mask = DIRECT_INCLUDE
		case SC_GLOBAL then
			return 1
		case else
			return from_file = sym_file
	end switch
	return and_bits( visible_mask, include_matrix[from_file][sym_file] )
end function


export function MarkTargets(symtab_index s, integer attribute)
-- Note the possible targets of a routine id call
	symtab_index p
	sequence sname
	sequence string
	integer colon, h
	integer scope
	
	if (SymTab[s][S_MODE] = M_TEMP or
		SymTab[s][S_MODE] = M_CONSTANT) and
		sequence(SymTab[s][S_OBJ]) then
		-- hard-coded string
		
		integer found = 0
		
		string = SymTab[s][S_OBJ]
		colon = find(':', string)
		if colon = 0 then
			sname = string
		else
			sname = string[colon+1..$]  -- ignore namespace part
			while length(sname) and sname[1] = ' ' or sname[1] = '\t' do
				sname = tail( sname, length( sname ) -1 )
			end while
		end if

		if length(sname) = 0 then
			return 1
		end if
		h = buckets[hashfn(sname)]
		while h do
			if equal(sname, SymTab[h][S_NAME]) then
				if attribute = S_NREFS then
					if BIND then
						add_ref({PROC, h})
					end if
				elsif is_routine( h ) and is_visible( h, current_file_no ) then
					SymTab[h][attribute] += 1
					if current_file_no = SymTab[h][S_FILE_NO] then
						found = 1
					end if
				end if
			end if
			h = SymTab[h][S_SAMEHASH]
		end while
		
		if not found then
			just_mark_everything_from = TopLevelSub
			recheck_targets &= s
			if not find( current_file_no, recheck_files ) then
				recheck_files &= current_file_no
			end if
		end if
		return found
	else
		if not just_mark_everything_from then
			just_mark_everything_from = TopLevelSub
		end if
		mark_all( attribute )
		return 1
	end if
end function

export sequence dup_globals, dup_overrides, in_include_path

-- remember which files have gotten warnings already to avoid issuing too many
sequence include_warnings
include_warnings = {}

-- remember which built-ins chosen warnings have already been issued to avoid too many
sequence builtin_warnings
builtin_warnings = {}

ifdef STDDEBUG then
-- remember which files have gotten warnings already to too many
sequence export_warnings
export_warnings = {}
end ifdef

-- Prevent (or allow) unincluded globals from being resolved in favor of
-- forward references in files that haven't been fully parsed yet.
integer Resolve_unincluded_globals = 0
export procedure resolve_unincluded_globals( integer ok )
	Resolve_unincluded_globals = ok
end procedure

export function get_resolve_unincluded_globals()
	return Resolve_unincluded_globals
end function

export integer No_new_entry = 0
export function keyfind(sequence word, integer file_no, integer scanning_file = current_file_no, integer namespace_ok = 0, 
						integer hashval = hashfn( word ) )
-- Uses hashing algorithm to try to match 'word' in the symbol
-- table. If not found, 'word' must be a new user-defined identifier.
-- If file_no is not -1 then file_no must match and symbol must be a GLOBAL.
-- namespace_ok: 0 => ignore namespaces, 1 => ignore everything but namespaces,
--              -1 => look at everything, and find the best resolution (probably a case statement)
--
-- If No_new_entry is true and we cannot resolve the symbol for word, it returns
-- {IGNORED,word,scope,symbols}, word being the word passed in, scope being a scope error value and symbols being 
-- a sequence of symbols that matched word.  In this case, the only possible values for scope are scope constants
-- that begin with SC_* and symbols are a set of symtab_indeces.

	sequence msg, b_name
	integer scope, defined, ix
	symtab_index st_ptr, st_builtin
	token tok, gtok
	
	dup_globals = {}
	dup_overrides = {}
	in_include_path = {}
	symbol_resolution_warning = ""
	st_builtin = 0

	ifdef EUDIS then
		bucket_hits[hashval] += 1
	end ifdef
	st_ptr = buckets[hashval]
	integer any_symbol = namespace_ok = -1
	while st_ptr do
		if SymTab[st_ptr][S_SCOPE] != SC_UNDEFINED 
		and equal(word, SymTab[st_ptr][S_NAME]) 
		and ( any_symbol or ( namespace_ok = (SymTab[st_ptr][S_TOKEN] = NAMESPACE) ) ) then
			-- name matches

			tok = {SymTab[st_ptr][S_TOKEN], st_ptr}

			if file_no = -1 then
				-- unqualified

				-- Consider: S_PREDEF

				scope = SymTab[st_ptr][S_SCOPE]

				switch scope with fallthru do
				case SC_OVERRIDE then
					dup_overrides &= st_ptr
					break
					
				case SC_PREDEF then
					st_builtin = st_ptr
					break
				case SC_GLOBAL then
					if scanning_file = SymTab[st_ptr][S_FILE_NO] then
						-- found global in current file

						if BIND then
							add_ref(tok)
						end if

						return tok
					end if

					-- found global in another file
					if Resolve_unincluded_globals 
					or (finished_files[scanning_file]
					and include_matrix[scanning_file][SymTab[st_ptr][S_FILE_NO]]) -- everything this file needs has been read in
					or SymTab[st_ptr][S_TOKEN] = NAMESPACE then -- this allows the eu: namespace to work
						gtok = tok
						dup_globals &= st_ptr
						in_include_path &= include_matrix[scanning_file][SymTab[st_ptr][S_FILE_NO]] != 0
					end if
					break
					-- continue looking for more globals with same name

				case SC_PUBLIC, SC_EXPORT then

					if scanning_file = SymTab[st_ptr][S_FILE_NO] then
						-- found export in current file
						if BIND then
							add_ref(tok)
						end if

						return tok
					end if

					if (finished_files[scanning_file] -- everything this file needs has been read in
						or (namespace_ok and SymTab[st_ptr][S_TOKEN] = NAMESPACE)) -- resolve name spaces..probably shouldn't, but not sure how to get around this
						and ((scope = SC_PUBLIC and  -- now we can look into the include relationship...
							and_bits( DIRECT_OR_PUBLIC_INCLUDE, include_matrix[scanning_file][SymTab[st_ptr][S_FILE_NO]] ))
							or (scope = SC_EXPORT and
							and_bits( DIRECT_INCLUDE, include_matrix[scanning_file][SymTab[st_ptr][S_FILE_NO]] )))
					then
						-- found public or export in another file 
						gtok = tok
						dup_globals &= st_ptr
						in_include_path &= include_matrix[scanning_file][SymTab[st_ptr][S_FILE_NO]] != 0 --symbol_in_include_path( st_ptr, scanning_file, {} )
					
					end if
ifdef STDDEBUG then
					if not and_bits( DIRECT_OR_PUBLIC_INCLUDE, include_matrix[scanning_file][SymTab[st_ptr][S_FILE_NO]] ) and
						include_matrix[scanning_file][SymTab[st_ptr][S_FILE_NO]] != 0 --symbol_in_include_path( st_ptr, scanning_file, {} )  
					then 
						gtok = tok
						dup_globals &= st_ptr
						in_include_path &= 0
						if not find( {scanning_file,SymTab[tok[T_SYM]][S_FILE_NO]}, export_warnings ) then
							
							export_warnings = prepend( export_warnings,
								{ scanning_file, SymTab[tok[T_SYM]][S_FILE_NO] })
							
							symbol_resolution_warning = GetMsgText(232, 0, 
										{name_ext(known_files[scanning_file]),
										 name_ext(known_files[SymTab[tok[T_SYM]][S_FILE_NO]])})

						end if
						
						
					end if
end ifdef
					break
				case SC_LOCAL then
					if scanning_file = SymTab[st_ptr][S_FILE_NO] then
						-- found local in current file

						if BIND then
							add_ref(tok)
						end if

						return tok
					end if
					break
				case else

					if BIND then
						add_ref(tok)
					end if

					return tok -- keyword, private

				end switch

			else
				-- qualified - must match global symbol in specified file (or be in the file's
				-- include path)
				scope = SymTab[tok[T_SYM]][S_SCOPE]
				if not file_no then
					-- internal eu namespace was used
					if scope = SC_PREDEF then
						if BIND then
							add_ref( tok )
						end if
						return tok
					end if
				else
					integer tok_file = SymTab[tok[T_SYM]][S_FILE_NO]
					integer good = 0
					if scope = SC_PRIVATE or scope = SC_PREDEF then
						-- ignore this one
						
					elsif file_no = tok_file then
						good = 1
					else
						-- globals and publics can come from a file included by the namespace file
						integer include_type = 0
						switch scope do
							case SC_GLOBAL then
								if Resolve_unincluded_globals then
									include_type = ANY_INCLUDE
								else
									include_type = DIRECT_OR_PUBLIC_INCLUDE
								end if
								
							case SC_PUBLIC then
								
								if tok_file != file_no then
									include_type = PUBLIC_INCLUDE
								else
									include_type = DIRECT_OR_PUBLIC_INCLUDE
								end if
								
						end switch
						good = and_bits( include_type, include_matrix[file_no][tok_file] )
					end if
					
					if good then
				
						if file_no = tok_file then
							if BIND then
								add_ref(tok)
							end if
							return tok
						end if
	
						gtok = tok
						dup_globals &= st_ptr
						in_include_path &= include_matrix[scanning_file][tok_file] != 0
					end if
				end if
			end if

			-- otherwise keep looking
		end if

		st_ptr = SymTab[st_ptr][S_SAMEHASH]
	end while

	if length(dup_overrides) then
		st_ptr = dup_overrides[1]
		tok = {SymTab[st_ptr][S_TOKEN], st_ptr}

		--if length(dup_overrides) = 1 then
			if BIND then
				add_ref(tok)
			end if

			return tok
--		end if

	elsif st_builtin != 0 then
		if length(dup_globals) and find(SymTab[st_builtin][S_NAME], builtin_warnings) = 0 then
			sequence msg_file 
			
			b_name = SymTab[st_builtin][S_NAME]
			builtin_warnings = append(builtin_warnings, b_name)
			
			if length(dup_globals) > 1 then
				msg = "\n"
			else
				msg = ""
			end if
			-- Get list of files...
			for i = 1 to length(dup_globals) do
				msg_file = known_files[SymTab[dup_globals[i]][S_FILE_NO]]
				msg &= "    " & msg_file & "\n"
			end for

			Warning(234, builtin_chosen_warning_flag, {b_name, known_files[scanning_file], msg})
		end if

		tok = {SymTab[st_builtin][S_TOKEN], st_builtin}

		if BIND then
			add_ref(tok)
		end if

		return tok
	end if

ifdef STDDEBUG then
	if length(dup_globals) > 1 and not find( 1, in_include_path ) then
		-- filter out possibly erroneous exports that may have snuck in
		integer dx = 1
		while dx <= length( dup_globals ) do
			if SymTab[dup_globals[dx]][S_SCOPE] = SC_EXPORT then
				dup_globals = remove( dup_globals, dx )
				in_include_path = remove( in_include_path, dx )
			else
				dx += 1
			end if
		end while
	end if
end ifdef

	if length(dup_globals) > 1 and find( 1, in_include_path ) then
		-- filter out based on include path
		ix = 1
		while ix <= length(dup_globals) do
			if in_include_path[ix] then
				ix += 1
			else
				dup_globals     = remove( dup_globals, ix )
				in_include_path = remove( in_include_path, ix )
			end if
		end while

		if length(dup_globals) = 1 then
				st_ptr = dup_globals[1]
				gtok = {SymTab[st_ptr][S_TOKEN], st_ptr}
		end if
	end if

ifdef STDDEBUG then
	if length( dup_globals ) = 1 and in_include_path[1] = 0 and length( symbol_resolution_warning ) then
		-- Turn this into an export warning, so pretend that it's included
		in_include_path[1] = 1
	else
		symbol_resolution_warning = ""
	end if
end ifdef

	if length(dup_globals) = 1 and st_builtin = 0 then
		-- matched exactly one global

		if BIND then
			add_ref(gtok)
		end if
		if not in_include_path[1] and
				not find( {scanning_file,SymTab[gtok[T_SYM]][S_FILE_NO]}, include_warnings )
		then
			include_warnings = prepend( include_warnings,
				{ scanning_file, SymTab[gtok[T_SYM]][S_FILE_NO] })
ifdef STDDEBUG then
				if SymTab[gtok[T_SYM]][S_SCOPE] = SC_EXPORT then
				-- we've already issued an export warning, don't need to add this one
					return gtok
				end if
end ifdef
				symbol_resolution_warning = GetMsgText(233,0,
									{name_ext(known_files[scanning_file]), 
									 line_number,
									 word,
									 name_ext(known_files[SymTab[gtok[T_SYM]][S_FILE_NO]])
									 })
		end if
		return gtok
	end if

	-- couldn't find unique one
	if length(dup_globals) = 0 then
		defined = SC_UNDEFINED
		
		if fwd_line_number then
			last_ForwardLine     = ForwardLine
			last_forward_bp      = forward_bp
			last_fwd_line_number = fwd_line_number
		end if

		ForwardLine = ThisLine
		forward_bp = bp
		fwd_line_number = line_number
	
	elsif length(dup_globals) then
		defined = SC_MULTIPLY_DEFINED
	elsif length(dup_overrides) then
		defined = SC_OVERRIDE
	end if
	
	if No_new_entry then
		return {IGNORED,word,defined,dup_globals}
	end if

	tok = {VARIABLE, NewEntry(word, 0, defined,
					   VARIABLE, hashval, buckets[hashval], 0)}
	buckets[hashval] = tok[T_SYM]
	
	if file_no != -1 then
		SymTab[tok[T_SYM]][S_FILE_NO] = file_no
	end if
	return tok  -- no ref on newly declared symbol
end function


export procedure Hide(symtab_index s)
-- remove the visibility of a symbol
-- by deleting it from its hash chain
	symtab_index prev, p
	
	p = buckets[SymTab[s][S_HASHVAL]]
	prev = 0
	
	while p != s and p != 0 do
		prev = p
		p = SymTab[p][S_SAMEHASH]
	end while
	
	if p = 0 then
		return -- already hidden
	end if
	if prev = 0 then
		buckets[SymTab[s][S_HASHVAL]] = SymTab[s][S_SAMEHASH]
	else
		SymTab[prev][S_SAMEHASH] = SymTab[s][S_SAMEHASH]
	end if
	SymTab[s][S_SAMEHASH] = 0
end procedure

export procedure Show(symtab_index s)
-- restore the visibility of a symbol
-- by adding it to its hash chain
	symtab_index p
	
	p = buckets[SymTab[s][S_HASHVAL]]
	
	if SymTab[s][S_SAMEHASH] or p = s then
		-- already visible
		return
	end if
	
	SymTab[s][S_SAMEHASH] = p
	buckets[SymTab[s][S_HASHVAL]] = s
	
end procedure

export procedure hide_params( symtab_index s )
	symtab_index param = s
	for i = 1 to SymTab[s][S_NUM_ARGS] do
		param = SymTab[s][S_NEXT]
		Hide( param )
	end for
end procedure

export procedure show_params( symtab_index s )
	symtab_index param = s
	for i = 1 to SymTab[s][S_NUM_ARGS] do
		param = SymTab[s][S_NEXT]
		Show( param )
	end for
end procedure

export procedure LintCheck(symtab_index s)
-- do some lint-like checks on s
	integer warn_level
	sequence file
	integer vscope
	sequence vname
	integer vusage 
	
	vusage = SymTab[s][S_USAGE]
	vscope = SymTab[s][S_SCOPE]
	vname = SymTab[s][S_NAME]
	
	switch vusage do

		case U_UNUSED then
			warn_level = 1
		
		case U_WRITTEN then -- Set but never read
			warn_level = 2
			
			if vscope > SC_LOCAL then
				-- Exposed vars/consts can be read by other files.
				warn_level = 0 
			end if
		
		case U_READ then -- Read but never set
			if SymTab[s][S_VARNUM] >= SymTab[CurrentSub][S_NUM_ARGS] then
		    	warn_level = 3
		    else
		    	-- Assume parameters have been assigned on entry.
		    	warn_level = 0
		    end if
	    	
	    case else
	    	warn_level = 0
	end switch

	if warn_level = 0 then
		return
	end if
	

	file = abbreviate_path(known_files[current_file_no])
	if warn_level = 3 then
		if vscope = SC_LOCAL then
			if current_file_no = SymTab[s][S_FILE_NO] then
				Warning(226, no_value_warning_flag, {file,  vname})
			end if
		else
			Warning(227, no_value_warning_flag, {file,  vname, SymTab[CurrentSub][S_NAME]})
		end if			
	else
		if vscope = SC_LOCAL then
			if current_file_no = SymTab[s][S_FILE_NO] then
				if SymTab[s][S_MODE] = M_CONSTANT then
					Warning(228, not_used_warning_flag, {file,  vname})
					
				elsif warn_level = 1 then
					Warning(229, not_used_warning_flag, {file,  vname})
					
				else
					Warning(320, not_used_warning_flag, {file,  vname})
				end if
			end if	
		else
			if SymTab[s][S_VARNUM] < SymTab[CurrentSub][S_NUM_ARGS] then
				-- Parameters
				if warn_level = 1 then
					if Strict_is_on then
						-- Only issue this warning if -strict is in play.
						Warning(230, not_used_warning_flag, {file,  vname, SymTab[CurrentSub][S_NAME]})
					end if
				else -- elsif warn_level = 2 then
					Warning(321, not_used_warning_flag, {file,  vname, SymTab[CurrentSub][S_NAME]})
				end if
			else
				-- Private Vars
				if warn_level = 1 then
					Warning(231, not_used_warning_flag, {file,  vname, SymTab[CurrentSub][S_NAME]})
				else -- elsif warn_level = 2 then
					Warning(322, not_used_warning_flag, {file,  vname, SymTab[CurrentSub][S_NAME]})
				end if
			end if
		end if
	end if

end procedure

export procedure HideLocals()
-- hide the local symbols and "lint" check them
	symtab_index s

	s = file_start_sym
	while s do
		if SymTab[s][S_SCOPE] = SC_LOCAL and
		   SymTab[s][S_FILE_NO] = current_file_no then
			Hide(s)
			if SymTab[s][S_TOKEN] = VARIABLE then
				LintCheck(s)
			end if
		end if
		s = SymTab[s][S_NEXT]
	end while
end procedure

export function sym_name( symtab_index sym )
	return SymTab[sym][S_NAME]
end function

export function sym_token( symtab_index sym )
	return SymTab[sym][S_TOKEN]
end function

export function sym_scope( symtab_index sym )
	return SymTab[sym][S_SCOPE]
end function

export function sym_mode( symtab_index sym )
	return SymTab[sym][S_MODE]
end function

export function sym_obj( symtab_index sym )
	return SymTab[sym][S_OBJ]
end function

export function sym_next( symtab_index sym )
	return SymTab[sym][S_NEXT]
end function

export function sym_block( symtab_index sym )
	return SymTab[sym][S_BLOCK]
end function

export function sym_next_in_block( symtab_index sym )
	return SymTab[sym][S_NEXT_IN_BLOCK]
end function

export function sym_usage( symtab_index sym )
	return SymTab[sym][S_USAGE]
end function


export function calc_stack_required( symtab_index sub )
	integer required = SymTab[sub][S_NUM_ARGS]
	integer arg = SymTab[sub][S_NEXT]
	
	for i = 1 to required do
		arg = SymTab[arg][S_NEXT]
	end for
	
	-- count the privates
	while arg != 0 and SymTab[arg][S_SCOPE] <= SC_PRIVATE do
		required += 1
		arg = SymTab[arg][S_NEXT]
	end while
	
	-- count the temps
	arg = SymTab[sub][S_TEMPS]
	while arg != 0 do
		required += 1
		arg = SymTab[arg][S_NEXT]
	end while
	
	return required
end function
