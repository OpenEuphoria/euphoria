#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

#include "execute.h"
#include "object.h"

#include "be_alloc.h"
#include "be_debug.h"
#include "be_execute.h"
#include "be_machine.h"
#include "be_rterror.h"
#include "be_runtime.h"

int external_debugger = 0;
int current_stack_depth = 0;

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

// functions to call the external debugger
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
	current_stack_depth = expr_top - expr_stack;
	((void (*)())UserDebugScreen)();
}

// debugger interface
object read_object( object_ptr ptr ){
	return *ptr;
}

void trace_off(){
	TraceOn = FALSE;
}

void disable_trace(){
	trace_off();
	trace_enabled = FALSE;
}

void skip_trace(){
	TraceOn = FALSE;
	TraceBeyond = start_line;
	TraceStack = current_stack_depth;
}

void abort_program(){
	RTFatal("program aborted");
}

enum INIT_ACCESSORS {
	IA_SYMTAB = 1,
	IA_SLIST,
	IA_OPS,
	IA_READ_OBJECT,
	IA_FILE_NAME,
	IA_TRACE_OFF,
	IA_DISABLE_TRACE,
	IA_SKIP_TRACE,
	IA_ABORT_PROGRAM,
	IA_SIZE
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
	
	ptrs = NewS1( IA_SIZE - 1 );
	
	ptrs->base[IA_SYMTAB]        = box_ptr( (uintptr_t) fe.st );
	ptrs->base[IA_SLIST]         = box_ptr( (uintptr_t) fe.sl );
	ptrs->base[IA_OPS]           = box_ptr( (uintptr_t) jumptab );
	ptrs->base[IA_READ_OBJECT]   = box_ptr( (uintptr_t) &read_object );
	ptrs->base[IA_FILE_NAME]     = box_ptr( (uintptr_t) file_name );
	ptrs->base[IA_TRACE_OFF]     = box_ptr( (uintptr_t) &trace_off );
	ptrs->base[IA_DISABLE_TRACE] = box_ptr( (uintptr_t) &disable_trace );
	ptrs->base[IA_SKIP_TRACE]    = box_ptr( (uintptr_t) &skip_trace );
	ptrs->base[IA_ABORT_PROGRAM]    = box_ptr( (uintptr_t) &abort_program );
	
	return MAKE_SEQ( ptrs );
}

object init_debug_addr(){
	return box_ptr( (uintptr_t) &init_debug );
}

