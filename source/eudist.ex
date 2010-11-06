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

include std/cmdline.e
include std/get.e
include std/io.e
include std/map.e
include std/text.e
include std/console.e
include std/sequence.e
include std/filesys.e

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
sequence
    included,
    includedNewNames,
    excludedIncludes

    included = {}
    includedNewNames = {}
    excludedIncludes = {}

object outputDir=-1

constant
    EuPlace = getenv( "EUDIR" )
    --Place = { "", EuPlace & "\\", EuPlace & "\\INCLUDE\\" }
sequence Place = { current_dir()&SLASH, EuPlace & SLASH, EuPlace & SLASH&"include"&SLASH, "" },
mainPath = ""
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
function getIncludeName( sequence data )

    -- if the statement is an include statement, return the file name
    integer at
    
    -- include statement missing?
    if not match( "include ", data ) then
	return {"","",""}
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

    sequence includeType
    -- not first statement?
    if equal( data[1..8], "include " ) then
	-- remove statement
	includeType = data[1..8]
	data = data[9..length(data)]
    elsif length(data) > 15 and equal( data[1..15], "public include " ) then
	-- remove statement
	includeType = data[1..15]
	data = data[16..length(data)]
    else
	-- not an include statement
	return {"","",""}
    end if

    sequence nameSpace = ""
    -- remove data after space
    at = find( ' ', data )
    if at then
	nameSpace = data[at..$]
	data = data[1..at-1]
    end if

    return {data,nameSpace,includeType}

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
    --t = reverse(s)
    --u = find(SLASH, t)
    --if not u then
	--return s
    --end if
    --t = t[1..u-1]
    --s = reverse(t)
    return s
end function

function includable(sequence name)
    --return not find(name, excludedIncludes)
    name = findFile(name)
    return not find(canonical_path(name), excludedIncludes)
end function

-----------------------------------------------------------------------------
without warning
function parseFile( sequence fName )

    integer inFile, outFile
    sequence newIncludeName, includeName, newfName, nameSpace, includeType
    object data

	included = append( included, fName )

    -- find the file
    fName = findFile( fName )
    
    inFile = open( fName, "r" )
    newfName = filename(fName)

    if sequence(outputDir) then
   	 while file_exists( outputDir & SLASH & newfName ) do
	 	newfName &= sprintf("%d", rand(10))
	 end while
   	 outFile = open( outputDir & SLASH & newfName, "w" )
    else
	 outFile = -1
    end if

	includedNewNames = append( includedNewNames, newfName )
    
    while 1 do        
    
	-- read a line
	data = gets( inFile )
    
	-- end of file?
	if integer( data ) then
	    exit
	end if

	-- include file?
	includeName = getIncludeName( data )
	includeType = includeName[3]
	nameSpace = includeName[2]
	includeName = includeName[1]
	if length( includeName ) and includable(trimer(includeName)) then
	
    -- already part of the file?
    if find( includeName, included ) then
	--return
	    newIncludeName = includedNewNames[find(includeName, included)]
    else
	    -- include the file
	    newIncludeName = parseFile( includeName )
    end if  
    if outFile != -1 then
	    puts( outFile, includeType & newIncludeName & nameSpace & "\n")
    end if
	    
	else
    if outFile != -1 then
	    puts( outFile, data )
    end if
	end if
	
    end while
    
    close( inFile )
    if outFile != -1 then
    close( outFile )
    end if
    return newfName
    
end function
with warning

function getListOfFiles(sequence inDir, integer recursive = 0)
	object s = dir(inDir)
	sequence z = ""
	if atom(s) then
		s = ""
	end if
	for i = 1 to length(s) do
		if not find('d', s[i][D_ATTRIBUTES]) then
			--z &= {inDir & SLAH & s[i][D_NAME]}
			z &= {canonical_path(inDir & SLASH & s[i][D_NAME])}
		elsif recursive and not find(s[i][D_NAME], {".",".."}) then
			z &= getListOfFiles(inDir & SLASH & s[i][D_NAME],recursive)
		end if
	end for
	return z
end function

-----------------------------------------------------------------------------
constant cmd_params = {
	{ "i", 0, "Input filename", { NO_CASE, HAS_PARAMETER, ONCE, "filename" } },
	{ "e", "exclude-file", "Exclude file", { NO_CASE, HAS_PARAMETER, OPTIONAL, MULTIPLE, "filename" } },
	{ "ed", "exclude-directory", "Exclude directory", { NO_CASE, HAS_PARAMETER, OPTIONAL, MULTIPLE, "dir" } },
	{ "edr", "exclude-directory-recursively", "Exclude directory recursively", { NO_CASE, HAS_PARAMETER, OPTIONAL, MULTIPLE, "dir" } },
	{ "d", 0, "Output dir", { NO_CASE, HAS_PARAMETER, OPTIONAL, ONCE, "dir" } }
}
    
procedure run()   
    -- read the command line
    map:map params = cmd_parse(cmd_params)
    object inFileName=map:get(params, "i"),
    excludeDirRec=map:get(params, "edr"),
    excludeDirs=map:get(params, "ed"),
    excludeFiles=map:get(params, "e")

    outputDir=map:get(params, "i")

	if sequence(excludeFiles) and length(excludeFiles) then
		for i = 1 to length(excludeFiles) do
			excludedIncludes = append(excludedIncludes, canonical_path(excludeFiles[i+1]))
		end for
	end if
	if sequence(excludeDirs) and length(excludeDirs) then
		for i = 1 to length(excludeDirs) do
			excludedIncludes &= getListOfFiles(excludeDirs[i+1])
		end for
	end if
	if sequence(excludeDirs) and length(excludeDirs) then
		for i = 1 to length(excludeFiles) do
			excludedIncludes &= getListOfFiles(excludeDirRec[i+1],1)
		end for
	end if

    -- get input file
    if atom(inFileName) then
	inFileName = prompt_string( "File to parse? " )
	if length( inFileName ) = 0 then
	    abort(0)
	end if
    end if
		     
    mainPath = pathname(canonical_path(inFileName))
    Place &= {mainPath&SLASH}
    -- process the input file
    parseFile( inFileName )

    printf(1, "%d files were found. These are:\n", {length(included)})
    for i = 1 to length(included) do
    	printf(1, "%s\n", {included[i]})
    end for
		       
end procedure

run()
