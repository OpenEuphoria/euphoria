-- inlining tests
include std/unittest.e
atom e
integer c
integer d
sequence s

without inline
function short_wo(integer a, sequence b)
   return b & a
end function

c = 0
e = time() + 0.1
while time() < e do
    s = short_wo('a', "abc")
    c += 1
end while


with inline
function short_wi(integer a, sequence b)
   return b & a
end function

d = 0
e = time() + 0.1
while time() < e do
    s = short_wi('a', "abc")
    d += 1
end while

-- The number of executions of 'with out' should be less than 'with'.
test_true(sprintf("inline %d < %d", {c,d}), c < d)

function set( sequence s, object v )
	s[1] = v
	return s
end function
s = {1}
s = set( s, 2 )
test_equal( "parameter assigned and return value", 2, s[1] )

test_report()
