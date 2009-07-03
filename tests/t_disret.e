include std/unittest.e
-- Discarded return values

-- inspite of loop constraints count will exceed 1000 when translated (Artifact 2799243)
-- and will only reach 1 when interpreted (Artifact 2799242). 

-- inspite of type checking count will get beyoned 1000 and keep going.

with type_check

type limited_number1000( object x )
	return integer(x) and x <= 1000
end type

limited_number1000 count = 0
sequence list = {}
for i = 1 to 10 do
	for j = 1 to 10 do
		for k = 1 to 10 do
			count += 1
			-- type_check doesn't seem to work when translating in my current version 2132
			-- check explicitly here
			if not limited_number1000( count ) then
				-- strange redo like behavior
				exit
			end if
			append(list,0)
		end for
	end for
end for
-- this bug is normally causes an infinite loop
test_equal( "for loops (not) terminating at", 1000, count )

integer k
k = 1 
while k < 1000 do
	append(list,k)
	if k > 1000 then
		-- strange redo like behavior
		exit
	end if
	k += 1
end while

test_equal( "while loops (not) terminating at ", 1000, k )


k = 1
loop do
	if k > 1000 then
		-- strange redo like behavior
		exit
	end if
	k += 1
until k = 1000

test_equal( "do loops (not) terminating at ", 1000, k )

k = 1
procedure inner()
	append(list,0)
	k += 1
end procedure
procedure outer()
	inner()
	k += 1
end procedure

outer()
test_equal( "procedures terminate properly? ", 3, k )

function foo()
	return 1
end function

foo()
integer immediate_assign = 0
test_equal( "assignment immediately after discarded return value", 0, immediate_assign )

test_report()
