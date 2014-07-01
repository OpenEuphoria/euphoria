-- (c) Copyright - See License.txt
--
-- Global declarations

public integer repl = 0
-- hack, this just happens to be larger than the largest possible
-- open file handle that eu:open() can return
public constant repl_file = 5555

ifdef ETYPE_CHECK then
	with type_check
elsedef
	without type_check
end ifdef

public include std/types.e 
public include common.e
include mode.e as mode
include reswords.e
public include msgtext.e

export constant
	INTERPRET = mode:get_interpret(),
	TRANSLATE = mode:get_translate(),
	BIND      = mode:get_bind()

export constant
	EXTRA_CHECK = mode:get_extra_check()

-- specific C compiler used (one may be TRUE)
export constant
	EWATCOM  = TRUE
	-- (assume GNU C for Unix variants)

export constant EGPM = 0     -- GPM mouse support on Linux

export integer con -- Windows console option for BIND
export integer type_i -- for type checking where in the array a failure occured

export sequence version_name
ifdef WINDOWS then
	version_name = "Windows"
elsifdef LINUX then
	version_name = "Linux"
elsifdef OPENBSD then
	version_name = "OpenBSD"
elsifdef NETBSD then
	version_name = "NetBSD"
elsifdef OSX then
	version_name = "Mac OS X"
elsifdef FREEBSD then
	version_name = "FreeBSD"
elsifdef UNIX then  --should never happen
	version_name = "UNIX"
end ifdef

-- common fields for all symbols, literal constants and temporaries
export enum
	S_OBJ,   -- initialized for literal constants
	         -- NOVALUE for other temps
	         -- run time object (vars)
	         -- must be first field in C
	S_NEXT,  -- index of next temp, or next var, or 0
	S_MODE,  -- M_NORMAL, M_TEMP, M_CONSTANT or M_BLOCK
	S_SCOPE, -- for temps at compile time: FREE or IN_USE,
	         -- or DELETED (Translator-only)
	         -- for variables see "Scope Values" below
	S_USAGE  -- for temps: type T_UNKNOWN or T_INTEGER
	         -- for vars, read/written/to be deleted
	

-- extra fields for vars (and routines) only but not temps
export constant
	S_NEXT_IN_BLOCK = 6 - get_backend(), --  Linked list of vars in a block
	S_FILE_NO = 7 - get_backend(), -- file number where symbol is defined
	S_NAME = 8 - get_backend(),    -- name string
	S_SAMEHASH = 9,                -- index of next symbol with same hash value
	S_TOKEN = 10 - get_backend()*2, -- token number to return to parser
	S_HASHVAL = 11,                -- hash value
	S_NREFS = 12,                  -- number of references to this symbol
	S_CODE = 13 - get_backend()*4  -- IL code for proc/func/type

-- canned tokens for defaulted routine parameters
-- for vars only (although S_VTYPE is used for any kind of variable):
export constant
	
	S_INITLEVEL = 14, -- nesting level where initialized or -1
	S_VTYPE = 15,     -- variable type or NULL
	S_VARNUM = 16,    -- local variable number
	
	S_BLOCK = 17 - get_backend() * 7 -- Either the containing scope for a var or the main scope for a routine

-- for blocks only:
export constant
	S_FIRST_LINE = 18 - get_backend() * 7,  -- first line of the block
	S_LAST_LINE  = 19 - get_backend() * 7   -- last line of the block

-- for routines only:
export constant
	S_LINETAB = 18 - get_backend()*7,      -- Line table for traceback
	S_FIRSTLINE = 19 - get_backend()*5,    -- global line number of start of routine
	S_TEMPS = 20 - get_backend()*8,        -- pointer to linked list of temps, or 0
	S_OPCODE = 21,                         -- opcode to emit (predefined subprograms)
	S_NUM_ARGS = 22 - get_backend()*9,     -- number of arguments
	S_EFFECT = 23,                         -- side effects
	S_REFLIST = 24,                        -- list of referenced symbols (for BIND)
	S_RESIDENT_TASK = 25,                  -- the task that's currently using this routine
	                                       -- (at run-time) or 0 if none
	S_SAVED_PRIVATES = 26,                 -- private data of any suspended tasks
	                                       -- executing this routine
	S_STACK_SPACE = 27 - get_backend()*12, -- amount of stack space needed by this routine
	                                       -- (for private data)
	S_DEF_ARGS = 28,                       -- {index of first defaulted arg in a routine, last
	                                       -- nondef, list of middle defaulted params}
	                                       -- or 0 if none
	S_INLINE = 29,                         -- 0 if routine cannot be inlined, or sequence of
	                                       -- inline code if it can
	S_DEPRECATED = 30
	

-- extra fields for TRANSLATOR (for temps and vars/routines)
export constant
	S_OBJ_MIN = 30,   -- minimum integer value
	S_OBJ_MAX = 31,   -- maximum integer value
	S_SEQ_LEN = 32,   -- length of a sequence
	S_SEQ_ELEM = 33,  -- type of all elements of a sequence, or
	                  -- type returned by a function/type
	S_TEMP_NAME = 34, -- for temps: number to use in the outputted C name
	S_ONE_REF = 35,   -- TRUE if we see that a variable can only ever have
	                  -- 1 reference count
	S_GTYPE = 36      -- current global idea of what the worst-case type is

-- extra fields for TRANSLATOR (for vars/routines only)
export constant
	S_LHS_SUBS2 = 37,        -- routine does double or more LHS subscripting
	S_GTYPE_NEW = 38,        -- new idea being formed of global type
	S_SEQ_LEN_NEW = 39,      -- new idea being formed of length of a sequence
	S_SEQ_ELEM_NEW = 40,     -- new type being formed on a pass

	S_OBJ_MIN_NEW = 41,      -- new integer value
	S_OBJ_MAX_NEW = 42,      -- new integer value

	S_ARG_TYPE = 43,         -- argument type info, stable and new versions
	S_ARG_TYPE_NEW = 44,

	S_ARG_SEQ_ELEM = 45,
	S_ARG_SEQ_ELEM_NEW = 46,

	S_ARG_MIN = 47,          -- argument min/max integers or NOVALUE or -NOVALUE
	S_ARG_MAX = 48,
	S_ARG_MIN_NEW = 49,
	S_ARG_MAX_NEW = 50,

	S_ARG_SEQ_LEN = 51,
	S_ARG_SEQ_LEN_NEW = 52,
	S_RI_TARGET = 53,        -- > 0 if targeted by a routine_id call or other
	                         -- external call, e.g. call to a DLL
	S_HAS_DELETE = 54

export procedure print_sym(integer s)
	printf(1,"[%d]:\n", {s} )
	object s_obj = SymTab[s][S_OBJ]
	if equal(s_obj,NOVALUE) then 
		puts(1,"S_OBJ=>NOVALUE\n")
	else
		puts(1,"S_OBJ=>")
		? s_obj		
	end if
	puts(1,"S_MODE=>")
	switch SymTab[s][S_MODE] do
		case M_NORMAL then
			puts(1,"M_NORMAL")
		case M_TEMP then
			puts(1,"M_TEMP")
		case M_CONSTANT then
			puts(1,"M_CONSTANT")
		case M_BLOCK then
			puts(1,"M_BLOCK")
	end switch
	puts(1,{10,10})
end procedure
	
		
export constant
	SIZEOF_ROUTINE_ENTRY = 30 + 25 * TRANSLATE,
	SIZEOF_VAR_ENTRY     = 17 + 37 * TRANSLATE,
	SIZEOF_BLOCK_ENTRY   = 19 + 35 * TRANSLATE,
	SIZEOF_TEMP_ENTRY    =  6 + 32 * TRANSLATE

-- Permitted values for various symbol table fields

-- MODE values:
export enum
	M_NORMAL,    -- all variables
	M_CONSTANT,  -- literals and declared constants
	M_TEMP,      -- temporaries
	M_BLOCK      -- code block for scoping variables

export constant M_VARS = {M_TEMP, M_NORMAL}
	
-- SCOPE values:
export enum
	SC_LOOP_VAR=2,    -- "private" loop vars known within a single loop
	SC_PRIVATE,    -- private within subprogram
	SC_GLOOP_VAR,   -- "global" loop var
	SC_LOCAL,    -- local to the file
	SC_GLOBAL,    -- global across all files
	SC_PREDEF,    -- predefined symbol - could be overriden
	SC_KEYWORD,    -- a keyword
	SC_UNDEFINED,   -- new undefined symbol
	SC_MULTIPLY_DEFINED,  -- global symbol defined in 2 or more files
	SC_EXPORT,   -- visible to anyone that includes the file
	SC_OVERRIDE, -- override an internal
	SC_PUBLIC    -- visible to any file that includes it, or via "public include"

-- USAGE values          -- how symbol has been used (1,2 can be OR'd)
export enum
	U_UNUSED  = 0,
	U_READ    = 1,
	U_WRITTEN = 2,
	U_USED    = 3,
	U_FORWARD = 4,
	U_DELETED = 99   -- we've decided to delete this symbol


-- Does a routine have an effect other than just returning a value?
-- We use 30 bits of information (to keep it in integer range).
-- Bits 0..28 give a rough indication of which local/global vars execution of
-- a routine might directly or indirectly modify. This helps to optimize a rare
-- situation when assigning to a multiply-subscripted sequence.
-- Bit 29 indicates all other side effects (I/O, task scheduling etc.)
export constant
	E_PURE = 0,   -- routine has no side effects
	E_SIZE = 29,  -- number of bits for screening out vars
	E_OTHER_EFFECT = power(2, E_SIZE),  -- routine has other effects, e.g. I/O
	E_ALL_EFFECT = #3FFFFFFF -- all bits (0..29) are set,
							 -- unspecified globals might be changed
							 -- plus other effects

export enum
	FREE = 0,
	IN_USE,
	DELETED

-- result types
export enum
	T_INTEGER,
	T_SEQUENCE,
	T_ATOM,
	T_UNKNOWN

export enum
	MIN,
	MAX

constant
	max_int32 = #3FFFFFFF

ifdef not EU4_0 then
	atom ptr = machine_func( 16, 8 )
		poke( ptr, { 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x3f } )
		constant
			max_int64 = peek8s( ptr )
		machine_proc( 17, ptr )
elsedef
	constant
		max_int64 = max_int32
end ifdef

ifdef BITS64 then
	export constant
		SIZEOF_POINTER = 8,
		max_int        = max_int64,
		$
elsedef
	export constant
		SIZEOF_POINTER = 4,
		max_int        = max_int32,
		$
end ifdef

public integer TARGET_SIZEOF_POINTER = SIZEOF_POINTER

export constant
	MAXINT = max_int,
	MININT = -MAXINT-1,   -- should be -ve
	MININT_DBL = MININT,
	MAXINT_DBL = MAXINT

export atom
	TMAXINT,
	TMININT,
	TMININT_DBL,
	TMAXINT_DBL

export procedure set_target_integer_size( integer sizeof_pointer )
	if sizeof_pointer = 4 then
		TMAXINT = max_int32
	else
		TMAXINT = max_int64
	end if
	
	TMININT = -TMAXINT - 1
	TMAXINT_DBL = TMAXINT
	TMININT_DBL = TMININT
end procedure
set_target_integer_size( SIZEOF_POINTER )

export function is_integer( object o )
	if not atom( o ) then
		return 0
	end if
	
	if o = floor( o ) then
		if o <= TMAXINT and o >= TMININT then
			return 1
		end if
	end if
	return 0
end function

export constant NOVALUE = -1.295837195871e307
-- An unlikely number. If it occurs naturally,  there will be a slight loss of optimization
-- as we will not know the value of a variable at compile time. (NaN could be used, but it's
-- not 100% portable).

--------- Global Types for Debugging -----------

export type symtab_entry(sequence x)
-- (could test all the fields)
	return length(x) = SIZEOF_ROUTINE_ENTRY or
		   length(x) = SIZEOF_VAR_ENTRY
end type

export type symtab_index(integer x)
-- index of a normal symbol or temporary
	if x = 0 then
		return TRUE -- NULL value
	end if
	if x < 0 or x > length(SymTab) then
		return FALSE
	end if
	return find(length(SymTab[x]), {SIZEOF_VAR_ENTRY, SIZEOF_ROUTINE_ENTRY,
						  SIZEOF_TEMP_ENTRY, SIZEOF_BLOCK_ENTRY})
end type

export type temp_index(integer x)
	return x >= 0 and x <= length(SymTab)
end type

-- token fields
export enum
	T_ID, -- SEE reswords.e from ILLEGAL_CHAR .. NAMESPACE
	T_SYM

export type token(object t)
-- scanner token
	if atom(t) then
		return FALSE
	end if
	if length(t) != 2 then
		return FALSE
	end if
	if not integer(t[T_ID]) then
		return FALSE
	end if
	if t[T_ID] = VARIABLE and (t[T_SYM] < 0 or symtab_index(t[T_SYM])) then
		return TRUE
	end if
	-- processed characters
	if QUESTION_MARK <= t[T_ID] and t[T_ID] <= -1 then
		return TRUE
	end if
	-- opcodes or EOF
	if t[T_ID] >= 1 and t[T_ID] <= MAX_OPCODE then
		return TRUE
	end if
	-- keywords that are not opcodes
	if END <= t[T_ID] and t[T_ID] <=  ROUTINE then
		if t[T_ID] != IGNORED and t[T_ID] < 500 and symtab_index(t[T_SYM]) = 0 then
			return FALSE
		end if
		return TRUE
	end if
	if FUNC <= t[T_ID] and t[T_ID] <= NAMESPACE then
		return TRUE
	end if
	return FALSE
end type

export type sequence_of_tokens(object x)
	token t
	if atom(x) then
		return FALSE
	end if
	for i = 1 to length(x) do
		type_i = i
		t = x[i]
	end for
	return TRUE
end type

export type sequence_of_opcodes(object s)
	integer oc
	if atom(s) then
		return FALSE
	end if
	for i = 1 to length(s) do
		-- if calling like a function change this 
		oc = s[i]
		-- to this:
		--type_i = i
		--if not integer(s[i]) then
		--	return FALSE
		--end if
	end for
	return TRUE
end type

export type file(integer f)
-- a file number
	return f >= -1 and f < 100 -- rough limit
end type

---------------- Global Variables ----------------------

export sequence file_name_entered = ""  -- interactively entered file name
export integer shroud_only = FALSE      -- making an unbound .il file
export integer current_file_no = 1      -- current file number
export integer line_number              -- source line number within current file (16 bits)
export integer fwd_line_number = 1      -- remember the line number for forward references
export integer putback_fwd_line_number = 0  -- in case we go to the next line for the next token, but put it back
export integer last_fwd_line_number     -- in case we go to the next line for the next token, but put it back
export integer gline_number             -- overall line number (32 bits)
export symtab_index file_start_sym
export symtab_index TopLevelSub         -- s.t. index of top level procedure
export symtab_index CurrentSub          -- s.t. index of current routine
export integer num_routines = 0         -- sequence number for routine_id lookups
export integer Argc = 0                 -- (our) number of args to main
export sequence Argv = {}               -- (our) arguments to main
export integer test_only = 0            -- testing code, not executing
export integer batch_job = 0            -- batch processing, do not "Press Enter" on error
export object TempWarningName
-- With/Without Options

export constant -- maskable warning flags
	no_warning_flag				= #0000,
	resolution_warning_flag		= #0001,
	short_circuit_warning_flag  = #0002,
	override_warning_flag		= #0004,
	builtin_chosen_warning_flag	= #0008,
	not_used_warning_flag		= #0010,
	no_value_warning_flag		= #0020,
	custom_warning_flag			= #0040,
	translator_warning_flag		= #0080,
	cmdline_warning_flag		= #0100,
	not_reached_warning_flag	= #0200,
	mixed_profile_warning_flag	= #0400,
	empty_case_warning_flag     = #0800,
	no_case_else_warning_flag   = #1000,
	def_arg_type_warning_flag   = #2000,
	deprecated_warning_flag     = #4000,
	all_warning_flag            = #7FFF

constant default_maskable_warnings =
	resolution_warning_flag + 
	override_warning_flag + 
	translator_warning_flag + 
	cmdline_warning_flag + 
	not_reached_warning_flag +
	mixed_profile_warning_flag + 
	custom_warning_flag +
	0

export constant warning_flags = {
	no_warning_flag,
	resolution_warning_flag,
	short_circuit_warning_flag,
	override_warning_flag,
	builtin_chosen_warning_flag,
	not_used_warning_flag,
	no_value_warning_flag,
	custom_warning_flag,
	translator_warning_flag,
	cmdline_warning_flag,
	not_reached_warning_flag,
	mixed_profile_warning_flag,
	empty_case_warning_flag,
	no_case_else_warning_flag,
	def_arg_type_warning_flag,
	deprecated_warning_flag,
	all_warning_flag
}

export constant warning_names = {
	"none",
	"resolution",
	"short_circuit",
	"override",
	"builtin_chosen",
	"not_used",
	"no_value",
	"custom",
	"translator",
	"cmdline",
	"not_reached",
	"mixed_profile",
	"empty_case",
	"default_case",
	"default_arg_type",
	"deprecated",
	"all"
}

-- These are warnings that can only be generated when Strict mode is on.
export constant strict_only_warnings = {
	def_arg_type_warning_flag,
	$
	}

export integer Strict_is_on = 0
export integer Strict_Override = 0
export integer OpWarning = default_maskable_warnings -- compile-time warnings option
export integer prev_OpWarning = OpWarning
export integer OpTrace              -- trace option
export integer OpTypeCheck          -- type check option
export integer OpProfileStatement   -- statement profile option currently on
export integer OpProfileTime        -- time profile option currently on
export sequence OpDefines = {}      -- defines
export integer OpInline             -- inline max size (0 = off)
export integer OpIndirectInclude

-- COMPILE only
export object dj_path = 0, wat_path = 0
export integer cfile_count = 0, cfile_size = 0
export integer Initializing = FALSE

export sequence temp_name_type = repeat({0, 0}, 4)  -- skip 1..4
export enum
	T_GTYPE,
	T_GTYPE_NEW

export integer Execute_id

export sequence Code ={}   -- The IL Code we are currently working with
export sequence LineTable  -- the line table we are currently building

export sequence slist = {}
export enum
	SRC,            -- line of source code
	LINE,           -- line number within file
	LOCAL_FILE_NO,  -- file number
	OPTIONS         -- options in effect

-- option bits:
export constant
	SOP_TRACE = #01,             -- statement trace
	SOP_PROFILE_STATEMENT = #04, -- statement profile
	SOP_PROFILE_TIME = #02       -- time profile


export integer previous_op  -- the previous opcode emitted

export integer max_stack_per_call = 1 -- max stack required per (recursive) call
export integer sample_size = 0        -- profile_time sample size

export sequence symbol_resolution_warning

-- token recording
export enum  -- values for Parser_mode
	PAM_PLAYBACK=-1,
	PAM_NORMAL,
	PAM_RECORD

export integer Parser_mode = PAM_NORMAL

-- lists of identifiers and namespaces to be parsed later
export sequence Recorded = {}, Ns_recorded = {}, Recorded_sym = {}, Ns_recorded_sym = {}

export sequence goto_delay = {}, goto_list = {}

export sequence private_sym = {}
export integer use_private_list = 0

export boolean silent = FALSE
export boolean verbose = FALSE

export sequence main_path         -- path of main file being executed
export integer src_file           -- the source file
export sequence new_include_name  -- name of file to be included at end of line

-- an index for GetMsgText in msgtext.e and for various routines in error.e
export constant ENUM_FWD_REFERENCES_NOT_SUPPORTED = 331 

export constant FIRST_USER_FILE = 3,
                MAX_USER_FILE   = 40


include fwdref.e
				
-- More general than a symtab_index, it could also be a forward reference encoded as a
-- negative number.
export type symtab_pointer(integer x)
	return x = -1 or symtab_index(x) or forward_reference(x)
end type
				
export integer trace_lines = 500
