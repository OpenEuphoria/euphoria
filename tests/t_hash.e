-- t_hash.e
include std/unittest.e
constant s = "Euphoria Programming Language brought to you by Rapid Deployment Software"
constant n = {-9.123, -4, -3, -2, -1, 0, 0.5, 1, 9, 9.123, #3FFFFFFF}
constant r = {
#1E500DD6,#04127A1A,#0671199C,#07408C06,#01EB9855,#1491F8FB,#07400C06,#1FFFEAAC,#16178814,  -- -9.123
#37D71B77,#37D71B78,#00460046,#0C1802CE,#209000AB,#009D009D,#0C98034E,#00000001,#30FD0A1E,  -- -4
#143F7601,#143F7602,#00460046,#2AB31DB2,#3FE58A01,#3FFFFFBC,#2AB39DB2,#00000001,#089B1012,  -- -3
#00000000,#00000000,#00000000,#00000000,#00000000,#00000000,#00000000,#00000000,#00000000,  -- -2
#00000000,#00000000,#00000000,#00000000,#00000000,#00000000,#00000000,#00000000,#00000000,  -- -1
#3008F1A1,#06F61B80,#0DEA49FF,#0CDBDC65,#2FB36422,#1F0AA898,#0CDB5C65,#04AF89E5,#1C861A1A,  -- 0
#3A1CE56B,#391EA5D4,#1CEA498E,#1DDBDC14,#25A770E8,#0E0AA8E9,#1DDB5C14,#04AFF8F6,#2929DDEC,  -- 0.5
#0808EDA1,#369A2F80,#0DEA7FFF,#0CDBEA65,#17B37822,#1F0A9E98,#0CDB6A65,#049989E5,#3D2029D2,  -- 1
#085ECD0A,#37660D4C,#0DEA6FFC,#0CDBFA66,#17E55889,#1F0A8E9B,#0CDB7A66,#04898A65,#0E593DF6,  -- 9
#1E7A0D83,#04667A74,#0671199C,#07408C06,#01C19800,#1491F8FB,#07400C06,#1FFFEA2C,#2C0F7D18,  -- 9.123
#1E3FB421,#30CA3836,#1F31C508,#1E005092,#018421A2,#0DD1246F,#1E00D092,#1F237EF3,#28D7B47C   -- #3FFFFFFF
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
    x += 1 test_equal(sprintf("hash(s[1..5] & {{1,1.1,{2.23,9}}}, %g)",n[i]), r[x], hash(s[1..5] & {{1,1.1,{2.23,9}}}, n[i]) )
end for


test_report()
