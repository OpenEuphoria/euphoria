-- (c) Copyright - See License.txt

ifdef ETYPE_CHECK then
	with type_check
elsedef
	without type_check
end ifdef

without trace

include std/text.e
include std/pretty.e
include std/error.e
include std/map.e
include dot.e
include std/sort.e
include std/cmdline.e
include std/math.e

include mode.e as mode
include cominit.e
include intinit.e
include traninit.e
include opnames.e
include global.e
include reswords.e
include symtab.e
include scanner.e
include fwdref.e
include c_out.e

include dox.e as dox

integer out, pc, a, b, c, d, target, len, keep_running
sequence operation


procedure RTInternal(sequence msg)
-- Internal errors in back-end
	--puts(2, '\n' & msg & '\n')
	--? 1/0
    -- M_CRASH = 67
	machine_proc(67, msg)
end procedure

sequence ps_options = PRETTY_DEFAULT
ps_options[DISPLAY_ASCII] = 2
ps_options[LINE_BREAKS]   = 0
function name_or_literal( integer sym )
	if not sym then
		return "[0: ???]"
	elsif sym < 0 then
		return sprintf("[UNRESOLVED FORWARD REFERENCE: %d]", sym )
	elsif sym > length(SymTab) then
		return sprintf("[_invalid_:%d]", sym )
	elsif length(SymTab[sym]) = 1 then
		return sprintf("[_deleted_:%d]", sym)
	elsif length(SymTab[sym]) >= SIZEOF_VAR_ENTRY then
		return sprintf("[%s:%d]", {SymTab[sym][S_NAME],sym})
	elsif SymTab[sym][S_MODE] = M_TEMP and equal( SymTab[sym][S_OBJ], NOVALUE ) then
		return sprintf("[_temp_:%d]", sym)
	else
		return sprintf("[LIT %s:%d]",{ pretty_sprint(SymTab[sym][S_OBJ], ps_options), sym})
	end if
end function

function names( object n )
	if atom( n ) then
		n = { n }
	end if
	sequence nl
	nl = {}
	for i = 1 to length(n) do
		if n[i] then
			nl = append( nl, name_or_literal(n[i]))
		else
			nl = append( nl, "[0]" )
		end if
	end for
	return nl
end function

procedure il( sequence dsm, integer len )
	sequence format, code
	integer line, space

	format = "%6d: %03d"
	for i = 1 to len do
		format &= " %d"
	end for
	code = sprintf( format, pc & Code[pc..$] )
	line = 1
	while length(code) > 40 do

		for c = 40 to 1 by -1 do
			if code[c] = 32 then
				if line > 1 then
					code = "        " & code
					printf( out, "\n%-40s # ", {"        " & code[1..c]})
				else
					printf( out, "%-40s # ", {code[1..c]})
				end if

				line += 1
				code = code[c+1..$]
				exit
			end if
		end for
	end while
	if length(code) then
		if line > 1 then
			printf( out, "\n%-40s # ", {"        " & code})
		else
			printf( out, "%-40s # ", {code})
		end if
	end if
	line = 1
	while length(dsm) > 60 do
		space = 0
		for i = 60 to length(dsm) do
			if dsm[i] = 32 then
				if line > 1 then
					puts( out, repeat( 32, 41 ) & "#     " )
				end if
				puts( out, dsm[1..i] & "\n")
				dsm = dsm[i+1..$]
				line += 1
				space = 1
				exit
			end if
		end for
		if not space then
			exit
		end if
	end while
	if length(dsm) then
		if line > 1 then
			puts( out, repeat( 32, 41 ) & "#     " )
		end if
		puts( out, dsm & "\n")
	end if

end procedure

procedure quadary()
	il( sprintf( "%s: %s, %s, %s, %s => %s", {opnames[Code[pc]]} & names(Code[pc+1..pc+5])), 5)
	pc += 6
end procedure

procedure pquadary()
	il( sprintf( "%s: %s, %s, %s %s", {opnames[Code[pc]]} & names(Code[pc+1..pc+4])), 4)
	pc += 5
end procedure


procedure trinary()
	il( sprintf( "%s: %s, %s, %s => %s", {opnames[Code[pc]]} & names(Code[pc+1..pc+4])), 4)
	pc += 5
end procedure

procedure ptrinary()
	il( sprintf( "%s: %s, %s, %s", {opnames[Code[pc]]} & names(Code[pc+1..pc+3])), 3)
	pc += 4
end procedure

procedure binary()
	il( sprintf( "%s: %s, %s => %s", {opnames[Code[pc]]} & names(Code[pc+1..pc+3])), 3)
	pc += 4
end procedure

procedure pbinary()
	il( sprintf( "%s: %s, %s", {opnames[Code[pc]]} & names(Code[pc+1..pc+2])), 2)
	pc += 3
end procedure

procedure unary( )
	il( sprintf( "%s: %s => %s", {opnames[Code[pc]]} & names(Code[pc+1..pc+2])), 2)
	pc += 3
end procedure

procedure punary( )
	il( sprintf( "%s: %s ", {opnames[Code[pc]]} & names(Code[pc+1..pc+1])), 1)
	pc += 2
end procedure

procedure nonary()
	il( sprintf( "%s: %s", {opnames[Code[pc]], name_or_literal( Code[pc+1])}), 1)
	pc += 2
end procedure

procedure pnonary()
	il( sprintf( "%s:", {opnames[Code[pc]]}), 0)
	pc += 1
end procedure

procedure opCOVERAGE_LINE()

	object line
	sequence entry_
	integer lx


	lx = Code[pc+1]
	symtab_index sub = Code[pc+2]
	if atom(slist[$]) then
		slist = s_expand( slist )
	end if

	if atom(slist[lx][SRC]) then
		slist[lx][SRC] = fetch_line(slist[lx][SRC])
	end if

	entry_ = slist[Code[pc+1]]
	line = entry_[SRC]
	if atom(line) then
		line = ""
	else
		while length(line) and find( line[1], "\t " ) do
			line = line[2..$]
		end while
	end if

	il( sprintf( "%s: %s:(%d)<<%s>>", {opnames[Code[pc]],  known_files[entry_[LOCAL_FILE_NO]], entry_[LINE] ,line}), 1)
	pc += 2
end procedure

include std/filesys.e
procedure opCOVERAGE_ROUTINE()
	il( sprintf( "%s: %s:%s\n",
		{ opnames[Code[pc]], canonical_path( known_files[ SymTab[Code[pc+1]][S_FILE_NO] ] ),
			sym_name( Code[pc+1] ) }  ), 1 )
	pc += 2
end procedure

procedure opSTARTLINE()
-- Start of a line. Use for diagnostics.
	object line
	sequence entry_
	integer lx

	lx = Code[pc+1]
	if atom(slist[$]) then
		slist = s_expand( slist )
	end if

	if atom(slist[lx][SRC]) then
		slist[lx][SRC] = fetch_line(slist[lx][SRC])
	end if

	entry_ = slist[Code[pc+1]]
	line = entry_[SRC]
	if atom(line) then
		line = ""
	else
		while length(line) and find( line[1], "\t " ) do
			line = line[2..$]
		end while
	end if
	il( sprintf( "%s: %s(%d)<<%s>>", {opnames[Code[pc]], known_files[entry_[LOCAL_FILE_NO]],entry_[LINE] ,line}), 1)

	pc += 2
end procedure

procedure opREF_TEMP()
	punary()
end procedure

procedure opDEREF_TEMP()
	punary()
end procedure

procedure opNOVALUE_TEMP()
	punary()
end procedure

procedure opTASK_YIELD()
-- temporarily stop running this task, and give the scheduler a chance
-- to pick a new task
	pnonary()
end procedure

procedure opTASK_STATUS()
-- return task status
	unary()
end procedure

procedure opTASK_LIST()
-- return list of active and suspended tasks
	nonary()
end procedure

procedure opTASK_SELF()
-- return current task id
	nonary()
end procedure

atom save_clock
save_clock = -1

procedure opTASK_CLOCK_STOP()
-- stop the scheduler clock
	pnonary()
end procedure

procedure opTASK_CLOCK_START()
-- resume the scheduler clock
	pnonary()
end procedure

procedure opTASK_SUSPEND()
-- suspend a task
	punary()
end procedure

procedure opTASK_CREATE()
-- create a new task
	binary()
end procedure

procedure opTASK_SCHEDULE()
-- schedule a task by linking it into the real-time tcb queue,
-- or the time sharing tcb queue
	pbinary()
end procedure

procedure opEMBEDDED_PROCEDURE_CALL()
	pbinary()
end procedure

procedure opEMBEDDED_FUNCTION_CALL()
	binary()
end procedure

-- based on execute.e
function find_line(symtab_index sub, integer pc, integer file_only = 1)
-- return the file name and line that matches pc in sub
	sequence linetab
	integer line, gline

	linetab = SymTab[sub][S_LINETAB]
	line = 1
	for i = 1 to length(linetab) do
		if linetab[i] >= pc or linetab[i] = -2 then
			line = i-1
			while line > 1 and linetab[line] = -1 do
				line -= 1
			end while
			exit
		end if
	end for
	gline = SymTab[sub][S_FIRSTLINE] + line - 1
	if file_only then
		return slist[gline][LOCAL_FILE_NO]
	
	elsif gline > length( slist ) or not gline then
		-- probably a bug with the line table code in the parser
		return { "??", -1, "???", gline }
	else
		return {known_files[slist[gline][LOCAL_FILE_NO]], slist[gline][LINE], slist[gline][SRC], gline}
	end if

end function

procedure opPROC()  -- Normal subroutine call
    integer n, arg, sub, top
    sequence dsm

    -- make a procedure or function/type call
    sub = Code[pc+1] -- subroutine
    n = SymTab[sub][S_NUM_ARGS]

	integer current_file
	if CurrentSub = TopLevelSub then
		current_file = find_line( sub, pc )
	else
		current_file = SymTab[CurrentSub][S_FILE_NO]
	end if

	-- record the data for the call graph
	-- called_from maps from the caller to the callee
	-- called_by maps from the callee back to the caller
	map:nested_put( called_from, { current_file, CurrentSub, SymTab[sub][S_FILE_NO], sub }, 1 , map:ADD )
	map:nested_put( called_by,   { SymTab[sub][S_FILE_NO], sub, current_file, CurrentSub }, 1, map:ADD )

    dsm = sprintf( "%s: %s",{opnames[Code[pc]],name_or_literal(sub)})

	for i = 1 to n do

		if i < n then
			dsm &= ", "
		end if
		arg = Code[pc + i + 1]
		dsm &= name_or_literal(arg)
	end for


    if SymTab[sub][S_TOKEN] != PROC then
    	dsm[1..4] = "FUNC"
		dsm &= sprintf( " => %s", {name_or_literal(Code[pc + n + 2])})
		il( dsm, n + 2 )
		pc += n + 3
	else
		il( dsm, n + 1 )
	    pc += n + 2
    end if
end procedure

integer result
result = 0
object result_val

procedure opRETURNP()   -- return from procedure (or function)
    pbinary()
--	pc += 3
end procedure

procedure opRETURNF()
-- return from function
	result_val = Code[pc+3]
	il(	sprintf( "RETURNF: %s block[%d]", {name_or_literal(result_val), Code[pc+2]}), 3)
	pc += 4
end procedure

procedure opCALL_BACK_RETURN()
--    keep_running = FALSE  -- force return from do_exec()
	il( "CALL_BACK_RETURN", 0 )
end procedure

procedure opBADRETURNF()  -- shouldn't reach here
	pnonary()
--    RTFatal("attempt to exit a function without returning a value")  -- end of a function
end procedure

procedure opRETURNT()   -- return from top-level "procedure"
	pnonary()
end procedure

procedure opRHS_SUBS() -- find(opcode, {RHS_SUBS_CHECK, RHS_SUBS,
		       -- RHS_SUBS_I}) then
    object sub, x

    a = Code[pc+1]
    b = Code[pc+2]
    target = Code[pc+3]
    il( sprintf("%s: %s sub %s => %s",{opnames[Code[pc]]} & names({a,b,target})), 3 )

    pc += 4
end procedure
--
procedure opIF()
    a = Code[pc+1]
    il(sprintf( "%s: %s = 0 goto %04d", {opnames[Code[pc]],name_or_literal(a), Code[pc+2]}),2)
    pc += 3
end procedure

procedure check()
	il( sprintf("%s: %s",{opnames[Code[pc]] ,name_or_literal(Code[pc+1])}), 1 )
	pc += 2
end procedure

procedure opINTEGER_CHECK()
	check()
end procedure

procedure opATOM_CHECK()
	check()
end procedure

procedure opSEQUENCE_CHECK()
	check()
end procedure
--
procedure opASSIGN()  -- or opASSIGN_I or SEQUENCE_COPY
    a = Code[pc+1]
    target = Code[pc+2]
    il( sprintf("%s => %s", names( {a,target} )), 2 )
    pc += 3
end procedure

procedure opMEMSTRUCT_ASSIGN()  -- or opASSIGN_I or SEQUENCE_COPY
    a = Code[pc+1]  -- pointer
    b = Code[pc+2]  -- member sym
    c = Code[pc+3]  -- new value
    il( sprintf("MEMSTRUCT_ASSIGN %s.%s = %s", names( {a, b, c} )), 3 )
    pc += 4
end procedure

procedure opELSE()  -- or EXIT, ENDWHILE}) then
	il( sprintf("%s goto %04d", {opnames[Code[pc]], Code[pc+1]}),1 )
--    pc = Code[pc+1]
	pc += 2
end procedure

procedure opRIGHT_BRACE_N()  -- form a sequence of any length
    sequence x

    len = Code[pc+1]
    x = sprintf("RIGHT_BRACE_N: len %d", len)

    for i = pc+len+1 to pc+2 by -1 do
		-- last one comes first
		x &= sprintf(", %s",{name_or_literal(Code[i])})
    end for
    target = Code[pc+len+2]
    x &= sprintf(" => %s", {name_or_literal(target)})
    il( x, len + 2 )
    pc += 3 + len
end procedure


procedure opRIGHT_BRACE_2()   -- form a sequence of length 2
	binary()
end procedure

procedure opPLUS1() --or opPLUS1_I then
    a = Code[pc+1]
    -- [2] is not used
    target = Code[pc+3]
    il( sprintf("PLUS1: %s + 1 => %s", names( a & target )), 3 )
    pc += 4
end procedure

procedure opGLOBAL_INIT_CHECK()  --or PRIVATE_INIT_CHECK then
    a = Code[pc+1]
    il( sprintf("%s: %s", {opnames[Code[pc]],name_or_literal(a)}), 1 )
    pc += 2
end procedure

procedure opWHILE()     -- sometimes emit.c optimizes this away
    a = Code[pc+1]
    il( sprintf("WHILE: %s goto %04d else goto %04d", {name_or_literal(a), pc+3, Code[pc+2]}), 2 )
    pc += 3
end procedure

procedure opLENGTH()
-- operand should be a sequence
    a = Code[pc+1]
    target = Code[pc+2]
    il( sprintf("LENGTH: %s => %s", names(a&target)), 2 )

    pc += 3
end procedure

-- Note: Multiple LHS subscripts, and $ within those subscripts,
-- is handled much more efficiently in the hand-coded C interpreter,
-- and in code translated to C, where C pointers can be used effectively.

procedure opPLENGTH()
-- Needed for some LHS uses of $. Operand should be a val index of a sequence,
-- with subscripts.
    a = Code[pc+1]
    target = Code[pc+2]
    il( sprintf("PLENGTH: %s => %s", names( a & target )), 2 )
    pc += 3
end procedure

procedure opLHS_SUBS()
-- Handle one LHS subscript, when there are multiple LHS subscripts.

    a = Code[pc+1] -- base var sequence, or a temp that contains
		   -- {base index, subs1, subs2... so far}
    b = Code[pc+2] -- subscript
    target = Code[pc+3] -- temp for storing result

    il( sprintf("LHS_SUBS: %s, %s => %s (UNUSED - %s)", names( Code[pc+1..pc+4] )), 4 )
    -- a is a "pointer" to the result of previous subscripting
--    val[target] = append(val[a], val[b])
    pc += 5
end procedure
--
procedure opLHS_SUBS1()
-- Handle first LHS subscript, when there are multiple LHS subscripts.

    a = Code[pc+1] -- base var sequence, or a temp that contains
		   -- {base index, subs1, subs2... so far}
    b = Code[pc+2] -- subscript
    target = Code[pc+3] -- temp for storing result
    il( sprintf("LHS_SUBS1: %s, %s => %s (UNUSED - %s)", names( Code[pc+1..pc+4] )), 4 )
    -- a is the base var
--    val[target] = {a, val[b]}
    pc += 5
end procedure

procedure opLHS_SUBS1_COPY()
-- Handle first LHS subscript, when there are multiple LHS subscripts.
-- In tricky situations a copy of the sequence is made into a temp.
-- (Protects against function call inside subscript expression.
-- In the C backend, it also prevents circular pointer references.)

    a = Code[pc+1] -- base var sequence

    b = Code[pc+2] -- subscript

    target = Code[pc+3] -- temp for storing result

    c = Code[pc+4] -- temp to hold base sequence while it's manipulated
    il( sprintf("LHS_SUBS1_COPY: %s, %s => (%s) %s", names( Code[pc+1..pc+4] )), 4 )
--    val[c] = val[a]

    -- a is the base var
--    val[target] = {c, val[b]}

    pc += 5
end procedure


procedure opASSIGN_SUBS() -- also ASSIGN_SUBS_CHECK, ASSIGN_SUBS_I
-- LHS single subscript and assignment
    object x, subs

    a = Code[pc+1]  -- the sequence
    b = Code[pc+2]  -- the subscript
    c = Code[pc+3]  -- the RHS value
--    x = val[a]
--    lhs_check_subs(x, val[b])
--    x = val[c]
--    subs = val[b]
--    val[a][subs] = x  -- single LHS subscript
	il( sprintf("%s: %s, %s <= %s", {opnames[Code[pc]]} & names( Code[pc+1..pc+3] )), 3 )
    pc += 4
end procedure

procedure opPASSIGN_SUBS()
-- final LHS subscript and assignment after a series of subscripts
    a = Code[pc+1]
    b = Code[pc+2]  -- subscript
    c = Code[pc+3]  -- RHS value

    -- multiple LHS subscript case
--    lhs_seq_index = val[a][1]
--    lhs_subs = val[a][2..$]
--    val[lhs_seq_index] = assign_subs(val[lhs_seq_index],
--					 lhs_subs & val[b],
--					 val[c])
	il( sprintf("PASSIGN_SUBS: %s, %s <= %s", names( Code[pc+1..pc+3] )), 3 )
    pc += 4
end procedure




procedure opASSIGN_OP_SUBS()  -- var[subs] op= expr
    object x

    a = Code[pc+1]
    b = Code[pc+2]
    target = Code[pc+3]
    -- var with one subscript
--    lhs_subs = {}
--    x = val[a]
--    val[target] = var_subs(x, lhs_subs & val[b])
	il( sprintf("ASSIGN_OP_SUBS: %s, %s => %s", names( Code[pc+1..pc+3] )), 3 )
    pc += 4
end procedure

procedure opPASSIGN_OP_SUBS()  -- var[subs] ... [subs] op= expr
    a = Code[pc+1]
    b = Code[pc+2]
    target = Code[pc+3]
    -- temp with multiple subscripts
--    lhs_seq_index = val[a][1]
--    lhs_subs = val[a][2..$]
	il( sprintf("PASSIGN_OP_SUBS: %s, %s => %s (patch %04dd => %d)",
		names( Code[pc+1..pc+3] ) & pc+9 & Code[pc+1]), 3 )
    Code[pc+9] = Code[pc+1] -- patch upcoming op
--    val[target] = var_subs(val[lhs_seq_index], lhs_subs & val[b])
    pc += 4
end procedure

procedure opASSIGN_OP_SLICE()  --then  -- var[i..j] op= expr
    object x

    a = Code[pc+1]

    b = Code[pc+2]
    c = Code[pc+3]
    target = Code[pc+4]
    il( sprintf("ASSIGN_OP_SLICE: %s, %s, %s => %s", names(a&b&c&target)),4 )
--    val[target] = var_slice(x, {}, val[b], val[c])
    pc += 5
end procedure

procedure opPASSIGN_OP_SLICE()  --then  -- var[subs] ... [i..j] op= expr
    object x

    a = Code[pc+1]

    b = Code[pc+2]
    c = Code[pc+3]
    target = Code[pc+4]
    il( sprintf("PASSIGN_OP_SLICE: %s, %s, %s => %s (patch %04d => %d",
    	names(a&b&c&target) & pc+10 & Code[pc+1]),4 )
    Code[pc+10] = Code[pc+1]

    pc += 5
end procedure

procedure opASSIGN_SLICE()   -- var[i..j] = expr
    object x

    a = Code[pc+1]  -- sequence
    b = Code[pc+2]  -- 1st index
    c = Code[pc+3]  -- 2nd index
    d = Code[pc+4]  -- rhs value to assign
    il(sprintf("ASSIGN_SLICE: %s %s..%s => %s", names({a,b,c,d})),4)
    pc += 5
end procedure

procedure opPASSIGN_SLICE()   -- var[x] ... [i..j] = expr
    a = Code[pc+1]  -- sequence
    b = Code[pc+2]  -- 1st index
    c = Code[pc+3]  -- 2nd index
    d = Code[pc+4]  -- rhs value to assign
    il(sprintf("PASSIGN_SLICE: %s %s..%s => %s", names({a,b,c,d})),4)
    pc += 5
end procedure

procedure opRHS_SLICE() -- rhs slice of a sequence a[i..j]
    object x

    a = Code[pc+1]  -- sequence
    b = Code[pc+2]  -- 1st index
    c = Code[pc+3]  -- 2nd index
    target = Code[pc+4]
    il(sprintf("RHS_SLICE: %s %s..%s => %s", names({a,b,c,target})),4)
    pc += 5
end procedure

procedure opTYPE_CHECK_FORWARD()
	il( sprintf("TYPE_CHECK_FORWARD: %s OpTypeCheck: %d", names({Code[pc+1]}) & Code[pc+2] ), 2 )
	pc += 3
end procedure

procedure opTYPE_CHECK()

	pnonary()

end procedure

procedure opMEM_TYPE_CHECK()

	punary()

end procedure


procedure is_an()
    a = Code[pc+1]
    target = Code[pc+2]
    il( sprintf("%s: %s %s",{ opnames[Code[pc]] } & names(a&target)), 2 )
    pc += 3
end procedure
procedure opIS_AN_INTEGER()
    is_an()
end procedure

procedure opIS_AN_ATOM()
    is_an()
end procedure

procedure opIS_A_SEQUENCE()
    is_an()
end procedure

procedure opIS_AN_OBJECT()
    is_an()
end procedure

--	-- ---------- start of unary ops -----------------
--
procedure opSQRT()
	unary()
end procedure

procedure opSIN()
	unary()
end procedure

procedure opCOS()
	unary()
end procedure

procedure opTAN()
	unary()
end procedure

procedure opARCTAN()
	unary()
end procedure

procedure opLOG()
	unary()
end procedure

procedure opNOT_BITS()
	unary()
end procedure

procedure opFLOOR()
	unary()
end procedure

procedure opNOT_IFW()
    a = Code[pc+1]
    il( sprintf( "NOT_IFW %s goto %04d else goto %04d",
    	{name_or_literal(a), pc + 3, Code[pc+2]}), 2 )
    pc += 3
end procedure

procedure opNOT()
	unary()
end procedure

procedure opUMINUS()
	unary()
end procedure

procedure opRAND()
	unary()
end procedure

procedure opDIV2()  -- like unary, but pc+=4

    a = Code[pc+1]
    -- Code[pc+2] not used
    target = Code[pc+3]
    il( sprintf("DIV2: %s => %s",names( a & target )), 3 )
    pc += 4
end procedure

procedure opFLOOR_DIV2()
    a = Code[pc+1]
    -- Code[pc+2] not used
    target = Code[pc+3]
    il( sprintf("FLOOR_DIV2: %s => %s",names( a & target )), 3 )
    pc += 4
end procedure

--	----------- start of binary ops ----------
--
procedure opGREATER_IFW()
    a = Code[pc+1]
    b = Code[pc+2]
    il( sprintf( "GREATER_IFW %s > %s goto %04d else goto %04d",
    	{name_or_literal(a),name_or_literal(b), pc + 4, Code[pc+3]}), 3 )
	pc += 4
end procedure
--
procedure opNOTEQ_IFW()
    a = Code[pc+1]
    b = Code[pc+2]
    il( sprintf( "NOTEQ_IFW %s != %s goto %04d else goto %04d",
    	{name_or_literal(a),name_or_literal(b), pc + 4, Code[pc+3]}), 3 )
	pc += 4
end procedure

procedure opLESSEQ_IFW()
    a = Code[pc+1]
    b = Code[pc+2]
    il( sprintf( "LESSEQ_IFW %s <= %s goto %04d else goto %04d",
    	{name_or_literal(a),name_or_literal(b), pc + 4, Code[pc+3]}), 3 )
	pc += 4

end procedure

procedure opGREATEREQ_IFW()
    a = Code[pc+1]
    b = Code[pc+2]
    il( sprintf( "GREATEREQ_IFW %s > %s goto %04d else goto %04d",
    	{name_or_literal(a),name_or_literal(b), pc + 4, Code[pc+3]}), 3 )
	pc += 4

end procedure

procedure opEQUALS_IFW()
    a = Code[pc+1]
    b = Code[pc+2]
	sequence i
	if Code[pc] = EQUALS_IFW then
		i = ""
	else
		i = "_I"
	end if
    il( sprintf( "EQUALS_IFW%s %s = %s goto %04d else goto %04d",
    	{i, name_or_literal(a),name_or_literal(b), pc + 4, Code[pc+3]}), 3 )
    pc += 4
end procedure

procedure opLESS_IFW()
    a = Code[pc+1]
    b = Code[pc+2]
    il( sprintf( "IFW %s < %s goto %04d else goto %04d",
    	{name_or_literal(a),name_or_literal(b), pc + 4, Code[pc+3]}), 3 )
    pc += 4
end procedure


--	-- other binary ops
--
procedure opMULTIPLY()
    binary()
end procedure

procedure opPLUS() -- or opPLUS_I then
    binary()
end procedure

procedure opMEMSTRUCT_PLUS()
	binary()
end procedure

procedure opMEMSTRUCT_MINUS()
	binary()
end procedure

procedure opMEMSTRUCT_MULTIPLY()
	binary()
end procedure

procedure opMEMSTRUCT_DIVIDE()
	binary()
end procedure

procedure opMINUS() -- or opMINUS_I then
    binary()
end procedure

procedure opOR()
    binary()
end procedure

procedure opXOR()
    binary()
end procedure

procedure opAND()
    binary()
end procedure

procedure opDIVIDE()
    binary()
end procedure

procedure opREMAINDER()
    binary()
end procedure

procedure opFLOOR_DIV()
    binary()
end procedure

procedure opAND_BITS()
    binary()
end procedure

procedure opOR_BITS()
    binary()
end procedure

procedure opXOR_BITS()
    binary()
end procedure

procedure opPOWER()
    binary()
end procedure

procedure opLESS()
    binary()
end procedure

procedure opGREATER()
    binary()
end procedure

procedure opEQUALS()
    binary()
end procedure

procedure opNOTEQ()
    binary()
end procedure

procedure opLESSEQ()
    binary()
end procedure

procedure opGREATEREQ()
    binary()
end procedure

-- short-circuit ops

procedure short_circuit()
    a = Code[pc+1]
    b = Code[pc+2]
    il( sprintf("%s: %s, %s, %04d", {opnames[Code[pc]]} & names(a&b) & Code[pc+3]), 3 )
    pc += 4
end procedure
procedure opSC1_AND()
	short_circuit()
end procedure

procedure opSC1_AND_IF()
	short_circuit()
end procedure

procedure opSC1_OR()
	short_circuit()
end procedure

procedure opSC1_OR_IF()
	short_circuit()
end procedure

procedure opSC2_OR() -- or opSC2_AND
-- short-circuit op
	pbinary()
end procedure

-- for loops

procedure opFOR()  -- or opFOR_I
-- enter into a for loop
    integer increment, limit, initial, loopvar, jump

    increment = Code[pc+1]
    limit = Code[pc+2]
    initial = Code[pc+3]
    -- ignore current_sub = Code[pc+4] - we don't patch the ENDFOR
    -- so recursion is not a problem
    loopvar = Code[pc+5]
    jump = Code[pc+6]

    il( sprintf("%s: inc %s, lim %s, initial %s, lv %s, jmp %04d",
    	{opnames[Code[pc]]} & names( Code[pc+1..pc+3] & Code[pc+5]) & Code[pc+6]), 6 )
    pc += 7
end procedure

procedure opENDFOR_GENERAL() -- ENDFOR_INT_UP,
			     -- ENDFOR_UP, ENDFOR_INT_DOWN1,
			     -- ENDFOR_INT_DOWN, ENDFOR_DOWN,
			     -- ENDFOR_GENERAL
-- end of for loop: exit or go back to the top
    il( sprintf("%s: top %04d lim %s, inc %s, lv %s",
    	{opnames[Code[pc]], Code[pc+1]} & names( Code[pc+2..pc+4] )), 4)
    pc += 5
end procedure

procedure opENDFOR_INT_UP1() -- ENDFOR_INT_UP1
-- faster: end of for loop with known +1 increment
-- exit or go back to the top
-- (loop var might not be integer, but that doesn't matter here)

    il( sprintf("ENDFOR_INT_UP1: top %04d, lim: %s, lv %s, inc %s",
    	Code[pc+1] & names( Code[pc+2..pc+4] )), 4)
    pc += 5
end procedure

--
--
--sequence e_routine -- list of routines with a routine id assigned to them
--e_routine = {}
--
procedure opCALL_PROC() -- or opCALL_FUNC
	sequence proc


    a = Code[pc+1]  -- routine id
    b = Code[pc+2]  -- argument list
    if Code[pc] = CALL_FUNC and pc + 3 <= length(Code) then
    	il( sprintf("%s: %s %s => %s", {opnames[Code[pc]]} & names( a&b & Code[pc+3]) ), 3 )
    else
    	il( sprintf("%s: %s %s", {opnames[Code[pc]]} & names( a&b) ), 2 )
    end if


    pc += 3 + (Code[pc] = CALL_FUNC)

end procedure

procedure opROUTINE_ID()
--    integer sub, fn, p
--    object name

--    sub = Code[pc+1]   -- CurrentSub
--    name = val[Code[pc+2]]  -- routine name sequence
--    fn = Code[pc+4]    -- file number
	if TRANSLATE then
		target = Code[pc+4]
		il( sprintf("ROUTINE_ID: (max=%d) %s => %s", Code[pc+1] & names( Code[pc+2] & target )), 4 )
    	pc += 5
    else
		target = Code[pc+5]
		il( sprintf("ROUTINE_ID: %s => %s", names( Code[pc+3] & target )), 5 )
		pc += 6
	end if
end procedure

procedure opAPPEND()
	binary()
end procedure

procedure opPREPEND()
	binary()

end procedure

procedure opCONCAT()
	binary()

end procedure

procedure opCONCAT_N()
    -- concatenate 3 or more items
    integer n
    object x

    n = Code[pc+1] -- number of items
    -- operands are in reverse order
    x = sprintf("CONCAT_N: %d", Code[pc+1] )
    for i = pc+2 to pc+n+1 do
		x &= sprintf(", %s", {name_or_literal(Code[i])})
    end for
    target = Code[pc+n+2]
    il( sprintf( "%s => %s", {x, name_or_literal( target )}), n + 2 )

    pc += n+3
end procedure

procedure opREPEAT()
	binary()

end procedure

procedure opDATE()
	nonary()
end procedure

procedure opTIME()
	nonary()
end procedure

procedure opSPACE_USED() -- RDS DEBUG only
	nonary()
--    pc += 2
end procedure

procedure opNOP1()
	pnonary()
end procedure

procedure opNOP2()   -- space filler
	il( sprintf("%s %d", {opnames[Code[pc]], Code[pc+1]}), 1 )
	pc += 2
end procedure

procedure opPOSITION()
	pbinary()
end procedure

procedure opEQUAL()
	binary()
end procedure

procedure opHASH()
	binary()
end procedure

procedure opCOMPARE()
	binary()
end procedure

procedure opFIND()
	binary()
end procedure

procedure opFIND_FROM()
	trinary()
end procedure

procedure opMATCH_FROM()
	trinary()
end procedure

procedure opMATCH()
	binary()
end procedure

procedure opPEEK()
	unary()
end procedure

procedure opPOKE()
	pbinary()
end procedure

procedure opSIZEOF()
	unary()
end procedure

procedure opADDRESSOF()
	unary()
end procedure

procedure opOFFSETOF()
	unary()
end procedure

procedure opMEM_COPY()
	ptrinary()
end procedure

procedure opMEM_SET()
	ptrinary()
end procedure

procedure opCALL()
	punary()
end procedure

procedure opSYSTEM()
	pbinary()
end procedure

procedure opSYSTEM_EXEC()
	binary()
end procedure

-- I/O routines

procedure opOPEN()
	trinary()
end procedure

procedure opCLOSE()
	punary()
end procedure

procedure opABORT()
	punary()
end procedure

procedure opGETC()  -- read a character from a file
	unary()
end procedure

procedure opGETS()  -- read a line from a file */
	unary()
end procedure

procedure opGET_KEY()
-- read an immediate key (if any) from the keyboard
-- or return -1
	nonary()
end procedure

procedure opCLEAR_SCREEN()
	pnonary()
end procedure

procedure opPUTS()
	pbinary()
end procedure
--
procedure opQPRINT()
-- Code[pc+1] not used

    a = Code[pc+2]
    il( sprintf( "QPRINT: %s",{name_or_literal( a )} ), 2 )
    pc += 3
end procedure

procedure opPRINT()
	pbinary()
end procedure

procedure opPRINTF()
    -- printf
    ptrinary()
end procedure

procedure opSPRINTF()
	binary()
end procedure

procedure opCOMMAND_LINE()
    sequence cmd
    nonary()
end procedure

procedure opGETENV()
	unary()
end procedure

procedure opC_PROC()
	il( sprintf( "%s: %s, %s", {opnames[Code[pc]]} & names(Code[pc+1..pc+2])), 3)
	pc += 4
end procedure

procedure opC_FUNC()
	il( sprintf( "%s: %s, %s (sub %s) => %s", {opnames[Code[pc]]} & names(Code[pc+1..pc+4])), 4)
	pc += 5
end procedure

procedure opTRACE()
	punary()
end procedure
--
-- other tracing/profiling ops - ignored
procedure opPROFILE() --or DISPLAY_VAR, ERASE_PRIVATE_NAMES, ERASE_SYMBOL
    -- NOT IMPLEMENTED, ignore
    punary()
--    pc += 2
end procedure

procedure opUPDATE_GLOBALS()
-- for interactive trace
	pnonary()
end procedure

procedure opMACHINE_FUNC()
	binary()
end procedure

procedure opMACHINE_PROC()
    pbinary()
end procedure

procedure opSWITCH()
	if Code[pc] = SWITCH_SPI then
		il( sprintf( "%s: value %s case offset %d jump %s else goto %d",
			{opnames[Code[pc]], name_or_literal( Code[pc+1] ), Code[pc+2], name_or_literal( Code[pc+3] ), Code[pc+4] } ), 5)
	else
		il( sprintf( "%s: value %s cases %s jump %s else goto %d",
			{opnames[Code[pc]]} & names(Code[pc+1..pc+3]) & Code[pc+4] ), 5)
	end if
	pc += 5
end procedure

procedure opCASE()
	-- only emitted for translator
	if Code[pc+1] then
		punary()
	else
		pnonary()
		pc += 1
	end if

end procedure

procedure opENTRY()
	-- nothing emitted
end procedure

procedure opOPTION_SWITCHES()
	nonary()
end procedure

procedure opNOPSWITCH()
	-- translator only
	pnonary()
end procedure

procedure opGLABEL()
	-- translator only
	il( sprintf("%s: %04d", {opnames[Code[pc]], Code[pc+1]}),1 )
	pc += 2
end procedure

procedure opSPLICE()
	trinary()
end procedure

procedure opINSERT()
	trinary()
end procedure

procedure opHEAD()
	binary()
end procedure

procedure opTAIL()
	binary()
end procedure

procedure opREMOVE()
	trinary()
end procedure

procedure opREPLACE()
	quadary()
end procedure

procedure opDELETE_ROUTINE()
	binary()
end procedure

procedure opDELETE_OBJECT()
	punary()
end procedure

procedure opEXIT_BLOCK()
	punary()
end procedure

procedure opMEMSTRUCT_ACCESS()
	-- pc+1 number of accesses
	-- pc+2 pointer to memstruct
	-- pc+3 .. pc+n+1 member syms for access
	-- pc+n+2 target for pointer
	integer members = Code[pc+1]
	sequence text = sprintf("MEMSTRUCT_ACCESS %s %s(", names( {Code[pc+2], SymTab[Code[pc+3]][S_MEM_PARENT]} ) )
	for i = pc+3 to pc+2+members do
		text &= sprintf(" %s", names( Code[i] ) )
	end for
	text &= sprintf(" ) => %s", names( Code[pc+members+3] ) )
	il( text, members + 3 )
	pc += members + 4
end procedure

procedure opMEMSTRUCT_ARRAY()
	trinary()
end procedure

procedure opPEEK_ARRAY()
	trinary()
end procedure

procedure opMEMSTRUCT_READ()
	binary()
end procedure

procedure opPEEK_MEMBER()
	binary()
end procedure

function strip_path( sequence file )
	for i = length( file ) to 1 by -1 do
		if find( file[i], "/\\" ) then
			return file[i+1..$]
		end if
	end for
	return file
end function

include dot.e

procedure make_pngs( sequence file )
		system( sprintf( "dot -Tpng %s.dot > %s.dot.png", repeat( file, 2 ) ), 2 )
		--system( sprintf( "fdp -Tpng %s.dot > %s.fdp.png", repeat( file, 2 ) ), 2 )
		--system( sprintf( "neato -Tpng %s.dot > %s.neato.png", repeat( file, 2 ) ), 2 )
		--system( sprintf( "twopi -Tpng %s.dot > %s.twopi.png", repeat( file, 2 ) ), 2 )
end procedure

procedure write_call_info( sequence name )
	-- The output of this procedure is meant to be post processed to
	-- create *.dot files to be used with something like graphviz to
	-- produce call graphs.  The *.calls file contains the raw maps, which
	-- can be used to generate more focused graphs (i.e., for individual
	-- routines).

	-- called_from:  file -> proc -> called_proc file : called proc
	-- called_by  :  called_proc file -> called proc -> file : proc
	sequence files = map:keys( called_from )

	integer fn = open( name & "calls", "w" )
	sequence pp = PRETTY_DEFAULT
	pp[DISPLAY_ASCII] = 2
	pp[LINE_BREAKS]   = -1

	puts( fn, "\"called_from\"\n" )
	pretty_print( fn, called_from, pp )
	puts( fn, "\n\n\"called_by\"\n" )
	pretty_print( fn, called_by, pp )
	puts( fn, "\n\n\"known_files\"\n")
	pretty_print( fn, known_files, pp )
	puts( fn, "\n\n\"file_include \"\n" )
	pretty_print( fn, file_include, pp )
	puts( fn, "\n" )
	close( fn )


	sequence routines = {"If_statement","main","SetBBType"}
	for r = 1 to length( routines ) do
		integer dn = open( sprintf( "%s.dot", {routines[r]}), "w" )
		puts( dn, diagram_routine( routines[r] ) )
		close( dn )
		make_pngs( routines[r] )
	end for

	fn = open( name & "include.dot", "w" )
	puts( fn, diagram_includes() )
	close( fn )
	make_pngs( name & "include" )

	fn = open( name & "include_all.dot", "w" )
	puts( fn, diagram_includes( 1 ) )
	close( fn )
	make_pngs( name & "include_all" )

	files = short_names
	for f = 1 to length( files ) do
		integer dn = open( sprintf("%s.dep.dot", {files[f]}), "w" )
		if dn != -1 then
			puts( dn, diagram_file_deps( f ) )
			close( dn )
			make_pngs( files[f] & ".dep" )
		end if
	end for
end procedure

procedure line_print( integer fn, object p )
	integer line_break, count
	if atom(p) then
		print(fn, p)
		return
	end if
	p = pretty_sprint( p, ps_options )
	count = 0
	while length(p) > 95 do
		line_break = 95
		while line_break < length(p) and p[line_break] != ',' do
			line_break += 1
		end while
		if count then
			puts(fn, '\t')
		else
			count += 1
		end if

		puts(fn, p[1..line_break])
		p = p[line_break+1..$]
		if length(p) then
			puts(fn,"\n")
		end if
	end while

	if count then
		puts(fn, '\t')
	end if
	puts(fn, p )
end procedure

constant MODES = {"M_NORMAL", "M_CONSTANT", "M_TEMP", "M_SCOPE" }
constant SCOPES = {
	"SC_NONE",
	"SC_LOOP_VAR",    -- "private" loop vars known within a single loop
	"SC_PRIVATE",    -- private within subprogram
	"SC_GLOOP_VAR",   -- "global" loop var
	"SC_LOCAL",    -- local to the file
	"SC_GLOBAL",    -- global across all files
	"SC_PREDEF",    -- predefined symbol - could be overriden
	"SC_KEYWORD",    -- a keyword
	"SC_UNDEFINED",   -- new undefined symbol
	"SC_MULTIPLY_DEFINED",  -- global symbol defined in 2 or more files
	"SC_EXPORT",   -- visible to anyone that includes the file
	"SC_OVERRIDE", -- override an internal
	"SC_PUBLIC",   -- visible to any file that includes it, or via "public include"
	"SC_MEMSTRUCT",
	$
	}

constant USAGE_VALUES = {
	U_UNUSED,
	U_READ,
	U_WRITTEN,
	U_DELETED,
	U_USED,
	U_FORWARD,
	U_DELETED} -- we've decided to delete this symbol

constant USAGES = {
	"U_UNUSED",
	"U_READ",
	"U_WRITTEN",
	"U_DELETED",
	"U_USED"} -- we've decided to delete this symbol

constant TEMP_USAGES = {
	"T_INTEGER",
	"T_SEQUENCE",
	"T_ATOM",
	"T_UNKNOWN",
	"T_USED"
	}

map:map gtypes = map:new()
map:put( gtypes, TYPE_NULL, "TYPE_NULL" )
map:put( gtypes, TYPE_INTEGER, "TYPE_INTEGER" )
map:put( gtypes, TYPE_DOUBLE, "TYPE_DOUBLE" )
map:put( gtypes, TYPE_ATOM, "TYPE_ATOM" )
map:put( gtypes, TYPE_SEQUENCE, "TYPE_SEQUENCE" )
map:put( gtypes, TYPE_OBJECT, "TYPE_OBJECT" )

function format_symbol( sequence symbol )
	if symbol[S_MODE] = M_TEMP then
		symbol[S_USAGE] = TEMP_USAGES[symbol[S_USAGE]]
	else
		switch symbol[S_USAGE] do
		case U_UNUSED then
			symbol[S_USAGE] = "U_UNUSED"
		case U_DELETED then
			symbol[S_USAGE] = "U_DELETED"
		case U_READ, U_WRITTEN then
			symbol[S_USAGE] = USAGES[symbol[S_USAGE]]
		case 3 then
			symbol[S_USAGE] = "U_READ + U_WRITTEN"
		case else
			symbol[S_USAGE] = "Usage Unknown"
		end switch
		
		if length( symbol ) >= S_TOKEN and symbol[S_TOKEN] = VARIABLE then
			if length( symbol ) >= S_VTYPE then
				integer vtype = symbol[S_VTYPE]
				if vtype > 0 then
					symbol[S_VTYPE] = sym_name( vtype )
				else
					symbol[S_VTYPE] = sprintf( "Unknown Type: %d", vtype )
				end if
			end if
			if TRANSLATE then
				symbol[S_GTYPE] = map:get( gtypes, symbol[S_GTYPE], sprintf( "Unknown GType: %d", symbol[S_GTYPE] ) )
				symbol[S_ARG_TYPE] = map:get( gtypes, symbol[S_ARG_TYPE], sprintf( "Unknown GType: %d", symbol[S_ARG_TYPE] ) )
				symbol[S_ARG_TYPE_NEW] = map:get( gtypes, symbol[S_ARG_TYPE_NEW], sprintf( "Unknown GType: %d", symbol[S_ARG_TYPE_NEW] ) )
			end if
		end if
	end if
	symbol[S_MODE] = MODES[symbol[S_MODE]]
	if symbol[S_SCOPE] then
		symbol[S_SCOPE] = SCOPES[symbol[S_SCOPE]]
	end if
	

	return symbol
end function

sequence in_chain = {}
procedure write_next_links( symtab_pointer s, integer fn )
	puts( fn, "\nSYMBOL CHAIN:\n")
	while s do
		if sym_mode( s ) = M_TEMP then
			printf(fn, "\t%6d TEMP\n", { s })
		elsif length( SymTab[s] ) >= S_NAME then
			printf(fn, "\t%6d %s\n", { s, SymTab[s][S_NAME] })
		else
			printf(fn, "\t%6d ?\n", s )
		end if
		in_chain[s] = 1
		s = SymTab[s][S_NEXT]
	end while
end procedure

procedure save_il( sequence name )
	integer st, max_width
	sequence line_format, pretty_options = PRETTY_DEFAULT
	integer used_buckets
	integer symcnt
	sequence bucket_usage

	st = open( sprintf("%ssym", { name }), "wb" )
	pretty_options[DISPLAY_ASCII] = 2
	pretty_options[LINE_BREAKS]   = 0

	for j = 1 to length( SymTab ) do
		puts( st,  pretty_sprint( j & format_symbol( SymTab[j] ), pretty_options ) )
-- 		pretty_print( st, j & SymTab[j], pretty_options )
		puts( st, "\n" )
	end for

	-- now output the chains...
	in_chain = repeat( 0, length( SymTab ) )
	for j = 1 to length( SymTab ) do
		if not in_chain[j] and sym_mode( j ) != M_TEMP then
			write_next_links( j, st )
		end if
	end for
	in_chain = {}
	close( st )

	st = open( sprintf("%sline", {name}), "wb" )

	if length(slist) and atom(slist[$]) then
		slist = s_expand( slist )
	end if

	max_width = 0
	for i = 1 to length(known_files) do
		if length(known_files[i]) > max_width then
			max_width = length(known_files[i])
		end if
	end for

	line_format = sprintf("%%%ds %%%dd : %%s\n", {max_width, floor(log( length(slist) ) / log(10) ) + 1})


	for j = 1 to length(slist) do
		if atom(slist[j][SRC]) then
			slist[j][SRC] = fetch_line(slist[j][SRC])
		end if
		
		printf( st, line_format, {known_files[slist[j][LOCAL_FILE_NO]], j, slist[j][SRC] })

	end for

	close(st)

	st = open( sprintf("%shash", { name }), "wb" )
	sequence bucket = repeat( "", length( buckets ) )
	sequence end_size = repeat( "", length( buckets ) )
	sequence bucket_reps = repeat( "", length( buckets ) ) 
	for i = 1 to length( buckets ) do
		integer size = 0
		integer s = buckets[i]
		while s do
			size += 1
			s = SymTab[s][S_SAMEHASH]
		end while
		end_size[i] = size
	end for
	used_buckets = 0
	symcnt = 0
	bucket_usage = {}
	
	for i = 1 to length( SymTab ) do
		if length( SymTab[i] ) >= S_HASHVAL and SymTab[i][S_HASHVAL] then
			integer h = SymTab[i][S_HASHVAL]
			integer bx = find( SymTab[i][S_NAME], bucket[h] )
			if not bx then
				bucket[h] = append( bucket[h], SymTab[i][S_NAME] )
				bucket_reps[h] &= 1
			else
				bucket_reps[h][bx] += 1
			end if
		end if
	end for

	for i = 1 to length( bucket ) do
		for j = 1 to length( bucket[i] ) do
			bucket[i][j] = sprintf( "[%d:%s]", {bucket_reps[i][j], bucket[i][j]})
		end for
		bucket[i] = sum(bucket_reps[i]) & i & bucket[i]
	end for
	
	bucket = sort(bucket, DESCENDING)
	bucket_usage = repeat(0, bucket[1][1])
	puts(st, "Bucket size / hashval / Ending Size / hits : contents\n" )
	for i = 1 to length( bucket ) do
		if bucket[i][1] > 0 then
			used_buckets += 1
			symcnt += bucket[i][1]
			bucket_usage[bucket[i][1]] += 1
			printf( st, "%5d %5d %5d %5d: ", bucket[i][1..2] & end_size[i] & bucket_hits[i] )
			for j = 3 to length( bucket[i] ) do
				if j > 3 then
					puts( st, ", " )
				end if
				printf( st, "%s", {bucket[i][j]} )
			end for
			puts( st, '\n' )
		end if
	end for
	puts( st, '\n' )
	printf( st, "Symbols         : %d\n", symcnt )
	printf( st, "Used buckets    : %d (%3.1f%%)\n", {used_buckets, 100 * used_buckets / length(bucket)})
	printf( st, "Empty buckets   : %d (%3.1f%%)\n", {length(bucket) - used_buckets, 100 * (length(bucket) - used_buckets) / length(bucket)})
	if used_buckets > 0 then
		printf( st, "Symbols / bucket: %4.2f\n", symcnt / used_buckets)
		for i = 1 to length(bucket_usage) do
			printf( st, "Len %2d : %d\n", {i, bucket_usage[i]})
		end for
		
		sequence hit_counts = {}
		for i = 1 to length( bucket_hits ) do
			integer hits = bucket_hits[i] + 1 -- could be 0
			if length( hit_counts ) < hits then
				hit_counts &= repeat( 0, hits - length( hit_counts ) )
			end if
			hit_counts[hits] += 1
		end for
		
		for i = 1 to length( hit_counts ) do
			hit_counts[i] = { i-1, hit_counts[i] }
		end for
		
		puts( st, "\nBucket search frequency counts (hits : # buckets):\n" )
-- 		hit_counts = sort( hit_counts )
		for i = length( hit_counts ) to 1 by -1 do
			if hit_counts[i][2] then
				printf( st, "%6d: %d\n", hit_counts[i]  )
			end if
			
		end for
	end if

	close( st )

end procedure

include std/filesys.e
procedure InitBackEnd( object ignore )
-- initialize Interpreter
    sequence name
    sequence missing = {}
    -- set up operations
    operation = repeat(-1, length(opnames))

	if not TRANSLATE then
		intoptions()
	else
		transoptions()
	end if

	for i = 1 to length(opnames) do
		name = opnames[i]
		-- some similar ops are handled by a common routine
		if find(name, {"RHS_SUBS_CHECK", "RHS_SUBS_I"}) then
			name = "RHS_SUBS"
		elsif find(name, {"ASSIGN_SUBS_CHECK", "ASSIGN_SUBS_I"}) then
			name = "ASSIGN_SUBS"
		elsif equal(name, "ASSIGN_I") then
			name = "ASSIGN"
		elsif find(name, {"EXIT", "ENDWHILE", "RETRY", "GOTO"}) then
			name = "ELSE"
		elsif equal(name, "PLUS1_I") then
			name = "PLUS1"
		elsif equal(name, "PRIVATE_INIT_CHECK") then
			name = "GLOBAL_INIT_CHECK"
		elsif equal(name, "PLUS_I") then
			name = "PLUS"
		elsif equal(name, "MINUS_I") then
			name = "MINUS"
		elsif equal(name, "FOR_I") then
			name = "FOR"
		elsif find(name, {"ENDFOR_UP", "ENDFOR_DOWN",
				"ENDFOR_INT_UP", "ENDFOR_INT_DOWN",
				"ENDFOR_INT_DOWN1"}) then
			name = "ENDFOR_GENERAL"
		elsif equal(name, "CALL_FUNC") then
			name = "CALL_PROC"
		elsif find(name, {"DISPLAY_VAR", "ERASE_PRIVATE_NAMES",
				"ERASE_SYMBOL"}) then
			name = "PROFILE"
		elsif equal(name, "SC2_AND") then
			name = "SC2_OR"
		elsif find(name, {"SC2_NULL", "ASSIGN_SUBS2", "PLATFORM",
				"END_PARAM_CHECK", "PROC_FORWARD", "FUNC_FORWARD"}) then
			-- never emitted
			name = "NOP2"
		elsif equal(name, "GREATER_IFW_I") then
			name = "GREATER_IFW"
		elsif equal(name, "LESS_IFW_I") then
			name = "LESS_IFW"
		elsif equal(name, "EQUALS_IFW_I") then
			name = "EQUALS_IFW"
		elsif equal(name, "NOTEQ_IFW_I") then
			name = "NOTEQ_IFW"
		elsif equal(name, "GREATEREQ_IFW_I") then
			name = "GREATEREQ_IFW"
		elsif equal(name, "LESSEQ_IFW_I") then
			name = "LESSEQ_IFW"
		elsif match( "PEEK", name ) and not match( "_MEMBER", name ) and not match( "_ARRAY", name ) then
			name = "PEEK"
		elsif match( "POKE", name ) then
			name = "POKE"
		elsif find( name, { "NOPWHILE" } ) then
			name = "NOP1"
		elsif find( name, { "SWITCH_I", "SWITCH_SPI", "SWITCH_RT" }) then
			name = "SWITCH"
		elsif equal( name, "PROC_TAIL" ) then
			name = "PROC"
		elsif equal( name, "STARTLINE_BREAK" ) then
			name = "STARTLINE"
		end if

		operation[i] = routine_id("op" & name)
		if operation[i] = -1 then
			missing = append( missing, name )
		end if
    end for

    if length( missing ) then
    	name = ""
		for i = 1 to length( missing ) do
			name &= missing[i] & ' '
		end for
		crash( "No routine id for ops: " & name )
    end if
end procedure
mode:set_init_backend( routine_id("InitBackEnd") )

function max( integer a, integer b )
	if a > b then
		return a
	end if
	return b
end function

function mem_name( symtab_index member_sym )
	integer tid = sym_token( member_sym )
	switch tid do
		case MS_CHAR then
			return "char"
		case MS_SHORT then
			return "short"
		case MS_INT then
			return "int"
		case MS_LONG then
			return "long"
		case MS_OBJECT then
			return "object"
		case MS_LONGLONG then
			return "long long int"
		case MS_FLOAT then
			return "float"
		case MS_DOUBLE then
			return "double"
		case MS_LONGDOUBLE then
			return "long double"
		case MS_EUDOUBLE then
			return "eudouble"
		case MS_MEMBER then
			return sym_name( SymTab[member_sym][S_MEM_STRUCT] )
	end switch
end function

procedure dis_memstruct( integer ms )
	if sym_token( ms ) = MEMSTRUCT then
		puts( out, "\nMemStruct" )
	else
		puts( out, "\nMemUnion" )
	end if
	
	printf( out, " [%s-%s:%05d]\n",
		{known_files[SymTab[ms][S_FILE_NO]], SymTab[ms][S_NAME], ms })
	printf( out, "    SIZE: %d\n", SymTab[ms][S_MEM_SIZE] )
	symtab_pointer member_sym = ms
	printf( out, "            %-20s  %-15s Other Information\n", {"Name", "Type"})
	while member_sym with entry do
		printf( out, "    %06d: %-20s  %-15s pointer[%d] signed[%d] array[%d] offset[%3d] size[%d]\n", 
			{ 
				member_sym, 
				sym_name( member_sym ), 
				mem_name( member_sym ),
				SymTab[member_sym][S_MEM_POINTER],
				SymTab[member_sym][S_MEM_SIGNED],
				SymTab[member_sym][S_MEM_ARRAY],
				SymTab[member_sym][S_MEM_OFFSET],
				SymTab[member_sym][S_MEM_SIZE],
				$
				} )
		
	entry
		member_sym = SymTab[member_sym][S_MEM_NEXT]
	end while
	if sym_token( ms ) = MEMSTRUCT then
		puts( out, "End MemStruct" )
	else
		puts( out, "End MemUnion" )
	end if
	printf( out, " [%s:%05d]\n", {sym_name( ms ), ms} )
end procedure

procedure dis( integer sub )
	integer op, ix
	sequence sym
	CurrentSub = sub

	symtab_index param = SymTab[sub][S_NEXT]
	sequence params = {}
	for p = 1 to SymTab[sub][S_NUM_ARGS] do
		params &= sprintf( " %s", names({param}) )
		param = SymTab[param][S_NEXT]
	end for

	printf( out, "\nSubProgram [%s-%s:%05d] %s\n",
		{known_files[SymTab[sub][S_FILE_NO]], SymTab[sub][S_NAME], sub, params })
	
	if sub != TopLevelSub then
		integer stack_space_required = calc_stack_required( sub )
		printf( out, "\tSTACK SPACE: %d\n\tRequired:    %d\n", { SymTab[sub][S_STACK_SPACE], stack_space_required } )
		if stack_space_required > SymTab[sub][S_STACK_SPACE] then
			printf(2, "Stack space mismatch! %s:%s Reserved[%d] Required[%d]\n", 
				{ filename( known_files[SymTab[sub][S_FILE_NO]] ), sym_name( sub ), SymTab[sub][S_STACK_SPACE], stack_space_required } )
		end if
	end if
	
	map:put( proc_names, SymTab[sub][S_NAME], sub )
	Code = SymTab[sub][S_CODE]
	pc = 1
	sequence line_table = SymTab[sub][S_LINETAB]
	while pc <= length(Code) do
		integer ln = find( pc-1, line_table )
		if ln > 0 and ln <= length(line_table) then
			printf(out, "\n        [%s:%d] %s (%d)\n", find_line( sub, pc, 0 ) )
		end if

		op = Code[pc]
		call_proc(operation[op], {})
	end while
	printf( out, "End SubProgram [%s:%05d]\n", {SymTab[sub][S_NAME], sub})
end procedure

function dis_crash( object c )
	save_il( "dis." )
	return 0
end function
crash_routine(routine_id("dis_crash"))

export function extract_options(sequence s)
	return s
end function

integer generate_html = 0
function set_html( object o )
	generate_html = 1
	return 0
end function

integer generate_file_list = 0
function enable_file_list( object o )
	generate_file_list = 1
	return 0
end function

include std/pretty.e

sequence opts = {
		{ 0, "html", "html output", {NO_PARAMETER}, routine_id("set_html") },
		{ 0, "dir", "output directory", {HAS_PARAMETER}, routine_id("set_out_dir") },
		{ 0, "no-dep", "suppress dependencies", {NO_PARAMETER}, routine_id("suppress_dependencies") },
		{ 0, "std", "show standard library information", {NO_PARAMETER}, routine_id("suppress_stdlib") },
		{ "f", "file", "include this file", {HAS_PARAMETER}, routine_id("document_file") },
		{ "g", "graphs", "suppress call graphs", {NO_PARAMETER}, routine_id("suppress_callgraphs") },
		{ "t", 0, "translator mode", {NO_PARAMETER}, -1 },
		{ "b", 0, "binder mode", {NO_PARAMETER}, -1 },
		{ 0, "file-list", "outputs the list of files in the disassembled code at the top of the .dis file",
			{NO_PARAMETER}, routine_id("enable_file_list") }
		}

add_options( opts )

export procedure BackEnd( object ignore )

-- 	map:map result = cmd_parse( opts, -1, Argv )

	save_il( known_files[1] & '.' )
	out = open( known_files[1] & ".dis", "wb" )
	printf(1,"saved to [%s.dis]\n", {known_files[1]})

	if generate_file_list then
		puts( out, "File List:\n" )
		for i = 1 to length( known_files ) do
			printf( out, "%s\n", {known_files[i]})
		end for
		puts( out, "\n" )
	end if

	if atom(slist[$]) then
		slist = s_expand(slist)
	end if

	for i = TopLevelSub to length(SymTab) do
		if length(SymTab[i]) = SIZEOF_ROUTINE_ENTRY
		and sequence(SymTab[i][S_CODE])
		and SymTab[i][S_SCOPE] != SC_PRIVATE then
			dis( i )
		
		elsif length(SymTab[i])  = SIZEOF_MEMSTRUCT_ENTRY
		and (SymTab[i][S_TOKEN] = MEMSTRUCT or SymTab[i][S_TOKEN] = MEMUNION) then
			dis_memstruct( i )
		else
			-- other symbols?
		end if
	end for
	close( out )

	if generate_html then
		dox:generate()
	end if

end procedure
mode:set_backend( routine_id("BackEnd") )

