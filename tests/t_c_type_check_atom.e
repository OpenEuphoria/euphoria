include std/unittest.e
with type_check

function seq()
        return {10,20,30}
end function

constant aSequence = seq()

atom aAtom = aSequence

test_fail("should not be able to assign a sequence to an atom")

test_report()
