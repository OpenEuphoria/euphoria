include std/pipeio.e as pipe

object z = pipe:create()

integer bytes = pipe:write(z[PARENT][STDIN],"This data was written to pipe STDIN!")
printf(1,"Number of bytes written to STDIN: %d\n\n", { bytes })

if pipe:close(z[PARENT][STDIN]) then
	printf(1, "Failed on closing STDIN with error %x\n", pipe:error_no())
	abort(1)
end if

object p = pipe:exec("eui pipe_sub.ex", z)
if atom(p) then
	printf(1, "Failed to exec() with error %x\n", pipe:error_no())
	abort(1)
end if

object c = pipe:read(p[STDOUT], 256)
if atom(c) then
	printf(1, "Failed on read with error %x\n", pipe:error_no())
	abort(1)
end if

puts(1,"demo1.ex read from pipe STDOUT: \""&c&"\"")

--Close pipes and make sure process is terminated
pipe:kill(p)

puts(1,"\n\n")
