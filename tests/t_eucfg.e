include std/cmdline.e
include std/unittest.e
include std/pipeio.e as pipe
include std/get.e

sequence cmd = command_line()

ifdef EUI then
	object this_pipe = pipe:create()
	object ph = pipe:exec(build_commandline(cmd[1..1] & { "-c", "definenum.cfg", "runnum.ex" }),this_pipe)
	object read_number = pipe:read(ph[pipe:STDOUT], 256)
	sequence buf = value(read_number)
    if buf[1] = GET_SUCCESS then
        test_equal("Explicit Configuration files are respected.",2,buf[2])
    else
    	test_fail("Explicit Configuration files are respected")
    end if

end ifdef
test_report()
