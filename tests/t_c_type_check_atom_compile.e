include std/unittest.e
with type_check

constant aSequence = ""

-- this should generate a compile error
atom aAtom = aSequence

test_fail("should not be able to assign a sequence to an atom")

test_report()
