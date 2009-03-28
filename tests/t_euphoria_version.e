include std/unittest.e
include euphoria/version.e

test_true("version #1", version() >= 400)
test_true("version_major #1", version_major() >= 4)
test_true("version_minor #1", version_minor() >= 0)
test_true("version_patch #1", version_patch() >= 0)
test_true("version_type #1", sequence(version_type()))
test_true("version_type #2", length(version_type()) > 0)
test_true("version_string #1", sequence(version_string()))
test_true("version_string #2", length(version_string()) > 0)
test_true("version_string_short #1", sequence(version_string_short()))
test_true("version_string_short #2", length(version_string_short()) > 0)
test_true("version_string_long #1", sequence(version_string_long()))
test_true("version_string_long #2", length(version_string_long()) > 0)

