--****
-- === unix/mylib.ex
--
-- Call a C routine in a shared library that you created.
-- Also read and write the value of a C variable.
--

include dll.e

atom mylib, extra_addr
integer sum

mylib = open_dll("./mylib.so")

if mylib = NULL then
    puts(2, "Couldn't open mylib.so - rebuild for FreeBSD?\n")
    abort(1)
end if

sum = define_c_func(mylib, "sum", {C_INT}, C_INT) 
if sum = -1 then
    puts(1, "Couldn't find \"sum\" function\n")
    abort(1)
end if

extra_addr = define_c_var(mylib, "extra")
if extra_addr = -1 then
    puts(1, "Couldn't find \"extra\" variable\n")
    abort(1)
end if

integer a, b, c
a = peek4u(extra_addr) -- should be 99
? a

poke4(extra_addr, 0)
b = c_func(sum, {10})  -- should be 55
? b

poke4(extra_addr, 1000)
c = c_func(sum, {10})  -- should be 1055
? c

if a = 99 and b = 55 and c = 1055 then
    puts(1, "\nCorrect\n")
else
    puts(1, "\nWrong\n")
end if
