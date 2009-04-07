-- shift IL code to dynamically insert, delete or replace previously emitted  IL code
namespace shift

include reswords.e
include global.e
include symtab.e
include fwdref.e
include error.e

export enum
	FIXED_SIZE,
	VARIABLE_SIZE

export sequence op_info = {}

export enum
	OP_SIZE_TYPE,
	OP_SIZE,
	OP_ADDR,
	OP_TARGET,
	OP_SUB

procedure init_op_info()
	op_info = repeat( 0, MAX_OPCODE )
	op_info[ABORT               ] = { FIXED_SIZE, 2, {}, {}, {} }   -- ary: pun
	op_info[AND                 ] = { FIXED_SIZE, 4, {}, {}, {} }   -- ary: bin
	op_info[AND_BITS            ] = { FIXED_SIZE, 4, {}, {3}, {} }   -- ary: bin
	op_info[APPEND              ] = { FIXED_SIZE, 4, {}, {3}, {} }   -- ary: bin
	op_info[ARCTAN              ] = { FIXED_SIZE, 3, {}, {2}, {} }   -- ary: un
	op_info[ASSIGN              ] = { FIXED_SIZE, 3, {}, {2}, {} }
	op_info[ASSIGN_I            ] = { FIXED_SIZE, 3, {}, {2}, {} }
	op_info[ASSIGN_OP_SLICE     ] = { FIXED_SIZE, 5, {}, {4}, {} }
	op_info[ASSIGN_OP_SUBS      ] = { FIXED_SIZE, 4, {}, {3}, {} }
	op_info[ASSIGN_SLICE        ] = { FIXED_SIZE, 5, {}, {1}, {} }
	op_info[ASSIGN_SUBS         ] = { FIXED_SIZE, 4, {}, {1}, {} }
	op_info[ASSIGN_SUBS_CHECK   ] = { FIXED_SIZE, 4, {}, {1}, {} }
	op_info[ASSIGN_SUBS_I       ] = { FIXED_SIZE, 4, {}, {1}, {} }
	op_info[BADRETURNF          ] = { FIXED_SIZE, 1, {}, {}, {} }
	op_info[CALL                ] = { FIXED_SIZE, 2, {}, {}, {} }
	op_info[CALL_PROC           ] = { FIXED_SIZE, 3, {}, {}, {} }
	op_info[CALL_FUNC           ] = { FIXED_SIZE, 4, {}, {3}, {} }
	op_info[CASE                ] = { FIXED_SIZE, 2, {}, {}, {} }
	op_info[CLEAR_SCREEN        ] = { FIXED_SIZE, 1, {}, {}, {} }
	op_info[CLOSE               ] = { FIXED_SIZE, 2, {}, {}, {} }
	op_info[COMMAND_LINE        ] = { FIXED_SIZE, 2, {}, {1}, {} }
	op_info[COMPARE             ] = { FIXED_SIZE, 4, {}, {3}, {} }
	op_info[CONCAT              ] = { FIXED_SIZE, 4, {}, {3}, {} }
	op_info[COS                 ] = { FIXED_SIZE, 3, {}, {2}, {} }
	op_info[C_FUNC              ] = { FIXED_SIZE, 5, {}, {4}, {3} }
	op_info[C_PROC              ] = { FIXED_SIZE, 4, {}, {}, {3} }
	op_info[DATE                ] = { FIXED_SIZE, 2, {}, {1}, {} }
	op_info[DELETE_ROUTINE      ] = { FIXED_SIZE, 4, {}, {3}, {} }
	op_info[DELETE_OBJECT       ] = { FIXED_SIZE, 2, {}, {}, {} }
	op_info[DIV2                ] = { FIXED_SIZE, 4, {}, {3}, {} }
	op_info[DIVIDE              ] = { FIXED_SIZE, 4, {}, {3}, {} }
	op_info[ELSE                ] = { FIXED_SIZE, 2, {1}, {}, {} }
	op_info[EXIT                ] = { FIXED_SIZE, 2, {1}, {}, {} }
	op_info[ENDWHILE            ] = { FIXED_SIZE, 2, {1}, {}, {} }
	op_info[RETRY               ] = { FIXED_SIZE, 2, {1}, {}, {} }
	op_info[GOTO                ] = { FIXED_SIZE, 2, {1}, {}, {} }
	op_info[ENDFOR_GENERAL      ] = { FIXED_SIZE, 5, {1}, {}, {} }
	op_info[ENDFOR_UP           ] = { FIXED_SIZE, 4, {1}, {}, {} }
	op_info[ENDFOR_DOWN         ] = { FIXED_SIZE, 4, {1}, {}, {} }
	op_info[ENDFOR_INT_UP       ] = { FIXED_SIZE, 4, {1}, {}, {} }
	op_info[ENDFOR_INT_DOWN     ] = { FIXED_SIZE, 4, {1}, {}, {} }
	op_info[ENDFOR_INT_DOWN1    ] = { FIXED_SIZE, 4, {1}, {}, {} }
	op_info[ENDFOR_INT_UP1      ] = { FIXED_SIZE, 5, {1}, {}, {} }
	op_info[EQUAL               ] = { FIXED_SIZE, 4, {}, {3}, {} }
	op_info[EQUALS              ] = { FIXED_SIZE, 4, {}, {3}, {} }
	op_info[EQUALS_IFW          ] = { FIXED_SIZE, 4, {3}, {}, {} }
	op_info[EQUALS_IFW_I        ] = { FIXED_SIZE, 4, {3}, {}, {} }
	op_info[FIND                ] = { FIXED_SIZE, 4, {}, {3}, {} }
	op_info[FIND_FROM           ] = { FIXED_SIZE, 5, {}, {4}, {} }
	op_info[FLOOR               ] = { FIXED_SIZE, 3, {}, {2}, {} }
	op_info[FLOOR_DIV           ] = { FIXED_SIZE, 4, {}, {3}, {} }
	op_info[FLOOR_DIV2          ] = { FIXED_SIZE, 4, {}, {3}, {} }
	op_info[FOR                 ] = { FIXED_SIZE, 7, {6}, {}, {} }
	op_info[FOR_I               ] = { FIXED_SIZE, 7, {6}, {}, {} }
	op_info[GETC                ] = { FIXED_SIZE, 3, {}, {2}, {} }
	op_info[GETENV              ] = { FIXED_SIZE, 3, {}, {2}, {} }
	op_info[GETS                ] = { FIXED_SIZE, 3, {}, {2}, {} }
	op_info[GET_KEY             ] = { FIXED_SIZE, 2, {}, {1}, {} }
	op_info[GET_PIXEL           ] = { FIXED_SIZE, 3, {}, {2}, {} }
	op_info[GLABEL              ] = { FIXED_SIZE, 2, {1}, {}, {} }
	op_info[GLOBAL_INIT_CHECK   ] = { FIXED_SIZE, 2, {}, {}, {} }
	op_info[PRIVATE_INIT_CHECK  ] = { FIXED_SIZE, 2, {}, {}, {} }
	op_info[GREATER             ] = { FIXED_SIZE, 4, {}, {3}, {} }
	op_info[GREATEREQ           ] = { FIXED_SIZE, 4, {}, {3}, {} }
	op_info[GREATEREQ_IFW       ] = { FIXED_SIZE, 4, {3}, {}, {} }
	op_info[GREATEREQ_IFW_I     ] = { FIXED_SIZE, 4, {3}, {}, {} }
	op_info[GREATER_IFW         ] = { FIXED_SIZE, 4, {3}, {}, {} }
	op_info[GREATER_IFW_I       ] = { FIXED_SIZE, 4, {3}, {}, {} }
	op_info[HASH                ] = { FIXED_SIZE, 4, {}, {3}, {} }
	op_info[HEAD                ] = { FIXED_SIZE, 4, {}, {3}, {} }
	op_info[IF                  ] = { FIXED_SIZE, 3, {2}, {}, {} }
	op_info[INSERT              ] = { FIXED_SIZE, 5, {}, {4}, {} }
	op_info[LENGTH              ] = { FIXED_SIZE, 3, {}, {2}, {} }
	op_info[LESS                ] = { FIXED_SIZE, 4, {}, {3}, {} }
	op_info[LESSEQ              ] = { FIXED_SIZE, 4, {}, {3}, {} }
	op_info[LESSEQ_IFW          ] = { FIXED_SIZE, 4, {3}, {}, {} }
	op_info[LESSEQ_IFW_I        ] = { FIXED_SIZE, 4, {3}, {}, {} }
	op_info[LESS_IFW            ] = { FIXED_SIZE, 4, {3}, {}, {} }
	op_info[LESS_IFW_I          ] = { FIXED_SIZE, 4, {3}, {}, {} }
	op_info[LHS_SUBS            ] = { FIXED_SIZE, 5, {}, {3}, {} }
	op_info[LHS_SUBS1           ] = { FIXED_SIZE, 5, {}, {3}, {} }
	op_info[LHS_SUBS1_COPY      ] = { FIXED_SIZE, 5, {}, {3}, {} }
	op_info[LOG                 ] = { FIXED_SIZE, 3, {}, {2}, {} }
	op_info[MACHINE_FUNC        ] = { FIXED_SIZE, 4, {}, {3}, {} }
	op_info[MACHINE_PROC        ] = { FIXED_SIZE, 3, {}, {}, {} }
	op_info[MATCH               ] = { FIXED_SIZE, 4, {}, {3}, {} }
	op_info[MATCH_FROM          ] = { FIXED_SIZE, 5, {}, {4}, {} }
	op_info[MEM_COPY            ] = { FIXED_SIZE, 4, {}, {}, {} }
	op_info[MEM_SET             ] = { FIXED_SIZE, 4, {}, {}, {} }
	op_info[MINUS               ] = { FIXED_SIZE, 4, {}, {3}, {} }
	op_info[MINUS_I             ] = { FIXED_SIZE, 4, {}, {3}, {} }
	op_info[MULTIPLY            ] = { FIXED_SIZE, 4, {}, {3}, {} }
	op_info[NOP1                ] = { FIXED_SIZE, 1, {}, {}, {} }
	op_info[NOPWHILE            ] = { FIXED_SIZE, 1, {}, {}, {} }
	op_info[NOP2                ] = { FIXED_SIZE, 2, {}, {}, {} }
	op_info[SC2_NULL            ] = { FIXED_SIZE, 2, {}, {}, {} }
	op_info[ASSIGN_SUBS2        ] = { FIXED_SIZE, 2, {}, {}, {} }
	op_info[PLATFORM            ] = { FIXED_SIZE, 2, {}, {1}, {} }
	op_info[END_PARAM_CHECK     ] = { FIXED_SIZE, 2, {}, {}, {} }
	
	op_info[NOPSWITCH           ] = { FIXED_SIZE, 1, {}, {}, {} }
	op_info[NOT                 ] = { FIXED_SIZE, 3, {}, {2}, {} }
	op_info[NOTEQ               ] = { FIXED_SIZE, 4, {}, {3}, {} }
	op_info[NOTEQ_IFW           ] = { FIXED_SIZE, 4, {3}, {}, {} }
	op_info[NOTEQ_IFW_I         ] = { FIXED_SIZE, 4, {3}, {}, {} }
	op_info[NOT_BITS            ] = { FIXED_SIZE, 3, {}, {2}, {} }
	op_info[NOT_IFW             ] = { FIXED_SIZE, 3, {2}, {}, {} }
	op_info[OPEN                ] = { FIXED_SIZE, 5, {}, {4}, {} }
	op_info[OPTION_SWITCHES     ] = { FIXED_SIZE, 2, {}, {1}, {} }
	op_info[OR                  ] = { FIXED_SIZE, 4, {}, {3}, {} }
	op_info[OR_BITS             ] = { FIXED_SIZE, 4, {}, {3}, {} }
	op_info[PASSIGN_OP_SLICE    ] = { FIXED_SIZE, 5, {}, {4}, {} }
	op_info[PASSIGN_OP_SUBS     ] = { FIXED_SIZE, 4, {}, {3}, {} }
	op_info[PASSIGN_SLICE       ] = { FIXED_SIZE, 5, {}, {1}, {} }
	op_info[PASSIGN_SUBS        ] = { FIXED_SIZE, 4, {}, {1}, {} }
	op_info[PEEK_STRING         ] = { FIXED_SIZE, 3, {}, {2}, {} }
	op_info[PEEK2U              ] = { FIXED_SIZE, 3, {}, {2}, {} }
	op_info[PEEK2S              ] = { FIXED_SIZE, 3, {}, {2}, {} }
	op_info[PEEK4U              ] = { FIXED_SIZE, 3, {}, {2}, {} }
	op_info[PEEK4S              ] = { FIXED_SIZE, 3, {}, {2}, {} }
	op_info[PEEKS               ] = { FIXED_SIZE, 3, {}, {2}, {} }
	op_info[PEEK                ] = { FIXED_SIZE, 3, {}, {3}, {} }
	op_info[PIXEL               ] = { FIXED_SIZE, 3, {}, {}, {} }
	op_info[PLENGTH             ] = { FIXED_SIZE, 3, {}, {2}, {} }
	op_info[PLUS                ] = { FIXED_SIZE, 4, {}, {3}, {} }
	op_info[PLUS_I              ] = { FIXED_SIZE, 4, {}, {3}, {} }
	op_info[PLUS1               ] = { FIXED_SIZE, 4, {}, {3}, {} }
	op_info[PLUS1_I             ] = { FIXED_SIZE, 4, {}, {3}, {} }
	op_info[POKE                ] = { FIXED_SIZE, 3, {}, {}, {} }
	op_info[POKE2               ] = { FIXED_SIZE, 3, {}, {}, {} }
	op_info[POKE4               ] = { FIXED_SIZE, 3, {}, {}, {} }
	op_info[POSITION            ] = { FIXED_SIZE, 3, {}, {}, {} }
	op_info[POWER               ] = { FIXED_SIZE, 4, {}, {3}, {} }
	op_info[PREPEND             ] = { FIXED_SIZE, 4, {}, {3}, {} }
	op_info[PRINT               ] = { FIXED_SIZE, 3, {}, {}, {} }
	op_info[PRINTF              ] = { FIXED_SIZE, 4, {}, {}, {} }
	op_info[PROFILE             ] = { FIXED_SIZE, 2, {}, {}, {} }
	op_info[DISPLAY_VAR         ] = { FIXED_SIZE, 2, {}, {}, {} }
	op_info[ERASE_PRIVATE_NAMES ] = { FIXED_SIZE, 2, {}, {}, {} }
	op_info[ERASE_SYMBOL        ] = { FIXED_SIZE, 2, {}, {}, {} }
	op_info[PUTS                ] = { FIXED_SIZE, 3, {}, {}, {} }
	op_info[QPRINT              ] = { FIXED_SIZE, 3, {}, {}, {} }
	op_info[RAND                ] = { FIXED_SIZE, 3, {}, {2}, {} }
	op_info[REMAINDER           ] = { FIXED_SIZE, 4, {}, {3}, {} }
	op_info[REMOVE              ] = { FIXED_SIZE, 5, {}, {4}, {} }
	op_info[REPEAT              ] = { FIXED_SIZE, 4, {}, {3}, {} }
	op_info[REPLACE             ] = { FIXED_SIZE, 6, {}, {5}, {} }
	op_info[RETURNF             ] = { FIXED_SIZE, 3, {}, {}, {} }
	op_info[RETURNP             ] = { FIXED_SIZE, 2, {}, {}, {} }
	op_info[RETURNT             ] = { FIXED_SIZE, 1, {}, {}, {} }
	op_info[RHS_SLICE           ] = { FIXED_SIZE, 5, {}, {}, {} }
	op_info[RHS_SUBS            ] = { FIXED_SIZE, 4, {}, {3}, {} }
	op_info[RHS_SUBS_I          ] = { FIXED_SIZE, 4, {}, {3}, {} }
	op_info[RHS_SUBS_CHECK      ] = { FIXED_SIZE, 4, {}, {3}, {} }
	op_info[RIGHT_BRACE_2       ] = { FIXED_SIZE, 4, {}, {}, {} }
	
	op_info[ROUTINE_ID          ] = { FIXED_SIZE, 6 - TRANSLATE, {}, { 4 + not TRANSLATE }, {} }
	op_info[SC2_OR              ] = { FIXED_SIZE, 3, {}, {}, {} }
	op_info[SC2_AND             ] = { FIXED_SIZE, 3, {}, {}, {} }
	op_info[SIN                 ] = { FIXED_SIZE, 3, {}, {2}, {} }
	op_info[SPACE_USED          ] = { FIXED_SIZE, 2, {}, {}, {} }
	op_info[SPLICE              ] = { FIXED_SIZE, 5, {}, {4}, {} }
	op_info[SPRINTF             ] = { FIXED_SIZE, 4, {}, {3}, {} }
	op_info[SQRT                ] = { FIXED_SIZE, 3, {}, {2}, {} }
	op_info[STARTLINE           ] = { FIXED_SIZE, 2, {}, {}, {} }
	op_info[SWITCH              ] = { FIXED_SIZE, 5, {4}, {}, {} }
	op_info[SWITCH_I            ] = { FIXED_SIZE, 5, {4}, {}, {} }
	op_info[SWITCH_SPI          ] = { FIXED_SIZE, 5, {4}, {}, {} }
	op_info[SWITCH_RT           ] = { FIXED_SIZE, 5, {4}, {}, {} }
	op_info[SYSTEM              ] = { FIXED_SIZE, 3, {}, {}, {} }
	op_info[SYSTEM_EXEC         ] = { FIXED_SIZE, 4, {}, {3}, {} }
	op_info[TAIL                ] = { FIXED_SIZE, 4, {}, {3}, {} }
	op_info[TAN                 ] = { FIXED_SIZE, 3, {}, {2}, {} }
	op_info[TASK_CLOCK_START    ] = { FIXED_SIZE, 1, {}, {}, {} }
	op_info[TASK_CLOCK_STOP     ] = { FIXED_SIZE, 1, {}, {}, {} }
	op_info[TASK_CREATE         ] = { FIXED_SIZE, 4, {}, {3}, {} }
	op_info[TASK_LIST           ] = { FIXED_SIZE, 2, {}, {1}, {} }
	op_info[TASK_SCHEDULE       ] = { FIXED_SIZE, 3, {}, {}, {} }
	op_info[TASK_SELF           ] = { FIXED_SIZE, 2, {}, {1}, {} }
	op_info[TASK_STATUS         ] = { FIXED_SIZE, 3, {}, {2}, {} }
	op_info[TASK_SUSPEND        ] = { FIXED_SIZE, 2, {}, {}, {} }
	op_info[TASK_YIELD          ] = { FIXED_SIZE, 1, {}, {}, {} }
	op_info[TIME                ] = { FIXED_SIZE, 2, {}, {1}, {} }
	op_info[TRACE               ] = { FIXED_SIZE, 2, {}, {}, {} }
	op_info[TYPE_CHECK          ] = { FIXED_SIZE, 1, {}, {}, {} }
	op_info[UMINUS              ] = { FIXED_SIZE, 3, {}, {2}, {} }
	op_info[UPDATE_GLOBALS      ] = { FIXED_SIZE, 1, {}, {}, {} }
	op_info[WHILE               ] = { FIXED_SIZE, 3, {2}, {}, {} }
	op_info[XOR                 ] = { FIXED_SIZE, 4, {}, {3}, {} }
	op_info[XOR_BITS            ] = { FIXED_SIZE, 4, {}, {3}, {} }
	
	op_info[TYPE_CHECK_FORWARD  ] = { FIXED_SIZE, 3, {}, {}, {} }
	
	sequence SHORT_CIRCUIT = { FIXED_SIZE, 4, {3}, {}, {} }
	op_info[SC1_AND_IF          ] = SHORT_CIRCUIT
	op_info[SC1_OR_IF           ] = SHORT_CIRCUIT
	op_info[SC1_AND             ] = SHORT_CIRCUIT
	op_info[SC1_OR              ] = SHORT_CIRCUIT
	
	op_info[ATOM_CHECK          ] = { FIXED_SIZE, 2, {}, {}, {} }
	op_info[INTEGER_CHECK       ] = { FIXED_SIZE, 2, {}, {}, {} }
	op_info[SEQUENCE_CHECK      ] = { FIXED_SIZE, 2, {}, {}, {} }
	
	op_info[IS_AN_INTEGER       ] = { FIXED_SIZE, 3, {}, {2}, {} }
	op_info[IS_AN_ATOM          ] = { FIXED_SIZE, 3, {}, {2}, {} }
	op_info[IS_A_SEQUENCE       ] = { FIXED_SIZE, 3, {}, {2}, {} }
	op_info[IS_AN_OBJECT        ] = { FIXED_SIZE, 3, {}, {2}, {} }
	
	op_info[CALL_BACK_RETURN    ] = { FIXED_SIZE, 1, {}, {}, {} }
	
	op_info[PROC_FORWARD        ] = { VARIABLE_SIZE, 0, {}, {}, {} }
	op_info[FUNC_FORWARD        ] = { VARIABLE_SIZE, 0, {}, {}, {} }
	
	op_info[RIGHT_BRACE_N       ] = { VARIABLE_SIZE, 3, {}, {}, {} } -- target: [pc+1] + 2
	op_info[CONCAT_N            ] = { VARIABLE_SIZE, 0, {}, {}, {} } -- target: [pc+1] + 2
	op_info[PROC                ] = { VARIABLE_SIZE, 0, {}, {}, {} }
	op_info[PROC_TAIL           ] = op_info[PROC]
end procedure

init_op_info()

export function advance( integer pc, sequence code = Code )

	integer op = code[pc]
	sequence info = op_info[op]
	if info[OP_SIZE_TYPE] = FIXED_SIZE then
		return pc + info[OP_SIZE]
	else
		switch op with fallthru do
			case PROC then
			case PROC_TAIL then
				return pc + SymTab[code[pc+1]][S_NUM_ARGS] + 2 + (SymTab[code[pc+1]][S_TOKEN] != PROC)
			case PROC_FORWARD then
				return pc + code[pc+2] + 3
			case FUNC_FORWARD then
				return pc + code[pc+2] + 4
			case RIGHT_BRACE_N then
			case CONCAT_N then
				return pc + 3 + code[pc+1]
			case else
				InternalErr( sprintf("Unknown op found when shifting code: ", op ) )
		end switch
	end if
end function

procedure shift_switch( integer pc, integer start, integer amount )
-- switch ops require some special processing due to their relative jumps
	integer addr
	if sequence( Code[pc+4] ) then
		addr = Code[pc+4][2]
	else
		addr = Code[pc+4]
	end if
	
	-- the jump to end / else is still absolute, though:
	if start < addr then
		if sequence( Code[pc+4] ) then
			Code[pc+4][2] += amount
		else
			Code[pc+4] += amount
		end if
	end if
	
	if start < pc or start > addr then
		-- doesn't affect the switch jumps
		return
	end if
	
	sequence jump = SymTab[Code[pc+3]][S_OBJ]
	for i = 1 to length(jump) do
		if start > pc and start < pc + jump[i] then
			jump[i] += amount
		end if
	end for
	SymTab[Code[pc+3]][S_OBJ] = jump
end procedure

procedure shift_addr( integer pc, integer amount, integer start, integer bound )
	if atom( Code[pc] ) then
		if Code[pc] >= start then
			if Code[pc] < bound then
				Code[pc] = start
			else
				Code[pc] += amount
			end if
		end if
	else
		if Code[pc][2] >= start then
			if Code[pc][2] < bound then
				Code[pc][2] = start
			else
				Code[pc][2] += amount
			end if
		end if
	end if
end procedure

export procedure shift( integer start, integer amount, integer bound = start )
-- modifies the IL code and the linetable

	if amount = 0 then
		return
	end if
	
	for i = length( LineTable ) to 1 by -1 do
		if LineTable[i] > 0 then
			if LineTable[i] < start then
			exit
			end if
			LineTable[i] += amount
		end if
	end for
	
	integer pc = 1
	integer op
	while pc <= length( Code ) do
		op = Code[pc]
		for i = 1 to length( op_info[op][OP_ADDR] ) do
			
			switch op with fallthru do
				case SWITCH then
				case SWITCH_I then
				case SWITCH_SPI then
				case SWITCH_RT then
					-- these have relative jumps, so we treat them specially
					shift_switch( pc, start, amount )
					break
					
				case else
					shift_addr( pc + op_info[op][OP_ADDR][i], amount, start, bound )
					
			end switch
			if find( op, {} ) then
				
			end if
		end for
		pc = advance( pc )
	end while
	shift_fwd_refs( start, amount )
end procedure

export procedure insert_code( sequence code, integer index )
	Code = splice( Code, code, index )
	shift( index, length( code ) )
end procedure

export procedure replace_code( sequence code, integer start, integer finish )
	Code = replace( Code, code, start, finish )
	shift( start , length( code ) - (finish - start + 1), finish )
end procedure
