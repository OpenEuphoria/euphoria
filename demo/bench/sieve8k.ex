		   ---------------------------
		   -- Prime Sieve Benchmark --
		   -- "Shootout" Version    --
		   ---------------------------
-- usage:
--     eui sieve8k <iterations> <largest>
-- default is 1 iteration with 8192 as largest allowable prime

without type_check
include std/get.e
include std/search.e
include std/console.e as con
integer SIZE = 8192 
integer iterations = 1
integer count
sequence flags

constant ON = 1, OFF = 0

procedure init()
	object arg
	sequence cmd
	cmd = command_line()
	if length(cmd) >= 3 then
		arg = value(cmd[3])
		if arg[1] = GET_SUCCESS then
			iterations = arg[2]
		end if
	end if
	if length(cmd) >= 4 then
		arg = value(cmd[4])
		if arg[1] = GET_SUCCESS then
			SIZE = arg[2]
		end if
	end if
end procedure

procedure main()
	for iter = 1 to iterations do
		count = 0
		flags = repeat(ON, SIZE)
		for i = 2 to SIZE do
			if flags[i] then
				integer MAX = SIZE - i
				integer k = i
				while k <= MAX do
					k += i
					flags[k] = OFF
				end while
				count += 1
			end if
		end for
	end for
end procedure

puts(1, "Prime Sieve Benchmark\n")

atom t
init()

t = time()  -- start timer
    
main()

t = time() - t -- end timer
printf(1, "Count: %d, Largest: %d\ntime: %g\n", {count, rfind(ON, flags), t})  -- 1028
con:maybe_any_key()

