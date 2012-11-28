--****
-- == Unit Testing Framework
--
-- <<LEVELTOC level=2 depth=4>>
--
-- === Background
-- Unit testing is the process of assuring that the smallest programming units
-- are actually delivering functionality that complies with their specification.
-- The units in question are usually individual routines rather than whole programs
-- or applications.
--
-- The theory is that if the components of a system are working correctly, then
-- there is a high probability that a system using those components can be made
-- to work correctly.
--
-- In Euphoria terms, this framework provides the tools to make testing and reporting on
-- functions and procedures easy and standardized. It gives us a simple way to
-- write a test case and to report on the findings.\\
-- Example~:
-- <eucode>
-- include std/unittest.e
--
-- test_equal( "Power function test #1", 4, power(2, 2))
-- test_equal( "Power function test #2", 4, power(16, 0.5))
--
-- test_report()
-- </eucode>
--
-- Name your test file in the special manner, ##t_NAME.e## and then simply run
-- ##eutest## in that directory.
--
-- {{{
-- C:\Euphoria> eutest
-- t_math.e:
--  failed: Bad math, expected: 100 but got: 8
--  2 tests run, 1 passed, 1 failed, 50.0% success
--
-- Test failure summary:
--    FAIL: t_math.e
--
-- 2 file(s) run 1 file(s) failed, 50.0% success--
-- }}}
--
-- In this example, we use the ##test_equal## function to record the result of
-- a test. The first parameter is the name of the test, which can be anything
-- and is displayed if the test fails. The second parameter is the expected
-- result ~-- what we expect the function being tested to return. The third
-- parameter is the actual result returned by the function being tested. This
-- is usually written as a call to the function itself.
--
-- It is typical to provide as many test cases as would be required to give us
-- confidence that the function is being truly exercised. This includes calling
-- it with typical values and edge-case or exceptional values. It is also useful
-- to test the function's error handling by calling it with bad parameters.
--
-- When a test fails, the framework displays a message, showing the test's name,
-- the expected result and the actual result. You can configure the framework to
-- display each test run, regardless of whether it fails or not.
--
-- After running a series of tests, you can get a summary displayed by calling
-- the ##test_report## procedure. To get a better feel for unit testing, have
-- a look at the provided test cases for the standard library in the //tests//
-- directory.
--
-- When included in your program, ##unittest.e## sets a crash handler to log a crash 
-- as a failure.

namespace unittest

include std/console.e
include std/filesys.e
include std/io.e
include std/math.e
include std/pretty.e
include std/search.e
include std/error.e

--****
-- === Constants
--

--
-- Public Variables
--

-- Verbosity values
public enum
	TEST_QUIET = 0,
	TEST_SHOW_FAILED_ONLY,
	TEST_SHOW_ALL

--
-- Private variables
--

atom time_start = time(), time_test = time()

integer test_count = 0, tests_passed = 0, tests_failed = 0
sequence filename
integer verbose = TEST_SHOW_FAILED_ONLY

integer abort_on_fail = 0
integer wait_on_summary = 0
integer accumulate_on_summary = 0
integer log_fh = 0

--
-- Private utility functions
--

procedure add_log(object data)
	if log_fh = 0 then
		return
	end if

	puts(log_fh, "entry = ")
	pretty:pretty_print(log_fh, data, {2, 2, 1, 78, "%d", "%.15g"})
	puts(log_fh, "\n")
	io:flush(log_fh)
end procedure

procedure test_failed(sequence name, object a, object b, integer TF = 0)
	if verbose >= TEST_SHOW_FAILED_ONLY then
		printf(2, "  failed: %s, expected: ", {name})
		if TF then
			if not equal(a,0) then
				puts(2, "TRUE")
			else
				puts(2, "FALSE")
			end if
		else
			pretty:pretty_print(2, a, {2,2,1,78,"%d", "%.15g"})
		end if
		puts(2, " but got: ")
		if TF and integer(b) then
			if not equal(b,0) then
				puts(2, "TRUE")
			else
				puts(2, "FALSE")
			end if
		else
			pretty:pretty_print(2, b, {2,2,1,78,"%d", "%.15g"})
		end if
		puts(2, "\n")
	end if

	tests_failed += 1

	add_log({ "failed", name, a, b, time() - time_test })
	time_test = time()

	if abort_on_fail then
		puts(2, "Abort On Fail set.\n")
		abort(2)
	end if
end procedure

procedure test_passed(sequence name)
	if verbose >= TEST_SHOW_ALL then
		printf(2, "  passed: %s\n", {name})
	end if

	tests_passed += 1

	add_log({ "passed", name, time() - time_test })
	time_test = time()
end procedure

--
-- Global Testing Functions
--

--****
-- === Setup Routines

--**
-- set the amount of information that is returned about passed and failed tests.
--
-- Parameters:
-- # ##verbosity## : an atom which takes predefined values for verbosity levels.
--
-- Comments:
-- The following values are allowable for ##verbosity##:
-- * ##TEST_QUIET## ~--  0,
-- * ##TEST_SHOW_FAILED_ONLY## ~--  1
-- * ##TEST_SHOW_ALL## ~-- 2
--
-- However, anything less than ##TEST_SHOW_FAILED_ONLY## is treated as ##TEST_QUIET##, and everything
-- above ##TEST_SHOW_ALL## is treated as ##TEST_SHOW_ALL##.
--
-- * At the lowest verbosity level, only the score is shown, ie the ratio passed tests/total tests.
-- * At the medium level, in addition, failed tests display their name, the expected outcome and
--   the outcome they got. This is the initial setting.
-- * At the highest level of verbosity, each test is reported as passed or failed.
--
-- If a file crashes when it should not, this event is reported no matter the verbosity level.
--
-- The command line switch ##"-failed"## causes verbosity to be set to medium at startup. The
-- command line switch ##"-all"## causes verbosity to be set to high at startup.
--
-- See Also:
-- [[:test_report]]

public procedure set_test_verbosity(atom verbosity)
	verbose = verbosity
end procedure

--**
-- requests the test report to pause before exiting.
--
-- Parameters:
--		# ##to_wait## : an integer, zero not to wait, nonzero to wait.
--
-- Comments:
-- Depending on the environment, the test results may be invisible if
-- ##set_wait_on_summary(1)## was not called prior, as this is not the default. The command
-- line switch ##"-wait"## performs this call.
--
-- See Also:
-- [[:test_report]]

public procedure set_wait_on_summary(integer to_wait)
	wait_on_summary = to_wait
end procedure

--**
-- requests the test report to save run stats in ##"unittest.dat"## before exiting.
--
-- Parameters:
--		# ##accumulate## : an integer, zero not to accumulate, nonzero to accumulate.
--
-- Comments:
-- The file "unittest.dat" is appended to with {t,f}\\
-- : where
-- :: //t// is total number of tests run
-- :: //f// is the total number of tests that failed
--

public procedure set_accumulate_summary(integer accumulate)
	accumulate_on_summary = accumulate
end procedure

--**
-- sets the behavior on test failure, and return previous value.
--
-- Parameters:
--		# ##abort_test## : an integer, the new value for this setting.
--
-- Returns:
-- 		An **integer**, the previous value for the setting.
--
-- Comments:
-- By default, the tests go on even if a file crashed.

public function set_test_abort(integer abort_test)
	integer tmp = abort_on_fail
	abort_on_fail = abort_test

	return tmp
end function

--****
-- === Reporting

--**
-- outputs the test report.
--
-- Comments:
--
-- The report components are described in the comments section for [[:set_test_verbosity]]. Everything
-- prints on the standard error device.
--
-- See Also:
--   [[:set_test_verbosity]]

public procedure test_report()
	atom score
	integer fh
	sequence fname
	sequence respc

	if tests_failed > 0 or verbose >= TEST_SHOW_ALL then
		if test_count = 0 then
			score = 100
		else
			score = (tests_passed / test_count) * 100
		end if

		respc = sprintf("%1.f%%", score)
		if equal(respc, "100%") then
			if tests_failed > 0 then
				-- this can happen when the number of tests is huge and the number of fails is tiny.
				respc = "99.99%" -- Cannot have 100% if any tests failed.
			end if
		end if
		printf(2, "  %d tests run, %d passed, %d failed, %s success\n",
			{test_count, tests_passed, tests_failed, respc})
	end if

	if accumulate_on_summary then
		fname = command_line()
		if equal(fname[1], fname[2]) then
			fname = fname[1]
		else
			fname = fname[2]
		end if
		fh = open("unittest.dat", "a")
		printf(fh, "{%d,%d,\"%s\"}\n", {test_count, tests_failed, fname})
		close(fh)
	end if

	add_log({ "summary", test_count, tests_failed, tests_passed, time() - time_start })

	if log_fh != 0 then
		close( log_fh )
		log_fh = 0
	end if
	
	if match("t_c_", filename) = 1 then
		puts(2, "  test should have failed but was a success\n")
		if wait_on_summary then
			console:maybe_any_key("Press a key to exit")
		end if
		abort(0)
	else
		if wait_on_summary then
			console:maybe_any_key("Press a key to exit")
		end if
		abort(tests_failed > 0)
	end if
end procedure

procedure record_result(integer success, sequence name, object a, object b, integer TF = 0)
	test_count += 1

	if success then
		test_passed(name)
	else
		test_failed(name, a, b, TF)
	end if
end procedure

--****
-- === Tests
--

--**
-- records whether a test passes by comparing two values.
--
-- Parameters:
--		# ##name## : a string, the name of the test
--		# ##expected## : an object, the expected outcome of some action
--		# ##outcome## : an object, some actual value that should equal the reference ##expected##.
--
-- Comments:
--
-- * For floating point numbers, a fuzz of ##1e-9## is used to assess equality.
--
-- A test is recorded as passed if equality holds between ##expected## and ##outcome##. The latter
-- is typically a function call, or a variable that was set by some prior action.
--
-- While ##expected## and ##outcome## are processed symmetrically, they are not recorded
-- symmetrically, so be careful to pass ##expected## before ##outcome## for better test failure
-- reports.
--
-- See Also:
-- [[:test_not_equal]], [[:test_true]], [[:test_false]], [[:test_pass]], [[:test_fail]]

public procedure test_equal(sequence name, object expected, object outcome)
	integer success

	if equal(expected, outcome ) then
		-- for inf and -inf simple values
		success = 1	
	elsif equal(0*expected, 0*outcome) then
		-- for complicated sequences values
		success = math:max( math:abs( expected - outcome ) ) < 1e-9
	else
		success = 0
	end if
			
	record_result(success, name, expected, outcome)
end procedure

--**
-- records whether a test passes by comparing two values.
--
-- Parameters:
--		# ##name## : a string, the name of the test
--		# ##expected## : an object, the expected outcome of some action
--		# ##outcome## : an object, some actual value that should equal the reference ##expected##.
--
-- Comments:
-- * For atoms, a fuzz of ##1e-9## is used to assess equality.
-- * For sequences, no such fuzz is implemented.
--
-- A test is recorded as passed if equality does not hold between ##expected## and ##outcome##. The
-- latter is typically a function call, or a variable that was set by some prior action.
--
-- See Also:
-- [[:test_equal]], [[:test_true]], [[:test_false]], [[:test_pass]], [[:test_fail]]

public procedure test_not_equal(sequence name, object a, object b)
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
	a = "anything but '" & pretty:pretty_sprint( a, {2,2,1,78,"%d", "%.15g"}) & "'"
	record_result(success, name, a, b)
end procedure

--**
-- records whether a test passes.
--
-- Parameters:
--		# ##name## : a string, the name of the test
--		# ##outcome## : an object, some actual value that should not be zero.
--
-- Comments:
-- This assumes an expected value different from 0. No fuzz is applied when checking whether an
-- atom is zero or not. Use [[:test_equal]] instead in this case.
--
-- See Also:
-- [[:test_equal]], [[:test_not_equal]], [[:test_false]], [[:test_pass]], [[:test_fail]]

public procedure test_true(sequence name, object outcome)
	record_result(not equal(outcome,0), name, 1, outcome, 1 )
end procedure

--**
-- records whether a test passes. If it fails, the program also fails.
--
-- Parameters:
--		# ##name## : a string, the name of the test
--		# ##outcome## : an object, some actual value that should not be zero.
--
-- Comments:
-- This is identical to ##test_true## except that if the test fails, the
-- program will also be forced to fail at this point.
--
-- See Also:
-- [[:test_equal]], [[:test_not_equal]], [[:test_false]], [[:test_pass]], [[:test_fail]]

public procedure assert(object name, object outcome)
	if sequence(name) then
		test_true(name, outcome)
		if equal(outcome,0) then
			error:crash(name)
		end if
	else
		test_true(outcome, name)
		if equal(name,0) then
			error:crash(outcome)
		end if
	end if
end procedure

--**
-- records whether a test passes by comparing two values.
--
-- Parameters:
--		# ##name## : a string, the name of the test
--		# ##outcome## : an object, some actual value that should be zero
--
-- Comments:
-- This assumes an expected value of 0. No fuzz is applied when checking whether an atom is zero
-- or not. Use [[:test_equal]] instead in this case.
--
-- See Also:
-- [[:test_equal]], [[:test_not_equal]], [[:test_true]], [[:test_pass]], [[:test_fail]]

public procedure test_false(sequence name, object outcome)
	record_result(equal(outcome, 0), name, 0, outcome, 1)
end procedure

--**
-- records that a test failed.
--
-- Parameters:
--		# ##name## : a string, the name of the test
--
-- See Also:
-- [[:test_equal]], [[:test_not_equal]], [[:test_true]], [[:test_false]], [[:test_pass]]
--

public procedure test_fail(sequence name)
	record_result(0, name, 1, 0, 1)
end procedure

--**
-- records that a test passed.
--
-- Parameters:
--		# ##name## : a string, the name of the test
--
-- See Also:
-- [[:test_equal]],  [[:test_not_equal]],[[:test_true]], [[:test_false]], [[:test_fail]]

public procedure test_pass(sequence name)
	record_result(1, name, 1, 1, 1)
end procedure

sequence cmd = command_line()
filename = cmd[2]


-- strip off path information
while find( filesys:SLASH, filename ) do
	filename = filename[find( filesys:SLASH, filename )+1..$]
end while

for i = 3 to length(cmd) do
	if equal(cmd[i], "-all") then
		set_test_verbosity(TEST_SHOW_ALL)
	elsif equal(cmd[i], "-failed") then
		set_test_verbosity(TEST_SHOW_FAILED_ONLY)
	elsif equal(cmd[i], "-wait") then
		set_wait_on_summary(1)
	elsif search:begins(cmd[i], "-accumulate") then
		set_accumulate_summary(1)
	elsif equal(cmd[i], "-log") then
		log_fh = open("unittest.log", "a")
		if log_fh = -1 then
			puts(2,"Cannot open unittest.log for append.\n")
			abort(1)
		end if
		add_log({"file", filename})
	end if
end for

ifdef not CRASH then



function test_crash( object o )
	test_fail( "unittesting crashed" )
	test_report()
	o = 0
	return o
end function
error:crash_routine( routine_id( "test_crash" ) )

end ifdef
