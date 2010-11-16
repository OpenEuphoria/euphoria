include std/unittest.e

include sort.e

-----  sort() ------
test_equal("sort() empty sequence",         
                    {}, 
                    sort({})
           )
test_equal("sort() one item sequence",
                    {9}, 
                    sort({9})
          )
test_equal("sort() integer sorted ",
                    {1,2,3}, 
                    sort({1,2,3})
          )
test_equal("sort() integer rev sorted ",
                    {1,2,3}, 
                    sort({3,2,1})
           )
test_equal("sort() integer dups ",
                    {1,1,2,2,3},
                    sort({1,2,3,2,1})
           )
test_equal("sort() integer sequence",
                    {1,2,3},
                    sort({3,1,2})
           )
test_equal("sort() float sequence",
                    {5.1, 5.2, 6.5},
                    sort({5.1, 6.5, 5.2})
          )
test_equal("sort() string", 
                    "ABa", 
                    sort("BaA")
          )
test_equal("sort() mixed", 
                    {2.477, 3,  "", {-5}, {1,{2,3}, 4.5}, "ABa"}, 
                    sort({"ABa",3, "", 2.477, {-5}, {1,{2,3},4.5}})
          )

-----  custom_sort() ------
function rs(object a, object b) -- reverse sort
    return -(compare(a, b))
end function

test_equal("custom_sort() empty sequence",         
                    {}, 
                    custom_sort( routine_id("rs"), {})
           )
test_equal("custom_sort() one item sequence",
                    {9}, 
                    custom_sort( routine_id("rs"), {9})
          )
test_equal("custom_sort() integer sorted ",
                    {3,2,1}, 
                    custom_sort( routine_id("rs"), {1,2,3})
          )
test_equal("custom_sort() integer rev sorted ",
                    {3,2,1}, 
                    custom_sort( routine_id("rs"), {3,2,1})
           )
test_equal("custom_sort() integer dups ",
                    {3,2,2,1,1},
                    custom_sort( routine_id("rs"), {1,2,3,2,1})
           )
test_equal("custom_sort() integer sequence",
                    {3,2,1},
                    custom_sort( routine_id("rs"), {3,1,2})
           )
test_equal("custom_sort() float sequence",
                    {6.5, 5.2, 5.1},
                    custom_sort( routine_id("rs"), {5.1, 6.5, 5.2})
          )
test_equal("custom_sort() string", 
                    "aBA", 
                    custom_sort( routine_id("rs"), "BaA")
          )
test_equal("custom_sort() mixed", 
                    {"ABa",  {1,{2,3}, 4.5}, {-5}, "", 3, 2.477},
                    custom_sort( routine_id("rs"), {"ABa",3, "", 2.477, {-5}, {1,{2,3},4.5}})
          )


test_report()
