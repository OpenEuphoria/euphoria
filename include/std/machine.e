--****
-- == Machine Level Access
--
-- <<LEVELTOC level=2 depth=4>>
-- ==== Marchine Level Access Summary
-- Warning: Some of these routines require a knowledge of
-- machine-level programming. You could crash your system!
--
-- These routines, along with [[:peek]], [[:poke]] and [[:call]], let you access all
-- of the features of your computer.  You can read and write to any allowed memory
-- location, and you can create and execute machine code subroutines.
--
-- If you are manipulating 32-bit addresses or values, remember to use
-- variables declared as atom. The integer type only goes up to 31 bits.
--
-- If you choose to call ##machine_proc## or ##machine_func## directly (to save
-- a bit of overhead) you *must* pass valid arguments or Euphoria could crash.
--
-- Some example programs to look at:
--   * ##demo/callmach.ex##      ~-- calling a machine language routine
--

namespace machine

public include std/memconst.e

ifdef SAFE then
	--**
	-- @nodoc@
	public include std/safe.e as memory
elsedef
	--**
	-- @nodoc@
	public include std/memory.e as memory
end ifdef

include std/dll.e
include std/error.e
include std/types.e

integer FREE_ARRAY_RID

-- The number of bytes required to hold a pointer.  Documented later...
ifdef EU4_0 then
	--**
	-- @nodoc@
	public constant ADDRESS_LENGTH = 4
elsedef
	--**
	-- @nodoc@
	public constant ADDRESS_LENGTH = sizeof( dll:C_POINTER )
end ifdef

ifdef EU4_0 then
	include std/math.e

	--**
	-- @nodoc@
	public procedure poke8(atom address, object x)
		if atom(x) then
			x = {x}
		end if
		address -= 8
		for i = 1 to length(x) do
			-- put less significant bits.
			poke4(address+i*8,and_bits(#FFFF_FFFF,x[i]))
			
			if x[i] > 0 then
				poke4(address+i*8+4,floor(x[i]/#1_0000_0000))
			else
				poke4(address+i*8+4,floor(x[i]/#1_0000_0000))
			end if
		end for
	end procedure


	--**
	-- @nodoc@
	public procedure poke_pointer(atom address, object x)
		poke4(address,x)
	end procedure


	--**
	-- @nodoc@
	public function peek8s(object address)
		integer count = 1
		integer atom_flag = atom(address)
		if sequence(address) then
			count = address[2]
			address = address[1]
		end if
		sequence sout = peek4s({address,2*count})
		sequence uout = peek4u({address,2*count})
		sequence out = repeat(0,count)
		for i = 1 to count do
			out[i] = sout[2*i] * #1_0000_0000 + uout[2*i-1]
		end for
		if atom_flag then
			return out[1]
		end if
		return out
	end function


	--**
	-- @nodoc@
	public function peek8u(object address)
		integer count = 1
		integer atom_flag = atom(address)
		if sequence(address) then
			count = address[2]
			address = address[1]
		end if
		sequence out = peek4u({address,count*2})
		for i = 1 to length(out) by 2 do
			out[floor((i+1)/2)] = out[i+1] * #1_0000_0000 + out[i]
		end for
		out = out[1..count]
		if atom_flag then
			return out[1]
		end if
		return out
	end function


	--**
	-- @nodoc@
	public function peek_pointer(object x)
		return peek4u(x)
	end function

	--**
	-- @nodoc@
	public procedure poke_long(atom address, object x)
		poke4( address, x )
	end procedure

	--**
	-- @nodoc
	public function peek_longs(object x)
		return peek4s( x )
	end function

	--**
	-- @nodoc@
	public function peek_longu(object x)
		return peek4u( x )
	end function

		
end ifdef


ifdef not WINDOWS then

ifdef FREEBSD then
	constant MMAP_OFFSET_SIZE = dll:C_LONGLONG
elsedef
	constant MMAP_OFFSET_SIZE = dll:C_LONG
end ifdef

include std/dll.e
--**
-- @nodoc@
export constant
	--**
	-- @nodoc@
	STDLIB   = dll:open_dll({ "libc.so", "libc.dylib", "" }),
	--**
	-- @nodoc@
	MMAP     = dll:define_c_func( STDLIB, "mmap", 
				{dll:C_POINTER, dll:C_LONG, dll:C_INT, dll:C_INT, dll:C_INT, MMAP_OFFSET_SIZE}, 
				dll:C_POINTER ),
	--**
	-- @nodoc@
	MUNMAP   = dll:define_c_func( STDLIB, "munmap", {dll:C_POINTER, dll:C_LONG}, dll:C_INT ),
	--**
	-- @nodoc@
	MPROTECT = dll:define_c_func( STDLIB, "mprotect", {dll:C_POINTER, dll:C_LONG, dll:C_INT}, dll:C_INT),
	--**
	-- @nodoc@
	MAP_PRIVATE   = 2,
	$

    ifdef OSX or BSD then
        --**
        -- @nodoc@
        export constant MAP_ANONYMOUS = 0x1000
    elsedef
        export constant MAP_ANONYMOUS = 32
    end ifdef
    
    ifdef LINUX or FREEBSD then
		export constant MAP_FAILED = power(256,ADDRESS_LENGTH)-1
    end ifdef
end ifdef

--**
-- === Safe Mode

--****
-- ==== Safe Mode Summary
--
-- During the development of your application, you can define the word ##SAFE## to cause
-- ##machine.e## to use alternative memory functions. These functions are slower but
-- help in the debugging stages. In general, ##SAFE## mode should not be enabled during
-- production phases but only for development phases.
--
-- To define the word ##SAFE## run your application with the ##-D SAFE## command line
-- option, or add to the top of your main file~:
--
-- <eucode>
-- with define safe
-- </eucode>
-- before the first appearance of 
-- ##include std/machine.e##
--
-- The implementation of the Machine Level Access routines used are controled 
-- with the define word ##SAFE##.
-- The use of ##SAFE## switches the routines included here to use debugging versions
-- which will allow you to catch all kinds of bugs that might otherwise may not 
-- always crash your program where in the line your program is written.  
-- There may be bugs that are invisible until you port the program they are in to 
-- another platform.  There has been no bench marking for how much of a speed penalty
-- there is using ##SAFE##.
--
--
-- You can take advantage of ##SAFE## debugging by:
--
-- *  If necessary, call [[:register_block]](address, length, memory_protection) to add additional
--    "external" blocks of memory to the safe_address_list. These are blocks 
--    of memory that are safe to use but which you did not acquire 
--    through Euphoria's [[:allocate]], [[:allocate_data]], [[:allocate_code]] or [[:allocate_protect]],
--    [[:allocate_string]], [[:allocate_wstring]]. Call 
--    [[:unregister_block]](address) when you want to prevent further access to 
--    an external block.  When ##SAFE## is not enabled these functions will do nothing
--    and will be converted into nothing by the inline code in the front-end.
--
-- *  You will be notified if memory that you haven't allocated is accessed, 
--    or if memory is freed twice, or if memory is used in the wrong way.  Your
--    application will can be ready for D.E.P. enabled systems even if the system you 
--    test on doesn't have D.E.P..
--
-- *  If a bug is caught, you will hear some "beep" sounds.
--    Press Enter to clear the screen and see the error message. 
--    There will be a descriptive crash message and a traceback in ex.err 
--    so you can find the statement that is making the illegal memory access.
--
--

--****
-- ==== check_calls
-- Define block checking policy.
-- <eucode>
-- include std/machine.e
-- public integer check_calls
-- </eucode>
--
-- Comments:
--
-- If this integer is 1, (the default), check all blocks for edge corruption after each
-- [[:Executable Memory]], [[:call]], [[:c_proc]] or [[:c_func]].
-- To save time, your program can turn off this checking by setting check_calls to 0.

--****
-- ==== edges_only
-- <eucode>
-- include std/machine.e
-- public integer edges_only
-- </eucode>
-- Determine whether to flag accesses to remote memory areas.
--
-- Comments:
--
-- If this integer is 1 (the default under //Windows//), only check for references to the 
-- leader or trailer areas just outside each registered block, and don't complain about 
-- addresses that are far out of bounds (it's probably a legitimate block from another source)
--
-- For a stronger check, set this to 0 if your program will never read/write an 
-- unregistered block of memory.
--
-- On //Windows// people often use unregistered blocks.  Please do not be one of them.

--****
-- ==== check_all_blocks
-- <eucode>
-- include std/machine.e
-- check_all_blocks()
-- </eucode>
--
-- Scans the list of registered blocks for any corruption.
--
-- Comments:
--
-- safe.e maintains a list of acquired memory blocks. Those gained through
-- ##allocate## are automatically included. Any other block,
-- for debugging purposes, must be registered by [[:register_block]]
-- and unregistered by [[:unregister_block]].
--
-- The list is scanned and, if any block shows signs of corruption, it is
-- displayed on the screen and the program terminates. Otherwise, nothing
-- happens.
--
-- Unless ##SAFE## is defined, this routine does nothing. It is there to make switching
-- between debugged and normal version of your program easier.
--
-- See Also:
-- [[:register_block]], [[:unregister_block]]

--****
-- ==== register_block
-- <eucode>
-- include std/machine.e
-- procedure register_block(machine_addr block_addr, positive_int block_len, 
--             valid_memory_protection_constant memory_protection = PAGE_READ_WRITE )
-- </eucode>
-- Description: 
-- Adds a block of memory to the list of safe blocks maintained
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
-- [[:peek]], [[:poke]], [[:mem_copy]] etc. These are normally just the
-- blocks that you have allocated using Euphoria's [[:allocate]] 
-- routine, and which you have not yet freed using
-- Euphoria's [[:free]]. In some cases, you may acquire
-- additional, external, blocks of memory, perhaps as a result of calling a
-- C routine. 
--
-- If you are debugging your program using ##safe.e##, you must register these
-- external blocks of memory or ##safe.e## will prevent you from accessing them.
-- When you are finished using an external block you can unregister it using
-- ##unregister_block##.
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
--   [[:unregister_block]], [[:Safe Mode]]

--****
-- ==== unregister_block
-- <eucode>
-- include std/machine.e
-- public procedure unregister_block(machine_addr block_addr)
-- </eucode>
-- removes a block of memory from the list of safe blocks maintained by safe.e
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
-- [[:register_block]]. By unregistering a block, you remove it from the
-- list of safe blocks maintained by safe.e. This prevents your program from
-- performing any further reads or writes of memory within the block.
--
--  See [[:register_block]] for further comments and an example.
-- 
-- See Also:
--   [[:register_block]], [[:Safe Mode]]

--****
-- === Data Execute Mode and Data Execute Protection
-- 
-- ##Data Execute Mode## makes data that will be returned from [[:allocate]] executable.  On some
-- systems you will not be allowed to run code in memory returned from [[:allocate]] unless this mode has been enabled.   This restriction is called Data Execute Protection or D.E.P..  When writing software you should use [[:allocate_code]] or [[:allocate_protect]] to get memory for execution.  This is more efficient and more secure than using ##Data Execute mode##.  Because many hacker exploits of software use data buffers and then trick software into running this data, Data Execute Protection stops an entire class of exploits.
--
-- If you get a Data Execute Protection Exception from running software, it means that D.E.P. could have thwarted an attack!  Your application crashes and your computer wasn't infected.  However, many people will decide that they want to disable D.E.P. because they know that they call memory returned by [[:allocate]] or perhaps they are simply careless.

--  Though, it is better to change these applications to use [[:allocate_code]] for executable memory but you can disable D.E.P. for the Interpreter in your Control Panel in Windows but if you do that all of your Interpreted Euphoria applications would no longer benefit from D.E.P..  It exposes you a lot less to use only disable D.E.P. on the command line on a per-application basis.  Using ##-D DATA_EXECUTE## or 
-- <eucode>
-- with define DATA_EXECUTE
-- </eucode>
--
-- To enable ##Data Execute mode## define the word ##DATA_EXECUTE## using 
-- the ##-D DATA_EXECUTE## command line option.
--

--**** 
-- === Type Sorted Function List
--

--****
-- ==== Executable Memory
-- Executable Memory is the way to run code on the stack in a completly portable way.
-- 
-- Use the following Routines:
-- Use [[:allocate_code]] to allocate some executable machine-code,
-- [[:call]] to call the code,
-- and [[:free_code]] to free the machine-code.
--

--****
-- ====Using Data Bytes
-- In C, bytes are called 'char' or 'BOOL' or 'boolean'.  They sometimes are used for very small numbers but mostly, they are used in C-strings.
-- See [[:Using Strings]].
-- 
-- Use [[:allocate_data]] to allocate data and return an address.
-- Use [[:poke]] to save atoms or sequences to at an address.
-- Use [[:peeks]] or [[:peek]] to read from an address.
-- Use [[:mem_set]] and [[:mem_copy]] to set and copy sections of memory.
-- Use [[:free]] to free or use [[:delete]] if you enabled ##cleanup## in [[:allocate_data]].


--****
-- ==== Using Data Words
-- Words are 16-bit integers and are big enough to hold most integers in common use as far as whole numbers go.  So they often are used to hold numbers.  In C, they are declared as WORD or short.
--
-- Use [[:allocate_data]] to allocate data and return its address.
-- Use [[:poke2]] to write to the data at an address.
-- Use [[:peek2]] or [[:peek2s]] to read from an address.
-- Use [[:free]] to free or use [[:delete]] if you enabled ##cleanup## in [[:allocate_data]].

--****
-- ==== Using Data Double Words
-- 
-- Double words are 32-bit integers.  In C, they are typically declared as int, or long
-- (on Windows and other 32-bit architectures), or DWORD.  They
-- are big enough to hold pointers to other values in memory on 32-bit architectures.
--
-- Use [[:allocate_data]] to allocate data and return its address.
-- Use [[:poke4]] to write to the data at an address.
-- Use [[:peek4]] or [[:peek4s]] to read from an address.
-- Use [[:free]] to free or use [[:delete]] if you enabled ##cleanup## in [[:allocate_data]].

--****
-- ==== Using Data Quad Words
--
-- Quad words are 64-bit integers.  In C, they are typically declared as long long int,
-- or long int (on 64-bit architectures other than Windows).  They
-- are big enough to hold pointers to other values in memory on 64-bit architectures.
--
-- Use [[:allocate_data]] to allocate data and return its address.
-- Use [[:poke8]] to write to the data at an address.
-- Use [[:peek8u]] or [[:peek8s]] to read from an address.
-- Use [[:free]] to free or use [[:delete]] if you enabled ##cleanup## in [[:allocate_data]].
--

--****
-- ==== Using Pointers
--
-- A Euphoria atom should be used to store pointer values.  On 32-bit architectures,
-- pointers may be larger than a Euphoria integer.  On 64-bit architectures, a
-- Euphoria integer is large enough to hold pointer values, since current 64-bit
-- architectures use only a 48-bit memory space
--
-- To portably peek and poke pointers, you should use [[:peek_pointer]] and
-- [[:poke_pointer]].  These routines automatically detect the architecture
-- and use the correct size for a pointer.

--****
-- ==== Using Long Integers
--
-- When interfacing with C code, some data will be defined as ##long## or ##long int##.
-- This data type can be tricky to use in a portable manner, due to the way that different
-- architectures and operating systems define it.
--
-- On all 32-bit architectures on which Euphoria runs, a ##long int## is defined as 32-bits.
-- On 64-bit Windows, a ##long int## is also 32-bits.  However, on other 64-bit operating
-- systems, a ##long int## is defined as 64-bits.
--
-- To portably peek and poke ##long int## data, you should use [[:peek_longs]], [[:peek_longu]]
-- and [[:poke_long]].  You can also use ##sizeof( C_LONG )## to determine the size (in bytes)
-- of a native ##long int##.


--****
-- ====  Using Strings
-- 
-- You can create legal ANSI and 16-bit UNICODE Strings with these routines.  In C, strings are often declared
-- as some pointer to a character:  char * or wchar *.
--
-- Microsoft Windows uses 8-bit ANSI and 16-bit UNICODE in its routines.
--
-- Use [[:allocate_string]] or [[:allocate_wstring]] to allocate a string pointer.
-- Use [[:peek_string]], [[:peek_wstring]], [[:peek4]], to read from memory byte strings, word strings and double word strings repsectively.
-- Use [[:poke]], [[:poke2]], or [[:poke4]] to write to memory byte strings, word strings and double word strings.
-- Use [[:free]] to free or use [[:delete]] if you enabled ##cleanup## in [[:allocate_data]].


--****
-- ====  Using Pointer Arrays
--
-- Use [[:allocate_string_pointer_array]] to allocate a string array from a sequence of strings.  Use [[:allocate_pointer_array]] to allocate and then write to an array for pointers . 
-- Use [[:free_pointer_array]] to deallocate or use [[:delete]] if you enabled ##cleanup## in [[:allocate_data]].


---****
-- ==== Using non-Memory Objects
--
-- Use call the ##new## routine belonging to the module and you normally don't need to 
-- free it.  You may use [[:delete]] to call its destructors explicitly.  It will be freeed 
-- automatically when the variable becomes unused.  For creating new objects
-- you can associate a destructor with [[:delete_routine]].
--



--****
-- === Memory Allocation
--

--**
-- This does the same as [[:allocate_data]] but allows the DATA_EXECUTE defined word
-- to cause it to return executable memory.
--
-- See Also:
-- [[:allocate_data]], [[:allocate_code]], [[:free]] 
public function allocate( memory:positive_int n, types:boolean cleanup = 0)
-- allocate memory block and add it to safe list
	atom iaddr --machine_addr iaddr
	atom eaddr	
	ifdef DATA_EXECUTE then
		-- high level call:  No need to add BORDER_SPACE*2 here.
		eaddr = machine:allocate_protect( n, 1, PAGE_READ_WRITE_EXECUTE )
	elsedef	
		iaddr = eu:machine_func( memconst:M_ALLOC, n + memory:BORDER_SPACE * 2)
		eaddr = memory:prepare_block( iaddr, n, PAGE_READ_WRITE )
	end ifdef
	if cleanup then
		eaddr = delete_routine( eaddr, memconst:FREE_RID )
	end if
	return eaddr
end function


--**
-- Allocate a contiguous block of data memory.
--
-- Parameters:
--   # ##n## : a positive integer, the size of the requested block.
--   # ##cleanup## : an integer, if non-zero, then the returned pointer will be
--     automatically freed when its reference count drops to zero, or
--     when passed as a parameter to [[:delete]].
--
-- Returns:
--   An **atom**, the address of the allocated memory or 0 if the memory
--   can't be allocated. **NOTE** you must use either an atom or object to
--   receive the returned value as sometimes the returned memory address is
--   too larger for an integer to hold.
--
-- Comments:
-- * Since ##allocate## acquires memory from the system, it is your responsiblity to 
-- return that memory when your application is done with it. There are two ways to
-- do that - automatically or manually.
-- ** //Automatically// - If the ##cleanup## parameter is non-zero, then the memory
-- is returned when the variable that receives the address goes out of scope **and**
-- is not referenced by anything else. Alternatively you can force it be released by
-- calling the [[:delete]] function.
-- ** //Manually// - If the ##cleanup## parameter is zero, then you must call the
-- [[:free]] function at some point in your program to release the memory back to the system.
-- * When your program terminates, the operating system will reclaim
-- all memory that your applicaiton acquired anyway.
-- * An address returned by this function shouldn't be passed to ##[[:call]]##.
-- For that purpose you should use ##[[:allocate_code]]## instead. 
-- * The address returned will be at least 8-byte aligned.
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
-- [[:Using Data Bytes]], [[:Using Data Words]], [[:Using Data Double Words]], [[:Using Strings]], [[:allocate_code]], [[:free]] 

public function allocate_data( memory:positive_int n, types:boolean cleanup = 0)
-- allocate memory block and add it to safe list
	memory:machine_addr a
	bordered_address sla
	a = eu:machine_func( memconst:M_ALLOC, n+BORDER_SPACE*2)
	sla = memory:prepare_block(a, n, PAGE_READ_WRITE )
	if cleanup then
		return delete_routine( sla, memconst:FREE_RID )
	else
		return sla
	end if
end function


--**
-- Allocate a NULL terminated pointer array.
--
-- Parameters:
--   # ##pointers## : a sequence of pointers to add to the pointer array.
--   # ##cleanup## : an integer, if non-zero, then the returned pointer will be
--     automatically freed when its reference count drops to zero, or
--     when passed as a parameter to [[:delete]]
--
-- Comments:
--   This function adds the NULL terminator.
--
-- Example 1:
-- <eucode>
-- atom pa
-- pa = allocate_pointer_array({ allocate_string("1"), allocate_string("2") })
-- </eucode>
--
-- See Also:
--   [[:Using Pointer Arrays]], [[:allocate_string_pointer_array]], [[:free_pointer_array]]

public function allocate_pointer_array(sequence pointers, types:boolean cleanup = 0)

    atom pList
	integer len = length(pointers) * ADDRESS_LENGTH
	
    pList = allocate( (len + ADDRESS_LENGTH ) )
    poke_pointer(pList, pointers)
    poke_pointer(pList + len, 0)
	if cleanup then
		return delete_routine( pList, FREE_ARRAY_RID )
	end if
    return pList
end function

--**
-- Free a NULL terminated pointers array.
--
-- Parameters:
--   # ##pointers_array## : memory address of where the NULL terminated array exists at.
--
-- Comments:
--   This is for NULL terminated lists, such as allocated by [[:allocate_pointer_array]].
--   Do not call ##free_pointer_array## for a pointer that was allocated to be cleaned
--   up automatically.  Instead, use [[:delete]].
--
-- See Also:
--   [[:allocate_pointer_array]], [[:allocate_string_pointer_array]]

public procedure free_pointer_array(atom pointers_array)
	atom saved = pointers_array
	atom ptr

	while ptr with entry do
		memory:deallocate( ptr )
		pointers_array += ADDRESS_LENGTH
		
	entry
		ptr = peek_pointer(pointers_array)
	end while

	free(saved)
end procedure
FREE_ARRAY_RID = routine_id("free_pointer_array")

--**
-- Allocate a C-style null-terminated array of strings in memory
--
-- Parameters:
--   # ##string_list## : sequence of strings to store in RAM.
--   # ##cleanup## : an integer, if non-zero, then the returned pointer will be
--     automatically freed when its reference count drops to zero, or
--     when passed as a parameter to [[:delete]]
--
-- Returns:
--   An **atom**, the address of the memory block where the string pointer
--   array was stored.
--
-- Example 1:
-- <eucode>
-- atom p = allocate_string_pointer_array({ "One", "Two", "Three" })
-- -- Same as C: char *p = { "One", "Two", "Three", NULL };
-- </eucode>
--
-- See Also:
--   [[:Using Pointer Arrays]], [[:free_pointer_array]]

public function allocate_string_pointer_array(object string_list, types:boolean cleanup = 0)
	for i = 1 to length(string_list) do
		string_list[i] = allocate_string(string_list[i])
	end for

	if cleanup then
		return delete_routine( allocate_pointer_array(string_list), FREE_ARRAY_RID )
	else
		return allocate_pointer_array(string_list)
	end if
end function

--**
-- Create a C-style null-terminated wchar_t string in memory
--
-- Parameters:
--   # ##s## : a unicode (utf16) string
--
-- Returns:
--   An **atom**, the address of the allocated string, or 0 on failure.
--
-- See Also:
-- [[:Using Strings]], [[:allocate_string]]
--
public function allocate_wstring(sequence s, types:boolean cleanup = 0 )
	atom mem
	
	mem = allocate( 2 * (length(s) + 1) )
	if mem then
		poke2(mem, s)
		poke2(mem + length(s)*2, 0)
		if cleanup then
			mem = delete_routine( mem, memconst:FREE_RID )
		end if
	end if
	
	return mem
end function


--****
-- === Reading from Memory


--****
-- Signature:
-- <built-in> function peek(object addr_n_length)
--
-- Description:
-- fetches a byte, or some bytes, from an address in memory.
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
-- Since addresses are 32-bit numbers on 32-bit architectures, they can be larger than the largest
-- value of type integer (31-bits). Variables that hold an address should 
-- therefore be declared as atoms.
--
-- It is faster to read several bytes at once using the second form of ##peek##
-- than it is to read one byte at a time in a loop. The returned sequence has
-- the length you asked for on input.
-- 
-- Remember that ##peek## takes just one argument, which in the second form
-- is actually a 2-element sequence.
--  
-- Example 1: 
-- <eucode>
-- -- The following are equivalent:
-- -- first way
-- s = {peek(100), peek(101), peek(102), peek(103)}
-- 
-- -- second way
-- s = peek({100, 4})
-- </eucode>
-- 
-- See Also: 
--  [[:Using Data Bytes]], [[:poke]], [[:peeks]], [[:peek4u]], [[:allocate]], [[:free]],
--  [[:peek2u]]
--

--****
-- Signature:
-- <built-in> function peeks(object addr_n_length)
--
-- Description:
-- fetches a byte, or some bytes, from an address in memory.
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
-- [[:peek | Peeking]] in memory you do not own may be blocked by the OS, and cause
-- a machine exception. If you use the define safe these routines will catch these problems with a Euphoria error.
--
-- When supplying a {address, count} sequence, the count must not be negative.
--
-- Comments: 
--
-- Since addresses are 32-bit numbers on 32-bit architectures, they can be larger than the largest
-- value of type integer (31-bits). Variables that hold an address should
-- therefore be declared as atoms.
--
-- It is faster to read several bytes at once using the second form of ##peek##
-- than it is to read one byte at a time in a loop. The returned sequence has
-- the length you asked for on input.
-- 
-- Remember that ##peeks## takes just one argument, which in the second
-- form is actually a 2-element sequence.
--  
-- Example 1:
--
-- <eucode>
-- -- The following are equivalent:
-- -- first way
-- s = {peeks(100), peek(101), peek(102), peek(103)}
-- 
-- -- second way
-- s = peeks({100, 4})
-- </eucode>
-- 
-- See Also:
--
--  [[:Using Data Bytes]], [[:poke]], [[:peek4s]], [[:allocate]], [[:free]], 
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
-- When supplying a ##{address, count}## sequence, the count must not be negative.
--
-- Comments: 
-- Since addresses are 32-bit numbers on 32-bit architectures, they can be larger than the largest
-- value of type integer (31-bits). Variables that hold an address should
-- therefore be declared as atoms.
--
-- It is faster to read several words at once using the second form of ##peek##
-- than it is to read one word at a time in a loop. The returned sequence has
-- the length you asked for on input.
-- 
-- Remember that ##peek2s## takes just one argument, which in the second
-- form is actually a 2-element sequence.
--
-- The only difference between ##peek2s## and ##peek2u## is how words
-- with the highest bit set are returned. ##peek2s## assumes them to be
-- negative, while ##peek2u## just assumes them to be large and positive.
--  
-- Example 1: 
--
-- <eucode>
-- -- The following are equivalent:
-- -- first way
-- s = {peek2s(100), peek2s(102), peek2s(104), peek2s(106)}
--
-- -- second way
-- s = peek2s({100, 4})
-- </eucode>
-- 
-- See Also:
--
--  [[:Using Data Words]], [[:poke2]], [[:peeks]], [[:peek4s]], [[:allocate]], [[:free]]
--  [[:peek2u]]
--

--****
-- Signature:
-- <built-in> function peek2u(object addr_n_length)
--
-- Description:
-- fetches an //unsigned// word, or some //unsigned// words, from an address
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
--      Peeking in memory you do not own may be blocked by the OS, and cause a
-- machine exception. If you use the define safe these routines will catch these problems with a Euphoria error.
--
-- When supplying a ##{address, count}## sequence, the count must not be negative.
--
-- Comments: 
--
-- Since addresses are 32-bit numbers on 32-bit architectures, they can be larger than the largest
-- value of type integer (31-bits). Variables that hold an address should
-- therefore be declared as atoms.
--
-- It is faster to read several words at once using the second form of ##peek##
-- than it is to read one word at a time in a loop. The returned sequence has
-- the length you asked for on input.
-- 
-- Remember that ##peek2u## takes just one argument, which in the second
-- form is actually a 2-element sequence.
--
-- The only difference between ##peek2s## and ##peek2u## is how words
-- with the highest bit set are returned. ##peek2s## assumes them to be
-- negative, while ##peek2u## just assumes them to be large and positive.
--  
-- Example 1: 
-- <eucode>
-- -- The following are equivalent:
-- -- first way
-- Get 4 2-byte numbers starting address 100.
-- s = {peek2u(100), peek2u(102), peek2u(104), peek2u(106)}
--
-- -- second way
-- Get 4 2-byte numbers starting address 100.
-- s = peek2u({100, 4})
-- </eucode>
-- 
-- See Also: 
--  [[:Using Data Words]], [[:poke2]], [[:peek]], [[:peek2s]], [[:allocate]], [[:free]]
--  [[:peek4u]]
--

--****
-- Signature:
-- <built-in> function peek4s(object addr_n_length)
--
-- Description:
-- fetches a //signed// double words, or some //signed// double words,
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
-- are double words, in the range -(2^^31^^)..2^^31^^-1.
--
-- Errors:
-- Peeking in memory you don't own may be blocked by the OS, and cause a
-- machine exception. If you use the define safe these routines will catch these problems with a Euphoria error.
--
-- When supplying a ##{address, count}## sequence, the count must not be negative.
--
-- Comments: 
--
-- Since addresses are 32-bit numbers on 32-bit architectures, they can be larger than the largest
-- value of type integer (31-bits). Variables that hold an address should
-- therefore be declared as atoms.
--
-- It is faster to read several double words at once using the second form
-- of ##peek## than it is to read one double word at a time in a loop. The
-- returned sequence has the length you asked for on input.
-- 
-- Remember that ##peek4s## takes just one argument, which in the second
-- form is actually a 2-element sequence.
--
-- The only difference between ##peek4s## and [[:peek4u]] is how double
-- words with the highest bit set are returned. ##peek4s## assumes them to
-- be negative, while [[:peek4u]] just assumes them to be large and positive.
--
-- Example 1:
-- <eucode>
-- -- The following are equivalent:
-- -- first way
-- s = {peek4s(100), peek4s(104), peek4s(108), peek4s(112)}
--
-- -- second way
-- s = peek4s({100, 4})
-- </eucode>
-- 
-- See Also: 
-- [[:Using Data Double Words]], [[:poke4]], [[:peeks]], [[:peek4u]], [[:allocate]], [[:free]],
-- [[:peek2s]]
--

--****
-- Signature:
-- <built-in> function peek8s(object addr_n_length)
--
-- Description:
-- fetches a //signed// quad words, or some //signed// quad words,
-- from an address in memory.
--
-- Parameters:
--   # ##addr_n_length## : an object, either of
--   ** an atom ##addr## ~-- to fetch one double word at ##addr##, or
--   ** a pair ##{ addr, len }## ~-- to fetch ##len## quad words at ##addr##
--
-- Returns:
-- An **object**, either an atom if the input was a single address, or a
-- sequence of atoms if a sequence was passed. In both cases, atoms returned
-- are quad words, in the range -power(2,63)..power(2,63)-1.
--
-- Errors:
-- Peeking in memory you don't own may be blocked by the OS, and cause a
-- machine exception. If you use the define safe these routines will catch these problems with a Euphoria error.
--
-- When supplying a ##{address, count}## sequence, the count must not be negative.
--
-- Comments:
--
-- Since addresses are 32-bit numbers on 32-bit architectures, they can be larger than the largest
-- value of type integer (31-bits). Variables that hold an address should
-- therefore be declared as atoms.
--
-- It is faster to read several quad words at once using the second form
-- of ##peek## than it is to read one quad word at a time in a loop. The
-- returned sequence has the length you asked for on input.
--
-- Remember that ##peek8s## takes just one argument, which in the second
-- form is actually a 2-element sequence.
--
-- The only difference between ##peek8s## and [[:peek8u]] is how quad
-- words with the highest bit set are returned. ##peek4s## assumes them to
-- be negative, while [[:peek4u]] just assumes them to be large and positive.
--
-- Example 1:
-- <eucode>
-- -- The following are equivalent:
-- -- first way
-- s = {peek8s(100), peek8s(108), peek8s(116), peek8s(124)}
--
-- -- second way
-- s = peek8s({100, 4})
-- </eucode>
--
-- See Also:
-- [[:Using Data Double Words]], [[:poke4]], [[:peeks]], [[:peek4u]], [[:allocate]], [[:free]],
-- [[:peek2s]]
--

--****
-- Signature:
-- <built-in> function peek_longs(object addr_n_length)
--
-- Description:
-- fetches a //signed// integer, or some //signed// integers,
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
-- are based on the native size of a "long int."  On //Windows// and all other 32-bit
-- architectures, the number will be in the range -power(2,31)..power(2,31)-1.
-- On other 64-bit architectures, the number will be in the range of
-- -power(2,63)..power(2,63)-1.
--
-- Errors:
-- Peeking in memory you do not own may be blocked by the OS, and cause a
-- machine exception. If you use the define safe these routines will catch these problems with a Euphoria error.
--
-- When supplying a ##{address, count}## sequence, the count must not be negative.
--
-- Comments:
--
-- Since addresses are 32-bit numbers on 32-bit architectures, they can be larger than the largest
-- value of type integer (31-bits). Variables that hold an address should
-- therefore be declared as atoms.
--
-- It is faster to read several double words at once using the second form
-- of ##peek## than it is to read one double word at a time in a loop. The
-- returned sequence has the length you asked for on input.
--
-- Remember that ##peek_longs## takes just one argument, which in the second
-- form is actually a 2-element sequence.
--
-- The only difference between ##peek_long## and [[:peek_longu]] is how
-- integers with the highest bit set are returned. ##peek_longs## assumes them to
-- be negative, while [[:peek_longu]] just assumes them to be large and positive.
--
-- Example 1:
-- <eucode>
-- -- The following are equivalent (on a 32-bit architecture, or Windows):
-- -- first way
-- s = {peek_longs(100), peek_longs(104), peek_longs(108), peek_longs(112)}
--
-- -- second way
-- s = peek_longs({100, 4})
-- </eucode>
--
-- See Also:
--  [[:Using Data Double Words]], [[:poke4]], [[:peek]], [[:peek4s]], [[:allocate]], [[:free]], [[:peek2u]],
--  [[:peek2s]], [[:peek8u]], [[:peek8s]], [[:peek_longu]], [[:poke_long]]
--

--****
-- Signature:
-- <built-in> function peek4u(object addr_n_length)
--
-- Description:
-- fetches an //unsigned// double word, or some //unsigned// double words,
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
-- returned are double words, in the range 0..2^^32^^-1. 
--
-- Errors:
--      Peeking in memory you do not own may be blocked by the OS, and cause
-- a machine exception. If you use the define safe these routines will catch these problems with a Euphoria error.
--
-- When supplying a ##{address, count}## sequence, the count must not be negative.
--
-- Comments: 
--
-- Since addresses are 32-bit numbers on 32-bit architectures, they can be larger than the largest
-- value of type integer (31-bits). Variables that hold an address should
-- therefore be declared as atoms.
--
-- It is faster to read several double words at once using the second form 
-- of ##peek## than it is to read one double word at a time in a loop. The
-- returned sequence has the length you asked for on input.
-- 
-- Remember that ##peek4u## takes just one argument, which in the second
-- form is actually a 2-element sequence.
--
-- The only difference between ##peek4s## and ##peek4u## is how double
-- words with the highest bit set are returned. ##peek4s## assumes them
-- to be negative, while ##peek4u## just assumes them to be large and
-- positive.
--  
-- Example 1: 
-- <eucode>
-- -- The following are equivalent:
-- -- first way
-- s = {peek4u(100), peek4u(104), peek4u(108), peek4u(112)}
--
-- -- second way
-- s = peek4u({100, 4})
-- </eucode>
-- 
-- See Also: 
--  [[:Using Data Double Words]], [[:poke4]], [[:peek]], [[:peek4s]], [[:allocate]], [[:free]], [[:peek2u]]
--

--****
-- Signature:
-- <built-in> function peek8u(object addr_n_length)
--
-- Description:
-- fetches an //unsigned// quad word, or some //unsigned// quad words,
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
-- returned are quad words, in the range 0..power(2,64)-1.
--
-- Errors:
--      Peeking in memory you do not own may be blocked by the OS, and cause
-- a machine exception. If you use the define safe these routines will catch these problems with a Euphoria error.
--
-- When supplying a ##{address, count}## sequence, the count must not be negative.
--
-- Comments:
--
-- Since addresses are 32-bit numbers on 32-bit architectures, they can be larger than the largest
-- value of type integer (31-bits). Variables that hold an address should
-- therefore be declared as atoms.
--
-- It is faster to read several quad words at once using the second form
-- of ##peek## than it is to read one quad word at a time in a loop. The
-- returned sequence has the length you asked for on input.
--
-- Remember that ##peek8u## takes just one argument, which in the second
-- form is actually a 2-element sequence.
--
-- The only difference between ##peek8s## and ##peek8u## is how quad
-- words with the highest bit set are returned. ##peek8s## assumes them
-- to be negative, while ##peek8u## just assumes them to be large and
-- positive.
--
-- Example 1:
-- <eucode>
-- -- The following are equivalent:
-- --first way
-- s = {peek8u(100), peek8u(108), peek8u(116), peek8u(124)}
--
-- -- second way
-- s = peek8u({100, 4})
-- </eucode>
--
-- See Also:
--  [[:Using Data Double Words]], [[:poke4]], [[:peek]], [[:peek4s]], [[:allocate]], [[:free]], [[:peek2u]]
--

--****
-- Signature:
-- <built-in> function peek_longu(object addr_n_length)
--
-- Description:
-- fetches an //unsigned// integer, or some //unsigned// integers,
-- from an address in memory.
--
-- Parameters:
--              # ##addr_n_length## : an object, either of
--              ** an atom ##addr## ~-- to fetch one double word at ##addr##, or
--              ** a pair {##addr,len}## ~-- to fetch ##len## double words at ##addr##
--
-- Returns:
-- An **object**, either an atom if the input was a single address, or a
-- sequence of atoms if a sequence was passed. In both cases, atoms returned
-- are based on the native size of a "long int."  On //Windows// and all other 32-bit
-- architectures, the number will be in the range 0..power(2,32)-1.
-- On other 64-bit architectures, the number will be in the range of
-- 0..power(2,64)-1.
--
-- Errors:
--      Peeking in memory you do not own may be blocked by the OS, and cause
-- a machine exception. If you use the define safe these routines will catch these problems with a Euphoria error.
--
-- When supplying a ##{address, count}## sequence, the count must not be negative.
--
-- Comments:
--
-- Since addresses are 32-bit numbers on 32-bit architectures, they can be larger than the largest
-- value of type integer (31-bits). Variables that hold an address should
-- therefore be declared as atoms.
--
-- It is faster to read several integers at once using the second form
-- of ##peek## than it is to read one integer at a time in a loop. The
-- returned sequence has the length you asked for on input.
--
-- Remember that ##peek_longu## takes just one argument, which in the second
-- form is actually a 2-element sequence.
--
-- The only difference between ##peek_longs## and ##peek_longu## is how double
-- words with the highest bit set are returned. ##peek4s## assumes them
-- to be negative, while ##peek_longu## just assumes them to be large and
-- positive.
--
-- Example 1:
-- <eucode>
-- -- The following are equivalent (on a 32-bit architecture, or Windows):
-- -- first way
-- s = {peek_longu(100), peek4u(104), peek4u(108), peek4u(112)}
--
-- -- second way
-- s = peek_longu({100, 4})
-- </eucode>
--
-- See Also:
--  [[:Using Data Double Words]], [[:poke4]], [[:peek]], [[:peek4s]], [[:allocate]], [[:free]], [[:peek2u]],
--  [[:peek2s]], [[:peek8u]], [[:peek8s]], [[:peek_longs]], [[:poke_long]]

--****
-- Signature:
-- <built-in> function peek_string(atom addr)
--
-- Description:
-- reads an ASCII string in RAM, starting from a supplied address.
--
-- Parameters:
--              # ##addr## : an atom, the address at which to start reading.
--
-- Returns:
-- A **sequence**, of bytes, the string that could be read.
--
-- Errors:
-- Further, peeking in memory that does not belong to your process is something the operating
-- system could prevent, and you'd crash with a machine level exception.
--
-- Comments:
--
-- An ASCII string is any sequence of bytes and ends with a 0 byte.
-- If you ##peek_string## at some place where there is no string, you will get a sequence of garbage.
-- 
-- See Also:
-- [[:Using Strings]], [[:peek]], [[:peek_wstring]], [[:allocate_string]]

--****
-- Signature:
-- <built-in> function peek_pointer(object addr_n_length)

-- Description:
-- fetches an //unsigned// pointer size integer, or some //unsigned// pointer size integers,
-- from an address in memory.
--
-- Parameters:
--              # ##addr_n_length## : an object, either of
--              ** an atom ##addr## ~-- to fetch one double word at ##addr##, or
--              ** a pair {##addr,len}## ~-- to fetch ##len## pointers at ##addr##
--
-- Returns:
-- An **object**, either an atom if the input was a single address, or a
-- sequence of atoms if a sequence was passed. In both cases, atoms returned
-- are based on the native size of a pointer.  On 32-bit
-- architectures, the number will be in the range 0..power(2,32).
-- On 64-bit architectures, the number will be in the range of
-- 0..power(2,64).
--
-- Errors:
--      Peeking in memory you do not own may be blocked by the OS, and cause
-- a machine exception. If you use the define safe these routines will catch these problems with a Euphoria error.
--
-- When supplying a ##{address, count}## sequence, the count must not be negative.
--
-- Comments:
--
-- Since addresses are 32-bit numbers on 32-bit architectures, they can be larger than the largest
-- value of type integer (31-bits). Variables that hold an address should
-- therefore be declared as atoms.
--
-- It is faster to read several pointers at once using the second form
-- of ##peek_pointer## than it is to read one integer at a time in a loop. The
-- returned sequence has the length you asked for on input.
--
-- Remember that ##peek_pointer## takes just one argument, which in the second
-- form is actually a 2-element sequence.
--
--
-- Example 1:
-- <eucode>
-- -- The following are equivalent (on a 32-bit architecture):
-- -- first way
-- s = {peek_longu(100), peek4u(104), peek4u(108), peek4u(112)}
--
-- -- second way
-- s = peek_pointer({100, 4})
-- </eucode>
--
-- See Also:
--  [[:Using Data Double Words]], [[:poke4]], [[:peek]], [[:peek4s]], [[:allocate]], [[:free]], [[:peek2u]],
--  [[:peek2s]], [[:peek8u]], [[:peek8s]], [[:peek_longs]], [[:poke_long]]


--**
-- returns a unicode (utf16) string that are stored at machine address a.
--
-- Parameters:
--   # ##addr## : an atom, the address of the string in memory
--
-- Returns:
--   The **string**, at the memory position.  The terminator is the null word (two bytes equal to 0).
--
-- See Also:
-- [[:Using Strings]], [[:peek_string]]

public function peek_wstring(atom addr)
	atom ptr = addr
	
	while peek2u(ptr) do
		ptr += 2
	end while
	
	return peek2u({addr, (ptr - addr) / 2})
end function

--****
-- === Writing to Memory


--****
-- Signature:
-- <built-in> procedure poke(atom addr, object x)
--
-- Description:
-- stores one or more bytes, starting at a memory location.
--
-- Parameters:
--              # ##addr## : an atom, the address at which to store
--              # ##x## : an object, either a byte or a non empty sequence of bytes.
--
-- Errors:
--      Poking in memory you do not own may be blocked by the OS, and cause a
-- machine exception. The ##-D SAFE## option will make ##poke## catch this sort of issues.
--
-- Comments:
--
-- The lower 8-bits of each byte value (such as ##remainder(x, 256)##) is actually
-- stored in memory.
--
-- It is faster to write several bytes at once by poking a sequence of values,
-- than it is to write one byte at a time in a loop. 
-- 
-- Writing to the screen memory with ##poke## can be much faster than using
-- ##puts## or ##printf##, but the programming is more difficult. In most cases
-- the speed is not needed. For example, the Euphoria editor, ##ed##, never uses
-- ##poke##.
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
-- [[:Using Data Bytes]], [[:peek]], [[:peeks]], [[:poke4]], [[:allocate]], [[:free]], [[:poke2]], 
-- [[:mem_copy]], [[:mem_set]]
--

--****
-- Signature:
-- <built-in> procedure poke2(atom addr, object x)
--
-- Description:
-- stores one or more words, starting at a memory location.
--
-- Parameters:
--              # ##addr## : an atom, the address at which to store
--              # ##x## : an object, either a word or a non empty sequence of words.
--
-- Errors:
--      Poking in memory you do not own may be blocked by the OS, and cause a
-- machine exception. If you use the define safe these routines will catch these problems with a Euphoria error.
--
-- Comments: 
--
-- There is no point in having ##poke2s## or ##poke2u##. For example, both 32768
-- and -32768 are stored as ###F000## when stored as words. It is up to whoever
-- reads the value to figure it out.
--
-- It is faster to write several words at once by poking a sequence of
-- values, than it is to write one words at a time in a loop.
-- 
-- Writing to the screen memory with ##poke2## can be much faster than using
-- ##puts## or ##printf##, but the programming is more difficult. In most cases
-- the speed is not needed. For example, the Euphoria editor, ed, never uses
-- ##poke2##.
--  
-- The 2-byte values to be stored can be negative or positive. You can read
-- them back with either ##peek2s## or ##peek2u##. Actually, only
-- ##remainder(##x##,65536)## is being stored.
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
-- poke2(a, {12345, #FF00, -12345})
-- </eucode>
-- 
-- See Also:
-- [[:Using Data Words]], [[:peek2s]], [[:peek2u]], [[:poke]], [[:poke4]], [[:allocate]], [[:free]]
--

--****
-- Signature:
-- <built-in> procedure poke4(atom addr, object x)
--
-- Description:
-- stores one or more double words, starting at a memory location.
--
-- Parameters:
--              # ##addr## : an atom, the address at which to store
--              # ##x## : an object, either a double word or a non empty sequence of
-- double words.
--
-- Errors:
--      Poking in memory you do not own may be blocked by the OS, and cause a
-- machine exception. If you use the define safe these routines will catch these problems with a Euphoria error.
--
-- Comments: 
--
-- There is no point in having ##poke4s## or ##poke4u##. For example, both
-- +2^^31^^ and -(2^^31^^) are stored as ###F0000000##. It is up to whoever
-- reads the value to figure it out.
--
-- It is faster to write several double words at once by poking a sequence
-- of values, than it is to write one double words at a time in a loop.
-- 
-- Writing to the screen memory with ##poke4## can be much faster than using
-- ##puts## or ##printf##, but the programming is more difficult. In most cases
-- the speed is not needed. For example, the Euphoria editor, ed, never uses
-- ##poke4##.
--  
-- The 4-byte values to be stored can be negative or positive. You can read
-- them back with either ##peek4s## or ##peek4u##. However, the results
-- are unpredictable if you want to store values with a fractional part or a
-- magnitude greater than 2^^32^^, even though Euphoria represents them
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
--     [[:Using Data Double Words]], [[:peek4s]], [[:peek4u]], [[:poke]], [[:poke2]], [[:allocate]], [[:free]], [[:call]]
--

--****
-- Signature:
-- <built-in> procedure poke8(atom addr, object x)
--
-- Description:
-- stores one or more quad words, starting at a memory location.
--
-- Parameters:
--              # ##addr## : an atom, the address at which to store
--              # ##x## : an object, either a quad word or a non empty sequence of
-- double words.
--
-- Errors:
--      Poking in memory you do not own may be blocked by the OS, and cause a
-- machine exception. If you use the define safe these routines will catch these problems with a Euphoria error.
--
-- Comments:
--
-- There is no point in having ##poke8s## or ##poke8u##. For example, both
-- +power(2,63) and -power(2,63) are stored as ###F000000000000000##. It is up to whoever
-- reads the value to figure it out.
--
-- It is faster to write several quad words at once by poking a sequence
-- of values, than it is to write one quad words at a time in a loop.
--
-- The 8-byte values to be stored can be negative or positive. You can read
-- them back with either ##peek8s## or ##peek8u##. However, the results
-- are unpredictable if you want to store values with a fractional part or a
-- magnitude greater than power(2,64), even though Euphoria represents them
-- all as atoms.
--
-- Example 1:
-- <eucode>
--  a = allocate(100)   -- allocate 100 bytes in memory
--
-- -- poke one 8-byte value at a time:
-- poke8(a, 9712345)
-- poke8(a+8, #FF00FF00)
-- poke8(a+16, -12345)
--
-- -- poke 3 8-byte values at once:
-- poke8(a, {9712345, #FF00FF00, -12345})
-- </eucode>
--
-- See Also:
--     [[:Using Data Double Words]], [[:peek4s]], [[:peek4u]], [[:poke]], [[:poke2]], [[:allocate]], [[:free]], [[:call]]
--

--****
-- Signature:
-- <built-in> procedure poke_long(atom addr, object x)
--
-- Description:
-- stores one or more integers, starting at a memory location.
--
-- Parameters:
--              # ##addr## : an atom, the address at which to store
--              # ##x## : an object, either an integer or a non empty sequence of
-- double words.
--
-- Errors:
--      Poking in memory you do not own may be blocked by the OS, and cause a
-- machine exception. If you use the define safe these routines will catch these problems with a Euphoria error.
--
-- Comments:
--
-- There is no point in having ##poke_longs## or ##poke_longu##. For example, both
-- +power(2,31) and -power(2,31) are stored as ###F0000000## on a 32-bit
-- architecture. It is up to whoever reads the value to figure it out.
--
-- On all //Windows// and other 32-bit operating systems, the ##poke_long##
-- uses 4-byte integers.  On 64-bit architectures using operating systems
-- other than //Windows//, ##poke_long## uses 8-byte integers.
--
-- It is faster to write several integers at once by poking a sequence
-- of values, than it is to write one double words at a time in a loop.
--
-- The 4-byte (or 8-byte) values to be stored can be negative or positive. You can read
-- them back with either ##peek_longs## or ##peek_longu##. However, the results
-- are unpredictable if you want to store values with a fractional part or a
-- magnitude greater than the size of a native ##long int##, even though Euphoria represents them
-- all as atoms.
--
-- Example 1:
-- <eucode>
--  a = allocate(100)   -- allocate 100 bytes in memory
--
-- -- poke one 4-byte value at a time (on Windows or other 32-bit operating system):
-- poke_long(a, 9712345)
-- poke_long(a+4, #FF00FF00)
-- poke_long(a+8, -12345)
--
-- -- poke 3 long int values at once:
-- poke_long(a, {9712345, #FF00FF00, -12345})
-- </eucode>
--
-- See Also:
--     [[:Using Data Double Words]], [[:peek4s]], [[:peek4u]], [[:poke]], [[:poke2]], [[:allocate]], [[:free]], [[:call]]
--

--****
-- Signature:
-- <built-in> procedure poke_pointer(atom addr, object x)
--
-- Description:
-- stores one or more pointers, starting at a memory location.
--
-- Parameters:
--              # ##addr## : an atom, the address at which to store
--              # ##x## : an object, either an integer or a non empty sequence of
-- pointers.
--
-- Errors:
--      Poking in memory you do not own may be blocked by the OS, and cause a
-- machine exception. If you use the define safe these routines will catch these problems with a Euphoria error.
--
-- Comments:
--
-- There is no point in having ##poke_pointers## or ##poke_pointersu##. For example, both
-- +power(2,31) and -power(2,31) are stored as ###F0000000## on a 32-bit
-- architecture. It is up to whoever reads the value to figure it out.
--
-- On all  32-bit operating systems, the ##poke_pointer##
-- uses 4-byte integers.  On 64-bit architectures using operating systems,
-- ##poke_pointer## uses 8-byte integers.
--
-- It is faster to write several pointers at once by poking a sequence
-- of values, than it is to write one double words at a time in a loop.
--
-- The 4-byte (or 8-byte) values to be stored can be negative or positive. You can read
-- them back with either ##peek_pointer## or any other peek function of the correctsize. However, the results
-- are unpredictable if you want to store values with a fractional part or a
-- magnitude greater than the size of a native ##pointer##, even though Euphoria represents them
-- all as atoms.
--
-- Example 1:
-- <eucode>
--  a = allocate(100)   -- allocate 100 bytes in memory
--
-- -- poke one 4-byte value at a time (on a 32-bit operating system):
-- poke_pointer(a, 9712345)
-- poke_pointer(a+4, #FF00FF00)
-- poke_pointer(a+8, -12345)
--
-- -- poke 3 long int values at once:
-- poke_pointer(a, {9712345, #FF00FF00, -12345})
-- </eucode>
--
-- See Also:
--     [[:Using Data Double Words]], [[:peek4s]], [[:peek4u]], [[:peek8u]], [[:peek8s]], [[:peek_pointer]] [[:poke]], [[:poke2]], [[:allocate]], [[:free]], [[:call]]
--

--**
-- Stores a C-style null-terminated ANSI string in memory
--
-- Parameters:
-- # ##buffaddr##: an atom, the RAM address to to the string at.
-- # ##buffsize##: an integer, the number of bytes available, starting from ##buffaddr##.
-- # ##s## : a sequence, the string to store at address ##buffaddr##.
--
-- Comments:
-- * This does not allocate an RAM. You must supply the preallocated area.
-- * This can only be used on ANSI strings. It cannot be used for double-byte strings.
-- * If ##s## is not a string, nothing is stored and a zero is returned.
--
-- Returns:
-- An atom. If this is zero, then nothing was stored, otherwise it is the
-- address of the first byte after the stored string.
--
-- Example 1:
-- <eucode>
--  atom title
--
-- title = allocate(1000)
-- if poke_string(title, 1000, "The Wizard of Oz") then
--     -- successful
-- else
--     -- failed
-- end if
-- </eucode>
-- 
-- See Also:
-- [[:Using Strings]], [[:allocate]], [[:allocate_string]]

public function poke_string(atom buffaddr, integer buffsize, sequence s)
	
	if buffaddr <= 0 then
		return 0
	end if
	
	if not types:string(s) then
		return 0
	end if
	
	if buffsize <= length(s) then
		return 0
	end if

	poke(buffaddr, s)
	buffaddr += length(s)
	poke(buffaddr, 0)

	return buffaddr
end function

--**
-- stores a C-style null-terminated Double-Byte string in memory.
--
-- Parameters:
-- # ##buffaddr##: an atom, the RAM address to to the string at.
-- # ##buffsize##: an integer, the number of bytes available, starting from ##buffaddr##.
-- # ##s## : a sequence, the string to store at address ##buffaddr##.
--
-- Comments:
-- * This does not allocate an RAM. You must supply the preallocated area.
-- * This uses two bytes per string character. **Note** that ##buffsize## 
-- is the number of //bytes// available in the buffer and not the number
-- of //characters// available.
-- * If ##s## is not a double-byte string, nothing is stored and a zero is returned.
--
-- Returns:
-- An atom. If this is zero, then nothing was stored, otherwise it is the
-- address of the first byte after the stored string.
--
-- Example 1:
-- <eucode>
--  atom title
--
-- title = allocate(1000)
-- if poke_wstring(title, 1000, "The Wizard of Oz") then
--     -- successful
-- else
--     -- failed
-- end if
-- </eucode>
-- 
-- See Also:
-- [[:Using Strings]], [[:allocate]], [[:allocate_wstring]]

public function poke_wstring(atom buffaddr, integer buffsize, sequence s)
	
	if buffaddr <= 0 then
		return 0
	end if
	
	if buffsize <= 2 * length(s) then
		return 0
	end if

	poke2(buffaddr, s)
	buffaddr += 2 * length(s)
	poke2(buffaddr, 0)

	return buffaddr
end function

--****
-- === Memory Manipulation

--****
-- Signature:
-- <built-in> procedure mem_copy(atom destination, atom origin, integer len)
--
-- Description:
-- copies a block of memory from an address to another.
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
-- [[:Using Data Bytes]], [[:mem_set]], [[:peek]], [[:poke]], [[:allocate]], [[:free]]
-- 

--****
-- Signature:
-- <built-in> procedure mem_set(atom destination, integer byte_value, integer how_many))
--
-- Description:
-- sets a contiguous range of memory locations to a single value.
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
--   [[:Using Data Bytes]], [[:peek]], [[:poke]], [[:allocate]], [[:free]], [[:mem_copy]]
--

--****
-- === Calling Into Memory

--****
-- Signature:
-- <built-in> procedure call(atom addr)
--
-- Description:
--  calls a machine language routine which was stored in memory prior.
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
-- bytes of machine code using ##allocate_code##. You might allocate other blocks of memory for data
-- and parameters that the machine code can operate on using ##allocate##. The addresses of these
-- blocks could be part of the machine code.
--
-- If your machine code uses the stack, use ##c_proc## instead of ##call##.
--
-- Example 1: 
--              ##demo/callmach.ex##
--
-- See Also:
--              [[:Executable Memory]], [[:allocate_code]], [[:free_code]], [[:c_proc]], [[:define_c_proc]]

integer page_size = 0
ifdef WINDOWS then

	atom oldprotptr = machine_func(M_ALLOC, ADDRESS_LENGTH)
	atom kernel_dll, memDLL_id, 
		VirtualAlloc_rid, 
		-- VirtualLock_rid, VirtualUnlock_rid,
		VirtualProtect_rid, GetLastError_rid, GetSystemInfo_rid

	memDLL_id = dll:open_dll( "kernel32.dll" )
	kernel_dll = memDLL_id
	VirtualAlloc_rid = dll:define_c_func( memDLL_id, "VirtualAlloc", { dll:C_POINTER, dll:C_SIZE_T, dll:C_DWORD, dll:C_DWORD }, dll:C_POINTER )
	VirtualProtect_rid = dll:define_c_func( memDLL_id, "VirtualProtect", { dll:C_POINTER, dll:C_SIZE_T, dll:C_DWORD, dll:C_POINTER }, dll:C_BOOL )
	-- set exported
	memory:VirtualFree_rid = dll:define_c_func( kernel_dll, "VirtualFree", { dll:C_POINTER, dll:C_SIZE_T, dll:C_DWORD }, dll:C_BOOL )
	GetLastError_rid = dll:define_c_func( kernel_dll, "GetLastError", {}, dll:C_DWORD )
	GetSystemInfo_rid = dll:define_c_proc( kernel_dll, "GetSystemInfo", { dll:C_POINTER } )
	if VirtualAlloc_rid != -1 and VirtualProtect_rid != -1 
		and GetLastError_rid != -1 and GetSystemInfo_rid != -1
		then
		atom vaa = VirtualAlloc( 0, 1, or_bits( MEM_RESERVE, MEM_COMMIT ), PAGE_READ_WRITE_EXECUTE ) != 0 
		if vaa then
			DEP_really_works = 1
			c_func( VirtualFree_rid, { vaa, 1, MEM_RELEASE } )
			vaa = 0
		end if
	end if

	
	if GetSystemInfo_rid != -1 then
		bordered_address system_info_ptr = allocate( 9 * ADDRESS_LENGTH )
		if system_info_ptr != 0 then
			c_proc( GetSystemInfo_rid, { system_info_ptr } )
			page_size = peek4u( system_info_ptr + ADDRESS_LENGTH )
			free( system_info_ptr )
		end if
	end if

elsifdef NETBSD then

	constant libc_h = open_dll("libc.so")
	constant getpagesize_rid = dll:define_c_func(libc_h, "sysconf", { dll:C_INT }, dll:C_LONG )
	if getpagesize_rid > -1 then
		page_size = c_func(getpagesize_rid, { 28 })
	end if

elsifdef UNIX then

	constant getpagesize_rid = dll:define_c_func( -1, "getpagesize", { }, dll:C_UINT )	 
	page_size = c_func( getpagesize_rid, {} )

end ifdef

--**
-- @nodoc@
public constant PAGE_SIZE = page_size


ifdef WINDOWS then
	function VirtualAlloc( atom addr, atom size, atom allocation_type, atom protect_ )
		atom r1
		r1 = c_func( VirtualAlloc_rid, {addr, size, allocation_type, protect_ } )
		return r1
	end function
end ifdef

-- who added these?  Please document them.
-- there is no need to expose this to the user.
--**
-- @nodoc@
public type page_aligned_address( object a )
	if not atom(a) then
		return 0
	end if
	return remainder( a, PAGE_SIZE ) = 0
end type

--**
-- @nodoc@
public function is_DEP_supported()
	return memconst:DEP_really_works
end function

--**
-- @nodoc@
public function is_using_DEP()
	return memconst:use_DEP
end function

--**
-- @nodoc@
public procedure DEP_on(integer value)
	memconst:use_DEP = value
end procedure

--****
-- === Allocating and Writing to memory:

--**
-- allocates and copies data into executable memory.
--
-- Parameters:
-- # ##a_sequence_of_machine_code## : is the machine code to
-- be put into memory to be later called with [[:call]]        
-- # the ##word length## : of the said code.  You can specify your
-- code as 1-byte, 2-byte or 4-byte chunks if you wish.  If your machine code is byte
-- code specify 1.  The default is 1.
--
-- Returns:
-- An **address**,
-- The function returns the address in memory of the code, that can be
-- safely executed whether DEP is enabled or not or 0 if it fails.  On the
-- other hand, if you try to execute a code address returned by [[:allocate]]
-- with DEP enabled the program will receive a machine exception.  
--
-- Comments:
-- 
-- Use this for the machine code you want to run in memory.  The copying is
-- done for you and when the routine returns the memory may not be readable
-- or writeable but it is guaranteed to be executable.  If you want to also
-- write to this memory **after the machine code has been copied** you should
-- use [[:allocate_protect]] instead and you should read about having memory
-- executable and writeable at the same time is a bad idea.  You mustn't use
-- ##free## on memory returned from this function.  You may instead
-- use ##free_code## but since you will probably need the code throughout
-- the life of your program's process this normally is not necessary.
-- If you want to put only data in the memory to be read and written use [[:allocate]].
--
-- See Also:
-- [[:Executable Memory]], [[:allocate]], [[:free_code]], [[:allocate_protect]]
public function allocate_code( object data, memconst:valid_wordsize wordsize = 1 )
	ifdef FREEBSD and BITS32 then
		return allocate_protect( data, wordsize, or_bits( PAGE_EXECUTE, PAGE_READONLY ) )
	elsedef
		return allocate_protect( data, wordsize, PAGE_EXECUTE )
	end ifdef

end function


--**
-- Allocate a C-style null-terminated string in memory
--
-- Parameters:
--              # ##s## : a sequence, the string to store in RAM.
--              # ##cleanup## : an integer, if non-zero, then the returned pointer will be
--                automatically freed when its reference count drops to zero, or
--                when passed as a parameter to [[:delete]].  
--
-- Returns:
--              An **atom**, the address of the memory block where the string was
-- stored, or 0 on failure.
--
-- Comments:
-- Only the 8 lowest bits of each atom in ##s## is stored. Use
-- ##allocate_wstring##  for storing double byte encoded strings.
--
-- There is no ##allocate_string_low## function. However, you could easily
-- craft one by adapting the code for ##allocate_string##.
--
-- Since ##allocate_string## allocates memory, you are responsible to
-- [[:free]] the block when done with it if ##cleanup## is zero.
-- If ##cleanup## is non-zero, then the memory can be freed by calling
-- [[:delete]], or when the pointer's reference count drops to zero.
--
-- Example 1:
-- <eucode>
--  atom title
--
-- title = allocate_string("The Wizard of Oz")
-- </eucode>
-- 
-- See Also:
--              [[:Using Strings]], [[:allocate]], [[:allocate_wstring]]

public function allocate_string(sequence s, types:boolean cleanup = 0 )
	atom mem
	
	mem = allocate( length(s) + 1) -- Thanks to Igor
	
	if mem then
		poke(mem, s)
		poke(mem+length(s), 0)  -- Thanks to Aku
		if cleanup then
			mem = delete_routine( mem, memconst:FREE_RID )
		end if
    end if

	return mem
end function

procedure local_free_protected_memory( atom p, integer s)
	ifdef WINDOWS then
		if dep_works() then
			c_func(VirtualFree_rid, { p, s, MEM_RELEASE })
		else
			machine_func(M_FREE, {p})
		end if
	elsifdef UNIX then
		c_func( MPROTECT, { p, s, PAGE_READWRITE } )
		machine_func( memconst:M_FREE, {p})
	end ifdef
end procedure

--**
-- Allocates and copies data into memory and gives it protection using
-- [[:Standard Library Memory Protection Constants]] or
-- [[:Microsoft Windows Memory Protection Constants]].  The user may only pass in one of these 
-- constants.  If you only wish to execute a sequence as machine code use ##allocate_code##.  
-- If you only want to read and write data into memory use ##allocate##.
--
-- See [[http://msdn.microsoft.com/en-us/library/aa366786(VS.85).aspx "MSDN: Microsoft's Memory Protection Constants"]]
--
-- Parameters:
-- # ##data## : is the machine code to be put into memory. 
-- # ##wordsize## : is the size each element of data will take in 
-- memory.  Are they 1-byte, 2-bytes, 4-bytes or 8-bytes long?  Specify here.  The default is 1.
-- # ##protection## : is the particular //Windows// protection.
--
-- Returns:
-- An **address**,
-- The function returns the address to the required memory
-- or 0 if it fails.  This function is guaranteed to return memory on 
-- the 8 byte boundary.  It also guarantees that the memory returned with 
-- at least the protection given (but you may get more).
--
-- If you want to call ##allocate_protect( data, PAGE_READWRITE )##, you can use 
-- [[:allocate]] instead.  It is more efficient and simpler.
--
-- If you want to call ##allocate_protect( data, PAGE_EXECUTE )##, you can use 
-- [[:allocate_code]] instead.  It is simpler.
--
-- You must not use [[:free]] on memory returned from this function, instead use [[:free_code]].
-- 
-- See Also:
-- [[:Executable Memory]]
public function allocate_protect( object data, memconst:valid_wordsize wordsize = 1, valid_memory_protection_constant protection )
	-- set the actual protection for the OS to /true_protection/ in all cases
	-- /protection/ is put into the checking system if it is there using SAFE
	
	atom iaddr = 0
	std_library_address eaddr	
	integer size
	valid_memory_protection_constant first_protection
	
	valid_memory_protection_constant true_protection = protection
		
	-- when SAFE is defined /true_protection/ always allows READ so that block edges can be 
	-- checked and WRITE so that we can add leader and trailer markers in this routine.
	-- when SAFE is not defined /true_protection/ is set to what is passed in without
	-- modification.
	ifdef SAFE then	
		if ( (not test_write(protection)) or (not test_read(protection) ) ) then
			if test_exec(protection) then
				true_protection = PAGE_READ_WRITE_EXECUTE
			else
				true_protection = PAGE_READ_WRITE
			end if
		end if
	end ifdef

	if atom(data) then
		size = data * wordsize
		first_protection = true_protection
	else
		size = length(data) * wordsize
		first_protection = PAGE_READ_WRITE
	end if

	iaddr = local_allocate_protected_memory( size + memory:BORDER_SPACE * 2, first_protection )
	if iaddr = 0 then
		return 0
	end if
	
	-- eaddr is set here
	eaddr = memory:prepare_block( iaddr, size, protection )

	if eaddr = 0 then
		return eaddr
	end if
	
	if sequence( data ) then
		switch wordsize do
			case 1 then
				eu:poke( eaddr, data )
				
			case 2 then
				eu:poke2( eaddr, data )
				
			case 4 then
				eu:poke4( eaddr, data )
			
			case 8 then
				poke8( eaddr, data )
			
			case else
				error:crash("Parameter error: Wrong word size %d in allocate_protect().", wordsize)
				
		end switch
	end if
	ifdef SAFE then
		-- here we can take away write access
		-- from true_protection if protection doesn't have it.
		-- true_protection must have read access though.
		switch protection do
			case PAGE_EXECUTE then
				true_protection = PAGE_EXECUTE_READ
				
			case PAGE_EXECUTE_WRITECOPY  then
				true_protection = PAGE_EXECUTE_READWRITE
				
			case PAGE_WRITECOPY, PAGE_NOACCESS then				
				true_protection = PAGE_READONLY
				
			case else
				true_protection = protection					
		end switch
	end ifdef
	
	if local_change_protection_on_protected_memory( iaddr, size + memory:BORDER_SPACE * 2, true_protection ) = -1 then
		local_free_protected_memory( iaddr, size + memory:BORDER_SPACE * 2 )
		eaddr = 0
	end if
	
	return eaddr
end function


function local_allocate_protected_memory( integer s, integer first_protection )
	ifdef WINDOWS then     
		if dep_works() then
			return eu:c_func(VirtualAlloc_rid, 
				{ 0, s, or_bits( MEM_RESERVE, MEM_COMMIT ), first_protection })
		else
			return machine_func(M_ALLOC, PAGE_SIZE)
		end if
	elsifdef UNIX then
		atom ptr = c_func( MMAP, { 0, s, first_protection, or_bits( MAP_ANONYMOUS, MAP_PRIVATE ), -1, 0 })
		-- please check the value for MAP_FAILED for other OSes above and here:
		ifdef LINUX or FREEBSD then
			if ptr = MAP_FAILED then
				return 0
			end if
		elsedef
			-- fail silently on other OSes...
		end ifdef
		integer fail = local_change_protection_on_protected_memory( ptr, s, first_protection )
		return ptr
	end ifdef
end function

-- return -1 for failure. 0 success  
function local_change_protection_on_protected_memory( atom p, integer s, integer new_protection )
	ifdef WINDOWS then
		if dep_works() then
			if eu:c_func( VirtualProtect_rid, { p, s, new_protection , oldprotptr } ) = 0 then
				-- 0 indicates failure here
				return -1
			end if
		end if
		return 0
	elsifdef UNIX then
		integer fail = c_func( MPROTECT, { p, s, new_protection } )
		if fail then
				error:crash( "Could not change memory protection at 0x%x (%d bytes) to %d", { p, s, new_protection } )
		end if
		return fail
	end ifdef
end function

--****
-- === Memory Disposal


--**
-- frees up a previously allocated block of memory.
--
-- Parameters:
--  # ##addr##, either a single atom or a sequence of atoms; these are addresses of a blocks to free.
--
-- Comments:
--  * Use ##free## to return blocks of memory the during execution. This will reduce the chance of 
--   running out of memory or getting into excessive virtual memory swapping to disk. 
-- * Do not reference a block of memory that has been freed. 
-- * When your program terminates, all allocated memory will be returned to the system.
-- * ##addr## must have been allocated previously using [[:allocate]]. You
--   cannot use it to relinquish part of a block. Instead, you have to allocate
--   a block of the new size, copy useful contents from old block there and
--   then ##free## the old block.  
-- * If the memory was allocated and automatic cleanup
--   was specified, then do not call ##free## directly.  Instead, use [[:delete]].
-- * An ##addr## of zero is simply ignored.
--
-- Example 1:
--   ##demo/callmach.ex##
--
-- See Also:
--     [[:Using Data Bytes]], [[:Using Data Words]], [[:Using Data Double Words]], [[:Using Strings]], [[:allocate_data]], [[:free_code]]
--

public procedure free(object addr)
	if types:number_array (addr) then
		if types:ascii_string(addr) then
			error:crash("free(\"%s\") is not a valid address", {addr})
		end if
		
		for i = 1 to length(addr) do
			memory:deallocate( addr[i] )
		end for
		return
	elsif sequence(addr) then
		error:crash("free() called with nested sequence")
	end if
	
	if addr = 0 then
		-- Special case, a zero address is assumed to be an uninitialized pointer,
		-- so it is ignored.
		return
	end if

	memory:deallocate( addr )
end procedure
memconst:FREE_RID = routine_id("free")


--****
-- ==== free_code
-- <eucode>
-- include std/machine.e
-- public procedure free_code( atom addr, integer size, valid_wordsize wordsize = 1 )
-- </eucode>
--
-- Description:
-- frees up allocated code memory.
--
-- Parameters:
-- # ##addr## : must be an address returned by [[:allocate_code]] or [[:allocate_protect]].  Do **not** pass memory returned from [[:allocate]] here! 
-- # ##size## : is the length of the sequence passed to ##alllocate_code## or the size you specified when you called ##allocate_protect##.  
-- # ##wordsize##: valid_wordsize  default = 1
--
-- Comments:
-- Chances are you will not need to call this function because code allocations are typically public scope operations that you want to have available until your process exits.
--
-- See Also: [[:Executable Memory]], [[:allocate_code]], [[:free]]



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
-- associates a routine for cleaning up after a Euphoria object.
-- 
-- Comments:
-- ##delete_routine## associates a euphoria object with a routine id meant
-- to clean up any allocated resources.  It always returns an atom
-- (double) or a sequence, depending on what was passed (integers are
-- promoted to atoms).
-- 
-- The routine specified by ##delete_routine## should be a procedure that
-- takes a single parameter, being the object to be cleaned up after.
-- Objects are cleaned up under one of two circumstances.  The first is
-- if it's called as a parameter to ##delete##.  After the call, the
-- association with the delete routine is removed.
-- 
-- The second way for the delete routine to be called is when its
-- reference count is reduced to 0.  Before its memory is freed, the
-- delete routine is called. A default delete will be used if the cleanup 
-- parameter to one of the [[:allocate]] routines is true. 
-- 
-- ##delete_routine## may be called multiple times for the same object.
-- In this case, the routines are called in reverse order compared to
-- how they were associated.

--****
-- Signature:
-- <built-in> procedure delete( object x )
-- 
-- Description:
-- calls the cleanup routines associated with the object, and removes the
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

--****
-- === Types and Constants

--**
-- an address returned from ##allocate## or ##allocate_protect##
-- or ##allocate_code## or the value 0.
--
-- Returns:
-- An **integer**, 
-- The type will return 1 if the parameter, an address, was returned
-- from one of these Machine Level functions (and has not yet been freeed)
--
-- Comments:
-- This type is equivalent to atom unless SAFE is defined.
-- Only values that satisfy this type may be passed into
-- free or free_code.
--
public type std_library_address( object addr ) 
	ifdef not SAFE then
		return atom(addr)
	elsedef
		if not atom(addr) then
			return 0
		end if
		return (addr = 0) or bordered_address(addr)
	end ifdef
end type

--****
-- ==== valid_memory_protection_constant
-- <eucode>
-- include std/machine.e
-- public type valid_memory_protection_constant(object a)
-- </eucode>
-- protection constants type


                                  
--****
-- ==== machine_addr
-- <eucode>
-- include std/machine.e
-- public type machine_addr(object a)
-- </eucode>
--
-- a 32-bit non-null machine address


--****
-- ==== safe_address
-- <eucode>
-- include std/machine.e
-- public function safe_address(machine_addr start, natural len, 
--               positive_int action )
-- </eucode>
--
-- action is some bitwise-or combination of the following constants:
-- A_READ, A_WRITE and A_EXECUTE.
--
-- Returns:
-- When [[:Safe Mode]] is turned on, this
-- returns true iff it is ok to perform action all addresses from start to start+len-1.
-- 
-- When [[:Safe Mode]] is not turned on, this always returns true.
--
-- Comments: 
-- This is used mostly inside the safe library itself to check whenever
-- you call Machine Level Access Functions or Procedures.  It should only be used
-- for debugging purposes.
--

--****
-- ==== ADDRESS_LENGTH
-- <eucode>
-- include std/machine.e
-- namespace machine
-- public constant ADDRESS_LENGTH
-- </eucode>
-- The number of bytes required to hold a pointer.


--**** 
-- ==== PAGE_SIZE
-- <eucode>
-- include std/machine.e
-- namespace machine
-- public constant PAGE_SIZE
-- </eucode>
-- The operating system's memory page length in bytes.


--****
-- == Indirect Routine Calling
--
-- <<LEVELTOC level=2 depth=4>>
-- 

--****
-- @[dyncall|]
-- === Accessing Euphoria coded routines
--

--****
-- Signature:
-- <built-in> function routine_id(sequence routine_name)
--
-- Description:
-- returns an integer id number for a user-defined Euphoria procedure or function.
--
-- Parameters:
--              # ##routine_name## : a string, the name of the procedure or function.
--
-- Returns:
-- An **integer**, known as a routine id, -1  if the named routine can't be found, else zero or more.
--
-- Errors:
-- ##routine_name## should not exceed 1,024 characters.
--
-- Comments:
-- The id number can be passed to [[:call_proc]] or [[:call_func]], to indirectly call
-- the routine named by ##routine_name##. This id depends on the internal process of 
-- parsing your code, not on ##routine_name##.
--
-- The routine named ##routine_name## must be visible (that is callable) at the place where
-- ##routine_id## is used to get the id number. If it is not, -1 is returned.
--
-- Indirect calls to the routine can appear earlier in the program than the definition of the routine,
-- but the id number can only be obtained in code that comes after the definition
-- of the routine - see example 2 below.
--
-- Once obtained, a valid routine id can be used at any place in the program to call
-- a routine indirectly via [[:call_proc]] or [[:call_func]], including at places where
-- the routine is no longer in scope.
--
-- Some typical uses of ##routine_id## are:
--
-- # Creating a subroutine that takes another routine as a parameter. (See Example 2 below)
-- # Using a sequence of routine id's to make a case (switch) statement. Using the 
-- [[:switch statement]] is more efficient.
-- # Setting up an Object-Oriented system.
-- # Getting a routine id so you can pass it to [[:call_back]]. (See [[:Platform-Specific Issues]])
-- # Getting a routine id so you can pass it to [[:task_create]]. (See [[:Multitasking in Euphoria]])
-- # Calling a routine that is defined later in a program. This is no longer needed from v4.0 onward.
--
-- Note that C routines, callable by Euphoria, also have ids, but they cannot be used where 
-- routine ids are, because of the different type checking and other technical issues.
--
-- See Also:
-- [[:define_c_proc]] and [[:define_c_func]]
--
-- Example 1:
-- <eucode>  
--  procedure foo()
--     puts(1, "Hello World\n")
-- end procedure
-- 
-- integer foo_num
-- foo_num = routine_id("foo")
-- 
-- call_proc(foo_num, {})  -- same as calling foo()
-- </eucode>
--  
-- Example 2:  
-- <eucode>
-- function apply_to_all(sequence s, integer f)
--     -- apply a function to all elements of a sequence
--     sequence result
--     result = {}
--     for i = 1 to length(s) do
--         -- we can call add1() here although it comes later in the program
--         result = append(result, call_func(f, {s[i]}))
--     end for
--     return result
-- end function
-- 
-- function add1(atom x)
--     return x + 1
-- end function
-- 
-- -- add1() is visible here, so we can ask for its routine id
-- ? apply_to_all({1, 2, 3}, routine_id("add1"))
-- -- displays {2,3,4}
-- </eucode>
--  
-- See Also:
-- [[:call_proc]], [[:call_func]], [[:call_back]], [[:define_c_func]], [[:define_c_proc]], 
-- [[:task_create]], [[:Platform-Specific Issues]], [[:Indirect routine calling]]

--****
-- Signature:
-- <built-in> function call_func(integer id, sequence args={})
--
-- Description:
--  calls the user-defined Euphoria function by routine id.
--
-- Parameters:
--   # ##id## : an integer, the routine id of the function to call
--   # ##args## : a sequence, the parameters to pass to the function.
--
-- Returns:
-- The **value**, the called function returns.
--
-- Errors:
-- If ##id## is negative or otherwise unknown, an error occurs.
--
-- If the length of ##args## is not the number of parameters the function takes, an error occurs.
--
-- Comments: 
-- ##id## must be a valid routine id returned by [[:routine_id]].
--
-- ##args## must be a sequence of argument values of length n, where n is the number of
-- arguments required by the called function. Defaulted parameters currently cannot be
-- synthesized while making a indirect call.
--
-- If the function with id ##id## does not take any arguments then ##args## should be ##{}##.
--
-- Example 1:
-- Take a look at the sample program called ##demo/csort.ex##
--
-- See Also:
-- [[:call_proc]], [[:routine_id]], [[:c_func]]
-- 

--****
-- Signature:
-- <built-in> procedure call_proc(integer id, sequence args={})
--
-- Description:
-- calls a user-defined Euphoria procedure by routine id.
--
-- Parameters:
--   # ##id## : an integer, the routine id of the procedure to call
--   # ##args## : a sequence, the parameters to pass to the function.
--
-- Errors:
-- If ##id## is negative or otherwise unknown, an error occurs.
--
-- If the length of ##args## is not the number of parameters the function takes, an error occurs.
--
-- Comments: 
-- ##id## must be a valid routine id returned by [[:routine_id]].
--
-- ##args## must be a sequence of argument values of length n, where n is the number of
-- arguments required by the called procedure. Defaulted parameters currently cannot be
-- synthesized while making a indirect call.
--
-- If the procedure with id ##id## does not take any arguments then ##args## should be ##{}##.
--
-- Example 1:
-- <eucode>
-- public integer foo_id
--
-- procedure x()
--     call_proc(foo_id, {1, "Hello World\n"})
-- end procedure
-- 
-- procedure foo(integer a, sequence s)
--     puts(a, s)
-- end procedure
-- 
-- foo_id = routine_id("foo")
-- 
-- x()
-- </eucode>
--  
-- See Also: 
--   [[:call_func]], [[:routine_id]], [[:c_proc]]

--****
-- === Accessing Euphoria Internals

--****
-- Signature:
-- <built-in> function machine_func(integer machine_id, object args={})
--
-- Description:
-- performs a machine-specific operation that returns a value.
--
-- Returns:
-- Depends on the called internal facility.
--
-- Comments:
-- This function us mainly used by the standard library files to implement machine dependent 
-- operations such as graphics and sound effects. This routine should normally be called 
-- indirectly via one of the library routines in a Euphoria include file.
-- User programs normally do not need to call ##machine_func##.
--
-- A direct call might cause a machine exception if done incorrectly.
--
-- See Also:
-- [[:machine_proc]]

--****
-- Signature:
-- <built-in> procedure machine_proc(integer machine_id, object args={})
--
-- Description:
-- perform a machine-specific operation that does not return a value.
--
-- Comments:
-- This procedure us mainly used by the standard library files to implement machine dependent 
-- operations such as graphics and sound effects. This routine should normally be called
-- indirectly via one of the library routines in a Euphoria include file.
-- User programs normally do not need to call ##machine_proc##.
--
-- A direct call might cause a machine exception if done incorrectly.
--
-- See Also:
-- [[:machine_func]]

