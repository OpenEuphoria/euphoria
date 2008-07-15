-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
--****
-- == Machine Level
--
-- Warning: Some of these routines require a knowledge of 
-- machine-level programming. You could crash your system!

-- These routines, along with peek(), poke() and call(), let you access all
-- of the features of your computer.  You can read and write to any memory 
-- location, and you can create and execute machine code subroutines.

-- If you are manipulating 32-bit addresses or values, remember to use
-- variables declared as atom. The integer type only goes up to 31 bits.

-- Writing characters to screen memory with poke() is much faster than  
-- using puts(). Address of start of text screen memory:
--
-- * mono: #B0000
-- * color: #B8000
--
-- If you choose to call machine_proc() or machine_func() directly (to save
-- a bit of overhead) you *must* pass valid arguments or Euphoria could crash.
--
-- Some example programs to look at:
--   * ##demo\callmach.ex##      - calling a machine language routine
--   * ##demo\dos32\hardint.ex## - setting up a hardware interrupt handler
--   * ##demo\dos32\dosint.ex##  - calling a DOS software interrupt
--
-- See also ##include/safe.e##. It's a safe, debugging version of this
-- file.
--
-- **Page Contents**
--
-- <<LEVELTOC depth=2>>
--

constant M_ALLOC = 16,
		 M_FREE = 17,
		 M_ALLOC_LOW = 32,
		 M_FREE_LOW = 33,
		 M_INTERRUPT = 34,
		 M_USE_VESA = 36,
		 M_GET_VECTOR = 39,
		 M_SET_VECTOR = 40,
		 M_LOCK_MEMORY = 41

-- biggest address on a 32-bit machine
constant MAX_ADDR = power(2, 32)-1

-- biggest address accessible to 16-bit real mode
constant LOW_ADDR = power(2, 20)-1

type positive_int(integer x)
	return x >= 1
end type

type machine_addr(atom a)
-- a 32-bit non-null machine address 
	return a > 0 and a <= MAX_ADDR and floor(a) = a
end type

type far_addr(sequence a)
-- protected mode far address {seg, offset}
	return length(a) = 2 and integer(a[1]) and machine_addr(a[2])
end type

type low_machine_addr(integer a)
-- a legal low machine address 
	return a > 0 and a <= LOW_ADDR 
end type

type sequence_8(sequence s)
-- an 8-element sequence
	return length(s) = 8
end type

type sequence_4(sequence s)
-- a 4-element sequence
	return length(s) = 4
end type

--****
-- === Constants
--
-- Register list length:
-- * global constant REG_LIST_SIZE = 10
global constant REG_LIST_SIZE = 10

--**
-- Register slots in a register structure:
-- * REG_DI = 1,
-- * REG_SI = 2,
-- * REG_BP = 3,
-- * REG_BX = 4,
-- * REG_DX = 5,
-- * REG_CX = 6,
-- * REG_AX =	 7,
-- * REG_FLAGS = 8, -- on input: ignored
     		   -- on output: low bit has carry flag for
     		   -- success/fail
-- * REG_ES = 9,
-- * REG_DS = 10

global constant 
				REG_DI = 1,
				REG_SI = 2,
				REG_BP = 3,
				REG_BX = 4,
				REG_DX = 5,
				REG_CX = 6,
				REG_AX = 7,
				REG_FLAGS = 8, -- on input: ignored
							   -- on output: low bit has carry flag for 
							   -- success/fail
				REG_ES = 9,
				REG_DS = 10

type register_list(sequence r)
-- a list of register values
	return length(r) = REG_LIST_SIZE
end type

--****
-- === Routines
-- ==== Memory management
--**
-- Allocate a contiguous block of memory.
--
-- Parameters:
--		# ##n##, a positive integer, the size of the requested block.
--
-- Return:
--		An **atom**, the address of the allocated memory, or 0 if the memory 
-- can't be allocated.
--
-- Comments:
-- When you are finished using the block, you should pass the address of the block to 
-- ##[[:free]]()##. This will free the block and make the memory available for other purposes. 
-- Euphoria will never free or reuse your block until you explicitly call ##[[:free]]()##. When 
-- your program terminates, the operating system will reclaim all memory for use with other 
-- programs.
--
-- The address returned will be at least 4-byte aligned.
--
-- Example:		
-- <eucode>
-- buffer = allocate(100)
-- for i = 0 to 99 do
--     poke(buffer+i, 0)
-- end for
-- </eucode>
--		    
-- See Also:
--     [[:free]], [[:allocate_low]], [[:peek]], [[:poke]], [[:mem_set]], [[:call]]

global function allocate(positive_int n)
-- Allocate n bytes of memory and return the address.
-- Free the memory using free() below.
	return machine_func(M_ALLOC, n)
end function

--**
-- Free up a previously allocated block of memory.
--
-- Parameters:
--		# ##addr##, an atom, the address of a block to free.
-- block, i.e. the address that was returned by ##[[:allocate]]()##.
--
-- Comments:
--   Use ##free()## to recycle blocks of memory during execution. This will reduce the chance of 
--   running out of memory or getting into excessive virtual memory swapping to disk. Do not 
--   reference a block of memory that has been freed. When your program terminates, all 
--   allocated memory will be returned to the system.
-- 
--   Do not use ##free()## to deallocate memory that was allocated using ##[[:allocate_low]]()##. 
--   Use ##[[:free_low]]()## for this purpose.
--
-- ##addr## must have been allocated previously using [[:allocate]](). You
-- cannot use it to relinquish part of a block. Instead, you have to allocate
-- a block of the new size, copy useful contents from old block there and
-- then free() the old block.
--
-- Example 1:
--   [[../demo/callmach.]]
--
-- See Also:
--     [[:allocate]], [[:free_low]]

global procedure free(machine_addr addr)
-- free the memory at address a
	machine_proc(M_FREE, addr)
end procedure

--**
-- Allocate a C-style null-terminated string in memory
--
-- Parameters:
--		# ##s##, a sequence, the string to store in RAM.
--
-- Returns:
--		An **atom**, the address of the memory block where the string was
-- stored, or 0 on failure.
-- Comments:
-- Only the 8 lowest bits of each atom in ##s## is stored. Use
-- ##allocate_wstring##()  for storing dounle byte encoded strings.
--
-- There is no allocate_string_low() function. However, you could easily
-- craft one by adapting the code for ##allocate_string##.
--
-- Since allocate_string() allocates memory, you are responsible to
-- [[:free]]() the block when done with it.
--
-- Example 1:
-- <eucode>
--  atom title
--
-- title = allocate_string("The Wizard of Oz")
-- </eucode>
-- 
-- See Also:
--		[[:allocate]], [[:allocate_low]], [[:allocate_wstring]]

global function allocate_string(sequence s)
	atom mem
	
	mem = machine_func(M_ALLOC, length(s) + 1) -- Thanks to Igor
	if mem then
		poke(mem, s)
		poke(mem+length(s), 0)  -- Thanks to Aku
	end if
	return mem
end function

--==== ///DOS// specific calls
--**
-- Prevent a memory area to be swapped out of memory.
--
-- Platform:
--		//DOS32//
--
-- Parameters:
--		# ##addr##, an atom, the starting address of the area to protect
--		# ##len##, an integer, the length of the area to protect.
--
-- Comments:
-- lock_memory() should only be used in the highly-specialized situation
-- where you have set up your own DOS hardware interrupt handler using
-- machine code. When a hardware interrupt occurs, it is not possible for
-- the operating system to retrieve any code or data that has been swapped
-- out, so you need to protect any blocks of machine code or data that will
-- be needed in servicing the interrupt.
--
-- Example 1: 
--		[[../demo/dos32/hardint.ex]]
--
-- See Also: 
--		[[:get_vector]], [[:set_vector]]

global procedure lock_memory(machine_addr a, positive_int n)
-- Prevent a chunk of code or data from ever being swapped out to disk.
	machine_proc(M_LOCK_MEMORY, {a, n})
end procedure

--**
-- Allocate a contiguous block of conventional memory (address below 1 megabyte).
--
-- Platform:
--		//DOS32//
--
-- Parameters:
--		# ##n##, an integer, the size of the requested block of conventional memory.
-- Returns:
--		An **atom**, the address of the block of memory, or 0 if the memory can't
-- be allocated.
--
-- Comments:
--   Some //DOS// software interrupts require that you pass one or more addresses in registers. 
--   These addresses must be conventional memory addresses for DOS to be able to read or write 
--   to them.
--
-- Example 1:
--   [[../demo/dos32/dosint]]
--
-- See Also:
--   [[:dos_interrupt]], [[:free_low]], [[:allocate]], [[:peek]], [[:poke]]

global function allocate_low(positive_int n)
-- Allocate n bytes of low memory (address less than 1Mb) 
-- and return the address. Free this memory using free_low() below.
-- Addresses in this range can be passed to DOS during software interrupts.
	return machine_func(M_ALLOC_LOW, n)
end function

--**
-- Free up a previously allocated block of conventional memory.
--
-- Platform:
--		//DOS32//
--
-- Parameters:
--		# ##addr##, an atom the address
-- of the start of the block, i.e. the address that was returned by ##[[:allocate_low]]()##.
--
-- Comments:
--   Use ##free_low()## to recycle blocks of conventional memory during execution. This will 
--   reduce the chance of running out of conventional memory. Do not reference a block of 
--   memory that has been freed. When your program terminates, all allocated memory will be 
--   returned to the system.
--
--   Do not use ##free_low()## to deallocate memory that was allocated using ##[[:allocate]]()##. 
--   Use ##[[:free]]()## for this purpose.
--
-- Example 1:
--   [[../demo/dos32/dosint.ex]]
--
-- See Also:
--   [[:allocate_low]], [[:dos_interrupt]], [[:free]]

global procedure free_low(low_machine_addr addr)
-- free the low memory at address a
	machine_proc(M_FREE_LOW, addr)
end procedure

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
-- machine.e has the following declaration which shows the order of the
-- register values in the input and output sequences.
-- <eucode>
--      global constant REG_DI = 1,
--                     REG_SI = 2,
--                     REG_BP = 3,
--                     REG_BX = 4,
--                     REG_DX = 5,
--                     REG_CX = 6,
--                     REG_AX = 7,
--                     REG_FLAGS = 8, -- input: ignored
--                                    -- output: 1 if carry flag set (which usully means a failure), else 0
--                     REG_ES = 9,
--                     REG_DS = 10
-- </eucode>
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

global function dos_interrupt(integer int_num, register_list input_regs)
-- call the DOS operating system via software interrupt int_num, using the
-- register values in input_regs. A similar register_list is returned.
-- It contains the register values after the interrupt.
	return machine_func(M_INTERRUPT, {int_num, input_regs})
end function

--**
-- Retrieve the address of a //DOS// interrupt handler.
--
-- Platform:
--		//DOS32//
--
-- Parameters:
--		# ##int_um##, an integer in the 0..255 range, the number of the interrupt.
-- Returns:
--		A **sequence of length 2: {16-bit segment, 32-bit offset}
-- Comments:
-- This way to return the address is convenient to pass it to other //DOS//
-- routines. To convert it back to a flat 32-bit address, simply use
-- ##65536 * segment + offset##.
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

global function get_vector(integer int_num)
-- returns the current (far) address of the interrupt handler
-- for interrupt vector number int_num as a 2-element sequence: 
-- {16-bit segment, 32-bit offset}
	return machine_func(M_GET_VECTOR, int_num)
end function

--**
-- Set the address of a //DOS// interrupt handler.
--
-- Platform:
--		//DOS32//
--
-- Parameters:
--		# ##int_um##, an integer in the 0..255 range, the number of the interrupt.
-- 		# ##addr##, a sequence like returned by [[:get_vector]].
--
-- Comments:
-- When setting an interrupt vector, //never// forget to restore it before
-- your program terminates. Also, the machine code that will handle the
-- interrupt must be at its expected address //before// calling
-- ##set_vector##(). It is highly recommended that you study 
-- [[../demo/dos32/hardint.ex]] before trying to set up your own interrupt
-- handler. This task requires a good knowledge of machine-level programming.
-- Disassembling a small freeware TSR is one of the best schools for this.
--
-- It is usually a good policy to chain to the previous interrupt handler.
-- Since the latter may be doing some good work already, it is often a
-- convenience as well.
--
-- Your handler might return from the interrupt using the iretd instruction,
-- or jump to the original interrupt handler. It should save and restore any
-- registers that it modifies. 
--
-- Interrupts occurring in either real mode or protected mode will be passed
-- to your handler. Your interrupt handler should immediately load the
-- correct data segment before it tries to reference memory. 
--
-- You should lock the memory used by your handler to ensure that it will
-- never be swapped out. See [[:lock_memory]]().
-- 
-- A handler for IRQ-mapped interrupts (8..15 and 112..119) must acknowledge
-- the interrupt if it does not pass it to th previous handler. Your machine
-- code should perform an OUT DX,AL instruction with both DX and AL set to #20.
--
-- The 16-bit segment can be the code segment used by Euphoria. To get the
-- value of this segment see [[../demo/dos32/hardint.ex]]. The offset can be
-- the 32-bit value returned by
-- [[:allocate]](). Euphoria runs in protected mode with the code segment
-- and data segment pointing to the same physical memory, but with different
-- access modes.
--
-- Example 1:
--		[[../demo/hardint.ex]]
--
-- Example 2:
-- <eucode>
--  set_vector(#1C, {code_segment, my_handler_address})
-- </eucode>
-- 
-- See Also:
--       [[:get_vector]], [[:lock_memory]], [[:allocate]]

global procedure set_vector(integer int_num, far_addr a)
-- sets a new interrupt handler address for vector int_num  
	machine_proc(M_SET_VECTOR, {int_num, a})
end procedure

--**
-- Set how Euphoria should use the VESA standard to perform video operations.
--
-- Platform:
--		//DOS32//
--
-- Parameters:
-- 		# ##code##, an integer, must be 0 or 1.
--
-- Comments:
-- If code is 1 then force Euphoria to use the VESA graphics standard.
-- This may let Euphoria work better in SVGA modes with certain graphics cards.
-- If code is 0 then Euphoria's normal use of the graphics card is restored.
-- Values of code other than 0 or 1 should not be used.
--
-- Most people can ignore this. However if you experience difficulty in SVGA
-- graphics modes you should try calling use_vesa(1) at the start of your
-- program before any calls to graphics_mode().
--
-- Example 1:
-- <eucode>
--  use_vesa(1)
-- fail = graphics_mode(261)
-- </eucode>
-- 
-- See Also: 
--       [[:graphics_mode]]

global procedure use_vesa(integer code)
	machine_proc(M_USE_VESA, code)
end procedure


--=== Memory access
--**
-- Signature:
-- global function peek(object addr_n_length)
--
-- Description:
-- Fetches a byte, or some bytes, from an address in memory.
--
-- Parameters:
--		# ##addr_n_length##, an object, either of
--		** an atom ##addr##, to fetch one byte at ##addr##, or
--		** a pair {##addr,len}##, to fetch ##len## bytes at ##addr##
--
-- Returns:
--		An **object**, either an integer if the input was a single address,
-- or a sequence of integers if a sequence was passed. In both cases,
-- integers returned are bytes, in the range 0..255.
--
-- Errors:
--	Peek()ing in memory you don't own may be blocked by the OS, and cause a
-- machine exception. The safe.e include file can catch this sort of issues.
--
-- Comments: 
-- Since addresses are 32-bit numbers, they can be larger than the largest
-- value of type integer (31-bits). Variables that hold an address should 
-- therefore be declared as atoms.
--
-- It is faster to read several bytes at once using the second form of peek()
-- than it is to read one byte at a time in a loop. The returned sequence has
-- the length you asked for on input.
-- 
-- Remember that ##peek##() takes just one argument, which in the second form
-- is actually a 2-element sequence.
--  
-- Example 1: 
-- <eucode>
-- -- The following are equivalent:
-- -- method 1
-- s = {peek(100), peek(101), peek(102), peek(103)}
-- 
-- -- method 2
-- s = peek({100, 4})
-- </eucode>
-- 
-- See Also: 
--  [[:poke]], [[:peek4s]], [[:peek4u]], [[:allocate]], [[:free]], [[:allocate_low]], 
-- [[:free_low]], [[:call]], [[:peek2s]], [[:peek2u]]
--
--**
-- Signature:
-- global function peeks(object addr_n_length)
--
-- Description:
-- Fetches a byte, or some bytes, from an address in memory.
--
-- Parameters:
--		# ##addr_n_length##, an object, either of
--		** an atom ##addr##, to fetch one byte at ##addr##, or
--		** a pair {##addr,len}##, to fetch ##len## bytes at ##addr##
--
-- Returns:
--		An **object**, either an integer if the input was a single address,
-- or a sequence of integers if a sequence was passed. In both cases,
-- integers returned are bytes, in the range -128..127.
--
-- Errors:
--	Peek()ing in memory you don't own may be blocked by the OS, and cause
-- a machine exception. The safe.e include file can catch this sort of issues.
--
-- Comments: 
-- Since addresses are 32-bit numbers, they can be larger than the largest
-- value of type integer (31-bits). Variables that hold an address should
-- therefore be declared as atoms.
--
-- It is faster to read several bytes at once using the second form of peek()
-- than it is to read one byte at a time in a loop. The returned sequence has
-- the length you asked for on input.
-- 
-- Remember that ##peeks##() takes just one argument, which in the second
-- form is actually a 2-element sequence.
--  
-- Example 1: 
-- <eucode>
-- -- The following are equivalent:
-- -- method 1
-- s = {peeks(100), peek(101), peek(102), peek(103)}
-- 
-- -- method 2
-- s = peeks({100, 4})
-- </eucode>
-- 
-- See Also: 
--  [[:poke]], [[:peek4s]], [[:peek4u]], [[:allocate]], [[:free]], [[:allocate_low]], 
-- [[:free_low]], [[:call]], [[:peek2s]], [[:peek2u]], [[peek]]
--
--**
-- Signature:
-- global function peek2s(object addr_n_length)
--
-- Description:
-- Fetches a //signed// word, or some //signed// words	, from an address
-- in memory.
--
-- Parameters:
--		# ##addr_n_length##, an object, either of
--		** an atom ##addr##, to fetch one word at ##addr##, or
--		** a pair {##addr,len}##, to fetch ##len## words at ##addr##
--
-- Returns:
--		An **object**, either an integer if the input was a single address,
-- or a sequence of integers if a sequence was passed. In both cases,
-- integers returned are double words, in the range -32768..32767.
--
-- Errors:
--	Peek()ing in memory you don't own may be blocked by the OS, and cause
-- a machine exception. The safe.e i,clude file can catch this sort of issues.
--
-- Comments: 
-- Since addresses are 32-bit numbers, they can be larger than the largest
-- value of type integer (31-bits). Variables that hold an address should
-- therefore be declared as atoms.
--
-- It is faster to read several words at once using the second form of peek()
-- than it is to read one word at a time in a loop. The returned sequence has
-- the length you asked for on input.
-- 
-- Remember that ##peek2s##() takes just one argument, which in the second
-- form is actually a 2-element sequence.
--
-- The only difference between ##peek2s##() and ##peek2u##() is how words
-- with the highest bit set are returned. ##peek2s##() assumes them to be
-- negative, while ##peek2u##() just assumes them to be large and positive.
--  
-- Example 1: 
-- <eucode>
-- -- The following are equivalent:
-- -- method 1
-- s = {peek2s(100), peek2s(102), peek2s(104), peek2s(106)}
--
-- -- method 2
-- s = peek2s({100, 4})
-- </eucode>
-- 
-- See Also: 
--  [[:poke]], [[:peek]], [[:peek4s]], [[:peek4u]], [[:allocate]], [[:free]], [[:allocate_low]],
-- [[:free_low]], [[:call]], [[:peek2u]]
--
--**
-- Signature:
-- global function peek2u(object addr_n_length)
--
-- Description:
-- Fetches an //unsigned// word, or some //unsigned// words, from an address
-- in memory.
--
-- Parameters:
--		# ##addr_n_length##, an object, either of
--		** an atom ##addr##, to fetch one double word at ##addr##, or
--		** a pair {##addr,len}##, to fetch ##len## double words at ##addr##
--
-- Returns:
--		An **object**, either an integer if the input was a single address,
-- or a sequence of integers if a sequence was passed. In both cases,
-- integers returned are words, in the range 0..65535.
--
-- Errors:
--	Peek()ing in memory you don't own may be blocked by the OS, and cause a
-- machine exception. The safe.e include file can catch this sort of issues.
--
-- Comments: 
-- Since addresses are 32-bit numbers, they can be larger than the largest
-- value of type integer (31-bits). Variables that hold an address should
-- therefore be declared as atoms.
--
-- It is faster to read several words at once using the second form of peek()
-- than it is to read one word at a time in a loop. The returned sequence has
-- the length you asked for on input.
-- 
-- Remember that ##peek2u##() takes just one argument, which in the second
-- form is actually a 2-element sequence.
--
-- The only difference between ##peek2s##() and ##peek2u##() is how words
-- with the highest bit set are returned. ##peek2s##() assumes them to be
-- negative, while ##peek2u##() just assumes them to be large and positive.
--  
-- Example 1: 
-- <eucode>
-- -- The following are equivalent:
-- -- method 1
-- s = {peek2u(100), peek2u(102), peek2u(104), peek2u(106)}
--
-- -- method 2
-- s = peek2u({100, 4})
-- </eucode>
-- 
-- See Also: 
--  [[:poke]], [[:peek]], [[:peek2s]], [[:allocate]], [[:free]], [[:allocate_low]],
-- [[:free_low]], [[:call]], [[:peek4s]], [[:peek4u]]
--
--**
-- Signature:
-- global function peek4s(object addr_n_length)
--
-- Description:
-- Fetches a //signed// double words, or some //signed// double words,
-- from an address in memory.
--
-- Parameters:
--		# ##addr_n_length##, an object, either of
--		** an atom ##addr##, to fetch one double word at ##addr##, or
--		** a pair {##addr,len}##, to fetch ##len## double words at ##addr##
--
-- Returns:
--		An **object**, either an atom if the input was a single address, or a
-- sequence of atoms if a sequence was passed. In both cases, atoms returned
-- are double words, in the range 0..power(2,32)-1.
--
-- Errors:
--	Peek()ing in memory you don't own may be blocked by the OS, and cause a
-- machine exception. The safe.e i,clude file can catch this sort of issues.
--
-- Comments: 
-- Since addresses are 32-bit numbers, they can be larger than the largest
-- value of type integer (31-bits). Variables that hold an address should
-- therefore be declared as atoms.
--
-- It is faster to read several double words at once using the second form
-- of peek() than it is to read one double word at a time in a loop. The
-- returned sequence has the length you asked for on input.
-- 
-- Remember that ##peek4s##() takes just one argument, which in the second
-- form is actually a 2-element sequence.
--
-- The only difference between ##peek4s##() and ##peek4u##() is how double
-- words with the highest bit set are returned. ##peek4s##() assumes them to
-- be negative, while ##peek4u##() just assumes them to be large and positive.
--  
-- Example 1: 
-- <eucode>
-- -- The following are equivalent:
-- -- method 1
-- s = {peek4s(100), peek4s(104), peek4s(108), peek4s(112)}
--
-- -- method 2
-- s = peek4s({100, 4})
-- </eucode>
-- 
-- See Also: 
--  [[:poke]], [[:peek]], [[:peek4u]], [[:allocate]], [[:free]], [[:allocate_low]],
-- [[:free_low]], [[:call]], [[:peek2s]], [[:peek2u]]
--
--**
-- Signature:
-- global function peek4u(object addr_n_length)
--
-- Description:
-- Fetches an //unsigned// double word, or some //unsigned// dounle words,
-- from an address in memory.
--
-- Parameters:
--		# ##addr_n_length##, an object, either of
--		** an atom ##addr##, to fetch one double word at ##addr##, or
--		** a pair {##addr,len}##, to fetch ##len## double words at ##addr##
--
-- Returns:
--		An **object**, either an atom if the input was a single address, or
-- a sequence of atoms if a sequence was passed. In both cases, atoms
-- returned are double words, in the range 
-- -power(2,31)..power(2,31)-1.
--
-- Errors:
--	Peek()ing in memory you don't own may be blocked by the OS, and cause
-- a machine exception. The safe.e include file can catch this sort of issues.
--
-- Comments: 
-- Since addresses are 32-bit numbers, they can be larger than the largest
-- value of type integer (31-bits). Variables that hold an address should
-- therefore be declared as atoms.
--
-- It is faster to read several double words at once using the second form 
-- of peek() than it is to read one double word at a time in a loop. The
-- returned sequence has the length you asked for on input.
-- 
-- Remember that ##peek4u##() takes just one argument, which in the second
-- form is actually a 2-element sequence.
--
-- The only difference between ##peek4s##() and ##peek4u##() is how double
-- words with the highest bit set are returned. ##peek4s##() assumes them
-- to be negative, while ##peek4u##() just assumes them to be large and
-- positive.
--  
-- Example 1: 
-- <eucode>
-- -- The following are equivalent:
-- -- method 1
-- s = {peek4u(100), peek4u(104), peek4u(108), peek4u(112)}
--
-- -- method 2
-- s = peek4u({100, 4})
-- </eucode>
-- 
-- See Also: 
--  [[:poke]], [[:peek]], [[:peek4s]], [[:allocate]], [[:free]], [[:allocate_low]],
-- [[:free_low]], [[:call]], [[:peek2s]], [[:peek2u]]
--

-- TODO: document peek_string()

--**
-- Signature:
-- global procedure poke(atom addr, object x)
--
-- Description:
-- Stores one or more bytes, starting at a memory location.
--
-- Parameters:
--		# ##addr##, an atom, the address at which to store
--		# ##x##, an object, either a byte or a non empty sequence of bytes.
--
-- Errors:
--	Poke()ing in memory you don't own may be blocked by the OS, and cause a
-- machine exception. The safe.e include file can catch this sort of issues.
--
-- Comments: 
-- The lower 8-bits of each byte value, i.e. remainder(x, 256), is actually
-- stored in memory.
--
-- It is faster to write several bytes at once by poking a sequence of values,
-- than it is to write one byte at a time in a loop. 
-- 
-- Writing to the screen memory with poke() can be much faster than using
-- puts() or printf(), but the programming is more difficult. In most cases
-- the speed is not needed. For example, the Euphoria editor, ed, never uses
-- poke().
--  
-- Example 1:
-- <eucode>
--  a = allocate(100)   -- allocate 100 bytes in memory
-- 
-- -- poke one byte at a time:
-- poke(a, 97)
-- poke(a+1, 98)
-- poke(a+2, 99)
-- 
-- -- poke 3 bytes at once:
-- poke(a, {97, 98, 99})
-- </eucode>
-- 
-- Example 2: 
--  [[../demo/callmach.ex]]
-- 
-- See Also:
--    [[:peek]], [[:poke4]], [[:allocate]], [[:free]], [[:poke2]], [[:call]], [[:safe.e]]
-- 
--**
-- Signature:
-- global procedure poke2(atom addr, object x)
--
-- Description:
-- Stores one or more words, starting at a memory location.
--
-- Parameters:
--		# ##addr##, an atom, the address at which to store
--		# ##x##, an object, either a word or a non empty sequence of words.
--
-- Errors:
--	Poke()ing in memory you don't own may be blocked by the OS, and cause a
-- machine exception. The safe.e include file can catch this sort of issues.
--
-- Comments: 
-- There is no point in having poke2s() or poke2u(). For example, both 32768
-- and -32768 are stored as #F000 when stored as words. It' up to whoever
-- reads the value to figure it out.
--
-- It is faster to write several words at once by poking a sequence of
-- values, than it is to write one words at a time in a loop.
-- 
-- Writing to the screen memory with poke2() can be much faster than using
-- puts() or printf(), but the programming is more difficult. In most cases
-- the speed is not needed. For example, the Euphoria editor, ed, never uses
-- poke2().
--  
-- The 2-byte values to be stored can be negative or positive. You can read
-- them back with either ##peek2s##() or ##peek2u##(). Actually, only
-- remainder(##x##,65536) is being stored.
--
-- Example 1:
-- <eucode>
--  a = allocate(100)   -- allocate 100 bytes in memory
-- 
-- -- poke one 2-byte value at a time:
-- poke2(a, 12345)
-- poke2(a+2, #FF00)
-- poke2(a+4, -12345)
--
-- -- poke 3 2-byte values at once:
-- poke4(a, {12345, #FF00, -12345})
-- </eucode>
-- 
-- See Also:
--     [[:peek2s]], [[:peek2u]], [[:poke]], [[:poke4]], [[:allocate]], [[:call]]
--
--**
-- Signature:
-- global procedure poke4(atom addr, object x)
--
-- Description:
-- Stores one or more double words, starting at a memory location.
--
-- Parameters:
--		# ##addr##, an atom, the address at which to store
--		# ##x##, an object, either a double word or a non empty sequence of
-- double words.
--
-- Errors:
--	Poke()ing in memory you don't own may be blocked by the OS, and cause a
-- machine exception. The safe.e include file can catch this sort of issues.
--
-- Comments: 
-- There is no point in having poke4s() or poke4u(). For example, both
-- +power(2,31) and -power(2,31) are stored as #F0000000. It' up to whoever
-- reads the value to figure it out.
--
-- It is faster to write several double words at once by poking a sequence
-- of values, than it is to write one double words at a time in a loop.
-- 
-- Writing to the screen memory with poke4() can be much faster than using
-- puts() or printf(), but the programming is more difficult. In most cases
-- the speed is not needed. For example, the Euphoria editor, ed, never uses
-- poke4().
--  
-- The 4-byte values to be stored can be negative or positive. You can read
-- them back with either ##peek4s##() or ##peek4u##(). However, the results
-- are unpredictable if you want to store values with a fractional part or a
-- magnitude greater than power(2,32), even though Euphoria represents them
-- all as atoms.
--
-- Example 1:
-- <eucode>
--  a = allocate(100)   -- allocate 100 bytes in memory
-- 
-- -- poke one 4-byte value at a time:
-- poke4(a, 9712345)
-- poke4(a+4, #FF00FF00)
-- poke4(a+8, -12345)
-- 
-- -- poke 3 4-byte values at once:
-- poke4(a, {9712345, #FF00FF00, -12345})
-- </eucode>
-- 
-- See Also:
--     [[:peek4s]], [[:peek4u]], [[:poke]], [[:poke2]], [[:allocate]], [[:call]]
--
--**
-- Signature:
-- global procedure mem_copy(atom destination, atom origin, integer len)
--
-- Descripotion:
-- Copy a block of memory from an address to another.
--
-- Parameters:
--		# ##destination##, an atom, the address at which data is to be copied
--		# ##origin##, an atom, the address from which data is to be copied
--		# ##len##, an integer, how many bytes are to be copied.
--
-- Comments: 
-- The bytes of memory will be copied correctly even if the block of memory
-- at ##destination## overlaps with the block of memory at ##origin##.
--
-- mem_copy(destination, origin, len) is equivalent to: poke(destination,
-- peek({origin, len})) but is much faster.
--
-- Example 1:
-- <eucode>
--  dest = allocate(50)
-- src = allocate(100)
-- poke(src, {1,2,3,4,5,6,7,8,9})
-- mem_copy(dest, src, 9)
-- </eucode>
-- 
-- See Also:
--      [[:mem_set]], [[:peek]], [[:poke]], [[:allocate]]
-- 
--**
-- Signature:
-- global procedure mem_set(atom destination, integer byte_value, integer how_many))
--
-- Description:
-- Sets a contiguous range of memory ocations to a single value.
--
-- Parameters:
--		# ##destination##, an atom, the address starting the range to set.
--		# ##byte_value##, an integer, the value to copy at all addresses in the range.
--		# ##how_many##, an integer, how many bytes are to be set.
--
-- Comments: 
-- The low order 8 bits of ##byte_value## are actually stored in each byte.
-- mem_set(destination, byte_value, how_many) is equivalent to: 
-- poke(destination, repeat(byte_value, how_many)) but is much faster.
--
-- Example 1:
-- <eucode>
--  destination = allocate(1000)
-- mem_set(destination, ' ', 1000)
-- -- 1000 consecutive bytes in memory will be set to 32
-- -- (the ASCII code for ' ')
-- </eucode>
-- 
-- See Also:
--      [[:peek]], [[:poke]], [[:allocate]], [[:mem_copy]]
--
--**
-- Signature:
-- global procedure call(atom addr)
--
-- Description:
--  Call a machine language routine which was stored in memory prior.
--
-- Parameters:
--		# ##addr##, an atom, the address at which to transfer execution control.
--
-- Comments:
-- The machine code routine must execute a RET instruction #C3 to return
-- control to Euphoria. 
-- The routine should save and restore any registers that it uses.
--
-- You can allocate a block of memory for the routine and then poke in the
-- bytes of machine code. You might allocate other blocks of memory for data
-- and parameters that the machine code can operate on. The addresses of these
-- blocks could be poked into the machine code.
--
-- If your machine code uses the stack, use ##c_proc##() instead of ##call##().
--
-- Example 1: 
--		[[../demo/callmach.ex]]
--
-- See Also:
-- 		[[:allocate]], [[:free]], [[:peek]], [[:poke]], [[:c_proc]], [[:define_c_proc]]

--=== variables and routines used in safe.e
without warning
integer check_calls = 1

--**
-- Description: Add a block of memory to the list of safe blocks maintained
-- by safe.e (the debug version of machine.e). The block starts at address a.
-- The length of the block is i bytes.
--
-- Parameters:
--		# ##block_addr##, an atom, the start address of the block
--		# ##block_len##, an integer, the size of the block.
--
-- Comments: 
--
-- In memory.e, this procedure does nothing. It is there simply to simpify
-- switching between machine.e and safe.e.
--
-- This routine is only meant to be used for debugging purposes. safe.e
-- tracks the blocks of memory that your program is allowed to 
-- [[:peek]](), [[:poke]](), [[mem_copy]]() etc. These are normally just the
-- blocks that you have allocated using Euphoria's [[:allocate]]() or
-- [[:allocate_low]]() routines, and which you have not yet freed using
-- Euphoria's [[:free]]() or [[:free_low]](). In some cases, you may acquire
-- additional, external, blocks of memory, perhaps as a result of calling a
-- C routine. 
--
-- If you are debugging your program using safe.e, you must register these
-- external blocks of memory or safe.e will prevent you from accessing them.
-- When you are finished using an external block you can unregister it using
-- unregister_block().
--
-- Example 1:
--  atom addr
-- 
-- addr = c_func(x, {})
-- register_block(addr, 5)
-- poke(addr, "ABCDE")
-- unregister_block(addr)
-- 
-- See Also: 
--   [[:unregister_block]], [[:safe.e]]
global procedure register_block(atom block_addr, atom block_len)
end procedure

--**
-- Remove a block of memory from the list of safe blocks maintained by safe.e
-- (the debug version of machine.e).
--
-- Parameters:
--		# ##block_addr##, an atom, the start address of the block
--
-- Comments: 
--
-- In memory.e, this procedure does nothing. It is there simply to simpify
-- switching between machine.e and safe.e.
--
-- This routine is only meant to be used for debugging purposes. Use it to
-- unregister blocks of memory that you have previously registered using
-- [[:register_block]](). By unregistering a block, you remove it from the
-- list of safe blocks maintained by safe.e. This prevents your program from
-- performing any further reads or writes of memory within the block.
--
--  See [[:register_block]]() for further comments and an example.
-- 
-- See Also: register_block, safe.e  
--   [[:register_block]], [[:safe.e]]

global procedure unregister_block(atom block_addr)
end procedure

--**
-- Scans the list of registered blocks for any corruption.
--
-- Comments:
--
-- safe.e maintains a list of acquired memory blocks. Those gained through
-- allocate() or allocate_low() are automatically included. Any other block,
-- for debugging purposes, must be registered by [[:register_block]]()
-- and unregistered by [[:untrgister_block]]().
--
-- The list is scanned and, if any block shows signs of corruption, it is
-- displayed on the screen and the program terminates. Otherwise, nothing
-- happens.
--
-- In memory.e, this routine does nothing. It is there to make switching
-- between debugged and normal version of your program easier.
--
-- See Also:
-- [[:register_block]], [[:unregister_block]], [[:memory.e]]
global procedure check_all_blocks()
end procedure
with warning
