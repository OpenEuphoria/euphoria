-- stats.e
include stats.e
set_test_module_name("stats.e")
include sort.e

test_equal("small list", 4, small( {4,5,6,1,7,5,4,3,"text"}, 3 ))
test_equal("small 1", {}, small( {100}, 5 ))
test_equal("small text", {}, small( {"text"},0 ))
test_equal("small empty", {}, small( {},5 ))

test_equal("stdev list", 1.3451854183, stdev( {4,5,6,7,5,4,3,"text"} ))
test_equal("stdev 1", 0, stdev( {100} ))
test_equal("stdev text", {}, stdev( {"text"} ))
test_equal("stdev empty", {}, stdev( {} ))
test_equal("stdeva list", 2.121320344, stdeva( {4,5,6,7,5,4,3,"text"} ))
test_equal("stdeva 1", 0, stdeva( {100} ))
test_equal("stdeva text", 0, stdeva( {"text"} ))
test_equal("stdeva empty", {}, stdeva( {} ))

test_equal("stdevp list", 1.245399698, stdevp( {4,5,6,7,5,4,3,"text"} ))
test_equal("stdevp 1", 0, stdevp( {100} ))
test_equal("stdevp text", {}, stdevp( {"text"} ))
test_equal("stdevp empty", {}, stdevp( {} ))


test_equal("stdevpa list", 1.984313483, stdevpa( {4,5,6,7,5,4,3,"text"} ))
test_equal("stdevpa 1", 0, stdevpa( {100} ))
test_equal("stdevpa text", 0, stdevpa( {"text"} ))
test_equal("stdevpa empty", {}, stdevpa( {} ))


test_equal("avedev list", 1.85777777777778, avedev( {7,2,8,5,6,6,4,8,6,6,3,3,4,1,8,"text"} ))
test_equal("avedev text", {}, avedev( {"text"} ))
test_equal("avedev empty", {}, avedev( {} ))

