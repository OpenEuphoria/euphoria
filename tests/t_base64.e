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
    
sequence msg = "OpenEuphoria is a great\r\nprogramming language that\r\nis open source."
sequence encoded = "T3BlbkV1cGhvcmlhIGlzIGEgZ3JlYXQNCnByb2dyYW1taW5nIGxhbmd1YWdlIHRoYXQNCmlzIG9wZW4gc291cmNlLg=="

test_equal("open euph msg encode", encoded, encode64(msg))
test_equal("open euph msg decode", msg, decode64(encoded))

sequence msg2 = "Man is distinguished, not only by his reason, but by this singular passion from other animals, which is a lust of the mind, that by a perseverance of delight in the continued and indefatigable generation of knowledge, exceeds the short vehemence of any carnal pleasure."

sequence encoded2 = "TWFuIGlzIGRpc3Rpbmd1aXNoZWQsIG5vdCBvbmx5IGJ5IGhpcyByZWFzb24sIGJ1dCBieSB0aGlz" &
    "IHNpbmd1bGFyIHBhc3Npb24gZnJvbSBvdGhlciBhbmltYWxzLCB3aGljaCBpcyBhIGx1c3Qgb2Yg" &
    "dGhlIG1pbmQsIHRoYXQgYnkgYSBwZXJzZXZlcmFuY2Ugb2YgZGVsaWdodCBpbiB0aGUgY29udGlu" &
    "dWVkIGFuZCBpbmRlZmF0aWdhYmxlIGdlbmVyYXRpb24gb2Yga25vd2xlZGdlLCBleGNlZWRzIHRo" &
    "ZSBzaG9ydCB2ZWhlbWVuY2Ugb2YgYW55IGNhcm5hbCBwbGVhc3VyZS4="

test_equal("Thomas Hobbes' Leviathan encode", encoded2, encode64(msg2))
test_equal("Thomas Hobbes' Leviathan decode", msg2, decode64(encoded2))

test_report()
