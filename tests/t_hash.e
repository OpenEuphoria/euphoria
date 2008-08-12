-- t_hash.e
include std/unittest.e
constant s = "Euphoria Programming Language brought to you by Rapid Deployment Software"
constant n = {-9.123, -4, -3, -2, -1, 0, 0.5, 1, 2, 9, 9.123, #3FFFFFFF}
constant r = {
{#D5483A58,#B05ABEB3,#90D9F7D1,#B202D31F,#4671199C,#07408C06,#A3C1AEA5,#1491F8FB,#07400C06,#5FFFEAAC,#699C7D1A}, -- (-9.123)
{#F7D71B77,#00460046,#E5861F90,#F7D71B78,#00460046,#0C1802CE,#209000AB,#009D009D,#0C98034E,#00000001,#30FD0A1E}, -- (-4)
{#543F7601,#45014501,#991D2072,#543F7602,#00460046,#EAB31DB2,#FFE58A01,#FFFFFFBC,#6AB39DB2,#00000001,#489B1012}, -- (-3)
{#00000000,#00000000,#00000000,#00000000,#00000000,#00000000,#00000000,#00000000,#00000000,#00000000,#00000000}, -- (-2)
{#00000000,#00000000,#00000000,#00000000,#00000000,#00000000,#00000000,#00000000,#00000000,#00000000,#00000000}, -- (-1)
{#1DD0A842,#E1FB28D5,#23DACE26,#E28588C3,#0DEA49FF,#4CDBDC65,#6B593CBF,#5F0AA898,#4CDB5C65,#C4AF89E5,#CFD3171F}, -- (0)
{#5E506B46,#21D92837,#87D3B1C5,#4185B18A,#1CEA498E,#5DDBDC14,#28D9FFBB,#4E0AA8E9,#5DDB5C14,#C4AFF8F6,#3196DEE0}, -- (0.5)
{#25A0D87A,#E1FB44B9,#C3AAD2C6,#F1CA0533,#0DEA7FFF,#4CDBEA65,#53294C87,#5F0A9E98,#4CDB6A65,#C49989E5,#F89318BA}, -- (1)
{#E48B5AE9,#E3FB24DB,#C68D3093,#6FFEEC0F,#0DEA4FFE,#4CDBDA64,#9202CE14,#5F0AAE99,#4CDB5A64,#C4A988E5,#BBE6BF9F}, -- (2)
{#66DC5EC5,#E6FB649E,#CED47438,#746130C3,#8DEA6FFC,#CCDBFA66,#1055CA38,#DF0A8E9B,#CCDB7A66,#C4898A65,#28EC53E8}, -- (9)
{#D5E23B0C,#B15ABEB2,#9271F684,#B336D586,#C671199C,#87408C06,#A36BAFF1,#9491F8FB,#87400C06,#5FFFEA2C,#7FB47426}, -- (9.123)
{#3CD9CF09,#2A698622,#C8FB95DA,#ADFE6E06,#1F31C508,#5E005092,#4A505BF4,#4DD1246F,#5E00D092,#1F237EF3,#2FD7B49D}  -- (3FFFFFFF)
            }

sequence test_data = {}
test_data = append(test_data, s									)
test_data = append(test_data, s[1..1]							)
test_data = append(test_data, s & 1.2345						)
test_data = append(test_data, {s}								)
test_data = append(test_data, s[1]								)
test_data = append(test_data, s[1] + 0.123						)
test_data = append(test_data, -s								)
test_data = append(test_data, -s[1]								)
test_data = append(test_data, -s[1] - 0.123						)
test_data = append(test_data, ""								)
test_data = append(test_data, s[1..5] & {{1,1.1,{2.23,9}}}		)


for i = 1 to length(n) do
	for x = 1 to length(test_data) do
    	test_equal(sprintf("hash t=%d n=%d",{x,i}), r[i][x], hash(test_data[x], n[i]) )
    end for
end for


test_report()
