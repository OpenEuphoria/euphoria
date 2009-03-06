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

without inline

function baz( fwdtype b )
	return b
end function


procedure foo( integer bar )
	if bar = 1 then
	else
		fwdtype f = {123}
		f = baz( f )
	end if
	
end procedure

type fwdtype( sequence f )
	return sequence(f)
end type
foo(1)
test_pass( "shift when pc = addr" )

with inline
function int_switch( integer i )
	switch i do
		case 1:
			return 1
		case 2:
			return 2
		case else
			return 0
	end switch
end function

procedure test_inline_switch_jumps()
	sequence s = {0,1,2}
	
	for i = 0 to 2 do
		test_equal( sprintf( "inlined int switch with known int #%d", i), i, int_switch( i ) )
		test_equal( sprintf( "inlined switch with unknown int #%d", i ), i, int_switch( s[i+1] ) )
	end for

end procedure
test_inline_switch_jumps()

function const_init( integer x )
	if x = 0 then
		return 0
	else
		return x * x
	end if
end function

constant
	ZERO_INIT = const_init( 0 ),
	ONE_INIT  = const_init( 1 ),
	TWO_INIT  = const_init( 2 )
test_equal( "inlined const init 0", 0, ZERO_INIT )
test_equal( "inlined const init 1", 1, ONE_INIT )
test_equal( "inlined const init 2", 4, TWO_INIT )

test_report()
