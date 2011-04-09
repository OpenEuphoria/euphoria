-- t_flags.e
include std/unittest.e
include std/flags.e
sequence test_data
test_data = {
	{#00000000, "WS_OVERLAPPED"},
	{#80000000, "WS_POPUP"},
	{#40000000, "WS_CHILD"},
	{#20000000, "WS_MINIMIZE"},
	{#10000000, "WS_VISIBLE"},
	{#08000000, "WS_DISABLED"},
	{#44000000, "WS_CLIPPINGCHILD"},
	{#04000000, "WS_CLIPSIBLINGS"},
	{#02000000, "WS_CLIPCHILDREN"},
	{#01000000, "WS_MAXIMIZE"},
	{#00C00000, "WS_CAPTION"},
	{#00800000, "WS_BORDER"},
	{#00400000, "WS_DLGFRAME"},
	{#00100000, "WS_HSCROLL"},
	{#00200000, "WS_VSCROLL"},
	{#00080000, "WS_SYSMENU"},
	{#00040000, "WS_THICKFRAME"},
	{#00020000, "WS_MINIMIZEBOX"},
	{#00010000, "WS_MAXIMIZEBOX"},
	{#00300000, "WS_SCROLLBARS"},
	{#00CF0000, "WS_OVERLAPPEDWINDOW"},
	$
}

test_equal("single bit not expanded",    {"WS_POPUP"}, flags_to_string( #80000000, test_data))
test_equal("single bit expanded",        {"WS_POPUP"}, flags_to_string( #80000000, test_data, 1))
test_equal("multiple bits not expanded", {"WS_CAPTION"}, flags_to_string( #00C00000, test_data))
test_equal("multiple bits expanded",     {"WS_BORDER","WS_DLGFRAME"}, flags_to_string( #00C00000, test_data, 1))
test_equal("ZERO not expanded",          {"WS_OVERLAPPED"}, flags_to_string( 0, test_data))
test_equal("ZERO expanded",              {"WS_OVERLAPPED"}, flags_to_string( 0, test_data, 1))
test_equal("Unknown not expanded",       {"?"}, flags_to_string( 1, test_data))
test_equal("Unknown expanded",           {"?"}, flags_to_string( 1, test_data, 1))
test_equal("List of values not expanded",{{"WS_OVERLAPPEDWINDOW"},{"?"},{"WS_OVERLAPPED"},{"?"}} , flags_to_string( {#0CF0000,9,0, "nested"}, test_data))
test_equal("List of values expanded",    {{"WS_BORDER","WS_DLGFRAME","WS_SYSMENU","WS_THICKFRAME","WS_MINIMIZEBOX","WS_MAXIMIZEBOX"},{"?"},{"WS_OVERLAPPED"},{"?"}}, flags_to_string( {#0CF0000,9,0, "nested"}, test_data, 1))

test_report()
