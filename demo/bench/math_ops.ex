include std/math.e
include std/stats.e
include std/console.e

sequence s1 = rand(repeat(255,5000))
sequence s2 = rand(repeat(255,5000))
sequence ans
constant inner_trials = 10_000

constant neg_prefixes = { {0.001,"m"} , {0.00_000_1,"mc"}, {0.00_000_000_1,"n"}, {0.00_000_000_000_1,"p"} }
function get_metric_prefix( atom value )
	if not value then
		return {1,""}
	end if
	atom digit_count = floor(log(value)/log(1000))
	if digit_count < 0 and digit_count > -4 then
		return neg_prefixes[-digit_count]
	end if
	return {1,""}
end function

-- we need large trial counts to get the standard deviation down...
function sum_trial_2()
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

sequence timing_data = {}
for i = 1 to 20 do
	timing_data = append(timing_data, sum_trial_2())
end for
sequence stats = average(timing_data) & 2*stdev(timing_data)
sequence prefix = get_metric_prefix(stats[1])
stats /= prefix[1]
printf(1, "Time to add an integer to a 5000 long sequence of integers: %.3f +- %f %ss\n", append(stats,prefix[2]) )

function sum_trial_1()
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

timing_data = {}
for i = 1 to 20 do
	timing_data = append(timing_data, sum_trial_1())
end for
stats = average(timing_data) & 2*stdev(timing_data)
prefix = get_metric_prefix(stats[1])
stats /= prefix[1]
printf(1, "Time to add two 5000 long sequences of integers: %.3f +- %f %ss\n", append(stats,prefix[2]) )

function subtract_trial_1()
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

timing_data = {}
for i = 1 to 20 do
	timing_data = append(timing_data, subtract_trial_1())
end for
stats = average(timing_data) & 2*stdev(timing_data)
prefix = get_metric_prefix(stats[1])
stats /= prefix[1]
printf(1, "Time to subtract an integer from a 5000 long sequence of integers: %.3f +- %f %ss\n", append(stats,prefix[2]) )

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

timing_data = {}
for i = 1 to 20 do
	timing_data = append(timing_data, subtract_trial_1())
end for
stats = average(timing_data) & 2*stdev(timing_data)
prefix = get_metric_prefix(stats[1])
stats /= prefix[1]
printf(1, "Time to subtract an a 5000 long sequence of integers from another 5000 long sequence of integers: %.3f +- %f %ss\n", append(stats,prefix[2]) )

maybe_any_key("Press any key to Close")
