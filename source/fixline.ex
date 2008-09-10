-- (c) Copyright 2007 Rapid Deployment Software - See License.txt
--
-- Change line terminator from \r\n (DOS-style) to \n (Linux style),
-- or vice versa. On Linux, some lines will get error messages from GNU C
-- if you use DOS-style. 

include std/console.e
include std/filesys.e
include std/get.e
include std/text.e

object d, line
sequence lEntry, dl, name
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
	lEntry = upper(d[i][D_NAME]) & '^'
	if match(".C^", lEntry) or
	   match(".H^", lEntry) or
	   match(".E^", lEntry) or
	   match(".EX^", lEntry) or
	   match("IMAKEU^", lEntry) then
		name = d[i][D_NAME]
		puts(2, name & ' ')
		ifdef LINUX then
			system("mv " & name & " junk.xxx", 2)
		elsedef
			system("move " & name & " junk.xxx > NUL" , 2)
		end ifdef
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
		if match("IMAKEU^", lEntry) then
			system("chmod +x imakeu", 2)
		end if
	end if
end for
puts(2, '\n')

