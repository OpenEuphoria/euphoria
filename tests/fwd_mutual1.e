include fwd_mutual2.e

export function foo1()
	return 1
end function

public atom fwd2 = foo2()

public atom fwd_add
public atom fwd_sub
public atom fwd_mult
public atom fwd_mult2
public atom fwd_div
public atom fwd_div2
public sequence fwd_sub_assign

public constant 
	FWD_CASE_1 = 1,
	FWD_CASE_2 = {1,"2"}

test_forward_case()
