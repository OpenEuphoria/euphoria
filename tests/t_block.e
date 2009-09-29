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

loop label "loop label" do

until 1
test_pass( "don't crash on label for loop" )

test_report()
