	-- hardware interrupt handler example
include std/machine.e
include std/convert.e
include std/dos/base_mem.e

atom handlerA_address, handlerB_address
sequence usual_address
atom code_segment

-- record the values of the data segment and code segment
atom segment, clock_ticks
segment = allocate(4)
lock_memory(segment, 4)

clock_ticks = allocate(4)
lock_memory(clock_ticks, 4)

sequence save_segment_code
save_segment_code = {
    #53,   -- push ebx
    #0E,   -- push cs   or #1E push ds -- only a 16-bit value
    #5B,   -- pop ebx  
    #89, #1D} & int_to_bytes(segment) & -- mov segment, ebx
    {#5B,   -- pop ebx
    #C3    -- ret
}       
-- note: there's no "pop cs" instruction

atom save_segment
save_segment = allocate(length(save_segment_code))
poke(save_segment, save_segment_code)
call(save_segment) -- save code segment

-- N.B. Only read the low order two bytes! - See data segment below
code_segment = peek(segment) + 256 * peek(segment+1)

poke(save_segment+1, #1E) 
call(save_segment) -- save data segment

-- Here's one type of interrupt handler:
-- Handler A just returns from the interrupt
-- after incrementing clock_ticks.

sequence handlerA_code
handlerA_code = {
    #1E,       -- push ds  
    #60,       -- pushad
    
    -- restore our data segment value:
    #BB} & 
    
    -- N.B. Only read low-order 2 bytes of segment.
    peek({segment, 2}) & {0,0} & -- mov ebx, data segment value
   
   {#53,       -- push ebx
    #1F        -- pop ds
    } & {#FF, #05} & int_to_bytes(clock_ticks) &  -- inc clock_ticks
    {
    -- acknowledge the interrupt (might not be necessary?)
    #BA,#20,0,0,0,   -- mov edx, 20 -- port number
    #B0,#20,         -- mov al, value to send to port
    #EE,             -- out dx, al
    
    #61,       -- popad
    #1F,       -- pop ds 
    #CF        -- iretd  -- return from interrupt
}

-- Here's another type of interrupt handler:

-- Handler B jumps to the usual clock tick interrupt handler after
-- incrementing clock_ticks

sequence handlerB_code
handlerB_code = {
    #1E,        -- push ds  
    #60,        -- pushad

    -- restore our data segment value:
    #BB} & peek({segment, 2}) & {0,0} & -- mov ebx, data segment value
   {#53,    -- push ebx
    #1F,    -- pop ds
    
    #FF, #05} & int_to_bytes(clock_ticks) &  -- inc clock_ticks
    
   {#61,        -- popad  -- make things the same as when we were called
    #1F,        -- popds
    
    #EA,        -- jmp to the usual interrupt handler
    #00,        -- 6-byte segment and offset to be filled in later
    #00,
    #00,
    #00,
    #00,
    #00
}

handlerA_address = allocate(length(handlerA_code))

poke(handlerA_address, handlerA_code)

usual_address = get_vector(#1C) -- clock tick

handlerB_address = allocate(length(handlerB_code))

--plug in far address of usual handler:
handlerB_code[length(handlerB_code)-5..
	      length(handlerB_code)] = 
	      int_to_bytes(usual_address[2]) &
	      remainder(usual_address[1], 256) & floor(usual_address[1] / 256) 

poke(handlerB_address, handlerB_code)

lock_memory(handlerA_address, length(handlerA_code))
lock_memory(handlerB_address, length(handlerB_code))

atom t
constant WAIT = 5

-- Handler A
poke4(clock_ticks, 0)
set_vector(#1C, {code_segment, handlerA_address}) 
t = time()
printf(1, "Handler A installed. wait %d seconds ...\n", WAIT)
while time() < t + WAIT do
end while
set_vector(#1C, usual_address)

printf(1, "Number of clock interrupts: %d\n", peek4u(clock_ticks))

-- Handler B
poke4(clock_ticks, 0)
set_vector(#1C, {code_segment, handlerB_address}) 
t = time()
printf(1, "Handler B installed. wait %d seconds ...\n", WAIT)
while time() < t + WAIT do
end while
set_vector(#1C, usual_address)

printf(1, "Number of clock interrupts: %d\n", peek4u(clock_ticks))

