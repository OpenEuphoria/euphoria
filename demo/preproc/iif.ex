include euphoria/keywords.e
include euphoria/tokenize.e
include std/sequence.e
include std/search.e
include std/map.e
include std/cmdline.e

include ../../source/reswords.e as rw

constant cmd_params = {
	{ "i", 0, "Input filename", { MANDATORY, NO_CASE, HAS_PARAMETER } },
	{ "o", 0, "Output filename", { MANDATORY, NO_CASE, HAS_PARAMETER } }
}

map:map params = cmd_parse(cmd_params)

object input_filename=map:get(params, "i"), 
	output_filename=map:get(params, "o")

enum SC_PREDEF, E_PURE, E_OTHER_EFFECT, E_ALL_EFFECT

-- keep in sync with trunk/source/keylist.e
export sequence keylist = {
	-- PREDEFINED SUBPROGRAMS and TYPEs
	{"length",           SC_PREDEF, FUNC, LENGTH,           1, E_PURE},
	{"puts",             SC_PREDEF, PROC, PUTS,             2, E_OTHER_EFFECT},
	{"integer",          SC_PREDEF, TYPE, IS_AN_INTEGER,    1, E_PURE},
	{"sequence",         SC_PREDEF, TYPE, IS_A_SEQUENCE,    1, E_PURE},
	{"position",         SC_PREDEF, PROC, POSITION,         2, E_OTHER_EFFECT},
	{"object",           SC_PREDEF, TYPE, IS_AN_OBJECT,     1, E_PURE},
	{"append",           SC_PREDEF, FUNC, rw:APPEND,           2, E_PURE},
	{"prepend",          SC_PREDEF, FUNC, PREPEND,          2, E_PURE},
	{"print",            SC_PREDEF, PROC, PRINT,            2, E_OTHER_EFFECT},
	{"printf",           SC_PREDEF, PROC, PRINTF,           3, E_OTHER_EFFECT, {0,0,{{STRING,{}}}}, {3,2,{3}} },
	{"clear_screen",     SC_PREDEF, PROC, CLEAR_SCREEN,     0, E_OTHER_EFFECT},
	{"floor",            SC_PREDEF, FUNC, FLOOR,            1, E_PURE},
	{"getc",             SC_PREDEF, FUNC, GETC,             1, E_OTHER_EFFECT},
	{"gets",             SC_PREDEF, FUNC, GETS,             1, E_OTHER_EFFECT},
	{"get_key",          SC_PREDEF, FUNC, GET_KEY,          0, E_PURE},
	{"rand",             SC_PREDEF, FUNC, RAND,             1, E_PURE},
	{"repeat",           SC_PREDEF, FUNC, REPEAT,           2, E_PURE},
	{"atom",             SC_PREDEF, TYPE, IS_AN_ATOM,       1, E_PURE},
	{"compare",          SC_PREDEF, FUNC, COMPARE,          2, E_PURE},
	{"find",             SC_PREDEF, FUNC, FIND_FROM,        3, E_PURE, {0,0,{{ATOM,1}}}, {3,2,{3}}},
	{"match",            SC_PREDEF, FUNC, MATCH_FROM,       3, E_PURE, {0,0,{{ATOM,1}}}, {3,2,{3}}},
	{"time",             SC_PREDEF, FUNC, TIME,             0, E_PURE},
	{"command_line",     SC_PREDEF, FUNC, COMMAND_LINE,     0, E_PURE},
	{"open",             SC_PREDEF, FUNC, OPEN,             3, E_OTHER_EFFECT, {0,0,{{ATOM,0}}}, {3,2,{3}} },
	{"close",            SC_PREDEF, PROC, CLOSE,            1, E_OTHER_EFFECT},
	{"trace",            SC_PREDEF, PROC, TRACE,            1, E_PURE},
	{"getenv",           SC_PREDEF, FUNC, GETENV,           1, E_PURE},
	{"sqrt",             SC_PREDEF, FUNC, SQRT,             1, E_PURE},
	{"sin",              SC_PREDEF, FUNC, SIN,              1, E_PURE},
	{"cos",              SC_PREDEF, FUNC, COS,              1, E_PURE},
	{"tan",              SC_PREDEF, FUNC, TAN,              1, E_PURE},
	{"log",              SC_PREDEF, FUNC, LOG,              1, E_PURE},
	{"system",           SC_PREDEF, PROC, SYSTEM,           2, E_OTHER_EFFECT, {0,{{ATOM,0}}}, {2,1,{2}}},
	{"date",             SC_PREDEF, FUNC, DATE,             0, E_PURE},
	{"remainder",        SC_PREDEF, FUNC, REMAINDER,        2, E_PURE},
	{"power",            SC_PREDEF, FUNC, POWER,            2, E_PURE},
	{"machine_func",     SC_PREDEF, FUNC, MACHINE_FUNC,     2, E_OTHER_EFFECT, {0,{{STRING,{}}}}, {2,1,{2}}},
	{"machine_proc",     SC_PREDEF, PROC, MACHINE_PROC,     2, E_OTHER_EFFECT, {0,{{STRING,{}}}}, {2,1,{2}}},
	{"abort",            SC_PREDEF, PROC, ABORT,            1, E_OTHER_EFFECT},
	{"peek",             SC_PREDEF, FUNC, PEEK,             1, E_PURE},
	{"poke",             SC_PREDEF, PROC, POKE,             2, E_OTHER_EFFECT},
	{"call",             SC_PREDEF, PROC, CALL,             1, E_OTHER_EFFECT},
	{"sprintf",          SC_PREDEF, FUNC, SPRINTF,          2, E_PURE},
	{"arctan",           SC_PREDEF, FUNC, ARCTAN,           1, E_PURE},
	{"and_bits",         SC_PREDEF, FUNC, AND_BITS,         2, E_PURE},
	{"or_bits",          SC_PREDEF, FUNC, OR_BITS,          2, E_PURE},
	{"xor_bits",         SC_PREDEF, FUNC, XOR_BITS,         2, E_PURE},
	{"not_bits",         SC_PREDEF, FUNC, NOT_BITS,         1, E_PURE},
	{"mem_copy",         SC_PREDEF, PROC, MEM_COPY,         3, E_OTHER_EFFECT},
	{"mem_set",          SC_PREDEF, PROC, MEM_SET,          3, E_OTHER_EFFECT},
	{"c_proc",           SC_PREDEF, PROC, C_PROC,           2, E_ALL_EFFECT, {0,{{STRING,{}}}}, {2,1,{2}}},
	{"c_func",           SC_PREDEF, FUNC, C_FUNC,           2, E_ALL_EFFECT, {0,{{STRING,{}}}}, {2,1,{2}}},
	{"routine_id",       SC_PREDEF, FUNC, ROUTINE_ID,       1, E_PURE},
	{"call_proc",        SC_PREDEF, PROC, CALL_PROC,        2, E_ALL_EFFECT, {0,{{STRING,{}}}}, {2,1,{2}}},
	{"call_func",        SC_PREDEF, FUNC, CALL_FUNC,        2, E_ALL_EFFECT, {0,{{STRING,{}}}}, {2,1,{2}}},
	{"poke4",            SC_PREDEF, PROC, POKE4,            2, E_OTHER_EFFECT},
	{"peek4s",           SC_PREDEF, FUNC, PEEK4S,           1, E_PURE},
	{"peek4u",           SC_PREDEF, FUNC, PEEK4U,           1, E_PURE},
	{"profile",          SC_PREDEF, PROC, PROFILE,          1, E_PURE},
	{"equal",            SC_PREDEF, FUNC, EQUAL,            2, E_PURE},
	{"system_exec",      SC_PREDEF, FUNC, SYSTEM_EXEC,      2, E_OTHER_EFFECT, {0,{{ATOM,0}}}, {2,1,{2}}},
	{"platform",         SC_PREDEF, FUNC, PLATFORM,         0, E_PURE},
	{"task_create",      SC_PREDEF, FUNC, TASK_CREATE,      2, E_OTHER_EFFECT},
	{"task_schedule",    SC_PREDEF, PROC, TASK_SCHEDULE,    2, E_OTHER_EFFECT},
	{"task_yield",       SC_PREDEF, PROC, TASK_YIELD,       0, E_ALL_EFFECT},
	{"task_self",        SC_PREDEF, FUNC, TASK_SELF,        0, E_PURE},
	{"task_suspend",     SC_PREDEF, PROC, TASK_SUSPEND,     1, E_OTHER_EFFECT},
	{"task_list",        SC_PREDEF, FUNC, TASK_LIST,        0, E_PURE},
	{"task_status",      SC_PREDEF, FUNC, TASK_STATUS,      1, E_PURE},
	{"task_clock_stop",  SC_PREDEF, PROC, TASK_CLOCK_STOP,  0, E_PURE},
	{"task_clock_start", SC_PREDEF, PROC, TASK_CLOCK_START, 0, E_PURE},
	{"find_from",        SC_PREDEF, FUNC, FIND_FROM,        3, E_PURE},
	{"match_from",       SC_PREDEF, FUNC, MATCH_FROM,       3, E_PURE},
	{"poke2",            SC_PREDEF, PROC, POKE2,            2, E_OTHER_EFFECT},
	{"peek2s",           SC_PREDEF, FUNC, PEEK2S,           1, E_PURE},
	{"peek2u",           SC_PREDEF, FUNC, PEEK2U,           1, E_PURE},
	{"peeks",            SC_PREDEF, FUNC, PEEKS,            1, E_PURE},
	{"peek_string",      SC_PREDEF, FUNC, PEEK_STRING,      1, E_PURE},
	{"option_switches",  SC_PREDEF, FUNC, OPTION_SWITCHES,  0, E_PURE},
	{"warning",  		 SC_PREDEF, PROC, WARNING,  		1, E_OTHER_EFFECT},
	{"splice",			 SC_PREDEF,	FUNC, SPLICE,			3, E_PURE},
	{"insert",			 SC_PREDEF,	FUNC, INSERT,			3, E_PURE},
	{"include_paths",	 SC_PREDEF,	FUNC, INCLUDE_PATHS,	1, E_OTHER_EFFECT},
	{"hash",             SC_PREDEF, FUNC, HASH,             2, E_PURE},
	{"head",             SC_PREDEF, FUNC, HEAD,             2, E_PURE, {0,{{ATOM,1}}},{2,1,{2}}},
	{"tail",             SC_PREDEF, FUNC, TAIL,             2, E_PURE,
									{0,{{BUILT_IN,"length"},{LEFT_ROUND,0},
									 {DEF_PARAM,1},{RIGHT_ROUND,0},{MINUS,0},
									 {ATOM,1}}},{2,1,{2}}},
	{"remove",           SC_PREDEF, FUNC, REMOVE,           3, E_PURE, {0,0,{{DEF_PARAM,2}}}, {3,2,{3}}},
	{"replace",          SC_PREDEF, FUNC, REPLACE,          4, E_PURE, {0,0,0,{{DEF_PARAM,3}}}, {4,3,{4}}},
	{"delete_routine",   SC_PREDEF, FUNC, DELETE_ROUTINE,   2, E_PURE},
	{"delete",           SC_PREDEF, PROC, DELETE_OBJECT,    1, E_OTHER_EFFECT}
}
	-- new words must go at end to maintain compatibility

function generate_builtin_wrappers()
sequence template, args, thecall, callargs, thename
sequence s = ""
for i = 1 to length(keylist) do
	thename = keylist[i][1]
	if keylist[i][2] = SC_PREDEF then
		if keylist[i][3] = PROC then
			template =
"""

procedure %s(%s)
%s
end procedure

"""
		else
			template =
"""

function %s(%s)
return %s
end function

"""
		end if
		args = ""
		callargs = ""
		for n = 1 to keylist[i][5] do
			args &= sprintf("object x%d,", {n})
			callargs &= sprintf("x%d,", {n})
		end for
		if length(args) then
			args = args[1..$-1]
			callargs = callargs[1..$-1]
		end if
		thecall = sprintf("%s(%s)", {thename,callargs})
		s = append(s, {thename, sprintf(template, {"_iif_builtin_wrap_"&thename, args, thecall})})
	end if
end for
return s
end function

constant builtin_wrappers = generate_builtin_wrappers()

constant TTOKEN = 1, TDATA = 2, IIF_COND_EXPR = 1, IIF_TRUE_EXPR = 2, IIF_FALSE_EXPR = 3, IIF_IDENTIFIERS = 4, IIF_ID_NAME = 1, IIF_ID_TYPE = 2, IIF_ROUTINE = 1, IIF_VARCONST = 2

	tokenize:keep_builtins(0)
	tokenize:keep_keywords()
	tokenize:keep_whitespace()
	tokenize:keep_newlines()
	tokenize:keep_comments()
	tokenize:string_numbers()
	tokenize:return_literal_string()
	tokenize:string_strip_quotes(0)

function decolonize(sequence toks)
	integer i = 1
	while i < length(toks) do
		if toks[i][TTOKEN] = T_COLON then
			if i-1 > 0 then
				toks[i][TDATA] = toks[i-1][TDATA] & toks[i][TDATA]
			end if
			if i+1 <= length(toks) then
				toks[i][TDATA] &= toks[i+1][TDATA]
			end if
			toks[i][TTOKEN] = T_IDENTIFIER
			toks = toks[1..i-2] & {toks[i]} & toks[i+2..$]
		end if
		i += 1
	end while
	return toks
end function

sequence s = tokenize_file(input_filename)
s = decolonize(s[1])
constant x = {
	"T_EOF",
	"T_NULL",
	"T_SHBANG",
	"T_NEWLINE",
	"T_COMMENT",
	"T_NUMBER",
	--**
	-- quoted character
	"T_CHAR",
	--**
	-- string
	"T_STRING",
	"T_IDENTIFIER",
	"T_KEYWORD",
	"T_PLUSEQ",
	"T_MINUSEQ",
	"T_MULTIPLYEQ",
	"T_DIVIDEEQ",
	"T_LTEQ",
	"T_GTEQ",
	"T_NOTEQ",
	"T_CONCATEQ",
	"T_PLUS",
	"T_MINUS",
	"T_MULTIPLY",
	"T_DIVIDE",
	"T_LT",
	"T_GT",
	"T_NOT",
	"T_CONCAT",
	"T_EQ",
	"T_LPAREN",
	"T_RPAREN",
	"T_LBRACE",
	"T_RBRACE",
	"T_LBRACKET",
	"T_RBRACKET",
	"T_QPRINT",
	"T_COMMA",
	"T_PERIOD",
	"T_COLON",
	"T_DOLLAR",
	"T_SLICE",
	"T_WHITE",
	"T_BUILTIN",
	$
	}
	--****

function match(sequence s, integer i, integer tok, integer n)
	while s[i][TTOKEN] = T_WHITE or
	s[i][TTOKEN] = T_COMMENT or
	s[i][TTOKEN] = T_NEWLINE do
		if i = n then
			exit
		end if
		i += 1
	end while
	if s[i][TTOKEN] = tok then
		return i
	else
		return 0
	end if
end function
function seek(integer i, integer tok, integer n, sequence ss, sequence c = s, object ne = 0)
	integer nestcount = 0
	while 1 do
		if c[i][TTOKEN] = tok and nestcount = 0 then
			if sequence(ne) then
				if equal(c[i][TDATA], ne) then
					exit
				end if
			else
				exit
			end if
		elsif find(c[i][TTOKEN], {T_LPAREN, T_LBRACE, T_LBRACKET}) then
			nestcount += 1
		elsif find(c[i][TTOKEN], {T_RPAREN, T_RBRACE, T_RBRACKET}) then
			nestcount -= 1
		end if
		if i = n then
			i = 0
			exit
		end if
		i += 1
	end while
	return i
end function

sequence iif_stack = ""
integer iif_stack_i = 0

integer i
function handle_iif_params(integer o, integer t, integer n, integer is, sequence ss)
	integer last = 0
	for x = o+1 to t-1 do
		if s[x][TTOKEN] = T_IDENTIFIER then
			integer k2 = 0
			if eu:match("routine_id(\"", s[x][TDATA]) then
				-- special case, only happens when nesting iif()s
				s[x][TDATA] = s[x][TDATA][length("routine_id(\"")+1..$-2]
				k2 = 1
			end if
			if find(s[x][TDATA], vslice(iif_stack[is][IIF_IDENTIFIERS], IIF_ID_NAME)) then
				-- if a var is used multiple times, we only need to pass it in once
				s[x][TTOKEN] = T_WHITE
				s[x][TDATA] = ""
				continue
			end if
			if last > 0 then
				s[last][TTOKEN] = T_COMMA
				s[last][TDATA] = ","
				last = 0
			end if
			integer k = match(s, x+1, T_LPAREN, n)
			if k or k2 then
				iif_stack[is][IIF_IDENTIFIERS] = append(iif_stack[is][IIF_IDENTIFIERS], {s[x][TDATA], IIF_ROUTINE})
				s[x][TDATA] = sprintf("routine_id(\"%s\")", {s[x][TDATA]})
			else
				iif_stack[is][IIF_IDENTIFIERS] = append(iif_stack[is][IIF_IDENTIFIERS], {s[x][TDATA], IIF_VARCONST})
			end if
			last = -1
		else
			if s[x][TTOKEN] = T_NEWLINE or
			s[x][TTOKEN] = T_COMMENT then
				continue
			end if
			if last = -1 then
				last = x
			end if
			s[x][TDATA] = ""
		end if
	end for
	return last
end function
function handle_iif(integer n)
	integer c = 0, t, o, n2, is
	while i <= n+c do
		if equal(s[i][TDATA], "iif") then
			t = match(s, i+1, T_LPAREN, n)
			if t then
				integer oo = i
				o = i
				n2 = seek(t+1, T_RPAREN, n, "pre")
				i = o
				integer j
				iif_stack_i += 1
				iif_stack = append(iif_stack, {"", "", "", ""})
				s[i][TDATA] = sprintf("_temp_iif_%d", iif_stack_i)
				is = iif_stack_i
				i = t
				t = seek(i+1, T_COMMA, n2, "cond")
				o = i
				j = handle_iif(t)
				c += j
				iif_stack[is][IIF_COND_EXPR] = s[o+1..t-1]
				if not handle_iif_params(o, t, n2, is, "cond") then
				s[t][TTOKEN] = T_WHITE
				s[t][TDATA] = ""
				end if
				t = seek(t+j+1, T_COMMA, n2, "true")
				o = i
				j = handle_iif(t)
				c += j
				iif_stack[is][IIF_TRUE_EXPR] = s[o+1..t-1]
				if not handle_iif_params(o, t, n2, is, "true") then
				s[t][TTOKEN] = T_WHITE
				s[t][TDATA] = ""
				end if
				t = seek(t+j+1, T_RPAREN, n, "false")
				o = i
				j = handle_iif(t)
				c += j
				iif_stack[is][IIF_FALSE_EXPR] = s[o+1..t-1]
				handle_iif_params(o, t, n2, is, "false")
				for xx = t-1 to oo by -1 do
					if s[xx][TTOKEN] = T_COMMA then
						s[xx][TDATA] = ""
					elsif s[xx][TTOKEN] = T_WHITE then
					elsif s[xx][TTOKEN] = T_NEWLINE then
					elsif s[xx][TTOKEN] = T_COMMENT then
					elsif length(s[xx][TDATA]) then
						exit
					end if
				end for
			end if
		end if
		i += 1
	end while
	return c
end function

procedure fix_iif_var_exprs(integer i, integer j, sequence newnam, integer expr)
	integer x = 1
	while x <= length(iif_stack[i][expr]) do
		if iif_stack[i][IIF_IDENTIFIERS][j][IIF_ID_TYPE] = IIF_VARCONST and
		equal(iif_stack[i][expr][x][TDATA],
		iif_stack[i][IIF_IDENTIFIERS][j][IIF_ID_NAME]) then
			iif_stack[i][expr][x][TDATA] = newnam
		end if
		x += 1
	end while
end procedure
procedure fix_iif_routine_exprs(integer i, integer j, sequence newnam, integer expr)
	integer x = 1
	integer found = 0
	while x <= length(iif_stack[i][expr]) do
		sequence newt
		if eu:match("routine_id(\"", iif_stack[i][IIF_IDENTIFIERS][j][IIF_ID_NAME]) then
			-- special case, only happens when nesting iif()s
		end if
		if eu:match("routine_id(\"", iif_stack[i][expr][x][TDATA]) then
			newt =
			iif_stack[i][expr][x][TDATA][length("routine_id(\"")+1..$-2]
		else
			newt = iif_stack[i][expr][x][TDATA]
		end if
		if iif_stack[i][IIF_IDENTIFIERS][j][IIF_ID_TYPE] = IIF_ROUTINE and
		equal(newt, iif_stack[i][IIF_IDENTIFIERS][j][IIF_ID_NAME]) then
		found = 1
		if not equal(newt, iif_stack[i][expr][x][TDATA]) then
			iif_stack[i][expr][x][TDATA] = newnam
		else
			iif_stack[i][expr][x][TDATA] = "call_func"
			object tok2 = s[1], tok3 = s[1], tok4 = s[1]
			tok2[TTOKEN] = T_IDENTIFIER
			tok2[TDATA] = newnam
			tok3[TTOKEN] = T_COMMA
			tok3[TDATA] = ","
			tok4[TTOKEN] = T_LBRACE
			tok4[TDATA] = "{"
			integer a = match(iif_stack[i][expr],
			x+1, T_LPAREN, length(iif_stack[i][expr]))
			iif_stack[i][expr] =
			iif_stack[i][expr][1..a] & {tok2, tok3, tok4} &
			iif_stack[i][expr][a+1..$]
			tok2[TTOKEN] = T_RBRACE
			tok2[TDATA] = "}"
			a = seek(a+3+1, T_RPAREN, length(iif_stack[i][expr]),
			"expr", iif_stack[i][expr], ")")
			iif_stack[i][expr] =
			iif_stack[i][expr][1..a-1] & {tok2} &
			iif_stack[i][expr][a..$]
		end if
		end if
		x += 1
	end while
	if found = 0 then
		--printf(1, "bad newnam: %s\n", {newnam})
	end if
end procedure
procedure build_iifs()
	object tok = s[1]
	sequence toks = ""
	sequence broutines, aroutines = ""
	for i = 1 to length(iif_stack) do
		broutines = ""
		tok[TTOKEN] = T_KEYWORD
		tok[TDATA] = "function"
		toks = append(toks, tok)
		tok[TTOKEN] = T_WHITE
		tok[TDATA] = " "
		toks = append(toks, tok)
		tok[TTOKEN] = T_IDENTIFIER
		tok[TDATA] = sprintf("_temp_iif_%d", i)
		toks = append(toks, tok)
		tok[TTOKEN] = T_LPAREN
		tok[TDATA] = "("
		toks = append(toks, tok)
		for j = 1 to length(iif_stack[i][IIF_IDENTIFIERS]) do
			tok[TTOKEN] = T_KEYWORD
			tok[TDATA] = "object"
			toks = append(toks, tok)
			tok[TTOKEN] = T_WHITE
			tok[TDATA] = " "
			toks = append(toks, tok)
			tok[TTOKEN] = T_IDENTIFIER
		if iif_stack[i][IIF_IDENTIFIERS][j][IIF_ID_TYPE] = IIF_ROUTINE then
			tok[TDATA] = sprintf("_temp_iif_rid_%s_%d_%d", {iif_stack[i][IIF_IDENTIFIERS][j][IIF_ID_NAME], i, j})
			tok[TDATA] = find_replace(':', tok[TDATA], '_')
			if find(iif_stack[i][IIF_IDENTIFIERS][j][IIF_ID_NAME], builtins)
			or eu:match("eu:", iif_stack[i][IIF_IDENTIFIERS][j][IIF_ID_NAME]) = 1 then
				broutines = append(broutines, {iif_stack[i][IIF_IDENTIFIERS][j][IIF_ID_NAME], tok[TDATA]})
				aroutines = append(aroutines, iif_stack[i][IIF_IDENTIFIERS][j][IIF_ID_NAME])
			end if
			fix_iif_routine_exprs(i, j, tok[TDATA], IIF_COND_EXPR)
			fix_iif_routine_exprs(i, j, tok[TDATA], IIF_TRUE_EXPR)
			fix_iif_routine_exprs(i, j, tok[TDATA], IIF_FALSE_EXPR)
		else
			tok[TDATA] = sprintf("_temp_iif_%s_%d_%d", {iif_stack[i][IIF_IDENTIFIERS][j][IIF_ID_NAME], i, j})
			tok[TDATA] = find_replace(':', tok[TDATA], '_')
			fix_iif_var_exprs(i, j, tok[TDATA], IIF_COND_EXPR)
			fix_iif_var_exprs(i, j, tok[TDATA], IIF_TRUE_EXPR)
			fix_iif_var_exprs(i, j, tok[TDATA], IIF_FALSE_EXPR)
		end if
			toks = append(toks, tok)
			tok[TTOKEN] = T_COMMA
			tok[TDATA] = ","
			toks = append(toks, tok)
		end for
		tok[TTOKEN] = T_RPAREN
		tok[TDATA] = ")"
		if toks[$][TTOKEN] = T_COMMA then
			-- overwrite last T_COMMA with a )
			toks[$] = tok
		else
			-- huh, no parameters, a bug?
			toks = append(toks, tok)
		end if
		tok[TTOKEN] = T_NEWLINE
		tok[TDATA] = "\n"
		toks = append(toks, tok)
		for ab = 1 to length(broutines) do
			tok[TTOKEN] = T_KEYWORD
			tok[TDATA] = "if"
			toks = append(toks, tok)
			tok[TTOKEN] = T_WHITE
			tok[TDATA] = " "
			toks = append(toks, tok)
			tok[TTOKEN] = T_IDENTIFIER
			tok[TDATA] = broutines[ab][2]
			toks = append(toks, tok)
			tok[TTOKEN] = T_WHITE
			tok[TDATA] = " "
			toks = append(toks, tok)
			tok[TTOKEN] = T_EQ
			tok[TDATA] = "="
			toks = append(toks, tok)
			tok[TTOKEN] = T_WHITE
			tok[TDATA] = " "
			toks = append(toks, tok)
			tok[TTOKEN] = T_MINUS
			tok[TDATA] = "-"
			toks = append(toks, tok)
			tok[TTOKEN] = T_NUMBER
			tok[TDATA] = "1"
			toks = append(toks, tok)
			tok[TTOKEN] = T_WHITE
			tok[TDATA] = " "
			toks = append(toks, tok)
			tok[TTOKEN] = T_KEYWORD
			tok[TDATA] = "then"
			toks = append(toks, tok)
			tok[TTOKEN] = T_NEWLINE
			tok[TDATA] = "\n"
			toks = append(toks, tok)
			tok[TTOKEN] = T_IDENTIFIER
			tok[TDATA] = broutines[ab][2]
			toks = append(toks, tok)
			tok[TTOKEN] = T_WHITE
			tok[TDATA] = " "
			toks = append(toks, tok)
			tok[TTOKEN] = T_EQ
			tok[TDATA] = "="
			toks = append(toks, tok)
			tok[TTOKEN] = T_WHITE
			tok[TDATA] = " "
			toks = append(toks, tok)
			tok[TTOKEN] = T_IDENTIFIER
			tok[TDATA] = "routine_id"
			toks = append(toks, tok)
			tok[TTOKEN] = T_LPAREN
			tok[TDATA] = "("
			toks = append(toks, tok)
			tok[TTOKEN] = T_STRING
			if eu:match("eu:", broutines[ab][1]) = 1 then
				tok[TDATA] = sprintf("\"_iif_builtin_wrap_%s\"", {broutines[ab][1][4..$]})
			else
				tok[TDATA] = sprintf("\"_iif_builtin_wrap_%s\"", {broutines[ab][1]})
			end if
			toks = append(toks, tok)
			tok[TTOKEN] = T_RPAREN
			tok[TDATA] = ")"
			toks = append(toks, tok)
			tok[TTOKEN] = T_NEWLINE
			tok[TDATA] = "\n"
			toks = append(toks, tok)
			tok[TTOKEN] = T_KEYWORD
			tok[TDATA] = "end"
			toks = append(toks, tok)
			tok[TTOKEN] = T_WHITE
			tok[TDATA] = " "
			toks = append(toks, tok)
			tok[TTOKEN] = T_KEYWORD
			tok[TDATA] = "if"
			toks = append(toks, tok)
			tok[TTOKEN] = T_NEWLINE
			tok[TDATA] = "\n"
			toks = append(toks, tok)
		end for
		tok[TTOKEN] = T_KEYWORD
		tok[TDATA] = "if"
		toks = append(toks, tok)
		tok[TTOKEN] = T_WHITE
		tok[TDATA] = " "
		toks = append(toks, tok)
		toks &= iif_stack[i][IIF_COND_EXPR]
		tok[TTOKEN] = T_WHITE
		tok[TDATA] = " "
		toks = append(toks, tok)
		tok[TTOKEN] = T_KEYWORD
		tok[TDATA] = "then"
		toks = append(toks, tok)
		tok[TTOKEN] = T_NEWLINE
		tok[TDATA] = "\n"
		toks = append(toks, tok)
		tok[TTOKEN] = T_KEYWORD
		tok[TDATA] = "return"
		toks = append(toks, tok)
		tok[TTOKEN] = T_WHITE
		tok[TDATA] = " "
		toks = append(toks, tok)
		toks &= iif_stack[i][IIF_TRUE_EXPR]
		tok[TTOKEN] = T_NEWLINE
		tok[TDATA] = "\n"
		toks = append(toks, tok)
		tok[TTOKEN] = T_KEYWORD
		tok[TDATA] = "else"
		toks = append(toks, tok)
		tok[TTOKEN] = T_NEWLINE
		tok[TDATA] = "\n"
		toks = append(toks, tok)
		tok[TTOKEN] = T_KEYWORD
		tok[TDATA] = "return"
		toks = append(toks, tok)
		tok[TTOKEN] = T_WHITE
		tok[TDATA] = " "
		toks = append(toks, tok)
		toks &= iif_stack[i][IIF_FALSE_EXPR]
		tok[TTOKEN] = T_NEWLINE
		tok[TDATA] = "\n"
		toks = append(toks, tok)
		tok[TTOKEN] = T_KEYWORD
		tok[TDATA] = "end"
		toks = append(toks, tok)
		tok[TTOKEN] = T_WHITE
		tok[TDATA] = " "
		toks = append(toks, tok)
		tok[TTOKEN] = T_KEYWORD
		tok[TDATA] = "if"
		toks = append(toks, tok)
		tok[TTOKEN] = T_NEWLINE
		tok[TDATA] = "\n"
		toks = append(toks, tok)
		tok[TTOKEN] = T_KEYWORD
		tok[TDATA] = "end"
		toks = append(toks, tok)
		tok[TTOKEN] = T_WHITE
		tok[TDATA] = " "
		toks = append(toks, tok)
		tok[TTOKEN] = T_KEYWORD
		tok[TDATA] = "function"
		toks = append(toks, tok)
		tok[TTOKEN] = T_NEWLINE
		tok[TDATA] = "\n"
		toks = append(toks, tok)
	end for

	sequence hacks = ""
	sequence alreadyfound = ""
	for j = 1 to length(aroutines) do
		sequence ej = aroutines[j]
		if eu:match("eu:", ej) = 1 then
			ej = ej[4..$]
		end if
		if not find(ej, alreadyfound) then
			alreadyfound = append(alreadyfound, ej)
			for y = 1 to length(builtin_wrappers) do
				if equal(builtin_wrappers[y][1],ej) then
					ej = tokenize_string(builtin_wrappers[y][2])
					hacks &= ej[1]
				end if
			end for
		end if
	end for

	s = hacks & toks & s
end procedure

procedure show_all(sequence s)
	for j = 1 to length(s) do
		printf(1, "%s: %s\n", {x[s[j][TTOKEN]], s[j][TDATA]})
	end for
end procedure

i = 1
handle_iif(length(s))
build_iifs()
integer h = open(output_filename, "w")
for a = 1 to length(s) do
	if s[a][TTOKEN] = T_NEWLINE then
		s[a][TDATA] = "\n"
	end if
	puts(h, s[a][TDATA])
end for
close(h)
