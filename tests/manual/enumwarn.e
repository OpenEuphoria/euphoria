-- warn about mismatched enums
-- how to test:
-- run this program with an alternative literals branch build or interpreted interpreter.  While you do so capture the standard out and standard error output to a file or the clipboard in Windows.  On Windows, make a really wide console Window.
-- Then use a diff like program to compare the results with this file.
-- The indicated output below should be common to the output of the program.

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

type enum boolean
	TRUE,
	FALSE
end type

function good_result(status s, button_type t, boolean b)
	return s = ID_OK and b
end function

procedure check_result(status s, button_type t, boolean b)
	object void
	void = good_result(s,t,b)
end procedure

status s888999 = ID_OK
button_type t = MB_OK

-- warns here
-- assigning a button type to a status
t = s888999

-- warns here
-- comparing a button_type to a status
if equal(MB_OKCANCEL,s888999) then
end if

-- warns here
-- comparing a button_type to a status
if compare(MB_OKCANCELRETRY,ID_CANCEL) then
end if

-- warns here
-- comparing a button_type to a status
? MB_OKCANCELRETRY < ID_RETRY

-- warns here
-- comparing a button_type to a status
? t = s888999

-- warns here
-- assigning a status to a button_type
t = ID_OK 

-- warns here                             : first argument should be a status not a button_type
--                                    also: second argument should be a button type not a boolean
--                             and finally: third argument should be a boolean not a button_type
-- spec parameters  : status, button_type, boolean
-- passed parameters: button_type, boolean, button_type
? good_result( MB_OK, TRUE, MB_OKCANCEL )

-- warns here                             : first argument should be a status not a button type
-- spec parameters  : status, button_type, boolean
-- passed parameters: button_type, button_type, boolean
check_result( MB_OK, MB_OKCANCELRETRY, FALSE )

-- Now cases with "forward referencing" (delayed resolution)
include ../enum_type.e

public architecture z = ARM
-- warns here
-- assigning an architecture to a status
s888999 = ARM

-- warns here
-- assigning an architecture to a status
t = y

-- warns here
-- comparing an architecture to a status
if equal(X86_64,s888999) then
end if

-- warns here
-- comparing a button_type to an architecture
if compare(MB_OKCANCELRETRY,z) then
end if

-- warns here
-- comparing a button_type to an architecture
? MB_OKCANCELRETRY < X86

-- warns here
-- comparing a button_type to an architecture
? t = z

-- warns here
-- assigning a status to an architecture
z = ID_OK 

-- warns here                             : third argument should be a boolean not an architecture
-- spec parameters  : status, button_type, boolean
-- passed parameters: status, boolean, architecture
? good_result( ID_OK, MB_OK, X86 )

-- warns here                             : first argument should be a status not an architecture
-- spec parameters  : status, button_type, boolean
-- passed parameters: button_type, button_type, boolean
check_result( ARM, MB_OKCANCELRETRY, FALSE )


/** 
Output should be:

0
1
1
Warning { literal_mismatch }:
    <0607>:: The two values have different associated literal sets: s888999 is of type status but t is of type button_type.
Warning { literal_mismatch }:
    <0607>:: The two values have different associated literal sets: s888999 is of type status but MB_OKCANCEL is of type button_type.
Warning { literal_mismatch }:
    <0607>:: The two values have different associated literal sets: ID_CANCEL is of type status but MB_OKCANCELRETRY is of type button_type.
Warning { literal_mismatch }:
    <0607>:: The two values have different associated literal sets: MB_OKCANCELRETRY is of type button_type but ID_RETRY is of type status.
Warning { literal_mismatch }:
    <0607>:: The two values have different associated literal sets: t is of type button_type but s888999 is of type status.
Warning { literal_mismatch }:
    <0607>:: The two values have different associated literal sets: ID_OK is of type status but t is of type button_type.
Warning { literal_mismatch }:
    <0608>:: The value passed to good_result as parameter 1 has different associated literal set than what is expected: It is a button_type and should be a status.
Warning { literal_mismatch }:
    <0608>:: The value passed to good_result as parameter 2 has different associated literal set than what is expected: It is a boolean and should be a button_type.
Warning { literal_mismatch }:
    <0608>:: The value passed to good_result as parameter 3 has different associated literal set than what is expected: It is a button_type and should be a boolean.
Warning { literal_mismatch }:
    <0608>:: The value passed to check_result as parameter 1 has different associated literal set than what is expected: It is a button_type and should be a status.
Warning { literal_mismatch }:
    <0607>:: The two values have different associated literal sets: ARM is of type architecture but s888999 is of type status.
Warning { literal_mismatch }:
    <0607>:: The two values have different associated literal sets: y is of type architecture but t is of type button_type.
Warning { literal_mismatch }:
    <0607>:: The two values have different associated literal sets: s888999 is of type status but X86_64 is of type architecture.
Warning { literal_mismatch }:
    <0607>:: The two values have different associated literal sets: X86 is of type architecture but MB_OKCANCELRETRY is of type button_type.
Warning { literal_mismatch }:
    <0607>:: The two values have different associated literal sets: MB_OKCANCELRETRY is of type button_type but X86 is of type architecture.
Warning { literal_mismatch }:
    <0607>:: The two values have different associated literal sets: t is of type button_type but X86_64 is of type architecture.
Warning { literal_mismatch }:
    <0607>:: The two values have different associated literal sets: ID_OK is of type status but y is of type architecture.
Warning { literal_mismatch }:
    <0608>:: The value passed to good_result as parameter 3 has different associated literal set than what is expected: It is a architecture and should be a boolean.
Warning { literal_mismatch }:
    <0608>:: The value passed to check_result as parameter 1 has different associated literal set than what is expected: It is a architecture and should be a status.

**/
