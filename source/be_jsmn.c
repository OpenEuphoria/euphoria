
#include <stdint.h>
#if defined(EWINDOWS) && INTPTR_MAX == INT64_MAX
// MSVCRT doesn't handle long double output correctly
#define __USE_MINGW_ANSI_STDIO 1
#endif
#include <stdio.h>
#include <stdlib.h>

#ifdef EWINDOWS
#  include <windows.h>
#endif
#if defined(EWINDOWS)
#  include "jsmn/config.h" /* cannot make it link w/o it */
#endif
#ifdef EMINGW
#  include "jsmn/jsmn_internal.h"
#endif

#include <ctype.h>
#include <string.h>
#include "alldefs.h"
#include "be_alloc.h"
#include "be_runtime.h"
#include "global.h"
#include "be_jsmn.h"
#include "be_machine.h"

object json_parse( object json )
{
	char* js; size_t len, i;
	unsigned int num_tokens;
	jsmn_parser parser;
	jsmntok_t* tokens;
	jsmnerr_t result;
	
	if ( !IS_SEQUENCE(json) ) {
		RTFatal("json_parse expected a sequence");
	}
	
	len = SEQ_PTR(json)->length + 1;
	js = EMalloc( len );
	MakeCString( js, json, len );
	
	num_tokens = 256;
	tokens = (jsmntok_t*)EMalloc( sizeof(jsmntok_t) * num_tokens );

	jsmn_init( &parser );
	result = jsmn_parse( &parser, js, len, tokens, num_tokens );
	
	while ( result == JSMN_ERROR_NOMEM ) {
		num_tokens += 128;
		tokens = (jsmntok_t*)ERealloc( (char*)tokens, sizeof(jsmntok_t) * num_tokens );

		jsmn_init( &parser );
		result = jsmn_parse( &parser, js, len, tokens, num_tokens );
	}
	
	if ( result < 0 ) {
		return MAKE_INT(result);
	}
	
	s1_ptr s = NewS1( result );
	for (i = 0; i < result; i++)
	{
		jsmntok_t* t = &tokens[i];
		
		s1_ptr n = NewS1( 5 );
		n->base[1] = MAKE_INT( t->type );
		n->base[2] = MAKE_INT( t->start + 1 );
		n->base[3] = MAKE_INT( t->end );
		n->base[4] = MAKE_INT( t->size );
		n->base[5] = MAKE_INT( t->parent + 1 );
		
		s->base[i+1] = MAKE_SEQ( n );
	}
	
	EFree( tokens );
	EFree( js );
	
	return MAKE_SEQ( s );
}
