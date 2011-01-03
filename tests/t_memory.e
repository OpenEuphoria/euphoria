include std/machine.e
include std/unittest.e

atom p, psave
p = allocate_string("Hello World")
test_not_equal("allocate_string not 0", 0, p)
test_equal("allocate_string contents", "Hello World", peek_string(p))
free(p)


sequence sp
sp = {allocate_string("Hello"), allocate_string("World")}
p = allocate_pointer_array( sp )
test_not_equal("allocate_pointer_array not 0", 0, p)
test_equal("allocate_pointer_array element 1", sp[1], peek4u(p))
test_equal("allocate_pointer_array element 2", sp[2], peek4u(p + ADDRESS_LENGTH))
test_equal("allocate_pointer_array element 3", 0, peek4u(p + (2 * ADDRESS_LENGTH)))
free_pointer_array(p)

p = allocate_string_pointer_array({"one", "two"})
test_not_equal("allocate_string_pointer_array not 0", 0, p)
test_equal("allocate_string_pointer_array element 1", "one", peek_string(peek4u(p)))
test_equal("allocate_string_pointer_array element 2", "two", peek_string(peek4u(p + 4)))
free_pointer_array(p)

test_equal("page & address length check", 0, remainder(PAGE_SIZE, ADDRESS_LENGTH))

p = allocate( 24 )
poke8( p, power( 2, 40 ) )
test_equal( "poke8/peek8u 2^40", power( 2, 40 ), peek8u( p ) )
test_equal( "poke8/peek8s 2^40", power( 2, 40 ), peek8s( p ) )

poke8( p, -1 )
test_equal( "poke8/peek8u -1", 0xffffffff + power(2,32)* 0xffffffff, peek8u( p ) )
test_equal( "poke8/peek8s -1", -1, peek8s( p ) )

poke8( p, {1, 2, 3})
test_equal( "poke8/peek8u 1,2,3", {1,2,3}, peek8u( p & 3 ) )
test_equal( "poke8/peek8s 1,2,3", {1,2,3}, peek8s( p & 3 ) )

poke8( p, {-1, -2, -3})
test_equal( "poke8/peek8s 1,2,3", {-1,-2,-3}, peek8s( p & 3 ) )

poke_pointer( p, 0x1234 )
test_equal( "poke/peek_pointer 0x1234", 0x1234, peek_pointer( p ) )

poke_pointer( p, 0x1234 & 0x5678 )
test_equal( "poke/peek_pointer 0x1234 & 0x5678", 0x1234 & 0x5678, peek_pointer( p & 2 ) )
test_report()
