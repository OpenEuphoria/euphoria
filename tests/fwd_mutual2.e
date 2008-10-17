public include fwd_mutual1.e
include std/unittest.e

export function foo2()
	return 2
end function

public atom fwd1 = foo1()

fwd_add = 1
fwd_add = fwd_add + fwd_add

fwd_sub = 1
fwd_sub = fwd_sub - fwd_sub

fwd_mult = 3
fwd_mult = fwd_mult * 4

fwd_mult2 = 2
fwd_mult2 = fwd_mult2 * 2

fwd_div = 18
fwd_div = fwd_div / 6

fwd_div2 = 4
fwd_div2 = fwd_div2 / 2

fwd_sub_assign = { 0 }
fwd_sub_assign[1] = 1

function fwd_switch( object x )
	switch x do
		case FWD_CASE_1:
			return 1
		case FWD_CASE_2:
			return 2
		case else
			return 0
	end switch
end function

export procedure test_forward_case()
	test_equal( "fwd_switch #1", 1, fwd_switch( FWD_CASE_1 ) )
	test_equal( "fwd_switch #2", 2, fwd_switch( FWD_CASE_2 ) )
	test_equal( "fwd_switch #3", 0, fwd_switch( 999 ) )
end procedure