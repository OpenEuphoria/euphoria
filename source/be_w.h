#ifndef BE_W_H
#define BE_W_H

#include "global.h"
#include "execute.h"

void screen_show();
void InitInOut();
int has_console();

#ifdef EUNIX
void screen_copy(struct char_cell a[MAX_LINES][MAX_COLS],
                 struct char_cell b[MAX_LINES][MAX_COLS]);

void update_screen_string(char *s);

// we need to record everything written to the screen
struct char_cell screen_image[MAX_LINES][MAX_COLS];
// plus have two alternate screens for interactive trace
struct char_cell alt_image_main[MAX_LINES][MAX_COLS];
struct char_cell alt_image_debug[MAX_LINES][MAX_COLS];
#endif
/*
  Description: opens a console Window if it doesn't exist and return true if the application started with one.
  
  Returns:
  	1 - if the this is a console app.
	0 - if this is a Windows Windowed application.
*/

extern void check_has_console();
extern int console_application();

#ifdef EWINDOWS
void SaveNormal();
void SaveTrace();
void RestoreTrace();
void RestoreNormal();
void DisableControlCHandling();
extern HANDLE console_input;  // HANDLE for WIN32 console input
extern HANDLE console_output; // HANDLE for WIN32 console output
extern HANDLE console_trace;  // HANDLE for WIN32 output to trace-screen
extern HANDLE console_var_display; // HANDLE for WIN32 output to large sequence display
extern HANDLE console_save;   // place to save console_output while in trace screen
void EClearLines(int first_line, int last_line, int len, WORD attributes);
void ReadInto(WORD * buf, LPTSTR str, int size, unsigned long * n, unsigned long * m, WORD * saved, struct rccoord * pos);
void WriteOutFrom(WORD * buf, LPTSTR str, unsigned long n, unsigned long m, WORD * saved, struct rccoord * pos);

#endif

extern int screen_line;     /* only used by ANSI code Linux */
extern int screen_col;      /* column on screen, needed by expand_tabs below
                         initialized in InitGraphics, then again in InitOutput */
extern int wrap_around;
extern int in_from_keyb;        /* stdin appears to be from keyboard */
extern char *collect;    /* to collect sprintf/sprint output */
extern int have_console;  // is there a console window yet?
extern int already_had_console; /* were we created with a console window or did we have to allocate our own? */

void ClearScreen();
void SetPosition(int line, int col);
struct rccoord GetTextPositionP();
void screen_output(IFILE f, char *out_string);
void screen_output_va(IFILE f, char *out_string, va_list ap);
void screen_output_vararg(IFILE f, char *out_string, ...);
void buffer_screen();
void flush_screen();

#endif
