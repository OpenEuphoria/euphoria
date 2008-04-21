include sort.e
include unittest.e

set_test_module_name("sort.e")

test_equal("sort() integer sequence", {1,2,3}, sort({3,1,2}))
test_equal("sort() float sequence", {5.1, 5.2, 6.5}, sort({5.1, 6.5, 5.2}))
test_equal("sort() string", "ABa", sort("BaA"))

function rs(object a, object b) -- reverse sort
    return 0 - compare(a, b)
end function

test_equal("custom_sort() integer sequence", {3,2,1}, custom_sort(routine_id("rs"), {2,3,1}))
test_equal("custom_sort() float sequence", {6.5, 5.2, 5.1},
    custom_sort(routine_id("rs"), {5.1, 6.5, 5.2}))
test_equal("custom_sort() string sequence", "aBA", custom_sort(routine_id("rs"), "AaB"))
