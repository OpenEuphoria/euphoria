include std/unittest.e

ifdef WINDOWS then
	include std/win32/msgbox.e
end ifdef

test_pass("msgbox.e at least loads")

test_report()
