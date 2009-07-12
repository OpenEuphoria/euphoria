--

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


--** 
-- An alias to PAGE_NOACCESS
public constant PAGE_NONE = PAGE_NOACCESS

--**
-- An alias to PAGE_EXECUTE_READ
public constant PAGE_READ_EXECUTE = PAGE_EXECUTE_READ

--**
-- An alias to PAGE_READWRITE
public constant PAGE_READ_WRITE = PAGE_READWRITE

--**
-- An alias to PAGE_READONLY
public constant PAGE_READ = PAGE_READONLY

--**
-- An alias to PAGE_EXECUTE_READWRITE
public constant PAGE_READ_WRITE_EXECUTE = PAGE_EXECUTE_READWRITE

export function test_read( valid_memory_protection_constant protection )
	return find( protection, { PAGE_EXECUTE_READ, PAGE_EXECUTE_READWRITE,  
			PAGE_READWRITE,	PAGE_READONLY } )
end function


export function test_write( valid_memory_protection_constant protection )
	return find( protection, { PAGE_EXECUTE_READWRITE,
		 	PAGE_EXECUTE_WRITECOPY,
		 PAGE_WRITECOPY,
	PAGE_READWRITE})
end function

export function test_exec( valid_memory_protection_constant protection )
	return find(protection,{PAGE_EXECUTE,
		PAGE_EXECUTE_READ,
		PAGE_EXECUTE_READWRITE,
		PAGE_EXECUTE_WRITECOPY})
end function

export type valid_memory_protection_constant( integer x )
	return 0 != find( x, MEMORY_PROTECTION )
end type

export constant MEMORY_PROTECTION = {
	PAGE_EXECUTE,
	PAGE_EXECUTE_READ,
	PAGE_EXECUTE_READWRITE,
	PAGE_EXECUTE_WRITECOPY,
	PAGE_WRITECOPY,
	PAGE_READWRITE,
	PAGE_READONLY,
	PAGE_NOACCESS
}

export type valid_wordsize( integer i )
	return find(i, {1,2,4})!=0
end type

export integer DEP_really_works = 0

-- Windows constants
export constant MEM_COMMIT = #1000,
		MEM_RESERVE = #2000,
		MEM_RESET = #8000,
		MEM_RELEASE = #8000

export integer FREE_RID = routine_id("free")		

export constant
        M_ALLOC = 16,
        M_FREE = 17

export atom kernel_dll, memDLL_id, 
	VirtualAlloc_rid, VirtualLock_rid, VirtualUnlock_rid,
	VirtualProtect_rid, GetLastError_rid, GetSystemInfo_rid

integer page_size = 0

function get_page_size()
	if page_size then
		return page_size
	end if
	if GetSystemInfo_rid != -1 then
		atom system_info_ptr = machine_func(M_ALLOC, 9 * 4)
		eu:c_proc(GetSystemInfo_rid, { system_info_ptr })
		page_size = eu:peek4u( system_info_ptr + 4)
		machine_proc(M_FREE, system_info_ptr)
	end if
	return page_size
end function


