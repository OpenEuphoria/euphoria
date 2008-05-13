-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
-- Euphoria 3.2
-- Test functions and procedures shipped with Euphoria

include unittest.e

set_test_verbosity(TEST_SHOW_FAILED_ONLY)

sequence cmd
cmd = command_line()

if length(cmd) > 2 then
    if equal(cmd[3], "-all") then
	set_test_verbosity(TEST_SHOW_ALL)
    elsif equal(cmd[3], "-failed") then
	set_test_verbosity(TEST_SHOW_FAILED_ONLY)
    end if
end if

-- Tests
include t_condcmp.e
include t_datetime.e
include t_file.e
include t_get.e
include t_locale.e
include t_loop.e
include t_map.e
include t_math.e
include t_misc.e
include t_os.e
include t_regex.e
include t_search.e
include t_sequence.e
include t_sort.e
include t_stack.e
include t_types.e
include t_unicode.e
include t_wildcard.e

test_summary()

