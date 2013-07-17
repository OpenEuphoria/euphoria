
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
#  include "pcre/config.h" /* cannot make it link w/o it */
#endif
#ifdef EMINGW
#  include "pcre/pcre_internal.h"
#endif

#include <ctype.h>
#include <string.h>
#include "alldefs.h"
#include "be_alloc.h"
#include "be_runtime.h"
#include "global.h"
#include "be_pcre.h"
#include "be_machine.h"

void pcre_deref(object re) {
	pcre_cleanup_ptr rcp;
	object errmsg;
	if (IS_ATOM_DBL(re)) {
		rcp = (pcre_cleanup_ptr)(DBL_PTR(re)->cleanup);
		if (rcp != 0) {
			if ( (errmsg = rcp->errmsg) ) {
				DeRefDS(errmsg);
				rcp->errmsg = 0;
			}
		}
	} else if (IS_SEQUENCE(re)) {
		rcp = (pcre_cleanup_ptr)(SEQ_PTR(re)->cleanup);
		if (rcp->re) {
			(*pcre_free)(rcp->re);
			rcp->re = 0;
		}
	} else {
		RTFatal("Object is being de-referenced as a regex variable but is not.");
	}
}


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
	MakeCString( str, pattern, SEQ_PTR(pattern)->length + 1 );
	re = pcre_compile( str, pflags, &error, &erroffset, NULL );
	EFree( str );
	if( re == NULL ){
		// error, so pass the error string to caller
		return NewString( (char *)error );
	}
	
	
	if ((uintptr_t) re > (uintptr_t)MAXINT)
		ret = NewDouble((double)(uintptr_t)re);
	else
		ret = (uintptr_t)re;
	
	return ret;
}


/* Acceptable values for flags in compile_pcre() is a
   bitmask or of the following flags:
   DEFAULT				,
   AUTO_CALLOUT       ,
   ANCHORED           ,
   NEWLINE_CR         ,
   NEWLINE_LF         ,
   NEWLINE_CRLF       ,
   NEWLINE_ANY        ,
   NEWLINE_ANYCRLF    ,
   BSR_ANYCRLF        ,
   BSR_UNICODE		   ,
   CASELESS           ,
   MULTILINE          ,
   DOTALL             ,
   EXTENDED           ,
   UNGREEDY           ,
   EXTRA              ,
   UTF8
 */
object compile_pcre(object x, object flags) {
	
	pcre_cleanup_ptr rcp;
	object compiled_regex;
	s1_ptr regex;
	
	compiled_regex = compile(x, flags);
	
	// Check to see if a sequence was returned. If so, the compile failed and the return
	// value is actually an error message.
	if (IS_SEQUENCE(compiled_regex)) {
		x = NewDouble((double) 0);
		rcp = (pcre_cleanup_ptr)EMalloc(sizeof(struct pcre_cleanup));
		rcp->cleanup.func.builtin = &pcre_deref;
		rcp->cleanup.type = CLEAN_PCRE;
		rcp->cleanup.next = 0;
		rcp->errmsg = compiled_regex;
		rcp->re = 0;
		DBL_PTR(x)->cleanup = (cleanup_ptr) rcp;
	} else {
		RefDS( x );  // Sequence Copy will de-ref, which we don't want here
		regex = SequenceCopy( SEQ_PTR( x ) );
		
		rcp = (pcre_cleanup_ptr)EMalloc(sizeof(struct pcre_cleanup));
		rcp->cleanup.next = 0;
		
		rcp->cleanup.func.builtin = &pcre_deref;
		rcp->cleanup.type = CLEAN_PCRE;
		rcp->errmsg = 0;
		
		
		regex->cleanup = (cleanup_ptr) rcp;
		if( IS_ATOM_INT( compiled_regex ) ){
			rcp->re = (struct real_pcre *) compiled_regex;
		}
		else {
			rcp->re = (struct real_pcre *) (uintptr_t) DBL_PTR( compiled_regex )->dbl;
		}
		x = MAKE_SEQ( regex );
	}
	
	return x;
}

object pcre_error_message(object x)
{
	pcre_cleanup_ptr rcp;
	object x1 = SEQ_PTR(x)->base[1];
	
	if (!IS_ATOM_DBL(x1)) {
		return 0;
	}
	
	rcp = (pcre_cleanup_ptr)(DBL_PTR(x1)->cleanup);
	if (rcp->errmsg == 0) {
		return 0;
	}
	
	RefDS(rcp->errmsg);
	
	return rcp->errmsg;
}

pcre *get_re(object x) {
	// Makes sure that the regex has been compiled, and then returns
	// the compiled regex
	pcre_cleanup_ptr rcp = (pcre_cleanup_ptr)(SEQ_PTR(x)->cleanup);
	if (rcp == 0) {
		return 0;
	}
	
	return rcp->re;
}

object get_ovector_size(object x ){
	object pcre_ptr;
	pcre* re;
	int where, rc;
	
	pcre_ptr = SEQ_PTR(x)->base[1];
	re = get_re(pcre_ptr);
	
	rc = pcre_fullinfo(re, NULL, PCRE_INFO_CAPTURECOUNT, &where);
	if (rc == 0) return where;
	return rc;
}

object exec_pcre(object x ){
	int rc;
	int ovector_size;
	pcre* re;
	char* str;
	int strLen, freeStr;
	s1_ptr s;
	s1_ptr sub;
	int i, j;
	object pcre_ptr;
	int options;
	int start_from;
	int * ovector;
	int ovector_elements;
	
	// x[1] = pcre ptr
	// x[2] = string to search (sequence or atom - char*)
	// x[3] = string to search length
	// x[4] = options
	// x[5] = start_from
	// x[6] = ovector size
	
	pcre_ptr = SEQ_PTR(x)->base[1];
	re = get_re(pcre_ptr);
	
	if (IS_SEQUENCE(SEQ_PTR(x)->base[2])) {
		sub = SEQ_PTR(SEQ_PTR(x)->base[2]);
		str = EMalloc(sub->length+1);
		MakeCString( str, SEQ_PTR(x)->base[2], sub->length+1 );
		strLen = get_int(SEQ_PTR(x)->base[3]);
		freeStr = 1;
	} else {
		str = (char *)get_int(SEQ_PTR(x)->base[2]);
		strLen = get_int(SEQ_PTR(x)->base[3]);
		freeStr = 0;
	}
	
	options    = get_int( SEQ_PTR(x)->base[4] );
	start_from = get_int( SEQ_PTR(x)->base[5] ) - 1;
	ovector_elements = get_int( SEQ_PTR(x)->base[6] );
	ovector_size = (ovector_elements+1) * 3;
	ovector = (int *)EMalloc(sizeof(int)*ovector_size);
	
	rc = pcre_exec( re, NULL, str, strLen, start_from, options, ovector, ovector_size );
	if (freeStr == 1)
		EFree( str );
	
	if( rc < 0 ) { EFree((char *)ovector); return rc; }
	if( rc == 0 ) { rc = ovector_elements+1; }
	
	// put the substrings into sequences
	s = NewS1( rc );
	
	for( i = 1, j=0; i <= rc; i++ ) {
		sub = NewS1( 2 );
		sub->base[1] = ovector[j++] + 1;
		sub->base[2] = ovector[j] > 0 ? ovector[j] : 0;
		j++;
		s->base[i] = MAKE_SEQ( sub );
	}
	
	EFree((char *)ovector);
	return MAKE_SEQ( s );
}

#define FLAG_UP_CASE     1
#define FLAG_DOWN_CASE   2
#define FLAG_UP_NEXT     4
#define FLAG_DOWN_NEXT   8

static int add(int *len, char **s, const char *a, int alen, int *flag) {
    int NewLen = *len + alen + 1;
    int i;
    int res;
	
    NewLen = NewLen * 2;
	
    if (alen == 0)
        return 0;
	
    if (*s) {
        *s = (char *) ERealloc(*s, NewLen);
        res = memcopy(*s + *len, NewLen, (void *)a, alen);
		if (res != 0) {
			RTFatal("Internal error: be_pcre:add#1 memcopy failed (%d).", res);
		}
    } else {
        *s = (char *) EMalloc(NewLen);
        res = memcopy(*s, NewLen, (void *)a, alen);
		if (res != 0) {
			RTFatal("Internal error: be_pcre:add#2 memcopy failed (%d).", res);
		}
		
        *len = 0;
    }
    if (*flag & FLAG_UP_CASE) {
        char *p = *s + *len;
		
        for (i = 0; i < alen; i++) {
            *p = (char)toupper(*p);
            p++;
        }
    } else if (*flag & FLAG_DOWN_CASE) {
        char *p = *s + *len;
		
        for (i = 0; i < alen; i++) {
            *p = (char)tolower(*p);
            p++;
        }
    }
    if (*flag & FLAG_UP_NEXT) {
        char *p = *s + *len;
		
        *p = (char)toupper(*p);
        *flag &= ~FLAG_UP_NEXT;
    } else if (*flag & FLAG_DOWN_NEXT) {
        char *p = *s + *len;
		
        *p = (char)tolower(*p);
        *flag &= ~FLAG_DOWN_NEXT;
    }
    *len += alen;
    return 0;
}
/*
   rep = replacement pattern
   src = source string
   ovector = matches from exec_pcre
   count = match count
   dest = destination
   dlen = length of dest
 */

int replace_pcre(const char *rep, const char *Src, int len, int *ovector, int cnt,
				 char **Dest, int *Dlen)
{
    int dlen = 0;
    char *dest = 0;
    char Ch;
    int n, st;
    int flag = 0;
	
    *Dest = 0;
    *Dlen = 0;
	add(&dlen, &dest, Src, ovector[0], &flag);
    while (*rep) {
		switch (Ch = *rep++) {
		case '\\':
			switch (Ch = *rep++) {
			case '0':
			case '1':
            case '2':
            case '3':
            case '4':
            case '5':
            case '6':
            case '7':
            case '8':
            case '9':
				if (Ch-48 < cnt) {
					st = 0;
					for (n = 0; n < Ch-48; n++) {
						st += 2;
					}
					
					if (ovector[st] != -1 && ovector[st+1] != 0) {
						add(&dlen, &dest, Src + ovector[st], ovector[st+1] - ovector[st], &flag);
					}
					else {
						return -1;
					}
				}
				break;
            case 0:
                if (dest) EFree(dest);
                return -1; // error
            case 'r':
                Ch = '\r';
                add(&dlen, &dest, &Ch, 1, &flag);
                break;
            case 'n':
                Ch = '\n';
                add(&dlen, &dest, &Ch, 1, &flag);
                break;
            case 'b':
                Ch = '\b';
                add(&dlen, &dest, &Ch, 1, &flag);
                break;
            case 'a':
                Ch = '\a';
                add(&dlen, &dest, &Ch, 1, &flag);
                break;
            case 't':
                Ch = '\t';
                add(&dlen, &dest, &Ch, 1, &flag);
                break;
            case 'U':
                flag |= FLAG_UP_CASE;
                break;
            case 'u':
                flag |= FLAG_UP_NEXT;
                break;
            case 'L':
                flag |= FLAG_DOWN_CASE;
                break;
            case 'l':
                flag |= FLAG_DOWN_NEXT;
                break;
            case 'E':
            case 'e':
                flag &= ~(FLAG_UP_CASE | FLAG_DOWN_CASE);
                break;
            case 'x': {
                int N = 0;
                int A = 0;
				
                if (*rep == 0) {
                    EFree(dest);
                    return 0;
                }
                N = toupper(*rep) - 48;
                if (N > 9) N = N + 48 - 65 + 10;
                if (N > 15) return 0;
                rep++;
                A = N << 4;
                if (*rep == 0) {
                    EFree(dest);
                    return 0;
                }
                N = toupper(*rep) - 48;
                if (N > 9) N = N + 48 - 65 + 10;
                if (N > 15) return 0;
                rep++;
                A = A + N;
                Ch = (char)A;
            }
				add(&dlen, &dest, &Ch, 1, &flag);
				break;
            case 'd': {
                int N = 0;
                int A = 0;
				
                if (*rep == 0) {
                    EFree(dest);
                    return 0;
                }
                N = toupper(*rep) - 48;
                if (N > 9) {
                    EFree(dest);
                    return 0;
                }
                rep++;
                A = N * 100;
                if (*rep == 0) {
                    EFree(dest);
                    return 0;
                }
                N = toupper(*rep) - 48;
                if (N > 9) {
                    EFree(dest);
                    return 0;
                }
                rep++;
                A = N * 10;
                if (*rep == 0) {
                    EFree(dest);
                    return 0;
                }
                N = toupper(*rep) - 48;
                if (N > 9) {
                    EFree(dest);
                    return 0;
                }
                rep++;
                A = A + N;
                Ch = (char)A;
            }
				add(&dlen, &dest, &Ch, 1, &flag);
				break;
            case 'o': {
                int N = 0;
                int A = 0;
				
                if (*rep == 0) {
                    EFree(dest);
                    return 0;
                }
                N = toupper(*rep) - 48;
                if (N > 7) {
                    EFree(dest);
                    return 0;
                }
                rep++;
                A = N * 64;
                if (*rep == 0) {
                    EFree(dest);
                    return 0;
                }
                N = toupper(*rep) - 48;
                if (N > 7) {
                    EFree(dest);
                    return 0;
                }
                rep++;
                A = N * 8;
                if (*rep == 0) {
                    EFree(dest);
                    return 0;
                }
                N = toupper(*rep) - 48;
                if (N > 7) {
                    EFree(dest);
                    return 0;
                }
                rep++;
                A = A + N;
                Ch = (char)A;
            }
				add(&dlen, &dest, &Ch, 1, &flag);
				break;
            default:
                add(&dlen, &dest, &Ch, 1, &flag);
                break;
            }
            break;
        default:
            add(&dlen, &dest, &Ch, 1, &flag);
            break;
        }
    }
	add(&dlen, &dest, Src + ovector[1], len - ovector[1] + 1, &flag);
	
    *Dlen = dlen;
    *Dest = dest;
	dest[dlen] = 0; // make sure it's zero terminated
    return 0;
}

object find_replace_pcre(object x )
{
	int rc;
	int ovector[30], out_len = 0;
	pcre *re;
	char *str, *rep, *out = 0;
	
	s1_ptr sub;
	s1_ptr rep_s;
	
	object pcre_ptr;
	int options;
	int start_from;
	int limit;
	
	// x[1] = pcre ptr
	// x[2] = string to search
	// x[3] = replacement
	// x[4] = options
	// x[5] = start_from
	// x[6] = limit
	
	pcre_ptr = SEQ_PTR(x)->base[1];
	re = get_re(pcre_ptr);
	
	sub = SEQ_PTR(SEQ_PTR(x)->base[2]);
	str = EMalloc(sub->length+1);
	MakeCString( str, SEQ_PTR(x)->base[2], sub->length+1 );
	
	rep_s = SEQ_PTR(SEQ_PTR(x)->base[3]);
	rep = EMalloc(rep_s->length+1);
	MakeCString(rep, SEQ_PTR(x)->base[3], rep_s->length+1);
	
	options    = get_int(SEQ_PTR(x)->base[4]);
	start_from = get_int(SEQ_PTR(x)->base[5]) - 1;
	limit      = get_int(SEQ_PTR(x)->base[6]);
	out_len    = SEQ_PTR(SEQ_PTR(x)->base[2])->length;
	
	while (1) {
		rc = pcre_exec(re, NULL, str, out_len, start_from, options, ovector, 30);
		
		if (rc <= 0 || limit == 0) {
			EFree(rep);
			
			return NewString(str);
		}
		
		if (out != 0) {
			EFree(out);
		}
		
		rc = replace_pcre(rep, str, out_len-1, ovector, rc, &out, &out_len);
		EFree(str);
		
		str = EMalloc(out_len + 2);
		copy_string(str, out, out_len + 1);
		
		start_from = ovector[rc] + rep_s->length;
		limit -= 1;
	}
	
	return ATOM_0;
}

