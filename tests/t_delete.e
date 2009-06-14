without inline
include std/unittest.e

integer delete_counter = 0

function delete_count()
	integer count = delete_counter
	delete_counter = 0
	return count
end function

procedure custom_delete( object obj )
	delete_counter += 1
end procedure
constant CUSTOM_DELETE = routine_id("custom_delete")


atom x 
x = delete_routine( 1, CUSTOM_DELETE )
delete( x )
test_equal( "integer promoted and explicitly deleted", 1, delete_count() )

x = delete_routine( 1, CUSTOM_DELETE )
x = 0
test_equal( "integer promoted and deleted by derefs", 1, delete_count() )

x = delete_routine( 2, CUSTOM_DELETE )
x = delete_routine(x, CUSTOM_DELETE )
delete( x )
test_equal( "integer promoted, 2 delete routines and explicitly deleted", 2, delete_count() )

x = delete_routine( delete_routine( 3, CUSTOM_DELETE ), CUSTOM_DELETE )
x = 3
test_equal( "integer promoted, 2 delete routines and deleted by derefs", 2, delete_count() )

x = delete_routine( x + 1.25, CUSTOM_DELETE )
delete(x)
test_equal( "double explicitly deleted", 1, delete_count() )

x = delete_routine( x, CUSTOM_DELETE )
x = 0
test_equal( "double deleted by derefs", 1, delete_count() )

sequence s
s = delete_routine( repeat( 0, 1 ), CUSTOM_DELETE )
delete(s)
test_equal( "sequence explicitly deleted", 1, delete_count() )

s = delete_routine( repeat( 0, 1 ), CUSTOM_DELETE )
s = ""
test_equal( "sequence deleted by derefs", 1, delete_count() )

s = delete_routine( delete_routine( repeat( 0, 1 ), CUSTOM_DELETE ), CUSTOM_DELETE )
delete(s)
test_equal( "sequence, 2 delete routines, explicitly deleted", 2, delete_count() )

s = delete_routine( delete_routine( repeat( 0, 1 ), CUSTOM_DELETE ), CUSTOM_DELETE )
s = ""
test_equal( "sequence, 2 delete routines, deleted by derefs", 2, delete_count() )

s = {0}
s[1] = delete_routine( 1, CUSTOM_DELETE )
s[1] = 0
test_equal( "ASSIGN_SUBS_I release atom by refcount", 1, delete_count() )

s[1] = delete_routine( 1, CUSTOM_DELETE )
s[1] = 1.1
test_equal( "ASSIGN_SUBS release atom by refcount", 1, delete_count() )

enum X, S, T1, T2
sequence val = repeat( 0, 4 )

val[S] = {3}
val[X] = delete_routine( 1, CUSTOM_DELETE )
val[S][1] = val[X]
val[X] = 0
val[S][1] = val[X]
test_equal( "assigning sequence elements release atom by refcount", 1, delete_count() )

test_report()

