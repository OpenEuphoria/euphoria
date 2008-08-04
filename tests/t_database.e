include std/unittest.e
include std/eds.e
include std/filesys.e
include std/sort.e

-- TODO: add actual tests
object void

void = delete_file("testunit.edb")

test_equal("current db #1", "", db_current())
test_equal("create db #1", DB_OK, db_create("testunit.edb", DB_LOCK_EXCLUSIVE))
test_equal("current db #2", "testunit.edb", db_current())
test_equal("create db #2", DB_EXISTS_ALREADY, db_create("testunit.edb", DB_LOCK_SHARED))
test_equal("current db #3", "testunit.edb", db_current())
db_close()
test_equal("current db #4", "", db_current())


test_equal("open db", DB_OK, db_open("testunit.edb", DB_LOCK_EXCLUSIVE))
test_equal("current db #4", "testunit.edb", db_current())

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

db_close()
test_equal("current db #5", "", db_current())

void = delete_file("testunit.edb")

test_report()
