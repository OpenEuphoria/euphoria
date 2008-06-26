include unittest.e

ifdef WIN32 then
	include msgbox.e
end ifdef

test_pass("msgbox.e at least loads")

test_report()
