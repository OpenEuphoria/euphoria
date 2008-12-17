-- tail recursion tests
include std/unittest.e

-- The Computer Language Shootout Benchmarks
--   http://shootout.alioth.debian.org/
--
--   contributed by Derek Parnell
--
--   run: exu ackermann.ex [N=1]

function Ack(integer M, integer N) 
    if M = 0 then
        return N+1
    elsif N = 0 then
        return Ack(M-1,1)
    end if
    return Ack(M-1, Ack(M, N-1))
end function
test_equal( "Ackermann 3, 2", 29, Ack(3, 2 ) )

function recursive_sequence( sequence s, integer x )
	s &= x
	if x = 0 then
		return s
	end if
	
	x -= 1
	return recursive_sequence( s, x )
end function
test_equal( "recursive sequence", {3,2,1,0}, recursive_sequence( {}, 3 ) )

test_report()
