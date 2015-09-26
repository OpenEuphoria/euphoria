include std/unittest.e

enum type w32flagsAndEx by *2
      FLAG1 = 0 & 1,
      FLAG2 = 0 & 2,
      FLAG3 = 0 & 4
end type

test_pass("t_c_enum_strings_sneaky")
