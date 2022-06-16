include std/unittest.e
constant M_MACHINE_INFO = 106
constant machine_info = machine_func(M_MACHINE_INFO, {})
constant ARCH = 1
test_true("Machine Info returns one of ARM, X86 or X86_64", 
    find(machine_info[ARCH], {"ARM", "X86", "X86_64"}))
test_report()