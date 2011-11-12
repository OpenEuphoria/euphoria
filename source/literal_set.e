-- literal set
include std/error.e
include std/pretty.e
include std/math.e
include global.e
include symtab.e
include parser.e
include emit.e
include std/text.e
include std/sequence.e
include std/sort.e

constant METHODS_OTHER_THAN_SEQUENCE_PAIR_ACTUALLY_WORK = 0

with type_check

enum type literal_accessor 
	NAME,
	MAP,
	ACCESS_METHOD,
	NO_FRACTION,
	CONTINUOUS,
	MINIMUM, -- the sym_index that attains the lowest value
	MAXIMUM, -- the sym_index that attains the higest value
	DATA_SYMBOL,
	UDT_SYMBOL,
	MONOTONIC,
	$
end type

export type enum access_method
	INDEX_MAP,
	SEQUENCE_PAIR
end type

export type literal_set(object x)
	if length(x)=10 then
		return sequence(x[NAME]) and sequence(x[MAP]) and access_method(x[ACCESS_METHOD]) and symtab_index(x[DATA_SYMBOL])
	else
		return 0
	end if
end type

export function set_udt(literal_set ls, symtab_index udt)
	ls[UDT_SYMBOL] = udt
	return ls
end function

export function get_udt(literal_set ls)
	return ls[UDT_SYMBOL]
end function

export function is_monotonic( literal_set ls )
	return ls[MONOTONIC]
end function

export function is_continuous( literal_set ls )
	return ls[CONTINUOUS]
end function

export function get_minimal( literal_set ls )
	return ls[MINIMUM]
end function

export function get_maximal( literal_set ls )
	return ls[MAXIMUM]
end function


export function get_access_method( literal_set ls )
	return ls[ACCESS_METHOD]
end function

constant binary_to_128 = {1,2,4,8,16,32,64,128}
constant binary_to_2__32 = binary_to_128 & 256 * binary_to_128 & power(2,16) * binary_to_128 * power(2,24) * binary_to_128 -- the geometric series going up by 2 that constains exactly 32 members from 1 to power(2,31)

 -- a binary series that must contain at least the bits up to that that can be contained in an integer
ifdef E32 or EU4_0 then
	constant binary_sequence = binary_to_2__32
	constant integer_bits = 30
elsifdef E64 then
	constant binary_sequence = binary_to_2__32 & #1_0000_0000 * binary_to_2__32
	constant integer_bits = 62
end ifdef

function bit_complexity(object x)
	if integer(x) then
		return sum(and_bits(binary_sequence,x) != 0)
	elsif sequence(x) then
		integer sum = 0
		for i = 1 to length(x) do
			sum += bit_complexity(x[i])
		end for
		return sum
    end if
end function

function compare_complexity(symtab_index a, symtab_index b)
	return compare(bit_complexity(sym_obj(a)),bit_complexity(sym_obj(b)))
end function

function logical_and_all(sequence s)
	integer ans = 1
	for i = 1 to length(s) do
		if sequence(s[i]) then
			ans = ans and logical_and_all(s[i])
		else
			ans = ans and s[i]
		end if
	end for
	return ans
end function

-- creates a flag set and returns it or returns 0 if it cannot create a flag set.
export function new(
	sequence type_name, 
	sequence syms,      -- a sequence of valid symtab indexes
	integer flag_flag   -- if true the enum set is a flag set.
	)
	integer all_integers = 1 -- true if all of the constants in syms are integers.
	object value_set = 0 -- used as a bit set for seeing which integers are attained in syms.
	symtab_index min_sym, max_sym -- the DATA_SYMBOLs with the minimal and maximal value 
	object min_obj, max_obj -- the minimal and maximal object
	integer min_obj_i, max_obj_i -- the indeces of the min and max values
	integer ciif_min, ciif_max -- the DATA_SYMBOLs of the min and max of an numeric integer interval which includes the first value. 
	symtab_index symbol
	integer direction = 0
	integer monotonic_flag = 1
	
	-- if flag_flag = 1 then
		-- warning("Flag aspect with name_of is not yet supported for type enums")
	-- end if
	-----------------------------------------------------------
	-- Gather summary information about the values of the syms
	-----------------------------------------------------------
	if length(syms) then
		if sym_mode(syms[1]) != M_CONSTANT then
			return 0 -- failure
		end if
		min_sym = syms[1]
		max_sym = syms[1]
		ciif_min = syms[1]
		ciif_max = syms[1]
		if length(syms) > 1 then
			direction = compare(sym_obj(syms[1]),sym_obj(syms[2]))
		end if
	end if
	for i = 1 to length( syms ) do
		if sym_mode(syms[i]) != M_CONSTANT then
			return 0
		end if
		if i > 2 and compare(sym_obj(syms[i-1]),sym_obj(syms[i])) != direction then
			monotonic_flag = 0
		end if
		object val_i = sym_obj(syms[i])
		if sequence(val_i) or floor(val_i) != val_i then
			all_integers = 0
		end if
		if all_integers then
			if val_i = sym_obj(ciif_min)-1 then
				ciif_min = syms[i]
			elsif val_i = sym_obj(ciif_max)+1 then
				ciif_max = syms[i]
			end if
		end if
		if (not all_integers) or 0 > val_i or val_i >= integer_bits then
			value_set = {}
		elsif atom(value_set) then
			value_set = or_bits(value_set,shift_bits(1,-val_i))
		end if
		if compare(sym_obj(min_sym),sym_obj(syms[i])) > 0 then
			min_sym = syms[i]
		end if
		if compare(sym_obj(syms[i]),sym_obj(max_sym)) > 0 then
			max_sym = syms[i]
		end if
	end for
	
	max_obj = sym_obj(max_sym)
	min_obj = sym_obj(min_sym)
	-- post conditions:
	-- all DATA_SYMBOLs are not forward referenced and are constants with a value that is already known by this point
	-- min_sym is the DATA_SYMBOL constant with the lowest value
	-- max_sym is the DATA_SYMBOL constant with the highest value
	-- min_obj is the smallest value these constants
	-- max_obj is the largest value of these constants
	-- all_integers is true if and only if all of these constants
	-- have no fraction part.
	-- value_set is {} if any of the values are out of range of 1 to integer_bits
	-- If none of the values are out of the range 1..integer_bits, then and_bits(values,shift_bits(1,-n)) is true if and only if the values attained in the DATA_SYMBOLs includes this value, n for each n>=0.  This relation ship is used	to detect integer intervals starting from 1..integer_bits.

	
	----------------------------------------------------------
	-- Determine which data structure to use taking advantage of this particular set.
	----------------------------------------------------------
	-- -- if the set could be a list of flags (including sequences for going over the 60 bit limit)	
	-- if METHODS_OTHER_THAN_SEQUENCE_PAIR_ACTUALLY_WORK
		-- and flag_flag and ((all_integers and 
		-- -binary_sequence[integer_bits+1] <= min_obj and
		-- max_obj < binary_sequence[integer_bits+1])
			-- or
		-- (logical_and_all(-binary_sequence[integer_bits+1] <= min_obj)
			-- or
			-- logical_and_all(max_obj < binary_sequence[integer_bits+1]))
		-- )
		-- then
			-- -- we don't handle numbers that are bigger than its integer type and no floats but we do allow sequences.
			-- if not all_integers then
				-- for i = 1 to length(syms) do
					-- if not binop_ok(sym_obj(syms[1]),sym_obj(syms[i])) then
						-- -- failure:
						-- return 0
					-- end if
				-- end for
			-- end if
			-- sequence list = custom_sort( routine_id("compare_complexity"), syms )
			-- symbol = NewStringSym(list)
			-- return {type_name, list, BINARY_SET, all_integers, 0, min_sym, max_sym, symbol, 0, 0}
	-- els
	if METHODS_OTHER_THAN_SEQUENCE_PAIR_ACTUALLY_WORK and all_integers then
		-- This is not a list of flags but all integers and we know thus the values do not attain values out of the range from 1 to some value less than integer_bits.  Access should be done via an indexing of a sequence if the index_set wouldn't be too sparse looking.  If the number of 0's exceeds the twice the number of entries we wont bother with an index_set and instead use a leaner sequence_pair.
		if min_obj > 0 and max_obj < 3*length(syms) then
			sequence index_map = repeat(0,max_obj)
			for i = 1 to length(syms) do
				index_map[sym_obj(syms[i])] = {i,sym_name(syms[i])}
			end for
			symbol = NewStringSym(index_map)
			if atom(value_set) and and_bits(value_set,1)=0 and find(or_bits(value_set,1)+1, binary_sequence) then
				-- The values sequences attain all values, mark it as continuous
				return {type_name, index_map, INDEX_MAP, all_integers, 1, min_sym, max_sym, symbol, 0, monotonic_flag}
			else
				return {type_name, index_map, INDEX_MAP, all_integers, 0, min_sym, max_sym, symbol, 0, monotonic_flag}
			end if
		else
			-- all values are integers but they are too big 
		end if
	end if
	
	sequence list = {{},{}}
	for i = 1 to length(syms) do
		list = {append(list[1],sym_obj(syms[i])),append(list[2],sym_name(syms[i]))}
	end for
	symbol = NewSequenceSym(list)
	-- Failing all else we can always use a pair of sequences with the
	-- keys in the first sequence and the names in the other.
	return {type_name, list, SEQUENCE_PAIR, all_integers, 0, min_sym, max_sym, symbol, 0, monotonic_flag}
end function

-- emits code for type checking.  Done in parser.e for now
procedure emit_type_function_body(literal_set s)
	symtab_index seq_sym
end procedure


-- emits the data structure for the name_of builtin.
export function emit_literals_data_structure(literal_set s)
	return s[DATA_SYMBOL]
end function

-- emits the code to access the data structure when the name_of builtin is used.
export function get_data_structure_symbol(literal_set s)
	return s[DATA_SYMBOL]
end function

procedure not_impl()
	crash("Not yet implemented.")
end procedure

-- Returns the C code to set the value in a specific symbol from a value in the literal set.
-- This provides us with a way of populating the other variables with the exactly the same
-- numbers in the C code when they share the same value in the EUPHORIA code.  As long as it
-- is a part of ls.  If value is not in the literal set an empty string is returned.
export function set_value_code(literal_set ls, object value, symtab_index source)
	integer vl =  find(value, ls[MAP][1])
	if not vl then
		return ""
	end if
	if ls[ACCESS_METHOD] != SEQUENCE_PAIR then
		return "" -- not implemented for non SEQUENCE_PAIR literal_sets
	end if
	if length(SymTab[ls[DATA_SYMBOL]]) < S_TEMP_NAME then
		return ""
	end if
	symtab_index ds = SymTab[ls[DATA_SYMBOL]][S_TEMP_NAME]
	
	return  
	sprintf("\tRef(SEQ_PTR(SEQ_PTR(_%d)->base[%d])->base[%d]);\n" &
            "\t_%d = SEQ_PTR(SEQ_PTR(_%d)->base[%d])->base[%d];\n", 
		    {ds, 1, vl, 
		     SymTab[source][S_TEMP_NAME], ds, 1, vl})
end function

export function first_assign_value_code(literal_set ls, sequence str, object x)
 	symtab_index ds = SymTab[ls[DATA_SYMBOL]][S_TEMP_NAME]
	if ls[ACCESS_METHOD] = SEQUENCE_PAIR then
		integer vl = find(x,ls[MAP][1])
		if vl then
			return 
				sprintf("\tRef(SEQ_PTR(SEQ_PTR(_%d)->base[%d])->base[%d]);\n" &
            "\t%s = SEQ_PTR(SEQ_PTR(_%d)->base[%d])->base[%d];\n", 
		    {ds, 1, vl, 
		    str, ds, 1, vl})
		end if
	end if
	return ""
end function

export function get_literal_code(symtab_index sym)
	not_impl()
	return 0
end function

-- get a literal for the value at parse time
-- if there is no enum literal it returns 0.
export function get_literal(literal_set s, object value)
	integer k
	object name = 0
	switch s[ACCESS_METHOD] do
		case  SEQUENCE_PAIR then
			k = find(value,s[MAP][1])
			if k > 0 then
				name = s[MAP][2][k]
			end if
		case INDEX_MAP then
		-- must be INDEX_MAP
			if integer(value) and value < length(s[MAP]) and value > 0 then
				name = s[MAP][value]
			end if
	end switch
	return name
end function

export function get_map(literal_set s)
	return s[MAP]
end function
