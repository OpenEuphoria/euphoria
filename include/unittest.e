-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
-- Euphoria 3.2
-- Unit testing framework

include misc.e

--
-- Public Variables
--

global constant TEST_QUIET = 0, TEST_SHOW_FAILED_ONLY = 1, TEST_SHOW_ALL = 2
global integer testCount, testsPassed, testsFailed

testCount   = 0
testsPassed = 0
testsFailed = 0

--
-- Private variables
--

integer modShown
modShown = 0

atom verbose
verbose = 0

sequence currentMod
currentMod = ""

--
-- Private utility functions
--

procedure test_failed(sequence name, object a, object b)
	if verbose > 0 then
        if modShown = 0 then
            printf(2, "%s:\n", {currentMod})
            modShown = 1
        end if
		printf(2, "  failed: %s. expected: ", {name})
		pretty_print(2, a, {2})
		puts(2, " but got: ")
		pretty_print(2, b, {2})
		puts(2, "\n")
	end if
	
	testsFailed += 1
end procedure

procedure test_passed(sequence name)
	if verbose > 1 then
        if modShown = 0 then
            printf(2, "%s:\n", {currentMod})
            modShown = 1
        end if
		printf(2, "  passed: %s\n", {name})
	end if
	
	testsPassed += 1
end procedure

--
-- Global Testing Functions
--

global procedure set_test_verbosity(atom verbosity)
	verbose = verbosity
end procedure

global procedure set_test_module_name(sequence name)
	currentMod = name
    modShown = 0
end procedure

global procedure test_summary()
	if verbose > 0 then
		printf(2, "\n%d tests run, %d passed, %d failed, %d%% success\n",
			{testCount, testsPassed, testsFailed, (testsPassed / testCount) * 100})
	end if
	
	abort(testsFailed > 0)
end procedure

global procedure test_equal(sequence name, object a, object b)
	testCount += 1

    if equal(a, b) then
	    test_passed(name)
    else
	    test_failed(name, a, b)
    end if
end procedure

global procedure test_not_equal(sequence name, object a, object b)
	testCount += 1
	
	if equal(a, b) then
		test_failed(name, a, b)
	else
		test_passed(name)
	end if
end procedure

global procedure test_true(sequence name, object a)
	testCount += 1

    if a = 1 then
	    test_passed(name)
    else
	    test_failed(name, a, 1)
    end if
end procedure

global procedure test_false(sequence name, object a)
    testCount += 1

    if a = 0 then
        test_passed(name)
    else
        test_failed(name, a, 0)
    end if
end procedure

