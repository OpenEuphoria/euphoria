-- A similar counter test file is t_c_ns_builtin.e
-- A similar counter test file is t_c_scope_local_include.e
namespace fail
include std/unittest.e

fail:puts(1, 1)

test_fail("resolved file-qualified procedure to predefined routine")
test_report()
