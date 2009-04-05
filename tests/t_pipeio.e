include std/unittest.e
include std/pipeio.e as pipe

object p = pipe:exec("eui ../demo/pipe_sub.ex")
if atom(p) then
	test_fail("pipe:exec #1")
	abort(1)
end if

sequence message = "Hello from eutest!"
integer bytes = pipe:write(p[STDIN], message)
test_equal("pipe:write #1", length(message), bytes)

if pipe:close(p[STDIN]) then
	test_fail("pipe:close")
end if

object r = pipe:read(p[STDOUT], 256)
if atom(r) then
	test_fail("pipe:read")
else
	test_equal("pipe:read", sprintf("read from STDIN: '%s'", { message }), r)
end if

pipe:kill(p)

test_report()
