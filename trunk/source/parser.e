-- (c) Copyright 2007 Rapid Deployment Software - See License.txt
--
-- Euphoria 3.1
-- Parser

constant UNDEFINED = -999
constant DEFAULT_SAMPLE_SIZE = 25000  -- for time profile

global integer max_stack_per_call  -- max stack required per (recursive) call 

global integer sample_size         -- profile_time sample size 
sample_size = 0

max_stack_per_call = 1

--*****************
-- Local variables 
--*****************
sequence branch_list
branch_list = {}

integer short_circuit     -- are we doing short-circuit code? 
			  -- > 0 means yes - if/elsif/while but not
			  -- in args, subscripts, slices, {,,}. 
short_circuit = 0
boolean short_circuit_B   -- are we in the skippable part of a short
short_circuit_B = FALSE   -- circuit expression? given short_circuit is TRUE.
			   
integer SC1_patch        -- place to patch jump address for SC1 ops 
integer SC1_type         -- OR or AND 
integer start_index      -- start of current top level command 

object backed_up_tok  -- place to back up a token 
integer FuncReturn    -- TRUE if a function return appeared 
integer param_num     -- number of parameters and private variables
		      -- in current procedure 
sequence elist        -- back-patch list for end if label 
sequence exit_list    -- stack of exits to back-patch 
integer loop_nest     -- current number of nested loops 
integer stmt_nest     -- nesting level of statement lists 
sequence init_stack   -- var init stack 

-- Expression statistics:
integer side_effect_calls -- number of calls to functions with side-effects
side_effect_calls = 0     -- on local/global variables

integer factors           -- number of factors parsed
factors = 0

integer lhs_subs_level    -- number of levels of subscripting of lhs var on RHS
lhs_subs_level = -1

symtab_index left_sym  -- var used on LHS of assignment
left_sym = 0

procedure EndLineTable()
-- put marker at end of current line number table 

    LineTable = append(LineTable, -2)
end procedure

procedure CreateTopLevel()
-- sets symbol table fields for the top level procedure 
    SymTab[TopLevelSub][S_NUM_ARGS] = 0
    SymTab[TopLevelSub][S_TEMPS] = 0
    SymTab[TopLevelSub][S_CODE] = {}
    SymTab[TopLevelSub][S_LINETAB] = {}
    SymTab[TopLevelSub][S_FIRSTLINE] = 1
    SymTab[TopLevelSub][S_REFLIST] = {}
    SymTab[TopLevelSub][S_NREFS] = 1
    SymTab[TopLevelSub][S_RESIDENT_TASK] = 1
    SymTab[TopLevelSub][S_SAVED_PRIVATES] = {}
end procedure

procedure EnterTopLevel()
-- prepare to put code into the top level procedure 
    if CurrentSub then
	EndLineTable()
	SymTab[CurrentSub][S_LINETAB] = LineTable
	SymTab[CurrentSub][S_CODE] = Code
    end if
    LineTable = SymTab[TopLevelSub][S_LINETAB]
    Code = SymTab[TopLevelSub][S_CODE]
    previous_op = -1
    CurrentSub = TopLevelSub
end procedure

procedure LeaveTopLevel()
-- prepare to resume compiling normal subprograms 
    LastLineNumber = -1
    SymTab[TopLevelSub][S_LINETAB] = LineTable
    SymTab[TopLevelSub][S_CODE] = Code
    LineTable = {}
    Code = {}
    previous_op = -1
end procedure

global procedure InitParser()
    elist = {}
    exit_list = {}
    init_stack = {}
    CurrentSub = 0
    CreateTopLevel()
    EnterTopLevel()
    backed_up_tok = UNDEFINED
    loop_nest = 0
    stmt_nest = 0
end procedure

procedure NotReached(integer tok, sequence keyword)
-- Issue warning about code that can't be executed 
    if not find(tok, {END, ELSE, ELSIF, END_OF_FILE}) then
	Warning(sprintf("%s:%d - statement after %s will never be executed", 
		{name_ext(file_name[current_file_no]), line_number, keyword}))
    end if
end procedure

procedure InitCheck(symtab_index sym, integer ref)
-- emit INIT_CHECK opcode if we aren't sure if a var has been
-- initialized yet. ref is TRUE if this is a read of this var 
    if SymTab[sym][S_MODE] = M_NORMAL and 
       SymTab[sym][S_SCOPE] != SC_LOOP_VAR and 
       SymTab[sym][S_SCOPE] != SC_GLOOP_VAR then
	if (SymTab[sym][S_SCOPE] != SC_PRIVATE and 
	   equal(SymTab[sym][S_OBJ], NOVALUE)) or 
	   (SymTab[sym][S_SCOPE] = SC_PRIVATE and 
	   SymTab[sym][S_VARNUM] >= SymTab[CurrentSub][S_NUM_ARGS]) then
	    if SymTab[sym][S_INITLEVEL] = -1 then
		if ref then
		    if SymTab[sym][S_SCOPE] = SC_GLOBAL or 
		       SymTab[sym][S_SCOPE] = SC_LOCAL then
			emit_op(GLOBAL_INIT_CHECK) -- will become NOP2
		    else
			emit_op(PRIVATE_INIT_CHECK)
		    end if
		    emit_addr(sym)
		end if
		if short_circuit <= 0 or short_circuit_B = FALSE then
		    init_stack = append(init_stack, sym)
		    SymTab[sym][S_INITLEVEL] = stmt_nest
		end if
	    end if
	    -- else we know that it must be initialized at this point 
	end if
	-- else ignore parameters, already initialized global/locals 
    end if
    -- else .. ignore loop vars, constants 
end procedure

procedure InitDelete()
-- remove vars whose nesting level is 
-- now too high from the init stack 
    while length(init_stack) and 
	  SymTab[init_stack[$]][S_INITLEVEL] > stmt_nest do
	SymTab[init_stack[$]][S_INITLEVEL] = -1
	init_stack = init_stack[1..$-1]
    end while
end procedure

procedure emit_forward_addr() 
-- emit blank forward address and add this branch point to the list 
-- for later straightening 
    emit_addr(0)
    branch_list = append(branch_list, length(Code))
end procedure

procedure StraightenBranches()
-- Straighten branches within the current subprogram (or top-level)
    integer br 
    integer target
    
    if TRANSLATE then
	return -- do it in back-end
    end if
    for i = length(branch_list) to 1 by -1 do
	target = Code[branch_list[i]]
	if target <= length(Code) then
	    br = Code[target]
	    if br = ELSE or br = ENDWHILE or br = EXIT then
		backpatch(branch_list[i], Code[target+1])
	    end if
	end if
    end for
    branch_list = {}
end procedure

procedure AppendEList(integer addr)
-- add address to list requiring back-patch at end of if statement 
    elist = append(elist, addr)
end procedure

procedure AppendXList(integer addr)
-- add exit location to list requiring back-patch at end of loop 
    exit_list = append(exit_list, addr)
end procedure

procedure PatchEList(integer base)
-- back-patch jump offsets for jumps to end of if-statement 
    integer elist_top
    
    elist_top = length(elist)
    while elist_top > base do
	backpatch(elist[elist_top], length(Code)+1)
	elist_top -= 1
    end while
    elist = elist[1..base]
end procedure

procedure PatchXList(integer base)
-- back-patch jump offsets for jumps to end of loop 
    integer exit_top
    
    exit_top = length(exit_list)
    while exit_top > base do
	backpatch(exit_list[exit_top], length(Code)+1)
	exit_top -= 1
    end while
    exit_list = exit_list[1..base] 
end procedure

procedure putback(token t) 
-- push a scanner token back onto the input stream    
    backed_up_tok = t
end procedure

function next_token() 
-- read next scanner token
    token t
    
    if atom(backed_up_tok) then
	 t = Scanner() 
    else     
	 t = backed_up_tok 
	 backed_up_tok = UNDEFINED 
    end if 
    return t
end function

integer forward_expr

function Expr_list()
-- parse a (possibly empty) list of expressions 
    token tok
    integer n

    tok = next_token()
    putback(tok)
    if tok[T_ID] = RIGHT_BRACE then
	return 0
    else 
	n = 0
	short_circuit -= 1
	while TRUE do 
	    call_proc(forward_expr, {})
	    n += 1
	    tok = next_token()
	    if tok[T_ID] != COMMA then
		exit
	    end if
	end while  
	short_circuit += 1
    end if
    putback(tok)
    return n
end function

procedure tok_match(integer tok)
-- match token or else syntax error 
    token t
    sequence expected, actual

    t = next_token()
    if t[T_ID] != tok then
	expected = LexName(tok)
	actual = LexName(t[T_ID])
	CompileErr(sprintf(
		   "Syntax error - expected to see possibly %s, not %s", 
		   {expected, actual}))
    end if
end procedure

procedure UndefinedVar(symtab_index s)
-- report a possibly undefined or multiply-defined symbol 
    symtab_index dup
    sequence errmsg
    
    if SymTab[s][S_SCOPE] = SC_UNDEFINED then
	CompileErr(sprintf("%s has not been declared", {SymTab[s][S_NAME]}))
    
    elsif SymTab[s][S_SCOPE] = SC_MULTIPLY_DEFINED then
	errmsg = sprintf("A namespace qualifier is needed to resolve %s.\n%s is defined as a global symbol in:\n", 
			 {SymTab[s][S_NAME], SymTab[s][S_NAME]})
	-- extended error message  
	for i = length(dup_globals) to 1 by -1 do
	    dup = dup_globals[i]
	    errmsg &= "    " & file_name[SymTab[dup][S_FILE_NO]] & "\n"
	end for
	
	CompileErr(errmsg)
    end if
end procedure

procedure WrongNumberArgs(symtab_index subsym, sequence only)
-- issue message for wrong number of arguments
    sequence plural

    if SymTab[subsym][S_NUM_ARGS] = 1 then
	plural = ""
    else
	plural = "s"
    end if
    CompileErr(sprintf("%s takes %s%d argument%s", 
	       {SymTab[subsym][S_NAME], only, 
		SymTab[subsym][S_NUM_ARGS], plural}))
end procedure

procedure ParseArgs(symtab_index subsym)
-- parse arguments for a function, type or procedure call 
    integer n
    token tok

    n = SymTab[subsym][S_NUM_ARGS]
    short_circuit -= 1
    for i = 1 to n do
	call_proc(forward_expr, {})
	if i != n then 
	    tok = next_token()
	    if tok[T_ID] != COMMA then
		if tok[T_ID] = RIGHT_ROUND then
		    WrongNumberArgs(subsym, "")
		else 
		    putback(tok)
		    tok_match(COMMA)
		end if
	    end if
	end if
    end for
    tok = next_token()
    short_circuit += 1
    if tok[T_ID] != RIGHT_ROUND then
	if tok[T_ID] = COMMA then
	    WrongNumberArgs(subsym, "only ")
	else 
	    putback(tok)
	    tok_match(RIGHT_ROUND)
	end if
    end if
end procedure

procedure Factor()
-- parse a factor in an expression 
    token tok
    integer id, n, scope, opcode, e
    integer save_factors, save_lhs_subs_level
    symtab_index sym
    
    factors += 1
    tok = next_token()
    id = tok[T_ID]
    if id = VARIABLE or id = QUALIFIED_VARIABLE then
	sym = tok[T_SYM]
	UndefinedVar(sym)
	    
	SymTab[sym][S_USAGE] = or_bits(SymTab[sym][S_USAGE], U_READ)

	InitCheck(sym, TRUE)
	emit_opnd(sym)

	if sym = left_sym then
	    lhs_subs_level = 0 -- start counting subscripts
	end if
	
	short_circuit -= 1
	tok = next_token()
	current_sequence = append(current_sequence, sym)
	while tok[T_ID] = LEFT_SQUARE do
	    if lhs_subs_level >= 0 then
		lhs_subs_level += 1
	    end if
	    save_factors = factors
	    save_lhs_subs_level = lhs_subs_level
	    call_proc(forward_expr, {})
	    tok = next_token()
	    if tok[T_ID] = SLICE then
		call_proc(forward_expr, {})
		emit_op(RHS_SLICE)
		tok_match(RIGHT_SQUARE)
		tok = next_token()
		exit
	    else 
		putback(tok)
		tok_match(RIGHT_SQUARE)
		current_sequence = current_sequence[1..$-1]
		emit_op(RHS_SUBS) -- current_sequence will be updated
	    end if
	    factors = save_factors
	    lhs_subs_level = save_lhs_subs_level
	    tok = next_token()
	end while
	current_sequence = current_sequence[1..$-1]
	putback(tok)
	short_circuit += 1

    elsif id = DOLLAR then
	if length(current_sequence) then
	    emit_op(DOLLAR)
	else
	    CompileErr("'$' must only appear between '[' and ']'")
	end if
	
    elsif id = ATOM then
	emit_opnd(tok[T_SYM])

    elsif id = LEFT_BRACE then
	n = Expr_list()
	tok_match(RIGHT_BRACE)
	op_info1 = n
	emit_op(RIGHT_BRACE_N)

    elsif id = STRING then
	emit_opnd(tok[T_SYM])

    elsif id = LEFT_ROUND then
	call_proc(forward_expr, {})
	tok_match(RIGHT_ROUND)

    elsif find(id, {FUNC, TYPE, QUALIFIED_FUNC, QUALIFIED_TYPE}) then
	e = SymTab[tok[T_SYM]][S_EFFECT]
	if e then
	    -- the routine we are calling has side-effects
	    if e = E_ALL_EFFECT or tok[T_SYM] > left_sym then
		-- it can access the LHS var (it uses indirect calls or comes later)
		side_effect_calls = or_bits(side_effect_calls, e)
	    end if
	    
	    SymTab[CurrentSub][S_EFFECT] = or_bits(SymTab[CurrentSub][S_EFFECT],
						   e)
	    
	    if short_circuit > 0 and short_circuit_B and
		      find(id, {FUNC, QUALIFIED_FUNC}) then
		Warning(sprintf(
		"%.99s:%d - call to %s() might be short-circuited", 
		{file_name[current_file_no], line_number, 
		 SymTab[tok[T_SYM]][S_NAME]}))
	    end if
	end if
	tok_match(LEFT_ROUND)
	scope = SymTab[tok[T_SYM]][S_SCOPE]
	opcode = SymTab[tok[T_SYM]][S_OPCODE]
	ParseArgs(tok[T_SYM])
	if scope = SC_PREDEF then
	    emit_op(opcode)
	else 
	    op_info1 = tok[T_SYM]
	    emit_op(PROC)
	    if not TRANSLATE then 
		if OpTrace then
		    emit_op(UPDATE_GLOBALS)
		end if
	    end if      
	end if

    else 
	CompileErr(sprintf(
		   "Syntax error - expected to see an expression, not %s",
		   {LexName(id)}))
    end if
end procedure


procedure UFactor()
-- parse an optional unary op applied to a factor 
    token tok

    tok = next_token()
    
    if tok[T_ID] = MINUS then
	Factor()
	emit_op(UMINUS)
    
    elsif tok[T_ID] = NOT then
	Factor()
	emit_op(NOT)
    
    elsif tok[T_ID] = PLUS then
	Factor()
    
    else 
	putback(tok)
	Factor()
    
    end if
end procedure

function term()
-- parse a term in an expression 
    token tok
    
    UFactor()   
    tok = next_token() 
    while tok[T_ID] = MULTIPLY or tok[T_ID] = DIVIDE do
	UFactor() 
	emit_op(tok[T_ID]) 
	tok = next_token() 
    end while
    return tok
end function

function aexpr()   
-- Parse an arithmetic expression 
    token tok
    integer id
    
    tok = term()
    while tok[T_ID] = PLUS or tok[T_ID] = MINUS do
	id = tok[T_ID]
	tok = term()
	emit_op(id) 
    end while
    return tok
end function

function cexpr()   
-- Parse a concatenation expression 
    token tok
    integer concat_count
    
    tok = aexpr()
    concat_count = 0 
    while tok[T_ID] = CONCAT do
	tok = aexpr()
	concat_count += 1 
    end while
    
    if concat_count = 1 then
	emit_op(CONCAT)
    
    elsif concat_count > 1 then
	op_info1 = concat_count+1 
	emit_op(CONCAT_N) 
    end if      
    
    return tok
end function

-- Parse a relational expression 
function rexpr()   
    token tok
    integer id
    
    tok = cexpr()
    while tok[T_ID] <= GREATER and tok[T_ID] >= LESS do
	id = tok[T_ID]
	tok = cexpr()
	emit_op(id)
    end while
    return tok
end function

procedure Expr()
-- Parse a general expression 
-- Use either short circuit or full evaluation. 
    token tok
    integer id
    integer patch
    
    id = -1
    patch = 0
    while TRUE do 
	if id != -1 and id != XOR and short_circuit > 0 then
	    if id = OR then
		emit_op(SC1_OR)
	    else
		emit_op(SC1_AND)
	    end if
	    patch = length(Code)+1
	    emit_forward_addr()
	    short_circuit_B = TRUE
	end if
	
	tok = rexpr()
	
	if id != -1 then
	    if id != XOR and short_circuit > 0 then
		if tok[T_ID] != THEN and tok[T_ID] != DO then
		    if id = OR then
			emit_op(SC2_OR)
		    else
			emit_op(SC2_AND)
		    end if
		else 
		    SC1_type = id -- if/while/elsif must patch
		    emit_op(SC2_NULL)
		end if
		if TRANSLATE then
		    emit_op(NOP1)   -- to get label here
		end if
		backpatch(patch, length(Code)+1)
	    else 
		emit_op(id)
	    end if
	end if
	id = tok[T_ID]
	if id != OR and id != AND and id != XOR then
	    exit
	end if
    end while
    putback(tok)
    SC1_patch = patch -- extra line
end procedure

forward_expr = routine_id("Expr")

procedure TypeCheck(symtab_index var)
-- emit code to type-check a var (after it has been assigned-to) 
    symtab_index which_type

    which_type = SymTab[var][S_VTYPE]
    if TRANSLATE then
	if OpTypeCheck then
	    if which_type != object_type then
		if SymTab[which_type][S_EFFECT] then
		    -- only call user-defined types that have side-effects
		    emit_opnd(var)
		    op_info1 = which_type
		    emit_op(PROC)
		    emit_op(TYPE_CHECK)
		end if
	    end if
	end if      
    
    else
	if OpTypeCheck then
	    if which_type != object_type then
		if which_type = integer_type then
		    op_info1 = var
		    emit_op(INTEGER_CHECK)
		
		elsif which_type = sequence_type then
		    op_info1 = var
		    emit_op(SEQUENCE_CHECK)
		
		elsif which_type = atom_type then
		    op_info1 = var
		    emit_op(ATOM_CHECK)
		
		else 
		    -- user-defined 
		    if SymTab[SymTab[which_type][S_NEXT]][S_VTYPE] = 
		       integer_type then
			op_info1 = var
			emit_op(INTEGER_CHECK) -- need integer conversion 
		    end if
		    emit_opnd(var)
		    op_info1 = which_type
		    emit_op(PROC)
		    emit_op(TYPE_CHECK)
		end if
	    end if
	end if
    end if

    if TRANSLATE or not OpTypeCheck then
	op_info1 = var
	if which_type = sequence_type or
	    SymTab[SymTab[which_type][S_NEXT]][S_VTYPE] = sequence_type then 
	    -- check sequences anyway, so we can avoid it on subscripting etc. 
	    emit_op(SEQUENCE_CHECK)
	    
	elsif which_type = integer_type or
		 SymTab[SymTab[which_type][S_NEXT]][S_VTYPE] = integer_type then
		 -- check integers too 
	    emit_op(INTEGER_CHECK)
	end if
    end if
end procedure

procedure Assignment(token left_var) 
-- parse an assignment statement 
    token tok
    integer subs, slice, assign_op, subs1_patch
    boolean dangerous  -- tricky subscripted assignment

    left_sym = left_var[T_SYM]
    
    UndefinedVar(left_sym)
	
    if SymTab[left_sym][S_SCOPE] = SC_LOOP_VAR or 
       SymTab[left_sym][S_SCOPE] = SC_GLOOP_VAR then
	CompileErr("may not assign to a for-loop variable")
    
    elsif SymTab[left_sym][S_MODE] = M_CONSTANT then
	CompileErr("may not change the value of a constant")
    
    elsif SymTab[left_sym][S_SCOPE] = SC_LOCAL or 
	  SymTab[left_sym][S_SCOPE] = SC_GLOBAL then
	-- this helps us to optimize things below
	SymTab[CurrentSub][S_EFFECT] = or_bits(SymTab[CurrentSub][S_EFFECT],
					 power(2, remainder(left_sym, E_SIZE)))
    end if
    
    SymTab[left_sym][S_USAGE] = or_bits(SymTab[left_sym][S_USAGE], U_WRITTEN)
    
    tok = next_token()
    subs = 0
    slice = FALSE

    dangerous = FALSE
    side_effect_calls = 0
    
    -- Process LHS subscripts and slice
    emit_opnd(left_sym)
    current_sequence = append(current_sequence, left_sym)
    
    while tok[T_ID] = LEFT_SQUARE do
	if lhs_ptr then
	    -- multiple lhs subscripts, evaluate first n-1 of them with this
	    current_sequence = current_sequence[1..$-1]
	    if subs = 1 then
		-- first subscript of 2 or more
		subs1_patch = length(Code)+1
		emit_op(LHS_SUBS1) -- creates new current_sequence
				   -- opcode might be patched (below)
	    else    
		emit_op(LHS_SUBS) -- adds to current_sequence
	    end if
	end if
	subs += 1
	if subs = 1 then
	    InitCheck(left_sym, TRUE) 
	end if
	Expr() 
	tok = next_token()
	if tok[T_ID] = SLICE then
	    Expr()
	    slice = TRUE
	    tok_match(RIGHT_SQUARE)
	    tok = next_token()
	    exit  -- no further subs or slices allowed 
	else 
	    putback(tok)
	    tok_match(RIGHT_SQUARE)
	end if
	tok = next_token()
	lhs_ptr = TRUE
    end while
    
    lhs_ptr = FALSE
    
    assign_op = tok[T_ID]
    if not find(assign_op, {EQUALS, PLUS_EQUALS, MINUS_EQUALS, MULTIPLY_EQUALS, 
			    DIVIDE_EQUALS, CONCAT_EQUALS}) then
	CompileErr("Syntax error - expected to see =, +=, -=, *=, /= or &=")
    end if
    
    if subs = 0 then
	-- not subscripted 
	if assign_op = EQUALS then
	    Expr() -- RHS expression
	    InitCheck(left_sym, FALSE)
	else 
	    InitCheck(left_sym, TRUE)
	    SymTab[left_sym][S_USAGE] = or_bits(SymTab[left_sym][S_USAGE], U_READ)
	    emit_opnd(left_sym)
	    Expr() -- RHS expression
	    emit_assign_op(assign_op)
	end if
	emit_op(ASSIGN)
	TypeCheck(left_sym)

    else 
	-- subscripted 
	factors = 0
	lhs_subs_level = -1
	Expr() -- RHS expression
	
	if subs > 1 then
	    if SymTab[left_sym][S_SCOPE] != SC_PRIVATE and
	       and_bits(side_effect_calls, 
			power(2, remainder(left_sym, E_SIZE))) then
		-- this var might be overwritten by a function call while
		-- we are executing this statement
		dangerous = TRUE
	    end if
	    
	    if factors = 1 and 
	       lhs_subs_level >= 0 and 
	       lhs_subs_level < subs+slice then
		-- must avoid a possible circular reference
		dangerous = TRUE  
	    end if
	    
	    if dangerous then
		-- Patch earlier op so it will copy lhs var to 
		-- a temp to avoid any problem.
		-- (This danger became greater when we implemented $ for 2.5,
		-- and had to interleave LHS subscripting with expression
		-- evaluation).
		backpatch(subs1_patch, LHS_SUBS1_COPY)
	    end if
	end if
	
	if slice then 
	    if assign_op != EQUALS then
		if subs = 1 then
		    emit_op(ASSIGN_OP_SLICE)
		else    
		    emit_op(PASSIGN_OP_SLICE)
		end if
		emit_assign_op(assign_op)
	    end if
	    if subs = 1 then
		emit_op(ASSIGN_SLICE)
	    else    
		emit_op(PASSIGN_SLICE)
	    end if
	else 
	    if assign_op = EQUALS then
		if subs = 1 then
		    emit_op(ASSIGN_SUBS)
		else
		    emit_op(PASSIGN_SUBS)
		end if
	    else 
		if subs = 1 then
		    emit_op(ASSIGN_OP_SUBS)
		else
		    emit_op(PASSIGN_OP_SUBS)
		end if
		emit_assign_op(assign_op)
		if subs = 1 then
		    emit_op(ASSIGN_SUBS2)
		else    
		    emit_op(PASSIGN_SUBS)
		end if
	    end if
	end if
	
	if subs > 1 then
	    if dangerous then
		-- copy temp back into lhs var
		emit_opnd(left_sym)
		emit_opnd(lhs_subs1_copy_temp) -- will be freed 
		emit_op(ASSIGN)
	    else
		TempFree(lhs_subs1_copy_temp)
	    end if
	end if
	
	if OpTypeCheck and SymTab[left_sym][S_VTYPE] != sequence_type then
	    TypeCheck(left_sym)
	end if
    end if

    current_sequence = current_sequence[1..$-1]
    
    if not TRANSLATE then
	if OpTrace then 
	    emit_op(DISPLAY_VAR)
	    emit_addr(left_sym)
	end if
    end if
end procedure

procedure Return_statement()
-- Parse a return statement 
    token tok
    
    if CurrentSub = TopLevelSub then
	CompileErr("return must be inside a procedure or function")
    end if
    if not TRANSLATE then    
	if OpTrace then
	    emit_op(ERASE_PRIVATE_NAMES)
	    emit_addr(CurrentSub)
	end if
    end if
    if SymTab[CurrentSub][S_TOKEN] != PROC then
	Expr()
	FuncReturn = TRUE
	emit_op(RETURNF)
    else 
	emit_op(RETURNP)
    end if
    tok = next_token()
    putback(tok)
    NotReached(tok[T_ID], "return")
end procedure

procedure Exit_statement()
-- Parse an exit statement 
    token tok
    
    if loop_nest = 0 then
	CompileErr("exit statement must be inside a loop")
    end if
    emit_op(EXIT)
    AppendXList(length(Code)+1)
    emit_forward_addr()     -- to be back-patched 
    tok = next_token()
    putback(tok)
    NotReached(tok[T_ID], "exit")
end procedure

integer forward_Statement_list 

procedure If_statement()
-- parse an if statement with optional elsif's and optional else 
    token tok
    integer prev_false 
    integer prev_false2
    integer elist_base

    elist_base = length(elist)
    short_circuit += 1
    short_circuit_B = FALSE
    SC1_type = 0
    Expr()
    emit_op(IF)
    prev_false = length(Code)+1
    prev_false2 = 0
    emit_forward_addr() -- to be patched 
    if SC1_type = OR then
	backpatch(SC1_patch-3, SC1_OR_IF)
	if TRANSLATE then
	    emit_op(NOP1)  -- to get label here
	end if
	backpatch(SC1_patch, length(Code)+1)
    elsif SC1_type = AND then
	backpatch(SC1_patch-3, SC1_AND_IF)
	prev_false2 = SC1_patch
    end if
    short_circuit -= 1
    tok_match(THEN)
    call_proc(forward_Statement_list, {})
    tok = next_token()

    while tok[T_ID] = ELSIF do
	emit_op(ELSE)
	AppendEList(length(Code)+1)
	emit_forward_addr()  -- to be patched 
	if TRANSLATE then
	    emit_op(NOP1)
	end if
	backpatch(prev_false, length(Code)+1)
	if prev_false2 != 0 then
	    backpatch(prev_false2, length(Code)+1)
	end if
	StartSourceLine(TRUE)
	short_circuit += 1
	short_circuit_B = FALSE
	SC1_type = 0
	Expr()
	emit_op(IF)
	prev_false = length(Code)+1
	prev_false2 = 0
	emit_forward_addr() -- to be patched 
	if SC1_type = OR then
	    backpatch(SC1_patch-3, SC1_OR_IF)
	    if TRANSLATE then
		emit_op(NOP1)
	    end if
	    backpatch(SC1_patch, length(Code)+1)
	elsif SC1_type = AND then
	    backpatch(SC1_patch-3, SC1_AND_IF)
	    prev_false2 = SC1_patch
	end if
	short_circuit -= 1
	tok_match(THEN)
	call_proc(forward_Statement_list, {})
	tok = next_token()
    end while

    if tok[T_ID] = ELSE then 
	StartSourceLine(FALSE)
	emit_op(ELSE)
	AppendEList(length(Code)+1)
	emit_forward_addr() -- to be patched 
	if TRANSLATE then
	    emit_op(NOP1)
	end if
	backpatch(prev_false, length(Code)+1)
	if prev_false2 != 0 then
	    backpatch(prev_false2, length(Code)+1)
	end if
	call_proc(forward_Statement_list, {})

    else 
	putback(tok)
	if TRANSLATE then
	    emit_op(NOP1)
	end if
	backpatch(prev_false, length(Code)+1)
	if prev_false2 != 0 then
	    backpatch(prev_false2, length(Code)+1)
	end if
    end if
   
    tok_match(END) 
    tok_match(IF)
    
    if TRANSLATE then
	if length(elist) > elist_base then
	    emit_op(NOP1)  -- to emit label here
	end if
    end if
    PatchEList(elist_base)
end procedure


procedure While_statement()
-- Parse a while loop 
    integer bp1 
    integer bp2
    integer exit_base

    if TRANSLATE then
	emit_op(NOPWHILE)
    end if
    bp1 = length(Code)+1
    short_circuit += 1
    short_circuit_B = FALSE
    SC1_type = 0
    Expr()
    tok_match(DO)
    optimized_while = FALSE
    emit_op(WHILE)
    short_circuit -= 1
    if not optimized_while then
	-- WHILE was emitted or combined into IFW op 
	bp2 = length(Code)+1
	emit_forward_addr() -- will be patched 
    else -- WHILE TRUE was optimized to nothing 
	bp2 = 0
    end if
    loop_nest += 1
    exit_base = length(exit_list)
    if SC1_type = OR then
	backpatch(SC1_patch-3, SC1_OR_IF)
	if TRANSLATE then
	    emit_op(NOP1)
	end if
	backpatch(SC1_patch, length(Code)+1)
    elsif SC1_type = AND then
	backpatch(SC1_patch-3, SC1_AND_IF)
	AppendXList(SC1_patch)
    end if
    call_proc(forward_Statement_list, {})
    tok_match(END)
    tok_match(WHILE)
    StartSourceLine(TRUE)
    emit_op(ENDWHILE)
    loop_nest -= 1
    emit_addr(bp1)
    if TRANSLATE then
	emit_op(NOP1)
    end if
    if bp2 != 0 then
	backpatch(bp2, length(Code)+1)
    end if
    PatchXList(exit_base)
end procedure

function SetPrivateScope(symtab_index s, symtab_index type_sym, integer n)
-- establish private scope for variable s in SymTab 
-- (index may be changed - new value is returned) 
    integer hashval, scope
    symtab_index t
    
    scope = SymTab[s][S_SCOPE]
    
    if find(scope, {SC_PRIVATE, SC_LOOP_VAR}) then
	DefinedYet(s)
	return s

    elsif find(scope, {SC_UNDEFINED, SC_MULTIPLY_DEFINED}) then
	SymTab[s][S_SCOPE] = SC_PRIVATE
	SymTab[s][S_VARNUM] = n
	SymTab[s][S_VTYPE] = type_sym
	return s

    elsif find(scope, {SC_LOCAL, SC_GLOBAL, SC_PREDEF}) then
	hashval = SymTab[s][S_HASHVAL]
	t = buckets[hashval]
	buckets[hashval] = NewEntry(SymTab[s][S_NAME], n, SC_PRIVATE, 
				    VARIABLE, hashval, t, type_sym)
	return buckets[hashval]
    else
	InternalErr("SetPS")
	
    end if
    
    return 0
end function

procedure For_statement()
-- Parse a for statement 
    integer bp1
    integer exit_base
    token tok, loop_var
    symtab_index loop_var_sym
    boolean def1
    
    loop_var = next_token()
    if not find(loop_var[T_ID], {VARIABLE, FUNC, TYPE, PROC}) then
	CompileErr("a loop variable name is expected here")
    end if

    if BIND then
	add_ref(loop_var)
    end if
   
    tok_match(EQUALS)
    Expr()
    tok_match(TO)
    loop_nest += 1
    exit_base = length(exit_list)    
    Expr()
    tok = next_token()
    if tok[T_ID] = BY then
	Expr()
	def1 = FALSE
    else 
	emit_opnd(NewIntSym(1))
	putback(tok)
	def1 = TRUE
    end if

    loop_var_sym = loop_var[T_SYM]
    if CurrentSub = TopLevelSub then
	DefinedYet(loop_var_sym)
	SymTab[loop_var_sym][S_SCOPE] = SC_GLOOP_VAR
	SymTab[loop_var_sym][S_VTYPE] = object_type
    else 
	loop_var_sym = SetPrivateScope(loop_var_sym, object_type, param_num)
	param_num += 1
	SymTab[loop_var_sym][S_SCOPE] = SC_LOOP_VAR
    end if
    SymTab[loop_var_sym][S_USAGE] = or_bits(SymTab[loop_var_sym][S_USAGE], 
					  or_bits(U_READ, U_WRITTEN))

    op_info1 = loop_var_sym
    emit_op(FOR)
    emit_addr(loop_var_sym)
    tok_match(DO)
    bp1 = length(Code)+1
    emit_addr(0) -- will be patched - don't straighten 
    if not TRANSLATE then
	if OpTrace then
	    emit_op(DISPLAY_VAR)
	    emit_addr(loop_var_sym)
	end if
    end if
    call_proc(forward_Statement_list, {})
    tok_match(END)
    tok_match(FOR)
    StartSourceLine(TRUE)
    op_info1 = loop_var_sym
    op_info2 = bp1 + 1
    if def1 then
	emit_op(ENDFOR_INT_UP1) -- (loop var might not be integer)
    else
	emit_op(ENDFOR_GENERAL) -- will be set at runtime by FOR op 
    end if
    backpatch(bp1, length(Code)+1)
    PatchXList(exit_base)
    loop_nest -= 1
    if not TRANSLATE then
	if OpTrace then
	    emit_op(ERASE_SYMBOL)
	    emit_addr(loop_var_sym)
	end if
    end if  
    Hide(loop_var_sym)
end procedure

function CompileType(symtab_index type_ptr)
-- Translator only: set the compile type for a variable 
    integer t
    
    if SymTab[type_ptr][S_TOKEN] = OBJECT then
	return TYPE_OBJECT 
      
    elsif type_ptr = integer_type then
	return TYPE_INTEGER
      
    elsif type_ptr = atom_type then
	return TYPE_ATOM 
      
    elsif type_ptr = sequence_type then
	return TYPE_SEQUENCE 
      
    elsif type_ptr = object_type then
	return TYPE_OBJECT
      
    else 
	-- user defined - look at type of the parameter of the type
	t = SymTab[SymTab[type_ptr][S_NEXT]][S_VTYPE]
	if t = integer_type then
	    return TYPE_INTEGER 
	elsif t = atom_type then
	    return TYPE_ATOM
	elsif t = sequence_type then
	    return TYPE_SEQUENCE 
	else    
	    return TYPE_OBJECT
	end if
    end if    
end function

procedure Global_declaration(symtab_index type_ptr, integer is_global)
-- parse a command-level variable or constant declaration 
-- type_ptr is NULL if constant 
    token tok
    symtab_index sym
    integer h

    while TRUE do 
	tok = next_token()
	if not find(tok[T_ID], {VARIABLE, FUNC, TYPE, PROC}) then
	    CompileErr("a name is expected here")
	end if
	sym = tok[T_SYM]
	DefinedYet(sym)
	if find(SymTab[sym][S_SCOPE], {SC_GLOBAL, SC_PREDEF}) then
	    h = SymTab[sym][S_HASHVAL]
	    -- create a new entry at beginning of this hash chain 
	    sym = NewEntry(SymTab[sym][S_NAME], 0, 0, VARIABLE, h, buckets[h], 0) 
	    buckets[h] = sym
	    -- more fields set below: 
	end if
	if is_global then
	    SymTab[sym][S_SCOPE] = SC_GLOBAL 
	else    
	    SymTab[sym][S_SCOPE] = SC_LOCAL
	end if
	if type_ptr = 0 then
	    -- CONSTANT 
	    SymTab[sym][S_MODE] = M_CONSTANT 
	    -- temporarily hide sym so it can't be used in defining itself 
	    buckets[SymTab[sym][S_HASHVAL]] = SymTab[sym][S_SAMEHASH]
	    tok_match(EQUALS)
	    StartSourceLine(FALSE)
	    emit_opnd(sym)
	    Expr()  -- no new symbols can be defined in here 
	    buckets[SymTab[sym][S_HASHVAL]] = sym
	    SymTab[sym][S_USAGE] = U_WRITTEN     
	   
	    if TRANSLATE then
		SymTab[sym][S_GTYPE] = TYPE_OBJECT 
		SymTab[sym][S_OBJ] = NOVALUE     -- distinguish from literals
	    end if
	   
	    emit_op(ASSIGN)
	else 
	    -- variable 
	    SymTab[sym][S_MODE] = M_NORMAL
	    if SymTab[type_ptr][S_TOKEN] = OBJECT then
		SymTab[sym][S_VTYPE] = object_type
	    else 
		SymTab[sym][S_VTYPE] = type_ptr
	    end if
	   
	    if TRANSLATE then
		SymTab[sym][S_GTYPE] = CompileType(type_ptr)
	    end if
       
	end if
	tok = next_token()
	if tok[T_ID] != COMMA then
	    exit
	end if
    end while 
    putback(tok)
end procedure

procedure Private_declaration(symtab_index type_sym)
-- parse a private declaration of one or more variables 
    token tok
    symtab_index sym
	
    while TRUE do 
	tok = next_token()
	if not find(tok[T_ID], {VARIABLE, FUNC, TYPE, PROC, NAMESPACE}) then
	    CompileErr("a variable name is expected here")
	end if
	sym = SetPrivateScope(tok[T_SYM], type_sym, param_num)
	param_num += 1
       
	if TRANSLATE then
	    SymTab[sym][S_GTYPE] = CompileType(type_sym)
	end if
       
	tok = next_token()
	if tok[T_ID] != COMMA then
	    exit
	end if
    end while 
    putback(tok)
end procedure


procedure Procedure_call(token tok)
-- parse a procedure call statement 
    integer n, scope, opcode
    token temp_tok
    symtab_index s
    
    tok_match(LEFT_ROUND)
    s = tok[T_SYM] 
    n = SymTab[s][S_NUM_ARGS]
    scope = SymTab[s][S_SCOPE]
    opcode = SymTab[s][S_OPCODE]
    if SymTab[s][S_EFFECT] then
	SymTab[CurrentSub][S_EFFECT] = or_bits(SymTab[CurrentSub][S_EFFECT],
					       SymTab[s][S_EFFECT])
    end if
    ParseArgs(s)
    if scope = SC_PREDEF then
	emit_op(opcode)
	if opcode = ABORT then
	    temp_tok = next_token()
	    putback(temp_tok)
	    NotReached(temp_tok[T_ID], "abort()")
	end if
    else 
	op_info1 = s
	emit_op(PROC)
	if not TRANSLATE then
	    if OpTrace then
		emit_op(UPDATE_GLOBALS)
	    end if
	end if  
    end if
end procedure

procedure Print_statement()
-- parse a '?' print statement 
    emit_opnd(NewIntSym(1)) -- stdout 
    Expr()
    emit_op(QPRINT)
    SymTab[CurrentSub][S_EFFECT] = or_bits(SymTab[CurrentSub][S_EFFECT],
					   E_OTHER_EFFECT)
end procedure

procedure Statement_list()
-- Parse a list of statements 
    token tok
    integer id
    
    stmt_nest += 1
    while TRUE do 
	tok = next_token()
	id = tok[T_ID]
	
	if id = VARIABLE or id = QUALIFIED_VARIABLE then
	    StartSourceLine(TRUE)
	    Assignment(tok)
	    
	elsif id = PROC or id = QUALIFIED_PROC then
	    StartSourceLine(TRUE)
	    Procedure_call(tok)
	    
	elsif id = IF then
	    StartSourceLine(TRUE)
	    If_statement()
	    
	elsif id = FOR then
	    StartSourceLine(TRUE)
	    For_statement()
	    
	elsif id = RETURN then
	    StartSourceLine(TRUE)
	    Return_statement()
	    
	elsif id = EXIT then
	    StartSourceLine(TRUE)
	    Exit_statement()
	    
	elsif id = WHILE then
	    StartSourceLine(TRUE)
	    While_statement()
	    
	elsif id = QUESTION_MARK then
	    StartSourceLine(TRUE)
	    Print_statement()

	else 
	    putback(tok)
	    stmt_nest -= 1
	    InitDelete()
	    return
	
	end if
    end while
end procedure

forward_Statement_list = routine_id("Statement_list")

procedure SubProg(integer prog_type, integer is_global)
-- parse a function, type or procedure 
-- global is 1 if it's global 
    integer h, pt
    symtab_index p, type_sym, sym
    token tok, prog_name

    LeaveTopLevel()

    prog_name = next_token()
    if not find(prog_name[T_ID], {VARIABLE, FUNC, TYPE, PROC}) then
	CompileErr("a name is expected here")
    end if
    p = prog_name[T_SYM] 

    DefinedYet(p)

    if prog_type = PROCEDURE then
	pt = PROC
    elsif prog_type = FUNCTION then
	pt = FUNC
    else        
	pt = TYPE
    end if
    
    if find(SymTab[p][S_SCOPE], {SC_PREDEF, SC_GLOBAL}) then
	-- redefine by creating new symbol table entry 
	if SymTab[p][S_SCOPE] = SC_PREDEF then  -- only warn about overriding predefined
	    Warning(sprintf("built-in routine %s() redefined", 
			    {SymTab[p][S_NAME]}))
	end if
	h = SymTab[p][S_HASHVAL]
	sym = buckets[h]
	p = NewEntry(SymTab[p][S_NAME], 0, 0, pt, h, sym, 0) 
	buckets[h] = p
    end if
    CurrentSub = p
    temps_allocated = 0
    
    if is_global then
	SymTab[p][S_SCOPE] = SC_GLOBAL
    else
	SymTab[p][S_SCOPE] = SC_LOCAL
    end if
    
    SymTab[p][S_TOKEN] = pt
    
    if length(SymTab[p]) < SIZEOF_ROUTINE_ENTRY then
	-- expand var entry to routine entry
	SymTab[p] = SymTab[p] & repeat(0, SIZEOF_ROUTINE_ENTRY - 
				       length(SymTab[p]))
    end if
    
    SymTab[p][S_CODE] = 0
    SymTab[p][S_LINETAB] = 0
    SymTab[p][S_EFFECT] = E_PURE
    SymTab[p][S_REFLIST] = {}
    SymTab[p][S_FIRSTLINE] = gline_number
    SymTab[p][S_TEMPS] = 0
    SymTab[p][S_RESIDENT_TASK] = 0
    SymTab[p][S_SAVED_PRIVATES] = {}
    
    StartSourceLine(FALSE)  
    tok_match(LEFT_ROUND)
    tok = next_token()
    param_num = 0
    while tok[T_ID] != RIGHT_ROUND do
	-- parse the parameter declarations
	if tok[T_ID] != TYPE and tok[T_ID] != QUALIFIED_TYPE then
	    if tok[T_ID] = VARIABLE or tok[T_ID] = QUALIFIED_VARIABLE then
		UndefinedVar(tok[T_SYM])
	    end if
	    CompileErr("a type is expected here")            
	end if
	type_sym = tok[T_SYM]
	tok = next_token()
	if not find(tok[T_ID], {VARIABLE, FUNC, TYPE, PROC, NAMESPACE}) then
	    CompileErr("a parameter name is expected here")
	end if
	sym = SetPrivateScope(tok[T_SYM], type_sym, param_num)
	param_num += 1
       
	if TRANSLATE then
	    SymTab[sym][S_GTYPE] = CompileType(type_sym)
	end if
       
	SymTab[sym][S_USAGE] = U_WRITTEN     
	tok = next_token()
	if tok[T_ID] = COMMA then
	    tok = next_token()
	    if tok[T_ID] = RIGHT_ROUND then
		CompileErr("expected to see a parameter declaration, not ')'")
	    end if
	elsif tok[T_ID] != RIGHT_ROUND then
	    CompileErr("badly-formed list of parameters - expected ',' or ')'")
	end if
    end while

    SymTab[p][S_NUM_ARGS] = param_num
    if TRANSLATE then
	if param_num > max_params then
	    max_params = param_num
	end if
	num_routines += 1
    end if
    if SymTab[p][S_TOKEN] = TYPE and param_num != 1 then
	CompileErr("types must have exactly one parameter")
    end if
    tok = next_token()
    -- parameters are numbered: 0, 1, ... num_args-1 
    -- other privates are numbered: num_args, num_args+1, ... 
    while tok[T_ID] = TYPE or tok[T_ID] = QUALIFIED_TYPE do
	-- parse the next private variable declaration
	Private_declaration(tok[T_SYM])
	tok = next_token()
    end while

    -- start of executable code for subprogram: 

    -- code to perform type checks on all the parameters 
    sym = SymTab[p][S_NEXT]
    for i = 1 to SymTab[p][S_NUM_ARGS] do
	TypeCheck(sym)
	sym = SymTab[sym][S_NEXT]
    end for

    if not TRANSLATE then
	if OpTrace then
	    -- clear any private names from screen 
	    emit_op(ERASE_PRIVATE_NAMES)
	    emit_addr(p)
	    -- display initial values of all the parameters 
	    sym = SymTab[p][S_NEXT]
	    for i = 1 to SymTab[p][S_NUM_ARGS] do
		emit_op(DISPLAY_VAR)
		emit_addr(sym)
		sym = SymTab[sym][S_NEXT]
	    end for
	    -- globals may have changed 
	    emit_op(UPDATE_GLOBALS)
	end if
    end if
    putback(tok)

    FuncReturn = FALSE
    Statement_list()
    tok_match(END)
    ExitScope()
    tok_match(prog_type)
    if prog_type != PROCEDURE then
	if not FuncReturn then
	    if prog_type = FUNCTION then
		CompileErr("no value returned from function")
	    else
		CompileErr("type must return true / false value")
	    end if
	end if
	emit_op(BADRETURNF) -- function/type shouldn't reach here 
    
    else 
	StartSourceLine(TRUE)
	if not TRANSLATE then
	    if OpTrace then
		emit_op(ERASE_PRIVATE_NAMES)
		emit_addr(p)
	    end if
	end if      
	emit_op(RETURNP)
	if TRANSLATE then
	    emit_op(BADRETURNF) -- just to mark end of procedure
	end if  
    end if
    
    SymTab[p][S_STACK_SPACE] = temps_allocated + param_num
    if temps_allocated + param_num > max_stack_per_call then 
	max_stack_per_call = temps_allocated + param_num
    end if
    
    StraightenBranches()
    EnterTopLevel()
end procedure

global procedure InitGlobals()
-- initialize global variables 
    ResetTP()
    OpTypeCheck = TRUE
    OpWarning = TRUE
end procedure

procedure not_supported_compile(sequence feature)
-- Report that a compile-time feature is not supported in this platform
    CompileErr(sprintf("%s is not supported in Euphoria for %s", 
		  {feature, version_name}))  
end procedure

sequence mix_msg
mix_msg = "can't mix profile and profile_time"

procedure SetWith(integer on_off)
-- set a with/without option 
    sequence option
    token tok
    
    option = StringToken()
    
    if equal(option, "type_check") then
	OpTypeCheck = on_off

    elsif equal(option, "profile") then
	if not TRANSLATE and not BIND then
	    OpProfileStatement = on_off
	    if OpProfileStatement then
		if AnyTimeProfile then
		    Warning(mix_msg)
		    OpProfileStatement = FALSE
		else
		    AnyStatementProfile = TRUE
		end if
	    end if
	end if
    
    elsif equal(option, "profile_time") then
	if not TRANSLATE and not BIND then
	    if not EDOS then
		if on_off then
		    not_supported_compile("profile_time")
		end if
	    end if
	    OpProfileTime = on_off
	    if OpProfileTime then
		if AnyStatementProfile then
		    Warning(mix_msg)
		    OpProfileTime = FALSE
		end if
		tok = next_token()
		if tok[T_ID] = ATOM then
		    if integer(SymTab[tok[T_SYM]][S_OBJ]) then
			sample_size = SymTab[tok[T_SYM]][S_OBJ]
		    else
			sample_size = -1
		    end if
		    if sample_size < 1 and OpProfileTime then
			CompileErr("sample size must be a positive integer")
		    end if
		else 
		    putback(tok)
		    sample_size = DEFAULT_SAMPLE_SIZE
		end if
		if OpProfileTime then
		    if EDOS then
			AnyTimeProfile = TRUE
		    end if
		end if
	    end if
	end if  
    
    elsif equal(option, "trace") then
	if not BIND then 
	    OpTrace = on_off
	end if
    
    elsif equal(option, "warning") then
	OpWarning = on_off
    
    elsif on_off and option[1] >= '0' and option[1] <= '9' then
	-- Ignore numeric stamp - not supported anymore
    
    else 
	CompileErr("unknown with/without option")
    
    end if
end procedure

procedure ExecCommand()
-- execute a top-level command  
    if TRANSLATE then
	emit_op(RETURNT)
    end if
    StraightenBranches()  -- straighten top-level
end procedure

global procedure parser()
-- top level of the parser - command level 
    token tok
    integer id
    
    tok = next_token()
    while TRUE do  -- infinite loop until scanner aborts
	start_index = length(Code)+1
	id = tok[T_ID]
	if id = VARIABLE or id = QUALIFIED_VARIABLE then
	    StartSourceLine(TRUE)
	    Assignment(tok)
	    ExecCommand()

	elsif id = PROCEDURE or id = FUNCTION or id = TYPE_DECL then
	    SubProg(tok[T_ID], 0)

	elsif id = GLOBAL then
	    tok = next_token()
	    id = tok[T_ID]
	    if id = TYPE then
		Global_declaration(tok[T_SYM], 1)
	    elsif id = CONSTANT then
		Global_declaration(0, 1)
		ExecCommand()
	    elsif id = PROCEDURE or id = FUNCTION or id = TYPE_DECL then
		SubProg(id, 1)
	    else 
		if id = VARIABLE or id = QUALIFIED_VARIABLE then
		    UndefinedVar(tok[T_SYM])
		end if
		CompileErr(
"'global' must be followed by:\n     <a type>, 'constant', 'procedure', 'type' or 'function'")
	    end if
		
	elsif id = TYPE or id = QUALIFIED_TYPE then
	    Global_declaration(tok[T_SYM], 0)

	elsif id = CONSTANT then
	    Global_declaration(0, 0)
	    ExecCommand()

	elsif id = IF then
	    StartSourceLine(TRUE)
	    If_statement()
	    ExecCommand()

	elsif id = FOR then
	    StartSourceLine(TRUE)
	    For_statement()
	    ExecCommand()

	elsif id = WHILE then
	    StartSourceLine(TRUE)
	    While_statement()
	    ExecCommand()

	elsif id = PROC or id = QUALIFIED_PROC then
	    StartSourceLine(TRUE)
	    Procedure_call(tok)
	    ExecCommand()
	    
	elsif id = FUNC or id = QUALIFIED_FUNC then
	    CompileErr("function result must be assigned or used")
		
	elsif id = RETURN then
	    Return_statement() -- will fail - not allowed at top level

	elsif id = EXIT then
	    CompileErr("exit must be inside a loop")                 

	elsif id = INCLUDE then
	    IncludeScan()

	elsif id = WITH then
	    SetWith(TRUE)

	elsif id = WITHOUT then
	    SetWith(FALSE)

	elsif id = END_OF_FILE then
	    if IncludePop() then
		read_line()
	    else
		exit -- all finished
	    end if
	
	elsif id = QUESTION_MARK then
	    StartSourceLine(TRUE)
	    Print_statement()
	    ExecCommand()
	    
	elsif id = ILLEGAL_CHAR then
	    CompileErr("illegal character")
	
	else 
	    CompileErr("unknown command")

	end if
	
	tok = next_token()
    end while 
    
    emit_op(RETURNT)
    StraightenBranches()
    SymTab[TopLevelSub][S_CODE] = Code
    EndLineTable()
    SymTab[TopLevelSub][S_LINETAB] = LineTable
end procedure

