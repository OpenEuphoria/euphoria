include unittest.e

test_equal("warning_file(-1)", -1, open("warning.lst","r"))

test_report()