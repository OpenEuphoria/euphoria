-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
-- Euphoria 3.2
-- Test functions and procedures shipped with Euphoria
include unittest.e
include file.e

set_test_verbosity(TEST_SHOW_FAILED_ONLY)

sequence cmd
object pwd, oldpwd
cmd = command_line()

if length(cmd) > 2 then
    if equal(cmd[3], "-all") then
	set_test_verbosity(TEST_SHOW_ALL)
    elsif equal(cmd[3], "-failed") then
	set_test_verbosity(TEST_SHOW_FAILED_ONLY)
    elsif equal(cmd[3], "-mods") then
        set_test_verbosity(TEST_SHOW_MODULES)
    end if
end if


-- Ensure we are in correct directory first.
pwd = dirname(cmd[2])
oldpwd = current_dir()
pwd = chdir(pwd)


-- Tests
include t_condcmp.e
include t_datetime.e
include t_enum.e
include t_euns.e
include t_file.e
include t_flow.e
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
include t_sets.e
include t_sort.e
include t_stack.e  
include t_types.e
include t_unicode.e
include t_wildcard.e
           
test_summary()

oldpwd = chdir(oldpwd)
