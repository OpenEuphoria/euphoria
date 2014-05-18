#ifndef OBJECT_H_
#define OBJECT_H_

#include <stdint.h>

typedef intptr_t object;
typedef object *object_ptr;

struct cleanup;
typedef struct cleanup *cleanup_ptr;
typedef void(*cleanup_func)(object);

struct cleanup {
	int type;
	union func_union{
		int rid;
		cleanup_func builtin;
	} func;
	cleanup_ptr next;
};

struct s1 {                        /* a sequence header block */
	object_ptr base;               /* pointer to (non-existent) 0th element */
#if INTPTR_MAX == INT32_MAX
	int length;                   /* number of elements */
	int ref;                      /* reference count */
	cleanup_ptr cleanup;           /* custom clean up when sequence is deallocated */
	int postfill;                 /* number of post-fill objects */
#else
	cleanup_ptr cleanup;           /* custom clean up when sequence is deallocated */
	intptr_t ref;                      /* reference count */
	intptr_t length;                   /* number of elements */
	intptr_t postfill;                 /* number of post-fill objects */
#endif
	
}; /* total 20 bytes */

#if INTPTR_MAX == INT32_MAX
typedef double eudouble;
#else
typedef long double eudouble;
#endif

struct d {                         /* a double precision number */
	eudouble dbl;                    /* double precision value */
#if INTPTR_MAX == INT32_MAX
	int ref;                      /* reference count */
#else
	intptr_t ref;                      /* reference count */
#endif
	cleanup_ptr cleanup;           /* custom clean up when sequence is deallocated */
}; /* total 16 bytes */

#define D_SIZE (sizeof(struct d))  

typedef struct d  *d_ptr;
typedef struct s1 *s1_ptr;


#endif
