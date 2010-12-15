include std/sequence.e
include std/console.e as con
include std/convert.e
include std/cmdline.e
include std/map.e
include std/math.e

without warning

constant VERSION = "1.0"

override procedure abort(integer x)
	maybe_any_key()
	eu:abort(x)
end procedure

ifdef WIN32_GUI then
	puts(2, "This program must be run from the command-line\n")
	abort(1)
end ifdef

procedure main()
	atom min_time = 999_999, max_time = -1

	sequence opts = {
		{ "i", "iterations", "Number of iterations (default 1)", { HAS_PARAMETER, "count" } },
		{   0, "stdout",     "Use standard output instead of standard error", {} },
		{   0, "verbose",    "Verbose (timing for each iteration)", { NO_PARAMETER } },
		{   0, "version",    "Display version number", { VERSIONING, "eubench v" & VERSION } }
	}
	map o = cmd_parse(opts, { NO_VALIDATION_AFTER_FIRST_EXTRA })

	integer verbose = map:get(o, "verbose", 0)
	object iterations = map:get(o, "iterations", 1)
	if sequence(iterations) then
		iterations = to_number(iterations)
	end if

	sequence cmds = map:get(o, cmdline:EXTRAS)
	if length(cmds) = 0 then
		show_help(opts)
		abort(1)
	end if

	-- Set output location:
	--     if stdout was supplied, it will be 1 otherwise the default map:get is returned
	--     which is 2, stderr.
	integer screen_fh = map:get(o, "stdout", 2)

	sequence cmd = join(cmds)

	atom t1 = time()
	for i = 1 to iterations do
		atom tThis = time()

		system(cmd, 2)

		atom tThisTotal = time() - tThis
		if tThisTotal > max_time then max_time = tThisTotal end if
		if tThisTotal < min_time then min_time = tThisTotal end if

		if verbose then
			printf(screen_fh, "iteration %d: %f\n", { i, tThisTotal })
		end if
	end for
	atom t2 = time()

	if iterations > 1 then
		printf(screen_fh, "%d iterations: total %f, max %f, avg %f, min %f\n", {
			iterations,
			t2 - t1,
			max_time,
			(t2 - t1) / iterations,
			min_time
		})
	else
		printf(screen_fh, "Time = %f\n", { t2 - t1 })
	end if
end procedure

main()
