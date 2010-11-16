
include std/unittest.e

include safe.e

atom addr = allocate( 4 )
eu:poke( addr - 1, 0 )
free( addr )

test_report()
