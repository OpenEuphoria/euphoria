-- (c) Copyright - See License.txt
--
-- Instruments euphoria source code for code coverage analysis

include std/filesys.e
include std/regex.e
include std/map.e
include std/eds.e

include global.e
include error.e
include emit.e
include symtab.e
include reswords.e
include scanner.e

sequence covered_files = {}
sequence file_coverage = {}
sequence coverage_db_name = ""
integer  coverage_erase = 0

sequence line_map    = {}
sequence routine_map = {}

sequence included_lines = {}

export procedure check_coverage()

	for i = length( file_coverage ) + 1 to length( file_name ) do
		file_coverage &= find( canonical_path( file_name[i] ), covered_files )
	end for
end procedure

--** 
-- Processes the files in the application vs the files requested for coverage.
-- Creates the coverage db.
export procedure init_coverage()
	
	for i = 1 to length( file_coverage ) do
		file_coverage[i] = find( canonical_path( file_name[i] ), covered_files )
	end for
	
	if equal( coverage_db_name, "" ) then
		sequence cmd = command_line()
		coverage_db_name = canonical_path( filebase( cmd[2] ) & "-cvg.edb" )
	end if
	
	if coverage_erase and file_exists( coverage_db_name ) then
		puts(1, "Deleting coverage DB!\n")
		if not delete_file( coverage_db_name ) then
			CompileErr( 335, { coverage_db_name } )
		end if
	end if
	
	if db_open( coverage_db_name ) = DB_OK then
		read_coverage_db()
		db_close()
	end if
end procedure

procedure write_map( map coverage, sequence table_name )
	if db_select_table( table_name ) != DB_OK then
		if db_create_table( table_name ) != DB_OK then
			CompileErr( 336, {table_name} )
		end if
	end if
	
	sequence keys = map:keys( coverage )
	for i = 1 to length( keys ) do
		integer rec = db_find_key( keys[i] )
		integer val = map:get( coverage, keys[i] )
		if rec > 0 then
			db_replace_data( rec, val )
		else
			db_insert( keys[i], val )
		end if
	end for
end procedure

export procedure write_coverage_db()
	if not length( covered_files ) then
		return
	end if
	
	if DB_OK != db_open( coverage_db_name ) then
		if DB_OK != db_create( coverage_db_name ) then
			CompileErr( 337, { coverage_db_name } )
		end if
	end if
	
	process_lines()
	
	for tx = 1 to length( covered_files ) do
		write_map( routine_map[tx], 'r' & covered_files[tx] )
		write_map( line_map[tx],    'l' & covered_files[tx] )
	end for
	db_close()
	
	routine_map = {}
	line_map    = {}
end procedure

procedure read_coverage_db()
	sequence tables = db_table_list()
	
	for i = 1 to length( tables ) do
		sequence name = tables[i][2..$]
		integer fx = find( name, covered_files )
		if not fx then
			continue
		end if
		
		db_select_table( tables[i] )
		map the_map
		if tables[i][1] = 'r' then
			-- routines
			the_map = routine_map[fx]
			
		else
			-- lines
			the_map = line_map[fx]
			
		end if
		
		for j = 1 to db_table_size() do
			map:put( the_map, db_record_key( j ), db_record_data( j ), map:ADD )
		end for
	end for
end procedure

export procedure coverage_db( sequence name )
	coverage_db_name = name
end procedure

--**
-- Returns 1 if the current file is to be included in coverage stats.
export function coverage_on()
	return file_coverage[current_file_no]
end function

regex eu_file = regex:new( `(?:\.e|\.eu|\.ew|\.exu|\.ex|\.exw)\s*$`, CASELESS )

--**
-- Add the specified file or directory to the coverage analysis.
export procedure add_coverage( sequence cover_this )
	
	sequence path = canonical_path( cover_this )
	
	if file_type( path ) = FILETYPE_DIRECTORY then
		sequence files = dir( path  )
		
		for i = 1 to length( files ) do
			if find( 'd', files[i][D_ATTRIBUTES] ) then
				if '.' != files[i][D_NAME][1] then
					add_coverage( cover_this & '/' & files[i][D_NAME] )
				end if
			
			elsif regex:has_match( eu_file, files[i][D_NAME] ) then
				sequence canonical = canonical_path( cover_this & '/' & files[i][D_NAME] )
				if not find( canonical, covered_files ) then
					covered_files = append( covered_files, canonical )
					routine_map &= map:new()
					line_map    &= map:new()
				end if
			end if
		end for
	elsif regex:has_match( eu_file, path ) 
	and not find( path, covered_files ) then
		covered_files = append( covered_files, path )
		routine_map &= map:new()
		line_map    &= map:new()
	end if
end procedure

export procedure new_coverage_db()
	coverage_erase = 1
end procedure

export procedure include_line( integer line_number )
	if coverage_on() then
		emit_op( COVERAGE_LINE )
		emit_addr( gline_number )
		
		included_lines &= line_number
	end if
end procedure

export procedure include_routine()
	if coverage_on() then
		emit_op( COVERAGE_ROUTINE )
		emit_addr( CurrentSub )
		
		-- make sure it's in the map
		integer file_no = SymTab[CurrentSub][S_FILE_NO]
		map:put( routine_map[file_coverage[file_no]], sym_name( CurrentSub ), 0, map:ADD )
	end if
end procedure

procedure process_lines()
	if atom(slist[$]) then
		slist = s_expand( slist )
	end if
	for i = 1 to length( included_lines ) do
		sequence sline = slist[included_lines[i]]
		integer file = file_coverage[sline[LOCAL_FILE_NO]]
		if file then
			integer line = sline[LINE]
			map:put( line_map[file], line, 0, map:ADD )
		end if
	end for
end procedure

export function cover_line( integer gline_number )
	if atom(slist[$]) then
		slist = s_expand(slist)
	end if
	sequence sline = slist[gline_number]
	integer file = file_coverage[sline[LOCAL_FILE_NO]]
	if file then
		integer line = sline[LINE]
		map:put( line_map[file], line, 1, map:ADD )
	end if
	return 0
end function

export function cover_routine( symtab_index sub )
	integer file_no = SymTab[sub][S_FILE_NO]
	map:put( routine_map[file_coverage[file_no]], sym_name( sub ), 1, map:ADD )
	return 0
end function
