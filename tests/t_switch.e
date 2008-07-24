include std/unittest.e

constant SWITCH = { 1, 2, "a", 3, "sdflkjasdfglkj" }

sequence s
s = {}
for i = 1 to length( SWITCH ) label "top" do
	switch SWITCH[i] do
		case 1:
			s = append( s, SWITCH[1] )
		case 2:
			s = append( s, SWITCH[2] )
			break
			
		case 3:
			switch i - 3 do
				case 1:
					s &= 3
					break
					
				case else
					exit "top"
			end switch
			break
			
		case "a":
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
    case C:
        ns = 1
        break
    case B:
    	switch pB do
    		case C:
        		ns = 2
        		break
        		
    		case B:
        		ns = 5
        		break
    		case A:
        		ns = 6
        		break
        end switch
        break
    case A:
        ns = 3
        break
end switch
end procedure
nst(B,A)
test_equal( "nested switch", 6, ns )

constant cases = - {1, "345", 2, 3}
constant TWO = 2, NEGATIVE_3 = -3
sequence negative_case = {}
for i = 1 to length( cases ) do
	switch cases[i] do
		case -1:
			negative_case = append( negative_case,-1 )
			break
		case -"345":
			negative_case = append( negative_case, -"345" )
			break
		case -TWO:
			negative_case = append( negative_case, -TWO )
			break
		case NEGATIVE_3:
			negative_case = append( negative_case, NEGATIVE_3 )
			break
	end switch
end for

test_equal( "switch with negative cases",  cases, negative_case )

integer static_int
switch 2 do
	case 2:
		static_int = 2
		break
	case else
		static_int = 1
end switch
test_equal( "static int", 2, static_int )

integer z = 0
switch "foo" do
	case 1:
		z = 1
		break
	case else
		z = 2
end switch
test_equal( "int cases, sequence switch with else", 2, z )

function int_switch1( object cond )
	integer ret = 0
	switch cond do
		case 1:
			ret = 1
			break
		case 2:
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
		case 1:
			ret = 1
			break
		case 2:
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
		case 1:
			ret = 1
			break
		case 2:
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
		case 1:
			ret = 1
			break
		case 2:
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
		case 1:
		label "foo"
			ret = 1
			break
		case 2:
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
		case 1:
		label "foo"
			ret = 1
			break
		case 2:
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


test_report()

