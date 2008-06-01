-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
-- Test functions and procedures shipped with Euphoria
--

include unittest.e
include file.e
include misc.e

set_test_verbosity(TEST_SHOW_FAILED_ONLY)

sequence cmd
object pwd, oldpwd
cmd = command_line()

for i = 3 to length(cmd) do
	if equal(cmd[i], "-all") then
		set_test_verbosity(TEST_SHOW_ALL)
	elsif equal(cmd[i], "-failed") then
		set_test_verbosity(TEST_SHOW_FAILED_ONLY)
	elsif equal(cmd[i], "-mods") then
		set_test_verbosity(TEST_SHOW_MODULES)
	elsif equal(cmd[i], "-wait") then
		set_wait_on_summary(1)
    end if
end for


-- Ensure we are in correct directory first.
pwd = dirname(cmd[2])
oldpwd = current_dir()
pwd = chdir(pwd)

-- Tests
include t_condcmp.e
include t_datetime.e
--include t_defparms.e
include t_enum.e
include t_euns.e
include t_file.e
--include t_flow.e
include t_get.e
include t_loop.e
include t_map.e
include t_math.e
include t_misc.e
include t_os.e
include t_primes.e
include t_regex.e
include t_search.e
include t_sequence.e
include t_sets.e
include t_sort.e
include t_stack.e  
include t_stats.e
include t_switch.e
include t_types.e
include t_unicode.e
include t_wildcard.e

-- Locale does not work on DOS
ifdef !DOS32 then
	include t_locale.e
end ifdef

test_summary()

oldpwd = chdir(oldpwd)

?machine_func(26,0)
