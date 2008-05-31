include bar_export.e
export include baz_export.e

export function export_test()
	return "foo"
end function

export constant EXPORT_CONSTANT = "foo"
