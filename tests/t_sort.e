---------- CHANGE HISTORY ------------
-- 16-May-2008, Derek Parnell, Added tests for sort_reverse() and sort_user()
--                             Added border-case tests, etc ...
--------------------------------------
include sort.e
include unittest.e
include wildcard.e

set_test_module_name("sort.e")

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

-----  sort_reverse() ------
test_equal("sort_reverse() empty sequence",         
                    {}, 
                    sort_reverse(  {})
           )
test_equal("sort_reverse() one item sequence",
                    {9}, 
                    sort_reverse(  {9})
          )
test_equal("sort_reverse() integer sorted ",
                    {3,2,1}, 
                    sort_reverse(  {1,2,3})
          )
test_equal("sort_reverse() integer rev sorted ",
                    {3,2,1}, 
                    sort_reverse(  {3,2,1})
           )
test_equal("sort_reverse() integer dups ",
                    {3,2,2,1,1},
                    sort_reverse(  {1,2,3,2,1})
           )
test_equal("sort_reverse() integer sequence",
                    {3,2,1},
                    sort_reverse(  {3,1,2})
           )
test_equal("sort_reverse() float sequence",
                    {6.5, 5.2, 5.1},
                    sort_reverse(  {5.1, 6.5, 5.2})
          )
test_equal("sort_reverse() string", 
                    "aBA", 
                    sort_reverse(  "BaA")
          )
test_equal("sort_reverse() mixed", 
                    {"ABa",  {1,{2,3}, 4.5}, {-5}, "", 3, 2.477},
                    sort_reverse(  {"ABa",3, "", 2.477, {-5}, {1,{2,3},4.5}})
          )

-----  sort_user() ------
function rsu(object a, object b, object c) -- asc/desc sort
    if equal(c, 1) then
         return -(compare(a, b))
    end if
    return compare(a, b)
end function
test_equal("sort_user() empty sequence",         
                    {}, 
                    sort_user( routine_id("rsu"), {}, 1)
           )
test_equal("sort_user() one item sequence",
                    {9}, 
                    sort_user( routine_id("rsu"), {9}, 1)
          )
test_equal("sort_user() integer sorted ",
                    {3,2,1}, 
                    sort_user( routine_id("rsu"), {1,2,3}, 1)
          )
test_equal("sort_user() integer rev sorted ",
                    {3,2,1}, 
                    sort_user( routine_id("rsu"), {3,2,1}, 1)
           )
test_equal("sort_user() integer dups ",
                    {3,2,2,1,1},
                    sort_user( routine_id("rsu"), {1,2,3,2,1}, 1)
           )
test_equal("sort_user() integer dups asc",
                    {1,1,2,2,3},
                    sort_user( routine_id("rsu"), {1,2,3,2,1}, 0)
           )
test_equal("sort_user() integer sequence",
                    {3,2,1},
                    sort_user( routine_id("rsu"), {3,1,2}, 1)
           )
test_equal("sort_user() float sequence",
                    {6.5, 5.2, 5.1},
                    sort_user( routine_id("rsu"), {5.1, 6.5, 5.2}, 1)
          )
test_equal("sort_user() string", 
                    "aBA", 
                    sort_user( routine_id("rsu"), "BaA", 1)
          )
test_equal("sort_user() mixed", 
                    {"ABa",  {1,{2,3}, 4.5}, {-5}, "", 3, 2.477},
                    sort_user( routine_id("rsu"), {"ABa",3, "", 2.477, {-5}, {1,{2,3},4.5}}, 1)
          )

