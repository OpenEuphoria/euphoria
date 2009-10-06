include std/unittest.e

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

idx = 0
idx2 = 0
loop do
	idx += 1
	if and_bits( 1, idx ) then
		continue
	end if
	idx2 += 1
until idx = 3
test_equal( "loop..until with continue", 1, idx2 )


function foo( sequence x )
	for i = 1 to length(x) do if atom(x[i]) then return 0 end if end for
	return 1
end function

test_equal( "for loop with if on one line #1", 0, foo("abc") )
test_equal( "for loop with if on one line #2", 1, foo( {{2}, {3}} ) )

idx = 0
for i = 1 to 5 do
	for j = 1 to 5 do
		idx += 1
end for	end for
test_equal( "for loop with two 'end for's on one line", 25, idx )

idx = 0
while idx < 25 do
	while idx < 25 do
		idx += 1
end while	end while
test_equal( "while loop with two 'end while's on one line", 25, idx )

idx = 0
loop do
	loop do
		idx += 1
until idx >= 25	until idx = 30
test_equal( "loop-until with two 'until's on one line", 30, idx )


idx = 0
label "LAB_B"
idx += 1
label "LAB_A"
idx += 1
if idx < 25 then if idx < 20 then goto "LAB_A" else goto "LAB_B" end if end if
test_equal( "goto-loop with two 'end-if's on one line", 26, idx )

test_report()

