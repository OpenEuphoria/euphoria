include std/types.e
include std/pretty.e
include std/text.e


type string_array( object x )
	if not sequence(x) then
		return 0
	end if
	
	for i = 1 to length(x) do
		if not t_text(x[i]) then
			return 0
		end if
	end for
	return 1
end type


function command_line_quote( string_array cmds )
	sequence t
	
	-- Only quote the first argument if it contains spaces.
	t = quote( cmds[1], " " )
	
	-- Quote all the remaining arguments.
	for i = 2 to length(cmds) do
		t &= " " & quote(cmds[i])
	end for
	
	return t	
end function


integer fd = open("command_line.txt","w")
if fd >= 0 then
	pretty_print(fd, command_line(), {2,2,1,78,"%d","%.10g",32,127,1000,1})
	puts(fd, '\n')
	close(fd)
end if
