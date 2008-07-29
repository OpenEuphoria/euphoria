-- t_hash.e
include std/unittest.e
constant s = "Euphoria Programming Language brought to you by Rapid Deployment Software"
constant n = {-4, -3, -2, -1, 0, 0.5, 1, 9, 9.123}
constant r = {
#37D71B77,#37D71B78,#00460046,#0C1802CE,#209000AB,#009D009D,#0C98034E,#00000001,#30FD0A1E,
#143F7601,#143F7602,#00460046,#2AB31DB2,#3FE58A01,#3FFFFFBC,#2AB39DB2,#00000001,#089B1012,
#00000000,#00000000,#00000000,#00000000,#00000000,#00000000,#00000000,#00000000,#00000000,
#00000000,#00000000,#00000000,#00000000,#00000000,#00000000,#00000000,#00000000,#00000000,
#16682E80,#1948B4E4,#0D07A3BE,#0651E414,#0997D180,#32F85C44,#06544410,#193B791C,#02D3C253,
#00003280,#00001940,#275AB511,#065372B6,#1FFFCD80,#18A54AF1,#0655D2B2,#0CA0D9D3,#1D41F500,
#00006942,#0C9D6F1B,#0CC184B1,#0CA04046,#000016C0,#333E7B51,#0CA2A042,#193A74F3,#012FA4DA,
#0C5F464C,#17B6B194,#0CC186D9,#0CA0404A,#0BE495B1,#333E7929,#0CA2A046,#193A74FB,#05DBB345,
#03AD05C6,#104421CC,#1A3FEE4F,#0197E449,#1FFFCD80,#25C011B3,#019A4445,#0329BCF9,#00BD739E
             }


integer x = 0
for i = 1 to length(n) do
    x += 1 test_equal(sprintf("hash(s, n[%d])",i), r[x], hash(s, n[i]) )
    x += 1 test_equal(sprintf("hash({s}, n[%d])",i), r[x], hash({s}, n[i]) )
    x += 1 test_equal(sprintf("hash(s[1], n[%d])",i), r[x], hash(s[1], n[i]) )
    x += 1 test_equal(sprintf("hash(s[1] + 0.123, n[%d])",i), r[x], hash(s[1] + 0.123, n[i]) )
    x += 1 test_equal(sprintf("hash(-s, n[%d])",i), r[x], hash(-s, n[i]) )
    x += 1 test_equal(sprintf("hash(-s[1], n[%d])",i), r[x], hash(-s[1], n[i]) )
    x += 1 test_equal(sprintf("hash(-s[1] - 0.0123, n[%d])",i), r[x], hash(-s[1] - 0.123, n[i]) )
    x += 1 test_equal(sprintf("hash(\"\", n[%d])",i), r[x], hash("", n[i]) )
    x += 1 test_equal(sprintf("hash(s[1..5] & {{1,1.1,{2.23,9}}}, n[i])",i), r[x], hash(s[1..5] & {{1,1.1,{2.23,9}}}, n[i]) )
end for


test_report()
