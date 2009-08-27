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

test_report()
