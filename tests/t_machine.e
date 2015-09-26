include std/machine.e
include std/unittest.e

atom ptr = allocate( 256 )

test_equal( "poke_string with null pointer", 0,       poke_string( 0, 10, "foo" ) )
test_equal( "poke_string with bad data",     0,       poke_string( ptr, 256, {"foo","bar"} ) )
test_equal( "poke_string with small buffer", 0,       poke_string( ptr, 3, "foo" ) )
test_equal( "poke_string",                   ptr + 3, poke_string( ptr, 256, "foo" ) )

test_equal( "poke_wstring with null pointer", 0,       poke_wstring( 0, 10, "foo" ) )
test_equal( "poke_wstring with small buffer", 0,       poke_wstring( ptr, 3, "foo" ) )
test_equal( "poke_wstring",                   ptr + 6, poke_wstring( ptr, 256, "foo" ) )
test_equal( "peek_wstring",                   "foo",   peek_wstring( ptr ) )
free( ptr )

test_true( "allocate_wstring", allocate_wstring( "foo", 1 ) )

test_true( "allocate_data with cleanup", allocate_data( 5, 1 ) )

ptr = allocate_data( 5 )
test_true( "allocate_data", allocate_data( 5 ) )
free( ptr )

DEP_on( 1 )
test_equal( "is_using_DEP", 1, is_using_DEP() )

test_true( "is_DEP_supported", integer( is_DEP_supported() ) )

ptr = allocate_protect( {1,2,3}, 2, PAGE_EXECUTE )
test_true( "allocate_protect wordsize 2", ptr )
free_code( ptr, 6 )

ptr = allocate_protect( {1,2,3}, 4, PAGE_EXECUTE )
test_true( "allocate_protect wordsize 4", ptr )
free_code( ptr, 12 )

ptr = allocate( 32 )
atom big = 0x4000_0000
poke4( ptr, big )
test_equal( "poke4 / peek4s atom", big, peek4s( ptr ) )
test_equal( "poke4 / peek4u atom", big, peek4u( ptr ) )

big *= -1
poke4( ptr, big )
test_equal( "poke4 / peek4s negative atom", big, peek4s( ptr ) )

poke( ptr, {77, -1, 5.1, -1.1})
test_equal( "poke/peek negagive, doubles",{77, 255, 5, 255}, peek( ptr & 4 ) )

poke2( ptr, {77, -1, 5.1, -1.1})
test_equal( "poke2/peek2u negagive, doubles",{77, 0xffff, 5, 0xffff}, peek2u( ptr & 4 ) )

poke4( ptr, {77, -1, 5.1, -1.1})
test_equal( "poke4/peek4u negagive, doubles",{77, 0xffff_ffff, 5, 0xffff_ffff}, peek4u( ptr & 4 ) )

poke8( ptr, {77, -1, 5.1, -1.1})
test_equal( "poke8/peek8u negagive, doubles",{77, 0xffff_ffff_ffff_ffff, 5, 0xffff_ffff_ffff_ffff}, peek8u( ptr & 4 ) )

poke8( ptr, {0xffff_ffff, 0xffff_ffff_ffff_f800, 0x7fff_ffff_ffff_fe00, 0x3fff_ffff_ffff_ff00})
test_equal( "poke8/peek8u long long doubles",{0xffff_ffff, 0xffff_ffff_ffff_f800, 0x7fff_ffff_ffff_fe00, 0x3fff_ffff_ffff_ff00}, peek8u( ptr & 4 ) )

test_report()
