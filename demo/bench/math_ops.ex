include std/math.e
include std/stats.e
include std/console.e
include std/text.e
include std/search.e
include std/filesys.e
include std/datetime.e
-- this makes sum_trial_ii a lot faster
without type_check

constant cmd = command_line()
sequence log_open_mode

object script_timestamp = file_timestamp(cmd[$])
if not datetime(script_timestamp) then
	maybe_any_key("Error, cannot stat program file.  Press Enter to Close.")
	abort(2)
end if


function setup_logging()
	integer last_bslash = rfind('\\',cmd[1])
	integer next_bslash  = last_bslash-1
	sequence file_name
	object log_timestamp -- may be assigned to -1.
	if last_bslash = 0 then
		file_name = "none.log"
	else
		while next_bslash and not find(cmd[1][next_bslash],"\\:") do
			next_bslash -= 1
		end while
	    file_name = cmd[1][next_bslash+1..last_bslash-1] & ".log"
	end if
	-- if file_name doesn't exist, it wont matter which mode
	-- is used for opening.
	log_timestamp = file_timestamp(file_name)
	if compare(script_timestamp, log_timestamp) < 0 then
		log_open_mode = "a"
	else
		-- the script has been modified, truncate this log file.
		log_open_mode = "w"
	end if
	return open(file_name, log_open_mode)
end function

integer stdlog = setup_logging()

printf(1,"Executed using: %s", {cmd[1]})

sequence s1 = rand(repeat(255,5000))
sequence s2 = rand(repeat(255,5000))

sequence s3b = rand(repeat(1_000_000_000,500))
sequence s4b = rand(repeat(1_000_000_000,500))

sequence save = {s1,s2}
sequence ans

-- we need large trial counts to get the standard deviation down...
constant inner_trials = 5000
constant base_prefix = {1,""}
constant tiniest_prefix = {0.00_000_000_000_1,"p"}
constant neg_prefixes = { {0.001,"m"} , {0.00_000_1,"mc"}, 
						  {0.00_000_000_1,"n"}, tiniest_prefix }
function get_metric_prefix( atom value )
	if not value then
		return tiniest_prefix
	end if
	atom digit_count = floor(log(value)/log(1000))
	if digit_count < 0 and digit_count > -4 then
		return neg_prefixes[-digit_count]
	end if
	return base_prefix
end function

function nothing_trial()
	atom ti
	ti = time()
	while ti = time() do
	end while
	ti = time()
	for k = 1 to inner_trials do
	end for
	atom tf = time()
	return (tf-ti)/inner_trials
end function	

function sum_trial_ii()
	atom ti
	integer r
	integer other = #BA5
	ti = time()
	while ti = time() do
	end while
	ti = time()
	for k = 1 to inner_trials do
		r = #F00 + other
	end for
	atom tf = time()
	return (tf-ti)/inner_trials
end function

function sum_trial_is()
	atom ti 
	ti = time()
	while ti = time() do
	end while
	ti = time()
	for k = 1 to inner_trials do
		ans = #F00 + s2
	end for
	atom tf = time()
	return (tf-ti)/inner_trials
end function

procedure display_report(sequence message, sequence routine_name)
	integer r = routine_id(routine_name)	
	sequence timing_data = {}
	sequence minimums = {}
	sequence out
	for j = 1 to 30 do
		for i = 1 to 8 do
			s1 = save[1]
			s2 = save[2]
			s1[1] = s1[1] -- deep copy s1
			s2[1] = s2[1] -- deep copy s2
			timing_data = append(timing_data, call_func(r,{}))
		end for
		minimums = append(minimums, min(timing_data))
	end for
	
	sequence stats = average(minimums) & stdev(minimums)
	sequence prefix = get_metric_prefix(stats[1])
	stats /= prefix[1]
	if length(message) then
		message[1] = lower(message[1])
	end if
	message = "Average minimal " & message
	out = sprintf("%s: %.3f (stddev: %.3f) %ss\n", prepend(append(stats,prefix[2]),message) )
	puts(1,out)
	puts(stdlog,out)
end procedure


function sum_trial_s2()
	atom ti 
	ti = time()
	while ti = time() do
	end while
	ti = time()
	for k = 1 to inner_trials do
		ans = s1 + s2
	end for
	atom tf = time()
	return (tf-ti)/inner_trials
end function



display_report("Time to do nothing", "nothing_trial")
display_report("Time to add an integer to another integer", "sum_trial_ii")
display_report("Time to add an integer to a 5000 long sequence of integers", "sum_trial_is")
display_report("Time to add two 5000 long sequences of integers", "sum_trial_s2")

function subtract_trial_si()
	atom ti 
	ti = time()
	while ti = time() do
	end while
	ti = time()
	for k = 1 to inner_trials do
		ans = s1 - 25
	end for
	atom tf = time()
	return (tf-ti)/inner_trials
end function

display_report( "Time to subtract an integer from a 5000 long sequence of integers", "subtract_trial_si")


function subtract_trial_2()
	atom ti 
	ti = time()
	while ti = time() do
	end while
	ti = time()
	for k = 1 to inner_trials do
		ans = s1 - s2
	end for
	atom tf = time()
	return (tf-ti)/inner_trials
end function


display_report( "Time to subtract an a 5000 long sequence of integers from\n" &
	"another 5000 long sequence of integers", 
	"subtract_trial_2")
	
close(stdlog)
maybe_any_key("Press any key to Close")
