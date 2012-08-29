include std/convert.e
include std/unittest.e
include std/math.e
include std/dll.e
include std/machine.e

test_equal("int_to_bytes +ve", {231, 3, 0, 0}, int_to_bytes(999))
test_equal("int_to_bytes -ve",  {25,252,255,255}, int_to_bytes(-999))
test_equal("int_to_bytes hex", {#CE, #FA, 0, 0}, int_to_bytes(#FACE))

test_equal("bytes_to_int +ve", 999, bytes_to_int({231, 3, 0, 0}))
test_equal("bytes_to_int -ve", 4294966297, bytes_to_int({-231, -4, -1, -1}))
test_equal("bytes_to_int #1", #FACE, bytes_to_int({#CE, #FA}))
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

test_equal("float32_to_atom #1", 157.82, round(float32_to_atom({236,209,29,67}), 100))
test_equal("float32_to_atom #2", 0, float32_to_atom({0,0,0,0}))
test_equal("float32_to_atom #3", PINF, float32_to_atom({0,0,128,127}))
test_equal("float32_to_atom #4", MINF, float32_to_atom({0,0,128,255}))

test_equal("float80_to_atom #1", 157.82, float80_to_atom( {236,81,184,30,133,235,209,157,6,64}) )
test_equal("float80_to_atom #2", PINF, float80_to_atom( {0,0,0,0,0,0,0,128,255,127}) )
test_equal("float80_to_atom #3", MINF, float80_to_atom({0,0,0,0,0,0,0,128,255,255}) )

ifdef BITS64 then
	-- these tests only really make sense for 64-bits:
	test_equal("atom_to_float80 #1", {236,81,184,30,133,235,209,157,6,64}, atom_to_float80( 157.82 ) )
	test_equal("atom_to_float80 #2", {0,0,0,0,0,0,0,128,255,127}, atom_to_float80( PINF ) )
	test_equal("atom_to_float80 #3", {0,0,0,0,0,0,0,128,255,255}, atom_to_float80( MINF ) )
end ifdef

test_equal("hex_text #1", -13562.003444492816925, hex_text("-#3_4FA.00E_1BD"))
test_equal("hex_text #2", 3735928559, hex_text("DEADBEEF"))
test_equal("hex_text #3", 13, hex_text("D#EADBEEF"))
test_equal("hex_text #4", -13562, hex_text("-#3_4FA.0.0E_1BD"))
test_equal("hex_text #5", -3, hex_text("-#3_-4FA.0.0E_1BD"))
test_equal("hex_text #5", -3, hex_text("-#3y56"))

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
test_equal( "to_number #11", {-12.34, 0}, to_number("-12.34", 1))
test_equal( "to_number #12", {-12, 4}, to_number("-12-.34", 1))
test_equal( "to_number #13", {12, 4}, to_number("+12+534", 1))
test_equal( "to_number #14", {#12, 4}, to_number("#12#534", 1))
test_equal( "to_number #14", {10, 4}, to_number("@12@534", 1))
test_equal( "to_number #15", {12, 3}, to_number("12!534", 1))
test_equal( "to_number #16", {12, 0}, to_number("$12", 1))
test_equal( "to_number #17", {12, 4}, to_number("$12$3", 1))
test_equal( "to_number #18", {0,1}, to_number("_12$3", 1))
test_equal( "to_number #19", {12.1, 6}, to_number("12.1$.1", 1))
test_equal( "to_number #20", {0.12, 4}, to_number("12%1", 1))
test_equal( "to_number #21", {0.12, 0}, to_number("%12", 1))
test_equal( "to_number #22", {0.12, 4}, to_number("%12%", 1))
test_equal( "to_number #23", {12, 0}, to_number(" 12", 1))
test_equal( "to_number #24", {12, 0}, to_number("\t12", 1))
test_equal( "to_number #25", {12, 5}, to_number(" 12\t1", 1))
test_equal( "to_number #25", {12, 4}, to_number(" 12=", 1))
test_equal( "to_number #26", {12.1, 5}, to_number("12.1.1", 1))
test_equal( "to_number #27", {0.121, 0}, to_number("12.1%", 1))

test_equal( "to_integer #1", 12,  to_integer(12))
test_equal( "to_integer #2", 12,  to_integer(12.4))
test_equal( "to_integer #3", 12,  to_integer("12"))
test_equal( "to_integer #4", 12,  to_integer("12.9"))
test_equal( "to_integer #5", 0,  to_integer("a12"))
test_equal( "to_integer #6", -1,  to_integer("a12",-1))
test_equal( "to_integer #7", 0,  to_integer({"12"}))
test_equal( "to_integer #8", 1073741823,  to_integer(#3FFFFFFF))
if sizeof( C_POINTER ) = 4 then
	test_equal( "to_integer #9", 0,  to_integer(#3FFFFFFF + 1))
else
	-- The relative size of 63-bit euphoria integers and the mantissa of
	-- doubles requires we add 513 to roll over to a double
	atom big_integer = #3FFFFFFF_FFFFFFFF
	atom ptr = allocate( 8, 1 )
	poke( ptr, repeat( 0xff, 7 ) & 0x3f )
	big_integer += 1
	test_equal( "to_integer #9", 0,  to_integer(big_integer ))
	test_equal( "to_integer #10", peek8s( ptr ),  to_integer(#3FFFFFFF_FFFFFFFF ))
end if

test_equal( "to_string #1", `12` , to_string(12))
test_equal( "to_string #2", `abc` , to_string("abc"))
test_equal( "to_string #3", `"abc"` , to_string("abc",'"'))
test_equal( "to_string #4", `"abc\\\""` , to_string(`abc\"`,'"'))
test_equal( "to_string #5", `{12, "abc", {4.5, -99}}` , to_string({12,"abc",{4.5, -99}}))
test_equal( "to_string #6", `{12, abc, {4.5, -99}}` , to_string({12,"abc",{4.5, -99}},,0))
test_equal( "to_string #7", `12.34567` , to_string(12.34567))
test_equal( "to_string #8", `1234567891234` , to_string(1_234_567_891_234))

test_report()

