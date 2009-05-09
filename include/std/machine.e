-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--

include std/dll.e

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
-- # Getting a routine id so you can pass it to [[:call_back]](). (See [[../docs/platform.txt]])
-- # Getting a routine id so you can pass it to [[:task_create]](). (See [[../docs/tasking.txt]])
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
-- [[:task_create]], [[../docs/platform.txt]], [[../docs/dynamic.txt]]

--****
-- Signature:
-- <built-in> function call_func(integer id, sequence args)
--
-- Description:
--  Call the user-defined Euphoria function by routine id.
--
-- Parameters:
--              # ##id##: an integer, the routine id of the function to call
--              # ##args##: a sequence, the parameters to pass to the function.
--
-- Returns:
-- The value the called function returns.
--
-- Errors:
-- If ##id## is negative or otherwise unknown, an error occurs.
--
-- If the length of ##args## is not the number of patameters the function takes, an error occurs.
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
-- [[../demo/csort.ex]]
--
-- See Also:
-- [[:call_proc]], [[:routine_id]], [[:c_func]]
-- 

--****
-- Signature:
-- <built-in> procedure call_proc(integer id, sequence args)
--
-- Description:
-- Call a user-defined Euphoria procedure by routine id.
--
-- Parameters:
--              # ##id##: an integer, the routine id of the procedure to call
--              # ##args##: a sequence, the parameters to pass to the function.
--
-- Errors:
-- If ##id## is negative or otherwise unknown, an error occurs.
--
-- If the length of ##args## is not the number of patameters the function takes, an error occurs.
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
-- <built-in> function machine_func(integer machine_id, object args)
--
-- Description:
-- Perform a machine-specific operation that returns a value.
--
-- Returns:
-- Depends on the called internal facility.
--
-- Comments:
-- This function us mainly used by the standard library files to implement machine dependent operations.
-- such as graphics and sound effects. This routine should normally be called indirectly
-- via one of the library routines in a Euphoria include file.
-- User programs normally do not need to call ##machine_func##.
--
-- A direct call might cause a machine exception if done incorrectly.
--
-- See Also:
-- [[:machine_func]]

--****
-- Signature:
-- <built-in> procedure machine_proc(integer machine_id, object args)
--
-- Description:
-- Perform a machine-specific operation that does not return a value.
--
-- Comments:
-- This procedure us mainly used by the standard library files to implement machine dependent operations.
-- such as graphics and sound effects. This routine should normally be called indirectly
-- via one of the library routines in a Euphoria include file.
-- User programs normally do not need to call ##machine_proc##.
--
-- A direct call might cause a machine exception if done incorrectly.
--
-- See Also:
-- [[:machine_proc]]

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

ifdef WIN32 then
	--****
	-- === Microsoft's Memory Protection Constants
	--
	-- Memory Protection Constants are the same constants
	-- across all platforms.  The API converts them as
	-- necessary.  They are only necessary for [[:allocate_protect]]

	--**
	-- You may run the data in this page
	public constant PAGE_EXECUTE = #10

	--**
	-- You may read or run the data
	public constant PAGE_EXECUTE_READ = #20

	--**
	-- You may run, read or write in this page
	public constant PAGE_EXECUTE_READWRITE = #40

	--**
	-- You may run or write in this page
	public constant PAGE_EXECUTE_WRITECOPY = #80

	--**
	-- You may write to this page.
	public constant PAGE_WRITECOPY = #08

	--**
	-- You may read or write in this page.
	public constant PAGE_READWRITE = #04

	--**
	-- You may only read data in this page
	public constant PAGE_READONLY = #02

	--**
	-- You have no access to this page
	public constant PAGE_NOACCESS = #01


elsedef

	constant
		PROT_EXEC = 4,
		PROT_READ = 1,
		PROT_WRITE = 2,
		PROT_NONE = 0

	public constant PAGE_EXECUTE = PROT_EXEC,
		PAGE_EXECUTE_READ = or_bits( PROT_READ, PROT_EXEC ),
		PAGE_EXECUTE_READWRITE = or_bits( PROT_READ, or_bits( PROT_EXEC, PROT_WRITE ) ),
		PAGE_EXECUTE_WRITECOPY = or_bits( PROT_READ, or_bits( PROT_EXEC, PROT_WRITE ) ),
		PAGE_WRITECOPY = or_bits( PROT_READ, PROT_WRITE ),
		PAGE_READWRITE = or_bits( PROT_READ, PROT_WRITE ),
		PAGE_READONLY = PROT_READ,
		PAGE_NOACCESS = PROT_NONE

end ifdef

constant MEMORY_PROTECTION = {
	PAGE_EXECUTE,
	PAGE_EXECUTE_READ,
	PAGE_EXECUTE_READWRITE,
	PAGE_EXECUTE_WRITECOPY,
	PAGE_WRITECOPY,
	PAGE_READWRITE,
	PAGE_READONLY,
	PAGE_NOACCESS
}

ifdef WIN32 then
	-- Windows constants
	constant MEM_COMMIT = #1000,
		MEM_RESERVE = #2000,
		--MEM_RESET = #8000,
		MEM_RELEASE = #8000

	atom kernel_dll, memDLL_id, VirtualFree_rid,
		VirtualAlloc_rid, VirtualLock_rid, VirtualUnlock_rid,
		VirtualProtect_rid, GetLastError_rid, GetSystemInfo_rid

	memDLL_id = open_dll( "kernel32.dll" )
	kernel_dll = memDLL_id
	VirtualAlloc_rid = define_c_func( memDLL_id, "VirtualAlloc", { C_POINTER, C_UINT, C_UINT, C_UINT }, C_POINTER )
	VirtualProtect_rid = define_c_func( memDLL_id, "VirtualProtect", { C_POINTER, C_UINT, C_INT, C_POINTER }, C_INT )
	VirtualLock_rid = define_c_func( memDLL_id, "VirtualLock", { C_POINTER, C_UINT }, C_UINT )
	VirtualUnlock_rid = define_c_func( memDLL_id, "VirtualUnlock", { C_POINTER, C_UINT }, C_UINT )
	GetLastError_rid = define_c_func( kernel_dll, "GetLastError", {}, C_UINT )
	GetSystemInfo_rid = define_c_proc( kernel_dll, "GetSystemInfo", { C_POINTER } )
	VirtualFree_rid = define_c_func( kernel_dll, "VirtualFree", { C_POINTER, C_UINT, C_INT }, C_UINT )

	integer page_size = 0
	function get_page_size()
		if page_size then
			return page_size
		end if
		if GetSystemInfo_rid != -1 then
			atom system_info_ptr = allocate( 9 * 4 )
			c_proc( GetSystemInfo_rid, { system_info_ptr } )
			page_size = peek4u( system_info_ptr + 4 )
			free( system_info_ptr )
		end if
		return page_size
	end function
	public constant PAGE_SIZE = get_page_size()
elsedef
	public constant PAGE_SIZE = -1

end ifdef

ifdef WIN32 then
	function VirtualAlloc( atom addr, atom size, atom flallocationtype, atom flprotect )
		atom r1
		r1 = c_func( VirtualAlloc_rid, {addr, size, flallocationtype, flprotect } )
		return r1
	end function
end ifdef

type valid_windows_memory_protection_constant( integer x )
	return 0 != find( x, MEMORY_PROTECTION )
end type

type page_aligned_address( atom a )
	return remainder( a, 4096 ) = 0
end type

--****
-- === Allocating and Writing to memory:

--**
-- Allocates and copies data into executible memory.
--
-- Parameters:
-- The parameter, ##a_sequence_of_machine_code_bytes##, is the machine code to be put into memory to be later called with [[:call()]]        
--
-- Return Value:
-- The function returns the address in memory of the byte-code that can be safely executed whether DEP is enabled or not or 0 if it fails.  On the other hand, if you try to execute a code address returned by [[:allocate()]] with DEP enabled the program will receive a machine exception.  
--
-- Comments:
-- 
-- Use this for the machine code you want to run in memory.  The copying is done for you and when the routine returns the memory may not be readable or writable but it is guaranteed to be executable.  If you want to also write to this memory **after the machine code has been copied** you should use [[:allocate_protect()]] instead and you should read about having memory executable and writable at the same time is a bad idea.  You mustn't use ##free()## on memory returned from this function.  You may instead
-- use ##free_code()## but since you will probably need the code througout the life of your program's process this normally is not necessary.
-- If you want to put only data in the memory to be read and written use [[:allocate]].
-- See Also:
-- [[:allocate]], [[:free_code]], [[:allocate_protect]]

public function allocate_code( sequence data )
	atom addr, oldprotptr
	integer size

	size = length(data)

	if dep_works() then
		ifdef WIN32 then
			addr = VirtualAlloc( 0, size, or_bits( MEM_RESERVE, MEM_COMMIT ), PAGE_READWRITE )
			oldprotptr = allocate(4)

			-- Windows 98 has VirtualAlloc but its VirtualAlloc always returns 0
			-- The following three lines are a kludge for Windows 9x
			-- Including os.e caused in r1338.
			if addr = 0 then
				addr = allocate( size )
			else
				register_block( addr, size )
			end if

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

		end ifdef

	end if

	addr = allocate( size )
	if addr = 0 then
		return 0
	end if

	poke( addr, data )

	return addr
end function

--**
-- Allocates and copies data into memory and gives it protection using [[:Microsoft's Memory Protection Constants]].  The user may only pass in one of these constants.  If you only wish to execute a sequence as machine code use ##allocate_code()##.  If you only want to read and write data into memory use ##allocate()##.
--
-- See <a href="http://msdn.microsoft.com/en-us/library/aa366786(VS.85).aspx">Microsoft's Memory Protection Constants<br>
-- http://msdn.microsoft.com/en-us/library/aa366786(VS.85).aspx</a><p>
--
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

	if dep_works() then
		ifdef WIN32 then
			addr = c_func( VirtualAlloc_rid, { 0, size, or_bits( MEM_RESERVE, MEM_COMMIT ), PAGE_READWRITE } )
			if addr = 0 then
				return 0
			end if

			register_block( addr, size )

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

		end ifdef
	end if

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

-- Returns 1 if the DEP executing data only memory would cause an exception
function dep_works()
	ifdef WIN32 then
		return VirtualAlloc_rid != -1 and VirtualProtect_rid != -1 and
		    GetLastError_rid != -1 and GetSystemInfo_rid != -1			
	end ifdef

	return 0
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

public procedure free_code( atom addr, integer size )
	integer free_succeeded
	if not dep_works() then
		free( addr )
		return
	end if

	ifdef WIN32 then
		free_succeeded = c_func( VirtualFree_rid, { addr, size, MEM_RELEASE } )
	end ifdef

	unregister_block( addr )
end procedure
