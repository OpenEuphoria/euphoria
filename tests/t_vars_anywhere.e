include unittest.e

sequence vars
procedure foo(integer n)
integer p
p=1
integer q
q=4
for i=1 to 3 do 
integer r
n=1
r=5
end for
integer i=0
vars={i,q,r}
end procedure
foo(0)
test_equal("variable out of block",4,vars[2])
test_equal("variable inside block",5,vars[3])
test_equal("Shadowing a for loop index",0,vars[1])

for i=1 to 4 do
integer q
q=2
end for
test_equal("Now at top level",2,q)

test_report()