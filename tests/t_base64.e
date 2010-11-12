include std/unittest.e

include std/base64.e

sequence result, this

result=encode64("a")
result=decode64(result)
test_equal("1 char conversion",result,"a")

result=encode64("12")
result=decode64(result)
test_equal("2 char conversion",result,"12")

result=encode64("XYZ")
result=decode64(result)
test_equal("3 char conversion",result,"XYZ")

for i = 1 to 57 do
    this=repeat(i,i)
    result=decode64(encode64(this))
    test_equal(sprintf("%d byte conversion",{i}),result,this)
end for
    
test_report()
