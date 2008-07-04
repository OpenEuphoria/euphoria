include unittest.e

ifdef NOT_DEFINED then
	procedure abc()
		integer a
		a = 10
	end procedure

	procedure def()
		integer a
		a = 10
	end procedure
else
	procedure abc()
		integer a
		a = 10
	end procedure

	procedure def()
		integer a
		a = 10
	end procedure
end ifdef

integer n=1
ifdef NOT_DEFINED then
	if n=1 then n=2 end if
else
	n=0
end ifdef
test_equal("Format of ifdef code",0,n)


function recursion1( sequence x, integer level=1 )
ifdef DONT_DEFINE_FOO then
	return 0
else
	integer count
	integer foo
	count = 0
	for i = 1 to length(x) do
		if sequence(x[i]) then
			foo = recursion1( x[i], level + 1 )
		end if
		count += 1
	end for
	return count
end ifdef
end function

function recursion2( sequence x, integer level=1 )
	integer count
	integer foo
	count = 0
	for i = 1 to length(x) do
		if sequence(x[i]) then
			foo = recursion1( x[i], level + 1 )
		end if
		count += 1
	end for
	return count
end function

test_equal( "ifdef at beginning of function breaks recursion", recursion2({"one","two"}), recursion1({"one","two"}) )

test_report()

