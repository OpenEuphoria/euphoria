include std/unittest.e

test_pass("name_of parses correctly")

type enum season
	spring, summer, fall, winter
end type

season birth = summer
test_equal("#1 name_of(summer): Using a basic type enum", "summer", name_of(summer))

type enum languages by 2
	en, es, kr, jp
end type

test_equal("#2 name_of(kr,jp): Using a by 2 type enum", "kr,jp", name_of(or_bits(kr,jp)))

test_report()
