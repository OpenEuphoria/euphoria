-- warn about mismatched enums
without inline
with warning += {literal_mismatch}
type enum status 
	ID_OK,
	ID_CANCEL,
	ID_RETRY
end type

type enum button_type
	MB_OK,
	MB_OKCANCEL,
	MB_OKCANCELRETRY
end type

function good_result(status s, button_type t)
	return s = ID_OK
end function

procedure check_result(status s, button_type t)
	object void
	void = good_result(s,t)
end procedure

status s888999 = ID_OK
button_type t = MB_OK

-- warns here
t = s888999

-- warns here
if equal(MB_OKCANCEL,s888999) then
end if

-- warns here
if compare(MB_OKCANCELRETRY,ID_CANCEL) then
end if

-- warns here
? MB_OKCANCELRETRY < ID_RETRY

-- warns here
? t = s888999

-- warns here
t = ID_OK 

-- ? good_result( ID_OK ) -- good

-- should warn here but doesn't yet: first argument should be a status not a button type
? good_result( MB_OK, MB_OKCANCEL )

-- should warn here but doesn't yet: first argument should be a status not a button type
check_result( MB_OK, MB_OKCANCELRETRY )
/** 
Output should be:

0
1
1
Warning { literal_mismatch }:
    <0362>:: The two values have different associated literal sets: s888999 is of type status but t is of type button_type.
Warning { literal_mismatch }:
    <0362>:: The two values have different associated literal sets: s888999 is of type status but MB_OKCANCEL is of type button_type.
Warning { literal_mismatch }:
    <0362>:: The two values have different associated literal sets: ID_CANCEL is of type status but MB_OKCANCELRETRY is of type button_type.
Warning { literal_mismatch }:
    <0362>:: The two values have different associated literal sets: MB_OKCANCELRETRY is of type button_type but ID_RETRY is of type status.
Warning { literal_mismatch }:
    <0362>:: The two values have different associated literal sets: t is of type button_type but s888999 is of type status.
Warning { literal_mismatch }:
    <0362>:: The two values have different associated literal sets: ID_OK is of type status but t is of type button_type.
Warning { literal_mismatch }:
    <0362>:: The two values have different associated literal sets: argument 1 of good_result is of type status but MB_OK is of type button_type.

**/
