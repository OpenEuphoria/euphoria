--****
-- == Machine Level Access
--
-- <<LEVELTOC level=2 depth=4>>
--

namespace machine

public include std/memconst.e

ifdef SAFE then
	public include std/safe.e as memory
elsedef
	public include std/memory.e as memory
end ifdef

include std/dll.e
include std/error.e
include std/types.e

integer FREE_ARRAY_RID

--****
-- === Memory allocation
--

--**
-- The number of bytes required to hold a pointer.
public constant ADDRESS_LENGTH = 4

--**
-- Allocate a contiguous block of data memory.
--
-- Parameters:
--   # ##n## : a positive integer, the size of the requested block.
--   # ##cleanup## : an integer, if non-zero, then the returned pointer will be
--     automatically freed when its reference count drops to zero, or
--     when passed as a parameter to [[:delete]].
--
-- Return:
--   An **atom**, the address of the allocated memory or 0 if the memory
--   can't be allocated. **NOTE** you must use either an atom or object to
--   receive the returned value as sometimes the returned memory address is
--   too larger for an integer to hold.
--
-- Comments:
-- * Since ##allocate##() acquires memory from the system, it is your responsiblity to 
-- return that memory when your application is done with it. There are two ways to
-- do that - automatically or manually.
-- ** //Automatically// - If the ##cleanup## parameter is non-zero, then the memory
-- is returned when the variable that receives the address goes out of scope **and**
-- is not referenced by anything else. Alternatively you can force it be released by
-- calling the [[:delete]]() function.
-- ** //Manually// - If the ##cleanup## parameter is zero, then you must call the
-- [[:free]]() function at some point in your program to release the memory back to the system.
-- * When your program terminates, the operating system will reclaim
-- all memory that your applicaiton acquired anyway.
-- * An address returned by this function shouldn't be passed to ##[[:call]]()##.
-- For that purpose you should use ##[[:allocate_code]]()## instead. 
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
--     [[:free]], [[:peek]], [[:poke]], [[:mem_set]], [[:allocate_code]] [[:allocate_string]]

public function allocate(positive_int n, boolean cleanup = 0)
-- allocate memory block and add it to safe list
	atom iaddr --machine_addr iaddr
	atom eaddr	
	ifdef DATA_EXECUTE then
		-- high level call:  No need to add BORDER_SPACE*2 here.
		eaddr = machine:allocate_protect( n, 1, PAGE_READ_WRITE_EXECUTE )
	elsedef	
		iaddr = eu:machine_func(M_ALLOC, n+BORDER_SPACE*2)
		eaddr = prepare_block( iaddr, n, PAGE_READ_WRITE )
	end ifdef
	if cleanup then
		eaddr = delete_routine( eaddr, FREE_RID )
	end if
	return eaddr
end function

--**
-- Allocate n bytes of memory and return the address.
-- Free the memory using free() below.

public function allocate_data(positive_int n, boolean cleanup = 0)
-- allocate memory block and add it to safe list
	machine_addr a
	bordered_address sla
	a = eu:machine_func(M_ALLOC, n+BORDER_SPACE*2)
	sla = prepare_block(a, n, PAGE_READ_WRITE )
	if cleanup then
		return delete_routine( sla, FREE_RID )
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
--   [[:allocate_string_pointer_array]], [[:free_pointer_array]]

public function allocate_pointer_array(sequence pointers, boolean cleanup = 0)

    atom pList
	integer len = length(pointers) * ADDRESS_LENGTH
	
    pList = allocate( (len + ADDRESS_LENGTH ) )
    poke4(pList, pointers)
    poke4(pList + len, 0)
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
--   Do not call ##free_pointer_array##() for a pointer that was allocated to be cleaned
--   up automatically.  Instead, use [[:delete]].
--
-- See Also:
--   [[:allocate_pointer_array]], [[:allocate_string_pointer_array]]

public procedure free_pointer_array(atom pointers_array)
	atom saved = pointers_array
	atom ptr

	while ptr with entry do
		deallocate(ptr)
		pointers_array += ADDRESS_LENGTH
		
	entry
		ptr = peek4u(pointers_array)
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
--   [[:free_pointer_array]]

public function allocate_string_pointer_array(object string_list, boolean cleanup = 0)
	for i = 1 to length(string_list) do
		string_list[i] = allocate_string(string_list[i])
	end for

	if cleanup then
		return delete_routine( allocate_pointer_array(string_list), FREE_ARRAY_RID )
	else
		return allocate_pointer_array(string_list)
	end if
end function


--****
-- == Indirect Routine Calling
--
-- <<LEVELTOC level=2 depth=4>>
--
-- === SAFE mode
--
-- During the development of your application, you can define the word ##SAFE## to cause
-- ##machine.e## to use alternative memory functions. These functions are slower but
-- help in the debugging stages. In general, ##SAFE## mode should not be enabled during
-- production phases but only for development phases.
--
-- To define the word ##SAFE## run your application with the ##-D SAFE## command line
-- option, or add to the top of your main file ##with define SAFE##.
--
-- 
-- === Data Execute mode
-- 
-- ##Data Execute mode## makes data that will be returned from allocate() executable.  On some
-- systems allocate() will return memory that is not executable unless this mode has been enabled. 
-- When writing software you should use allocate_code() or allocate_protect() to get memory for   
-- execution.  This is more efficient and more secure than using ##Data Execute mode##.  However,
-- since on many systems executing memory returned from allocate() will work much software will be
-- written 4.0 and yet use allocate() for executable memory instead of the afore mentioned routines. 
-- Therefore, you may use this switch when you find that your are getting Data Execute Exceptions
-- running some software.  ##SAFE## mode will help you discover what memory should be changed to
-- what access level.  ##Data Execute## mode will only work when the EUPHORIA program uses
-- std/machine.e not machine.e.

-- To enable ##Data Execute mode## define the word ##DATA_EXECUTE## using 
-- the ##-D DATA_EXECUTE## command line option.
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
-- Return an integer id number for a user-defined Euphoria procedure or function.
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
-- The id number can be passed to [[:call_proc]]() or [[:call_func]](), to indirectly call
-- the routine named by ##routine_name##. This id depends on the internal process of 
-- parsing your code, not on ##routine_name##.
--
-- The routine named ##routine_name## must be visible, i.e. callable, at the place where
-- ##routine_id##() is used to get the id number. If it is not, -1 is returned.
--
-- Indirect calls to the routine can appear earlier in the program than the definition of the routine,
-- but the id number can only be obtained in code that comes after the definition
-- of the routine - see example 2 below.
--
-- Once obtained, a valid routine id can be used at any place in the program to call
-- a routine indirectly via [[:call_proc]]()/[[:call_func]](), including at places where
-- the routine is no longer in scope.
--
-- Some typical uses of ##routine_id##() are:
--
-- # Creating a subroutine that takes another routine as a parameter. (See Example 2 below)
-- # Using a sequence of routine id's to make a case (switch) statement. Using the 
-- [[:switch statement]] is more efficient.
-- # Setting up an Object-Oriented system.
-- # Getting a routine id so you can pass it to [[:call_back]](). (See [[:Platform-Specific Issues]])
-- # Getting a routine id so you can pass it to [[:task_create]](). (See [[:Multitasking in Euphoria]])
-- # Calling a routine that is defined later in a program. This is no longer needed from v4.0 onward.
--
-- Note that C routines, callable by Euphoria, also have ids, but they cannot be used where 
-- routine ids are, because of the different type checking and other technical issues.
-- See [[:define_c_proc]]() and [[:define_c_func]]().
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
--  Call the user-defined Euphoria function by routine id.
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
-- ##id## must be a valid routine id returned by [[:routine_id]]().
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
-- Call a user-defined Euphoria procedure by routine id.
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
-- ##id## must be a valid routine id returned by [[:routine_id]]().
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
-- === Accessing Euphoria internals

--****
-- Signature:
-- <built-in> function machine_func(integer machine_id, object args={})
--
-- Description:
-- Perform a machine-specific operation that returns a value.
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
-- Perform a machine-specific operation that does not return a value.
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

integer page_size = 0
ifdef WIN32 then

	atom kernel_dll, memDLL_id, 
		VirtualAlloc_rid, 
		-- VirtualLock_rid, VirtualUnlock_rid,
		VirtualProtect_rid, GetLastError_rid, GetSystemInfo_rid

	memDLL_id = open_dll( "kernel32.dll" )
	kernel_dll = memDLL_id
	VirtualAlloc_rid = define_c_func( memDLL_id, "VirtualAlloc", { C_POINTER, C_SIZE_T, C_DWORD, C_DWORD }, C_POINTER )
	VirtualProtect_rid = define_c_func( memDLL_id, "VirtualProtect", { C_POINTER, C_SIZE_T, C_DWORD, C_POINTER }, C_BOOL )
	VirtualFree_rid = define_c_func( kernel_dll, "VirtualFree", { C_POINTER, C_SIZE_T, C_DWORD }, C_BOOL )
	-- VirtualLock_rid = define_c_func( memDLL_id, "VirtualLock", { C_POINTER, C_SIZE_T }, C_BOOL )
	-- VirtualUnlock_rid = define_c_func( memDLL_id, "VirtualUnlock", { C_POINTER, C_SIZE_T }, C_BOOL )
	GetLastError_rid = define_c_func( kernel_dll, "GetLastError", {}, C_DWORD )
	GetSystemInfo_rid = define_c_proc( kernel_dll, "GetSystemInfo", { C_POINTER } )
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
elsifdef UNIX then
	constant getpagesize_rid = define_c_func( -1, "getpagesize", { }, C_UINT )	 
	page_size = c_func( getpagesize_rid, {} )
end ifdef

--** 
-- The operating system's memory page length in bytes.
public constant PAGE_SIZE = page_size

ifdef WIN32 then
	function VirtualAlloc( atom addr, atom size, atom allocation_type, atom protect_ )
		atom r1
		r1 = c_func( VirtualAlloc_rid, {addr, size, allocation_type, protect_ } )
		return r1
	end function
end ifdef

--****
-- == Types supporting Memory

--**
-- protection constants type
public type valid_memory_protection_constant( object x )
	return find( x, MEMORY_PROTECTION )
end type

--**
-- page aligned address type
public type page_aligned_address( object a )
	if not atom(a) then
		return 0
	end if
	return remainder( a, PAGE_SIZE ) = 0
end type

public function is_DEP_supported()
	return DEP_really_works
end function

public function is_using_DEP()
	return use_DEP
end function

public procedure DEP_on(integer value)
	use_DEP = value
end procedure

--****
-- === Allocating and Writing to memory:

--**
-- Allocates and copies data into executable memory.
--
-- Parameters:
-- # ##a_sequence_of_machine_code## : is the machine code to
-- be put into memory to be later called with [[:call()]]        
-- # the ##word length## : of the said code.  You can specify your
-- code as 1-byte, 2-byte or 4-byte chunks if you wish.  If your machine code is byte
-- code specify 1.  The default is 1.
--
-- Return Value:
-- An **address**,
-- The function returns the address in memory of the code, that can be
-- safely executed whether DEP is enabled or not or 0 if it fails.  On the
-- other hand, if you try to execute a code address returned by [[:allocate()]]
-- with DEP enabled the program will receive a machine exception.  
--
-- Comments:
-- 
-- Use this for the machine code you want to run in memory.  The copying is
-- done for you and when the routine returns the memory may not be readable
-- or writeable but it is guaranteed to be executable.  If you want to also
-- write to this memory **after the machine code has been copied** you should
-- use [[:allocate_protect()]] instead and you should read about having memory
-- executable and writeable at the same time is a bad idea.  You mustn't use
-- ##free()## on memory returned from this function.  You may instead
-- use ##free_code()## but since you will probably need the code throughout
-- the life of your program's process this normally is not necessary.
-- If you want to put only data in the memory to be read and written use [[:allocate]].
-- See Also:
-- [[:allocate]], [[:free_code]], [[:allocate_protect]]

public function allocate_code( object data, valid_wordsize wordsize = 1 )

	return allocate_protect( data, wordsize, PAGE_EXECUTE )

end function



--**
-- Type for memory addresses
--
-- an address returned from allocate() or allocate_protect()
-- or allocate_code() or the value 0.
--
-- Return Value:
-- An **integer**, 
-- The type will return 1 if the parameter was returned
-- from one of these functions (and has not yet been freeed)
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

ifdef WIN32 then
std_library_address oldprotptr = allocate_data(ADDRESS_LENGTH)
end ifdef

function local_allocate_protected_memory( integer s, integer first_protection )
	ifdef WIN32 then
		if dep_works() then
			return eu:c_func(VirtualAlloc_rid, 
				{ 0, s, or_bits( MEM_RESERVE, MEM_COMMIT ), first_protection })
		else
			return machine_func(M_ALLOC, PAGE_SIZE)
		end if
	elsifdef UNIX then
		return machine_func(M_ALLOC, PAGE_SIZE)
--		return mmap( 0, PAGE_SIZE, protection, or_bits(MAP_PRIVATE,MAP_ANONYMOUS), -1, 0 )
	end ifdef
end function

-- return -1 for failure. 0 success  
function local_change_protection_on_protected_memory( atom p, integer s, integer new_protection )
	ifdef WIN32 then
		if dep_works() then
			if eu:c_func( VirtualProtect_rid, { p, s, new_protection , oldprotptr } ) = 0 then
				-- 0 indicates failure here
				return -1
			end if
		end if
		return 0
	elsifdef UNIX then
		return 0
--		return mprotect(p, s, new_protection)
	end ifdef
end function

procedure local_free_protected_memory( atom p, integer s)
	ifdef WINDOWS then
		if dep_works() then
			c_func(VirtualFree_rid, { p, s, MEM_RELEASE })
		else
			machine_func(M_FREE, {p})
		end if
	elsifdef UNIX then
			machine_func(M_FREE, {p})
--		munmap(p, s)
	end ifdef
end procedure

--**
-- Allocates and copies data into memory and gives it protection using
-- [[:Standard Library Memory Protection Constants]] or
-- [[:Microsoft Windows Memory Protection Constants]].  The user may only pass in one of these 
-- constants.  If you only wish to execute a sequence as machine code use ##allocate_code()##.  
-- If you only want to read and write data into memory use ##allocate()##.
--
-- See [[http://msdn.microsoft.com/en-us/library/aa366786(VS.85).aspx "MSDN: Microsoft's Memory Protection Constants"]]
--
-- Parameters:
-- # ##data## : is the machine code to be put into memory. 
-- # ##wordsize## : is the size each element of data will take in 
-- memory.  Are they 1-byte, 2-bytes or 4-bytes long?  Specify here.  The default is 1.
-- # ##protection## : is the particular Windows protection.
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
-- [[:allocate_code()]] instead.  It is simpler.
--
-- You must not use [[:free()]] on memory returned from this function, instead use [[:free_code()]].

public function allocate_protect( object data, valid_wordsize wordsize = 1, valid_memory_protection_constant protection )
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

	iaddr = local_allocate_protected_memory( size+BORDER_SPACE*2, first_protection )
	if iaddr = 0 then
		return 0
	end if
	
	-- eaddr is set here
	eaddr = prepare_block( iaddr, size, protection )

	if eaddr = 0 or atom( data ) then
		return eaddr
	end if

	switch wordsize do
		case 1 then
			eu:poke( eaddr, data )
			
		case 2 then
			eu:poke2( eaddr, data )
			
		case 4 then
			eu:poke4( eaddr, data )
			
		case else
			crash("Parameter error: Wrong word size %d in allocate_protect().", wordsize)
			
	end switch
	
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
	
	if local_change_protection_on_protected_memory( iaddr, size+BORDER_SPACE*2, true_protection ) = -1 then
		local_free_protected_memory( iaddr, size+BORDER_SPACE*2 )
		eaddr = 0
	end if
	
	return eaddr
end function



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
-- [[:allocate]], [[:allocate_string]]

public function poke_string(atom buffaddr, integer buffsize, sequence s)
	
	if buffaddr <= 0 then
		return 0
	end if
	
	if not string(s) then
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
-- Stores a C-style null-terminated Double-Byte string in memory
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
-- [[:allocate]], [[:allocate_wstring]]

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
-- ##allocate_wstring##()  for storing double byte encoded strings.
--
-- There is no allocate_string_low() function. However, you could easily
-- craft one by adapting the code for ##allocate_string##.
--
-- Since ##allocate_string##() allocates memory, you are responsible to
-- [[:free]]() the block when done with it if ##cleanup## is zero.
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
--              [[:allocate]], [[:allocate_wstring]]

public function allocate_string(sequence s, boolean cleanup = 0 )
	atom mem
	
	mem = allocate( length(s) + 1) -- Thanks to Igor
	
	if mem then
		poke(mem, s)
		poke(mem+length(s), 0)  -- Thanks to Aku
		if cleanup then
			mem = delete_routine( mem, FREE_RID )
		end if
	end if

	return mem
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
-- [[:allocate_string]]
--
public function allocate_wstring(sequence s, boolean cleanup = 0 )
	atom mem
	
	mem = allocate( 2 * (length(s) + 1) )
	if mem then
		poke2(mem, s)
		poke2(mem + length(s)*2, 0)
		if cleanup then
			mem = delete_routine( mem, FREE_RID )
		end if
	end if
	
	return mem
end function

--**
-- Return a unicode (utf16) string that are stored at machine address a.
--
-- Parameters:
--   # ##addr## : an atom, the address of the string in memory
--
-- Returns:
--   The **string**, at the memory position.  The terminator is the null word (two bytes equal to 0).
--
-- See Also:
-- [[:peek_string]]

public function peek_wstring(atom addr)
	atom ptr = addr
	
	while peek2u(ptr) do
		ptr += 2
	end while
	
	return peek2u({addr, (ptr - addr) / 2})
end function

--****
-- === Memory disposal
--

--**
-- Free up a previously allocated block of memory.
-- @[machine:free]
--
-- Parameters:
--  # ##addr##, either a single atom or a sequence of atoms; these are addresses of a blocks to free.
--
-- Comments:
--  * Use ##free##() to return blocks of memory the during execution. This will reduce the chance of 
--   running out of memory or getting into excessive virtual memory swapping to disk. 
-- * Do not reference a block of memory that has been freed. 
-- * When your program terminates, all allocated memory will be returned to the system.
-- * ##addr## must have been allocated previously using [[:allocate]](). You
--   cannot use it to relinquish part of a block. Instead, you have to allocate
--   a block of the new size, copy useful contents from old block there and
--   then ##free##() the old block.  
-- * If the memory was allocated and automatic cleanup
--   was specified, then do not call ##free()## directly.  Instead, use [[:delete]].
-- * An ##addr## of zero is simply ignored.
--
-- Example 1:
--   ##demo/callmach.ex##
--
-- See Also:
--     [[:allocate]], [[:free_code]]
public procedure free(object addr)
	if number_array (addr) then
		if ascii_string(addr) then
			crash("free(\"%s\") is not a valid address", {addr})
		end if
		
		for i = 1 to length(addr) do
			deallocate(addr[i])
		end for
		return
	elsif sequence(addr) then
		crash("free() called with nested sequence")
	end if
	
	if addr = 0 then
		-- Special case, a zero address is assumed to be an uninitialized pointer,
		-- so it is ignored.
		return
	end if

	deallocate(addr)
end procedure
FREE_RID = routine_id("free")


--****
-- Signature:
-- include std/machine.e
-- public procedure free_code( atom addr, integer size, valid_wordsize wordsize = 1 )
--
-- Description:
-- Frees up allocated code memory
--
-- Parameters:
-- # ##addr## : must be an address returned by [[:allocate_code()]] or [[:allocate_protect()]].  Do **not** pass memory returned from [[:allocate()]] here! 
-- # ##size## : is the length of the sequence passed to ##alllocate_code()## or the size you specified when you called allocate_protect().  
-- # ##wordsize##: valid_wordsize  default = 1
--
-- Comments:
-- Chances are you will not need to call this function because code allocations are typically public scope operations that you want to have available until your process exits.
--
-- See Also: [[:allocate_code]], [[:free]]
