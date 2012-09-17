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
printf(1, "(4*12/3) = %s\n", {name_of(4 * 12 / 3)})
printf(1, "(%d) = %s\n", {x, name_of(x)})
printf(1, "vtrue = %s\n", {name_of(vtrue)})
printf(1, "etrue = %s\n", {name_of(etrue)})
*/
test_equal("name_of an expression result will be like sprint", "16", name_of(4 * 12 / 3))
test_equal("name_of an object is like sprint", "0", name_of(x))
test_equal("name_of an object of a udt that isn't an enumerated type is like sprint", "1", name_of(vtrue))
test_equal("name_of a udt enumerated type displays its name", "efalse", name_of(y))
test_equal("name_of a floating point value", "4.321", name_of(4.321))
test_equal("name_of 1/3", "0." & repeat('3', 10), name_of(1/3))
test_equal("name_of a complicated sequence", "{4, 5, {3.12}}", name_of({4, 5, {3.12}}))
--
test_report()
