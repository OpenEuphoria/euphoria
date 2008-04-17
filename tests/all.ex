-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
-- Euphoria 3.2
-- Test functions and procedures shipped with Euphoria

include unittest.e

setTestVerbosity(TEST_SHOW_ALL)

sequence cmd
cmd = command_line()

if length(cmd) > 2 then
    if equal(cmd[3], "-all") then
        setTestVerbosity(TEST_SHOW_ALL)
    elsif equal(cmd[3], "-failed") then
        setTestVerbosity(TEST_SHOW_FAILED_ONLY)
    end if
end if

-- Tests
include t_get.e
include t_misc.e
include t_sort.e
include t_wildcard.e

testSummary()
