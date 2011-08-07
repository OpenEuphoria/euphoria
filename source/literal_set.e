-- literal set
include std/error.e
include std/pretty.e

export type literal_set(object x)
	if length(x)=3 then
		return sequence(x[1]) and (compare(x[2],-1) xor compare(x[3],-1))
	else
		return 0
	end if
end type

enum type literal_accessor 
	NAME,
	ROUTINE,
	MAP,
	$
end type

export function new(sequence type_name, integer rid = -1, object mid = -1)
	if rid = -1 and equal(mid,-1) then
		crash( "New must contain either an routine id or a valid map")
	end if
	return {type_name, rid, mid}
end function

export function get_name_of(literal_set s, object value)
	integer k
	object name
	if s[MAP] = -1 then
		name = call_func(s[ROUTINE], {value})
	else
		k = find(value,s[MAP][1])
		if k > 0 then
			name = s[MAP][2][k]
		else
			name = 0
		end if
	end if
	if atom(name) then
		return pretty_sprint(value)
	end if
	return name
end function
