public type enum status 
	ID_OK,
	ID_CANCEL,
	ID_RETRY
end type

export type enum button_type
	MB_OK,
	MB_OKCANCEL,
	MB_OKCANCELRETRY
end type

global type enum boolean
	TRUE,
	FALSE
end type

public function good_result(status s, button_type t, boolean b)
	return s = ID_OK and b
end function


