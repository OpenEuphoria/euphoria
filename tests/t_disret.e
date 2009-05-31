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
				test_equal( "for loops terminating", 1000, count )
				test_report()
				abort(1)
			end if
			append(list,0)
		end for
	end for
end for
-- this bug is normally causes an infinite loop
test_equal( "for loops not terminating", 1000, count )
test_report()
