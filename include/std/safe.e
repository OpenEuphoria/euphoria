-- (c) Copyright Rapid Deployment Software - See License.txt
--
-- Euphoria 4.0
-- Machine Level Programming (386/486/Pentium)

public include std/memconst.e
ifdef DATA_EXECUTE then
	public include std/machine.e as machine
end ifdef
--****
-- === safe.e
--
-- This is a slower DEBUGGING VERSION of machine.e
--
-- How To Use This File:
--
-- 1. If your program doesn't already include machine.e add:
--           include std/machine.e
--    to your main .ex[w][u] file at the top.
--
-- 2. To turn debug version on, issue 
-- <eucode>
-- with define SAFE
-- </eucode>
-- in your main program, before the statement including machine.e.
--
-- 3. If necessary, call register_block(address, length) to add additional
--    "external" blocks of memory to the safe_address_list. These are blocks 
--    of memory that are safe to read/write but which you did not acquire 
--    through Euphoria's allocate() or allocate_low(). Call 
--    unregister_block(address) when you want to prevent further access to
--    an external block.
--
-- 4. Run your program. It might be 10x slower than normal but it's
--    worth it to catch a nasty bug.
--
-- 5. If a bug is caught, you will hear some "beep" sounds.
--    Press Enter to clear the screen and see the error message. 
--    There will be a "divide by zero" traceback in ex.err 
--    so you can find the statement that is making the illegal memory access.
--
-- 6. To switch between normal and debug versions, simply comment in or out the 
-- "with define SAFE" directive. In means debugging and out means normal.
-- Alternatively, you can use -D SAFE as a switch on the command line (debug) or not (normal).
--
-- 7. The older method of switching files and renaming them //**no longer works**//. machine.e conditionally includes safe.e.
--
-- This file is equivalent to machine.e, but it overrides the built-in 
-- routines: 
--     poke, peek, poke4, peek4s, peek4u, call, mem_copy, and mem_set
-- and it provides alternate versions of:
--     allocate, allocate_low, free, free_low
--
-- Your program will only be allowed to read/write areas of memory
-- that it allocated (and hasn't freed), as well as areas in low memory
-- that you list below, or add dynamically via register_block().

-- Some parameters you may wish to change:

--**
-- Define block checking policy.
--
-- Comments:
--
-- If this integer is 1, (the default), check all blocks for edge corruption after each
-- [[:call]](), [[:dos_interrupt]](), [[:c_proc]]() or [[:c_func]]().
-- To save time, your program can turn off this checking by setting check_calls to 0.

public integer check_calls = 1

--**
-- Determine whether to flag accesses to remote memory areas.
--
-- Comments:
--
-- If this integer is 1 (the default under //WIN32//), only check for references to the 
-- leader or trailer areas just outside each registered block, and don't complain about 
-- addresses that are far out of bounds (it's probably a legitimate block from another source)
--
-- For a stronger check, set this to 0 if your program will never read/write an 
-- unregistered block of memory.
--
-- On //WIN32// people often use unregistered blocks.
public integer edges_only = (platform()=2) 
				  

-- from misc.e and graphics.e:
constant M_SOUND = 1

-- Constants that tell us what we are about to try to do: read, write or execute memory.  
-- They should be distinct from PERM_EXEC, etc...
-- These are not permission constants.
export enum A_READ = 1, A_WRITE = 2, A_EXECUTE = 3

-- Include the starting address and length of any 
-- acceptable areas of memory for peek/poke here. 
-- Set allocation number to 0.
public sequence safe_address_list = {}

with type_check

puts(1, "\n\t\tUsing Debug Version of machine.e\n")
atom t
t = time()
while time() < t + 3 do
end while

constant OK = 1, BAD = 0
constant M_ALLOC = 16,
		 M_FREE = 17

-- biggest address on a 32-bit machine
constant MAX_ADDR = power(2, 32)-1

-- biggest address accessible to 16-bit real mode
constant LOW_ADDR = power(2, 20)-1

type positive_int(integer x)
	return x >= 1
end type

type natural(integer x)
	return x >= 0
end type

type machine_addr(atom a)
-- a 32-bit non-null machine address 
	return a > 0 and a <= MAX_ADDR and floor(a) = a
end type

type far_addr(sequence a)
-- protected mode far address {seg, offset}
	return length(a) = 2 and integer(a[1]) and machine_addr(a[2])
end type

type low_machine_addr(atom a)
-- a legal low machine address 
	return a > 0 and a <= LOW_ADDR and floor(a) = a
end type

export constant BORDER_SPACE = 40
export constant leader = repeat('@', BORDER_SPACE)
export constant trailer = repeat('%', BORDER_SPACE)

export type bordered_address( atom addr )
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

export function safe_address(atom start, integer len, positive_int action )
-- is it ok to read/write all addresses from start to start+len-1?
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

public procedure die(sequence msg)
-- Terminate with a message.
-- makes warning beeps first so you can see what's happening on the screen
	atom t
	
	for i = 1 to 7 do
		machine_proc(M_SOUND, 1000)
		t = time()
		while time() < t + .1 do
		end while
		machine_proc(M_SOUND, 0)
		t = time()
		while time() < t + .1 do
		end while
	end for
	puts(1, "\n *** Press Enter *** ")
	if getc(0) then
	end if
	if machine_func(5, -1) then -- graphics_mode
	end if		
	puts(1, "\n\n" & msg & "\n\n" )
	if getc(0) then
	end if
	? 1/0 -- force traceback
end procedure

function bad_address(atom a)
-- show address in decimal and hex  
	return sprintf(" ADDRESS!!!! %d (#%08x)", {a, a})
end function

without warning &= (override)

override function peek(object x)
-- safe version of peek 
	integer len
	atom a
	
	if atom(x) then
		len = 1
		a = x
	else
		len = x[2]
		a = x[1]
	end if
	if safe_address(a, len, A_READ) then
		return eu:peek(x)
	else
		die("BAD PEEK" & bad_address(a))
	end if
end function

override function peeks(object x)
-- safe version of peeks
	integer len
	atom a
	
	if atom(x) then
		len = 1
		a = x
	else
		len = x[2]
		a = x[1]
	end if
	if safe_address(a, len, A_READ) then
		return eu:peeks(x)
	else
		die("BAD PEEK" & bad_address(a))
	end if
end function

override function peek2u(object x)
-- safe version of peek 
	integer len
	atom a
	
	if atom(x) then
		len = 2
		a = x
	else
		len = x[2] * 2
		a = x[1]
	end if
	if safe_address(a, len, A_READ) then
		return eu:peek2u(x)
	else
		die("BAD PEEK2U" & bad_address(a))
	end if
end function

override function peek2s(object x)
-- safe version of peek 
	integer len
	atom a
	
	if atom(x) then
		len = 2
		a = x
	else
		len = x[2] * 2
		a = x[1]
	end if
	if safe_address(a, len, A_READ) then
		return eu:peek2s(x)
	else
		die("BAD PEEK2S" & bad_address(a))
	end if
end function

override function peek4s(object x)
-- safe version of peek4s 
	integer len
	atom a
	
	if atom(x) then
		len = 4
		a = x
	else
		len = x[2]*4
		a = x[1]
	end if
	if safe_address(a, len, A_READ) then
		return eu:peek4s(x)
	else
		die("BAD PEEK4S" & bad_address(a))
	end if
end function

override function peek4u(object x)
-- safe version of peek4u 
	integer len
	atom a
	
	if atom(x) then
		len = 4
		a = x
	else
		len = x[2]*4
		a = x[1]
	end if
	if safe_address(a, len, A_READ) then
		return eu:peek4u(x)
	else
		die("BAD PEEK4U" & bad_address(a))
	end if
end function


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


override procedure poke(atom a, object v)
-- safe version of poke 
	integer len
	
	if atom(v) then
		len = 1
	else
		len = length(v)
	end if
	if safe_address(a, len, A_WRITE) then
		eu:poke(a, v)
	else
		die("BAD POKE" & bad_address(a))
	end if
end procedure

override procedure poke2(atom a, object v)
-- safe version of poke2 
	integer len
	
	if atom(v) then
		len = 2
	else
		len = length(v) * 2
	end if
	if safe_address(a, len, A_WRITE) then
		eu:poke2(a, v)
	else
		die("BAD POKE" & bad_address(a))
	end if
end procedure

override procedure poke4(atom a, object v)
-- safe version of poke4 
	integer len
	
	if atom(v) then
		len = 4
	else
		len = length(v)*4
	end if
	if safe_address(a, len, A_WRITE) then
		eu:poke4(a, v)
	else
		die("BAD POKE4" & bad_address(a))
	end if
end procedure

override procedure mem_copy(machine_addr target, machine_addr source, natural len)
-- safe mem_copy
	if not safe_address(target, len, A_WRITE) then 
		die("BAD MEM_COPY TARGET" & bad_address(target))
	elsif not safe_address(source, len, A_READ) then
		die("BAD MEM_COPY SOURCE" & bad_address(source))
	else
		eu:mem_copy(target, source, len)
	end if
end procedure

override procedure mem_set(machine_addr target, atom value, natural len)
-- safe mem_set
	if safe_address(target, len, A_WRITE) then
		eu:mem_set(target, value, len)
	else
		die("BAD MEM_SET" & bad_address(target))
	end if
end procedure

atom allocation_num
allocation_num = 0

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
	die("")
end procedure

public procedure check_all_blocks()
-- Check all allocated blocks for corruption of the leader and trailer areas. 
	integer n
	atom a
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

override procedure call(bordered_address addr)
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

override procedure c_proc(integer i, sequence s)
	eu:c_proc(i, s)
	if check_calls then
		check_all_blocks()
	end if
end procedure

override function c_func(integer i, sequence s)
	object r
	
	r = eu:c_func(i, s)
	if check_calls then
		check_all_blocks()
	end if 
	return r
end function

enum BLOCK_ADDRESS, BLOCK_LENGTH, ALLOC_NUMBER, BLOCK_PROT


public procedure register_block(machine_addr block_addr, positive_int block_len, valid_memory_protection_constant memory_protection = PAGE_READ_WRITE )
-- register an externally-acquired block of memory as being safe to use
	allocation_num += 1
	safe_address_list = prepend(safe_address_list, {block_addr, block_len,
	   -allocation_num,memory_protection})
end procedure

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

export function prepare_block(atom a, integer n, positive_int protection)
-- set up an allocated block so we can check it for corruption
	if a = 0 then
		die("OUT OF MEMORY!")
	end if
	eu:poke(a, leader)
	a += BORDER_SPACE
	eu:poke(a+n, trailer)
	allocation_num += 1
--  if allocation_num = ??? then 
--      trace(1) -- find out who allocated this block number
--  end if  
	safe_address_list = prepend(safe_address_list, {a, n, allocation_num, protection})
	return a
end function

public function allocate_data(positive_int n, integer cleanup = 0)
-- allocate memory block and add it to safe list
	atom a
	bordered_address sla
	a = machine_func(M_ALLOC, n+BORDER_SPACE*2)
	sla = prepare_block(a, n, PAGE_READ_WRITE )
	if cleanup then
		return delete_routine( sla, FREE_RID )
	else
		return sla
	end if
end function

public function allocate(positive_int n, integer cleanup = 0)
-- allocate memory block and add it to safe list
	ifdef DATA_EXECUTE then                                   
		return allocate_protect( n, 1, PAGE_READ_WRITE_EXECUTE )
	elsedef	
		atom a	
		a = machine_func(M_ALLOC, n+BORDER_SPACE*2)
		return prepare_block(a, n, PAGE_READ_WRITE )
	end ifdef	
end function

public procedure free(bordered_address a)
-- free address a - make sure it was allocated
	for i = 1 to length(safe_address_list) do
		if safe_address_list[i][BLOCK_ADDRESS] = a then
			-- check pre and post block areas
			integer n
			if safe_address_list[i][ALLOC_NUMBER] <= 0 then
				die("ATTEMPT TO FREE A BLOCK THAT WAS NOT ALLOCATED!")
			end if
			n = safe_address_list[i][BLOCK_LENGTH]
			if not equal(leader, eu:peek({a-BORDER_SPACE, BORDER_SPACE})) then
				show_block(safe_address_list[i])
			elsif not equal(trailer, eu:peek({a+n, BORDER_SPACE})) then
				show_block(safe_address_list[i])
			end if
			ifdef DATA_EXECUTE then
				free_code(a, safe_address_list[i][BLOCK_LENGTH])
			elsedef
				if safe_address_list[i][BLOCK_PROT] != PAGE_READ_WRITE then
					die("ATTEMPT TO FREE WITH free() A BLOCK " &
						"THAT WAS ALLOCATED BY allocate_protect()!") 
				end if
				machine_proc(M_FREE, a-BORDER_SPACE)
			end ifdef
			-- remove it from list
			safe_address_list = remove(safe_address_list, i)
			return
		end if
	end for
	die("ATTEMPT TO FREE USING AN ILLEGAL ADDRESS!")
end procedure
FREE_RID = routine_id("free")

-- Returns 1 if the DEP executing data only memory would cause an exception
export function dep_works()
	ifdef WIN32 then
		return DEP_really_works		
	end ifdef

	return 0
end function

export atom VirtualFree_rid

public procedure free_code( bordered_address addr, integer size, valid_wordsize wordsize = 1 )
	integer free_succeeded
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

	ifdef WIN32 then
		if not dep_works() then
			machine_proc(M_FREE, addr-BORDER_SPACE)
		else
			free_succeeded = c_func( VirtualFree_rid, 
				{ addr-BORDER_SPACE, size*wordsize, MEM_RELEASE } )
		end if
	elsedef
		machine_proc(M_FREE, addr-BORDER_SPACE)	
	end ifdef
end procedure
