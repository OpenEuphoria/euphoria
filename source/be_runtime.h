#ifndef BE_RUNTIME_H
#define BE_RUNTIME_H

#include "global.h"
#include "execute.h"
#include "reswords.h"

void de_reference(s1_ptr a);


#define FIRST_USER_FILE 3
#define MAX_USER_FILE 40
extern struct file_info user_file[MAX_USER_FILE];

extern struct routine_list *rt00;

extern int EuConsole;

extern unsigned char *string_ptr;
extern char *file_name_entered;
extern int warning_count;
extern char **warning_list;
extern int crash_count;
extern int clocks_per_sec;
extern int clk_tck;
extern int gameover;
extern int insert_pos;

extern int TraceOn;
extern object *rhs_slice_target;
extern s1_ptr *assign_slice_seq;

extern object last_w_file_no;
extern IFILE last_w_file_ptr;
extern object last_r_file_no;
extern IFILE last_r_file_ptr;
extern int current_screen;

extern IFILE TempErrFile;
extern char *TempErrName; // "ex.err" - but must be on the heap
extern char *TempWarningName;
extern int display_warnings;

extern int32_t seed1, seed2;  /* current value of first and second random generators */
extern int rand_was_set;
extern int con_was_opened; /* TRUE if CON device was ever opened */
extern int current_screen;

extern int print_chars;  // value can be checked by caller

extern struct op_info optable[MAX_OPCODE+1];

extern int trace_lines;

void debug_msg(char *msg);

void UserCleanup(int status)
#if defined(EUNIX) || defined(EMINGW)
__attribute__ ((noreturn))
#else
#pragma aux UserCleanup aborts;
#endif
;

void RTFatal(char *, ...)
#if defined(EUNIX) || defined(EMINGW)
__attribute__ ((noreturn))
#else
#pragma aux RTFatal aborts;
#endif
;
void RTInternal(char *msg, ...)
#if defined(EUNIX) || defined(EMINGW)
__attribute__ ((noreturn))
#else
#pragma aux RTInternal aborts;
#endif
;
void RTFatal_va(char *msg, va_list ap)
#if defined(EUNIX) || defined(EMINGW)
__attribute__ ((noreturn))
#else
#pragma aux RTFatal_va aborts;
#endif
;
void Cleanup()
#if defined(EUNIX) || defined(EMINGW)
__attribute__ ((noreturn))
#else
#pragma aux Cleanup aborts;
#endif
;


#ifdef EUNIX
char key_buff[KEYBUFF_SIZE];
int key_write;;       // place where next key will be stored
#endif

void system_call(object command, object wait);
object system_exec_call(object command, object wait);

int might_go_screen(object file_no);
void set_text_color(int c);

void Append(object_ptr target, object s1, object a);
void Prepend(object_ptr target, object s1, object a);
void Replace( replace_ptr rb );
void Concat(object_ptr target, object a_obj, object b_obj);
s1_ptr Add_internal_space(object a,int at,int len);
void Concat_Ni(object_ptr target, object_ptr *source, int n);
void Concat_N(object_ptr target, object_ptr  source, int n);

object EGetEnv(object name);

object EPrintf(object file_no, object format_obj, object values);
void StdPrint(object fn, object a, int new_lines);
void EPuts(object file_no, object obj);
void Print(IFILE f, object a, int lines, int width, int init_chars, int pretty);
int show_ascii_char(IFILE print_file, int iv);

int get_key(int wait);
object EGets(object file_no);
void EClose(object a);
int CheckFileNumber(object a);
int NumberOpen();
void key_gets(char *input_string, int buffsize);

IFILE which_file(object a, int mode);
void MakeCString(char *s, object pobj, int slen);

void setran();
void call_crash_routines();

object compare(object a, object b);
object calc_hash(object a, object b);
void ctrace(char *line);
void Position(object line, object col);
extern int charcopy(char *, int, char *, int);
s1_ptr Copy_elements(int start,s1_ptr source, int replace );
cleanup_ptr ChainDeleteRoutine( cleanup_ptr old, cleanup_ptr prev );
cleanup_ptr DeleteRoutine( int e_index );
void AssignSlice(object start, object end, object val);
void cleanup_double( d_ptr dbl );
void cleanup_sequence( s1_ptr seq );
void Tail(s1_ptr s1, int start, object_ptr target);
void Head(s1_ptr s1, int reqlen, object_ptr target);
object Remove_elements(int start, int stop, int in_place );
object find_from(object a, object bobj, object c);
object e_match_from(object aobj, object bobj, object c);
object e_match(s1_ptr a, s1_ptr b);
object find(object a, s1_ptr b);
void RHS_Slice( object a, object start, object end);
object Repeat(object item, object repcount);
object Insert(object a,object b,int pos);
int32_t good_rand();
object Date();
object EOpen(object filename, object mode_obj, object cleanup);
object Command_Line();

object make_atom32(unsigned c32);
object DoubleToInt(object d);

object unary_op(int fn, object a);

// Binary Ops
object binary_op_a(int fn, object a, object b);
object binary_op(int fn, object a, object b);
object x();
object minus(object a, object b);
object multiply(object a, object b);
object divide(object a, object b);
object Ddivide(d_ptr a, d_ptr b);
object eremainder(object a, object b);
object Dremainder(d_ptr a, d_ptr b);
object and_bits(uintptr_t a, uintptr_t b);
object Dand_bits(d_ptr a, d_ptr b);
object or_bits(uintptr_t a, uintptr_t b);
object Dor_bits(d_ptr a, d_ptr b);
object xor_bits(uintptr_t a, uintptr_t b);
object Dxor_bits(d_ptr a, d_ptr b);
object not_bits(uintptr_t a);
object Dnot_bits(d_ptr a);
object power(object a, object b);
object Dpower(d_ptr a, d_ptr b);
object equals(object a, object b);
object Dequals(d_ptr a, d_ptr b);
object less(object a, object b);
object Dless(d_ptr a, d_ptr b);
object greater(object a, object b);
object Dgreater(d_ptr a, d_ptr b);
object noteq(object a, object b);
object Dnoteq(d_ptr a, d_ptr b);
object lesseq(object a, object b);
object Dlesseq(d_ptr a, d_ptr b);
object greatereq(object a, object b);
object Dgreatereq(d_ptr a, d_ptr b);
object and(object a, object b);
object Dand(d_ptr a, d_ptr b);
object or(object a, object b);
object Dor(d_ptr a, d_ptr b);
object xor(object a, object b);
object Dxor(d_ptr a, d_ptr b);
object uminus(object a);
object Duminus(d_ptr a);
object not(object a);
object Dnot(d_ptr a);
object e_sqrt(object a);
object De_sqrt(d_ptr a);
object e_sin(object a);
object De_sin(d_ptr a);
object e_cos(object a);
object De_cos(d_ptr a);
object e_tan(object a);
object De_tan(d_ptr a);
object e_arctan(object a);
object De_arctan(d_ptr a);
object e_log(object a);
object De_log(d_ptr a);
object De_floor(d_ptr a);
object Random(object a);
object DRandom(d_ptr a);

object e_floor(object a);  // not used anymore

int memcopy( void *dest, size_t avail, void *src, size_t len);

object eu_sizeof( object data_type );
int getKBchar();

#if INTPTR_MAX == INT32_MAX
#define CALLBACK_POINTER 0x12345678L
#define general_ptr_magic 0xF001F001L

#elif INTPTR_MAX == INT64_MAX
#define general_ptr_magic 0xabcdefabcdefabcdLL
#ifdef ERUNTIME
#define CALLBACK_POINTER ((uintptr_t)0x1234567812345678LL)
#else
#define CALLBACK_POINTER ((symtab_ptr)0x1234567812345678LL)
#endif
#endif

#ifdef EOSX
uintptr_t __cdecl osx_cdecl_call_back(uintptr_t arg1, uintptr_t arg2, uintptr_t arg3,
						uintptr_t arg4, uintptr_t arg5, uintptr_t arg6,
                        uintptr_t arg7, uintptr_t arg8, uintptr_t arg9);
#endif // EOSX
extern uintptr_t (*general_ptr)();


uintptr_t general_call_back(
#ifdef ERUNTIME
		  intptr_t cb_routine,
#else
		  symtab_ptr cb_routine,
#endif
						   uintptr_t arg1, uintptr_t arg2, uintptr_t arg3,
						   uintptr_t arg4, uintptr_t arg5, uintptr_t arg6,
						   uintptr_t arg7, uintptr_t arg8, uintptr_t arg9);

#endif /* BE_RUNTIME_H */

