include std/unittest.e
include std/rand.e
include std/math.e
include std/sort.e

object s
object t

set_rand(1001)
s = {rand(10), rand(100), rand(1000)}
set_rand(1001)
t = {rand(10), rand(100), rand(1000)}

test_true( "set_rand", equal(s,t))

set_rand({1001, -3456})
test_equal("get_rand #1", {1001, -3456}, get_rand())

set_rand("some text")
test_equal("get_rand #2", {-913232434,701926632}, get_rand())

set_rand(1001)
test_equal("get_rand #3", {1002, -3}, get_rand())

set_rand(1001)
test_equal("rand_range A", 22, rand_range(18, 24))
test_equal("rand_range B", -15, rand_range(-18, 24))
test_equal("rand_range C", -20, rand_range(-24, -18))
test_equal("rand_range D", -23, rand_range(-18, -24))
test_equal("rand_range E", 2.18054905704903, rand_range(1.8, 2.4))
test_equal("rand_range F", 1.27958396125514, rand_range(1, 2.4))
test_equal("rand_range G", 1.89014651699885, rand_range(1.8, 2))

set_rand(1001)
test_equal("rnd() A", 0.627733820066871, rnd())
test_equal("rnd() B", 0.782460699403474, rnd())
test_equal("rnd() C", 0.63424842841505, rnd())

set_rand(1001)
test_equal("rnd_1() A", 0.627733820066871, rnd_1())
test_equal("rnd_1() B", 0.782460699403474, rnd_1())
test_equal("rnd_1() C", 0.63424842841505, rnd_1())

set_rand(1001)
atom A = rnd()

set_rand(1002)
atom B = rnd()

test_true( "rnd() #2", A != B)

set_rand({134, -200919})
test_equal("set_rand explicit ", 0.920170838582831, rnd())

set_rand("some text string as a seed generator")
test_equal("set_rand string", 0.163853923565223, rnd())

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
test_equal("roll(-1)", 0, roll( {54}, -1 ) )
test_equal( "roll( atom )", 1, integer( roll( 3, 6 ) ) )

atom tmpNo = rand_range(0xFFFFFFFF, 0x3FFFFFFF)
test_true("rand_range(hi,lo) ticket:501", 
	(tmpNo >= 0x3FFFFFFF) and (tmpNo <= 0xFFFFFFFF))

test_equal("empty sample", {}, sample( "abc", 0 ) )
test_equal("empty sample without replacement, also unselected", {{}, "abc"}, sample( "abc", 0, 1 ) )
test_equal("full sample", "abc", sort( sample( "abc", 4, 0 ) ) )
sequence sample_result = sample( "abc", 4, 1 )
sample_result[1] = sort( sample_result[1] )
test_equal("full sample without replacement, also unselected", {"abc", {}}, sample_result )

test_report()

