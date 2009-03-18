-- Execution-count profile.
-- Left margin shows the exact number of times that
-- the statement(s) on that line were executed.

       |
       |constant SIZE = 8192 
       |
       |constant ON = 1, OFF = 0
       |
       |procedure main()
       |    integer count, iterations
       |    sequence flags, cmd
       |    object arg
       |    
     1 |    cmd = command_line()
     1 |    iterations = 1
     1 |    if length(cmd) = 3 then
       |	arg = value(cmd[3])
       |	if arg[1] = GET_SUCCESS then
       |	    iterations = arg[2]
       |	end if
       |    end if
       |    
     1 |    for iter = 1 to iterations do
     1 |	count = 0
     1 |	flags = repeat(ON, SIZE)
     1 |	for i = 2 to SIZE do
  8191 |	    if flags[i] then
  1028 |		for k = i + i to SIZE by i do
 18690 |		    flags[k] = OFF
 18690 |		end for 
  1028 |		count += 1
       |	    end if
  8191 |	end for
     1 |    end for
     1 |    printf(1, "Count: %d\n", count)
     1 |end procedure
       |
     1 |puts(1, "Prime Sieve Benchmark\n")
       |
       |atom t
     1 |t = time()  -- start timer
       |    
     1 |main()
       |
     1 |t = time() - t -- end timer
       |
     1 |printf(1, "time: %.2f\n", t)
       |
       |-- if getc(0) then  -- wait for key press
       |-- end if
       |

