include sort.e
include unittest.e

setTestModuleName("sort.e")

testEqual("sort() integer sequence", {1,2,3}, sort({3,1,2}))
testEqual("sort() float sequence", {5.1, 5.2, 6.5}, sort({5.1, 6.5, 5.2}))
testEqual("sort() string", "ABa", sort("BaA"))

function rs(object a, object b) -- reverse sort
    return 0 - compare(a, b)
end function

testEqual("custom_sort() integer sequence", {3,2,1}, custom_sort(routine_id("rs"), {2,3,1}))
testEqual("custom_sort() float sequence", {6.5, 5.2, 5.1},
    custom_sort(routine_id("rs"), {5.1, 6.5, 5.2}))
testEqual("custom_sort() string sequence", "aBA", custom_sort(routine_id("rs"), "AaB"))
