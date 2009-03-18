include std/sequence.e

procedure main(sequence cmds=command_line())
	if length(cmds) < 3 then
		puts(1, "Usage: bench myprog [myprog options]\n")
		abort(1)
	end if

	sequence cmd = join(cmds[3..$])

	atom t1 = time()
	system(cmd, 2)
	printf(1, "Time = %f\n", { time() - t1 })
end procedure

main()
