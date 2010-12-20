// Don't delete!
// You can compile this file into a shared library with:
//
//              gcc -shared Mylib.c -o mylib.so
//
// Feel free to add other C routines below.

int extra = 99;

int sum(int x)
// compute the sum of the integers from 1 to x
// (x+1)*x/2 would be faster!
// then add the global var "extra"
{
    int i, sum;
    
    sum = 0;
    for (i = 1; i <= x; i++)
	sum += i;
    return sum + extra;
}
