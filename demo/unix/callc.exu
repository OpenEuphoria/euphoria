	-- Calls to C routines in standard shared libraries
include std/dll.e
include std/machine.e

atom libc, libm, p, q, format
sequence text
integer s

-- Standard C Library:
libc = open_dll("/lib/libc.so.6")
if libc = 0 then
    puts(2, "couldn't find /lib/libc.so.6 - try just \"libc.so\"\n")
end if

-- Standard Math Library:
libm = open_dll("/usr/lib/libm.so")
if libm = 0 then
    puts(2, "libm not found\n")
end if

puts(1, "> string copy test:\n")
s = define_c_proc(libc, "strcpy", {C_POINTER, C_POINTER})
p = allocate(100)
poke(p, repeat(0, 100))
q = allocate_string("Hello Euphoria\n")
c_proc(s, {p, q})  
text = peek({p, 15})
puts(1, text)

puts(1, "\n> malloc test:\n")
s = define_c_func(libc, "malloc", {C_INT}, C_POINTER)
p = c_func(s, {160})
? peek4u(p-4) -- should be a somewhat larger size than what you allocated
	      -- (except on FreeBSD)
	      
puts(1, "\n> sin test:\n")
s = define_c_func(libm, "sin", {C_DOUBLE}, C_DOUBLE)
? c_func(s, {1.0})
? sin(1.0) -- same?

puts(1, "\n> printf test:\n")
s = define_c_proc(libc, "printf", {C_POINTER, C_INT, C_DOUBLE, C_INT, C_DOUBLE})
format = allocate_string("Here are 4 numbers: %d, %.3f, %d, %e\n")
c_proc(s, {format, 111, 222.222, 333, 444.4444})


