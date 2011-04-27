include std/unittest.e
include std/filesys.e
include std/sort.e
include std/pretty.e

include database.e

-- TODO: add actual tests
object void

void = delete_file("testunit.edb")
sequence dbname = canonical_path("testunit.edb")
test_equal("create db #1", DB_OK, db_create("testunit.edb", DB_LOCK_EXCLUSIVE))
test_equal("create db #2", DB_EXISTS_ALREADY, db_create("testunit", DB_LOCK_SHARED))
db_close()


test_equal("open db", DB_OK, db_open("testunit", DB_LOCK_EXCLUSIVE))
test_equal("create table #1", DB_OK, db_create_table("first"))
test_equal("create table #2", DB_OK, db_create_table("second"))
test_equal("create table #3", DB_OK, db_create_table("third"))
test_equal("create table #4", DB_EXISTS_ALREADY, db_create_table("third"))

db_delete_table("first")
db_delete_table("third")
db_delete_table("second")


test_equal("create table #5", DB_OK, db_create_table("second"))
test_equal("create table #6", DB_OK, db_create_table("first"))
test_equal("create table #7", DB_OK, db_create_table("third"))
test_equal("table_list", {"first", "second", "third"}, sort(db_table_list()))

test_equal("select table #1", DB_OK, db_select_table("first"))

test_equal("select table #2", DB_OK, db_select_table("second"))
-- Ensure at least one record is in the second table.
test_equal("insert table 'second' #1", DB_OK, db_insert(-1, {}))

test_equal("select table #3", DB_OK, db_select_table("third"))
test_equal("select table #4", DB_OK, db_select_table("third"))

test_equal("select table #4", DB_OPEN_FAIL, db_select_table("bad table name"))

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

db_replace_data( 1, 1 )
test_equal("replace data", 1, db_record_data( 1 ) )

void = db_select_table("third")
void = db_select_table("first")
db_delete_record(4 )

void = db_select_table("first")
db_delete_table("third")
db_select_table("first")

for i = 1 to 500 do
    void = db_insert(i, sprintf("Record %05d",i))
end for
test_equal("db_table_size after mass insert", 503, db_table_size())


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
test_equal("db_table_size after mass delete ", 489, db_table_size())

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

-- Change table so its not the same as we got the recids from.
void = db_select_table("second")
test_equal("db_table_size before recid fetch ", 1, db_table_size())

-- create lots of tables
for i = 1 to 10 do
	test_equal( sprintf("create lots of tables #%d", i ), DB_OK, db_create_table( sprintf("lots of tables #%d", i) ) )
end for

db_close()

void = delete_file("testunit.edb")
void = delete_file("testunit.t0")

procedure test_db_select()
	-- create some fresh databases:
	sequence the_db = "the_db.edb"
	sequence the_db_full = canonical_path(the_db)
	sequence the_alias = "myDB"
	
	
	delete_file( the_db_full )
	test_equal("w/o caching - create", DB_OK,  db_create( the_db_full, DB_LOCK_EXCLUSIVE ) )
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

end procedure
test_db_select()


sequence error_msg = ""
procedure db_fatal_error( sequence msg )
	error_msg = msg
end procedure

function get_db_error()
	sequence msg = error_msg
	error_msg = ""
	return msg
end function

procedure test_dump()
	db_fatal_id = routine_id("db_fatal_error")
	db_close()
	if file_exists( "dump.edb" ) then
		delete_file( "dump.edb" )
	end if
	test_equal( "create dump.edb", DB_OK, db_create( "dump.edb" , DB_LOCK_EXCLUSIVE) )
	
	test_equal( "create dump.edb table 1", DB_OK, db_create_table( "table 1" ) )
	test_equal( "check for dump.edb #1", {"table 1"}, db_table_list() )
	
	test_equal( "create dump.edb table 2", DB_OK, db_create_table( "table-2" ) )
	test_equal( "check for dump.edb #2", {"table 1", "table-2"}, db_table_list() )
	
	db_rename_table( "table 1", "table-1")
	test_equal( "renamed table", {"table-1", "table-2"}, db_table_list() )
	
	db_select_table( "table-1" )
	db_insert( 1, 1 )
	db_insert( 2, 1 )
	db_insert( 3, 1 )
	db_delete_record( 2 )
	
	if file_exists( "eds-dump.txt" ) then
		delete_file( "eds-dump.txt" )
	end if
	
	db_dump( open( "eds-dump.txt", "w", 1 ), 1 )
	
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
	
	--delete_file( "eds-dump.txt" )
	delete_file( "dump.edb" )
end procedure
test_dump()



test_report()
