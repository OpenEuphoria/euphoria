/*****************************************************************************/
/*      (c) Copyright - See License.txt       */
/*****************************************************************************/
/*                                                                           */
/*                            Run-time Routines                              */
/*                                                                           */
/*****************************************************************************/

/******************/
/* Included files */
/******************/
#define _LARGE_FILE_API
#define _LARGEFILE64_SOURCE
#include <stdint.h>
#if defined(EWINDOWS) && INTPTR_MAX == INT64_MAX
// MSVCRT doesn't handle long double output correctly
#define __USE_MINGW_ANSI_STDIO 1
#endif
#include <stdio.h>

#include <stdarg.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>
#include <ctype.h>
#include <inttypes.h>

#ifdef EUNIX
#  include <unistd.h>
#  include <termios.h>
#  include <time.h>
#  include <sys/ioctl.h>
#  include <sys/types.h>
#  include <sys/wait.h>
#  include <dlfcn.h>
#else
#  include <io.h>
#  if !defined(EMINGW)
#    include <bios.h>
#  endif
#  if !defined(EMINGW)
#    include <graph.h>
#  endif
#  include <dos.h>
#  include <process.h>
#  include <conio.h>
#endif

#include <string.h>
#ifdef EWINDOWS
	/* Ensure we set this to 0x400 whether or not it is set. */
	#include <windows.h>
	#ifndef _WIN32_IE
		#define _WIN32_IE WINVER
	#endif
	#include <commctrl.h>
#endif


#include "alldefs.h"
#include "be_alloc.h"
#include "be_runtime.h"
#include "be_machine.h"
#include "be_inline.h"
#include "be_w.h"
#include "be_callc.h"
#include "be_task.h"

#ifndef ERUNTIME
#include "be_rterror.h"
#include "be_coverage.h"
#include "be_execute.h"
#include "be_symtab.h"
#endif



/******************/
/* Local defines  */
/******************/
#define IsDigit(x) ((x) >= '0' && (x) <= '9')

#define NUM_SIZE 30     /* enough space to print a number */
#define LOCAL_SPACE 100 /* some local space */

/* convert atom to char. *must avoid side effects in elem* */
#define Char(elem) ((IS_ATOM_INT(elem)) ? ((char)INT_VAL(elem)) : doChar(elem))

#define CONTROL_Z 26
#define CR 13
#define LF 10
#ifdef WINDOWS
#define BS 8
#else
#define BS 127
#endif

#ifdef EWINDOWS
static int winkbhit();
#endif
/**********************/
/* Imported variables */
/**********************/
extern int Argc;
extern char **Argv;

/**********************/
/* Exported variables */
/**********************/
char *file_name_entered = "";
int warning_count = 0;
char **warning_list;
int crash_count = 0; /* number of crashes so far */
int clocks_per_sec;
int clk_tck;
int gameover = FALSE;           /* Are we shutting down? */
int insert_pos;
IFILE TempErrFile;
char *TempErrName; // "ex.err" - but must be on the heap
char *TempWarningName;
int display_warnings;
double eustart_time;

/**********************/
/* Declared Functions */
/**********************/

object add(object a, object b);

struct op_info optable[MAX_OPCODE+1] = {
{x, x}, /* no 0th element */
{less, Dless},
{greatereq, Dgreatereq},
{equals, Dequals},
{noteq, Dnoteq},
{lesseq, Dlesseq},
{greater, Dgreater},
{not, Dnot},
{and, Dand},
{or, Dor},
/* 10 */ {minus, Dminus},
{add, Dadd},
{uminus, Duminus},
{multiply, Dmultiply},
{divide, Ddivide},
{x, x},
{x, x},
{x, x},
{x, x},
{x, x},
/* 20 */ {x, x},
{x, x},
{x, x},
{x, x},
{or_bits, Dor_bits},
{x, x},
{xor_bits, Dxor_bits},
{x, x},
{x, x},
{x, x},
/* 30 */ {x, x},
{x, x},
{x, x},
{x, x},
{x, x},
{x, x},
{x, x},
{x, x},
{x, x},
{x, x},
/* 40 */ {x, x},
{e_sqrt, De_sqrt},
{x, x},
{x, x},
{x, x},
{x, x},
{x, x},
{x, x},
{x, x},
{x, x},
/* 50 */ {x, x},
{not_bits, Dnot_bits},
{x, x},
{x, x},
{x, x},
{x, x},
{and_bits, Dand_bits},
{x, x},
{x, x},
{x, x},
/* 60 */ {x, x},
{x, x},
{Random, DRandom},
{x, x},
{x, x},
{x, x},
{x, x},
{x, x},
{x, x},
{x, x},
/* 70 */ {x, x},
{eremainder, Dremainder},
{power, Dpower},
{e_arctan, De_arctan},
{e_log, De_log},
{x, x},
{x, x},
{x, x},
{x, x},
{x, x},
/* 80 */ {e_sin, De_sin},
{e_cos, De_cos},
{e_tan, De_tan},
{e_floor, De_floor},
{x, x},
{x, x},
{x, x},
{x, x},
{x, x},
{x, x},
/* 90 */ {x, x},
{x, x},
{x, x},
{x, x},
{x, x},
{x, x},
{x, x},
{x, x},
{x, x},
{x, x},
/* 100 */ {x, x},
{x, x},
{x, x},
{x, x},
{x, x},
{x, x},
{x, x},
{x, x},
{x, x},
{x, x},
/* 110 */ {x, x},
{x, x},
{x, x},
{x, x},
{x, x},
{x, x},
{x, x},
{x, x},
{x, x},
{x, x},
/* 120 */ {x, x},
{x, x},
{x, x},
{x, x},
{x, x},
{x, x},
{x, x},
{x, x},
{x, x},
{x, x},
  /* 130 */ {x, x},
			// two removed
{x, x},
{x, x},
{x, x},
{x, x},
{x, x},
{x, x},
{x, x},
{x, x},
{x, x},
{x, x},/* 140 */ 
{x, x},
{x, x},
{x, x},
{x, x},
{x, x},
{x, x},
{x, x},
{x, x},
{x, x},
{x, x},/* 150 */
{x, x},
{xor, Dxor},
{x, x},
{x, x}, 
{x, x},  // platform - never actually emitted
{x, x}, 
{x, x}, 
{x, x}, 
{x, x}, 
{x, x},/* 160 */
{x, x},
{x, x},
{x, x},
{x, x},
{x, x},
{x, x},     // 166: SEQUENCE_COPY
{x, x},
{x, x},
{x, x},
{x, x}, /* 170 */
{x, x},
{x, x},
{x, x},
{x, x},
{x, x},
{x, x},
{x, x},
{x, x},
{x, x},
/* 180 */{x, x},
{x, x},
{x, x},
{x, x},
{x, x},
{x, x},
{x, x},
{x, x},
{x, x},
{x, x},
/* 190 */{x, x},
{x, x},
{x, x},
{x, x},
{x, x},
{x, x},
{x, x},
{x, x},
{x, x},
{x, x},
/*200*/{x, x},
{x, x},
{x, x},
{x, x},
{x, x},
{x, x},
{x, x},
{x, x},
{x, x},
{x, x},
{x, x},/*210*/
{x, x}
};

int TraceOn = FALSE;
object *rhs_slice_target;
s1_ptr *assign_slice_seq;
object last_w_file_no = NOVALUE;
IFILE last_w_file_ptr;
object last_r_file_no = NOVALUE;
IFILE last_r_file_ptr;
struct file_info user_file[MAX_USER_FILE];
int32_t seed1, seed2;  /* current value of first and second random generators */
int rand_was_set = FALSE;   /* TRUE if user has called set_rand() */
int con_was_opened = FALSE; /* TRUE if CON device was ever opened */
int current_screen = MAIN_SCREEN;

int EuConsole = 0; /* TRUE if EnvVar EUCONS=1. Forces use of alternate console support
                      for euid running on Windows systems that do not support
                      'full screen DOS' mode; eg. Vista.
                   */
char *last_traced_line = NULL;
struct routine_list *rt00;
struct ns_list *rt01;
char ** rt02;

/*******************/
/* Local variables */
/*******************/
static int user_abort = FALSE; /* TRUE if abort() was called by user program */

/**********************/
/* Declared functions */
/**********************/

/*********************/
/* Defined functions */
/*********************/
/* Copies character from one buffer (source) to another (target).
   It copies a maximum of the smaller of 'source_chars' and strlen(source) from source.
   It adds a null character at the end of the copied characters in target but only
   if it can fit it in.

   It returns the number of remaining characters positions in target. If this is
   less than 1 then the target buffer was not big enough to hold the source and
   the target buffer is not terminated with a null character.
*/
int charcopy(char *target, int target_len, char *source, int source_len)
{
	int source_remaining = source_len;
	int target_remaining = target_len;

	while ((source_remaining > 0) && (target_remaining > 0) && (*source != '\0'))
	{
		*target = *source;
		target++;
		source++;
		source_remaining--;
		target_remaining--;
	}

	if (target_remaining > 0)
		*target = '\0';

	return target_remaining;
}


/* essential primitive debug code - might as well leave it in */

IFILE debug_log = NULL;    /* DEBUG log messages */

void debug_msg(char *msg)
// send debug message to debug.log
{
	if (debug_log == NULL) {
		debug_log = iopen("debug.log", "w");
		if (debug_log == NULL) {
			iprintf(stderr, "Couldn't open debug.log\n");
			exit(1);
		}
	}
	iprintf(debug_log, "%s\n", msg);
	iflush(debug_log);
}

void debug_int(int num)
// send an integer to debug.log
{
#define dbg_int_len (40)
	char buff[dbg_int_len];
	snprintf(buff, dbg_int_len, "%d", num);
	buff[dbg_int_len - 1] = 0; // ensure NULL
	debug_msg(buff);
}

void debug_dbl(double num)
// send a double to debug.log
{
#define dbg_dbl_len (40)
	char buff[dbg_dbl_len];
	snprintf(buff, dbg_dbl_len, "%g", num);
	buff[dbg_dbl_len - 1] = 0; // ensure NULL
	debug_msg(buff);
}
#ifdef EARM
double maxplus1 = ((double)UINTPTR_MAX) + 1;
uintptr_t doubletouintptrdiscardhighbits(double d)
{
	return d-(maxplus1*floor(d/maxplus1));
}
#endif

#ifdef ERUNTIME
int color_trace = 1;
void MainScreen()
{
}

#endif

#if !defined(EBSD62)
#undef matherr // avoid OpenWATCOM problem
#if (defined(__WATCOMC__) || defined(EUNIX)) && !defined(EOW)
int matherr(struct exception *err)   // 10.6 wants this
#else
int matherr(struct _exception *err)  // OW wants this
#endif
{
	char *msg;

#ifdef EMSVC
	switch(0) {
#else
	switch(err->type) {
#endif
		case DOMAIN:
			msg = "domain";
			break;
		case SING:
			msg = "singularity";
			break;
		case OVERFLOW:
			msg = "overflow";
			break;
		case UNDERFLOW:
			msg = "underflow";
			break;
		case TLOSS:
		case PLOSS:
			msg = "loss of significance";
			break;
		default:
			msg = "internal";
			break;
	}
	RTFatal("math function %s error", msg);
	return 0;
}
#endif

int crash_call_back = FALSE;

void call_crash_routines()
/* call all the routines in the crash list */
{
	int i, r;
	object quit;
	if (crash_count > 0)
		return;
	crash_count++;

	if (TempErrName) EFree(TempErrName);
#define CCR_len (16)
	TempErrName = (char *)EMalloc(CCR_len);
	copy_string(TempErrName, "ex_crash.err", CCR_len);

#ifndef ERUNTIME
	// clear the interpreter call stack
	if ( expr_stack != NULL ) {
		expr_stack[1] = 0;
		expr_top = &expr_stack[2];
	}
	tpc = 0;
#endif

	for (i = crash_routines-1; i >= 0; i--) {
		r = crash_list[i];
		crash_call_back = TRUE;
		quit = (object)general_call_back(
#ifdef ERUNTIME
		   (int)r,
#else
		   (symtab_ptr)e_routine[r],
#endif
		   0, // first and only arg is 0
		   0,0,0,0,0,0,0,0 // other args ignored
		   );
		// keep going?
		if (IS_ATOM_INT(quit)) {
			if (quit != 0)
				break;
		}
		else if (IS_ATOM(quit)) {
			if (DBL_PTR(quit)->dbl != 0.0)
				break;
		}
		else {
			/* SEQUENCE returned */
			break;
		}
	}
}

#if defined(EUNIX) || defined(EMINGW)
static void SimpleRTFatal(char *msg, va_list ap) __attribute__ ((noreturn));
#endif

static void SimpleRTFatal(char *msg, va_list ap)

/* Fatal errors for translated code */
{
	va_list aq;
#	ifdef va_copy
		va_copy(aq, ap);
#	else
		/* Syntax error here is on purpose.  We need to handle the case here that
		 * va_copy() is missing differently for each compiler. */
		va_copy(aq, ap);

#	endif

	if (crash_msg == NULL || crash_count > 0) {
		screen_output(stderr, "\nFatal run-time error:\n");
		screen_output_va(stderr, msg, aq);
		screen_output(stderr, "\n\n");
	}
	else {
		screen_output(stderr, crash_msg);
	}
	va_end(aq);
	if (TempErrFile == NULL)
	{
		TempErrFile = iopen(TempErrName, "w");
	}
	if (TempErrFile != NULL) {
		iprintf(TempErrFile, "Fatal run-time error:\n");
		vfprintf(TempErrFile, msg, ap);
		iprintf(TempErrFile, "\n");

		if (last_traced_line != NULL) {
			if (crash_msg == NULL || crash_count > 0)
				iprintf(stderr, "%s\n", last_traced_line);
			iprintf(TempErrFile, "%s\n", last_traced_line);
		}
		iclose(TempErrFile);
		TempErrFile = NULL;
	}


	call_crash_routines();
	gameover = TRUE;
	Cleanup(1);
}

void RTFatal_va(char *msg, va_list ap)
/* handle run time fatal errors */
{
#ifndef ERUNTIME
	if (Executing)
		CleanUpError_va(msg, NULL, ap);
	else
#endif
		SimpleRTFatal(msg, ap);
}

void RTFatal(char *msg, ...)
{
	va_list ap;
	va_start(ap, msg);
	RTFatal_va(msg, ap);
	va_end(ap);
}

void InitFiles()
/* initialize user files before executing */
{
	int i;

	user_file[0].fptr = stdin;
	user_file[0].mode = EF_READ;
	user_file[1].fptr = stdout;
	user_file[1].mode = EF_WRITE;
	user_file[2].fptr = stderr;
	user_file[2].mode = EF_WRITE;
	for (i = FIRST_USER_FILE; i < MAX_USER_FILE; i++)
		user_file[i].mode = EF_CLOSED;
}

int NumberOpen()
// return a count of the number of open user files
{
	int i, op;

	op = 0;
	for (i = FIRST_USER_FILE; i < MAX_USER_FILE; i++) {
		if (user_file[i].mode != EF_CLOSED)
			op++;
	}
	return op;
}

static char doChar(object elem)
/* convert to char (int done in-line) */
{
	if (IS_ATOM_INT(elem))
		return (char)elem;
	if (IS_ATOM(elem))
		return (char)(DBL_PTR(elem)->dbl);
	else {
		RTFatal("sequence found inside character string");
	}
}


void Prepend(object_ptr target, object s1, object a)
/* prepend object 'a' onto front of s1 sequence. Caller should
   increment ref count if necessary. */
{
	object_ptr p, q;
	s1_ptr t;
	s1_ptr s1p, new_seq;
	int len, new_len;
	object temp;

	t = (s1_ptr)*target;
	s1p = SEQ_PTR(s1);
	len = s1p->length;
	if ((s1_ptr)s1 == t && s1p->ref == 1) {
		/* we can to prepend in-place */
		/* Check for room at beginning */
		if (s1p->base >= (object_ptr)(s1p+1)) {
			s1p->length++;
			*(s1p->base) = a;
			s1p->base--;
			return;
		}
		/* OPTIMIZE: check for postfill & copy down */
		/* OPTIMIZE: check for extra room in current allocation? */
		/* OPTIMIZE: Do an _expand() if possible */
	}
	/* make a new sequence */
	new_len = EXTRA_EXPAND(len);
	new_seq = NewS1(new_len);
	new_seq->length = len + 1;
	new_seq->base += new_len - new_seq->length; /* make room at beginning */
	p = new_seq->base+1;
	*p = a;
	q = s1p->base;
	while (TRUE) {  // NOVALUE will be copied
		temp = *(++q);
		*(++p) = temp;
		if (!IS_ATOM_INT(temp)) {
			if (temp == NOVALUE)
				break;
			RefDS(temp);
		}
	}
	ASSIGN_SEQ(target, new_seq);
}

void Append(object_ptr target, object s1, object a)
/* append object 'a' onto the end of s1 sequence. Caller should
   increment ref count if necessary. */
{
	object_ptr p, q;
	s1_ptr t;
	s1_ptr s1p, new_s1p, new_seq;
	long len, new_len;
	object_ptr base, last;
	object temp;

	t = (s1_ptr)*target;
	s1p = SEQ_PTR(s1);
	len = s1p->length;

	if ((s1_ptr)s1 == t && s1p->ref == 1) {
		/* we can append in-place */
		if (s1p->postfill == 0) {
			/* make some more postfill space */
			new_len = EXTRA_EXPAND(len);
			base = s1p->base;
			/* allow 1*4 for end marker */
			/* base + new_len + 2 could overflow 32-bits??? */
			new_s1p = (s1_ptr)ERealloc((char *)s1p,
							   (char *)(base + new_len + 2) - (char *)s1p);
			new_s1p->base = (object_ptr)new_s1p +
							 ((object_ptr)base - (object_ptr)s1p);
			s1p = new_s1p;
			s1p->postfill = new_len - len;

			*target = MAKE_SEQ(s1p);
		/* OPTIMIZE: we may have more space in the current allocation
		   than we think, due to power of 2 round up etc. Can
		   we find out what we have and increment postfill
		   accordingly? Then we can usually avoid memcopying too much
		   in Realloc. */
		}
		s1p->postfill--;
		s1p->length++;
		last = s1p->base + len + 1;
		*last = a;
		*(last+1) = NOVALUE;  // make a new end marker
		return;
	}
	/* make a new sequence */
	new_len = EXTRA_EXPAND(len);
	new_seq = NewS1(new_len);
	new_seq->length = len + 1;
	new_seq->postfill = new_len - new_seq->length;
	p = new_seq->base;
	q = s1p->base;
	while (TRUE) {  // NOVALUE will be copied
		temp = *(++q);
		*(++p) = temp;
		if (!IS_ATOM_INT(temp)) {
			if (temp == NOVALUE)
				break;
			RefDS(temp);
		}
	}
	*p++ = a;
	*p = NOVALUE; // end marker
	ASSIGN_SEQ(target, new_seq);
}

/**
 * Adds some room at at for len in seq.  If a has refcount > 1,
 * it makes a copy and derefs a.
 */
s1_ptr Add_internal_space(object a,int at,int len)
{

	s1_ptr new_seq;
	object temp;
	int i;
	int new_len;
	object_ptr p,q;
	s1_ptr seq = SEQ_PTR(a);
	int nseq = seq->length;
	if (seq->ref == 1 ){
		if( len >= seq->postfill ){
			int base_offset;
			new_len = EXTRA_EXPAND(nseq + len);
			base_offset = (object_ptr)seq->base - (object_ptr)seq;
			new_seq = (s1_ptr)ERealloc((char *)seq, (new_len + 1)*sizeof(s1_ptr) + sizeof( struct s1 ));
			new_seq->base = (object_ptr)(new_seq) + base_offset;
			seq = new_seq;
			seq->postfill = new_len - (len + nseq) - 1;

		}
		else{
			seq->postfill -= len;
		}
		seq->length += len;
		seq->base[seq->length+1] = NOVALUE;
		q = seq->base + nseq;
		p = seq->base + seq->length;

		new_len = seq->length+1;
		len = nseq+1;
		for( i = nseq - at; i > -1; i-- ){
			*(p--) = *(q--);
			len--;
			new_len--;
		}
		return seq;
	}

	new_seq = NewS1(nseq + len);
	p = new_seq->base;
	q = seq->base;
	for (i=1;i<at;i++) {
		temp = *(++q);
		*(++p) = temp;
		if (!IS_ATOM_INT(temp)) RefDS(temp);
	}
	p += len;
	while (TRUE) {  // NOVALUE will be copied

		temp = *(++q);
		*(++p) = temp;
		if (!IS_ATOM_INT(temp)) {
			if (temp == NOVALUE){
				break;
			}
			RefDS(temp);
		}
		i++;
	}
	DeRefDS( MAKE_SEQ( seq ) );
	return new_seq;
}


s1_ptr Copy_elements(int start,s1_ptr source, int replace )
{
	object_ptr t_elem, s_elem;
	s1_ptr s1 = *assign_slice_seq;
	object temp;
	int i;

	if (s1->ref != 1 || !replace) {
		s1_ptr new_seq = NewS1(s1->length);
		object_ptr next_pos;
		t_elem = new_seq->base;
		s_elem = s1->base;
		for (i=1;i<start;i++) {
			temp = *(++s_elem);
			*(++t_elem) = temp;
			if (!IS_ATOM_INT(temp))
				RefDS(temp);
		}
		next_pos = s_elem+source->length;
		s_elem = source->base;
		for (i=1;i<=source->length;i++) {
			temp = *(++s_elem);
			*(++t_elem) = temp;
			if (!IS_ATOM_INT(temp))
				RefDS(temp);
		}
		s_elem = next_pos;
		while (TRUE) {
			temp = *(++s_elem);
			*(++t_elem) = temp;
			if (!IS_ATOM_INT(temp)) {
				if (temp == NOVALUE)
					break;
				RefDS(temp);
			}
		}
		return new_seq;
	}
	else {
		t_elem = (*assign_slice_seq)->base+start;
		s_elem = source->base+1;
		for (i=1;i<=source->length;i++) {
			temp = *(s_elem++);
			*(t_elem++) = temp;
			if (!IS_ATOM_INT(temp))
				RefDS(temp);
		}
		return s1;
	}
}

/**
  * Insert b into, the sequence, a at position pos.  If a has a ref > 1, Insert makes a copy of 
  * a and inserts b into this copy and derefs a.  After that, this modified copy of a is returned. 
  */
object Insert(object a,object b,int pos)
{
	s1_ptr s1 = Add_internal_space(a,pos,1);
	s1->base[pos] = b;
	return MAKE_SEQ(s1);
}

/**
  * Assigns to *target a sequence object which is comprised of the first reqlen-1 elements of s1.
  * If s1->ref == 1 and *target == MAKESEQ(s1), the sequence will be processed in place.
  */
void Head(s1_ptr s1, int reqlen, object_ptr target)
{
	int i;
	object_ptr op, se;

	if (s1->ref == 1 && *target == MAKE_SEQ(s1)) {
		// Target is same as source and source only has one reference,
		// so just use the existing allocation rather than create a new sequence.

		// First, dereference all existing elements after the new end position.
		for (op = (s1->base+reqlen), se = s1->base + s1->length + 1; op < se; op++)
			DeRef(*op);

		// Mark the 'end-of-sequence'
		*(s1->base+reqlen) = NOVALUE;

		// Update the post-fill count.
		s1->postfill += (s1->length - reqlen + 1);

		// Adjust the new length.
		s1->length = reqlen-1;
	}
	else {
		// Build a new sequence.
		s1_ptr s2 = NewS1(reqlen-1);
		object temp;

		for (i = 1; i < reqlen; i++) {
			temp = *(s1->base+i);
			*(s2->base+i) = temp;
		  	Ref(temp);
		}

		*(s2->base+reqlen) = NOVALUE;
		ASSIGN_SEQ(target, s2);
	}
}

void Tail(s1_ptr s1, int start, object_ptr target)
{

	int newlen;
	object_ptr ss, op, se;

	newlen = s1->length - start + 1;
	if (s1->ref == 1 && MAKE_SEQ(s1) == *target) {
		// Target is same as source and source only has one reference,
		// so just use the existing allocation rather than creare a new sequence.

		// First, dereference all existing elements before the new start position.
		for (ss = op = (s1->base + 1), se = s1->base + start; op < se; op++)
			DeRef(*op);
		// Now copy the 'tail' elements to the start of the existing sequence.
		memmove((void *)ss,(void *)se, sizeof(object_ptr)*(newlen + 1));
		s1->postfill += start-1;
		s1->length = newlen;
    }
    else {
		s1_ptr s2 = NewS1(newlen);
		object temp;
		object_ptr src = s1->base + start - 1, trg = s2->base;
		while (TRUE) {
			temp = *(++src);
			*(++trg) = temp;
     		if (temp == NOVALUE)
       			break;
			Ref(temp);
	 	}
	 	ASSIGN_SEQ(target, s2);
    }
}

/**
 * Caller must assign assign_slice_seq to be the address of
 * the s1_ptr from which to remove elements.
 * The caller must also check to see if the ultimate target
 * (i.e., where this will ultimately be assigned) is the
 * same as the sequence from which elements are being
 * removed, as well as if the reference count on the
 * target is 1:
 *
 *    in_place = (*obj_ptr) == target && SEQ_PTR(target)->ref == 1
 *
 * Returns the resulting object (no change if in_place == 1).
 */
object Remove_elements(int start, int stop, int in_place )
{
	int n = stop-start+1;
	s1_ptr s1 = *assign_slice_seq;

	if (in_place) {
		int i;
		object_ptr p = s1->base + start;
		object_ptr q = s1->base + stop + 1;

		for (i=start;i<=stop;i++)
			DeRef( s1->base[i] );

		for( ; i <= s1->length+1; i++ ){
			*(p++) = *(q++);
		}

		s1->postfill += n;
		s1->length -= n;
		return MAKE_SEQ( s1 );
	}
	else {
		s1_ptr s2 = NewS1(s1->length-n);
		int i;
		object temp, *src = s1->base, *trg = s2->base;
		for ( i = 1; i < start; i++) {
			temp = *(++src);
			*(++trg) = temp;
			Ref(temp);
		}
        src = s1->base+stop;
		while (TRUE) {
			temp = *(++src);
			*(++trg) = temp;
			if (!IS_ATOM_INT(temp)) {
		    	if (temp == NOVALUE)
		      		break;
				RefDS(temp);
			}
		}
		return MAKE_SEQ( s2 );
// 		ASSIGN_SEQ(target, s2);
	}
}

void AssignElement(object what, int place, object_ptr target)
{
	s1_ptr s1 = *assign_slice_seq;
	if (UNIQUE(s1) && *target == (object)(*assign_slice_seq))
		{DeRef(*(s1->base+place));}
	else {
		s1_ptr s2 = NewS1(s1->length);
		int i;
		object temp, *src = s1->base, *trg = s2->base;
		for (i=1;i<place;i++) {
			temp = *(++src);
			*(++trg) = temp;
			if (!IS_ATOM_INT(temp))
				RefDS(temp);
		}
		*(++trg) = what;
		src++;
		while (TRUE) {
			temp = *(++src);
			*(++trg) = temp;
			if (!IS_ATOM_INT(temp)) {
		    	if (temp == NOVALUE)
		      		break;
				RefDS(temp);
			}
		}
		ASSIGN_SEQ(target, s2);
	}
}

void Concat(object_ptr target, object a_obj, object b_obj)
/* concatenate a & b, put result in new object c */
/* new object created - no copy needed to avoid circularity */
/* only handles seq & seq and atom & atom */
/* seq & atom done by append, atom & seq done by prepend */
{
	object_ptr p, q;
	s1_ptr c, a, b;
	long na, nb;
	object temp;

	if (IS_ATOM(a_obj)) {
		c = NewS1(2);
		/* both are atoms */
		*(c->base+1) = a_obj;
		Ref(a_obj);
		*(c->base+2) = b_obj;
		Ref(b_obj);
	}
	else {
		/* both are sequences */
		a = SEQ_PTR(a_obj);
		b = SEQ_PTR(b_obj);
		na = a->length;
		nb = b->length;

		if (a_obj == *target &&
			a->ref == 1 &&
			na > ((nb - a->postfill) << 3)) {
			/* try to update in-place */
			int insert;
			object temp;
			q = b->base+1;
			while (nb > 0) {
				insert = (nb <= a->postfill) ? nb : a->postfill;
				p = a->base + 1 + a->length;
				a->postfill -= insert;
				a->length += insert;
				nb -= insert;
				while (--insert >= 0) {
					temp = *q++;
					*p++ = temp;
					Ref(temp);
				}
				*p = NOVALUE; // end marker
				if (nb > 0) {
					Ref(*q);
					Append(target, a_obj, *q);
					a_obj = *target;
					a = SEQ_PTR(a_obj);
					nb--;
					q++;
				}
			}
			return;
		}
		c = NewS1(na + nb);
		p = c->base;
		q = a->base;
		while (TRUE) {  // NOVALUE will be copied
			temp = *(++q);
			*(++p) = temp;
			if (!IS_ATOM_INT(temp)) {
				if (temp == NOVALUE)
					break;
				RefDS(temp);
			}
		}
		q = b->base;
		while (TRUE) {  // NOVALUE will be copied
			temp = *(++q);
			*p++ = temp;
			if (!IS_ATOM_INT(temp)) {
				if (temp == NOVALUE)
					break;
				RefDS(temp);
			}
		}
	}

	ASSIGN_SEQ(target, c);
}

void Concat_N(object_ptr target, object_ptr  source, int n)
/* run-time library version for Translator
 * Concatenate n objects (n > 2). This is more efficient
 * than doing multiple calls to Concat() above, since we
 * can allocate space for the final result, and copy all
 * the data just one time.
 */
{
	s1_ptr result;
	object s_obj, temp;
	int i, size;
	object_ptr p, q;

	/* Compute the total size of all the operands */
	size = 0;
	for (i = 1; i <= n; i++) {
		s_obj = *source++;
		if (IS_ATOM(s_obj))
			size += 1;
		else
			size += SEQ_PTR(s_obj)->length;
	}

	/* Allocate the result sequence */
	result = NewS1(size);

	/* Copy the operands into the result. */
	/* The operands are in reverse order. */
	p = result->base+1;
	for (i = 1; i <= n; i++) {
		s_obj = *(--source);
		if (IS_ATOM(s_obj)) {
			*p++ = s_obj;
			Ref(s_obj);
		}
		else {
			/* sequence */
			q = SEQ_PTR(s_obj)->base;
			while (TRUE) {  // NOVALUE will be copied
				temp = *(++q);
				*p++ = temp;
				if (!IS_ATOM_INT(temp)) {
					if (temp == NOVALUE)
						break;
					RefDS(temp);
				}
			}
			p--;
		}
	}
	ASSIGN_SEQ(target, result);
}

void Concat_Ni(object_ptr target, object_ptr *source, int n)
/* version used by interpreter
 * Concatenate n objects (n > 2). This is more efficient
 * than doing multiple calls to Concat() above, since we
 * can allocate space for the final result, and copy all
 * the data just one time.
 */
{
	s1_ptr result;
	object s_obj, temp;
	int i, size;
	object_ptr p, q;

	/* Compute the total size of all the operands */
	size = 0;
	for (i = 1; i <= n; i++) {
		s_obj = **source++;
		if (IS_ATOM(s_obj))
			size += 1;
		else
			size += SEQ_PTR(s_obj)->length;
	}

	/* Allocate the result sequence */
	result = NewS1(size);

	/* Copy the operands into the result. */
	/* The operands are in reverse order. */
	p = result->base+1;
	for (i = 1; i <= n; i++) {
		s_obj = **(--source);
		if (IS_ATOM(s_obj)) {
			*p++ = s_obj;
			Ref(s_obj);
		}
		else {
			/* sequence */
			q = SEQ_PTR(s_obj)->base;
			while (TRUE) {  // NOVALUE will be copied
				temp = *(++q);
				*p++ = temp;
				if (!IS_ATOM_INT(temp)) {
					if (temp == NOVALUE)
						break;
					RefDS(temp);
				}
			}
			p--;
		}
	}

	ASSIGN_SEQ(target, result);
}

// used by translator
void RepeatElem(object *addr, object item, int repcount)
/* replicate an object in memory - used by RIGHT_BRACE op */
/* repcount will be at least 10 */
{
	if (IS_DBL_OR_SEQUENCE(item)) {
		(DBL_PTR(item)->ref) += repcount;
	}
	while (repcount-- > 0) {
		*addr++ = item;
	}
}

object Repeat(object item, object repcount)
/* generate a sequence of <item> repeated <count> times */
{
	object_ptr obj_ptr;

	long count;
	s1_ptr s1;

	if (IS_ATOM_INT(repcount)) {
		count = repcount;
	}

	else if (IS_ATOM_DBL(repcount)) {
		count = (long)(DBL_PTR(repcount)->dbl);
	}

	else
		RTFatal("repetition count must be an atom");

	if (count < 0)
		RTFatal("repetition count must not be less than 0");
	if (count > MAXINT_DBL)
		RTFatal("repetition count must not be more than %ld", MAXINT_DBL);


	s1 = NewS1(count);
	obj_ptr = s1->base+1;

	if (! IS_ATOM_INT(item)) {
		(DBL_PTR(item)->ref) += count;
	}

	while (count >= 10) {
		*obj_ptr++   = item; // 1
		*obj_ptr++   = item; // 2
		*obj_ptr++   = item; // 3
		*obj_ptr++   = item; // 4
		*obj_ptr++   = item; // 5
		*obj_ptr++   = item; // 6
		*obj_ptr++   = item; // 7
		*obj_ptr++   = item; // 8
		*obj_ptr++   = item; // 9
		*obj_ptr++   = item; // 10
		count -= 10;
	};

	while (count > 0) {
		*obj_ptr++ = item;
		count--;
	};

	return MAKE_SEQ(s1);
}

/**
 * Calls the specified translated routine id for cleaning up the
 * UDT object.
 */
void udt_clean_rt( object o, int rid ){
	int pre_ref;

	pre_ref = SEQ_PTR( o )->ref;
	if( pre_ref == 0 ){
		SEQ_PTR( o )->ref += 2;
	}
	else{
		RefDS( o );
	}
#ifdef EWINDOWS
	if( rt00[rid].convention ){
		// stdcall
		(*(int (__stdcall *)())rt00[rid].addr)( o );
	}
	else
#endif
	{ // cdecl
		(*(int ( *)())rt00[rid].addr)( o );
	}

	if( pre_ref == 0 ){
		SEQ_PTR( o )->ref -= 2;
	}
}

#ifndef ERUNTIME
/**
 * Calls the specified routine id for cleaning up the UDT object.
 */
void udt_clean( object o, uintptr_t rid ){

	intptr_t *code;
	char seq[8+2*sizeof(object)+sizeof(struct s1)]; // seq struct on the stack
	s1_ptr s;
	object args;
	int pre_ref;
	intptr_t *save_tpc;

	// Need to make sure that s is 8-byte aligned
	s = (s1_ptr)( ((object)&seq[7])  & ~7 );
	s->base = (((object_ptr)(s+1))-1);
	s->ref = 2;
	s->length = 1;
	s->postfill = 0;
	s->cleanup = 0;
	s->base[1] = o;
	s->base[2] = NOVALUE;

	pre_ref = SEQ_PTR(o)->ref;

	if( pre_ref == 0 ){
		SEQ_PTR( o )->ref += 2;
	}
	else{
		RefDS( o );
	}

	args = MAKE_SEQ( s );
	code = (object *)EMalloc( 4 * sizeof(object*) );
	code[0] = (object)opcode(CALL_PROC);
	code[1] = (object)&rid;
	code[2] = (object)&args;
	code[3] = (object)opcode(CALL_BACK_RETURN);
	if (expr_top >= expr_limit) {
		expr_max = BiggerStack();
		expr_limit = expr_max - 3;
	}
	*expr_top++ = (object)tpc;    // needed for traceback
	*expr_top = *(expr_top-2);  // prevents restore_privates()
	++expr_top;

	save_tpc = tpc;
	do_exec(code);  // execute routine without setting up new stack
	EFree((char *)code);

	tpc = save_tpc;
	expr_top -= 2;
	if( pre_ref == 0 ){
		SEQ_PTR(o)->ref -= 2;
	}
	else{
		DeRefDS( o );
	}
}
#endif

void cleanup_sequence( s1_ptr seq ){
	cleanup_ptr cp, next;

	cp = seq->cleanup;
	while( cp ){
		next = cp->next;
#ifndef ERUNTIME
		if( cp->type == CLEAN_UDT ){
			udt_clean( MAKE_SEQ(seq), cp->func.rid );
			if( next ){
				EFree( (char *)cp );
			}
		}
		else
#endif
		if( cp->type == CLEAN_UDT_RT ){
			udt_clean_rt( MAKE_SEQ(seq), cp->func.rid );
			if( next ){
				EFree( (char *)cp );
			}
		}
		else{
			(cp->func.builtin)( MAKE_SEQ( seq ) );
			EFree( (char *)cp );
		}
		cp = next;
	}
	seq->cleanup = 0;
}

void cleanup_double( d_ptr dbl ){
	cleanup_ptr cp, next;
	cp = dbl->cleanup;
	while( cp ){
		next = cp->next;
#ifndef ERUNTIME
		if( cp->type == CLEAN_UDT ){
			udt_clean( MAKE_DBL(dbl), cp->func.rid );
			if( next ){
				EFree( (char *)cp );
			}
		}
		else
#endif
		if( cp->type == CLEAN_UDT_RT ){
			udt_clean_rt( MAKE_DBL(dbl), cp->func.rid );
			if( next ){
				EFree( (char *)cp );
			}
		}
		else{
			(cp->func.builtin)( MAKE_DBL( dbl ) );
			EFree( (char *)cp );
		}

		cp = next;
	}
	dbl->cleanup = 0;
}

/* non-recursive - no chance of stack overflow */
void de_reference(s1_ptr a)
/* frees an object whose reference count is 0 */
/* a must not be an ATOM_INT */
{
	object_ptr p;
	object t;
	intptr_t temp;

#ifdef EXTRA_CHECK
	s1_ptr a1;

	if ((object)a == NOVALUE || IS_ATOM_INT(a))
		RTInternal("bad object passed to de_reference");
	if (DBL_PTR(a)->ref > 1000)
		RTInternal("more than 1000 refs");
#endif
	if (IS_ATOM_DBL(a)) {
#ifdef EXTRA_CHECK
		a1 = (s1_ptr)DBL_PTR(a);

		if (a1->ref < 0)
			RTInternal("f.p. reference count less than 0");
#endif
		a = (s1_ptr)DBL_PTR(a);
		if( ((d_ptr)a)->cleanup != 0 ){
			cleanup_double( (d_ptr)a );

			// user might have made a reference during cleanup;
			if( a->ref != 0 ){
				return;
			}
		}
		FreeD((unsigned char *)a);
	}

	else { /* SEQUENCE */
		/* sequence reference count has reached 0 */
		a = SEQ_PTR(a);
		if( a->cleanup != 0 ){
			cleanup_sequence( a );

			// user might have made a reference during cleanup
			if( a->ref != 0 ){
				return;
			}
		}
		p = a->base;
#ifdef EXTRA_CHECK
		if (a->ref < 0)
			RTInternal("sequence reference count less than 0");
		if (*(p+(a->length+1)) != NOVALUE)
			RTInternal("Sentinel missing!\n");
#endif
		while (TRUE) {
			p++;
			t = *p;
#ifdef EXTRA_CHECK
			if (t > MAXINT)
				RTInternal("de_reference: invalid object found!");
#endif
			if (!IS_ATOM_INT(t)) {

				if (t == NOVALUE) {
					// end of sequence: back up a level
					
					p = (object_ptr)a->cleanup;
					temp = (intptr_t) &(a->ref);
					t = *(object_ptr)temp;
					EFree((char *)a);
					a = (s1_ptr)t;
					if ((((intptr_t) a) & ((intptr_t) 0xffffffff)) == 0)
						break;  // it's the top-level sequence - quit
				}
				else if (--(DBL_PTR(t)->ref) == 0) {
					if (IS_ATOM_DBL(t)) {
						if( DBL_PTR(t)->cleanup != 0 ){
							cleanup_double( DBL_PTR(t) );
							// the user might have referenced this somewhere
							if((DBL_PTR(t)->ref) == 0){
								continue;
							}
						}
						FreeD((unsigned char *)DBL_PTR(t));
					}
					else {
						// switch to subsequence
						// was: de_reference((s1_ptr)t);
						t = (object)SEQ_PTR(t);
						if( ((s1_ptr)t)->cleanup != 0 ){
							cleanup_sequence( (s1_ptr)t );
						}
						temp  = (intptr_t) &((s1_ptr)t)->ref;
						*(intptr_t*)temp =  (intptr_t) a;
						
						temp  = (intptr_t) &((s1_ptr)t)->cleanup;
						*(intptr_t*) temp = (intptr_t) p;
						a = (s1_ptr)t;
						p = a->base;
					}
				}
			}
		}
	}
}

void DeRef1(object a)
/* Saves space. Use in top-level code (outside of loops) */
{
	DeRef(a);
}

void DeRef5(object a, object b, object c, object d, object e)
/* Saves space. Use instead of 5 in-line DeRef's */
{
	DeRef(a);
	DeRef(b);
	DeRef(c);
	DeRef(d);
	DeRef(e);
}

/* NEW - non-recursive - only integer elements */
void de_reference_i(s1_ptr a)
/* frees an object whose reference count is 0 */
/* We know that if there are any sequence elements,
   they will all be integers */
/* a must not be an ATOM_INT */
{


#ifdef EXTRA_CHECK
	s1_ptr a1;

	if ((object)a == NOVALUE || IS_ATOM_INT(a))
		RTInternal("bad object passed to de_reference");
	if (DBL_PTR(a)->ref > 1000)
		RTInternal("more than 1000 refs");
#endif
	if (IS_ATOM_DBL(a)) {
#ifdef EXTRA_CHECK
		a1 = (s1_ptr)DBL_PTR(a);
		if (a1->ref < 0)
			RTInternal("f.p. reference count less than 0");
#endif
		a = (s1_ptr)DBL_PTR(a);
		if( ((d_ptr)a)->cleanup != 0 ){
			cleanup_double( (d_ptr)a );

			// user might have made a reference during cleanup
			if( a->ref != 0 ){
				return;
			}
		}
		FreeD((unsigned char *)a);
	}

	else { /* SEQUENCE */
		/* sequence reference count has reached 0 */
		a = SEQ_PTR(a);
		if( a->cleanup != 0 ){
			cleanup_sequence( a );

			// user might have made a reference during cleanup
			if( a->ref != 0 ){
				return;
			}
		}
#ifdef EXTRA_CHECK
		if (a->ref < 0)
			RTInternal("sequence reference count less than 0");
#endif
		EFree((char *)a);
	}
}

object DoubleToInt(object d)
/* try to convert a double to an integer, if possible */
{
	eudouble temp_dbl;
	temp_dbl = DBL_PTR(d)->dbl;
	if (EUFLOOR(temp_dbl) == temp_dbl &&
		temp_dbl <= MAXINT_DBL &&
		temp_dbl >= MININT_DBL) {
			/* return it in integer repn */
			return (object)temp_dbl;
	}
	else{
		return d; /* couldn't convert */
	}
}


/* --- Binary Ops --- */

object x()
/* error routine */
{
#ifdef EXTRA_CHECK
	RTInternal("bad fcode");
#endif
	return NOVALUE;
}


object add(object a, object b)
/* integer add */
{
	object c;

	c = a + b;
	if (c + HIGH_BITS < 0)
		return MAKE_INT(c);
	else
		return (object)NewDouble((eudouble)c);
}

object minus(object a, object b)
/* integer subtract */
{
	object c;

	c = a - b;
	if (c + HIGH_BITS < 0)
		return MAKE_INT(c);
	else
		return (object)NewDouble((eudouble)c);
}

object multiply(object a, object b)
/* integer multiply */
/* n.b. char type is signed */
{
	// TODO: this condition changes for 64-bits...
	if (a == (short)a) {
		if ((b <= INT15 && b >= -INT15) ||
		   (a == (char)a && b <= INT23 && b >= -INT23) ||
		   (b == (short)b && a <= INT15 && a >= -INT15))
			return MAKE_INT(a * b);
	}
	else if (b == (char)b && a <= INT23 && a >= -INT23)
		return MAKE_INT(a * b);

	return (object)NewDouble(a * (eudouble)b);
}

object divide(object a, object b)
/* compute a / b */
{
	if (b == 0)
		RTFatal("attempt to divide by 0");
	if (a % b != 0)
		return (object)NewDouble((eudouble)a / b);
	else
		return MAKE_INT(a / b);
}

object Ddivide(d_ptr a, d_ptr b)
/* double divide */
{
	if (b->dbl == 0.0)
		RTFatal("attempt to divide by 0");
	return (object)NewDouble(a->dbl / b->dbl);
}

object eremainder(object a, object b)  // avoid conflict with "remainder" math fn
/* integer remainder of a divided by b */
{
	if (b == 0)
		RTFatal("can't get remainder of a number divided by 0");
	return MAKE_INT(a % b);
}


object Dremainder(d_ptr a, d_ptr b)
/* double remainder of a divided by b */
{
	if (b->dbl == 0.0)
		RTFatal("can't get remainder of a number divided by 0");
	return (object)NewDouble(fmod(a->dbl, b->dbl)); /* for now */
}

object and_bits(uintptr_t a, uintptr_t b)
/* integer a AND b */
{
	a = a & b;
	return MAKE_UINT(a);
}

object Dand_bits(d_ptr a, d_ptr b)
/* double a AND b */
{
#ifdef EARM
	return and_bits(doubletouintptrdiscardhighbits(a->dbl), doubletouintptrdiscardhighbits(b->dbl));
#else
	return and_bits( (uintptr_t)(a->dbl), (uintptr_t)(b->dbl));
#endif
}

object or_bits(uintptr_t a, uintptr_t b)
/* integer a OR b */
{
	a = a | b;
	return MAKE_UINT(a);
}


object Dor_bits(d_ptr a, d_ptr b)
/* double a OR b */
{
#ifdef EARM
	return or_bits(doubletouintptrdiscardhighbits(a->dbl), doubletouintptrdiscardhighbits(b->dbl));
#else
	return or_bits( (uintptr_t)(a->dbl), (uintptr_t)(b->dbl));
#endif
}

object xor_bits(uintptr_t a, uintptr_t b)
/* integer a XOR b */
{
	a = a ^ b;
	return MAKE_UINT(a);
}


object Dxor_bits(d_ptr a, d_ptr b)
/* double a XOR b */
{
#ifdef EARM
	return xor_bits(doubletouintptrdiscardhighbits(a->dbl), doubletouintptrdiscardhighbits(b->dbl));
#else
	return xor_bits((uintptr_t)(a->dbl), (uintptr_t)(b->dbl));
#endif
}

object not_bits(uintptr_t a)
/* integer bitwise NOT of a */
{
	a = ~a;
	return MAKE_UINT(a);
}


object Dnot_bits(d_ptr a)
/* double bitwise NOT of a */
{
#ifdef EARM
	return not_bits(doubletouintptrdiscardhighbits(a->dbl));
#else
	return not_bits((uintptr_t)(a->dbl));
#endif
}

#if defined(EFREEBSD) && INTPTR_MAX != INT32_MAX
long double powl( long double a, long double b ){
	return (long double) pow( (double) a, (double) b );
}
#endif

object power(object a, object b)
/* integer a to the power b */
{
	long i, p;

	if (a == 2 && b >= 0 && b <= 29) {
		/* positive power of 2 */
		return MAKE_INT(1 << b);
	}
	else if (a == 0 && b <= 0) {
		RTFatal("can't raise 0 to power <= 0");
	}
	else if (b == 0) {
		return ATOM_1;
	}
	else if (b >= 1 && b <= 4 && a >= -178 && a <= 178) {
		p = a;
		for (i = 2; i <= b; i++)
			p = p * a;
		return MAKE_INT(p);
	}
	else
		return (object)NewDouble(EUPOW((eudouble)a, (eudouble)b));
}

object Dpower(d_ptr a, d_ptr b)
/* double power */
{
	if (a->dbl == 0.0 && b->dbl <= 0.0)
		RTFatal("can't raise 0 to power <= 0");
	if (a->dbl < 0.0 && EUFLOOR(b->dbl) != b->dbl)
		RTFatal("can't raise negative number to non-integer power");
	return (object)NewDouble(EUPOW(a->dbl, b->dbl));
}

object equals(object a, object b)
/* integer a = b */
{
	if (a == b)
		return ATOM_1;
	else
		return ATOM_0;
}

object Dequals(d_ptr a, d_ptr b)
/* double a = b */
{
	if (a->dbl == b->dbl)
		return ATOM_1;
	else
		return ATOM_0;
}


object less(object a, object b)
/* integer a < b */
{
	if (a < b)
		return ATOM_1;
	else
		return ATOM_0;
}

object Dless(d_ptr a, d_ptr b)
/* double a < b */
{
	if (a->dbl < b->dbl)
		return ATOM_1;
	else
		return ATOM_0;
}


object greater(object a, object b)
/* integer a > b */
{
	if (a > b)
		return ATOM_1;
	else
		return ATOM_0;
}

object Dgreater(d_ptr a, d_ptr b)
/* double a > b */
{
	if (a->dbl > b->dbl) {
		return ATOM_1;
	}
	else {
		return ATOM_0;
	}
}


object noteq(object a, object b)
/* integer a != b */
{
	if (a != b)
		return ATOM_1;
	else
		return ATOM_0;
}

object Dnoteq(d_ptr a, d_ptr b)
/* double a != b */
{
	if (a->dbl != b->dbl)
		return ATOM_1;
	else
		return ATOM_0;
}


object lesseq(object a, object b)
/* integer a <= b */
{
	if (a <= b)
		return ATOM_1;
	else
		return ATOM_0;
}

object Dlesseq(d_ptr a, d_ptr b)
/* double a <= b */
{
	if (a->dbl <= b->dbl)
		return ATOM_1;
	else
		return ATOM_0;
}


object greatereq(object a, object b)
/* integer a >= b */
{
	if (a >= b)
		return ATOM_1;
	else
		return ATOM_0;
}

object Dgreatereq(d_ptr a, d_ptr b)
/* double a >= b */
{
	if (a->dbl >= b->dbl)
		return ATOM_1;
	else
		return ATOM_0;
}


object and(object a, object b)
/* integer a and b */
{
	if (a != 0 && b != 0)
		return ATOM_1;
	else
		return ATOM_0;
}

object Dand(d_ptr a, d_ptr b)
/* double a and b */
{
	if (a->dbl != 0.0 && b->dbl != 0.0)
		return ATOM_1;
	else
		return ATOM_0;
}


object or(object a, object b)
/* integer a or b */
{
	if (a != 0 || b != 0)
		return ATOM_1;
	else
		return ATOM_0;
}

object Dor(d_ptr a, d_ptr b)
/* double a or b */
{
	if (a->dbl != 0.0 || b->dbl != 0.0)
		 return ATOM_1;
	 else
		 return ATOM_0;
}

object xor(object a, object b)
/* integer a xor b */
{
	if ((a != 0) != (b != 0))
		return ATOM_1;
	else
		return ATOM_0;
}

object Dxor(d_ptr a, d_ptr b)
/* double a xor b */
{
	if ((a->dbl != 0.0) != (b->dbl != 0.0))
		 return ATOM_1;
	 else
		 return ATOM_0;
}

/* --- Unary Ops --- */

object uminus(object a)
/* integer -a */
{
	if (a == MININT)
		return (object)NewDouble((eudouble)-MININT);
	else
		return MAKE_INT(-a);
}

object Duminus(d_ptr a)
/* double -a */
{
	return (object)NewDouble(-a->dbl);
}


object not(object a)
/* compute c := not a */
{
	if (a == 0)
		return ATOM_1;
	else
		return ATOM_0;
}

object Dnot(d_ptr a)
/* double not a */
{
	if (a->dbl == 0.0)
		return ATOM_1;
	else
		return ATOM_0;
}


object e_sqrt(object a)
/* integer square_root(a) */
{
	if (a < 0)
		RTFatal("attempt to take square root of a negative number");
	return (object)NewDouble( sqrt((double)a) );
}

object De_sqrt(d_ptr a)
/* double square root(a) */
{
	if (a->dbl < 0)
		RTFatal("attempt to take square root of a negative number");
	return (object)NewDouble( sqrt(a->dbl) );
}


object e_sin(object a)
/* sin of an angle a (radians) */
{
	return (object)NewDouble( sin((double)a) );
}

object De_sin(d_ptr a)
/* double sin of a */
{
	return (object)NewDouble( sin(a->dbl) );
}

object e_cos(object a)
/* cos of an angle a (radians) */
{
	return (object)NewDouble( cos((double)a) );
}

object De_cos(d_ptr a)
/* double cos of a */
{
	return (object)NewDouble( cos(a->dbl) );
}

object e_tan(object a)
/* tan of an angle a (radians) */
{
	return (object)NewDouble( tan((double)a) );
}

object De_tan(d_ptr a)
/* double tan of a */
{
	return (object)NewDouble( tan(a->dbl) );
}

object e_arctan(object a)
/* arctan of an angle a (radians) */
{
	return (object)NewDouble( atan((double)a) );
}

object De_arctan(d_ptr a)
/* double arctan of a */
{
	return (object)NewDouble( atan(a->dbl) );
}

object e_log(object a)
/* natural log of a (integer) */
{
	if (a <= 0)
		RTFatal("may only take log of a positive number");
	return (object)NewDouble( log((double)a) );
}

object De_log(d_ptr a)
/* natural log of a (double) */
{
	if (a->dbl <= 0.0)
		RTFatal("may only take log of a positive number");
	return (object)NewDouble( log(a->dbl) );
}

object e_floor(object a)  // not used anymore
/* floor of a number - no op since a is already known to be an int */
{
	return a;
}

object De_floor(d_ptr a)
/* floor of a number */
{
	eudouble temp;

	temp = EUFLOOR(a->dbl);
#ifndef ERUNTIME
	if (fabs(temp) < MAXINT_DBL)
		return MAKE_INT((object)temp);
	else
#endif
		return (object)NewDouble(temp);
}

#define V(a,b) ((((a) << 1) | (a & 0x1)) ^ ((((b) >> 14) & 0x0000FFFF) | ((b) << 18)))

#define prim1 ((int32_t)2147483563)
#define prim2 ((int32_t)2147483399)

#define root1 ((int32_t)40014)
#define root2 ((int32_t)40692)

#define quo1 ((int32_t)53668)  /* prim1 / root1 */
#define quo2 ((int32_t)52774)  /* prim2 / root2 */

#define rem1 ((int32_t)12211)  /* prim1 % root1 */
#define rem2 ((int32_t)3791)   /* prim2 % root2 */

/* set random seed1 and seed2 - neither can be 0 */
void setran()
{
	time_t time_of_day;
	struct tm *local;
#if !defined( EWINDOWS )
	object garbage;
#endif
	static int32_t src = prim1 ^ prim2;

	time_of_day = time(NULL);
	local = localtime(&time_of_day);
	seed2 = local->tm_yday * 86400 + local->tm_hour * 3600 +
			local->tm_min * 60 +     local->tm_sec;
#ifdef EWINDOWS
	seed1 = GetTickCount() + src;  // milliseconds since Windows started
#else
	seed1 = (int32_t)(0xffffffff & (uintptr_t)&garbage) + random() + src;
#endif
	src += 1;
	good_rand();  // skip first one, second will be more random-looking
}

static ldiv_t my_ldiv (int32_t numer, int32_t denom)
{
	ldiv_t result;

	result.quot = (int32_t) numer / denom;
	result.rem =  (int32_t) numer % denom;

	if (numer >= 0 && result.rem < 0)   {
		++result.quot;
		result.rem -= denom;
	}

	return result;
}

int32_t good_rand()
/* Public Domain random number generator from USENET posting */
{
	ldiv_t temp;
	int32_t remval, quotval;

	if (!rand_was_set && seed1 == 0 && seed2 == 0) {
		// First time thru.
		setran();
	}

	/* seed = seed * ROOT % PRIME */
	temp = my_ldiv(seed1, quo1);
	remval = root1 * (int32_t) temp.rem;
	quotval = rem1 * (int32_t) temp.quot;

	/* normalize */
	seed1 = remval - quotval;
	if (remval <= quotval)
		seed1 += prim1;

	temp = my_ldiv(seed2, quo2);
	remval = root2 * temp.rem;
	quotval = rem2 * temp.quot;

	seed2 = remval - quotval;
	if (remval <= quotval)
		seed2 += prim2;

	if (seed1 == 0) {
		seed1 = prim2;
	}
	if (seed2 == 0)
		seed2 = prim1;

	return V(seed1, seed2);
}

object Random(object a)
/* random number from 1 to a */
/* a is a legal integer value */
{
	if (a <= 0)
		RTFatal("argument to rand must be >= 1");
	return MAKE_INT((good_rand() % (uint32_t)a) + 1);
}


object DRandom(d_ptr a)
/* random number from 1 to a (a <= 1.07 billion) */
{
	unsigned long res;

	if (a->dbl < 1.0)
		RTFatal("argument to rand must be >= 1");
	if ((uint32_t)(a->dbl) <= 0)
		RTFatal("argument to rand is too large");
	res = (1 + good_rand() % (uint32_t)(a->dbl));
	return MAKE_UINT(res);
}


object unary_op(int fn, object a)
/* recursive evaluation of a unary op
   c may be the same as a. ATOM_INT case handled in-line by caller */
{
	int length;
	object_ptr ap, cp;
	object x;
	s1_ptr c;
	object (*int_fn)();

	if (IS_ATOM_DBL(a))
		return (*optable[fn].dblfn)(DBL_PTR(a));

	else {
		/* a must be a SEQUENCE */
		a = (object)SEQ_PTR(a);
		length = ((s1_ptr)a)->length;
		c = NewS1(length);
		cp = c->base;
		ap = ((s1_ptr)a)->base;
		int_fn = optable[fn].intfn;
		while (TRUE) {
			x = *(++ap);
			if (IS_ATOM_INT(x)) {
				*(++cp) = (*int_fn)(INT_VAL(x));
			}
			else {
				if (x == NOVALUE)
					break;
				*(++cp) = unary_op(fn, x);
			}
		}
		return MAKE_SEQ(c);
	}
}


object binary_op_a(int fn, object a, object b)
/* perform binary op on two atoms */
{
	struct d temp_d;

	if (IS_ATOM_INT(a)) {
		if (IS_ATOM_INT(b)){
			return (*optable[fn].intfn)(INT_VAL(a), INT_VAL(b));
		}
		else {
			temp_d.dbl = (eudouble)INT_VAL(a);
			return (*optable[fn].dblfn)(&temp_d, DBL_PTR(b));
		}
	}
	else {
		if (IS_ATOM_INT(b)) {
			temp_d.dbl = (eudouble)INT_VAL(b);
			return (*optable[fn].dblfn)(DBL_PTR(a), &temp_d);
		}
		else
			return (*optable[fn].dblfn)(DBL_PTR(a), DBL_PTR(b));
	}
}


object binary_op(int fn, object a, object b)
/* Recursively calculates fn of a and b. */
/* Caller must handle INT:INT case */
{
	int length;
	object_ptr ap, bp, cp;
	struct d temp_d;
	s1_ptr c;
	object (*int_fn)();
	object x;

	/* handle all ATOM:ATOM cases except INT:INT - not allowed
	   n.b. IS_ATOM_DBL actually only distinguishes ATOMS from SEQUENCES */
	if (IS_ATOM_INT(a) && IS_ATOM_DBL(b)) {
		/* in test above b can't be an int if a is */
		temp_d.dbl = (eudouble)INT_VAL(a);
		return (*optable[fn].dblfn)(&temp_d, DBL_PTR(b));
	}
	else if (IS_ATOM_DBL(a)) {
		/* a could be an int, but then b must be a sequence */
		if (IS_ATOM_INT(b)) {
			temp_d.dbl = (eudouble)INT_VAL(b);
			return (*optable[fn].dblfn)(DBL_PTR(a), &temp_d);
		}
		else if (IS_ATOM_DBL(b))  {
			return (*optable[fn].dblfn)(DBL_PTR(a), DBL_PTR(b));
		}
	}

	/* result is a sequence */
	int_fn = optable[fn].intfn;
	if (IS_ATOM(a)) {
		/* b must be a sequence */
		b = (object)SEQ_PTR(b);
		length = ((s1_ptr)b)->length;
		c = NewS1(length);
		cp = c->base;
		bp = ((s1_ptr)b)->base;
		if (IS_ATOM_INT(a)) {
			while (TRUE) {
				x = *(++bp);
				if (IS_ATOM_INT(x)) {
					*(++cp) = (*int_fn)(INT_VAL(a), INT_VAL(x));
				}
				else {
					if (x == NOVALUE)
						break;
					*(++cp) = binary_op(fn, a, x);
				}
			}
		}
		else {
			// a is not an integer
			while (--length >= 0) {
				*(++cp) = binary_op(fn, a, *(++bp));
			}
		}
	}
	else if (IS_ATOM(b)) {
		/* a must be a sequence */
		a = (object)SEQ_PTR(a);
		length = ((s1_ptr)a)->length;
		c = NewS1(length);
		cp = c->base;
		ap = ((s1_ptr)a)->base;
		if (IS_ATOM_INT(b)) {
			while (TRUE) {
				x = *(++ap);
				if (IS_ATOM_INT(x)) {
					*(++cp) = (*int_fn)(INT_VAL(x), INT_VAL(b));
				}
				else {
					if (x == NOVALUE)
						break;
					*(++cp) = binary_op(fn, x, b);
				}
			}
		}
		else {
			// b is not an integer
			while (--length >= 0) {
				*(++cp) = binary_op(fn, *(++ap), b);
			}
		}
	}
	else {
		/* a and b must both be sequences */
		a = (object)SEQ_PTR(a);
		b = (object)SEQ_PTR(b);
		length = ((s1_ptr)a)->length;
		if (length != ((s1_ptr)b)->length) {
			RTFatal("sequence lengths are not the same (%ld != %ld)",
					length, ((s1_ptr)b)->length);
		}
		c = NewS1(length);
		cp = c->base;
		ap = ((s1_ptr)a)->base;
		bp = ((s1_ptr)b)->base+1;
		while (TRUE) {
			x = *(++ap);
			if (IS_ATOM_INT(x) && IS_ATOM_INT(*bp)) {
				*(++cp) = (*int_fn)(INT_VAL(x), INT_VAL(*bp++));
			}
			else {
				if (x == NOVALUE)
					break;
				*(++cp) = binary_op(fn, x, *bp++);
			}
		}
	}
	return MAKE_SEQ(c);
}

/* When hashing, we treat doubles differently from integers.  But if a 
 * double can be represented as an integer, we want to use that.
 */
#define IS_DOUBLE_AN_INTEGER( X ) \
if( !IS_ATOM_INT( X ) && IS_ATOM( X ) ){ \
	double TMP_dbl = DBL_PTR( X )->dbl; \
	if( TMP_dbl == (eudouble)(object)TMP_dbl ){\
		X = (object)TMP_dbl;\
	}\
}\

object calc_MD5(object a)
{
#if 0
// TODO: MD5 Unimplemented!
	object lTempResult;
	long lSLen;
	int tfi;
	union TF
	{
		double ieee_double;
		unsigned char tfc[8];
	} tf;

	object_ptr ap;
	object av;


	IS_DOUBLE_AN_INTEGER(a)
	if (IS_ATOM_INT(a)) {
	}
	else if (IS_ATOM_DBL(a)) {
		tf.ieee_double = (DBL_PTR(a)->dbl);
		for(tfi = 0; tfi < 8; tfi++)
		{
		}
	}
	else { // input is a sequence
		lSLen = SEQ_PTR(a)->length;
		ap = SEQ_PTR(a)->base;
		while (lSLen > 0) {
			av = *(++ap);
			if (av == NOVALUE) {
				break;  // we hit the end marker
			}

			if (IS_ATOM_INT(av)) {
			}
			else if (IS_ATOM_DBL(av)) {
				tf.ieee_double = (DBL_PTR(av)->dbl);
				for(tfi = 0; tfi < 8; tfi++)
				{
				}
			}
			else {
				lTempResult = calc_MD5(av);
			}
			lSLen--;
		}
	}
#endif
	return a ^ a;
}

object calc_SHA256(object a)
{
#if 0
// TODO: SHA256 Unimplemented!
	object lTempResult;
	long lSLen;
	int tfi;
	union TF
	{
		double ieee_double;
		unsigned char tfc[8];
	} tf;

	object_ptr ap;
	object av;


	IS_DOUBLE_AN_INTEGER(a)
	if (IS_ATOM_INT(a)) {
	}
	else if (IS_ATOM_DBL(a)) {
		tf.ieee_double = (DBL_PTR(a)->dbl);
		for(tfi = 0; tfi < 8; tfi++)
		{
		}
	}
	else { // input is a sequence
		lSLen = SEQ_PTR(a)->length;
		ap = SEQ_PTR(a)->base;
		while (lSLen > 0) {
			av = *(++ap);
			if (av == NOVALUE) {
				break;  // we hit the end marker
			}

			IS_DOUBLE_AN_INTEGER(av)
			if (IS_ATOM_INT(av)) {
			}
			else if (IS_ATOM_DBL(av)) {
				tf.ieee_double = (DBL_PTR(av)->dbl);
				for(tfi = 0; tfi < 8; tfi++)
				{
				}
			}
			else {
				lTempResult = calc_SHA256(av);
			}
			lSLen--;
		}
	}
#endif
	return a ^ a;
}



unsigned int calc_adler32(object a)
{

	long lSLen;
	int tfi;
	union TF
	{
		double ieee_double;
		unsigned char tfc[8];
	} tf;
	unsigned int lA;
	unsigned int lB;
	unsigned int lC;

	object_ptr ap;
	object av;

	lA = 1;
	lB = 0;

	IS_DOUBLE_AN_INTEGER(a)
	if (IS_ATOM_INT(a)) {
		lA +=  a; if (lA >= 65521) lA %= 65521;
		lB +=  lA; if (lB >= 65521) lB %= 65521;
	}
	else if (IS_ATOM_DBL(a)) {
		tf.ieee_double = (DBL_PTR(a)->dbl);
		for(tfi = 0; tfi < 8; tfi++)
		{
			lA += tf.tfc[tfi]; if (lA >= 65521) lA %= 65521;
			lB += lA; if (lB >= 65521) lB %= 65521;
		}
	}
	else { /* input is a sequence */
		lSLen = SEQ_PTR(a)->length;

		ap = SEQ_PTR(a)->base;
		while (lSLen > 0) {
			av = *(++ap);
			if (av == NOVALUE) {
				break;  // we hit the end marker
			}

			IS_DOUBLE_AN_INTEGER(av)
			if (IS_ATOM_INT(av)) {
				lA += av; if (lA >= 65521) lA %= 65521;
				lB += lA; if (lB >= 65521) lB %= 65521;
			}
			else if (IS_ATOM_DBL(av)) {
				tf.ieee_double = (DBL_PTR(av)->dbl);
				for(tfi = 0; tfi < 8; tfi++)
				{
					lA += tf.tfc[tfi]; if (lA >= 65521) lA %= 65521;
					lB += lA; if (lB >= 65521) lB %= 65521;
				}
			}
			else {
				lC = calc_adler32(av);
				lA += lC & 0x0000FFFF; if (lA >= 65521) lA %= 65521;
				lB += (lC >> 16) & 0x0000FFFF; if (lB >= 65521) lB %= 65521;
			}
			lSLen--;
		}
	}

	return ((lB << 16) | lA);
}

// hsieh32 hash is Copyright 2004-2008 by Paul Hsieh , http://www.azillionmonkeys.com/qed/hash.html

#include "stdint.h"
#undef get16bits
#if defined(__X86__) || defined(__i386__)
#define get16bits(d) (*((const uint16_t *) (d)))
#endif

#if !defined (get16bits)
#define get16bits(d) ((((unsigned int)(((const uint8_t *)(d))[1])) << 8)\
                       +(unsigned int)(((const uint8_t *)(d))[0]) )
#endif


static unsigned int hsieh32(char *data, int len, unsigned int starthash)
{

 	int rem;
 	unsigned int tmp;
 	unsigned int hash;

    if (len <= 0 || data == NULL) return 0;
 	hash = starthash;
    rem = len & 3;
    len >>= 2;
    /* Main loop */
    for (;len > 0; len--) {
        hash  += get16bits (data);
        tmp    = (get16bits (data+2) << 11) ^ hash;
        hash   = (hash << 16) ^ tmp;
        data  += 4; // 2*sizeof (uint16_t);
        hash  += hash >> 11;
    }

    /* Handle end cases */
    switch (rem) {
        case 3: hash += get16bits (data);
                hash ^= hash << 16;
                hash ^= data[sizeof (uint16_t)] << 18;
                hash += hash >> 11;
                break;
        case 2: hash += get16bits (data);
                hash ^= hash << 11;
                hash += hash >> 17;
                break;
        case 1: hash += *data;
                hash ^= hash << 10;
                hash += hash >> 1;
    }

    /* Force "avalanching" of final 127 bits */
    hash ^= hash << 3;
    hash += hash >> 5;
    hash ^= hash << 4;
    hash += hash >> 17;
    hash ^= hash << 25;
    hash += hash >> 6;

    return hash;
}

char *hsieh_tempstr  = 0;
int   hsieh_tempsize = 0;
static uint32_t calc_hsieh32(object a)
{


	union TF
	{
		double ieee_double;
		int32_t    integer;
		char tfc[8];
	} tf;

	object_ptr ap;
	object av;
	char *sp;
	int slen;
 	uint32_t lHashVal;
	int has_string;

	sp = 0;
	IS_DOUBLE_AN_INTEGER(a)
	if (IS_ATOM_INT(a)) {
	 	tf.integer = a;
	 	lHashVal = hsieh32(tf.tfc, 4, a*2 - 1);
 	}
	else if (IS_ATOM_DBL(a)) {
 		tf.ieee_double = (DBL_PTR(a)->dbl);
 		lHashVal = hsieh32(tf.tfc, 8, 8);
	}
	else { /* input is a sequence */
		slen = SEQ_PTR(a)->length;
		if (slen == 0)
			return 0;

		lHashVal = slen;
		ap = SEQ_PTR(a)->base;
		// Check for a byte array first.
		has_string = 0;
		while (slen > 0) {
			av = *(++ap);
			slen--;
			if (av == NOVALUE) {
				break;  // we hit the end marker
			}

			IS_DOUBLE_AN_INTEGER(av)
			if (IS_ATOM_INT(av)) {
				if (av >= 0 && av <= 255) {
					if ( !has_string ){
						if(hsieh_tempstr == 0 || ( (SEQ_PTR(a)->length) > hsieh_tempsize) ) {
							hsieh_tempsize = SEQ_PTR(a)->length;
							if( hsieh_tempstr != 0 ){
								hsieh_tempstr = ERealloc( hsieh_tempstr, hsieh_tempsize );
							}
							else{
								hsieh_tempstr = EMalloc( hsieh_tempsize );
							}
						}
						sp = hsieh_tempstr;
						has_string = 1;
					}
					
					*sp = (char)av;
					sp++;
				}
				else {
					has_string = 0;
					break;
				}
			}
			else {
				has_string = 0;
				break;
			}
		}
		if (has_string != 0) {
			lHashVal = hsieh32( hsieh_tempstr, SEQ_PTR(a)->length, lHashVal);
		}
		else {
			slen = SEQ_PTR(a)->length;
			ap = SEQ_PTR(a)->base;
			while (slen > 0) {
				av = *(++ap);
				slen--;
				if (av == NOVALUE) {
					break;  // we hit the end marker
				}

				IS_DOUBLE_AN_INTEGER(av)
				if (IS_ATOM_INT(av)) {
				 	tf.integer = av;
				 	lHashVal = hsieh32(tf.tfc, 4, lHashVal);
				}
				else if (IS_ATOM_DBL(av)) {
					tf.ieee_double = (DBL_PTR(av)->dbl);
			 		lHashVal = hsieh32(tf.tfc, 8, lHashVal);
				}
				else {
					lHashVal ^= calc_hsieh32(av);
				}
			}
		}
	}


	return lHashVal;
}


static uint32_t calc_hsieh30(object a)
{

	uint32_t i32;
	
	i32 = calc_hsieh32(a);
	return (0x3FFFFFFF & (i32 + ((0xC0000000 & i32) >> 30)));
}

unsigned int calc_fletcher32(object a)
{

	long lSLen;
	int tfi;
	union TF
	{
		double ieee_double;
		unsigned short tfc[4];
	} tf;
	unsigned int lA;
	unsigned int lB;
	unsigned int lC;

	object_ptr ap;
	object av;

	lA = 1;
	lB = 0;

	IS_DOUBLE_AN_INTEGER(a)
	if (IS_ATOM_INT(a)) {
		lA +=  a;
		lB +=  lA;
	}
	else if (IS_ATOM_DBL(a)) {
		double a_dbl = (DBL_PTR(a)->dbl);
		if( a_dbl == (double)(object)a_dbl ){
			a = (object) a_dbl;
			lA +=  a;
			lB +=  lA;
		}
		else{
			tf.ieee_double = a_dbl;
			for(tfi = 0; tfi < 4; tfi++)
			{
				lA += tf.tfc[tfi];
				lB += lA;
			}
		}
	}
	else { /* input is a sequence */
		int lChar;

		lSLen = SEQ_PTR(a)->length;
		lChar = -1;

		ap = SEQ_PTR(a)->base;
		while (lSLen > 0) {
			av = *(++ap);
			if (av == NOVALUE) {
				break;  // we hit the end marker
			}

			IS_DOUBLE_AN_INTEGER(av)
			
			if (IS_ATOM_INT(av)) {
				if (av < 256)
				{
					if (lChar == -1) {
						lChar = av;
					} else {
						lA += (av + lChar) << 8;
						lChar = -1;
						lB += lA;
					}
				}
				else
				{
					lA += av;
					lB += lA;
				}
			}
			else if (IS_ATOM_DBL(av)) {
				tf.ieee_double = (DBL_PTR(av)->dbl);
				for(tfi = 0; tfi < 4; tfi++)
				{
					lA += tf.tfc[tfi];
					lB += lA;
				}
			}
			else {
				lC = calc_fletcher32(av);
				lA += lC & 0x0000FFFF;
				lB += (lC >> 16) & 0x0000FFFF;
			}
			lSLen--;
		}
		if (lChar != -1) {
			lA += lChar << 8;
			lB += lA;
		}

	}

	return ((lB << 16) | lA);

}

#define rol(a,b) (((a) << b) | ((a) >> (32 - b)))
object calc_hash(object a, object b)
/* calculate the hash value of object a.
   b influences the style of hash calculated.
   b ==> -1 SHA256
   b ==> -2 MD5
   b ==> -3 Fletcher-32
   b ==> -4 Adler-32
   b ==> -5 Hsieh-32
   b ==> >=0 and  <1 69096 + b
   b ==> >=1 hash = (hash * b + x)

*/
{
	uint32_t lHashValue;
	int32_t lSLen;


	int32_t tfi;
	object lTemp;

	union TF
	{
		double ieee_double;
		struct dbllong
		{
			uint32_t a;
			uint32_t b;
		} ieee_uint;
		uint8_t ieee_char[8];
	} tf, seeder, prev;

	object_ptr ap, lp;
	object av, lv;

	IS_DOUBLE_AN_INTEGER(a)
	if (IS_ATOM_INT(b)) {
		if (b == -6)
			return calc_hsieh30(a);	// Will always return a Euphoria integer.

		if (b == -5)
			return make_atom32(calc_hsieh32(a));

		if (b == -4)
			return make_atom32(calc_adler32(a));

		if (b == -3)
			return make_atom32(calc_fletcher32(a));

		if (b == -2)
			return calc_MD5(a);

		if (b == -1)
			return calc_SHA256(a);

		if (b < 0)
			RTFatal("second argument of hash() must not be a negative integer.");
		
		if (b == 0)
		{
			if (IS_ATOM_INT(a)) {
				tf.ieee_double = 69096.0 + (double)a;
			}
			else if (IS_ATOM_DBL(a)) {
				tf.ieee_double = 3690961.0 + (DBL_PTR(a)->dbl);
			}
			else {
				tf.ieee_double = 196069.10 + (double)(SEQ_PTR(a)->length);
			}
			tf.ieee_uint.a &= MAXINT32;
			if (tf.ieee_uint.a == 0) {
				tf.ieee_uint.a = MAXINT32;
			}
			
			lTemp = calc_hash(a, (uint32_t)tf.ieee_uint.a);

			if (IS_ATOM_INT(lTemp)) {
				seeder.ieee_uint.a = lTemp;
				seeder.ieee_uint.b = rol(lTemp, 15);
			}
			else {
				seeder.ieee_double = (DBL_PTR(lTemp)->dbl);
			}
			DeRef(lTemp);
		}
		else {
			seeder.ieee_uint.a = b;
			seeder.ieee_uint.b = rol(b, 15);
		}
	}
	else if (IS_ATOM_DBL(b)) {
		seeder.ieee_double = (DBL_PTR(b)->dbl);
	}
	else {
		lTemp = calc_hash(b, 16063 + (uint32_t)(SEQ_PTR(b)->length));
		if (IS_ATOM_INT(lTemp)) {
			seeder.ieee_uint.a = lTemp;
			seeder.ieee_uint.b = rol(lTemp, 15);
		}
		else {
			seeder.ieee_double = (DBL_PTR(lTemp)->dbl);
		}
		DeRef(lTemp);
	}

	lHashValue = 0x193A74F1;

	for(tfi = 0; tfi < 8; tfi++)
	{
		if (seeder.ieee_char[tfi] == 0)
			seeder.ieee_char[tfi] = (uint8_t)(tfi * 171 + 1);
		seeder.ieee_char[tfi] += (tfi + 1) << 8;
		
		lHashValue = rol(lHashValue, 3) ^ seeder.ieee_char[tfi];
	}
	if (IS_ATOM_INT(a)) {
		tf.ieee_uint.a = a;
		tf.ieee_uint.b = rol(a, 15);
		for(tfi = 0; tfi < 8; tfi++)
		{
			if (tf.ieee_char[tfi] == 0)
				tf.ieee_char[tfi] = (uint8_t)(tfi * 171 + 1);
			lHashValue = rol(lHashValue, 3) ^ ((tf.ieee_char[tfi] + (tfi + 1)) << 8);
		}
	}
	else if (IS_ATOM_DBL(a)) {
		tf.ieee_double = ((DBL_PTR(a)->dbl));
		for(tfi = 0; tfi < 8; tfi++)
		{
			if (tf.ieee_char[tfi] == 0)
				tf.ieee_char[tfi] = (uint8_t)(tfi * 171 + 1);
			lHashValue = rol(lHashValue, 3) ^ ((tf.ieee_char[tfi] + (tfi + 1)) << 8);
		}
	}
	else { /* input is a sequence */
		lSLen = SEQ_PTR(a)->length;
		lHashValue += lSLen + 3;
		ap = SEQ_PTR(a)->base;
		lp = ap + lSLen + 1;
		while (lSLen > 0) {
			av = *(++ap);
			lv = *(--lp);
			if (av == NOVALUE) {
				break;  // we hit the end marker
			}

			for(tfi = 0; tfi < 8; tfi++)
			{
				lHashValue = rol(lHashValue, 3) ^ seeder.ieee_char[tfi];
			}

			IS_DOUBLE_AN_INTEGER( lv )
			if (IS_ATOM_INT(lv)) {
				prev.ieee_uint.a = lv;
				prev.ieee_uint.b = rol(lv, 15);
			}
			else if (IS_ATOM_DBL(lv)) {
				prev.ieee_double = (DBL_PTR(lv)->dbl);
			}
			else {
				lv = (uint32_t)(SEQ_PTR(lv)->length);
				prev.ieee_uint.a = lv;
				prev.ieee_uint.b = rol(lv, 15);
			}

			IS_DOUBLE_AN_INTEGER( av )
			if (IS_ATOM_INT(av)) {
				tf.ieee_uint.a = av;
				tf.ieee_uint.b = rol(av, 15);
			}
			else if (IS_ATOM_DBL(av)) {
				tf.ieee_double = DBL_PTR(av)->dbl;
			}
			else if (IS_SEQUENCE(av))
			{
				lTemp = calc_hash(av,b);
				if (IS_ATOM_INT(lTemp))
				{
					tf.ieee_uint.a = lTemp;
					tf.ieee_uint.b = rol(lTemp, 15);
				}
				else //	if (IS_ATOM_DBL(lTemp))
				{
					tf.ieee_double = (DBL_PTR(lTemp)->dbl);
				}
				DeRef(lTemp);
			}

			tf.ieee_uint.a += prev.ieee_uint.b;
			tf.ieee_uint.b += prev.ieee_uint.a;
			for(tfi = 0; tfi < 8; tfi++)
			{
				if (tf.ieee_char[tfi] == 0)
					tf.ieee_char[tfi] = (uint8_t)(tfi * 171 + 1);
				lHashValue = rol(lHashValue, 3) ^ ((tf.ieee_char[tfi] + (tfi + 1)) << 8);
			}
			lHashValue = rol(lHashValue,1);
			lSLen--;
		}
	}
	
	if (lHashValue  > MAXINT32 ) {
		return NewDouble((eudouble)lHashValue);
	}
	else {
		return (int32_t)MAKE_INT(lHashValue);
	}

}

object compare(object a, object b)
/* Compare general objects a and b. Return 0 if they are identical,
   1 if a > b, -1 if a < b. All atoms are less than all sequences.
   The INT-INT case *must* be taken care of by the caller */
{
	object_ptr ap, bp;
	object av, bv;
	int length, lengtha, lengthb;
	eudouble da, db;
	int c;

	if (IS_ATOM(a)) {
		if (!IS_ATOM(b))
			return -1;
		if (IS_ATOM_INT(a)) {
			/* b *must* be a double */
			da = (eudouble)a;
			db = DBL_PTR(b)->dbl;
		}
		else {
			da = DBL_PTR(a)->dbl;
			if (IS_ATOM_INT(b))
				db = (eudouble)b;
			else
				db = DBL_PTR(b)->dbl;
		}
		return (da < db) ? -1: (da == db) ? 0: 1;
	}

	else {
		/* a must be a SEQUENCE */
		if (!IS_SEQUENCE(b))
			return 1;
		a = (object)SEQ_PTR(a);
		b = (object)SEQ_PTR(b);
		ap = ((s1_ptr)a)->base;
		bp = ((s1_ptr)b)->base;
		lengtha = ((s1_ptr)a)->length;
		lengthb = ((s1_ptr)b)->length;
		if (lengtha < lengthb)
			length = lengtha;
		else
			length = lengthb;
		while (--length >= 0) {
			ap++;
			bp++;
			av = *ap;
			bv = *bp;
			if (av != bv) {
				if (IS_ATOM_INT(av) && IS_ATOM_INT(bv)) {
					if (av < bv)
						return -1;
					else
						return 1;
				}
				else {
					c = compare(av, bv);
					if (c != 0)
						return c;
				}
			}
		}
		return (lengtha < lengthb) ? -1: (lengtha == lengthb) ? 0: 1;
	}
}


object find(object a, s1_ptr b)
/* find object a as an element of sequence b */
{
	object_ptr bp;
	object bv;

	if (!IS_SEQUENCE(b))
		RTFatal("second argument of find() must be a sequence");

	b = SEQ_PTR(b);
	bp = b->base;

	if (IS_ATOM_INT(a)) {
		eudouble da = (eudouble)0;
		int daok = 0;
		while (TRUE) {
			bv = *(++bp);
			if (IS_ATOM_INT(bv)) {
				if (a == bv)
					return bp - (object_ptr)b->base;
			}
			else if (IS_SEQUENCE(bv)) {
				continue;  // can't be equal so skip it.
			}
			else if (bv == NOVALUE) {
				break;  // we hit the end marker
			}
			else {  /* INT-DBL case */
				if (! daok) {
					da = (eudouble)a;
					daok = 1;
				}
				if (da == DBL_PTR(bv)->dbl)
					return bp - (object_ptr)b->base;
			}
		}
	}

	else if (IS_ATOM_DBL(a)) {
		eudouble da = DBL_PTR(a)->dbl;
		while (TRUE) {
			bv = *(++bp);
			if (IS_ATOM_INT(bv)) {
				if (da == (eudouble)bv) {  /* DBL-INT case */
					return bp - (object_ptr)b->base;
				}
			}
			else if (IS_SEQUENCE(bv)) {
				continue;  // can't be equal so skip it.
			}
			else if (bv == NOVALUE) {
				break;  // we hit the end marker
			}
			else {  /* DBL-DBL case */
				if (da == DBL_PTR(bv)->dbl)
					return bp - (object_ptr)b->base;
			}
		}
	}
	else { // IS_SEQUENCE(a)

		int a_len;

		a_len = SEQ_PTR(a)->length;
		while (TRUE) {
			bv = *(++bp);
			if (bv == NOVALUE) {
				break;  // we hit the end marker
			}

			if (IS_SEQUENCE(bv)) {
				if (a_len == SEQ_PTR(bv)->length) {
					/* a is SEQUENCE => not INT-INT case */
					if (compare(a, bv) == 0)
						return bp - (object_ptr)b->base;
				}
			}
		}
	}

	return 0;
}


object e_match(s1_ptr a, s1_ptr b)
/* find sequence a as a slice within sequence b
   sequence a may not be empty */
{
	int ntries, len_remaining;
	object_ptr a1, b1, bp;
	object_ptr ai, bi;
	object av, bv;
	int lengtha, lengthb;

	if (!IS_SEQUENCE(a))
		RTFatal("first argument of match() must be a sequence");
	if (!IS_SEQUENCE(b))
		RTFatal("second argument of match() must be a sequence");
	a = SEQ_PTR(a);
	b = SEQ_PTR(b);
	lengtha = a->length;
	if (lengtha == 0)
		RTFatal("first argument of match() must be a non-empty sequence");
	lengthb = b->length;
	b1 = b->base;
	bp = b1;
	a1 = a->base;
	ntries = lengthb - lengtha + 1;
	while (--ntries >= 0) {
		ai = a1;
		bi = bp;
		len_remaining = lengtha;
		do {
			ai++;
			bi++;
			av = *ai;
			bv = *bi;
			if (av != bv) {
				if (IS_ATOM_INT(av) && IS_ATOM_INT(bv)) {
					bp++;
					break;
				}
				else if (compare(av, bv) != 0) {
					bp++;
					break;
				}
			}
			if (--len_remaining == 0)
				return bp - b1 + 1; /* perfect match */
		} while (TRUE);
	}
	return 0; /* couldn't match */
}

#ifndef ERUNTIME
static void CheckSlice(object a, int startval, int endval, int length)
/* check legality of a slice, return integer values of start, length */
/* startval and endval are deref'd */
{
	long n;
	s1_ptr s;

	if (IS_ATOM(a))
		RTFatal("attempt to slice an atom");

	if (startval < 1) {
		RTFatal("slice lower index is less than 1 (%d)", (int32_t) startval);
	}
	if (endval < 0) {
		RTFatal("slice upper index is less than 0 (%d)", (int32_t) endval);
	}

	if (length < 0 ) {
		RTFatal("slice length is less than 0 (%d)", (int32_t) length);
	}

	s = SEQ_PTR(a);
	n = s->length;
	if ((startval > n + 1 || length > 0) && startval > n) {
		RTFatal("slice starts past end of sequence (%ld > %ld)",
				startval, n);
	}
	if (endval > n) {
		RTFatal("slice ends past end of sequence (%ld > %ld)", endval, n);
	}
}
#endif

void RHS_Slice( object a, object start, object end)
/* Construct slice a[start..end] */
{
	int startval;
	int length;
	int endval;
	s1_ptr newa, olda;
	object temp;
	object_ptr p, q, sentinel;
	object save;

	if (IS_ATOM_INT(start))
		startval = INT_VAL(start);
	else if (IS_ATOM_DBL(start)) {
		startval = (int)(DBL_PTR(start)->dbl);
	}
	else
		RTFatal("slice lower index is not an atom");

	if (IS_ATOM_INT(end))
		endval = INT_VAL(end);
	else if (IS_ATOM_DBL(end)) {
#ifdef __arm__
		// Get consistent error messages..ARM FP casting is different than x86
		if( DBL_PTR(end)->dbl > MAXINT_DBL ){
			endval = INT32_MIN;
		}
		else
#endif
		endval = (int)(DBL_PTR(end)->dbl);
		 /* f.p.: if the double is too big for
			a long WATCOM produces the most negative number. This
			will be caught as a bad subscript, although the value in the
			diagnostic will be wrong */
	}
	else
		RTFatal("slice upper index is not an atom");
	olda = SEQ_PTR(a);
	length = endval - startval + 1;

#ifndef ERUNTIME
	CheckSlice( a, startval, endval, length);
#endif


	if (*rhs_slice_target == a &&
		olda->ref == 1 &&
		(olda->base + olda->length - (object_ptr)olda) < 8 * (length+1)) {
								   // we must limit the wasted space
		/* do it in-place */       // or we could even run out of memory
		object_ptr p;

		/* update the sequence descriptor */
		p = olda->base+1;
		olda->base = olda->base + startval - 1;

		/* deref the lower excluded elements */
		for (; p <= olda->base; p++)
			DeRef(*p);

		/* deref the upper excluded elements */
		for (p = olda->base + 1 + length;
			 p <= olda->base + 1 + olda->length - startval;
			 p++)
			DeRef(*p);

		olda->postfill += olda->length - endval;
		olda->length = length;
		*(olda->base + length + 1) = NOVALUE; // new end marker
	}
	else {
		/* allocate a new sequence */
		newa = NewS1(length);
		p = newa->base;
		q = olda->base + startval;

		// plant a sentinel
		sentinel = q + length;
		save = *(sentinel);
		*(sentinel) = NOVALUE;

		while (TRUE) {
			temp = *q++;
			*(++p) = temp;
			if (!IS_ATOM_INT(temp)) {
				if (temp == NOVALUE)
					break;
				RefDS(temp);
			}
		}

		*(sentinel) = save;

		ASSIGN_SEQ(rhs_slice_target, newa);
	}
}


void AssignSlice(object start, object end, object val)
/* assign to a sliced variable */
{
	s1_ptr *seq_ptr, sp, val_seq;
	int startval, endval, length;
	object_ptr s_elem;
	object_ptr v_elem;

	seq_ptr = assign_slice_seq; /* "4th" arg */

	if (IS_ATOM_INT(start))
		startval = INT_VAL(start);
	else if (IS_ATOM_DBL(start)) {
		startval = (int)(DBL_PTR(start)->dbl);
	}
	else
		RTFatal("slice lower index is not an atom");

	if (IS_ATOM_INT(end))
		endval = INT_VAL(end);
	else if (IS_ATOM_DBL(end)) {
		endval = (int)(DBL_PTR(end)->dbl); /* see above comments on f.p. */
	}
	else
		RTFatal("slice upper index is not an atom");

	length = endval - startval + 1;

#ifndef ERUNTIME
	CheckSlice((object)*seq_ptr, startval, endval, length);
#endif

	sp = SEQ_PTR(*seq_ptr);
	if (!UNIQUE(sp)) {
		sp = (s1_ptr)SequenceCopy(sp);
		*seq_ptr = (s1_ptr)MAKE_SEQ(sp);
	}
	s_elem = sp->base + startval;
	if (IS_ATOM(val)) {
		if (!IS_ATOM_INT(val))
			(DBL_PTR(val)->ref) += length;

		while (--length >= 0) {
			DeRef(*s_elem);
			*s_elem++ = (object)val;
		}
	}
	else {
		val_seq = SEQ_PTR(val);
		v_elem = val_seq->base+1;
		if (val_seq->length != length) {
			RTFatal("lengths do not match on assignment to slice (%d != %d)",
					length, val_seq->length);
		}
		while (TRUE) {
			if (!IS_ATOM_INT(*v_elem)) {
				if (*v_elem == NOVALUE)
					break;
				RefDS(*v_elem);
			}
			DeRef(*s_elem);
			*s_elem++ = *v_elem++;
		}
	}
}

object Date()
/* returns year, month, day, hour, minute, second */
{
	object_ptr obj_ptr;
	s1_ptr result;
	time_t time_of_day;
	struct tm *local;

	time_of_day = time(NULL);
	local = localtime(&time_of_day);
	result = NewS1(8);
	obj_ptr = result->base;
	obj_ptr[1] = MAKE_INT(local->tm_year);
	obj_ptr[2] = MAKE_INT(local->tm_mon+1);
	obj_ptr[3] = MAKE_INT(local->tm_mday);
	obj_ptr[4] = MAKE_INT(local->tm_hour);
	obj_ptr[5] = MAKE_INT(local->tm_min);
	obj_ptr[6] = MAKE_INT(local->tm_sec);
	obj_ptr[7] = MAKE_INT(local->tm_wday+1);
	obj_ptr[8] = MAKE_INT(local->tm_yday+1);
	return MAKE_SEQ(result);
}

void MakeCString(char *s, object pobj, int slen)
/** make an atom or sequence into a C string.  The length
  * of the string will never write more than slen bytes as long as
  * slen is positive.  At least one byte is written to s and
  * s always becomes a valid string.
  */

/* N.B. caller must allow one extra for the null terminator */
{
	object_ptr elem;
	object x;
	int seqlen;
	s1_ptr obj;

#ifdef EXTRA_CHECK
	if (s == 0) RTInternal("MakeCString null buffer");
#endif
	while (slen > 1) {
		if (IS_ATOM(pobj)) {
			*s++ = Char(pobj);
			slen = 1;
		}
		else {
			obj = SEQ_PTR(pobj);
			elem = obj->base;
			seqlen = obj->length;
			while (seqlen && (slen > 1)) {
				x = *(++elem);
				seqlen--;
				if (IS_ATOM_INT(x)) {
					*s++ = (char)x;
				}
				else {
					if (x == NOVALUE) {
						slen = 1;
						seqlen = 0;
					}
					else
						*s++ = doChar(x);
				}
				slen--;
			}
			slen = 1;
		}
	}
	*s = '\0';
}

int might_go_screen(object file_no)
// return TRUE if object file_no might be directed to the screen or keyboard
// N.B. file_no is an object (maybe atom or sequence)
{
	return (file_no < 3) || con_was_opened;
}

int CheckFileNumber(object a)
/* check for valid file number */
{
	long file_no;

	if (IS_ATOM_INT(a))
		file_no = a;
	else if (IS_ATOM_DBL(a))
		file_no = (long)DBL_PTR(a)->dbl;
	else
		RTFatal("file number must be an atom");
	if (file_no < 0 || file_no >= MAX_USER_FILE) {
		RTFatal("bad file number (%ld)", file_no);
	}
	return (int)file_no;
}


IFILE which_file(object a, int mode)
/* return FILE pointer, given the file number */
{
	int file_no;

	file_no = CheckFileNumber(a);
	if (user_file[file_no].mode & mode)
		return user_file[file_no].fptr;
	else {
		if (user_file[file_no].mode == EF_CLOSED) {
			RTFatal("file number %d is not open", file_no);
		}
		else {
			RTFatal("wrong file mode for attempted operation");
		}
	}
}

int strcmp_ins(char *s, char *t)
/* case-insensitive string compare */
{
	int low_s, low_t;

	while (TRUE) {
		low_s = tolower(*s);
		low_t = tolower(*t);
		if (low_s != low_t)
			return low_s - low_t;
		if (low_s == '\0')
			return 0;
		s++;
		t++;
	}
}

void EClose(object a)
/* close a file */
{
	int file_no;

	last_w_file_no = NOVALUE;
	last_r_file_no = NOVALUE;
	file_no = CheckFileNumber(a);
	if (user_file[file_no].mode != EF_CLOSED) {
		iclose(user_file[file_no].fptr);
		user_file[file_no].mode = EF_CLOSED;
	}
}

object EOpen(object filename, object mode_obj, object cleanup)
/* open a file */
{
	char cname[MAX_FILE_NAME+1];
#define EOpen_cmode_len (8)
	char cmode[EOpen_cmode_len];
	IFILE fp;
	long length;
	int i;
	int mode;
	cleanup_ptr cup;

	if (IS_ATOM(mode_obj))
		RTFatal("open mode must be a sequence");

	if (!IS_SEQUENCE(filename))
		RTFatal("device or file name must be a sequence");

	length = SEQ_PTR(filename)->length + 1;
	if (length > MAX_FILE_NAME)
		return ATOM_M1;
	MakeCString(cname, filename, MAX_FILE_NAME+1);

	if (SEQ_PTR(mode_obj)->length > 3)
		RTFatal("invalid open mode");
	MakeCString(cmode, mode_obj, EOpen_cmode_len );

	length = strlen(cmode);
	if (strcmp(cmode, "r") == 0) {
		mode = EF_READ;
	}

	else if (strcmp(cmode, "rb") == 0) {
		mode = EF_READ;
	}

	else if (strcmp(cmode, "w") == 0) {
		mode = EF_WRITE;
	}

	else if (strcmp(cmode, "wb") == 0) {
		mode = EF_WRITE;
	}

	else if (strcmp(cmode, "a") == 0) {
		mode = EF_WRITE | EF_APPEND;
	}

	else if (strcmp(cmode, "ab") == 0) {
		mode = EF_WRITE | EF_APPEND;
	}

	else if (strcmp(cmode, "ub") == 0) {
		mode = EF_READ | EF_WRITE;
		copy_string(cmode, "r+b", EOpen_cmode_len);
	}

	else if (strcmp(cmode, "u") == 0) {
		mode = EF_READ | EF_WRITE;
		copy_string(cmode, "r+", EOpen_cmode_len);
	}

	else
		RTFatal("invalid open mode");

	for (i = FIRST_USER_FILE; i < MAX_USER_FILE; i++) {
		if (user_file[i].mode == EF_CLOSED)
			break;
	}
	if (i < MAX_USER_FILE) {
		if (strcmp_ins("con", cname) == 0) {
			// opening console
#ifdef EWINDOWS
			show_console();
#endif
			con_was_opened = TRUE;
		}
		fp = long_iopen(cname, cmode);
		if (fp == NULL)
			return ATOM_M1;
		else {
			user_file[i].fptr = fp;
			user_file[i].mode = mode;
			if (mode & EF_APPEND) {
				// Ensure that 'append' mode is initially positioned at end of file.
				fseek(fp, 0, SEEK_END);
			}
			
			if( get_pos_int( "open", cleanup ) ){
				cup = (cleanup_ptr) EMalloc( sizeof( struct cleanup ) );
				cup->type = CLEAN_FILE;
				cup->func.builtin = &EClose;
				cup->next = 0;
				cleanup = NewDouble( (eudouble) i );
				DBL_PTR(cleanup)->cleanup = cup;
				return cleanup;
			}
			else{
				return MAKE_INT(i);
			}
		}
	}
	else {
		RTFatal("can't open -- too many open files");
	}
}


object EGets(object file_no)
/* reads a line of text from a file for the user (GETS) */
{
	long i, c;
	long oldc;
	IFILE f;
	object_ptr line_ptr;
	s1_ptr line;
	object_ptr next_char_ptr;
	object_ptr last_char_ptr;
	int bufsize;
	
	bufsize = 134;	// Initial value. Assumes most line lengths are less than this.

	if (file_no == last_r_file_no)
		f = last_r_file_ptr;
	else {
		f = which_file(file_no, EF_READ);
		if (IS_ATOM_INT(file_no))
			last_r_file_no = file_no;
		else
			last_r_file_no = NOVALUE;
		last_r_file_ptr = f;
	}

	if (current_screen != MAIN_SCREEN && might_go_screen(last_r_file_no))
		MainScreen();

	line = (s1_ptr)EMalloc(bufsize * sizeof(object) + sizeof( struct s1 ));
	line_ptr = (object_ptr)(line + 1);
	next_char_ptr = line_ptr - 1; // Point to the [-1] object.
	last_char_ptr = line_ptr + (bufsize - 2); // Leave room for final NL and NOVALUE
	i = 0;
	oldc = EOF;

	if ((f == stdin) && in_from_keyb) {

		while (1)
		{
			// Move to next location to receive the next input character.
			next_char_ptr++;
	
			if (next_char_ptr == last_char_ptr) {
				// No room in current buffer, so expand it.
				bufsize = 64;	// Expansions use this value.
				i = last_char_ptr - line_ptr;
				line = (s1_ptr)ERealloc((char *)line, (i + bufsize + 2) * sizeof(object) + sizeof( struct s1) );
				line_ptr = (object_ptr)(line + 1);
				next_char_ptr = line_ptr + i;
				last_char_ptr = next_char_ptr + bufsize; // Leave room for final NL and NOVALUE
			}
			
			/* read a character */
			c = getKBchar();
			if (c == EOF) {
				break;
			}
	
			// Save the current character.
			oldc = c;
			
			if (c == '\n') {
				screen_col = 1;
				break;
			}
						
				
			*next_char_ptr = c;

		}	// end while
	}
	else {
		do
		{
			// Move to next location to receive the next input character.
			next_char_ptr++;

			if (next_char_ptr == last_char_ptr) {
				// No room in current buffer, so expand it.
				bufsize = 64;	// Expansions use this value.
				i = last_char_ptr - line_ptr;
				line = (s1_ptr)ERealloc((char *)line, (i + bufsize + 2) * sizeof(object) + sizeof( struct s1 ) );
				line_ptr = (object_ptr)(line + 1);
				next_char_ptr = line_ptr + i;
				last_char_ptr = next_char_ptr + bufsize;
			}

			/* read a character */
			c = getc(f);

			if (c == EOF) {
				break;
			}	
			// Save the current character.
			oldc = c;

			if (c == '\n') {
				break;
			}

			*next_char_ptr = c;

		} while(TRUE);
		
	} // end if
	
	
	if (oldc == EOF) {
		// No input characters where actually read.
		EFree( (char*)line );
		return (object)ATOM_M1;
	}

	if (oldc == '\r') {
		// Remove trailing CR.
		next_char_ptr--;
	}
		
	// Every line will end with a NL character.
	(*next_char_ptr) = (object)'\n';
	
	// Calc number of characters in buffer; includes NL and NOVALUE spots.
	i = (next_char_ptr - line_ptr) + 2;
		

	// Shrink buffer
	line = (s1_ptr)ERealloc((char *)line, i * sizeof(object) + sizeof( struct s1 ) );
	line_ptr = (object_ptr)(line + 1);

	// Create the new sequence.
	return NewPreallocSeq(i, line);

}

void set_text_color(int c)
/* set the foreground color for color displays
   or just set to white for mono displays */
{
	if (color_trace && COLOR_DISPLAY) {
		if (c == 0 && !TEXT_MODE)
			c = 8; /* graphics mode can't handle black (0) */
		SetTColor(MAKE_INT(c));
	}
	else {
		SetTColor(MAKE_INT(7));
	}
}

/* print variables */
int print_chars;  // value can be checked by caller
static int print_lines;
static int print_width;
static int print_start;
static int print_pretty;
static int print_level;
static IFILE print_file;
static int show_ascii;

int show_ascii_char(IFILE print_file, int iv)
/* display corresponding ascii char */
{
	char sbuff[4];

	if (print_file == NULL && color_trace && COLOR_DISPLAY) {
		/* show ascii char in different color on color trace screen */
		flush_screen();
		set_text_color(13);
		if (iv == ' ')
			iv = 254; /* half block character */
		sbuff[0] = iv;
		sbuff[1] = '\0';
		screen_output(print_file, sbuff);
		set_text_color(15);
		buffer_screen();
		return 1;
	}
	else {
		/* show ascii char with quotes on ex.err, error report on screen
		   or mono trace screen */
		sbuff[0] = '\'';
		sbuff[1] = iv;
		sbuff[2] = '\'';
		sbuff[3] = '\0';
		screen_output(print_file, sbuff);
		return 3;
	}
}

static void the_end()
/* we've reached the maximum number of lines, now what? */
{
	int i;
	int c;

	if (use_prompt() && print_file == NULL && print_pretty) {
		/* pretty printing to screen - prompt the user */
		screen_output(print_file, "\n");
		screen_output(print_file, "* Press Enter to continue, or q to quit\n");
		screen_output(print_file, "\n");

		c = get_key(TRUE);
		if (c != 'q' && c != 'Q') {
			ClearScreen();
			for (i = 1; i <= print_chars; i++)
				screen_output(print_file, " ");
			print_lines = line_max-5;
		}
		else {
			print_chars = -1; // stop
		}
	}
	else {
		screen_output(print_file, "...");
		print_chars = -1; // stop printing immediately
	}
}

static void cut_line(int n)
/* check for end of line */
{
	if (print_lines == 0)
		return;
	if (print_chars + n > print_width) {
		print_chars = 0;
		if (print_file == NULL && print_pretty) {
			screen_output(print_file, "\n");
			if (--print_lines == 0)
				the_end();
		}
		else {
			if (--print_lines == 0) {
				screen_output(print_file, "...");
				print_chars = -1; // stop printing immediately
			}
			else
				screen_output(print_file, "\n");
		}
	}
}

static void indent()
/* indent the display of a sequence */
{
	int i;

	if (print_chars > 0) {
		screen_output(print_file, "\n");
		print_chars = 0;
	}
	for (i = 1; i <= print_start + print_level*2; i++) {
		screen_output(print_file, " ");
		print_chars++;
	}
	if (--print_lines == 0) {
		the_end();
	}
}


static void rPrint(object a)
/* print any object in default numeric format */
{
	int length;
	int multi_line;
	object_ptr elem;
	char sbuff[NUM_SIZE];

	if (print_lines == 0)
		return;

	if (IS_ATOM(a)) {
		if (IS_ATOM_INT(a)) {
			snprintf(sbuff, NUM_SIZE, "%" PRIdPTR, a);
			sbuff[NUM_SIZE-1] = 0; // ensure NULL
			screen_output(print_file, sbuff);
			print_chars += strlen(sbuff);
			if (show_ascii && a >= ' ' &&
#ifdef EUNIX
				a <= 126)  // DEL is a problem with ANSI code display
#else
				a <= 127)
#endif
				print_chars += show_ascii_char(print_file, a);
		}
                else if (a == NOVALUE) {
                        screen_output(print_file, "NOVALUE" );
                        print_chars += strlen("NOVALUE");
                }
		else {
#if INTPTR_MAX == INT32_MAX
			snprintf(sbuff, NUM_SIZE, "%.10g", DBL_PTR(a)->dbl);
#else
			snprintf(sbuff, NUM_SIZE, "%.10Lg", DBL_PTR(a)->dbl);
#endif
			sbuff[NUM_SIZE-1] = 0; // ensure NULL
			screen_output(print_file, sbuff);
			print_chars += strlen(sbuff);
		}
	}
	else {
		/* a is a SEQUENCE */
		a = (object)SEQ_PTR(a);
		cut_line(1);
		if (print_chars == -1)
			return;

		multi_line = FALSE;
		if (print_pretty) {
			/* check if all elements are either atoms or null-sequences */
			elem = ((s1_ptr)a)->base;
			length = ((s1_ptr)a)->length;
			while (length > 0) {
				elem++;
				if (IS_SEQUENCE(*elem) && SEQ_PTR(*elem)->length > 0) {
					multi_line = TRUE;
					break;
				}
				length--;
			}
		}

		screen_output(print_file, "{");
		print_chars++;

		elem = ((s1_ptr)a)->base+1;
		length = ((s1_ptr)a)->length;
		if (length > 0) {
			print_level++;
			while (--length > 0) {
				if (multi_line)
					indent();
				rPrint(*elem++);
				if (print_chars == -1)
					return;
				screen_output(print_file, ",");
				print_chars++;
				cut_line(6);
				if (print_chars == -1)
					return;
			}
			if (multi_line)
				indent();
			rPrint(*elem);
			if (print_chars == -1)
				return;
			print_level--;
		}
		if (multi_line)
			indent();
		if (print_chars == -1)
			return;
		screen_output(print_file, "}");
		print_chars++;
	}
}

void Print(IFILE f, object a, int lines, int width, int init_chars, int pretty)
/* print an object */
{
	print_lines = lines;
	print_width = width;
	print_file = f;
	print_chars = init_chars; /* first line may be shorter */
	print_start = print_chars+1;
	print_pretty = pretty;
	print_level = 0;
	if (f == stderr)
		show_ascii = FALSE; /* don't bother showing for type-check failure */
	else
		show_ascii = TRUE;
	buffer_screen();
	rPrint(a);
	flush_screen();
}

void StdPrint(object fn, object a, int new_lines)
/* standard Print - lets us have <= 3 args in do_exec() */
{
	if (new_lines) {
		print_pretty = TRUE;
		print_width = col_max - 8;
	}
	else {
		print_pretty = FALSE;
		print_width = MAX_LONG;
	}
	if (fn == last_w_file_no)
		print_file = last_w_file_ptr;
	else {
		print_file = which_file(fn, EF_WRITE);
		if (IS_ATOM_INT(fn))
			last_w_file_no = fn;
		else
			last_w_file_no = NOVALUE;
		last_w_file_ptr = print_file;
	}

	print_lines = MAX_LONG;
	print_chars = 0;
	print_start = 0;
	print_level = 0;
	show_ascii = FALSE;
	buffer_screen();
	rPrint(a);
	flush_screen();
	if (new_lines)
		screen_output(print_file, "\n");
}

void EPuts(object file_no, object obj)
/* print out a string of characters */
{
	object_ptr elem;
	char *out_ptr;
	long n;
	int c, size;
	long len;
	IFILE f;

	if (file_no == last_w_file_no)
		f = last_w_file_ptr;
	else {
		f = which_file(file_no, EF_WRITE);
		if (IS_ATOM_INT(file_no))
			last_w_file_no = file_no;
		else
			last_w_file_no = NOVALUE;
		last_w_file_ptr = f;
	}
	if (IS_ATOM(obj)) {
		c = Char(obj);
		if (f == stdout || f == stderr || f == NULL) {
			/* might be going to screen, won't be binary mode */
			TempBuff[0] = c;
			TempBuff[1] = '\0';
			screen_output(f, TempBuff);
		}
		else {
			/* might be binary mode, must allow for 0's */
			if (current_screen != MAIN_SCREEN && might_go_screen(file_no))
				MainScreen();
			iputc(c, f);
		}
	}
	else {
		obj = (object)SEQ_PTR(obj);
		elem = ((s1_ptr)obj)->base;
		len = ((s1_ptr)obj)->length;
		while (len > 0) {
			n = len;
			if (n >= TEMP_SIZE)
				n = TEMP_SIZE - 1; /* need space for 0 */
			len = len - n;
			out_ptr = TempBuff;
			size = n;
			do {
				elem++;
				*out_ptr++ = Char(*elem);
			} while (--n > 0);
			if (f == stdout || f == stderr || f == NULL) {
				*out_ptr = '\0';
				screen_output(f, TempBuff);
			}
			else {
				if (current_screen != MAIN_SCREEN && might_go_screen(file_no))
					MainScreen();
				iwrite(TempBuff, size, 1, f);  /* allow for 0's */
			}
		}
	}
}


static object_ptr FormatItem(f, cstring, f_elem, f_last, v_elem)
/* print one format item from printf */
IFILE f;
char *cstring;
object_ptr f_elem;
object_ptr f_last;
object_ptr v_elem;
{
	int flen, sbuff_len=0;
	char c;
	intptr_t dval;
	uintptr_t uval;
	eudouble gval = (eudouble)0;
	char *sval;
	char *sbuff;
	int slength;
	char quick_alloc1[LOCAL_SPACE];
	int free_sv;
	int free_sb;

	c = '%';
	flen = 0;
	do {
		cstring[flen++] = c;
		if (++f_elem > f_last) {
			cstring[flen] = '\0';
			RTFatal("format specifier is incomplete (%s)", cstring);
		}
		c = Char(*f_elem);
	} while (IsDigit(c) || c == '.' || c == '-' || c == '+');

	free_sb = FALSE;
	if (c == 's') {
		int len_used;
		cstring[flen++] = c;
		cstring[flen] = '\0';
		free_sv = FALSE;
		if (IS_SEQUENCE(*v_elem)) {
			slength = (SEQ_PTR(*v_elem))->length + 1;
			if (slength > LOCAL_SPACE) {
				sval = EMalloc(slength);
				free_sv = TRUE;
				len_used = slength;
			}
			else {
				sval = quick_alloc1;
				len_used = LOCAL_SPACE;
			}
			MakeCString(sval, *v_elem, len_used);
		}
		else {
			slength = 4L;
			sval = quick_alloc1;
			sval[0] = Char(*v_elem);
			sval[1] = '\0';
		}
		if (slength + flen > TEMP_SIZE) {
			sbuff_len = slength + flen;
			sbuff = EMalloc(sbuff_len);
			free_sb = TRUE;
		}
		else {
			sbuff = TempBuff;
			sbuff_len = TEMP_SIZE;
		}
		snprintf(sbuff, sbuff_len, cstring, sval);
		sbuff[sbuff_len-1] = 0; // ensure NULL
		screen_output(f, sbuff);
		if (free_sv)
			EFree(sval);
	}
	else if (c == 'd' || c == 'x' || c == 'o') {
#if defined( EWINDOWS ) && INTPTR_MAX == INT64_MAX
		cstring[flen++] = 'l';
#endif
		cstring[flen++] = 'l';
		if (c == 'x')
			c = 'X';
		if (IS_ATOM_INT(*v_elem))
			dval = INT_VAL(*v_elem);
		else {
			gval = DBL_PTR(*v_elem)->dbl;
			if (gval > INTPTR_MAX || gval < INTPTR_MIN) {
				/* can't convert to long integer */
				if (c == 'd') {
					/* use .0f instead */
					cstring[flen-1] = '.';
					cstring[flen++] = '0';
					c = 'f';
				}
				else if (gval >= 0.0 &&
						 gval <= UINTPTR_MAX ) {
					/* need conversion to unsigned */
					uval = gval;
					dval = (object)uval;
				}
				else{
					RTFatal("number is too big for %%x or %%o format");
				}
			}
			else {
				/* convert to positive or negative long integer */
				dval = gval;
			}
		}
		if (NUM_SIZE + flen > TEMP_SIZE) {
			sbuff_len = NUM_SIZE + (long) flen;
			sbuff = EMalloc(sbuff_len);
			free_sb = TRUE;
		}
		else {
			sbuff = TempBuff;
			sbuff_len = TEMP_SIZE;
		}

		cstring[flen++] = c;
		cstring[flen] = '\0';
		if (c == 'f')
			snprintf(sbuff, sbuff_len, cstring, gval);
		else
			snprintf(sbuff, sbuff_len, cstring, dval);
		sbuff[sbuff_len-1] = 0; // ensure NULL
		screen_output(f, sbuff);
	}
	else if (c == 'e' || c == 'f' || c == 'g') {
#if INTPTR_MAX == INT64_MAX
		cstring[flen++] = 'L';
#endif
		cstring[flen++] = c;
		cstring[flen] = '\0';
		if (IS_ATOM_INT(*v_elem))
			gval = (eudouble)INT_VAL(*v_elem);
		else
			gval = DBL_PTR(*v_elem)->dbl;
		if (NUM_SIZE + flen > TEMP_SIZE) {
			sbuff_len = NUM_SIZE + (long) flen;
			sbuff = EMalloc(sbuff_len);
			free_sb = TRUE;
		}
		else {
			sbuff = TempBuff;
			sbuff_len = TEMP_SIZE;
		}

		snprintf(sbuff, sbuff_len, cstring, gval);
		sbuff[sbuff_len-1] = 0; // ensure NULL
		screen_output(f, sbuff);
	}
	else {
		cstring[flen++] = c;
		cstring[flen] = '\0';
		RTFatal("Unknown printf format (%s)", cstring);
	}
	if (free_sb)
		EFree(sbuff);
	return(f_elem);
}


object EPrintf(object file_no, object format_obj, object values)
/* formatted print */
/* file_no could be DOING_SPRINTF (for sprintf) */
{
	object_ptr f_elem, f_last;
	char c; /* avoid peep bug - no register decl */
	object_ptr v_elem, v_last = 0;
	char *cstring;
	char quick_alloc[LOCAL_SPACE]; // don't use TempBuff - FormatItem uses it
	int free_cs;
	char out_string[LOCAL_SPACE];
	int flen;
	int s;
	IFILE f;
	object result;
	s1_ptr format;

	if (file_no == DOING_SPRINTF) {
		f = (IFILE )DOING_SPRINTF;
	}
	else {
		if (file_no == last_w_file_no)
			f = last_w_file_ptr;
		else {
			f = which_file(file_no, EF_WRITE);
			if (IS_ATOM_INT(file_no))
				last_w_file_no = file_no;
			else
				last_w_file_no = NOVALUE;
			last_w_file_ptr = f;
		}
	}
	free_cs = FALSE;
	buffer_screen();
	if (IS_ATOM(format_obj)) {
		out_string[0] = doChar(format_obj);
		out_string[1] = '\0';
		screen_output(f, out_string);
	}
	else {
		format = SEQ_PTR(format_obj);
		flen = format->length;
		if (flen == 0) {
			screen_output(f, "");
		}
		else {
			f_elem = format->base;
			f_last = f_elem + flen;
			f_elem++;
			if (flen > LOCAL_SPACE) {
				cstring = EMalloc(flen + 1);
				free_cs = TRUE;
			}
			else
				cstring = quick_alloc;
			if (IS_ATOM(values))
				v_elem = &values;
			else {
				v_elem = SEQ_PTR(values)->base;
				v_last = v_elem + SEQ_PTR(values)->length;
				v_elem++;
			}
			out_string[0] = '\0';
			s = 0;
			while (f_elem <= f_last) {
				c = Char((object)*f_elem);
				if (c == '%') {
					if (f_elem < f_last && Char((object)*(f_elem + 1)) == '%') {
						/* %% */
						if (s >= LOCAL_SPACE-1) {
							out_string[s] = '\0';
							screen_output(f, out_string);
							s = 0;
						}
						out_string[s++] = '%';
						f_elem++;
					}
					else {
						if (IS_SEQUENCE(values) && v_elem > v_last) {
							if (file_no == DOING_SPRINTF)
								RTFatal("not enough values to print in sprintf()");
							else
								RTFatal("not enough values to print in printf()");
						}
						if (s != 0) {
							out_string[s] = '\0';
							screen_output(f, out_string);
							s = 0;
						}
						f_elem = FormatItem(f, cstring, f_elem, f_last, v_elem);
						if (IS_SEQUENCE(values))
							v_elem++;
					}
				}
				else {
					if (s >= LOCAL_SPACE-1) {
						out_string[s] = '\0';
						screen_output(f, out_string);
						s = 0;
					}
					out_string[s++] = c;
				}
				f_elem++;
			} /* end while */

			if (s != 0) {
				out_string[s] = '\0';
				screen_output(f, out_string);
			}
			if (free_cs)
				EFree(cstring);
		}
	}
	flush_screen();
	if (file_no == DOING_SPRINTF) {
		result = NewString(collect);
		EFree(collect);
		collect = NULL;
		return result;
	}
	else
		return ATOM_0;
}

#ifdef EUNIX
int nodelaych(int wait)
// returns a character, or -1 if no character is there and wait is FALSE
{
	unsigned char ch;
	int error;
	extern struct termios newtty;

	noecho(wait);

	if (0 == (error = tcsetattr(STDIN_FILENO, TCSANOW, &newtty))) {
		/* get a single character from stdin */
		error  = read(STDIN_FILENO, &ch, 1 );
	}

	return (error == 1 ? (int) ch : -1 );
}
#endif

#if defined(EWINDOWS) && defined(EMINGW)
int winkbhit();
#endif

int get_key(int wait)
/* Get one key from keyboard, without echo. If wait is TRUE then wait until
   a key is typed, otherwise return -1 if no key is available. */
{
	int a;

#ifdef EWINDOWS
		if (wait || winkbhit()) {
			a = getKBcode();

			return a;
		}
		return -1;
#endif

#ifdef EUNIX
		a = nodelaych(wait); // no delay, no echo
		return a;
#endif // EUNIX
}


static int trace_line = 0;
static IFILE trace_file;
int trace_lines = 500;

static void one_trace_line(char *line)
/* write a line to the ctrace.out file */
{
#ifdef EUNIX
	iprintf(trace_file, "%-78.78s\n", line);
#else
	iprintf(trace_file, "%-77.77s\r\n", line);
#endif
}

void ctrace(char *line)
/* display source line */
{
	last_traced_line = line;

	if (TraceOn) {
		if (trace_file == NULL) {
			if (Argc == 0)
				trace_file = iopen("ctrace-d.out", "wb");
			else
				trace_file = iopen("ctrace.out", "wb");
		}
		if (trace_file != NULL) {
			trace_line++;
			if (trace_line >= trace_lines) {
				one_trace_line("");
				one_trace_line("               "); // erase THE END
				trace_line = 0;
				iflush(trace_file);
				iseek(trace_file, 0, SEEK_SET);
			}
			one_trace_line(line);
			one_trace_line("");
			one_trace_line("=== THE END ===");
			one_trace_line("");
			one_trace_line("");
			one_trace_line("");
			iflush(trace_file);
			iseek(trace_file, -79*5, SEEK_CUR);
		}
	}
}

#ifdef EXTRA_CHECK
static void RTInternal(char *msg, ...)
{
	va_list ap;
	va_start(ap, msg);
	vfprintf(stderr, msg, ap);
	va_end(ap);
	exit(1);
}
#endif


void *xstdin;

int CRoutineId(int seq_num, int current_file_no, object name)
/* Routine_id for compiled code.
   (Similar to RTLookup() for interpreter, but here we only find routines,
	not vars, and we don't have the normal symbol table available). */
{
	char *routine_string;
	s1_ptr routine_ptr;
	int i, f, ns_file, found;
	char *colon;
	char *simple_name;
	char *p;
	char *ns;
	int in_include_path;
	int out_of_path_found;
	int in_path_found;

	if (IS_ATOM(name))
		return ATOM_M1;

	routine_ptr = SEQ_PTR(name);

	if (routine_ptr->length >= TEMP_SIZE)
		return ATOM_M1;

	routine_string = (char *)&TempBuff;
	MakeCString(routine_string, name, TEMP_SIZE);

	colon = strchr(routine_string, ':');
	seq_num = 999999998; // look through the whole list
	if (colon != NULL) {
		/* look up "ns : name" */

		/* trim off any trailing whitespace from ns */
		p = colon-1;
		while ((*p == ' ' || *p == '\t') && p >= routine_string) {
			p--;
		}
		*(p+1) = 0;

		ns = routine_string;

		/* trim off any leading whitespace from ns */
		while (*ns == ' ' || *ns == '\t')
			ns++;

		if (*ns == 0) {
			return ATOM_M1;
		}

		/* step 1: look up NAMESPACE symbol */
		if( strcmp( ns, "eu") == 0 )
			// Predefined routines don't have routine_ids
			return ATOM_M1;
		i = 0;
		while (TRUE) {
			if (rt01[i].seq_num > seq_num){
				return ATOM_M1; // ignore symbols defined after this point
			}
			if (rt02[current_file_no][rt01[i].file_num] & DIRECT_OR_PUBLIC_INCLUDE &&
				strcmp(ns, rt01[i].name) == 0) {
				ns_file = rt01[i].ns_num;
				break;
			}
			i++;
		}

		/* step 2: look up global symbol in the chosen namespace */
		simple_name = colon + 1;

		/* trim off any leading whitespace from name */
		while (*simple_name == ' ' || *simple_name == '\t')
			simple_name++;

		i = 0;

		while (rt00[i].seq_num <= seq_num) {
			if( (( rt00[i].scope == S_PUBLIC
					&& ( (rt00[i].file_num == ns_file && rt02[current_file_no][ns_file] & DIRECT_OR_PUBLIC_INCLUDE ) ||
						(rt02[ns_file][rt00[i].file_num] & PUBLIC_INCLUDE &&
						 rt02[current_file_no][ns_file] & DIRECT_OR_PUBLIC_INCLUDE)))
				||
				( rt00[i].scope == S_EXPORT
					&& rt00[i].file_num == ns_file && rt02[current_file_no][ns_file] & DIRECT_INCLUDE)
				||
				( rt00[i].scope == S_GLOBAL
					&& ( (rt00[i].file_num == ns_file  && rt02[current_file_no][ns_file] ) ||
						(rt02[ns_file][rt00[i].file_num] && rt02[current_file_no][ns_file] & DIRECT_OR_PUBLIC_INCLUDE)) )
				||
				( rt00[i].scope == S_LOCAL && ns_file == current_file_no && ns_file == rt00[i].file_num))
				&& strcmp(simple_name, rt00[i].name) == 0) {
				return i;
			}
			i++;
		}
		return ATOM_M1;
	}

	else {
		/* look up simple unqualified name */

		/* first look for local or global symbol in the same file */
		i = 0;
		while (rt00[i].seq_num <= seq_num) {
			f = rt00[i].file_num;
			if ((current_file_no == f ||
				 current_file_no == -f) &&
				strcmp(routine_string, rt00[i].name) == 0) {
				return i;
			}
			i++;
		}

		/* then look for unique global, public or export symbol */
		i = 0;
		found = ATOM_M1;
		out_of_path_found = 0;
		in_path_found = 0;
		while (rt00[i].seq_num <= seq_num) {

			if (rt00[i].scope != S_LOCAL &&
				strcmp(routine_string, rt00[i].name) == 0) {



				if(rt00[i].scope == S_GLOBAL ){
					in_include_path = rt02[current_file_no][rt00[i].file_num] != NOT_INCLUDED;
					if (in_include_path) {
						found = i;
						in_path_found++;
					}
					else{
						out_of_path_found++;
						if(!in_path_found) found = i;
					}
				}
				else if( (rt00[i].scope == S_EXPORT && (rt02[current_file_no][rt00[i].file_num] & DIRECT_INCLUDE))
				|| (rt00[i].scope == S_PUBLIC && (rt02[current_file_no][rt00[i].file_num] & DIRECT_OR_PUBLIC_INCLUDE) ) ){

					found = i;
					in_path_found++;
				}
			}
			i++;
		}

		if( in_path_found != 1  && ((in_path_found + out_of_path_found) != 1) )
			return ATOM_M1;
		return found;

	}
}

#ifdef EWINDOWS
	typedef void WINAPI (*VfP_t)(void *);
	typedef void WINAPI (*Vf_t)(void);	
#endif
void eu_startup(struct routine_list *rl, struct ns_list *nl, unsigned char **ip,
				int cps, int clk)
/* Initialize run-time data structures for the compiled user program. */
{
	#ifdef EWINDOWS
		HMODULE Comctl32;
		VfP_t initCommonControlsPtr;
		Vf_t initCommonControls95Ptr;
	#endif
	rt00 = rl;
	rt01 = nl;
	rt02 = (char**)ip;
	clocks_per_sec = cps;
	clk_tck = clk;
	xstdin = (void *)stdin;
	eustart_time = current_time();
	InitInOut();
	InitGraphics();
	InitEMalloc();
	InitFiles();
#define TempErrName_len (16)
	TempErrName = (char *)EMalloc(TempErrName_len);
	copy_string(TempErrName, "ex.err", TempErrName_len);
	TempWarningName = NULL;
	display_warnings = 1;
#ifdef EWINDOWS
	{
		/* Make sure the common controls stuff is initialized.
		 * Since we use a manifest, we have to make sure that
		 * comdlg32.dll is loaded, or GUI stuff won't work.
		 */
		INITCOMMONCONTROLSEX initcc;
		Comctl32 = LoadLibrary("Comctl32.dll");
		if (Comctl32 == NULL) {
			RTFatal("Unable to initialize Common Windows Controls.");
		}
		if (!(0 == (initCommonControlsPtr = (VfP_t)GetProcAddress(Comctl32, "InitCommonControlsEx")))) {
			initcc.dwSize = sizeof( INITCOMMONCONTROLSEX );
			initcc.dwICC  = 0;
			(*initCommonControlsPtr)( (void*)&initcc );
		} else if (!(0 == (initCommonControls95Ptr = (Vf_t)GetProcAddress(Comctl32, "InitCommonControls")))) {
			(*initCommonControls95Ptr)();
		} else {
			RTFatal("Unable to initialize Common Windows Controls.");
	}
	}
#endif
	if (Argc)
		InitTask();  // i.e. don't do this in a Euphoria .dll/.so
}

void Position(object line, object col)
/* Set two-d cursor position on screen.
   The Euphoria program assumes origin (1, 1) */
{
	int line_val, col_val;

	if (IS_ATOM_INT(line))
		line_val = INT_VAL(line);
	else {
		line_val = (int)(DBL_PTR(line)->dbl);   /* need check here */
	}
	if (IS_ATOM_INT(col))
		col_val = INT_VAL(col);
	else {
		col_val = (int)(DBL_PTR(col)->dbl);     /* need better check here too */
	}
	if (line_val < 1 ||
#ifdef EWINDOWS
	line_val > line_max ||
#endif
		 col_val < 1 ||  col_val > col_max) {
		RTFatal("attempt to move cursor off the screen to line %d, column %d", line_val, col_val);
	}
	if (current_screen != MAIN_SCREEN)
		MainScreen();
	SetPosition(line_val, col_val);
}

#ifdef EWINDOWS

char *get_module_name(){
	int ns, bs;
	char *name;
	name = 0;
	bs = 32;
	ns = bs;
	/* If ns equals bs it means that we have not gotten
		the complete path string yet */
	while (ns == bs) {
		bs += 32;
		if (name != 0){
			EFree((void *)name);
		}

		name = (char *)EMalloc(bs + 2);
		ns = GetModuleFileName(NULL, (LPTSTR)name, bs);
	}
	if (ns == 0) {
		name = (char *)EMalloc(8); // strlen("eui.exe") + 1
		copy_string(name, "eui.exe", 8);
	}
	return name;
}
#endif

char **make_arg_cv(char *cmdline, int *argc, int skip_leading_dquote)
/* Convert command line string to argc, argv.
   If *argc is 1, then get program name from GetModuleFileName().
   When double-clicked under Windows, cmdline will
   typically contain double-quoted strings. */
{
	int i, w, j;
	char **argv;
	InitEMalloc();
#ifdef EWINDOWS
	if( cmdline == NULL ){
		// Windows already did the work for us
		*argc = __argc;
		__argv[0] = get_module_name();
		return __argv;
	}
#endif
	argv = (char **)EMalloc((strlen(cmdline)/2+3) * sizeof(char *));
#ifdef EWINDOWS
	if (*argc == 1) {
		argv[0] = get_module_name();
		w = 1;
	}
	else
#endif
	   {
		w = 0;
	   }
	i = 0;
	while (TRUE) {
		/* skip white space */
		while (cmdline[i] == ' '  ||
			   cmdline[i] == '\t' ||
			   cmdline[i] == '\n') {
			i++;
		}
		if (cmdline[i] == '\0')
			break;
		if (cmdline[i] == '\"') {
            if (skip_leading_dquote)
                i++;
			argv[w++] = &cmdline[i]; // start of new quoted word
            if (!skip_leading_dquote)
                i++;
			while (cmdline[i] != '\"' &&
				   cmdline[i] != '\0') {

				/* allow a quote after a backslash,
				   then we copy over the backslash */
				if (cmdline[i] == '\\' && cmdline[i+1] == '\"') {
					/* copy the rest of the string over the backslash */
					for (j = ++i;(cmdline[j-1] = cmdline[j]); ++j) /* do nothing */;
				}
				i++;
			}
            if (!skip_leading_dquote && cmdline[i] == '\"')
                i++;
		}
		else {
			argv[w++] = &cmdline[i]; // start of new unquoted word
			i++;
			/* move through word */
			while (cmdline[i] != ' ' &&
				cmdline[i] != '\t' &&
				cmdline[i] != '\n' &&
				cmdline[i] != '\0') {

				i++;
			}
		}
		if (cmdline[i] == '\0')
			break;
		cmdline[i] = '\0';  // end marker for string - is this Kosher?
				    // it's Kosher.
		i++;
	}
	*argc = w;
	argv[w] = NULL;  // end marker needed by spawnvp
	return argv;
}


void system_call(object command, object wait)
/* Open a new shell. Run a command, then restore the graphics mode.
   Will wait for user to hit key if desired */
{
	char *string_ptr;
	int len, w;
	int len_used;


	if (!IS_SEQUENCE(command))
		RTFatal("first argument of system() must be a sequence");

	if (IS_ATOM_INT(wait))
		w = INT_VAL(wait);
	else if (IS_ATOM_DBL(wait))
		w = (long)DBL_PTR(wait)->dbl;
	else
		RTFatal("second argument of system() must be an atom");

	len = SEQ_PTR(command)->length + 1;
	if (len > TEMP_SIZE) {
		string_ptr = (char *)EMalloc(len);
		len_used = len;
	}
	else {
		string_ptr = TempBuff;
		len_used = TEMP_SIZE;
	}

	MakeCString(string_ptr, command, len_used);
	len_used = system(string_ptr);
	if (len > TEMP_SIZE)
		EFree(string_ptr);

	if (w == 1) {
		get_key(TRUE);
	}
	if (w != 2)
		RestoreConfig();
}


object system_exec_call(object command, object wait)
/* Run a .exe or .com file, then restore the graphics mode.
   Will wait for user to hit key if desired. */
{
#ifndef EUNIX
	char **argv;
    char *argvNDQ; // Without double-quote
#endif
	char *string_ptr;
	int len, w, exit_code;
	int len_used;


	if (!IS_SEQUENCE(command))
		RTFatal("first argument of system_exec() must be a sequence");

	if (IS_ATOM_INT(wait))
		w = INT_VAL(wait);
	else if (IS_ATOM_DBL(wait))
		w = (long)DBL_PTR(wait)->dbl;
	else
		RTFatal("second argument of system_exec() must be an atom");

	len = SEQ_PTR(command)->length + 1;
	if (len > TEMP_SIZE) {
		string_ptr = (char *)EMalloc(len);
		len_used = len;
	}
	else {
		string_ptr = TempBuff;
		len_used = TEMP_SIZE;
	}

	MakeCString(string_ptr, command, len_used);

	exit_code = 0;

#ifdef EUNIX
	// this runs the shell - not really supposed to, but it gets exit code
	// Assigning directly to WEXITSTATUS causes a compiler failure on BSD and OSX.
	// Fix by adding a separate assignment.
		exit_code = system(string_ptr);
		exit_code = WEXITSTATUS( exit_code );
#else
	argv = make_arg_cv(string_ptr, &exit_code, 0);
	
    argvNDQ = (char *)EMalloc(strlen(argv[0])+1);
    if (argv[0][0] == '\"') { // Assume argument is surrounded by double-quote and remove them
        copy_string(argvNDQ, argv[0]+1, strlen(argv[0])-1);
    } else {
        copy_string(argvNDQ, argv[0], strlen(argv[0])+1);
    }
    
    exit_code = _spawnvp(P_WAIT, argvNDQ, (char const * const *)argv);
    
	#if INTPTR_MAX == INT32_MAX
	// This causes a crash on Win64
    EFree(argvNDQ);			// free the 'process' name
	#endif
	EFree((char *)argv); // free the list of arg addresses, but not the args themself.

#endif
	if (len > TEMP_SIZE)
		EFree(string_ptr);

	if (w == 1) {
		get_key(TRUE);
	}
	if (w != 2)
		RestoreConfig();
	#if INTPTR_MAX == INT32_MAX
	if (exit_code >= MININT && exit_code <= MAXINT)
	#endif
		return (object)exit_code;
	#if INTPTR_MAX == INT32_MAX
	else
		return NewDouble((eudouble)exit_code);
	#endif
}

object EGetEnv(object name)
/* map an environment var to its value */
{
	char *string;
	char *result;
	int len;
	int len_used;

	if (!IS_SEQUENCE(name))
		RTFatal("argument to getenv must be a sequence");
	len = SEQ_PTR(name)->length+1;
	if (len > TEMP_SIZE) {
		string = (char *)EMalloc(len);
		len_used = len;
	}
	else {
		string = TempBuff;
		len_used = TEMP_SIZE;
	}
	MakeCString(string, (object)name, len_used);
	result = getenv(string);
	if (len > TEMP_SIZE)
		EFree(string);
	if (result == NULL)
		return ATOM_M1;
	else
		return NewString(result);
}

#ifndef ERUNTIME

#ifndef BACKEND
static int total_samples = 0;
static int sample_overflow = FALSE;
int bad_samples;

void match_samples()
/* match time profile samples to source lines */
{
	int i, gline;
	symtab_ptr proc;
	int *iptr;

	bad_samples = 0;
	if (sample_next >= sample_size)
		sample_overflow = TRUE;
	total_samples += sample_next;  // volatile
	for (i = 0; i < sample_next; i++) {
		proc = Locate((intptr_t *)profile_sample[i]);
		if (proc == NULL) {
			bad_samples++;
		}
		else {
			gline = FindLine((intptr_t *)profile_sample[i], proc);

			if (gline == 0) {
				bad_samples++;
			}
			else if (slist[gline].options & OP_PROFILE_TIME) {
				iptr = (int *)slist[gline].src;
				(*iptr)++;
			}
		}
	}
	sample_next = 0;
	total_samples -= bad_samples;
}

static void show_prof_line(IFILE f, int i)
/* display one line of profile output */
{
	if (*(slist[i].src+4) == END_OF_FILE_CHAR) {
		screen_output(f, "       |\021\n");
		return;
	}
	else if (*(int *)slist[i].src == 0) {
		screen_output(f, "       |");
	}
	else {
#define SPL_len (20)
		char buff[SPL_len];
		if (slist[i].options & OP_PROFILE_TIME) {
			snprintf(buff, SPL_len, "%6.2f |",
					 (double)(*(int *)slist[i].src)*100.0 / (double)total_samples);
			buff[SPL_len - 1] = 0; // ensure NULL
		}
		else {
			snprintf(buff, SPL_len, "%6ld |", (long int)*(int *)slist[i].src);
			buff[SPL_len - 1] = 0; // ensure NULL
		}
		screen_output(f, buff);
	}
	screen_output(f, slist[i].src + 4);
	screen_output(f, "\n");
}


void ProfileCommand()
/* display the execution profile */
{
	long i;
	IFILE f;

	f = iopen("ex.pro", "w");
	if (f == NULL) {
		/* don't use RTFatal - will get recursive calls */
		screen_output(stderr, "can't open ex.pro\n");
		return;
	}
	screen_output(stderr, "\nWriting profile results to ex.pro ...\n");

	if (AnyTimeProfile) {
		match_samples();
		iprintf(f, "-- Time profile based on %d samples.\n", total_samples);
		if (sample_overflow)
			iprintf(f, "-- Sample buffer overflowed - increase size!\n");
		iprintf(f,
			   "-- Left margin shows the percentage of total execution time\n");
		iprintf(f, "-- consumed by the statement(s) on that line.\n\n");
	}
	else {
		iprintf(f, "-- Execution-count profile.\n");
		iprintf(f, "-- Left margin shows the exact number of times that\n");
		iprintf(f, "-- the statement(s) on that line were executed.\n\n");
	}
	for (i = 1; i < gline_number; i++) {
		if (slist[i].options & (OP_PROFILE_STATEMENT | OP_PROFILE_TIME)) {
			show_prof_line(f, i);
		}
	}
	screen_output(f, "\n");
	iclose(f);
}
#endif // not BACKEND

#endif // ERUNTIME

object make_atom32(unsigned c32)
/* make a Euphoria atom from an unsigned C value */
{
	if (c32 <= (uintptr_t)MAXINT32)
		return c32;
	else
		return NewDouble((eudouble)c32);
}

object make_atom(uintptr_t c)
/* make a Euphoria atom from an unsigned C value */
{
	if (c <= (uintptr_t)MAXINT)
		return c;
	else
		return NewDouble((eudouble)c);
}

uintptr_t general_call_back(
#ifdef ERUNTIME
		  intptr_t cb_routine,
#else
		  symtab_ptr cb_routine,
#endif
						   uintptr_t arg1, uintptr_t arg2, uintptr_t arg3,
						   uintptr_t arg4, uintptr_t arg5, uintptr_t arg6,
						   uintptr_t arg7, uintptr_t arg8, uintptr_t arg9)
/* general call-back routine: 0 to 9 args */
{
	int num_args;
#ifdef ERUNTIME
	intptr_t (*addr)();
#else
	object *code[4+9]; // place to put IL: max 9 args
	object *save_tpc;
#endif
	struct symtab_entry call_back_sym;
	
	if (gameover)
		return (uintptr_t)0; // ignore messages after we decide to shutdown

#ifdef ERUNTIME
// translator call-back
	num_args = rt00[cb_routine].num_args;
	addr = rt00[cb_routine].addr;
	if (num_args >= 1) {
	  call_back_arg1->obj = make_atom((uintptr_t)arg1);
	  if (num_args >= 2) {
		call_back_arg2->obj = make_atom((uintptr_t)arg2);
		if (num_args >= 3) {
		  call_back_arg3->obj = make_atom((uintptr_t)arg3);
		  if (num_args >= 4) {
			call_back_arg4->obj = make_atom((uintptr_t)arg4);
			if (num_args >= 5) {
			  call_back_arg5->obj = make_atom((uintptr_t)arg5);
			  if (num_args >= 6) {
				call_back_arg6->obj = make_atom((uintptr_t)arg6);
				if (num_args >= 7) {
				  call_back_arg7->obj = make_atom((uintptr_t)arg7);
				  if (num_args >= 8) {
					call_back_arg8->obj = make_atom((uintptr_t)arg8);
					if (num_args >= 9) {
					  call_back_arg9->obj = make_atom((uintptr_t)arg9);
					}
				  }
				}
			  }
			}
		  }
		}
	  }
	}
	switch (num_args) {
		case 0:
			call_back_sym.obj = (*addr)();
			break;
		case 1:
			call_back_sym.obj = (*addr)(call_back_arg1->obj);
			break;
		case 2:
			call_back_sym.obj = (*addr)(call_back_arg1->obj,
											call_back_arg2->obj);
			break;
		case 3:
			call_back_sym.obj = (*addr)(call_back_arg1->obj,
											call_back_arg2->obj,
											call_back_arg3->obj);
			break;
		case 4:
			call_back_sym.obj = (*addr)(call_back_arg1->obj,
											call_back_arg2->obj,
											call_back_arg3->obj,
											call_back_arg4->obj);
			break;
		case 5:
			call_back_sym.obj = (*addr)(call_back_arg1->obj,
											call_back_arg2->obj,
											call_back_arg3->obj,
											call_back_arg4->obj,
											call_back_arg5->obj);
			break;
		case 6:
			call_back_sym.obj = (*addr)(call_back_arg1->obj,
											call_back_arg2->obj,
											call_back_arg3->obj,
											call_back_arg4->obj,
											call_back_arg5->obj,
											call_back_arg6->obj);
			break;
		case 7:
			call_back_sym.obj = (*addr)(call_back_arg1->obj,
											call_back_arg2->obj,
											call_back_arg3->obj,
											call_back_arg4->obj,
											call_back_arg5->obj,
											call_back_arg6->obj,
											call_back_arg7->obj);
			break;
		case 8:
			call_back_sym.obj = (*addr)(call_back_arg1->obj,
											call_back_arg2->obj,
											call_back_arg3->obj,
											call_back_arg4->obj,
											call_back_arg5->obj,
											call_back_arg6->obj,
											call_back_arg7->obj,
											call_back_arg8->obj);
			break;
		case 9:
			call_back_sym.obj = (*addr)(call_back_arg1->obj,
											call_back_arg2->obj,
											call_back_arg3->obj,
											call_back_arg4->obj,
											call_back_arg5->obj,
											call_back_arg6->obj,
											call_back_arg7->obj,
											call_back_arg8->obj,
											call_back_arg9->obj);
			break;
	}

#else
	call_back_sym.obj = NOVALUE;
	call_back_sym.next = 0;
	call_back_sym.next_in_block = 0;
	call_back_sym.mode = M_TEMP;
	
	/* Interpreter: set up a PROC opcode call */
	code[0] = (intptr_t *)opcode(PROC);
	code[1] = (intptr_t *)cb_routine;  // symtab_ptr of Euphoria routine
	num_args = cb_routine->u.subp.num_args;

	if (num_args >= 1) {
	  DeRef(call_back_arg1->obj);
	  call_back_arg1->obj = make_atom((uintptr_t)arg1);
	  code[2] = (object *)call_back_arg1;
	  if (num_args >= 2) {
		DeRef(call_back_arg2->obj);
		call_back_arg2->obj = make_atom((uintptr_t)arg2);
		code[3] = (object *)call_back_arg2;
		if (num_args >= 3) {
		  DeRef(call_back_arg3->obj);
		  call_back_arg3->obj = make_atom((uintptr_t)arg3);
		  code[4] = (object *)call_back_arg3;
		  if (num_args >= 4) {
			DeRef(call_back_arg4->obj);
			call_back_arg4->obj = make_atom((uintptr_t)arg4);
			code[5] = (object *)call_back_arg4;
			if (num_args >= 5) {
			  DeRef(call_back_arg5->obj);
			  call_back_arg5->obj = make_atom((uintptr_t)arg5);
			  code[6] = (object *)call_back_arg5;
			  if (num_args >= 6) {
				DeRef(call_back_arg6->obj);
				call_back_arg6->obj = make_atom((uintptr_t)arg6);
				code[7] = (object *)call_back_arg6;
				if (num_args >= 7) {
				  DeRef(call_back_arg7->obj);
				  call_back_arg7->obj = make_atom((uintptr_t)arg7);
				  code[8] = (object *)call_back_arg7;
				  if (num_args >= 8) {
					DeRef(call_back_arg8->obj);
					call_back_arg8->obj = make_atom((uintptr_t)arg8);
					code[9] = (object *)call_back_arg8;
					if (num_args >= 9) {
					  DeRef(call_back_arg9->obj);
					  call_back_arg9->obj = make_atom((uintptr_t)arg9);
					  code[10] = (object *)call_back_arg9;
					}
				  }
				}
			  }
			}
		  }
		}
	  }
	}
	
	code[num_args+2] = (object *)&call_back_sym;
	code[num_args+3] = (object *)opcode(CALL_BACK_RETURN);

	*expr_top++ = (object)tpc;    // needed for traceback
	*expr_top++ = (object)NULL;   // prevents restore_privates()

	// Save the tpc value across do_exec. Sometimes Windows
	// makes two or more call-backs in a row without returning
	// at all to the main Euphoria code.
	save_tpc = tpc;

	do_exec((intptr_t *)code);  // execute routine without setting up new stack

	tpc = save_tpc;
	expr_top -= 2;
#endif
	// Don't do get_pos_int() for crash handler
	if (crash_call_back) {
		crash_call_back = FALSE;
		return (object)(call_back_sym.obj);
	}
	else {
		return (object)get_pos_int("call-back", call_back_sym.obj);
	}
}

uintptr_t (*general_ptr)() = (void *)&general_call_back;

#ifdef __WATCOMC__
#pragma off (check_stack);
#endif

#ifdef EOSX
uintptr_t __cdecl osx_cdecl_call_back(uintptr_t arg1, uintptr_t arg2, uintptr_t arg3,
						uintptr_t arg4, uintptr_t arg5, uintptr_t arg6,
						uintptr_t arg7, uintptr_t arg8, uintptr_t arg9)
{
	// a dummy where CallBack will later assign the value of general_ptr
	// this saves us the trouble of trying to calculate the offset of
	// the callback copy from general_ptr and stuffing that into a LEA
	// calculation
	uintptr_t (*f)(symtab_ptr, uintptr_t, uintptr_t, uintptr_t, uintptr_t,
	uintptr_t, uintptr_t, uintptr_t, uintptr_t, uintptr_t)
	= (uintptr_t (*)(symtab_ptr, uintptr_t, uintptr_t, uintptr_t, uintptr_t,
	uintptr_t, uintptr_t, uintptr_t, uintptr_t, uintptr_t)) (uintptr_t)general_ptr_magic;
	return (f)((symtab_ptr)CALLBACK_POINTER,
									 arg1, arg2, arg3, arg4, arg5,
									 arg6, arg7, arg8, arg9);
}
#endif

#if INTPTR_MAX == INT32_MAX
#define CALL_GENERAL_CALLBACK (*general_ptr)
#else

// Need to force the compiler to use an absolute address
typedef intptr_t (*cbfunc)();
#define CALL_GENERAL_CALLBACK ((cbfunc)general_ptr_magic)
#endif

/* Windows cdecl - Need only one template.
   It can handle a variable number of args.
   Not all args below will actually be provided on a given call. */

intptr_t __cdecl cdecl_call_back(uintptr_t arg1, uintptr_t arg2, uintptr_t arg3,
						uintptr_t arg4, uintptr_t arg5, uintptr_t arg6,
						uintptr_t arg7, uintptr_t arg8, uintptr_t arg9)
{
	return (intptr_t) CALL_GENERAL_CALLBACK((symtab_ptr) ((uintptr_t) CALLBACK_POINTER ),
									 arg1, arg2, arg3, arg4, arg5,
									 arg6, arg7, arg8, arg9);
}

/* stdcall Call-back templates for 0-9 unsigned arguments.
 * 0x12345678 address will be overwritten by the symtab_ptr of the
 * Euphoria routine.
 */

intptr_t CALLBACK call_back0()
{
	return (intptr_t) CALL_GENERAL_CALLBACK((symtab_ptr)CALLBACK_POINTER, // will be replaced
									 0, 0, 0, 0, 0,
									 0, 0, 0, 0);
}

intptr_t CALLBACK call_back1(uintptr_t arg1)
{
	return (intptr_t) CALL_GENERAL_CALLBACK((symtab_ptr)CALLBACK_POINTER,
									 arg1, 0, 0, 0, 0,
									 0, 0, 0, 0);
}

intptr_t CALLBACK call_back2(uintptr_t arg1, uintptr_t arg2)
{
	return (intptr_t) CALL_GENERAL_CALLBACK((symtab_ptr)CALLBACK_POINTER,
									 arg1, arg2, 0, 0, 0,
									 0, 0, 0, 0);
}

intptr_t CALLBACK call_back3(uintptr_t arg1, uintptr_t arg2, uintptr_t arg3)
{
	return (intptr_t) CALL_GENERAL_CALLBACK((symtab_ptr)CALLBACK_POINTER,
									 arg1, arg2, arg3, 0, 0,
									 0, 0, 0, 0);
}

intptr_t CALLBACK call_back4(uintptr_t arg1, uintptr_t arg2, uintptr_t arg3,
							uintptr_t arg4)
{
	return (intptr_t) CALL_GENERAL_CALLBACK((symtab_ptr)CALLBACK_POINTER,
									 arg1, arg2, arg3, arg4, 0,
									 0, 0, 0, 0);
}

intptr_t CALLBACK call_back5(uintptr_t arg1, uintptr_t arg2, uintptr_t arg3,
							uintptr_t arg4, uintptr_t arg5)
{
	return (intptr_t) CALL_GENERAL_CALLBACK((symtab_ptr)CALLBACK_POINTER,
									 arg1, arg2, arg3, arg4, arg5,
									 0, 0, 0, 0);
}

intptr_t CALLBACK call_back6(uintptr_t arg1, uintptr_t arg2, uintptr_t arg3,
							uintptr_t arg4, uintptr_t arg5, uintptr_t arg6)
{
	return (intptr_t) CALL_GENERAL_CALLBACK((symtab_ptr)CALLBACK_POINTER,
									 arg1, arg2, arg3, arg4, arg5,
									 arg6, 0, 0, 0);
}

intptr_t CALLBACK call_back7(uintptr_t arg1, uintptr_t arg2, uintptr_t arg3,
							uintptr_t arg4, uintptr_t arg5, uintptr_t arg6,
							uintptr_t arg7)
{
	return (intptr_t) CALL_GENERAL_CALLBACK((symtab_ptr)CALLBACK_POINTER,
									 arg1, arg2, arg3, arg4, arg5,
									 arg6, arg7, 0, 0);
}

intptr_t CALLBACK call_back8(uintptr_t arg1, uintptr_t arg2, uintptr_t arg3,
							uintptr_t arg4, uintptr_t arg5, uintptr_t arg6,
							uintptr_t arg7, uintptr_t arg8)
{
	return (intptr_t) CALL_GENERAL_CALLBACK((symtab_ptr)CALLBACK_POINTER,
									 arg1, arg2, arg3, arg4, arg5,
									 arg6, arg7, arg8, 0);
}

intptr_t CALLBACK call_back9(uintptr_t arg1, uintptr_t arg2, uintptr_t arg3,
							uintptr_t arg4, uintptr_t arg5, uintptr_t arg6,
							uintptr_t arg7, uintptr_t arg8, uintptr_t arg9)
{
	return (intptr_t) CALL_GENERAL_CALLBACK((symtab_ptr)CALLBACK_POINTER,
									 arg1, arg2, arg3, arg4, arg5,
									 arg6, arg7, arg8, arg9);
}


void shift_args(int argc, char *argv[])
/* insert argv[0] as argv[1] and
	move the other args down */
{
	int i;

	Argc = argc+1;
	Argv = (char **)EMalloc(Argc * sizeof(char *));
	Argv[0] = argv[0];
	Argv[1] = argv[0];
	for (i = 1; i < argc; i++) {
		Argv[i+1] = argv[i];
	}
}

object Command_Line()
{
	int i;
	object_ptr obj_ptr;
	char **argv;
	s1_ptr result;

#ifndef ERUNTIME
#ifdef BACKEND
	if (Executing && il_file) {
#else
	if (Executing) {
#endif
		SEQ_PTR(fe.argv)->ref++;
		return fe.argv;
	}
	else {
#endif
		argv = Argv;
		result = NewS1((long)Argc);
		obj_ptr = result->base;
		for (i = 0; i < Argc; i++) {
			*(++obj_ptr) = NewString(*argv++);
		}
#ifdef EUNIX
		{
			char * buff;
			ssize_t len;
			// We try to get the actual path of the executable on *nix
			// systems using readlink()
			buff = EMalloc( 2049 );
			len = readlink( "/proc/self/exe\0", buff, 2048 );
			if( len != -1 ){
				buff[len] = 0;
				result->base[1] = NewString( buff );
			}
			EFree( buff );
		}
#endif
		return MAKE_SEQ(result);
#ifndef ERUNTIME
	}
#endif
}

void Cleanup(int status)
/* clean things up before leaving 0 - ok, non 0 - error */
{
	int fh;
#ifdef EUNIX
	char *xterm;
#endif

#ifndef ERUNTIME
	int i;
	long c;
	FILE *wrnf = NULL;
#endif

	gameover = TRUE;
#ifndef ERUNTIME
	if( !WRITE_COVERAGE_DB() && in_backend ){
		// check to make sure we're in the backend, and not exiting
		// from the front end (e.g., when user passes -v flag
		screen_output(stderr, "\nUnable to open coverage database!\n");
	}
#endif
	/* Close all user-opened files */
	for (fh = FIRST_USER_FILE; fh < MAX_USER_FILE; fh++) {
		EClose(fh);
	}

#ifndef ERUNTIME
	Executing = FALSE;
#endif

	if (current_screen != MAIN_SCREEN)
		MainScreen();

	/* conin might be closed here, if we were debugging */
#ifndef ERUNTIME
	if (warning_count && display_warnings) {
		if (TempWarningName) {
			wrnf = iopen(TempWarningName,"w");
			if (wrnf != NULL) {
				for (i = 0; i < warning_count; i++)
					iprintf(wrnf,"%s",warning_list[i]);
				iclose(wrnf);
			}
			else
				screen_output(stderr, "\nUnable to open warning file!\n");
			EFree(TempWarningName);
			TempWarningName = NULL;
		}
		else {
			screen_output(stderr, "\n");
			for (i = 0; i < warning_count; i++) {
				screen_output(stderr, warning_list[i]);
				if (((i+1) % 20) == 0 && use_prompt()) {
					screen_output(stderr, "\nPress Enter to continue, q to quit\n");
					c = getKBchar();
					if (c == 'q') {
						break;
					}
				}
			}
		}
	}
#ifndef BACKEND
	if (AnyStatementProfile || AnyTimeProfile)
		ProfileCommand();
#endif // BACKEND
#endif // ERUNTIME

#ifdef EUNIX
	if (use_prompt() && have_console &&
		(config.numtextrows < 24 || config.numtextrows > 25 || config.numtextcols != 80 ||
			((xterm = getenv("TERM")) != NULL &&
		  		strcmp_ins(xterm, "xterm") == 0))) 
	{
		screen_output(stderr, "\n\nPress Enter...\n");
		getKBchar();
	}

#else // EUNIX

	if (use_prompt() && TempWarningName == NULL && display_warnings &&
		(warning_count || (status && !user_abort)))
	{
		DisableControlCHandling();
		// we will have a console if we showed an error trace back or
		// if this program was using a console when it called abort(>0)
		screen_output(stderr, "\n\nPress Enter...\n");
		getKBchar();
	}
#endif // EUNIX
	EndGraphics();

#ifndef ERUNTIME
#ifdef EXTRA_STATS
	Stats();
#endif


	// Note: ExitProcess() - frees all the dlls but won't flush the regular files
	for (i = 0; i < open_dll_count; i++) {
#ifdef EWINDOWS
		FreeLibrary(open_dll_list[i]);
#else
		dlclose( open_dll_list[i] );
#endif // EWINDOWS
	}
#if 0
	{
		symtab_ptr sym;
		intptr_t len, i;
		sym = TopLevelSub;
		while( sym ){
			if( sym->mode = M_NORMAL ){
				object x = sym->obj;
				if( x >= NOVALUE ) /* do nothing */;
				else if ( IS_ATOM_DBL( x ) && DBL_PTR( x )->cleanup != 0){
					RefDS(x);
					cleanup_double( DBL_PTR( x ) );
				}
				else if (IS_SEQUENCE( x ) && SEQ_PTR( x )->cleanup != 0 ){
					RefDS(x);
					cleanup_sequence( SEQ_PTR( x ) );
				}
			}
			sym = sym->next;
		}

		sym = TopLevelSub;
		while( sym ){
			if( sym->mode == M_NORMAL ){
				DeRef( sym->obj );
				sym->obj = NOVALUE;
			}
			sym = sym->next;
		}

		sym = TopLevelSub;
		while( sym ){
			if( sym->mode == M_NORMAL &&
				(sym->token == PROC ||
				sym->token == FUNC ||
				sym->token == TYPE) ){

				EFree( sym->u.subp.code - 1 );
				EFree( sym->u.subp.linetab );
			}
			sym = sym->next;
		}

		// deal with M_CONSTANTs:
		sym = fe.st;
		if( sym ){
			len = sym->obj;
			++sym;
			for( i = 1; i <= len; ++i, ++sym ){
				if( sym->mode == M_CONSTANT ){
					DeRef( sym->obj );
					sym->obj = NOVALUE;
				}
			}
		}
	}
	if( fe.st ){
		EFree( fe.st[0].name );
		EFree( fe.st ); // = (symtab_ptr)     get_pos_int(w, *(x_ptr->base+1));
		EFree( fe.sl ); //= (struct sline *) get_pos_int(w, *(x_ptr->base+2));
		EFree( fe.misc ); // = (int *)        get_pos_int(w, *(x_ptr->base+3));
	}
#endif
#endif // ERUNTIME
	exit(status);
}

void UserCleanup(int status)
/* Euphoria abort() */
{
	user_abort = TRUE;
	Cleanup(status);
}

#ifdef EUNIX
int getKBchar()
{
	echo_wait();
	return getc(stdin);
}
#endif

#ifdef EWINDOWS
static char one_line[300];
static char *next_char_ptr = NULL;

static int winkbhit()
/* kbhit for Windows GUI apps */
{
	INPUT_RECORD pbuffer;
	DWORD junk = 0;

	while (TRUE) {
		PeekConsoleInput(console_input, &pbuffer, 1, &junk);
		if (junk == 0)
			return FALSE;
		if (pbuffer.EventType == KEY_EVENT &&
			pbuffer.Event.KeyEvent.bKeyDown) {
			return TRUE; // Key pressed down (not a release event)
		}
		ReadConsoleInput(console_input, &pbuffer, 1, &junk);
	}
}


int getKBchar()
// Windows - read next char from keyboard
{
	int c;
	
	if (next_char_ptr == NULL) {
		key_gets(one_line, sizeof(one_line));
		next_char_ptr = one_line;
	}
	c = *next_char_ptr++;
	if (c == 0) {
		// end of line
		next_char_ptr = NULL;
		c = '\n';
	} else {
		if (c == CONTROL_Z) {
			c = -1; // EOF
			next_char_ptr--; // Move pointer back to EOF char.
		}
	}

	return c;

}
#endif

void key_gets(char *input_string, int buffsize)
/* return input string from keyboard */
/* lets us use any color to echo user input in graphics modes */
{
	int line, len, init_column, column, c;
	struct eu_rccoord cursor;
	char one_char[2];
	int maxin;
	int maxcol;
	int numpad_enter;
	int left_arrow;
	char *ip;
	
	numpad_enter = VK_to_EuKBCode[VK_RETURN];
	left_arrow   = VK_to_EuKBCode[VK_LEFT];
	
#ifdef EWINDOWS
	show_console();
#endif	
	GetTextPositionP(&cursor);

	line = cursor.row;
	init_column = cursor.col;
	maxin = cursor.bufwidth - init_column + 1;
	if (maxin >= buffsize) {
		maxin = buffsize - 1; // allow for trailing null byte.
	}
	maxcol = init_column + maxin - 1;
	
	one_char[1] = '\0';
	column = init_column;
	
	input_string[0] = '\0';
	ip = &input_string[0];
	len = 0;
	
	while (TRUE) {
		c = get_key(TRUE);

		if (c == CR || c == LF || c == numpad_enter)
			break;

#ifndef WINDOWS
		if( c == 27 ){
			char d, e;
			// escape code!
			d = get_key(TRUE);
			e = get_key(TRUE);
			if( (d == 'O') &&  (e == 'D') ){
				c = left_arrow;
			}
			else{
				// just ignore it
				continue;
			}
		}
#endif

		if (c == BS || c == left_arrow ) {
			if (len > 0) {
				// update buffer
				ip--;
				*ip = '\0';
				len--;
				// update screen display
				column--;
				SetPosition(line, column);
				screen_output(NULL, " ");
				SetPosition(line, column);
			}
			continue;
		}
		
		if ((c >= ' ' && c <= 255) ||  c == CONTROL_Z) { // Only allow extended ascii byte chars for now.
			if (column <= maxcol) {
				// update buffer
				*ip = c;
				ip++;
				*ip = '\0';
				len++;
				
				if (c == CONTROL_Z)
					break;
					
				// update screen display
				one_char[0] = c;
				screen_output(NULL, one_char);
				column++;
			}
		}
	}
}

object find_from(object a, object bobj, object c)
/* find object a as an element of sequence b starting from c*/
{
	int length;
	object_ptr bp;
	object bv;
	s1_ptr b;

	if (!IS_SEQUENCE(bobj))
		RTFatal("second argument of find/find_from() must be a sequence");

	b = SEQ_PTR(bobj);
	length = b->length;

	// same rules as the lower limit on a slice
	if (IS_ATOM_INT(c)) {
		;
	}
	else if (IS_ATOM_DBL(c)) {
		c = (object)(DBL_PTR(c)->dbl);
	}
	else
		RTFatal("third argument of find/find_from() must be an atom");

	// we allow c to be $+1, just as we allow the lower limit
	// of a slice to be $+1, i.e. the empty sequence
	if (c < 1 || c > length+1) {
		RTFatal("third argument of find/find_from() is out of bounds (%ld)", c);
	}

	bp = b->base;
	bp += c - 1;
	if (IS_ATOM_INT(a)) {
		eudouble da = (eudouble)0;
		int daok = 0;
		while (TRUE) {
			bv = *(++bp);
			if (IS_ATOM_INT(bv)) {
				if (a == bv) {
					return bp - (object_ptr)b->base;
				}
			}
			else if (IS_SEQUENCE(bv)) {
				continue;  // can't be equal so skip it.
			}
			else if (bv == NOVALUE) {
				break;  // we hit the end marker
			}
			else {  /* INT-DBL case */
				if (! daok) {
					da = (eudouble)a;
					daok = 1;
				}
				if (da == DBL_PTR(bv)->dbl)
					return bp - (object_ptr)b->base;
			}
		}
	}

	else if (IS_ATOM_DBL(a)) {
		eudouble da = DBL_PTR(a)->dbl;
		while (TRUE) {
			bv = *(++bp);
			if (IS_ATOM_INT(bv)) {
				if (da == (eudouble)bv) {  /* DBL-INT case */
					return bp - (object_ptr)b->base;
				}
			}
			else if (IS_SEQUENCE(bv)) {
				continue;  // can't be equal so skip it.
			}
			else if (bv == NOVALUE) {
				break;  // we hit the end marker
			}
			else {  /* DBL-DBL case */
				if (da == DBL_PTR(bv)->dbl)
					return bp - (object_ptr)b->base;
			}
		}
	}
	else { // IS_SEQUENCE(a)
		int a_len;

		length -= c - 1;
		a_len = SEQ_PTR(a)->length;
		while (TRUE) {
			bv = *(++bp);
			if (bv == NOVALUE) {
				break;  // we hit the end marker
			}

			if (IS_SEQUENCE(bv)) {
				if (a_len == SEQ_PTR(bv)->length) {
					/* a is SEQUENCE => not INT-INT case */
					if (compare(a, bv) == 0)
						return bp - (object_ptr)b->base;
				}
			}
		}
	}

	return 0;
}

object e_match_from(object aobj, object bobj, object c)
/* find sequence a as a slice within sequence b
   sequence a may not be empty */
{
	int ntries, len_remaining;
	object_ptr a1, b1, bp;
	object_ptr ai, bi;
	object av, bv;
	int lengtha, lengthb;
	s1_ptr a, b;

	if (!IS_SEQUENCE(aobj))
		RTFatal("first argument of match/match_from() must be a sequence");

	if (!IS_SEQUENCE(bobj))
		RTFatal("second argument of match/match_from() must be a sequence");

	a = SEQ_PTR(aobj);
	b = SEQ_PTR(bobj);

	lengtha = a->length;
	if (lengtha == 0)
		RTFatal("first argument of match/match_from() must be a non-empty sequence");

	// same rules as the lower limit on a slice
	if (IS_ATOM_INT(c)) {
		;
	}
	else if (IS_ATOM_DBL(c)) {
		c = (object)(DBL_PTR(c)->dbl);
	}
	else
		RTFatal("third argument of match/match_from() must be an atom");

	lengthb = b->length;

	// we allow c to be $+1, just as we allow the lower limit
	// of a slice to be $+1, i.e. the empty sequence
	if (c < 1 || c > lengthb+1) {
		RTFatal("third argument of match/match_from() is out of bounds (%ld)", c);
	}

	b1 = b->base;
	bp = b1 + c - 1;
	a1 = a->base;
	ntries = lengthb - lengtha - c + 2; // will be max 0, when c is lengthb+1
	while (--ntries >= 0) {
		ai = a1;
		bi = bp;

		len_remaining = lengtha;
		do {
			ai++;
			bi++;
			av = *ai;
			bv = *bi;
			if (av != bv) {
				if (IS_ATOM_INT(av) && IS_ATOM_INT(bv)) {
					bp++;
					break;
				}
				else if (compare(av, bv) != 0) {
					bp++;
					break;
				}
			}
			if (--len_remaining == 0)
				return(bp - b1 + 1); /* perfect match */
		} while (TRUE);
	}
	return 0; /* couldn't match */
}

void Replace( replace_ptr rb )
{
//  normalise arguments, dispatch special cases
	int start_pos, end_pos, seqlen, replace_len;
	object copy_from, copy_to, target;
	s1_ptr s1, s2;

	start_pos = (IS_ATOM_INT(*rb->start)) ? *rb->start : (int)(DBL_PTR(*rb->start)->dbl);
	end_pos = (IS_ATOM_INT(*rb->stop)) ? *rb->stop : (int)(DBL_PTR(*rb->stop)->dbl);

	copy_to   = *rb->copy_to;
	copy_from = *rb->copy_from;

	seqlen = SEQ_PTR( copy_to )->length;

	if (end_pos < 0 && start_pos <= seqlen) {  // return (replacement & target)
		Concat( rb->target, copy_from, copy_to );
		return;
	}

	if (end_pos > seqlen)
		end_pos = seqlen;   // Can't be after last position.

	if (start_pos < 1){
		if (seqlen > 0){
			start_pos = 1;
		}
		else{
			start_pos = 0;
		}
	}

	if (start_pos > seqlen) {  // return (target & replacement)
		Concat( rb->target, copy_to, copy_from );
		return;
	}

	target = *rb->target;
	if (start_pos < 2 ) { //replacing start or all
		if (end_pos == seqlen) { // all
			Ref(copy_from);
			if( IS_SEQUENCE( copy_from ) ){
				*rb->target = copy_from;
				DeRef(target);
			}
			else{
				if( IS_SEQUENCE( target ) && UNIQUE( SEQ_PTR(target) ) ){
					s1 = SEQ_PTR( target );
					s1->postfill += (s1->length - 1);
					s1->length = 1;
					s1->base[1] = copy_from;
					s1->base[2] = NOVALUE;
				}
				else{
					s1 = NewS1( 1 );
					s1->base[1] = copy_from;
					*rb->target = MAKE_SEQ( s1 );
					DeRef( target );
				}
			}
			return;
		}
		else if( end_pos < 1 ){
			Concat( rb->target, copy_from, copy_to );
			return;
			}

	}
	if (start_pos > end_pos) {  // just splice
		if (IS_SEQUENCE( copy_from )) {
			s2 = SEQ_PTR( copy_from );
			if( (target != copy_to) || ( SEQ_PTR( copy_to )->ref != 1 ) ){
				// not in place: need to deref the target and ref the orig seq
				if( target != NOVALUE ){
					DeRef(target);
				}

				// ensures that Add_internal_space will make a copy
				RefDS( copy_to );

			}
			s1 = Add_internal_space( copy_to, start_pos, s2->length );

			assign_slice_seq = &s1;

			s1 = Copy_elements( start_pos, s2, 1 );
			*rb->target = MAKE_SEQ( s1 );
		}
		else if( (target == copy_to) && ( SEQ_PTR( copy_to )->ref == 1 ) ){
			// in place
			*rb->target = Insert( copy_to, copy_from, start_pos );
		}
		else{
			if( target != NOVALUE ){
				DeRef(target);
			}
			RefDS( copy_to );
			*rb->target = Insert( copy_to, copy_from, start_pos);
		}
		return;
	}
	// actual inner replacing
	if (IS_SEQUENCE( copy_from )) {

		s2 = SEQ_PTR( copy_from );
		replace_len = s2->length;
		assign_slice_seq = &s1;
		if (replace_len > end_pos - start_pos+1) { //replacement longer than replaced
		/**												a->ref != 1		a->ref==1
			Assigning to something else	*obj_ptr != a	D(o)			D(o) R(a)
			Assigning to same var		*obj_ptr == a	R(a)			N/A
		*/
			if( target != copy_to ){
				if( target != NOVALUE ){
					DeRef(target);
				}
				RefDS( copy_to );
			}
			else if( SEQ_PTR( copy_to )->ref != 1 ){
				RefDS( copy_to );
			}
			s1 = Add_internal_space( copy_to, end_pos + 1, replace_len + start_pos - end_pos - 1);
			assign_slice_seq = &s1;
			s1 = Copy_elements( start_pos, s2, 1);
			*rb->target = MAKE_SEQ(s1);
		}
		else { // remove any extra elements, and then assign a regular slice

			long c;
			if( target != copy_to ){
				// ensures that Add_internal_space will make a copy
				RefDS( copy_to );
				c = 1;
			}
			else{
				c = 0;
			}
			s1 = SEQ_PTR( copy_to );
			assign_slice_seq = &s1;
			if (replace_len < end_pos - start_pos+1) {

				if( copy_to == target && SEQ_PTR( target )->ref == 1 ){
					Remove_elements( start_pos + replace_len, end_pos, 1 );
				}
				else{
					*rb->target = Remove_elements( start_pos + replace_len, end_pos, 0 );
					DeRef( target );
				}
				s1 = SEQ_PTR(*rb->target);
				assign_slice_seq = &s1;
				s1 = Copy_elements( start_pos, s2, 1 );
			}
			else {
				int replace_elements = target == copy_to;
				if( !replace_elements ){
					DeRef( target );
				}
				else if( !UNIQUE( SEQ_PTR( target ) ) ){
					DeRef( target );
					replace_elements = 0;
				}
				s1 = Copy_elements( start_pos, s2, replace_elements );
			}
			*rb->target = MAKE_SEQ( s1 );
			if( c ){
				DeRefDS(copy_to);
			}
		}
	}
	else {  // replacing by an atom
		s1 = SEQ_PTR(copy_to);
		assign_slice_seq = &s1;
		Ref( copy_from );
		if (start_pos < end_pos) {
			object_ptr optr;
			if( copy_to == target && SEQ_PTR( target )->ref == 1 ){
				Remove_elements( start_pos + 1, end_pos, 1);
			}
			else{
				*rb->target = Remove_elements( start_pos + 1, end_pos, 0);
				DeRef( target );
			}
			optr = SEQ_PTR( *rb->target )->base+start_pos;
			DeRef(*optr);
			*optr = copy_from;
		}
		else{
			AssignElement( copy_from, start_pos, rb->target);
		}
	}
}

cleanup_ptr DeleteRoutine( int e_index ){
	cleanup_ptr cup;

#ifdef ERUNTIME
	cup = rt00[e_index].cleanup;
#else
	cup = e_cleanup[e_index];
#endif
	if( cup == 0 ){
		cup = (cleanup_ptr)EMalloc( sizeof(struct cleanup) );
#ifdef ERUNTIME
		rt00[e_index].cleanup = cup;
#else
		e_cleanup[e_index] = cup;
#endif
	}
	cup->type = CLEAN_UDT;
	cup->func.rid = e_index;
	cup->next = 0;
	return cup;
}

int memcopy( void *dest, size_t avail, void *src, size_t len)
{
	// Only copies memory if both dest and source are valid addresses, and
	// all of the source can be copied.

	if (dest == 0) return -1; // No destination supplied
	if (src == 0) return -2; // No source supplied
	if (len > avail) return -3; // Source is too large;
	if ((char *)dest + len <= (char *)dest) return -4; // Writing outside of RAM
	if ((char *)src + len <= (char *)src) return -5; // Reading outside of RAM
	memcpy(dest, src, len);
	return 0;
}

cleanup_ptr ChainDeleteRoutine( cleanup_ptr old, cleanup_ptr prev ){
	cleanup_ptr new_cup;
	int res;

	new_cup = (cleanup_ptr)EMalloc( sizeof(struct cleanup) );
	res = memcopy( new_cup, sizeof(struct cleanup), old, sizeof(struct cleanup) );
	if (res != 0) {
		RTFatal("Internal error: ChainDeleteRoutine memcopy failed (%d).", res);
	}

	new_cup->next = prev;

	return new_cup;
}

object eu_sizeof( object data_type ){
	long dt;
	if( IS_ATOM_INT( data_type ) ){
		dt = data_type;
	}
	else if( IS_ATOM( data_type ) ){
		dt = (long) DBL_PTR( data_type )->dbl;
	}
	else{
		RTFatal("Argument to sizeof must be an atom");
	}
	switch( dt ){
		case C_DOUBLE:
			return sizeof( double );
		case C_FLOAT:
			return sizeof( float );
		case C_CHAR:
		case C_UCHAR:
			return sizeof( char );
		case C_SHORT:
		case C_USHORT:
			return sizeof( short );
		case E_INTEGER:
		case E_ATOM:
		case E_SEQUENCE:
		case E_OBJECT:
		case C_POINTER:
			return sizeof( void* );
		case C_INT:
		case C_UINT:
			return sizeof( int );
		case C_LONG:
		case C_ULONG:
			return sizeof( long );
		case C_LONGLONG:
			return sizeof( long long );
		default:
			return 0;
	}
}

