-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
-- Euphoria 3.1
-- Machine Level Programming (386/486/Pentium)

-- This is a slower DEBUGGING VERSION of machine.e

-- How To Use This File:

-- 1. Temporarily replace machine.e with safe.e
--    (Remember to set things back to normal 
--     when you are finished debugging.)

-- 2. If your program doesn't already include machine.e add:  
--           include machine.e  
--    to your main .ex[w][u] file at the top.

-- 3. If necessary, call register_block(address, length) to add additional
--    "external" blocks of memory to the safe_address_list. These are blocks 
--    of memory that are safe to read/write but which you did not acquire 
--    through Euphoria's allocate() or allocate_low(). Call 
--    unregister_block(address) when you want to prevent further access to 
--    an external block.

-- 4. Run your program. It might be 10x slower than normal but it's
--    worth it to catch a nasty bug.

-- 5. If a bug is caught, you will hear some "beep" sounds.
--    Press Enter to clear the screen and see the error message. 
--    There will be a "divide by zero" traceback in ex.err 
--    so you can find the statement that is making the illegal memory access.

-- This file is equivalent to machine.e, but it overrides the built-in 
-- routines: 
--     poke, peek, poke4, peek4s, peek4u, call, mem_copy, and mem_set
-- and it provides alternate versions of:
--     allocate, allocate_low, free, free_low

-- Some parameters you may wish to change:

global integer check_calls, edges_only
check_calls = 1   -- if 1, check all blocks for edge corruption after each 
				  -- call(), dos_interrupt(), c_proc(), or c_func(). 
				  -- To save time, your program can turn off this checking by 
				  -- setting check_calls to 0. 

edges_only = (platform()=2) -- on WIN32 people often use unregistered blocks   
				  -- if 1, only check for references to the leader or trailer
				  -- areas just outside each registered block.
				  -- don't complain about addresses that are far out of bounds
				  -- (it's probably a legitimate block from another source)
				  -- For a stronger check, set this to 0 if your program 
				  -- will never read/write an unregistered block of memory.
				  

-- from misc.e and graphics.e:
constant M_SOUND = 1

-- Your program will only be allowed to read/write areas of memory
-- that it allocated (and hasn't freed), as well as areas in low memory 
-- that you list below, or add dynamically via register_block().

sequence safe_address_list
-- Include the starting address and length of any 
-- acceptable areas of memory for peek/poke here. 
-- Set allocation number to 0.
if platform() = 1 then -- DOS32
	safe_address_list = {
--      {start , length , allocation_number}        
		{#A0000, 200*320, 0},   -- mode 19 pixel memory, start & length 
	  --{#B0000, 4000   , 0},   -- monochrome text memory, first page
		{#B8000, 8000   , 0},   -- color text memory, first page, 50-line mode 
		{1024  , 100    , 0}    -- keyboard buffer area (roughly)
		-- add more here
}
else
	safe_address_list = {}
end if

with type_check

puts(1, "\n\t\tUsing Debug Version of machine.e\n")
atom t
t = time()
while time() < t + 3 do
end while

constant OK = 1, BAD = 0
constant M_ALLOC = 16,
		 M_FREE = 17,
		 M_ALLOC_LOW = 32,
		 M_FREE_LOW = 33,
		 M_INTERRUPT = 34,
		 M_SET_RAND = 35,
		 M_USE_VESA = 36,
		 M_CRASH_MESSAGE = 37,
		 M_TICK_RATE = 38,
		 M_GET_VECTOR = 39,
		 M_SET_VECTOR = 40,
		 M_LOCK_MEMORY = 41,
		 M_A_TO_F64 = 46,
		 M_F64_TO_A = 47,
		 M_A_TO_F32 = 48,
		 M_F32_TO_A = 49,
		 M_CRASH_FILE = 57,
		 M_CRASH_ROUTINE = 66,
		 M_WARNING_FILE = 72

-- biggest address on a 32-bit machine
constant MAX_ADDR = power(2, 32)-1

-- biggest address accessible to 16-bit real mode
constant LOW_ADDR = power(2, 20)-1

type positive_int(integer x)
	return x >= 1
end type

type natural(integer x)
	return x >= 0
end type

type machine_addr(atom a)
-- a 32-bit non-null machine address 
	return a > 0 and a <= MAX_ADDR and floor(a) = a
end type

type far_addr(sequence a)
-- protected mode far address {seg, offset}
	return length(a) = 2 and integer(a[1]) and machine_addr(a[2])
end type

type low_machine_addr(atom a)
-- a legal low machine address 
	return a > 0 and a <= LOW_ADDR and floor(a) = a
end type

constant BORDER_SPACE = 40
constant leader = repeat('@', BORDER_SPACE)
constant trailer = repeat('%', BORDER_SPACE)

function safe_address(atom start, integer len)
-- is it ok to read/write all addresses from start to start+len-1?
	atom block_start, block_upper, upper
	sequence block
	
	if len = 0 then
		return OK
	end if
	
	upper = start + len
	-- search the list of safe memory blocks:
	for i = 1 to length(safe_address_list) do
		block = safe_address_list[i]
		block_start = block[1]
		if edges_only then
			-- addresses are considered safe as long as 
			-- they aren't in any block's border zone
			if start <= 3 then
				return BAD -- null pointer (or very small address)
			end if
			if block[3] >= 1 then
				-- an allocated block with a border area
				block_upper = block_start + block[2]
				if (start >= block_start - BORDER_SPACE and 
					start < block_start) or 
				   (start >= block_upper and 
					start < block_upper + BORDER_SPACE) then
					return BAD
				
				elsif (upper > block_start - BORDER_SPACE and
					   upper <= block_start) or
					  (upper > block_upper and
					  upper < block_upper + BORDER_SPACE) then
					return BAD
				
				elsif start < block_start - BORDER_SPACE and
					upper > block_upper + BORDER_SPACE then
					return BAD
				end if
			end if
		else
			-- addresses are considered safe as long as 
			-- they are inside an allocated or registered block
			if start >= block_start then 
				block_upper = block_start + block[2]
				if upper <= block_upper then
					if i > 1 then
						-- move block i to the top and move 1..i-1 down
						if i = 2 then
							-- common case, subscript is faster than slice:
							safe_address_list[2] = safe_address_list[1]
						else
							safe_address_list[2..i] = safe_address_list[1..i-1]
						end if
						safe_address_list[1] = block
					end if
					return OK
				end if
			end if
		end if
	end for
	if edges_only then
		return OK  -- not found in any border zone
	else
		return BAD -- not found in any safe block
	end if
end function

procedure die(sequence msg)
-- Terminate with a message.
-- makes warning beeps first so you can see what's happening on the screen
	atom t
	
	for i = 1 to 7 do
		machine_proc(M_SOUND, 1000)
		t = time()
		while time() < t + .1 do
		end while
		machine_proc(M_SOUND, 0)
		t = time()
		while time() < t + .1 do
		end while
	end for
	puts(1, "\n *** Press Enter *** ")
	if getc(0) then
	end if
	if machine_func(5, -1) then -- graphics_mode
	end if
	puts(1, "\n\n" & msg & "\n\n")
	if getc(0) then
	end if
	? 1/0 -- force traceback
end procedure

function bad_address(atom a)
-- show address in decimal and hex  
	return sprintf(" ADDRESS!!!! %d (#%08x)", {a, a})
end function

function original_peek(object x)
	return peek(x) -- Euphoria's normal peek
end function

without warning
--**
-- Signature:
-- peek(object addr_n_length)
--
-- Description:
-- Fetches a byte, or some bytes, from an address in memory.
--
-- Parameters:
--		# ##addr_n_length##: an object, either of
--		#* an atom ##addr##, to fetch one byte at ##addr##, or
--		#* a pair {##addr,len}##, to fetch ##len## bytes at ##addr##
--
-- Returns:
--		An **object**, either an integer if the input was a single address, or a sequence of integers if a sequence was passed. In both cases, integers returned are bytes, in the range 0..255.
--
-- Errors:
--	Peek()ing in memory you don't own may be blocked by the OS, and cause a machine exception. The safe.e include file can catch this sort of issues.
--
-- Comments: 
-- Since addresses are 32-bit numbers, they can be larger than the largest value of type integer (31-bits). Variables that hold an address should therefore be declared as atoms.
--
-- It is faster to read several bytes at once using the second form of peek() than it is to read one byte at a time in a loop. The returned sequence has the length you asked for on input.
-- 
-- Remember that ##peek##() takes just one argument, which in the second form is actually a 2-element sequence.
--  
-- This routine overrides ##eu:peek##() with a debug version.
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

override function peek(object x)
-- safe version of peek 
	integer len
	atom a
	
	if atom(x) then
		len = 1
		a = x
	else
		len = x[2]
		a = x[1]
	end if
	if safe_address(a, len) then
		return original_peek(x)
	else
		die("BAD PEEK" & bad_address(a))
	end if
end function

function original_peeks(object x)
	return peeks(x) -- Euphoria's normal peek
end function

--**
-- Signature:
-- peeks(object addr_n_length)
--
-- Description:
-- Fetches a byte, or some bytes, from an address in memory.
--
-- Parameters:
--		# ##addr_n_length##: an object, either of
--		#* an atom ##addr##, to fetch one byte at ##addr##, or
--		#* a pair {##addr,len}##, to fetch ##len## bytes at ##addr##
--
-- Returns:
--		An **object**, either an integer if the input was a single address, or a sequence of integers if a sequence was passed. In both cases, integers returned are bytes, in the range -128..127.
--
-- Errors:
--	Peek()ing in memory you don't own may be blocked by the OS, and cause a machine exception. The safe.e include file can catch this sort of issues.
--
-- Comments: 
-- Since addresses are 32-bit numbers, they can be larger than the largest value of type integer (31-bits). Variables that hold an address should therefore be declared as atoms.
--
-- It is faster to read several bytes at once using the second form of peek() than it is to read one byte at a time in a loop. The returned sequence has the length you asked for on input.
-- 
-- Remember that ##peeks##() takes just one argument, which in the second form is actually a 2-element sequence.
-- 
-- This routine overrides ##eu:peeks##() with a debug version.
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
override function peeks(object x)
-- safe version of peeks
	integer len
	atom a
	
	if atom(x) then
		len = 1
		a = x
	else
		len = x[2]
		a = x[1]
	end if
	if safe_address(a, len) then
		return original_peeks(x)
	else
		die("BAD PEEK" & bad_address(a))
	end if
end function

function original_peek2u(object x)
	return peek2u(x) -- Euphoria's normal peek2u
end function

without warning

--**
-- Signature:
-- peek2u(object addr_n_length)
--
-- Description:
-- Fetches an //unsigned// word, or some //unsigned// words, from an address in memory.
--
-- Parameters:
--		# ##addr_n_length##: an object, either of
--		#* an atom ##addr##, to fetch one double word at ##addr##, or
--		#* a pair {##addr,len}##, to fetch ##len## double words at ##addr##
--
-- Returns:
--		An **object**, either an integer if the input was a single address, or a sequence of integers if a sequence was passed. In both cases, integers returned are words, in the range
-- 0..65535.
--
-- Errors:
--	Peek()ing in memory you don't own may be blocked by the OS, and cause a machine exception. The safe.e include file can catch this sort of issues.
--
-- Comments: 
-- Since addresses are 32-bit numbers, they can be larger than the largest value of type integer (31-bits). Variables that hold an address should therefore be declared as atoms.
--
-- It is faster to read several words at once using the second form of peek() than it is to read one word at a time in a loop. The returned sequence has the length you asked for on input.
-- 
-- Remember that ##peek2u##() takes just one argument, which in the second form is actually a 2-element sequence.
--
-- The only difference between ##peek2s##() and ##peek2u##() is how words with the highest bit set are returned. ##peek2s##() assumes them to be negative, while ##peek2u##() just assumes them to be large and positive.
--
-- This routine overrides ##eu:peek2u##() with a debug version.
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
override function peek2u(object x)
-- safe version of peek 
	integer len
	atom a
	
	if atom(x) then
		len = 1
		a = x
	else
		len = x[2] * 2
		a = x[1]
	end if
	if safe_address(a, len) then
		return original_peek2u(x)
	else
		die("BAD PEEK2U" & bad_address(a))
	end if
end function

function original_peek2s(object x)
	return peeks(x) -- Euphoria's normal peek
end function

--**
-- Signature:
-- peek2s(object addr_n_length)
--
-- Description:
-- Fetches a //signed// word, or some //signed// words	, from an address in memory.
--
-- Parameters:
--		# ##addr_n_length##: an object, either of
--		#* an atom ##addr##, to fetch one word at ##addr##, or
--		#* a pair {##addr,len}##, to fetch ##len## words at ##addr##
--
-- Returns:
--		An **object**, either an integer if the input was a single address, or a sequence of integers if a sequence was passed. In both cases, integers returned are double words, in the range -32768..32767.
--
-- Errors:
--	Peek()ing in memory you don't own may be blocked by the OS, and cause a machine exception. The safe.e i,clude file can catch this sort of issues.
--
-- Comments: 
-- Since addresses are 32-bit numbers, they can be larger than the largest value of type integer (31-bits). Variables that hold an address should therefore be declared as atoms.
--
-- It is faster to read several words at once using the second form of peek() than it is to read one word at a time in a loop. The returned sequence has the length you asked for on input.
-- 
-- Remember that ##peek2s##() takes just one argument, which in the second form is actually a 2-element sequence.
--
-- The only difference between ##peek2s##() and ##peek2u##() is how words with the highest bit set are returned. ##peek2s##() assumes them to be negative, while ##peek2u##() just assumes them to be large and positive.
--
-- This routine overrides ##eu:peek2s##() with a debug version.
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
override function peek2s(object x)
-- safe version of peek 
	integer len
	atom a
	
	if atom(x) then
		len = 1
		a = x
	else
		len = x[2] * 2
		a = x[1]
	end if
	if safe_address(a, len) then
		return original_peek2s(x)
	else
		die("BAD PEEK2S" & bad_address(a))
	end if
end function

function original_peek4s(object x)
	return peek4s(x) -- Euphoria's normal peek
end function

--**
-- Signature:
-- peek4s(object addr_n_length)
--
-- Description:
-- Fetches a //signed// double words, or some //signed// double words	, from an address in memory.
--
-- Parameters:
--		# ##addr_n_length##: an object, either of
--		#* an atom ##addr##, to fetch one double word at ##addr##, or
--		#* a pair {##addr,len}##, to fetch ##len## double words at ##addr##
--
-- Returns:
--		An **object**, either an atom if the input was a single address, or a sequence of atoms if a sequence was passed. In both cases, atoms returned are double words, in the range 0..power(2,32)-1.
--
-- Errors:
--	Peek()ing in memory you don't own may be blocked by the OS, and cause a machine exception. The safe.e i,clude file can catch this sort of issues.
--
-- Comments: 
-- Since addresses are 32-bit numbers, they can be larger than the largest value of type integer (31-bits). Variables that hold an address should therefore be declared as atoms.
--
-- It is faster to read several double words at once using the second form of peek() than it is to read one double word at a time in a loop. The returned sequence has the length you asked for on input.
-- 
-- Remember that ##peek4s##() takes just one argument, which in the second form is actually a 2-element sequence.
--
-- The only difference between ##peek4s##() and ##peek4u##() is how double words with the highest bit set are returned. ##peek4s##() assumes them to be negative, while ##peek4u##() just assumes them to be large and positive.
-- 
-- This routine overrides ##eu:peek4s##() with a debuug version.

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
override function peek4s(object x)
-- safe version of peek4s 
	integer len
	atom a
	
	if atom(x) then
		len = 4
		a = x
	else
		len = x[2]*4
		a = x[1]
	end if
	if safe_address(a, len) then
		return original_peek4s(x)
	else
		die("BAD PEEK4S" & bad_address(a))
	end if
end function

function original_peek4u(object x)
	return peek4u(x) -- Euphoria's normal peek
end function

--**
-- Signature:
-- peek4u(object addr_n_length)
--
-- Description:
-- Fetches an //unsigned// double word, or some //unsigned// dounle words, from an address in memory.
--
-- Parameters:
--		# ##addr_n_length##: an object, either of
--		#* an atom ##addr##, to fetch one double word at ##addr##, or
--		#* a pair {##addr,len}##, to fetch ##len## double words at ##addr##
--
-- Returns:
--		An **object**, either an atom if the input was a single address, or a sequence of atoms if a sequence was passed. In both cases, atoms returned are double words, in the range 
-- -power(2,31)..power(2,31)-1.
--
-- Errors:
--	Peek()ing in memory you don't own may be blocked by the OS, and cause a machine exception. The safe.e include file can catch this sort of issues.
--
-- Comments: 
-- Since addresses are 32-bit numbers, they can be larger than the largest value of type integer (31-bits). Variables that hold an address should therefore be declared as atoms.
--
-- It is faster to read several double words at once using the second form of peek() than it is to read one double word at a time in a loop. The returned sequence has the length you asked for on input.
-- 
-- Remember that ##peek4u##() takes just one argument, which in the second form is actually a 2-element sequence.
--
-- The only difference between ##peek4s##() and ##peek4u##() is how double words with the highest bit set are returned. ##peek4s##() assumes them to be negative, while ##peek4u##() just assumes them to be large and positive.
--
-- This routine overrides ##eu:peek4u##() with a debug version.
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
override function peek4u(object x)
-- safe version of peek4u 
	integer len
	atom a
	
	if atom(x) then
		len = 4
		a = x
	else
		len = x[2]*4
		a = x[1]
	end if
	if safe_address(a, len) then
		return original_peek4u(x)
	else
		die("BAD PEEK4U" & bad_address(a))
	end if
end function

function original_peek_string(object x)
	return peek(x) -- Euphoria's normal peek_string
end function

without warning
-- override "peek_string" with debug peek_string
global function peek_string(object x)
-- safe version of peek_string 
	integer len
	atom a
	
	len = 1
	while 1 do
		if safe_address( a, len ) then
			if not original_peek( a + len - 1 ) then
				exit
			else
				len += 1
			end if
		else
			die("BAD PEEK_STRING" & bad_address(a))
		end if
	end while
	return original_peek_string(x)
end function

procedure original_poke(atom a, object v)
	poke(a, v)
end procedure

--**
-- Signature:
-- global procedure poke(atom addr, object x)
--
-- Description:
-- Stores one or more bytes, starting at a memory location.
--
-- Parameters:
--		# ##addr##: an atom, the address at which to store
--		# ##x##: an object, either a byte or a non empty sequence of bytes.
--
-- Errors:
--	Poke()ing in memory you don't own may be blocked by the OS, and cause a machine exception. The safe.e include file can catch this sort of issues.
--
-- Comments: 
-- The lower 8-bits of each byte value, i.e. remainder(x, 256), is actually stored in memory.
--
-- It is faster to write several bytes at once by poking a sequence of values, than it is to write one byte at a time in a loop. 
-- 
-- Writing to the screen memory with poke() can be much faster than using puts() or printf(), but the programming is more difficult. In most cases the speed is not needed. For example, the Euphoria editor, ed, never uses poke().
--  
-- This routine overrides ##eu:poke##-) with a debug version.
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

override procedure poke(atom a, object v)
-- safe version of poke 
	integer len
	
	if atom(v) then
		len = 1
	else
		len = length(v)
	end if
	if safe_address(a, len) then
		original_poke(a, v)
	else
		die("BAD POKE" & bad_address(a))
	end if
end procedure

procedure original_poke2(atom a, object v)
	poke(a, v)
end procedure

-- Signature:
-- global procedure poke2(atom addr, object x)
--
-- Description:
-- Stores one or more words, starting at a memory location.
--
-- Parameters:
--		# ##addr##: an atom, the address at which to store
--		# ##x##: an object, either a word or a non empty sequence of words.
--
-- Errors:
--	Poke()ing in memory you don't own may be blocked by the OS, and cause a machine exception. The safe.e include file can catch this sort of issues.
--
-- Comments: 
-- There is no point in having poke2s() or poke2u(). For example, both 32768 and -32768 are stored as #F000 when stored as words. It' up to whoever reads the value to figure it out.
--
-- It is faster to write several words at once by poking a sequence of values, than it is to write one words at a time in a loop.
-- 
-- Writing to the screen memory with poke2() can be much faster than using puts() or printf(), but the programming is more difficult. In most cases the speed is not needed. For example, the Euphoria editor, ed, never uses poke2().
--  
-- The 2-byte values to be stored can be negative or positive. You can read them back with either ##peek2s##() or ##peek2u##(). Actually, only remainder(##x##,65536) is being stored.
--
-- This routine overrides ##eu:poke2##() with a debug version.
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
override procedure poke2(atom a, object v)
-- safe version of poke2 
	integer len
	
	if atom(v) then
		len = 1
	else
		len = length(v) * 4
	end if
	if safe_address(a, len) then
		original_poke2(a, v)
	else
		die("BAD POKE" & bad_address(a))
	end if
end procedure

procedure original_poke4(atom a, object v)
	poke4(a, v)
end procedure

--**
-- Signature:
-- global procedure poke4(atom addr, object x)
--
-- Description:
-- Stores one or more double words, starting at a memory location.
--
-- Parameters:
--		# ##addr##: an atom, the address at which to store
--		# ##x##: an object, either a double word or a non empty sequence of double words.
--
-- Errors:
--	Poke()ing in memory you don't own may be blocked by the OS, and cause a machine exception. The safe.e include file can catch this sort of issues.
--
-- Comments: 
-- There is no point in having poke4s() or poke4u(). For example, both +power(2,31) and -power(2,31) are stored as #F0000000. It' up to whoever reads the value to figure it out.
--
-- It is faster to write several double words at once by poking a sequence of values, than it is to write one double words at a time in a loop.
-- 
-- Writing to the screen memory with poke4() can be much faster than using puts() or printf(), but the programming is more difficult. In most cases the speed is not needed. For example, the Euphoria editor, ed, never uses poke4().
--  
-- The 4-byte values to be stored can be negative or positive. You can read them back with either ##peek4s##() or ##peek4u##(). However, the results are unpredictable if you want to store values with a fractional part or a magnitude greater than power(2,32), even though Euphoria represents them all as atoms.
--
-- Yhis routine overrides ##eu:poke4##() with a debug version.
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
override procedure poke4(atom a, object v)
-- safe version of poke4 
	integer len
	
	if atom(v) then
		len = 4
	else
		len = length(v)*4
	end if
	if safe_address(a, len) then
		original_poke4(a, v)
	else
		die("BAD POKE4" & bad_address(a))
	end if
end procedure

procedure original_mem_copy(atom target, atom source, atom len)
	mem_copy(target, source, len)
end procedure

--**
-- Signature:
-- mem_copy(atom destination, atom origin, integer len)
--
-- Descripotion:
-- Copy a block of memory from an address to another.
--
-- Parameters:
--		# ##destination##: an atom, the address at which data is to be copied
--		# ##origin##: an atom, the address from which data is to be copied
--		# ##len##: an integer, how many bytes are to be copied.
--
-- Comments: 
-- The bytes of memory will be copied correctly even if the block of memory at ##destination## overlaps with the block of memory at ##origin##.
--
-- mem_copy(destination, origin, len) is equivalent to: poke(destination, peek({origin, len})) but is much faster.
--
-- This routine overrides ##eu:mem_copy##() with a debug version.
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
override procedure mem_copy(machine_addr target, machine_addr source, natural len)
-- safe mem_copy
	if not safe_address(target, len) then 
		die("BAD MEM_COPY TARGET" & bad_address(target))
	elsif not safe_address(source, len) then
		die("BAD MEM_COPY SOURCE" & bad_address(source))
	else
		original_mem_copy(target, source, len)
	end if
end procedure

procedure original_mem_set(atom target, atom value, integer len)
	mem_set(target, value, len)
end procedure

--**
-- Signature:
-- mem_set(atom destination, integer byte_value, integer how_many))
--
-- Description:
-- Sets a contiguous range of memory ocations to a single value.
--
-- Parameters:
--		# ##destination##: an atom, the address starting the range to set.
--		# ##byte_value##, an integer, the value to copy at all addresses in the range.
--		# ##how_many##: an integer, how many bytes are to be set.
--
-- Comments: 
-- The low order 8 bits of ##byte_value## are actually stored in each byte.
-- mem_set(destination, byte_value, how_many) is equivalent to: poke(destination, repeat(byte_value, how_many)) but is much faster.
--
-- This routine overrides ##eu:mem_set##() with a debug version.
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
override procedure mem_set(machine_addr target, atom value, natural len)
-- safe mem_set
	if safe_address(target, len) then
		original_mem_set(target, value, len)
	else
		die("BAD MEM_SET" & bad_address(target))
	end if
end procedure

atom allocation_num
allocation_num = 0

procedure show_byte(atom m)
-- display byte at memory location m
	integer c
	
	c = original_peek(m)
	if c <= 9 then
		printf(1, "%d", c)
	elsif c < 32 or c > 127 then
		printf(1, "%d #%02x", {c, c})
	else
		if c = leader[1] or c = trailer[1] then
			printf(1, "%s", c)
		else
			printf(1, "%d #%02x '%s'", {c, c, c})
		end if
	end if
	puts(1, ",  ")
end procedure

procedure show_block(sequence block_info)
-- display a corrupted block and die
	integer len, id, bad, p
	atom start
	
	start = block_info[1]
	len = block_info[2]
	id = block_info[3]
	printf(1, "BLOCK# %d, START: #%x, SIZE %d\n", {id, start, len})
	-- check pre-block
	bad = 0
	for i = start-BORDER_SPACE to start-1 do
		p = original_peek(i)
		if p != leader[1] or bad then
			bad += 1
			if bad = 1 then
				puts(1, "DATA WAS STORED ILLEGALLY, JUST BEFORE THIS BLOCK:\n")
				puts(1, "(" & leader[1] & " characters are OK)\n")
				printf(1, "#%x: ", i)
			end if
			show_byte(i)
		end if
	end for
	puts(1, "\nDATA WITHIN THE BLOCK:\n")
	printf(1, "#%x: ", start)
	if len <= 30 then
		-- show whole block
		for i = start to start+len-1 do
			show_byte(i)
		end for 
	else
		-- first part of block
		for i = start to start+14 do
			show_byte(i)
		end for 
		-- last part of block
		puts(1, "\n ...\n")
		printf(1, "#%x: ", start+len-15)
		for i = start+len-15 to start+len-1 do
			show_byte(i)
		end for 
	end if
	bad = 0
	-- check post-block
	for i = start+len to start+len+BORDER_SPACE-1 do
		p = original_peek(i)
		if p != trailer[1] or bad then
			bad += 1
			if bad = 1 then
				puts(1, "\nDATA WAS STORED ILLEGALLY, JUST AFTER THIS BLOCK:\n")
				puts(1, "(" & trailer[1] & " characters are OK)\n")
				printf(1, "#%x: ", i)
			end if
			show_byte(i)
		end if
	end for 
	die("")
end procedure

--**
-- Scans the list of registered blocks for any corruption.
--
-- Comments:
--
-- safe.e maintains a list of acquired memory blocks. Those gained through allocate() or allocate_low() are automatically included. Any other block, for debugging purposes, must be registered by [[:register_block]]() and unregistered by [[:untrgister_block]]().
--
-- The list is scanned and, if any block shows signs of corruption, it is displayed on the screen and the program terminates. Otherwise, nothing happens.
--
-- In memory.e, this routine does nothing. It is there to make switching between debugged and normal version of your program easier.
--
-- See Also:
-- [[:register_block]], [[:unregister_block]], [[:memory.e]]

global procedure check_all_blocks()
-- Check all allocated blocks for corruption of the leader and trailer areas. 
	integer n
	atom a
	sequence block
	
	for i = 1 to length(safe_address_list) do
		block = safe_address_list[i]
		if block[3] >= 1 then
			-- a block that we allocated
			a = block[1]
			n = block[2]
			if not equal(leader, 
						 original_peek({a-BORDER_SPACE, BORDER_SPACE})) then
				show_block(block)
			elsif not equal(trailer, 
						 original_peek({a+n, BORDER_SPACE})) then
				show_block(block)
			end if          
		end if
	end for
end procedure

procedure original_call(atom addr)
	call(addr)
end procedure

--**
-- Signature:
-- global procedure call(atom addr)
--
-- Description:
--  Call a machine language routine which was stored in memory prior.
--
-- Parameters:
--		# ##addr##: an atom, the address at which to transfer execution control.
--
-- Comments:
-- The machine code routine must execute a RET instruction #C3 to return control to Euphoria. The routine should save and restore any registers that it uses.
--
-- You can allocate a block of memory for the routine and then poke in the bytes of machine code. You might allocate other blocks of memory for data and parameters that the machine code can operate on. The addresses of these blocks could be poked into the machine code.
--
-- If your machine code uses the stack, use ##c_proc##() instead of ##call##().
--
-- This routine overrides ##eu:call##() with a debug version.
--
-- Example 1: 
--		[[../demo/callmach.ex]]
--
-- See Also:
-- 		[[:allocate]], [[:free]], [[:peek]], [[:poke]], [[:c_proc]], [[:define_c_proc]]
override procedure call(atom addr)
-- safe call - machine code must start in block that we own
	if safe_address(addr, 1) then
		original_call(addr)
		if check_calls then
			check_all_blocks() -- check for any corruption
		end if
	else
		die(sprintf("BAD CALL ADDRESS!!!! %d\n\n", addr))
	end if
end procedure

procedure original_c_proc(integer i, sequence s)
	c_proc(i, s)
end procedure

-- TODO: document, as well as in dll.e
global procedure c_proc(integer i, sequence s)
	original_c_proc(i, s)
	if check_calls then
		check_all_blocks()
	end if
end procedure

function original_c_func(integer i, sequence s)
	return c_func(i, s)
end function

-- TODO: document, as well as in dll.e
global function c_func(integer i, sequence s)
	object r
	
	r = original_c_func(i, s)
	if check_calls then
		check_all_blocks()
	end if 
	return r
end function

--**
-- Description: Add a block of memory to the list of safe blocks maintained by safe.e (the debug version of machine.e). The block starts at address a. The length of the block is i bytes.
--
-- Parameters:
--		# ##block_addr##: an atom, the start address of the block
--		# ##block_len##: an integer, the size of the block.
--
-- Comments: 
--
-- In memory.e, this procedure does nothing. It is there simply to simpify switching between machine.e and safe.e.
--
-- This routine is only meant to be used for debugging purposes. safe.e tracks the blocks of memory that your program is allowed to [[:peek]](), [[:poke]](), [[mem_copy]]() etc. These are normally just the blocks that you have allocated using Euphoria's [[:allocate]]() or [[:allocate_low]]() routines, and which you have not yet freed using Euphoria's [[:free]]() or [[:free_low]](). In some cases, you may acquire additional, external, blocks of memory, perhaps as a result of calling a C routine. 
--
-- If you are debugging your program using safe.e, you must register these external blocks of memory or safe.e will prevent you from accessing them. When you are finished using an external block you can unregister it using unregister_block().
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
--   [[:unregister_block]], [[:memory.e]]
global procedure register_block(machine_addr block_addr, positive_int block_len)
-- register an externally-acquired block of memory as being safe to use
	allocation_num += 1
	safe_address_list = prepend(safe_address_list, {block_addr, block_len,
	   -allocation_num})
end procedure

--**
-- Remove a block of memory from the list of safe blocks maintained by safe.e (the debug version of machine.e).
--
-- Parameters:
--		# ##block_addr##: an atom, the start address of the block
--
-- Comments: 
--
-- In memory.e, this procedure does nothing. It is there simply to simpify switching between machine.e and safe.e.
--
-- This routine is only meant to be used for debugging purposes. Use it to unregister blocks of memory that you have previously registered using [[:register_block]](). By unregistering a block, you remove it from the list of safe blocks maintained by safe.e. This prevents your program from performing any further reads or writes of memory within the block.
--
--  See [[:register_block]]() for further comments and an example.
-- 
-- See Also: register_block, safe.e  
--   [[:register_block]], [[:memory.e]]
global procedure unregister_block(machine_addr block_addr)
-- remove an external block of memory from the safe address list
	for i = 1 to length(safe_address_list) do
		if safe_address_list[i][1] = block_addr then
			if safe_address_list[i][3] >= 0 then
				die("ATTEMPT TO UNREGISTER A NON-EXTERNAL BLOCK")
			end if
			safe_address_list = safe_address_list[1..i-1] &
								safe_address_list[i+1..$]
			return
		end if  
	end for
	die("ATTEMPT TO UNREGISTER A BLOCK THAT WAS NOT REGISTERED!")
end procedure

function prepare_block(atom a, integer n)
-- set up an allocated block so we can check it for corruption
	if a = 0 then
		die("OUT OF MEMORY!")
	end if
	original_poke(a, leader)
	a += BORDER_SPACE
	original_poke(a+n, trailer)
	allocation_num += 1
--  if allocation_num = ??? then 
--      trace(1) -- find out who allocated this block number
--  end if  
	safe_address_list = prepend(safe_address_list, {a, n, allocation_num})
	return a
end function

--**
-- Allocate a contiguous block of memory.
--
-- Parameters:
--		# ##n##: a positive integer, the size of the requested block.
--
-- Return:
--		An **atom**, the address of the allocated memory, or 0 if the memory can't be allocated.
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
-- This routine overrides ##machine:allocate##() with a debug version.
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
-- allocate memory block and add it to safe list
	atom a

	a = machine_func(M_ALLOC, n+BORDER_SPACE*2)
	return prepare_block(a, n)
end function

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

global function allocate_low(positive_int n)
-- allocate memory block and add it to safe list
	atom a
	
	a = machine_func(M_ALLOC_LOW, n+BORDER_SPACE*2)
	return prepare_block(a, n)
end function

--**
-- Free up a previously allocated block of memory.
--
-- Parameters:
--		# ##addr##: an atom, the address of a block to free.
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
-- ##addr## must have been allocated previously using [[:allocate]](). You cannot use it to relinquish part of a block. Instead, you have to allocate a block of the new size, copy useful contents from old block there and then free() the old block.
--
-- This routine overrides ##machine:free##-) with a debug version.
--
-- Example 1:
--   [[../demo/callmach.]]
--
-- See Also:
--     [[:allocate]], [[:free_low]]
global procedure free(machine_addr a)
-- free address a - make sure it was allocated
	integer n
	
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
			machine_proc(M_FREE, a-BORDER_SPACE)
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
global procedure free_low(low_machine_addr a)
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

global constant REG_LIST_SIZE = 10

type register_list(sequence r)
-- a list of register values
	return length(r) = REG_LIST_SIZE
end type

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
--      global constant REG_DI = 1,
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

global function dos_interrupt(integer int_num, register_list input_regs)
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


----------- the rest is identical to machine.e ------------------------------

type sequence_8(sequence s)
-- an 8-element sequence
	return length(s) = 8
end type

type sequence_4(sequence s)
-- a 4-element sequence
	return length(s) = 4
end type

global constant REG_DI = 1,      
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

--==== Data type conversion
--**
-- Converts an atom that represents an integer to a sequence of 4 bytes.
--
-- Parameters:
--		# ##x##: an atom, the value to convert.
--
-- Retrns:
--		A **sequence** of 4 bytes, lowest significant byte first.
-- Comments:
-- If the atom does not fit into a 32-bit integer, things may still work right:
-- * If there is a fractional part, the first element in the returned value will carry it. If you poke the value to RAM, that fraction will be discarded anyway.
-- * If ##x## is simply too big, the first three bytes will still be correct, and the 4th 
-- element will be  floor(##x##/power(2,24)). If this is not a byte sized integer, some
-- truncation may occur, but usually o error.
--
-- The integer can be negative. Negative byte-values will be returned, but after poking them into memory you will have the correct (two's complement) representation for the 386+.
--
-- Example 1:
-- <eucode>
--  s = int_to_bytes(999)
-- -- s is {231, 3, 0, 0}
-- </eucode>
--  
-- Example 2:  
-- <eucode>
--  s = int_to_bytes(-999)
-- -- s is {-231, -4, -1, -1}
-- <8eucode>
-- 
-- See Also:
--		[[:bytes_to_int]], [[:int_to_bits]], [[:atom_to_float64]], [[:poke4]], [[:poke8]]

global function int_to_bytes(atom x)
-- returns value of x as a sequence of 4 bytes 
-- that you can poke into memory 
--      {bits 0-7,  (least significant)
--       bits 8-15,
--       bits 16-23,
--       bits 24-31} (most significant)
-- This is the order of bytes in memory on 386+ machines.
	integer a,b,c,d
	
	a = remainder(x, #100)
	x = floor(x / #100)
	b = remainder(x, #100)
	x = floor(x / #100)
	c = remainder(x, #100)
	x = floor(x / #100)
	d = remainder(x, #100)
	return {a,b,c,d}
end function

atom mem
mem = allocate(4)

--**
-- Converts a sequence of at most 4 bytes into an atom.
--
-- Parameters:
--		# ##s##: the sequence to convert
-- Returns:
--		An **atom**, the value of the concatenated bytes of ##s##.
--
-- Comments:
--
--	This perfoms the reverse operation from [[:int_to_bytes]]
--
--  An atom is being returned, because the converted value may be bigger than what can fit in an Euphoria integer.
--
-- Example 1:
-- <eucode>
--  atom int32
--
-- int32 = bytes_to_int({37,1,0,0})
-- -- int32 is 37 + 256*1 = 293
-- </eucode>
-- 
-- See Also:
-- 		[[:bits_to_int]], [[:float64_to_atom]], [[:int_to_bytes]], [[:peek]], [[:peek4s]], [[:pee4ku]], [[:poke4]]
global function bytes_to_int(sequence s)
-- converts 4-byte peek() sequence into an integer value
	if length(s) = 4 then
		poke(mem, s)
	else    
		poke(mem, s[1..4])
	end if
	return peek4u(mem)
end function

--**
-- Extracts the lower bits from an integer.
--
-- Parameters:
--		# ##x##: the atom to convert
-- 		# ##nbits##: the number of bits requested.
--
-- Returns:
--		A **sequence of length ##nbits##, made of 1's and 0's.
--
-- Comments:
-- ##x## should have no fractional part. If it does, then the first "bit" will be an atom between 0 and 2.
--
-- The bits are returned lowest first.
--
-- For negative numbers the two's complement bit pattern is returned.
--
-- You can use subscripting, slicing, and/or/xor/not of entire sequences etc. to manipulate sequences of bits. Shifting of bits and rotating of bits are easy to perform.
--
-- Example 1:
-- <eucode>
--  s = int_to_bits(177, 8)
-- -- s is {1,0,0,0,1,1,0,1} -- "reverse" order
-- </eucode>
--  
-- See Also:
--		[[:bits_to_int]], [[:int_to_bytes]], [[:bitwise operations]], [[:operations on sequences]]
global function int_to_bits(atom x, integer nbits)
-- Returns the low-order nbits bits of x as a sequence of 1's and 0's. 
-- Note that the least significant bits come first. You can use Euphoria's
-- and/or/not operators on sequences of bits. You can also subscript, 
-- slice, concatenate etc. to manipulate bits.
	sequence bits
	integer mask
	
	bits = repeat(0, nbits)
	if integer(x) and nbits < 30 then
		-- faster method
		mask = 1
		for i = 1 to nbits do
			bits[i] = and_bits(x, mask) and 1
			mask *= 2
		end for
	else
		-- slower, but works for large x and large nbits
		if x < 0 then
			x += power(2, nbits) -- for 2's complement bit pattern
		end if
		for i = 1 to nbits do
			bits[i] = remainder(x, 2) 
			x = floor(x / 2)
		end for
	end if
	return bits
end function

--**
-- Converts a sequence of bits to an atom that has no fractional part.
--
-- Parameters:
-- 		# ##bits##: the sequence to convert.
--
-- Returns:
--		A positive **atom**, whose machine representation was given by ##bits##.
--
-- Comments:
-- An element in ##bits## can be any atom. If nonzero, it counts for 1, else for 0.
--
-- The first elements in ##bits## represent the bits with the least weight in the returned value. Only the 52 last bits will matter, as the PC hardware cannot hold an integer with more digits than this.
--  If you print s the bits will appear in "reverse" order, but it is convenient to have increasing subscripts access bits of increasing significance.
--
-- Example 1:
-- <eucode>
--  a = bits_to_int({1,1,1,0,1})
-- -- a is 23 (binary 10111)
-- </eucode>
--  
-- See Also:
--		[[:bytes_to_int]], [[:int_to_bits]], [[:operations on sequences]]

global function bits_to_int(sequence bits)
-- get the (positive) value of a sequence of "bits"
	atom value, p
	
	value = 0
	p = 1
	for i = 1 to length(bits) do
		if bits[i] then
			value += p
		end if
		p += p
	end for
	return value
end function

--**
-- Reset the random number generator.
--
-- Parameters:
-- 		# ##seed##: an integer, which the generator uses to initialise itself
--
-- Comments:
-- 		Starting from a ##seed##, the values returned by rand() are reproducible. This is useful for demos and stress tests based on random data. Normally the numbers returned by the rand() function are totally unpredictable, and will be different each time you run your program. Sometimes however you may wish to repeat the same series of numbers, perhaps because you are trying to debug your program, or maybe you want the ability to generate the same output (e.g. a random picture) for your user upon request.  
--
-- Example 1:
-- <eucode>
--  sequence s, t
-- s = repeat(0, 3)
-- t = s
-- 
-- set_rand(12345)
-- s[1] = rand(10)
-- s[2] = rand(100)
-- s[3] = rand(1000)
-- 
-- set_rand(12345)  -- same value for set_rand()
-- t[1] = rand(10)  -- same arguments to rand() as before
-- t[2] = rand(100)
-- t[3] = rand(1000)
-- -- at this point s and t will be identical
--  </eucode>
-- 
-- See Also:
--		[[:rand]]
global procedure set_rand(integer seed)
-- Reset the random number generator.
-- A given value of seed will cause the same series of
-- random numbers to be generated from the rand() function
	machine_proc(M_SET_RAND, seed)
end procedure

--**
-- Set how Euphoria should use the VESA standard to perform video operations.
--
-- Platform:
--		//DOS32//
--
-- Parameters:
-- 		# ##code##: an integer, must be 0 or 1.
--
-- Comments:
-- If code is 1 then force Euphoria to use the VESA graphics standard.
-- This may let Euphoria work better in SVGA modes with certain graphics cards.
-- If code is 0 then Euphoria's normal use of the graphics card is restored.
-- Values of code other than 0 or 1 should not be used.
--
-- Most people can ignore this. However if you experience difficulty in SVGA graphics modes you should try calling use_vesa(1) at the start of your program before any calls to graphics_mode().
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
-- If code is 1 then force Euphoria to use the VESA graphics standard.
-- This may let Euphoria work better in SVGA modes with certain graphics cards.
-- If code is 0 then Euphoria's normal use of the graphics card is restored.
-- Values of code other than 0 or 1 should not be used.
	machine_proc(M_USE_VESA, code)
end procedure

--**
-- Specify a final message to display for your user, in the event
-- that Euphoria has to shut down your program due to an error.
-- Parameters:
-- 		# ##msg##: a sequence to display. It must only contain printable characters.
--
-- Comments:
-- 		There can be as many crash_message() call as needed in a program. Whatever was defined 
-- last will be used in case of a runtime error.
-- Example 1:
-- <eucode>
-- crash_message("The password you entered must have at least 8 characters.")
-- pwd_key = input_text[1..8]
-- -- if ##input_text## is too short, user will get a more meaningful message than "index out of bounds".
-- </eucode>
-- See Also:
-- 	[[:crash]], [[:crash_file]]
export procedure crash_message(sequence msg)
-- Specify a final message to display for your user, in the event 
-- that Euphoria has to shut down your program due to an error.
	machine_proc(M_CRASH_MESSAGE, msg)
end procedure

--**
-- Specify a file path name in place of "ex.err" where you want
-- any diagnostic information to be written.
-- Parameters:
-- 		# ##fie_path##: a sequence, the new error and traceback file path.
--
-- Comments:
-- 		There can be as many calls to crash_file() as needed. Whatever was defined last will be used in case of an error at runtime, whether it was troggered by crash() or not.
--
-- See Also:
-- 		[[:crash]], [[:crash_message]]
export procedure crash_file(sequence file_path)
-- Specify a file name in place of "ex.err" where you want
-- diagnostic information to be written.
	machine_proc(M_CRASH_FILE, file_path)
end procedure

--**
-- Specify a file path where to output warnings. 
--
-- Parameters:
-- 		#file_path##: an object indicating where to dump any warning that were produced.
--
-- Comments:
-- 		By default, warnings are displayed on the standard error, and require pressing the 
-- Enter key to keep going. Redirecting to a file enables skipping the latter step and having 
-- a console window open, while retaining ability to inspect the warnings in case any was issued.
--
--	 	Any atom >=0 causes standard error to be used, thus reverting to default behaviour.
--
--		Any atom <0 suppresses both warning generation and output. Use this latter in extreme cases only.
--
-- 		On an error, some output to the console is performed anyway, so that whatever warning file was specified is ignored then.
--
-- Example 1:
-- <eucode>
-- warning_file("warnings.lst")
-- -- some code
-- warning_file(0)
-- -- changed opinion: warnings will go to standard error as usual
-- </eucode>
-- See Also:
-- 	[[:without warning]]
export procedure warning_file(sequence file_path)
-- Specify a file name where to output warnings. Any atom >=0 causes STDERR to be used. Any 
-- value <0 suppresses output. Use the latter in extreùe cases only.
	machine_proc(M_CRASH_FILE, file_path)
end procedure

--**
-- Specify a function to be called when an error takes place at run time.
--
-- Parameters:
-- 		# ##func##: an integer, the routine_id of the function to link in.
--
-- Comments:
-- 		The supplied function must have only one parameter, which should be integer or more general. Defaulted parameters in crash routines are not supported yet.
--
--		Euphoria maintains a linked list of routines to execute upon a crash. crash_routine() adds a new function to the list. The routines are executed last defined first. You cannot unlink a routine once it is linked, nor inspect the crash routine chain.
--
--		Currently, the crash routines are passed 0. Future versions may attempt to convey more
-- information to them. If a crash routine returns anything else than 0, the remaining
-- routines in the chain are skipped.
--
-- 		crash routines are not full fledged exception handlers, and they cannot resume execution at current or next statement. However, they can read the generated crash file, and might perform any action, including restarting the program.
--
-- Example 1:
-- <eucode>
-- function report_error(integer dummy)
--	  mylib:email("maintainer@remote_site.org", "ex.err")
--    return 0 and dummy
-- end function
-- crash_routine(routine_id("report_error"))
-- </eucode>
-- See Also:
-- 	[[:crash_file]], [[:routine_id]], [[:Debugging and profiling]]
export procedure crash_routine(integer proc)
-- specify the routine id of a 1-parameter Euphoria function to call in the
-- event that Euphoria must shutdown your program due to an error.
	machine_proc(M_CRASH_ROUTINE, proc)
end procedure

--**
-- Specify the number of clock-tick interrupts per second.
--
-- Parameters:
-- 		# ##rate##: an atom, the number of ticks by seconds.
--
-- Cimments:
-- This setting determines the precision of the time() library routine. It also affects the sampling rate for time profiling.
--
-- ##tick_rate## is efective under //DOS// only, and is a no-op elsewhere. Under //DOS//, the tick rate is 18.2 ticks per second. Under //WIN32//, it is always 100 ticks per second.
--
-- ##tick_rate##() can increase the setting above the default value. As a special case, ##tick_rate(0)## resets //DOS// to the default tick rates.
--
-- If a program runs in a DOS window with a tick rate other than 18.2, the time() function will not advance unless the window is the active window. 
--
-- With a tick rate other than 18.2, the time() function on DOS takes about 1/100 the usual time that it needs to execute. On Windows and FreeBSD, time() normally executes very quickly.
-- 
-- See Also:
--		[[:Debugging and profiling]]

-- While ex.exe is running, the system will maintain the correct time of day. However if ex.exe should crash (e.g. you see a "CauseWay..." error) while the tick rate is high, you (or your user) may need to reboot the machine to restore the proper rate. If you don't, the system time may advance too quickly. This problem does not occur on Windows 95/98/NT, only on DOS or Windows 3.1. You will always get back the correct time of day from the battery-operated clock in your system when you boot up again. 
--  
-- Example 1:
-- <eucode>
--  tick_rate(100)
-- -- time() will now advance in steps of .01 seconds
-- -- instead of the usual .055 seconds
-- </eucode>
-- 
-- See Also: 
--        [[:time]], [[:time profiling]]

global procedure tick_rate(atom rate)
-- Specify the number of clock-tick interrupts per second.
-- This determines the precision of the time() library routine, 
-- and also the sampling rate for time profiling.
	machine_proc(M_TICK_RATE, rate)
end procedure

--**
-- Retrieve the address of a //DOS// interrupt handler.
--
-- Platform:
--		//DOS32//
--
-- Parameters:
--		# ##int_um##: an integer in the 0..255 range, the number of the interrupt.
-- Returns:
--		A **sequence of length 2: {16-bit segment, 32-bit offset}
-- Comments:
-- This way to return the address is convenient to pass it to other //DOS// routines. To convert it back to a flat 32-bit address, simply use 65536*segment+offset.
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
--		# ##int_um##: an integer in the 0..255 range, the number of the interrupt.
-- 		# ##addr##: a sequence like returned by [[:get_vector]].
--
-- Comments:
-- When setting an interrupt vector, //never// forget to restore it before your program terminates. Also, the machine code that will handle the interrupt must be at its expected address //before// calling ##set_vector##(). It is highly recommended that you study 
-- [[../demo/dos32/hardint.ex]] before trying to set up your own interrupt handler. This task requires a good knowledge of machine-level programming. Disassembling a small freeware TSR is one of the best schools for this.
--
-- It is usually a good policy to chain to the previous interrupt handler. Since the latter may be doing some good work already, it is often a convenience as well.
--
-- Your handler might return from the interrupt using the iretd instruction, or jump to the original interrupt handler. It should save and restore any registers that it modifies. 
--
-- Interrupts occurring in either real mode or protected mode will be passed to your handler. Your interrupt handler should immediately load the correct data segment before it tries to reference memory. 
--
-- You should lock the memory used by your handler to ensure that it will never be swapped out. See [[:lock_memory]]().
-- 
-- A handler for IRQ-mapped interrupts (8..15 and 112..119) must acknowledge the interrupt if
-- it does not pass it to th previous handler. Your machine code should perform an OUT DX,AL
-- instruction with both DX and AL set to #20.
--
-- The 16-bit segment can be the code segment used by Euphoria. To get the value of this segment see [[../demo/dos32/hardint.ex]]. The offset can be the 32-bit value returned by
-- [[:allocate]](). Euphoria runs in protected mode with the code segment and data segment pointing to the same physical memory, but with different access modes.
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
-- lock_memory() should only be used in the highly-specialized situation where you have set up your own DOS hardware interrupt handler using machine code. When a hardware interrupt occurs, it is not possible for the operating system to retrieve any code or data that has been swapped out, so you need to protect any blocks of machine code or data that will be needed in servicing the interrupt.
--
-- Example 1: 
--		[[../demo/dos32/hardint.ex]]
--
-- See Also: 
--		[[:get_vector]], [[:set_vector]]

global procedure lock_memory(machine_addr a, positive_int n)
-- Prevent a chunk of code or data from ever being swapped out to disk.
-- You should lock any code or data used by an interrupt handler.
	machine_proc(M_LOCK_MEMORY, {a, n})
end procedure

--**
-- Convert an atom to a sequence of 8 bytes in IEEE 64-bit format
-- Parameters:
-- 		# ##a##: the atom to convert:
--
-- Returns:
--		A **sequence of 8 bytes, which can be poked in memory to rpresent ##a##.
--
-- Comments:
-- All Euphoria atoms have values which can be represented as 64-bit IEEE floating-point numbers, so you can convert any atom to 64-bit format without losing any precision.
--
-- Integer values will also be converted to 64-bit floating-point format.
--
-- Example:
--  <eucode>
--  fn = open("numbers.dat", "wb")
-- puts(fn, atom_to_float64(157.82)) -- write 8 bytes to a file
--  </eucode>
-- 
-- See Also:
--		[[:float64_to_atom]], [[:int_to_bytes]], [[:atom_to_float32]]
global function atom_to_float64(atom a)
-- Convert an atom to a sequence of 8 bytes in IEEE 64-bit format
	return machine_func(M_A_TO_F64, a)
end function

--**
-- Convert an atom to a sequence of 4 bytes in IEEE 32-bit format
-- Parameters:
-- 		# ##a##: the atom to convert:
--
-- Returns:
--		A **sequence of 4 bytes, which can be poked in memory to rpresent ##a##.
--
-- Comments: 
-- Euphoria atoms can have values which are 64-bit IEEE floating-point numbers, so you may lose precision when you convert to 32-bits (16 significant digits versus 7). The range of exponents is much larger in 64-bit format (10 to the 308, versus 10 to the 38), so some atoms may be too large or too small to represent in 32-bit format. In this case you will get one of the special 32-bit values: inf or -inf (infinity or -infinity). To avoid this, you can use atom_to_float64().
--
-- Integer values will also be converted to 32-bit floating-point format.
--
-- On nowadays computers, computations on 64 bit floats are no faster than on 32 bit floats. Internally, the PC stores them in 80 bit registers anyway. Euphoria doesn't support these so called long doubles.
--
-- Example 1:
-- <eucode>
--  fn = open("numbers.dat", "wb")
-- puts(fn, atom_to_float32(157.82)) -- write 4 bytes to a file
-- </eucode>
-- 
-- See Also:
--		[[:float32_to_atom]], [[:int_to_bytes]], [[:atom_to_float64]]
global function atom_to_float32(atom a)
-- Convert an atom to a sequence of 4 bytes in IEEE 32-bit format
	return machine_func(M_A_TO_F32, a)
end function

--**
-- Convert a sequence of 8 bytes in IEEE 64-bit format to an atom
-- Parameters:
-- 		# ##ieee64##: the sequence to convert:
--
-- Returns:
--		An **atom**, the same value as the FPU would see by peeking ##ieee64## from RAM.
--
-- Comments:
-- Any 64-bit IEEE floating-point number can be converted to an atom.
--
-- Example 1:
-- <eucode>
--  f = repeat(0, 8)
-- fn = open("numbers.dat", "rb")  -- read binary
-- for i = 1 to 8 do
--     f[i] = getc(fn)
-- end for
-- a = float64_to_atom(f)
-- </eucode>
--
-- See Also:
--		[[:float32_to_atom]], [[:bytes_to_int]], [[:atom_to_float64]]
global function float64_to_atom(sequence_8 ieee64)
-- Convert a sequence of 8 bytes in IEEE 64-bit format to an atom
	return machine_func(M_F64_TO_A, ieee64)
end function

--**
-- Convert a sequence of 4 bytes in IEEE 32-bit format to an atom
-- Parameters:
-- 		# ##ieee32##: the sequence to convert:
--
-- Returns:
--		An **atom**, the same value as the FPU would see by peeking ##ieee64## from RAM.
--
-- Comments:
-- Any 32-bit IEEE floating-point number can be converted to an atom.
--
-- Example 1:
-- <eucode>
--  f = repeat(0, 4)
-- fn = open("numbers.dat", "rb") -- read binary
-- f[1] = getc(fn)
-- f[2] = getc(fn)
-- f[3] = getc(fn)
-- f[4] = getc(fn)
-- a = float32_to_atom(f)
-- </eucode>
--
-- See Also:
--		[[:float64_to_atom]], [[:bytes_to_int]], [[:atom_to_float32]]
global function float32_to_atom(sequence_4 ieee32)
-- Convert a sequence of 4 bytes in IEEE 32-bit format to an atom
	return machine_func(M_F32_TO_A, ieee32)
end function

--**
-- Allocate a C-style null-terminated string in memory
--
-- Parameters:
--		# ##s##: a sequence, the string to store in RAM.
--
-- Returns:
--		An **atom**, the address of the memory block where the string was stored, or 0 on failure.
-- Comments:
-- Only the 8 lowest bits of each atom in ##s## is stored. Use ##allocate_wstring##()  for storing dounle byte encoded strings.
--
-- There is no allocate_string_low() function. However, you could easily craft one by adapting the code for ##allocate_string##.
--
-- Since allocate_string() allocates memory, you are responsible to [[:free]]() the block when done with it.
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
-- create a C-style null-terminated string in memory
	atom mem
	
	mem = allocate(length(s) + 1)
	if mem then
		poke(mem, s)
		poke(mem+length(s), 0)  -- Thanks to Aku
	end if
	return mem
end function


