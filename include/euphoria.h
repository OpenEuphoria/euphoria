#ifndef EUPHORIA_H_
#define EUPHORIA_H_

/* Euphoria
   C include file for Euphoria programs 
   that have been translated to C */

#undef _segment
#undef _self
#undef _dos_ds

#include <stdio.h>

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
*
****************************************************************************/
#if EBITS == 32

#define NOVALUE      ((long)0xbfffffffL)
#define DBL_MASK ((long)0xA0000000)
#define SEQ_MASK ((long)0x80000000)
#define HIGH_BITS    ((long)0xC0000000L)

#undef MININT
#undef MAXINT
#define MININT     (long)0xC0000000
#define MAXINT     (long)0x3FFFFFFF

#elif EBITS == 64

#define NOVALUE      ((long)0xbfffffffffffffffL)
#define DBL_MASK ((long)0xA000000000000000)
#define SEQ_MASK ((long)0x8000000000000000)
#define HIGH_BITS    ((long)0xC000000000000000L)

#undef MININT
#undef MAXINT
#define MININT     (long)0xC000000000000000
#define MAXINT     (long)0x3FFFFFFFFFFFFFFF

#endif

#define MAXINT_VAL MAXINT
#define MAXINT_DBL ((double)MAXINT_VAL)
#define INT15      (long)0x00003FFFL

#define IS_ATOM_INT(ob)       (((long)(ob)) > NOVALUE)
#define IS_ATOM_DBL(ob)         (((object)(ob)) >= DBL_MASK)
#define IS_ATOM(ob)             (((long)(ob)) >= DBL_MASK)
#define IS_SEQUENCE(ob)         (((long)(ob))  < DBL_MASK)
#define IS_DBL_OR_SEQUENCE(ob)  (((long)(ob)) < NOVALUE)


#define LOW_MEMORY_MAX ((unsigned)0x0010FFEF)

typedef long object;
typedef long *object_ptr;

struct cleanup;
typedef struct cleanup *cleanup_ptr;
typedef void(*cleanup_func)(object);

struct cleanup {
	long type;
	union func_union{
		long rid;
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
	#if EBITS == 32
		long length;                   /* number of elements */
		long ref;                      /* reference count */
	#elif EBITS == 64
		long ref;                      /* reference count */
		long length;                   /* number of elements */
	#endif
	long postfill;                 /* number of post-fill objects */
	cleanup_ptr cleanup;           /* custom clean up when sequence is deallocated */
}; /* total 20 bytes */

struct d {
	double dbl;
	long ref;
	cleanup_ptr cleanup; 
};

struct routine_list {
	char *name;
	long (*addr)();
	long seq_num;
	long file_num;
	short int num_args;
	short int convention;
	char scope;
	cleanup_ptr cleanup;
};

struct ns_list {
	char *name;
	long ns_num;
	long seq_num;
	long file_num;
};

typedef struct d  *d_ptr;
typedef struct s1 *s1_ptr;

#define MAKE_DBL(x) ( (long) (((unsigned long)(x) >> 3) + DBL_MASK) )
#define DBL_PTR(ob) ( (d_ptr)  (((unsigned long)(ob)) << 3) )
#define MAKE_SEQ(x) ( (long) (((unsigned long)(x) >> 3) + SEQ_MASK) )
#define SEQ_PTR(ob) ( (s1_ptr) (((unsigned long)(ob)) << 3) ) 

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
#define XOR      154

struct replace_block {
	object_ptr copy_to;
	object_ptr copy_from;
	object_ptr start;
	object_ptr stop;
	object_ptr target;
};

typedef struct replace_block *replace_ptr;

long wingetch();
long call_c();
long Command_Line();
void show_console();
long Dpower();
long Dand_bits();
long Dand();
long Dremainder();
void Cleanup();
void init_literal();
char **make_arg_cv();
long NewDouble(double);
void DeRef5(long, long, long, long, long);
void de_reference(s1_ptr);
void de_reference_i(s1_ptr);
double current_time(void);
double floor(double);
double fabs(double);
long binary_op_a(long, long, long);
long binary_op(long, long, long);
void *which_file(long, long);
long unary_op(long, long);
long NewS1(long);
long compare(long, long);
unsigned long get_pos_int(char *, long);
long memory_set(long, long, long);
long memory_copy(long, long, long);
long EOpen(long, long,int);
void EClose(long);
long EPrintf(long, long, long);
void EPuts(long, long);
void Concat(long *, long, long);
void Concat_N(long *, long *, long);
void Append(long *, long, long);
void Prepend(long *, long, long);
object EGetEnv(object name);
void RHS_Slice(long, long, long);
long find(long, long);
long e_match(long, long);
void ctrace(char *);
long e_floor(long);
long DoubleToInt(long);
long machine(long, long);
long Repeat(long, long);
void RepeatElem(long, long, long);
long SequenceCopy(s1_ptr);
long power(long, long);
long EGets(long);
long Pixel(long, long);
long Get_Pixel(long);
void shift_args(long, char**);
long NewString(char *);
char *malloc(long);
void eu_startup();
// void exit(long);
long CRoutineId(long, long, long);
long e_sqrt(long);
long e_arctan(long);
void AssignSlice(long, long, long);
void StdPrint(long, long, long);
void ClearScreen();
void Position(long, long);
long CommandLine(void);
void system_call(long, long);
void RTFatal(char *);

// be_alloc:
char *TransAlloc(unsigned long);

// be_decompress:
object decompress(unsigned long c);

// be_runtime:
extern void *xstdin;
extern object *rhs_slice_target;
extern s1_ptr *assign_slice_seq;
#define IFILE FILE*
extern object last_w_file_no;
extern IFILE last_w_file_ptr;
extern object last_r_file_no;
extern IFILE last_r_file_ptr;
extern long insert_pos;;

long find_from(long,long,int);
long e_match_from(object aobj, object bobj, object c);
void Tail(s1_ptr , long , object_ptr );
void Head(s1_ptr , long , object_ptr );
object Remove_elements(long start, long stop, long in_place );
s1_ptr Add_internal_space(object a,long at,long len);
object system_exec_call(object command, object wait);
s1_ptr Copy_elements(long start,s1_ptr source, long replace );
object Insert(object a,object b,long pos);
object calc_hash(object a, object b);
object Dxor_bits(d_ptr a, d_ptr b);
object not_bits(long a);
object Date();
cleanup_ptr ChainDeleteRoutine( cleanup_ptr old, cleanup_ptr prev );
cleanup_ptr DeleteRoutine( long e_index );
void DeRef1(long a);
void Replace(replace_ptr rb);
void UserCleanup(long);

#define TASK_HANDLE int

// be_task:
struct interpreted_task{
	long *pc;         // program counter for this task
	object_ptr expr_stack; // call stack for this task
	object_ptr expr_max;   // current top limit of stack
	object_ptr expr_limit; // don't start a new routine above this
	object_ptr expr_top;   // stack pointer
	long stack_size;        // current size of stack
};

struct translated_task{
	TASK_HANDLE task;
	
};

// Task Control Block - sync with euphoria\include\euphoria.h
struct tcb {
	long rid;         // routine id
	double tid;      // external task id
	long type;        // type of task: T_REAL_TIME or T_TIME_SHARED
	long status;      // status: ST_ACTIVE, ST_SUSPENDED, ST_DEAD
	double start;    // start time of current run
	double min_inc;  // time increment for min
	double max_inc;  // time increment for max 
	double min_time; // minimum activation time
					 // or number of executions remaining before sharing
	double max_time; // maximum activation time (determines task order)
	long runs_left;   // number of executions left in this burst
	long runs_max;    // maximum number of executions in one burst
	long next;        // index of next task of the same kind
	object args;     // args to call task procedure with at startup
	
	long mode;  // TRANSLATED_TASK or INTERPRETED_TASK
	union task_impl {
		struct interpreted_task interpreted;
		struct translated_task translated;
	} impl;
	
};

extern long tcb_size;
extern long current_task;
extern double clock_period;
void task_yield();
extern struct tcb *tcb;

// be_w:
extern long in_from_keyb;
extern long TraceOn;
#endif
