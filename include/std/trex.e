--****
-- == Regular Expressions based on T-Rex
--
-- <<LEVELTOC depth=2>>
--
-- === Expression Syntax
-- * ##\##	Quote the next metacharacter
-- * ##^##	Match the beginning of the string
-- * ##.##	Match any character
-- * ##$##	Match the end of the string
-- * ##|##	Alternation
-- * ##()##	Grouping (creates a capture)
-- * ##[]##	Character class
--
-- ==== Greedy Closures
-- * ##*##	   Match 0 or more times
-- * ##+##	   Match 1 or more times
-- * ##?##	   Match 1 or 0 times
-- * ##{n}##    Match exactly n times
-- * ##{n,}##   Match at least n times
-- * ##{n,m}##  Match at least n but not more than m times
--
-- ==== Escape Characters
-- * ##\t##		tab                   (HT, TAB)
-- * ##\n##		newline               (LF, NL)
-- * ##\r##		return                (CR)
-- * ##\f##		form feed             (FF)
--
-- ==== Predefined Classes
-- * ##\l##		lowercase next char
-- * ##\u##		uppercase next char
-- * ##\a##		letters
-- * ##\A##		non letters
-- * ##\w##		alphanimeric [0-9a-zA-Z]
-- * ##\W##		non alphanimeric
-- * ##\s##		space
-- * ##\S##		non space
-- * ##\d##		digits
-- * ##\D##		non nondigits
-- * ##\x##		exadecimal digits
-- * ##\X##		non exadecimal digits
-- * ##\c##		control charactrs
-- * ##\C##		non control charactrs
-- * ##\p##		punctation
-- * ##\P##		non punctation
-- * ##\b##		word boundary
-- * ##\B##		non word boundary
--

enum M_TREX_COMPILE=76, M_TREX_EXEC, M_TREX_FREE

public function new(sequence pattern)
	return machine_func(M_TREX_COMPILE, { pattern, 0 })
end function

public procedure free(atom re)
	machine_proc(M_TREX_FREE, { re })
end procedure

public function find(atom re, sequence haystack, integer from=1)
	return machine_func(M_TREX_EXEC, { re, haystack, from })
end function

public function has_match(atom re, sequence haystack, integer from=1)
	return sequence(machine_func(M_TREX_EXEC, { re, haystack, from }))
end function

public function is_match(atom re, sequence haystack, integer from=1)
	object m = machine_func(M_TREX_EXEC, { re, haystack, from })

	if sequence(m) and length(m) > 0 and m[1][1] = 1 and m[1][2] = length(haystack) then
		return 1
	end if

	return 0
end function
