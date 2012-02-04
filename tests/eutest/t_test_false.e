include std/unittest.e

function is_prime(integer x)
	if x = 2 then
		return 0 -- wrong
	elsif x = 3 then
		return 1
	elsif remainder(x,2)=1 then
		return 1 -- wrong
	end if
	return 0
end function

test_true( "trivial eutest test gone bad...", is_prime(2) )
test_true( "trivial eutest 3 is prime...", is_prime(3) )
test_false( "all odd numbers are prime [not!]", is_prime(15))
test_equal( "a question of order of operations", 1 + 40 = 40 * 0, 1 ) -- wrong answer

test_report()
