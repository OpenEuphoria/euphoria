-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
-- Euphoria 3.1
-- Machine Level Programming (386/486/Pentium)

-- This is a slower DEBUGGING VERSION of machine.e

-- How To Use This File:

-- 1. If your program doesn't already include machine.e add:
--           include machine.e  
--    to your main .ex[w][u] file at the top.

-- 2. To turn debug version on, issue 
-- <eucode>
-- with define SAFE
-- </eucode>
-- in your main program, before the statement including machine.e.
--
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

-- 6. To switch between normal and debig bversions, simply comment in or out the 
-- "with define SAFE" directive. In means debugging and out means normal.
-- Alternatively, you can use -D SAFE as a switch on the command line (debug) or not (normal).

-- 7. The older method of switching files and renaming them //**no longer works**//. machine.e conditionally includes safe.e.

-- This file is equivalent to machine.e, but it overrides the built-in 
-- routines: 
--     poke, peek, poke4, peek4s, peek4u, call, mem_copy, and mem_set
-- and it provides alternate versions of:
--     allocate, allocate_low, free, free_low

-- Some parameters you may wish to change:

export integer check_calls, edges_only
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

-- Include the starting address and length of any 
-- acceptable areas of memory for peek/poke here. 
-- Set allocation number to 0.
export sequence safe_address_list = {}

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
		 M_LOCK_MEMORY = 41

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

export constant BORDER_SPACE = 40
export constant leader = repeat('@', BORDER_SPACE)
export constant trailer = repeat('%', BORDER_SPACE)

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

export procedure die(sequence msg)
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

export function original_peek(object x)
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
export function peek_string(object x)
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
-- export procedure poke(atom addr, object x)
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
-- export procedure poke2(atom addr, object x)
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
-- export procedure poke4(atom addr, object x)
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
-- Description:
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

export procedure show_block(sequence block_info)
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

export procedure check_all_blocks()
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
-- export procedure call(atom addr)
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
export procedure c_proc(integer i, sequence s)
	original_c_proc(i, s)
	if check_calls then
		check_all_blocks()
	end if
end procedure

function original_c_func(integer i, sequence s)
	return c_func(i, s)
end function

-- TODO: document, as well as in dll.e
export function c_func(integer i, sequence s)
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
export procedure register_block(machine_addr block_addr, positive_int block_len)
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
export procedure unregister_block(machine_addr block_addr)
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

export function prepare_block(atom a, integer n)
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
export function allocate(positive_int n)
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

export function allocate_low(positive_int n)
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
export procedure free(machine_addr a)
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

export constant REG_LIST_SIZE = 10

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


----------- the rest is identical to machine.e ------------------------------

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
export function allocate_string(sequence s)
-- create a C-style null-terminated string in memory
	atom mem
	
	mem = allocate(length(s) + 1)
	if mem then
		poke(mem, s)
		poke(mem+length(s), 0)  -- Thanks to Aku
	end if
	return mem
end function


