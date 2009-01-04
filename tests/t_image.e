include std/unittest.e
ifdef DOS then
include std/dos/image.e

test_pass("image.e at least loads")

-- TODO: add real tests

end ifdef

test_report()
