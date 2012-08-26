-- (c) Copyright - See License.txt
--
-- shift IL code to dynamically insert, delete or replace previously emitted  IL code

namespace shift

ifdef ETYPE_CHECK then
	with type_check
elsedef
	without type_check
end ifdef

include reswords.e
include global.e
include symtab.e
include fwdref.e
include error.e
include emit.e

export enum
	FIXED_SIZE,
	VARIABLE_SIZE

export sequence op_info = {}

-- op_info is an array of structures with
-- the following members
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
	op_info[COVERAGE_LINE       ] = { FIXED_SIZE, 2, {}, {}, {} }
	op_info[COVERAGE_ROUTINE    ] = { FIXED_SIZE, 2, {}, {}, {} }
	op_info[C_FUNC              ] = { FIXED_SIZE, 5, {}, {4}, {3} }
	op_info[C_PROC              ] = { FIXED_SIZE, 4, {}, {}, {3} }
	op_info[DATE                ] = { FIXED_SIZE, 2, {}, {1}, {} }
	op_info[DELETE_ROUTINE      ] = { FIXED_SIZE, 4, {}, {3}, {} }
	op_info[DELETE_OBJECT       ] = { FIXED_SIZE, 2, {}, {}, {} }
	op_info[DIV2                ] = { FIXED_SIZE, 4, {}, {3}, {} }
	op_info[DIVIDE              ] = { FIXED_SIZE, 4, {}, {3}, {} }
	op_info[ELSE                ] = { FIXED_SIZE, 2, {1}, {}, {} }
	op_info[EXIT                ] = { FIXED_SIZE, 2, {1}, {}, {} }
	op_info[EXIT_BLOCK          ] = { FIXED_SIZE, 2, {},  {}, {} }
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
	op_info[LHS_SUBS1           ] = { FIXED_SIZE, 5, {}, {3,4}, {} }
	op_info[LHS_SUBS1_COPY      ] = { FIXED_SIZE, 5, {}, {3,4}, {} }
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
	op_info[PEEK8U              ] = { FIXED_SIZE, 3, {}, {2}, {} }
	op_info[PEEK8S              ] = { FIXED_SIZE, 3, {}, {2}, {} }
	op_info[PEEK2U              ] = { FIXED_SIZE, 3, {}, {2}, {} }
	op_info[PEEK2S              ] = { FIXED_SIZE, 3, {}, {2}, {} }
	op_info[PEEK4U              ] = { FIXED_SIZE, 3, {}, {2}, {} }
	op_info[PEEK4S              ] = { FIXED_SIZE, 3, {}, {2}, {} }
	op_info[PEEKS               ] = { FIXED_SIZE, 3, {}, {2}, {} }
	op_info[PEEK                ] = { FIXED_SIZE, 3, {}, {2}, {} }
	op_info[SIZEOF              ] = { FIXED_SIZE, 3, {}, {2}, {} }
	op_info[PEEK_POINTER        ] = { FIXED_SIZE, 3, {}, {2}, {} }
	op_info[PLENGTH             ] = { FIXED_SIZE, 3, {}, {2}, {} }
	op_info[PLUS                ] = { FIXED_SIZE, 4, {}, {3}, {} }
	op_info[PLUS_I              ] = { FIXED_SIZE, 4, {}, {3}, {} }
	op_info[PLUS1               ] = { FIXED_SIZE, 4, {}, {3}, {} }
	op_info[PLUS1_I             ] = { FIXED_SIZE, 4, {}, {3}, {} }
	op_info[POKE                ] = { FIXED_SIZE, 3, {}, {}, {} }
	op_info[POKE2               ] = { FIXED_SIZE, 3, {}, {}, {} }
	op_info[POKE4               ] = { FIXED_SIZE, 3, {}, {}, {} }
	op_info[POKE8               ] = { FIXED_SIZE, 3, {}, {}, {} }
	op_info[POKE_POINTER        ] = { FIXED_SIZE, 3, {}, {}, {} }
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
	op_info[RETURNF             ] = { FIXED_SIZE, 4, {}, {}, {} }
	op_info[RETURNP             ] = { FIXED_SIZE, 3, {}, {}, {} }
	op_info[RETURNT             ] = { FIXED_SIZE, 1, {}, {}, {} }
	op_info[RHS_SLICE           ] = { FIXED_SIZE, 5, {}, {4}, {} }
	op_info[RHS_SUBS            ] = { FIXED_SIZE, 4, {}, {3}, {} }
	op_info[RHS_SUBS_I          ] = { FIXED_SIZE, 4, {}, {3}, {} }
	op_info[RHS_SUBS_CHECK      ] = { FIXED_SIZE, 4, {}, {3}, {} }
	op_info[RIGHT_BRACE_2       ] = { FIXED_SIZE, 4, {}, {3}, {} }

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

	op_info[REF_TEMP            ] = { FIXED_SIZE, 2, {}, {}, {} }
	op_info[DEREF_TEMP          ] = { FIXED_SIZE, 2, {}, {}, {} }
	op_info[NOVALUE_TEMP        ] = { FIXED_SIZE, 2, {}, {}, {} }

	op_info[PROC_FORWARD        ] = { VARIABLE_SIZE, 0, {}, {}, {} }
	op_info[FUNC_FORWARD        ] = { VARIABLE_SIZE, 0, {}, {}, {} }

	op_info[RIGHT_BRACE_N       ] = { VARIABLE_SIZE, 3, {}, {}, {} } -- target: [pc+1] + 2
	op_info[CONCAT_N            ] = { VARIABLE_SIZE, 0, {}, {}, {} } -- target: [pc+1] + 2
	op_info[PROC                ] = { VARIABLE_SIZE, 0, {}, {}, {} }
	op_info[PROC_TAIL           ] = op_info[PROC]
end procedure

init_op_info()

function op_size( integer pc, sequence code = Code )
	integer op = code[pc]
	sequence info = op_info[op]
	integer int = info[OP_SIZE_TYPE]
	
	if int = FIXED_SIZE then
		int = info[OP_SIZE]
		return int
	else
		switch op do
			case PROC, PROC_TAIL then
				info = SymTab[code[pc+1]]
				return info[S_NUM_ARGS] + 2 + (info[S_TOKEN] != PROC)
			case PROC_FORWARD then
				int = code[pc+2]
				int += 3
			case FUNC_FORWARD then
				int = code[pc+2]
				int += 4
			case RIGHT_BRACE_N, CONCAT_N then
				int = code[pc+1]
				int += 3
			case else
				InternalErr( 269, {op} )
		end switch
		return int
	end if
end function

export function advance( integer pc, sequence code = Code )
	pc += op_size( pc, code )
	return pc
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

	sequence jump = SymTab[Code[pc+3]][S_OBJ]
	for i = 1 to length(jump) do
		if start > pc and start < pc + jump[i] then
			jump[i] += amount
		end if
	end for
	SymTab[Code[pc+3]][S_OBJ] = jump
end procedure

procedure shift_addr( integer pc, integer amount, integer start, integer bound )
	integer int
	if atom( Code[pc] ) then
		int = Code[pc]
		if int >= start then
			if int < bound then
				Code[pc] = start
			else
				int += amount
				Code[pc] = int
			end if
		end if
	else
		int = Code[pc][2]
		if int >= start then
			if int < bound then
				Code[pc][2] = start
			else
				int += amount
				Code[pc][2] = int
			end if
		end if
	end if
end procedure

export procedure shift( integer start, integer amount, integer bound = start )
-- modifies the IL code and the linetable

	if amount = 0 then
		return
	end if

	integer int
	for i = length( LineTable ) to 1 by -1 do
		int = LineTable[i]
		if int > 0 then
			if int < start then
				exit
			end if
			int += amount
			LineTable[i] = int
		end if
	end for

	integer pc = 1
	integer op
	integer finish = start + amount - 1
	integer len = length( Code )
	while pc <= len do
		if pc < start or pc > finish then
			op = Code[pc]
			sequence addrs = op_info[op][OP_ADDR]
			for i = 1 to length( addrs ) do

				switch op with fallthru do
					case SWITCH then
					case SWITCH_I then
					case SWITCH_SPI then
					case SWITCH_RT then
						-- these have relative jumps, so we treat them specially
						shift_switch( pc, start, amount )
						break

					case else
						int = addrs[i]
						shift_addr( pc + int, amount, start, bound )

				end switch
			end for
		end if
		pc = advance( pc )
	end while
	shift_fwd_refs( start, amount )
	move_last_pc( amount )
end procedure

export procedure insert_code( sequence code, integer index )
	Code = splice( Code, code, index )
	shift( index, length( code ) )
end procedure

--**
-- replaces the subsequence of the global variable Code, Code[start..finish] with code[start..finish] 
-- and then adjusts the addresses from code to be like that of Code
export procedure replace_code( sequence code, integer start, integer finish )
	Code = replace( Code, code, start, finish )
	shift( start, length( code ) - (finish - start + 1), finish )
end procedure

--**
-- Returns a sequence of the current op and all of its operands.
export function current_op( integer pc, sequence code = Code )

	if pc > length(code) or pc < 1 then
		return {}
	end if
	return code[pc..pc-1+op_size( pc, code )]
end function

--**
-- Returns a sequence of ops and all of their operands.  The
-- offset describes the offset of the number of ops from the current.
export function get_ops( integer pc, integer offset, integer num_ops = 1, sequence code=Code )
	integer sign = offset >= 0
	if not sign then
		offset = -offset
		sign = -1
	end if

	while offset do
		pc = advance( pc )
		offset -= sign
	end while

	sequence ops = repeat( 0, num_ops )
	integer opx = 1
	while num_ops and pc <= length(code) do
		ops[opx] = current_op( pc )
		pc += length( ops[opx] )
		opx += 1
		num_ops -= 1
	end while
	if num_ops then
		ops = head( ops, length( ops ) - num_ops )
	end if
	return ops
end function

export function find_ops( integer pc, integer op, sequence code=Code )
	sequence ops = {}
	while pc <= length(code) do
		sequence found_op = current_op( pc )
		if found_op[1] = op then
			ops = append( ops, { pc, found_op } )
		end if
		pc += length( found_op )
	end while
	return ops
end function

--**
-- Pass in the result of [:current_op].  The return value will be
-- zero if there is no target, or the sym of the target for the op,
-- or a sequence of syms if the op has multiple targets
-- (e.g., LHS_SUBS).
export function get_target_sym( sequence opseq )
	if not length( opseq ) then
		return 0
	end if
	integer op = opseq[1]
	sequence info = op_info[op]

	if info[OP_SIZE_TYPE] = FIXED_SIZE then
		switch length( info[OP_TARGET] ) do
			case 0 then
				break

			case 1 then
				return opseq[info[OP_TARGET][1]+1]

			case else
				sequence targets = info[OP_TARGET]
				for i = 1 to length( targets ) do
					targets[i] = opseq[targets[i] + 1]
				end for

				return targets

		end switch

	else

		switch op do
			case PROC, PROC_TAIL then
				symtab_index sub = opseq[2]
				if sym_token( sub ) = FUNC then
					return opseq[$]
				end if

			case FUNC_FORWARD then
				return opseq[$]

			case RIGHT_BRACE_N, CONCAT_N then
				return opseq[opseq[2]+2]

		end switch
	end if
	return 0
end function
