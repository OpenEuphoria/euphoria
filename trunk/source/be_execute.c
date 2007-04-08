/*****************************************************************************/
/*      (c) Copyright 2006 Rapid Deployment Software - See License.txt       */
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
#include <stdio.h>
#include <time.h>
#ifdef ELINUX
#include <sys/times.h>
#else
#ifdef EDJGPP
#include <go32.h>
#endif
#ifdef EWATCOM
#include <graph.h>
#endif
#include <conio.h>
#endif
#include <math.h>
#ifdef EXTRA_CHECK
#include <malloc.h>
#endif
#ifdef EWINDOWS
#include <windows.h>
#endif
#include "alldefs.h"
#include "alloc.h"
#include <signal.h>

/******************/
/* Local defines  */
/******************/
#define POINT5 0.5
#define HUGE_LINE 1000000000

/* took out:    || (fp)->_flag&_UNGET \  
   added:       tpc = pc */
#ifdef ORIGINALWATCOM
#define getc(fp) \
	((fp)->_cnt<=0 \
	|| (fp)->_flag&_UNGET \
	|| (*(fp)->_ptr)=='\x0d' \
	|| (*(fp)->_ptr)=='\x1a' \
	? fgetc(fp) \
	: ((fp)->_cnt--,*(fp)->_ptr++))
#endif

#if defined(EWATCOM) || defined(ELINUX)
// a bit faster:
#define mygetc(fp) \
	((fp)->_cnt<=0 \
	|| (*(fp)->_ptr)=='\x0d' \
	|| (*(fp)->_ptr)=='\x1a' \
	? (tpc = pc , fgetc(fp)) \
	: ((fp)->_cnt--,*(fp)->_ptr++))
#else
#define mygetc(fp) getc(fp)
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

#define START_BIN_OP  a = *(object_ptr)pc[1];        \
		      top = *(object_ptr)pc[2];      \
		      obj_ptr = (object_ptr)pc[3];   \
		      if (IS_ATOM_INT(a) && IS_ATOM_INT(top)) { 

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
			       pc = (int *)pc[3];     \
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
			       pc = (int *)pc[3];     \
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
/* Imported variables */
/**********************/
extern int clk_tck;
extern int current_task;
extern struct tcb *tcb;
extern char *file_name_entered;
extern int traced_lines;
extern struct op_info optable[];
extern unsigned cache_size;
extern int align4;
extern int clocks_per_sec;
extern unsigned char TempBuff[];
extern int TraceOn;
extern int in_from_keyb;
extern int trace_enabled;
extern int *TraceLineBuff;      
extern int TraceLineSize;
extern int TraceLineNext;
extern symtab_ptr TopLevelSub;
extern object last_w_file_no;
extern FILE *last_w_file_ptr;
extern object last_r_file_no;
extern FILE *last_r_file_ptr;
extern long bytes_allocated;
extern int current_screen;
extern d_ptr d_list;
extern int color_trace;
extern int file_trace;
extern symtab_ptr *e_routine;
extern int e_routine_next;
extern char *type_error_msg;
extern object_ptr rhs_slice_target;  /* avoids 4th arg for RHS_Slice() */
extern s1_ptr *assign_slice_seq;
extern int *profile_sample;
#ifdef EWINDOWS
extern unsigned default_heap;
#endif

/**********************/
/* Declared functions */
/**********************/
void INT_Handler(int);
unsigned long good_rand();
void RHS_Slice();
object user(), Command_Line(), EOpen(), Repeat(); 
object machine();
object unary_op(), binary_op(), binary_op_a(), Date(), Time(),
       NewDouble();

object add(), minus(), uminus(), e_sqrt(), Random(), multiply(), divide(),
     equals(), less(), greater(), noteq(), greatereq(), lesseq(),
     and(), or(), xor(), not(), e_sin(), e_cos(), e_tan(), e_arctan(),
     e_log(), e_floor(), eremainder(), and_bits(), or_bits(),
     xor_bits(), not_bits(), power();

object Dadd(), Dminus(), Duminus(), De_sqrt(), DRandom(), Dmultiply(), Ddivide(),
     Dequals(), Dless(), Dgreater(), Dnoteq(), Dgreatereq(), Dlesseq(),
     Dand(), Dor(), Dxor(), Dnot(), De_sin(), De_cos(), De_tan(), De_arctan(),
     De_log(), De_floor(), Dremainder(), Dand_bits(), Dor_bits(),
     Dxor_bits(), Dnot_bits(), Dpower();

object x(); /* error */
symtab_ptr PrivateVar();
long find(), e_match();
FILE *which_file();
char *EMalloc();
object_ptr BiggerStack();
void do_exec();
s1_ptr NewS1();
double current_time();
void Machine_Handler();

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
int *tpc;

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
    int i;              
		
    if (IS_ATOM_INT(x)) {
	i = x;
    }
    else if (IS_ATOM(x)) {
	i = (int)DBL_PTR(x)->dbl;
    }
    else 
	RTFatal("argument to trace() must be an atom");
#ifdef EWINDOWS
	if (i != 3) {
	    show_console();
	}
#endif

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
	}
	else if (i == 2) {
	    TraceOn = trace_enabled;
	    color_trace = FALSE;
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

static object do_peek4(object a, int b, int *pc)
// peek4u, peek4s
// moved it here because it was causing bad code generation for WIN32
{
    int i;              
    unsigned long *peek4_addr;
    object top;
    s1_ptr s1;
    object_ptr obj_ptr;
		
    /* check address */
    if (IS_ATOM_INT(a)) {
	peek4_addr = (unsigned long *)a;
    }
    else if (IS_ATOM(a)) {
	peek4_addr = (unsigned long *)(unsigned long)(DBL_PTR(a)->dbl);
    }
    else {
	/* a sequence: {addr, nbytes} */
	s1 = SEQ_PTR(a);                                        
	i = s1->length;
	if (i != 2) {
	    RTFatal("argument to peek() must be an atom or a 2-element sequence");
	}
	peek4_addr = (unsigned long *)get_pos_int("peek4s/peek4u", *(s1->base+1));
#ifdef EDOS                    
	if (current_screen != MAIN_SCREEN && 
	    (unsigned)peek4_addr >= (unsigned)0xA0000 && 
	    (unsigned)peek4_addr < (unsigned)0xC0000) 
	    MainScreen();
#endif                  
	i = get_pos_int("peek4s/peek4u", *(s1->base+2));/* length*/
	if (i < 0)
	    RTFatal("number of bytes to peek is less than 0");
	s1 = NewS1(i);
	obj_ptr = s1->base;
	if (b) {
	    // unsigned
	    while (--i >= 0) {
#ifdef EDJGPP                       
		if ((unsigned)peek4_addr <= LOW_MEMORY_MAX)
		    top = _farpeekl(_go32_info_block.selector_for_linear_memory, 
				       (unsigned)peek4_addr++);
		else    
#endif                      
		    top = (object)*peek4_addr++;
		if ((unsigned)top > (unsigned)MAXINT)
		    top = NewDouble((double)(unsigned long)top);
		*(++obj_ptr) = top;
	    }
	}
	else {
	    // signed
	    while (--i >= 0) {
#ifdef EDJGPP                       
		if ((unsigned)peek4_addr <= LOW_MEMORY_MAX)
		    top = _farpeekl(_go32_info_block.selector_for_linear_memory, 
						(unsigned)peek4_addr++);
		else    
#endif                      
		    top = (object)*peek4_addr++;
		if (top < MININT || top > MAXINT)
		    top = NewDouble((double)(long)top);
		*(++obj_ptr) = top;
	    }
	}
	return (object)MAKE_SEQ(s1);
    }
#ifdef EDOS
    if (current_screen != MAIN_SCREEN && 
	(unsigned)peek4_addr >= (unsigned)0xA0000 && 
	(unsigned)peek4_addr < (unsigned)0xC0000) 
	MainScreen();
#endif              
#ifdef EDJGPP                       
    if ((unsigned)peek4_addr <= LOW_MEMORY_MAX)
	top = _farpeekl(_go32_info_block.selector_for_linear_memory, 
						   (unsigned)peek4_addr);
    else    
#endif                      
	top = (object)*peek4_addr;
    if (b) {
	// unsigned
	if ((unsigned)top > (unsigned)MAXINT)
	    top = NewDouble((double)(unsigned long)top);
    }
    else {
	// signed
	if (top < MININT || top > MAXINT)
	    top = NewDouble((double)(long)top);
    }
    
    return top;
}


static void do_poke4(object a, object top)
// moved it here because it was causing bad code generation for WIN32
{
    unsigned long *poke4_addr;
    double temp_dbl;
    s1_ptr s1;
    object_ptr obj_ptr;
	
    /* determine the address to be poked */
    if (IS_ATOM_INT(a)) {
	poke4_addr = (unsigned long *)INT_VAL(a);
    }
    else if (IS_ATOM(a)) {
	poke4_addr = (unsigned long *)(unsigned long)(DBL_PTR(a)->dbl);
    }
    else {
	RTFatal("first argument to poke4 must be an atom");
    }
#ifdef EDOS
    if (current_screen != MAIN_SCREEN && 
	(unsigned)poke4_addr >= (unsigned)0xA0000 && 
	(unsigned)poke4_addr < (unsigned)0xC0000)
	MainScreen();
#endif
    /* look at the value to be poked */
    if (IS_ATOM_INT(top)) {
#ifdef EDJGPP       
	if ((unsigned)poke4_addr <= LOW_MEMORY_MAX)
	    _farpokel(_go32_info_block.selector_for_linear_memory,
		      (unsigned long)poke4_addr, (unsigned long)INT_VAL(top));
	else
#endif      
	    *poke4_addr = (unsigned long)INT_VAL(top);
    }
    else if (IS_ATOM(top)) {
	temp_dbl = DBL_PTR(top)->dbl;
	if (temp_dbl < MIN_BITWISE_DBL || temp_dbl > MAX_BITWISE_DBL)
	    RTFatal("poke4 is limited to 32-bit numbers");
#ifdef EDJGPP       
	if ((unsigned)poke4_addr <= LOW_MEMORY_MAX)
	    _farpokel(_go32_info_block.selector_for_linear_memory,
		      (unsigned long)poke4_addr, (unsigned long)temp_dbl);
	else
#endif      
	    *poke4_addr = (unsigned long)temp_dbl;
    }
    else {
	/* second arg is sequence */
	s1 = SEQ_PTR(top);
	obj_ptr = s1->base;
	while (TRUE) { 
	    top = *(++obj_ptr); 
	    if (IS_ATOM_INT(top)) {
#ifdef EDJGPP       
		if ((unsigned)poke4_addr <= LOW_MEMORY_MAX)
		    _farpokel(_go32_info_block.selector_for_linear_memory,
		      (unsigned long)poke4_addr++, (unsigned long)INT_VAL(top));
		else
#endif      
		    *poke4_addr++ = (unsigned long)INT_VAL(top);
	    }
	    else if (IS_ATOM(top)) {
		if (top == NOVALUE)
		    break;
		temp_dbl = DBL_PTR(top)->dbl;
		if (temp_dbl < MIN_BITWISE_DBL || temp_dbl > MAX_BITWISE_DBL)
		    RTFatal("poke4 is limited to 32-bit numbers");
#ifdef EDJGPP       
		if ((unsigned)poke4_addr <= LOW_MEMORY_MAX)
		    _farpokel(_go32_info_block.selector_for_linear_memory,
		      (unsigned long)poke4_addr++, (unsigned long)temp_dbl);
		else
#endif      
		    *poke4_addr++ = (unsigned long)temp_dbl;
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
#define thread2() {pc += 2; goto loop_top;}
#define thread4() {pc += 4; goto loop_top;}
#define thread5() {pc += 5; goto loop_top;}
#define threadpc3() {pc = (int *)pc[3]; goto loop_top;}
#define inc3pc() pc += 3
#include "redef.h"
#include "opnames.h"
#define BREAK break

#else
// THREADED CODE - implemented in various ways

#define FP_EMULATION_NEEDED // FOR WATCOM/DOS to run on old 486/386 without f.p.

#if defined(EWINDOWS) || (defined(EDOS) && defined(EWATCOM) && !defined(FP_EMULATION_NEEDED))
// #pragma aux thread aborts; does nothing

#pragma aux thread = \
	"jmp [ECX]" \
	modify [EAX EBX EDX];

void thread2(void);
#pragma aux thread2 = \
	"ADD ECX, 8" \
	"jmp [ECX]" \
	modify [EAX EBX EDX];

void thread4(void);
#pragma aux thread4 = \
	"ADD ECX, 16" \
	"jmp [ECX]" \
	modify [EAX EBX EDX];

void thread5(void);
#pragma aux thread5 = \
	"ADD ECX, 20" \
	"jmp [ECX]" \
	modify [EAX EBX EDX];

/* have to hide this from WATCOM or it will generate stupid code
   at the top of the switch */
#pragma aux inc3pc = \
	"ADD ECX, 12" \
	modify [];

void threadpc3(void);
#pragma aux threadpc3 = \
	"MOV ECX, EDI" \
	"jmp [ECX]"    \
	modify [EAX EBX ECX EDX];
	
#define BREAK break
#include "redef.h"
#endif

#if defined(EDOS) && defined(EWATCOM) && defined(FP_EMULATION_NEEDED)
// WATCOM:
// #pragma aux thread aborts; does nothing
// modify [...] seems to do very little, works no matter what regs are
// specified or even if modify is removed

void thread(void);
#pragma aux thread = "jmp [ESI]"  \
		     modify [EAX EBX EDX];

void thread2(void);
#pragma aux thread2 = "ADD ESI, 8" \
		      "jmp [ESI]" \
		      modify [EAX EBX EDX];

void thread4(void);
#pragma aux thread4 = "ADD ESI, 16" \
		      "jmp [ESI]" \
		      modify [EAX EBX EDX];

void thread5(void);
#pragma aux thread5 = "ADD ESI, 20" \
		      "jmp [ESI]" \
		      modify [EAX EBX EDX];

/* have to hide this from WATCOM or it will generate stupid code
   at the top of the switch */
#pragma aux inc3pc = \
	"ADD ESI, 12" \
	modify [];
#define BREAK break
#include "redef.h"
#endif

#if defined(ELINUX) || defined(EDJGPP)
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

#pragma aux nop = \
	"nop" \
	modify[];

static int recover_rhs_subscript(object subscript, s1_ptr s)
/* rhs subscript failed initial check, but might be ok */
{
    int subscripti;
    
    if (IS_ATOM_INT(subscript)) {
	RangeReading(subscript, s->length);
    }
    else if (IS_ATOM_DBL(subscript)) {
	subscripti = (long)(DBL_PTR(subscript)->dbl); 
	if ((unsigned long)(subscripti - 1) < s->length) 
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
    sprintf(TempBuff,
	   "call to %s() via routine-id should pass %d argument%s, not %d",
	   sub->name, sub->u.subp.num_args, 
	   (sub->u.subp.num_args == 1) ? "" :"s",
	   ((s1_ptr)a)->length);
    RTFatal(TempBuff);
}

static int recover_lhs_subscript(object subscript, s1_ptr s)
/* lhs subscript failed initial check, but might be ok */
{
    int subscripti;
    
    if (IS_ATOM_INT(subscript)) {
	BadSubscript(subscript, s->length);
    }
    else if (IS_ATOM_DBL(subscript))  {
	subscripti = (long)(DBL_PTR(subscript)->dbl);
	if ((unsigned long)(subscripti - 1) < s->length)
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
    expr_stack[toplevel] = TopLevelSub;  
    expr_top = &expr_stack[toplevel+1];  /* next available place on expr stack */
 
    /* must allow for a few extra words */
    expr_max = expr_stack + (stack_size - 5);
    expr_limit = expr_max - 3; // we only push two items per call
}

void InitExecute()
{
    // signal(SIGFPE, FPE_Handler)  // generate inf and nan instead
    signal(SIGINT, INT_Handler); 
    // SIG_IGN=> still see ^C echoed, but it has no effect other
    // than messing up the screen. INT_Handler lets us do
    // a bit of cleanup - tick rate, profile, active page etc.

#ifndef EDOS      // doesn't work on DOS
#ifndef ERUNTIME  // dll shouldn't take handler away from main program
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
}

void Execute(int *);

#ifndef INT_CODES
#if defined(ELINUX) || defined(EDJGPP)
int **jumptab; // initialized in do_exec() 
#else
/* Important! The offset below is based on the object code WATCOM 
 * generates for x.c. It is the address of the internal jump table 
 * generated by the compiler for the main switch statement in x.c.
 * It needs to be kept up-to-date or nothing will work.
 */
#ifdef EXTRA_CHECK
// address of big switch table minus address of Execute(), divided by 4
int **jumptab = ((int **)Execute)+53; 
#else
int **jumptab = ((int **)Execute)+4; 
#endif

#endif 
#endif //not INT_CODES


/* IL data passed from the front end */
struct IL fe;

#define SET_OPERAND(word) ((int *)(((word) == 0) ? 0 : (&fe.st[(int)(word)])))

#define SET_JUMP(word) ((int *)(&code[(int)(word)]))

void code_set_pointers(int **code)
/* adjust code pointers, changing some indexes into pointers */
{
    int len, i, j, n, sub, word;
    
    char msg[100]; 
    
    len = (int)code[0];
    i = 1;
    while (i <= len) {
	word = (int)code[i];
	
	if (word > MAX_OPCODE || word < 1) {
	    sprintf(msg, "BAD IL OPCODE: i is %d, word is %d, len is %d", 
		    i, word, len);
	    RTFatal(msg);
	}
	
	code[i] = (int *)opcode(word);
	
	//sprintf(msg, "word is %d", word);
	//debug_msg(msg);
	
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
	    case RETURNP:
	    case DATE: 
	    case TIME: 
	    case SPACE_USED: 
	    case CALL: 
	    case CLOSE:
	    case GET_KEY: 
	    case COMMAND_LINE:
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
		// one operand
		code[i+1] = SET_OPERAND(code[i+1]);
		i += 2;
		break;

	    case NOP2: 
	    case STARTLINE: 
		i += 2;
		break;

	    case ENDWHILE:
	    case ELSE:
	    case EXIT: 
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
	    case FLOOR:
	    case ASSIGN_I:
	    case ASSIGN:
	    case IS_AN_INTEGER:
	    case IS_AN_OBJECT:
	    case NOT_BITS:
	    case CALL_PROC:
	    case RETURNF: 
	    case POSITION: 
	    case PEEK4S: 
	    case PEEK4U:
	    case PIXEL: 
	    case GET_PIXEL:
	    case SYSTEM: 
	    case PUTS: 
	    case QPRINT:
	    case PRINT:
	    case GETENV:
	    case MACHINE_PROC:
	    case POKE4:
	    case POKE:
	    case SC2_AND:
	    case SC2_OR:
	    case TASK_SCHEDULE: 
	    case TASK_STATUS:
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
	    case OPEN: 
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
		// 4 operands follow
		code[i+1] = SET_OPERAND(code[i+1]);
		code[i+2] = SET_OPERAND(code[i+2]);
		code[i+3] = SET_OPERAND(code[i+3]);
		code[i+4] = SET_OPERAND(code[i+4]);
		i += 5;
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
		
	// special cases: variable number of operands
	
	    case PROC:
		sub = (int)code[i+1];
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
		n = (int)code[i+1];
		for (j = 1; j <= n+1; j++) {
		    word = (int)code[i+1+j];
		    code[i+1+j] = SET_OPERAND(word);
		}
		
		// more
		i += n + 3;
		break;
		
	    case CONCAT_N:
		n = (int)code[i+1];
		for (j = 1; j <= n; j++) {
		    word = (int)code[i+1+j];
		    code[i+1+j] = SET_OPERAND(word);
		}
		word = (int)code[i+n+2];
		code[i+n+2] = SET_OPERAND(word);
		
		i += n + 3;
		break;
		
	    default:
		RTFatal("UNKNOWN IL OPCODE");
	}
    }
}

// Compressed format of Euphoria objects
//
// First byte:
//          0..248  // immediate small integer, -9 to 239
		    // since small negative integers -9..-1 might be common
#define I2B 249   // 2-byte signed integer follows
#define I3B 250   // 3-byte signed integer follows
#define I4B 251   // 4-byte signed integer follows
#define F4B 252   // 4-byte f.p. number follows
#define F8B 253   // 8-byte f.p. number follows
#define S1B 254   // sequence, 1-byte length follows, then elements
#define S4B 255   // sequence, 4-byte length follows, then elements

#define MIN1B (-2)
#define MIN2B (-0x00008000)
#define MIN3B (-0x00800000)
#define MIN4B (-0x80000000)

static unsigned char *string_ptr;

object decompress(unsigned int c)
// read a compressed Euphoria object
// if c is set, then c is not <= 248    
{
    s1_ptr s;
    object_ptr obj_ptr;
    unsigned int len, i;
    int x;
    double d;
    
    if (c == 0) {
	c = *string_ptr++;
	if (c < I2B) {
	    return c + MIN1B;
	}
    }
    
    if (c == I2B) {
	i = (*string_ptr++);
	i = i + 256 * (*string_ptr++);
	return i + MIN2B;
    }
    
    else if (c == I3B) {
	i = *string_ptr++;
	i = i + 256 * (*string_ptr++);
	i = i + 65536 * (*string_ptr++);
	return i + MIN3B;
    }
    
    else if (c == I4B) {
	i = *(unsigned int *)string_ptr;
	string_ptr += 4;
	return i + MIN4B;
    }
    
    else if (c == F4B) {
	d = (double)*(float *)string_ptr; 
	string_ptr += 4;
	return NewDouble(d);
    }
    
    else if (c == F8B) {
	d = *(double *)string_ptr; 
	string_ptr += 8;
	return NewDouble(d);
    }
    
    else {
	// sequence
	if (c == S1B) {
	    len = *string_ptr++;
	}
	else {
	    len = *(unsigned int *)string_ptr;
	    string_ptr += 4;
	}
	s = NewS1(len);
	obj_ptr = s->base;
	obj_ptr++;
	for (i = 1; i <= len; i++) {
	    // inline small integer for greater speed on strings
	    c = *string_ptr++;
	    if (c < I2B) {
		*obj_ptr = c + MIN1B;
	    }
	    else {
		*obj_ptr = decompress(c);
	    }
	    obj_ptr++;
	}
	return MAKE_SEQ(s);
    }
}

void symtab_set_pointers()
/* set some symbol table fields to absolute pointers, rather than indexes */
{
    int i, len;
    struct symtab_entry *s;
    int **code;
    
    s = fe.st;
    len = *(int *)s;  // number of entries
    
    s++;  // point to first real entry
    for (i = 1; i <= len; i++) {
	s->next = (symtab_ptr)SET_OPERAND(s->next);
	
	if (s->mode == M_NORMAL) {
	    // normal variables, routines
	    s->obj = NOVALUE;

	    if (s->token == PROC || 
		s->token == FUNC || 
		s->token == TYPE) {

		code = (int **)s->u.subp.code;
		if (code != NULL) {
		    code_set_pointers(code);
		}
		s->u.subp.code = (int *)code+1; // skip length
		
		s->u.subp.temps = (symtab_ptr)SET_OPERAND(s->u.subp.temps);
		
		s->u.subp.resident_task = -1;
		s->u.subp.saved_privates = NULL;
		
		if (s->name[0] == '_' && strcmp(s->name, "_toplevel_") == 0) {
		    TopLevelSub = s;
		}
	    }
	}
	else if (s->mode == M_CONSTANT && s->obj) {
	    // namespaces, literal values only - vars declared as "constant" are left as 0
	    string_ptr = (unsigned char *)s->obj;
	    s->obj = decompress(0);
	}
	
	else {
	    // M_TEMP - temps
	    // leave obj as 0
	}
	s++;
    }
}

struct sline *slist;

/* Front-end variables passed via miscellaneous fe.misc */
char **file_name;
extern int warning_count;
extern char **warning_list;
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
    
#ifdef EDOS
    if (sample_size > 0) {
	profile_sample = (int *)EMalloc(sample_size * sizeof(int));
	lock_region(profile_sample, sample_size * sizeof(int));
	tick_rate(100);
    }
#endif  
    gline_number = fe.misc[4];
    il_file      = fe.misc[5];
    
    warning_count = fe.misc[6];
    file_name = (char **)&fe.misc[7];
    file_name_entered = (char *)fe.misc[8+fe.misc[7]];
    warning_list = (char **)&fe.misc[9+fe.misc[7]];
    
    // string containing all literals and constants in compressed form:
    free(fe.lit); 
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


static load_private_block(symtab_ptr routine, int task)
// Retrieve a private block and remove it from the list for this routine.
// We know that the block will be there, often near the start of the list.
{   
    struct private_block *p;
    struct private_block *prev_p;
    struct private_block *defunct;
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
	    
	    EFree(p); 
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

void Execute(int *start_index)
/* top level executor */
/* CAREFUL: any change to this routine might affect the offset to
   the big opccode switch table - see jumptab */
{
    do_exec(start_index);
	
    Executing = FALSE;
}

#ifndef INT_CODES
#if defined(ELINUX) || defined(EDJGPP)
// don't use switch/case - use special jump to label feature
#define case
#endif 
#endif //not INT_CODES


void do_exec(int *start_pc)
/* execute code, starting at start_pc */
{
    /* WATCOM keeps pc in a register, and usually top, a, obj_ptr */

    /* address registers: (3 max) */
    register int *pc;               /* program counter, kept in a register */
    register object_ptr obj_ptr;    /* general pointer to an object */

    /* data registers: (5 max) */
    register object a;            /* another object */
    volatile object v;            /* get compiler to do the right thing! */
    register object top;          /* an object - hopefully kept in a register */
    /*register*/ int i;           /* loop counter */
    
    double temp_dbl;
    struct d temp_d;
    unsigned char *poke_addr;
    void (*sub_addr)();
    int nvars;   
    int *iptr;
    int file_no;
    int going_up; 
    object_ptr result_ptr;
    object result_val;
    int cf;
    opcode_type *patch;
    object b, c;
    symtab_ptr sym, sub, caller;
    int c0;
    s1_ptr s1;
    object *block;
    
#if defined(ELINUX) || defined(EDJGPP)
#ifndef INT_CODES
    static void *localjumptab[MAX_OPCODE] = {
  &&L_LESS, &&L_GREATEREQ, &&L_EQUALS, &&L_NOTEQ, &&L_LESSEQ, &&L_GREATER,
  &&L_NOT, &&L_AND, &&L_OR, &&L_MINUS, 
/* 10 */  
  &&L_PLUS, &&L_UMINUS, &&L_MULTIPLY, &&L_DIVIDE, &&L_CONCAT, &&L_ASSIGN_SUBS,
  &&L_GETS, &&L_ASSIGN, &&L_PRINT, &&L_IF, 
/* 20 */  
  &&L_FOR, &&L_ENDWHILE, &&L_ELSE, &&L_OR_BITS, &&L_RHS_SUBS, &&L_XOR_BITS, 
  &&L_PROC, &&L_RETURNF, &&L_RETURNP, &&L_PRIVATE_INIT_CHECK, 
/* 30 */  
  &&L_RIGHT_BRACE_N, &&L_REPEAT, &&L_GETC, &&L_RETURNT, &&L_APPEND,
  &&L_QPRINT, &&L_OPEN, &&L_PRINTF, &&L_ENDFOR_GENERAL, &&L_IS_AN_OBJECT, 
/* 40 */  
  &&L_SQRT, &&L_LENGTH, &&L_BADRETURNF, &&L_PUTS, &&L_ASSIGN_SLICE,
  &&L_RHS_SLICE, &&L_WHILE, &&L_ENDFOR_INT_UP, &&L_ENDFOR_UP, &&L_ENDFOR_DOWN,
/* 50 */  
  &&L_NOT_BITS, &&L_ENDFOR_INT_DOWN, &&L_SPRINTF, &&L_ENDFOR_INT_UP1,
  &&L_ENDFOR_INT_DOWN1, &&L_AND_BITS, &&L_PREPEND, &&L_STARTLINE,
  &&L_CLEAR_SCREEN, &&L_POSITION,
/* 60 */  
  &&L_EXIT, &&L_RAND, &&L_FLOOR_DIV, &&L_TRACE, &&L_TYPE_CHECK,
  &&L_FLOOR_DIV2, &&L_IS_AN_ATOM, &&L_IS_A_SEQUENCE, &&L_DATE, &&L_TIME,
/* 70 */  
  &&L_REMAINDER, &&L_POWER, &&L_ARCTAN, &&L_LOG, NULL, &&L_COMPARE,
  &&L_FIND, &&L_MATCH, &&L_GET_KEY, &&L_SIN, 
/* 80 */  
  &&L_COS, &&L_TAN, &&L_FLOOR, &&L_ASSIGN_SUBS_CHECK, &&L_RIGHT_BRACE_2,
  &&L_CLOSE, &&L_DISPLAY_VAR, &&L_ERASE_PRIVATE_NAMES, &&L_UPDATE_GLOBALS,
  &&L_ERASE_SYMBOL, 
/* 90 */  
  &&L_GETENV, &&L_RHS_SUBS_CHECK, &&L_PLUS1, &&L_IS_AN_INTEGER,
  &&L_LHS_SUBS, &&L_INTEGER_CHECK, &&L_SEQUENCE_CHECK, &&L_DIV2,
  &&L_SYSTEM, &&L_COMMAND_LINE,
/* 100 */  
  &&L_ATOM_CHECK, &&L_LESS_IFW, &&L_GREATEREQ_IFW, &&L_EQUALS_IFW,
  &&L_NOTEQ_IFW, &&L_LESSEQ_IFW, &&L_GREATER_IFW, &&L_NOT_IFW, 
  &&L_GLOBAL_INIT_CHECK, &&L_NOP2,
/* 110 */  
  &&L_MACHINE_FUNC, &&L_MACHINE_PROC, &&L_ASSIGN_I, &&L_RHS_SUBS_I,
  &&L_PLUS_I, &&L_MINUS_I, &&L_PLUS1_I, &&L_ASSIGN_SUBS_I, &&L_LESS_IFW_I,
  &&L_GREATEREQ_IFW_I, 
/* 120 */  
  &&L_EQUALS_IFW_I, &&L_NOTEQ_IFW_I, &&L_LESSEQ_IFW_I, &&L_GREATER_IFW_I,
  &&L_FOR_I, &&L_ABORT, &&L_PEEK, &&L_POKE, &&L_CALL, &&L_PIXEL,
/* 130 */  
  &&L_GET_PIXEL, &&L_MEM_COPY, &&L_MEM_SET, &&L_C_PROC, &&L_C_FUNC,
  &&L_ROUTINE_ID, &&L_CALL_BACK_RETURN, &&L_CALL_PROC, &&L_CALL_FUNC,
  &&L_POKE4,
/* 140 */  
  &&L_PEEK4S, &&L_PEEK4U, &&L_SC1_AND, &&L_SC2_AND, &&L_SC1_OR,
  &&L_SC2_OR, NULL, &&L_SC1_AND_IF, &&L_SC1_OR_IF, NULL,
/* 150 */  
  &&L_ASSIGN_OP_SUBS, &&L_ASSIGN_OP_SLICE, &&L_PROFILE, &&L_XOR, &&L_EQUAL,
  &&L_SYSTEM_EXEC, 
  &&L_PLATFORM /* PLATFORM not always emitted*/, 
  NULL /* END_PARAM_CHECK not emitted */, 
  &&L_CONCAT_N, 
  NULL, /* L_NOPWHILE not emitted */
  NULL, /* L_NOP1 not emitted */
  &&L_PLENGTH,
  &&L_LHS_SUBS1,
  &&L_PASSIGN_SUBS, &&L_PASSIGN_SLICE, &&L_PASSIGN_OP_SUBS, 
  &&L_PASSIGN_OP_SLICE,
  &&L_LHS_SUBS1_COPY, &&L_TASK_CREATE, &&L_TASK_SCHEDULE, &&L_TASK_YIELD,
  &&L_TASK_SELF, &&L_TASK_SUSPEND, &&L_TASK_LIST,
  &&L_TASK_STATUS, &&L_TASK_CLOCK_STOP, 
/* 178 */ &&L_TASK_CLOCK_START
  };
#endif
#endif
    if (start_pc == NULL) {
#if defined(ELINUX) || defined(EDJGPP)
#ifndef INT_CODES
	jumptab = (int **)localjumptab;
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
	    sprintf(TempBuff, "Runtime bad opcode (%d) at %lx", *pc, pc);
	    RTFatal(TempBuff);
	}
	
	//{
	//char dm[100];
	//sprintf(dm, "%d: %s", *pc, opnames[*pc]);
	//debug_msg(dm);
	//}
	
	switch(*pc) {
#else
// threaded code
	thread();
#if !defined(ELINUX) && !defined(EDJGPP)
	switch((int)pc) {                                       
#endif

#endif
	    case L_RHS_SUBS_CHECK:
		if (!IS_SEQUENCE(*(object_ptr)pc[1])) {
		    goto subsfail;
		}
		/* FALL THROUGH */
	    case L_RHS_SUBS: /* rhs subscript of a sequence */
		top = *(object_ptr)pc[2];  /* the subscript */
		obj_ptr = (object_ptr)SEQ_PTR(*(object_ptr)pc[1]);/* the sequence */
		if ((unsigned long)(top-1) >= ((s1_ptr)obj_ptr)->length) {
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

	    case L_RHS_SUBS_I: /* rhs subscript of a known-to-be sequence */
		/* the target is an integer variable - no DeRef, 
		   TypeCheck failure if assigned non-integer */
		top = *(object_ptr)pc[2];  /* the subscript */
		obj_ptr = (object_ptr)SEQ_PTR(*(object_ptr)pc[1]);/* the sequence */
		if ((unsigned long)(top-1) >= ((s1_ptr)obj_ptr)->length) {
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
		// temp has pointer to sequence
		top = **(object_ptr *)pc[1];
		goto aos;
				
	    case L_ASSIGN_OP_SUBS:  /* var[subs] op= expr */
		top = *(object_ptr)pc[1];
	      aos:  
		if (!IS_SEQUENCE(top)) {  //optimize better
		    goto subsfail;
		}
		obj_ptr = (object_ptr)SEQ_PTR(top);/* the sequence */
		top = *(object_ptr)pc[2];  /* the subscript */
		pc[9] = pc[1]; // store in ASSIGN_SUBS op after length-4 binop
		if ((unsigned long)(top-1) >= ((s1_ptr)obj_ptr)->length) {
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
		if (!IS_SEQUENCE(*(object_ptr)pc[1])) {
		    goto asubsfail;
		}
		/* FALL THROUGH */
	    
	    case L_ASSIGN_SUBS:  /* final subscript and assignment */
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
		if ((unsigned long)(a-1) >= ((s1_ptr)obj_ptr)->length) { 
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
		/* we know that the rhs value to be assigned is an integer */
		obj_ptr = (object_ptr)SEQ_PTR(*(object_ptr *)pc[1]);/* the sequence */
		if (!UNIQUE(obj_ptr)) {
		    /* make it single-ref */
		    tpc = pc;
		    obj_ptr = (object_ptr)SequenceCopy((s1_ptr)obj_ptr);
		    *(object_ptr)pc[1] = MAKE_SEQ(obj_ptr);
		}
		top = *(object_ptr)pc[2]; /* the subscript */
		if ((unsigned long)(top-1) >= ((s1_ptr)obj_ptr)->length) { 
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
		obj_ptr = (object_ptr)pc[3]; /* loop var */
		top = *obj_ptr + 1;
		if (top <= *(object_ptr)pc[2]) {  /* limit */
		    *obj_ptr = top;
		    pc = (int *)pc[1];   /* loop again */
		    thread();
		}
		else {
		    thread5();  /* exit loop */
		}
		BREAK;

	    case L_ENDFOR_INT_UP:
		obj_ptr = (object_ptr)pc[3]; /* loop var */
		top = *obj_ptr + *(object_ptr)pc[4]; /* increment */
		if (top <= *(object_ptr)pc[2]) { /* limit */
		    *obj_ptr = top;
		    pc = (int *)pc[1]; /* loop again */
		    thread();
		}
		else {
		    thread5();  /* exit loop */
		}
		BREAK;


	    case L_EXIT:
	    case L_ENDWHILE:
	    case L_ELSE:
		pc = (int *)pc[1];
		thread();
		BREAK;

	    case L_PLUS1:
		a = (object)pc[3];
		top = *(object_ptr)pc[1];
		if (IS_ATOM_INT(top)) {
		    top++; 
		    if (top > MAXINT) {
			b = top;
			top = NewDouble((double)(INT_VAL(b)));
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
		    *(object_ptr)a = NewDouble((double)(INT_VAL(b)));
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
		top = *(object_ptr)pc[1];
		if (top >= ATOM_1) {   /* works with new representation */
		    inc3pc();
		    thread();
		    pc++; /* dummy */
		    BREAK;
		}
		goto if_check;
	  
	    case L_IF:
		top = *(object_ptr)pc[1];
	    if_check:
		if (top == ATOM_0) {
		    pc = (int *)pc[2];
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
			pc = (int *)pc[2];
		    }
		    else
			inc3pc();
		    thread();
		} 
		BREAK;

	    case L_ASSIGN_I:
		/* source & destination are known to be integers */
		*(object_ptr)pc[2] = *(object_ptr)pc[1];
		inc3pc();
		thread();
		BREAK;

	    case L_ASSIGN:
		obj_ptr = (object_ptr)pc[2];
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
		// temp contains a pointer to the sequence
		obj_ptr = (object_ptr)*(object_ptr)pc[1]; 
		b = 0;
		goto ls;

	    case L_LHS_SUBS1_COPY:
		// copy base sequence into a temp, then use the temp
		obj_ptr = (object_ptr)pc[4]; 
		a = *(object_ptr)pc[1];
		Ref(a);
		DeRef(*obj_ptr);
		*obj_ptr = a;
		b = 1;
		goto ls;
		
	    case L_LHS_SUBS1:  
		/* left hand side, first subscript of multiple lhs subscripts */
		// sequence var: 
		obj_ptr = (object_ptr)pc[1]; 
		b = 1;
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
		if ((unsigned long)(a-1) >= ((s1_ptr)obj_ptr)->length) {
		    tpc = pc;
		    a = recover_lhs_subscript(a, (s1_ptr)obj_ptr);
		}
		obj_ptr = a + ((s1_ptr)obj_ptr)->base;
		
		// error-check for sequence
		if (IS_SEQUENCE(*obj_ptr)) {
		    top = pc[3]; // target temp
		    if (b) {
			DeRef(*(object_ptr)top); // only SUBS1
		    }
		    *((object_ptr)top) = (object)obj_ptr; // storing a C pointer
		    thread5();
		}
		goto asubsfail;
		BREAK;

	    case L_PASSIGN_OP_SLICE:
		// temp has pointer to sequence
		top = *(object_ptr)pc[1];
		goto aosl;
		
	    case L_ASSIGN_OP_SLICE:  /* var[i..j] op= expr */
		top = pc[1];
	     aosl:  
		pc[10] = pc[1];
		rhs_slice_target = (object_ptr)pc[4];
		tpc = pc;
		RHS_Slice((s1_ptr)*(object_ptr)top, 
			  *(object_ptr)pc[2], 
			  *(object_ptr)pc[3]);
		thread5();
		BREAK;
	    
	    case L_PASSIGN_SLICE:
		// temp contains pointer to sequence
		assign_slice_seq = (s1_ptr *)*(object_ptr)pc[1];
		*(object_ptr)pc[1] = 0; // preclude DeRef of C pointer
		goto las;
		
	    case L_ASSIGN_SLICE: /* var[i..j] = expr */
		assign_slice_seq = (s1_ptr *)pc[1]; /* extra parameter */
	      las:  
		tpc = pc;
		AssignSlice(*(object_ptr)pc[2], 
			    *(object_ptr)pc[3],  /* 3 args max for good code */
			    (s1_ptr)*(object_ptr)pc[4]);
		thread5();
		BREAK;
	    
	    case L_RHS_SLICE: /* rhs slice of a sequence a[i..j] */
		tpc = pc;
		rhs_slice_target = (object_ptr)pc[4];
		RHS_Slice((s1_ptr)*(object_ptr)pc[1], 
			  *(object_ptr)pc[2], 
			  *(object_ptr)pc[3]);
		thread5();
		BREAK;

	    case L_RIGHT_BRACE_N: /* form a sequence of any length */
		nvars = pc[1];
		pc += 2;
		tpc = pc;
		s1 = NewS1((long)nvars);
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
		tpc = pc;
		s1 = NewS1((long)2);
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
		thread2();
		BREAK;
	    
	    case L_GLOBAL_INIT_CHECK:
		pc += 2;
		if (*(object_ptr)pc[-1] != NOVALUE) {
		    *(pc - 2) = (int)opcode(NOP2);
		    thread();
		    BREAK;
		}
		tpc = pc;
		NoValue((symtab_ptr)pc[-1]);
		BREAK;

	    case L_PRIVATE_INIT_CHECK:
		pc += 2;
		if (*(object_ptr)pc[-1] != NOVALUE) {
		    thread();
		    BREAK;
		}
		tpc = pc;
		NoValue((symtab_ptr)pc[-1]);
		BREAK;

	    case L_INTEGER_CHECK:
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
		pc += 2;
		if (IS_ATOM(*(object_ptr)pc[-1])) {
		    thread();
		    BREAK;
		}
		RTFatalType(pc-1);
		BREAK;

	    case L_SEQUENCE_CHECK:
		pc += 2;
		if (IS_SEQUENCE(*(object_ptr)pc[-1])) {
		    thread();
		    BREAK;
		}
		RTFatalType(pc-1);
		BREAK;

	    case L_IS_AN_INTEGER:
		top = *(object_ptr)pc[1];
		if (IS_ATOM_INT(top))
		    top = ATOM_1;
		else if (IS_ATOM_DBL(top)) {
		    tpc = pc;
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
		top = *(object_ptr)pc[1];
		if (IS_ATOM(top)) 
		    top = ATOM_1;
		else 
		    top = ATOM_0;
		DeRefx(*(object_ptr)pc[2]);
		*(object_ptr)pc[2] = top;
		inc3pc();
		thread();
		BREAK;
		
	    case L_IS_A_SEQUENCE:
		top = *(object_ptr)pc[1];
		if (IS_SEQUENCE(top)) 
		    top = ATOM_1;
		else 
		    top = ATOM_0;
		DeRefx(*(object_ptr)pc[2]);
		*(object_ptr)pc[2] = top;
		inc3pc();
		BREAK;
	    
	    case L_IS_AN_OBJECT:
		DeRefx(*(object_ptr)pc[2]);
		*(object_ptr)pc[2] = ATOM_1;
		inc3pc();
		BREAK;

	    case L_PLENGTH:
		/* *pc[1] contains a pointer to the sequence */
		top = (object)**(object_ptr **)pc[1]; 
		goto len;

	    case L_LENGTH:
		/* *pc[1] is a sequence */
		top = *(object_ptr)pc[1];
	      len:  
		if (IS_SEQUENCE(top)) { 
		    top = SEQ_PTR(top)->length;
		    obj_ptr = (object_ptr)pc[2];
		    DeRefx(*obj_ptr);
		    *obj_ptr = top;
		    inc3pc();
		    thread();
		}
		else {
		    tpc = pc;
		    RTFatal("length of an atom is not defined");
		}
		BREAK;

		/* ---------- start of unary ops ----------------- */

	    case L_SQRT: 
		a = SQRT;
		goto unary;
	    case L_SIN:
		a = SIN;
		goto unary;
	    case L_COS:
		a = COS;
		goto unary;
	    case L_TAN:
		a = TAN;
		goto unary;
	    case L_ARCTAN:
		a = ARCTAN;
		goto unary;
	    case L_LOG:
		a = LOG;
		goto unary;
	    case L_NOT_BITS:
		a = NOT_BITS;
		goto unary;
	    
	    case L_FLOOR:
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
		START_UNARY_OP
		if (top == ATOM_0)
		    top++;
		else
		    top = ATOM_0;
		END_UNARY_OP(NOT)
		thread();
		BREAK;

	    case L_NOT_IFW:
		top = *(object_ptr)pc[1]; 
		if (IS_ATOM_INT(top)) {
		    if (top == ATOM_0) {
			inc3pc();
			thread();
			pc++; /* dummy */
			BREAK;
		    }
		    else {
			pc = (int *)pc[2]; 
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
		START_UNARY_OP
		if (top == MININT) {
		    tpc = pc; 
		    top = (object)NewDouble((double)-MININT_VAL);
		}
		else
		    top = -top;
		END_UNARY_OP(UMINUS)
		thread();
		BREAK;

	    case L_RAND:
		START_UNARY_OP
		tpc = pc; 
		if (INT_VAL(top) <= 0) {
		    RTFatal("argument to rand() must be >= 1");
		}
		top = MAKE_INT((good_rand() % ((unsigned)INT_VAL(top))) + 1);
		END_UNARY_OP(RAND)
		thread();
		BREAK;


		/* --------- start of binary ops ----------*/
	    case L_PLUS:    
		START_BIN_OP
		    /* INT:INT case */
		    top = INT_VAL(a) + INT_VAL(top);
		    // mwl: gcc 4.1 doesn't do this right unless you do the unsigned casts:
		    if ((long)((unsigned long)top + (unsigned long)HIGH_BITS) >= 0) {
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
			temp_d.dbl = (double)INT_VAL(v);
			top = Dadd(&temp_d, DBL_PTR(top));
			goto aresult;
		    }
		    else if (IS_ATOM_DBL(a)) { // true if a is INT - careful!
			if (IS_ATOM_INT(top)) {
			    v = top;
			    temp_d.dbl = (double)INT_VAL(v);
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
		/* we know that the inputs and the output must be integers */
		START_BIN_OP_I
		top = INT_VAL(a) + INT_VAL(top);
		if ((long)((unsigned long)top + (unsigned long)HIGH_BITS) >= 0) { 
		    goto dblplus_i;
		}
	    contplus_i:  
		END_BIN_OP_I
		BREAK;

	    case L_MINUS:
		START_BIN_OP
		    /* INT:INT case L_*/
		    top = INT_VAL(a) - INT_VAL(top);
		    if ((long)((unsigned long)top + (unsigned long)HIGH_BITS) >= 0) {
			tpc = pc;
			v = top;
			top = NewDouble((double)v);
		    }
		    STORE_TOP_I
		}
		else {
		    /* non INT:INT cases */
		    tpc = pc;
		    if (IS_ATOM_INT(a) && IS_ATOM_DBL(top)) { 
			v = a;
			temp_d.dbl = (double)INT_VAL(v);
			top = Dminus(&temp_d, DBL_PTR(top));
			goto aresult;
		    }
		    else if (IS_ATOM_DBL(a)) {
			if (IS_ATOM_INT(top)) {
			    v = top;
			    temp_d.dbl = (double)INT_VAL(v);
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
		START_BIN_OP_I
		top = a - top;
		if ((long)((unsigned long)top + (unsigned long)HIGH_BITS) >= 0) {
		    tpc = pc;
		    b = top;
		    top = NewDouble((double)b);
		    *obj_ptr = top;
		    inc3pc();
		    RTFatalType(pc);
		}
		END_BIN_OP_I
		BREAK;
	    
	   case L_MULTIPLY:
		START_BIN_OP
		    /* INT:INT case L_*/
		    c = a;
		    b = top; 
		    
		    if (c == (short)c) {
			/* c is 16-bit */
			if ((b <= INT15 && b >= -INT15) || 
			    (c == (char)c && b <= INT23 && b >= -INT23) ||
			    (b == (short)b && c <= INT15 && c >= -INT15)) {
			    top = MAKE_INT(c * b);
			}
			else {
			    tpc = pc;
			    top = (object)NewDouble(c * (double)b);
			}
		    }
		    else if (b == (char)b && c <= INT23 && c >= -INT23) {
			/* b is 8-bit, c is 23-bit */
			top = MAKE_INT(c * b);
		    }
		    else {
			tpc = pc;
			top = (object)NewDouble(c * (double)b);
		    }
		    STORE_TOP_I
		}
		else {
		    /* non INT:INT cases 
		       - what if a is int and top is sequence? */
		    tpc = pc;
		    if (IS_ATOM_INT(a) && IS_ATOM_DBL(top)) { 
			v = a;
			temp_d.dbl = (double)INT_VAL(v);
			top = Dmultiply(&temp_d, DBL_PTR(top));
			goto aresult;
		    }
		    else if (IS_ATOM(a)) {   // was IS_ATOM_DBL
			if (IS_ATOM_INT(top)) {
			    v = top;
			    temp_d.dbl = (double)INT_VAL(v);
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
		START_BIN_OP
		c = INT_VAL(a);
		tpc = pc;
		if ((b = INT_VAL(top)) == 0) 
		    RTFatal("attempt to divide by 0");
		if (c % b != 0) /* could try in-line DIV call here for speed */
		    top = (object)NewDouble((double)c / b);
		else
		    top = MAKE_INT(c / b);
		END_BIN_OP(DIVIDE)
		BREAK;


	    case L_REMAINDER:
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
		START_BIN_OP
		top = MAKE_INT(INT_VAL(a) & INT_VAL(top));
		END_BIN_OP(AND_BITS)
		BREAK;
	    
	    case L_OR_BITS:
		START_BIN_OP
		top = MAKE_INT(INT_VAL(a) | INT_VAL(top));
		END_BIN_OP(OR_BITS)
		BREAK;
	    
	    case L_XOR_BITS:
		START_BIN_OP
		top = MAKE_INT(INT_VAL(a) ^ INT_VAL(top));
		END_BIN_OP(XOR_BITS)
		BREAK;
		
	    case L_POWER:
		START_BIN_OP
		tpc = pc;
		top = power(INT_VAL(a), INT_VAL(top));
		END_BIN_OP(POWER)
		BREAK;


	    case L_DIV2:
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
			temp_dbl = floor((double)v / (double)b);
			if (fabs(temp_dbl) <= MAXINT_DBL)
			    b = (long)temp_dbl;
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
		START_BIN_OP
		if (a == top)
		    top = ATOM_1;
		else
		    top = ATOM_0;
		END_BIN_OP(EQUALS)
		BREAK;

	    case L_EQUALS_IFW:
		START_BIN_OP
		if (a == top)
		END_BIN_OP_IFW(EQUALS)
		BREAK;

	    case L_EQUALS_IFW_I:
		START_BIN_OP_I
		if (a == top)
		END_BIN_OP_IFW_I
		BREAK;

	    case L_LESS:
		START_BIN_OP
		if (a < top)
		    top = ATOM_1;
		else
		    top = ATOM_0;
		END_BIN_OP(LESS)
		BREAK;

	    case L_LESS_IFW:
		START_BIN_OP
		if (a < top)
		END_BIN_OP_IFW(LESS)
		BREAK;

	    case L_LESS_IFW_I:
		START_BIN_OP_I
		if (a < top)
		END_BIN_OP_IFW_I
		BREAK;

	    case L_GREATER:
		START_BIN_OP
		if (a > top)
		    top = ATOM_1;
		else
		    top = ATOM_0;
		END_BIN_OP(GREATER)
		BREAK;

	    case L_GREATER_IFW:
		START_BIN_OP
		if (a > top)
		END_BIN_OP_IFW(GREATER)
		BREAK;

	    case L_GREATER_IFW_I:
		START_BIN_OP_I
		if (a > top)
		END_BIN_OP_IFW_I
		BREAK;

	    case L_NOTEQ:
		START_BIN_OP
		if (a != top)
		    top = ATOM_1;
		else
		    top = ATOM_0;
		END_BIN_OP(NOTEQ)
		BREAK;

	    case L_NOTEQ_IFW:
		START_BIN_OP
		if (a != top)
		END_BIN_OP_IFW(NOTEQ)
		BREAK;

	    case L_NOTEQ_IFW_I:
		START_BIN_OP_I
		if (a != top)
		END_BIN_OP_IFW_I
		BREAK;

	    case L_LESSEQ:
		START_BIN_OP
		if (a <= top)
		    top = ATOM_1;
		else
		    top = ATOM_0;
		END_BIN_OP(LESSEQ)
		BREAK;

	    case L_LESSEQ_IFW:
		START_BIN_OP
		if (a <= top)
		END_BIN_OP_IFW(LESSEQ)
		BREAK;

	    case L_LESSEQ_IFW_I:
		START_BIN_OP_I
		if (a <= top)
		END_BIN_OP_IFW_I
		BREAK;

	    case L_GREATEREQ:
		START_BIN_OP
		if (a >= top)
		    top = ATOM_1;
		else
		    top = ATOM_0;
		END_BIN_OP(GREATEREQ)
		BREAK;

	    case L_GREATEREQ_IFW:
		START_BIN_OP
		if (a >= top)
		END_BIN_OP_IFW(GREATEREQ)
		BREAK;

	    case L_GREATEREQ_IFW_I:
		START_BIN_OP_I
		if (a >= top)
		END_BIN_OP_IFW_I
		BREAK;

	    case L_AND:
		START_BIN_OP
		if (a != ATOM_0 && top != ATOM_0)
		    top = ATOM_1;
		else
		    top = ATOM_0;
		END_BIN_OP(AND)
		BREAK;

	    case L_SC1_AND:
		top = *(object_ptr)pc[1];
		if (IS_ATOM_INT(top)) {
		    if (top == ATOM_0) {
			DeRefx(*(object_ptr)pc[2]);
			*(object_ptr)pc[2] = ATOM_0;
			pc = (int *)pc[3];
			thread();
			BREAK;
		    }   
		}
		else if (IS_ATOM_DBL(top)) {
		    if (DBL_PTR(top)->dbl == 0.0) {
			DeRefx(*(object_ptr)pc[2]);
			*(object_ptr)pc[2] = ATOM_0;                
			pc = (int *)pc[3];
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
		top = *(object_ptr)pc[1];
		if (IS_ATOM_INT(top)) {
		    if (top == ATOM_0) {
			pc = (int *)pc[3];
			thread();
			BREAK;
		    }   
		}
		else if (IS_ATOM_DBL(top)) {
		    if (DBL_PTR(top)->dbl == 0.0) {
			pc = (int *)pc[3];
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
	    case L_SC2_AND:
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
		START_BIN_OP
		if ((a != ATOM_0) != (top != ATOM_0))
		    top = ATOM_1;
		else
		    top = ATOM_0;
		END_BIN_OP(XOR)
		BREAK;

	    case L_OR:
		START_BIN_OP
		if (a != ATOM_0 || top != ATOM_0)
		    top = ATOM_1;
		else
		    top = ATOM_0;
		END_BIN_OP(OR)
		BREAK;

	    case L_SC1_OR:
		top = *(object_ptr)pc[1];
		if (IS_ATOM_INT(top)) {
		    if (top != ATOM_0) {
			DeRefx(*(object_ptr)pc[2]);
			*(object_ptr)pc[2] = ATOM_1;
			pc = (int *)pc[3];
			thread();
			BREAK;
		    }   
		}
		else if (IS_ATOM_DBL(top)) {
		    if (DBL_PTR(top)->dbl != 0.0) {
			DeRefx(*(object_ptr)pc[2]);
			*(object_ptr)pc[2] = ATOM_1;                
			pc = (int *)pc[3];
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
		top = *(object_ptr)pc[1];
		if (IS_ATOM_INT(top)) {
		    if (top != ATOM_0) {
			pc = (int *)pc[3];
			thread();
			BREAK;
		    }   
		}
		else if (IS_ATOM_DBL(top)) {
		    if (DBL_PTR(top)->dbl != 0.0) {
			pc = (int *)pc[3];
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
		/* integer loop */
		obj_ptr = (object_ptr)pc[5]; /* loop var */
		c = *(object_ptr)pc[3]; /* initial value */
		*obj_ptr = c;
		top = *(object_ptr)pc[1];    /* inc */
		a = *(object_ptr)pc[2];      /* limit */
	      intloop:
		if ((long)((unsigned long)a + (unsigned long)top + (unsigned long)HIGH_BITS) < 0) { 
		    /* purely integer loop */
		    if ((top >= 0)) {
			/* going up */
			if (c > a) {
			    pc = (int *)pc[6];
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
			    pc = (int *)pc[6];
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
			pc = (int *)pc[6];  /* exit loop - 0 iterations */
			BREAK;
		    }
		    else {
			i = going_up ? ENDFOR_UP : ENDFOR_DOWN;
			/* Ref(top); inc */
			/* Ref(a);   limit */
		    }
		}
		/* we're going in - patch the ENDFOR opcode */
		patch = (opcode_type *) ((int *)pc[6] - 5);
		i = (int)opcode(i);
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
		obj_ptr = (object_ptr)pc[3]; /* loop var */
		top = *obj_ptr - 1;
		if (top < *(object_ptr)pc[2]) {  /* limit */
		    thread5();  /* exit loop */
		}
		else {
		    *obj_ptr = top;
		    pc = (int *)pc[1];  /* loop again */
		    thread();
		}
		BREAK;

	    case L_ENDFOR_INT_DOWN:
		obj_ptr = (object_ptr)pc[3];  /* loop var */
		top = *obj_ptr + *(object_ptr)pc[4]; /* increment */
		if (top < *(object_ptr)pc[2]) { /* limit */
		    thread5();  /* exit loop */
		}
		else {
		    *obj_ptr = top;
		    pc = (int *)pc[1]; /* loop again */
		    thread();
		}
		BREAK;

	    case L_ENDFOR_GENERAL:
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
		    pc = (int *)pc[1]; /* loop again */
		    thread();
		}
		BREAK;

	    case L_ENDFOR_DOWN:
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
		    pc = (int *)pc[1]; /* loop again */
		    thread();
		}
		BREAK;


	    // Call by handle to procedure, function or type
	    case L_CALL_FUNC: 
		cf = TRUE;
	    case L_CALL_PROC: 
		tpc = pc;
		if (expr_top >= expr_limit) {
		    expr_max = BiggerStack();
		    expr_limit = expr_max - 3;
		} 
		
		// get the routine symtab_ptr:
		a = get_pos_int("call_proc/call_func", *(object_ptr)pc[1]); 
		if ((unsigned)a >= e_routine_next) {
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
			sprintf(TempBuff, "%s() does not return a value",
				sub->name);
			RTFatal(TempBuff);
		    }
		}
		else {
		    if (sub->token != PROC) {
			sprintf(TempBuff, 
			  "the value returned by %s() must be assigned or used",
				sub->name);
			RTFatal(TempBuff);
		    }
		}
		
		if (IS_ATOM(a)) {
		    RTFatal("argument list must be a sequence");
		}
		a = (object)SEQ_PTR(a);
		
		// if length is huge it will be rejected here,
		// so max_stack_per_call will protect against stack overflow
		if (sub->u.subp.num_args != ((s1_ptr)a)->length) {
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
		*expr_top++ = sub;             // push sub symtab pointer
		pc = sub->u.subp.code;         // start executing the sub 
		thread();
		BREAK;

	    case L_PROC:  // Normal subroutine call
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
		    while (obj_ptr < (object_ptr)a) {
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
		*expr_top++ = sub;             // push sub symtab pointer 
		pc = sub->u.subp.code;         // start executing the sub
		thread();
		BREAK;

	    case L_CALL_BACK_RETURN: /* return from a call-back */
		return;
	    
	    case L_RETURNT: /* end of execution - falling off the end */
		tpc = pc;  /* we need this to be different from CALL_BACK_RETURN */
		Cleanup(0);
		return;
		
	    case L_BADRETURNF:  /* shouldn't reach here */
		tpc = pc;
		RTFatal("attempt to exit a function without returning a value");
		BREAK;

	    case L_RETURNF: /* return from function */
		result_val = *(object_ptr)pc[2]; /* the return value */
		Ref(result_val);
		// record the place to put the return value 
		result_ptr = (object_ptr)*((int *)expr_top[-2] - 1);

	    case L_RETURNP: /* return from procedure */
		sub = ((symtab_ptr)pc[1]);
		sym = sub->next; /* first private var */
		
		/* free the privates and set to NOVALUE */
		while (sym && sym->scope <= S_PRIVATE) {
		    DeRef(sym->obj);
		    sym->obj = NOVALUE; // not actually needed for params
		    sym = sym->next;
		}
		    
		/* free the temps and set to NOVALUE */ 
		sym = sub->u.subp.temps;
		while (sym != NULL) {
		    DeRef(sym->obj);
		    sym->obj = NOVALUE;
		    sym = sym->next;
		}
		
		// vacating this routine
		sub->u.subp.resident_task = -1;

		tpc = pc;
		    
		if (expr_top > expr_stack+3) {
		    // stack is not empty
		    pc = (int *)expr_top[-2]; 
		    expr_top -= 2;
		    top = expr_top[-1]; 
		    restore_privates((symtab_ptr)top);

		    if (result_ptr != NULL) {
			// store function result
			top = *result_ptr;
			*result_ptr = result_val; //was important not to use "a"
			DeRef(top);
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

	    case L_ROUTINE_ID:
		top = (object)pc[1];    // CurrentSub
		a = *(object_ptr)pc[3]; // routine name sequence
		SymTabLen = pc[2]; // avoid > 3 args
		b = RoutineId((symtab_ptr)top, a, pc[4]);
		DeRefx(*(object_ptr)pc[5]);
		*(object_ptr)pc[5] = b;
		pc += 6;
		/*thread();*/
		BREAK;

	    case L_APPEND:
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

	    case L_CONCAT:
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
		Concat((object_ptr)pc[3], b, (s1_ptr)top);
		pc += 4;  // WATCOM thread() fails
		BREAK;
	    
	    case L_CONCAT_N:
		/* concatenate 3 or more items */
		nvars = pc[1];
		tpc = pc;
		Concat_Ni((object_ptr)pc[nvars+2], (object_ptr *)(pc+2), nvars);
		pc += nvars + 3; // WATCOM thread() fails
		BREAK;
	    
	    case L_REPEAT:
		tpc = pc;
		top = Repeat(*(object_ptr)pc[1], *(object_ptr)pc[2]);
		DeRef(*(object_ptr)pc[3]);
		*(object_ptr)pc[3] = top;               
		pc += 4;
		thread();
		BREAK;

	    case L_DATE:
		tpc = pc;
		top = Date(); 
		DeRef(*(object_ptr)pc[1]);
		*(object_ptr)pc[1] = top;
		pc += 2;
		BREAK;

	    case L_TIME:
		tpc = pc;
		top = NewDouble(current_time());
		DeRef(*(object_ptr)pc[1]);
		*(object_ptr)pc[1] = top;
		pc += 2;
		thread();
		BREAK;


#ifdef HEAP_CHECK
	    case L_SPACE_USED:
		top = MAKE_INT(bytes_allocated);
		DeRef(*(object_ptr)pc[1]);
		*(object_ptr)pc[1] = top;
		pc += 2;                
		BREAK;
#endif
	    case L_POSITION:
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

	    case L_FIND:
		tpc = pc;
		a = find(*(object_ptr)pc[1], (s1_ptr)*(object_ptr)pc[2]);
		top = MAKE_INT(a);
		DeRef(*(object_ptr)pc[3]);
		*(object_ptr)pc[3] = top;               
		pc += 4;
		thread();
		BREAK;

	    case L_MATCH:
		tpc = pc;
		top = MAKE_INT(e_match((s1_ptr)*(object_ptr)pc[1], 
				     (s1_ptr)*(object_ptr)pc[2]));
		DeRef(*(object_ptr)pc[3]);
		*(object_ptr)pc[3] = top;               
		pc += 4;
		thread();
		BREAK;


	    case L_PEEK4U:
		b = 1;
		goto peek4s1;
		
	    case L_PEEK4S:
		b = 0;
	     peek4s1:
		a = *(object_ptr)pc[1]; /* the address */
		tpc = pc;  // in case of machine exception
		top = do_peek4(a, b, pc);
		DeRefx(*(object_ptr)pc[2]);
		*(object_ptr)pc[2] = top;
		inc3pc();
		thread();
		BREAK;

	    case L_PEEK:
		a = *(object_ptr)pc[1]; /* the address */
		tpc = pc;  // in case of machine exception
		
		/* check address */
		if (IS_ATOM_INT(a)) {
		    poke_addr = (unsigned char *)INT_VAL(a);
		}
		else if (IS_ATOM(a)) {
		    poke_addr = (unsigned char *)(unsigned long)
				(DBL_PTR(a)->dbl);
		}
		else {
		    /* a sequence: {addr, nbytes} */
		    s1 = SEQ_PTR(a);                                        
		    i = s1->length;
		    if (i != 2) {
			RTFatal(
		  "argument to peek() must be an atom or a 2-element sequence");
		    }
		    poke_addr = (unsigned char *)get_pos_int("peek", *(s1->base+1));
#ifdef EDOS                    
		    if (current_screen != MAIN_SCREEN && 
			(unsigned)poke_addr >= (unsigned)0xA0000 && 
			(unsigned)poke_addr < (unsigned)0xC0000) 
			MainScreen();
#endif                  
		    i = get_pos_int("peek", *((s1->base)+2)); /* length */
		    if (i < 0)
			RTFatal("number of bytes to peek is less than 0");
		    s1 = NewS1(i);
		    obj_ptr = s1->base;
		    while (--i >= 0) {
			obj_ptr++;
#ifdef EDJGPP                       
			if ((unsigned)poke_addr <= LOW_MEMORY_MAX)
			    *obj_ptr = _farpeekb(_go32_info_block.selector_for_linear_memory, 
						   (unsigned)poke_addr);
			else    
#endif                      
			    *obj_ptr = *poke_addr; 
			poke_addr++;
		    }
		    DeRef(*(object_ptr)pc[2]);
		    *(object_ptr)pc[2] = (object)MAKE_SEQ(s1);           
		    inc3pc();
		    thread();
		}
#ifdef EDOS
		if (current_screen != MAIN_SCREEN && 
		    (unsigned)poke_addr >= (unsigned)0xA0000 && 
		    (unsigned)poke_addr < (unsigned)0xC0000) 
		    MainScreen();
#endif              
		DeRefx(*(object_ptr)pc[2]);
#ifdef EDJGPP                       
		if ((unsigned)poke_addr <= LOW_MEMORY_MAX)
		    *(object_ptr)pc[2] = _farpeekb(_go32_info_block.selector_for_linear_memory, 
						   (unsigned)poke_addr);
		else    
#endif                      
		    *(object_ptr)pc[2] = *poke_addr;               
		inc3pc();
		thread();
		BREAK;
	    
	    case L_POKE4:
		a = *(object_ptr)pc[1];   /* address */
		top = *(object_ptr)pc[2]; /* byte value */
		tpc = pc;
		do_poke4(a, top);
		inc3pc();
		thread();
		BREAK;

	    case L_POKE:
		a = *(object_ptr)pc[1];   /* address */
		top = *(object_ptr)pc[2]; /* byte value */
		tpc = pc;  // in case of machine exception

		/* check address */
		if (IS_ATOM_INT(a)) {
		    poke_addr = (unsigned char *)a;
		}
		else if (IS_ATOM(a)) {
		    poke_addr = (unsigned char *)(unsigned long)
				(DBL_PTR(a)->dbl);
		}
		else {
		    tpc = pc;
		    RTFatal("first argument to poke must be an atom");
		}
#ifdef EDOS
		if (current_screen != MAIN_SCREEN && 
		    (unsigned)poke_addr >= (unsigned)0xA0000 && 
		    (unsigned)poke_addr < (unsigned)0xC0000)
		    MainScreen();
#endif              
		/* the following 6 lines bumped top out of a register */
		b = top;
		
		if (IS_ATOM_INT(b)) {
#ifdef EDJGPP       
		    if ((unsigned)poke_addr <= LOW_MEMORY_MAX)
			_farpokeb(_go32_info_block.selector_for_linear_memory,
			   (unsigned long)poke_addr, (unsigned char)b);
		    else
#endif      
			*poke_addr = (unsigned char)b;
		}
		else if (IS_ATOM(b)) {
#ifdef EDJGPP       
		    if ((unsigned)poke_addr <= LOW_MEMORY_MAX)
			_farpokeb(_go32_info_block.selector_for_linear_memory,
			(unsigned long)poke_addr, (unsigned char)DBL_PTR(b)->dbl);
		    else
#endif      
			*poke_addr = (signed char)DBL_PTR(b)->dbl;
		}
		else {
		    /* second arg is sequence */
		    s1 = SEQ_PTR(b);
		    obj_ptr = s1->base;
		    while (TRUE) { 
			b = *(++obj_ptr); 
			if (IS_ATOM_INT(b)) {
#ifdef EDJGPP       
			    if ((unsigned)poke_addr <= LOW_MEMORY_MAX)
				_farpokeb(_go32_info_block.selector_for_linear_memory,
				(unsigned long)poke_addr++, (unsigned char)b);
			    else
#endif      
				*poke_addr++ = (unsigned char)b;
			}
			else if (IS_ATOM(b)) {
			    if (b == NOVALUE)
				break;
#ifdef EDJGPP       
			    if ((unsigned)poke_addr <= LOW_MEMORY_MAX)
				_farpokeb(_go32_info_block.selector_for_linear_memory,
				(unsigned long)poke_addr++, (unsigned char)DBL_PTR(b)->dbl);
			    else
#endif      
				*poke_addr++ = (signed char)DBL_PTR(b)->dbl;
			}
			else {
			    RTFatal(
			    "sequence to be poked must only contain atoms");
			}
		    }
		}
		inc3pc();
		thread();
		BREAK;

	    case L_MEM_COPY:
		tpc = pc;
		memory_copy(*(object_ptr)pc[1], 
			    *(object_ptr)pc[2],
			    *(object_ptr)pc[3]);
		pc += 4;                
		thread();
		BREAK;
	    
	    case L_MEM_SET:
		tpc = pc;
		memory_set(*(object_ptr)pc[1], 
			   *(object_ptr)pc[2],
			   *(object_ptr)pc[3]);
		pc += 4;                
		thread();
		BREAK;
	    
	    case L_PIXEL:
		tpc = pc;
		Pixel(*(object_ptr)pc[1],
		      *(object_ptr)pc[2]);
		inc3pc();
		thread();
		BREAK;
	    
	    case L_GET_PIXEL:
		tpc = pc;
		a = Get_Pixel(*(object_ptr)pc[1]);
		DeRef(*(object_ptr)pc[2]);
		*(object_ptr)pc[2] = a;
		inc3pc();
		thread();
		BREAK;
	  
	    case L_CALL:
		a = *(object_ptr)pc[1];
		tpc = pc;   // for better profiling and machine exception
		/* check address */
		if (IS_ATOM_INT(a)) {
		    sub_addr = (void(*)())INT_VAL(a);
		}
		else if (IS_ATOM(a)) {
		    sub_addr = (void(*)())(unsigned long)(DBL_PTR(a)->dbl);
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
		tpc = pc;
		if (current_screen != MAIN_SCREEN)
		    MainScreen();
		system_call(*(object_ptr)pc[1], *(object_ptr)pc[2]);
		inc3pc();
		BREAK;
		
	    case L_SYSTEM_EXEC:
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
		tpc = pc;
		top = EOpen(*(object_ptr)pc[1], 
			    *(object_ptr)pc[2]);
		DeRef(*(object_ptr)pc[3]);
		*(object_ptr)pc[3] = top;
		pc += 4;
		thread(); 
		BREAK;

	    case L_CLOSE:
		tpc = pc;
		EClose(*(object_ptr)pc[1]);
		pc += 2;
		thread();
		BREAK;

	    case L_GETC:  /* read a character from a file */
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
#ifndef EDOS
		if (last_r_file_ptr == stdin) {
#ifdef EWINDOWS
		    // In WIN32 this is needed before 
		    // in_from_keyb is set correctly
		    show_console();  
#endif
		    if (in_from_keyb) {
#ifdef ELINUX
#ifdef EGPM
			b = mgetch(TRUE); // echo the character
#else
			echo_wait();
			b = getc(stdin);
#endif                      
#else
			b = wingetch();
#endif                  
		    }
		    else {
#ifdef ELINUX                       
			b = getc(last_r_file_ptr);
#else                   
			b = mygetc(last_r_file_ptr); 
#endif
		    }
		}
		else
#endif
#ifdef ELINUX
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
		tpc = pc;
		top = EGets(*(object_ptr)pc[1]);
		DeRef(*(object_ptr)pc[2]);
		*(object_ptr)pc[2] = top;
		inc3pc();
		thread();
		BREAK;

	    case L_PLATFORM: // only shrouded code needs this (for portability)
		DeRef(*(object_ptr)pc[1]);
#ifdef ELINUX
		top = 3;  // Linux
#endif
#ifdef EWINDOWS
		top = 2;  // WIN32
#endif
#ifdef EDOS
		top = 1;  // DOS32
#endif
		
		*(object_ptr)pc[1] = top;
		pc += 2;
		thread();
		BREAK;
	    
	    case L_GET_KEY: /* read an immediate key (if any) from the keyboard 
			     or return -1 */
		tpc = pc;
#if defined(EWINDOWS)
		show_console();
#endif
		if (current_screen != MAIN_SCREEN) {
		    MainScreen();
		}
		top = MAKE_INT(get_key(FALSE));
		if (top == ATOM_M1 && TraceOn) {
#ifdef ELINUX
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
		tpc = pc++;
		if (current_screen != MAIN_SCREEN) {
		    tpc = pc;
		    MainScreen();
		}
		ClearScreen();
		BREAK;

	    case L_PUTS:
		tpc = pc;
		EPuts(*(object_ptr)pc[1], *(object_ptr)pc[2]);
		inc3pc();
		tpc = pc;
		BREAK;

	    case L_QPRINT:
		i = 1;
		goto nextp;
	    case L_PRINT:
		i = 0;
	    nextp:
		tpc = pc;
		a = *(object_ptr)pc[1];  /* file number */
		top = *(object_ptr)pc[2];
		StdPrint(a, top, i);
		inc3pc();
		BREAK;

	    case L_PRINTF:
		/* file number, format string, value */
		tpc = pc;
		file_no = *(object_ptr)pc[1];
		EPrintf(file_no, 
			(s1_ptr)*(object_ptr)pc[2], 
			(s1_ptr)*(object_ptr)pc[3]);
		pc += 4;
		BREAK;

	    case L_SPRINTF:
		/* format string, value */
		tpc = pc;
		top = EPrintf(DOING_SPRINTF, 
			(s1_ptr)*(object_ptr)pc[1], 
			(s1_ptr)*(object_ptr)pc[2]);
		DeRef(*(object_ptr)pc[3]);
		*(object_ptr)pc[3] = top;
		pc += 4;
		thread();
		BREAK;

	    case L_COMMAND_LINE:
		tpc = pc;
		top = Command_Line();
		DeRef(*(object_ptr)pc[1]);
		*(object_ptr)pc[1] = top;
		pc += 2;
		thread();
		BREAK;

	    case L_GETENV:
		tpc = pc;
		top = EGetEnv((s1_ptr)*(object_ptr)pc[1]);
		DeRef(*(object_ptr)pc[2]);
		*(object_ptr)pc[2] = top;
		inc3pc();
		thread();
		BREAK;

	    case L_MACHINE_FUNC:
		tpc = pc;
		top = machine(*(object_ptr)pc[1], 
			      *(object_ptr)pc[2]);
		DeRef(*(object_ptr)pc[3]);
		*(object_ptr)pc[3] = top;
		pc += 4;
		thread();
		BREAK;

	    case L_MACHINE_PROC:
		tpc = pc;
		machine(*(object_ptr)pc[1], *(object_ptr)pc[2]);
		inc3pc();
		thread();
		BREAK;
	 
	    case L_C_FUNC:
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
		tpc = pc;
		task_schedule(*(object_ptr)pc[1], 
			      *(object_ptr)pc[2]);
		inc3pc();
		thread();
		BREAK;
	    
	    case L_TASK_YIELD:
		tpc = pc;
		task_yield();
		pc = tpc;
		thread();
		BREAK;
	    
	    case L_TASK_SELF:
		top = (object)pc[1];
		DeRef(*(object_ptr)top);
		*(object_ptr)top = NewDouble(tcb[current_task].tid);
		pc += 2;
		thread();
		BREAK;
	    
	    case L_TASK_SUSPEND:
		tpc = pc;
		task_suspend(*(object_ptr)pc[1]);
		pc += 2;
		thread();
		BREAK;
	    
	    case L_TASK_LIST:
		tpc = pc;
		top = task_list();
		a = pc[1];
		DeRef(*(object_ptr)a);
		*(object_ptr)a = top;
		pc += 2;
		thread(); // causes problem? - ok now
		BREAK;
	    
	    case L_TASK_STATUS:
		tpc = pc;
		top = task_status(*(object_ptr)pc[1]);
		a = pc[2];
		DeRef(*(object_ptr)a);
		*(object_ptr)a = top;
		inc3pc();
		thread();
		BREAK;
	    
	    case L_TASK_CLOCK_STOP:
		tpc = pc;
		task_clock_stop();
		pc += 1;
		BREAK;
	    
	    case L_TASK_CLOCK_START:
		tpc = pc;
		task_clock_start();
		pc += 1;
		BREAK;


	    /* tracing/profiling ops */

	    case L_STARTLINE:
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
			char one_line[120];

			sprintf(one_line, "%.20s:%d\t%.80s",
				name_ext(file_name[slist[top].file_no]),
				slist[top].line,
				(slist[top].options & (OP_PROFILE_STATEMENT | 
						       OP_PROFILE_TIME)) ? 
				     slist[top].src+4 :
				     slist[top].src);
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
			b = top > TraceBeyond && i == TraceStack ||
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
		tpc = pc;
		top = *(object_ptr)pc[1];
		trace_command(top);
		pc += 2;
		BREAK;

	    case L_PROFILE:
		tpc = pc;
		top = *(object_ptr)pc[1];
		profile_command(top);
		pc += 2;
		BREAK;

	    case L_DISPLAY_VAR: /* display variable name and value */
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
		BREAK;
#ifdef INT_CODES
	}
#else
#if !defined(ELINUX) && !defined(EDJGPP)
	}
#endif
#endif
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
    top = NewDouble((double)v);
    goto contplus;

dblplus_i:
    tpc = pc;
    b = top;
    top = NewDouble((double)b);
    *obj_ptr = top;
    inc3pc();
    RTFatalType(pc);
    goto contplus_i;
}

void AfterExecute()
// Address of this routine is used by time profiler
{
}



