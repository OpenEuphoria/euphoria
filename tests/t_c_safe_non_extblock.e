with define SAFE

include std/unittest.e
include std/machine.e

atom read_write_memory
read_write_memory = allocate(100)
register_block(read_write_memory, 100, PAGE_READ_WRITE)

test_pass("Should not be able to register a non-external block of memory.")

