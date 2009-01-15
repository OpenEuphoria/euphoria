-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
--****
-- == Usage Notes
-- <<LEVELTOC depth=2>>
-- This file is not normally included directly. The normal approach is to
-- ##include std/machine.e##, which will automatically include either this file
-- or ##std/safe.e## if the SAFE symbol has been defined.
--
-- == Low-Level Memory Management
--
-- <<LEVELTOC depth=2>>
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
--   * ##demo/callmach.ex##      - calling a machine language routine
--   * ##demo/dos32/hardint.ex## - setting up a hardware interrupt handler
--   * ##demo/dos32/dosint.ex##  - calling a DOS software interrupt
--
-- See also ##include/safe.e##. It's a safe, debugging version of this
-- file.
--
-- <<LEVELTOC depth=2>>
--

include std/os.e

constant
	M_ALLOC = 16,
	M_FREE = 17

-- biggest address on a 32-bit machine
constant MAX_ADDR = power(2, 32)-1

-- Positive integer type

public type positive_int(integer x)
	return x >= 1
end type

-- Machine address type

public type machine_addr(atom a)
-- a 32-bit non-null machine address 
	return a > 0 and a <= MAX_ADDR and floor(a) = a
end type

--****
-- === Microsoft's Memory Protection Constants
--
-- 
-- Memory Protection Constants are the same constants 
-- across all platforms.  The API converts them as
-- necessary.  They are only necessary for [[:allocate_protect]]

--** 
-- You may run the data in this page

public constant PAGE_EXECUTE = #10

	--** PAGE_EXECUTE_READ
	-- You may run and read the data    
public constant 	PAGE_EXECUTE_READ = #20
	--**
	-- You may run, read or write this page
public constant 	PAGE_EXECUTE_READWRITE = #40
	--**
	-- You may run, read or write this page
public constant 	PAGE_EXECUTE_WRITECOPY = #80
	--**
	-- You may write to this page.
public constant 	PAGE_WRITECOPY = #08
	--**
	-- You may read or write to this page.
public constant 	PAGE_READWRITE = #04
	--**
	-- You may only read data 
public constant	PAGE_READONLY = #02    	
--**
	-- You have no access to this page
public constant 	PAGE_NOACCESS = #01
     
--

--****
-- === Memory allocation
--

--**
-- Allocate a contiguous block of data memory.
--
-- Parameters:
--		# ##n##, a positive integer, the size of the requested block.
--
-- Return:
--		An **atom**, the address of the allocated memory or 0 if the memory
-- can't be allocated.
--
-- Comments:
-- When you are finished using the block, you should pass the address of the block to 
-- ##[[:free]]()##. This will free the block and make the memory available for other purposes. 
-- Euphoria will never free or reuse your block until you explicitly call ##[[:free]]()##. When 
-- your program terminates, the operating system will reclaim all memory for use with other 
-- programs.  An address returned by this function shouldn't be passed to ##[[:call]]()##.
-- For that purpose you may use ##[[:allocate_code]]()## instead. 
--
-- The address returned will be at least 4-byte aligned.
--
-- Example 1:
-- <eucode>
-- buffer = allocate(100)
-- for i = 0 to 99 do
--     poke(buffer+i, 0)
-- end for
-- </eucode>
--		    
-- See Also:
--     [[:free]], [[:allocate_low]], [[:peek]], [[:poke]], [[:mem_set]], [[:allocate_code]]

public function allocate(positive_int n)
-- Allocate n bytes of memory and return the address.
-- Free the memory using free() below.
	return machine_func(M_ALLOC, n)
end function

include std/dll.e

-- Linux constants
constant PROT_EXEC = 4, PROT_READ = 1, PROT_WRITE = 2,
 PROT_NONE = 0



ifdef WIN32 then
	-- Windows constants
	constant MEM_COMMIT = #1000,
	MEM_RESERVE = #2000,
	--MEM_RESET = #8000,
	MEM_RELEASE = #8000
	
	atom kernel_dll, memDLL_id, VirtualFree_rid, VirtualQuery_rid,
	VirtualAlloc_rid, VirtualLock_rid, VirtualUnlock_rid, 
	VirtualProtect_rid, GetLastError_rid, GetSystemInfo_rid

	memDLL_id = open_dll( "kernel32.dll" )
	kernel_dll = memDLL_id
	VirtualQuery_rid = define_c_func( memDLL_id, "VirtualQuery", { C_POINTER, C_POINTER, C_UINT }, C_UINT )
	VirtualAlloc_rid = define_c_func( memDLL_id, "VirtualAlloc", { C_POINTER, C_UINT, C_UINT, C_UINT }, C_POINTER )
	VirtualProtect_rid = define_c_func( memDLL_id, "VirtualProtect", { C_POINTER, C_UINT, C_INT, C_POINTER }, C_INT )
	VirtualLock_rid = define_c_func( memDLL_id, "VirtualLock", { C_POINTER, C_UINT }, C_UINT )
	VirtualUnlock_rid = define_c_func( memDLL_id, "VirtualUnlock", { C_POINTER, C_UINT }, C_UINT )
	GetLastError_rid = define_c_func( kernel_dll, "GetLastError", {}, C_UINT )
	GetSystemInfo_rid = define_c_proc( kernel_dll, "GetSystemInfo", { C_POINTER } )
	VirtualFree_rid = define_c_func( kernel_dll, "VirtualFree", { C_POINTER, C_UINT, C_INT }, C_UINT )
		
elsifdef UNIX then
	constant MAP_ANONYMOUS = #20, MAP_PRIVATE = #2
	--,MAP_SHARED = #1, MAP_TYPE = #F, MAP_FIXED = #10,
	--MAP_FILE = 0
	atom getpagesize_rid, mmap_rid, mprotect_rid, munmap_rid,
	mlock_rid, munlock_rid
	
	getpagesize_rid = define_c_func( -1, "getpagesize", { }, C_UINT )
	mmap_rid = define_c_func( -1, "mmap", { C_POINTER, C_UINT, C_INT, C_INT, C_INT, C_INT }, C_POINTER )
	mprotect_rid = define_c_func( -1, "mprotect", { C_POINTER, C_UINT, C_INT }, C_INT )
	munmap_rid = define_c_func( -1, "munmap", { C_POINTER, C_UINT }, C_INT )
	mlock_rid = define_c_func( -1, "mlock", { C_POINTER, C_UINT }, C_INT )
	munlock_rid = define_c_func( -1, "munlock", { C_POINTER, C_UINT }, C_INT )
		
end ifdef

ifdef WIN32 then

function VirtualAlloc( atom addr, atom size, atom flallocationtype, atom flprotect )
	atom r1
	r1 = c_func( VirtualAlloc_rid, {addr, size, flallocationtype, flprotect } )
	return r1
end function

end ifdef

ifdef UNIX then

function mmap( object start, integer length, integer protection, integer flags, integer fd, integer offset )
	atom pc
	if atom( start ) then
		return c_func( mmap_rid, { start, length, protection, flags, fd, offset } )
	else
		pc = mmap( 0, length, protection, flags, fd, offset )
		poke( pc, start )
		return pc
	end if
end function

end ifdef

function mem_const_set( sequence s, sequence hash )
	for i = 1 to length( hash ) do
		s[log(hash[i][1])/log(2)+1] = hash[i][2]
	end for
	return s
end function




function make_constants_table()
	sequence s
	s  =  repeat( PROT_NONE, 10 )
	s = mem_const_set( s, { 
		{ PAGE_EXECUTE_READWRITE, or_bits( PROT_READ, or_bits( PROT_EXEC, PROT_WRITE ) ) },
		{ PAGE_EXECUTE_READ, or_bits( PROT_READ, PROT_EXEC ) },
		{ PAGE_EXECUTE, PROT_EXEC },
		{ PAGE_EXECUTE_WRITECOPY, or_bits( PROT_READ, or_bits( PROT_EXEC, PROT_WRITE ) ) },
		{ PAGE_NOACCESS, PROT_NONE },
		{ PAGE_READONLY, PROT_READ },
		{ PAGE_READWRITE, or_bits( PROT_READ, PROT_WRITE ) },
		{ PAGE_WRITECOPY, or_bits( PROT_READ, PROT_WRITE ) }
	} )	
	return s
end function


type valid_windows_memory_protection_constant( integer x )
	atom value
	value = log(x)/log(2)
	return integer( value ) and (value <= 8) and (value >= 0)
end type

type page_aligned_address( atom a )
	return remainder( a, 4096 ) = 0
end type

constant mem_constants_table = make_constants_table()

function mem_win2linux( valid_windows_memory_protection_constant protection )
	return mem_constants_table[log(protection)/log(2)+1]
end function

--****
-- === Allocating and Writing to memory:

--**
-- Signature: 
-- function allocate_code( sequence a_sequence_of_machine_code_bytes )
--
-- Description:
-- Allocates and copies data into executible memory.
--
-- Parameters:
-- The parameter, ##a_sequence_of_machine_code_bytes##, is the machine code to be put into memory to be later called with [[:call()]]        

-- Return Value:
-- The function returns the address in memory of the byte-code that can be safely executed whether DEP is enabled or not or 0 if it fails.  On the other hand, if you try to execute a code address returned by [[:allocate()]] with DEP enabled the program will receive a machine exception.  

-- Comments:
-- 
-- Use this for the machine code you want to run in memory.  The copying is done for you and when the routine returns the memory may not be readable or writable but it is guaranteed to be executable.  If you want to also write to this memory **after the machine code has been copied** you should use [[:allocate_protect()]] instead and you should read about having memory executable and writable at the same time is a bad idea.  You mustn't use ##free()## on memory returned from this function.  You may instead use ##free_code()## but since you will probably need the code througout the life of your program's process this normally is not necessary.
-- If you want to put only data in the memory to be read and written use [[:allocate]].
-- See Also:
-- [[:allocate]], [[:free_code]], [[:allocate_protect]]
public function allocate_code( sequence data )
	atom addr, oldprotptr
	integer size
	
	size = length(data)

	if not xalloc_loaded() then
		goto "no_dep"
	end if

	ifdef DOS32 then

		goto "no_dep"

	elsifdef WIN32 then
		
		addr = VirtualAlloc( 0, size, or_bits( MEM_RESERVE, MEM_COMMIT ), PAGE_READWRITE )
		oldprotptr = allocate(4) 
		if addr = 0 then
		    return 0
		end if
		poke( addr, data )
		if c_func( VirtualProtect_rid, { addr, size, PAGE_EXECUTE , oldprotptr } ) = 0 then
			-- 0 indicates failure here
			return 0
		end if
		free( oldprotptr )
		return addr
		
	elsifdef UNIX then

		addr = c_func( mmap_rid, { 0, size, PROT_WRITE, or_bits( MAP_PRIVATE, MAP_ANONYMOUS ), 0, 0 } )
		if addr = -1 then
			return 0
		end if
		poke( addr, data )
		if c_func( mprotect_rid, { addr, size, PROT_EXEC } ) != 0 then
			-- non zero indicates failure here
			return 0
		end if
		return addr

	elsedef -- unknown platform.  Return normal memory.

		goto "no_dep"

	end ifdef

	label "no_dep"
	addr = allocate( size )
	if addr = 0 then
		return 0
	end if
	poke( addr, data )
	return addr

end function

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
-- ##allocate_wstring##()  for storing double byte encoded strings.
--
-- There is no allocate_string_low() function. However, you could easily
-- craft one by adapting the code for ##allocate_string##.
--
-- Since ##allocate_string##() allocates memory, you are responsible to
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
public function allocate_string(sequence s)
	atom mem
	
	mem = machine_func(M_ALLOC, length(s) + 1) -- Thanks to Igor
	if mem then
		poke(mem, s)
		poke(mem+length(s), 0)  -- Thanks to Aku
	end if
	return mem
end function


--**
-- Signature:
-- function allocate_protect( sequence data, integer protection )
--
-- Description:
-- Allocates and copies data into memory and gives it protection using [[:Microsoft's Memory Protection Constants]].  The user may only pass in one of these constants.  If you only wish to execute a sequence as machine code use ##allocate_code()##.  If you only want to read and write data into memory use ##allocate()##.

-- See <a href="http://msdn.microsoft.com/en-us/library/aa366786(VS.85).aspx">Microsoft's Memory Protection Constants<br>
-- http://msdn.microsoft.com/en-us/library/aa366786(VS.85).aspx</a><p>

-- Parameters:
-- The first parameter, data, is the machine code to be put into memory. 
--
-- Returns:
-- The function returns the address to the required memory
-- or 0 if it fails.  This function is guaranteed to return memory on 
-- the 4 byte boundary.  It also guarantees that the memory returned with 
-- at least the protection given (but you may get more).
--
-- If you want to call ##allocate_protect( data, PAGE_READWRITE )##, you can use 
-- [[:allocate]] instead.  It is more efficient and simplier.
--
-- If you want to call ##allocate_protect( data, PAGE_EXECUTE )##, you can use 
-- [[:allocate_code()]] instead.  It is more efficient and simplier.
--
-- You mustn't use [[:free()]] on memory returned from this function, instead use [[:free_code()]].
public function allocate_protect( sequence data, valid_windows_memory_protection_constant protection )
	atom addr, oldprotptr
	integer size
	
	size = length(data)

	if not xalloc_loaded() then
		goto "no_dep"
	end if

	ifdef DOS32 then

		goto "no_dep"

	elsifdef WIN32 then

		addr = c_func( VirtualAlloc_rid, { 0, size, or_bits( MEM_RESERVE, MEM_COMMIT ), PAGE_READWRITE } )
		if addr = 0 then
		    return 0
		end if
		oldprotptr = allocate(4)
		if oldprotptr = 0 then
		    return 0
		end if
		poke( addr, data )
		if c_func( VirtualProtect_rid, { addr, size, protection , oldprotptr } ) = 0 then
		    -- 0 indicates failure here
		    return 0
		end if
		free( oldprotptr )
		return addr

	elsifdef UNIX then

		addr = c_func( mmap_rid, { 0, size, PROT_WRITE, or_bits( MAP_PRIVATE, MAP_ANONYMOUS ), 0, 0 } )
		if addr = -1 then
			return 0
		end if
		poke( addr, data )
		if c_func( mprotect_rid, { addr, size, mem_win2linux( protection ) } ) != 0 then
			-- non zero indicates failure in mprotect 			
			return 0
		end if
		return addr

	elsedef

		goto "no_dep"

	end ifdef

	label "no_dep"
	addr = allocate( size )
	if addr = 0 then
		return 0
	end if
	poke( addr, data )

	return addr

	-- Implementation notes:
	--    The amount of memory actually allocated on Windows is the lowest 
	--    multiple of the page_size (4kB on Windows XP)  
	--    The C manuals do not guarantee that the memory RETURNED from 
	--    underlying C-functions are page aligned only but they require 
	--    what you pass into them must be page aligned.  I suspect that 
	--    that is the spirit of the work though.  
end function


-- Undocumented function
function allocate_exec( integer size )
	atom addr
	
	if not xalloc_loaded() then
		goto "no_dep"
	end if

	ifdef DOS32 then

		goto "no_dep"

	elsifdef WIN32 then
		
		addr = VirtualAlloc( 0, size, or_bits( MEM_RESERVE, MEM_COMMIT ), PAGE_READWRITE )
		if addr = 0 then
		    return 0
		end if
		return addr
		
	elsifdef UNIX then

		addr = c_func( mmap_rid, { 0, size, or_bits(PROT_WRITE,PROT_EXEC), or_bits( MAP_PRIVATE, MAP_ANONYMOUS ), 0, 0 } )
		if addr = -1 then
			return 0
		end if
		return addr

	elsedef -- unknown platform.  Return normal memory.

		goto "no_dep"

	end ifdef

	label "no_dep"
	addr = allocate( size )
	if addr = 0 then
		return 0
	end if

	return addr
	
end function




-- new_addr = memory_reprotect( addr, size, protection )
--
-- Changes protection on a segment of memory using MS-Windows style constants.
--
-- The memory should have been returned from allocate_protect or allocate_code.
--
-- The affected region is really:
--        floor( addr / page_size() ) * page_size() .. ceil( (addr+size) / page_size() ) * page_size
-- On an error 0 is returned.  If you ask this function to do what it can't it
-- will return 0.
-- See the memory protection constants at:
--   http://msdn2.microsoft.com/en-us/library/aa366786(VS.85).aspx
--   The idea is to support everything that both mmap and VirtualAlloc can
--   do and no more.
--
--
-- Implementation notes: The memory constants that are less than #100 are supported
-- and you may NOT put two together with or_bits().
-- WARNING: UNTESTED FUNCTION
function memory_reprotect( page_aligned_address addr, integer size, valid_windows_memory_protection_constant protection )
	integer linux_protection
	atom new_addr

	if not xalloc_loaded() then
		return addr
	end if

	ifdef DOS32 then
		if addr = 0 then
			new_addr = allocate( size )
			poke( new_addr, peek( { addr, size } ) )
		else
		    	new_addr = addr
		end if
	elsifdef WIN32 then
		new_addr = VirtualAlloc( addr, size, or_bits( MEM_RESERVE, MEM_COMMIT ), protection )
		poke( new_addr, peek( { addr, size } ) )
	elsifdef UNIX then
		linux_protection = mem_win2linux( protection )
		new_addr = c_func( mmap_rid, { 0, size, linux_protection, 
			or_bits( MAP_PRIVATE, MAP_ANONYMOUS ), 0, 0 } )
		if new_addr = -1 then
			return 0
		end if
	elsedef -- unknown platform
		return 0
	end ifdef

	return new_addr
end function	

ifdef WIN32 then

function memory_protection( atom addr, integer size )
	atom memory_basic_information_ptr
	atom protection
	memory_basic_information_ptr = allocate( 28 )
	if c_func( VirtualQuery_rid, { addr, memory_basic_information_ptr, size } ) < 12 then
		return -1
	end if
	protection = peek4u( memory_basic_information_ptr + 8 )
	free( memory_basic_information_ptr )
	return or_bits( protection, #FF )
end function

end ifdef

public function xalloc_loaded()
	ifdef WIN32 then
		return VirtualAlloc_rid != -1 and VirtualProtect_rid != -1 
			and GetLastError_rid != -1 and GetSystemInfo_rid != -1
	elsifdef UNIX then
		return mmap_rid != -1 and getpagesize_rid != -1
	elsedef
		return 1
	end ifdef
	return 0
end function

--****
-- === Memory disposal
--

--**
-- Signature:
-- procedure free_code( atom addr, integer size )
--
-- Description:
-- frees up allocated code memory
-- Parameters:
-- ##addr## must be an address returned by [[:allocate_code()]] or [[:allocate_protect()]].  Do **not** pass memory returned from [[:allocate()]] here!   
-- The ##size## is the length of the sequence passed to ##alllocate_code()## or the size you specified when you called allocate_protect().                           

-- Comments:
-- Chances are you will not need to call this function because code allocations are typically public scope operations that you want to have available until your process exits.
--
-- See Also: [[:allocate_code]], [[:free]]
public procedure free_code( atom addr, integer size )
	integer free_succeeded
	if not xalloc_loaded() then
		free( addr )
		return
	end if

	ifdef WIN32 then
		free_succeeded = c_func( VirtualFree_rid, { addr, size, MEM_RELEASE } )
	elsifdef UNIX then
		free_succeeded = not c_func( munmap_rid, { addr, size } )
	elsifdef DOS32 then
		free( addr )
	elsedef
		free( addr )
	end ifdef
end procedure


--**
-- Free up a previously allocated block of memory.
-- @[machine:free]
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
--   ##demo/callmach.ex##
--
-- See Also:
--     [[:allocate]], [[:free_low]], [[:free_code]]

public procedure free(machine_addr addr)
-- free the memory at address a
	machine_proc(M_FREE, addr)
end procedure


--****
-- === Reading from, Writing to, and Calling into Memory

--**
-- Signature:
-- <built-in> function peek(object addr_n_length)
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
--
--	Peek()ing in memory you don't own may be blocked by the OS, and cause a
-- machine exception. The safe.e include file can catch this sort of issues.
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
--  [[:poke]], [[:peeks]], [[:peek4u]], [[:allocate]], [[:free]], [[:allocate_low]],
-- [[:free_low]], [[:peek2u]]
--
--**
-- Signature:
-- <built-in> function peeks(object addr_n_length)
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
--
--		An **object**, either an integer if the input was a single address,
-- or a sequence of integers if a sequence was passed. In both cases,
-- integers returned are bytes, in the range -128..127.
--
-- Errors:
--
--	Peek()ing in memory you don't own may be blocked by the OS, and cause
-- a machine exception. The safe.e include file can catch this sort of issues.
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
--  [[:poke]], [[:peek4s]], [[:allocate]], [[:free]], [[:allocate_low]],
-- [[:free_low]], [[:peek2s]], [[peek]]
--
--**
-- Signature:
-- <built-in> function peek2s(object addr_n_length)
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
--
--		An **object**, either an integer if the input was a single address,
-- or a sequence of integers if a sequence was passed. In both cases,
-- integers returned are double words, in the range -32768..32767.
--
-- Errors:
--
--	Peek()ing in memory you don't own may be blocked by the OS, and cause
-- a machine exception. The safe.e i,clude file can catch this sort of issues.
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
--  [[:poke2]], [[:peeks]], [[:peek4s]], [[:allocate]], [[:free]], [[:allocate_low]],
-- [[:free_low]], [[:peek2u]]
--
--**
-- Signature:
-- <built-in> function peek2u(object addr_n_length)
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
-- s = {peek2u(100), peek2u(102), peek2u(104), peek2u(106)}
--
-- -- method 2
-- s = peek2u({100, 4})
-- </eucode>
-- 
-- See Also: 
--  [[:poke2]], [[:peek]], [[:peek2s]], [[:allocate]], [[:free]], [[:allocate_low]],
-- [[:free_low]], [[:peek4u]]
--
--**
-- Signature:
-- <built-in> function peek4s(object addr_n_length)
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
-- An **object**, either an atom if the input was a single address, or a
-- sequence of atoms if a sequence was passed. In both cases, atoms returned
-- are double words, in the range 0..power(2,32)-1.
--
-- Errors:
-- Peek()ing in memory you don't own may be blocked by the OS, and cause a
-- machine exception. The safe.e i,clude file can catch this sort of issues.
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
-- of peek() than it is to read one double word at a time in a loop. The
-- returned sequence has the length you asked for on input.
-- 
-- Remember that ##peek4s##() takes just one argument, which in the second
-- form is actually a 2-element sequence.
--
-- The only difference between ##peek4s##() and [[peek4u]]() is how double
-- words with the highest bit set are returned. ##peek4s##() assumes them to
-- be negative, while [[peek4u]]() just assumes them to be large and positive.
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
-- [[:poke4]], [[:peeks]], [[:peek4u]], [[:allocate]], [[:free]], [[:allocate_low]],
-- [[:free_low]], [[:peek2s]]
--
--**
-- Signature:
-- <built-in> function peek4u(object addr_n_length)
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
-- When supplying a {address, count} sequence, the count must not be negative.
--
-- Comments: 
--
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
--  [[:poke4]], [[:peek]], [[:peek4s]], [[:allocate]], [[:free]], [[:allocate_low]],
-- [[:free_low]], [[:peek2u]]
--

--**
-- Signature:
-- <built-in> procedure peek_string(atom addr)
--
-- Description:
-- Read an ASCIZ string in RAM, starting from a supplied address.
--
-- Parameters:
-- 		# ##addr#: an atom, the address at whuich to start reading.
--
-- Returns:
-- A **sequence** of bytes, the string that could be read.
--
-- Errors:
-- Further, peek()ing memory that doesn't belong to your process is something the operating
-- system could prevent, and you'd crash with a machine level exception.
--
-- Comments:
--
-- An ASCIZ string is any sequence of bytes and ends with a 0 byte.
-- If you ##peek_string##() at some place where there is no string, you will get a sequence of garbage.
--
-- See Also:
-- [[:peek]], [[:peek_wstring]], [[:allocate_string]]


--**
-- Signature:
-- <built-in> procedure poke(atom addr, object x)
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
--
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
--  ##demo/callmach.ex##
-- 
-- See Also:
-- [[:peek]], [[:peeks]], [[:poke4]], [[:allocate]], [[:free]], [[:poke2]], [[:call]],
-- [[[:mem_copy]]], [[:mem_set]]
-- 
--**
-- Signature:
-- <built-in> procedure poke2(atom addr, object x)
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
--
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
--     [[:peek2s]], [[:peek2u]], [[:poke]], [[:poke4]], [[:allocate]], [[:free]], [[:call]]
--
--**
-- Signature:
-- <built-in> procedure poke4(atom addr, object x)
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
--
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
--     [[:peek4s]], [[:peek4u]], [[:poke]], [[:poke2]], [[:allocate]], [[:free]], [[:call]]
--
--**
-- Signature:
-- <built-in> procedure mem_copy(atom destination, atom origin, integer len)
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

--**
-- Signature:
-- <built-in> procedure mem_set(atom destination, integer byte_value, integer how_many))
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
--**
-- Signature:
-- <built-in> procedure call(atom addr)
--
-- Description:
--  Call a machine language routine which was stored in memory prior.
--
-- Parameters:
--		# ##addr##, an atom, the address at which to transfer execution control.
--
-- Comments:
--
-- The machine code routine must execute a RET instruction #C3 to return
-- control to Euphoria. 
-- The routine should save and restore any registers that it uses.
--
-- You can allocate a block of memory for the routine and then poke in the
-- bytes of machine code using ##allocate_code()##. You might allocate other blocks of memory for data
-- and parameters that the machine code can operate on using ##allocate()##. The addresses of these
-- blocks could be part of the machine code.
--
-- If your machine code uses the stack, use ##c_proc##() instead of ##call##().
--
-- Example 1: 
--		##demo/callmach.ex##
--
-- See Also:
-- 		[[:allocate_code]], [[:free_code]], [[:c_proc]], [[:define_c_proc]]

without warning
integer check_calls = 1
--****
-- === Safe memory access

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
-- switching between the normal and debu version of the library.
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

public procedure register_block(atom block_addr, atom block_len)
	-- NOP to avoid strict lint
	block_addr = block_addr
	block_len = block_len
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
--   [[:register_block]], [[safe.e]]

public procedure unregister_block(atom block_addr)
	-- NOP to avoid strict lint
	block_addr =  block_addr
end procedure

--**
-- Scans the list of registered blocks for any corruption.
--
-- Comments:
--
-- safe.e maintains a list of acquired memory blocks. Those gained through
-- allocate() or allocate_low() are automatically included. Any other block,
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

public procedure check_all_blocks()
end procedure
with warning
