include std/unittest.e
include std/os.e

test_equal("getenv() #1", -1, getenv("EUTEST_EXAMPLE"))
test_equal("setenv() new", 1, setenv("EUTEST_EXAMPLE", "1"))
test_equal("getenv() #2", "1", getenv("EUTEST_EXAMPLE"))
test_equal("setenv() overwrite", 1, setenv("EUTEST_EXAMPLE", "2"))
test_equal("getenv() #3", "2", getenv("EUTEST_EXAMPLE"))
test_equal("setenv() no overwrite", 1, setenv("EUTEST_EXAMPLE", "3", 0))
test_equal("getenv() #4", "2", getenv("EUTEST_EXAMPLE"))
test_equal("unsetenv()", 1, unsetenv("EUTEST_EXAMPLE"))
test_equal("getenv() #5", -1, getenv("EUTEST_EXAMPLE"))

test_report()

