-- warning_file( "warnings_issued.txt" )
type boolean(integer x)
    return x = x * x
end type

global integer foo
-- expect resolution warning here if resolution is enabled {resolution}
include dependency.e

integer a1 = 1
-- expect short-circut warning here if short-circut is enabled {short_circuit}
function increment_a1()
    a1 += 1
    return a1
end function

-- do warn here because increment_a1() has a side-effect
if a1 and increment_a1() then
    -- do nothing
end if

-- do warn here that puts is being overridden {override}
override procedure printf(integer fd, sequence fmt, sequence s)
    --eu:printf(fd, fmt, s)
end procedure

printf(1, "", {})

-- warn about builtin_chosen
puts(1, "")


procedure bar()
    integer unused = 5
end procedure

-- war about not_used
bar()


-- warn about no_value
procedure baz()
    integer no_value
end procedure

baz()

-- warn about useless code {custom}
warning("Useless code")


-- {translator} warning must be issued from the command line arguments : An option was given to the translator, but this option is not recognized as valid for the C compiler being used.

-- {cmdline} is an anachronism

ifdef not LINUX then
-- {mixed_profile} 
with profile_time
with profile
end ifdef

switch 4 without fallthru do
    case 0 then
    -- {empty_case}
    case 1 then
       print(1, "one")
    
    -- no case else {default_case}
end switch


printf(1, "builtin for floor chosen %d=%d", {floor(2), 2})

abort(0)

-- Code {not_reached}
a1 = 1
