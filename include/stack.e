-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
-- Euphoria 3.2
-- Stack routines

include machine.e

global constant
    FIFO = 1,
    FILO = 2

global type stack(object o)
    return sequence(o) and length(o) >= 1
end type

global function new(integer stack_type)
    return {stack_type}
end function

global function is_empty(stack sk)
    return length(sk) = 1
end function

global function push(stack sk, object value)
    if sk[1] = FIFO then
        if length(sk) = 1 then
            return sk & value
        end if

        return FIFO & value & sk[2..$]
    else
        return sk[1..$] & value
    end if
end function

global function top(stack sk)
    if length(sk) = 1 then
        crash("stack underflow in top()", {})
    end if

    return sk[$]
end function

global function pop(stack sk)
    if length(sk) = 1 then
        crash("stack underflow in pop()", {})
    end if

    return sk[1..$-1]
end function

global function clear(stack sk)
    return {sk[1]}
end function
