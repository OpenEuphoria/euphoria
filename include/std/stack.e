-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
--****
-- == Stack
--
-- **Page Contents**
--
-- <<LEVELTOC depth=2>>

include std/error.e
include std/eumem.e

--****
-- === Constants
--

--**
-- Stack types
-- * FIFO: like people standing in line: first item in is first item out
-- * FILO: like for a stack of plates  : first item in is last item out


public constant
	FIFO = 1,
	FILO = 2

--****
-- === Types
--

enum type_tag, stack_type, data
constant type_is_stack = "Eu:StdStack"

--**
-- A stack is a sequence of objects with some internal data.

public type stack(object obj_p)
	if not valid(obj_p, "") then return 0 end if

	object o = ram_space[obj_p]
	if not sequence(o) then return 0 end if
	if not length(o) = data then return 0 end if
	if not equal(o[type_tag], type_is_stack) then return 0 end if
	if not find(o[stack_type], { FIFO, FILO }) then return 0 end if
	if not sequence(o[data]) then return 0 end if

	return 1
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
--		An empty **stack**.  Note that the variable storing the stack must
--      not be an integer.  The resources allocated for the stack will
--      be automatically cleaned up if the reference count of the returned value drops
--      to zero, or if passed in a call to [[:delete]].
--
-- Comments:
-- There are two sorts of stacks, designated by the types ##FIFO## and ##FILO##:
-- * A ##FIFO## stack is one where the first item to be pushed is popped first. People standing in line form a ##FIFO## stack.
-- * a ##FILO## stack is one where the item pushed last is popped first. A stack of coins is of the ##FILO## kind.
--
-- See Also:
-- [[:is_empty]]

public function new(integer typ)
	atom new_stack = malloc()

	ram_space[new_stack] = { type_is_stack, typ, {} }

	return new_stack
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

public function is_empty(stack sk)
	return length(ram_space[sk][data]) = 0
end function

--**
-- Returns how many elements a stack has.
--
-- Parameters:
--		# ##sk##: the stack being queried.
--
-- Returns:
--		An **integer**, the number of elements in ##sk##.

public function size(stack sk)
	return length(ram_space[sk][3])
end function

--**
-- Peek at a stack.
--
-- Parameters:
--		# ##sk##: the stack being queried
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
-- In a ##FIFO## type stack, the first object is the one popped last. In a ##FILO## stack, it is popped first. The distinction applies for all possible values of ##idx##.
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

public function at(stack sk, integer idx)
	sequence o = ram_space[sk]

	if idx <= 0 then
		-- number from top
		idx = length(o[data]) + idx
		if idx < 1 then
			crash("stack underflow in at()", {})
		end if
	else
		if idx > length(o[data]) then
			crash("stack overflow in at()", {})
		end if
	end if
	
	return o[data][idx]
end function

--**
-- Adds something to a stack.
--
-- Parameters:
--		# ##sk##: the stack to augment
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
-- push(sk,5)
-- push(sk,"abc")
-- push(sk, {})
-- object x = at(sk,3) -- x is 5
-- </eucode>
--
-- See Also:
-- [[:pop]], [[:top]]

public procedure push(stack sk, object value)
	-- Type checking ensures type is either FIFO or FILO
	switch ram_space[sk][stack_type] do
		case FIFO:
			ram_space[sk][data] = prepend(ram_space[sk][data], value)
			break

		case FILO:
			ram_space[sk][data] = append(ram_space[sk][data], value)
			break
	end switch
end procedure

--**
-- Retrieve element pushed first or last on a stack.
--
-- Parameters:
--		# ##sk##: the stack to inspect.
--
-- Returns:
--		An **object**, the last element on a stack.
--
-- Comments:
-- This call is equivalent to ##at(sk,0)##.
--
-- ##top(sk)## is the next element to be popped on a ##FILO## stack, and the last one on a ##FIFO## stack.
--
-- Example 1:
-- <eucode>
-- stack sk = new(FILO)
-- push(sk,5)
-- push(sk,"abc")
-- push(sk, {})
-- object x = top(sk) -- x is {}
-- </eucode>
--
-- See Also:
-- [[:at]], [[:pop]]

public function top(stack sk)
	if length(ram_space[sk][data]) = 0 then
		crash("stack underflow in top()", {})
	end if

	return ram_space[sk][data][$]
end function

--**
-- Removes an object from a stack.
--
-- Parameters:
--		# ##sk##: the stack to pop
--
-- Returns:
--   The top stack item
--
-- Side effects:
--   The top stack item is removed from the stack
--
-- Errors:
--   If the stack is empty, an underflow error occurs.
--
-- Comments:
--   The object which is removed is at index 0, and was pushed last, in
--   ##FILO## stacks and at position 1, pushed first, in ##FIFO## stacks.
--
-- Example 1:
-- <eucode>
-- stack sk = new(FIFO)
-- push(sk, 1)
-- push(sk, 2)
-- ? size(sk) -- 2
-- ? pop(sk) -- 1
-- ? size(sk) -- 1
-- </eucode>
--
-- See Also:
-- [[:push]], [[:top]], [[:is_empty]]

public function pop(stack sk)
	if length(ram_space[sk][data]) = 0 then
		crash("stack underflow in pop()", {})
	end if

	object top_obj = ram_space[sk][data][$]
	ram_space[sk][data] = ram_space[sk][data][1..$-1]
	return top_obj
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
-- push(sk,5)
-- push(sk,"abc")
-- push(sk, {})
-- swap(sk)
-- ? top(sk)  -- "abc"
-- </eucode>
--

public procedure swap(stack sk)
	if length(ram_space[sk][data]) < 2 then
		crash("stack underflow in swap()", {})
	end if

	object tmp = ram_space[sk][data][$]
	ram_space[sk][data][$] = ram_space[sk][data][$-1]
	ram_space[sk][data][$-1] = tmp
end procedure

--**
-- Repeat the last element of a stack.
--
-- Parameters:
--		# ##sk##: the stack to swap.
--
-- Side effects:
--   The stack copies the value of top() onto the end of itself, thus
--   the stack size grows by one.
--
-- Errors:
--   If the stack has no elements, an error occurs.
--
-- Example 1:
-- <eucode>
-- stack sk = new(FILO)
-- push(sk,5)
-- push(sk,"abc")
-- push(sk, {})
-- dup(sk)
-- ? at(sk,3)  -- x is {}
-- ? top(sk)   -- {} again
-- ? size(sk)  -- 4
-- </eucode>
--

public procedure dup(stack sk)
	if length(ram_space[sk][data]) = 0 then
		crash("stack underflow in dup()", {})
	end if

	ram_space[sk][data] = ram_space[sk][data] & { ram_space[sk][data][$] }
end procedure

--**
-- Wipe out a stack.
--
-- Parameters:
-- 		# ##sk##: the stack to clear.
--
-- Side effect:
--   The stack contents is emptied.
--
-- See Also:
-- [[:new]], [[is_empty]]

public procedure clear(stack sk)
	ram_space[sk][data] = {}
end procedure
