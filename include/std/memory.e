--****
-- == Memory Management - Low-Level
--
-- <<LEVELTOC level=2 depth=4>>
--
-- === Usage Notes
--@[safe.e]
-- This file is not normally included directly. The normal approach is to
-- ##include std/machine.e##, which will automatically include either this file
-- or ##std/safe.e## if the SAFE symbol has been defined.
--
-- Warning: Some of these routines require a knowledge of
-- machine-level programming. You could crash your system!
--
-- These routines, along with [[:peek]](), [[:poke]]() and [[:call]](), let you access all
-- of the features of your computer.  You can read and write to any memory
-- location, and you can create and execute machine code subroutines.
--
-- If you are manipulating 32-bit addresses or values, remember to use
-- variables declared as atom. The integer type only goes up to 31 bits.
--
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
--   * ##demo/callmach.ex##      ~-- calling a machine language routine
--
-- See also ##include/safe.e##. It's a safe, debugging version of this
-- file.
--

namespace memory

public include std/memconst.e

-- biggest address on a 32-bit machine
constant MAX_ADDR = power(2, 32)-1

ifdef DATA_EXECUTE then
	include std/machine.e
end ifdef

without warning &= (not_used)

public integer edges_only 

--**
-- Positive integer type

export type positive_int(object x)
	if not integer(x) then
		return 0
	end if
    return x >= 1
end type

--**
-- Machine address type

public type machine_addr(object a)
-- a 32-bit non-null machine address 
	if not atom(a) then
		return 0
	end if
	
	if not integer(a)then
		if floor(a) != a then
			return 0
		end if
	end if
	
	return a > 0 and a <= MAX_ADDR
end type

-- Internal use of the library only.  free() calls this.  It works with
-- only atoms and in the SAFE implementation is different.
export procedure deallocate(atom addr)
	ifdef DATA_EXECUTE and WINDOWS then
		if dep_works() then
			c_func( VirtualFree_rid, { addr, 1, MEM_RELEASE } )
			return
		end if
	end ifdef
   	machine_proc( memconst:M_FREE, addr)
end procedure
memconst:FREE_RID = routine_id("deallocate")


--****
-- === Reading from, Writing to, and Calling into Memory

--****
-- Signature:
-- <built-in> function peek(object addr_n_length)
--
-- Description:
-- Fetches a byte, or some bytes, from an address in memory.
--
-- Parameters:
--              # ##addr_n_length## : an object, either of
--              ** an atom ##addr## ~-- to fetch one byte at ##addr##, or
--              ** a pair {##addr,len}## ~-- to fetch ##len## bytes at ##addr##
--
-- Returns:
--              An **object**, either an integer if the input was a single address,
-- or a sequence of integers if a sequence was passed. In both cases,
-- integers returned are bytes, in the range 0..255.
--
-- Errors:
--
-- [[:peek | Peeking]] in memory you don't own may be blocked by the OS, and cause a
-- machine exception. If you use the define safe these routines will catch these problems with a EUPHORIA error.
--
-- When supplying a {address, count} sequence, the count must not be negative.
--
-- Comments:
--
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
--  [[:poke]], [[:peeks]], [[:peek4u]], [[:allocate]], [[:free]],
--  [[:peek2u]]
--

--****
-- Signature:
-- <built-in> function peeks(object addr_n_length)
--
-- Description:
-- Fetches a byte, or some bytes, from an address in memory.
--
-- Parameters:
--              # ##addr_n_length## : an object, either of
--              ** an atom ##addr## : to fetch one byte at ##addr##, or
--              ** a pair {##addr,len}## : to fetch ##len## bytes at ##addr##
--
-- Returns:
--
--              An **object**, either an integer if the input was a single address,
-- or a sequence of integers if a sequence was passed. In both cases,
-- integers returned are bytes, in the range -128..127.
--
-- Errors:
--
-- [[:peek | Peeking]] in memory you don't own may be blocked by the OS, and cause
-- a machine exception. If you use the define safe these routines will catch these problems with a EUPHORIA error.
--
-- When supplying a {address, count} sequence, the count must not be negative.
--
-- Comments: 
--
-- Since addresses are 32-bit numbers, they can be larger than the largest
-- value of type integer (31-bits). Variables that hold an address should
-- therefore be declared as atoms.
--
-- It is faster to read several bytes at once using the second form of ##peek##()
-- than it is to read one byte at a time in a loop. The returned sequence has
-- the length you asked for on input.
-- 
-- Remember that ##peeks##() takes just one argument, which in the second
-- form is actually a 2-element sequence.
--  
-- Example 1:
--
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
--
--  [[:poke]], [[:peek4s]], [[:allocate]], [[:free]], 
--  [[:peek2s]], [[:peek]]
--

--****
-- Signature:
-- <built-in> function peek2s(object addr_n_length)
--
-- Description:
-- Fetches a //signed// word, or some //signed// words  , from an address
-- in memory.
--
-- Parameters:
--   # ##addr_n_length## : an object, either of
--   ** an atom ##addr## ~-- to fetch one word at ##addr##, or
--   ** a pair ##{ addr, len}##, to fetch ##len## words at ##addr##
--
-- Returns:
-- An **object**, either an integer if the input was a single address,
-- or a sequence of integers if a sequence was passed. In both cases,
-- integers returned are double words, in the range -32768..32767.
--
-- Errors:
-- Peeking in memory you don't own may be blocked by the OS, and cause
-- a machine exception. If you use the define safe these routines will catch these problems with a EUPHORIA error.
--
-- When supplying a {address, count} sequence, the count must not be negative.
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
--
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
--
--  [[:poke2]], [[:peeks]], [[:peek4s]], [[:allocate]], [[:free]]
--  [[:peek2u]]
--

--****
-- Signature:
-- <built-in> function peek2u(object addr_n_length)
--
-- Description:
-- Fetches an //unsigned// word, or some //unsigned// words, from an address
-- in memory.
--
-- Parameters:
--              # ##addr_n_length## : an object, either of
--              ** an atom ##addr## ~-- to fetch one double word at ##addr##, or
--              ** a pair {##addr,len}## ~-- to fetch ##len## double words at ##addr##
--
-- Returns:
--              An **object**, either an integer if the input was a single address,
-- or a sequence of integers if a sequence was passed. In both cases,
-- integers returned are words, in the range 0..65535.
--
-- Errors:
--      Peek() in memory you don't own may be blocked by the OS, and cause a
-- machine exception. If you use the define safe these routines will catch these problems with a EUPHORIA error.
--
-- When supplying a {address, count} sequence, the count must not be negative.
--
-- Comments: 
--
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
-- Get 4 2-byte numbers starting address 100.
-- s = {peek2u(100), peek2u(102), peek2u(104), peek2u(106)}
--
-- -- method 2
-- Get 4 2-byte numbers starting address 100.
-- s = peek2u({100, 4})
-- </eucode>
-- 
-- See Also: 
--  [[:poke2]], [[:peek]], [[:peek2s]], [[:allocate]], [[:free]]
--  [[:peek4u]]
--

--****
-- Signature:
-- <built-in> function peek4s(object addr_n_length)
--
-- Description:
-- Fetches a //signed// double words, or some //signed// double words,
-- from an address in memory.
--
-- Parameters:
--   # ##addr_n_length## : an object, either of
--   ** an atom ##addr## ~-- to fetch one double word at ##addr##, or
--   ** a pair ##{ addr, len }## ~-- to fetch ##len## double words at ##addr##
--
-- Returns:
-- An **object**, either an atom if the input was a single address, or a
-- sequence of atoms if a sequence was passed. In both cases, atoms returned
-- are double words, in the range -power(2,31)..power(2,31)-1.
--
-- Errors:
-- Peeking in memory you don't own may be blocked by the OS, and cause a
-- machine exception. If you use the define safe these routines will catch these problems with a EUPHORIA error.
--
-- When supplying a {address, count} sequence, the count must not be negative.
--
-- Comments: 
--
-- Since addresses are 32-bit numbers, they can be larger than the largest
-- value of type integer (31-bits). Variables that hold an address should
-- therefore be declared as atoms.
--
-- It is faster to read several double words at once using the second form
-- of ##peek##() than it is to read one double word at a time in a loop. The
-- returned sequence has the length you asked for on input.
-- 
-- Remember that ##peek4s##() takes just one argument, which in the second
-- form is actually a 2-element sequence.
--
-- The only difference between ##peek4s##() and [[:peek4u]]() is how double
-- words with the highest bit set are returned. ##peek4s##() assumes them to
-- be negative, while [[:peek4u]]() just assumes them to be large and positive.
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
-- [[:poke4]], [[:peeks]], [[:peek4u]], [[:allocate]], [[:free]],
-- [[:peek2s]]
--

--****
-- Signature:
-- <built-in> function peek4u(object addr_n_length)
--
-- Description:
-- Fetches an //unsigned// double word, or some //unsigned// double words,
-- from an address in memory.
--
-- Parameters:
--              # ##addr_n_length## : an object, either of
--              ** an atom ##addr## ~-- to fetch one double word at ##addr##, or
--              ** a pair {##addr,len}## ~-- to fetch ##len## double words at ##addr##
--
-- Returns:
--              An **object**, either an atom if the input was a single address, or
-- a sequence of atoms if a sequence was passed. In both cases, atoms
-- returned are double words, in the range 0..power(2,32)-1. 
--
-- Errors:
--      Peek() in memory you don't own may be blocked by the OS, and cause
-- a machine exception. If you use the define safe these routines will catch these problems with a EUPHORIA error.
--
-- When supplying a {address, count} sequence, the count must not be negative.
--
-- Comments: 
--
-- Since addresses are 32-bit numbers, they can be larger than the largest
-- value of type integer (31-bits). Variables that hold an address should
-- therefore be declared as atoms.
--
-- It is faster to read several double words at once using the second form 
-- of ##peek##() than it is to read one double word at a time in a loop. The
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
--  [[:poke4]], [[:peek]], [[:peek4s]], [[:allocate]], [[:free]], [[:peek2u]]
--

--****
-- Signature:
-- <built-in> procedure peek_string(atom addr)
--
-- Description:
-- Read an ASCII string in RAM, starting from a supplied address.
--
-- Parameters:
--              # ##addr## : an atom, the address at which to start reading.
--
-- Returns:
-- A **sequence**, of bytes, the string that could be read.
--
-- Errors:
-- Further, ##peek##() memory that doesn't belong to your process is something the operating
-- system could prevent, and you'd crash with a machine level exception.
--
-- Comments:
--
-- An ASCII string is any sequence of bytes and ends with a 0 byte.
-- If you ##peek_string##() at some place where there is no string, you will get a sequence of garbage.
--
-- See Also:
-- [[:peek]], [[:peek_wstring]], [[:allocate_string]]


--****
-- Signature:
-- <built-in> procedure poke(atom addr, object x)
--
-- Description:
-- Stores one or more bytes, starting at a memory location.
--
-- Parameters:
--              # ##addr## : an atom, the address at which to store
--              # ##x## : an object, either a byte or a non empty sequence of bytes.
--
-- Errors:
--      Poke() in memory you don't own may be blocked by the OS, and cause a
-- machine exception. The -D SAFE option will make ##poke()## catch this sort of issues.
--
-- Comments:
--
-- The lower 8-bits of each byte value, i.e. remainder(x, 256), is actually
-- stored in memory.
--
-- It is faster to write several bytes at once by poking a sequence of values,
-- than it is to write one byte at a time in a loop. 
-- 
-- Writing to the screen memory with ##poke##() can be much faster than using
-- ##puts##() or ##printf##(), but the programming is more difficult. In most cases
-- the speed is not needed. For example, the Euphoria editor, ##ed##, never uses
-- ##poke##().
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
--  ##demo/callmach.ex##
-- 
-- See Also:
-- [[:peek]], [[:peeks]], [[:poke4]], [[:allocate]], [[:free]], [[:poke2]], [[:call]],
-- [[:mem_copy]], [[:mem_set]]
--

--****
-- Signature:
-- <built-in> procedure poke2(atom addr, object x)
--
-- Description:
-- Stores one or more words, starting at a memory location.
--
-- Parameters:
--              # ##addr## : an atom, the address at which to store
--              # ##x## : an object, either a word or a non empty sequence of words.
--
-- Errors:
--      Poke() in memory you don't own may be blocked by the OS, and cause a
-- machine exception. If you use the define safe these routines will catch these problems with a EUPHORIA error.
--
-- Comments: 
--
-- There is no point in having ##poke2s##() or ##poke2u##(). For example, both 32768
-- and -32768 are stored as #F000 when stored as words. It's up to whoever
-- reads the value to figure it out.
--
-- It is faster to write several words at once by poking a sequence of
-- values, than it is to write one words at a time in a loop.
-- 
-- Writing to the screen memory with ##poke2##() can be much faster than using
-- ##puts##() or ##printf##(), but the programming is more difficult. In most cases
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
--     [[:peek2s]], [[:peek2u]], [[:poke]], [[:poke4]], [[:allocate]], [[:free]], [[:call]]
--

--****
-- Signature:
-- <built-in> procedure poke4(atom addr, object x)
--
-- Description:
-- Stores one or more double words, starting at a memory location.
--
-- Parameters:
--              # ##addr## : an atom, the address at which to store
--              # ##x## : an object, either a double word or a non empty sequence of
-- double words.
--
-- Errors:
--      Poke() in memory you don't own may be blocked by the OS, and cause a
-- machine exception. If you use the define safe these routines will catch these problems with a EUPHORIA error.
--
-- Comments: 
--
-- There is no point in having poke4s() or poke4u(). For example, both
-- +power(2,31) and -power(2,31) are stored as #F0000000. It's up to whoever
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
--     [[:peek4s]], [[:peek4u]], [[:poke]], [[:poke2]], [[:allocate]], [[:free]], [[:call]]
--

--****
-- Signature:
-- <built-in> procedure mem_copy(atom destination, atom origin, integer len)
--
-- Description:
-- Copy a block of memory from an address to another.
--
-- Parameters:
--              # ##destination## : an atom, the address at which data is to be copied
--              # ##origin## : an atom, the address from which data is to be copied
--              # ##len## : an integer, how many bytes are to be copied.
--
-- Comments: 
--
-- The bytes of memory will be copied correctly even if the block of memory
-- at ##destination## overlaps with the block of memory at ##origin##.
--
-- mem_copy(destination, origin, len) is equivalent to: poke(destination,
-- peek({origin, len})) but is much faster.
--
-- Example 1:
-- <eucode>
-- dest = allocate(50)
-- src = allocate(100)
-- poke(src, {1,2,3,4,5,6,7,8,9})
-- mem_copy(dest, src, 9)
-- </eucode>
-- 
-- See Also:
-- [[:mem_set]], [[:peek]], [[:poke]], [[:allocate]], [[:free]]
-- 

--****
-- Signature:
-- <built-in> procedure mem_set(atom destination, integer byte_value, integer how_many))
--
-- Description:
-- Sets a contiguous range of memory locations to a single value.
--
-- Parameters:
--              # ##destination## : an atom, the address starting the range to set.
--              # ##byte_value## : an integer, the value to copy at all addresses in the range.
--              # ##how_many## : an integer, how many bytes are to be set.
--
-- Comments:
--
-- The low order 8 bits of ##byte_value## are actually stored in each byte.
-- mem_set(destination, byte_value, how_many) is equivalent to: 
-- poke(destination, repeat(byte_value, how_many)) but is much faster.
--
-- Example 1:
-- <eucode>
-- destination = allocate(1000)
-- mem_set(destination, ' ', 1000)
-- -- 1000 consecutive bytes in memory will be set to 32
-- -- (the ASCII code for ' ')
-- </eucode>
--
-- See Also:
--   [[:peek]], [[:poke]], [[:allocate]], [[:free]], [[:mem_copy]]
--

--****
-- Signature:
-- <built-in> procedure call(atom addr)
--
-- Description:
--  Call a machine language routine which was stored in memory prior.
--
-- Parameters:
--              # ##addr## : an atom, the address at which to transfer execution control.
--
-- Comments:
--
-- The machine code routine must execute a RET instruction #C3 to return
-- control to Euphoria. 
-- The routine should save and restore any registers that it uses.
--
-- You can allocate a block of memory for the routine and then poke in the
-- bytes of machine code using ##allocate_code##(). You might allocate other blocks of memory for data
-- and parameters that the machine code can operate on using ##allocate##(). The addresses of these
-- blocks could be part of the machine code.
--
-- If your machine code uses the stack, use ##c_proc##() instead of ##call##().
--
-- Example 1: 
--              ##demo/callmach.ex##
--
-- See Also:
--              [[:allocate_code]], [[:free_code]], [[:c_proc]], [[:define_c_proc]]

without warning
public integer check_calls = 1

--****
-- === Safe memory access

without warning strict
--**
-- Description: Add a block of memory to the list of safe blocks maintained
-- by safe.e (the debug version of memory.e). The block starts at address a.
-- The length of the block is i bytes.
--
-- Parameters:
--              # ##block_addr## : an atom, the start address of the block
--              # ##block_len## : an integer, the size of the block.
--              # ##protection## : a constant integer, of the memory 
--                  protection constants found in machine.e, that describes
--                  what access we have to the memory. 
--
-- Comments: 
--
-- In memory.e, this procedure does nothing. It is there to simplify
-- switching between the normal and debug version of the library.
--
-- This routine is only meant to be used for debugging purposes. safe.e
-- tracks the blocks of memory that your program is allowed to 
-- [[:peek]](), [[:poke]](), [[:mem_copy]]() etc. These are normally just the
-- blocks that you have allocated using Euphoria's [[:allocate]]() 
-- routine, and which you have not yet freed using
-- Euphoria's [[:free]](). In some cases, you may acquire
-- additional, external, blocks of memory, perhaps as a result of calling a
-- C routine. 
--
-- If you are debugging your program using safe.e, you must register these
-- external blocks of memory or safe.e will prevent you from accessing them.
-- When you are finished using an external block you can unregister it using
-- unregister_block().
--
-- Example 1:
-- <eucode>
--  atom addr
-- 
-- addr = c_func(x, {})
-- register_block(addr, 5)
-- poke(addr, "ABCDE")
-- unregister_block(addr)
-- </eucode>
-- 
-- See Also: 
--   [[:unregister_block]], [[:safe.e]]

public procedure register_block(atom block_addr, atom block_len, integer protection )
	-- Only implemented in safe.e
end procedure

without warning strict
--**
-- Remove a block of memory from the list of safe blocks maintained by safe.e
-- (the debug version of memory.e).
--
-- Parameters:
--              # ##block_addr## : an atom, the start address of the block
--
-- Comments: 
--
-- In memory.e, this procedure does nothing. It is there to simplify
-- switching between the normal and debug version of the library.
--
-- This routine is only meant to be used for debugging purposes. Use it to
-- unregister blocks of memory that you have previously registered using
-- [[:register_block]](). By unregistering a block, you remove it from the
-- list of safe blocks maintained by safe.e. This prevents your program from
-- performing any further reads or writes of memory within the block.
--
--  See [[:register_block]]() for further comments and an example.
-- 
-- See Also:
--   [[:register_block]], [[:safe.e]]

public procedure unregister_block(atom block_addr)
	-- Only implemented in safe.e
end procedure

without warning strict
--**
-- Scans the list of registered blocks for any corruption.
--
-- Comments:
--
-- safe.e maintains a list of acquired memory blocks. Those gained through
-- allocate() are automatically included. Any other block,
-- for debugging purposes, must be registered by [[:register_block]]()
-- and unregistered by [[:unregister_block]]().
--
-- The list is scanned and, if any block shows signs of corruption, it is
-- displayed on the screen and the program terminates. Otherwise, nothing
-- happens.
--
-- In memory.e, this routine does nothing. It is there to make switching
-- between debugged and normal version of your program easier.
--
-- See Also:
-- [[:register_block]], [[:unregister_block]]

public function safe_address(atom start, integer len, positive_int action)
	-- Only implemented in safe.e
	return 1
end function

without warning strict
public procedure check_all_blocks()
	-- Only implemented in safe.e
end procedure

without warning strict
export function prepare_block( atom addr, integer a, integer protection )
	-- Only implemented in safe.e
	return addr
end function

export constant BORDER_SPACE = 0
export constant leader = repeat('@', BORDER_SPACE)
export constant trailer = repeat('%', BORDER_SPACE)

export type bordered_address( object addr )
	if not atom(addr) then
		return 0
	end if
	return 1
end type


with warning

--****
--=== Automatic Resource Management
--
-- Euphoria objects are automatically garbage collected when they are no
-- longer referenced anywhere.  Euphoria also provides the ability to manage 
-- resources associated with euphoria objects.  These resources could be open file 
-- handles, allocated memory, or other euphoria objects.  There are two built-in
-- routines for managing these external resources.

--****
-- Signature:
-- <built-in> function delete_routine( object x, integer rid )
-- 
-- Description:
-- Associates a routine for cleaning up after a euphoria object.
-- 
-- Comments:
-- delete_routine() associates a euphoria object with a routine id meant
-- to clean up any allocated resources.  It always returns an atom
-- (double) or a sequence, depending on what was passed (integers are
-- promoted to atoms).
-- 
-- The routine specified by delete_routine() should be a procedure that
-- takes a single parameter, being the object to be cleaned up after.
-- Objects are cleaned up under one of two circumstances.  The first is
-- if it's called as a parameter to delete().  After the call, the
-- association with the delete routine is removed.
-- 
-- The second way for the delete routine to be called is when its
-- reference count is reduced to 0.  Before its memory is freed, the
-- delete routine is called. A default delete will be used if the cleanup 
-- parameter to one of the [[:allocate]] routines is true. 
-- 
-- delete_routine() may be called multiple times for the same object.
-- In this case, the routines are called in reverse order compared to
-- how they were associated.

--****
-- Signature:
-- <built-in> procedure delete( object x )
-- 
-- Description:
-- Calls the cleanup routines associated with the object, and removes the
-- association with those routines.
-- 
-- Comments:
-- The cleanup routines associated with the object are called in reverse
-- order than they were added.  If the object is an integer, or if no
-- cleanup routines are associated with the object, then nothing happens.
-- 
-- After the cleanup routines are called, the value of the object is 
-- unchanged, though the cleanup routine will no longer be associated
-- with the object.

--**
-- Returns 1 if the DEP executing data only memory would cause an exception
export function dep_works()
	ifdef WINDOWS then
		return (DEP_really_works and use_DEP)
	end ifdef

	return 1
end function

export atom VirtualFree_rid

public procedure free_code( atom addr, integer size, valid_wordsize wordsize = 1 )
	ifdef WINDOWS then
		if dep_works() then
			c_func(VirtualFree_rid, { addr, size*wordsize, MEM_RELEASE })
		else
			machine_proc( memconst:M_FREE, addr)
		end if
	elsedef
		machine_proc( memconst:M_FREE, addr)
	end ifdef
end procedure
