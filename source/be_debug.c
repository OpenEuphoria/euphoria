
#include <stdint.h>
#if defined(EWINDOWS) && INTPTR_MAX == INT64_MAX
// MSVCRT doesn't handle long double output correctly
#define __USE_MINGW_ANSI_STDIO 1
#endif
#include <stdio.h>
#include <stdlib.h>

#ifdef EWINDOWS

#else

#include <dlfcn.h>

#endif

#include "execute.h"
#include "global.h"
#include "object.h"
#include "redef.h"
#include "reswords.h"

#include "be_alloc.h"
#include "be_debug.h"
#include "be_execute.h"
#include "be_machine.h"
#include "be_rterror.h"
#include "be_runtime.h"
#include "be_symtab.h"

int external_debugger = 0;
int current_stack_depth = 0;

char *external_debugger_name = 0;

object_ptr external_buffer = 0;

uintptr_t UserShowDebug;
uintptr_t UserDisplayVar;
uintptr_t UserUpdateGlobals;
uintptr_t UserDebugScreen;
uintptr_t UserEraseSymbol;
uintptr_t UserErasePrivates;

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

void ExternalEraseSymbol( symtab_ptr sym ){
	((void (*)())UserEraseSymbol)( box_ptr( (uintptr_t)sym ) );
}

void ExternalErasePrivates( symtab_ptr proc_sym ){
	((void (*)())UserErasePrivates)( box_ptr( (uintptr_t)proc_sym ) );
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

void step_over(){
	TraceOn = FALSE;
	TraceBeyond = start_line;
	TraceStack = current_stack_depth;
}

int is_novalue( object_ptr obj ){
	return *obj == NOVALUE;
}

void abort_program(){
	RTFatal("program aborted");
}

object get_pc(){
	return box_ptr( (uintptr_t) tpc );
}

int break_at_routine( symtab_ptr proc, int enable ){
	intptr_t *pc;
	intptr_t len;
	intptr_t i;
	pc = proc->u.subp.code;
	len = *pc++;
	for( i = 1; i <= len; ++pc, ++i ){
		if( *pc == (intptr_t)opcode( L_STARTLINE ) || *pc == (intptr_t) opcode( L_STARTLINE_BREAK ) ) {
			if( enable ){
				*pc = (intptr_t) opcode( L_STARTLINE_BREAK );
			}
			else{
				*pc = (intptr_t) opcode( L_STARTLINE );
			}
			return 1;
		}
	}
	return 0;
}

// Used in the sequence returned from init_debug()
enum INIT_ACCESSORS {
	IA_SYMTAB = 1,
	IA_SLIST,
	IA_OPS,
	IA_READ_OBJECT,
	IA_FILE_NAME,
	IA_TRACE_OFF,
	IA_DISABLE_TRACE,
	IA_STEP_OVER,
	IA_ABORT_PROGRAM,
	IA_RTLOOKUP,
	IA_GET_PC,
	IA_IS_NOVALUE,
	IA_CALL_STACK,
	IA_BREAK_ROUTINE,
	IA_SIZE
};

// Used in the sequence passed to init_debug()
enum INIT_PARAMS {
	IP_BUFFER = 1,
	IP_SHOW_DEBUG,
	IP_DISPLAY_VAR,
	IP_UPDATE_GLOBALS,
	IP_DEBUG_SCREEN,
	IP_ERASE_PRIVATE_NAMES,
	IP_ERASE_SYMBOL
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
	UserErasePrivates = get_pos_int( "user debug erase private names", params_s1->base[IP_ERASE_PRIVATE_NAMES] );
	UserEraseSymbol   = get_pos_int( "user debug erase symbol", params_s1->base[IP_ERASE_SYMBOL] );
	
	
	ptrs = NewS1( IA_SIZE - 1 );
	
	ptrs->base[IA_SYMTAB]        = box_ptr( (uintptr_t) fe.st );
	ptrs->base[IA_SLIST]         = box_ptr( (uintptr_t) fe.sl );
	ptrs->base[IA_OPS]           = box_ptr( (uintptr_t) jumptab );
	ptrs->base[IA_READ_OBJECT]   = box_ptr( (uintptr_t) &read_object );
	ptrs->base[IA_FILE_NAME]     = box_ptr( (uintptr_t) file_name );
	ptrs->base[IA_TRACE_OFF]     = box_ptr( (uintptr_t) &trace_off );
	ptrs->base[IA_DISABLE_TRACE] = box_ptr( (uintptr_t) &disable_trace );
	ptrs->base[IA_STEP_OVER]     = box_ptr( (uintptr_t) &step_over );
	ptrs->base[IA_ABORT_PROGRAM] = box_ptr( (uintptr_t) &abort_program );
	ptrs->base[IA_RTLOOKUP]      = box_ptr( (uintptr_t) &RTLookup );
	ptrs->base[IA_GET_PC]        = box_ptr( (uintptr_t) &get_pc );
	ptrs->base[IA_IS_NOVALUE]    = box_ptr( (uintptr_t) &is_novalue );
	ptrs->base[IA_CALL_STACK]    = box_ptr( (uintptr_t) &eu_call_stack );
	ptrs->base[IA_BREAK_ROUTINE] = box_ptr( (uintptr_t) &break_at_routine );
	
	return MAKE_SEQ( ptrs );
}

object init_debug_addr(){
	return box_ptr( (uintptr_t) &init_debug );
}

void set_debugger( char *debugger_name ){
	if( debugger_name ){
		external_debugger = 2;
		external_debugger_name = debugger_name;
	}
}

int load_debugger(){
#ifdef EWINDOWS
	HANDLE lib;
	FARPROC sym;
#else
	void *lib;
	void *sym;
#endif

	external_debugger = 0;
#ifdef EWINDOWS
	lib = LoadLibrary( external_debugger_name );
#else
	lib = dlopen( external_debugger_name, RTLD_LAZY );
#endif
	
	if( !lib ){
		return 0;
	}
	
#ifdef EWINDOWS
	sym = GetProcAddress( lib, "initialize_debugger" );
#else
	sym = dlsym( lib, "initialize_debugger" );
#endif
	
	if( !sym ){
		return 0;
	}
	
	((void(*)(object)) sym)( box_ptr( (uintptr_t) &init_debug ) );
	external_debugger = 1;
	return 1;
}

int add_to_call_stack( object_ptr stack_seq_ptr, intptr_t *pc, int debugger ){
	symtab_ptr current_proc;
	s1_ptr cs;
	long gline;
	
	current_proc = Locate( pc );
	if( current_proc == NULL ){
		return 0;
	}
	gline = FindLine(pc, current_proc );
	
	if( debugger ){
		cs = NewS1( 6 );
		cs->base[4] = box_ptr( (uintptr_t) current_proc );
		cs->base[5] = box_ptr( (uintptr_t) pc );
		cs->base[6] = gline;
	}
	else{
		cs = NewS1( 3 );
	}
	cs->base[1] = NewString( current_proc->name );
	
	
	if (gline == 0) {
		cs->base[2] = MAKE_SEQ( NewS1( 0 ) );
		cs->base[3] = -1;
	}
	else{
		cs->base[2] = NewString( file_name[ slist[gline].file_no ] );
		cs->base[3] = slist[gline].line;
		
	}
	
	Append( stack_seq_ptr, *stack_seq_ptr, MAKE_SEQ( cs ) );
	
	return 1;
}


// Return the current call stack
object eu_call_stack( int debugger ){
	object_ptr stack_top, stack;
	intptr_t *new_pc;
	s1_ptr stack_s1;
	object stack_seq;
	
	stack_top = expr_top;
	stack     = expr_stack;
	
	stack_s1 = NewS1(0);
	stack_seq = MAKE_SEQ( stack_s1 );
	
	new_pc = (intptr_t*)*stack_top;
	if( 0 == add_to_call_stack( &stack_seq, tpc, debugger ) ){
		return stack_seq;
	}
	
	stack_top -= 2;
	while (stack_top >= stack) {
		// unwind the stack for this task
		new_pc = (intptr_t *)*stack_top;
		stack_top -= 2;
		
		if (*new_pc == (intptr_t)opcode(CALL_BACK_RETURN)) {
			// we're in a callback routine
			
#ifdef EWINDOWS         
			copy_string(TempBuff, "\n^^^ call-back from Windows\n", TEMP_SIZE);
#else           
			copy_string(TempBuff, "\n^^^ call-back from external source\n", TEMP_SIZE);
#endif          
			if( debugger ){
				stack_s1 = NewS1( 4 );
			}
			else{
				stack_s1 = NewS1( 2 );
			}
			stack_s1->base[1] = NewString( TempBuff );
			stack_s1->base[2] = MAKE_SEQ( NewS1( 0 ) );
			
			Append( &stack_seq, stack_seq, MAKE_SEQ( stack_s1 ) );
			
		}
		else if( 0 == add_to_call_stack( &stack_seq, new_pc, debugger ) ){
			return stack_seq;
		}
		
	} // end while
	
	return stack_seq;
}
