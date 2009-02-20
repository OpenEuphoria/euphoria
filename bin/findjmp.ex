-- This program disassembles be_execute.obj
-- and parses the assembler code to determine
-- what jumptab should have been set to.
-- Algorithm Thanks to Jim Brown
include std/os.e
include std/types.e

sequence alphabet = repeat(0, 255 )
for i = 1 to length(alphabet) do
	alphabet[i] = i
end for

sequence hextable = { alphabet['0'..'9'] & alphabet['A'..'F'],
		      0 & alphabet[1..15] }

function parse_hex_number( sequence s )
	integer value = 0
	integer deltai
	for i = 1 to length(s) do
		deltai = find(s[i],hextable[1])
		if not deltai then
			exit
		end if
		value *= 16
		value += hextable[2][deltai]
	end for
	return value
end function

system( "wdis be_execute.obj > be_execute.asm", 0 )
integer asm = open("be_execute.asm","r")
object line
atom exec_addr = 0, jmp_addr = 0
line = ""
while sequence(line) and not
	 match( " Execute_:", line ) do
	line = gets(asm)
end while
if sequence(line) and length(line) > 7 then
	exec_addr = parse_hex_number(line[1..8] )
end if
line = gets(asm)
while sequence(line) and not match( " DD\t", line ) do
	line = gets(asm)
end while
jmp_addr = parse_hex_number(line[1..8])
close(asm)
if exec_addr and jmp_addr then
	-- create .h file for jumptab address
	printf(1,"int ** jumptab = Execute+%d\n", {jmp_addr - exec_addr }/4 )
else
	abort(1) -- tell Make to quit
end if
