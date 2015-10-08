include std/math.e  
include std/convert.e 

function Bin(integer n, sequence s = "") 
  if n > 0 then 
   return Bin(floor(n/2),(mod(n,2) + #30) & s) 
  end if 
  if length(s) = 0 then 
   return to_integer("0") 
  end if 
  return to_integer(s) 
end function 

include std/unittest.e

test_equal("Bin(0) = '0'", "0", sprintf("%d", Bin(0)))
test_equal("Bin(5) = '5'", "101", sprintf("%d", Bin(5)))
test_equal("Bin(50) = '110010'", "110010", sprintf("%d", Bin(50)))
test_equal("Bin(9000) = '10001100101000'", "10001100101000", sprintf("%d", Bin(9000)))

test_report()
