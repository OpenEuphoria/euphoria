#ifndef EUPHORIA_H_
#define EUPHORIA_H_

#ifdef EWINDOWS
#include <windows.h>
#endif

/* Euphoria
   C include file for Euphoria programs 
   that have been translated to C */

#undef _segment
#undef _self
#undef _dos_ds
#include <stdint.h>
#include <stdio.h>
#include <math.h>

/***************************************************************************
*
*
 32 bit number range:
  0X8      0XA      0XC      0XE      0X0      0X2      0X4      0X6      0X8
-4*2^29  -3*2^29  -2*2^29-1  -2^29   0*2^29   1*2^29   2*2^29   3*2^29 4*2^29 
   *--------*--------*--------*--------*--------*--------*--------*--------o
                     o NOVALUE = -2*2^29-1
		     o<-----------ATOM_INT---------[-2*2^29..4*2^29)------>o
	    |<----------------ATOM_DBL-------[-3*2^29..4*2^29)------------>o
-->|        |<-- IS_SEQUENCE [-4*2^29..-3*2^29)
-->|                 o<--- IS_DBL_OR_SEQUENCE [-4*2^29..-2*2^29-1)
-->|sequence|<-------
----------->| double |<-----------------------------------------------------
                     |<--------     integer    --------->|
   |<--------------------- object ---------------------->|		     
*
****************************************************************************/

#undef MININT

#if INTPTR_MAX == INT32_MAX

#define DBL_MASK     (uintptr_t)0xA0000000L
#define SEQ_MASK     (uintptr_t)0x80000000L
#define DS_MASK      (uintptr_t)0xE0000000L
#define MININT       (intptr_t) 0xC0000000L
#define MAXINT       (intptr_t) 0x3FFFFFFFL
#define NOVALUE      (intptr_t)0xbfffffffL
#define TOO_BIG_INT  (intptr_t)0x40000000L
#define HIGH_BITS    (intptr_t)0xC0000000L

#define EUFLOOR floor

#else

typedef int int128_t __attribute__((mode(TI)));

#define DBL_MASK     (uintptr_t)INT64_C( 0xA000000000000000 )
#define SEQ_MASK     (uintptr_t)INT64_C( 0x8000000000000000 )
#define DS_MASK      (uintptr_t)INT64_C( 0xE000000000000000 )
#define MININT       (intptr_t) INT64_C( 0xC000000000000000 )
#define MAXINT       (intptr_t) INT64_C( 0x3FFFFFFFFFFFFFFF )
#define NOVALUE      (intptr_t) INT64_C( 0xbfffffffffffffff )
#define TOO_BIG_INT  (intptr_t) INT64_C( 0x4000000000000000 )
#define HIGH_BITS    (intptr_t) INT64_C( 0xC000000000000000 )

#define EUFLOOR floorl

#endif

#define IS_ATOM_INT(ob)       (((intptr_t) (ob)) > NOVALUE)
#define IS_ATOM_INT_NV(ob)    ((intptr_t)(ob) >= NOVALUE)

#ifdef __GNUC__
#define MAKE_UINT(x) ((object)( \
						{ uintptr_t _x = x; \
							_x < (uintptr_t)TOO_BIG_INT \
							? _x : NewDouble((eudouble)_x);}))
#else
/* Watch for side effects */
#define MAKE_UINT(x) ((object)((uintptr_t)x < (uintptr_t)TOO_BIG_INT \
                          ? (uintptr_t)x : \
                            NewDouble((eudouble)(uintptr_t)x)))
#endif

/* these are obsolete */
/*
#define INT_VAL(x)        ((intptr_t)(x))
#define MAKE_INT(x)       ((object)(x))
*/

#define DBL_TO_OBJ(d)	((object)(int64_t)(d))


/* N.B. the following distinguishes DBL's from SEQUENCES -
   must eliminate the INT case first */
#define IS_ATOM_DBL(ob)         (((object)(ob)) >= (object)DBL_MASK)

#define IS_ATOM(ob)             (((object)(ob)) >= (object)DBL_MASK)
#define IS_SEQUENCE(ob)         (((object)(ob))  < (object)DBL_MASK)

#define ASEQ(s) (((uintptr_t)s & (uintptr_t)DS_MASK) == (uintptr_t)SEQ_MASK)

#define IS_DBL_OR_SEQUENCE(ob)  (((object)(ob)) < NOVALUE)


#define MININT_DBL ((eudouble)MININT)
#define MAXINT_DBL ((eudouble)MAXINT)
#define INT23      (object)0x003FFFFFL
#define INT16      (object)0x00007FFFL
#define INT15      (object)0x00003FFFL
#define INT31      (object)0x3FFFFFFFL
#define INT55      (intptr_t) INT64_C( 0x003fffffffffffff )
#define INT47      (intptr_t) INT64_C( 0x00003fffffffffff )
#define ATOM_M1    -1
#define ATOM_0     0
#define ATOM_1     1
#define ATOM_2     2

#undef MAKE_UINT
#define MAKE_UINT(x)	((object)((uintptr_t)x <= (uintptr_t)MAXINT  ? (uintptr_t)x : NewDouble((eudouble)(uintptr_t)x)))

#define LOW_MEMORY_MAX ((unsigned)0x0010FFEF)
#if INTPTR_MAX == INT32_MAX
typedef double eudouble;
#else
typedef long double eudouble;
#endif

typedef intptr_t object;
typedef object *object_ptr;

struct cleanup;
typedef struct cleanup *cleanup_ptr;
typedef void(*cleanup_func)(object);

struct cleanup {
	int type;
	union func_union{
		int rid;
		cleanup_func builtin;
	} func;
	cleanup_ptr next;
};

enum CLEANUP_TYPES {
	CLEAN_UDT,
	CLEAN_UDT_RT,
	CLEAN_PCRE,
	CLEAN_FILE
};

struct s1 {                        /* a sequence header block */
	object_ptr base;               /* pointer to (non-existent) 0th element */
#if INTPTR_MAX == INT32_MAX
	int length;                   /* number of elements */
	int ref;                      /* reference count */
	cleanup_ptr cleanup;           /* custom clean up when sequence is deallocated */
	int postfill;                 /* number of post-fill objects */
#else
	cleanup_ptr cleanup;           /* custom clean up when sequence is deallocated */
	intptr_t ref;                      /* reference count */
	intptr_t length;                   /* number of elements */
	intptr_t postfill;                 /* number of post-fill objects */
#endif
	
}; /* total 20 bytes */

struct d {                         /* a double precision number */
	eudouble dbl;                    /* double precision value */
#if INTPTR_MAX == INT32_MAX
	int ref;                      /* reference count */
#else
	intptr_t ref;                      /* reference count */
#endif
	cleanup_ptr cleanup;           /* custom clean up when sequence is deallocated */
}; /* total 16 bytes */

struct routine_list {
	char *name;
	object (*addr)();
	int seq_num;
	int file_num;
	short int num_args;
	short int convention;
	char scope;
	cleanup_ptr cleanup;
};

struct ns_list {
	char *name;
	int ns_num;
	int seq_num;
	int file_num;
};

typedef struct d  *d_ptr;
typedef struct s1 *s1_ptr;

#define MAKE_DBL(x) ( (object) (((uintptr_t)(x) >> 3) + DBL_MASK) )
#define DBL_PTR(ob) ( (d_ptr)  (((uintptr_t)(ob)) << 3) )
#define MAKE_SEQ(x) ( (object) (((uintptr_t)(x) >> 3) + SEQ_MASK) )
#define SEQ_PTR(ob) ( (s1_ptr) (((uintptr_t)(ob)) << 3) )


#define RefDS(a) ++(DBL_PTR(a)->ref)    
#define RefDSn(a,n) (DBL_PTR(a)->ref += n)    
#define Ref(a) if (IS_DBL_OR_SEQUENCE(a)) { RefDS(a); }
#define Refn(a,n) if (IS_DBL_OR_SEQUENCE(a)) { RefDSn(a,n); }

#define DeRefDS(a) if (--(DBL_PTR(a)->ref) == 0 ) { de_reference((s1_ptr)(a)); }
#define DeRefDSi(a) if (--(DBL_PTR(a)->ref) == 0 ) { de_reference_i((s1_ptr)(a)); }

#define DeRef(a) if (IS_DBL_OR_SEQUENCE(a)) { DeRefDS(a); }
#define DeRefi(a) if (IS_DBL_OR_SEQUENCE(a)) { DeRefDSi(a); }

#define UNIQUE(seq) (((s1_ptr)(seq))->ref == 1)

#define EF_READ 1

#define LESS       1
#define GREATEREQ  2
#define EQUALS     3
#define NOTEQ      4
#define LESSEQ     5
#define GREATER    6
#define NOT        7
#define AND        8
#define OR         9
#define MINUS     10
#define PLUS      11
#define UMINUS    12
#define MULTIPLY  13
#define DIVIDE    14
#define OR_BITS   24  
#define XOR_BITS  26
#define SQRT      41
#define NOT_BITS  51
#define AND_BITS  56
#define RAND      62
#define FLOOR_DIV 63
#define REMAINDER 71
#define POWER     72
#define ARCTAN    73
#define LOG       74
#define SIN       80
#define COS       81
#define TAN       82
#define FLOOR     83
#define XOR      152

struct replace_block {
	object_ptr copy_to;
	object_ptr copy_from;
	object_ptr start;
	object_ptr stop;
	object_ptr target;
};

typedef struct replace_block *replace_ptr;

object call_c(int,object,object);
object Command_Line();
void show_console();
object Dpower();
object Dand_bits();
object Dand();
object Dremainder();
void Cleanup();
void init_literal();
char **make_arg_cv();
object NewDouble(eudouble);
void DeRef5(object, object, object, object, object);
void de_reference(s1_ptr);
void de_reference_i(s1_ptr);
double current_time(void);
double floor(double);
double fabs(double);
object binary_op_a(int, object, object);
object binary_op(int, object, object);
void *which_file(object, int);
object unary_op(int, object);
object NewS1(intptr_t);
object compare(object, object);
intptr_t get_pos_int(char *, intptr_t);
object memory_set(object d, object v, object n);
object memory_copy(object d, object s, object n);
object EOpen(object, object, object);
void EClose(object);
object EPrintf(object, object, object);
void EPuts(object, object);
void Concat(object *, object, object);
void Concat_N(object *, object *, int);
void Append(object *, object, object);
void Prepend(object *, object, object);
object EGetEnv(object name);
void RHS_Slice(object, object, object);
object find(object, object);
object e_match(object, object);
void ctrace(char *);
object e_floor(object);
object DoubleToInt(object);
object machine(object, object);
object Repeat(object, object);
void RepeatElem(object*, object, int);
object SequenceCopy(s1_ptr);
object power(object, object);
object EGets(object);
void shift_args(int, char**);
object NewString(char *);
object e_log(object a);
object De_log(d_ptr a);
object e_sin(object a);
object De_sin(object a);
object e_cos(object a);
object De_cos(object a);
object e_tan(object a);
object De_tan(object a);
object e_arctan(object);
object De_arctan(object a);

int32_t good_rand();
#ifdef __GNUC__
#if !defined(EMINGW) && !defined(__MINGW32__) && !defined(__CYGWIN32__)
char *malloc(size_t);
#endif
#endif
void setran();
void eu_startup(struct routine_list *rl, struct ns_list *nl, char **ip,
				int cps, int clk);
void exit(int);
int CRoutineId(int, int, object);
object e_sqrt(object);
void AssignSlice(object, object, object);
void StdPrint(object, object, int);
void ClearScreen();
void Position(object, object);
object CommandLine(void);
void system_call(object, object);
void RTFatal(char *);

// be_alloc:
char *TransAlloc(unsigned long);

// be_decompress:
object decompress(uintptr_t c);

// be_runtime:
extern void *xstdin;
extern object *rhs_slice_target;
extern s1_ptr *assign_slice_seq;
#define IFILE FILE*
extern object last_w_file_no;
extern IFILE last_w_file_ptr;
extern object last_r_file_no;
extern IFILE last_r_file_ptr;
extern int insert_pos;
extern int trace_lines;

object find_from(object,object,object);
object e_match_from(object aobj, object bobj, object c);
void Tail(s1_ptr , object , object_ptr );
void Head(s1_ptr , object , object_ptr );
object Remove_elements(int start, int stop, int in_place );
s1_ptr Add_internal_space(object a,int at,int len);
object system_exec_call(object command, object wait);
s1_ptr Copy_elements(int start,s1_ptr source, int replace );
object Insert(object a,object b,int pos);
object calc_hash(object a, object b);
object Dor_bits(d_ptr a, d_ptr b);
object Dxor_bits(d_ptr a, d_ptr b);
object not_bits(object a);
object Dxor(object a, object b);
object Date();
cleanup_ptr ChainDeleteRoutine( cleanup_ptr old, cleanup_ptr prev );
cleanup_ptr DeleteRoutine( object e_index );
void DeRef1(object a);
void Replace(replace_ptr rb);
void UserCleanup(int);

// from be_task.h
extern int tcb_size;
extern int current_task;
extern double clock_period;
#ifdef EWINDOWS
#include <windows.h>

// Address to a fiber:
#define TASK_HANDLE LPVOID

#else

#include <pthread.h>

// PThread handle:
#define TASK_HANDLE pthread_t

#endif

struct interpreted_task{
	intptr_t *pc;         // program counter for this task
	object_ptr expr_stack; // call stack for this task
	object_ptr expr_max;   // current top limit of stack
	object_ptr expr_limit; // don't start a new routine above this
	object_ptr expr_top;   // stack pointer
	int stack_size;        // current size of stack
};

struct translated_task{
	TASK_HANDLE task;
	
};

// Task Control Block - sync with euphoria\include\euphoria.h
struct tcb {
	int rid;         // routine id
	double tid;      // external task id
	int type;        // type of task: T_REAL_TIME or T_TIME_SHARED
	int status;      // status: ST_ACTIVE, ST_SUSPENDED, ST_DEAD
	double start;    // start time of current run
	double min_inc;  // time increment for min
	double max_inc;  // time increment for max 
	double min_time; // minimum activation time
					 // or number of executions remaining before sharing
	double max_time; // maximum activation time (determines task order)
	int runs_left;   // number of executions left in this burst
	int runs_max;    // maximum number of executions in one burst
	int next;        // index of next task of the same kind
	object args;     // args to call task procedure with at startup
	
	int mode;  // TRANSLATED_TASK or INTERPRETED_TASK
	union task_impl {
		struct interpreted_task interpreted;
		struct translated_task translated;
	} impl;
	
};

extern struct tcb *tcb;

// TASK API:
void task_yield();
void task_schedule(object task, object sparams);
void task_suspend(object a);
object task_list();
object task_status(object a);
void task_clock_stop();
void task_clock_start();
object ctask_create(object r_id, object args);
void InitTask();
void terminate_task(int task);
void scheduler(double now);
double Wait(double t);

// be_w:
extern int in_from_keyb;
extern int TraceOn;
int check_has_console();
extern object eu_sizeof();
#endif
