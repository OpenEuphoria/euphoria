#ifndef OBJECT_H_
#define OBJECT_H_


typedef long object;
typedef object *object_ptr;

struct cleanup;
typedef struct cleanup *cleanup_ptr;
typedef void(*cleanup_func)(object);

struct cleanup {
	long type;
	union func_union{
		long rid;
		cleanup_func builtin;
	} func;
	cleanup_ptr next;
};

struct s1 {                        /* a sequence header block */
	object_ptr base;               /* pointer to (non-existent) 0th element */
	long length;                   /* number of elements */
	long ref;                      /* reference count */
	long postfill;                 /* number of post-fill objects */
	cleanup_ptr cleanup;           /* custom clean up when sequence is deallocated */
}; /* total 20 bytes */

struct d {                         /* a double precision number */
	double dbl;                    /* double precision value */
	long ref;                      /* reference count */
	cleanup_ptr cleanup;           /* custom clean up when sequence is deallocated */
}; /* total 16 bytes */

#define D_SIZE (sizeof(struct d))  

typedef struct d  *d_ptr;
typedef struct s1 *s1_ptr;


#endif
