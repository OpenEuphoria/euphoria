-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
ifdef not UNIX then
	crash("Only supported on Unix systems!")
end ifdef

include std/dll.e

ifdef SAFE then
	public include std/safe.e
elsedef
	public include std/memory.e
end ifdef

public constant
	PROT_EXEC = 4,
	PROT_READ = 1,
	PROT_WRITE = 2,
	PROT_NONE = 0

-- not public to avoid conflicting with constants in machine.e
constant PAGE_EXECUTE = PROT_EXEC,
	PAGE_EXECUTE_READ = or_bits( PROT_READ, PROT_EXEC ),
	PAGE_EXECUTE_READWRITE = or_bits( PROT_READ, or_bits( PROT_EXEC, PROT_WRITE ) ),
	PAGE_EXECUTE_WRITECOPY = or_bits( PROT_READ, or_bits( PROT_EXEC, PROT_WRITE ) ),
	PAGE_WRITECOPY = or_bits( PROT_READ, PROT_WRITE ),
	PAGE_READWRITE = or_bits( PROT_READ, PROT_WRITE ),
	PAGE_READONLY = PROT_READ,
	PAGE_NOACCESS = PROT_NONE

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

public constant MAP_ANONYMOUS = #20, MAP_PRIVATE = #2
,MAP_SHARED = #1, MAP_TYPE = #F, MAP_FIXED = #10,
MAP_FILE = 0
atom getpagesize_rid, mmap_rid, mprotect_rid, munmap_rid,
	mlock_rid, munlock_rid

getpagesize_rid = define_c_func( -1, "getpagesize", { }, C_UINT )
mmap_rid = define_c_func( -1, "mmap", { C_POINTER, C_UINT, C_INT, C_INT, C_INT, C_INT }, C_POINTER )
mprotect_rid = define_c_func( -1, "mprotect", { C_POINTER, C_UINT, C_INT }, C_INT )
munmap_rid = define_c_func( -1, "munmap", { C_POINTER, C_UINT }, C_INT )
mlock_rid = define_c_func( -1, "mlock", { C_POINTER, C_UINT }, C_INT )
munlock_rid = define_c_func( -1, "munlock", { C_POINTER, C_UINT }, C_INT )

public function get_page_size()
	return c_func( getpagesize_rid, {} )
end function

public function mmap( object start, integer length, integer protection, integer flags, integer fd, integer offset )
	atom pc
	if atom( start ) then
		return c_func( mmap_rid, { start, length, protection, flags, fd, offset } )
	else
		pc = mmap( 0, length, protection, flags, fd, offset )
		poke( pc, start )
		return pc
	end if
end function

public function munmap( atom addr, integer length )
	return c_func( munmap_rid, { addr, length } )
end function

public function mlock( atom addr, integer length )
	return c_func( mlock_rid, { addr, length } )
end function

public function munlock( atom addr, integer length )
	return c_func( munlock_rid, { addr, length } )
end function

public function mprotect( atom addr, integer length, integer flags )
	return c_func( mprotect_rid, { addr, length, flags } )
end function

public function is_valid_memory_protection_constant( integer x )
	return 0 != find( x, MEMORY_PROTECTION )
end function

public function is_page_aligned_address( atom a )
	return remainder( a, 4096 ) = 0
end function

