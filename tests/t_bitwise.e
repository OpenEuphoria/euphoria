include std/unittest.e

test_equal( "and_bits 1", 1, and_bits( 1, 3 ) )

integer i1 = 1, i2 = 3
test_equal( "and_bits 1", 1, and_bits( i1, i2 ) )

global function make_word( integer lo, integer hi) 
   lo  = and_bits( lo,  #FF ) 
   hi = and_bits( hi, #FF )     
   return hi*#100 + lo 
end function 

test_equal( "and bits in func 1", 0x101, make_word( 1, 1 ) )

i1 = and_bits( i1, 0xff )
test_equal( "and bits assign operand", 1, i1 )

i1 = 1
i1 = or_bits( i1, 0xff )
test_equal( "or bits assign operand", 0xff, i1 )

i1 = 0xff
i1 = xor_bits( i1, 0xff )
test_equal( "xor bits assign operand", 0, i1 )

function inline_binop( integer a, integer b )
	return remainder( a, b ) + 1
end function
test_equal( "inlined return and_bits", 1, inline_binop( i1, i2 ) )

i1 = 0x00103070
i1 = not_bits( i1 )
test_equal( "not bits assign operand", 0xFFEFCF8F, i1 )

i1 = not_bits( 0xFFEFCF8F )
test_equal( "not bits assign operand", 0x00103070, i1 )

test_report()
