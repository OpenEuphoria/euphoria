#ifndef BE_CALLC_H_
#define BE_CALLC_H_

#include <inttypes.h>
#include "execute.h"

object call_c(long func, object proc_ad, object arg_list);


typedef union {
	double dbl;
	int32_t ints[2];
	int64_t longint;
} double_arg;

typedef union {
	float flt;
	int32_t intval;
} float_arg;

#endif
