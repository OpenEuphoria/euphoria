-- (c) Copyright 2007 Rapid Deployment Software - See License.txt
--
-- Euphoria 3.1
-- Machine Level Programming (386/486/Pentium)

-- Warning: Some of these routines require a knowledge of 
-- machine-level programming. You could crash your system!

-- These routines, along with peek(), poke() and call(), let you access all 
-- of the features of your computer.  You can read and write to any memory 
-- location, and you can create and execute machine code subroutines.

-- If you are manipulating 32-bit addresses or values, remember to use
-- variables declared as atom. The integer type only goes up to 31 bits.

-- Writing characters to screen memory with poke() is much faster than  
-- using puts(). Address of start of text screen memory:
--       mono: #B0000
--      color: #B8000

-- If you choose to call machine_proc() or machine_func() directly (to save
-- a bit of overhead) you *must* pass valid arguments or Euphoria could crash.

-- Some example programs to look at:
--   demo\callmach.ex      - calling a machine language routine
--   demo\dos32\hardint.ex - setting up a hardware interrupt handler
--   demo\dos32\dosint.ex  - calling a DOS software interrupt

-- See also safe.e in this directory. It's a safe, debugging version of this
-- file.

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

type machine_addr(atom a)
-- a 32-bit non-null machine address 
    return a > 0 and a <= MAX_ADDR and floor(a) = a
end type

type far_addr(sequence a)
-- protected mode far address {seg, offset}
    return length(a) = 2 and integer(a[1]) and machine_addr(a[2])
end type

type low_machine_addr(integer a)
-- a legal low machine address 
    return a > 0 and a <= LOW_ADDR 
end type

type sequence_8(sequence s)
-- an 8-element sequence
    return length(s) = 8
end type

type sequence_4(sequence s)
-- a 4-element sequence
    return length(s) = 4
end type

global constant REG_LIST_SIZE = 10
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

type register_list(sequence r)
-- a list of register values
    return length(r) = REG_LIST_SIZE
end type

global function allocate(positive_int n)
-- Allocate n bytes of memory and return the address.
-- Free the memory using free() below.
    return machine_func(M_ALLOC, n)
end function

global procedure free(machine_addr a)
-- free the memory at address a
    machine_proc(M_FREE, a)
end procedure

global function allocate_low(positive_int n)
-- Allocate n bytes of low memory (address less than 1Mb) 
-- and return the address. Free this memory using free_low() below.
-- Addresses in this range can be passed to DOS during software interrupts.
    return machine_func(M_ALLOC_LOW, n)
end function

global procedure free_low(low_machine_addr a)
-- free the low memory at address a
    machine_proc(M_FREE_LOW, a)
end procedure

global function dos_interrupt(integer int_num, register_list input_regs)
-- call the DOS operating system via software interrupt int_num, using the
-- register values in input_regs. A similar register_list is returned.
-- It contains the register values after the interrupt.
    return machine_func(M_INTERRUPT, {int_num, input_regs})
end function

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
	poke(mem, s[1..4]) -- avoid breaking old code
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

-- Crash handling routines:

global procedure crash_message(sequence msg)
-- Specify a final message to display for your user, in the event 
-- that Euphoria has to shut down your program due to an error.
    machine_proc(M_CRASH_MESSAGE, msg)
end procedure

global procedure crash_file(sequence file_path)
-- Specify a file path name in place of "ex.err" where you want
-- any diagnostic information to be written.
    machine_proc(M_CRASH_FILE, file_path)
end procedure

global procedure crash_routine(integer proc)
-- specify the routine id of a 1-parameter Euphoria function to call in the
-- event that Euphoria must shut down your program due to an error.
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
    
    mem = machine_func(M_ALLOC, length(s) + 1) -- Thanks to Igor
    if mem then
	poke(mem, s)
	poke(mem+length(s), 0)  -- Thanks to Aku
    end if
    return mem
end function

-- variables and routines used in safe.e
without warning
integer check_calls
check_calls = 1

global procedure register_block(atom block_addr, atom block_len)
end procedure

global procedure unregister_block(atom block_addr)
end procedure

global procedure check_all_blocks()
end procedure
with warning


