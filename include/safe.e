-- (c) Copyright 2007 Rapid Deployment Software - See License.txt
--
-- Euphoria 3.1
-- Machine Level Programming (386/486/Pentium)
-- This is a DEBUGGING VERSION of machine.e

-- How To Use This File:

-- 1. Copy safe.e into the same directory as your main .ex[w][u] file and 
--    rename safe.e as machine.e in that directory. (Do NOT simply 
--    include safe.e, or you may have naming conflicts.)

-- 2. If your program doesn't already include machine.e add:  
--           include machine.e  
--    to your main .ex[w][u] file at the top.

-- 3. If necessary, call register_block(address, length) to add additional
--    "external" blocks of memory to the safe_address_list. These are blocks 
--    of memory that are safe to read/write but which you did not acquire 
--    through Euphoria's allocate() or allocate_low(). Call 
--    unregister_block(address) when you want to prevent further access to 
--    an external block.

-- 4. Run your program. It might be 10x slower than normal but it's
--    worth it to catch a nasty bug.

-- 5. If a bug is caught, you will hear some "beep" sounds.
--    Press Enter to clear the screen and see the error message. 
--    There will be a "divide by zero" traceback in ex.err 
--    so you can find the statement that is making the illegal memory access.

-- 6. When you are finished debugging and want to run at full speed,
--    remove or rename the local copy of machine.e (really safe.e) 
--    in your directory.

-- This file is equivalent to machine.e, but it overrides the built-in 
-- routines: 
--     poke, peek, poke4, peek4s, peek4u, call, mem_copy, and mem_set
-- and it provides alternate versions of:
--     allocate, allocate_low, free, free_low

-- Some parameters you may wish to change:

global integer check_calls, edges_only
check_calls = 1   -- if 1, check all blocks for edge corruption after each 
		  -- call(), dos_interrupt(), c_proc(), or c_func(). 
		  -- To save time, your program can turn off this checking by 
		  -- setting check_calls to 0. 

edges_only = (platform()=2) -- on WIN32 people often use unregistered blocks   
		  -- if 1, only check for references to the leader or trailer
		  -- areas just outside each registered block.
		  -- don't complain about addresses that are far out of bounds
		  -- (it's probably a legitimate block from another source)
		  -- For a stronger check, set this to 0 if your program 
		  -- will never read/write an unregistered block of memory.
		  

-- from misc.e and graphics.e:
constant M_SOUND = 1

-- Your program will only be allowed to read/write areas of memory
-- that it allocated (and hasn't freed), as well as areas in low memory 
-- that you list below, or add dynamically via register_block().

sequence safe_address_list
-- Include the starting address and length of any 
-- acceptable areas of memory for peek/poke here. 
-- Set allocation number to 0.
if platform() = 1 then -- DOS32
    safe_address_list = {
--      {start , length , allocation_number}        
	{#A0000, 200*320, 0},   -- mode 19 pixel memory, start & length 
      --{#B0000, 4000   , 0},   -- monochrome text memory, first page
	{#B8000, 8000   , 0},   -- color text memory, first page, 50-line mode 
	{1024  , 100    , 0}    -- keyboard buffer area (roughly)
	-- add more here
}
else
    safe_address_list = {}
end if

with type_check

puts(1, "\n\t\tUsing Debug Version of machine.e\n")
atom t
t = time()
while time() < t + 3 do
end while

constant OK = 1, BAD = 0
constant M_ALLOC = 16,
	 M_FREE = 17,
	 M_ALLOC_LOW = 32,
	 M_FREE_LOW = 33,
	 M_INTERRUPT = 34,
	 M_SET_RAND = 35,
	 M_USE_VESA = 36,
	 M_CRASH_MESSAGE = 37,
	 M_TICK_RATE = 38,
	 M_GET_VECTOR = 39,
	 M_SET_VECTOR = 40,
	 M_LOCK_MEMORY = 41,
	 M_A_TO_F64 = 46,
	 M_F64_TO_A = 47,
	 M_A_TO_F32 = 48,
	 M_F32_TO_A = 49,
	 M_CRASH_FILE = 57,
	 M_CRASH_ROUTINE = 66
	 
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

constant BORDER_SPACE = 40
constant leader = repeat('@', BORDER_SPACE)
constant trailer = repeat('%', BORDER_SPACE)

function safe_address(atom start, integer len)
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
	block_start = block[1]
	if edges_only then
	    -- addresses are considered safe as long as 
	    -- they aren't in any block's border zone
	    if start <= 3 then
		return BAD -- null pointer (or very small address)
	    end if
	    if block[3] >= 1 then
		-- an allocated block with a border area
		block_upper = block_start + block[2]
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
	else
	    -- addresses are considered safe as long as 
	    -- they are inside an allocated or registered block
	    if start >= block_start then 
		block_upper = block_start + block[2]
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
		    return OK
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
    puts(1, "\n\n" & msg & "\n\n")
    if getc(0) then
    end if
    ? 1/0 -- force traceback
end procedure

function bad_address(atom a)
-- show address in decimal and hex  
    return sprintf(" ADDRESS!!!! %d (#%08x)", {a, a})
end function

function original_peek(object x)
    return peek(x) -- Euphoria's normal peek
end function

without warning
-- override "peek" with debug peek
global function peek(object x)
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
    if safe_address(a, len) then
	return original_peek(x)
    else
	die("BAD PEEK" & bad_address(a))
    end if
end function

function original_peek4s(object x)
    return peek4s(x) -- Euphoria's normal peek
end function

-- override "peek4s" with debug peek4s
global function peek4s(object x)
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
    if safe_address(a, len) then
	return original_peek4s(x)
    else
	die("BAD PEEK4S" & bad_address(a))
    end if
end function

function original_peek4u(object x)
    return peek4u(x) -- Euphoria's normal peek
end function

-- override "peek4u" with debug peek4u
global function peek4u(object x)
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
    if safe_address(a, len) then
	return original_peek4u(x)
    else
	die("BAD PEEK4U" & bad_address(a))
    end if
end function

procedure original_poke(atom a, object v)
    poke(a, v)
end procedure

global procedure poke(atom a, object v)
-- safe version of poke 
    integer len
    
    if atom(v) then
	len = 1
    else
	len = length(v)
    end if
    if safe_address(a, len) then
	original_poke(a, v)
    else
	die("BAD POKE" & bad_address(a))
    end if
end procedure

procedure original_poke4(atom a, object v)
    poke4(a, v)
end procedure

global procedure poke4(atom a, object v)
-- safe version of poke4 
    integer len
    
    if atom(v) then
	len = 4
    else
	len = length(v)*4
    end if
    if safe_address(a, len) then
	original_poke4(a, v)
    else
	die("BAD POKE4" & bad_address(a))
    end if
end procedure

procedure original_mem_copy(atom target, atom source, atom len)
    mem_copy(target, source, len)
end procedure

global procedure mem_copy(machine_addr target, machine_addr source, natural len)
-- safe mem_copy
    if not safe_address(target, len) then 
	die("BAD MEM_COPY TARGET" & bad_address(target))
    elsif not safe_address(source, len) then
	die("BAD MEM_COPY SOURCE" & bad_address(source))
    else
	original_mem_copy(target, source, len)
    end if
end procedure

procedure original_mem_set(atom target, atom value, integer len)
    mem_set(target, value, len)
end procedure

global procedure mem_set(machine_addr target, atom value, natural len)
-- safe mem_set
    if safe_address(target, len) then
	original_mem_set(target, value, len)
    else
	die("BAD MEM_SET" & bad_address(target))
    end if
end procedure

atom allocation_num
allocation_num = 0

procedure show_byte(atom m)
-- display byte at memory location m
    integer c
    
    c = original_peek(m)
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

procedure show_block(sequence block_info)
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
	p = original_peek(i)
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
	p = original_peek(i)
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

global procedure check_all_blocks()
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
			 original_peek({a-BORDER_SPACE, BORDER_SPACE})) then
		show_block(block)
	    elsif not equal(trailer, 
			 original_peek({a+n, BORDER_SPACE})) then
		show_block(block)
	    end if          
	end if
    end for
end procedure

procedure original_call(atom addr)
    call(addr)
end procedure

global procedure call(atom addr)
-- safe call - machine code must start in block that we own
    if safe_address(addr, 1) then
	original_call(addr)
	if check_calls then
	    check_all_blocks() -- check for any corruption
	end if
    else
	die(sprintf("BAD CALL ADDRESS!!!! %d\n\n", addr))
    end if
end procedure

procedure original_c_proc(integer i, sequence s)
    c_proc(i, s)
end procedure

global procedure c_proc(integer i, sequence s)
    original_c_proc(i, s)
    if check_calls then
	check_all_blocks()
    end if
end procedure

function original_c_func(integer i, sequence s)
    return c_func(i, s)
end function

global function c_func(integer i, sequence s)
    object r
    
    r = original_c_func(i, s)
    if check_calls then
	check_all_blocks()
    end if 
    return r
end function


global procedure register_block(machine_addr block_addr, positive_int block_len)
-- register an externally-acquired block of memory as being safe to use
    allocation_num += 1
    safe_address_list = prepend(safe_address_list, {block_addr, block_len,
       -allocation_num})
end procedure

global procedure unregister_block(machine_addr block_addr)
-- remove an external block of memory from the safe address list
    for i = 1 to length(safe_address_list) do
	if safe_address_list[i][1] = block_addr then
	    if safe_address_list[i][3] >= 0 then
		die("ATTEMPT TO UNREGISTER A NON-EXTERNAL BLOCK")
	    end if
	    safe_address_list = safe_address_list[1..i-1] &
				safe_address_list[i+1..$]
	    return
	end if  
    end for
    die("ATTEMPT TO UNREGISTER A BLOCK THAT WAS NOT REGISTERED!")
end procedure

function prepare_block(atom a, integer n)
-- set up an allocated block so we can check it for corruption
    if a = 0 then
	die("OUT OF MEMORY!")
    end if
    original_poke(a, leader)
    a += BORDER_SPACE
    original_poke(a+n, trailer)
    allocation_num += 1
--  if allocation_num = ??? then 
--      trace(1) -- find out who allocated this block number
--  end if  
    safe_address_list = prepend(safe_address_list, {a, n, allocation_num})
    return a
end function

global function allocate(positive_int n)
-- allocate memory block and add it to safe list
    atom a

    a = machine_func(M_ALLOC, n+BORDER_SPACE*2)
    return prepare_block(a, n)
end function

global function allocate_low(positive_int n)
-- allocate memory block and add it to safe list
    atom a
    
    a = machine_func(M_ALLOC_LOW, n+BORDER_SPACE*2)
    return prepare_block(a, n)
end function

global procedure free(machine_addr a)
-- free address a - make sure it was allocated
    integer n
    
    for i = 1 to length(safe_address_list) do
	if safe_address_list[i][1] = a then
	    -- check pre and post block areas
	    if safe_address_list[i][3] <= 0 then
		die("ATTEMPT TO FREE A BLOCK THAT WAS NOT ALLOCATED!")
	    end if
	    n = safe_address_list[i][2]
	    if not equal(leader, original_peek({a-BORDER_SPACE, BORDER_SPACE})) then
		show_block(safe_address_list[i])
	    elsif not equal(trailer, original_peek({a+n, BORDER_SPACE})) then
		show_block(safe_address_list[i])
	    end if          
	    machine_proc(M_FREE, a-BORDER_SPACE)
	    -- remove it from list
	    safe_address_list = 
			safe_address_list[1..i-1] &
			safe_address_list[i+1..$]
	    return
	end if
    end for
    die("ATTEMPT TO FREE USING AN ILLEGAL ADDRESS!")
end procedure

global procedure free_low(low_machine_addr a)
-- free low address a - make sure it was allocated
    integer n
    
    if a > 1024*1024 then
	die("TRYING TO FREE A HIGH ADDRESS USING free_low!")
    end if
    for i = 1 to length(safe_address_list) do
	if safe_address_list[i][1] = a then
	    -- check pre and post block areas
	    if safe_address_list[i][3] <= 0 then
		die("ATTEMPT TO FREE A BLOCK THAT WAS NOT ALLOCATED!")
	    end if
	    n = safe_address_list[i][2]
	    if not equal(leader, original_peek({a-BORDER_SPACE, BORDER_SPACE})) then
		show_block(safe_address_list[i])
	    elsif not equal(trailer, original_peek({a+n, BORDER_SPACE})) then
		show_block(safe_address_list[i])
	    end if          
	    machine_proc(M_FREE_LOW, a-BORDER_SPACE)
	    -- remove it from list
	    safe_address_list = 
			safe_address_list[1..i-1] &
			safe_address_list[i+1..$]
	    return
	end if
    end for
    die("ATTEMPT TO FREE USING AN ILLEGAL ADDRESS!")
end procedure

global constant REG_LIST_SIZE = 10

type register_list(sequence r)
-- a list of register values
    return length(r) = REG_LIST_SIZE
end type

global function dos_interrupt(integer int_num, register_list input_regs)
-- call the DOS operating system via software interrupt int_num, using the
-- register values in input_regs. A similar register_list is returned.
-- It contains the register values after the interrupt.
    object r
    r = machine_func(M_INTERRUPT, {int_num, input_regs})
    if check_calls then
	check_all_blocks()
    end if
    return r
end function


----------- the rest is identical to machine.e ------------------------------

type sequence_8(sequence s)
-- an 8-element sequence
    return length(s) = 8
end type

type sequence_4(sequence s)
-- a 4-element sequence
    return length(s) = 4
end type

global constant REG_DI = 1,      
		REG_SI = 2,
		REG_BP = 3,
		REG_BX = 4,
		REG_DX = 5,
		REG_CX = 6,
		REG_AX = 7,
		REG_FLAGS = 8, -- on input: ignored 
			       -- on output: low bit has carry flag for 
			       -- success/fail
		REG_ES = 9,
		REG_DS = 10

global function int_to_bytes(atom x)
-- returns value of x as a sequence of 4 bytes 
-- that you can poke into memory 
--      {bits 0-7,  (least significant)
--       bits 8-15,
--       bits 16-23,
--       bits 24-31} (most significant)
-- This is the order of bytes in memory on 386+ machines.
    integer a,b,c,d
    
    a = remainder(x, #100)
    x = floor(x / #100)
    b = remainder(x, #100)
    x = floor(x / #100)
    c = remainder(x, #100)
    x = floor(x / #100)
    d = remainder(x, #100)
    return {a,b,c,d}
end function

atom mem
mem = allocate(4)

global function bytes_to_int(sequence s)
-- converts 4-byte peek() sequence into an integer value
    if length(s) = 4 then
	poke(mem, s)
    else    
	poke(mem, s[1..4])
    end if
    return peek4u(mem)
end function

global function int_to_bits(atom x, integer nbits)
-- Returns the low-order nbits bits of x as a sequence of 1's and 0's. 
-- Note that the least significant bits come first. You can use Euphoria's
-- and/or/not operators on sequences of bits. You can also subscript, 
-- slice, concatenate etc. to manipulate bits.
    sequence bits
    integer mask
    
    bits = repeat(0, nbits)
    if integer(x) and nbits < 30 then
	-- faster method
	mask = 1
	for i = 1 to nbits do
	    bits[i] = and_bits(x, mask) and 1
	    mask *= 2
	end for
    else
	-- slower, but works for large x and large nbits
	if x < 0 then
	    x += power(2, nbits) -- for 2's complement bit pattern
	end if
	for i = 1 to nbits do
	    bits[i] = remainder(x, 2) 
	    x = floor(x / 2)
	end for
    end if
    return bits
end function

global function bits_to_int(sequence bits)
-- get the (positive) value of a sequence of "bits"
    atom value, p
    
    value = 0
    p = 1
    for i = 1 to length(bits) do
	if bits[i] then
	    value += p
	end if
	p += p
    end for
    return value
end function

global procedure set_rand(integer seed)
-- Reset the random number generator.
-- A given value of seed will cause the same series of
-- random numbers to be generated from the rand() function
    machine_proc(M_SET_RAND, seed)
end procedure

global procedure use_vesa(integer code)
-- If code is 1 then force Euphoria to use the VESA graphics standard.
-- This may let Euphoria work better in SVGA modes with certain graphics cards.
-- If code is 0 then Euphoria's normal use of the graphics card is restored.
-- Values of code other than 0 or 1 should not be used.
    machine_proc(M_USE_VESA, code)
end procedure

global procedure crash_message(sequence msg)
-- Specify a final message to display for your user, in the event 
-- that Euphoria has to shut down your program due to an error.
    machine_proc(M_CRASH_MESSAGE, msg)
end procedure

global procedure crash_file(sequence file_path)
-- Specify a file name in place of "ex.err" where you want
-- diagnostic information to be written.
    machine_proc(M_CRASH_FILE, file_path)
end procedure

global procedure crash_routine(integer proc)
-- specify the routine id of a 1-parameter Euphoria function to call in the
-- event that Euphoria must shutdown your program due to an error.
    machine_proc(M_CRASH_ROUTINE, proc)
end procedure

global procedure tick_rate(atom rate)
-- Specify the number of clock-tick interrupts per second.
-- This determines the precision of the time() library routine, 
-- and also the sampling rate for time profiling.
    machine_proc(M_TICK_RATE, rate)
end procedure

global function get_vector(integer int_num)
-- returns the current (far) address of the interrupt handler
-- for interrupt vector number int_num as a 2-element sequence: 
-- {16-bit segment, 32-bit offset}
    return machine_func(M_GET_VECTOR, int_num)
end function

global procedure set_vector(integer int_num, far_addr a)
-- sets a new interrupt handler address for vector int_num  
    machine_proc(M_SET_VECTOR, {int_num, a})
end procedure

global procedure lock_memory(machine_addr a, positive_int n)
-- Prevent a chunk of code or data from ever being swapped out to disk.
-- You should lock any code or data used by an interrupt handler.
    machine_proc(M_LOCK_MEMORY, {a, n})
end procedure

global function atom_to_float64(atom a)
-- Convert an atom to a sequence of 8 bytes in IEEE 64-bit format
    return machine_func(M_A_TO_F64, a)
end function

global function atom_to_float32(atom a)
-- Convert an atom to a sequence of 4 bytes in IEEE 32-bit format
    return machine_func(M_A_TO_F32, a)
end function

global function float64_to_atom(sequence_8 ieee64)
-- Convert a sequence of 8 bytes in IEEE 64-bit format to an atom
    return machine_func(M_F64_TO_A, ieee64)
end function

global function float32_to_atom(sequence_4 ieee32)
-- Convert a sequence of 4 bytes in IEEE 32-bit format to an atom
    return machine_func(M_F32_TO_A, ieee32)
end function

global function allocate_string(sequence s)
-- create a C-style null-terminated string in memory
    atom mem
    
    mem = allocate(length(s) + 1)
    if mem then
	poke(mem, s)
	poke(mem+length(s), 0)  -- Thanks to Aku
    end if
    return mem
end function


