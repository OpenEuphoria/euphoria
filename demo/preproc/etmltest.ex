include std/map.e as m
include hello.etml as hello
include std/console.e as con

sequence cmds = command_line()
if length(cmds) != 3 then
	ifdef WINDOWS and GUI then
	    puts(1, "This program must be run from the command-line:\n\n")
	end ifdef

	puts(1, "usage: eui etmltest.ex <name>\n")
	con:maybe_any_key()
	abort(0)
end if

m:map d = m:new()
m:put(d, "name", cmds[3])

puts(1, hello:template(d) & "\n")
con:maybe_any_key()
