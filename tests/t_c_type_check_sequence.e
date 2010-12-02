include std/unittest.e
with type_check

function atm()
        return 30.5
end function

constant aAtom = atm()

sequence aSequence = aAtom

test_fail("should not be able to assign an atom to a sequence")

test_report()
