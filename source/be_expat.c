#include <stdio.h>
#include <stdlib.h>

#ifdef EUNIX
#ifndef timeval
#include <sys/time.h>
#endif
#endif

#include "alldefs.h"
#include "be_alloc.h"
#include "be_machine.h"
#include "be_runtime.h"
#include "be_expat.h"

#include "expat/expat.h"

#define ATOM_INT_VAL(x) (int)(((((unsigned long)x) | 0xE0000000) == 0xA0000000) ? DBL_PTR(x)->dbl : x)

/*
 * create_parser(encoding)
 */

object euexpat_create_parser(object x)
{
    char *encoding;
    s1_ptr encoding_s;
    object_ptr base;
    object ret;
    
    if (!IS_SEQUENCE((base = SEQ_PTR(x)->base)[1]))
        RTFatal("first argument to create_parser must be a sequence");
    
    encoding_s = SEQ_PTR(base[1]);
    encoding   = EMalloc(encoding_s->length + 1);
    MakeCString(encoding, base[1], encoding_s->length + 1);
    
    XML_Parser p = XML_ParserCreate(encoding);
    
    EFree(encoding);
    
	if ((uintptr_t) p > (uintptr_t)MAXINT)
		ret = NewDouble((double)(uintptr_t)p);
	else
		ret = (uintptr_t)p;
	
	return ret;
}

object euexpat_reset_parser(object x)
{
    char *encoding;
    XML_Parser p;
    
    s1_ptr encoding_s;
    object_ptr base;
    
    base = SEQ_PTR(x)->base;
    
    if (!IS_SEQUENCE(base[2]))
        RTFatal("second argument to reset_parser must be a sequence");
    
    encoding_s = SEQ_PTR(base[2]);
    encoding = EMalloc(encoding_s->length + 1);
    MakeCString(encoding, base[2], encoding_s->length + 1);
    
    p = ATOM_INT_VAL(base[1]);
    
    XML_ParserReset(p, encoding);
    
    EFree(encoding);
    
    return 0;
}

/*
 * free_parser(parser)
 */

object euexpat_free_parser(object x)
{
    object parser = SEQ_PTR(x)->base[1];
    XML_Parser p;
    
    p = ATOM_INT_VAL(parser);
    
    XML_ParserFree(p);
    
    return 0;
}
