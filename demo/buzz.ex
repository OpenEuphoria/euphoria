	-- Buzzword Generator
	-- Add your own phrases!

-- How it Works:
-- buzz has lists of parts of sentences that it matches up at random.
-- It will always make a grammatically correct sentence.

constant leadins = {
"Unfortunately",
"In the final analysis,",
"For all intents and purposes",
"We may definitely conclude that",
"Leading industry analysts agree that",
"Therefore",
"Without a doubt",
"According to the National Enquirer,",
"It is rumoured that"
}

constant subjects = {
"the Asian economic crisis",
"the Year 2000 Problem",
"George Bush",
"shareware",
"the North American Free Trade Deal",
"C++",
"IBM",
"multimedia PCs",
"local bus video",
"fax modems",
"Euphoria",
"Rapid Deployment Software",
"Bill Gates",
"Microsoft",
"the Pentium processor",
"pen-based computing",
"the promised land of 21st century computing",
"RISC machines",
"object-oriented technology",
"case tools",
"Windows",
"lap top computers",
"notebook computers",
"the World Wide Web",
"the Information Super Highway"
}

constant verbs = {
"will no longer support",
"can save",
"will nibble away at the installed base of",
"will be the downfall of",
"will lead the way to",
"will be like a cancerous growth in",
"will destroy",
"will make a mockery of",
"will not be compatible with",
"will be a great embarrassment to"
}

function buzz(integer n)
-- generate a paragraph containing n sentences of pure nonsense
    sequence paragraph

    paragraph = ""
    for i = 1 to n do
	paragraph &= leadins [rand(length(leadins))]  & " " &
		     subjects[rand(length(subjects))] & " " &
		     verbs   [rand(length(verbs))]    & " " &
		     subjects[rand(length(subjects))] & ". "
    end for
    return paragraph
end function

procedure display(sequence paragraph)
-- neatly display a paragraph
    integer column
    sequence line
    
    column = 1
    line = ""
    for i = 1 to length(paragraph) do
	line &= paragraph[i]  -- faster to print a whole line at a time
	column += 1
	if column > 65 and (paragraph[i] = ' ' or paragraph[i] = '-') then
	    puts(1, line & '\n')
	    column = 1
	    line = ""
	end if
    end for
    puts(1, line & '\n')
end procedure

puts(1, "\n\t\tComputer Industry Forecast\n")
puts(1, "\t\t--------------------------\n\n")
display(buzz(8))
puts(1, "\n\n")


