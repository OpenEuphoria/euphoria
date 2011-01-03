#include <stdlib.h>

#include "be_coverage.h"
#include "be_machine.h"

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
