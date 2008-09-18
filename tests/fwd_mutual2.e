public include fwd_mutual1.e

export function foo2()
	return 2
end function

public atom fwd1 = foo1()

with trace

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
