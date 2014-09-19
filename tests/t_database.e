include std/unittest.e
include std/eds.e
include std/filesys.e
include std/sort.e
include std/pretty.e

-- TODO: add actual tests
object void

void = delete_file("testunit.edb")
sequence dbname = canonical_path("testunit.edb")
test_equal("current db #1", "", db_current())
test_equal("create db #1", DB_OK, db_create("testunit.edb", DB_LOCK_EXCLUSIVE))
test_equal("current db #2", dbname, db_current())
test_equal("create db #2", DB_EXISTS_ALREADY, db_create("testunit", DB_LOCK_SHARED))
test_equal("current db #3", dbname, db_current())
db_close()
test_equal("current db #4", "", db_current())


test_equal("open db", DB_OK, db_open("testunit", DB_LOCK_EXCLUSIVE))
test_equal("current db #5", dbname, db_current())

test_equal("create table #0a", DB_BAD_NAME, db_create_table("zero" & 0))
test_equal("create table #0b", DB_BAD_NAME, db_create_table({5,"bad"}))

test_equal("create table #1", DB_OK, db_create_table("first"))
test_equal("current table #1", "first", db_current_table())

test_equal("create table #2", DB_OK, db_create_table("second"))
test_equal("current table #2", "second", db_current_table())

test_equal("create table #3", DB_OK, db_create_table("third"))
test_equal("current table #3", "third", db_current_table())

test_equal("create table #4", DB_EXISTS_ALREADY, db_create_table("third"))
test_equal("current table #4", "third", db_current_table())

db_delete_table("first")
db_delete_table("third")
db_delete_table("second")
test_equal("delete table #1", "", db_current_table())


test_equal("create table #5", DB_OK, db_create_table("second"))
test_equal("create table #6", DB_OK, db_create_table("first"))
test_equal("create table #7", DB_OK, db_create_table("third"))
test_equal("table_list", {"first", "second", "third"}, sort(db_table_list()))

test_equal("select table #1", DB_OK, db_select_table("first"))
test_equal("current table #5", "first", db_current_table())

test_equal("select table #2", DB_OK, db_select_table("second"))
test_equal("current table #6", "second", db_current_table())
-- Ensure at least one record is in the second table.
test_equal("insert table 'second' #1", DB_OK, db_insert(-1, {}))

test_equal("select table #3", DB_OK, db_select_table("third"))
test_equal("current table #7", "third", db_current_table())
test_equal("select table #4", DB_OK, db_select_table("third"))
test_equal("current table #8", "third", db_current_table())

test_equal("select table #4", DB_OPEN_FAIL, db_select_table("bad table name"))
test_equal("current table #9", "third", db_current_table())

void = db_select_table("first")
test_equal("insert #1", DB_OK, db_insert("one", {1,2,3,"four"}))
test_equal("insert #2", DB_OK, db_insert("two", {2,3,4,"five"}))
test_equal("insert #3", DB_OK, db_insert("three", {3,4,5,"six"}))
test_equal("insert #4", DB_OK, db_insert("four", {4,5,6,"seven"}))
test_equal("insert #5", DB_EXISTS_ALREADY, db_insert("two", {9,9,9,"nine"}))


void = db_select_table("third")
test_equal("insert #6", DB_OK, db_insert("1", {1,2,3,"four"}))
test_equal("insert #7", DB_OK, db_insert("2", {2,3,4,"five"}))
test_equal("insert #8", DB_OK, db_insert("3", {3,4,5,"six"}))
test_equal("insert #9", DB_OK, db_insert("4", {4,5,6,"seven"}))


void = db_select_table("first")
test_equal("db_insert w/table name #1", DB_OK, db_insert("5", {6,7,8,"nine"}, "third"))
test_equal("db_insert w/table name #2", DB_OK, db_insert("five", {6,7,8,"nine"}, "first"))
test_equal("db_find_key w/table name #1", 5, db_find_key("5", "third"))
test_equal("db_find_key w/table name #2", 4, db_find_key("three", "first"))
db_delete_record(5, "third")
db_delete_record(4, "first")
test_equal("db_table_size/db_delete_record w/table name #1", 4, db_table_size("third"))
test_equal("db_table_size/db_delete_record w/table name #2", 4, db_table_size("first"))
db_replace_data(1, {3,3,3,"third"}, "third")
db_replace_data(1, {1,1,1,"first"}, "first")
test_equal("db_replace_data w/table name #1", {3,3,3,"third"}, db_record_data(1, "third"))
test_equal("db_replace_data w/table name #1", {1,1,1,"first"}, db_record_data(1, "first"))

void = db_select_table("first")
db_delete_table("third")
db_clear_table("first")
test_equal("db_table_size after clear #1", 0, db_table_size("first"))
test_equal("insert #10", DB_OK, db_insert("one", {1,2,3,"four"}, "first"))
test_equal("db_table_size ", 1, db_table_size("first"))
db_delete_record(1)
test_equal("db_table_size after delete", 0, db_table_size("first"))

for i = 1 to 500 do
    void = db_insert(i, sprintf("Record %05d",i))
end for
test_equal("db_table_size after mass insert", 500, db_table_size("first"))
db_clear_table("first")
check_free_list()
test_equal("db_table_size after clear #2", 0, db_table_size("first"))


for i = 1 to 100 do
    void = db_insert(i, sprintf("Record %05d",i))
end for
check_free_list()

integer n
for i = 3 to 100 by 7 do
	n = db_find_key(i)
    db_delete_record(n)
end for
check_free_list()
test_equal("db_table_size after mass delete ", 86, db_table_size("first"))

for i = 3 to 100 by 7 do
	n = db_find_key(i)
    test_true(sprintf("Delete of '%d' worked", i), n < 0)
end for

-- Saves table 'first' keys to cache and gets table 'second' keys
void = db_select_table("second")
test_true("'Second records are still okay'", db_find_key(-1) > 0)

-- Saves table 'second' keys to cache and gets table 'first' keys
void = db_select_table("first")
for i = 3 to 100 by 7 do
	n = db_find_key(i)
    test_true(sprintf("Delete of '%d' still worked", i), n < 0)
end for
for i = 2 to 100 by 7 do
	n = db_find_key(i)
    test_true(sprintf("'%d' still exists", i), n > 0)
end for


void = delete_file("testunit.t0")
test_equal("compress", DB_OK, db_compress())
check_free_list()
test_equal("db_table_size after compress ", 86, db_table_size("first"))

atom rid1, rid2
rid1 = db_get_recid(3)
test_true("get recid #1", rid1 = -1)
rid1 = db_get_recid(20)
test_true("get recid #2", rid1 > 0)
rid2 = db_get_recid(99)
test_true("get recid #3", rid2 > 0)

-- Change table so its not the same as we got the recids from.
void = db_select_table("second")
test_equal("db_table_size before recid fetch ", 1, db_table_size())

object rec

rec = db_record_recid(rid2)
test_equal("fetch with recid #1", {99, "Record 00099"}, rec) 
test_equal("fetch with recid #2", {20, "Record 00020"}, db_record_recid(rid1)) 
rec[2] = "Updated 99"
db_replace_recid(rid2, rec[2]) 
test_equal("fetch with recid #3", {99, "Updated 99"}, db_record_recid(rid2)) 

-- create lots of tables
for i = 1 to 10 do
	test_equal( sprintf("create lots of tables #%d", i ), DB_OK, db_create_table( sprintf("lots of tables #%d", i) ) )
end for

db_close()
test_equal("current db #5", "", db_current())
test_equal("current table after close", "", db_current_table())

-- Attempt to get record data after the database is closed.
rec = db_record_data(rid2)
test_true( "Error recorded", length(db_get_errors()) > 0)
test_true( "Errors cleared", length(db_get_errors()) = 0)



void = delete_file("testunit.edb")
void = delete_file("testunit.t0")

procedure test_db_select()
	-- create some fresh databases:
	sequence the_db = "the_db.edb"
	sequence the_db_full = canonical_path(the_db)
	sequence the_alias = "myDB"
	
	test_equal("connect 0 - no path", DB_OPEN_FAIL, db_connect(the_alias))
	test_equal("connect 1 - using connection string style", DB_OK, db_connect(the_alias, the_db, "init_tables=3, init_free=-1"))
	test_equal("connect 2", {the_db_full,{DB_LOCK_NO,3,3}}, db_connect(the_alias, , CONNECTION))
	
	test_equal("disconnect 1", DB_OK, db_connect(the_alias, , DISCONNECT))
	test_equal("disconnect 2 - already disconnected", DB_OPEN_FAIL, db_connect(the_alias, "", DISCONNECT))
	test_equal("connect 3 - not connected", DB_OPEN_FAIL, db_connect(the_alias, , CONNECTION))
	
	test_equal("connect 4 - using kv style", DB_OK, db_connect(the_alias, the_db, {{INIT_TABLES,3}, {INIT_FREE,-1}}))
	test_equal("connect 5", {the_db_full,{DB_LOCK_NO,3,3}}, db_connect(the_alias,"", CONNECTION))
	test_equal("connect 6 - already connected", DB_OPEN_FAIL, db_connect(the_alias, the_db, {{INIT_TABLES,3}, {INIT_FREE,-1}}))
	
	-- WITHOUT CACHING
	db_set_caching(0)
	
	delete_file( the_db_full )
	test_equal("w/o caching - create", DB_OK,  db_create( the_alias ) )
	db_select( the_db_full )
	db_create_table( "TABLEDEF" )
	db_insert( "MY_DATA", "original data" )
	
	object temp_data = "replacement data"
	
	-- delete TABLEDEF entry in the_db
	db_select( the_db )
	db_select_table( "TABLEDEF" )
	db_delete_record( db_find_key( "MY_DATA" ) )
	test_equal( "Found MY_DATA #1 w/o caching", -1, db_find_key( "MY_DATA" ))
	
	-- insert new TABLEDEF entry into the_db
	db_select( the_alias )
	db_select_table( "TABLEDEF" )
	test_equal( "Found MY_DATA #2 w/o caching", 0, db_insert( "MY_DATA", temp_data ))
	
	object the_data = db_record_data( db_find_key( "MY_DATA" ) )
	test_equal( "w/o caching -> insert, delete, select db/table, insert, get", temp_data, the_data )
	delete_file( the_db )

	-- WITH CACHING
	db_set_caching(1)
	
	delete_file( the_db )		
	db_create( the_db )
	db_create_table( "TABLEDEF" )
	db_insert( "MY_DATA", "original data" )
	
	temp_data = "replacement data"
	
	-- delete TABLEDEF entry in the_db
	db_select( the_db )
	db_select_table( "TABLEDEF" )
	db_delete_record( db_find_key( "MY_DATA" ) )
	test_equal( "db_find_key( \"MY_DATA\" ) w/caching", -1, db_find_key( "MY_DATA" ))
	
	-- insert new TABLEDEF entry into the_db
	db_select( the_db )
	db_select_table( "TABLEDEF" )
	test_equal( "db_insert( \"MY_DATA\", \"" & temp_data & "\" ) w/caching", 0, db_insert( "MY_DATA", temp_data ))
	
	the_data = db_record_data( db_find_key( "MY_DATA" ) )
	test_equal( "w/caching -> insert, delete, select db/table, insert, get", temp_data, the_data )
	
	-- Close the database before deleting it.
	db_close()
	delete_file( the_db )
end procedure
test_db_select()


sequence error_msg = ""
procedure db_fatal_error( sequence msg )
	error_msg = msg
end procedure

function get_db_error()
	sequence msg = error_msg
	error_msg = ""
	db_get_errors( 1 )
	return msg
end function

procedure test_dump()
	db_fatal_id = routine_id("db_fatal_error")
	db_close()
	if file_exists( "dump.edb" ) then
		delete_file( "dump.edb" )
	end if
	test_equal( "create dump.edb", DB_OK, db_create( "dump.edb" ) )
	
	db_delete_record( 1 )
	test_not_equal( "delete record with no table", "", get_db_error() )
	
	test_equal( "create dump.edb table 1", DB_OK, db_create_table( "table 1" ) )
	test_equal( "check for dump.edb #1", {"table 1"}, db_table_list() )
	
	test_equal( "create dump.edb table 2", DB_OK, db_create_table( "table-2" ) )
	test_equal( "check for dump.edb #2", {"table 1", "table-2"}, sort(db_table_list()) )
	
	db_rename_table( "Table 1", "table-1")
	test_not_equal( "rename table fail #1 check error msg", "", get_db_error() )
	test_equal( "rename table fail #1 check table list", {"table 1", "table-2"}, sort(db_table_list()) )
	
	db_rename_table( "table 1", "table-2")
	test_not_equal( "rename table fail #2 check error msg", "", get_db_error() )
	test_equal( "rename table fail #2", {"table 1", "table-2"}, sort(db_table_list()) )
	
	db_select_table( "table-2" )
	test_equal("current table before rename #1", "table-2", db_current_table())
	db_rename_table( "table 1", "table-1")
	test_equal( "renamed table #1", {"table-1", "table-2"}, sort(db_table_list()) )
	test_equal("current table after rename #1", "table-2", db_current_table())
	
	test_equal("current table before rename #2", "table-2", db_current_table())
	db_rename_table( "table-2", "table-3")
	test_equal( "renamed table #2", {"table-1", "table-3"}, sort(db_table_list()) )
	test_equal("current table after rename #2", "table-3", db_current_table())
	
	test_equal("current table before rename #3", "table-3", db_current_table())
	db_rename_table( "table-3", "table-2")
	test_equal( "renamed table #3", {"table-1", "table-2"}, sort(db_table_list()) )
	test_equal("current table after rename #3", "table-2", db_current_table())
	
	db_select_table( "table-1" )
	db_insert( 1, 1 )
	db_insert( 2, 1 )
	db_insert( 3, 1 )
	db_delete_record( 2 )
	
	db_delete_record( 1, "what table?")
	test_not_equal( "delete record with a bad table name", "", get_db_error() )
	
	if file_exists( "eds-dump.txt" ) then
		delete_file( "eds-dump.txt" )
	end if
	
	db_dump( -1 ) -- this should simply return
	test_not_equal( "passing invalid file handle to db_dump", "", get_db_error() )
	
	db_dump( "eds-dump.txt", 1 )
	
	atom fn = open( "eds-dump.txt", "r", 1 )
	test_not_equal( "opened dump file", -1, fn )
	
	sequence look_for = {
			"Database dump as at",
			"Euphoria Database System",
			`The "` & canonical_path("dump.edb") & `" database`,
			"Disk Dump",
			"DiskAddr",
			"[tables:",
			`table "table-1"`,
			"key: 1",
			"data: 1",
			"key: 3",
			"data: 1",
			`table "table-2"`,
			"[free blocks",
			{0}
			}
	
	object in
	integer lf = 1
	while sequence(in) with entry do
		if match( look_for[lf], in ) then
			lf += 1
		end if
	entry
		in = gets( fn )
	end while
	
	test_equal( "examine dump file", {0}, look_for[lf] )
	
	--delete_file( "eds-dump.txt" )
	delete_file( "dump.edb" )
end procedure
test_dump()

procedure test_create_clear_table_init_records()
       sequence the_db = "create_table_init_records.edb"
       sequence test_table
       db_fatal_id = routine_id( "db_fatal_error" )
       db_close()
       if file_exists( the_db ) then
               delete_file( the_db )
       end if
       test_equal( "create " & the_db, DB_OK, db_create( the_db ) )
       for i = 0 to 50 do
               test_table = sprintf( "table%d", i )
               test_equal( "create " & the_db & " " & test_table, DB_OK, db_create_table( test_table, i ) )
               for h = 0 to 10 do
                       db_insert( sprintf( "dummy%d", h ), {h, "data"} )
               end for
               db_clear_table( test_table, i )
               for h = 0 to 10 do
                       db_insert( sprintf( "dummy%d", h ), {h, "data"} )
               end for
       end for
       db_close()
       delete_file( the_db )
end procedure
test_create_clear_table_init_records()

test_report()
