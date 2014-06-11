public enum
-- math
xq_ADD,
xq_SUB,
xq_MUL,
xq_DIV,
xq_MOD,
xq_POW,
-- logical
xq_AND,
xq_OR,
xq_XOR,
-- bitwise
xq_AND_BITS,
xq_OR_BITS,
xq_XOR_BITS,
-- comparison
xq_LESS,
xq_MORE,
xq_EQU,
xq_NEQ,
xq_LEQ,
xq_GEQ,
xq_NOP

function xq_do_op(atom a, atom b, integer op)
	switch op do
		-- math
		case xq_ADD then
			return a+b
		case xq_SUB then
			return a-b
		case xq_MUL then
			return a*b
		case xq_DIV then
			return a/b
		case xq_MOD then
			return remainder(a,b)
		case xq_POW then
			return power(a,b)
		-- logical
		case xq_AND then
			return a and b
		case xq_OR then
			return a or b
		case xq_XOR then
			return a xor b
		-- bitwise
		case xq_AND_BITS then
			return and_bits(a,b)
		case xq_OR_BITS then
			return or_bits(a,b)
		case xq_XOR_BITS then
			return xor_bits(a,b)
		-- comparison
		case xq_LESS then
			return a<b
		case xq_MORE then
			return a>b
		case xq_EQU then
			return a=b
		case xq_NEQ then
			return a!=b
		case xq_LEQ then
			return a<=b
		case xq_GEQ then
			return a>=b
		case else
			return -1
	end switch
end function
public function xq_op(object a, object b, integer op)
    if atom(a) then
        if atom(b) then return xq_do_op(a, b, op) end if
        for i=1 to length(b) do
            b[i] = xq_op(a,b[i],op)
        end for
        return b
    elsif atom(b) then
        for i=1 to length(a) do
            a[i] = xq_op(a[i],b,op)
        end for
        return a
    end if
--  if length(a)!=length(b) then fatal(a,b) end if
    if length(a)<length(b) then
        for i=1 to length(a) do
            b[i] = xq_op(a[i],b[i],op)
        end for
        return b
    end if
    for i=1 to length(b) do
        a[i] = xq_op(a[i],b[i],op)
    end for
    return a
end function

-- math
public function xq_add(object a, object b)
	return xq_op(a, b, xq_ADD)
end function
public function xq_sub(object a, object b)
	return xq_op(a, b, xq_SUB)
end function
public function xq_mul(object a, object b)
	return xq_op(a, b, xq_MUL)
end function
public function xq_div(object a, object b)
	return xq_op(a, b, xq_DIV)
end function
public function xq_mod(object a, object b)
	return xq_op(a, b, xq_MOD)
end function
public function xq_pow(object a, object b)
	return xq_op(a, b, xq_POW)
end function
-- logical
public function xq_and(object a, object b)
	return xq_op(a, b, xq_AND)
end function
public function xq_or(object a, object b)
	return xq_op(a, b, xq_OR)
end function
public function xq_xor(object a, object b)
	return xq_op(a, b, xq_XOR)
end function
-- bitwise
public function xq_and_bits(object a, object b)
	return xq_op(a, b, xq_AND_BITS)
end function
public function xq_or_bits(object a, object b)
	return xq_op(a, b, xq_OR_BITS)
end function
public function xq_xor_bits(object a, object b)
	return xq_op(a, b, xq_XOR_BITS)
end function
-- comparison
public function xq_less(object a, object b)
	return xq_op(a, b, xq_LESS)
end function
public function xq_more(object a, object b)
	return xq_op(a, b, xq_MORE)
end function
public function xq_equ(object a, object b)
	return xq_op(a, b, xq_EQU)
end function
public function xq_neq(object a, object b)
	return xq_op(a, b, xq_NEQ)
end function
public function xq_leq(object a, object b)
	return xq_op(a, b, xq_LEQ)
end function
public function xq_geq(object a, object b)
	return xq_op(a, b, xq_GEQ)
end function
