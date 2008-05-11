include unittest.e

set_test_module_name("internal-loops")

sequence a
integer idx

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
idx = 0
while 1 do
    idx += 1
    a &= idx
    if idx = 5 then exit end if
end while
test_equal("while #1", {1,2,3,4,5}, a)

a = {}
idx = 0
while 1 do
    idx += 1
    if idx > 1 and idx < 5 then continue end if
    a &= idx
    if idx = 5 then exit end if
end while
test_equal("while continue", {1,5}, a)
