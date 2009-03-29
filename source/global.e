-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
-- Global declarations
public include std/types.e 
include mode.e as mode
public include common.e

include version.e
global constant INTERPRETER_VERSION = sprintf("%d.%d.%d %s", { MAJ_VER, MIN_VER, PAT_VER, REL_TYPE })
global constant TRANSLATOR_VERSION = INTERPRETER_VERSION

global constant
	INTERPRET = mode:get_interpret(),
	TRANSLATE = mode:get_translate(),
	BIND      = mode:get_bind()

global constant
	EXTRA_CHECK = mode:get_extra_check()

global boolean mybsd -- set to true if very little RAM available (build fails)
mybsd = FALSE  -- default to false

-- specific C compiler used (one may be TRUE)
global constant
	EWATCOM  = TRUE,
	EBORLAND = FALSE,
	ELCC     = FALSE,
	EDJGPP   = FALSE
	-- (assume GNU C for Unix variants)

global constant EGPM = 0     -- GPM mouse support on Linux

global boolean w32 -- Windows option for BIND

global sequence version_name
if EDOS then
	if EDJGPP then
		version_name = "DOS32 built for DJGPP"
	else
		version_name = "DOS32"
	end if
elsif EWINDOWS then
	version_name = "WIN32"
elsif ELINUX then
	version_name = "Linux"
elsif ESUNOS then
	version_name = "SunOS"
elsif EOSX then
	version_name = "Mac OS X"
elsif EBSD then
	version_name = "BSD"
elsif EUNIX then  --should never happen
	version_name = "UNIX"
end if

-- common fields for all symbols, literal constants and temporaries
global enum
	S_OBJ,   -- initialized for literal constants
	         -- NOVALUE for other temps
	         -- run time object (vars)
	         -- must be first field in C
	S_NEXT,  -- index of next temp, or next var, or 0
	S_MODE,  -- M_NORMAL, M_TEMP or M_CONSTANT
	S_SCOPE, -- for temps at compile time: FREE or IN_USE,
	         -- or DELETED (Translator-only)
	S_USAGE  -- for temps: type T_UNKNOWN or T_INTEGER
	         -- for vars, read/written/to be deleted

-- extra fields for vars (and routines) only but not temps
global constant
	S_FILE_NO = 6 - get_backend(), -- file number where symbol is defined
	S_NAME = 7 - get_backend(),    -- name string
	S_SAMEHASH = 8,                -- index of next symbol with same hash value
	S_TOKEN = 9 - get_backend()*2, -- token number to return to parser
	S_HASHVAL = 10,                -- hash value
	S_NREFS = 11,                  -- number of references to this symbol
	S_CODE = 12 - get_backend()*4  -- IL code for proc/func/type

-- canned tokens for defaulted routine parameters
-- for vars only:
global constant
	S_VARNUM = 15,    -- local variable number
	S_INITLEVEL = 13, -- nesting level where initialized or -1
	S_VTYPE = 14      -- variable type or NULL

-- for routines only:
global constant
	S_LINETAB = 16 - get_backend()*7,      -- Line table for traceback
	S_FIRSTLINE = 17 - get_backend()*5,    -- global line number of start of routine
	S_TEMPS = 18 - get_backend()*8,        -- pointer to linked list of temps, or 0
	S_OPCODE = 19,                         -- opcode to emit (predefined subprograms)
	S_NUM_ARGS = 20 - get_backend()*9,     -- number of arguments
	S_EFFECT = 21,                         -- side effects
	S_REFLIST = 22,                        -- list of referenced symbols (for BIND)
	S_RESIDENT_TASK = 23,                  -- the task that's currently using this routine
	                                       -- (at run-time) or 0 if none
	S_SAVED_PRIVATES = 24,                 -- private data of any suspended tasks
	                                       -- executing this routine
	S_STACK_SPACE = 25 - get_backend()*12, -- amount of stack space needed by this routine
	                                       -- (for private data)
	S_DEF_ARGS = 26,                  -- {index of first defaulted arg in a routine, last
										--	nondef, list of middle defaulted params}
	                                    -- or 0 if none
	S_INLINE = 27                          -- 0 if routine cannot be inlined, or sequence of
	                                       -- inline code if it can

-- extra fields for TRANSLATOR (for temps and vars/routines)
global constant
	S_OBJ_MIN = 28,   -- minimum integer value
	S_OBJ_MAX = 29,   -- maximum integer value
	S_SEQ_LEN = 30,   -- length of a sequence
	S_SEQ_ELEM = 31,  -- type of all elements of a sequence, or
	                  -- type returned by a function/type
	S_TEMP_NAME = 32, -- for temps: number to use in the outputted C name
	S_ONE_REF = 33,   -- TRUE if we see that a variable can only ever have
	                  -- 1 reference count
	S_GTYPE = 34      -- current global idea of what the worst-case type is

-- extra fields for TRANSLATOR (for vars/routines only)
global constant
	S_LHS_SUBS2 = 35,        -- routine does double or more LHS subscripting
	S_GTYPE_NEW = 36,        -- new idea being formed of global type
	S_SEQ_LEN_NEW = 37,      -- new idea being formed of length of a sequence
	S_SEQ_ELEM_NEW = 38,     -- new type being formed on a pass

	S_OBJ_MIN_NEW = 39,      -- new integer value
	S_OBJ_MAX_NEW = 40,      -- new integer value

	S_ARG_TYPE = 41,         -- argument type info, stable and new versions
	S_ARG_TYPE_NEW = 42,

	S_ARG_SEQ_ELEM = 43,
	S_ARG_SEQ_ELEM_NEW = 44,

	S_ARG_MIN = 45,          -- argument min/max integers or NOVALUE or -NOVALUE
	S_ARG_MAX = 46,
	S_ARG_MIN_NEW = 47,
	S_ARG_MAX_NEW = 48,

	S_ARG_SEQ_LEN = 49,
	S_ARG_SEQ_LEN_NEW = 50,
	S_RI_TARGET = 51         -- > 0 if targeted by a routine_id call or other
	                         -- external call, e.g. call to a DLL


global constant
	SIZEOF_ROUTINE_ENTRY = 27 + 24 * TRANSLATE,
	SIZEOF_VAR_ENTRY     = 15 + 36 * TRANSLATE,
	SIZEOF_TEMP_ENTRY    =  5 + 29 * TRANSLATE

-- Permitted values for various symbol table fields

-- MODE values:
global enum
	M_NORMAL,    -- all variables
	M_CONSTANT,  -- literals and declared constants
	M_TEMP       -- temporaries

-- SCOPE values:
global enum
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
global enum
	U_UNUSED=0,
	U_READ,
	U_WRITTEN,
	U_FORWARD = 4,
	U_DELETED=99   -- we've decided to delete this symbol

-- Does a routine have an effect other than just returning a value?
-- We use 30 bits of information (to keep it in integer range).
-- Bits 0..28 give a rough indication of which local/global vars execution of
-- a routine might directly or indirectly modify. This helps to optimize a rare
-- situation when assigning to a multiply-subscripted sequence.
-- Bit 29 indicates all other side effects (I/O, task scheduling etc.)
global constant
	E_PURE = 0,   -- routine has no side effects
	E_SIZE = 29,  -- number of bits for screening out vars
	E_OTHER_EFFECT = power(2, E_SIZE),  -- routine has other effects, e.g. I/O
	E_ALL_EFFECT = #3FFFFFFF -- all bits (0..29) are set,
							 -- unspecified globals might be changed
							 -- plus other effects

global enum
	FREE = 0,
	IN_USE,
	DELETED

-- result types
global enum
	T_INTEGER,
	T_SEQUENCE,
	T_ATOM,
	T_UNKNOWN

global enum
	MIN,
	MAX

global constant
	MAXINT = #3FFFFFFF,
	MININT = -MAXINT-1,   -- should be -ve
	MININT_VAL = MININT,  -- these are redundant ...
	MAXINT_VAL = MAXINT,
	MININT_DBL = MININT_VAL,
	MAXINT_DBL = MAXINT_VAL

global constant NOVALUE = -1.295837195871e307
-- An unlikely number. If it occurs naturally,  there will be a slight loss of optimization
-- as we will not know the value of a variable at compile time. (NaN could be used, but it's
-- not 100% portable).

--------- Global Types for Debugging -----------

global type symtab_entry(sequence x)
-- (could test all the fields)
	return length(x) = SIZEOF_ROUTINE_ENTRY or
		   length(x) = SIZEOF_VAR_ENTRY
end type

global type symtab_index(integer x)
-- index of a normal symbol or temporary
	if x = 0 then
		return TRUE -- NULL value
	end if
	if x < 0 or x > length(SymTab) then
		return FALSE
	end if
	return find(length(SymTab[x]), {SIZEOF_VAR_ENTRY, SIZEOF_ROUTINE_ENTRY,
						  SIZEOF_TEMP_ENTRY})
end type

global type temp_index(integer x)
	return x >= 0 and x <= length(SymTab)
end type

-- token fields
global enum
	T_ID,
	T_SYM

global type token(sequence t)
-- scanner token
	return length(t) = 2 and integer(t[T_ID]) and symtab_index(t[T_SYM])
end type

global type file(integer f)
-- a file number
	return f >= -1 and f < 100 -- rough limit
end type

---------------- Global Variables ----------------------

global object eudir                     -- path to Euphoria directory
global sequence file_name_entered = ""  -- interactively entered file name
global integer shroud_only = FALSE      -- making an unbound .il file
global integer current_file_no = 1      -- current file number
global integer line_number              -- source line number within current file (16 bits)
global integer fwd_line_number          -- remember the line number for forward references
global integer gline_number             -- overall line number (32 bits)
global symtab_index file_start_sym
global symtab_index TopLevelSub         -- s.t. index of top level procedure
global symtab_index CurrentSub          -- s.t. index of current routine
global integer num_routines = 0         -- sequence number for routine_id lookups
global integer Argc = 0                 -- (our) number of args to main
global sequence Argv = {}               -- (our) arguments to main
global integer test_only = 0            -- testing code, not executing
global integer batch_job = 0            -- batch processing, do not "Press Enter" on error
global object TempWarningName
-- With/Without Options

global constant -- maskable warning flags
	no_warning_flag				= 0,
	resolution_warning_flag		= 1,
	short_circuit_warning_flag  = 2,
	override_warning_flag		= 4,
	builtin_chosen_warning_flag	= 8,
	not_used_warning_flag		= 16,
	no_value_warning_flag		= 32,
	custom_warning_flag			= 64,
	translator_warning_flag		= 128,
	cmdline_warning_flag		= 256,
	not_reached_warning_flag	= 512,
	mixed_profile_warning_flag	= 1024,
	strict_warning_flag			= 2047

constant default_maskable_warnings =
	resolution_warning_flag + override_warning_flag + builtin_chosen_warning_flag +
	translator_warning_flag + cmdline_warning_flag + not_reached_warning_flag +
	mixed_profile_warning_flag + custom_warning_flag

global constant warning_flags = {
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
	strict_warning_flag
}

global constant warning_names = {
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
	"strict"
}

global integer Strict_is_on = 0

global integer OpWarning = default_maskable_warnings -- compile-time warnings option
global integer prev_OpWarning = OpWarning
global integer OpTrace              -- trace option
global integer OpTypeCheck          -- type check option
global integer OpProfileStatement   -- statement profile option currently on
global integer OpProfileTime        -- time profile option currently on
global sequence OpDefines = {}      -- defines
global integer OpInline             -- inline max size (0 = off)
global integer OpIndirectInclude

-- COMPILE only
global object dj_path = 0, wat_path = 0, bor_path = 0
global integer cfile_count = 0, cfile_size = 0
global integer Initializing = FALSE

global sequence temp_name_type = repeat({0, 0}, 4)  -- skip 1..4
global enum
	T_GTYPE,
	T_GTYPE_NEW

global integer Execute_id

global sequence Code       -- The IL Code we are currently working with
global sequence LineTable  -- the line table we are currently building

global sequence slist = {}
global enum
	SRC,            -- line of source code
	LINE,           -- line number within file
	LOCAL_FILE_NO,  -- file number
	OPTIONS         -- options in effect

-- option bits:
global constant
	SOP_TRACE = #01,             -- statement trace
	SOP_PROFILE_STATEMENT = #04, -- statement profile
	SOP_PROFILE_TIME = #02       -- time profile


global integer previous_op  -- the previous opcode emitted

global integer max_stack_per_call = 1 -- max stack required per (recursive) call
global integer sample_size = 0        -- profile_time sample size

global sequence symbol_resolution_warning

-- token recording
global enum  -- values for Parser_mode
	PAM_PLAYBACK=-1,
	PAM_NORMAL,
	PAM_RECORD

global integer Parser_mode = PAM_NORMAL

-- lists of identifiers and namespaces to be parsed later
global sequence Recorded = {}, Ns_recorded = {}, Recorded_sym = {}, Ns_recorded_sym = {}

global sequence goto_delay = {}, goto_list = {}

global sequence private_sym = {}
global integer use_private_list = 0

global boolean wat_option, djg_option, bor_option, lcc_option, gcc_option
global boolean silent = FALSE
