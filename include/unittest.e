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

atom verbose
verbose = 0

sequence currentMod
currentMod = ""

--
-- Private utility functions
--

procedure testFailed(sequence name, object a, object b)
	if verbose > 0 then
		printf(2, "  failed: %s. expected: ", {name})
		pretty_print(2, a, {2})
		puts(2, " but got: ")
		pretty_print(2, b, {2})
		puts(2, "\n")
	end if
	
	testsFailed += 1
end procedure

procedure testPassed(sequence name)
	if verbose > 1 then
		printf(2, "  passed: %s\n", {name})
	end if
	
	testsPassed += 1
end procedure

--
-- Global Testing Functions
--

global procedure setTestVerbosity(atom verbosity)
	verbose = verbosity
end procedure

global procedure setTestModuleName(sequence name)
	currentMod = name
	
	printf(2, "%s:\n", {currentMod})
end procedure

global procedure testSummary()
	if verbose > 0 then
		puts(2, "\n")
	
		printf(2, "%d tests run, %d passed, %d failed, %d%% success\n",
			{testCount, testsPassed, testsFailed, (testsPassed / testCount) * 100})
	end if
	
	abort(testsFailed > 0)
end procedure

global procedure testEqual(sequence name, object a, object b)
	testCount += 1
	
	if equal(a, b) = 0 then
		testFailed(name, a, b)
	else
		testPassed(name)
	end if
end procedure

global procedure testNotEqual(sequence name, object a, object b)
	testCount += 1
	
	if equal(a,b) then
		testFailed(name, a, b)
	else
		testPassed(name)
	end if
end procedure
