#ifndef COVERAGE_H_
#define COVERAGE_H_

extern int cover_line;
extern int cover_routine;
extern int write_coverage_db;

void COVER_LINE( int );
void COVER_ROUTINE( int );
long WRITE_COVERAGE_DB();

#endif
