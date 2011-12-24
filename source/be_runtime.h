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

extern long seed1, seed2;  /* current value of first and second random generators */
extern int rand_was_set;
extern int con_was_opened; /* TRUE if CON device was ever opened */
extern int current_screen;

extern int print_chars;  // value can be checked by caller

extern struct op_info optable[MAX_OPCODE+1];

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

object EGetEnv(object name);

object EPrintf(int file_no, object format_obj, object values);
void StdPrint(int fn, object a, int new_lines);
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

int compare(object a, object b);
object calc_hash(object a, object b);
void ctrace(char *line);
void Position(object line, object col);
extern int charcopy(char *, int, char *, int);
s1_ptr Copy_elements(int start,s1_ptr source, int replace );
cleanup_ptr ChainDeleteRoutine( cleanup_ptr old, cleanup_ptr prev );
cleanup_ptr DeleteRoutine( int e_index );
void AssignSlice(object start, object end, s1_ptr val);
void cleanup_double( d_ptr dbl );
void cleanup_sequence( s1_ptr seq );
void Tail(s1_ptr s1, int start, object_ptr target);
void Head(s1_ptr s1, int reqlen, object_ptr target);
object Remove_elements(int start, int stop, int in_place );
long find_from(object a, object bobj, object c);
long e_match_from(object aobj, object bobj, object c);
long e_match(s1_ptr a, s1_ptr b);
long find(object a, s1_ptr b);
void RHS_Slice( object a, object start, object end);
object Repeat(object item, object repcount);
object Insert(object a,object b,int pos);
unsigned long good_rand();
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
object minus(long a, long b);
object multiply(long a, long b);
object divide(long a, long b);
object Ddivide(d_ptr a, d_ptr b);
object eremainder(long a, long b);
object Dremainder(d_ptr a, d_ptr b);
object and_bits(unsigned long a, unsigned long b);
object Dand_bits(d_ptr a, d_ptr b);
object or_bits(unsigned long a, unsigned long b);
object Dor_bits(d_ptr a, d_ptr b);
object xor_bits(unsigned long a, unsigned long b);
object Dxor_bits(d_ptr a, d_ptr b);
object not_bits(unsigned long a);
object Dnot_bits(d_ptr a);
object power(long a, long b);
object Dpower(d_ptr a, d_ptr b);
object equals(long a, long b);
object Dequals(d_ptr a, d_ptr b);
object less(long a, long b);
object Dless(d_ptr a, d_ptr b);
object greater(long a, long b);
object Dgreater(d_ptr a, d_ptr b);
object noteq(long a, long b);
object Dnoteq(d_ptr a, d_ptr b);
object lesseq(long a, long b);
object Dlesseq(d_ptr a, d_ptr b);
object greatereq(long a, long b);
object Dgreatereq(d_ptr a, d_ptr b);
object and(long a, long b);
object Dand(d_ptr a, d_ptr b);
object or(long a, long b);
object Dor(d_ptr a, d_ptr b);
object xor(long a, long b);
object Dxor(d_ptr a, d_ptr b);
object uminus(long a);
object Duminus(d_ptr a);
object not(long a);
object Dnot(d_ptr a);
object e_sqrt(long a);
object De_sqrt(d_ptr a);
object e_sin(long a);
object De_sin(d_ptr a);
object e_cos(long a);
object De_cos(d_ptr a);
object e_tan(long a);
object De_tan(d_ptr a);
object e_arctan(long a);
object De_arctan(d_ptr a);
object e_log(long a);
object De_log(d_ptr a);
object De_floor(d_ptr a);
object Random(long a);
object DRandom(d_ptr a);

object e_floor(long a);  // not used anymore

int memcopy( void *dest, size_t avail, void *src, size_t len);

int getKBchar();

#endif /* BE_RUNTIME_H */
