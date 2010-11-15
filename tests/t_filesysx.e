include std/unittest.e

ifdef WIN32 then
	include std/win32/filesysx.e
end ifdef

test_equal( "C:\\ drive serial", 1, equal(get_vol_serial(), get_vol_serial('C')) )

test_report()
