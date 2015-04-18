constant M_GET_IL_CURRENT_POS = 888, M_INSERT_IL_AT = 999, M_DELETE_IL_AT = 777, M_SET_IL_CURRENT_POS = 666

sequence insert = {126, 166}
machine_proc(M_INSERT_IL_AT, {0, insert})
machine_proc(M_SET_IL_CURRENT_POS, 0)

-- the following will never get executed
puts(1, "testing\n")
puts(1, "done\n")
