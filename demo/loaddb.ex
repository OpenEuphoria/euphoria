--****
-- === loaddb.ex
--

include std/error.e
include std/io.e
include std/eds.e
include std/text.e
include std/sequence.e
include std/search.e
include std/get.e
include std/filesys.e

include std/console.e

without warning
--**
--@nodoc@
override procedure abort(integer x)
	maybe_any_key()
	eu:abort(x)
end procedure

procedure ProcessFile(sequence pFileName)

	object lLine
	integer fh
	atom fpos
	sequence tablename
	sequence dbname
	sequence location
	object recd
	
	dbname = ""
	tablename = ""
	location = ""
	
	fh = open(pFileName, "r")
	if fh = -1 then
		printf(1, "Failed to open input file : %s\n" , {pFileName})
		abort(1)
	end if
	
	fpos = where(fh)
	lLine = gets(fh)
	while sequence(lLine) do
		lLine = trim(lLine)	
	
		if length(lLine) > 0 then
			
			if lLine[1] = '{' then
				seek(fh, fpos)
				recd = get(fh)
				if recd[1] != GET_SUCCESS then
					seek(fh, fpos)
					lLine = gets(fh)
					printf(1, "Bad get at '%s'", {lLine})
					abort(1)
				end if
				recd = recd[2]
				
				if length(tablename) = 0 then
					printf(1, "No active table", {})
					abort(1)
				end if	
				
				if length(recd) != 2 then
					printf(1, "Record must have exactly two elements.", {})
					abort(1)
				end if
				
				db_delete_record( db_find_key(recd[1]))
				db_insert(recd[1], recd[2])
				
			else
				if begins("location ", lLine) then
					location = trim(lLine[10 .. $])
					if length(location) = 0 then
						location = "."
					end if
					if location[$] != SLASH then
						location &= SLASH
					end if
					dbname = ""
					tablename = ""
					
				elsif begins("database ", lLine) then
					dbname = trim(lLine[10 .. $])
					tablename = ""
					create_directory(location)
					chdir(location)
					db_create(dbname, DB_LOCK_NO)
					db_select(dbname, DB_LOCK_NO)
					
				elsif begins("table ", lLine) then
					if length(dbname) = 0 then
						printf(1, "No active database", {})
						abort(1)
					end if
					tablename = trim(lLine[7 .. $])
					db_create_table(tablename)
					db_select_table(tablename)
					
				elsif begins("dump", lLine) then
					if length(lLine) = 4 then
						db_dump(1)
					elsif lLine[5] = ' ' then
						db_dump( trim(lLine[6..$]))
					else
						db_dump( lLine[5..$])
					end if
					
				end if
			end if
		end if
		fpos = where(fh)
		lLine = gets(fh)
	end while
	
	close(fh)
	db_close()
	
end procedure

procedure main(sequence pArgs)

	ifdef WINDOWS and GUI then
	    writefln("This program must be run from the command-line.")
	    abort(0)
	end ifdef
	
	if length(pArgs) < 3 then
		if equal(pArgs[1], pArgs[2]) then
			writefln("Usage: [] SourceFile\n", {pArgs[2]})
		else
			writefln("Usage: eui [] SourceFile\n", {pArgs[2]})
		end if
		abort(0)
	end if
	
	for i = 3 to length(pArgs) do
		ProcessFile( pArgs[i] )
	end for
	
end procedure

main( command_line() )

	
