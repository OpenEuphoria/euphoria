include std/memory.e
include std/unittest.e

atom p, psave
p = allocate_string("Hello World")
test_not_equal("allocate_string not 0", 0, p)
test_equal("allocate_string contents", "Hello World", peek_string(p))
free(p)


p = allocate_pointer_array({ 1, 2 })
test_not_equal("allocate_pointer_array not 0", 0, p)
test_equal("allocate_pointer_array element 1", 1, peek4u(p))
test_equal("allocate_pointer_array element 2", 2, peek4u(p + 4))
test_equal("allocate_pointer_array element 3", 0, peek4u(p + 8))
free(p) -- not calling free_pointer_array because actual contents
        -- of this array are not real pointers

p = allocate_string_pointer_array({"one", "two"})
test_not_equal("allocate_string_pointer_array not 0", 0, p)
test_equal("allocate_string_pointer_array element 1", "one", peek_string(peek4u(p)))
test_equal("allocate_string_pointer_array element 2", "two", peek_string(peek4u(p + 4)))
free_pointer_array(p)

test_report()
