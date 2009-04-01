include std/unittest.e
without warning

integer nx = 1
--switch nx do
--end switch

--test_true("case-less switch", nx = 1)

switch nx do
   case 1
      nx = 2
      break
   case 2
      nx = 3
      break
end switch

test_true("colon-less switch", nx = 2)

constant SWITCH = { 1, 2, "a", 3, "sdflkjasdfglkj" }

sequence s
s = {}
for i = 1 to length( SWITCH ) label "top" do
	switch SWITCH[i] do
		case 1 then
			s = append( s, SWITCH[1] )
		case 2 then
			s = append( s, SWITCH[2] )
			break
			
		case 3 then
			switch i - 3 do
				case 1 then
					s &= 3
					break
					
				case else
					exit "top"
			end switch
			break
			
		case "a" then
			s = append( s, SWITCH[i] )
			break
			
		case else
			s = append( s, "what?" )
	end switch
end for

integer zero
zero = 0
switch 1 do
	case 0:
		zero = 1
end switch
constant 
	CORRECT = { 1, 2, 2, "a", 3, "what?" }

test_equal( "switch", CORRECT, s )
test_false( "no matching case", zero )


integer ns = 0
enum A,B,C
procedure nst(object pA, object pB = -1)
switch pA do
    case C then
        ns = 1
        break
    case B then
    	switch pB do
    		case C then
        		ns = 2
        		break
        		
    		case B then
        		ns = 5
        		break
    		case A then
        		ns = 6
        		break
        end switch
        break
    case A then
        ns = 3
        break
end switch
end procedure
nst(B,A)
test_equal( "nested switch", 6, ns )

constant cases = - {1, "345", 2, C}
constant TWO = 2, NEGATIVE_3 = -3
sequence negative_case = {}
for i = 1 to length( cases ) do
	switch cases[i] do
		case -1 then
			negative_case = append( negative_case,-1 )
			break
		case -"345" then
			negative_case = append( negative_case, -"345" )
			break
		case -TWO then
			negative_case = append( negative_case, -TWO )
			break
		case NEGATIVE_3 then
			negative_case = append( negative_case, NEGATIVE_3 )
			break
	end switch
end for

test_equal( "switch with negative cases",  cases, negative_case )

integer static_int
switch 2 do
	case 2 then
		static_int = 2
		break
	case else
		static_int = 1
end switch
test_equal( "static int", 2, static_int )

integer z = 0
switch "foo" do
	case 1 then
		z = 1
		break
	case else
		z = 2
end switch
test_equal( "int cases, sequence switch with else", 2, z )

function int_switch1( object cond )
	integer ret = 0
	switch cond do
		case 1 then
			ret = 1
			break
		case 2 then
			ret = 2
			break
		case else
			ret = 3
	end switch
	return ret
end function

z = int_switch1( 1 )
test_equal( "int_switch1( 1 )", 1, z )

z = int_switch1( "foo" )
test_equal( "int_switch1( \"foo\" )", 3, z )

function int_switch2( object cond )
	integer ret = 0
	switch cond do
		case 1 then
			ret = 1
			break
		case 2 then
			ret = 2
			break
		case else
			ret = 3
	end switch
	return ret
end function

z = int_switch2( "foo" )
test_equal( "int_switch2 -- check for sequence optimization with case else", 3, z )

function int_switch3( object cond )
	integer ret = 0
	switch cond do
		case 1 then
			ret = 1
			break
		case 2 then
			ret = 2
			break
	end switch
	return ret
end function

z = int_switch3( "foo" )
test_equal( "int_switch3 -- check for sequence optimization without case else", 0, z )

function int_switch4( object cond )
	integer ret = 0
	switch cond do
		case 1 then
			ret = 1
			break
		case 2 then
			ret = 2
			break
	end switch
	return ret
end function

z = int_switch4( "foo" )
integer is4rid = routine_id("int_switch4" )
z = call_func( is4rid, {1} )
test_equal( "int_switch4 -- detect integer cond through r_id", 1, z )

function int_switch5( object cond )
	integer ret = 0
	goto "foo"
	switch cond do
		case 1 then
		label "foo"
			ret = 1
			break
		case 2 then
			ret = 2
			break
	end switch
	return ret
end function

z = int_switch5( "foo" )
test_equal( "int_switch5: goto label exists (forward goto), don't optimize away because of sequence", 1, z )

function int_switch6( object cond )
	integer ret = 0
	
	switch cond do
		case 1 then
		label "foo"
			ret = 1
			break
		case 2 then
			ret = 2
			break
	end switch
	if not ret then
		goto "foo"
	end if
	return ret
end function
z = int_switch6( "foo" )
test_equal( "int_switch6: goto label exists (backward goto), don't optimize away because of sequence", 1, z )

function make_D()
	return 3
end function

constant 
	D = make_D(),
	E = {1,2,"3"}

function rt_int_switch( object x )
	switch x do
		case A then
			return A
		case D then
			return D
		case else
			return "else"
	end switch
end function

function rt_switch( object x )
	switch x do
		case D then
			return D
		case E then
			return E
		case else
			return "else"
	end switch
end function

test_equal( "rt int switch #1", D, rt_int_switch( D ) )
test_equal( "rt int switch #2", A, rt_int_switch( A ) )
test_equal( "rt int switch #3", "else", rt_int_switch( 0 ) )
test_equal( "rt int switch #4", "else", rt_int_switch( "" ) )

test_equal( "rt switch #1", D, rt_switch( D ) )
test_equal( "rt switch #2", E, rt_switch( E ) )
test_equal( "rt switch #3", "else", rt_switch( 0 ) )
test_equal( "rt switch #4", "else", rt_switch( "" ) )



function s_w_f( object x )
	sequence y = {}
	switch x with fallthru do
		case 1 then
			y &=  1
		case 2, 3 then
			y &=  2
		case else
			y &= 4
	end switch
	return y
end function

test_equal("swith with fallthru 1", {1,2,4}, s_w_f( 1 ) )
test_equal("swith with fallthru 2", {2,4}, s_w_f( 2 ) )
test_equal("swith with fallthru 3", {2,4}, s_w_f( 3 ) )
test_equal("swith with fallthru 4", {4}, s_w_f( 4 ) )

function s_wo_f( object x )
	sequence y = {}
	switch x without fallthru do
		case 5 then
			y &= 6
			fallthru
		case 1 then
			y &=  1
		case 2, 3 then
			y &=  2
		
		case else
			y &=  4
	end switch
	return y
end function


test_equal("swith without fallthru 1", {1}, s_wo_f( 1 ) )
test_equal("swith without fallthru 2", {2}, s_wo_f( 2 ) )
test_equal("swith without fallthru 3", {2}, s_wo_f( 3 ) )
test_equal("swith without fallthru 4", {4}, s_wo_f( 4 ) )
test_equal("swith without fallthru 5", {6, 1}, s_wo_f( 5 ) )

test_report()

