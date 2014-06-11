--****
-- == Memory Management - Low-Level
--
-- <<LEVELTOC level=2 depth=4>>
--
-- === Usage Notes

namespace memory

--**
-- @nodoc@
public include std/memconst.e

ifdef BITS64 then
    -- biggest address on a 64-bit machine 
    constant MAX_ADDR = power(2, 48)-1 
elsedef 
    -- biggest address on a 32-bit machine 
    constant MAX_ADDR = power(2, 32)-1 
end ifdef

ifdef DATA_EXECUTE or not WINDOWS  then
	include std/machine.e
end ifdef

without warning &= (not_used)
--**
-- @nodoc@
public integer edges_only 

--**
-- Positive integer type

--**
-- @nodoc@
export type positive_int(object x)

	if not integer(x) then
		return 0
	end if
    return x >= 1
end type

--**
-- Machine address type

--**
-- @nodoc@
public type machine_addr(object a)-- a 32-bit non-null machine address 

	if not atom(a) then
		return 0
	end if
	
	if not integer(a)then
		if floor(a) != a then
			return 0
		end if
	end if
	
	return a > 0 and a <= MAX_ADDR
end type

--**
-- @nodoc@
-- Internal use of the library only.  free() calls this.  It works with
-- only atoms and in the SAFE implementation is different.
--**
-- @nodoc@
export procedure deallocate(atom addr)
	ifdef DATA_EXECUTE then
		ifdef WINDOWS then
			if dep_works() then
				c_func( VirtualFree_rid, { addr, 1, MEM_RELEASE } )
				return
			end if
		elsedef
			c_func( MUNMAP, { addr, 1 } )
			return
		end ifdef
	end ifdef
   	machine_proc( memconst:M_FREE, addr)
end procedure
memconst:FREE_RID = routine_id("deallocate")



without warning
--**
-- @nodoc@
public integer check_calls = 1

--****
-- === Safe memory access

without warning strict

--**
-- @nodoc@
public procedure register_block(atom block_addr, atom block_len, integer protection )	-- Only implemented in safe.e

end procedure

without warning strict

--**
-- @nodoc@
public procedure unregister_block(atom block_addr)	-- Only implemented in safe.e

end procedure

without warning strict

--**
-- @nodoc@
public function safe_address(atom start, integer len, positive_int action)	-- Only implemented in safe.e

	return 1
end function

without warning strict
--**
-- @nodoc@
public procedure check_all_blocks()	-- Only implemented in safe.e

end procedure

without warning strict
--**
-- @nodoc@
export function prepare_block( atom addr, integer a, integer protection )

	-- Only implemented in safe.e
	return addr
end function

--**
-- @nodoc@
export constant BORDER_SPACE = 0

--**
-- @nodoc@
export constant leader = repeat('@', BORDER_SPACE)

--**
-- @nodoc@
export constant trailer = repeat('%', BORDER_SPACE)


--**
-- @nodoc@
export type bordered_address( object addr )

	if not atom(addr) then
		return 0
	end if
	return 1
end type


with warning

--**
-- @nodoc@
-- Returns 1 if the DEP executing data only memory would cause an exception
--**
-- @nodoc@
export function dep_works()

	ifdef WINDOWS then
		return (DEP_really_works and use_DEP)
	end ifdef

	return 1
end function

--**
-- @nodoc@
export atom VirtualFree_rid


--**
-- @nodoc@
public procedure free_code( atom addr, integer size, valid_wordsize wordsize = 1 )	ifdef WINDOWS then

		if dep_works() then
			c_func(VirtualFree_rid, { addr, size*wordsize, MEM_RELEASE })
		else
			machine_proc( memconst:M_FREE, addr)
		end if
	elsedef
		c_func( MUNMAP, { addr, size * wordsize } )
	end ifdef
end procedure
