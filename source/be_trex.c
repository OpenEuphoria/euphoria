/*****************************************************************************
 *      (c) Copyright 2008 Rapid Deployment Software - See License.txt       *
 *****************************************************************************

 Regular expression backend for Euphoria

 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef EWINDOWS
#include <windows.h>
extern int default_heap;
#endif

#include "alldefs.h"
#include "alloc.h"

#include "trex.h"

object eu_trex_compile(object x) {
    s1_ptr re_str_seq;
    char *re_str, *error = NULL;
    TRex *re;

    re_str_seq = SEQ_PTR(SEQ_PTR(x)->base[1]);
    re_str = EMalloc(re_str_seq->length + 1);
    MakeCString(re_str, SEQ_PTR(x)->base[1]);

	re = trex_compile(re_str, &error);

	EFree(re_str);

	if (re) {
		if ((unsigned) re > (unsigned) MAXINT)
			return NewDouble((double) (unsigned long) re);
		return (unsigned long) re;
	} else {
		return NewString(error);
	}
}

object eu_trex_exec(object x, int do_match) {
    object re_ptr, matches_ptr, from_ptr;
    s1_ptr haystack_seq, tmp_seq, res_seq;
    TRex *re;
    char *haystack;
	int result, i, count=0;
	unsigned int from=0;
	TRexMatch match;
	char *sbegin, *send, *mbegin, *mend;

    re_ptr = SEQ_PTR(x)->base[1];
    if (IS_ATOM_INT(re_ptr))
        re = (TRex *) re_ptr;
    else
		re = (TRex *) (unsigned int) DBL_PTR(re_ptr)->dbl;

    haystack_seq = SEQ_PTR(SEQ_PTR(x)->base[2]);
    haystack = EMalloc(haystack_seq->length + 1);
	MakeCString(haystack, SEQ_PTR(x)->base[2]);

	from_ptr = SEQ_PTR(x)->base[3];
	if (IS_ATOM_INT(from_ptr))
		from = from_ptr - 1;
	else
		from = (unsigned int) DBL_PTR(from_ptr)->dbl - 1;

	sbegin = haystack + from;
	send = haystack + strlen(haystack);
	result = trex_searchrange(re, sbegin, send, &mbegin, &mend);

	if (result == 0) {
		EFree(haystack);
		return 0;
	}

	count = trex_getsubexpcount(re);
	res_seq = NewS1(count);
	for (i=0; i < count; i++) {
		trex_getsubexp(re, i, &match);

		tmp_seq = NewS1(2);
		tmp_seq->base[1] = (match.begin-haystack) + 1;
		tmp_seq->base[2] = (match.begin-haystack) + match.len;
		res_seq->base[i+1] = MAKE_SEQ(tmp_seq);
	}

	EFree(haystack);

	return MAKE_SEQ(res_seq);
}

object eu_trex_free(object x) {
    object re_ptr;
    TRex *re;

    re_ptr = SEQ_PTR(x)->base[1];
    if (IS_ATOM_INT(re_ptr))
        re = (TRex *) re_ptr;
    else
        re = (TRex *) (unsigned int) DBL_PTR(re_ptr)->dbl;

	trex_free(re);

	return ATOM_1;
}
