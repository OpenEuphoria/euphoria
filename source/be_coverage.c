#include "be_coverage.h"
#include <stdlib.h>

unsigned internal_general_call_back(
		  int cb_routine,
						   unsigned arg1, unsigned arg2, unsigned arg3,
						   unsigned arg4, unsigned arg5, unsigned arg6,
						   unsigned arg7, unsigned arg8, unsigned arg9);

int cover_line = -1, cover_routine = -1, write_coverage_db = -1;

void COVER_LINE(int line)
{
	if (cover_line != -1)
	{
		internal_general_call_back(cover_line,
		line,0,0, 0,0,0, 0,0,0);
	}
}

void COVER_ROUTINE(int routine)
{
	if (cover_routine != -1)
	{
		internal_general_call_back(cover_routine,
		routine,0,0, 0,0,0, 0,0,0);
	}
}

long WRITE_COVERAGE_DB()
{
	if (write_coverage_db != -1)
	{
		return (long)internal_general_call_back(write_coverage_db,
		0,0,0, 0,0,0, 0,0,0);
	}
	return 0;
}

void SET_COVERAGE(int line, int routine, int write)
{
	cover_line = line;
	cover_routine = routine;
	write_coverage_db = write;
}
