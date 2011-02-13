sequence s
s  = {12, 23, 34}
-- this errors out as too small see the fp. comment in be_runtime.c:3412
s[1..#1_0000_0000_0000_0000] += 1
