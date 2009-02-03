-- inlining tests
include std/unittest.e
atom e
integer c
integer d
sequence s

without inline
function short_wo(integer a, sequence b)
   return b & a
end function

c = 0
e = time() + 0.1
while time() < e do
    s = short_wo('a', "abc")
    c += 1
end while


with inline
function short_wi(integer a, sequence b)
   return b & a
end function

d = 0
e = time() + 0.1
while time() < e do
    s = short_wo('a', "abc")
    d += 1
end while

-- The number of executions of 'with out' should be less than 'with'.
test_true(sprintf("inline %d < %d", {c,d}), c < d)

