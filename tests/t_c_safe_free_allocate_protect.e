with define SAFE

include std/machine.e
include std/unittest.e

atom addr = allocate_protect( 4, , PAGE_READ )
free( addr )

test_report()
