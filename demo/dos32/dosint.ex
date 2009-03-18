	-- DOS Interrupt examples

include std/machine.e
include std/dos/base_mem.e
include std/dos/interrup.e

constant SCREEN = 1, ERR = 2

	-- Example 1: Get DOS version number

sequence reg_list -- list of register values

reg_list = repeat(0, 10)
reg_list[REG_AX] = #3000   -- function: AH = #30 ==> Get MS-DOS Version Number

reg_list = dos_interrupt(#21, reg_list) -- Call DOS interrupt #21

if and_bits(reg_list[REG_FLAGS], 1) then
    puts(ERR, "Problem with Get DOS version interrupt\n")
end if
printf(SCREEN, "DOS Version: %d.%d\n", {remainder(reg_list[REG_AX], #100), 
				       floor(reg_list[REG_AX] / #100)})

		    
	-- Example 2: Get name of current directory
	-- Note: Euphoria has a library routine for this. See current_dir().

integer low_buff, p  -- low memory addresses (integer ok)
sequence dir_name

low_buff = allocate_low(100)  -- space in low memory to hold directory name

reg_list = repeat(0, 10)
reg_list[REG_AX] = #4700                   -- function: AH = #47
reg_list[REG_DX] = 0                       -- select current drive
reg_list[REG_DS] = floor(low_buff / 16)    -- address - paragraph number 
reg_list[REG_SI] = remainder(low_buff, 16) -- address - offset

reg_list = dos_interrupt(#21, reg_list)    -- Call DOS interrupt #21

if and_bits(reg_list[REG_FLAGS], 1) != 0 then
    puts(2, "Couldn't get name of current directory!\n")
end if

dir_name = "\\"
p = low_buff
while peek(p) != 0 do
    dir_name &= peek(p)
    p += 1
end while

free_low(low_buff)

puts(SCREEN, "Current Directory: " & dir_name & '\n')

