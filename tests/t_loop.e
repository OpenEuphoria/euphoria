include unittest.e

set_test_module_name("internal-loops")

sequence a
integer idx, idx2

a = {}
for i = 1 to 5 do
    a &= i
end for
test_equal("for #1", {1,2,3,4,5}, a)

a = {}
for i = 1 to 5 by 2 do
    a &= i
end for
test_equal("for by +", {1,3,5}, a)

a = {}
for i = 5 to 1 by -2 do
    a &= i
end for
test_equal("for by -", {5,3,1}, a)

a = {}
for i = 1 to 10 do
    if i > 5 then exit end if
    a &= i
end for
test_equal("for exit", {1,2,3,4,5}, a)

a = {}
for i = 1 to 5 do
    if i > 1 and i < 5 then continue end if
    a &= i
end for
test_equal("for continue", {1,5}, a)

a = {}
for b = 1 to 2 do
    for c = 1 to 5 do
        if c > 1 and c < 5 then continue end if
        a &= {{b,c}}
    end for
end for
test_equal("for nested continue", {{1,1},{1,5},{2,1},{2,5}}, a)

a = {}
idx = 0
while idx < 5 do
    idx += 1
    a &= idx
end while
test_equal("while #1", {1,2,3,4,5}, a)

a = {}
idx = 0
while idx < 5 do
    idx += 1
    if idx > 1 and idx < 5 then continue end if
    a &= idx
end while
test_equal("while continue", {1,5}, a)

a = {}
idx = 0
while idx < 2 do
    idx += 1
    idx2 = 0
    while idx2 < 5 do
        idx2 += 1
        if idx2 > 1 and idx2 < 5 then continue end if
        a &= {{idx,idx2}}
    end while
end while
test_equal("while nested continue", {{1,1},{1,5},{2,1},{2,5}}, a)

