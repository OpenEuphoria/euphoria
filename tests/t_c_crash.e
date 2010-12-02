include std/unittest.e

include std/error.e

error:crash("This is the crash message: %d", { 10 })

test_fail("should have died with a crash message")

test_report()
