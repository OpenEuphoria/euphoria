include unittest.e

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
    case A:
        ns = 1
        break
    case B:
    	switch pB do
    		case A:
        		ns = 2
        		break
        		
    		case B:
        		ns = 5
        		break
    		case C:
        		ns = 6
        		break
        end switch
        break
    case C:
        ns = 3
        break
end switch
end procedure
nst(B,A)
test_equal( "nested switch", 2, ns )


test_embedded_report()

