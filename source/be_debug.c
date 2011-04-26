#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

#include "execute.h"
#include "object.h"

#include "be_alloc.h"
#include "be_debug.h"
#include "be_execute.h"
#include "be_machine.h"

int        external_debugger = 0;
object_ptr external_buffer = 0;

uintptr_t UserShowDebug;
uintptr_t UserDisplayVar;
uintptr_t UserUpdateGlobals;
uintptr_t UserDebugScreen;

object box_ptr( uintptr_t ptr ){
	if( ptr > (uintptr_t) MAXINT ){
		return NewDouble( (eudouble) ptr );
	}
	else{
		return (object) ptr;
	}
}

void ExternalShowDebug(){
	*external_buffer = (object) start_line;
	((void (*)())UserShowDebug)();
}

void ExternalDisplayVar( symtab_ptr s_ptr, int user_requested ){
	external_buffer[0] = (object) s_ptr;
	external_buffer[1] = (object) user_requested;
	((void (*)())UserDisplayVar)();
}

void ExternalUpdateGlobals(){
	((void (*)())UserUpdateGlobals)();
}

void ExternalDebugScreen(){
	((void (*)())UserDebugScreen)();
}

enum INIT_ACCESSORS {
	IA_SYMTAB = 1,
	IA_SLIST,
	IA_OPS 
};

enum INIT_PARAMS {
	IP_BUFFER = 1,
	IP_SHOW_DEBUG,
	IP_DISPLAY_VAR,
	IP_UPDATE_GLOBALS,
	IP_DEBUG_SCREEN
};

// an external debugger calls this to get the data and to let us know how to call it
object init_debug( object params ){
	s1_ptr ptrs;
	s1_ptr params_s1;
	
	external_debugger = 1;
	
	params_s1 = SEQ_PTR( params );
	external_buffer   = (object_ptr) get_pos_int( "debugger buffer", params_s1->base[IP_BUFFER] );
	UserShowDebug     = get_pos_int( "user show debug callback", params_s1->base[IP_SHOW_DEBUG] );
	UserDisplayVar    = get_pos_int( "user display var callback", params_s1->base[IP_DISPLAY_VAR] );
	UserUpdateGlobals = get_pos_int( "user update globals callback", params_s1->base[IP_UPDATE_GLOBALS] );
	UserDebugScreen   = get_pos_int( "user debug screen callback", params_s1->base[IP_DEBUG_SCREEN] );
	ptrs = NewS1( 3 );
	
	ptrs->base[IA_SYMTAB] = box_ptr( (uintptr_t) fe.st );
	ptrs->base[IA_SLIST]  = box_ptr( (uintptr_t) fe.sl );
	ptrs->base[IA_OPS]    = box_ptr( (uintptr_t) jumptab );
	
	return MAKE_SEQ( ptrs );
}

object init_debug_addr(){
	return box_ptr( (uintptr_t) &init_debug );
}
