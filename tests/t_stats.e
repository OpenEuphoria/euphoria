include std/unittest.e
include std/stats.e
include std/sort.e

test_equal("small list", {4,1}, small( {4,5,6,1,7,5,4,3,"text"}, 3 ))
test_equal("small 1", {}, small( {100}, 5 ))
test_equal("small text", {}, small( {"text"},ST_IGNSTR ))
test_equal("small empty", {}, small( {},5 ))

test_equal("stdev list", 1.3451854183, stdev( {4,5,6,7,5,4,3,"text"}, ST_IGNSTR ))
test_equal("stdev 1", 0, stdev( {100} ))
test_equal("stdev text", {}, stdev( {"text"}, ST_IGNSTR  ))
test_equal("stdev empty", {}, stdev( {} ))

test_equal("stdev a list", 2.121320344, stdev( {4,5,6,7,5,4,3,"text"}, ST_ZEROSTR ))
test_equal("stdev a 1", 0, stdev( {100}, 0 ))
test_equal("stdev a text", 0, stdev( {"text"}, 0 ))
test_equal("stdev a empty", {}, stdev( {}, 0 ))

test_equal("stdev p list", 1.245399698, stdev( {4,5,6,7,5,4,3,"text"}, ST_IGNSTR, ST_FULLPOP ))
test_equal("stdev p 1", 0, stdev( {100}, ST_IGNSTR, ST_FULLPOP ))
test_equal("stdev p text", {}, stdev( {"text"}, ST_IGNSTR, ST_FULLPOP ))
test_equal("stdev p empty", {}, stdev( {}, ST_IGNSTR, ST_FULLPOP ))


test_equal("stdev pa list", 1.984313483, stdev( {4,5,6,7,5,4,3,"text"}, ST_ZEROSTR, ST_FULLPOP ))
test_equal("stdev pa 1", 0, stdev( {100}, ST_IGNSTR, ST_FULLPOP  ))
test_equal("stdev pa text", 0, stdev( {"text"}, ST_ZEROSTR, ST_FULLPOP  ))
test_equal("stdev pa empty", {}, stdev( {}, ST_IGNSTR, ST_FULLPOP  ))

test_equal("Geometric mean", 2.8844991406148167646432766215602, geomean({2, "", -3, 4}, ST_IGNSTR))
test_equal("Geometric mean, no data", 1, geomean({"", {-3, 4}}, ST_IGNSTR))
test_equal("Harmonic mean", 36/13, harmean({2, "", 3, 4}, ST_IGNSTR))
test_equal("HGeometric mean, no data", 0, harmean({"", {-3, 4}}, ST_IGNSTR))

test_equal("avedev list", 1.99047619047619, avedev( {7,2,8,5,6,6,4,8,6,6,3,3,4,1,8,"text"}, ST_IGNSTR ))
test_equal("avedev text", {}, avedev( {"text"}, ST_IGNSTR ))
test_equal("avedev empty", {}, avedev( {}, ST_IGNSTR ))

test_report()

