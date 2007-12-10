-- (c) Copyright 2007 Rapid Deployment Software - See License.txt
--
-- Euphoria 3.1
-- KEYWORDS and BUILTIN ROUTINES
include global.e
include reswords.e
global constant 
    K_NAME = 1,      -- string
    K_SCOPE = 2,     -- keyword or predefined 
    K_TOKEN = 3,     -- token number returned to parser 
    K_OPCODE = 4,    -- opcode to emit (predefined subprograms) 
    K_NUM_ARGS = 5,  -- number of arguments (predefined subprograms) 
    K_EFFECT = 6     -- side effects 

global sequence keylist
-- N.B. order and number of keywords and builtins 
-- is assumed by scanner.e, euphoria\bin\keywords.e, and others
keylist = 
  {  
    -- KEYWORDS
    {"if",        SC_KEYWORD, IF, 0, 0, 0},
    {"end",       SC_KEYWORD, END, 0, 0, 0},
    {"then",      SC_KEYWORD, THEN, 0, 0, 0},
    {"procedure", SC_KEYWORD, PROCEDURE, 0, 0, 0},
    {"else",      SC_KEYWORD, ELSE, 0, 0, 0},
    {"for",       SC_KEYWORD, FOR, 0, 0, 0},
    {"return",    SC_KEYWORD, RETURN, 0, 0, 0},
    {"do",        SC_KEYWORD, DO, 0, 0, 0},
    {"elsif",     SC_KEYWORD, ELSIF, 0, 0, 0},
    {"while",     SC_KEYWORD, WHILE, 0, 0, 0},
    {"type",      SC_KEYWORD, TYPE_DECL, 0, 0, 0},
    {"constant",  SC_KEYWORD, CONSTANT, 0, 0, 0},
    {"to",        SC_KEYWORD, TO, 0, 0, 0},
    {"and",       SC_KEYWORD, AND, 0, 0, 0},
    {"or",        SC_KEYWORD, OR, 0, 0, 0},
    {"exit",      SC_KEYWORD, EXIT, 0, 0, 0},
    {"function",  SC_KEYWORD, FUNCTION, 0, 0, 0},
    {"global",    SC_KEYWORD, GLOBAL, 0, 0, 0},
    {"by",        SC_KEYWORD, BY, 0, 0, 0},
    {"not",       SC_KEYWORD, NOT, 0, 0, 0},
    {"include",   SC_KEYWORD, INCLUDE, 0, 0, 0},
    {"with",      SC_KEYWORD, WITH, 0, 0, 0},
    {"without",   SC_KEYWORD, WITHOUT, 0, 0, 0},
    {"xor",       SC_KEYWORD, XOR, 0, 0, 0},
    -- new ones must go at end to maintain compatibility with old shrouded code

    -- PREDEFINED SUBPROGRAMS and TYPEs 
    {"length",    SC_PREDEF, FUNC, LENGTH, 1, E_PURE},
    {"puts",      SC_PREDEF, PROC, PUTS, 2, E_OTHER_EFFECT},
    {"integer",   SC_PREDEF, TYPE, IS_AN_INTEGER, 1, E_PURE},
    {"sequence",  SC_PREDEF, TYPE, IS_A_SEQUENCE, 1, E_PURE},
    {"position",  SC_PREDEF, PROC, POSITION, 2, E_OTHER_EFFECT},
    {"object",    SC_PREDEF, TYPE, IS_AN_OBJECT, 1, E_PURE},
    {"append",    SC_PREDEF, FUNC, APPEND, 2, E_PURE},
    {"prepend",   SC_PREDEF, FUNC, PREPEND, 2, E_PURE},
    {"print",     SC_PREDEF, PROC, PRINT, 2, E_OTHER_EFFECT},
    {"printf",    SC_PREDEF, PROC, PRINTF, 3, E_OTHER_EFFECT},
    {"clear_screen", SC_PREDEF,PROC,CLEAR_SCREEN, 0, E_OTHER_EFFECT},
    {"floor",     SC_PREDEF, FUNC, FLOOR, 1, E_PURE},
    {"getc",      SC_PREDEF, FUNC, GETC, 1, E_OTHER_EFFECT},
    {"gets",      SC_PREDEF, FUNC, GETS, 1, E_OTHER_EFFECT},
    {"get_key",   SC_PREDEF, FUNC, GET_KEY, 0, E_PURE}, -- tiny effect, unimportant
    {"rand",      SC_PREDEF, FUNC, RAND, 1, E_PURE}, -- effect usually not important
    {"repeat",    SC_PREDEF, FUNC, REPEAT, 2, E_PURE},
    {"atom",      SC_PREDEF, TYPE, IS_AN_ATOM, 1, E_PURE},
    {"compare",   SC_PREDEF, FUNC, COMPARE, 2, E_PURE},
    {"find",      SC_PREDEF, FUNC, FIND, 2, E_PURE},
    {"match",     SC_PREDEF, FUNC, MATCH, 2, E_PURE},
    {"time",      SC_PREDEF, FUNC, TIME, 0, E_PURE},
    {"command_line",SC_PREDEF,FUNC,COMMAND_LINE, 0, E_PURE},
    {"open",      SC_PREDEF, FUNC, OPEN, 2, E_OTHER_EFFECT},
    {"close",     SC_PREDEF, PROC, CLOSE, 1, E_OTHER_EFFECT},
    {"trace",     SC_PREDEF, PROC, TRACE, 1, E_PURE},
    {"getenv",    SC_PREDEF, FUNC, GETENV, 1, E_PURE},
    {"sqrt",      SC_PREDEF, FUNC, SQRT, 1, E_PURE},
    {"sin",       SC_PREDEF, FUNC, SIN, 1, E_PURE},
    {"cos",       SC_PREDEF, FUNC, COS, 1, E_PURE},
    {"tan",       SC_PREDEF, FUNC, TAN, 1, E_PURE},
    {"log",       SC_PREDEF, FUNC, LOG, 1, E_PURE},
    {"system",    SC_PREDEF, PROC, SYSTEM, 2, E_OTHER_EFFECT},
    {"date",      SC_PREDEF, FUNC, DATE, 0, E_PURE}, 
    {"remainder", SC_PREDEF, FUNC, REMAINDER, 2, E_PURE},
    {"power",     SC_PREDEF, FUNC, POWER, 2, E_PURE},
    {"machine_func", SC_PREDEF, FUNC, MACHINE_FUNC, 2, E_OTHER_EFFECT},
    {"machine_proc", SC_PREDEF, PROC, MACHINE_PROC, 2, E_OTHER_EFFECT},
    {"abort",     SC_PREDEF, PROC, ABORT, 1, E_OTHER_EFFECT},
    {"peek",      SC_PREDEF, FUNC, PEEK, 1, E_PURE},
    {"poke",      SC_PREDEF, PROC, POKE, 2, E_OTHER_EFFECT},
    {"call",      SC_PREDEF, PROC, CALL, 1, E_OTHER_EFFECT},
    {"sprintf",   SC_PREDEF, FUNC, SPRINTF, 2, E_PURE},
    {"arctan",    SC_PREDEF, FUNC, ARCTAN, 1, E_PURE},
    {"and_bits",  SC_PREDEF, FUNC, AND_BITS, 2, E_PURE},
    {"or_bits",   SC_PREDEF, FUNC, OR_BITS, 2, E_PURE},
    {"xor_bits",  SC_PREDEF, FUNC, XOR_BITS, 2, E_PURE},
    {"not_bits",  SC_PREDEF, FUNC, NOT_BITS, 1, E_PURE},
    {"pixel",     SC_PREDEF, PROC, PIXEL, 2, E_OTHER_EFFECT},
    {"get_pixel", SC_PREDEF, FUNC, GET_PIXEL, 1, E_PURE},
    {"mem_copy",  SC_PREDEF, PROC, MEM_COPY, 3, E_OTHER_EFFECT},
    {"mem_set",   SC_PREDEF, PROC, MEM_SET, 3, E_OTHER_EFFECT},
    {"c_proc",    SC_PREDEF, PROC, C_PROC, 2,  E_ALL_EFFECT}, 
    {"c_func",    SC_PREDEF, FUNC, C_FUNC, 2, E_ALL_EFFECT},
    {"routine_id",SC_PREDEF, FUNC, ROUTINE_ID, 1, E_PURE},
    {"call_proc", SC_PREDEF, PROC, CALL_PROC, 2, E_ALL_EFFECT},
    {"call_func", SC_PREDEF, FUNC, CALL_FUNC, 2, E_ALL_EFFECT},
    {"poke4",     SC_PREDEF, PROC, POKE4, 2, E_OTHER_EFFECT},
    {"peek4s",    SC_PREDEF, FUNC, PEEK4S, 1, E_PURE},
    {"peek4u",    SC_PREDEF, FUNC, PEEK4U, 1, E_PURE},
    {"profile",   SC_PREDEF, PROC, PROFILE, 1, E_PURE},
    {"equal",     SC_PREDEF, FUNC, EQUAL, 2, E_PURE},
    {"system_exec",SC_PREDEF,FUNC, SYSTEM_EXEC, 2, E_OTHER_EFFECT},
    {"platform",  SC_PREDEF, FUNC, PLATFORM, 0, E_PURE},
    {"task_create", SC_PREDEF, FUNC, TASK_CREATE, 2, E_OTHER_EFFECT},
    {"task_schedule", SC_PREDEF, PROC, TASK_SCHEDULE, 2, E_OTHER_EFFECT},
    {"task_yield", SC_PREDEF, PROC, TASK_YIELD, 0, E_ALL_EFFECT},
    {"task_self", SC_PREDEF, FUNC, TASK_SELF,  0, E_PURE},
    {"task_suspend", SC_PREDEF, PROC, TASK_SUSPEND, 1, E_OTHER_EFFECT},
    {"task_list", SC_PREDEF, FUNC, TASK_LIST, 0, E_PURE},
    {"task_status", SC_PREDEF, FUNC, TASK_STATUS, 1, E_PURE},
    {"task_clock_stop", SC_PREDEF, PROC, TASK_CLOCK_STOP, 0, E_PURE},
    {"task_clock_start", SC_PREDEF, PROC, TASK_CLOCK_START, 0, E_PURE},
    {"find_from", SC_PREDEF, FUNC, FIND_FROM, 3, E_PURE },
    {"match_from", SC_PREDEF, FUNC, MATCH_FROM, 3, E_PURE },
    {"poke2",     SC_PREDEF, PROC, POKE2, 2, E_OTHER_EFFECT},
    {"peek2s",    SC_PREDEF, FUNC, PEEK2S, 1, E_PURE},
    {"peek2u",    SC_PREDEF, FUNC, PEEK2U, 1, E_PURE},
    {"peeks",    SC_PREDEF, FUNC, PEEKS, 1, E_PURE},
    {"peek_string",SC_PREDEF, FUNC, PEEK_STRING, 1, E_PURE}
}
    -- new words must go at end to maintain compatibility 

if EXTRA_CHECK then
    -- for debugging storage leaks
    keylist = append(keylist, {"space_used", SC_PREDEF, FUNC, SPACE_USED, 
			       0, E_PURE})
end if
    
-- top level pseudo-procedure (assumed to be last on the list) 
keylist = append(keylist, {"_toplevel_", SC_PREDEF, PROC, 0, 0, E_ALL_EFFECT})


