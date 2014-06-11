
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
test_equal("Geometric mean, positive", 2.8844991406148167646432766215602, geomean({2, "", 3, 4}, ST_IGNSTR))
test_equal("Geometric mean, no data", 1, geomean({"", {-3, 4}}, ST_IGNSTR))
test_equal("Geometric mean, atom", 9, geomean( 9 ) )
test_equal("Geometric mean, one number", 7, geomean( {7} ) )
test_equal("Geometric mean, with zero", 0, geomean( {1,2,0}) )

test_equal("Harmonic mean", 36/13, harmean({2, "", 3, 4}, ST_IGNSTR))
test_equal("HGeometric mean, no data", 0, harmean({"", {-3, 4}}, ST_IGNSTR))
test_equal("harmean one number", 5, harmean( {5} ) )

test_equal("avedev list", 1.99047619047619, avedev( {7,2,8,5,6,6,4,8,6,6,3,3,4,1,8,"text"}, ST_IGNSTR ))
test_equal("avedev text", {}, avedev( {"text"}, ST_IGNSTR ))
test_equal("avedev empty", {}, avedev( {}, ST_IGNSTR ))
test_equal("avedev one number", 0, avedev( {1}, ST_ALLNUM ) )

test_equal("sum central moments 1", -8.526512829e-14, sum_central_moments("the cat is the hatter", 1)) --> -8.526512829e-14
test_equal("sum central moments 2", 19220.5714285714, sum_central_moments("the cat is the hatter", 2)) --> 19220.57143      
test_equal("sum central moments 3", -811341.551020408, sum_central_moments("the cat is the hatter", 3)) --> -811341.551      

atom CENTRAL_MOMENT4 = 56824083.708454810082912
ifdef BSD and BITS64 then
	-- We don't have powl on BSD, so the calculation is slightly different due to floating point casts
	CENTRAL_MOMENT4 = 56824083.7084547973681765143
elsedef
		
end ifdef
test_equal("sum central moments 4", CENTRAL_MOMENT4, sum_central_moments("the cat is the hatter", 4)) --> 56824083.71 ? 

test_equal("central moment no numbers", 0, central_moment( {}, 1 ) )

test_equal("sum atom", 9.5, sum( 9.5 ) )

test_equal("average atom", 4.3, average( 4.3 ) )
test_equal("average no numbers", {}, average( {} ) )


test_equal("smallest integers and text", 1,  smallest( {7,2,8,5,6,6,4,8,6,6,3,3,4,1,8,"text"} ) ) -- Ans: 1 
test_equal("smallest text", {}, smallest( {"just", "text"} ) )
test_equal("smallest atom", 6.2, smallest( 6.2 ) )

test_equal("skewness #1", -1.36166186, skewness("the cat is the hatter"))
test_equal("skewness #2", 0.1093730315, skewness("thecatisthehatter") ) 
test_equal("skewness atom", 5.9, skewness( 5.9 ) )
test_equal("skewness no data", {}, skewness( {} ) )

test_equal( "raw frequency", 
	{
		{5,116},
		{4,32},
		{3,104},
		{3,101},
		{2,97},
		{1,115},
		{1,114},
		{1,105},
		{1,99}
	},
	raw_frequency("the cat is the hatter") )
test_equal( "raw frequency atom", {{1, 6}}, raw_frequency( 6 ) )
test_equal( "raw frequency no data", {{1,{}}}, raw_frequency( {} ) )

test_equal( "range", {1, 16, 15, 8.5} , range( {7,2,8,5,6,6,4,8,6,16,3,3,4,1,8,"text"} ) ) -- Ans: {1, 16, 15, 8.5} 
test_equal( "range atom", {4,4,0,4}, range( 4 ) )
test_equal( "range no data", {}, range( {} ) )

test_equal( "moving average #1", {5.8, 5.4, 5.5, 5.1, 4.7, 4.9}, movavg( {7,2,8,5,6,6,4,8,6,6,3,3,4,1,8}, 10 )  )
test_equal( "moving average #2,", {4.5, 5, 6.5, 5.5} , movavg( {7,2,8,5,6}, 2 )  )
test_equal( "moving average #3", {3.25, 6.5, 5.75, 5.75}, movavg( {7,2,8,5,6}, {0.5, 1.5} ) )
test_equal( "moving average #4", {5.8, 5.4, 5.5, 5.1, 4.7, 4.9} , movavg( {7,2,8,5,6,6,4,8,6,6,3,3,4,1,8}, 10 )  )
test_equal( "moving average #5",  {3.25, 6.5, 5.75, 5.75}, movavg( {7,2,8,5,6}, {0.5, 1.5} )  )
test_equal( "moving average atom", {99}, movavg( 99, 1 ) )
test_equal( "moving average atom fractional period", {}, movavg( 99, 0.5 ) )
test_equal( "moving average shorter than period", {0.5}, movavg( {1}, 2 ) )
test_equal( "moving average no data", {}, movavg( {}, 1 ) )

test_equal( "count atom", 1, count( 9.45 ) )

test_equal( "mode #1", {6}, mode( {7,2,8,5,6,6,4,8,6,6,3,3,4,1,8,4} ))
test_equal( "mode #2", {8,6}, mode( {8,2,8,5,6,6,4,8,6,6,3,3,4,1,8,4} ) )
test_equal( "mode empty", {}, mode( {} ) )

test_equal( "median #1", 5, median( {7,2,8,5,6,6,4,8,6,6,3,3,4,1,8,4} ) )
test_equal( "median #2", 1, median( {1,2} ) )
test_equal( "median atom", 3, median( 3 ) )
test_equal( "median no data", {}, median( {} ) )

test_equal( "largest #1", 8, largest( {7,2,8,5,6,6,4,8,6,6,3,3,4,1,8,"text"} ) ) -- Ans: 8 
test_equal( "largest #2", {},  largest( {"just","text"} ) )
test_equal( "largest atom", 5, largest( 5 ) )

test_equal( "kurtosis #1", -1.737889192, kurtosis("thecatisthehatter"))     --> -1.737889192 
test_equal( "kurtosis atom", 5, kurtosis( 5 ) )
test_equal( "kurtosis empty", {0}, kurtosis( {} ) )
test_equal( "kurtosis sd = 0", {1}, kurtosis( {1, 1} ) )

test_equal( "exp moving average #1",  {6.65,3.1625,6.790625,5.44765625,5.861914063}, emovavg( {7,2,8,5,6}, 0.75 )  )
test_equal( "exp moving average #2",  {5.95,4.9625,5.721875,5.54140625,5.656054687} , emovavg( {7,2,8,5,6}, 0.25 )  )
test_equal( "exp moving average #3",  {6.066666667,4.711111111,5.807407407,5.538271605,5.69218107} , emovavg( {7,2,8,5,6}, -1 )   )
test_equal( "exp moving average atom", {3}, emovavg( 3, 0.5 ) )
test_equal( "exp moving average no data", {}, emovavg( {}, 0.5 ) )

test_report()

