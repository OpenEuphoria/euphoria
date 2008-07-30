
constant
	M_GET_VECTOR = 39,
	M_SET_VECTOR = 40,
	M_LOCK_MEMORY = 41


-- internal - used in dos/safe.e and dos/memory.e

export constant
	M_ALLOC_LOW = 32,
	M_FREE_LOW = 33

--**
-- biggest address accessible to 16-bit real mode
export constant LOW_ADDR = power(2, 20)-1

--**
-- a legal low machine address
export type low_machine_addr(atom a)
	return a > 0 and a <= LOW_ADDR and floor(a) = a
end type

--**
-- Positive Integer Type

export type positive_int(integer x)
	return x >= 1
end type

include memory.e

-- biggest address on a 32-bit machine
constant MAX_ADDR = power(2, 32)-1

--**
-- Machine Address Type

export type machine_addr(atom a)
-- a 32-bit non-null machine address 
	return a > 0 and a <= MAX_ADDR and floor(a) = a
end type

type far_addr(sequence a)
-- protected mode far address {seg, offset}
	return length(a) = 2 and integer(a[1]) and machine_addr(a[2])
end type

--**
-- Retrieve the address of a //DOS// interrupt handler.
--
-- Platform:
--		//DOS32//
--
-- Parameters:
--		# ##int_um##: an integer in the 0..255 range, the number of the interrupt.
--
-- Returns:
--		A **sequence** of length 2: {16-bit segment, 32-bit offset}
--
-- Comments:
-- This way to return the address is convenient to pass it to other //DOS// routines. To convert 
-- it back to a flat 32-bit address, simply use 65536*segment+offset.
--
-- Example 1:
-- <eucode>
--  s = get_vector(#1C)
-- -- s will be set to the far address of the clock tick
-- -- interrupt handler, for example: {59, 808}
-- </eucode>
--  
-- Example 2: 
--		[[../demo/dos32/hardint.ex]]
--
-- See Also:
-- 		[[:set_vector]], [[:dos_interrupt]]

export function get_vector(integer int_num)
	return machine_func(M_GET_VECTOR, int_num)
end function

--**
-- Set the address of a //DOS// interrupt handler.
--
-- Platform:
--		//DOS32//
--
-- Parameters:
--		# ##int_um##: an integer in the 0..255 range, the number of the interrupt.
-- 		# ##addr##: a sequence like returned by [[:get_vector]].
--
-- Comments:
-- When setting an interrupt vector, //never// forget to restore it before your program 
-- terminates. Also, the machine code that will handle the interrupt must be at its expected 
-- address //before// calling ##set_vector##(). It is highly recommended that you study 
-- ##../demo/dos32/hardint.ex## before trying to set up your own interrupt handler. This task 
-- requires a good knowledge of machine-level programming. Disassembling a small freeware TSR 
-- is one of the best schools for this.
--
-- It is usually a good policy to chain to the previous interrupt handler. Since the latter may 
-- be doing some good work already, it is often a convenience as well.
--
-- Your handler might return from the interrupt using the iretd instruction, or jump to the 
-- original interrupt handler. It should save and restore any registers that it modifies. 
--
-- Interrupts occurring in either real mode or protected mode will be passed to your handler. 
-- Your interrupt handler should immediately load the correct data segment before it tries to 
-- reference memory. 
--
-- You should lock the memory used by your handler to ensure that it will never be swapped out. 
-- See [[:lock_memory]]().
-- 
-- A handler for IRQ-mapped interrupts (8..15 and 112..119) must acknowledge the interrupt if
-- it does not pass it to th previous handler. Your machine code should perform an OUT DX,AL
-- instruction with both DX and AL set to #20.
--
-- The 16-bit segment can be the code segment used by Euphoria. To get the value of this segment 
-- see ##../demo/dos32/hardint.ex##. The offset can be the 32-bit value returned by
-- [[:allocate]](). Euphoria runs in protected mode with the code segment and data segment pointing 
-- to the same physical memory, but with different access modes.
--
-- Example 1:
--		##../demo/hardint.ex##
--
-- Example 2:
-- <eucode>
--  set_vector(#1C, {code_segment, my_handler_address})
-- </eucode>
-- 
-- See Also:
--       [[:get_vector]], [[:lock_memory]], [[:allocate]]

export procedure set_vector(integer int_num, far_addr a)
	machine_proc(M_SET_VECTOR, {int_num, a})
end procedure

--**
-- Prevent a memory area to be swapped out of memory.
--
-- Platform:
--		//DOS32//
--
-- Parameters:
--		# ##addr##: an atom, the starting address of the area to protect
--		# ##len##: an integer, the length of the area to protect.
--
-- Comments:
-- lock_memory() should only be used in the highly-specialized situation where you have set up 
-- your own DOS hardware interrupt handler using machine code. When a hardware interrupt occurs, 
-- it is not possible for the operating system to retrieve any code or data that has been swapped 
-- out, so you need to protect any blocks of machine code or data that will be needed in servicing 
-- the interrupt.
--
-- Example 1: 
--		##../demo/dos32/hardint.ex##
--
-- See Also: 
--		[[:get_vector]], [[:set_vector]]

export procedure lock_memory(machine_addr a, positive_int n)
	machine_proc(M_LOCK_MEMORY, {a, n})
end procedure

