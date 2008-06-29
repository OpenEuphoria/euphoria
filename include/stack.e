-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
--****
-- == Stack
--
-- TODO: 
-- documentation

include error.e

--****
-- === Constants
--

export constant
	FIFO = 1,
	FILO = 2

--****
-- === Types
--

--**
export type stack(object o)
	return sequence(o) and length(o) >= 1
end type

--****
-- === Routines
--

--**
export function new(integer stack_type)
	return {stack_type}
end function

--**
export function is_empty(stack sk)
	return length(sk) = 1
end function

--**
export function size(stack sk)
	return length(sk) - 1
end function

--**
export function at(stack sk, integer idx)
	if idx <= 0 then
		-- number from top
		idx = length(sk) + idx
		if idx<=1 then
			crash("stack underflow in at()", {})
		end if
	else
		idx += 1
		if idx>length(sk) then
			crash("stack overflow in at()", {})
		end if
	end if
	
	return sk[idx]
end function

--**
export function push(stack sk, object value)

	if sk[1] = FIFO then
		sk = prepend(sk, FIFO)
		sk[2] = value
		return sk
	else
		return append(sk, value)
	end if
end function

--**
export function top(stack sk)
	if length(sk) = 1 then
		crash("stack underflow in top()", {})
	end if

	return sk[$]
end function

--**
export function pop(stack sk)
	if length(sk) = 1 then
		crash("stack underflow in pop()", {})
	end if

	return sk[1..$-1]
end function

--**
export function swap(stack sk)
	object a, b

	if length(sk) < 3 then
		crash("stack underflow in swap()", {})
	end if

	a = sk[$]
	b = sk[$-1]

	sk[$] = b
	sk[$-1] = a

	return sk
end function

--**
export function dup(stack sk)
	if length(sk) = 1 then
		crash("stack underflow in dup()", {})
	end if

	return sk & {sk[$]}
end function

--**
export function clear(stack sk)
	return {sk[1]}
end function
