include std/unittest.e

-- Literals:
object a, b

{a, b} = { 1, 2 }
test_equal( "a {a, b} = { 1, 2 }", a, 1 )
test_equal( "b {a, b} = { 1, 2 }", b, 2 )

{?, b} = {2, 3}
test_equal( "b {?, b} = { 2, 3 }", b, 3 )

-- Swap
a = 1
b = 2
{a, b} = {b, a}
test_equal( "swap a", a, 2 )
test_equal( "swap b", b, 1 )

without inline
function foo()
	return {1, 2, 3, 4, 5}
end function

{a} = foo()
test_equal( "{a} = foo()", a, 1 )

{?, a, ?, b, ? } = foo()
test_equal( "a {?, a, ?, b, ? } = foo()", a, 2 )
test_equal( "b {?, a, ?, b, ? } = foo()", b, 4 )

test_report()
