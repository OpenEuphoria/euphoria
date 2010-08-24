#ifndef OBJECT_H_
#define OBJECT_H_

#include <inttypes.h>

#if EBITS == 32

#define eulong int

#elif EBITS == 64

#define eulong long long

#endif

typedef eulong object;
typedef object *object_ptr;

struct cleanup;
typedef struct cleanup *cleanup_ptr;
typedef void(*cleanup_func)(object);

struct cleanup {
	eulong type;
	union func_union{
		eulong rid;
		cleanup_func builtin;
	} func;
	cleanup_ptr next;
};

struct s1 {                        /* a sequence header block */
	object_ptr base;               /* pointer to (non-existent) 0th element */
	#if EBITS == 32
		eulong length;                   /* number of elements */
		eulong ref;                      /* reference count */
	#elif EBITS == 64
		eulong ref;                      /* reference count */
		eulong length;                   /* number of elements */
	#endif
	eulong postfill;                 /* number of post-fill objects */
	cleanup_ptr cleanup;           /* custom clean up when sequence is deallocated */
}; /* total 20 bytes */

struct d {                         /* a double precision number */
	double dbl;                    /* double precision value */
	eulong ref;                      /* reference count */
	cleanup_ptr cleanup;           /* custom clean up when sequence is deallocated */
}; /* total 16 bytes */

#define D_SIZE (sizeof(struct d))  

typedef struct d  *d_ptr;
typedef struct s1 *s1_ptr;


#endif
