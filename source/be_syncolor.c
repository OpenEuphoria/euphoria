/*****************************************************************************/
/*      (c) Copyright - See License.txt       */
/*****************************************************************************/
/*                                                                           */
/*                          Syntax Color                                     */
/*                                                                           */
/*****************************************************************************/

/* based on syncolor.e */

/******************/
/* Included files */
/******************/
#include <stdlib.h>
#include "be_w.h"

#include <stdint.h>
#if defined(EWINDOWS) && INTPTR_MAX == INT64_MAX
// MSVCRT doesn't handle long double output correctly
#define __USE_MINGW_ANSI_STDIO 1
#endif
#include <stdio.h>
#include <string.h>
#ifdef EWINDOWS
#include <windows.h>
#endif
#ifdef __WATCOMC__
#include <graph.h>
#endif

#include "alldefs.h"
#include "be_alloc.h"
#include "be_machine.h"
#include "be_syncolor.h"

int syncolor = -1;

/*********************/
/* Defined functions */
/*********************/

void init_class()
/* set up character classes for easier line scanning */
{
	/* since the Euphoria front end has its own version of this */
	/* and calls it upon initialization, we don't need it here. */
}

int DisplayColorLine(char *pline, int string_color, int last_multi )
/* Display a '\0'-terminated line with colors identifying the various
 * parts of the Euphoria language.
 * Each screen write has a lot of overhead, so we try to minimize
 * the number of them by collecting consecutive characters of the
 * same color into a 'segment' seg_start..seg_end.
 */
{
	int scolor;
	object line;
	int multi = 0;
	scolor = get_pos_int("DisplayColorLine", string_color);
	line = NewString(pline);

	if (syncolor != -1)
	{
		multi = internal_general_call_back(syncolor,
		line,scolor,last_multi, 0,0,0, 0,0,0);
	}
	else
	{
		/* if we don't have the front end code **
		** then we fall back to outputing the line without color */
		screen_output(NULL, pline);
	}
	return multi;
}
