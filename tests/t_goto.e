include unittest.e

without warning

integer n,m,c
n = 0

goto "a"
n = 1
label "a"

test_equal("Goto skip", 0,n)

m = 0
label "b"
if m = 9 then
	goto "c"
end if
m += 1
goto "b"

label "c"

test_equal("Goto loop", 0,n)

for i = 1 to 10 do
	goto "d"
	test_fail("Goto jump out of for loop")
end for

label "d"
test_pass("Goto jump out of for loop")

c = 1
goto "e"
while c = 0 do
	label "e"
	c = 2
end while

test_equal("Goto jump into while loop", 2,c)

while c = 2 do
	goto "f"
	test_fail("Goto jump out of while loop")
end while

label "f"
test_pass("Goto jump out of while loop")

test_embedded_report()

