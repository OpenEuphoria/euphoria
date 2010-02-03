include std/unittest.e

function abc()
   switch 1 label "abc" do
       case 2 then
           break "abc"
       case 1 then
           break "abc"
   end switch
   return 1
end function

test_equal( "convert FUNC block to PROC block", 1, abc() )

integer llv = 0
integer lly = 0
loop label "loop label" do
	llv += 1
	
	if llv < 5 then
		continue "loop label"
	end if
	lly += 1
	until llv > 10
end loop

test_pass( "don't crash on label for loop" )

test_equal("loop worked", {7, 11}, {lly, llv})

test_report()
