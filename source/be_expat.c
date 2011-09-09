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
 * create_parser(
 *     encoding,
 *     element_handler,
 *     start_element_handler,
 *     end_element_handler,
 *     char_data_handler,
 *     default_handler,
 *     comment_handler)
 */

#define PARSER                1
#define START_ELEMENT_HANDLER 2
#define END_ELEMENT_HANDLER   3
#define CHAR_DATA_HANDLER     4
#define DEFAULT_HANDLER       5
#define COMMENT_HANDLER       6

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
    
    euexpat *p = EMalloc(sizeof(euexpat));
    XML_Parser xp = XML_ParserCreate(encoding);
    EFree(encoding);
    
    p->start_element_handler = -1;
    p->end_element_handler   = -1;
    p->char_data_handler     = -1;
    p->default_handler       = -1;
    p->comment_handler       = -1;
    
	if ((uintptr_t) xp > (uintptr_t)MAXINT)
		p->p = NewDouble((double)(uintptr_t) xp);
	else
		p->p = (uintptr_t) xp;
	
	if ((uintptr_t) p > (uintptr_t)MAXINT)
		ret = NewDouble((double)(uintptr_t) p);
	else
		ret = (uintptr_t) p;
    
    XML_SetUserData(p->p, p);
    XML_SetElementHandler(p->p, base[START_ELEMENT_HANDLER], base[END_ELEMENT_HANDLER]);
    XML_SetCharacterDataHandler(p->p, base[CHAR_DATA_HANDLER]);
    XML_SetDefaultHandler(p->p, base[DEFAULT_HANDLER]);
    XML_SetCommentHandler(p->p, base[COMMENT_HANDLER]);
    
	return ret;
}

object euexpat_reset_parser(object x)
{
    char *encoding;
    euexpat *p;
    
    s1_ptr encoding_s;
    object_ptr base;
    
    base = SEQ_PTR(x)->base;
    
    if (!IS_SEQUENCE(base[2]))
        RTFatal("second argument to reset_parser must be a sequence");
    
    encoding_s = SEQ_PTR(base[2]);
    encoding = EMalloc(encoding_s->length + 1);
    MakeCString(encoding, base[2], encoding_s->length + 1);
    
    p = ATOM_INT_VAL(base[1]);
    
    XML_ParserReset(p->p, encoding);
    
    EFree(encoding);
    
    return 0;
}

/*
 * free_parser(parser)
 */

object euexpat_free_parser(object x)
{
    object parser = SEQ_PTR(x)->base[1];
    euexpat *p = ATOM_INT_VAL(parser);
    XML_ParserFree(p->p);
    EFree(p);
    
    return 0;
}

/*
 * parse(parser, buffer)
 */

object euexpat_parse(object x)
{
    object_ptr base = SEQ_PTR(x)->base;
    
    if (!IS_SEQUENCE(base[2]))
        RTFatal("second argument to parse must be a sequence");
    
    s1_ptr buffer_s = SEQ_PTR(base[2]);
    char *buffer = EMalloc(buffer_s->length + 1);
    MakeCString(buffer, base[2], buffer_s->length + 1);
    
    euexpat *p = ATOM_INT_VAL(base[1]);
    
    int parse_result = XML_Parse(p->p, buffer, buffer_s->length, 1);
    EFree(buffer);
    
    if (parse_result == 0) {
        int error_code = XML_GetErrorCode(p->p);
        char *error_str = XML_ErrorString(error_code);
        int error_line = XML_GetCurrentLineNumber(p->p);
        int error_column = XML_GetCurrentColumnNumber(p->p);
        int error_byte_index = XML_GetCurrentByteIndex(p->p);
        
        s1_ptr r = NewS1(5);
        r->base[1] = error_code;
        r->base[2] = NewString(error_str);
        r->base[3] = error_line;
        r->base[4] = error_column;
        r->base[5] = error_byte_index;
        
        return MAKE_SEQ(r);
    }
    
    return parse_result;
}

#define START_ELEMENT_CALLBACK 1
#define END_ELEMENT_CALLBACK   2
#define CHAR_DATA_CALLBACK     3
#define DEFAULT_CALLBACK       4
#define COMMENT_CALLBACK       5

/*
 * set_callback(parser, callback_type, routine_id)
 */

object euexpat_set_callback(object x)
{
    object_ptr base = SEQ_PTR(x)->base;
    
    euexpat *p = ATOM_INT_VAL(base[1]);
    int callback_type = ATOM_INT_VAL(base[2]);
    int rtn_id = ATOM_INT_VAL(base[3]);
    
    switch (callback_type) {
        case START_ELEMENT_CALLBACK:
            p->start_element_handler = rtn_id;
            break;
        
        case END_ELEMENT_CALLBACK:
            p->end_element_handler = rtn_id;
            break;
        
        case CHAR_DATA_CALLBACK:
            p->char_data_handler = rtn_id;
            break;
        
        case DEFAULT_CALLBACK:
            p->default_handler = rtn_id;
            break;
        
        case COMMENT_CALLBACK:
            p->comment_handler = rtn_id;
            break;
    }
    
    return 0;
}

/*
 * get_callback(parser, callback_type)
 */

object euexpat_get_callback(object x)
{
    object_ptr base = SEQ_PTR(x)->base;
    
    euexpat *p = ATOM_INT_VAL(base[1]);
    int callback_type = ATOM_INT_VAL(base[2]);
    
    switch (callback_type) {
        case START_ELEMENT_CALLBACK:
            return p->start_element_handler;
        
        case END_ELEMENT_CALLBACK:
            return p->end_element_handler;
        
        case CHAR_DATA_CALLBACK:
            return p->char_data_handler;
        
        case DEFAULT_CALLBACK:
            return p->default_handler;
        
        case COMMENT_CALLBACK:
            return p->comment_handler;
    }
    
    return -1;
}