-- (c) Copyright 2006 Rapid Deployment Software - See License.txt
--
-- Change line terminator from \r\n (DOS-style) to \n (Linux style),
-- or vice versa. On Linux, some lines will get error messages from GNU C
-- if you use DOS-style. 

include file.e
include get.e
include wildcard.e

object d, line
sequence entry, dl, name
integer len, linux_style, infile, outfile

d = dir(".")
if atom(d) then
    puts(2, "dir failed\n")
end if
dl = prompt_string("Convert to DOS-style or Linux-style? (d/l) ")
if not find('d', dl) and not find('l', dl) then
    puts(2, "Specify d or l\n")
    abort(1)    
end if
linux_style = find('l', dl)
for i = 1 to length(d) do
    entry = upper(d[i][D_NAME]) & '^'
    if match(".C^", entry) or
       match(".H^", entry) or
       match(".E^", entry) or
       match(".EX^", entry) or
       match("IMAKEU^", entry) then
	name = d[i][D_NAME]
	puts(2, name & ' ')
	if platform() = LINUX then
	    system("mv " & name & " junk.xxx", 2)
	else    
	    system("move " & name & " junk.xxx > NUL" , 2)
	end if
	infile = open("junk.xxx", "rb")
	if infile = -1 then
	    puts(2, "Can't open junk.xxx\n")
	    abort(1)
	end if
	outfile = open(name, "wb")
	if outfile = -1 then
	    puts(2, "Can't open " & name & "\n")
	    abort(1)
	end if
	while 1 do
	    line = gets(infile)
	    if atom(line) then
		exit
	    end if
	    len = length(line)
	    if linux_style then
		if len >= 2 and 
		   line[len-1] = '\r' and
		   line[len] = '\n' then
		    line = line[1..len-2] & '\n'
		end if
	    else
		if line[len] = '\n' then
		    line = line[1..len-1] & "\r\n"
		end if
	    end if
	    puts(outfile, line)
	end while
	close(infile)
	close(outfile)
	if match("IMAKEU^", entry) then
	    system("chmod +x imakeu", 2)
	end if
    end if
end for
puts(2, '\n')

