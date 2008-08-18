include bar_export.e
public include baz_export.e

export function export_test()
	return "foo"
end function

public constant EXPORT_CONSTANT = "foo"
