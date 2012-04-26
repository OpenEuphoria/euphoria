namespace defparams

include std/unittest.e

sequence s s={1,2,3}

function f(object x)
return x
end function

function incr(object x,integer n=f(9))
return x+n
end function

function incr2(object x,integer n=length(s))
return x+n
end function

integer n1
n1=3
integer n0
n0=n1

function mul2(integer x,integer y)
return x*y
end function

function mul3(integer p=n0,object x,object y=incr(s))
return x*y+p
end function

function foo( object a=10, object b=20, object c=30, object d = 40 )
	return a & b & c & d
end function

function foo2( object a=10, object b=0)
	return a & b 
end function

function foo3( object a=10, object b=20)
	return a & b 
end function

test_equal("2nd arg defaulted to function", 13, incr(4))
test_equal("No defaults", 7, incr(2,5))
test_equal("2nd arg defaulted to builtin", 1, incr2(-2))
test_equal("1st arg defaulted, but explicit",14,mul3(2,3,4))
test_equal("1st arg defaulted,functional defaulted arg explicit",9,mul3(,2,3))
test_equal("Recursive defaulting",{32,35,38},mul3(2,3))
test_equal("- - - -", {10,20,30,40}, foo() )
test_equal("1 - - -", {1,20,30,40}, foo(1) )
test_equal("1 - 1 -", {1,20,1,40}, foo(1,,1) )
test_equal("1 ? 1 -", {1,20,1,40}, foo(1,?,1) )
test_equal("1 ? 1 ?", {1,20,1,40}, foo(1,?,1,?) )
test_equal("- - - 1", {10,20,30,1}, foo(,,,1) )
test_equal("? ? ? 1", {10,20,30,1}, foo(?,?,?,1) )
test_equal("1 - - -21", {1,20,30,-21}, foo(1,,,-21) )
test_equal("1 1 1 1", {1,1,1,1}, foo(1,1,1,1) )
test_equal(", , , ,", {10,20,30,40}, foo(,,,) )
test_equal("? ? ? ?", {10,20,30,40}, foo(?,?,?,?) )
test_equal("1 , , ,", {1,20,30,40}, foo(1,,,) )
test_equal("1 ? ? ?", {1,20,30,40}, foo(1,?,?,?) )
test_equal("1 ? - ?", {1,20,30,40}, foo(1,?,,?) )

test_equal("foo2(, 1)", {10,1}, foo2(,1) )
test_equal("foo2(, -1)", {10,-1}, foo2(,-1) )
test_equal("foo2(1,)", {1,0}, foo2(1) )
test_equal("foo2(-1,)", {-1,0}, foo2(-1) )

test_equal("foo3(, 1)", {10,1}, foo3(,1) )
test_equal("foo3(, -1)", {10,-1}, foo3(,-1) )
test_equal("foo3(1,)", {1,20}, foo3(1) )
test_equal("foo3(-1,)", {-1,20}, foo3(-1) )


test_equal("default call as part of compound expression", 2, mul2(1,1) + mul2(1,1) )

include std/sequence.e
function find2(object x,sequence s,integer from=1,integer upto=length(s))
	s=head(s,upto)
	if from=1 then
		return find(x,s)
	else
		return upto
	end if
end function
test_equal("Use parameters of function to set default values #1",3,find2('h',"John Doe"))
test_equal("Use parameters of function to set default values #2",8,find2('h',"John Doe",2))

function f1(sequence s0=s)
	return length(s0)
end function

function f2(sequence s,integer n=f1())
	return n
end function
test_equal("Indirect reference to parameter",5,f2("abcde"))

include unknown_defparm.e
test_equal("Default parameter relays knwn symbols #1", 3, unk_foo())

function nested_functions_in_default_param( sequence a, sequence b = repeat(a,(length(a)))) 
	return { a, b }
end function
test_equal( "nested functions in default parameters",{"ab" ,{"ab","ab" }} , nested_functions_in_default_param("ab"))

s = "abc"
function t_563( sequence a = s )
	return a
end function

include defparam1.e
procedure test_563()
	sequence s = "def"
	test_equal( "resolve default parameter in its parsing context", defparams:s, t_563() )
	test_equal( "resolve default parameters as forward references from their parsing contexts",
				3, defparams() )
end procedure
test_563()

test_report()

