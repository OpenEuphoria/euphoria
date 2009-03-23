#include <stdio.h>
#include <stdlib.h>

#ifdef EWINDOWS
#include <windows.h>
extern int default_heap;
#endif
#ifdef EMINGW
#include "pcre/pcre_internal.h"
#endif
#if defined(EWINDOWS) || defined(EDOS)
#include "pcre/config.h" /* cannot make it link w/o it */
#endif

#include <string.h>
#include "alldefs.h"
#include "alloc.h"
#include "pcre/pcre.h"

struct pcre_cleanup {
	struct cleanup cleanup;
	pcre *re;
};
typedef struct pcre_cleanup *pcre_cleanup_ptr;

void pcre_deref(object re) {
	pcre_cleanup_ptr rcp = SEQ_PTR(re)->cleanup;
	if (rcp->re) {
		(*pcre_free)(rcp->re);
		rcp->re = 0;
	}
}

long get_int();

object compile(object pattern, object eflags) {
	pcre *re;
	const char *error;
	int erroffset;
	char* str;
	object ret;
	int pflags;

	if (IS_ATOM_INT(eflags)) {
		pflags = eflags;
	} else if (IS_ATOM(eflags)) {
		pflags = (int)(DBL_PTR(eflags)->dbl);
	} else {
		RTFatal("compile_pcre expected an atom as the second parameter, not a sequence");
	}

	str = EMalloc( SEQ_PTR(pattern)->length + 1);
	MakeCString( str, pattern );
	re = pcre_compile( str, pflags, &error, &erroffset, NULL );
	if( re == NULL ){
		// error, so pass the error string to caller
		return NewString( error );
	}
	EFree( str );

	if ((unsigned) re > (unsigned)MAXINT)
		ret = NewDouble((double)(unsigned long)re);
	else
		ret = (unsigned long)re;

	return ret;
}

object compile_pcre(object x, object flags) {
	pcre *re;
	pcre_cleanup_ptr rcp;

	RefDS(x);
	rcp = SEQ_PTR(x)->cleanup;
	if (rcp != 0) {
		(*pcre_free)(rcp->re);
	} else {
		rcp = EMalloc(sizeof(struct pcre_cleanup));
		rcp->cleanup.func.builtin = &pcre_deref;
		rcp->cleanup.type = CLEAN_PCRE;
		SEQ_PTR(x)->cleanup = (cleanup_ptr) rcp;
	}

	rcp->re = compile(x, flags);

	return x;
}

pcre *get_re(object x) {
	// Makes sure that the regex has been compiled, and then returns
	// the compiled regex
	pcre_cleanup_ptr rcp = SEQ_PTR(x)->cleanup;
	if (rcp == 0) {
		return 0;
	}

	return rcp->re;
}

object exec_pcre(object x ){
	int rc;
	int ovector[30];
	pcre* re;
	char* str;
	s1_ptr s;
	s1_ptr sub;
	int i, j;
	object pcre_ptr;
	int options;
	int start_from;

	// x[1] = pcre ptr
	// x[2] = string to search
	// x[3] = options
	// x[4] = start_from

	pcre_ptr = SEQ_PTR(x)->base[1];
	re = get_re(pcre_ptr);

	sub = SEQ_PTR(SEQ_PTR(x)->base[2]);
	str = EMalloc(sub->length+1);
	MakeCString( str, SEQ_PTR(x)->base[2] );

	options    = get_int( SEQ_PTR(x)->base[3] );
	start_from = get_int( SEQ_PTR(x)->base[4] ) - 1;

	rc = pcre_exec( re, NULL, str, ((s1_ptr)SEQ_PTR(SEQ_PTR(x)->base[2]))->length,
				   start_from, options, ovector, 30 );
	EFree( str );
	if( rc <= 0 ) return rc;

	// put the substrings into sequences
	s = NewS1( rc );

	for( i = 1, j=0; i <= rc; i++ ) {
		sub = NewS1( 2 );
		sub->base[1] = ovector[j++] + 1;
		sub->base[2] = ovector[j] > 0 ? ovector[j] : 0;
		j++;
		s->base[i] = MAKE_SEQ( sub );
	}

	return MAKE_SEQ( s );
}

void free_pcre( object x ){
	pcre *re = get_re(x);
	(*pcre_free)(re);
}
