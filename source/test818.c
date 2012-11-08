#include "euphoria.h"
#include <string.h>
#ifdef __WIN32
#define EXPORT __declspec(dllexport)
#define MINLONG 0xc0000000
#else
#define EXPORT
#if INT32_MAX == INTPTR_MAX
#define MINLONG 0xc0000000
#else
#define MINLONG 0xc000000000000000L
#endif
#endif

/* The expression falls within the signed int range */
#define MAKE_FN(ctype,etype,min) \
	ctype etype = min - 20; \
	EXPORT ctype etype ## _faux_sequence() { return etype; }
	

/* Which of these are not 64-bit on 64-bit platforms? */
MAKE_FN(int,       C_INT,      0xC0000000)
MAKE_FN(long,      C_LONG,     MINLONG)
MAKE_FN(long long, C_LONGLONG, MININT)
