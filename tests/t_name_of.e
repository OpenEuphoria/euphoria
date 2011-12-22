include std/unittest.e

type vboolean(integer x)
	return or_bits(x,1) = 1
end type
type enum eboolean
	efalse = 0, etrue
end type

constant vtrue = etrue
object x = 0
eboolean y = 0
/*
puts(1, name_of(4 * 12 / 3))
puts(1, name_of(x))
puts(1, name_of(vtrue))
puts(1, name_of(etrue))*/
test_equal("name_of an expression result will be like sprint", "16", name_of(4 * 12 / 3))
test_equal("name_of an object is like sprint", "0", name_of(x))
test_equal("name_of an object of a udt that isn't an enumerated type is like sprint", "1", name_of(vtrue))
test_equal("name_of an a udt enumerated type displays its name", "efalse", name_of(y))
test_report()
