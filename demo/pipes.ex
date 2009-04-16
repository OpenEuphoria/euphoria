include std/pipeio.e as pipe

object z = pipe:create()
object p = pipe:exec("eui pipe_sub.ex", z)
if atom(p) then
	printf(1, "Failed to exec() with error %x\n", pipe:error_no())
	abort(1)
end if

integer bytes = pipe:write(p[STDIN],"This data was written to pipe STDIN!\n")
printf(1,"number bytes written to child: %d\n", { bytes })

object c = pipe:read(p[STDOUT], 256)
if atom(c) then
	printf(1, "Failed on read with error %x\n", pipe:error_no())
	abort(1)
end if

puts(1,"read from child pipe: \""&c&"\"")

--Close pipes and make sure process is terminated
pipe:kill(p)

puts(1,"\n\n")
