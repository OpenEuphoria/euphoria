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
			exit
			
		case 3:
			switch i - 3 do
				case 1:
					s &= 3
					exit
					
				case else
					exit "top"
			end switch
			exit
			
		case "a":
			s = append( s, SWITCH[i] )
			exit
			
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

test_embedded_report()

