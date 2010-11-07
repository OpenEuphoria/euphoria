-- process coverage database

include std/eds.e
include std/cmdline.e
include std/map.e
include std/filesys.e
include std/net/url.e
include std/regex.e
include std/sort.e

------------------------------------------------------------------------------
--
-- HTML TEMPLATES
--
-----------------------------------------------------------------------------

constant HEADER =`
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
   "http://www.w3.org/TR/html4/strict.dtd">
<HTML>
  <HEAD>
    <TITLE>%s</TITLE>
    %s
  </HEAD>
  <BODY>
`

constant FOOTER =`
  </BODY>
</HTML>
`

constant DEFAULT_CSS =`
<style type="text/css">
<!--
table     { margin: 10px 0px 0px 20px; }
th        { background-color: #ccccff; }
.summary_header, .summary_header a {
  border: black solid 1px;
  margin-top: 2em;
  padding: 3px 5px 3px 5px;
  font-weight: bold;
  background-color: #0033CC;
  color: white; }
.nocode   { font-family: monospace; font-style: italic; white-space: pre; background-color: #ffffdd; }
.exec     { font-family: monospace; white-space: pre; background-color: #bbffbb; }
.noexec   { font-family: monospace; white-space: pre; background-color: #ffbbbb; }
.num      { text-align: right; }
.line     { background-color: #ffcc00; padding-left: 5px; padding-right: 5px; }
.executed { background-color: #e0e0ff; }
.shade-row { background-color: #eeeeff; }
-->
</style>
`

constant USER_CSS = `<LINK href="%s" rel="stylesheet" type="text/css">`

-- Line number, times executed, style class, source
constant SOURCE_LINE = `
	<tr><td class="line num">%d</td><td class="executed num">%d</td><td><div class="%s">%s</div></td></tr>
`

-- Line number, style class, source
constant EMPTY_LINE = `
	<tr><td class="line num">%d</td><td></td><td><div class="nocode">%s</div></td></tr>
`

-- Line number, times executed, style class, routine name, source
constant ROUTINE_LINE = `
	<tr><td class="line num">%d</td><td class="executed num">%d</td><td><div class="%s"><a name="%s">%s</a></div></td></tr>
`

-- row class, url, name,
-- routines executed, routines total, percent routines executed,
-- lines executed, lines total, percent line executed
constant FILE_SUMMARY_ROW = `
	<tr class="%s"><td><a href="%s">%s</a></td><td class="num">%d</td><td class="num">%d</td><td class="num">%0.2f%%</td><td class="num">%d</td><td class="num">%d</td><td class="num">%0.2f%%</td><td class="num">%d</td></tr>
`

constant FILE_SUMMARY_ROW_NO_LINK = `
	<tr class="%s"><td>%s</td><td class="num">%d</td><td class="num">%d</td><td class="num">%0.2f%%</td><td class="num">%d</td><td class="num">%d</td><td class="num">%0.2f%%</td><td class="num">%d</td></tr>
`
-- row class, name, name, executed, total, percent executed
constant ROUTINE_SUMMARY_ROW = `
	<tr class="%s"><td><a href="#%s">%s()</a></td><td class="num">%d</td><td class="num">%d</td><td class="num">%0.2f%%</td><td class="num">%d</td></tr>
`

------------------------------------------------------------------------------
--
-- PROGRAM CODE
--
-----------------------------------------------------------------------------

constant opts = {
	{"o", 0, "output directory", { NO_CASE, HAS_PARAMETER, "dir" } },
	{"s", 0, "stylesheet", { NO_CASE, HAS_PARAMETER, "css-file" } },
	{"v", 0, "verbose output", { NO_CASE } },
	$
}

integer verbose = 0

sequence output_directory = ""
sequence coverage_db_name = ""
sequence stylesheet = ""

sequence line_map      = {}
sequence routine_map   = {}
sequence files         = {}
sequence file_coverage = {}
sequence short_names   = {}

map dir_coverage
map dir_map

procedure process_cmd_line()
	map cmd = cmd_parse( opts )
	sequence keys = map:keys( cmd )

	for i = 1 to length( keys ) do
		object val = map:get( cmd, keys[i] )
		switch keys[i] do
			case "o" then
				output_directory = val
			case "v" then
				verbose = 1
			case "s" then
				stylesheet = sprintf(USER_CSS, { val })
		end switch
	end for

	if length(stylesheet) = 0 then
		stylesheet = DEFAULT_CSS
	end if

	sequence extras = map:get( cmd, OPT_EXTRAS )
	if length( extras ) != 1 then
		puts( 2, "Expected a single input coverage database\n" )
		abort( 1 )
	end if

	coverage_db_name = canonical_path( extras[1] )
end procedure

procedure read_table( sequence table_name )
	if db_select_table( table_name ) != DB_OK then
		printf( 2, "Error reading table %s\n", {table_name})
		abort( 1 )
	end if

	sequence file_name = table_name[2..$]
	integer tx = find( file_name, files )
	if not tx then
		files = append( files, file_name )
		file_coverage &= 0
		tx = length( files )
		routine_map &= map:new()
		line_map    &= map:new()
	end if

	map coverage
	if table_name[1] = 'r' then
		coverage = routine_map[tx]
	else
		coverage = line_map[tx]
	end if

	integer records = db_table_size()
	for i = 1 to records do
		map:put( coverage, db_record_key( i ), db_record_data( i ) )
	end for
	if verbose then
		printf( 1, "%d records in table %s\n", { records, table_name } )
	end if
end procedure

procedure read_db()
	if db_open( coverage_db_name ) != DB_OK then
		printf( 2, "Could not open coverage DB %s\n", { coverage_db_name } )
		abort( 1 )
	end if

	sequence table_list = db_table_list()
	for i = 1 to length( table_list ) do
		read_table( table_list[i] )
	end for
end procedure

enum
	COV_FUNCS_TESTED,
	COV_FUNCS,
	COV_LINES_TESTED,
	COV_LINES,
	$
constant COV_SIZE = 4

function sum_coverage( map coverage )
	sequence keys = map:keys( coverage )
	integer covered = 0
	for i = 1 to length( keys ) do
		covered += 0 != map:get( coverage, keys[i] )
	end for
	return covered
end function

procedure analyze_coverage()
	dir_map = map:new()
	dir_coverage = map:new()

	for i = 1 to length( files ) do
		sequence file_name = files[i]
		sequence path = dirname( file_name )

		sequence coverage = repeat( 0, COV_SIZE )
		integer op

		coverage[COV_FUNCS] = map:size( routine_map[i] )
		coverage[COV_FUNCS_TESTED] = sum_coverage( routine_map[i] )

		coverage[COV_LINES] = map:size( line_map[i] )
		coverage[COV_LINES_TESTED] = sum_coverage( line_map[i] )

		file_coverage[i] = coverage

		if verbose then
			printf( 1, "file coverage: %s routines [%d / %d]  lines [%d / %d]\n",
				prepend( file_coverage[i], file_name ) )
		end if

		map:put( dir_map, path, i, map:APPEND )
		map:put( dir_coverage, path, coverage, map:ADD )

	end for

end procedure

procedure output_dir( sequence name )
	if not file_exists( name ) then
		if not create_directory( name ) then
			printf( 2, "Could not create output directory: %s\n", {name})
			abort(1)
		end if
	end if
end procedure

function get_style( integer executed )
	if executed then
		return "exec"
	else
		return "noexec"
	end if
end function

function calc_percent( atom numerator, atom denominator )
	if denominator then
		return 100 * numerator / denominator
	else
		return 100
	end if
end function

regex match_routine = regex:new( `^\s*(?:global\s+|public\s+|export\s+|override\s+|\s*)(?:function|procedure|type)\s+([a-zA-Z_0-9]+)\s*\(` )
regex match_end_routine = regex:new( `^\s*end\s+(?:function|procedure|type)` )

procedure write_file_html( sequence output_dir, integer fx )
	atom in  = open( files[fx], "r", 1 )
	if in = -1 then
		return
	end if

	sequence html_name = output_dir & encode( short_names[fx] ) & ".html"
	atom out = open( html_name, "w", 1 )

	sequence source_lines = {}
	integer line_number = 0

	map lines    = line_map[fx]
	map routines = routine_map[fx]

	object line
	map routine_lines = map:new()
	integer routine_line_count = 0
	integer routines_executed = 0
	integer routine_executed_count = 0
	integer total_routines = 0
	integer in_routine = 0
	sequence routine_name = ""

	integer total_lines    = 0
	integer total_executed = 0

	while sequence( line ) with entry do
		line[$] = ' ' -- remove the newline char
		sequence out_line
		if map:has( lines, line_number ) then
			integer executed = map:get( lines, line_number )
			total_lines += 1
			total_executed += 0 != executed
			out_line = sprintf( SOURCE_LINE, {line_number, executed, get_style( executed ), line})
			if in_routine then
				routine_line_count     += 1
				routine_executed_count += 0 != executed

				if regex:has_match( match_end_routine, line ) then
					in_routine = 0
					map:put( routine_lines, routine_name, { routine_executed_count, routine_line_count } )
					routine_executed_count = 0
					routine_line_count = 0
				else

				end if
			elsif regex:has_match( match_routine, line ) then
				sequence routine_matches = all_matches( match_routine, line )
				routine_name = routine_matches[1][2]
				integer r_executed = map:get( routines, routine_name)
				if r_executed and not executed then
					total_executed += 1
				end if
				executed = r_executed


				routines_executed += 0 != executed
				total_routines += 1
				out_line = sprintf( ROUTINE_LINE, { line_number, executed, get_style( executed ), routine_name, line })
				in_routine = 1
				routine_executed_count = 0 != executed
				routine_line_count = 1

			end if
		else
			out_line = sprintf( EMPTY_LINE, { line_number, line } )

			if in_routine and regex:has_match( match_end_routine, line ) then
				in_routine = 0
				map:put( routine_lines, routine_name, { routine_executed_count, routine_line_count } )
				routine_executed_count = 0
				routine_line_count = 0
			end if
		end if
		source_lines = append( source_lines, out_line )

	entry
		line = gets( in )
		line_number += 1
	end while

	file_coverage[fx][COV_FUNCS] = total_routines
	file_coverage[fx][COV_LINES_TESTED] = total_executed
	printf( out, HEADER, { short_names[fx], stylesheet } )


	atom percent
	puts( out, "<div class='summary_header'><a href='../index.html'>COVERAGE SUMMARY</a></div>\n" )
	-- file summary
	puts( out, "<div class='summary_header'>FILE SUMMARY</div>\n" )
	puts( out, "<table class='overview'>" &
	           "<tr><th>Name</th><th>Executed</th><th>Routines</th><th><span style='margin-left:3em;'>%</span>" &
	           "</th><th>Executed</th><th>Lines</th><th><span style='margin-left:3em;'>%</span></th><th>Unexecuted</th></tr>\n" )

	printf( out, FILE_SUMMARY_ROW_NO_LINK, { "", short_names[fx],
		routines_executed, map:size( routine_lines ), calc_percent( routines_executed, total_routines ),
		total_executed, total_lines, calc_percent( total_executed, total_lines ),
		total_lines - total_executed})

	puts( out, "</table>\n" )

	-- routine summary table


	sequence keys = map:keys( routine_lines )
	sequence routine_coverage = repeat( 0, length( keys ) )

	for i = 1 to length( keys ) do
		sequence coverage = map:get( routine_lines, keys[i] )
		total_executed = coverage[1]
		total_lines    = coverage[2]
		percent = calc_percent( total_executed, total_lines )
		routine_coverage[i] = { total_executed - total_lines, keys[i], keys[i],
			total_executed, total_lines, percent,total_lines -  total_executed }
	end for
	routine_coverage = sort( routine_coverage )

	puts( out, "<div class='summary_header'>ROUTINE SUMMARY</div>\n" )
	puts( out, "<table class='overview'><tr><th>Routine</th><th>Executed</th><th>Lines</th><th></th><th>Unexecuted</th></tr>\n" )
	for i = 1 to length( routine_coverage ) do
		sequence row_class = ""
		if and_bits( i, 1 ) then
			row_class = "shade-row"
		end if
		printf( out, ROUTINE_SUMMARY_ROW, { row_class } & routine_coverage[i][2..$] )
	end for
	puts( out, "</table>\n" )

	-- annotated source
	puts( out, "<div class='summary_header'>LINE COVERAGE DETAIL</div>\n" )
	puts( out, "<table class='code'><tr><th class='num'>#</th><th><span style='margin-left: 1em;'>Executed</span></th><th></th></tr>\n" )
	for i = 1 to length( source_lines ) do
		puts( out, source_lines[i] )
	end for
	puts( out, "</table>\n" )

	puts( out, FOOTER )
end procedure

procedure write_summary( sequence output_directory )
	atom out = open( output_directory & SLASH & "index.html", "w", 1 )

	integer total_lines             = 0
	integer total_lines_executed    = 0
	integer total_routines          = 0
	integer total_routines_executed = 0
	integer total_files_executed    = 0

	sequence file_data = repeat( 0, length( file_coverage ) )

	for i = 1 to length( file_coverage ) do
		sequence coverage = file_coverage[i]
		-- %, name, url, name, r.e., t.r., p.r.e., l.e., t.l., p.l.e.
		atom routine_percent = calc_percent( coverage[COV_FUNCS_TESTED], coverage[COV_FUNCS] )
		atom line_percent    = calc_percent( coverage[COV_LINES_TESTED], coverage[COV_LINES] )

		total_lines             += coverage[COV_LINES]
		total_lines_executed    += coverage[COV_LINES_TESTED]
		total_routines          += coverage[COV_FUNCS]
		total_routines_executed += coverage[COV_FUNCS_TESTED]

		total_files_executed    += 0 != coverage[COV_LINES_TESTED]
		sequence html_name = "files/" & encode( encode( short_names[i] ) ) & ".html"
		file_data[i] = { coverage[COV_LINES_TESTED] - coverage[COV_LINES], short_names[i], html_name,
			short_names[i],
			coverage[COV_FUNCS_TESTED], coverage[COV_FUNCS], routine_percent,
			coverage[COV_LINES_TESTED], coverage[COV_LINES], line_percent,
			coverage[COV_LINES] - coverage[COV_LINES_TESTED]}



	end for

	file_data = sort( file_data )

	printf( out, HEADER, { "Coverage Summary", stylesheet } )

	puts( out, "<div class='summary_header'>COVERAGE SUMMARY</div>\n" )
	puts( out, "<table class='summary'><tr><th>Files</th><th>Routines</th><th>Lines</th><th>Unexecuted</th></tr>\n" )
	printf( out,
		"<tr class='shade-row'>" &
		"<td>%d / %d [%0.2f%%]</td>" &
		"<td>%d / %d [%0.2f%%]</td>" &
		"<td>%d / %d [%0.2f%%]</td>" &
		"<td>%d</td>" &
		"</tr>\n",
		{
			total_files_executed,    length( files ), calc_percent( total_files_executed,    length( files ) ),
			total_routines_executed, total_routines,  calc_percent( total_routines_executed, total_routines ),
			total_lines_executed,    total_lines,     calc_percent( total_lines_executed,    total_lines ),
			total_lines - total_lines_executed } )

	puts( out, "</table>\n" )

	puts( out, "<div class='summary_header'>FILES COVERAGE SUMMARY</div>\n" )
	puts( out, "<table class='summary'><tr><th>Name</th><th>Executed</th><th>Routines</th><th><span style='margin-left:3em;'>%</span></th>" &
				"<th>Executed</th><th>Lines</th><th><span style='margin-left:3em;'>%</span></th><th>Unexecuted</th></tr>\n" )
	for i = 1 to length( file_data ) do
		sequence row_class = ""
		if and_bits( i, 1 ) then
			row_class = "shade-row"
		end if
		printf( out, FILE_SUMMARY_ROW, {row_class} & file_data[i][3..$] )
	end for
	puts( out, "</table>\n" )
	puts( out, FOOTER )
end procedure

function get_common( sequence a, sequence b )
	integer len = 1
	while len <= length(a) and len <= length(b) do
		if a[len] != b[len] then
			exit
		end if
		len += 1
	end while
	return a[1..len-1]
end function

procedure shorten_names()

	if not length(files) then
		return
	end if
	sequence common = files[1]
	for i = 2 to length(files) do
		common = get_common( common, files[i] )
	end for

	integer size = length( common )
	if length(common) and common[$] != SLASH then
		while size and common[size] != SLASH do
			size -= 1
		end while
	end if

	for i = 1 to length( files ) do
		short_names = append( short_names, remove( files[i], 1, size ) )
	end for
end procedure

procedure write_html()
	shorten_names()
	if equal( output_directory, "" ) then
		output_directory = dirname( coverage_db_name ) & SLASH & filebase( coverage_db_name )
	end if

	output_dir( output_directory )

	sequence files_dir = output_directory & SLASH & "files"
	output_dir( files_dir )

	output_directory &= SLASH
	files_dir &= SLASH



	for i = 1 to length( files ) do
		write_file_html( files_dir, i )
	end for

	write_summary( output_directory )
end procedure

procedure main()
	process_cmd_line()
	read_db()
	analyze_coverage()
	write_html()
end procedure
main()
