
include std/filesys.e
include std/regex.e
include std/sort.e

-- Directories to look into
constant BUILDDIRS = {
	"intobj",
	"transobj",
	"libobj"
	}

constant CSS =`
.nocode   { font-family: monospace; font-style: italic; white-space: pre; background-color: #ffffdd; }
.exec     { font-family: monospace; white-space: pre; background-color: #bbffbb; }
.noexec   { font-family: monospace; white-space: pre; background-color: #ffbbbb; }
`

constant HEADER =`
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
   "http://www.w3.org/TR/html4/strict.dtd">
<HTML>
  <HEAD>
    <LINK href="gcov.css" rel="stylesheet" type="text/css">
  </HEAD>
  <BODY>
`
constant FOOTER =`
  </BODY>
</HTML>
`
constant LINE = 
`<div class="%s">%s</div>
`

regex exec   = regex:new(`^\s*[0-9]+:`)
regex noexec = regex:new(`^\s*#####:`)

function write_html( sequence gcov )
	
	sequence html_file = replace( gcov, "html", length(gcov) - 4, length(gcov) )
	
	if not file_exists( gcov ) then
		return 0
	end if
	
	printf( 1, "writing html for %s\n", {gcov})
	atom html = open( html_file, "w", 1 )
	atom fin  = open( gcov, "r", 1 )
	
	integer
		lines    = 0,
		executed = 0
	
	puts( html, HEADER )
	
	object in
	while sequence(in) with entry do
		sequence line_class
		if regex:has_match( exec, in ) then
			line_class = "exec"
			lines += 1
			executed += 1
		elsif regex:has_match( noexec, in ) then
			lines += 1
			line_class = "noexec"
		else
			line_class = "nocode"
		end if
		printf( html, LINE, { line_class, in } )
		
	entry
		in = gets( fin )
	end while
	puts( html, FOOTER )
	
	sequence target_css = dirname( gcov ) & "/gcov.css"
	if not file_exists( target_css ) then
		atom css = open( target_css, "w", 1 )
		puts( css, CSS )
	end if
	return { html_file, lines, executed }
end function

constant FILE_ROW = `<tr class="%s"><td><a href="%s">%s</a></td><td>%d</td><td>%d</td><td>%0.2f%%</td></tr>
`
procedure write_index( sequence coveragedir, sequence objectdir, sequence stats )
	atom index = open( coveragedir & objectdir & "/index.html", "w", 1 )
	
	stats = sort( stats )
	puts( index, HEADER )
	puts( index, "\n<table>\n" )
	
	puts( index, "<tr><td>File</td><td>Lines</td><td>Executed</td><td>%</td></tr>\n" )
	for i = 1 to length(stats) do
		atom  pct = 100
		if stats[i][3] then
			pct = stats[i][4] / stats[i][3] * 100
		end if
		printf( index, FILE_ROW, {"nocode", stats[i][2], stats[i][1], stats[i][3], stats[i][4], pct})
	end for
	
	puts( index, "</table>\n" )
	puts( index, FOOTER )
	
end procedure

function process_builddir( sequence builddir, sequence objectdir, sequence coveragedir, sequence sourcedir )
	sequence stats = {}
	
	-- backend object files are in builddir/back, but source files
	sequence source_files = dir( "be_*.c" )
	sequence back_dir = builddir & '/' & objectdir & "/back"
	for i = 1 to length( source_files ) do
		system( sprintf(`gcov -o "%s" %s`, { back_dir, source_files[i][D_NAME] }),-2)
		
		sequence 
			source = sourcedir & '/' & source_files[i][D_NAME] & ".gcov",
			target = coveragedir & objectdir & "/back"
		if file_exists( source ) then
			system( sprintf(`mv "%s" "%s"`,{source, target}), 2 )
			
			object result = write_html( target & '/' &  source_files[i][D_NAME] & ".gcov")
			if sequence( result ) then
				stats = append( stats, prepend( result, source_files[i][D_NAME] ) )
			end if
		end if
	end for
	
	-- euphoria translated source files and object files are in the builddir
	chdir( builddir & '/' & objectdir )
	object euphoria_translated_source = dir( "*.c" )
	if sequence( euphoria_translated_source ) then
		source_files = euphoria_translated_source
		for i = 1 to length( source_files ) do
			system( sprintf(`gcov %s`, { source_files[i][D_NAME] }),-2)
			
			sequence 
				source = builddir & '/' & objectdir & '/' & source_files[i][D_NAME] & ".gcov",
				target = coveragedir & objectdir

			system( sprintf(`mv "%s" "%s"`, {source, target}), 2)
			object result = write_html( target & '/' &  source_files[i][D_NAME] & ".gcov")
			if sequence( result ) then
				stats = append( stats, prepend( result, source_files[i][D_NAME] ) )
			end if
		end for
		
	end if
		
	write_index( coveragedir, objectdir, stats )
	return aggregate( coveragedir, objectdir, stats )
end function

function aggregate( sequence coveragedir, sequence objectdir, sequence stats )
	if not length( stats ) then
		return repeat( 0, 4 )
	end if
	sequence total = repeat( 0, length( stats[1] ) )
	total[1] = objectdir
	total[2] = coveragedir & objectdir & "/index.html"
	for i = 1 to length( stats ) do
		total[3] += stats[i][3]
		total[4] += stats[i][4]
	end for
	return total
end function

function read_builddir()
	-- assumes default location...
	return current_dir() & "/build/"
end function

procedure main()
	sequence builddir = read_builddir()
	sequence coveragedir = builddir & "coverage"
	sequence sourcedir = current_dir()
	
	create_directory( coveragedir )
	coveragedir &= '/'
	
	sequence stats = {}
	for i = 1 to length( BUILDDIRS ) do
		chdir( sourcedir )
		create_directory( coveragedir & BUILDDIRS[i] & "/back" )
		stats = append( stats, process_builddir( builddir, BUILDDIRS[i], coveragedir, sourcedir ) )
	end for
	write_index( coveragedir, "", stats )
end procedure
main()
