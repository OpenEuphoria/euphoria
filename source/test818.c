/**
 * Trivial functions for testing how EUPHORIA's EUPHORIA to C bridge c_func and c_proc 
 * convert the values from EUPHORIA to C.
 * 
 * Note: Attemps to use bool and C_BOOL in any of these macros result in an error.  There is 
 * something special about one of these identifiers...  */ 

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

/* predefined as some macro */
#undef bool
#undef byte
typedef signed char byte;
typedef unsigned char ubyte;
typedef enum {false,true} bool;
#define BFFD_SHORT_VALUE (0xC * (1 << (8*sizeof(short)-8)))

/* The expression falls within the signed int range but outside of that of EUPHORIA */
#define MAKE_BORDER_FUNCTIONS(ctype,etype) \
	EXPORT ctype etype ## _below_EUPHORIA_MIN_INT() \
	{\
		return EUPHORIA_MIN_INT - 20;\
	}\
	EXPORT ctype etype ## _above_EUPHORIA_MAX_INT() \
	{\
		return EUPHORIA_MAX_INT + 20;\
	}\
	EXPORT ctype etype ## _NOVALUE() \
	{\
		return NOVALUE; \
	}\
	EXPORT ctype etype ## _half_MIN() \
	{\
		return EUPHORIA_MIN_INT/2;\
	}\
	EXPORT ctype etype ## _half_MAX() \
	{\
		return EUPHORIA_MAX_INT/2; \
	}

#if INT32_MAX == INTPTR_MAX
MAKE_BORDER_FUNCTIONS(int,C_INT)
#endif

#if INT32_MAX == INTPTR_MAX || !defined(EWINDOWS)
MAKE_BORDER_FUNCTIONS(long,C_LONG)
#endif
MAKE_BORDER_FUNCTIONS(long long,C_LONGLONG)

#define MAKE_ID_FUNCTION(ctype,etype) \
	EXPORT ctype etype ## _id(ctype val) {\
		return val;\
	}
MAKE_ID_FUNCTION(bool, C_BOOL)
MAKE_ID_FUNCTION(signed char, C_CHAR)
MAKE_ID_FUNCTION(byte, C_BYTE)
MAKE_ID_FUNCTION(ubyte, C_UBYTE)
MAKE_ID_FUNCTION(unsigned char, C_UCHAR)
MAKE_ID_FUNCTION(short, C_SHORT)
MAKE_ID_FUNCTION(unsigned short, C_USHORT)
MAKE_ID_FUNCTION(int, C_INT)
MAKE_ID_FUNCTION(unsigned int, C_UINT)
MAKE_ID_FUNCTION(void*, C_POINTER)
MAKE_ID_FUNCTION(long, C_LONG)
MAKE_ID_FUNCTION(unsigned long, C_ULONG)
MAKE_ID_FUNCTION(long long, C_LONGLONG)

MAKE_ID_FUNCTION(float, C_FLOAT)
MAKE_ID_FUNCTION(double, C_DOUBLE)

	
#define MAKE_NEAR_HASHC_FN(ctype,etype,min) \
	ctype etype ## _BFFD_value = min - 20; \
	EXPORT ctype etype ## _BFF_FD() { return etype ## _BFFD_value; }
	
MAKE_NEAR_HASHC_FN(char,      C_CHAR,     0xC0)
MAKE_NEAR_HASHC_FN(short,     C_SHORT,    BFFD_SHORT_VALUE)
MAKE_NEAR_HASHC_FN(int,       C_INT,      BFFD_INT_VALUE)
MAKE_NEAR_HASHC_FN(long,      C_LONG,     BFFD_LONG_VALUE)
MAKE_NEAR_HASHC_FN(long long, C_LONGLONG, BFFD_LONGLONG_VALUE)


unsigned long long bit_repeat(bool bit, unsigned char count) {
	long long bit_vector = 0LL;
	// make sure bit is boolean.
	bit = (bit != false);
	while (count--) {
		bit_vector <<= 1;
		bit_vector |= bit;
	}
	return bit_vector;
}

