-- (c) Copyright - See License.txt
--
namespace machine

include std/dll.e
include std/error.e
public include std/memconst.e

ifdef SAFE then
	public include std/safe.e

	ifdef DOS32 then
		public include std/dos/safe.e
	end ifdef
elsedef
	public include std/memory.e

	ifdef DOS32 then
		public include std/dos/memory.e
	end ifdef
end ifdef

integer FREE_ARRAY_RID

type block_aligned( atom a )
	return remainder(a,4096)=0
end type

--**
-- Allocate a C-style null-terminated string in memory
--
-- Parameters:
--              # ##s##, a sequence, the string to store in RAM.
--              # ##cleanup##, an integer, if non-zero, then the returned pointer will be
--                automatically freed when its reference count drops to zero, or
--                when passed as a parameter to [[:delete]].  
--
-- Returns:
--              An **atom**, the address of the memory block where the string was
-- stored, or 0 on failure.
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
--              [[:allocate]], [[:allocate_low]], [[:allocate_wstring]]

--**
-- Allocate a NULL terminated pointer array.
--
-- Parameters:
--   # #pointers# - A sequence of pointers to add to the pointer array.
--   # ##cleanup##, an integer, if non-zero, then the returned pointer will be
--     automatically freed when its reference count drops to zero, or
--     when passed as a parameter to [[:delete]]
--
-- Comments:
--   This function adds the NULL terminator.
--
-- Example 1:
-- <eucode>
-- atom pa = allocate_pointer_array({ allocate_string("1"), allocate_string("2") })
-- </eucode>
--
-- See Also:
--   [[:allocate_string_pointer_array]], [[:free_pointer_array]]

public function allocate_pointer_array(sequence pointers, integer cleanup = 0)
    atom pList

    if atom(pointers) then
        return 0
    end if

    pointers &= 0
    pList = allocate(length(pointers) * 4)
    poke4(pList, pointers)
	if cleanup then
		return delete_routine( pList, FREE_ARRAY_RID )
	end if
    return pList
end function

public procedure free_pointer_array(atom pointers_array)
	atom saved = pointers_array,
		ptr = peek4u(pointers_array)

	while ptr do
		free(ptr)

		pointers_array+=4
		ptr = peek4u(pointers_array)
	end while

	free(saved)
end procedure
FREE_ARRAY_RID = routine_id("free_pointer_array")

--**
-- Allocate a C-style null-terminated array of strings in memory
--
-- Parameters:
--   # #string_list# - sequence of strings to store in RAM.
--   # ##cleanup##, an integer, if non-zero, then the returned pointer will be
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

public function allocate_string_pointer_array(object string_list, integer cleanup = 0)
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
-- == Dynamic Calling
--
-- <<LEVELTOC depth=2>>
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
--              # ##routine_name##: a string, the name of the procedure or function.
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
-- Some typical uses of routine_id() are:
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
-- [[:task_create]], [[:Platform-Specific Issues]], [[:Dynamic routine calling]]

--****
-- Signature:
-- <built-in> function call_func(integer id, sequence args={})
--
-- Description:
--  Call the user-defined Euphoria function by routine id.
--
-- Parameters:
--   # ##id##: an integer, the routine id of the function to call
--   # ##args##: a sequence, the parameters to pass to the function.
--
-- Returns:
-- The value the called function returns.
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
-- synthesized while making a dynamic call.
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
--   # ##id##: an integer, the routine id of the procedure to call
--   # ##args##: a sequence, the parameters to pass to the function.
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
-- synthesized while making a dynamic call.
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
-- === Accessing Euphoria internals dynamically

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
-- [[:machine_func]]

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
-- [[:machine_proc]]


ifdef WIN32 then

	atom kernel_dll, memDLL_id, 
		VirtualAlloc_rid, 
		-- VirtualLock_rid, VirtualUnlock_rid,
		VirtualProtect_rid, GetLastError_rid, GetSystemInfo_rid

	memDLL_id = open_dll( "kernel32.dll" )
	kernel_dll = memDLL_id
	VirtualAlloc_rid = define_c_func( memDLL_id, "VirtualAlloc", { C_POINTER, C_UINT, C_UINT, C_UINT }, C_POINTER )
	VirtualProtect_rid = define_c_func( memDLL_id, "VirtualProtect", { C_POINTER, C_UINT, C_INT, C_POINTER }, C_INT )
	-- VirtualLock_rid = define_c_func( memDLL_id, "VirtualLock", { C_POINTER, C_UINT }, C_UINT )
	-- VirtualUnlock_rid = define_c_func( memDLL_id, "VirtualUnlock", { C_POINTER, C_UINT }, C_UINT )
	GetLastError_rid = define_c_func( kernel_dll, "GetLastError", {}, C_UINT )
	GetSystemInfo_rid = define_c_proc( kernel_dll, "GetSystemInfo", { C_POINTER } )
	VirtualFree_rid = define_c_func( kernel_dll, "VirtualFree", { C_POINTER, C_UINT, C_INT }, C_UINT )
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

	integer page_size = 0
	if GetSystemInfo_rid != -1 then
		bordered_address system_info_ptr = allocate( 9 * 4 )
		if system_info_ptr != 0 then
			c_proc( GetSystemInfo_rid, { system_info_ptr } )
			page_size = peek4u( system_info_ptr + 4 )
--			free( system_info_ptr )
			machine_proc(M_FREE, system_info_ptr)
		end if
	end if
	public constant PAGE_SIZE = page_size
elsedef
	public constant PAGE_SIZE = -1

end ifdef

ifdef WIN32 then
	function VirtualAlloc( atom addr, atom size, atom allocation_type, atom protect_ )
		atom r1
		r1 = c_func( VirtualAlloc_rid, {addr, size, allocation_type, protect_ } )
		return r1
	end function
end ifdef

--***
-- == Types supporting Memory

--** protection constants type
public type valid_memory_protection_constant( integer x )
	return 0 != find( x, MEMORY_PROTECTION )
end type

--** page aligned address type
export type page_aligned_address( atom a )
	return remainder( a, 4096 ) = 0
end type

--****
-- === Allocating and Writing to memory:

--**
-- Allocates and copies data into executable memory.
--
-- Parameters:
-- The first parameter, ##a_sequence_of_machine_code##, is the machine code to
-- be put into memory to be later called with [[:call()]]        
--
-- The second parameter is the word length of the said code.  You can specify your
-- code as 1-byte, 2-byte or 4-byte chunks if you wish.  If your machine code is byte
-- code specify 1.  The default is 1.
--
-- Return Value:
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
-- The type will return 1 if the parameter was returned
-- from one of these functions (and has not yet been freeed)
--
-- Comments:
-- This type is equivalent to atom unless SAFE is defined.
-- Only values that satisfy this type may be passed into
-- free or free_code.
public type std_library_address( atom addr ) 
	ifdef not SAFE then
		return 1
	elsedef
		return (addr = 0) or bordered_address(addr)
	end ifdef
end type

std_library_address oldprotptr = allocate_data(4)

public function allocate_string(sequence s, integer cleanup = 0 )
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
-- Allocates and copies data into memory and gives it protection using [[:Microsoft's Memory Protection Constants]].  The user may only pass in one of these constants.  If you only wish to execute a sequence as machine code use ##allocate_code()##.  If you only want to read and write data into memory use ##allocate()##.
--
-- See [[http://msdn.microsoft.com/en-us/library/aa366786(VS.85).aspx "Microsoft's Memory Protection Constants"]]
--
-- Parameters:
-- The first parameter, data, is the machine code to be put into memory. 
-- The second parameter, wordsize, is the size each element of data will take in 
-- memory.  Are they 1-byte, 2-bytes or 4-bytes long?  Specify here.  The default is 1.
-- The third and last parameter is the particular Windows protection.
--
-- Returns:
-- The function returns the address to the required memory
-- or 0 if it fails.  This function is guaranteed to return memory on 
-- the 4 byte boundary.  It also guarantees that the memory returned with 
-- at least the protection given (but you may get more).
--
-- If you want to call ##allocate_protect( data, PAGE_READWRITE )##, you can use 
-- [[:allocate]] instead.  It is more efficient and simpler.
--
-- If you want to call ##allocate_protect( data, PAGE_EXECUTE )##, you can use 
-- [[:allocate_code()]] instead.  It is simpler.
--
-- You mustn't use [[:free()]] on memory returned from this function, instead use [[:free_code()]].

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

	ifdef WIN32 then
		if dep_works() then
			iaddr = eu:c_func(VirtualAlloc_rid, 
				{ 0, size+BORDER_SPACE*2, or_bits( MEM_RESERVE, MEM_COMMIT ), first_protection })
		else
			iaddr = machine_func(M_ALLOC, size+BORDER_SPACE*2)
		end if
	elsedef 
		iaddr = machine_func(M_ALLOC, size+BORDER_SPACE*2)
	end ifdef
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
			crash("logic error: Wrong word size %d in allocate_protect", wordsize)
			
	end switch
	

	ifdef WIN32 then
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
		if dep_works() then
			if eu:c_func( VirtualProtect_rid, { iaddr, size, true_protection , oldprotptr } ) = 0 then
				-- 0 indicates failure here
				c_proc(VirtualFree_rid, { iaddr, size, MEM_RELEASE })
				return 0
			end if
		end if
	end ifdef

	return eaddr
end function



--****
-- === Memory disposal
--

--**
-- Frees up allocated code memory
--
-- Parameters:
-- ##addr## must be an address returned by [[:allocate_code()]] or [[:allocate_protect()]].  Do **not** pass memory returned from [[:allocate()]] here!   
-- The ##size## is the length of the sequence passed to ##alllocate_code()## or the size you specified when you called allocate_protect().                           
--
-- Comments:
-- Chances are you will not need to call this function because code allocations are typically public scope operations that you want to have available until your process exits.
--
-- See Also: [[:allocate_code]], [[:free]]


