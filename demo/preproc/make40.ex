--JBrown
--combine.ex
--global scopes aren't redefined
    --this MIGHT cause an error, however, euphoria should normally have an
    --error in that case too.
--procedure-scope vars aren't saved, this makes code more readable
    --N/A if shroud is on
--you can either choose not to combine files in a list, or
    --you can ignore include files on 1 dir (default: eu's include dir)
--shrouding symbols is optional.
--bug fixed: local symbols were being treated as global.
--bug fixed: strings with \x were changed to \x\x.
--bug fixed: file c:\myfile.e and myfile.e were the diffrent files.
--added platform to sequence builtin
--bug: using routine_id("abort_") gives error
    --"Unable to resolve routine id for abort"
    --to fix made routine_id-ing of builtin routines legal.
-- concat.ex
-- version 1.0
--
-- replacement for Euphoria's bind routine

include std/get.e
include std/io.e
include std/text.e
include std/console.e
include std/sequence.e
include std/filesys.e

integer slash
if platform() = 3 then
    slash = '/'
else
    slash = '\\'
end if

-----------------------------------------------------------------------------
-- code from RDS's ED color coding routines

sequence charClass

-- character classes
constant    
    DIGIT       = 1,
    OTHER       = 2,
    LETTER      = 3,
    BRACKET     = 4,
    QUOTE       = 5,
    DASH        = 6,
    WHITE_SPACE = 7,
    NEW_LINE    = 8

    charClass = repeat( OTHER, 255 )

    
    charClass['a'..'z'] = LETTER
    charClass['A'..'Z'] = LETTER
    charClass['_']      = LETTER
    charClass['0'..'9'] = DIGIT
    charClass['[']      = BRACKET
    charClass[']']      = BRACKET
    charClass['(']      = BRACKET
    charClass[')']      = BRACKET
    charClass['{']      = BRACKET
    charClass['}']      = BRACKET
    charClass['\'']     = QUOTE
    charClass['"']      = QUOTE
    charClass[' ']      = WHITE_SPACE
    charClass['\t']     = WHITE_SPACE
    charClass['\n']     = NEW_LINE
    charClass['-']      = DASH

-----------------------------------------------------------------------------
-- built-in identifiers
constant old_keywords = {
    "and",            
    "by",
    "constant",
    "do",
    "else",
    "elsif",
    "end",
    "exit",
    "for",
    "function",
    "global",
    "if",
    "include",
    "not",
    "or",
    "procedure",
    "profile",
    "profile_time",
    "return",
    "to",
    "type",   
    "type_check",
    "then",       
    "warning",
    "while",
    "with",
    "without",
    "xor" }


-----------------------------------------------------------------------------
-- built in routines
constant old_builtins = {
    "?",
    "abort",
    "and_bits",
    "append",
    "arctan",
    "atom",
    "call",
    "c_func",   
    "c_proc",
    "call_func",
    "call_proc",
    "clear_screen",
    "close",
    "command_line",
    "compare",
    "cos",
    "date",
    "equal",
    "find",
    "floor",
    "get_key",
    "get_pixel",
    "getc",
    "getenv",
    "gets",
    "integer",
    "length",
    "log",
    "machine_func",
    "machine_proc",
    "match",
    "mem_copy",
    "mem_set",
    "not_bits",
    "object",
    "open",
    "or_bits",
    "peek",
    "peek4s",
    "peek4u",
    "pixel",
    "poke",
    "poke4",
    "position",
    "power",
    "prepend",
    "print",
    "printf",
    "profile",
    "puts",
    "rand",
    "remainder",
    "repeat",
    "routine_id",
    "sequence",
    "sin",
    "sprintf",
    "sqrt",         -- missing
    "system",
    "system_exec",
    "tan",
    "time",
    "trace",
    "platform",
    "xor_bits" }


--****
-- == Keyword Data

include euphoria/keywords.e

-----------------------------------------------------------------------------
integer 
    globalState,            -- 1 = just set, 2 = old flag
    routineFlag,            -- 1 = last keyword was routine_id
    procState,              -- 1 = keyword follows, 2 = inProc
    outFile                 -- file to write to
    
    globalState = 0         
    routineFlag = 0
    procState = 0
    
sequence
    oldLocal, newLocal,
    included

    oldLocal = {}
    newLocal = {}
    included = {}

constant
    EuPlace = getenv( "EUDIR" ),
    --Place = { "", EuPlace & "\\", EuPlace & "\\INCLUDE\\" }
Place = { current_dir()&slash, EuPlace & slash, EuPlace & slash&"include"&slash, "" }
-----------------------------------------------------------------------------
function findFile( sequence fName )

    -- returns where a file is
    -- looks in the usual places
    
    -- look in the usual places
    --trace(1)
    if find(fName[length(fName)], {10, 13}) then
	fName = fName[1..length(fName)-1]
    end if
    for i = 1 to length( Place ) do
	if sequence( dir( Place[i] & fName ) ) then
	    if platform() = 3 then
		return Place[i] & fName
	    else
		return upper( Place[i] & fName )
	    end if
	end if
    end for
    
    printf( 1, "Unable to locate file %s.\n", {fName} )
    --abort(0)
    
end function

-----------------------------------------------------------------------------
function replaceWord( sequence word )

    if find(word, keywords&builtins) and
    not find(word, old_keywords&old_builtins) then
    	return "__" & word
    end if

    return word
    
end function


-----------------------------------------------------------------------------
function parseLine( sequence s )
    -- parse a sequence into keywords
    -- and convert them
    
    integer at, char, i
    sequence out, word
    
    out = {}
    at = 1

    while at <= length( s ) do        
    
	-- get a character
	char = s[at]      

	-- identifier
	if charClass[char] = LETTER then     
	
	    word = {}
	
	    -- read until end
	    while charClass[char] = LETTER
	    or    charClass[char] = DIGIT do
	
		-- add to word
		word = append( word, char )
		-- next letter
		at += 1       
		char = s[at]
	
	    end while       

	    -- routine flag
	    routineFlag = equal( word, "routine_id" )

	    -- substitute?            
	    word = replaceWord( word )

	    -- global flag
	    if equal( word, "global" ) then
		-- new occurance
		globalState = 1
		
	    elsif globalState = 1 then
		-- mark as used
		globalState = 2
	    end if

	    
	    -- manage proc state
	    if equal( word, "function" )
	    or equal( word, "procedure" )
	    or equal( word, "type" ) then
		if procState = 0 then
		    -- beginning of definition
		    procState = 1

		elsif procState = 2 then
		    -- end function/procedure
		    procState = 0

		end if          

	    elsif procState = 1 then
		-- move state ahead
		procState = 2    
		globalState = 0
	    end if

	    -- substitute, if needed            
	    out = out & word

	-- number: handles hex as well
	elsif charClass[char] = DIGIT
	or    char = '#' then

	    word = {}
	    
	    -- read until end
	    while charClass[char] = DIGIT
	    or    charClass[char] = LETTER
	    or    char = '#' do
	    
		-- add to word
		word = append( word, char )
		-- next letter
		at += 1       
		char = s[at]
	
	    end while       

	    -- accumulated number            
	    out = out & word

	
	-- comment
	elsif char = '-'
	and   s[at+1] = '-' then
	    -- comment
	    out = out & s[at..length(s)]
	    -- move past end
	    at = length(s)+1
	
	-- character literal        
	elsif char = '\'' then
	    at += 1
	    if s[at] = '\\' then
		-- special
		at += 1
		word = "'\\" & s[at] & "'"
	    else          
		-- normal
		word = "'" & s[at] & "'"
	    end if       

	    -- move past quote            
	    at += 2

	    -- accumulate            
	    out = out & word

	-- quote                 
	elsif char = '"' then

	    word = {'"'}
	    while 1 do 
		-- move ahead
		at += 1
		-- special?
		if s[at] = '\\' then           
		    at += 1
		    --word = word & s[at-1] & s[at]
		    word = word & '\\' & s[at]
		    -- prevent reading as quote
		    s[at] = ' '
		else
		    word = word & s[at]
		end if

		-- end of quote?                
		if s[at] = '"' then
		    -- move ahead and exit
		    at += 1
		    exit
		end if
		
	    end while

	    -- handle routine_id
	    if routineFlag then

		-- remove quotes
		word = word[2..length(word)-1]
		
		word = replaceWord(word)
		
		-- re-apply quotes
		word = '"' & word & '"'
		
	    end if

	    -- accumulated
	    out = out & word
	    
	-- delimiter
	else        
	    out = out & char
	    at += 1
					  
	end if
	
    end while
    
    return out
    
end function


-----------------------------------------------------------------------------
function getIncludeName( sequence data )

    -- if the statement is an include statement, return the file name
    integer at
    
    -- include statement missing?
    if not match( "include ", data ) then
	return ""
    end if

    -- trim white space
    while charClass[ data[1] ] = WHITE_SPACE do
	data = data[2..length( data ) ]
    end while      
    
    -- line feed?
    if find( '\n', data ) then
	data = data[1..length(data)-1]
    end if
    if find( '\r', data ) then
	data = data[1..length(data)-1]
    end if

    -- not first statement?
    if not equal( data[1..8], "include " ) then
	-- not an include statement
	return ""  
    else
	-- remove statement
	data = data[9..length(data)]
    end if

    -- remove data after space
    at = find( ' ', data )
    if at then
	data = data[1..at-1]
    end if

    return data

end function


-----------------------------------------------------------------------------
function trimer(sequence s)
    sequence t
    integer u
    if s[length(s)] = '\n' then
	s = s[1..length(s)-1]
    end if
    if s[length(s)] = '\r' then
	s = s[1..length(s)-1]
    end if
    t = reverse(s)
    u = find(slash, t)
    if not u then
	return s
    end if
    t = t[1..u-1]
    s = reverse(t)
    return s
end function

function includable(sequence name)
    return 0
end function

-----------------------------------------------------------------------------
without warning
procedure parseFile( sequence fName )

    integer inFile
    sequence newPrior, oldPrior, includeName
    object data

    -- find the file
    fName = findFile( fName )

    -- already part of the file?
    if find( fName, included ) then
	return
    else
	included = append( included, fName )
    end if  
    
    -- store locals and clear
    oldPrior = oldLocal
    newPrior = newLocal
    oldLocal = {}
    newLocal = {}

    -- write header                              
    puts( outFile, "\n" )
    
    inFile = open( fName, "r" )
    
    while 1 do        
    
	-- read a line
	data = gets( inFile )
    
	-- end of file?
	if integer( data ) then
	    exit
	end if

	-- include file?
	includeName = getIncludeName( data )
	if length( includeName ) and includable(trimer(includeName)) then
	
	    -- include the file
	    parseFile( includeName )
	    
	elsif length(includeName) then --no parse
	    puts( outFile, data )        
	
	else
	
	    -- translate
	    data = parseLine( data )

	    -- output
	    puts( outFile, data )        
	    
	end if
	
    end while
    
    close( inFile )
    --end of file header
    puts( outFile, "\n" )

    -- restore locals
    oldLocal = oldPrior
    newLocal = newPrior

    
end procedure
with warning

-----------------------------------------------------------------------------
export function preprocess(sequence inFileName, sequence outFileName, sequence optParams)
		  
    -- make sure they are different
    if equal( inFileName, outFileName ) then
	puts( 1, "File names must be different!\n" )
	return 1
    end if
		       
    -- open the file
    outFile = open( outFileName, "w" )

    -- process the input file
    parseFile( inFileName )
    
    -- close the output file
    close( outFile )

    return 0
		       
end function


-----------------------------------------------------------------------------
		  
procedure run()   
    object cmd, inFileName, outFileName, optParams
    inFileName = -1
    outFileName = -1
    optParams = {}

    -- read the command line
    cmd = command_line()

    for i = 3 to length(cmd) do
    	if equal(cmd[i], "-i") then
		if i = length(cmd) then
			puts(1, "Expected filename to follow -i!\n")
			abort(0)
		else
			inFileName = cmd[i+1]
		end if
    	elsif equal(cmd[i], "-o") then
		if i = length(cmd) then
			puts(1, "Expected filename to follow -o!\n")
			abort(0)
		else
			outFileName = cmd[i+1]
		end if
	else
		--ignored
	end if
    end for

    -- get input file
    if atom(inFileName) then
	inFileName = prompt_string( "File to concatonate? " )
	if length( inFileName ) = 0 then
	    abort(0)
	end if
    end if
		     
    -- get output file
    if atom(outFileName) then
	outFileName = prompt_string( "File to create? " )
	if length( outFileName ) = 0 then
	    abort(0)
	end if
    end if

    -- make sure they are different
    if preprocess( inFileName, outFileName, optParams ) then
	abort(0)
    end if
		       
end procedure

ifdef not EUC_DLL then
run()
end ifdef

