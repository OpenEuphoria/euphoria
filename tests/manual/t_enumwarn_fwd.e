-- warn about mismatched enums
-- how to test:
-- run this program with an alternative literals branch build or interpreted interpreter.  While you do so capture the standard out and standard error output to a file or the clipboard in Windows.  On Windows, make a really wide console Window.
-- Then use a diff like program to compare the results with this file.
-- The indicated output below should be common to the output of the program.

without inline
with warning += {literal_mismatch}

procedure check_result(status s, button_type t, boolean b)
	object void
	void = good_result(s,t,b)
end procedure

-- Now cases with "forward referencing" (delayed resolution)
include ../enum_type.e
include enum_type_fwd.e

-- assigning an architecture to an architecture
-- well, this one is okay. ;)
public architecture z = ARM

-- warns here
-- assigning an architecture to a status
status s888999 = ARM

-- warns here
-- assigning an architecture to a status
button_type t = y

-- didn't warn here but it does now.
-- comparing an architecture to a status
if equal(s888999,X86_64) then
end if

-- didn't warn here but it does now.
-- comparing a button_type to an architecture
if compare(MB_OKCANCELRETRY,z) then
end if

-- warns here
-- comparing a button_type to an architecture
if MB_OKCANCELRETRY < X86 then
end if

-- didn't warn here but it does now.
-- comparing a button_type to an architecture
if t = z then
end if

-- didn't warn here but it does now.
-- assigning a status to an architecture
z = ID_OK 

-- does not warn here but should          : third argument should be a boolean not an architecture
-- spec parameters  : status, button_type, boolean
-- passed parameters: status, boolean, architecture
good_result( ID_OK, MB_OK, X86 )

-- warns here                             : first argument should be a status not an architecture
-- spec parameters  : status,       button_type, boolean
-- passed parameters: architecture, button_type, boolean
check_result( ARM, MB_OKCANCELRETRY, FALSE )




/** 
Output should be:

Warning { literal_mismatch }:
    <0607>:: The two values have different associated literal sets: ARM is of type architecture but s888999 is of type status.
Warning { literal_mismatch }:
    <0607>:: The two values have different associated literal sets: y is of type architecture but t is of type button_type.
Warning { literal_mismatch }:
    <0607>:: The two values have different associated literal sets: s888999 is of type status but X86_64 is of type architecture.
Warning { literal_mismatch }:
    <0607>:: The two values have different associated literal sets: MB_OKCANCELRETRY is of type button_type but z is of type architecture.
Warning { literal_mismatch }:
    <0607>:: The two values have different associated literal sets: MB_OKCANCELRETRY is of type button_type but X86 is of type architecture.
Warning { literal_mismatch }:
    <0607>:: The two values have different associated literal sets: t is of type button_type but z is of type architecture.
Warning { literal_mismatch }:
    <0607>:: The two values have different associated literal sets: ID_OK is of type status but z is of type architecture.
Warning { literal_mismatch }:
    <0608>:: The value passed to good_result as parameter 3 has different associated literal set than what is expected: It is a architecture and should be a boolean.
Warning { literal_mismatch }:
    <0608>:: The value passed to check_result as parameter 1 has different associated literal set than what is expected: It is a architecture and should be a status.
**/
