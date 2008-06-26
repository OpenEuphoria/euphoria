-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
--****
-- == Unit Testing Framework
-- === Constants

include pretty.e

--
-- Public Variables
--

export enum 
	TEST_QUIET = 0, 
	TEST_SHOW_FAILED_ONLY, 
	TEST_SHOW_ALL

--
-- Private variables
--

integer testCount = 0, testsPassed = 0, testsFailed = 0
sequence filename
integer verbose = TEST_SHOW_FAILED_ONLY

integer abort_on_fail = 0
integer wait_on_summary = 0

--
-- Private utility functions
--

procedure test_failed(sequence name, object a, object b)
	if verbose >= TEST_SHOW_FAILED_ONLY then
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
		printf(2, "  passed: %s\n", {name})
	end if
		
	testsPassed += 1
end procedure

--
-- Global Testing Functions
--

--****
-- === Setup Routines

--**
export procedure set_test_verbosity(atom verbosity)
	verbose = verbosity
end procedure

--**
export procedure set_wait_on_summary(integer toWait)
	wait_on_summary = toWait
end procedure

--**
export function set_test_abort(integer pValue)
	integer lTmp
	lTmp = abort_on_fail
	abort_on_fail = pValue
	return lTmp
end function

--****
-- === Reporting

--**
export procedure test_report()
	atom score

	if testsFailed > 0 or verbose = TEST_SHOW_ALL then
		if testCount = 0 then
			score = 100
		else
			score = (testsPassed / testCount) * 100
		end if

	    printf(2, "  %d tests run, %d passed, %d failed, %.1f%% success\n",
       		{testCount, testsPassed, testsFailed, score})
	end if
		
	if match("t_c_", filename) = 1 then	
		puts(2, "  test should have failed but was a success\n")
		abort(0)
	else
		abort(testsFailed > 0)
	end if
end procedure

--**
procedure record_result(integer success, sequence name, object a, object b)
	testCount += 1

	if success then
		test_passed(name)
	else
		test_failed(name, a, b)
	end if
end procedure

--****
-- === Tests
--

--**
export procedure test_equal(sequence name, object a, object b)
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

--**
export procedure test_not_equal(sequence name, object a, object b)
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

--**
export procedure test_true(sequence name, object a)
	integer success
	if sequence(a) then
		success = 0
	else
		success = (a != 0)
	end if
	record_result(success, name, 1, a )
end procedure

--**
export procedure test_false(sequence name, object a)
	integer success
	if not integer(a) then
		success = 0
	else
		success = (a = 0)
	end if
	record_result(success, name, 0, a)
end procedure

--**
export procedure test_fail(sequence name)
	record_result(0, name, 1, 0)
end procedure

--**
export procedure test_pass(sequence name)
	record_result(1, name, 1, 1)
end procedure

sequence cmd
cmd = command_line()
filename = cmd[2]

for i = 3 to length(cmd) do
	if equal(cmd[i], "-all") then
		set_test_verbosity(TEST_SHOW_ALL)
	elsif equal(cmd[i], "-failed") then
		set_test_verbosity(TEST_SHOW_FAILED_ONLY)
	elsif equal(cmd[i], "-wait") then
		set_wait_on_summary(1)
    end if
end for
