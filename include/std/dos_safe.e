--****
--== //DOS low level routines

-- **Page Contents**
--
-- <<LEVELTOC depth=2>>
--




include dos_base.e

include safe.e
safe_address_list = {
--      {start , length , allocation_number}
		{#A0000, 200*320, 0},   -- mode 19 pixel memory, start & length
	  --{#B0000, 4000   , 0},   -- monochrome text memory, first page
		{#B8000, 8000   , 0},   -- color text memory, first page, 50-line mode
		{1024  , 100    , 0}    -- keyboard buffer area (roughly)
		-- add more here
}

--**
-- Allocate a contiguous block of conventional memory (address below 1 megabyte).
--
-- Platform:
--		//DOS32//
--
-- Parameters:
--		# ##n##: an integer, the size of the requested block of conventional memory.
-- Returns:
--		An **atom**, the address of the block of memory, or 0 if the memory can't
-- be allocated.
--
-- Comments:
--   Some //DOS// software interrupts require that you pass one or more addresses in registers. 
--   These addresses must be conventional memory addresses for DOS to be able to read or write 
--   to them.
--
-- This routine overrides ##machine:allocate_low##() with a debug version.
--
-- Example 1:
--   [[../demo/dos32/dosint]]
--
-- See Also:
--   [[:dos_interrupt]], [[:free_low]], [[:allocate]], [[:peek]], [[:poke]]

export function allocate_low(positive_int n)
-- allocate memory block and add it to safe list
	atom a
	
	a = machine_func(M_ALLOC_LOW, n+BORDER_SPACE*2)
	return prepare_block(a, n)
end function

--**
-- Free up a previously allocated block of conventional memory.
--
-- Platform:
--		//DOS32//
--
-- Parameters:
--		# ##addr##: an atom the address
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
-- This routine overrides ##machine.free_low##() with a debug version.
--
-- Example 1:
--   [[../demo/dos32/dosint.ex]]
--
-- See Also:
--   [[:allocate_low]], [[:dos_interrupt]], [[:free]]
export procedure free_low(low_machine_addr a)
-- free low address a - make sure it was allocated
	integer n
	
	if a > 1024*1024 then
		die("TRYING TO FREE A HIGH ADDRESS USING free_low!")
	end if
	for i = 1 to length(safe_address_list) do
		if safe_address_list[i][1] = a then
			-- check pre and post block areas
			if safe_address_list[i][3] <= 0 then
				die("ATTEMPT TO FREE A BLOCK THAT WAS NOT ALLOCATED!")
			end if
			n = safe_address_list[i][2]
			if not equal(leader, original_peek({a-BORDER_SPACE, BORDER_SPACE})) then
				show_block(safe_address_list[i])
			elsif not equal(trailer, original_peek({a+n, BORDER_SPACE})) then
				show_block(safe_address_list[i])
			end if          
			machine_proc(M_FREE_LOW, a-BORDER_SPACE)
			-- remove it from list
			safe_address_list = 
						safe_address_list[1..i-1] &
						safe_address_list[i+1..$]
			return
		end if
	end for
	die("ATTEMPT TO FREE USING AN ILLEGAL ADDRESS!")
end procedure

--**
-- Call a //DOS// interrupt.
--
-- Platform:
--		//DOS32//
--
-- Parameters:
--		# ##int_num##: a, integer between 0 and 255, the interrupt number.
--		# ##input_regs##: a sequence indicating how should the machine registers be on calling the interrupt.
--
-- Returns:
--		A **sequence** holding the contents of registers on return from the interrupt.
--
-- Comments:
--		You should carefully read the documentation of the API you want to call before making a ##dos_interrupt##() call. Machine level exceptions are frequent while debugging.
--
-- machine.e has the following declaration which shows the order of the register values in the input and output sequences.
-- <eucode>
--      export constant REG_DI = 1,
--                     REG_SI = 2,
--                     REG_BP = 3,
--                     REG_BX = 4,
--                     REG_DX = 5,
--                     REG_CX = 6,
--                     REG_AX = 7,
--                     REG_FLAGS = 8, -- input: ignored
                                      -- output: 1 if carry flag set (which usully means a failure), else 0
--                     REG_ES = 9,
--                     REG_DS = 10
-- </eucode>
--  
-- Certain interrupts require that you supply addresses of blocks of memory. These addresses must be conventional, low-memory addresses. You can allocate/deallocate low-memory using allocate_low() and free_low().
-- 
-- With DOS software interrupts you can perform a wide variety of specialized operations, anything from formatting your floppy drive to rebooting your computer. For documentation on these interrupts consult a technical manual such as Peter Norton's "PC Programmer's Bible", or download Ralf Brown's Interrupt List from the Web: 
--
-- [[http://www.cs.cmu.edu/afs/cs.cmu.edu/user/ralf/pub/WWW/files.html]]
--
-- This routine overrides ##machine:dos_interrupt##() with a debug version.
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
	if check_calls then
		check_all_blocks()
	end if
	return r
end function

