include std/math.e
include std/stats.e
sequence s1 = rand(repeat(255,5000))
sequence s2 = rand(repeat(255,5000))
sequence ans

constant neg_prefixes = { {0.001,"m"} , {0.00_000_1,"mc"}, {0.00_000_000_1,"n"}, {0.00_000_000_000_1,"p"} }
function get_metric_prefix( atom value )
	if not value then
		return ""
	end if
	atom digit_count = floor(log(value)/log(1000))
	if digit_count < 0 then
		return neg_prefixes[-digit_count]
	end if
	return ""
end function

constant inner_trials = 1_000
function sum_trial()
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

sequence timing_data = {}
for i = 1 to 50 do
	timing_data = append(timing_data, sum_trial())
end for
sequence stats = average(timing_data) & 2*stdev(timing_data)
sequence prefix = get_metric_prefix(stats[1])
stats /= prefix[1]
printf(1, "Time to add two 5000 long sequences: %.3f +- %f %ss\n", append(stats,prefix[2]) )

	
