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
include std/regex.e

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
    excludedIncludes

    included = {}
    excludedIncludes = {}

object outputDir=-1

integer verbose = 0

function stringifier(object s)
	if atom(s) then
		return ""
	end if
	return s
end function
function slashifier(sequence s, object null = 0)
	if length( s) and s[$] != SLASH then
		s &= SLASH
	end if
	return s
end function

constant
    EuPlace = getenv( "EUDIR" )
    --Place = { "", EuPlace & "\\", EuPlace & "\\INCLUDE\\" }
sequence 
	Place = {}
-----------------------------------------------------------------------------
function findFile( sequence fName, integer showWarning = verbose )

    -- returns where a file is
    -- looks in the usual places
    
    -- look in the usual places
    if find(fName[length(fName)], {10, 13}) then
		fName = fName[1..length(fName)-1]
    end if
    
    for i = 1 to length( Place ) do
		if sequence( dir( Place[i] & fName ) ) then
			ifdef WINDOWS then
				return upper( Place[i] & fName )
			elsedef
				return Place[i] & fName
			end ifdef
		end if
    end for
    
    if showWarning then
		printf( 1, "Warning: Unable to locate file %s.\n", {fName} )
    end if
    return fName
    
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
		data = remove( data, 1 )
	end while      

	-- line feed?
	if find( '\n', data ) then
		data = remove( data, length( data ) )
	end if
	if find( '\r', data ) then
		data = remove( data, length( data ) )
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
	if s[$] = '\n' then
		s = remove( s, length(s) )
	end if
    return s
end function

function includable(sequence name)
    --return not find(name, excludedIncludes)
    name = findFile(name,0)
    return not find(canonical_path(name), excludedIncludes)
end function

-- strips out the leading slash / drive
function convertAbsoluteToRelative( sequence name )
	if absolute_path( name ) then
		for i = 1 to length( name ) do
			if find( name[i], `/\` ) then
				return name[i+1..$]
			end if
		end for
	end if
	return name
end function

-----------------------------------------------------------------------------
function parseFile( sequence fName, sequence fromPath = "" )

	integer inFile, outFile
	sequence newIncludeName, newfName, nameSpace, includeType, includeName
	object data

	included = append( included, fName )
	
	inFile = -1
	
	-- find the file
	sequence includeFile = convertAbsoluteToRelative( fName )
	sequence includePath = ""
	for i = length( includeFile ) to 1 by -1 do
		if find( includeFile[i], `\/` ) then
			includePath = includeFile[1..i]
			exit
		end if
	end for
	
	if length( fromPath ) then
		sequence tryName = findFile( slashifier( fromPath ) & fName )
		if file_exists( tryName ) then
			includePath = fromPath
			includeFile = slashifier( fromPath ) & fName
			fName = includeFile
		end if
	end if
	
	fName = findFile( fName )
	inFile = open( fName, "r" )
	
    if inFile = -1 then
		included = remove( included, length( included ) )
		printf(1, "Error finding file: %s\n", { fName } )
		return includeFile
    end if

	sequence newPath = slashifier( outputDir & includePath )
	if not file_exists( newPath ) then
		create_directory( newPath )
	end if
	
	if verbose then
		puts(1, outputDir & SLASH & includeFile & "\n")
	end if
	outFile = open( outputDir & SLASH & includeFile, "w" )

	if outFile = -1 then
		printf(1, "Warning: Unable to open %s for writing\n",
			{outputDir & SLASH & includeFile })
	end if
	
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
			newIncludeName = includeName
			
			if not find( includeName, included ) then
				-- include the file
				newIncludeName = parseFile( includeName, includePath )
				
			elsif absolute_path( includeName ) then
				newIncludeName = convertAbsoluteToRelative( includeName )
				
			end if
			
			if absolute_path( includeName ) and eu:compare( includeName, newIncludeName ) then
				integer ix = match( newIncludeName, data )
				if verbose then
					printf(1, "rewriting include with absolute path: %s", { data } )
				end if
				data = replace( data, "include ", 1, ix-1 )
			end if
			
		elsif length( includeName ) then
			printf(1, "Error finding include file %s\n", { includeName } )
		end if
		if outFile != -1 then
			puts( outFile, data )
		end if
		
	end while

	close( inFile )
	if outFile != -1 then
		close( outFile )
	end if
	return includeFile
    
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
	{ "c", "", "config file", { NO_CASE, HAS_PARAMETER, MULTIPLE, "eu.cfg" } },
	{ "", "clear", { NO_CASE } },
	{ "d", 0, "Output dir", { HAS_CASE, HAS_PARAMETER, OPTIONAL, ONCE, "dir" } },
	{ "e", "exclude-file", "Exclude file", { NO_CASE, HAS_PARAMETER, OPTIONAL, MULTIPLE, "filename" } },
	{ "ed", "exclude-directory", "Exclude directory", { NO_CASE, HAS_PARAMETER, OPTIONAL, MULTIPLE, "dir" } },
	{ "edr", "exclude-directory-recursively", "Exclude directory recursively", { NO_CASE, HAS_PARAMETER, OPTIONAL, MULTIPLE, "dir" } },
	{ "i", "include", "include dir", { NO_CASE, HAS_PARAMETER, MULTIPLE, "dir" } },
	{ "v", "verbose", "verbose output", { NO_CASE } },
	$
}

regex inc_path = regex:new( `^\s*-i (.+)\s*$`, regex:CASELESS )
procedure read_config( sequence eu_cfg )
	sequence orig_dir = current_dir()
	
	sequence lines = read_lines( eu_cfg )
	sequence cfg_path = pathname( canonical_path( eu_cfg ) )
	chdir( cfg_path )
	for lx = 1 to length( lines ) do
		object m = regex:matches( inc_path, lines[lx] )
		if sequence( m ) then
			Place = append( Place, canonical_path( slashifier( m[2] ) ) )
		end if
	end for
	
	chdir( orig_dir )
end procedure

procedure run()

	
    puts(1, "Euphoria distribution helper v1.0\n")
	sequence default_dir = current_dir() & SLASH & "eudist"
	sequence start_dir   = current_dir() & SLASH
	
    -- read the command line
    map:map params = cmd_parse(cmd_params)
    object 
		inFileName    = map:get( params, cmdline:EXTRAS, {} ),
		configFiles   = map:get( params, "c", {} ),
		excludeDirRec = map:get( params, "edr"),
		excludeDirs   = map:get( params, "ed"),
		excludeFiles  = map:get( params, "e"),
		verbose       = map:get( params, "verbose", 0 )

	outputDir = map:get(params, "d")
	
	if atom( outputDir ) then
		outputDir = default_dir
		
	end if
	
	if not absolute_path( outputDir ) then
		outputDir = start_dir & outputDir
	end if
	
	outputDir = slashifier( outputDir )
	
	-- get input file
	if length( inFileName ) < 1 then
		puts(2, "You must specify at least a single file\n" )
		abort( 1 )
	else
		if eu:compare( pathname( inFileName[1] ), current_dir() ) then
			chdir( pathname( inFileName[1] ) )
			inFileName[1] = filename( inFileName[1] )
		end if
		
	end if

    Place &= apply(stringifier(map:get(params, "include")), routine_id("slashifier"))
    
	sequence default_config_file = slashifier( pathname( inFileName[1] ) ) & "eu.cfg"
	if file_exists( default_config_file ) then
		configFiles = prepend( configFiles, default_config_file )
	end if
	
	for i = 1 to length( configFiles ) do
		read_config( configFiles[i] )
	end for
	
	Place &= apply( include_paths( 1 ), routine_id("slashifier") )
	
	if sequence( EuPlace ) then
		Place &= { EuPlace & SLASH, EuPlace & SLASH & "include" & SLASH }
	end if
	
	if sequence( getenv( "EUINC" ) ) then
		Place &= apply( stdseq:split( stringifier(getenv("EUINC")),PATHSEP), routine_id("slashifier") )
	end if
	Place &= { "" }

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
	
	if not file_exists( outputDir ) then
		create_directory( outputDir )
	
	elsif map:get( params, "clear", 0 ) then
		remove_directory( outputDir, 1 )
		create_directory( outputDir )
		if verbose then
			puts(1, "clearing the output directory\n")
		end if
		
	end if
	
	printf(1, "Outputting files to directory: %s\n", {outputDir})
		     
	for i = 1 to length(inFileName) do
	parseFile( inFileName[i] )
	end for
	
	printf(1, "\n%d files were found.\n", {length(included)})
	if verbose then
		for i = 1 to length(included) do
			printf(1, "%s\n", {included[i]})
		end for
	else
		
	end if
end procedure

run()
