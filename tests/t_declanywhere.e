include std/unittest.e

function foo()
	integer bar = 1
	if bar then
		bar = 0
	end if
	
	sequence hello = "hello world"
	return hello
end function

function if_in_routine( integer start )
	start += 1
	
	integer x1 = 2
	start += x1
	if start > x1 then
		integer x2 = 1
		start += x2
		if start < x2 then
			integer x3 = 5
		else
			integer x3 = x2 + x1
			start += x3
		end if
	elsif start = 0 then
		integer x2 = 0
		start *= x2
	else
		integer x2 = 4
		start -= x2
	end if
	
	return start
end function

integer if_at_top_level = 1
if if_at_top_level = 1 then
	integer x1 = 1
	if_at_top_level += x1
	if x1 > if_at_top_level then
		integer x2 = if_at_top_level
		if_at_top_level += x2
	else
		integer x2 = -if_at_top_level
		if_at_top_level += x2
	end if
elsif if_at_top_level = 0 then
	integer x1 = 0
	if_at_top_level *= x1
else
	integer x1 = 4
	if_at_top_level -= x1
end if

function for_in_routine( integer start )
	for i = 1 to 3 do
		integer x1
		x1 = i
		for j = 1 to x1 do
			integer x2 = i
			start += x1 + x2
		end for
	end for
	return start
end function

integer for_at_top_level = 1
for i = 1 to 3 do
	integer x1
	x1 = i
	for j = 1 to x1 do
		integer x2 = i
		for_at_top_level += x1 + x2
	end for
end for

function while_in_routine( integer start )
	while start < 4 do
		integer x1
		x1 = start
		while x1 do
			integer x2 = start
			start += x2
			x1 -= 1
		end while
	end while
	return start
end function

integer while_at_top_level = 1
while while_at_top_level < 4 do
	integer x1
	x1 = while_at_top_level
	while x1 do
		integer x2 = while_at_top_level
		while_at_top_level += x2
		x1 -= 1
	end while
end while

-- TODO: Test for switch statement

test_equal( "declare variable anywhere at top level of routine", "hello world", foo() )
test_equal( "declare inside if in a routine", 8, if_in_routine( 1 ) )
test_equal( "declare inside if at top level", 0, if_at_top_level )
test_equal( "declare inside for in a routine", 29, for_in_routine( 1 ) )
test_equal( "declare inside for at top level", 29, for_at_top_level )
test_equal( "declare inside while in a routine", 8, while_in_routine( 1 ) )
test_equal( "declare inside while at top level", 8, while_at_top_level )
test_report()
