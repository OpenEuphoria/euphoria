include stack.e as s
include unittest.e

set_test_module_name("stack.e")

stack sk

--
-- FIFO testing
--

sk = s:new(s:FIFO)

test_true("FIFO new() #1", sequence(sk) and length(sk) = 1)
test_true("FIFO is_empty() #1", s:is_empty(sk))

sk = s:push(sk, 10)
sk = s:push(sk, 20)
sk = s:push(sk, 30)

test_equal("FIFO push() #1", {FIFO,30,20,10}, sk)
test_equal("FIFO top()", 10, s:top(sk))

sk = s:swap(sk)
test_equal("FIFO swap() #1", {FIFO,30,10,20}, sk)
sk = s:swap(sk)
test_equal("FIFO swap() #1", {FIFO,30,20,10}, sk)

sk = s:dup(sk)
test_equal("FIFO dup()", {FIFO,30,20,10,10}, sk)
sk = s:pop(sk)

sk = s:pop(sk)
test_equal("FIFO pop() #1", {FIFO,30,20}, sk)

sk = s:pop(sk)
test_equal("FIFO pop() #2", {FIFO,30}, sk)

sk = s:pop(sk)
test_equal("FIFO pop() #3", {FIFO}, sk)

sk = s:push(sk, 10)
test_equal("FIFO push() #2", {FIFO,10}, sk)

sk = s:clear(sk)
test_equal("FIFO clear()", {FIFO}, sk)
test_true("is_empty() #2", s:is_empty(sk))

--
-- FILO testing
--

sk = s:new(s:FILO)
test_true("FILO new()", sequence(sk) and length(sk) = 1)
test_true("FILO is_empty() #1", s:is_empty(sk))

sk = s:push(sk, 10)
sk = s:push(sk, 20)
sk = s:push(sk, 30)

test_equal("FILO push() #1", {FILO,10,20,30}, sk)
test_equal("FILO top() #1", 30, s:top(sk))

sk = s:pop(sk)
test_equal("FILO pop() #1", {FILO,10,20}, sk)
test_equal("FILO top() #2", 20, s:top(sk))

sk = s:pop(sk)
test_equal("FILO pop() #2", {FILO,10}, sk)
test_equal("FILO top() #3", 10, s:top(sk))

sk = s:pop(sk)
test_equal("FILO pop() #3", {FILO}, sk)

sk = s:clear(sk)
test_equal("FILO clear()", {FILO}, sk)
test_true("FILO is_empty() #2", s:is_empty(sk))
