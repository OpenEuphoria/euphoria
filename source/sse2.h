/* The following is defined only if there are vector operations defined such as SSE2.
   A header file like this one must define ALIGN_SIZE, BASE_ALIGN_SIZE,
   a vreg union an initialization routine and the pointers and flag defined
   below.  It's value is not to be used.  Check only if it is defined. */
#define VECTOROPS 2

/* alignment of pointer objects.  If you want to
  set this to another number, such as 16, you will have to change loads of code in be_alloc and
  be_runtime. */
#define ALIGN_SIZE 8

/* alignment memory must be at to call the SSE2 instructions */
#define BASE_ALIGN_SIZE 16 
/* a variable type of the same size and structure of a 
vector register.  In this case the SSE2 XMM register.  In 
the case where the vectors are scalar 4. */

/* Assumption: size of this is a power of 2 */
typedef union {
	object obj[4];
	double dbl[2];
} vreg;
void sse2_variable_init();
/* The following are pointers to aligned register sized values */
extern object_ptr NOVALUE_128bit, MINUSONES_128bit, ZEROS_128bit;
extern object_ptr MAXINT_128bit, MININT_128bit;
extern object_ptr overunder_128bit, integer_128bit, intermediate_128bit;
/* iterate flag */
extern signed long iterate_over_double_words;
extern object_ptr vregs_temp;
#ifndef EWATCOM
#	error	SSE2 instructions not defined for this compiler
#endif

