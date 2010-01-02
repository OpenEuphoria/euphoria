include std/convert.e
include std/unittest.e
include std/math.e

test_equal("int_to_bytes +ve", {231, 3, 0, 0}, int_to_bytes(999))
test_equal("int_to_bytes -ve", {-231, -4, -1, -1}, int_to_bytes(-999))
test_equal("int_to_bytes hex", {#CE, #FA, 0, 0}, int_to_bytes(#FACE))

test_equal("bytes_to_int +ve", 999, bytes_to_int({231, 3, 0, 0}))
test_equal("bytes_to_int -ve", 4294966297, bytes_to_int({-231, -4, -1, -1}))
test_equal("bytes_to_int #1", #FACE, bytes_to_int({#CE, #FA}))
test_equal("bytes_to_int #2", 293, bytes_to_int({37, 1, 0, 0}))


test_equal("int_to_bits #1", {1,0,0,0,1,1,0,1}, int_to_bits(177, 8))
test_equal("int_to_bits #2", {1,1,1,0,1},       int_to_bits(23, 5))

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

test_equal("float32_to_atom #1", 157.82, round(float32_to_atom({236,209,29,67}), 100))
test_equal("float32_to_atom #2", 0, float32_to_atom({0,0,0,0}))
test_equal("float32_to_atom #3", PINF, float32_to_atom({0,0,128,127}))
test_equal("float32_to_atom #4", MINF, float32_to_atom({0,0,128,255}))


test_equal("hex_text #1", -13562.003444492816925, hex_text("-#3_4FA.00E_1BD"))
test_equal("hex_text #2", 3735928559, hex_text("DEADBEEF"))


test_equal("set_decimal_mark #1", '.', set_decimal_mark(0))
test_equal("set_decimal_mark #2", '.', set_decimal_mark(','))
test_equal("set_decimal_mark #3", ',', set_decimal_mark(0))
test_equal("set_decimal_mark #4", ',', set_decimal_mark('.'))
test_equal("set_decimal_mark #5", '.', set_decimal_mark(0))

test_equal( "to_number #1", {12.34, 0}, to_number("12.34", 1))
test_equal( "to_number #2", {12.34, 6}, to_number("12.34a", 1))
test_equal( "to_number #1a", 12.34, to_number("12.34", -1))
test_equal( "to_number #2a", {6}, to_number("12.34a", -1))
test_equal( "to_number #3", 0, to_number("12.34a"))
test_equal( "to_number #4", 63500, to_number("#f80c"))
test_equal( "to_number #5", 63500.47900390625, to_number("#f80c.7aa"))
test_equal( "to_number #6", 963, to_number("@1703"))
test_equal( "to_number #7", 45, to_number("!101101"))
test_equal( "to_number #8", 12583891, to_number("12_583_891"))
test_equal( "to_number #9", 125838.91, to_number("12_583_891%"))
test_equal( "to_number #10", 12583.891, to_number("12,583,891%%"))


test_equal( "to_integer #1", 12,  to_integer(12))
test_equal( "to_integer #2", 12,  to_integer(12.4))
test_equal( "to_integer #3", 12,  to_integer("12"))
test_equal( "to_integer #4", 12,  to_integer("12.9"))
test_equal( "to_integer #5", 0,  to_integer("a12"))
test_equal( "to_integer #6", -1,  to_integer("a12",-1))
test_equal( "to_integer #7", 0,  to_integer({"12"}))
test_equal( "to_integer #8", 1073741823,  to_integer(#3FFFFFFF))
test_equal( "to_integer #9", 0,  to_integer(#3FFFFFFF + 1))


test_report()

