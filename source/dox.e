-- writes html dox

include std/error.e
include dot.e
include std/sets.e as set
include std/filesys.e
include std/sort.e
include std/map.e as map
include keylist.e
include std/search.e

include global.e
include reswords.e

sequence out_dir           = "eudox" & SLASH
integer  show_dependencies = 1
integer  show_callgraphs   = 1

set:set  files             = {}

export procedure set_out_dir( sequence out )
	if length( out ) and out[$] != SLASH then
		out &= SLASH
	end if
	out_dir = out
end procedure

export procedure suppress_dependencies()
	show_dependencies = 0
end procedure

export procedure suppress_callgraphs()
	show_callgraphs = 0
end procedure

export procedure suppress_stdlib()
	show_stdlib = 0
end procedure

export procedure document_file( sequence name )
	files = set:add_to( name, files )
end procedure

function dir_exists( sequence path )
	return file_type( path ) > 0
end function

include std/pretty.e
procedure make_dir( sequence path )
	if not create_directory( path ) then
		crash( sprintf( "could not create directory '%s'", {path} ) )
	end if
end procedure

-- make sure the directory structure exists
procedure make_dirs()
	if length( out_dir ) and not dir_exists( out_dir ) then
		make_dir( out_dir )
	end if
	
	if (show_dependencies or show_callgraphs) and not dir_exists( out_dir & "image" ) then
		make_dir( out_dir & "image" )
	end if
end procedure

function safe_open( sequence name )
	integer fn = open( out_dir & name, "w" )
	if fn = -1 then
		crash( sprintf( "Could not open file '%s' for writing", {name} ) )
	end if
	return fn
end function

procedure header( integer fn, sequence format, object data = {} )
	sequence title = sprintf( format, data )
	printf( fn, "<html><head><title>%s</title></head>\n", { title } )
	puts( fn, "<body>\n")
end procedure

procedure footer( integer fn )
	puts( fn, "</body></html>\n" )
end procedure


function underscore_name( sequence name )
	name = find_replace( '\\', name, '_' )
	name = find_replace( '/', name,  '_' )
	return name
end function

function link( sequence name )
	return underscore_name( name ) & ".html"
end function

procedure write_index()
	integer fn = safe_open( "index.html" )
	header( fn, "%s EuDox", {short_names[1]} )
	printf( fn, "<h1>Documentation for %s</h1>\n", { short_names[1] } )
	puts( fn, "<table><tr style=\"vertical-align:top;\"><td >\n" )
	puts( fn, "<h2>Files:</h2>\n" )
	puts( fn, "<ul>\n" )
	sequence files = short_names
	for i = 1 to length( files ) do
		files[i] = { files[i], i }
	end for
	files = files[1..1] & sort( files[2..$] )
	
	for i = 1 to length( files ) do
		if show_stdlib or (not std_libs[files[i][2]]) then
			printf( fn, "<li><a href=\"%s\">%s</a></li>\n", { link( files[i][1] ), files[i][1] } )
		end if
	end for
	puts( fn, "</ul>\n" )
	puts( fn, "</td><td>\n" )
	if show_dependencies then
		puts( fn, "<h2>Overall file dependency graph:</h2>\n" )
		puts( fn, "<a href=\"image/all_dep.png\"><img src=\"image/all_dep.png\" style=\"max-width: 800px;\"/></a>\n" )
	end if
	puts( fn, "</td></tr></table>\n" )
	footer( fn )
	close( fn )
end procedure

-- maps file -> sequence of all of its routines
map:map routine_map = map:new()
procedure make_routine_map()
	for s = length( keylist ) + 1 to length( SymTab ) do
		if length( SymTab[s] ) = SIZEOF_ROUTINE_ENTRY and find( SymTab[s][S_TOKEN], {FUNC, PROC, TYPE})
		and SymTab[s][S_SCOPE] != SC_PREDEF  then
			if not std_libs[ SymTab[s][S_FILE_NO] ] then
				map:put( routine_map, SymTab[s][S_FILE_NO], s, map:APPEND )
			end if
		end if
	end for
end procedure

map:map scope_map = map:new()
map:put( scope_map, SC_GLOBAL, "global " )
map:put( scope_map, SC_EXPORT, "export " )

-- TODO: make anchor for the signature
function signature( symtab_index proc )
	symtab_entry e = SymTab[proc]
	sequence sig = map:get( scope_map, e[S_SCOPE], "" )
	sig &= sprintf( "<a name=\"%d\">%s</a>(", { proc, SymTab[proc][S_NAME] } )
	
	integer args = e[S_NUM_ARGS]
	if args then
		symtab_index arg_sym = e[S_NEXT]
		symtab_entry arg = SymTab[arg_sym]
		
		while args > 0 with entry do
			sig &= ", "
			arg_sym = arg[S_NEXT]
			arg = SymTab[arg_sym]
		entry
			sig &= SymTab[arg[S_VTYPE]][S_NAME] & " " & arg[S_NAME]
			args -= 1
		end while
	end if
	return sig & " )"	
end function

function routine_ref( integer f, symtab_index proc, map:map call_map )
	map:map file_map = new_extra( map:nested_get( call_map, {f, proc}) )
	
	sequence files = map:keys( file_map )
	sequence names = {}
	for fx = 1 to length( files ) do
		integer fn = files[fx]
		if not std_libs[fn] then
			map:map proc_map = new_extra( map:get( file_map, fn) )
			sequence procs = map:keys( proc_map )
			for p = 1 to length( procs ) do
				symtab_index psym = procs[p]
				if SymTab[psym][S_SCOPE] != SC_PREDEF then
					names = append( names, { SymTab[psym][S_NAME], psym } )
				end if
			end for
		end if
	end for
	
	names = sort( names )
	for n = 1  to length( names ) do
		names[n] = names[n][2]
	end for
	return names
end function

function proc_link( symtab_index proc )
	symtab_entry e = SymTab[proc]
	return sprintf( "<a href=\"%s#%d\">%s</a>", { link( short_names[e[S_FILE_NO]] ), proc, e[S_NAME] } )
end function

procedure write_routines( integer fn, integer f )
	sequence rsyms = map:get( routine_map, f, {} )
	if not length( rsyms) then
		return
	end if
	
	for r = 1 to length( rsyms ) do
		rsyms[r] = { SymTab[rsyms[r]][S_NAME], rsyms[r] }
	end for
	rsyms = sort( rsyms )
	
	puts( fn, "<h2>Routines:</h2>\n" )
	
	for r = 1 to length( rsyms )  do
		printf( fn, "<table><tr><td>Signature:</td><td>%s</td></tr>\n", { signature( rsyms[r][2] ) } )
		sequence references    = routine_ref( f, rsyms[r][2], called_from )
		sequence referenced_by = routine_ref( f, rsyms[r][2], called_by )
		
		puts( fn, "<tr><td>References:</td><td>" )
		for i = 1 to length( references ) do
			puts( fn, proc_link( references[i]  ) )
			if i < length( references ) then
				puts( fn, ", " )
			end if
		end for
		puts( fn, "</td></tr>\n" )
		
		puts( fn, "<tr><td>Referenced by:</td><td>" )
		for i = 1 to length( referenced_by ) do
			puts( fn, proc_link( referenced_by[i] ) )
			if i < length( referenced_by ) then
				puts( fn, ", " )
			end if
		end for
		puts( fn, "</td></tr>\n" )
		
		if show_callgraphs then
			sequence image_file = sprintf( "image/%s_%s.png", { underscore_name( short_names[f] ), underscore_name( rsyms[r][1] ) } )
			printf( fn, "<tr><td>Call graph:</td><td><a href=\"%s\"><img src=\"%s\" style=\"max-width: 600px;\"/></a></td></tr>\n", repeat( image_file, 2 ) )
		end if
		
		puts( fn, "</table>\n<hr>\n" )
	end for
end procedure

procedure write_files()
	
	for f = 1 to length( short_names ) do
		if show_stdlib or not std_libs[f] then
			integer fn = safe_open( link( short_names[f] ) )
			header( fn, short_names[f] )
			printf( fn, "<h1>%s</h1>\n", { short_names[f] } )
			puts( fn, "<a href=\"index.html\">Main</a><br>\n" )
			if show_dependencies then
				puts( fn, "<h2>Include dependencies</h2>\n" )
				printf( fn, "<img src=\"image/%s.dep.png\"/>\n", {underscore_name( short_names[f] )} )
			end if
			write_routines( fn, f )
			footer( fn )
			close( fn )
		end if
	end for
end procedure

procedure dependencies()
	if not show_dependencies then
		return
	end if
	
	-- the whole shebang
	integer dotfn = safe_open( "_working_.dot" )
	puts( dotfn, diagram_includes( 1, show_stdlib ) )
	close( dotfn )
	object void = system_exec( sprintf("dot -Tpng \"%s_working_.dot\" -o \"%simage/all_dep.png\"", {out_dir, out_dir}), 2 )
	
	
	-- each file
	for f = 1 to length( short_names ) do
		if not std_libs[f] then
			dotfn = safe_open( "_working_.dot" )
			puts( dotfn, diagram_file_deps( f ) )
			close( dotfn )
			void = system_exec( 
				sprintf( "dot -Tpng \"%s_working_.dot\" -o \"%simage/%s.dep.png\"", { out_dir, out_dir, underscore_name( short_names[f] ) } ), 
				2 )
			puts(1, '.' )
		end if
	end for
	puts( 1, "\n" )
	
end procedure

function proc_file_name( symtab_index proc )
	symtab_entry e = SymTab[proc]
	return sprintf( "%s_%s", { underscore_name( short_names[e[S_FILE_NO]] ), underscore_name( e[S_NAME] ) } )
end function

procedure call_graphs()
	if not show_callgraphs then
		return
	end if
	
	sequence files = map:keys( routine_map )
	for f = 1 to length( files ) do
		integer file = files[f]
		if not std_libs[file] then
			sequence procs = map:get( routine_map, file, {} )
			for p = 1 to length( procs ) do
				symtab_index proc = procs[p]
				sequence name = proc_file_name( proc )
				integer dn = safe_open( "_working_.dot" )
				puts( dn, diagram_routine( proc ) )
				close( dn )
				integer ok = system_exec( sprintf( "dot -Tpng \"%s_working_.dot\" -o \"%simage/%s.png\"", {out_dir, out_dir, name}), 2)
				puts(1, '.' )
			end for
		end if
	end for
	puts(1, '\n')
end procedure

export procedure generate()
	puts(1, "generating dox\n" )
	puts(1, "preparing file structure\n" )
	make_dirs()
	
	puts(1, "initializing data\n" )
	short_files()
	make_routine_map()
	
	puts(1, "writing the index page\n" )
	write_index()
	
	puts(1, "writing the file pages\n" )
	write_files()
	
	puts(1, "generating the dependency graphs\n" )
	dependencies()
	
	puts(1, "generating the call graphs\n" )
	call_graphs()
	
	--if delete_file( sprintf( "%s_working_.dot", {out_dir}) ) then end if
end procedure
