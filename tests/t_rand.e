include std/unittest.e
include std/rand.e

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

test_report()

