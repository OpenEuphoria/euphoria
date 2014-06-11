include std/machine.e
include std/dll.e
include std/unittest.e

constant do_nothing = allocate_code( {#C2} ) -- RET instruction (but it doesn't matter anyway)

constant r_proc = define_c_proc( "", { "+", do_nothing }, {} ) 

test_report()
