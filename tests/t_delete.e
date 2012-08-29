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
-- 
x = delete_routine( delete_routine( 3, CUSTOM_DELETE ), CUSTOM_DELETE )
x = 3
test_equal( "integer promoted, 2 delete routines and deleted by derefs", 2, delete_count() )

x = delete_routine( x + 1.25, CUSTOM_DELETE )
delete(x)
test_equal( "double explicitly deleted", 1, delete_count() )

x = delete_routine( x, CUSTOM_DELETE )
x = 0
test_equal( "double deleted by derefs", 1, delete_count() )

x = 3.25
x = delete_routine( x, CUSTOM_DELETE )
x = 0
test_equal( "double assigned from literal deleted by derefs", 1, delete_count() )

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

enum X, S, T1, T2, L0, L1, LS0
sequence val = repeat( 0, 4 )

val[S] = {3}
val[X] = delete_routine( 1, CUSTOM_DELETE )
val[S][1] = val[X]
val[X] = 0
val[S][1] = val[X]
test_equal( "assigning sequence elements release atom by refcount", 1, delete_count() )

val = { repeat( 0, 4 ) }
val[1][S] = {3}
val[1][X] = delete_routine( 1, CUSTOM_DELETE )
val[1][S][1] = val[1][X]
val[1][X] = 0
val[1][S][1] = val[1][X]
test_equal( "assigning sequence elements release atom by refcount indirectly (simulating eu.ex)", 1, delete_count() )

val = repeat( 4.4, 4 )

val[X] = 3.0
val[X] = delete_routine( val[X], CUSTOM_DELETE )
val[X] = 0
test_equal( "delete routine on seq element reassigned to itself, release atom by refcount", 1, delete_count() )

val[X] = 9.4
val[X] = val[X] + val[T1]
val[X] = delete_routine( val[X], CUSTOM_DELETE )
if not atom( val[X] ) then
	
end if
val[X] = 0
test_equal( "simulated eu.ex double deleted by derefs", 1, delete_count() )

constant NOVALUE = -1.295837195872e307
integer a, b, c, target, pc
sequence Code
val = repeat( NOVALUE, 10 )

val[S] = {1.3}
val[L1] = 1
val[L0] = 0
val[LS0] = {0}
val[T1] = CUSTOM_DELETE


val[S] = {0}
val[S][1] = delete_routine( 1, CUSTOM_DELETE )

object vX
vX = val[S]
vX = val[L0]
val[S][1] = vX
vX = NOVALUE

test_equal( "simulated ASSIGN_SUBS_I", 1, delete_count() )

function simple_function( object x )
  return 0
end function

function is_sequence( object x, integer y = simple_function(x) )
  return sequence(x)
end function

test_equal( "temp with delete routine lost when used in default argument as an argument to another call", 
  1, is_sequence( repeat( 0, 2 ) ) )



function assign_subs(sequence x, sequence subs, object rhs_val)
	if length(subs) = 1 then
		x[subs[1]] = rhs_val
	else
		x[subs[1]] = assign_subs(x[subs[1]], subs[2..$], rhs_val)
	end if
	return x
end function

val[S] = {0}   

val = assign_subs( val, {S,1}, delete_routine(1, CUSTOM_DELETE) )
val = {}

test_equal( "recursive assign_subs", 1, delete_count() )

integer
	atom_check     = 0,
	integer_check  = 0,
	object_check   = 0,
	sequence_check = 0

procedure is_an_atom( object x )
	atom_check += 1
end procedure

procedure is_an_integer( object x )
	integer_check += 1
end procedure

procedure is_an_object( object x )
	object_check += 1
end procedure

procedure is_a_sequence( object x )
	sequence_check += 1
end procedure

procedure native_derefs_ticket_775()
	sequence s = {
		delete_routine( 1, routine_id("is_an_atom") ),
		delete_routine( 1, routine_id("is_an_integer") ),
		delete_routine( 1, routine_id("is_an_object") ),
		delete_routine( 1, routine_id("is_a_sequence") )
	}
	integer x = atom( s[1] ) + integer( s[2] ) + object( s[3] ) + sequence( s[4] )
	s = ""
	test_true( "atom check dereferenced temp", atom_check )
	test_true( "integer check dereferenced temp", integer_check )
	test_true( "object check dereferenced temp", object_check )
	test_true( "sequence check dereferenced temp", sequence_check )
end procedure
native_derefs_ticket_775()

test_report()
