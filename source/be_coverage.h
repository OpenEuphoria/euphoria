#ifndef COVERAGE_H_
#define COVERAGE_H_

int cover_line;
int cover_routine;
int write_coverage_db;

void COVER_LINE( int );
void COVER_ROUTINE( int );
long WRITE_COVERAGE_DB();

#endif
