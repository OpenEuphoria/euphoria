-- fwd.e
include t_fwd.e

export procedure foo2(integer a)
	result2 = 123
end procedure

export function foo3(integer a)
	for i = 1 to 3 do
		result3[i] = i
	end for
	return a + 3
end function

