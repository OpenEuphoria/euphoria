-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--

--****
-- == Calling an interrupt under DOS
--
-- <<LEVELTOC depth=2>>
--
-- === Constants
--

--**
-- Length of a register list

export constant REG_LIST_SIZE = 10

constant M_INTERRUPT = 34

--**
-- Register structure
--
-- * REG_DI
-- * REG_SI
-- * REG_BP
-- * REG_BX
-- * REG_DX
-- * REG_CX
-- * REG_AX
-- * REG_FLAGS
-- * REG_ES
-- * REG_DS

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

--****
-- === Routines
--

--**
-- Call a //DOS// interrupt.
--
-- Platform:
--		//DOS32//
--
-- Parameters:
--		# ##int_num##, a, integer between 0 and 255, the interrupt number.
--		# ##input_regs##, a sequence indicating how should the machine
-- registers be on calling the interrupt.
--
-- Returns:
--		A **sequence** holding the contents of registers on return from the
-- interrupt.
--
-- Comments:
--		You should carefully read the documentation of the API you want to
-- call before making a ##dos_interrupt##() call. Machine level exceptions
-- are frequent while debugging.
--
-- Certain interrupts require that you supply addresses of blocks of memory.
-- These addresses must be conventional, low-memory addresses. You can
-- allocate/deallocate low-memory using allocate_low() and free_low().
-- 
-- With DOS software interrupts you can perform a wide variety of
-- specialized operations, anything from formatting your floppy drive to
-- rebooting your computer. For documentation on these interrupts consult
-- a technical manual such as Peter Norton's "PC Programmer's Bible", or
-- download Ralf Brown's Interrupt List from the Web: 
--
-- [[http://www.cs.cmu.edu/afs/cs.cmu.edu/user/ralf/pub/WWW/files.html]]
--  
-- Example 1:
-- <eucode>
--  sequence registers
--
-- registers = repeat(0, 10)  -- no registers need to be set
--
-- -- call DOS interrupt 5: Print Screen
-- registers = dos_interrupt(#5, registers)
-- </eucode>
-- 
-- Example 2:
--		[[../demo/dos32/dosint.ex]]
--  
-- See Also: , 
--       [[:allocate_low]], [[:free_low]]

export function dos_interrupt(integer int_num, register_list input_regs)
-- call the DOS operating system via software interrupt int_num, using the
-- register values in input_regs. A similar register_list is returned.
-- It contains the register values after the interrupt.
	object r
	r = machine_func(M_INTERRUPT, {int_num, input_regs})
	ifdef SAFE then
		if check_calls then
			check_all_blocks()
		end if
	end ifdef
	return r
end function

