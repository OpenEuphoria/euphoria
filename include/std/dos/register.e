--**
-- Length of a register list

export constant REG_LIST_SIZE = 10

--**
-- Register structure

export enum 
	REG_DI,
	REG_SI,
	REG_BP,
	REG_BX,
	REG_DX,
	REG_CX,
	REG_AX,
	REG_FLAGS, -- on input: ignored 
			   -- on output: low bit has carry flag for 
			   -- success/fail
	REG_ES,
	REG_DS

--**
-- register list type

export type register_list(sequence r)
-- a list of register values
	return length(r) = REG_LIST_SIZE
end type

