#ifndef BE_RUNTIME_H
#define BE_RUNTIME_H

#include "global.h"
#include "execute.h"
#include "reswords.h"
extern unsigned eulong (*general_ptr)();
void de_reference(s1_ptr a);
void UserCleanup(eulong status);

#define FIRST_USER_FILE 3
#define MAX_USER_FILE 40
extern struct file_info user_file[MAX_USER_FILE];

extern struct routine_list *rt00;

extern eulong EuConsole;

extern unsigned char *string_ptr;
extern char *file_name_entered;
extern eulong warning_count;
extern char **warning_list;
extern eulong crash_count;
extern eulong clocks_per_sec;
extern eulong clk_tck;
extern eulong gameover;
extern eulong insert_pos;

extern eulong TraceOn;
extern object *rhs_slice_target;
extern s1_ptr *assign_slice_seq;

extern object last_w_file_no;
extern IFILE last_w_file_ptr;
extern object last_r_file_no;
extern IFILE last_r_file_ptr;
extern eulong current_screen;

extern IFILE TempErrFile;
extern char *TempErrName; // "ex.err" - but must be on the heap
extern char *TempWarningName;
extern eulong display_warnings;

extern eulong seed1, seed2;  /* current value of first and second random generators */
extern eulong rand_was_set;
extern eulong con_was_opened; /* TRUE if CON device was ever opened */
extern eulong current_screen;

extern eulong print_chars;  // value can be checked by caller

extern struct op_info optable[MAX_OPCODE+1];

void debug_msg(char *msg);

void RTFatal(char *, ...)
#ifdef EUNIX
__attribute__ ((noreturn))
#endif
;
void RTInternal(char *msg, ...)
#ifdef EUNIX
__attribute__ ((noreturn))
#endif
;
void RTFatal_va(char *msg, va_list ap)
#ifdef EUNIX
__attribute__ ((noreturn))
#endif
;
void Cleanup()
#ifdef EUNIX
__attribute__ ((noreturn))
#endif
;
void CleanUpError_va(char *msg, symtab_ptr s_ptr, va_list ap)
#ifdef EUNIX
__attribute__ ((noreturn))
#endif
;

#ifdef EUNIX
char key_buff[KEYBUFF_SIZE];
int key_write;;       // place where next key will be stored
#endif

void system_call(object command, object wait);
object system_exec_call(object command, object wait);

eulong might_go_screen(object file_no);
void set_text_color(eulong c);

void Append(object_ptr target, object s1, object a);
void Prepend(object_ptr target, object s1, object a);
void Replace( replace_ptr rb );
void Concat(object_ptr target, object a_obj, object b_obj);
s1_ptr Add_internal_space(object a,int at,int len);
void Concat_Ni(object_ptr target, object_ptr *source, eulong n);

object EGetEnv(object name);

object EPrintf(eulong file_no, object format_obj, object values);
void StdPrint(eulong fn, object a, long new_lines);
void EPuts(object file_no, object obj);
void Print(IFILE f, object a, eulong lines, long width, long init_chars, long pretty);
int show_ascii_char(IFILE print_file, eulong iv);

int get_key(eulong wait);
object EGets(object file_no);
void EClose(object a);
int CheckFileNumber(object a);
int NumberOpen();
void key_gets(char *input_string);

IFILE which_file(object a, eulong mode);
void MakeCString(char *s, object pobj, eulong slen);

void setran();
void call_crash_routines();

eulong compare(object a, object b);
object calc_hash(object a, object b);
void ctrace(char *line);
void Position(object line, object col);
extern eulong charcopy(char *, long, char *, long);
s1_ptr Copy_elements(eulong start,s1_ptr source, long replace );
cleanup_ptr ChainDeleteRoutine( cleanup_ptr old, cleanup_ptr prev );
cleanup_ptr DeleteRoutine( eulong e_index );
void AssignSlice(object start, object end, s1_ptr val);
void cleanup_double( d_ptr dbl );
void cleanup_sequence( s1_ptr seq );
void Tail(s1_ptr s1, eulong start, object_ptr target);
void Head(s1_ptr s1, eulong reqlen, object_ptr target);
object Remove_elements(eulong start, long stop, long in_place );
eulong find_from(object a, object bobj, object c);
eulong e_match_from(object aobj, object bobj, object c);
eulong e_match(s1_ptr a, s1_ptr b);
eulong find(object a, s1_ptr b);
void RHS_Slice( object a, object start, object end);
object Repeat(object item, object repcount);
object Insert(object a,object b,int pos);
unsigned eulong good_rand();
object Date();
object EOpen(object filename, object mode_obj, object cleanup);
object Command_Line();

object make_atom32(unsigned eulong c32);
object DoubleToInt(object d);

object unary_op(eulong fn, object a);

// Binary Ops
object binary_op_a(eulong fn, object a, object b);
object binary_op(eulong fn, object a, object b);
object x();
object minus(eulong a, long b);
object multiply(eulong a, long b);
object divide(eulong a, long b);
object Ddivide(d_ptr a, d_ptr b);
object eremainder(eulong a, long b);
object Dremainder(d_ptr a, d_ptr b);
object and_bits(eulong a, long b);
object Dand_bits(d_ptr a, d_ptr b);
object or_bits(eulong a, long b);
object Dor_bits(d_ptr a, d_ptr b);
object xor_bits(eulong a, long b);
object Dxor_bits(d_ptr a, d_ptr b);
object not_bits(eulong a);
object Dnot_bits(d_ptr a);
object power(eulong a, long b);
object Dpower(d_ptr a, d_ptr b);
object equals(eulong a, long b);
object Dequals(d_ptr a, d_ptr b);
object less(eulong a, long b);
object Dless(d_ptr a, d_ptr b);
object greater(eulong a, long b);
object Dgreater(d_ptr a, d_ptr b);
object noteq(eulong a, long b);
object Dnoteq(d_ptr a, d_ptr b);
object lesseq(eulong a, long b);
object Dlesseq(d_ptr a, d_ptr b);
object greatereq(eulong a, long b);
object Dgreatereq(d_ptr a, d_ptr b);
object and(eulong a, long b);
object Dand(d_ptr a, d_ptr b);
object or(eulong a, long b);
object Dor(d_ptr a, d_ptr b);
object xor(eulong a, long b);
object Dxor(d_ptr a, d_ptr b);
object uminus(eulong a);
object Duminus(d_ptr a);
object not(eulong a);
object Dnot(d_ptr a);
object e_sqrt(eulong a);
object De_sqrt(d_ptr a);
object e_sin(eulong a);
object De_sin(d_ptr a);
object e_cos(eulong a);
object De_cos(d_ptr a);
object e_tan(eulong a);
object De_tan(d_ptr a);
object e_arctan(eulong a);
object De_arctan(d_ptr a);
object e_log(eulong a);
object De_log(d_ptr a);
object De_floor(d_ptr a);
object Random(eulong a);
object DRandom(d_ptr a);

object e_floor(eulong a);  // not used anymore

int memcopy( void *dest, size_t avail, void *src, size_t len);

#endif /* BE_RUNTIME_H */
