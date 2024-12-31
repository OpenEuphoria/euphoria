include std/unittest.e

procedure delete_proc(integer x) 
  test_pass(sprintf("deleting %d", {x})) 
end procedure 
 
constant op = delete_routine(1, routine_id("delete_proc")) 
 
switch op do 
  case 1 then
    test_pass("can use delete_routined value as a value for switch")
end switch

switch 1 do 
  case op then
    test_pass("can use delete_routined value as a case constant for switch") 
end switch

test_report()
