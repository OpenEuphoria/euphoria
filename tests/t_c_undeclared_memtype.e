include std/unittest.e

-- segfault when referencing an undefined memtype. should be "memtype 'bool' has not been declared." 
memstruct TEST_STRUCT 
    bool enabled 
end memstruct 
