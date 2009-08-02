include std/map.e as m
include hello.etml as hello

sequence cmds = command_line()
if length(cmds) != 3 then
	puts(1, "usage: test.ex <name>")
	abort(0)
end if

m:map d = m:new()
m:put(d, "name", cmds[3])

puts(1, hello:template(d) & "\n")
