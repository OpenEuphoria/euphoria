--****
-- == Pseudo Memory
--
--
-- One use is to emulate PBR, such as Euphoria's map and stack types.
--
-- <<LEVELTOC level=2 depth=4>>

namespace eumem


--**
-- The (pseudo) RAM heap space. Use [[:malloc]] to gain ownership to a heap location
-- and [[:free]] to release it back to the system.
export sequence ram_space = {}


procedure cleanup_ram_space( object rs )
	ram_space = {}
end procedure

integer ram_free_list = 0
integer free_rid

--**
-- allocates a block of (pseudo) memory.
--
-- Parameters:
-- # ##mem_struct_p## : The initial structure (sequence) to occupy the allocated
-- block. If this is an integer, a sequence of zero this long is used. The default
-- is the number one, meaning that the default initial structure is ##{0}##
-- # ##cleanup_p## : Identifies whether the memory should be released automatically
-- when the reference count for the handle for the allocated block drops to
-- zero, or when passed to ##delete##.  If zero, then the block must be freed
-- using the [[:free]] procedure.
--
-- Returns:
-- A **handle**, to the acquired block. Once you acquire the handle you can use it as needed.
-- Note that if ##cleanup_p## is one, then the variable holding the 
-- handle must be capable of storing an atom (do not use an integer) as a double floating point value.
-- 
-- Example 1:
-- <eucode>
--  my_spot = malloc()
--  ram_space[my_spot] = my_data
-- </eucode>

export function malloc(object mem_struct_p = 1, integer cleanup_p = 1)
	integer temp_

	if atom(mem_struct_p) then
		mem_struct_p = repeat(0, mem_struct_p)
	end if
	if ram_free_list = 0 then
		ram_space = append(ram_space, mem_struct_p)
		if cleanup_p then
			return delete_routine( length(ram_space), free_rid )
		else
			return length(ram_space)
		end if
	end if
	
	temp_ = ram_free_list
	ram_free_list = ram_space[temp_]
	ram_space[temp_] = mem_struct_p

	if cleanup_p then
		return delete_routine( temp_, free_rid )
	else
		return temp_
	end if
end function

--**
-- deallocates a block of (pseudo) memory.
--
-- Parameters:
-- # ##mem_p## : The handle to a previously acquired [[:ram_space]] location.
--
-- Comments:
-- This allows the location to be used by other parts of your application. You 
-- should no longer access this location again because it could be acquired by
-- some other process in your application.  This routine should only be called
-- if you passed zero as ##cleanup_p## to [[:malloc]].
--
-- Example 1:
-- <eucode>
--  my_spot = malloc(1,0)
--  ram_space[my_spot] = my_data
--      -- . . . do some processing  . . . 
--  free(my_spot)
-- </eucode>

export procedure free(atom mem_p)
	if object( ram_space ) then
		if mem_p < 1 then return end if
		if mem_p > length(ram_space) then return end if

		ram_space[mem_p] = ram_free_list
		ram_free_list = floor(mem_p)
	end if
end procedure
free_rid = routine_id("free")

--**
-- validates a block of (pseudo) memory.
--
-- Parameters:
-- # ##mem_p## : The handle to a previously acquired [[:ram_space]] location.
-- # ##mem_struct_p## : If an integer, this is the length of the sequence that
-- should be occupying the ##ram_space## location pointed to by ##mem_p##.
--
-- Returns:
-- An **integer**,\\
-- 0 if either the ##mem_p## is invalid or if the sequence at that location is
-- the wrong length.\\
-- 1 if the handle and contents are okay.
--
-- Comments:
-- This can only check the length of the contents at the location. Nothing else
-- is checked at that location.
--
-- Example 1:
-- <eucode>
--  my_spot = malloc()
--  ram_space[my_spot] = my_data
--  . . . do some processing  . . 
--  if valid(my_spot, length(my_data)) then
--      free(my_spot)
--  end if
-- </eucode>

export function valid(object mem_p, object mem_struct_p = 1)
	if not integer(mem_p) then return 0 end if
	if mem_p < 1 then return 0 end if
	if mem_p > length(ram_space) then return 0 end if
	
	if sequence(mem_struct_p) then return 1 end if
	
	if atom(ram_space[mem_p]) then 
		if mem_struct_p >= 0 then
			return 0
		end if

		return 1
	end if

	if length(ram_space[mem_p]) != mem_struct_p then
		return 0
	end if

	return 1
end function
