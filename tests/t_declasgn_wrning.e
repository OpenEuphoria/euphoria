include get.e
include unittest.e
test_equal("warning",1,prompt_number("\nDid you just get any warnings, and especially one about some useless code? 1 = Yes, 0 = No   :",{0,1}))
