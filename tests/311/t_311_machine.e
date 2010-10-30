include std/unittest.e

include machine.e

constant
	PINF     = 1E308 * 1000,
	MINF     = - PINF

test_equal("int_to_bytes +ve", {231, 3, 0, 0}, int_to_bytes(999))
test_equal("int_to_bytes -ve", {-231, -4, -1, -1}, int_to_bytes(-999))
test_equal("int_to_bytes hex", {#CE, #FA, 0, 0}, int_to_bytes(#FACE))

test_equal("bytes_to_int +ve", 999, bytes_to_int({231, 3, 0, 0}))
test_equal("bytes_to_int -ve", 4294966297, bytes_to_int({-231, -4, -1, -1}))
test_equal("bytes_to_int #1", #FACE, bytes_to_int({#CE, #FA, 0, 0}))
test_equal("bytes_to_int #2", 293, bytes_to_int({37, 1, 0, 0}))
test_equal("bytes_to_int too large", 293, bytes_to_int({37, 1, 0, 0, 1}))

test_equal("int_to_bits #1", {1,0,0,0,1,1,0,1}, int_to_bits(177, 8))
test_equal("int_to_bits #2", {1,1,1,0,1},       int_to_bits(23, 5))
test_equal("int_to_bits #3", {},                int_to_bits(0xFFEEDDCC, 0))
test_equal("int_to_bits #4", {0,0,1,1,0,0,1,1,1,0,1,1,1,0,1,1,0,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1},  int_to_bits(0xFFEEDDCC, 32))
test_equal("int_to_bits #5", {0,0,1,1,0,0,1,1,1,0,1,1,1,0,1,1,0,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,0},int_to_bits(0xFFEEDDCC, 33))
test_equal("int_to_bits #6", repeat( 1, 33 ), int_to_bits( -1, 33 ) )

test_equal("bits_to_int #1",  23, bits_to_int({1,1,1,0,1}))
test_equal("bits_to_int #2", 177, bits_to_int({1,0,0,0,1,1,0,1}))

test_equal("atom_to_float64 #1", {10,215,163,112,61,186,99,64}, atom_to_float64(157.82))
test_equal("atom_to_float64 #2", {0,0,0,0,0,0,0,0}, atom_to_float64(0))
test_equal("atom_to_float64 #3", {0,0,0,0,0,0,240,127}, atom_to_float64(PINF))
test_equal("atom_to_float64 #4", {0,0,0,0,0,0,240,255}, atom_to_float64(MINF))

test_equal("atom_to_float32 #1", {236,209,29,67}, atom_to_float32(157.82))
test_equal("atom_to_float32 #2", {0, 0, 0, 0}, atom_to_float32(0))
test_equal("atom_to_float32 #3", {0,0,128,127}, atom_to_float32(PINF))
test_equal("atom_to_float32 #4", {0,0,128,255}, atom_to_float32(MINF))

test_equal("float64_to_atom #1", 157.82, float64_to_atom( {10,215,163,112,61,186,99,64}))
test_equal("float64_to_atom #2", 0, float64_to_atom({0,0,0,0,0,0,0,0}))
test_equal("float64_to_atom #3", PINF, float64_to_atom({0,0,0,0,0,0,240,127}))
test_equal("float64_to_atom #4", MINF, float64_to_atom({0,0,0,0,0,0,240,255}))

test_equal("float32_to_atom #2", 0, float32_to_atom({0,0,0,0}))
test_equal("float32_to_atom #3", PINF, float32_to_atom({0,0,128,127}))
test_equal("float32_to_atom #4", MINF, float32_to_atom({0,0,128,255}))

atom ptr = allocate_string( "hello" )
test_equal( "allocate string", "hello", peek( ptr & 5 ) )
free( ptr )

ptr = allocate_low( 4 )
test_not_equal( "allocate low", 0, ptr )
free_low( ptr )

crash_file( "machine.err" )
crash_message( "machine.e crashed...use the new stdlib" )
function my_crash( object o )
	return 0
end function
crash_routine( routine_id("my_crash" ) )

set_rand( 5 )
integer first_rand = rand( 1000 )
set_rand( 5 )
test_equal( "set_rand", first_rand, rand ( 1000 ) )

check_all_blocks()
register_block(1,1)
unregister_block(1)
test_report()
