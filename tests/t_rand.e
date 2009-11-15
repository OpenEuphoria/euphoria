include std/unittest.e
include std/rand.e
include std/math.e

object s
object t

set_rand(1001)
s = {rand(10), rand(100), rand(1000)}
set_rand(1001)
t = {rand(10), rand(100), rand(1000)}

test_true( "set_rand", equal(s,t))


set_rand(1001)
test_equal("rand_range A", 22, rand_range(18, 24))
test_equal("rand_range B", -15, rand_range(-18, 24))
test_equal("rand_range C", -20, rand_range(-24, -18))
test_equal("rand_range D", -23, rand_range(-18, -24))

set_rand(1001)
test_equal("rnd() A", 0.391873680838033, rnd())
test_equal("rnd() B", 0.257111201676016, rnd())
test_equal("rnd() C", 0.527862612725599, rnd())

set_rand(1001)
test_equal("rnd_1() A", 0.391873680838033, rnd_1())
test_equal("rnd_1() B", 0.257111201676016, rnd())
test_equal("rnd_1() C", 0.527862612725599, rnd())

set_rand(1001)
atom A = rnd()

set_rand(1002)
atom B = rnd()

test_true( "rnd() #2", A != B)

set_rand({34, 100919})
test_equal("set_rand explicit", 0.734853451398937, rnd())

set_rand("some text string as a seed generator")
test_equal("set_rand explicit", 0.652952084646423, rnd())

set_rand("") -- Reset generator.
integer y = 0
integer n = 0
integer c = 10000
for i = 1 to c do
	if chance(50) then
		y += 1
	else
		n += 1
	end if
end for

test_equal("chance()",0, approx(y,n, c * 0.025))

y = 0
n = 0
c = 10000
integer sides = 20
sequence ls = {1,5,11}
for i = 1 to c do
	if roll(ls, sides) then
		y += 1
	else
		n += 1
	end if
end for
test_equal("roll()",0, approx(y, c * length(ls) / sides, c * 0.025))


test_report()

