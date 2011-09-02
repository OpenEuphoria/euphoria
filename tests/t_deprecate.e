include std/unittest.e

deprecate procedure hi()
    printf(1, "Hi\n", {})
end procedure

test_pass("deprecate keyword assigned to a procedure")

deprecate public procedure hi2()
    printf(1, "Hi2\n", {})
end procedure

test_pass("deprecate keyword assigned to a public procedure")

test_report()
