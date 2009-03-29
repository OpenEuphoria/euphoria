include std/io.e
include std/pretty.e
integer fd

fd = open("command_line.txt","w")
pretty_print(fd,command_line(),{2,2,1,78,"%d","%.10g",32,127,1000,1})
puts(fd,10)
close(fd)
