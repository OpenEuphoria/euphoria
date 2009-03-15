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

#include "regex.h"

struct regex_cleanup{
	struct cleanup cleanup;
	RxNode* re;
};
typedef struct regex_cleanup *regex_cleanup_ptr;

void regex_deref( object re ){
	
	regex_cleanup_ptr rcp = SEQ_PTR(re)->cleanup;
	if( rcp->re ){
		RxFree( rcp->re );
		rcp->re = 0;
	}
}

RxNode* compile(object x ){
    s1_ptr re_str_seq;
    char *re_str;
    RxNode *re;
    re_str_seq = SEQ_PTR(x);
    re_str = EMalloc(re_str_seq->length + 1);
    MakeCString(re_str, x);
    re = RxCompile(re_str);
    EFree(re_str);

    return re;
}

object regex_compile(object x) {
    RxNode* re;
	RefDS(x); // we send a 'naked' sequence for this, and machine() DeRefs
	regex_cleanup_ptr rcp = (regex_cleanup_ptr) SEQ_PTR(x)->cleanup;
	if( rcp != 0 ){
		RxFree( rcp->re );
	}
	else{
		rcp = EMalloc( sizeof( struct regex_cleanup ) );
		rcp->cleanup.func.builtin = &regex_deref;
		rcp->cleanup.type = CLEAN_REGEX;
		SEQ_PTR(x)->cleanup = (cleanup_ptr)rcp;
	}
	rcp->re = compile( x );
	return x;
}

RxNode* get_re( object x ){
// Makes sure that the regex has been compiled, and then 
// returns the compiled regex
	regex_cleanup_ptr rcp = SEQ_PTR(x)->cleanup;
	if( rcp == 0 ){
		RxNode *re = compile( x );
		if( re == 0 ){
			return re;
		}
		rcp = EMalloc( sizeof( struct regex_cleanup ) );
		if( rcp == 0 ){
			// out of memory error
			RTFatal("Your program has run out of memory.\nOne moment please...");
		}
		rcp->re = re;
		rcp->cleanup.type = CLEAN_REGEX;
		rcp->cleanup.func.builtin = &regex_deref;
		SEQ_PTR(x)->cleanup = rcp;
	}
	return rcp->re;
}

object regex_exec(object x, int match) {
    object re_ptr, matches_ptr, from_ptr;
    s1_ptr haystack_seq, tmp_seq, res_seq;
    RxNode *re;
    char *haystack;
	int result, i, count=0;
	unsigned int from=0;
    RxMatchRes matches;

    re_ptr = SEQ_PTR(x)->base[1];
// 	printf("re_ptr: %x\n", re_ptr );
	re = get_re( re_ptr );
    haystack_seq = SEQ_PTR(SEQ_PTR(x)->base[2]);
    haystack = EMalloc(haystack_seq->length + 1);
	MakeCString(haystack, SEQ_PTR(x)->base[2]);

	from_ptr = SEQ_PTR(x)->base[3];
	if (IS_ATOM_INT(from_ptr))
		from = from_ptr - 1;
	else
		from = (unsigned int) DBL_PTR(from_ptr)->dbl - 1;

	if (match == 1)
		result = RxExecMatch(re, haystack, haystack_seq->length, haystack + from, &matches, RX_CASE);
	else
		result = RxExec(re, haystack, haystack_seq->length, haystack + from, &matches, RX_CASE);

	EFree(haystack);

	if (result == 0 || match == 1)
		return result;

    for (i=0; i < NSEXPS; i++) {
        if (matches.Open[i] == -1) break;
        count++;
    }

    res_seq = NewS1(count);

    for (i=0; i < count; i++) {
        tmp_seq = NewS1(2);
        tmp_seq->base[1] = matches.Open[i]+1;
        tmp_seq->base[2] = matches.Close[i];
        res_seq->base[i+1] = MAKE_SEQ(tmp_seq);
    }

    return MAKE_SEQ(res_seq);
}

object regex_replace(object x) {
    object matches_ptr, re_ptr;
    s1_ptr replacement_seq, haystack_seq;
    RxNode *re;
    char *replacement, *haystack, *out = 0, *tmp;
    int result, out_len = 0;
    RxMatchRes match;

    re_ptr = SEQ_PTR(x)->base[1];
	re = get_re( re_ptr );

    haystack_seq = SEQ_PTR(SEQ_PTR(x)->base[2]);
    haystack = EMalloc(haystack_seq->length + 1);
    MakeCString(haystack, SEQ_PTR(x)->base[2]);

    result = RxExec(re, haystack, haystack_seq->length, haystack, &match, RX_CASE);
    if (result == 0) {
        EFree(haystack);
        return 0;
    }

    replacement_seq = SEQ_PTR(SEQ_PTR(x)->base[3]);
    replacement = EMalloc(replacement_seq->length + 1);
    MakeCString(replacement, SEQ_PTR(x)->base[3]);

    result = RxReplace(replacement, haystack, haystack_seq->length-1,
                       match, &out, &out_len);

    tmp = EMalloc(out_len + 1);
    strncpy(tmp, out, out_len);
    tmp[out_len] = 0;

    EFree(replacement);
    EFree(haystack);

    if (result != 0)
        return 0;

    return NewString(tmp);
}

object regex_free(object x) {
	regex_cleanup_ptr rcp = SEQ_PTR(x)->cleanup;
	if( rcp != 0 && rcp->cleanup.type == CLEAN_REGEX){
		RxFree( rcp->re );
		EFree( rcp );
		SEQ_PTR(x)->cleanup = 0;
// 		printf("free'd regex manually for %p [%p] refs: %d\n", x, rcp, SEQ_PTR(x)->ref);
	}
	return ATOM_1;
}

object regex_ok(object x){
	RxNode *re = get_re( x );
	if( re == 0 ){
	
	}
	return re != 0;
}

