#ifndef COVERAGE_H_
#define COVERAGE_H_

void COVER_LINE( int );
void COVER_ROUTINE( int );
long WRITE_COVERAGE_DB();
//void SET_COVERAGE(void(*)(int), void(*)(int), long(*)(void));
void SET_COVERAGE(int, int, int);

#endif
