-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
--****
-- == Stack
--
-- **Page Contents**
--
-- <<LEVELTOC depth=2>>

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
-- A stack is a sequence of objects with some internal data.
export type stack(object o)
	return sequence(o) and length(o) >= 1
end type

--****
-- === Routines
--

--**
-- Create a new stack.
--
-- Parameters:
--		# ##stack_type##: an integer, defining the semantics of the stack
--
-- Returns:
--		An empty **stack***.
--
-- Comments:
-- There are two sorts of stacks, designated by the types ##FIFO## and ##FILO##:
-- * A ##FIFO## stack is one where the first item to be pushed is popped first. People standing in line form a ##FIFO## stack.
-- * a ##FILO## stack is one where the item pushed last is popped first. A stack of coins is of the ##FILO## kind.
--
-- See Also:
-- [[:is_empty]]
export function new(integer stack_type)
	return {stack_type}
end function

--**
-- Determine whether a stack is empty.
--
-- Parameters:
--		# ##sk##: the stack being queried.
--
-- Returns:
--		An **integer**, 1 if the stack is empty, else 0.
--
-- See Also:
-- [[:size]]
export function is_empty(stack sk)
	return length(sk) = 1
end function

--**
-- Returns how many elements a stack has.
--
-- Parameters:
--		# ##sk##: the stack being queried.
--
-- Returns:
--		An **integer**, the number of elements in ##sk##.
export function size(stack sk)
	return length(sk) - 1
end function

--**
-- Peek at a stack.
--
-- Parameters:
--		# ##sk##: the stack bieing queried
--		# ##idx##: an integer, the place to inspect.
--
-- Returns:
--		An **object**, the ##idx##-th item of the stack.
--
-- Errors:
-- If the supplied value of ##idx## does not correspond to an existing element, an error occurs.
--
-- Comments:
-- ##idx## may be negative, in which case it refers to an element counted backwards. Thus, 0 stands for the last element.
--
-- In a ##FIFO## type stack, the first object is the one popped last. In a ##FILO## stack, it is popped first. The distinction applies for all possibl values of ##idx##.
--
-- Example 1:
-- <eucode>
-- stack sk = new(FIFO)
-- sk = push(sk,5)
-- sk = push(sk,"abc")
-- object x = at(sk,0) -- x is 5
-- </eucode>
--
-- Example 2:
-- <eucode>
-- stack sk = new(FILO)
-- sk = push(sk,5)
-- sk = push(sk,"abc")
-- object x = at(sk,0) -- x is "abc"
-- </eucode>
--
-- See Also:
-- [[:size]], [[:top]]
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
-- Adds something to a stacj.
--
-- Parameters:
--		# ##sk##: the stacj to augment
--		# ##value##: an object, the value to push.
--
-- Returns:
-- A copy of the original **stack**, with one more element.
--
-- Comments:
-- ##value## appears at position 1 for ##FIFO## stacks and 0 for ##FILO## stacks.  The size of the returned stack is ##size(sk)+1##.
--
-- Example 1:
-- <eucode>
-- stack sk = new(FIFO)
-- sk = push(sk,5)
-- sk = push(sk,"abc")
-- sk = push(sk, {})
-- object x = at(sk,3) -- x is 5
-- </eucode>
--
-- See Also:
-- [[:pop]], [[:top]]
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
-- Retrieve element pushed first or last on a stack.
--
-- Parameters:
--		# ##sk##: the stack to inspect.
--
-- Returns
--		An **object**, the last element on a stack.
--
-- Comments:
-- This call is esquivalent to ##at(sk,0)##.
--
-- ##top(sk)## is the next element to be popped on a ##FILO## stack, and the last one on a ##FIFO## stack.
--
-- Example 1:
-- <eucode>
-- stack sk = new(FILO)
-- sk = push(sk,5)
-- sk = push(sk,"abc")
-- sk = push(sk, {})
-- object x = top(sk) -- x is {}
-- </eucode>
--
-- See Also:
-- [[:at]], [[:pop]]
export function top(stack sk)
	if length(sk) = 1 then
		crash("stack underflow in top()", {})
	end if

	return sk[$]
end function

--**
-- Removes an object from a stack.
--
-- Parameters:
--		# ##sk##: the stack to pop
--
-- Returns:
--	A copy of the original **stack**, with the last element removed.
--
-- Errors:
-- If the stack is empty, an underflow error occrurs.
--
-- Comments:
-- The object which is removed is at index 0, and was pushed last, in ##FILO## stacks and at position 1, pushed first, in ##FIFO## stacks.
--
-- The size of the returned stack is ##size(sk)-1## on a succesful ##pop##:
--
-- To pop a stack and retrieve he popped value, which this routine does not, you have to do this:
--
-- Example 1:
-- <eucode>
-- object x = top(sk)
-- sk = pop(sk)
-- </eucode>
-- See Also:
-- [[:push]], [[:top]], [[:is_empty]]
export function pop(stack sk)
	if length(sk) = 1 then
		crash("stack underflow in pop()", {})
	end if

	return sk[1..$-1]
end function

--**
-- Swap the last two elements of a stack
--
-- Parameters:
--		# ##sk##: the stack to swap.
--
-- Returns:
-- A copy of the original **stack**, with the last two elements swapped.
--
-- Errors:
-- If the stack has less than two elements, an error occurs.
--
-- Example 1:
-- <eucode>
-- stack sk = new(FILO)
-- sk = push(sk,5)
-- sk = push(sk,"abc")
-- sk = push(sk, {})
-- sk = swap(sk)
--	object x = top(sk)  -- x is "abc"
-- </eucode>
--
-- Comments:
-- Various algorithms use this primitive.
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
-- Repeat the last element of a stack.
--
-- Parameters:
--		# ##sk##: the stack to swap.
--
-- Returns:
-- A copy of the original **stack**, with the last element repeated.
--
-- Errors:
-- If the stack has less than two elements, an error occurs.
--
-- Comments:
-- Various algorithms use this primitive.
--
-- Example 1:
-- <eucode>
-- stack sk = new(FILO)
-- sk = push(sk,5)
-- sk = push(sk,"abc")
-- sk = push(sk, {})
-- sk = dup(sk)
--	object x = at(sk,3)  -- x is {}
-- x = top(sk) -- {} again
-- ?size(sk) -- 4
-- </eucode>
--
-- The size of the returned stack is 1 more than ##size(sk)##.
export function dup(stack sk)
	if length(sk) = 1 then
		crash("stack underflow in dup()", {})
	end if

	return sk & {sk[$]}
end function

--**
-- Wipe out a stack.
--
-- Parameters:
-- 		# ##sk##: the stack to clear.
--
-- Returns:
--		An empty **stack**, which has the type of ##sk##.
--
-- See Also:
-- [[:new]], [[is_empty]]
export function clear(stack sk)
	return {sk[1]}
end function
