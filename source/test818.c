#include "euphoria.h"
#include <string.h>
#ifdef __WIN32
#define EXPORT __declspec(dllexport)
#else
#define EXPORT
#endif

/* The expression falls within the signed int range */
#define MAKE_FN(ctype,etype) EXPORT ctype etype ## _faux_sequence() { return MININT - 20; }

/* Which of these are not 64-bit on 64-bit platforms? */
MAKE_FN(int,C_INT)
MAKE_FN(long,C_LONG)
MAKE_FN(long long,C_LONGLONG)
