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
#include <stdio.h>
#include <string.h>
#ifdef _WIN32
#include <windows.h>
#endif
#ifdef __WATCOMC__
#include <graph.h>
#endif
#include "alldefs.h"
#include "be_runtime.h"
#include "be_w.h"

/******************/
/* Local defines  */
/******************/
#define LMAX 200             /* maximum input line length */
/* colors of various syntax classes */
#define NORMAL_COLOR 0
#define BUILTIN_COLOR 5
#ifdef EUNIX
#define YELLOW 11
#define BRIGHT_CYAN 14
#define BRIGHT_BLUE 12
#define BRIGHT_RED 9
#define COMMENT_COLOR 1
#define KEYWORD_COLOR 4
#else
#define BRIGHT_CYAN 11
#define BRIGHT_BLUE 9
#define BRIGHT_RED 12
#define YELLOW 14
#define COMMENT_COLOR 4
#define KEYWORD_COLOR 1
#endif
//#define STRING_COLOR 2 - varies
/* highlighted background is 3-CYAN - don't use for foreground */

/* character classes */
#define C_DIGIT 1
#define C_OTHER 2
#define C_LETTER 3
#define C_BRACKET 4
#define C_QUOTE 5
#define C_DASH 6
#define C_WHITE_SPACE 7
#define C_NEW_LINE 8

#define LENGTH_BRACKET_COLOR 7

/**********************/
/* Imported variables */
/**********************/

/*******************/
/* Local variables */
/*******************/
static char BRACKET_COLOR[LENGTH_BRACKET_COLOR] = 
			{NORMAL_COLOR, YELLOW, 15, BRIGHT_BLUE, 
			BRIGHT_RED, BRIGHT_CYAN, 10};
static char char_class[256];
static char *line;             /* the line being processed */
static int seg_start, seg_end; /* start and end of current segment of line */
static int color;              /* the current color */
static char segment[LMAX];     /* a segment to be printed */

/* Must be kept in sync with keylist.e in scanner */
static char *keyword[] = {
	"if",
	"end",
	"then",
	"procedure",
	"else",
	"for",
	"return",
	"do",
	"elsif",
	"while",
	"type",
	"constant",
	"to",
	"and",
	"or",
	"exit",
	"function",
	"global",
	"by",
	"not",
	"include",
	"with",
	"without",
	"xor",
	"continue",
	"ifdef",
	"elsifdef",
	"retry",
	"goto",
	"break",
	"label",
	"enum",
	"loop",
	"until",
	"entry",
	"fallthru",
	NULL
};

static char *predefined[] = {
	"length",
	"puts",
	"integer",
	"sequence",
	"position",
	"object",
	"append",
	"prepend",
	"print",
	"printf",
	"clear_screen",
	"floor",
	"getc",
	"gets",
	"get_key",
	"rand",
	"repeat",
	"atom",
	"compare",
	"find",
	"match",
	"time",
	"command_line",
	"open",
	"close",
	"trace",
	"getenv",
	"sqrt",
	"sin",
	"cos",
	"tan",
	"log",
	"system",
	"date",
	"remainder",
	"power",
	"machine_func",
	"machine_proc",
	"abort",
	"peek",
	"poke",
	"call",
	"sprintf",
	"arctan",
	"and_bits",
	"or_bits",
	"xor_bits",
	"not_bits",
	"pixel",
	"get_pixel",
	"mem_copy",
	"mem_set",
	"c_proc",
	"c_func",
	"routine_id",
	"call_proc",
	"call_func",
	"poke4",
	"peek4s",
	"peek4u",
	"profile",
	"equal",
	"system_exec",
	"platform",
	"task_create", 
	"task_schedule",
	"task_yield", 
	"task_self", 
	"task_suspend",
	"task_list", 
	"task_status",
	"task_clock_stop", 
	"task_clock_start",
	"find_from",
	"match_from",
	"poke2",
	"peek2s",
	"peek2u",
	"peeks",
	"peek_string",
	"option_switches",
	"retry",
	"switch",
	"goto",
	"label",
	"splice",
	"insert",
	"hash",
	"head",
	"tail",
	"remove",
	"replace",
	NULL
};

/*********************/
/* Defined functions */
/*********************/

void init_class()
/* set up character classes for easier line scanning */
{
	int i;
	
	char_class[0] = C_NEW_LINE;
	for (i = 1; i <= 255; i++)
		char_class[i] = C_OTHER;
	for (i = 'a'; i <= 'z'; i++)
		char_class[i] = C_LETTER;
	for (i = 'A'; i <= 'Z'; i++)
		char_class[i] = C_LETTER;
	char_class['_'] = C_LETTER;
	for (i = '0'; i <= '9'; i++)
		char_class[i] = C_DIGIT;
	char_class['['] = C_BRACKET;
	char_class[']'] = C_BRACKET;
	char_class['('] = C_BRACKET;
	char_class[')'] = C_BRACKET;
	char_class['{'] = C_BRACKET;
	char_class['}'] = C_BRACKET;
	char_class['\''] = C_QUOTE;
	char_class['"'] = C_QUOTE;
	char_class[' '] = C_WHITE_SPACE;
	char_class['\t'] = C_WHITE_SPACE;
	char_class['\n'] = C_WHITE_SPACE; //C_NEW_LINE;
	char_class['-'] = C_DASH;
}


static int s_find(char *name)
/* look up a name in the keyword/builtin list */
{
	int i;
	i = 0;
	while (keyword[i] != NULL) {
		if (strcmp(name, keyword[i]) == 0) 
			return S_KEYWORD;
		i++;
	}
	i = 0;
	while (predefined[i] != NULL) {
		if (strcmp(name, predefined[i]) == 0) 
			return S_PREDEF;
		i++;
	}
	return -1;
}

static void flush(int new_color)
/* if the color is changing, write out the current segment */
{
	if (new_color != color) {
		if (color != -1) {
			set_text_color(color);
			if (charcopy(segment, LMAX, line+seg_start, seg_end - seg_start + 1) <= 0)
				segment[LMAX-1] = 0; // Force null terminator if buffer too small.
			screen_output(NULL, segment);
			seg_start = seg_end + 1;
		}
		color = new_color;
	}
}

void DisplayColorLine(char *pline, int string_color)
/* Display a '\0'-terminated line with colors identifying the various
 * parts of the Euphoria language.
 * Each screen write has a lot of overhead, so we try to minimize
 * the number of them by collecting consecutive characters of the
 * same color into a 'segment' seg_start..seg_end.
 */
{
	int class, last, i, c, bracket_level;
	char word[LMAX];
	int length, s_type, j;
	
	line = pline;
	length = strlen(line); /* the place where the '\0' exists */
	if (length >= LMAX) 
		line[LMAX-1] = 0;    /* truncate long line */
	color = -1; /* initially undefined */
	bracket_level = -1;
	seg_start = 0;
	seg_end = -1;
	
	while (TRUE) {
		c = line[seg_end+1];
		class = char_class[c];

		if (class == C_WHITE_SPACE) 
			seg_end++;  /* continue with same color */

		else if (class == C_LETTER) {
			last = length-1;
			for (j = seg_end + 2; j <= last; j++) {
				c = line[j];
				class = char_class[c];
				if (class != C_LETTER) {
					if (class != C_DIGIT) {
						last = j - 1;
						break;
					}
				}
			}
			if (charcopy(word, LMAX, line + seg_end + 1, last - seg_end) <= 0)
				word[LMAX - 1] = 0; // Force null terminator if buffer was too small.
			s_type = s_find(word);
			if (s_type == S_KEYWORD) 
				flush(KEYWORD_COLOR);
			else if (s_type == S_PREDEF) 
				flush(BUILTIN_COLOR);
			else
				flush(NORMAL_COLOR);
			seg_end = last;
		}
		
		else if (class <= C_OTHER) {   /* C_DIGIT too */
			flush(NORMAL_COLOR);
			seg_end = seg_end + 1;
		}
		
		else if (class == C_BRACKET) {
			if (c == '(' || c == '[' || c == '{') 
				bracket_level = bracket_level + 1;
			if (bracket_level >= 0 &&
				bracket_level < LENGTH_BRACKET_COLOR) 
				flush(BRACKET_COLOR[bracket_level]);
			else
				flush(NORMAL_COLOR);
			if (c == ')' || c == ']' || c == '}') 
				bracket_level = bracket_level - 1;
			seg_end++;
		}
		
		else if (class == C_NEW_LINE) {
			break;  /* end of line */
		}
		else if (class == C_DASH) {
			if (line[seg_end+2] == '-') {
				flush(COMMENT_COLOR);
				seg_end = length-1;
				break;
			}
			flush(NORMAL_COLOR);
			seg_end++;
		}
		
		else { /* C_QUOTE */
			i = seg_end + 2;
			while (i < length) {
				if (line[i] == c) {
					i = i + 1;
					break;
				}
				else if (line[i] == '\\') {
					if (i < length-1)
						i = i + 1;  /* ignore escaped char */
				}
				i = i + 1;
			}
			flush(string_color);
			seg_end = i - 1;
		}
	}
	
	// flush(-1);
	
	if (color != -1) 
		set_text_color(color);
	if (charcopy(segment, LMAX, line+seg_start, seg_end - seg_start+1) <= 0)
		segment[LMAX - 1] = 0; // Force null terminator if buffer too small.
	screen_output(NULL, segment);
}


