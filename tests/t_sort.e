include std/sort.e
include std/unittest.e
include std/wildcard.e

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
                    sort(  {}, DESCENDING)
           )
test_equal("sort_reverse() one item sequence",
                    {9}, 
                    sort(  {9}, DESCENDING)
          )
test_equal("sort_reverse() integer sorted ",
                    {3,2,1}, 
                    sort(  {1,2,3}, DESCENDING)
          )
test_equal("sort_reverse() integer rev sorted ",
                    {3,2,1}, 
                    sort(  {3,2,1}, DESCENDING)
           )
test_equal("sort_reverse() integer dups ",
                    {3,2,2,1,1},
                    sort(  {1,2,3,2,1}, DESCENDING)
           )
test_equal("sort_reverse() integer sequence",
                    {3,2,1},
                    sort(  {3,1,2}, DESCENDING)
           )
test_equal("sort_reverse() float sequence",
                    {6.5, 5.2, 5.1},
                    sort(  {5.1, 6.5, 5.2}, DESCENDING)
          )
test_equal("sort_reverse() string", 
                    "aBA", 
                    sort(  "BaA", DESCENDING)
          )
test_equal("sort_reverse() mixed", 
                    {"ABa",  {1,{2,3}, 4.5}, {-5}, "", 3, 2.477},
                    sort(  {"ABa",3, "", 2.477, {-5}, {1,{2,3},4.5}}, DESCENDING)
          )

function rsu(object a, object b, sequence c) -- asc/desc sort
    if equal(c, "rev") then
         return -(compare(a, b))
    end if
    return compare(a, b)
end function
integer rid_rsu = routine_id("rsu")
test_equal("custom_sort() empty sequence",         
                    {}, 
                    custom_sort( rid_rsu, {}, {"rev"})
           )
test_equal("custom_sort() one item sequence",
                    {9}, 
                    custom_sort( rid_rsu, {9}, {"rev"})
          )
test_equal("custom_sort() integer sorted ",
                    {3,2,1}, 
                    custom_sort( rid_rsu, {1,2,3}, {"rev"})
          )
test_equal("custom_sort() integer rev sorted ",
                    {3,2,1}, 
                    custom_sort( rid_rsu, {3,2,1}, {"rev"})
           )
test_equal("custom_sort() integer dups ",
                    {3,2,2,1,1},
                    custom_sort( rid_rsu, {1,2,3,2,1}, {"rev"})
           )
test_equal("custom_sort() integer dups asc",
                    {1,1,2,2,3},
                    custom_sort( rid_rsu, {1,2,3,2,1}, {"norm"})
           )
test_equal("custom_sort() integer sequence",
                    {3,2,1},
                    custom_sort( rid_rsu, {3,1,2}, {"rev"})
           )
test_equal("custom_sort() float sequence",
                    {6.5, 5.2, 5.1},
                    custom_sort( rid_rsu, {5.1, 6.5, 5.2}, {"rev"})
          )
test_equal("custom_sort() string", 
                    "aBA", 
                    custom_sort( rid_rsu, "BaA", {"rev"})
          )
test_equal("custom_sort() mixed", 
                    {"ABa",  {1,{2,3}, 4.5}, {-5}, "", 3, 2.477},
                    custom_sort( rid_rsu, {"ABa",3, "", 2.477, {-5}, {1,{2,3},4.5}}, {"rev"})
          )

-----  sort_columns() ------
test_equal("sort_columns() empty sequence",
                    {},
                    sort_columns({}, {})
           )
           
test_equal("sort_columns() single item sequence",
                    {{1,2,3}},
                    sort_columns({{1,2,3}}, {2,-3})
           )           
           
test_equal("sort_columns() single item sequence",
                    {{1,2,4}, {1,2,3}, {1,2,1}, {5,3,4}, {1,3,3}},
                    sort_columns({{1,2,3}, {1,2,4}, {1,2,1}, {1,3,3}, {5,3,4}}, {2,-3})
           )                      

test_report()

