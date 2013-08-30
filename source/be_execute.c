/*****************************************************************************/
/*      (c) Copyright - See License.txt       */
/*****************************************************************************/
/*                                                                           */
/*                 The Interpreter Back-end Main Program                     */
/*                 (not linked by user translated code)                      */
/*                                                                           */
/*****************************************************************************/

/* Some rules that must be followed:
 *
 *  - pc must be in ESI, ECX (or some other) register
 *  - watch out for instructions that the compiler places after a thread()
 *    - they won't be executed. e.g. increments of pc
 *  - top, a, obj_ptr, sym should be in registers (almost all references)
 *    avoid using * / (double) with these vars
 *  - must do tpc = pc before calling any subroutine - for error reporting
 *    and profiling
 *  - must inc PC (sometimes have to use inc3pc() or thread4()) before jumping
 *    to next op
 *  - code is generally: operator
 *                       operand1
 *                       operand2
 *                       target
 *    operator is address of the C code that performs this operation
 *    operands are generally addresses of vars or temps containing the
 *    value to be manipulated, target is the address of the var or temp to
 *    store the result into
 *  - must deref any target pointer (double or sequence) that is overwritten
 *    e.g. temp or var location, or sequence element containing
 *    non-ATOM_INT_NV. Use DeRefx when tpc=pc has not been done already
 *    in the op, to have accurate time profile of de_reference
 *  - avoid passing more than 3 arguments to any routine - it results in
 *    poor code quality throughout do_exec()
 */

/******************/
/* Included files */
/******************/
#include <stdint.h>
#if defined(EWINDOWS) && INTPTR_MAX == INT64_MAX
// MSVCRT doesn't handle long double output correctly
#define __USE_MINGW_ANSI_STDIO 1
#endif
#include <stdio.h>
#include <time.h>
#ifdef EUNIX
#	include <sys/times.h>
#	include <string.h>
#else
#	ifdef __WATCOMC__
#		include <graph.h>
#	endif
#	include <conio.h>
#endif
#include <math.h>
#ifdef EWINDOWS
#	include <windows.h>
#endif
#include <signal.h>

#include "alldefs.h"
#include "be_alloc.h"
#include "be_runtime.h"
#include "be_decompress.h"
#include "be_inline.h"
#include "be_machine.h"
#include "be_task.h"
#include "be_rterror.h"
#include "be_symtab.h"
#include "be_w.h"
#include "be_callc.h"
#include "be_coverage.h"
#include "be_execute.h"
#include "be_debug.h"

/******************/
/* Local defines  */
/******************/
#define POINT5 0.5
#define HUGE_LINE 1000000000

#ifdef DEBUG_OPCODE_TRACE
#define deprintf(s) do { printf(s); printf("\n"); } while (0)
#else
#define deprintf(s) do {  } while (0)
#endif

#define SYMTAB_INDEX(X) ((symtab_ptr)X) - fe.st

/* To eliminate type casts for pc[*] you
 would need a union like this:
union pc_t {
    unsigned int code;
    object obj;
    object_ptr objptr;
    object_ptr * objptrptr;
    pc_t * codeptr;
    s1_ptr * sptr;
};*/

/* took out:    || (fp)->_flag&_UNGET \
   added:       tpc = pc */
#ifdef ORIGINALWATCOM
#define getc(fp) \
		((fp)->_cnt<=0 \
		|| (fp)->_flag&_UNGET \
		|| (*(fp)->_ptr)=='\x0d' \
		|| (*(fp)->_ptr)=='\x1a' \
		? igetc(fp) \
		: ((fp)->_cnt--,*(fp)->_ptr++))
#endif

#if defined(__WATCOMC__) || defined(EUNIX)
	// a bit faster:
#	define mygetc(fp) \
		((fp)->_cnt<=0 \
		|| (*(fp)->_ptr)=='\x0d' \
		|| (*(fp)->_ptr)=='\x1a' \
		? (tpc = pc , igetc(fp)) \
		: ((fp)->_cnt--,*(fp)->_ptr++))
#else
#	define mygetc(fp) getc(fp)
#endif

#define STORE_TOP_I   a = *obj_ptr;                  \
					  *obj_ptr = top;                \
					  pc += 4;                       \
					  if (IS_ATOM_INT_NV(a)) {       \
						  thread();                  \
					  }                              \
					  else {                         \
						   DeRefDSx(a);              \
					  }


#define SHOW_PARAM(foo) 	if (foo == NOVALUE) {    \
					printf("NOVALUE");          \
				} else if (IS_SEQUENCE(foo)) {          \
					printf("0x%x=MAKE_SEQ(0x%x)", foo, SEQ_PTR(foo)); \
				} else if (IS_ATOM_INT(foo)) {                  \
					printf("%d",foo);              \
				} else if (IS_ATOM_DBL(foo))              \
					printf("%e",*DBL_PTR(foo))


#ifdef DEBUG_OPCODE_TRACE
#	define SHOW_START_BIN_OP_OPCODE_PARAMETERS() printf("(%d=>",pc[1]); \
				SHOW_PARAM(a); \
				printf(", %d=>",pc[2]); \
				SHOW_PARAM(top); \
				deprintf(")")

#else
#	define SHOW_START_BIN_OP_OPCODE_PARAMETERS() 0
#endif
#ifdef EDEBUG
#	define START_BIN_OP  a = *(object_ptr)pc[1];	\
				top = *(object_ptr)pc[2];      \
				SHOW_START_BIN_OP_OPCODE_PARAMETERS();   \
					  if ( a == NOVALUE || top == NOVALUE ) RTFatal( "NOVALUE passed to a binary op." ); \
					  obj_ptr = (object_ptr)pc[3];   \
					  if (IS_ATOM_INT(a) && IS_ATOM_INT(top)) {
#else
#	define START_BIN_OP  a = *(object_ptr)pc[1];	\
					  top = *(object_ptr)pc[2];      \
					  obj_ptr = (object_ptr)pc[3];   \
					  if (IS_ATOM_INT(a) && IS_ATOM_INT(top)) {
#endif

#define END_BIN_OP(x)     STORE_TOP_I                \
					  }                              \
					  else {                         \
						  tpc = pc;                  \
						  top = binary_op(x, a, top);\
						  a = *obj_ptr;              \
						  *obj_ptr = top;            \
						  pc += 4;                   \
						  DeRef(a);                  \
					  }

#define END_BIN_OP_IFW(x)  {                          \
								;                     \
						   }                          \
						   else {                     \
							   pc = (intptr_t *)pc[3];     \
							   BREAK;                 \
						   }                          \
						   thread4();             \
						   BREAK;                \
					   }                              \
					   else {                         \
						   tpc = pc;                  \
						   top = binary_op(x, a, top);  \
						   pc++;                      \
						   goto if_check;             \
					   }

#define END_BIN_OP_IFW_I   {                          \
								;                     \
						   }                          \
						   else {                     \
							   pc = (intptr_t *)pc[3];     \
							   BREAK;                 \
						   }                          \
						   thread4();             \
						   BREAK;                \

#define START_BIN_OP_I  a = *(object_ptr)pc[1];      \
					  top = *(object_ptr)pc[2];      \
					  obj_ptr = (object_ptr)pc[3];   \

#define END_BIN_OP_I      *obj_ptr = top;            \
						  pc += 4;                   \
						  thread();                  \

#define START_UNARY_OP  top = *(object_ptr)pc[1]; \
						obj_ptr = (object_ptr)pc[2]; \
						a = *obj_ptr;             \
						if (IS_ATOM_INT(top)) {

#define END_UNARY_OP(x)     inc3pc();              \
							*obj_ptr = top;       \
							if (IS_ATOM_INT_NV(a))    \
								thread();         \
							else                  \
								DeRefDSx(a);       \
						}                         \
						else {                    \
							tpc = pc;             \
							*obj_ptr = unary_op(x, top); \
							inc3pc();              \
							DeRef(a);             \
						}

/**********************/
/* Declared functions */
/**********************/

void INT_Handler(int);

/**********************/
/* Exported variables */
/**********************/
object_ptr expr_stack;  // runtime call stack
object_ptr expr_max;    // top limit of call stack
object_ptr expr_limit;  // don't start a new routine above this
int stack_size;         // current size of call stack
object_ptr expr_top;    // expression stack pointer
int SymTabLen;          // avoid > 3 args
int start_line;         // line number set by STARTLINE
int TraceBeyond;        // continue tracing after this line
int TraceStack;         // stack level when down-arrow was pressed
int Executing = FALSE;  // TRUE if user program is executing
int ProfileOn;          // TRUE if profile/profile_time is turned on

/* Euphoria program counter needed for traceback */
intptr_t *tpc;

/*******************/
/* Local variables */
/*******************/
#ifdef EXTRA_CHECK
static int *watch_point = (int *)0x3aa41c;
static int watch_value = 1948266795;
static int watch_count = 1;
#endif

/*********************/
/* Defined functions */
/*********************/
static void trace_command(object x)
// perform trace(x)
{
	int i = 0;

	if (IS_ATOM_INT(x)) {
		i = x;
	}
	else if (IS_ATOM(x)) {
		i = (int)DBL_PTR(x)->dbl;
	}
	else
		RTFatal("argument to trace() must be an atom", i);

#ifndef BACKEND
		if (i == 0) {
			TraceOn = FALSE;
			file_trace = FALSE;
			if (current_screen != MAIN_SCREEN)
				MainScreen();
		}
		else if (i == 1) {
			TraceOn = trace_enabled;
			color_trace = TRUE;
#ifdef EWINDOWS
			show_console();
#endif
		}
		else if (i == 2) {
			TraceOn = trace_enabled;
			color_trace = FALSE;
#ifdef EWINDOWS
			show_console();
#endif
		}
		else if (i == 3) {
			file_trace = TRUE;
		}
		else
			RTFatal("argument to trace() must be 0, 1, 2 or 3");
#endif
}

static void profile_command(object x)
// perform profile(x)
{
	int i;

	if (IS_ATOM_INT(x)) {
		i = x;
	}
	else if (IS_ATOM(x)) {
		i = (int)DBL_PTR(x)->dbl;
	}
	else
		RTFatal("argument to profile() must be an atom");
	if (i == 0) {
		ProfileOn = FALSE;
	}
	else if (i == 1) {
		ProfileOn = TRUE;
	}
	else
		RTFatal("argument to profile() must be 0 or 1");
}

static object do_peek2(object a, int b )
// peek2u, peek2s
// moved it here because it was causing bad code generation for WIN32
{
	int i;
	uint16_t *peek2_addr;
	object top;
	s1_ptr s1;
	object_ptr obj_ptr;

	/* check address */
	if (IS_ATOM_INT(a)) {
		peek2_addr = (uint16_t *)a;
	}
	else if (IS_ATOM(a)) {
		peek2_addr = (uint16_t *)(uintptr_t)(DBL_PTR(a)->dbl);
	}
	else {
		/* a sequence: {addr, nbytes} */
		s1 = SEQ_PTR(a);
		i = s1->length;
		if (i != 2) {
			RTFatal("argument to peek() must be an atom or a 2-element sequence");
		}
		peek2_addr = (uint16_t *)get_pos_int("peek2s/peek2u", *(s1->base+1));
		i = get_pos_int("peek2s/peek2u", *(s1->base+2));/* length*/
		if (i < 0)
			RTFatal("number of bytes to peek is less than 0");
		s1 = NewS1(i);
		obj_ptr = s1->base;
		if (b) {
			// unsigned
			while (--i >= 0) {
				top = (object)*peek2_addr;
				++peek2_addr;
				*(++obj_ptr) = top;
			}
		}
		else {
			// signed
			while (--i >= 0) {
				top = (object)(int16_t)*peek2_addr;
				++peek2_addr;
				*(++obj_ptr) = top;
			}
		}
		return (object)MAKE_SEQ(s1);
	}
	if (b) {
		// unsigned
		top = (object)*peek2_addr;
	}
	else {
		// signed
		top = (object)(int16_t)*peek2_addr;
	}

	return top;
}

static object do_peek8(object a, int b )
// peek8u, peek8s
{
		int64_t sval;
int i;
	object_ptr obj_ptr;
	object top;
	s1_ptr s1;
	uint64_t *peek8_addr;
	uint64_t uval;

	/* check address */
	if (IS_ATOM_INT(a)) {
		peek8_addr = (uint64_t *)a;
	}
	else if (IS_ATOM(a)) {
		peek8_addr = (uint64_t *)(uintptr_t)(DBL_PTR(a)->dbl);
	}
	else {
		/* a sequence: {addr, nbytes} */
		s1 = SEQ_PTR(a);
		i = s1->length;
		if (i != 2) {
			RTFatal("argument to peek() must be an atom or a 2-element sequence");
		}
		peek8_addr = (uint64_t *)get_pos_int("peek8s/peek8u", *(s1->base+1));
		i = get_pos_int("peek8s/peek8u", *(s1->base+2));/* length*/
		if (i < 0)
			RTFatal("number of bytes to peek is less than 0");
		s1 = NewS1(i);
		obj_ptr = s1->base;
		if (b) {
			// unsigned
			while (--i >= 0) {
				uval = *peek8_addr;
				++peek8_addr;
				if ( uval > (uint64_t)MAXINT){
					top = NewDouble((eudouble) uval);
				}
				else{
					top = (uintptr_t)uval;
				}
				*(++obj_ptr) = top;
			}
		}
		else {
			// signed
			while (--i >= 0) {
				sval = (int64_t) *peek8_addr;
				++peek8_addr;
				if (sval < (int64_t)MININT || sval > (int64_t)MAXINT){
					top = NewDouble((eudouble) sval);
				}
				else{
					top = (uintptr_t) sval;
				}
				*(++obj_ptr) = top;
			}
		}
		return (object)MAKE_SEQ(s1);
	}
	if (b) {
		// unsigned
		uval = *peek8_addr;
		if ( uval > (uint64_t)MAXINT){
			top = NewDouble((eudouble) uval);
		}
		else{
			top = (intptr_t) uval;
		}
	}
	else {
		// signed
		sval = (int64_t) *peek8_addr;
		if (sval < (int64_t)MININT || sval > (int64_t)MAXINT){
			top = NewDouble((eudouble) sval);
		}
		else{
			top = (intptr_t) sval;
		}
	}

	return top;
}


static object do_peek4(object a, int b )
// peek4u, peek4s
// moved it here because it was causing bad code generation for WIN32
{
	int i;
	uint32_t *peek4_addr;
	object top;
	s1_ptr s1;
	object_ptr obj_ptr;

	/* check address */
	if (IS_ATOM_INT(a)) {
		peek4_addr = (uint32_t *)a;
	}
	else if (IS_ATOM(a)) {
#ifdef __arm__
		double d = DBL_PTR(a)->dbl;
		peek4_addr = (uint32_t*)(uintptr_t)d;
#else
		peek4_addr = (uint32_t *)(uintptr_t)(DBL_PTR(a)->dbl);
#endif
	}
	else {
		/* a sequence: {addr, nbytes} */
		s1 = SEQ_PTR(a);
		i = s1->length;
		if (i != 2) {
			RTFatal("argument to peek() must be an atom or a 2-element sequence");
		}
		peek4_addr = (uint32_t *)get_pos_int("peek4s/peek4u", *(s1->base+1));
		i = get_pos_int("peek4s/peek4u", *(s1->base+2));/* length*/
		if (i < 0)
			RTFatal("number of bytes to peek is less than 0");
		s1 = NewS1(i);
		obj_ptr = s1->base;
		if (b) {
			// unsigned
			while (--i >= 0) {
				top = *peek4_addr;
				++peek4_addr;
				if ((uintptr_t)top > (uintptr_t)MAXINT)
					top = NewDouble((eudouble)(uint32_t)top);
				*(++obj_ptr) = top;
			}
		}
		else {
			// signed
			while (--i >= 0) {
				top = (int32_t)*peek4_addr;
				++peek4_addr;
				if (top < (int32_t)MININT || top > (int32_t)MAXINT)
					top = NewDouble((eudouble)(int32_t)top);
				*(++obj_ptr) = top;
			}
		}
		return (object)MAKE_SEQ(s1);
	}
	
	if (b) {
		// unsigned
		top = *peek4_addr;
		if ((uintptr_t)top > (uintptr_t)MAXINT)
			top = NewDouble((eudouble)(uintptr_t)top);
	}
	else {
		// signed
		top = (int32_t)*peek4_addr;
		if (top < (intptr_t) MININT || top > (intptr_t) MAXINT)
			top = NewDouble((eudouble)(intptr_t)top);
	}

	return top;
}

#if INTPTR_MAX == INT32_MAX
#define POKE_LIMIT(x) "poke" #x " is limited to 32-bit numbers"
#else
#define POKE_LIMIT(x) "poke" #x " is limited to 64-bit numbers"
#endif

static void do_poke2(object a, object top)
// moved it here because it was causing bad code generation for WIN32
{
	uint16_t *poke2_addr;
	eudouble temp_dbl;
	s1_ptr s1;
	object_ptr obj_ptr;

	/* determine the address to be poked */
	if (IS_ATOM_INT(a)) {
		poke2_addr = (uint16_t *)INT_VAL(a);
	}
	else if (IS_ATOM(a)) {
		poke2_addr = (uint16_t *)(uintptr_t)(DBL_PTR(a)->dbl);
	}
	else {
		RTFatal("first argument to poke2 must be an atom");
	}
	/* look at the value to be poked */
	if (IS_ATOM_INT(top)) {
		*poke2_addr = (uint16_t) INT_VAL(top);
	}
	else if (IS_ATOM(top)) {
		temp_dbl = DBL_PTR(top)->dbl;
		if (temp_dbl < MIN_BITWISE_DBL || temp_dbl > MAX_BITWISE_DBL)
			RTFatal(POKE_LIMIT(2));
#ifdef __arm__
			a = trunc( temp_dbl );
			*poke2_addr = (uint16_t) a;
#else
			*poke2_addr = (uint16_t) temp_dbl;
#endif
		
	}
	else {
		/* second arg is sequence */
		s1 = SEQ_PTR(top);
		obj_ptr = s1->base;
		while (TRUE) {
			top = *(++obj_ptr);
			if (IS_ATOM_INT(top)) {
				*poke2_addr = (uint16_t) INT_VAL(top);
				++poke2_addr;
			}
			else if (IS_ATOM(top)) {
				if (top == NOVALUE)
					break;
				temp_dbl = DBL_PTR(top)->dbl;
		
				if (temp_dbl < MIN_BITWISE_DBL || temp_dbl > MAX_BITWISE_DBL)
					RTFatal( POKE_LIMIT(2) );
#ifdef __arm__
				a = trunc( DBL_PTR(top)->dbl );
				*poke2_addr = (uint16_t) a;
#else
				*poke2_addr = (uint16_t) temp_dbl;
#endif
				++poke2_addr;
			}
			else {
				RTFatal("sequence to be poked must only contain atoms");
			}
		}
	}
}

static void do_poke8(object a, object top)
{
	uint64_t *poke8_addr;
	eudouble temp_dbl;
	s1_ptr s1;
	object_ptr obj_ptr;
#ifdef __arm__
	uint64_t tmp64;
#endif

	/* determine the address to be poked */
	if (IS_ATOM_INT(a)) {
		poke8_addr = (uint64_t *)INT_VAL(a);
	}
	else if (IS_ATOM(a)) {
		poke8_addr = (uint64_t *)(uintptr_t)(DBL_PTR(a)->dbl);
	}
	else {
		RTFatal("first argument to poke8 must be an atom");
	}
	/* look at the value to be poked */
	if (IS_ATOM_INT(top)) {
		*poke8_addr = (uint64_t) top;
	}
	else if (IS_ATOM(top)) {
		temp_dbl = DBL_PTR(top)->dbl;
		if (temp_dbl < MIN_LONGLONG_DBL || temp_dbl > MAX_LONGLONG_DBL)
			RTFatal("poke8 is limited to 64-bit numbers");
#ifdef __arm__
		tmp64 = trunc( temp_dbl );
		*poke8_addr = tmp64;
#else
		*poke8_addr = (uint64_t) temp_dbl;
#endif
	}
	else {
		/* second arg is sequence */
		s1 = SEQ_PTR(top);
		obj_ptr = s1->base;
		while (TRUE) {
			top = *(++obj_ptr);
			if (IS_ATOM_INT(top)) {
				*poke8_addr = (uint64_t) top;
				++poke8_addr;
			}
			else if (IS_ATOM(top)) {
				if (top == NOVALUE)
					break;
				temp_dbl = DBL_PTR(top)->dbl;
				if (temp_dbl < MIN_LONGLONG_DBL || temp_dbl > MAX_LONGLONG_DBL)
					RTFatal("poke8 is limited to 64-bit numbers");
#ifdef __arm__
				tmp64 = trunc( temp_dbl );
				*poke8_addr = (uint64_t) tmp64;
#else
				*poke8_addr = (uint64_t) temp_dbl;
#endif
				++poke8_addr;
			}
			else {
				RTFatal("sequence to be poked must only contain atoms");
			}
		}
	}
}

static void do_poke4(object a, object top)
// moved it here because it was causing bad code generation for WIN32
{
	uint32_t *poke4_addr;
	eudouble temp_dbl;
	s1_ptr s1;
	object_ptr obj_ptr;
#ifdef __arm__
	int32_t tmp_int;
#endif

	/* determine the address to be poked */
	if (IS_ATOM_INT(a)) {
		poke4_addr = (uint32_t *)INT_VAL(a);
	}
	else if (IS_ATOM(a)) {
#ifdef __arm__
		temp_dbl = DBL_PTR(a)->dbl;
		poke4_addr = (uint32_t *)(uintptr_t)temp_dbl;
#else
		poke4_addr = (uint32_t *)(uintptr_t)(DBL_PTR(a)->dbl);
#endif
	}
	else {
		RTFatal("first argument to poke4 must be an atom");
	}
	/* look at the value to be poked */
	if (IS_ATOM_INT(top)) {
		*poke4_addr = (uint32_t) INT_VAL(top);
	}
	else if (IS_ATOM(top)) {
		temp_dbl = DBL_PTR(top)->dbl;
		if (temp_dbl < MIN_BITWISE_DBL || temp_dbl > MAX_BITWISE_DBL)
			RTFatal(POKE_LIMIT(4));
#ifdef __arm__
		if( temp_dbl < 0.0 ){
			tmp_int = (int32_t) temp_dbl;
		}
		else{
			tmp_int = (int32_t)(uint32_t) temp_dbl;
		}
		*poke4_addr = (uint32_t) tmp_int;
#else
		*poke4_addr = (uint32_t) temp_dbl;
#endif
	}
	else {
		/* second arg is sequence */
		s1 = SEQ_PTR(top);
		obj_ptr = s1->base;
		while (TRUE) {
			top = *(++obj_ptr);
			if (IS_ATOM_INT(top)) {
				*poke4_addr = (uint32_t) INT_VAL(top);
				++poke4_addr;
			}
			else if (IS_ATOM(top)) {
				if (top == NOVALUE)
					break;
				temp_dbl = DBL_PTR(top)->dbl;
				if (temp_dbl < MIN_BITWISE_DBL || temp_dbl > MAX_BITWISE_DBL)
					RTFatal(POKE_LIMIT(4));
#ifdef __arm__
				if( temp_dbl < 0.0 ){
					tmp_int = (int32_t) temp_dbl;
				}
				else{
					tmp_int = (int32_t)(uint32_t) temp_dbl;
				}
				*poke4_addr = (uint32_t) tmp_int;
#else
				*poke4_addr = (uint32_t) temp_dbl;
#endif
				++poke4_addr;
			}
			else {
				RTFatal("sequence to be poked must only contain atoms");
			}
		}
	}
}

// WATCOM does not completely understand thread().
// When it inserts a jump machine instruction, it will
// sometimes move code after the thread()
// and the code will not be executed.

#ifdef INT_CODES
#define thread() goto loop_top
#define thread2() {(long)pc += 2; goto loop_top;}
#define thread4() {(long)pc += 4; goto loop_top;}
#define thread5() {(long)pc += 5; goto loop_top;}
#define threadpc3() {pc = (intptr_t *)pc[3]; goto loop_top;}
#define inc3pc() (long)pc += 3
#include "redef.h"
#include "opnames.h"
#define BREAK break

#else
// THREADED CODE - implemented in various ways

#define FP_EMULATION_NEEDED // FOR WATCOM/DOS to run on old 486/386 without f.p.

#if !defined(EMINGW)
#if defined(EWINDOWS) || (defined(__WATCOMC__) && !defined(FP_EMULATION_NEEDED))
#ifdef EMSVC
long msvc_spare = 0;
#define thread() do { __asm { JMP [pc] } } while(0)
#define thread2() do { msvc_spare = pc + 8; __asm { JMP [msvc_spare] } } while(0)
#define thread4() do { msvc_spare = pc + 16; __asm { JMP [msvc_spare] } } while(0)
#define thread5() do { msvc_spare = pc + 20; __asm { JMP [msvc_spare] } } while(0)
#define inc3pc() do { __asm { ADD pc, 12 } } while(0)
// not converted because it is not used
#define threadpc3()
#define BREAK break
#include "redef.h"
#else
// #pragma aux thread aborts; does nothing

#define thread() do { wcthread((long)pc); } while (0)
void wcthread(long x);
#pragma aux wcthread = \
		"jmp [ECX]" \
		modify [EAX EBX EDX] \
		parm [ECX];

long wcinc2pc(long x);
#pragma aux wcinc2pc = \
		"ADD ECX, 8" \
		modify [] \
		value [ECX] \
		parm [ECX];

long wcinc4pc(long x);
#pragma aux wcinc4pc = \
		"ADD ECX, 16" \
		modify [] \
		value [ECX] \
		parm [ECX];

long wcinc5pc(long x);
#pragma aux wcinc5pc = \
		"ADD ECX, 20" \
		modify [] \
		value [ECX] \
		parm [ECX];

#define thread2() do { pc = (intptr_t *)wcinc2pc((long)pc); wcthread((long)pc); } while (0)
#define thread4() do { pc = (intptr_t *)wcinc4pc((long)pc); wcthread((long)pc); } while (0)
#define thread5() do { pc = (intptr_t *)wcinc5pc((long)pc); wcthread((long)pc); } while (0)

/* have to hide this from WATCOM or it will generate stupid code
   at the top of the switch */
long wcinc3pc(long x);
#pragma aux wcinc3pc = \
		"ADD ECX, 12" \
		modify [] \
		value [ECX] \
		parm [ECX];
#define inc3pc() do { pc = (intptr_t *)wcinc3pc((long)pc); } while (0)

// not converted because it is not used
void threadpc3(void);
#pragma aux threadpc3 = \
		"MOV ECX, EDI" \
		"jmp [ECX]"    \
		modify [EAX EBX ECX EDX];

#define BREAK break
#include "redef.h"
#endif // EMSVC
#endif
#endif // !defined(EMINGW)

#if defined(EUNIX) || defined(EMINGW)
// these GNU-based compilers support dynamic labels,
// so threading is much easier
#define thread() goto *((void *)*pc)
#define thread2() {pc += 2; goto *((void *)*pc);}
#define thread4() {pc += 4; goto *((void *)*pc);}
#define thread5() {pc += 5; goto *((void *)*pc);}
#define inc3pc() pc += 3
#define BREAK goto *((void *)*pc)
#endif

#endif  // threaded code

#ifdef __WATCOMC__
#pragma aux nop = \
		"nop" \
		modify[];
#endif

static int recover_rhs_subscript(object subscript, s1_ptr s)
/* rhs subscript failed initial check, but might be ok */
{
	intptr_t subscripti;

	if (IS_ATOM_INT(subscript)) {
		RangeReading(subscript, s->length);
	}
	else if (IS_ATOM_DBL(subscript)) {
		subscripti = (intptr_t)(DBL_PTR(subscript)->dbl);
		if ((uintptr_t)(subscripti - 1) < (uintptr_t)s->length)
			return subscripti;
		else
			RangeReading(subscript, s->length);
	}
	else {
		/* SEQUENCE */
		RTFatal("subscript must be an atom\n(reading an element of a sequence)");
	}
	return 0; // not reached
}

static void wrong_arg_count(symtab_ptr sub, object a)
// report wrong arg count in call via routine id
{
	RTFatal("call to %s() via routine-id should pass %d argument%s, not %d",
			sub->name, sub->u.subp.num_args,
			(sub->u.subp.num_args == 1) ? "" :"s",
			((s1_ptr)a)->length);
}

static int recover_lhs_subscript(object subscript, s1_ptr s)
/* lhs subscript failed initial check but the value may be an
 * encoded pointer to a number. */
{
	intptr_t subscripti;

	if (IS_ATOM_INT(subscript)) {
		BadSubscript(subscript, s->length);
	}
	else if (IS_ATOM_DBL(subscript))  {
		subscripti = (intptr_t)(DBL_PTR(subscript)->dbl);
		if ((uintptr_t)(subscripti - 1) < (uintptr_t)s->length)
			return subscripti;
		else
			BadSubscript(subscript, s->length);
	}
	else {
		/* SEQUENCE */
		SubsNotAtom();
	}
	return 0; // not reached
}


void InitStack(int size, int toplevel)
// called to create the initial call stack for a task
{
	stack_size = size;
	expr_stack = (object_ptr) EMalloc(stack_size * sizeof(object));
	expr_stack[toplevel] = (object)TopLevelSub;
	expr_top = &expr_stack[toplevel+1];  /* next available place on expr stack */

	/* must allow for a few extra words */
	expr_max = expr_stack + (stack_size - 5);
	expr_limit = expr_max - 3; // we only push two items per call
}


void InitExecute()
{
#ifndef EDEBUG
	// signal(SIGFPE, FPE_Handler)  // generate inf and nan instead
	signal(SIGINT, INT_Handler);
	// SIG_IGN=> still see ^C echoed, but it has no effect other
	// than messing up the screen. INT_Handler lets us do
	// a bit of cleanup - tick rate, profile, active page etc.
#endif

#ifdef EWINDOWS
		/* Prevent "Send Error Report to Microsoft dialog from coming up
		   if this thing has an unhandled exception.  */
		SetUnhandledExceptionFilter(Win_Machine_Handler);
#endif

#ifndef ERUNTIME  // dll shouldn't take handler away from main program
#ifndef EDEBUG
	signal(SIGILL,  Machine_Handler);
	signal(SIGSEGV, Machine_Handler);
#endif
#endif
	TraceOn = FALSE;
	ProfileOn = TRUE;
	TraceBeyond = HUGE_LINE;

	// Create Call Stack
	InitStack(EXPR_SIZE, 1);

	// create first task (task 0)
	InitTask();
	TopLevelSub->u.subp.resident_task = current_task;

	// Initialize random generator seeds.
	setran();
}

#ifndef INT_CODES
#if defined(EUNIX) || defined(EMINGW)
intptr_t **jumptab; // initialized in do_exec()
#else
#ifdef __WATCOMC__
/* Jump table location is determined by another program. */
extern intptr_t ** jumptab;
#else
#error Not supported use INT_CODES?
#endif
#endif // not GNU-C
#endif //not INT_CODES


/* IL data passed from the front end */
struct IL fe;

#define SET_OPERAND(word) ((intptr_t *)(((word) == 0) ? 0 : (&fe.st[(intptr_t)(word)])))

#define SET_JUMP(word) ((intptr_t *)(&code[(intptr_t)(word)]))
#define JUMP_INDEX(word) (((intptr_t*)word) - ((symtab_ptr)expr_top[-1])->u.subp.code)

void code_set_pointers(intptr_t **code)
/* adjust code pointers, changing some indexes into pointers */
{
	intptr_t len, i, j, n, sub, word;

	len = (intptr_t) code[0];
	i = 1;
	while (i <= len) {
		word = (intptr_t)code[i];

		if (word > MAX_OPCODE || word < 1) {
			RTFatal("BAD IL OPCODE: i is %d, word is %d (max=%d), len is %d",
					i, word, len);
		}

		code[i] = (intptr_t *)opcode(word);

		switch (word) {
			case TYPE_CHECK:
			case CALL_BACK_RETURN:
			case BADRETURNF:
			case RETURNT:
			case CLEAR_SCREEN:
			case UPDATE_GLOBALS:
			case NOP1:
			case TASK_CLOCK_STOP:
			case TASK_CLOCK_START:
			case TASK_YIELD:
			case NOPWHILE:  // translator only
				 // no operands follow
				i += 1;
				break;

			case GLOBAL_INIT_CHECK:
			case PRIVATE_INIT_CHECK:
			case INTEGER_CHECK:
			case ATOM_CHECK:
			case SEQUENCE_CHECK:
			case DATE:
			case TIME:
			case SPACE_USED:
			case CALL:
			case CLOSE:
			case GET_KEY:
			case COMMAND_LINE:
			case OPTION_SWITCHES:
			case TRACE:
			case PROFILE:
			case DISPLAY_VAR:
			case ERASE_PRIVATE_NAMES:
			case ERASE_SYMBOL:
			case ABORT:
			case PLATFORM:
			case TASK_SELF:
			case TASK_SUSPEND:
			case TASK_LIST:
			case DELETE_OBJECT:
			case EXIT_BLOCK:
			case DEREF_TEMP:
			case REF_TEMP:
			case NOVALUE_TEMP:
				// one operand
				code[i+1] = SET_OPERAND(code[i+1]);
				i += 2;
				break;

			case NOP2:
			case STARTLINE:
			case COVERAGE_LINE:
			case COVERAGE_ROUTINE:
				i += 2;
				break;

			case ENDWHILE:
			case ELSE:
			case RETRY:
		case EXIT:
				code[i+1] = SET_JUMP(code[i+1]);
				i += 2;
				break;

			case GLABEL:
			case GOTO:
				code[i+1] = SET_JUMP(code[i+1]);
				i += 2;
				break;

			case NOT:
			case IS_AN_ATOM:
			case IS_A_SEQUENCE:
			case UMINUS:
			case GETS:
			case GETC:
			case SQRT:
			case LENGTH:
			case PLENGTH:
			case ARCTAN:
			case LOG:
			case SIN:
			case COS:
			case TAN:
			case RAND:
			case PEEK:
			case SIZEOF:
			case PEEK_STRING:
			case PEEKS:
			case FLOOR:
			case ASSIGN_I:
			case ASSIGN:
			case IS_AN_INTEGER:
			case IS_AN_OBJECT:
			case NOT_BITS:
			case CALL_PROC:
			case POSITION:
			case PEEK4S:
			case PEEK4U:
			case PEEK2S:
			case PEEK2U:
			case PEEK8U:
			case PEEK8S:
			case PEEK_POINTER:
			case SYSTEM:
			case PUTS:
			case QPRINT:
			case PRINT:
			case GETENV:
			case MACHINE_PROC:
			case POKE4:
			case POKE8:
			case POKE:
			case POKE_POINTER:
			case POKE2:
			case SC2_AND:
			case SC2_OR:
			case TASK_SCHEDULE:
			case TASK_STATUS:
			case RETURNP:
				// 2 operands follow
				code[i+1] = SET_OPERAND(code[i+1]);
				code[i+2] = SET_OPERAND(code[i+2]);
				i += 3;
				break;

			case NOT_IFW:
			case IF:
			case WHILE:
				// 2 operands follow
				code[i+1] = SET_OPERAND(code[i+1]);
				code[i+2] = SET_JUMP(code[i+2]);
				i += 3;
		break;

			case LESS:
			case GREATEREQ:
			case EQUALS:
			case NOTEQ:
			case LESSEQ:
			case GREATER:
			case AND:
			case OR:
			case MINUS:
			case PLUS:
			case MULTIPLY:
			case DIVIDE:
			case CONCAT:
			case REMAINDER:
			case POWER:
			case OR_BITS:
			case XOR_BITS:
			case APPEND:
			case REPEAT:
			case PREPEND:
			case COMPARE:
			case FIND:
			case MATCH:
			case XOR:
			case AND_BITS:
			case EQUAL:
			case RHS_SUBS:
			case RHS_SUBS_CHECK:
			case RHS_SUBS_I:
			case ASSIGN_OP_SUBS:
			case PASSIGN_OP_SUBS:
			case ASSIGN_SUBS:
			case ASSIGN_SUBS_CHECK:
			case ASSIGN_SUBS_I:
			case PASSIGN_SUBS:
			case PLUS1:
			case PLUS1_I:
			case RIGHT_BRACE_2:
			case PLUS_I:
			case MINUS_I:
			case DIV2:
			case FLOOR_DIV2:
			case FLOOR_DIV:
			case MEM_COPY:
			case MEM_SET:
			case SYSTEM_EXEC:
			case PRINTF:
			case SPRINTF:
			case MACHINE_FUNC:
			case CALL_FUNC:
			case C_PROC:
			case TASK_CREATE:
			case HASH:
			case HEAD:
			case TAIL:
			case DELETE_ROUTINE:
			case RETURNF:
				// 3 operands follow
				code[i+1] = SET_OPERAND(code[i+1]);
				code[i+2] = SET_OPERAND(code[i+2]);
				code[i+3] = SET_OPERAND(code[i+3]);
				i += 4;
				break;

			case SC1_AND_IF:
			case SC1_OR_IF:
			case SC1_AND:
			case SC1_OR:
				// 3 operands follow
				code[i+1] = SET_OPERAND(code[i+1]);
				code[i+2] = SET_OPERAND(code[i+2]);
				code[i+3] = SET_JUMP(code[i+3]);
				i += 4;
				break;

			case LESS_IFW_I:
			case GREATEREQ_IFW_I:
			case EQUALS_IFW_I:
			case NOTEQ_IFW_I:
			case LESSEQ_IFW_I:
			case GREATER_IFW_I:
			case LESS_IFW:
			case GREATEREQ_IFW:
			case EQUALS_IFW:
			case NOTEQ_IFW:
			case LESSEQ_IFW:
			case GREATER_IFW:
				// 2 operands and a branch follow
				code[i+1] = SET_OPERAND(code[i+1]);
				code[i+2] = SET_OPERAND(code[i+2]);
				code[i+3] = SET_JUMP(code[i+3]);
				i += 4;
				break;

			case ASSIGN_OP_SLICE:
			case PASSIGN_OP_SLICE:
			case ASSIGN_SLICE:
			case PASSIGN_SLICE:
			case RHS_SLICE:
			case LHS_SUBS:
			case LHS_SUBS1:
			case LHS_SUBS1_COPY:
			case C_FUNC:
			case FIND_FROM:
			case MATCH_FROM:
			case SPLICE:
			case INSERT:
			case REMOVE:
			case OPEN:
				// 4 operands follow
				code[i+1] = SET_OPERAND(code[i+1]);
				code[i+2] = SET_OPERAND(code[i+2]);
				code[i+3] = SET_OPERAND(code[i+3]);
				code[i+4] = SET_OPERAND(code[i+4]);
				i += 5;
				break;

			case REPLACE:
				// 5 operands follow
				code[i+1] = SET_OPERAND(code[i+1]);
				code[i+2] = SET_OPERAND(code[i+2]);
				code[i+3] = SET_OPERAND(code[i+3]);
				code[i+4] = SET_OPERAND(code[i+4]);
				code[i+5] = SET_OPERAND(code[i+5]);
				i += 6;
				break;

			case ROUTINE_ID:
				// 5 operands follow - #2 and #4 are integers
				code[i+1] = SET_OPERAND(code[i+1]);
				code[i+3] = SET_OPERAND(code[i+3]);
				code[i+5] = SET_OPERAND(code[i+5]);
				i += 6;
				break;

			case ENDFOR_INT_UP1:
			case ENDFOR_INT_DOWN1:
			case ENDFOR_INT_UP:
			case ENDFOR_INT_DOWN:
			case ENDFOR_UP:
			case ENDFOR_DOWN:
			case ENDFOR_GENERAL:
				// 4 operands follow
				code[i+1] = SET_JUMP(code[i+1]);
				code[i+2] = SET_OPERAND(code[i+2]);
				code[i+3] = SET_OPERAND(code[i+3]);
				code[i+4] = SET_OPERAND(code[i+4]);
				i += 5;
				break;

			case FOR:
			case FOR_I:
				// 6 operands follow
				code[i+1] = SET_OPERAND(code[i+1]);
				code[i+2] = SET_OPERAND(code[i+2]);
				code[i+3] = SET_OPERAND(code[i+3]);
				code[i+4] = SET_OPERAND(code[i+4]);
				code[i+5] = SET_OPERAND(code[i+5]);
				code[i+6] = SET_JUMP(code[i+6]);
				i += 7;
				break;

			case SWITCH:
			case SWITCH_I:
			case SWITCH_RT:
				code[i+2] = SET_OPERAND(code[i+2]); // cases
			case SWITCH_SPI:
				code[i+1] = SET_OPERAND(code[i+1]); // select val

				code[i+3] = SET_OPERAND(code[i+3]); // jump table
				code[i+4] = SET_JUMP(code[i+4]);    // else or end switch
				i += 5;
				break;

		// special cases: variable number of operands

			case PROC:
			case PROC_TAIL:
				sub = (intptr_t)code[i+1];
				code[i+1] = SET_OPERAND(sub);

				// we must look at the symbol table to know
				// how many arguments follow, and whether the
				// routine being called is a function or not
				n = fe.st[sub].u.subp.num_args;

				for (j = 2; j <= n+1; j++) {
					code[i+j] = SET_OPERAND(code[i+j]);
				}

				if (fe.st[sub].token != PROC) {
					code[i+2+n] = SET_OPERAND(code[i+2+n]);
					i += 1;
				}

				i += 2 + n;
				break;

			case RIGHT_BRACE_N:
				n = (intptr_t)code[i+1];
				for (j = 1; j <= n+1; j++) {
					word = (intptr_t)code[i+1+j];
					code[i+1+j] = SET_OPERAND(word);
				}

				// more
				i += n + 3;
				break;

			case CONCAT_N:
				n = (intptr_t)code[i+1];
				for (j = 1; j <= n; j++) {
					word = (intptr_t)code[i+1+j];
					code[i+1+j] = SET_OPERAND(word);
				}
				word = (intptr_t)code[i+n+2];
				code[i+n+2] = SET_OPERAND(word);

				i += n + 3;
				break;

			default:
				RTFatal("UNKNOWN IL OPCODE");
		}
	}
}


void symtab_set_pointers()
/* set some symbol table fields to absolute pointers, rather than indexes */
{
	intptr_t i, len;
	struct symtab_entry *s;
	intptr_t **code;

	s = fe.st;
	len = *(intptr_t *)s;  // number of entries

	s++;  // point to first real entry
	for (i = 1; i <= len; i++) {
		s->next = (symtab_ptr)SET_OPERAND(s->next);
		s->next_in_block = (symtab_ptr)SET_OPERAND(s->next_in_block);

		if (s->mode == M_NORMAL) {
			// normal variables, routines
			s->obj = NOVALUE;

			if (s->token == PROC ||
				s->token == FUNC ||
				s->token == TYPE) {
				code = (intptr_t **)s->u.subp.code;
				if (code != NULL) {
					code_set_pointers(code);
				}
				s->u.subp.code = (intptr_t *)code+1; // skip length

				s->u.subp.temps = (symtab_ptr)SET_OPERAND(s->u.subp.temps);

				s->u.subp.resident_task = -1;
				s->u.subp.saved_privates = NULL;

				if (s->name[0] == '<' && strcmp(s->name, "<TopLevel>") == 0) {
					TopLevelSub = s;
				}
				s->u.subp.block = (symtab_ptr)SET_OPERAND( s->u.subp.block );
			}
			else{
				s->u.var.declared_in = (symtab_ptr)SET_OPERAND( s->u.var.declared_in );
			}
		}
		else if (s->mode == M_CONSTANT ) {
			if (s->obj) {
				// namespaces, some constants and literal values only
				string_ptr = (unsigned char *)s->obj;
				s->obj = decompress(0);
			}
			else {
				// Set constants to NOVALUE because there may be
				// forward references that require init checks
				s->obj = NOVALUE;
			}

		}
		else if (s->mode == M_BLOCK ) {
			s->u.subp.block = (symtab_ptr)SET_OPERAND( s->u.subp.block );
		}

		else {
			// M_TEMP - temps
			// leave obj as 0
		}
		s++;
	}
}


// routine ids to euphoria std/map routines:
int map_new;
int map_put;
int map_get;

/**
 * Call's the front end's map:new() function
 */
object call_map_new(){
	return internal_general_call_back( map_new, 690, 0, 0, 0, 0, 0, 0, 0, 0 );
}

/**
 * Calls the front end's map:put procedure
 */
void call_map_put( object map, object key, object value, object operation ){
	RefDS( map );
	Ref( key );
	Ref( value );
	internal_general_call_back( map_put, map, key, value, operation, 23 /* default threshold */, 0, 0, 0, 0 );
}

/**
 * Calls the front end's map:get function
 */
object call_map_get( object map, object key, object default_value ){
	RefDS( map );
	Ref( key );
	Ref( default_value );
	return internal_general_call_back( map_get, map, key, default_value, 0, 0, 0, 0, 0, 0 );
}

void analyze_switch()
// changes a SWITCH_RT to a real switch statement
{
/*
 pc+1: switch value
 pc+2: case values
 pc+3: jump_table
 pc+4: else jump

 SET_OPERAND(word) ((intptr_t *)(((word) == 0) ? 0 : (&fe.st[(int)(word)])))
 SET_JUMP(word) ((intptr_t *)(&code[(int)(word)]))
*/

	object a;
	intptr_t min = MAXINT;
	intptr_t max = MININT;
	int all_ints = 1;
	int negative;
	int offset;
	object sym;
	s1_ptr values = SEQ_PTR( *(object_ptr)tpc[2] );
	s1_ptr jump   = SEQ_PTR( *(object_ptr)tpc[3] );
	s1_ptr new_values = NewS1( values->length );
	s1_ptr lookup;
	int i;
	object top;
	object unique_jumps;
	s1_ptr unique_values;
	object unique_values_obj;
	object empty_sequence;
	object check_map;

	unique_jumps = call_map_new();
	unique_values = NewS1( values->length );
	unique_values->postfill = unique_values->length;
	unique_values->length = 0;
	unique_values->base[1] = NOVALUE;
	unique_values_obj = MAKE_SEQ( unique_values );
	empty_sequence = MAKE_SEQ( NewS1(0) );
	for( i = 1; i <= values->length; ++i ){
		negative = 0;
		sym = values->base[i];
		if( sym < 0 ){
			negative = 1;
			sym = -sym;
		}
		top = fe.st[sym].obj;

		if( top == NOVALUE ){
			NoValue( &fe.st[sym] );
		}

		// int check
		if (IS_ATOM_INT(top) || IS_ATOM_DBL(top)) {
			if (!IS_ATOM_INT(top) ) {
				a = DoubleToInt(top);
				if (IS_ATOM_INT(a)) {
					DeRefDS(top);
					top = a;
				}
			}

			if( top > max ) max = top;
			if( top < min ) min = top;
		}
		else{
			all_ints = 0;
		}

		if( negative ){

			if( IS_ATOM_INT( top ) ){
				if (top == MININT) {
					top = (object)NewDouble((eudouble)-MININT);
				}
				else
					top = -top;
			}
			else {
				top = unary_op( UMINUS, top );
			}

			new_values->base[i] = top;
		}
		else{

			new_values->base[i] = fe.st[sym].obj;
		}
		Ref( new_values->base[i] );
		
		// Use a std;map just like in the front end to check for duplicate case values:
		check_map = call_map_get( unique_jumps, jump->base[i], empty_sequence );
		if( find_from( new_values->base[i], check_map, 1 ) ){
			// duplicate value in the same case..ok
		}
		else if( find_from( new_values->base[i], unique_values_obj, 1 ) ){
			// error!
			// TODO: report correct line, value
			// Currently points to top of the switch, and reports
			// the offending symbol or symbols, but not a value, as
			// there is currently no way to pretty sprint into a buffer
			symtab_ptr first, second;
			object second_val;
			first = 0;
			second_val = new_values->base[i];
			second = fe.st + sym;
			while( --i ){
				int c = 0;
				if( new_values->base[i] == second_val ){
					c = 1;
				}
				else if( !IS_ATOM_INT( new_values->base[i] ) || IS_ATOM_INT( second_val ) ){
					c = (0 == compare( new_values->base[i], second_val ) );
				}
				if( c ){
					sym = values->base[i];
					if( sym < 0 ){
						sym = -sym;
					}
					first = fe.st + sym;
					break;
				}
			}
			if( first->name && second->name ){
				RTFatal("duplicate values in a switch: %s and %s", first->name, second->name );
			}
			else if( first->name ){
				RTFatal("duplicate values in a switch: %s and a literal value", first->name );
			}
			else if( second->name ){
				RTFatal("duplicate values in a switch: %s and a literal value", second->name );
			}
			else{
				// this shouldn't happen
				RTFatal("duplicate values in a switch" );
			}
		}
		else{
			// new value...
			call_map_put( unique_jumps, jump->base[i], new_values->base[i], 6 /* map:APPEND */ );
			Append( &unique_values_obj, unique_values_obj, new_values->base[i] );
			unique_values = SEQ_PTR( unique_values_obj );
		}
		DeRefDS( check_map );
	}
	DeRefDS( unique_jumps );
	DeRefDS( empty_sequence );
	DeRefDS( unique_values_obj );

	DeRefDS( MAKE_SEQ( values ) );
	if( all_ints &&  max - min < 1024){
		*tpc = (intptr_t)opcode( SWITCH_SPI );

		// calculate the 'else' jump as a relative jump:
		offset = (tpc[4]-(intptr_t)tpc) / sizeof( intptr_t );

		a = Repeat( offset, max - min + 1 );
		lookup = SEQ_PTR( a );
		offset = min - 1;
		for( i = 1; i <= new_values->length; ++i ){
			lookup->base[new_values->base[i] - offset] = jump->base[i];
		}
		tpc[2] = (intptr_t)offset;
		DeRefDS( *(object_ptr)tpc[3] );
		*(object_ptr)tpc[3] = (object)MAKE_SEQ( lookup );
	}
	else{
		*(object_ptr)tpc[2] = (object)MAKE_SEQ( new_values );
		if( all_ints ){
			*tpc = (intptr_t)opcode( SWITCH_I );
		}
		else{
			*tpc = (intptr_t)opcode( SWITCH );
		}
	}
}

struct sline *slist;

/* Front-end variables passed via miscellaneous fe.misc */
char **file_name;
#ifdef EWINDOWS
extern DWORD WINAPI WinTimer(LPVOID lpParameter);
#endif
int max_stack_per_call;
int AnyTimeProfile;
int AnyStatementProfile;
int sample_size;
int gline_number;  /* last global line number in program */
int il_file;       /* we are processing a separate .il file */

void fe_set_pointers()
{
	symtab_set_pointers();

	slist = fe.sl;

	max_stack_per_call = fe.misc[0];
	AnyTimeProfile     = fe.misc[1];
	AnyStatementProfile= fe.misc[2];
	sample_size        = fe.misc[3];

#if defined(EWINDOWS)
	if (sample_size > 0) {
		profile_sample = (intptr_t *)EMalloc(sample_size * sizeof(intptr_t));
		//lock_region(profile_sample, sample_size * sizeof(int));
		//tick_rate(100);
		SetThreadPriority(CreateThread(0,0,WinTimer,0,0,0),THREAD_PRIORITY_TIME_CRITICAL);
	}
#endif
	gline_number = fe.misc[4];
	il_file      = fe.misc[5];

	warning_count = fe.misc[6];
	file_name = (char **)&fe.misc[7];
	file_name_entered = (char *)fe.misc[8+fe.misc[7]];
	warning_list = (char **)&fe.misc[9+fe.misc[7]];

	// string containing all literals and constants in compressed form:
	EFree(fe.lit);
}

static object *save_private_block(symtab_ptr routine)
// Save block for resident task on the private list for this routine.
// Save in last-in, first-out order.
// We use a linked list. The data is filled in by the caller after the call.
{
	struct private_block *entry;
	int size, task;

	size = routine->u.subp.stack_space;
	task = routine->u.subp.resident_task;
	entry = (struct private_block *)
			EMalloc(sizeof(struct private_block) + size * sizeof(object));

	entry->task_number = task;

	// insert block at front of list
	entry->next = routine->u.subp.saved_privates;
	routine->u.subp.saved_privates = entry;

	return (object *)&(entry->block); //private data will be filled in by caller
}


static void load_private_block(symtab_ptr routine, int task)
// Retrieve a private block and remove it from the list for this routine.
// We know that the block will be there, often near the start of the list.
{
	struct private_block *p;
	struct private_block *prev_p;

	object *block;
	symtab_ptr sym;

	p = routine->u.subp.saved_privates; // won't be NULL
	prev_p = NULL;

	while (TRUE) {
		if (p->task_number == task) {
			block = (object *)&(p->block);

			// unlink it
			if (prev_p == NULL) {
				routine->u.subp.saved_privates = p->next;
			}
			else {
				prev_p->next = p->next;
			}

			// N.B. must read temps and privates *before* freeing p

			// private vars
			sym = routine->next;
			while (sym != NULL && sym->scope <= S_PRIVATE) {
				sym->obj = *block++;
				sym = sym->next;
			}

			// temps
			sym = routine->u.subp.temps;
			while (sym != NULL) {
				sym->obj = *block++;
				sym = sym->next;
			}

			EFree((char *)p);
			return;
		}
		prev_p = p;
		p = p->next;
	}
}

void restore_privates(symtab_ptr this_routine)
// kick out the current private data and
// restore the private data for the current task
{
	symtab_ptr sym;
	object *block;

	if (this_routine != NULL &&
		this_routine->u.subp.resident_task != current_task) {
		// get new private data

		if (this_routine->u.subp.resident_task != -1) {
			// calling routine was taken over by another task

			// save the other task's private data
			block = save_private_block(this_routine);

			// private vars
			sym = this_routine->next;
			while (sym != NULL && sym->scope <= S_PRIVATE) {
				*block++ = sym->obj;
				sym = sym->next;
			}

			// temps
			sym = this_routine->u.subp.temps;
			while (sym != NULL) {
				*block++ = sym->obj;
				sym = sym->next;
			}
		}

		// restore the current task's private data (will always be there)

		load_private_block(this_routine, current_task);

		this_routine->u.subp.resident_task = current_task;
	}
}

void Execute(intptr_t *start_index)
/* top level executor */
/* CAREFUL: any change to this routine might affect the offset to
   the big opccode switch table - see jumptab */
{
	do_exec(start_index);

	Executing = FALSE;
}

#ifndef INT_CODES
#if defined(EUNIX) || defined(EMINGW)
// don't use switch/case - use special jump to label feature
#define case
#endif
#endif //not INT_CODES


void do_exec(intptr_t *start_pc)
/* execute code, starting at start_pc */
{
	/* WATCOM keeps pc in a register, and usually top, a, obj_ptr */

	/* address registers: (3 max) */
	register intptr_t *pc;               /* program counter, kept in a register */
	register object_ptr obj_ptr = 0;    /* general pointer to an object */

	/* data registers: (5 max) */
	register object a;            /* another object */
	volatile object v;            /* get compiler to do the right thing! */
	register object top = 0;          /* an object - hopefully kept in a register */
	/*register*/ intptr_t i;           /* loop counter */

	eudouble temp_dbl;
	struct d temp_d;
	char *poke_addr;
	void (*sub_addr)();
	int nvars;
#ifndef BACKEND
	int *iptr;
#endif
	object file_no;

	int end_pos;
	int going_up;
	object_ptr result_ptr;
	object result_val;
	int cf;
	int seqlen;
	opcode_type *patch;
	object b, c;
	symtab_ptr sym, sub;
	int c0,splins;
	s1_ptr s1,s2;
	object *block;
	uintptr_t tuint;

#if defined(EUNIX) || defined(EMINGW)
#ifndef INT_CODES
	static void *localjumptab[MAX_OPCODE] = {
  &&L_LESS, &&L_GREATEREQ, &&L_EQUALS, &&L_NOTEQ, &&L_LESSEQ, &&L_GREATER,
  &&L_NOT, &&L_AND, &&L_OR, &&L_MINUS,
/* 10 (previous is 10 (L_MINUS)) */
  &&L_PLUS, &&L_UMINUS, &&L_MULTIPLY, &&L_DIVIDE, &&L_CONCAT, &&L_ASSIGN_SUBS,
  &&L_GETS, &&L_ASSIGN, &&L_PRINT, &&L_IF,
/* 20 (previous) */
  &&L_FOR, &&L_ENDWHILE, &&L_ELSE, &&L_OR_BITS, &&L_RHS_SUBS, &&L_XOR_BITS,
  &&L_PROC, &&L_RETURNF, &&L_RETURNP, &&L_PRIVATE_INIT_CHECK,
/* <- 30 (previous) */
  &&L_RIGHT_BRACE_N, &&L_REPEAT, &&L_GETC, &&L_RETURNT, &&L_APPEND,
  &&L_QPRINT, &&L_OPEN, &&L_PRINTF, &&L_ENDFOR_GENERAL, &&L_IS_AN_OBJECT,
/* <- 40 (previous) */
  &&L_SQRT, &&L_LENGTH, &&L_BADRETURNF, &&L_PUTS, &&L_ASSIGN_SLICE,
  &&L_RHS_SLICE, &&L_WHILE, &&L_ENDFOR_INT_UP, &&L_ENDFOR_UP, &&L_ENDFOR_DOWN,
/* <- 50 (previous) */
  &&L_NOT_BITS, &&L_ENDFOR_INT_DOWN, &&L_SPRINTF, &&L_ENDFOR_INT_UP1,
  &&L_ENDFOR_INT_DOWN1, &&L_AND_BITS, &&L_PREPEND, &&L_STARTLINE,
  &&L_CLEAR_SCREEN, &&L_POSITION,
/* 60 (previous) */
  &&L_EXIT, &&L_RAND, &&L_FLOOR_DIV, &&L_TRACE, &&L_TYPE_CHECK,
  &&L_FLOOR_DIV2, &&L_IS_AN_ATOM, &&L_IS_A_SEQUENCE, &&L_DATE, &&L_TIME,
/* 70 (previous) */
  &&L_REMAINDER, &&L_POWER, &&L_ARCTAN, &&L_LOG, NULL, &&L_COMPARE,
  &&L_FIND, &&L_MATCH, &&L_GET_KEY, &&L_SIN,
/* 80 (previous) */
  &&L_COS, &&L_TAN, &&L_FLOOR, &&L_ASSIGN_SUBS_CHECK, &&L_RIGHT_BRACE_2,
  &&L_CLOSE, &&L_DISPLAY_VAR, &&L_ERASE_PRIVATE_NAMES, &&L_UPDATE_GLOBALS,
  &&L_ERASE_SYMBOL,
/* 90 (previous) */
  &&L_GETENV, &&L_RHS_SUBS_CHECK, &&L_PLUS1, &&L_IS_AN_INTEGER,
  &&L_LHS_SUBS, &&L_INTEGER_CHECK, &&L_SEQUENCE_CHECK, &&L_DIV2,
  &&L_SYSTEM, &&L_COMMAND_LINE,
/* 100 (previous) */
  &&L_ATOM_CHECK, &&L_LESS_IFW, &&L_GREATEREQ_IFW, &&L_EQUALS_IFW,
  &&L_NOTEQ_IFW, &&L_LESSEQ_IFW, &&L_GREATER_IFW, &&L_NOT_IFW,
  &&L_GLOBAL_INIT_CHECK, &&L_NOP2,
/* 110 (previous) */
  &&L_MACHINE_FUNC, &&L_MACHINE_PROC, &&L_ASSIGN_I, &&L_RHS_SUBS_I,
  &&L_PLUS_I, &&L_MINUS_I, &&L_PLUS1_I, &&L_ASSIGN_SUBS_I, &&L_LESS_IFW_I,
  &&L_GREATEREQ_IFW_I,
/* 120 (previous) */
  &&L_EQUALS_IFW_I, &&L_NOTEQ_IFW_I, &&L_LESSEQ_IFW_I, &&L_GREATER_IFW_I,
  &&L_FOR_I, &&L_ABORT, &&L_PEEK, &&L_POKE, &&L_CALL,
/* 130 (previous) */
  &&L_MEM_COPY, &&L_MEM_SET, &&L_C_PROC, &&L_C_FUNC,
  &&L_ROUTINE_ID, &&L_CALL_BACK_RETURN, &&L_CALL_PROC, &&L_CALL_FUNC,
  &&L_POKE4,
/* 140 (previous) */
  &&L_PEEK4S, &&L_PEEK4U, &&L_SC1_AND, &&L_SC2_AND, &&L_SC1_OR,
  &&L_SC2_OR, NULL, &&L_SC1_AND_IF, &&L_SC1_OR_IF, NULL,
/* 150 (previous) */
  &&L_ASSIGN_OP_SUBS, &&L_ASSIGN_OP_SLICE, &&L_PROFILE, &&L_XOR, &&L_EQUAL,
  &&L_SYSTEM_EXEC,
  &&L_PLATFORM /* PLATFORM not always emitted*/,
  NULL /* END_PARAM_CHECK not emitted */,
  &&L_CONCAT_N,
  NULL, /* L_NOPWHILE not emitted */
/* 160 (previous) */
  NULL, /* L_NOP1 not emitted */
  &&L_PLENGTH,
  &&L_LHS_SUBS1,
  &&L_PASSIGN_SUBS, &&L_PASSIGN_SLICE, &&L_PASSIGN_OP_SUBS,
  &&L_PASSIGN_OP_SLICE,
  &&L_LHS_SUBS1_COPY,
/* 168 (previous) */
  &&L_TASK_CREATE, &&L_TASK_SCHEDULE, &&L_TASK_YIELD,
  &&L_TASK_SELF, &&L_TASK_SUSPEND, &&L_TASK_LIST,
  &&L_TASK_STATUS, &&L_TASK_CLOCK_STOP, &&L_TASK_CLOCK_START,
/* 177 (previous) */
  &&L_FIND_FROM, &&L_MATCH_FROM,
  &&L_POKE2, &&L_PEEK2S, &&L_PEEK2U, &&L_PEEKS, &&L_PEEK_STRING,
  &&L_OPTION_SWITCHES, &&L_RETRY, &&L_SWITCH,
/* 187 (previous)*/
  NULL, NULL,/* L_CASE, L_NOPSWITCH not emitted*/
  &&L_GOTO, &&L_GLABEL, &&L_SPLICE, &&L_INSERT,
/* 193 (previous) */
  &&L_SWITCH_SPI, &&L_SWITCH_I, &&L_HASH,
/* 196 (previous) */
 NULL, NULL, NULL, /* L_PROC_FORWARD, L_FUNC_FORWARD, TYPE_CHECK_FORWARD not emitted */
  &&L_HEAD, &&L_TAIL, &&L_REMOVE, &&L_REPLACE, &&L_SWITCH_RT,
/* 204 (previous) */
  &&L_PROC_TAIL, &&L_DELETE_ROUTINE, &&L_DELETE_OBJECT, &&L_EXIT_BLOCK,
/* 207 (previous) */
  &&L_REF_TEMP, &&L_DEREF_TEMP, &&L_NOVALUE_TEMP,
/* 209 (previous) */
  &&L_COVERAGE_LINE, &&L_COVERAGE_ROUTINE,
/* 211 (previous) */
  &&L_POKE8, &&L_PEEK8S, &&L_PEEK8U,
/* 214 (previous) */
  &&L_POKE_POINTER, &&L_PEEK_POINTER,
/* 215 (previous) */
  &&L_SIZEOF, &&L_STARTLINE_BREAK
  };
#endif
#endif
	if (start_pc == NULL) {
#if defined(EUNIX) || defined(EMINGW)
#ifndef INT_CODES
		jumptab = (intptr_t **)localjumptab;
#endif
#endif
		return;
	}

	/* Initialize run-time data structures: */
	result_ptr = NULL;
	cf = FALSE;
	tpc = start_pc;
	pc = tpc;

	Executing = TRUE;

	do {
#ifdef INT_CODES
	  loop_top:

		if (*pc < 1 || *pc > MAX_OPCODE) {
			tpc = pc;
			RTFatal("Runtime bad opcode (%d) at %lx", *pc, pc);
		}

		switch(*pc) {
#else
// threaded code
		if (Executing == FALSE)
		{
			// TODO  XXX might this affect exit code improperly?
			Cleanup(1);
			return;
		}
		thread();
		switch((intptr_t)pc) {

#endif
			case L_RHS_SUBS_CHECK:
			deprintf("case L_RHS_SUBS_CHECK:");
				if (!IS_SEQUENCE(*(object_ptr)pc[1])) {
					goto subsfail;
				}
				/* FALL THROUGH */
			case L_RHS_SUBS: /* rhs subscript of a sequence */
			deprintf("case L_RHS_SUBS:");
				top = *(object_ptr)pc[2];  /* the subscript */
				obj_ptr = (object_ptr)SEQ_PTR(*(object_ptr)pc[1]);/* the sequence */
				if ((uintptr_t)(top-1) >= (uintptr_t)((s1_ptr)obj_ptr)->length) {
					tpc = pc;
					top = recover_rhs_subscript(top, (s1_ptr)obj_ptr);
				}
				top = (object)*(top + ((s1_ptr)obj_ptr)->base);
				a = pc[3];

				Ref( top );
				DeRef( ((symtab_ptr)a)->obj );

				*(object_ptr)a = top;
				pc += 4;
				thread();
				BREAK;

			case L_RHS_SUBS_I: /* rhs subscript of a known-to-be sequence */
			deprintf("case L_RHS_SUBS_I:");
				/* the target is an integer variable - no DeRef,
				   TypeCheck failure if assigned non-integer */
				top = *(object_ptr)pc[2];  /* the subscript */
				obj_ptr = (object_ptr)SEQ_PTR(*(object_ptr)pc[1]);/* the sequence */
				if ((uintptr_t)(top-1) >= (uintptr_t)((s1_ptr)obj_ptr)->length) {
					/* possibly bad subscript */
					tpc = pc;
					top = recover_rhs_subscript(top, (s1_ptr)obj_ptr);
				}
				top = (object)*(top + ((s1_ptr)obj_ptr)->base);
				a = pc[3];
				pc += 4;
				*(object_ptr)a = top;
				if (IS_ATOM_INT(top)) {
					thread();
					BREAK;
				}
				else {
					if (IS_ATOM_DBL(top)) {
						tpc = pc;
						top = DoubleToInt(top);
						if (IS_ATOM_INT(top)) {
							*(object_ptr)a = top;
							BREAK;
						}
					}
					RTFatalType(pc-1);
					BREAK;
				}

			case L_PASSIGN_OP_SUBS:
			deprintf("case L_PASSIGN_OP_SUBS:");
				// temp has pointer to sequence
				top = **(object_ptr *)pc[1];
				goto aos;

			case L_ASSIGN_OP_SUBS:  /* var[subs] op= expr
			pc[0..3] = { 0: L_ASSIGN_OP_SUBS
				     1: in:var,
				     2: in:subs,
				     3: *out: destination address
				     4: ??
				     5:
				     6:
				     7: in:rhs value
				     8: Already there:ASSIGN_SUBS op?
				     9: out: in:var
			 */
			deprintf("case L_ASSIGN_OP_SUBS:");
				top = *(object_ptr)pc[1];
			  aos:
				if (!IS_SEQUENCE(top)) {  //optimize better
					goto subsfail;
				}
				obj_ptr = (object_ptr)SEQ_PTR(top);/* the sequence */
				top = *(object_ptr)pc[2];  /* the subscript */
				pc[9] = pc[1]; // store in ASSIGN_SUBS op after length-4 binop
				if ((uintptr_t)(top-1) >= (uintptr_t)((s1_ptr)obj_ptr)->length) {
					/* possibly bad subscript */
					tpc = pc;
					top = recover_rhs_subscript(top, (s1_ptr)obj_ptr);
				}
				top = (object)*(top + ((s1_ptr)obj_ptr)->base);
				a = pc[3];
				pc += 4;
				if (IS_ATOM_INT(top)) {
					if (IS_ATOM_INT_NV(*(object_ptr)a)) {
						*(object_ptr)a = top;
						thread();
						BREAK;
					}
					else {
						DeRefDSx(*(object_ptr)a);
						*(object_ptr)a = top;
						thread();
						BREAK;
					}
				}
				else {
					RefDS(top);
					DeRefx(*(object_ptr)a);
					*(object_ptr)a = top;
					thread();
					BREAK;
				}

			case L_PASSIGN_SUBS:
			deprintf("case L_PASSIGN_SUBS:");
				// temp has pointer to sequence
				top = *(object_ptr)pc[3];  /* the rhs value */
				Ref(top); /* do before UNIQUE check - avoids circularity */
				obj_ptr = (object_ptr)SEQ_PTR(**(object_ptr **)pc[1]);
				if (!UNIQUE(obj_ptr)) {
					/* make it single-ref */
					tpc = pc;
					obj_ptr = (object_ptr)SequenceCopy((s1_ptr)obj_ptr);
					**(object_ptr *)pc[1] = MAKE_SEQ(obj_ptr);
				}
				*(object_ptr)pc[1] = 0; // to preclude DeRef of C pointer
				goto as;

			case L_ASSIGN_SUBS_CHECK:
			deprintf("case L_ASSIGN_SUBS_CHECK:");
				if (!IS_SEQUENCE(*(object_ptr)pc[1])) {
					goto asubsfail;
				}
				/* FALL THROUGH */

			case L_ASSIGN_SUBS:  /* final subscript and assignment */
			deprintf("case L_ASSIGN_SUBS:");

				/* the var sequence */
				top = *(object_ptr)pc[3];  /* the rhs value */
				Ref(top); /* do before UNIQUE check - avoids circularity */
				obj_ptr = (object_ptr)SEQ_PTR(*(object_ptr *)pc[1]);
				if (!UNIQUE(obj_ptr)) {
					/* make it single-ref */
					tpc = pc;
					obj_ptr = (object_ptr)SequenceCopy((s1_ptr)obj_ptr);
					*(object_ptr)pc[1] = MAKE_SEQ(obj_ptr);
				}

			  as:
				a = *(object_ptr)pc[2]; /* the subscript */
				if ((uintptr_t)(a-1) >= (uintptr_t)((s1_ptr)obj_ptr)->length) {
					/* subscript out of bounds (or it's a double) */
					tpc = pc;
					a = recover_lhs_subscript(a, (s1_ptr)obj_ptr);
				}

				obj_ptr = a + ((s1_ptr)obj_ptr)->base;
				a = *obj_ptr;
				*obj_ptr = top;
				pc += 4;
				if (IS_ATOM_INT_NV(a)) {
					thread();
					BREAK;
				}
				else {
					DeRefDSx(a);
					thread();
					BREAK;
				}

			case L_ASSIGN_SUBS_I:  /* final subscript and assignment */
			deprintf("case L_ASSIGN_SUBS_I:");
				/* we know that the rhs value to be assigned is an integer */
				obj_ptr = (object_ptr)SEQ_PTR(*(object_ptr *)pc[1]);/* the sequence */
				if (!UNIQUE(obj_ptr)) {
					/* make it single-ref */
					tpc = pc;
					obj_ptr = (object_ptr)SequenceCopy((s1_ptr)obj_ptr);
					*(object_ptr)pc[1] = MAKE_SEQ(obj_ptr);
				}
				top = *(object_ptr)pc[2]; /* the subscript */
				if ((uintptr_t)(top-1) >= (uintptr_t)((s1_ptr)obj_ptr)->length) {
					/* subscript out of bounds (or it's a double) */
					tpc = pc;
					top = recover_lhs_subscript(top, (s1_ptr)obj_ptr);
				}
				obj_ptr = top + ((s1_ptr)obj_ptr)->base;
				top = *obj_ptr;   // the previous value
				pc += 4;
				*obj_ptr = *(object_ptr)pc[-1]; // the RHS value
				if (IS_ATOM_INT_NV(top)) {
					thread();
					BREAK;
				}
				else {
					DeRefDSx(top);
					thread();
					BREAK;
				}

			case L_ENDFOR_INT_UP1:
			deprintf("case L_ENDFOR_INT_UP1:");
				obj_ptr = (object_ptr)pc[3]; /* loop var */
				top = *obj_ptr + 1;
				if (top <= *(object_ptr)pc[2]) {  /* limit */
					*obj_ptr = top;
					pc = (intptr_t *)pc[1];   /* loop again */
					thread();
				}
				else {
					thread5();  /* exit loop */
				}
				BREAK;

			case L_ENDFOR_INT_UP:
			deprintf("case L_ENDFOR_INT_UP:");
				obj_ptr = (object_ptr)pc[3]; /* loop var */
				top = *obj_ptr + *(object_ptr)pc[4]; /* increment */
				if (top <= *(object_ptr)pc[2]) { /* limit */
					*obj_ptr = top;
					pc = (intptr_t *)pc[1]; /* loop again */
					thread();
				}
				else {
					thread5();  /* exit loop */
				}
				BREAK;


			case L_EXIT:
			deprintf("case L_EXIT:");
			case L_ENDWHILE:
			deprintf("case L_ENDWHILE:");
			case L_ELSE:
			deprintf("case L_ELSE:");
			case L_RETRY:
			deprintf("case L_RETRY:");
				pc = (intptr_t *)pc[1];
				thread();
				BREAK;

			case L_GOTO:
			deprintf("case L_GOTO:");
				pc = (intptr_t *)pc[1];
				thread();
				BREAK;

			case L_GLABEL:
			deprintf("case L_GLABEL:");
				pc = (intptr_t *)pc[1];
				thread();
				BREAK;

			case L_PLUS1:
			deprintf("case L_PLUS1:");
				a = (object)pc[3];
				top = *(object_ptr)pc[1];
				if (IS_ATOM_INT(top)) {
					top++;
					if (top > MAXINT) {
						b = top;
						top = NewDouble((eudouble)(INT_VAL(b)));
					}
					if (IS_ATOM_INT_NV(*(object_ptr)a)) {
						*(object_ptr)a = top;
						thread4(); /* common case */
					}
				}
				else {
					tpc = pc;
					top = binary_op(PLUS, ATOM_1, top);
				}
				DeRefx(*(object_ptr)a);
				*(object_ptr)a = top;
				thread4();
				BREAK;

			case L_PLUS1_I:
			deprintf("case L_PLUS1_I:");
				/* target must be integer var - type check */
				top = *(object_ptr)pc[1];
				a = (object)pc[3];
				pc += 4;
				if (IS_ATOM_INT(top)) {
					top++;
					if (top <= MAXINT) {
						*(object_ptr)a = top;
						thread();   /* common case */
						BREAK;
					}
					b = top;
					tpc = pc - 4;
					*(object_ptr)a = NewDouble((eudouble)(INT_VAL(b)));
				}
				else {
					tpc = pc - 4;
					top = binary_op(PLUS, ATOM_1, top);
					if (IS_ATOM_DBL(top)) {
						b = DoubleToInt(top);
						if (IS_ATOM_INT(b)) {
							DeRefDS(top);
							*(object_ptr)a = b;
							BREAK;
						}
					}
					*(object_ptr)a = top;
				}
				RTFatalType(pc-1); /* point at dest var */
				BREAK;

			case L_WHILE:
			deprintf("case L_WHILE:");
				top = *(object_ptr)pc[1];
				if (top >= ATOM_1) {   /* works with new representation */
					inc3pc();
					thread();
					pc++; /* dummy */
					BREAK;
				}
				goto if_check;

			case L_SWITCH_RT:
				tpc = pc;

				// *pc will be updated by analyze_switch()
				analyze_switch();
				thread();
				BREAK;

			case L_SWITCH_SPI:
			deprintf("case L_SWITCH_SPI:");
				tpc = pc;
				a = *(object_ptr)pc[1];
				if( IS_SEQUENCE( a ) ){
					// no match:  goto else or skip the switch
					pc = (intptr_t *) pc[4];
					thread();
					BREAK;
				}
				if( !IS_ATOM_INT( a ) ){
					// have to check for integer value
					top = (intptr_t) DBL_PTR( a )->dbl;
					if( (eudouble)top == DBL_PTR( a )->dbl ){
						a = (intptr_t) DBL_PTR( a )->dbl;
					}
					else{
						pc = (intptr_t *) pc[4];
						thread();
						BREAK;
					}
				}
				a -= pc[2];

				if( a > 0 && a <=  SEQ_PTR( *(object_ptr)pc[3])->length ){
					// bounds check
					top = SEQ_PTR( *(object_ptr)pc[3])->base[a];
					pc += top;
					thread();
					BREAK;
				}
				pc = (intptr_t *) pc[4];
				thread();
				BREAK;

			case L_SWITCH_I:
			deprintf("case L_SWITCH_I:");
				tpc = pc;
				a = *(object_ptr)pc[1];
				if( IS_SEQUENCE( a ) ){
					// no match:  goto else or skip the switch
					pc = (intptr_t *) pc[4];
					thread();
					BREAK;
				}
				if( !IS_ATOM_INT( a ) ){
					// have to check for integer value
					top = (intptr_t) DBL_PTR( a )->dbl;
					if( (eudouble)top == DBL_PTR( a )->dbl ){
						a = (intptr_t) DBL_PTR( a )->dbl;
					}
					else{
						pc = (intptr_t *) pc[4];
						thread();
						BREAK;
					}
				}
				top = SEQ_PTR( *(object_ptr)pc[2])->length;
				obj_ptr = SEQ_PTR( *(object_ptr)pc[2])->base;
				for( b = 1; b <= top; ++b ){
					if( a == *++obj_ptr ){
						pc += SEQ_PTR(*(object_ptr)pc[3])->base[b];
						thread();
						BREAK;
					}
				}
				// no match
				pc = (intptr_t *) pc[4];
				thread();
				BREAK;

			case L_SWITCH:
			deprintf("case L_SWITCH:");

				tpc = pc;
				// find which case is met:
				a = find(*(object_ptr)pc[1], (s1_ptr)*(object_ptr)pc[2]);
				top = MAKE_INT(a);
				if( top ){
					// a is the index in the jump table
		  			a = SEQ_PTR(*(object_ptr)pc[3])->base[top];
		  			pc += a;
		  		}
		  		else{
		  			// no match:  goto else or skip the switch
					pc = (intptr_t *) pc[4];
		  		}

		  		thread();
		  		BREAK;
			case L_IF:
			deprintf("case L_IF:");
				top = *(object_ptr)pc[1];
			if_check:
				if (top == ATOM_0) {
					pc = (intptr_t *)pc[2];
					thread();
					pc++; /* DUMMY ! */
				}
				else if (IS_ATOM_INT(top)) {
					inc3pc();
					thread();
					pc += 9; /* DUMMY ! */
				}
				else {
					if (IS_SEQUENCE(top)) {
						tpc = pc;
						atom_condition();
					}
					if (DBL_PTR(top)->dbl == 0.0) {
						pc = (intptr_t *)pc[2];
					}
					else
						inc3pc();
					thread();
				}
				BREAK;

			case L_ASSIGN_I:
			deprintf("case L_ASSIGN_I:");
				/* source & destination are known to be integers */
#if DEBUG_OPCODE_TRACE
				deprintf("(");
				SHOW_PARAM(pc[2]);
				deprintf(", ");
				SHOW_PARAM((*(intptr_t*)pc[1]));
				deprintf(")");
#endif
				*(object_ptr)pc[2] = *(object_ptr)pc[1];
				inc3pc();
				thread();
				BREAK;

			case L_ASSIGN:
			deprintf("case L_ASSIGN:");
				obj_ptr = (object_ptr)pc[2];
#if DEBUG_OPCODE_TRACE
				deprintf("(");
				SHOW_PARAM(pc[2]);
				deprintf(", ");
				SHOW_PARAM((*(intptr_t *)pc[1]));
				deprintf(")");
#endif
				top = *obj_ptr;
				*obj_ptr = *(object_ptr)pc[1];

				Ref(*obj_ptr);

				if (IS_ATOM_INT_NV(top)) {
					inc3pc();
					thread();
					BREAK;
				}
				else {
					DeRefDSx(top);
					inc3pc();
					thread();
					BREAK;
				}

			case L_LHS_SUBS:
			deprintf("case L_LHS_SUBS:");
				// temp contains a pointer to the sequence
				obj_ptr = (object_ptr)*(object_ptr)pc[1];
				goto ls;

			case L_LHS_SUBS1_COPY:
			deprintf("case L_LHS_SUBS1_COPY:");
				// copy base sequence into a temp, then use the temp
				obj_ptr = (object_ptr)pc[4];
				a = *(object_ptr)pc[1];
				Ref(a);
				*obj_ptr = a;
				goto ls;

			case L_LHS_SUBS1:
			deprintf("case L_LHS_SUBS1:");
				/* left hand side, first subscript of multiple lhs subscripts */
				// sequence var:
				obj_ptr = (object_ptr)pc[1];
			  ls:
				// subscript:
				a = *(object_ptr)pc[2];
				top = *obj_ptr;
				if (!IS_SEQUENCE(top)) {
					goto asubsfail;
				}
				top = (object)SEQ_PTR(top);
				if (!UNIQUE(top)) {
					tpc = pc;
					top = (object)SequenceCopy((s1_ptr)top);
					*obj_ptr = MAKE_SEQ(top);
				}
				obj_ptr = (object_ptr)top;
				// The variable, a, seems to index past the end of the sequence.
				if ((uintptr_t)(a-1) >= (uintptr_t)((s1_ptr)obj_ptr)->length) {
					tpc = pc;
					// It may be an encoded pointer to d struct.
					// Do a check in the routine below.
					a = recover_lhs_subscript(a, (s1_ptr)obj_ptr);
				}
				obj_ptr = a + ((s1_ptr)obj_ptr)->base;

				// error-check for sequence
				if (IS_SEQUENCE(*obj_ptr)) {
					top = pc[3]; // target temp
					*((object_ptr)top) = (object)obj_ptr; // storing a C pointer
					thread5();
				}
				goto asubsfail;
				BREAK;

			case L_PASSIGN_OP_SLICE:
			deprintf("case L_PASSIGN_OP_SLICE:");
				// temp has pointer to sequence
				top = *(object_ptr)pc[1];
				goto aosl;

			case L_ASSIGN_OP_SLICE:  /* var[i..j] op= expr */
			deprintf("case L_ASSIGN_OP_SLICE:");
				top = pc[1];
			 aosl:
				pc[10] = pc[1];
				rhs_slice_target = (object_ptr)pc[4];
				tpc = pc;
				RHS_Slice(*(object_ptr)top,
						  *(object_ptr)pc[2],
						  *(object_ptr)pc[3]);
				thread5();
				BREAK;

			case L_PASSIGN_SLICE:
			deprintf("case L_PASSIGN_SLICE:");
				// temp contains pointer to sequence
				assign_slice_seq = (s1_ptr *)*(object_ptr)pc[1];
				*(object_ptr)pc[1] = 0; // preclude DeRef of C pointer
				goto las;

			case L_ASSIGN_SLICE: /* var[i..j] = expr */
			deprintf("case L_ASSIGN_SLICE:");
				assign_slice_seq = (s1_ptr *)pc[1]; /* extra parameter */
			  las:
				tpc = pc;
				AssignSlice(*(object_ptr)pc[2],
							*(object_ptr)pc[3],  /* 3 args max for good code */
							*(object_ptr)pc[4]);
				thread5();
				BREAK;

			case L_RHS_SLICE: /* rhs slice of a sequence a[i..j] */
			deprintf("case L_RHS_SLICE:");
				tpc = pc;
				rhs_slice_target = (object_ptr)pc[4];
				RHS_Slice(*(object_ptr)pc[1],
						  *(object_ptr)pc[2],
						  *(object_ptr)pc[3]);
				thread5();
				BREAK;

			case L_RIGHT_BRACE_N: /* form a sequence of any length */
			deprintf("case L_RIGHT_BRACE_N:");
				nvars = pc[1];
				pc += 2;
				tpc = pc;
				s1 = NewS1(nvars);
				obj_ptr = s1->base + nvars;
				for (a = 1; a <= nvars; a++) {
					/* the last one comes first */
					*obj_ptr = *((object_ptr)pc[0]);
					Ref(*obj_ptr);
					pc++;
					obj_ptr--;
				}
				DeRef(*(object_ptr)pc[0]);
				*(object_ptr)pc[0] = MAKE_SEQ(s1);
				pc++;
				thread();
				BREAK;

			case L_RIGHT_BRACE_2: /* form a sequence of length 2 */
			deprintf("case L_RIGHT_BRACE_2:");
				tpc = pc;
				s1 = NewS1(2);
				obj_ptr = s1->base;
				/* the second one comes first */
				obj_ptr[1] = *((object_ptr)pc[2]);
				Ref(obj_ptr[1]);
				obj_ptr[2] = *((object_ptr)pc[1]);
				Ref(obj_ptr[2]);
				DeRef(*(object_ptr)pc[3]);
				*(object_ptr)pc[3] = MAKE_SEQ(s1);
				pc += 4;
				thread();
				BREAK;

			case L_TYPE_CHECK: /* top has TRUE/FALSE */
			deprintf("case L_TYPE_CHECK:");
				/* type check for a user-defined type */
				/* this always follows a type-call */
				top = *(object_ptr)pc[-1];
				pc += 1;
				if (top == ATOM_1) {
					thread();
					BREAK;  /* usual case L_*/
				}
				else if (IS_ATOM_INT(top)) {
					if (top == ATOM_0)
						RTFatalType(pc-3);
				}
				else if (IS_ATOM_DBL(top)) {
					if (DBL_PTR(top)->dbl == 0.0)
						RTFatalType(pc-3);
				}
				else  {/* sequence */
					type_error_msg =
						"\ntype_check failure (type returned a sequence!), ";
					RTFatalType(pc-3);
				}
				BREAK;

			case L_NOP2:
			deprintf("case L_NOP2:");
				thread2();
				BREAK;

			case L_GLOBAL_INIT_CHECK:
			deprintf("case L_GLOBAL_INIT_CHECK:");
				pc += 2;
				if (*(object_ptr)pc[-1] != NOVALUE) {
					*(pc - 2) = (intptr_t)opcode(NOP2);
					thread();
					BREAK;
				}
				tpc = pc;
				NoValue((symtab_ptr)pc[-1]);
				BREAK;

			case L_PRIVATE_INIT_CHECK:
			deprintf("case L_PRIVATE_INIT_CHECK:");
				pc += 2;
				if (*(object_ptr)pc[-1] != NOVALUE) {
					thread();
					BREAK;
				}
				tpc = pc;
				NoValue((symtab_ptr)pc[-1]);
				BREAK;

			case L_INTEGER_CHECK:
			deprintf("case L_INTEGER_CHECK:");
				top = *(object_ptr)pc[1];
				pc += 2;
				if (IS_ATOM_INT(top)) {
					thread();
					BREAK;
				}
				else if (IS_ATOM_DBL(top)) {
					tpc = pc;
					a = DoubleToInt(top);
					if (IS_ATOM_INT(a)) {
						DeRefDS(top);
						*(object_ptr)pc[-1] = a;
						BREAK;
					}
				}
				RTFatalType(pc-1);
				BREAK;

			case L_ATOM_CHECK:
			deprintf("case L_ATOM_CHECK:");
				pc += 2;
				if (IS_ATOM(*(object_ptr)pc[-1])) {
					thread();
					BREAK;
				}
				RTFatalType(pc-1);
				BREAK;

			case L_SEQUENCE_CHECK:
			deprintf("case L_SEQUENCE_CHECK:");
				pc += 2;
				if (IS_SEQUENCE(*(object_ptr)pc[-1])) {
					thread();
					BREAK;
				}
				RTFatalType(pc-1);
				BREAK;

			case L_IS_AN_INTEGER:
			deprintf("case L_IS_AN_INTEGER:");
				top = *(object_ptr)pc[1];
				if (IS_ATOM_INT(top))
					top = ATOM_1;
				else if (IS_ATOM_DBL(top)) {
					/* tpc = pc; */
					top = DoubleToInt(top);
					if (IS_ATOM_INT(top))
						top = ATOM_1;
					else
						top = ATOM_0;
				}
				else {
					top = ATOM_0;
				}
				DeRefx(*(object_ptr)pc[2]);
				*(object_ptr)pc[2] = top;
				inc3pc();
				thread();
				BREAK;

			case L_IS_AN_ATOM:
			deprintf("case L_IS_AN_ATOM:");
				top = *(object_ptr)pc[1];
				if (IS_ATOM(top))
					top = ATOM_1;
				else
					top = ATOM_0;
				if( ((symtab_ptr)pc[1])->mode == M_TEMP ){
					DeRef( ((symtab_ptr)pc[1])->obj );
					((symtab_ptr)pc[1])->obj = NOVALUE;
				}
				DeRefx(*(object_ptr)pc[2]);
				*(object_ptr)pc[2] = top;
				inc3pc();
				thread();
				BREAK;

			case L_IS_A_SEQUENCE:
			deprintf("case L_IS_A_SEQUENCE:");
				top = *(object_ptr)pc[1];
				if (IS_SEQUENCE(top))
					top = ATOM_1;
				else
					top = ATOM_0;
				if( ((symtab_ptr)pc[1])->mode == M_TEMP ){
					DeRef( ((symtab_ptr)pc[1])->obj );
					((symtab_ptr)pc[1])->obj = NOVALUE;
				}
				DeRefx(*(object_ptr)pc[2]);
				*(object_ptr)pc[2] = top;
				inc3pc();
				BREAK;

			case L_IS_AN_OBJECT:
			deprintf("case L_IS_AN_OBJECT:");
				top = *(object_ptr)pc[1];
				if (top != NOVALUE) {
					if (IS_ATOM_INT(top))
						top = 1;
					else if (IS_ATOM_DBL(top)) {
						top = DoubleToInt(top);
						if (IS_ATOM_INT(top))
							top = 1;
						else
							top = 2;
					}
					else if (IS_SEQUENCE(top))
						top = 3;
				}
				else
					top = ATOM_0;

				if( ((symtab_ptr)pc[1])->mode == M_TEMP ){
					DeRef( ((symtab_ptr)pc[1])->obj );
					((symtab_ptr)pc[1])->obj = NOVALUE;
				}
				DeRefx(*(object_ptr)pc[2]);
				*(object_ptr)pc[2] = top;
				inc3pc();
				BREAK;

			case L_PLENGTH:
			deprintf("case L_PLENGTH:");
				/* *pc[1] contains a pointer to the argument */
				top = (object)**(object_ptr **)pc[1];
				goto len;

			case L_LENGTH:
			deprintf("case L_LENGTH:");
				/* *pc[1] is a sequence */
				top = *(object_ptr)pc[1];
			  len:
				if (IS_SEQUENCE(top)) {
					top = SEQ_PTR(top)->length;
				}
				else {
					if( ((symtab_ptr)pc[1])->mode == M_TEMP ){
						DeRef( ((symtab_ptr)pc[1])->obj );
						((symtab_ptr)pc[1])->obj = NOVALUE;
					}
					top = ATOM_1;
				}
				obj_ptr = (object_ptr)pc[2];
				DeRefx(*obj_ptr);
				*obj_ptr = top;
				inc3pc();
				thread();
				BREAK;

				/* ---------- start of unary ops ----------------- */

			case L_SQRT:
			deprintf("case L_SQRT:");
				a = SQRT;
				goto unary;
			case L_SIN:
			deprintf("case L_SIN:");
				a = SIN;
				goto unary;
			case L_COS:
			deprintf("case L_COS:");
				a = COS;
				goto unary;
			case L_TAN:
			deprintf("case L_TAN:");
				a = TAN;
				goto unary;
			case L_ARCTAN:
			deprintf("case L_ARCTAN:");
				a = ARCTAN;
				goto unary;
			case L_LOG:
			deprintf("case L_LOG:");
				a = LOG;
				goto unary;
			case L_NOT_BITS:
			deprintf("case L_NOT_BITS:");
				a = NOT_BITS;
				goto unary;

			case L_FLOOR:
			deprintf("case L_FLOOR:");
				top = *(object_ptr)pc[1];
				if (!IS_ATOM_INT(top)) {
					tpc = pc;
					top = unary_op(FLOOR, top);
				}
				DeRef(*(object_ptr)pc[2]);
				*(object_ptr)pc[2] = top;
				inc3pc();
				thread();
				BREAK;

			unary:
				top = *(object_ptr)pc[1];
				tpc = pc;
				if (IS_ATOM_INT(top))
					top = (*optable[a].intfn)(INT_VAL(top));
				else
					top = unary_op(a, top);
				DeRef(*(object_ptr)pc[2]);
				*(object_ptr)pc[2] = top;
				inc3pc();
				thread();
				BREAK;

			case L_NOT:
			deprintf("case L_NOT:");
				START_UNARY_OP
				if (top == ATOM_0)
					top++;
				else
					top = ATOM_0;
				END_UNARY_OP(NOT)
				thread();
				BREAK;

			case L_NOT_IFW:
			deprintf("case L_NOT_IFW:");
				top = *(object_ptr)pc[1];
				if (IS_ATOM_INT(top)) {
					if (top == ATOM_0) {
						inc3pc();
						thread();
						pc++; /* dummy */
						BREAK;
					}
					else {
						pc = (intptr_t *)pc[2];
						thread();
						BREAK;
					}
				}
				else {
					tpc = pc;
					top = unary_op(NOT, top);
					goto if_check;
				}
				BREAK;

			case L_UMINUS:
			deprintf("case L_UMINUS:");
				START_UNARY_OP
				if (top == MININT) {
					tpc = pc;
					top = (object)NewDouble((eudouble)-MININT);
				}
				else
					top = -top;
				END_UNARY_OP(UMINUS)
				thread();
				BREAK;

			case L_RAND:
			deprintf("case L_RAND:");
				START_UNARY_OP
				tpc = pc;
				if (INT_VAL(top) <= 0) {
					RTFatal("argument to rand() must be >= 1");
				}
				top = MAKE_INT((good_rand() % ((uint32_t)INT_VAL(top))) + 1);
				END_UNARY_OP(RAND)
				thread();
				BREAK;


				/* --------- start of binary ops ----------*/
			case L_PLUS:
			deprintf("case L_PLUS:");
				START_BIN_OP
					/* INT:INT case */
					top = INT_VAL(a) + INT_VAL(top);
					// mwl: gcc 4.1 doesn't do this right unless you do the unsigned casts:
					if ((intptr_t)((uintptr_t)top + (uintptr_t)HIGH_BITS) >= 0) {
						goto dblplus;
					}
				contplus:
					STORE_TOP_I
				}
				else {
					/* non INT:INT cases */
					tpc = pc;
					if (IS_ATOM_INT(a) && IS_ATOM_DBL(top)) {
						v = a;
						temp_d.dbl = (eudouble)INT_VAL(v);
						top = Dadd(&temp_d, DBL_PTR(top));
						goto aresult;
					}
					else if (IS_ATOM_DBL(a)) { // true if a is INT - careful!
						if (IS_ATOM_INT(top)) {
							v = top;
							temp_d.dbl = (eudouble)INT_VAL(v);
							top = Dadd(DBL_PTR(a), &temp_d);
							goto aresult;
						}
						else if (IS_ATOM_DBL(top)) {
							top = Dadd(DBL_PTR(a), DBL_PTR(top));
							goto aresult;
						}
					}
					/* a is a sequence */
					top = binary_op(PLUS, a, top);

				aresult:
					/* store result and DeRef */
					a = *obj_ptr;
					*obj_ptr = top;
					pc += 4;
					if (IS_ATOM_INT_NV(a))
						thread();

					else {
						DeRefDS(a);
					}
				}
				BREAK;

			case L_PLUS_I:
			deprintf("case L_PLUS_I:");
				/* we know that the inputs and the output must be integers */
				START_BIN_OP_I
				top = INT_VAL(a) + INT_VAL(top);
				if ((intptr_t)((uintptr_t)top + (uintptr_t)HIGH_BITS) >= 0) {
					goto dblplus_i;
				}
			contplus_i:
				END_BIN_OP_I
				BREAK;

			case L_MINUS:
			deprintf("case L_MINUS:");
				START_BIN_OP
					/* INT:INT case L_*/
					top = INT_VAL(a) - INT_VAL(top);
					if ((intptr_t)((uintptr_t)top + (uintptr_t)HIGH_BITS) >= 0) {
						tpc = pc;
						v = top;
						top = NewDouble((eudouble)v);
					}
					STORE_TOP_I
				}
				else {
					/* non INT:INT cases */
					tpc = pc;
					if (IS_ATOM_INT(a) && IS_ATOM_DBL(top)) {
						v = a;
						temp_d.dbl = (eudouble)INT_VAL(v);
						top = Dminus(&temp_d, DBL_PTR(top));
						goto aresult;
					}
					else if (IS_ATOM_DBL(a)) {
						if (IS_ATOM_INT(top)) {
							v = top;
							temp_d.dbl = (eudouble)INT_VAL(v);
							top = Dminus(DBL_PTR(a), &temp_d);
							goto aresult;
						}
						else if (IS_ATOM_DBL(top)) {
							top = Dminus(DBL_PTR(a), DBL_PTR(top));
							goto aresult;
						}
					}
					/* a is a sequence */
					top = binary_op(MINUS, a, top);
					goto aresult;
				}
				BREAK;


			case L_MINUS_I:
			deprintf("case L_MINUS_I:");
				START_BIN_OP_I
				top = a - top;
				if ((intptr_t)((uintptr_t)top + (uintptr_t)HIGH_BITS) >= 0) {
					tpc = pc;
					b = top;
					top = NewDouble((eudouble)b);
					*obj_ptr = top;
					inc3pc();
					RTFatalType(pc);
				}
				END_BIN_OP_I
				BREAK;

		   case L_MULTIPLY:
		   deprintf("case L_MULTIPLY:");
				START_BIN_OP
					/* INT:INT case L_*/
					c = a;
					b = top;

#if INT64_MAX == INTPTR_MAX
					{
						int128_t product = (int128_t)c * (int128_t)b;
						if( product == (int128_t)( a = (intptr_t)product ) && IS_ATOM_INT( product ) ){
							top = MAKE_INT( a );
						}
						else{
							tpc = pc;
							top = NewDouble( (eudouble) product );
						}
					}
					
#else
					if (c == (short)c) {
						/* c is 16-bit */
						if ((b <= INT15 && b >= -INT15) ||
							(c == (char)c && b <= INT23 && b >= -INT23) ||
							(b == (short)b && c <= INT15 && c >= -INT15)) {
							top = MAKE_INT(c * b);
						}
						else {
							tpc = pc;
							top = (object)NewDouble(c * (eudouble)b);
						}
					}
					else if (b == (char)b && c <= INT23 && c >= -INT23) {
						/* b is 8-bit, c is 23-bit */
						top = MAKE_INT(c * b);
					}
					else {
						tpc = pc;
						top = (object)NewDouble(c * (eudouble)b);
					}
#endif
					STORE_TOP_I
				}
				else {
					/* non INT:INT cases
					   - what if a is int and top is sequence? */
					tpc = pc;
					if (IS_ATOM_INT(a) && IS_ATOM_DBL(top)) {
						v = a;
						temp_d.dbl = (eudouble)INT_VAL(v);
						top = Dmultiply(&temp_d, DBL_PTR(top));
						goto aresult;
					}
					else if (IS_ATOM(a)) {   // was IS_ATOM_DBL
						if (IS_ATOM_INT(top)) {
							v = top;
							temp_d.dbl = (eudouble)INT_VAL(v);
							top = Dmultiply(DBL_PTR(a), &temp_d);
							goto aresult;
						}
						else if (IS_ATOM_DBL(top)) {
							top = Dmultiply(DBL_PTR(a), DBL_PTR(top));
							goto aresult;
						}
					}
					/* a is a sequence */
					top = binary_op(MULTIPLY, a, top);
					goto aresult;
				}
				BREAK;

			case L_DIVIDE:
			deprintf("case L_DIVIDE:");
				START_BIN_OP
				c = INT_VAL(a);
				tpc = pc;
				if ((b = INT_VAL(top)) == 0)
					RTFatal("attempt to divide by 0");
				if (c % b != 0) /* could try in-line DIV call here for speed */
					top = (object)NewDouble((eudouble)c / b);
				else
					top = MAKE_INT(c / b);
				END_BIN_OP(DIVIDE)
				BREAK;


			case L_REMAINDER:
			deprintf("case L_REMAINDER:");
				START_BIN_OP
				if ((b = INT_VAL(top)) == 0) {
					tpc = pc;
					RTFatal("Can't get remainder of a number divided by 0");
				}
				else {
					top = MAKE_INT(INT_VAL(a) % b); /* a used in divide ok? */
				}
				END_BIN_OP(REMAINDER)
				BREAK;

			case L_AND_BITS:
			deprintf("case L_AND_BITS:");
				START_BIN_OP
				tuint = (uintptr_t)a & (uintptr_t)top;
				top = MAKE_UINT(tuint);
				END_BIN_OP(AND_BITS)
				BREAK;

			case L_OR_BITS:
			deprintf("case L_OR_BITS:");
				START_BIN_OP
				tuint = (uintptr_t)a | (uintptr_t)top;
				top = MAKE_UINT(tuint);
				END_BIN_OP(OR_BITS)
				BREAK;

			case L_XOR_BITS:
			deprintf("case L_XOR_BITS:");
				START_BIN_OP
				tuint = (uintptr_t)a ^ (uintptr_t)top;
				top = MAKE_UINT(tuint);
				END_BIN_OP(XOR_BITS)
				BREAK;

			case L_POWER:
			deprintf("case L_POWER:");
				START_BIN_OP
				tpc = pc;
				top = power(INT_VAL(a), INT_VAL(top));
				END_BIN_OP(POWER)
				BREAK;


			case L_DIV2:
			deprintf("case L_DIV2:");
				top = *(object_ptr)pc[1];
				if (IS_ATOM_INT(top)) {
					b = top;
					if (b & 1) {
						/* odd */
						tpc = pc;
						top = NewDouble( (b >> 1) + POINT5 );
										/*-ves ok */
					}
					else
						top = b >> 1;
				}
				else {
					tpc = pc;
					top = binary_op(DIVIDE, top, ATOM_2);
				}
				DeRefx(*(object_ptr)pc[3]);
				*(object_ptr)pc[3] = top;
				thread4();
				BREAK;

			case L_FLOOR_DIV2:
			deprintf("case L_FLOOR_DIV2:");
				top = *(object_ptr)pc[1];
				if (IS_ATOM_INT(top)) {
					b = top;
					top = b >> 1;
				}
				else {
					tpc = pc;
					a = binary_op(DIVIDE, top, ATOM_2);
					top = unary_op(FLOOR, a);
					DeRef(a);
				}
				DeRefx(*(object_ptr)pc[3]);
				*(object_ptr)pc[3] = top;
				thread4();
				BREAK;

			case L_FLOOR_DIV:
			deprintf("case L_FLOOR_DIV:");
				a = *(object_ptr)pc[1];   // numerator
				top = *(object_ptr)pc[2]; // denominator
				if (IS_ATOM_INT(top) && IS_ATOM_INT(a)) {
					b = top; // get better code elsewhere
					if (top > ATOM_0 && a >= ATOM_0)  {
						/* v = a; doesn't help */
						b = a / b;
					}
					else {
						if (b == 0) {
							tpc = pc;
							RTFatal("attempt to divide by 0");
						}
						v = a;
						temp_dbl = EUFLOOR((eudouble)v / (eudouble)b);
						if (fabs(temp_dbl) <= MAXINT_DBL)
							b = (intptr_t)temp_dbl;
						else
							b = (object)NewDouble(temp_dbl);
					}
				}
				else {
					tpc = pc;
					a = binary_op(DIVIDE, a, top);
					b = unary_op(FLOOR, a);
					DeRef(a);
				}
				DeRef(*(object_ptr)pc[3]);
				*(object_ptr)pc[3] = b;
				pc += 4;
				thread();
				BREAK;

			case L_EQUALS:
			deprintf("case L_EQUALS:");
				START_BIN_OP
				if (a == top)
					top = ATOM_1;
				else
					top = ATOM_0;
				END_BIN_OP(EQUALS)
				BREAK;

			case L_EQUALS_IFW:
			deprintf("case L_EQUALS_IFW:");
				START_BIN_OP
				if (a == top)
				END_BIN_OP_IFW(EQUALS)
				BREAK;

			case L_EQUALS_IFW_I:
			deprintf("case L_EQUALS_IFW_I:");
				START_BIN_OP_I
				if (a == top)
				END_BIN_OP_IFW_I
				BREAK;

			case L_LESS:
			deprintf("case L_LESS:");
				START_BIN_OP
				if (a < top)
					top = ATOM_1;
				else
					top = ATOM_0;
				END_BIN_OP(LESS)
				BREAK;

			case L_LESS_IFW:
			deprintf("case L_LESS_IFW:");
				START_BIN_OP
				if (a < top)
				END_BIN_OP_IFW(LESS)
				BREAK;

			case L_LESS_IFW_I:
			deprintf("case L_LESS_IFW_I:");
				START_BIN_OP_I
				if (a < top)
				END_BIN_OP_IFW_I
				BREAK;

			case L_GREATER:
			deprintf("case L_GREATER:");
				START_BIN_OP
				if (a > top)
					top = ATOM_1;
				else
					top = ATOM_0;
				END_BIN_OP(GREATER)
				BREAK;

			case L_GREATER_IFW:
			deprintf("case L_GREATER_IFW:");
				START_BIN_OP
				if (a > top)
				END_BIN_OP_IFW(GREATER)
				BREAK;

			case L_GREATER_IFW_I:
			deprintf("case L_GREATER_IFW_I:");
				START_BIN_OP_I
				if (a > top)
				END_BIN_OP_IFW_I
				BREAK;

			case L_NOTEQ:
			deprintf("case L_NOTEQ:");
				START_BIN_OP
				if (a != top)
					top = ATOM_1;
				else
					top = ATOM_0;
				END_BIN_OP(NOTEQ)
				BREAK;

			case L_NOTEQ_IFW:
			deprintf("case L_NOTEQ_IFW:");
				START_BIN_OP
				if (a != top)
				END_BIN_OP_IFW(NOTEQ)
				BREAK;

			case L_NOTEQ_IFW_I:
			deprintf("case L_NOTEQ_IFW_I:");
				START_BIN_OP_I
				if (a != top)
				END_BIN_OP_IFW_I
				BREAK;

			case L_LESSEQ:
			deprintf("case L_LESSEQ:");
				START_BIN_OP
				if (a <= top)
					top = ATOM_1;
				else
					top = ATOM_0;
				END_BIN_OP(LESSEQ)
				BREAK;

			case L_LESSEQ_IFW:
			deprintf("case L_LESSEQ_IFW:");
				START_BIN_OP
				if (a <= top)
				END_BIN_OP_IFW(LESSEQ)
				BREAK;

			case L_LESSEQ_IFW_I:
			deprintf("case L_LESSEQ_IFW_I:");
				START_BIN_OP_I
				if (a <= top)
				END_BIN_OP_IFW_I
				BREAK;

			case L_GREATEREQ:
			deprintf("case L_GREATEREQ:");
				START_BIN_OP
				if (a >= top)
					top = ATOM_1;
				else
					top = ATOM_0;
				END_BIN_OP(GREATEREQ)
				BREAK;

			case L_GREATEREQ_IFW:
			deprintf("case L_GREATEREQ_IFW:");
				START_BIN_OP
				if (a >= top)
				END_BIN_OP_IFW(GREATEREQ)
				BREAK;

			case L_GREATEREQ_IFW_I:
			deprintf("case L_GREATEREQ_IFW_I:");
				START_BIN_OP_I
				if (a >= top)
				END_BIN_OP_IFW_I
				BREAK;

			case L_AND:
			deprintf("case L_AND:");
				START_BIN_OP
				if (a != ATOM_0 && top != ATOM_0)
					top = ATOM_1;
				else
					top = ATOM_0;
				END_BIN_OP(AND)
				BREAK;

			case L_SC1_AND:
			deprintf("case L_SC1_AND:");
				top = *(object_ptr)pc[1];
				if (IS_ATOM_INT(top)) {
					if (top == ATOM_0) {
						DeRefx(*(object_ptr)pc[2]);
						*(object_ptr)pc[2] = ATOM_0;
						pc = (intptr_t *)pc[3];
						thread();
						BREAK;
					}
				}
				else if (IS_ATOM_DBL(top)) {
					if (DBL_PTR(top)->dbl == 0.0) {
						DeRefx(*(object_ptr)pc[2]);
						*(object_ptr)pc[2] = ATOM_0;
						pc = (intptr_t *)pc[3];
						thread();
						BREAK;
					}
				}
				else {
					tpc = pc;
					atom_condition();
				}
				thread4();
				BREAK;

			case L_SC1_AND_IF:  // no need to store ATOM_0
			deprintf("case L_SC1_AND_IF:");
				top = *(object_ptr)pc[1];
				if (IS_ATOM_INT(top)) {
					if (top == ATOM_0) {
						pc = (intptr_t *)pc[3];
						thread();
						BREAK;
					}
				}
				else if (IS_ATOM_DBL(top)) {
					if (DBL_PTR(top)->dbl == 0.0) {
						pc = (intptr_t *)pc[3];
						thread();
						BREAK;
					}
				}
				else {
					tpc = pc;
					atom_condition();
				}
				thread4();
				BREAK;

			case L_SC2_OR:
			deprintf("case L_SC2_OR:");
			case L_SC2_AND:
			deprintf("case L_SC2_AND:");
				top = *(object_ptr)pc[1];
				DeRefx(*(object_ptr)pc[2]);
				if (IS_ATOM_INT(top)) {
					if (top == ATOM_0)
						*(object_ptr)pc[2] = ATOM_0;
					else
						*(object_ptr)pc[2] = ATOM_1;
				}
				else if (IS_ATOM_DBL(top)) {
					if (DBL_PTR(top)->dbl == 0.0)
						*(object_ptr)pc[2] = ATOM_0;
					else
						*(object_ptr)pc[2] = ATOM_1;
				}
				else {
					tpc = pc;
					atom_condition();
				}
				inc3pc();
				thread();
				BREAK;

			case L_XOR:
			deprintf("case L_XOR:");
				START_BIN_OP
				if ((a != ATOM_0) != (top != ATOM_0))
					top = ATOM_1;
				else
					top = ATOM_0;
				END_BIN_OP(XOR)
				BREAK;

			case L_OR:
			deprintf("case L_OR:");
				START_BIN_OP
				if (a != ATOM_0 || top != ATOM_0)
					top = ATOM_1;
				else
					top = ATOM_0;
				END_BIN_OP(OR)
				BREAK;

			case L_SC1_OR:
			deprintf("case L_SC1_OR:");
				top = *(object_ptr)pc[1];
				if (IS_ATOM_INT(top)) {
					if (top != ATOM_0) {
						DeRefx(*(object_ptr)pc[2]);
						*(object_ptr)pc[2] = ATOM_1;
						pc = (intptr_t *)pc[3];
						thread();
						BREAK;
					}
				}
				else if (IS_ATOM_DBL(top)) {
					if (DBL_PTR(top)->dbl != 0.0) {
						DeRefx(*(object_ptr)pc[2]);
						*(object_ptr)pc[2] = ATOM_1;
						pc = (intptr_t *)pc[3];
						thread();
						BREAK;
					}
				}
				else {
					tpc = pc;
					atom_condition();
				}
				thread4();
				BREAK;

			case L_SC1_OR_IF: // no need to store ATOM_1
			deprintf("case L_SC1_OR_IF:");
				top = *(object_ptr)pc[1];
				if (IS_ATOM_INT(top)) {
					if (top != ATOM_0) {
						pc = (intptr_t *)pc[3];
						thread();
						BREAK;
					}
				}
				else if (IS_ATOM_DBL(top)) {
					if (DBL_PTR(top)->dbl != 0.0) {
						pc = (intptr_t *)pc[3];
						thread();
						BREAK;
					}
				}
				else {
					tpc = pc;
					atom_condition();
				}
				thread4();
				BREAK;


/* end of binary ops */


			/* Note: we *must* always patch the endfor op, because it might
			   actually be wrong as determined by the front-end */
			case L_FOR:
			deprintf("case L_FOR:");
				obj_ptr = (object_ptr)pc[5]; /* loop var */
				top = *obj_ptr;
				c = *(object_ptr)pc[3]; /* initial value */
				*obj_ptr = c;
				Ref(c);
				DeRefx(top);
				top = *(object_ptr)pc[1];    /* inc */
				a = *(object_ptr)pc[2];      /* limit */
				if (IS_ATOM_INT(top) &&
					IS_ATOM_INT(c) &&
					IS_ATOM_INT(a))
					goto intloop;
				else
					goto general;

			case L_FOR_I:
			deprintf("case L_FOR_I:");
				/* integer loop */
				obj_ptr = (object_ptr)pc[5]; /* loop var */
				c = *(object_ptr)pc[3]; /* initial value */
				*obj_ptr = c;
				top = *(object_ptr)pc[1];    /* inc */
				a = *(object_ptr)pc[2];      /* limit */
			  intloop:
				if ((intptr_t)((uintptr_t)a + (uintptr_t)top + (uintptr_t)HIGH_BITS) < 0) {
					/* purely integer loop */
					if ((top >= 0)) {
						/* going up */
						if (c > a) {
							pc = (intptr_t *)pc[6];
							thread();
							BREAK;
						}
						if (top == ATOM_1) {
							i = ENDFOR_INT_UP1;
						}
						else {
							i = ENDFOR_INT_UP;
						}
					}
					else {
						/* going down */
						if (c < a) {
							pc = (intptr_t *)pc[6];
							thread();
							BREAK;
						}
						if (top == ATOM_M1) {
							i = ENDFOR_INT_DOWN1;
						}
						else {
							i = ENDFOR_INT_DOWN;
						}
					}
				}
				else {
				  general:
					/* general loop */
					tpc = pc;
					if (!IS_ATOM(c))
						RTFatal("for-loop variable is not an atom");
					if (!IS_ATOM(a))
						RTFatal("for-loop limit is not an atom");
					if (IS_ATOM_INT(top))
						going_up = (INT_VAL(top) >= 0);
					else if (IS_ATOM_DBL(top))
						going_up = (DBL_PTR(top)->dbl >= 0.0);
					else
						RTFatal("for-loop increment is not an atom");
					if (going_up)
						b = binary_op_a(GREATER, c, a);
					else
						b = binary_op_a(LESS, c, a);
					if (b == ATOM_1) {
						pc = (intptr_t *)pc[6];  /* exit loop - 0 iterations */
						BREAK;
					}
					else {
						i = going_up ? ENDFOR_UP : ENDFOR_DOWN;
						/* Ref(top); inc */
						/* Ref(a);   limit */
					}
				}
				/* we're going in - patch the ENDFOR opcode */
				patch = (opcode_type *) ((intptr_t *)pc[6] - 5);
				i = (intptr_t)opcode(i);
				pc += 7;   // so WATCOM will do it before thread()
				if (patch[0] != (opcode_type)i) {
					// changing the endfor op from what it was
					sub = (symtab_ptr)pc[-3];
					if (sub->u.subp.saved_privates == NULL) {
						/* no one else in here, safe to change the op */
						patch[0] = (opcode_type)i;
					}
					else {
						// don't upset other tasks or levels of recursion
						patch[0] = opcode(ENDFOR_GENERAL);
					}
				}
				thread();
				BREAK;


			case L_ENDFOR_INT_DOWN1:
			deprintf("case L_ENDFOR_INT_DOWN1:");
				obj_ptr = (object_ptr)pc[3]; /* loop var */
				top = *obj_ptr - 1;
				if (top < *(object_ptr)pc[2]) {  /* limit */
					thread5();  /* exit loop */
				}
				else {
					*obj_ptr = top;
					pc = (intptr_t *)pc[1];  /* loop again */
					thread();
				}
				BREAK;

			case L_ENDFOR_INT_DOWN:
			deprintf("case L_ENDFOR_INT_DOWN:");
				obj_ptr = (object_ptr)pc[3];  /* loop var */
				top = *obj_ptr + *(object_ptr)pc[4]; /* increment */
				if (top < *(object_ptr)pc[2]) { /* limit */
					thread5();  /* exit loop */
				}
				else {
					*obj_ptr = top;
					pc = (intptr_t *)pc[1]; /* loop again */
					thread();
				}
				BREAK;

			case L_ENDFOR_GENERAL:
			deprintf("case L_ENDFOR_GENERAL:");
				/* totally general ENDFOR */
				top = *(object_ptr)pc[4]; /* increment */
				if (IS_ATOM_INT(top)) {
					if (top < ATOM_0)
						goto downloop;
				}
				else {
					/* increment must be an atom (not a sequence) */
					 if (DBL_PTR(top)->dbl < 0.0) {
						goto downloop;
					 }
				}
				/* fall-through */
			case L_ENDFOR_UP:
			deprintf("case L_ENDFOR_UP:");
				/* add increment */
				obj_ptr = (object_ptr)pc[3]; /* loop var */
				a = *obj_ptr;
				tpc = pc;
				top = binary_op_a(PLUS, a, *(object_ptr)pc[4]); /* increment */
				/* compare with limit */
				if (binary_op_a(GREATER, top, *(object_ptr)pc[2]) == ATOM_1) {
					DeRef(top);
					thread5();
				}
				else {
					DeRef(*obj_ptr);
					*obj_ptr = top;
					pc = (intptr_t *)pc[1]; /* loop again */
					thread();
				}
				BREAK;

			case L_ENDFOR_DOWN:
			deprintf("case L_ENDFOR_DOWN:");
			  downloop:
				obj_ptr = (object_ptr)pc[3]; /* loop var */
				a = *obj_ptr;
				tpc = pc;
				top = binary_op_a(PLUS, a, *(object_ptr)pc[4]); /* increment */
				if (binary_op_a(LESS, top, *(object_ptr)pc[2]) == ATOM_1) {
					DeRef(top);
					thread5();  /* exit loop */
				}
				else {
					DeRef(*obj_ptr);
					*obj_ptr = top;
					pc = (intptr_t *)pc[1]; /* loop again */
					thread();
				}
				BREAK;


			// Call by handle to procedure, function or type
			case L_CALL_FUNC:
			deprintf("case L_CALL_FUNC:");
				cf = TRUE;
			case L_CALL_PROC:
			deprintf("case L_CALL_PROC:");
				tpc = pc;
				if (expr_top >= expr_limit) {
					expr_max = BiggerStack();
					expr_limit = expr_max - 3;
				}

				// get the routine symtab_ptr:
				a = get_pos_int("call_proc/call_func", *(object_ptr)pc[1]);
				if (a < 0 || a >= e_routine_next) {
					RTFatal("invalid routine id");
				}
				sub = e_routine[a];

				// get the argument sequence
				a = *(object_ptr)pc[2];

				// check for correct kind of routine
				if (cf) {
					cf = FALSE;
					pc++;
					if (sub->token == PROC) {
						RTFatal("%s() does not return a value", sub->name);
					}
				}
				else {
					if (sub->token != PROC) {
						RTFatal("the value returned by %s() must be assigned or used",
								sub->name);
					}
				}

				if (IS_ATOM(a)) {
					RTFatal("argument list must be a sequence");
				}
				a = (object)SEQ_PTR(a);

				// if length is huge it will be rejected here,
				// so max_stack_per_call will protect against stack overflow
				if (sub->u.subp.num_args != (uintptr_t)((s1_ptr)a)->length) {
					// must avoid > 3 arg calls to get better WATCOM code gen
					wrong_arg_count(sub, a);
				}
				obj_ptr = ((s1_ptr)a)->base;
				sym = sub->next;

				if (sub->u.subp.resident_task != -1) {
					/* someone is using the sub - save the privates and temps */
					block = save_private_block(sub);

					/* save & copy the args */
					while (TRUE) {
						obj_ptr++;
						a = *(object_ptr)obj_ptr;
						if (!IS_ATOM_INT(a)) {
							if (a == NOVALUE) { // sentinel
								obj_ptr = (object_ptr)(pc + 3);
								break;
							}
							RefDS(a);
						}
						*block++ = sym->obj;
						sym->obj = a;
						sym = sym->next;
					}

					/* save the remaining privates and loop-vars &
					   set to NOVALUE */
					while (sym && sym->scope <= S_PRIVATE ) {
						*block++ = sym->obj;
						sym->obj = NOVALUE;
						sym = sym->next;
					}

					/* save the temps & set to NOVALUE */
					sym = sub->u.subp.temps;
					while (sym != NULL) {
						*block++ = sym->obj;
						sym->obj = NOVALUE;
						sym = sym->next;
					}
				}
				else {
					/* don't push */
					/* save & copy the args */
					while (TRUE) {
						obj_ptr++;
						a = *(object_ptr)obj_ptr;
						if (!IS_ATOM_INT(a)) {
							if (a == NOVALUE) { // sentinel
								obj_ptr = (object_ptr)(pc + 3);
								break;
							}
							RefDS(a);
						}
						sym->obj = a;
						sym = sym->next;
					}
					/* the remaining privates and loop-vars will already
					   contain NOVALUE from the previous first-level return */
				}

				sub->u.subp.resident_task = current_task;

				*expr_top++ = (object)obj_ptr; // push return address
				*expr_top++ = (object)sub;             // push sub symtab pointer
				pc = sub->u.subp.code;         // start executing the sub
				thread();
				BREAK;

			case L_PROC:  // Normal subroutine call
			deprintf("case L_PROC:");
				/* make a procedure or function/type call */
				if (expr_top >= expr_limit) {
					tpc = pc;
					expr_max = BiggerStack();
					expr_limit = expr_max - 3;
				}
				sub = (symtab_ptr)pc[1]; // subroutine
				sym = sub->next;

				// pc (ESI) is used for role of obj_ptr here and in loop
				obj_ptr = (object_ptr)(pc + 2); // list of argument addresses

				a = (object)(obj_ptr + sub->u.subp.num_args);

				if (sub->u.subp.resident_task != -1) {
					/* someone is using the sub - save the privates and temps */

					tpc = pc;
					block = save_private_block(sub);

					/* save & copy the args */
					while ( obj_ptr < (object_ptr)a) {
						*block++ = sym->obj;
						sym->obj = *(object_ptr)obj_ptr[0];
						Ref(sym->obj);
						sym = sym->next;
						obj_ptr++;
					}

					/* save the remaining privates and loop-vars &
					   set to NOVALUE */
					while (sym && sym->scope <= S_PRIVATE) {
						*block++ = sym->obj;
						sym->obj = NOVALUE;
						sym = sym->next;
					}

					/* save the temps & set to NOVALUE */
					sym = sub->u.subp.temps;
					while (sym != NULL) {
						*block++ = sym->obj;
						sym->obj = NOVALUE;
						sym = sym->next;
					}
				}
				else {
					/* no need to save the privates or temps */

					/* just copy the args */
					while (obj_ptr < (object_ptr)a) {
						sym->obj = *(object_ptr)obj_ptr[0];
						Ref(sym->obj);
						sym = sym->next;
						obj_ptr++;
					}

					/* the remaining privates and loop-vars will already
					   contain NOVALUE from the previous level-1 return */
				}

				sub->u.subp.resident_task = current_task;

				if (sub->token != PROC)
					obj_ptr++; /* skip address for fn/type result */

				*expr_top++ = (object)obj_ptr; // push return address
				*expr_top++ = (object)sub;             // push sub symtab pointer
				pc = sub->u.subp.code;         // start executing the sub
				thread();
				BREAK;

			case L_PROC_TAIL:   // tail recursion
				sub = ((symtab_ptr)pc[1]);
				sym = sub->next; /* first private var */

				// pc (ESI) is used for role of obj_ptr here and in loop
				obj_ptr = (object_ptr)(pc + 2); // list of argument addresses

				a = (object)(obj_ptr + sub->u.subp.num_args);
				/* just copy the args */
				while (obj_ptr < (object_ptr)a) {
					b = sym->obj;
					sym->obj = *(object_ptr)obj_ptr[0];
					Ref(sym->obj);
					DeRef( b );
					sym = sym->next;
					obj_ptr++;
				}

				/* release the privates and set to NOVALUE */
				while (sym && sym->scope <= S_PRIVATE) {
					DeRef(sym->obj);
					sym->obj = NOVALUE; // not actually needed for params
					sym = sym->next;
				}

				/* release the temps and set to NOVALUE */
				sym = sub->u.subp.temps;
				while (sym != NULL) {
					DeRef(sym->obj);
					sym->obj = NOVALUE;
					sym = sym->next;
				}

				pc = sub->u.subp.code;         // start executing the sub
				thread();
				BREAK;

			case L_CALL_BACK_RETURN: /* return from a call-back */
			deprintf("case L_CALL_BACK_RETURN:");
				return;

			case L_RETURNT: /* end of execution - falling off the end */
			deprintf("case L_RETURNT:");
				tpc = pc;  /* we need this to be different from CALL_BACK_RETURN */
				Cleanup(0);
				return;

			case L_BADRETURNF:  /* shouldn't reach here */
			deprintf("case L_BADRETURNF:");
				tpc = pc;
				RTFatal("attempt to exit a function without returning a value");
				BREAK;

			case L_RETURNF: /* return from function */
			deprintf("case L_RETURNF:");
				result_val = *(object_ptr)pc[3]; /* the return value */
				Ref(result_val);

				// record the place to put the return value
				result_ptr = (object_ptr)*((intptr_t *)expr_top[-2] - 1);
				goto return_p;

			case L_RETURNP: /* return from procedure */
			deprintf("case L_RETURNP:");

				result_ptr = 0;

			return_p:
				sub = ((symtab_ptr)pc[1]);
				/* release the privates and set to NOVALUE */
				sym = (symtab_ptr)pc[2];
				while(1){
					obj_ptr = (object_ptr)sym;
					while( (obj_ptr = (object_ptr)((symtab_ptr)obj_ptr)->next_in_block) ){
						DeRef( *obj_ptr);
						*obj_ptr = NOVALUE;
					}
					if( sym == sub->u.subp.block ) break;
					sym = sym->u.subp.block;
				}

				// vacating this routine
				sub->u.subp.resident_task = -1;

				tpc = pc;

				if (expr_top > expr_stack+3) {
					// stack is not empty
					pc = (intptr_t *)expr_top[-2];
					expr_top -= 2;
					top = expr_top[-1];
					restore_privates((symtab_ptr)top);

					if (result_ptr != NULL) {
						// store function result
						top = *result_ptr;
						*result_ptr = result_val; //was important not to use "a"
						DeRef(top);
						if( ((symtab_ptr)tpc[3])->mode == M_TEMP ){
							DeRef( result_val );

							// Watch for recursion:
							if( tpc[3] != (intptr_t)result_ptr )
								((symtab_ptr)tpc[3])->obj = NOVALUE;
						}
						result_ptr = NULL;
					}
				}
				else {
					// stack is empty - this task is finished
					terminate_task(current_task);
					scheduler(current_time());
					pc = tpc;
				}

				thread();
				BREAK;

			case L_EXIT_BLOCK:
			deprintf("case L_EXIT_BLOCK:");
				sym = ((symtab_ptr)pc[1]);
				result_ptr = 0;
				pc += 2;
				while( (sym = sym->next_in_block) ){
					DeRef(sym->obj);
					sym->obj = NOVALUE;

				}
				thread();

			case L_ROUTINE_ID:
			deprintf("case L_ROUTINE_ID:");
				top = (object)pc[1];    // CurrentSub
				a = *(object_ptr)pc[3]; // routine name sequence
				SymTabLen = pc[2]; // avoid > 3 args
				b = RoutineId((symtab_ptr)top, a, pc[4]);
				DeRefx(*(object_ptr)pc[5]);
				*(object_ptr)pc[5] = b;
				pc += 6;
				/*thread();*/
				BREAK;

			case L_DELETE_ROUTINE:
			deprintf("case L_DELETE_ROUTINE:");
				a = *(object_ptr)pc[1]; // the object

				// get the routine symtab_ptr:
				b = get_pos_int("call_proc/call_func", *(object_ptr)pc[2]);
				if (b >= e_routine_next) {
					RTFatal("invalid routine id");
				}
				obj_ptr = (object_ptr) DeleteRoutine( b );

				// Only ref if source and target are different, and the source
				// isn't a temp.  If copied below, then don't ref, either.
				b = (pc[1] != pc[3]) && (((symtab_ptr)pc[1])->mode != M_TEMP);
				if( IS_ATOM_INT(a) ){
					a = NewDouble( (eudouble)a );
					DBL_PTR(a)->cleanup = (cleanup_ptr) obj_ptr;
					b = 0;
				}
				else if( IS_ATOM_DBL(a) ){
					if( (!UNIQUE(DBL_PTR(a)) && !DBL_PTR(a)->cleanup) ||
					(((symtab_ptr)pc[1])->mode == M_CONSTANT && ((symtab_ptr)pc[1])->name == 0) ){
						a = NewDouble( DBL_PTR(a)->dbl );
						b = 0;
					}
					else{
						c = (object) DBL_PTR( a )->cleanup;
						if( c != 0 ){
							obj_ptr = (object_ptr) ChainDeleteRoutine( (cleanup_ptr)obj_ptr, (cleanup_ptr)c );
						}
					}
					DBL_PTR(a)->cleanup = (cleanup_ptr) obj_ptr;
				}
				else{ // sequence
					if( (!UNIQUE(SEQ_PTR(a)) && !SEQ_PTR(a)->cleanup) ||
					(((symtab_ptr)pc[1])->mode == M_CONSTANT && ((symtab_ptr)pc[1])->name == 0) ){
						a = MAKE_SEQ( SequenceCopy( SEQ_PTR(a) ) );
						b = 0;
					}
					else{
						c = (object) SEQ_PTR( a )->cleanup;
						if( c != 0 ){
							obj_ptr = (object_ptr) ChainDeleteRoutine( (cleanup_ptr)obj_ptr, (cleanup_ptr)c );
						}
					}
					SEQ_PTR(a)->cleanup = (cleanup_ptr)obj_ptr;
				}
				obj_ptr = (object_ptr)pc[3];
				if( a != *obj_ptr ){
					DeRef( *obj_ptr );
					*obj_ptr = a;
				}

				if( b != 0 ){
					RefDS( a );
				}
				else if( ((symtab_ptr)pc[1])->mode == M_TEMP ){
					*(object_ptr)pc[1] = NOVALUE;
				}
				thread4();
				BREAK;

			case L_DELETE_OBJECT:
				a = *(object_ptr)pc[1];
				if( !IS_ATOM_INT(a) ){
					if( IS_ATOM_DBL(a) ){
						cleanup_double( DBL_PTR(a) );
					}
					else if( IS_SEQUENCE(a) ){
						cleanup_sequence( (s1_ptr)DBL_PTR(a) );
					}
				}
				pc += 2;
				thread();
				BREAK;

			case L_REF_TEMP:
				deprintf("case L_REF_TEMP:");
				Ref( ((symtab_ptr)pc[1])->obj );
				pc += 2;
				thread();
				BREAK;

			case L_DEREF_TEMP:
				deprintf("case L_DEREF_TEMP:");
				DeRef( ((symtab_ptr)pc[1])->obj );

			case L_NOVALUE_TEMP:
				deprintf("case L_NOVALUE_TEMP:");
				((symtab_ptr)pc[1])->obj = NOVALUE;
				pc += 2;
				thread();
				BREAK;

			case L_APPEND:
			deprintf("case L_APPEND:");
				b = *(object_ptr)pc[1];
				top = *(object_ptr)pc[2];
				if (!IS_SEQUENCE(b)) {
					tpc = pc;
					RTFatal("first argument of append must be a sequence");
				}
	  app_copy:
				tpc = pc;
				Ref(top);
				Append((object_ptr)pc[3], b, top);
				thread4();
				BREAK;

			case L_PREPEND:
			deprintf("case L_PREPEND:");
				b = *(object_ptr)pc[1];
				top = *(object_ptr)pc[2];
				if (!IS_SEQUENCE(b)) {
					tpc = pc;
					RTFatal("first argument of prepend must be a sequence");
				}
	 prep_copy:
				tpc = pc;
				Ref(top);
				Prepend((object_ptr)pc[3], b, top);
				thread4();
				BREAK;

			case L_REMOVE:
			deprintf("case L_REMOVE:");
				tpc = pc;
				// type check and normalise arguments
				a = *(object_ptr)pc[1];  // source
				if (!IS_SEQUENCE(a))
					RTFatal("First argument to remove() must be a sequence");
				s1 = SEQ_PTR(a);
				seqlen = s1->length;
				b = *(object_ptr)pc[2];  //start
				if (IS_SEQUENCE(b))
					RTFatal("Second argument to remove() must be an atom");
				nvars = (IS_ATOM_INT(b)) ? b : (intptr_t)(DBL_PTR(b)->dbl);
				top = *(object_ptr)pc[3]; //stop
				if (IS_SEQUENCE(top))
					RTFatal("Third argument to remove() must be an atom");
				end_pos = (IS_ATOM_INT(top)) ? top : (intptr_t)(DBL_PTR(top)->dbl);
				if (end_pos > seqlen)
					end_pos=seqlen;
				obj_ptr = (object_ptr)pc[4];
				top = *obj_ptr;
				// no removal
				if (nvars > seqlen || nvars > end_pos || end_pos<0) {  // return target
					*obj_ptr = a;
					Ref(*obj_ptr);
					DeRef(top);
					thread5();
					BREAK;
				}
				// remove all or start
				if (nvars < 2 ) {
					if (end_pos >= seqlen) {   // return ""
						*obj_ptr = MAKE_SEQ(NewS1(0));
						DeRef(top);
					}
				   	else
						Tail(s1,end_pos+1,obj_ptr); //end_pos = 1st element kept
				   	thread5();
				   	BREAK;
				}
				if (end_pos >= seqlen) //remove tail
					Head(s1,nvars,obj_ptr);   //nvars=1+final length
				else { // carve slice out
					assign_slice_seq = &s1;
					if( (a == *obj_ptr) && (SEQ_PTR(a)->ref == 1) ){
						Remove_elements( nvars, end_pos, 1);
					}
					else{
						*obj_ptr = Remove_elements( nvars, end_pos, 0 );
					}
				}
				thread5();
				BREAK;

			case L_REPLACE:
			deprintf("case L_REPLACE:");
				// type check arguments
				tpc = pc;

				if (!IS_SEQUENCE(*(object_ptr)pc[1])) // source
					RTFatal("First argument to replace() must be a sequence");

				if (IS_SEQUENCE(*(object_ptr)pc[3])) // start
					RTFatal("Third argument to replace() must be an atom");

				if (IS_SEQUENCE(*(object_ptr)pc[4])) // stop
					RTFatal("Fourth argument to replace() must be an atom");

				Replace( (replace_ptr)(pc+1) );

				pc += 6;
				thread();
				BREAK;

			case L_HEAD:
			deprintf("case L_HEAD:");
				// type check and normalise arguments
				tpc = pc;
				a = *(object_ptr)pc[1];  // source
				if (!IS_SEQUENCE(a))
					RTFatal("First argument to head() must be a sequence");
				s1 = SEQ_PTR(a);
				seqlen = s1->length;
				b = *(object_ptr)pc[2];   // start
				if (IS_SEQUENCE(b))
					RTFatal("Second argument to head() must be an atom");
				nvars = (IS_ATOM_INT(b)) ? b : (intptr_t)(DBL_PTR(b)->dbl);
				if (nvars < 0)
					RTFatal("Second argument to head() must not be negative");
				obj_ptr = (object_ptr)pc[3];

				// get first elements
				if (nvars == 0) {
					// Nothing to get so return an empty sequence.
					*obj_ptr = MAKE_SEQ(NewS1(0));
				}
				else if (nvars >= seqlen) {
					// Caller wants it all. So pass another reference to source.
					Ref(a);
					*obj_ptr = a;
				}
				else
					Head(s1, nvars+1, obj_ptr);
				thread4();
				BREAK;

			case L_TAIL:
			deprintf("case L_TAIL:");
				// type check and normalise arguments
				tpc = pc;

				a = *(object_ptr)pc[1];  // source
				if (!IS_SEQUENCE(a))
					RTFatal("First argument to tail() must be a sequence");
				s1 = SEQ_PTR(a);
				seqlen = s1->length;

				b = *(object_ptr)pc[2];  // length
				if (IS_SEQUENCE(b))
					RTFatal("Second argument to tail() must be an atom");
				nvars = (!IS_ATOM_INT(b)) ? (intptr_t)(DBL_PTR(b)->dbl) : b;
				if (nvars < 0)
					RTFatal("Second argument to tail() must not be negative");

				obj_ptr = (object_ptr)pc[3]; // target
				// get last elements
				if (nvars == 0) {
					DeRef(*obj_ptr);
					*obj_ptr = MAKE_SEQ(NewS1(0));
				}
				else if (nvars >= seqlen) {
					DeRef(*obj_ptr);
					Ref(a);
					*obj_ptr = a;
				}
				else
					Tail(s1, seqlen - nvars + 1, obj_ptr);
				thread4();
				BREAK;

			case L_CONCAT:
			deprintf("case L_CONCAT:");
				/* concatenate 2 items */
				b = *(object_ptr)pc[1];
				top = *(object_ptr)pc[2];
				if (IS_SEQUENCE(b) && IS_ATOM(top))
					goto app_copy; /* append is faster */
				else if (IS_ATOM(b) && IS_SEQUENCE(top)) {
					/* swap args */
					a = top;
					top = b;
					b = a;
					goto prep_copy; /* prepend is faster */
				}
				tpc = pc;
				Concat((object_ptr)pc[3], b, top);
				pc += 4;  // WATCOM thread() fails
				BREAK;

			case L_SPLICE:
			deprintf("case L_SPLICE:");
				splins = !IS_ATOM( *(object_ptr) pc[2] );
				goto spin;
			case L_INSERT:
			deprintf("case L_INSERT:");
				splins = 0;
			spin:
				tpc = pc;
				if (!IS_SEQUENCE(*(object_ptr)pc[1]))
					RTFatal("First argument to splice/insert() must be a sequence");
				a = *(object_ptr)pc[1]; // the source
				i = SEQ_PTR(a)->length;

				obj_ptr = (object_ptr)pc[3];
				if (IS_SEQUENCE(*obj_ptr))
					RTFatal("Third argument to splice/insert() must be an atom");
				nvars = (IS_ATOM_INT(*obj_ptr)) ?
					*obj_ptr : (intptr_t)DBL_PTR(*obj_ptr)->dbl;  //insertion point

				b = *(object_ptr)pc[2]; //the stuff to insert
				Ref(b);

				obj_ptr = (object_ptr)pc[4]; //-> the target

				// now the variable part
				if (nvars <= 0) {
					if (splins) Concat(obj_ptr,b,a);
					else Prepend(obj_ptr,a,b);
				}
				else if (nvars > i) {
					if (splins) Concat(obj_ptr,a,b);
					else Append(obj_ptr,a,b);
				}
				else if (IS_SEQUENCE(b) && splins) {
				// splice is now just a sequence assign
					s2 = SEQ_PTR(b);
					if( (*obj_ptr != a) || ( SEQ_PTR( a )->ref != 1 ) ){
						// not in place: need to deref the target and ref the orig seq
						if( *obj_ptr != NOVALUE ) DeRef(*obj_ptr);

						// ensures that Add_internal_space will make a copy
						RefDS( a );
					}
					s1 = (s1_ptr)Add_internal_space( a, nvars, s2->length );
					assign_slice_seq = &s1;

					s1 = Copy_elements( nvars, s2, (*obj_ptr == a) );
					*obj_ptr = MAKE_SEQ(s1);
			}
				else { // inserting is just adding an extra element and assigning it
					if( (*obj_ptr == a) && ( SEQ_PTR( a )->ref == 1 ) ){
						// in place
						*obj_ptr = Insert( a, b, nvars );
					}
					else{
						if( *obj_ptr != NOVALUE ) DeRef(*(obj_ptr));
						RefDS( a );
						*obj_ptr = Insert(a,b,nvars);
					}
				}
				thread5();
				BREAK;

			case L_CONCAT_N:
			deprintf("case L_CONCAT_N:");
				/* concatenate 3 or more items */
				nvars = pc[1];
				tpc = pc;
				Concat_Ni((object_ptr)pc[nvars+2], (object_ptr *)(pc+2), nvars);
				pc += nvars + 3; // WATCOM thread() fails
				BREAK;

			case L_REPEAT:
			deprintf("case L_REPEAT:");
				tpc = pc;
				top = Repeat(*(object_ptr)pc[1], *(object_ptr)pc[2]);
				DeRef(*(object_ptr)pc[3]);
				*(object_ptr)pc[3] = top;
				pc += 4;
				thread();
				BREAK;

			case L_DATE:
			deprintf("case L_DATE:");
				tpc = pc;
				top = Date();
				DeRef(*(object_ptr)pc[1]);
				*(object_ptr)pc[1] = top;
				pc += 2;
				BREAK;

			case L_TIME:
			deprintf("case L_TIME:");
				tpc = pc;
				top = NewDouble(current_time());
				DeRef(*(object_ptr)pc[1]);
				*(object_ptr)pc[1] = top;
				pc += 2;
				thread();
				BREAK;


#ifdef HEAP_CHECK
			case L_SPACE_USED:
			deprintf("case L_SPACE_USED:");
				top = MAKE_INT(bytes_allocated);
				DeRef(*(object_ptr)pc[1]);
				*(object_ptr)pc[1] = top;
				pc += 2;
				BREAK;
#endif
			case L_POSITION:
			deprintf("case L_POSITION:");
				a = *(object_ptr)pc[1];
				top = *(object_ptr)pc[2];
				tpc = pc;
				if (!IS_ATOM(top)) {
					RTFatal("second argument of position() is not an atom");
				}
				if (IS_ATOM(a)) {
					Position(a, top);
					inc3pc();
					thread();
				}
				else {
					RTFatal("first argument of position() is not an atom");
				}
				BREAK;

			case L_EQUAL:
			deprintf("case L_EQUAL:");
				a = *(object_ptr)pc[1];
				top = *(object_ptr)pc[2];
				if (a == top) {
					top = ATOM_1; // lucky case
				}
				else if (IS_ATOM_INT(a) && IS_ATOM_INT(top)) {
					top = ATOM_0;
				}
				else {
					tpc = pc;
					top = MAKE_INT(compare(a, top));
					top = (top == ATOM_0);
				}
				obj_ptr = (object_ptr)pc[3];
				DeRefx(*obj_ptr);
				pc += 4;
				*obj_ptr = top;
				thread();
				BREAK;

			case L_COMPARE:
			deprintf("case L_COMPARE:");
				a = *(object_ptr)pc[1];
				top = *(object_ptr)pc[2];
				if (IS_ATOM_INT(a) && IS_ATOM_INT(top)) {
					top = (a < top) ? ATOM_M1: (a > top);
				}
				else {
					tpc = pc;
					top = compare(a, top);
				}
				obj_ptr = (object_ptr)pc[3];
				DeRefx(*obj_ptr);
				pc += 4;
				*obj_ptr = top;
				thread();
				BREAK;

			case L_HASH:
			deprintf("case L_HASH:");
				tpc = pc;
				a = *(object_ptr)pc[3];
				*(object_ptr)pc[3] = calc_hash(*(object_ptr)pc[1], *(object_ptr)pc[2]);
				DeRef( a );
				pc += 4;
				thread();
				BREAK;

			case L_FIND:
			deprintf("case L_FIND:");
				tpc = pc;
				a = find(*(object_ptr)pc[1], (s1_ptr)*(object_ptr)pc[2]);
				top = MAKE_INT(a);
				DeRef(*(object_ptr)pc[3]);
				*(object_ptr)pc[3] = top;
				pc += 4;
				thread();
				BREAK;

			case L_MATCH:
			deprintf("case L_MATCH:");
				tpc = pc;
				top = MAKE_INT(e_match((s1_ptr)*(object_ptr)pc[1],
									 (s1_ptr)*(object_ptr)pc[2]));
				DeRef(*(object_ptr)pc[3]);
				*(object_ptr)pc[3] = top;
				pc += 4;
				thread();
				BREAK;

#if INTPTR_MAX == INT64_MAX
			case L_PEEK_POINTER:
#endif
			case L_PEEK8U:
				deprintf("case L_PEEK8U:");
				b = 1;
				goto peek8s1;

			case L_PEEK8S:
			deprintf("case L_PEEK8S:");
				b = 0;
			 peek8s1:
				a = *(object_ptr)pc[1]; /* the address */
				tpc = pc;  // in case of machine exception
				top = do_peek8(a, b);
				DeRefx(*(object_ptr)pc[2]);
				*(object_ptr)pc[2] = top;
				inc3pc();
				thread();
				BREAK;


#if INTPTR_MAX == INT32_MAX
			case L_PEEK_POINTER:
#endif
			case L_PEEK4U:
			deprintf("case L_PEEK4U:");
				b = 1;
				goto peek4s1;

			case L_PEEK4S:
			deprintf("case L_PEEK4S:");
				b = 0;
			 peek4s1:
				a = *(object_ptr)pc[1]; /* the address */
				tpc = pc;  // in case of machine exception
				top = do_peek4(a, b);
				DeRefx(*(object_ptr)pc[2]);
				*(object_ptr)pc[2] = top;
				inc3pc();
				thread();
				BREAK;

			case L_PEEK2U:
			deprintf("case L_PEEK2U:");
				b = 1;
				goto peek2s1;

			case L_PEEK2S:
			deprintf("case L_PEEK2S:");
				b = 0;
			 peek2s1:
				a = *(object_ptr)pc[1]; /* the address */
				tpc = pc;  // in case of machine exception
				top = do_peek2(a, b);
				DeRefx(*(object_ptr)pc[2]);
				*(object_ptr)pc[2] = top;
				inc3pc();
				thread();
				BREAK;

			case L_PEEK_STRING:
			deprintf("case L_PEEK_STRING:");
				a = *(object_ptr)pc[1]; /* the address */
				tpc = pc;  // in case of machine exception
				if (IS_ATOM_INT(a)) {
					poke_addr = (char *)INT_VAL(a);
				}
				else if (IS_ATOM(a)) {
#ifdef __arm__
					double d = DBL_PTR(a)->dbl;
					poke_addr = (char*) (uintptr_t) d;
#else
					poke_addr = (char*) (uintptr_t) DBL_PTR(a)->dbl;
#endif
				}
				else { /* sequence */
						RTFatal(
				  "argument to peek_string() must be an atom");
				}
				top = NewString(poke_addr);
				DeRefx(*(object_ptr)pc[2]);
				*(object_ptr)pc[2] = top;
				inc3pc();
				thread();
				BREAK;

			case L_SIZEOF:
				a = *(object_ptr)pc[1]; /* the data type */
				top = *(object_ptr)pc[2];
				tpc = pc;  // in case of machine exception
				*(object_ptr)pc[2] = eu_sizeof( a );
				DeRef( top );
				inc3pc();
				thread();
				BREAK;
				
			case L_PEEKS:
			deprintf("case L_PEEKS:");
				b = 1;
				goto peeks1;
			case L_PEEK:
			deprintf("case L_PEEK:");
				b = 0;

				peeks1:

				a = *(object_ptr)pc[1]; /* the address */
				tpc = pc;  // in case of machine exception

				/* check address */
				if (IS_ATOM_INT(a)) {
					poke_addr = (char *)INT_VAL(a);
				}
				else if (IS_ATOM(a)) {
					poke_addr = (char *)(uintptr_t)(DBL_PTR(a)->dbl);
				}
				else {
					/* a sequence: {addr, nbytes} */
					s1 = SEQ_PTR(a);
					i = s1->length;
					if (i != 2) {
						RTFatal(
				  "argument to peek() must be an atom or a 2-element sequence");
					}
					poke_addr = (char *)get_pos_int("peek", *(s1->base+1));
					i = get_pos_int("peek", *((s1->base)+2)); /* length */
					if (i < 0)
						RTFatal("number of bytes to peek is less than 0");
					s1 = NewS1(i);
					obj_ptr = s1->base;
					while (--i >= 0) {
						obj_ptr++;
						if(b)
							*obj_ptr = (signed char)*poke_addr;
						else
							*obj_ptr = (unsigned char)*poke_addr;
						poke_addr++;
					}
					DeRef(*(object_ptr)pc[2]);
					*(object_ptr)pc[2] = (object)MAKE_SEQ(s1);
					inc3pc();
					thread();
				}

				DeRefx(*(object_ptr)pc[2]);

				if (b)
					*(object_ptr)pc[2] = (signed char)*poke_addr;
				else
					*(object_ptr)pc[2] = (unsigned char)*poke_addr;

				inc3pc();
				thread();
				BREAK;
#if INT64_MAX == INTPTR_MAX
			case L_POKE_POINTER:
#endif
			case L_POKE8:
				deprintf("case L_POKE8:");
				a = *(object_ptr)pc[1];   /* address */
				top = *(object_ptr)pc[2]; /* byte value */
				tpc = pc;
				do_poke8(a, top);
				inc3pc();
				thread();
				BREAK;
				
#if INT32_MAX == INTPTR_MAX
			case L_POKE_POINTER:
#endif
			case L_POKE4:
			deprintf("case L_POKE4:");
				a = *(object_ptr)pc[1];   /* address */
				top = *(object_ptr)pc[2]; /* byte value */
				tpc = pc;
				do_poke4(a, top);
				inc3pc();
				thread();
				BREAK;

			case L_POKE2:
			deprintf("case L_POKE2:");
				a = *(object_ptr)pc[1];   /* address */
				top = *(object_ptr)pc[2]; /* byte value */
				tpc = pc;
				do_poke2(a, top);
				inc3pc();
				thread();
				BREAK;

			case L_POKE:
			deprintf("case L_POKE:");
				a = *(object_ptr)pc[1];   /* address */
				top = *(object_ptr)pc[2]; /* byte value */
				tpc = pc;  // in case of machine exception

				/* check address */
				if (IS_ATOM_INT(a)) {
					poke_addr = (char *)a;
				}
				else if (IS_ATOM(a)) {
					poke_addr = (char *)(uintptr_t)(DBL_PTR(a)->dbl);
				}
				else {
					tpc = pc;
					RTFatal("first argument to poke must be an atom");
				}
				/* the following 6 lines bumped top out of a register */
				b = top;

				if (IS_ATOM_INT(b)) {
					
					*poke_addr = (uint8_t) b;
				}
				else if (IS_ATOM(b)) {
					/* no check for overflow here.. hmm*/
#ifdef __arm__
					b = trunc( DBL_PTR(b)->dbl );
					*poke_addr = (uint8_t) b;
#else
					*poke_addr = (uint8_t) DBL_PTR(b)->dbl;
#endif
				}
				else {
					/* second arg is sequence */
					s1 = SEQ_PTR(b);
					obj_ptr = s1->base;
					while (TRUE) {
						b = *(++obj_ptr);
						if (IS_ATOM_INT(b)) {
							*poke_addr = (uint8_t) b;
						}
						else if (IS_ATOM(b)) {
							if (b == NOVALUE)
								break;
#ifdef __arm__
							b = trunc( DBL_PTR(b)->dbl );
							*poke_addr = (uint8_t) b;
#else
							*poke_addr = (uint8_t) DBL_PTR(b)->dbl;
#endif
						}
						else {
							RTFatal(
							"sequence to be poked must only contain atoms");
						}
						++poke_addr;
					}
				}
				inc3pc();
				thread();
				BREAK;

			case L_MEM_COPY:
			deprintf("case L_MEM_COPY:");
				tpc = pc;
				memory_copy(*(object_ptr)pc[1],
							*(object_ptr)pc[2],
							*(object_ptr)pc[3]);
				pc += 4;
				thread();
				BREAK;

			case L_MEM_SET:
			deprintf("case L_MEM_SET:");
				tpc = pc;
				memory_set(*(object_ptr)pc[1],
						   *(object_ptr)pc[2],
						   *(object_ptr)pc[3]);
				pc += 4;
				thread();
				BREAK;

			case L_CALL:
			deprintf("case L_CALL:");
				a = *(object_ptr)pc[1];
				tpc = pc;   // for better profiling and machine exception
				/* check address */
				if (IS_ATOM_INT(a)) {
					sub_addr = (void(*)())INT_VAL(a);
				}
				else if (IS_ATOM(a)) {
#ifdef __arm__
					tuint = (uintptr_t)(DBL_PTR(a)->dbl);
					sub_addr = (void(*)())tuint;
#else
					sub_addr = (void(*)())(uintptr_t)(DBL_PTR(a)->dbl);
#endif
				}
				else {
					RTFatal("argument to call() must be an atom");
				}
				if (current_screen != MAIN_SCREEN)
					MainScreen();
				(*sub_addr)();
				pc += 2;
				/* thread(); */
				BREAK;

			case L_SYSTEM:
			deprintf("case L_SYSTEM:");
				tpc = pc;
				if (current_screen != MAIN_SCREEN)
					MainScreen();
				system_call(*(object_ptr)pc[1], *(object_ptr)pc[2]);
				inc3pc();
				BREAK;

			case L_SYSTEM_EXEC:
			deprintf("case L_SYSTEM_EXEC:");
				tpc = pc;
				if (current_screen != MAIN_SCREEN)
					MainScreen();
				top = system_exec_call(*(object_ptr)pc[1], *(object_ptr)pc[2]);
				DeRef(*(object_ptr)pc[3]);
				*(object_ptr)pc[3] = top;
				pc += 4;
				thread();
				BREAK;


				/* start of I/O routines */

			case L_OPEN:
			deprintf("case L_OPEN:");
				tpc = pc;
				top = EOpen(*(object_ptr)pc[1],
							*(object_ptr)pc[2],
							*(object_ptr)pc[3]);
				DeRef(*(object_ptr)pc[4]);
				*(object_ptr)pc[4] = top;
				pc += 5;
				thread();
				BREAK;

			case L_CLOSE:
			deprintf("case L_CLOSE:");
				tpc = pc;
				EClose(*(object_ptr)pc[1]);
				pc += 2;
				thread();
				BREAK;

			case L_GETC:  /* read a character from a file */
			deprintf("case L_GETC:");
				top = *(object_ptr)pc[1];
				if (current_screen != MAIN_SCREEN && might_go_screen(top)) {
					MainScreen(); // no error can happen, tpc needn't be set
								  // time_profile not relevant if debugging
				}
				if (top != last_r_file_no) {
					tpc = pc;
					last_r_file_ptr = which_file(top, EF_READ);
					if (IS_ATOM_INT(top))
						last_r_file_no = top;
					else
						last_r_file_no = NOVALUE;
				}
				if (last_r_file_ptr == stdin) {
#ifdef EWINDOWS
					// In WIN32 this is needed before
					// in_from_keyb is set correctly
					show_console();
#endif
					if (in_from_keyb) {
						b = getKBchar();
					}
					else {
#ifdef EUNIX
						b = getc(last_r_file_ptr);
#else
						b = mygetc(last_r_file_ptr);
#endif
					}
				}
				else
#ifdef EUNIX
					b = getc(last_r_file_ptr);
#else
					b = mygetc(last_r_file_ptr); /* don't use <a> ! */
#endif
				DeRefx(*(object_ptr)pc[2]);
				*(object_ptr)pc[2] = b;    //top;
				inc3pc();
				thread();
				BREAK;

			case L_GETS:  /* read a line from a file */
			deprintf("case L_GETS:");
				tpc = pc;
				top = EGets(*(object_ptr)pc[1]);
				DeRef(*(object_ptr)pc[2]);
				*(object_ptr)pc[2] = top;
				inc3pc();
				thread();
				BREAK;

			case L_PLATFORM: // only shrouded code needs this (for portability)
			deprintf("case L_PLATFORM:");
				DeRef(*(object_ptr)pc[1]);
				top = 1;  // Unknown platform
#ifdef EUNIX
				top = 3;  // (UNIX, called Linux for backwards compatibility)
#endif
#ifdef EBSD
				top = 8; // FreeBSD
#endif
#ifdef EOSX
				top = 4;  // OSX
#endif
#ifdef EOPENBSD
				top = 6; // OpenBSD
#endif
#ifdef ENETBSD
				top = 7; // NetBSD
#endif
#ifdef EWINDOWS
				top = 2;  // WIN32
#endif

				*(object_ptr)pc[1] = top;
				pc += 2;
				thread();
				BREAK;

			case L_GET_KEY: /* read an immediate key (if any) from the keyboard
							 or return -1 */
			deprintf("case L_GET_KEY:");
				tpc = pc;
#if defined(EWINDOWS)
				show_console();
#endif
				if (current_screen != MAIN_SCREEN) {
					MainScreen();
				}
				top = MAKE_INT(get_key(FALSE));
				if (top == ATOM_M1 && TraceOn) {
#ifdef EUNIX
					struct tms buf;
					c0 = times(&buf) + 8 * clk_tck; // wait 8 real seconds
					while (times(&buf)
#else
					c0 = clock() + 8 * clocks_per_sec;
					while (clock()
#endif
						< c0 && top == ATOM_M1) {
						top = MAKE_INT(get_key(FALSE));
					}
				}
				DeRef(*(object_ptr)pc[1]);
				*(object_ptr)pc[1] = top;
				pc += 2;
				thread();
				BREAK;

			case L_CLEAR_SCREEN:
			deprintf("case L_CLEAR_SCREEN:");
				tpc = pc++;
				if (current_screen != MAIN_SCREEN) {
					tpc = pc;
					MainScreen();
				}
				ClearScreen();
				BREAK;

			case L_PUTS:
			deprintf("case L_PUTS:");
				tpc = pc;
				EPuts(*(object_ptr)pc[1], *(object_ptr)pc[2]);
				inc3pc();
				tpc = pc;
				BREAK;

			case L_QPRINT:
			deprintf("case L_QPRINT:");
				i = 1;
				goto nextp;
			case L_PRINT:
			deprintf("case L_PRINT:");
				i = 0;
			nextp:
				tpc = pc;
				a = *(object_ptr)pc[1];  /* file number */
				top = *(object_ptr)pc[2];
				StdPrint(a, top, i);
				inc3pc();
				BREAK;

			case L_PRINTF:
			deprintf("case L_PRINTF:");
				/* file number, format string, value */
				tpc = pc;
				file_no = *(object_ptr)pc[1];
				EPrintf(file_no,*(object_ptr)pc[2], *(object_ptr)pc[3]);
				pc += 4;
				BREAK;

			case L_SPRINTF:
			deprintf("case L_SPRINTF:");
				/* format string, value */
				tpc = pc;
				top = EPrintf(DOING_SPRINTF, *(object_ptr)pc[1], *(object_ptr)pc[2]);
				DeRef(*(object_ptr)pc[3]);
				*(object_ptr)pc[3] = top;
				pc += 4;
				thread();
				BREAK;

			case L_COMMAND_LINE:
			deprintf("case L_COMMAND_LINE:");
				tpc = pc;
				top = Command_Line();
				DeRef(*(object_ptr)pc[1]);
				*(object_ptr)pc[1] = top;
				pc += 2;
				thread();
				BREAK;

			case L_OPTION_SWITCHES:
			deprintf("case L_OPTION_SWITCHES:");
				tpc = pc;
				top = fe.switches;
				RefDS( top );

				*(object_ptr)pc[1] = top;
				pc += 2;
				thread();
				BREAK;

			case L_GETENV:
			deprintf("case L_GETENV:");
				tpc = pc;
				top = EGetEnv( *(object_ptr)pc[1] );
				DeRef(*(object_ptr)pc[2]);
				*(object_ptr)pc[2] = top;
				inc3pc();
				thread();
				BREAK;

			case L_MACHINE_FUNC:
			deprintf("case L_MACHINE_FUNC:");
				tpc = pc;
				top = machine(*(object_ptr)pc[1],
							  *(object_ptr)pc[2]);
				DeRef(*(object_ptr)pc[3]);
				*(object_ptr)pc[3] = top;
				pc += 4;
				thread();
				BREAK;

			case L_MACHINE_PROC:
			deprintf("case L_MACHINE_PROC:");
				tpc = pc;
				machine(*(object_ptr)pc[1], *(object_ptr)pc[2]);
				inc3pc();
				thread();
				BREAK;

			case L_C_FUNC:
			deprintf("case L_C_FUNC:");
				tpc = pc;
				top = call_c(1, *(object_ptr)pc[1],
								*(object_ptr)pc[2]);//callback could happen here
				restore_privates((symtab_ptr)pc[3]);
				DeRef(*(object_ptr)pc[4]);
				*(object_ptr)pc[4] = top;
				tpc = pc + 5;
				thread5();
				BREAK;

			case L_C_PROC:
			deprintf("case L_C_PROC:");
				tpc = pc;
				top = call_c(0, *(object_ptr)pc[1],
								*(object_ptr)pc[2]);//callback could happen here
				restore_privates((symtab_ptr)pc[3]);
				pc += 4;
				tpc = pc;
				thread();
				BREAK;

			/* Multitasking */

			case L_TASK_CREATE:
			deprintf("case L_TASK_CREATE:");
				tpc = pc;
				top = task_create(*(object_ptr)pc[1],
								  *(object_ptr)pc[2]);
				a = pc[3];
				DeRef(*(object_ptr)a);
				*(object_ptr)a = top;
				pc += 4;
				thread();
				BREAK;

			case L_TASK_SCHEDULE:
			deprintf("case L_TASK_SCHEDULE:");
				tpc = pc;
				task_schedule(*(object_ptr)pc[1],
							  *(object_ptr)pc[2]);
				inc3pc();
				thread();
				BREAK;

			case L_TASK_YIELD:
			deprintf("case L_TASK_YIELD:");
				tpc = pc;
				task_yield();
				pc = tpc;
				thread();
				BREAK;

			case L_TASK_SELF:
			deprintf("case L_TASK_SELF:");
				top = (object)pc[1];
				DeRef(*(object_ptr)top);
				*(object_ptr)top = NewDouble(tcb[current_task].tid);
				pc += 2;
				thread();
				BREAK;

			case L_TASK_SUSPEND:
			deprintf("case L_TASK_SUSPEND:");
				tpc = pc;
				task_suspend(*(object_ptr)pc[1]);
				pc += 2;
				thread();
				BREAK;

			case L_TASK_LIST:
			deprintf("case L_TASK_LIST:");
				tpc = pc;
				top = task_list();
				a = pc[1];
				DeRef(*(object_ptr)a);
				*(object_ptr)a = top;
				pc += 2;
				thread(); // causes problem? - ok now
				BREAK;

			case L_TASK_STATUS:
			deprintf("case L_TASK_STATUS:");
				tpc = pc;
				top = task_status(*(object_ptr)pc[1]);
				a = pc[2];
				DeRef(*(object_ptr)a);
				*(object_ptr)a = top;
				inc3pc();
				thread();
				BREAK;

			case L_TASK_CLOCK_STOP:
			deprintf("case L_TASK_CLOCK_STOP:");
				tpc = pc;
				task_clock_stop();
				pc += 1;
				BREAK;

			case L_TASK_CLOCK_START:
			deprintf("case L_TASK_CLOCK_START:");
				tpc = pc;
				task_clock_start();
				pc += 1;
				BREAK;


			/* tracing/profiling ops */
			case L_STARTLINE_BREAK:
				TraceOn = trace_enabled;
				
			case L_STARTLINE:
			deprintf("case L_STARTLINE:");
				top = pc[1];
				a = slist[top].options;
#ifndef BACKEND
				if (a & OP_PROFILE_STATEMENT) {
					if (ProfileOn) {
						iptr = (int *)slist[top].src;
						(*iptr)++;
					}
				}
#endif
				pc += 2;
				tpc = pc;

#ifndef BACKEND
				if (a & OP_TRACE) {
					start_line = top;
					if (file_trace) {
#define one_line_len (120)
						char one_line[one_line_len];
						snprintf(one_line, one_line_len, "%.20s:%d\t%.80s",
								 name_ext(file_name[slist[top].file_no]),
								 slist[top].line,
								 (slist[top].options & (OP_PROFILE_STATEMENT |
														OP_PROFILE_TIME)) ?
								 slist[top].src+4 :
								 slist[top].src);
						one_line[one_line_len - 1] = '\0'; // ensure NULL

						b = TraceOn;
						TraceOn = TRUE;
						ctrace(one_line);
						TraceOn = b;
					}
					traced_lines = TRUE;
					TraceLineBuff[TraceLineNext++] = top;
					if (TraceLineNext == TraceLineSize)
						TraceLineNext = 0;
					if (TraceBeyond == HUGE_LINE) {
						b = 0;
					}
					else {
						/* stop after down-arrow pressed */
						i = expr_top - expr_stack;
						b = (top > TraceBeyond && i == TraceStack) ||
							i < TraceStack;
					}
					if (TraceOn || b) {
						/* turn on tracing */
						TraceOn = TRUE;
						if (b) {
							ShowDebug();
							UpdateGlobals();
						}

						TraceBeyond = HUGE_LINE;
						DebugScreen();
					}
				}
#endif

				thread();
				BREAK;

			case L_TRACE:
			deprintf("case L_TRACE:");
				tpc = pc;
				top = *(object_ptr)pc[1];
				trace_command(top);
				pc += 2;
				BREAK;

			case L_PROFILE:
			deprintf("case L_PROFILE:");
				tpc = pc;
				top = *(object_ptr)pc[1];
				profile_command(top);
				pc += 2;
				BREAK;

			case L_DISPLAY_VAR: /* display variable name and value */
			deprintf("case L_DISPLAY_VAR:");
				if (TraceOn) {
					tpc = pc;
#ifndef BACKEND
					ShowDebug();
					DisplayVar((symtab_ptr)pc[1], FALSE);
#endif
				}
				pc += 2;
				BREAK;

			case L_ERASE_PRIVATE_NAMES: /* blank private vars on debug screen */
			deprintf("case L_ERASE_PRIVATE_NAMES:");
#ifndef BACKEND
				if (TraceOn) {
					tpc = pc;
					ShowDebug();
					ErasePrivates((symtab_ptr)pc[1]);
				}
#endif
				pc += 2;
				BREAK;

			case L_ERASE_SYMBOL:
			deprintf("case L_ERASE_SYMBOL:");
#ifndef BACKEND
				if (TraceOn) {
					tpc = pc;
					ShowDebug();
					EraseSymbol((symtab_ptr)pc[1]);
				}
#endif
				pc += 2;
				BREAK;

			case L_UPDATE_GLOBALS:
			deprintf("case L_UPDATE_GLOBALS:");
				if (TraceOn) {
					tpc = pc;
#ifndef BACKEND
					ShowDebug();
					UpdateGlobals();
#endif
				}
				pc++;
				BREAK;

			case L_ABORT:
			deprintf("case L_ABORT:");
				tpc = pc;
				top = *(object_ptr)pc[1];
				if (IS_ATOM_INT(top)) {
					i = top;
				}
				else if (IS_ATOM(top)) {
					i = (int)DBL_PTR(top)->dbl;
				}
				else
					RTFatal("argument to abort() must be an atom");
				UserCleanup(i);
				sym = TopLevelSub->u.subp.block;
				while( (sym = sym->next_in_block) ){
						DeRef(sym->obj);
				}
				BREAK;

			case L_FIND_FROM:
			deprintf("case L_FIND_FROM:");
					tpc = pc;
					a = find_from(*(object_ptr)pc[1], *(object_ptr)pc[2], *(object_ptr)pc[3]);
					top = MAKE_INT(a);
					DeRef(*(object_ptr)pc[4]);
					*(object_ptr)pc[4] = top;
					thread5();
					BREAK;

			case L_MATCH_FROM:
			deprintf("case L_MATCH_FROM:");
					tpc = pc;
					a = e_match_from( *(object_ptr)pc[1], *(object_ptr)pc[2],
							*(object_ptr) pc[3]);
					top = MAKE_INT(a);
					DeRef(*(object_ptr)pc[4]);
					*(object_ptr)pc[4] = top;

					thread5();
					BREAK;

			case L_COVERAGE_LINE:
			deprintf("case L_COVERAGE_LINE");
				COVER_LINE( *(pc+1) );
				thread2();
				BREAK;

			case L_COVERAGE_ROUTINE:
			deprintf("case L_COVERAGE_ROUTINE");
				COVER_ROUTINE( *(pc+1) );
				thread2();
				BREAK;

			default:
				RTFatal("Unsupported Op Code ");

		}
	} while(TRUE);

subsfail:
	tpc = pc;
	RTFatal("attempt to subscript an atom\n(reading from it)");

asubsfail:
	tpc = pc;
	SubsAtomAss();

dblplus:
	tpc = pc;
	v = top;
	top = NewDouble((eudouble)v);
	goto contplus;

dblplus_i:
	tpc = pc;
	b = top;
	top = NewDouble((eudouble)b);
	*obj_ptr = top;
	inc3pc();
	RTFatalType(pc);
	goto contplus_i;
}

void AfterExecute()
// Address of this routine is used by time profiler
{
}

