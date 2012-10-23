--****
-- == Safe Machine Level Access
--
-- <<LEVELTOC level=2 depth=4>>
--

namespace safe

atom allocation_num = 0

constant C_POINTER = #03000001
function address_space()
	if sizeof( C_POINTER ) = 4 then
		return power(2, 32) - 1
	else
		return power(2, 48 ) - 1
	end if
end function
-- biggest address on a 32-bit machine

constant MAX_ADDR = address_space()

--**
-- @nodoc@
export constant BORDER_SPACE = 40

--**
-- @nodoc@
export constant leader = repeat('@', BORDER_SPACE)

--**
-- @nodoc@
export constant trailer = repeat('%', BORDER_SPACE)

--**
-- @nodoc@
public integer check_calls = 1


--**
-- @nodoc@
public integer edges_only = (platform()=2) 
				  
-- Constants that tell us what we are about to try to do: read, write or execute memory.  
-- They should be distinct from PERM_EXEC, etc...
-- These are not permission constants.

-- Internal types for understanding more than type-checking:

-- internal address
-- addresses used for passing to and getting from low level machine_func calls and to a few
-- local only routines.
type int_addr(object a)
	return machine_addr(a)
end type

-- external address
-- addresses used for passing to and getting from high level functions in machine.e and 
-- public functions declared here.
type ext_addr(object a)
	return machine_addr(a)
end type


-- Include the starting address and length of any 
-- acceptable areas of memory for peek/poke here. 
-- Set allocation number to 0.
-- This symbol is *only* available from std/machine.e when SAFE is defined.
--**
-- @nodoc@
public sequence safe_address_list = {}

enum BLOCK_ADDRESS, BLOCK_LENGTH, ALLOC_NUMBER, BLOCK_PROT

with type_check

constant OK = 1, BAD = 0
constant
	M_FREE = 17,
	M_SLEEP = 64

--**
-- @nodoc@
public include std/memconst.e
include std/error.e
ifdef WINDOWS then
	include std/win32/sounds.e
elsedef
	include std/machine.e
end ifdef

puts(1, "\n\t\tUsing Debug Version of machine.e\n")
-- machine_proc(M_SLEEP, 3)

-- biggest address accessible to 16-bit real mode
constant LOW_ADDR = power(2, 20)-1

--**
-- @nodoc@
export type positive_int(object x)
	if not integer(x) then
		return 0
	end if
    return x >= 1
end type

type natural(object x)
	if not integer(x) then
		return 0
	end if
	return x >= 0
end type

--**
-- @nodoc@
public type machine_addr(object a)
-- a 32-bit non-null machine address 
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

type far_addr(sequence a)
-- protected mode far address {seg, offset}
	return length(a) = 2 and integer(a[1]) and machine_addr(a[2])
end type

type low_machine_addr(atom a)
-- a legal low machine address 
	return a > 0 and a <= LOW_ADDR and floor(a) = a
end type

-- **
-- @devdoc@

--**
-- @nodoc@
export type bordered_address(ext_addr addr )
	sequence l
	for i = 1 to length(safe_address_list) do
		if safe_address_list[i][BLOCK_ADDRESS] = addr then
			l = eu:peek( {addr - BORDER_SPACE, BORDER_SPACE} )
			return equal(l, leader)
		end if
	end for
	return 0
end type

-- Return true if /action/ is not allowed when memory has /protection/
function does_not_permit(valid_memory_protection_constant protection, positive_int action)
	if action = A_READ and not test_read( protection ) then
		return 1
	elsif action = A_WRITE and not test_write( protection ) then
		return 1
	elsif action = A_EXECUTE and not test_exec( protection ) then
		return 1
	else
		return 0
	end if
end function

-- Return true if /action/ is allowed when memory has /protection/
function permits(valid_memory_protection_constant protection, positive_int action)
	return not does_not_permit(protection,action)
end function

--**
-- @nodoc@
public function safe_address(machine_addr start, natural len, positive_int action )
-- is it ok to read/write all addresses from start to start+len-1?
-- Note:  This routine is available from std/machine.e *only* when SAFE
-- is defined.
	atom block_start, block_upper, upper
	sequence block
	
	if len = 0 then
		return OK
	end if
	
	upper = start + len
	-- search the list of safe memory blocks:
	for i = 1 to length(safe_address_list) do
		block = safe_address_list[i]
		block_start = block[BLOCK_ADDRESS]
		if edges_only then
			-- addresses are considered safe as long as 
			-- they aren't in any block's border zone and
			-- if they are in a block, the action is permitted
			-- for that block's protection
			if start <= 3 then
				return BAD -- null pointer (or very small address)
			end if
			if block[ALLOC_NUMBER] >= 1 then
				-- an allocated block with a border area
				block_upper = block_start + block[BLOCK_LENGTH]
				if (start >= block_start - BORDER_SPACE and 
					start < block_start) or 
				   (start >= block_upper and 
					start < block_upper + BORDER_SPACE) then
					return BAD
				
				elsif (upper > block_start - BORDER_SPACE and
					   upper <= block_start) or
					  (upper > block_upper and
					  upper < block_upper + BORDER_SPACE) then
					return BAD
				
				elsif start < block_start - BORDER_SPACE and
					upper > block_upper + BORDER_SPACE then
					return BAD
				end if
			end if
			if ( (block_start <= start and start <= block_upper) or
				(block_start <= upper and upper <= block_upper)  )
				and
				does_not_permit( block[BLOCK_PROT], action )
				then
				return BAD
			end if
		else
			-- addresses are considered safe as long as 
			-- they are inside an allocated or registered block
			-- whose protection permits the current action.
			if start >= block_start then 
				block_upper = block_start + block[BLOCK_LENGTH]
				if upper <= block_upper then
					if i > 1 then
						-- move block i to the top and move 1..i-1 down
						if i = 2 then
							-- common case, subscript is faster than slice:
							safe_address_list[2] = safe_address_list[1]
						else
							safe_address_list[2..i] = safe_address_list[1..i-1]
						end if
						safe_address_list[1] = block
					end if
					if does_not_permit( block[BLOCK_PROT], action ) then
						return BAD
					else
						return OK
					end if
				end if
			end if
		end if
	end for
	if edges_only then
		return OK  -- not found in any border zone
	else
		return BAD -- not found in any safe block
	end if
end function

procedure die(sequence msg)
-- Terminate with a message.
-- makes warning beeps first so you can see what's happening on the screen
	for i = 1 to 3 do
		ifdef WINDOWS then
			sound()
		end ifdef
		machine_func(M_SLEEP,0.1)
		ifdef WINDOWS then
			sound(0)
		end ifdef
		machine_func(M_SLEEP,0.1)
	end for
	error:crash(msg)
end procedure

function bad_address(atom a)
-- show address in decimal and hex  
	return sprintf(" ADDRESS!!!! %d (#%08x)", {a, a})
end function

without warning &= (override)

--**
-- @nodoc@
override function peek(object x)
-- safe version of peek 
	integer len
	atom a
	
	if atom(x) then
		len = 1
		a = x
	else
		len = x[2]
		if len = 0 then
			return {}
		end if
		a = x[1]
	end if
	if safe_address(a, len, A_READ) then
		return eu:peek(x)
	else
		die("BAD PEEK" & bad_address(a))
	end if
end function

--**
-- @nodoc@
override function peeks(object x)
-- safe version of peeks
	integer len
	atom a
	
	if atom(x) then
		len = 1
		a = x
	else
		len = x[2]
		if len = 0 then
			return {}
		end if
		a = x[1]
	end if
	if safe_address(a, len, A_READ) then
		return eu:peeks(x)
	else
		die("BAD PEEK" & bad_address(a))
	end if
end function

--**
-- @nodoc@
override function peek2u(object x)
-- safe version of peek 
	integer len
	atom a
	
	if atom(x) then
		len = 2
		a = x
	else
		len = x[2] * 2
		if len = 0 then
			return {}
		end if
		a = x[1]
	end if
	if safe_address(a, len, A_READ) then
		return eu:peek2u(x)
	else
		die("BAD PEEK2U" & bad_address(a))
	end if
end function

--**
-- @nodoc@
override function peek2s(object x)
-- safe version of peek 
	integer len
	atom a
	
	if atom(x) then
		len = 2
		a = x
	else
		len = x[2] * 2
		if len = 0 then
			return {}
		end if
		a = x[1]
	end if
	if safe_address(a, len, A_READ) then
		return eu:peek2s(x)
	else
		die("BAD PEEK2S" & bad_address(a))
	end if
end function

--**
-- @nodoc@
override function peek4s(object x)
-- safe version of peek4s 
	integer len
	atom a
	
	if atom(x) then
		len = 4
		a = x
	else
		len = x[2]*4
		if len = 0 then
			return {}
		end if
		a = x[1]
	end if
	if safe_address(a, len, A_READ) then
		return eu:peek4s(x)
	else
		die("BAD PEEK4S" & bad_address(a))
	end if
end function

--**
-- @nodoc@
override function peek4u(object x)
-- safe version of peek4u 
	integer len
	atom a
	
	if atom(x) then
		len = 4
		a = x
	else
		len = x[2]*4
		if len = 0 then
			return {}
		end if
		a = x[1]
	end if
	if safe_address(a, len, A_READ) then
		return eu:peek4u(x)
	else
		die("BAD PEEK4U" & bad_address(a))
	end if
end function


--**
-- @nodoc@
override function peek_string(object x)
-- safe version of peek_string 
	integer len
	atom a = x
	
	len = 1
	while 1 do
		if safe_address( a, len, A_READ ) then
			if not eu:peek( a + len - 1 ) then
				exit
			else
				len += 1
			end if
		else
			die("BAD PEEK_STRING" & bad_address(a))
		end if
	end while
	return eu:peek_string(x)
end function


--**
-- @nodoc@
override procedure poke(atom a, object v)
-- safe version of poke 
	integer len
	
	if atom(v) then
		len = 1
	else
		len = length(v)
		if len = 0 then
			return
		end if
	end if
	if safe_address(a, len, A_WRITE) then
		eu:poke(a, v)
	else
		die("BAD POKE" & bad_address(a))
	end if
end procedure

--**
-- @nodoc@
override procedure poke2(atom a, object v)
-- safe version of poke2 
	integer len
	
	if atom(v) then
		len = 2
	else
		len = length(v) * 2
		if len = 0 then
			return
		end if
	end if
	if safe_address(a, len, A_WRITE) then
		eu:poke2(a, v)
	else
		die("BAD POKE" & bad_address(a))
	end if
end procedure

--**
-- @nodoc@
override procedure poke4(atom a, object v)
-- safe version of poke4 
	integer len
	
	if atom(v) then
		len = 4
	else
		len = length(v)*4
		if len = 0 then
			return
		end if
	end if
	if safe_address(a, len, A_WRITE) then
		eu:poke4(a, v)
	else
		die("BAD POKE4" & bad_address(a))
	end if
end procedure

--**
-- @nodoc@
override procedure mem_copy(machine_addr target, machine_addr source, natural len)
-- safe mem_copy
	if len = 0 then
		return
	end if
	if not safe_address(target, len, A_WRITE) then 
		die("BAD MEM_COPY TARGET" & bad_address(target))
	elsif not safe_address(source, len, A_READ) then
		die("BAD MEM_COPY SOURCE" & bad_address(source))
	else
		eu:mem_copy(target, source, len)
	end if
end procedure

--**
-- @nodoc@
override procedure mem_set(machine_addr target, atom value, natural len)
-- safe mem_set
	if len = 0 then
		return
	end if
	if safe_address(target, len, A_WRITE) then
		eu:mem_set(target, value, len)
	else
		die("BAD MEM_SET" & bad_address(target))
	end if
end procedure


procedure show_byte(atom m)
-- display byte at memory location m
	integer c
	
	c = eu:peek(m)
	if c <= 9 then
		printf(1, "%d", c)
	elsif c < 32 or c > 127 then
		printf(1, "%d #%02x", {c, c})
	else
		if c = leader[1] or c = trailer[1] then
			printf(1, "%s", c)
		else
			printf(1, "%d #%02x '%s'", {c, c, c})
		end if
	end if
	puts(1, ",  ")
end procedure

--**
-- @nodoc@
public procedure show_block(sequence block_info)
-- display a corrupted block and die
	integer len, id, bad, p
	atom start
	
	start = block_info[1]
	len = block_info[2]
	id = block_info[3]
	printf(1, "BLOCK# %d, START: #%x, SIZE %d\n", {id, start, len})
	-- check pre-block
	bad = 0
	for i = start-BORDER_SPACE to start-1 do
		p = eu:peek(i)
		if p != leader[1] or bad then
			bad += 1
			if bad = 1 then
				puts(1, "DATA WAS STORED ILLEGALLY, JUST BEFORE THIS BLOCK:\n")
				puts(1, "(" & leader[1] & " characters are OK)\n")
				printf(1, "#%x: ", i)
			end if
			show_byte(i)
		end if
	end for
	puts(1, "\nDATA WITHIN THE BLOCK:\n")
	printf(1, "#%x: ", start)
	if len <= 30 then
		-- show whole block
		for i = start to start+len-1 do
			show_byte(i)
		end for 
	else
		-- first part of block
		for i = start to start+14 do
			show_byte(i)
		end for 
		-- last part of block
		puts(1, "\n ...\n")
		printf(1, "#%x: ", start+len-15)
		for i = start+len-15 to start+len-1 do
			show_byte(i)
		end for 
	end if
	bad = 0
	-- check post-block
	for i = start+len to start+len+BORDER_SPACE-1 do
		p = eu:peek(i)
		if p != trailer[1] or bad then
			bad += 1
			if bad = 1 then
				puts(1, "\nDATA WAS STORED ILLEGALLY, JUST AFTER THIS BLOCK:\n")
				puts(1, "(" & trailer[1] & " characters are OK)\n")
				printf(1, "#%x: ", i)
			end if
			show_byte(i)
		end if
	end for 
	die("safe.e: show_block()")
end procedure

--**
-- @nodoc@
public procedure check_all_blocks()
-- Check all allocated blocks for corruption of the leader and trailer areas. 
	integer n
	ext_addr a
	sequence block
	
	for i = 1 to length(safe_address_list) do
		block = safe_address_list[i]
		if block[3] >= 1 then
			-- a block that we allocated
			a = block[1]
			n = block[2]
			if not equal(leader, 
						eu:peek({a-BORDER_SPACE, BORDER_SPACE})) then
				show_block(block)
			elsif not equal(trailer, 
						 eu:peek({a+n, BORDER_SPACE})) then
				show_block(block)
			end if
		end if
	end for
end procedure

--**
-- @nodoc@
override procedure call(machine_addr addr)
-- safe call - machine code must start in block that we own
	if safe_address(addr, 1, A_EXECUTE) then
		eu:call(addr)
		if check_calls then
			check_all_blocks() -- check for any corruption
		end if
	else
		die(sprintf("BAD CALL ADDRESS!!!! %d\n\n", addr))
	end if
end procedure

--**
-- @nodoc@
override procedure c_proc(integer i, sequence s)
	eu:c_proc(i, s)
	if check_calls then
		check_all_blocks()
	end if
end procedure

--**
-- @nodoc@
override function c_func(integer i, sequence s)
	object r
	
	r = eu:c_func(i, s)
	if check_calls then
		check_all_blocks()
	end if 
	return r
end function

--**
-- @nodoc@
public procedure register_block(machine_addr block_addr, positive_int block_len, valid_memory_protection_constant memory_protection = PAGE_READ_WRITE )
-- register an externally-acquired block of memory as being safe to use
	allocation_num += 1
    for i = 1 to length(safe_address_list) do
	if safe_address_list[i][BLOCK_ADDRESS] = block_addr then
	    die("ATTEMPT TO REGISTER A NON-EXTERNAL BLOCK.")
	end if
    end for
    safe_address_list = prepend(safe_address_list, {block_addr, block_len,
       -allocation_num,memory_protection})
end procedure

--**
-- @nodoc@
public procedure unregister_block(machine_addr block_addr)
-- remove an external block of memory from the safe address list
	for i = 1 to length(safe_address_list) do
		if safe_address_list[i][BLOCK_ADDRESS] = block_addr then
			if safe_address_list[i][ALLOC_NUMBER] >= 0 then
				die("ATTEMPT TO UNREGISTER A NON-EXTERNAL BLOCK")
			end if
			safe_address_list = safe_address_list[1..i-1] &
								safe_address_list[i+1..$]
			return
		end if  
	end for
	die("ATTEMPT TO UNREGISTER A BLOCK THAT WAS NOT REGISTERED!")
end procedure

--**
-- @nodoc@
export function prepare_block(int_addr iaddr, positive_int n, natural protection)
	ext_addr eaddr
-- set up an allocated block so we can check it for corruption
	if iaddr = 0 then
		die("OUT OF MEMORY!")
	end if
	eu:poke(iaddr, leader)
	eaddr = iaddr + BORDER_SPACE
	eu:poke(eaddr+n, trailer)
	allocation_num += 1
	safe_address_list = prepend(safe_address_list, {eaddr, n, allocation_num, protection})
	return eaddr
end function

-- **
-- @devdoc@
-- Internal use of the library only.  ##free## calls this.  It works with
-- only atoms and in the unSAFE implementation is different.
--**
-- @nodoc@
export procedure deallocate(atom a)
	-- free address a - make sure it was allocated
	int_addr ia
	
	for i = 1 to length(safe_address_list) do
		if safe_address_list[i][BLOCK_ADDRESS] = a then
			-- check pre and post block areas
			integer n
			ia = a-BORDER_SPACE
			if safe_address_list[i][ALLOC_NUMBER] <= 0 then
				die("ATTEMPT TO FREE A BLOCK THAT WAS NOT ALLOCATED!")
			end if
			n = safe_address_list[i][BLOCK_LENGTH]
			if not equal(leader, eu:peek({ia, BORDER_SPACE})) then
				show_block(safe_address_list[i])
			elsif not equal(trailer, eu:peek({a+n, BORDER_SPACE})) then
				show_block(safe_address_list[i])
			end if
			ifdef DATA_EXECUTE then
				ifdef WINDOWS then
					if dep_works() then
						eu:c_func( VirtualFree_rid, { ia, n, MEM_RELEASE } )
					else
						eu:machine_proc(M_FREE, ia)
					end if
				elsedef
					eu:c_func( MUNMAP, { ia, n } )		
				end ifdef
			elsedef
				if safe_address_list[i][BLOCK_PROT] != PAGE_READ_WRITE then
					die("ATTEMPT TO FREE WITH free() A BLOCK " &
						"THAT WAS ALLOCATED BY allocate_protect()!") 
				end if
				eu:machine_proc(M_FREE, ia)
			end ifdef
			-- remove it from list
			safe_address_list = remove(safe_address_list, i)
			return
		end if
	end for
	if bordered_address( a ) then
		die("ATTEMPT TO FREE USING AN ILLEGAL ADDRESS!")
	end if
end procedure
FREE_RID = routine_id("deallocate")

-- **
-- @devdoc@
-- Returns 1 if the DEP executing data only memory would cause an exception
--**
-- @nodoc@
export function dep_works()
	ifdef WINDOWS then
		return DEP_really_works		
	elsedef
		return 1
	end ifdef
end function

--**
-- @nodoc@
export atom VirtualFree_rid

--**
-- @nodoc@
public procedure free_code( atom addr, integer size, valid_wordsize wordsize = 1 )
	sequence block

	for i = 1 to length(safe_address_list) do
		block = safe_address_list[i] 
		if block[BLOCK_ADDRESS] = addr then
			if safe_address_list[i][ALLOC_NUMBER] <= 0 then
				die("ATTEMPT TO FREE A BLOCK THAT WAS NOT ALLOCATED!")
			end if
			integer n = safe_address_list[i][BLOCK_LENGTH]
			if not equal(leader, eu:peek({addr-BORDER_SPACE, BORDER_SPACE})) then
				show_block(safe_address_list[i])
			elsif not equal(trailer, eu:peek({addr+n, BORDER_SPACE})) then
				show_block(safe_address_list[i])
			end if
			safe_address_list = remove( safe_address_list, i )
			exit
		end if
	end for

	ifdef WINDOWS then
		if dep_works() then
			c_func( VirtualFree_rid, 
				{ addr-BORDER_SPACE, size*wordsize, MEM_RELEASE } )
			return
		end if
	elsedef
		c_func( MUNMAP, { addr - BORDER_SPACE, size * wordsize } )
	end ifdef
end procedure

-- Shawn's custom stuff:
--**
-- @nodoc@
public function info() 
	integer tm = 0 
	for i = 1 to length( safe_address_list ) do 
		tm += safe_address_list[i][BLOCK_LENGTH] 
	end for
	return sprintf(""" 
Total memory allocations %10d 
Total memory allocated   %10dB""", 
	{ length(safe_address_list), tm } ) 
end function 
 
--**
-- @nodoc@
public function memory_used() 
	integer tm = 0 
	for i = 1 to length( safe_address_list ) do 
		tm += safe_address_list[i][BLOCK_LENGTH] 
	end for 
	return tm 
end function 
 
--**
-- @nodoc@
public function allocations() 
	return length( safe_address_list ) 
end function 
