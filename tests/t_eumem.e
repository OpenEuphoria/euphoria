include std/eumem.e
include std/unittest.e
object myspot

myspot = malloc(10)

test_equal("eumem allocation", 10, length(ram_space[myspot]))

test_true("eumem validation", valid(myspot, 10))

free(myspot)

test_false("eumem free", valid(myspot, 10))


test_report()
