include std/sequence.e
include std/console.e as con
without warning

override procedure abort(integer x)
	maybe_any_key()

	eu:abort(x)
end procedure

procedure main(sequence cmds=command_line())
	if length(cmds) < 3 then
		ifdef WIN32_GUI then
		    puts(1, "This program must be run from the command-line:\n\n")
		end ifdef
		puts(1, "Usage: eui bench.ex myprog [myprog options]\n")
		abort(1)
	end if

	sequence cmd = join(cmds[3..$])

	atom t1 = time()
	system(cmd, 2)
	printf(1, "Time = %f\n", { time() - t1 })
end procedure

main()
