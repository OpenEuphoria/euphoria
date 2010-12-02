include std/unittest.e

test_equal("Scaning fp #1", 24, floor(10 * 2.35 + 0.5)  )

/* Start of nested comment
  test_true("Failed level 1", 1)
  /*
  	test_true("Failed level 2", 1)
  */ 
*/

test_true("Success one one line", /*  not /* seen */ */ 1)

/* 
test_true("Failed eol slash", 1)/
*/

/* 
test_true("Failed eol star", 1)*
*/

/* 
test_true("Failed many stars", 1) 
**/

/* 
test_true("Failed embedded complex", 1) 
  ///*** ***///
*/

test_report()
