/*****************************************************************************/
/*                                                                           */
/*                              GLOBAL DEFINES                               */
/*                                                                           */
/*****************************************************************************/

#ifndef H_GLOBAL
#define H_GLOBAL

#ifdef EWINDOWS
#include <windows.h>
#endif
#ifdef EWATCOM
#include <graph.h>
#endif

#define UNUSED(expr) do { (void)(expr); } while (0)

typedef unsigned char   uchar;
typedef signed   char   schar;

#include <stdarg.h>

#define _LARGEFILE64_SOURCE
#include <stdint.h>

#if defined(EWINDOWS) && INTPTR_MAX == INT64_MAX
// MSVCRT doesn't handle long double output correctly
#define __USE_MINGW_ANSI_STDIO 1
#endif
#include <stdio.h>


#include "object.h"
#include "symtab.h"

//TODO if we are on 64bit linux, then we should fall back to the EBSD version
#if defined(ELINUX) || defined(EMINGW)
	/* use glibc 64bit variants */
#	define _LARGEFILE_SOURCE
#	define _LARGEFILE64_SOURCE
	/* note that LARGEFILE* macros do not work on MinGW */
#	include <sys/types.h>
#ifndef EMINGW
#	include <unistd.h>
#endif
#	include <errno.h>
#	define IFILE FILE*
#	define IOFF long long
#	define iopen fopen64
#	define igets fgets
#	define igetc fgetc
#	define iputs fputs
#	define iputc fputc
#	define iread fread64
#	define iwrite fwrite
	// these don't seem to exist???
	//#define iseek fseek64
	//#define itell ftell64
	// these seem to be only 32 bit???
	//#define iseek(f,o,w) lseek64(fileno(f),(o),(w))
	//#define itell(f) lseek64(fileno(f), (long long)0, SEEK_CUR)
	// this works, but has the undesirable side-effect of an unsuppressable warning from glibc 2.1.3 on
	//long long llseek(int,long long,int);
	//#define iseek(f,o,w) llseek(fileno(f),(o),(w))
	//#define itell(f) llseek(fileno(f), (long long)0, SEEK_CUR)
#	define iseek fseeko64
#	define itell ftello64
#	define iflush fflush
#	define iclose fclose
#	define ifileno fileno
#	define iprintf fprintf
#ifdef EMINGW
#   include <windef.h>
#endif
#elif defined(EWINDOWS) && !defined(EMINGW)
#	define IFILE FILE*
#	define IOFF __int64
#	define iopen fopen
#	define igets fgets
#	define igetc fgetc
#	define iputs fputs
#	define iputc fputc
#	define iread fread
#	define iwrite fwrite
#   define iseek(f,o,w) (_lseeki64(fileno(f),(__int64)(o),(w)) == -1 ? -1 : 0)
#	define itell(f) _lseeki64(fileno(f), (__int64)0, SEEK_CUR)
#	define iflush fflush
#	define iclose fclose
#	define ifileno fileno
#	define iprintf fprintf
#   include <windef.h>
#elif defined(EBSD) || defined(EOSX)
	/* 64bit support is automatic */
#	define IFILE FILE*
#	define IOFF long long
#	define iopen fopen
#	define igets fgets
#	define igetc fgetc
#	define iputs fputs
#	define iputc fputc
#	define iread fread
#	define iwrite fwrite
#	define iseek fseek
#	define itell ftell
#	define iflush fflush
#	define iclose fclose
#	define ifileno fileno
#	define iprintf fprintf
#else
/* no 64bit support */
#	define IFILE FILE*
#	define IOFF long
#	define iopen fopen
#	define igets fgets
#	define igetc fgetc
#	define iputs fputs
#	define iputc fputc
#	define iread fread
#	define iwrite fwrite
#	define iseek fseek
#	define itell ftell
#	define iflush fflush
#	define iclose fclose
#	define ifileno fileno
#	define iprintf fprintf
#endif

#undef TRUE
#undef FALSE
#define TRUE  1
#define FALSE 0

struct replace_block;
typedef struct replace_block *replace_ptr;

#ifdef INT_CODES
	typedef intptr_t opcode_type;
	#define opcode(x) (x)
#else
	typedef intptr_t *opcode_type;
	#define opcode(x) jumptab[x-1]
#endif

/* screens */
#define MAIN_SCREEN 1
#define DEBUG_SCREEN 2

#define MAX_LONG 0x7fffffffL /* largest positive long integer */

struct time_info {
	char *name;
	long start_ticks;
	long num_events;
	long tot_ticks;
};

#if defined(EUNIX) || defined(EMINGW)
#  define KEYBUFF_SIZE 50
#  define __far
#  define FAR
#  ifndef EMINGW
typedef int (*FARPROC)();
#    define CALLBACK
#    define WINAPI
#  endif // EMINGW
#  define __interrupt
#  define LRESULT intptr_t
#  if !defined(EMINGW)
#    define O_TEXT 0
#    define HINSTANCE void*
#  endif
struct videoconfig {
	int monitor;
#  define _MONO 1
#  define _ANALOGMONO 2
#  define _COLOR 3
	int mode;
	int numcolors;
	int numxpixels;
	int numypixels;
	int numtextrows;
	int numtextcols;
	int numvideopages;
};
#  define _WHITE 7
#  define _BLACK 0
#  define _BLUE 4
#  define _BROWN 3
#  define _CYAN 6
#  define _YELLOW 11
#endif

struct eu_rccoord {
	int row;
	int col;
	int winwidth;
	int winheight;
	int bufwidth;
	int bufheight;
	short attrs;
};


struct videoconfigEx {
	int screenrows;
	int screencols;
};

#ifdef EUNIX
#define PATH_SEPARATOR ':'
#define SLASH '/'
#else
#define PATH_SEPARATOR ';'
#define SLASH '\\'
#endif

#if defined(EUNIX)
#define WORD unsigned short
#define __stdcall
#define __cdecl
#endif

#ifdef EWINDOWS 
// Use Heap functions for everything.
extern HANDLE default_heap;
#define malloc(n) HeapAlloc((void *)default_heap, 0, n)
#define free(p) HeapFree((void *)default_heap, 0, p)
#define realloc(p, n) HeapReAlloc((void *)default_heap, 0, p, n)


#endif

void show_console();

extern int is_batch;
extern int is_test;

#ifndef LRESULT
#define LRESULT intptr_t
#endif
#ifndef CALLBACK
#define CALLBACK
#endif

/*
 * This breaks Win32 cdecl callbacks.  If DOS doesn't
 * have __cdecl defined, we should use the pragma
 * aux method to define it: 
 * http://www.openwatcom.org/index.php/Calling_Conventions#Specifying_Calling_Conventions_the_Watcom_Way
 * According to the documentation, however, OW for DOS should 
 * support cdecl.  If this was for other compilers (DJGPP?),
 * then we should figure out a better way to handle this:
#ifndef __cdecl
#define __cdecl
#endif
 */

struct EuViewPort
{
	int columns;			/* Number of columns visible */
	int lines;				/* Number if lines visible */
	int num_trace_lines;    /* number of lines available for statements */
	int vars_per_line;  	/* number of variables slots per line */
	int display_size;   	/* number of slots for variables */
};

#endif // H_GLOBAL
