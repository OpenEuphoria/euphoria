// /*****************************************************************************/
/*                                                                           */
/*                    INCLUDE FILE FOR RUN TIME DATA TYPES                   */
/*                                                                           */
/*****************************************************************************/
#ifndef EXECUTE_H_
#define EXECUTE_H_

#define ARM 0xA 
#define ix86 86 
#define ix86_64 8664
#include <stdint.h>

#include "global.h"

		  /* Euphoria object format v1.2 and later */

/* an object is represented as a 32-bit value as follows:

		unused  : 011xxxxx xxxxxxxx xxxxxxxx xxxxxxxx
		unused  : 010xxxxx xxxxxxxx xxxxxxxx xxxxxxxx

		TOO_BIG:  01000000 00000000 00000000 00000000   (just too big for INT)

	   +ATOM-INT: 001vvvvv vvvvvvvv vvvvvvvv vvvvvvvv   (31-bit integer value)
	   +ATOM-INT: 000vvvvv vvvvvvvv vvvvvvvv vvvvvvvv   (31-bit integer value)
	   -ATOM-INT: 111vvvvv vvvvvvvv vvvvvvvv vvvvvvvv   (31-bit integer value)
	   -ATOM-INT: 110vvvvv vvvvvvvv vvvvvvvv vvvvvvvv   (31-bit integer value)

		NO VALUE: 10111111 11111111 11111111 11111111   (undefined object)

		ATOM-DBL: 101ppppp pppppppp pppppppp pppppppp   (29-bit pointer)

		SEQUENCE: 100ppppp pppppppp pppppppp pppppppp   (29-bit pointer)

   We ensure 8-byte alignment for s1 and dbl blocks - lower 3 bits
   aren't needed - only 29 bits are stored.
*/

/* NO VALUE objects can occur only in a few well-defined places,
   so we can simplify some tests. For speed we first check for ATOM-INT
   since that's what most objects are. */
#undef MININT

#define MININT32     (intptr_t) 0xC0000000L
#define MAXINT32     (intptr_t) 0x3FFFFFFFL


#if INTPTR_MAX == INT32_MAX

#define DBL_MASK     (uintptr_t)0xA0000000L
#define SEQ_MASK     (uintptr_t)0x80000000L
#define DS_MASK      (uintptr_t)0xE0000000L
#define MININT       MININT32
#define MAXINT       MAXINT32
#define NOVALUE      (intptr_t) 0xbfffffffL
#define TOO_BIG_INT  (intptr_t) 0x40000000L
#define HIGH_BITS    (intptr_t) 0xC0000000L

#else

#define DBL_MASK     (uintptr_t)INT64_C( 0xA000000000000000 )
#define SEQ_MASK     (uintptr_t)INT64_C( 0x8000000000000000 )
#define DS_MASK      (uintptr_t)INT64_C( 0xE000000000000000 )
#define MININT       (intptr_t) INT64_C( 0xC000000000000000 )
#define MAXINT       (intptr_t) INT64_C( 0x3FFFFFFFFFFFFFFF )
#define NOVALUE      (intptr_t) INT64_C( 0xbfffffffffffffff )
#define TOO_BIG_INT  (intptr_t) INT64_C( 0x4000000000000000 )
#define HIGH_BITS    (intptr_t )INT64_C( 0xC000000000000000 )

typedef   signed int int128_t __attribute__((mode(TI)));
typedef unsigned int uint128_t __attribute__((mode(TI)));
#endif

#define IS_ATOM_INT(ob)       (((intptr_t)(ob)) > NOVALUE)
#define IS_ATOM_INT_NV(ob)    ((intptr_t)(ob) >= NOVALUE)

#define MAKE_UINT(x) ((object)((uintptr_t)x < (uintptr_t)TOO_BIG_INT \
                          ? (uintptr_t)x : \
                            (uintptr_t)NewDouble((eudouble)(uintptr_t)x)))

/* these are obsolete */
#define INT_VAL(x)        ((intptr_t)(x))
#define MAKE_INT(x)       ((object)(x))

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

#include "object.h"


/* **** Important Note ****
  The offset of the 'ref' field in the 'struct d' and the 'struct s1' must
  always be the same. This offset is assumed to be the same by the RefDS() macro.
*/

struct symtab_entry;


/* 'routine_list' must always be identical to definition in euphoria\include\euphoria.h
*/
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

struct sline {      /* source line table entry */
	char *src;               /* text of line,
								first 4 bytes used for count when profiling */
	unsigned short line;     /* line number within file */
	unsigned char file_no;   /* file number */
	unsigned char options;   /* options in effect: */
#define OP_TRACE   0x01      /* statement trace */
#define OP_PROFILE_STATEMENT 0x04  /* statement profile */
#define OP_PROFILE_TIME 0x02       /* time profile */
	int multiline;          /* multiline token at EOL */
}; /* 12 / 16 bytes  32/64 bit*/

struct op_info {
	object (*intfn)();
	object (*dblfn)();
};

struct replace_block {
	object_ptr copy_to;
	object_ptr copy_from;
	object_ptr start;
	object_ptr stop;
	object_ptr target;
};


#define UNKNOWN -1

#define EXPR_SIZE 200  /* initial size of call stack */


/* MACROS */
#define MAKE_DBL(x) ( (object) (((uintptr_t)(x) >> 3) | DBL_MASK) )
#define DBL_PTR(ob) ( (d_ptr)  (((uintptr_t)(ob)) << 3) )
#define MAKE_SEQ(x) ( (object) (((uintptr_t)(x) >> 3) | SEQ_MASK) )
#define SEQ_PTR(ob) ( (s1_ptr) (((uintptr_t)(ob)) << 3) )

/* ref a double or a sequence (both need same 3 bit shift) */
#define RefDS(a) ++(DBL_PTR(a)->ref)

/* ref a general object */
#define Ref(a) if (IS_DBL_OR_SEQUENCE(a)) { RefDS(a); }

/* de-ref a double or a sequence */
#define DeRefDS(a) if (--(SEQ_PTR(a)->ref) == 0 ) { de_reference((s1_ptr)(a)); }
/* de-ref a double or a sequence in x.c and set tpc (for time-profile) */
#define DeRefDSx(a) if (--(SEQ_PTR(a)->ref) == 0 ) {tpc=pc; de_reference((s1_ptr)(a)); }

/* de_ref a sequence already in pointer form */
#define DeRefSP(a) if (--((s1_ptr)(a))->ref == 0 ) { de_reference((s1_ptr)MAKE_SEQ(a)); }

/* de-ref a general object */
#define DeRef(a) if (IS_DBL_OR_SEQUENCE(a)) { DeRefDS(a); }
/* de-ref a general object in x.c and set tpc (for time-profile) */
#define DeRefx(a) if (IS_DBL_OR_SEQUENCE(a)) { DeRefDSx(a); }

/* Reassign Target object as a Sequence */
#define ASSIGN_SEQ(t,s) DeRef(*(t)); *(t) = MAKE_SEQ(s);


#define UNIQUE(seq) (((s1_ptr)(seq))->ref == 1)

/* file modes */
#define EF_CLOSED 0
#define EF_READ   1
#define EF_WRITE  2
#define EF_APPEND 4

struct file_info {
	IFILE fptr;  // C FILE pointer
	int mode;    // file mode
};

struct arg_info {
	intptr_t (*address)();// pointer to C function
	s1_ptr name;          // name of routine (for diagnostics)
	s1_ptr arg_size;      // s1_ptr of sequence of argument sizes
	object return_size;   // atom or sequence for return value size
	int convention;       // calling convention
};

#define NOT_INCLUDED     0x0
#define INDIRECT_INCLUDE 0x1
#define DIRECT_INCLUDE   0x2
#define PUBLIC_INCLUDE   0x4
#define DIRECT_OR_PUBLIC_INCLUDE  (PUBLIC_INCLUDE | DIRECT_INCLUDE)
#define ANY_INCLUDE               (INDIRECT_INCLUDE | DIRECT_INCLUDE | PUBLIC_INCLUDE)

struct IL {
	struct symtab_entry *st;
	struct sline *sl;
	intptr_t *misc;
	char *lit;
	unsigned char **includes;
	object switches;
	object argv;
};

// saved private blocks
struct private_block {
   int task_number;            // internal task number
   struct private_block *next; // pointer to next block
   object block[1];            // variable-length array of saved private data
};

#ifdef EUNIX
#define MAX_LINES 100
#define MAX_COLS 200
struct char_cell {
	char ascii;
	char fg_color;
	char bg_color;
};
#endif

#ifdef EUNIX
#ifdef EBSD
#include <limits.h>
#else
#include <linux/limits.h>
#endif
#else
#include <limits.h>
#endif

#ifdef PATH_MAX
#  define MAX_FILE_NAME PATH_MAX
#else
#  define MAX_FILE_NAME 255
#endif

#define CONTROL_C 3

#define COLOR_DISPLAY   (config.monitor != _MONO &&         \
						 config.monitor != _ANALOGMONO &&   \
						 config.mode != 7 && config.numcolors >= 16)

#define TEXT_MODE (config.numxpixels <= 80 || config.numypixels <= 80)

#define TEMP_SIZE 1040  // size of TempBuff - big enough for 1024 image

#define EXTRA_EXPAND(x) (4 + (x) + ((x) >> 2))

#define DEFAULT_SAMPLE_SIZE 25000

#define MAX_DOUBLE_DBL ((eudouble)(unsigned long)0xFFFFFFFF)
#define MIN_DOUBLE_DBL ((eudouble)(signed long)  0x80000000)

#define MAX_LONGLONG_DBL ((eudouble)(unsigned long long) 0xFFFFFFFFFFFFFFFFLL)
#define MIN_LONGLONG_DBL ((eudouble)(signed long long)   0x8000000000000000LL)

#if INTPTR_MAX == INT32_MAX

#define MAX_BITWISE_DBL MAX_DOUBLE_DBL
#define MIN_BITWISE_DBL MIN_DOUBLE_DBL

#define EUFLOOR floor
#define EUPOW   pow
#else

#define MAX_BITWISE_DBL MAX_LONGLONG_DBL
#define MIN_BITWISE_DBL MIN_LONGLONG_DBL

#define EUFLOOR floorl
#define EUPOW   powl

#endif

/* .dll argument & return value types */
#define C_TYPE     0x0F000000
#define C_DOUBLE   0x03000008
#define C_FLOAT    0x03000004
#define C_CHAR     0x01000001
#define C_UCHAR    0x02000001
#define C_SHORT    0x01000002
#define C_USHORT   0x02000002
#define E_INTEGER  0x06000004
#define E_ATOM     0x07000004
#define E_SEQUENCE 0x08000004
#define E_OBJECT   0x09000004
#define C_INT      0x01000004
#define C_UINT     0x02000004
#define C_LONG     0x01000008
#define C_ULONG    0x02000008
#define C_POINTER  0x03000001
#define C_LONGLONG 0x03000002
	
#define C_STDCALL 0
#define C_CDECL 1

// multitasking
#define ST_ACTIVE 0
#define ST_SUSPENDED 1
#define ST_DEAD 2

#define LOW_MEMORY_MAX ((unsigned)0x0010FFEF)
// It used to be ((unsigned)0x000FFFFF)
// but I found putsxy accessing ROM font above here
// successfully on Millennium. It got the address from a DOS interrupt.

#define DOING_SPRINTF -9999999 // indicates sprintf rather than printf

/* Machine Operations - avoid renumbering existing constants */
#define M_COMPLETE            0  /* determine Complete Edition */
#define M_SOUND               1
#define M_LINE                2
#define M_PALETTE             3
#define M_SOCK_INFO           4
#define M_GRAPHICS_MODE       5
#define M_CURSOR              6
#define M_WRAP                7
#define M_SCROLL              8
#define M_SET_T_COLOR         9
#define M_SET_B_COLOR        10
#define M_POLYGON            11
#define M_TEXTROWS           12
#define M_VIDEO_CONFIG       13
#define M_GET_MOUSE          14
#define M_MOUSE_EVENTS       15
#define M_ALLOC              16
#define M_FREE               17
#define M_ELLIPSE            18
#define M_SEEK               19
#define M_WHERE              20
// #define M_SET_SYNCOLOR       21
#define M_DIR                22
#define M_CURRENT_DIR        23
#define M_MOUSE_POINTER      24
#define M_GET_POSITION       25
#define M_WAIT_KEY           26
#define M_ALL_PALETTE        27
#define M_GET_DISPLAY_PAGE   28
#define M_SET_DISPLAY_PAGE   29
#define M_GET_ACTIVE_PAGE    30
#define M_SET_ACTIVE_PAGE    31
#define M_ALLOC_LOW          32
#define M_FREE_LOW           33
#define M_INTERRUPT          34
#define M_SET_RAND           35
//#define M_SET_COVERAGE       36
#define M_CRASH_MESSAGE      37
#define M_TICK_RATE          38
#define M_GET_VECTOR         39
#define M_SET_VECTOR         40
#define M_LOCK_MEMORY        41
#define M_ALLOW_BREAK        42
#define M_CHECK_BREAK        43
#define M_MEM_COPY           44 // obsolete, but keep for now
#define M_MEM_SET            45 // obsolete, but keep for now
#define M_A_TO_F64           46
#define M_F64_TO_A           47
#define M_A_TO_F32           48
#define M_F32_TO_A           49
#define M_OPEN_DLL           50
#define M_DEFINE_C           51
#define M_CALLBACK           52
#define M_PLATFORM           53 // obsolete, but keep for now
#define M_FREE_CONSOLE       54
#define M_INSTANCE           55
#define M_DEFINE_VAR         56
#define M_CRASH_FILE         57
#define M_GET_SCREEN_CHAR    58
#define M_PUT_SCREEN_CHAR    59
#define M_FLUSH              60
#define M_LOCK_FILE          61
#define M_UNLOCK_FILE        62
#define M_CHDIR              63
#define M_SLEEP              64
#define M_BACKEND            65
#define M_CRASH_ROUTINE      66
#define M_CRASH              67
#define M_PCRE_COMPILE       68
#define M_PCRE_FREE          69
#define M_PCRE_EXEC          70
#define M_PCRE_REPLACE       71
#define M_WARNING_FILE       72
#define M_SET_ENV            73
#define M_UNSET_ENV          74
#define M_EU_INFO            75
#define M_UNAME              76
#define M_SOCK_GETSERVBYNAME 77
#define M_SOCK_GETSERVBYPORT 78
#define M_SOCK_GETHOSTBYNAME 79
#define M_SOCK_GETHOSTBYADDR 80
#define M_SOCK_SOCKET        81
#define M_SOCK_CLOSE         82
#define M_SOCK_SHUTDOWN      83
#define M_SOCK_CONNECT       84
#define M_SOCK_SEND          85
#define M_SOCK_RECV          86
#define M_SOCK_BIND          87
#define M_SOCK_LISTEN        88
#define M_SOCK_ACCEPT        89
#define M_SOCK_SETSOCKOPT    90
#define M_SOCK_GETSOCKOPT    91
#define M_SOCK_SELECT        92
#define M_SOCK_SENDTO   	 93
#define M_SOCK_RECVFROM 	 94
#define M_PCRE_ERROR_MESSAGE 95
#define M_SOCK_ERROR_CODE    96
#define M_PCRE_GET_OVECTOR_SIZE 97
#define M_GET_RAND           98
#define M_HAS_CONSOLE        99
#define M_KEY_CODES          100
#define M_F80_TO_A           101
#define M_INFINITY           102
#define M_CALL_STACK         103
#define M_INIT_DEBUGGER      104
#define M_A_TO_F80           105

enum CLEANUP_TYPES {
	CLEAN_UDT,
	CLEAN_UDT_RT,
	CLEAN_PCRE,
	CLEAN_FILE
};

#endif
