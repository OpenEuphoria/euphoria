include std/unittest.e

include scope_3.e
include scope_1.e as s1

test_equal( "public include (not on initial include)", "public constant", PUBLIC_CONSTANT )
test_equal( "public include (not on initial include) using default namespace", 1, S2:sprintf() )

test_equal( "resolve to local fwd public when unqualified", 0, public_foo() )
test_equal( "resolve to local fwd export when unqualified", 0, export_foo() )

test_equal( "resolve to other fwd public when qualified", 1, s1:public_foo() )
test_equal( "resolve to other fwd export when qualified", 1, s1:export_foo() )

public function public_foo()
	return 0
end function

export function export_foo()
	return 0
end function

include scope_4.e

test_report()
