include std/unittest.e

enum type numbers
   one,
   two,
   three = two + one,
   four = three + one
end type

switch 3 do
  case one then
    puts(1, "one")
  case two then 
    puts(1, "two")
  case three then
    puts(1, "three")
end switch

test_pass("type enum expressions")
test_report()
