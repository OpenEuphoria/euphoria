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


ifdef EC then
	-- the compiler may inline on its own when translated
	test_pass( "inlined functions ran" )
elsedef
	-- The number of executions of 'with out' should be less than 'with'.
	test_true(sprintf("inline %d < %d", {c,d}), c < d)
end ifdef

function set( sequence s, object v )
	s[1] = v
	return s
end function
s = {1}
s = set( s, 2 )
test_equal( "parameter assigned and return value", 2, s[1] )

with inline 50
function return_literal( object o )
	if sequence(o) then
		return 2
	end if
	if o > 3 then
		return 3
	end if
	return 1
end function

test_equal( "return literal {}", 2, return_literal( {} ) )
test_equal( "return literal 0", 1, return_literal( 0 ) )
test_equal( "return literal 4", 3, return_literal( 4 ) )

test_report()
