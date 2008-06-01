include unittest.e

set_test_module_name("eu-switch")

constant SWITCH = { 1, 2, "a", "sdflkjasdfglkj" }

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
			switch i do
				case 1:
					s &= 1
				case else
					exit "top"
			end switch
		case "a":
			s = append( s, SWITCH[i] )
			exit
		case else
			s = append( s, "what?" )
	end switch
end for

constant 
	CORRECT = { 1, 2, 2, "a", "what?" }

test_equal( "switch", s, CORRECT )

