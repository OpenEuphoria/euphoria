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

#ifdef _WIN32
#define EXPORT __declspec(dllexport)
#else
#define EXPORT
#endif

#define C000_INT_VALUE 0xc0000000
#define C000_LONG_VALUE (0xC * (1L << (8*sizeof(long)-8)))
#define C000_SHORT_VALUE (0xC * (1 << (8*sizeof(short)-8)))
#define C000_LONGLONG_VALUE (0xC * (1LL << (8*sizeof(long long)-8)))
#define C000_ULONGLONG_VALUE (0xC * (1ULL << (8*sizeof(unsigned long long)-8)))
#define C000_FLOAT_VALUE (float)(0xC * (1 << (8*sizeof(float)-8)))
#define C000_DOUBLE_VALUE (double)(0xC * (1 << (8*sizeof(double)-8)))
typedef signed char Byte;
typedef unsigned char UByte;
typedef enum {false,true} Bool;

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

#if defined(__i386__)
MAKE_BORDER_FUNCTIONS(int,C_INT)
#endif

#if defined(__i386__) || !defined(_WIN32)
MAKE_BORDER_FUNCTIONS(long,C_LONG)
#endif
MAKE_BORDER_FUNCTIONS(long long,C_LONGLONG)
MAKE_BORDER_FUNCTIONS(unsigned long long,C_ULONGLONG)
MAKE_BORDER_FUNCTIONS(float, C_FLOAT)
MAKE_BORDER_FUNCTIONS(double, C_DOUBLE)

#define MAKE_ID_FUNCTION(ctype,etype) \
	EXPORT ctype etype ## _id(ctype val) {\
		return val;\
	}
MAKE_ID_FUNCTION(Bool, C_BOOL)
MAKE_ID_FUNCTION(signed char, C_CHAR)
MAKE_ID_FUNCTION(Byte, C_BYTE)
MAKE_ID_FUNCTION(UByte, C_UBYTE)
MAKE_ID_FUNCTION(unsigned char, C_UCHAR)
MAKE_ID_FUNCTION(short, C_SHORT)
MAKE_ID_FUNCTION(unsigned short, C_USHORT)
MAKE_ID_FUNCTION(int, C_INT)
MAKE_ID_FUNCTION(unsigned int, C_UINT)
MAKE_ID_FUNCTION(void*, C_POINTER)
MAKE_ID_FUNCTION(long, C_LONG)
MAKE_ID_FUNCTION(unsigned long, C_ULONG)
MAKE_ID_FUNCTION(long long, C_LONGLONG)
MAKE_ID_FUNCTION(unsigned long long, C_ULONGLONG)
MAKE_ID_FUNCTION(float, C_FLOAT)
MAKE_ID_FUNCTION(double, C_DOUBLE)

	
#define MAKE_GET_VAL_FN(ctype,etype,prefix,testvalue) \
	EXPORT ctype etype ## prefix ## _value = testvalue; \
	EXPORT ctype etype ## prefix() { return etype ## prefix ## _value; }
	
MAKE_GET_VAL_FN(char,      C_CHAR,     _BFF_FD, 0xC0 - 20)
MAKE_GET_VAL_FN(short,     C_SHORT,    _BFF_FD, C000_SHORT_VALUE - 20)
MAKE_GET_VAL_FN(int,       C_INT,      _BFF_FD, C000_INT_VALUE - 20)
MAKE_GET_VAL_FN(long,      C_LONG,     _BFF_FD, C000_LONG_VALUE - 20)
MAKE_GET_VAL_FN(long long, C_LONGLONG, _BFF_FD, C000_LONGLONG_VALUE - 20)
MAKE_GET_VAL_FN(unsigned long long, C_ULONGLONG, _BFF_FD, C000_LONGLONG_VALUE - 20)

MAKE_GET_VAL_FN(char,      C_CHAR,     _M20, -20)
MAKE_GET_VAL_FN(short,     C_SHORT,    _M20, -20)
MAKE_GET_VAL_FN(int,       C_INT,      _M20, -20)
MAKE_GET_VAL_FN(long,      C_LONG,     _M20, -20)
MAKE_GET_VAL_FN(long long, C_LONGLONG, _M20, -20)
MAKE_GET_VAL_FN(unsigned long long, C_ULONGLONG, _M20, -20)

MAKE_GET_VAL_FN(char,      C_CHAR,     _M100, -100)
MAKE_GET_VAL_FN(short,     C_SHORT,    _M100, -10000)
MAKE_GET_VAL_FN(int,       C_INT,      _M100, -1000000000)
MAKE_GET_VAL_FN(long,      C_LONG,     _M100, ((sizeof(long) == sizeof(long long)) ? -1000000000000000000LL : -1000000000L) )
MAKE_GET_VAL_FN(long long, C_LONGLONG, _M100, -1000000000000000000LL)
MAKE_GET_VAL_FN(unsigned long long, C_ULONGLONG, _M100, -1000000000000000000LL)


EXPORT double sum_C_FLOAT_C_DOUBLE(float f1, double d1) {
	return f1 + d1;
}

EXPORT double sum_C_DOUBLE_C_FLOAT(double d1, float d2) {
	return d1+d2;
}

EXPORT double sum_C_FLOAT_C_FLOAT_C_DOUBLE(float f1, float f2, double f3) {
	return f1+f2+f3;
}

EXPORT double sum_C_FLOAT_C_DOUBLE_C_FLOAT_C_FLOAT_C_FLOAT_C_DOUBLE(float f1, double f2, float f3, float f4, float f5, double d6) {
	return f1+f2+f3+f4+f5+d6;
}

EXPORT double sum_C_FLOAT_C_FLOAT_C_FLOAT_C_FLOAT_C_FLOAT_C_FLOAT_C_FLOAT_C_FLOAT(float f1, float f2, float f3, float f4, float f5, float f6, float f7, float f8) {
	return f1+f2+f3+f4+f5+f6+f7+f8;	
}

EXPORT double sum_C_DOUBLE_C_DOUBLE_C_DOUBLE_C_DOUBLE_C_DOUBLE_C_DOUBLE_C_DOUBLE_C_DOUBLE(double f1, double f2, double f3, double f4, double f5, double f6, double f7, double f8) {
	return f1+f2+f3+f4+f5+f6+f7+f8;	
}

EXPORT unsigned long long bit_repeat(Bool bit, unsigned char count) {
	long long bit_vector = 0LL;
	// make sure bit is boolean.
	bit = (bit != false);
	while (count--) {
		bit_vector <<= 1;
		bit_vector |= bit;
	}
	return bit_vector;
}

double Dpow(double d, unsigned short n) {
	double base = 1.0;
	while (n--) base *= d;
	return base;
}


EXPORT double powsum(double d1, unsigned short n1, 
	double d2, unsigned short n2,
	double d3, unsigned short n3,
	double d4, unsigned short n4,
	double d5, unsigned short n5) {
	return Dpow(d1,n1)+Dpow(d2,n2)+Dpow(d3,n3)+Dpow(d4,n4)+Dpow(d5,n5);
}

EXPORT object object_func( object foo ){
	return foo;
}

EXPORT double sum_mul8df(double d1, double d2, double d3, double d4, double d5, double d6, double d7, double d8){
    return (d1+1)*(d2+2)*(d3+3)*(d4+4)*(d5+5)*(d6+6)*(d7+7)*(d8+8);
}

EXPORT double sum_mul8df2lli(double d1, double d2, double d3, double d4, double d5, double d6, double d7, double d8, long long l1, long long l2){
    return (d1+1)*(d2+2)*(d3+3)*(d4+4)*(d5+5)*(d6+6)*(d7+7)*(d8+8)*(l1+9)*(l2+10);
}

EXPORT double sum_8l6d(
	long i1, long i2, long i3, long i4, long i5, long i6, long i7, long i8,
	double d1, double d2, double d3, double d4, double d5, double d6 ){
	return ((double)(i1 + i2 + i3 + i4 + i5 + i6 + i7 + i8)) +
		(d1 + d2 + d3 + d4 + d5 + d6);
}
