include std/sequence.e
include std/console.e as con
include std/convert.e
include std/cmdline.e
include std/map.e

without warning

override procedure abort(integer x)
	maybe_any_key()

	eu:abort(x)
end procedure

ifdef WIN32_GUI then
	puts(1, "This program must be run from the command-line\n")
	abort(1)
end ifdef

procedure main()
	sequence opts = {
		{ "i", "iterations", "Number of iterations (default 1)", { HAS_PARAMETER, "count" }},
		{ 0, "verbose", "Verbose (timing for each iteration)", { NO_PARAMETER }}
	}
	map o = cmd_parse(opts)

	integer verbose = map:get(o, "verbose", 0)
	object iterations = map:get(o, "iterations", 1)
	if sequence(iterations) then
		iterations = to_number(iterations)
	end if

	sequence cmds = map:get(o, OPT_EXTRAS)
	if length(cmds) = 0 then
		show_help(opts)
		abort(1)
	end if

	sequence cmd = join(cmds)

	atom t1 = time()
	for i = 1 to iterations do
		atom tThis = time()
		system(cmd, 2)
		if verbose then
			printf(1, "iteration %d: %f\n", { i, time() - tThis })
		end if
	end for
	atom t2 = time()

	if iterations > 1 then
		printf(1, "total time %f, avg per iteration %f\n", { t2 - t1, (t2 - t1) / iterations })
	else
		printf(1, "Time = %f\n", { t2 - t1 })
	end if
end procedure

main()
