--****
-- == Memory Constants
--
-- <<LEVELTOC level=2 depth=4>>
--

namespace memconst

--****
-- === Microsoft Windows Memory Protection Constants === @[microsoftsmemoryprotectionconstants]
-- These constant names are taken right from Microsoft's Memory Protection constants.

ifdef WINDOWS then
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

--****
-- === Standard Library Memory Protection Constants === @[stardardlibrarymemoryprotectionconstants]
--
-- 
-- Memory Protection Constants are the same constants names and meaning
-- across all platforms yet possibly of different numeric value.
-- They are only necessary for [[:allocate_protect]]
--
-- The constant names are created like this:  You have four aspects of protection 
-- READ, WRITE, EXECUTE and COPY.
-- You take the word PAGE and you concatonate an underscore and the aspect
-- in the order above.  For example: PAGE_WRITE_EXECUTE
-- The sole exception to this nomenclature is when you will have no acesss to the page the 
-- constant is called PAGE_NONE.

--** 
-- You have no access to this page.
public constant PAGE_NONE = PAGE_NOACCESS

--**
-- You may read or run the data
-- An alias to PAGE_EXECUTE_READ
public constant PAGE_READ_EXECUTE = PAGE_EXECUTE_READ

--**
-- You may read or write to this page
-- An alias to PAGE_READWRITE
public constant PAGE_READ_WRITE = PAGE_READWRITE

--**
-- You may only read to this page
-- An alias to PAGE_READONLY
public constant PAGE_READ = PAGE_READONLY

--**
-- You may run, read or write in this page
-- An alias to PAGE_EXECUTE_READWRITE
public constant PAGE_READ_WRITE_EXECUTE = PAGE_EXECUTE_READWRITE

--**
-- You may run or write to this page.  Data
-- will copied for use with other processes when
-- you first write to it.
public constant PAGE_WRITE_EXECUTE_COPY = PAGE_EXECUTE_WRITECOPY 

--**
-- You may write to this page.  Data
-- will copied for use with other processes when
-- you first write to it.
public constant PAGE_WRITE_COPY = PAGE_WRITECOPY



--**
-- @nodoc@
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

--**
-- @nodoc@
public type valid_memory_protection_constant( object x )
	return find( x, MEMORY_PROTECTION )
end type

--**
-- @nodoc@
export function test_read( valid_memory_protection_constant protection )
	-- does this protection allow for reading?
	ifdef UNIX then
		-- take advantage of the use of bit fields in UNIX for protections
		return and_bits(PROT_READ,protection) != 0
	elsedef
		return find( protection, { PAGE_EXECUTE_READ, PAGE_EXECUTE_READWRITE,  
				PAGE_READWRITE,	PAGE_READONLY } )
	end ifdef			
end function

--**
-- @nodoc@
export function test_write( valid_memory_protection_constant protection )
	-- does this protection allow for writing?
	ifdef UNIX then
		-- take advantage of the use of bit fields in UNIX for protections
		return and_bits(PROT_WRITE,protection) != 0
	elsedef
		return find( protection, { PAGE_EXECUTE_READWRITE,
				PAGE_EXECUTE_WRITECOPY,
			PAGE_WRITECOPY,
		PAGE_READWRITE})
	end ifdef
end function

--**
-- @nodoc@
export function test_exec( valid_memory_protection_constant protection )
	-- does this protection allow for executing?
	ifdef UNIX then
		-- take advantage of the use of bit fields in UNIX for protections
		return and_bits(PROT_EXEC,protection) != 0
	elsedef
		return find(protection,{PAGE_EXECUTE,
			PAGE_EXECUTE_READ,
			PAGE_EXECUTE_READWRITE,
			PAGE_EXECUTE_WRITECOPY})
	end ifdef
end function

--**
-- @nodoc@
export type valid_wordsize( object i )
	return find(i, {1,2,4})
end type

--**
-- @nodoc@
export integer DEP_really_works = 0
--**
-- @nodoc@
export integer use_DEP = 1

--**
-- @nodoc@
-- Windows constants
export constant MEM_COMMIT = #1000,
		MEM_RESERVE = #2000,
		MEM_RESET = #80000,
		MEM_RELEASE = #8000

--**
-- @nodoc@
export integer FREE_RID		

--**
-- @nodoc@
public enum A_READ = 1, A_WRITE = 2, A_EXECUTE = 3

--**
-- @nodoc@
export constant
        M_ALLOC = 16,
        M_FREE = 17

--**
-- @nodoc@
export atom kernel_dll, memDLL_id, 
	VirtualAlloc_rid, VirtualLock_rid, VirtualUnlock_rid,
	VirtualProtect_rid, GetLastError_rid, GetSystemInfo_rid
