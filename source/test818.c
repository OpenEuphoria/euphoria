#include "euphoria.h"
/* smallest EUPHORIA integer */
#define EUPHORIA_MIN_INT MININT
#define EUPHORIA_MAX_INT MAXINT
#include <string.h>

#define BFFD_INT_VALUE 0xc0000000
#define BFFD_LONGLONG_VALUE 0xc000000000000000L
#ifdef __WIN32
#define EXPORT __declspec(dllexport)
#define BFFD_LONG_VALUE 0xc0000000
#else
#define EXPORT
#if INT32_MAX == INTPTR_MAX
#define BFFD_LONG_VALUE 0xc0000000
#else
#define BFFD_LONG_VALUE BFFD_LONGLONG_VALUE
#endif
#endif

#define BFFD_SHORT_VALUE (0xC * (1 << (8*sizeof(short)-8)))

/* The expression falls within the signed int range but outside of that of EUPHORIA */
#define MAKE_BORDER_FUNCTIONS(ctype,etype) \
	EXPORT ctype etype ## _below_EUPHORIA_MIN_INT() \
	{ return EUPHORIA_MIN_INT - 20; }\
	EXPORT ctype etype ## _above_EUPHORIA_MAX_INT() \
	{ return EUPHORIA_MAX_INT + 20; }\
	EXPORT ctype etype ## _NOVALUE() \
	{ return NOVALUE; }\
	EXPORT ctype etype ## _half_MIN() \
	{ return EUPHORIA_MIN_INT/2; }\
	EXPORT ctype etype ## _half_MAX() \
	{ return EUPHORIA_MAX_INT/2; }

MAKE_BORDER_FUNCTIONS(int,C_INT)
MAKE_BORDER_FUNCTIONS(long,C_LONG)
MAKE_BORDER_FUNCTIONS(long long,C_LONGLONG)

#define MAKE_NEAR_HASHC_FN(ctype,etype,min) \
	ctype etype ## _BFFD_value = min - 20; \
	EXPORT ctype etype ## _BFF_FD() { return etype ## _BFFD_value; }
	
MAKE_NEAR_HASHC_FN(char,      C_CHAR,     0xC0)
MAKE_NEAR_HASHC_FN(short,     C_SHORT,    BFFD_SHORT_VALUE)
MAKE_NEAR_HASHC_FN(int,       C_INT,      BFFD_INT_VALUE)
MAKE_NEAR_HASHC_FN(long,      C_LONG,     BFFD_LONG_VALUE)
MAKE_NEAR_HASHC_FN(long long, C_LONGLONG, BFFD_LONGLONG_VALUE)
