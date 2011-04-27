include std/math.e
include std/stats.e
include std/console.e

-- this makes sum_trial_ii a lot faster
without type_check

sequence s1 = rand(repeat(255,5000))
sequence s2 = rand(repeat(255,5000))

sequence s3b = rand(repeat(1_000_000_000,500))
sequence s4b = rand(repeat(1_000_000_000,500))

sequence save = {s1,s2}
sequence ans

-- we need large trial counts to get the standard deviation down...
constant inner_trials = 5000

constant neg_prefixes = { {0.001,"m"} , {0.00_000_1,"mc"}, 
						  {0.00_000_000_1,"n"}, {0.00_000_000_000_1,"p"} }
function get_metric_prefix( atom value )
	if not value then
		return {1,""}
	end if
	atom digit_count = floor(log(value)/log(1000))
	if digit_count < 0 and digit_count > -4 then
		return neg_prefixes[-digit_count]
	end if
	return {1,""}
end functionw

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
	for i = 1 to 20 do
		s1 = save[1]
		s2 = save[2]
		s1[1] = s1[1] -- deep copy s1
		s2[1] = s2[1] -- deep copy s2
		timing_data = append(timing_data, call_func(r,{}))
	end for
	sequence stats = average(timing_data) & 2*stdev(timing_data)
	sequence prefix = get_metric_prefix(stats[1])
	stats /= prefix[1]
	printf(1, "%s: %.3f +- %f %ss\n", prepend(append(stats,prefix[2]),message) )
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

maybe_any_key("Press any key to Close")
