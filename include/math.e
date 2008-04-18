-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
-- Euphoria 3.2
-- Math routines

-- trig formulas provided by Larry Gregg

global constant PI = 3.141592653589793238

constant
    PI_HALF =  PI / 2.0,  -- PI / 2
    PINF = 1E308 * 1000,  -- Plus infinity (used in several routines)
    MINF = - PINF         -- Minus infinity (used in several routines)

type trig_range(object x)
--  values passed to arccos and arcsin must be [-1,+1]
    if atom(x) then
	return x >= -1 and x <= 1
    else
	for i = 1 to length(x) do
	    if not trig_range(x[i]) then
		return 0
	    end if
	end for
	return 1
    end if
end type

global function arccos(trig_range x)
--  returns angle in radians
    return PI_HALF - 2 * arctan(x / (1.0 + sqrt(1.0 - x * x)))
end function

global function arcsin(trig_range x)
--  returns angle in radians
    return 2 * arctan(x / (1.0 + sqrt(1.0 - x * x)))
end function

global function ceil(object a)
    return -floor(-a)
end function

global function round_prec(object a, object cent)
    integer len
    sequence s
    object t, u
    if atom(a) then
        if atom(cent) then
            return floor(a * cent + 0.5) / cent
        end if
        len = length(cent)
        s = repeat(0, len)
        for i = 1 to len do
            t = cent[i]
            if atom (t) then
                s[i] = floor(a * t + 0.5) / t
            else
                s[i] = round_prec(a, t)
            end if
        end for
        return s
    elsif atom(cent) then
        len = length(a)
        s = repeat(0, len)
        for i = 1 to len do
            t = a[i]
            if atom(t) then
                s[i] = floor(t * cent + 0.5) / cent
            else
                s[i] = round_prec(t, cent)
            end if
        end for
        return s
    end if
    len = length(a)
    if len != length(cent) then
	    abort(1)
    end if
    s = repeat(0, len)
    for i = 1 to len do
        t = cent[i]
        if atom(t) then
            u = a[i]
            if atom(u) then
                s[i] = floor(u * t + 0.5) / t
            else
                s[i] = round_prec(u, t)
            end if
        else
            s[i] = round_prec(a[i], t)
        end if
    end for
    return s
end function

global function round(object a)
    object t
    if integer(a) then
    	return a
    elsif atom(a) then
	    return floor(a + 0.5)
    end if
    for i = 1 to length(a) do
    	t = a[i]
	    if integer(t) then
    	elsif atom(t) then
	        a[i] = floor(t + 0.5)
    	else
	        a[i] = round(t)
    	end if
    end for
    return a
end function

global function sign(object a)
    object t
    if atom(a) then
    	if a > 0 then
	        return 1
    	elsif a < 0 then
	        return - 1
    	else
	        return 0
    	end if
    end if
    for i = 1 to length(a) do
	    t = a[i]
    	if atom(t) then
	        if t > 0 then
	    	    a[i] = 1
    	    elsif t < 0 then
		        a[i] = - 1
    	    end if
	    else
	        a[i] = sign(t)
    	end if
    end for
    return a
end function

global function abs(object a)
    object t
    if atom(a) then
    	if a >= 0 then
	        return a
    	else
	        return - a
	    end if
    end if
    for i = 1 to length(a) do
    	t = a[i]
	    if atom(t) then
    	    if t < 0 then
		        a[i] = - t
	        end if
    	else
	        a[i] = abs(t)
    	end if
    end for
    return a
end function

global function sum(object a)
    atom b
    if atom(a) then
	    return a
    end if
    b = 0
    for i = length(a) to 1 by -1 do
	    b += sum(a[i])
    end for
    return b
end function

global function average(object a)
    atom b
    integer len
    if atom(a) then
        return a
    end if

    len = length(a)
    b = 0

    for i = 1 to len do
        b += a[i]
    end for

    return b / len
end function

global function max(object a)
    atom b, c
    if atom(a) then
	    return a
    end if
    b = MINF
    for i = 1 to length(a) do
	    c = max(a[i])
    	if c > b then
	        b = c
    	end if
    end for
    return b
end function

global function min(object a)
    atom b, c
    if atom(a) then
	    return a
    end if
    b = PINF
    for i = 1 to length(a) do
    	c = min(a[i])
	    if c < b then
	        b = c
    	end if
    end for
    return b
end function
