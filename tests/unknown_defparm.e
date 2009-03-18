constant something = 3

public function unk_foo(object x = something)
	return x
end function

include unknown_defparm2.e as unk

public function unk_foo1(object x = unk:something)
	return x
end function

