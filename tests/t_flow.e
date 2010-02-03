include std/unittest.e

integer n,total_exit
sequence printed_i,printed_n2,loops
printed_i=repeat(0,5)
printed_n2=repeat(0,5)
total_exit=1
n=0
while n=0 label "top" do
	for i=1 to 6 do
		printed_i[n+1]=i
		if and_bits(i,1) then
			n+=1
			if n=1 then
				retry
			else
				exit
			end if
		end if
	end for
	if n=n then
		for i=1 to 4 do
			if i=4 then
				exit "top"
			elsif i=2 then
				continue
			else
				n+=10
			end if
			printed_n2[i]=n
		end for
	end if
	total_exit=0
end while
n=2
integer p
p=0
loops={}
loop entry do
	n+=1
	entry
	n+=2
	p+=1 
	loops=append(loops,{n,p})
	until n>10
end loop
if n>0 then
	if p=1 then
		p=-1
	else
		p=0
		break 0 -- topmost if/select
	end if
	p=-2
end if

test_equal("Retry",{1,1,0,0,0},printed_i)
test_equal("Continue",{12,0,22,0,0},printed_n2)
test_equal("Labelled exit",1,total_exit)
test_equal("Loop with entry",{{4,1},{7,2},{10,3},{13,4}},loops)
test_equal("Break with backward index",0,p)

sequence a
integer idx,idx2

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

idx = 1
idx2 = -1 
loop do
	idx += 1
	if idx > 10 then exit end if
	idx2 = idx
	until 0
end loop
test_equal("until 0", {11,10}, {idx,idx2})

idx = 1
idx2 = -1
loop do
	idx += 1
	if idx > 10 then exit end if
	idx2 = idx
	until 1
end loop
test_equal("until 1", {2,2}, {idx,idx2})

idx = 1
idx2 = -1
while 0 do
	idx += 1
	if idx > 10 then exit end if
	idx2 = idx
end while
test_equal("while 0", {1,-1}, {idx,idx2})

idx = 1
idx2 = -1
while 1 do
	idx += 1
	if idx > 10 then exit end if
	idx2 = idx
end while
test_equal("while 1", {11,10}, {idx,idx2})

idx = 0
for i = 1 to 10 do
	for j = 1 to 10 do
		for k = 1 to 10 do
			idx += 1
			exit -1
		end for
		idx += 1
	end for
	idx += 1
	exit
end for
test_equal( "exit negative index", 2, idx )

test_report()

