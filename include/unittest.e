-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
-- Euphoria 3.2
-- Unit testing framework


include misc.e

--
-- Public Variables
--

global constant 
	TEST_QUIET = 0, 
	TEST_SHOW_FAILED_ONLY = 1, 
	TEST_SHOW_MODULES = 2,
	TEST_SHOW_ALL = 3
global integer testCount, testsPassed, testsFailed

testCount	= 0
testsPassed = 0
testsFailed = 0

--
-- Private variables
--

integer modShown
modShown = 0

integer verbose
verbose = 0
sequence currentMod
currentMod = ""
sequence modulesTested
modulesTested = {}

integer abort_on_fail
abort_on_fail = 0
--
-- Private utility functions
--

procedure test_failed(sequence name, object a, object b)
	if verbose >= TEST_SHOW_FAILED_ONLY then
		if modShown = 0 then
			printf(2, "%s:\n", {currentMod})
			modShown = 1
		end if
		printf(2, "  failed: %s, expected: ", {name})
		pretty_print(2, a, {2,2,1,78,"%d", "%.15g"})
		puts(2, " but got: ")
		pretty_print(2, b, {2,2,1,78,"%d", "%.15g"})
		puts(2, "\n")
	end if

	testsFailed += 1
	if abort_on_fail then
		puts(2, "Abort On Fail set.\n")
		abort(2)
	end if
end procedure

procedure test_passed(sequence name)
	if verbose >= TEST_SHOW_ALL then
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

global function set_test_abort(integer pValue)
	integer lTmp
	lTmp = abort_on_fail
	abort_on_fail = pValue
	return lTmp
end function

global procedure set_test_module_name(sequence name)
	modulesTested = append(modulesTested, name)
	currentMod = name
	modShown = 0
end procedure

global procedure test_summary()
	if verbose > TEST_QUIET then
		if verbose >= TEST_SHOW_MODULES and length(modulesTested) > 0 then
			puts(2, "\nModules tested...\n")
			for i = 1 to length(modulesTested) do
				printf(2, "  %s\n", {modulesTested[i]})
			end for
		end if
		printf(2, "\n%d tests run, %d passed, %d failed, %d%% success\n",
				{testCount, testsPassed, testsFailed, (testsPassed / testCount) * 100})
	end if
		
	abort(testsFailed > 0)
end procedure

procedure record_result(integer success, sequence name, object a, object b)
	testCount += 1

	if success then
		test_passed(name)
	else
		test_failed(name, a, b)
	end if
end procedure

global procedure test_equal(sequence name, object a, object b)
	integer success
	if sequence(a) or sequence(b) then
		success = equal(a,b)
	else
		if a > b then
			success = ((a-b) < 1e-9)
		else
			success = ((b-a) < 1e-9)
		end if
	end if
	record_result(success, name, a, b)
end procedure

global procedure test_not_equal(sequence name, object a, object b)
	integer success
	if sequence(a) or sequence(b) then
		success = not equal(a,b)
	else
		if a > b then
			success = ((a-b) >= 1e-9)
		else
			success = ((b-a) >= 1e-9)
		end if
	end if
	record_result(success, name, a, b)
end procedure

global procedure test_true(sequence name, object a)
	integer success
	if sequence(a) then
		success = 0
	else
		success = (a != 0)
	end if
	record_result(success, name, a, 1)
end procedure

global procedure test_false(sequence name, object a)
	integer success
	if not integer(a) then
		success = 0
	else
		success = (a = 0)
	end if
	record_result(success, name, a, 0)
end procedure

global procedure test_fail(sequence name)
	record_result(0, name, 1, 0)
end procedure

global procedure test_pass(sequence name)
	record_result(1, name, 1, 1)
end procedure

