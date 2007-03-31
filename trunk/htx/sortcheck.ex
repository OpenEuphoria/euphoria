include wildcard.e

object line
sequence words, prev_line

words = {}
prev_line = ""
while 1 do
    line = gets(0)
    if atom(line) then
	exit
    end if
    if equal(line, prev_line) then
	puts(1, "duplicate: " & line & '\n')
    end if
    if compare(line, prev_line) < 0 then
	puts(1, "bad sort: " & line & '\n')
    end if
    if not equal(line, upper(line)) then
	puts(1, "not upper case: " & line & '\n')
    end if
    words = append(words, line)
    prev_line = line
end while

? length(words)
