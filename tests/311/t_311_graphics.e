 include std/unittest.e

include graphics.e

text_color( 15 )
bk_color( 0 )
text_color( 7 )

cursor( NO_CURSOR )
cursor( UNDERLINE_CURSOR )

graphics_mode( 0 )
wrap( 1 )
wrap( 0 )

sequence pos = get_position()
test_equal( "get_position", 2, length( pos ) )

integer rows = text_rows( 25 )
text_rows( rows )

scroll( 1, 3, 6 )

test_report()
