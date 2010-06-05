include std/filesys.e
include std/regex.e
include std/io.e

constant H_FILE = `
#ifndef COVERAGE_H_
#define COVERAGE_H_

#define COVER_LINE %scover_line
#define COVER_ROUTINE %scover_routine
#define WRITE_COVERAGE_DB %swrite_coverage_db

void COVER_LINE( int );
void COVER_ROUTINE( int );
long WRITE_COVERAGE_DB();

#endif
`

sequence cmd = command_line()
if length( cmd ) < 3 then
	puts(2, "Missing build directory\n")
	abort( 1 )
end if


procedure create_header( sequence builddir )
	sequence c_files = dir( builddir )

	for i = 1 to length( c_files ) label "i_loop" do
		if eu:match( "coverage", c_files[i][D_NAME] ) then
		
			regex filenum = regex:new( `void (_[0-9]+)cover_line` )
			sequence lines = read_lines( builddir & '/' & c_files[i][D_NAME] )
			
			for j = 1 to length( lines ) do
				if regex:has_match( filenum, lines[j] ) then
					sequence m = regex:all_matches( filenum, lines[j] )
					atom out = open( builddir & "/back/coverage.h", "w", 1 )
					printf( out, H_FILE, repeat( m[1][2], 3 ) )
					exit "i_loop"
				end if
			end for
			
		end if
	end for
end procedure

for i = 3 to length( cmd ) do
	create_header( cmd[i] )
end for
