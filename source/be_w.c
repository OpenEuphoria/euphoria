/*****************************************************************************/
/*      (c) Copyright - See License.txt       */
/*****************************************************************************/
/*                                                                           */
/*                       SCREEN OUTPUT HANDLER                               */
/*                                                                           */
/*****************************************************************************/

/******************/
/* Included files */
/******************/
#include <stdint.h>
#if defined(EWINDOWS) && INTPTR_MAX == INT64_MAX
// MSVCRT doesn't handle long double output correctly
#define __USE_MINGW_ANSI_STDIO 1
#endif
#include <stdio.h>
#include <stdarg.h>
#include <time.h>

#ifdef EUNIX
#  include <sys/stat.h>
#  include <unistd.h>
#else
#  ifdef EMINGW
#    include <sys/types.h>
#    include <sys/stat.h>
#  else
#    include <sys\types.h>
#    include <sys\stat.h>
#  endif
#  if !defined(EMINGW)
#      include <graph.h>
#  endif
#endif

#include <string.h>

#ifdef EWINDOWS
#  include <windows.h>
#endif

#include "alldefs.h"
#include "global.h"
#include "be_w.h"
#include "be_machine.h"
#include "be_runtime.h"
#include "be_rterror.h"

/******************/
/* Local defines  */
/******************/
#define TAB_WIDTH 4    /* power of 2 assumed */

/**********************/
/* Exported variables */
/**********************/
int screen_line = 1;     /* only used by ANSI code Linux */
int screen_col = 1;      /* column on screen, needed by expand_tabs below
                         initialized in InitGraphics, then again in InitOutput */
int wrap_around = 1;
int in_from_keyb;        /* stdin appears to be from keyboard */
char *collect = NULL;    /* to collect sprintf/sprint output */
int have_console = FALSE;  // is there a console window yet?
int already_had_console = -1; /* were we created with a console window or did we have to allocate our own? */
#ifdef EWINDOWS
HANDLE console_input;  // HANDLE for WIN32 console input
HANDLE console_output; // HANDLE for WIN32 console output
HANDLE console_trace;  // HANDLE for WIN32 output to trace-screen
HANDLE console_var_display; // HANDLE for WIN32 output to large sequence display
HANDLE console_save;   // place to save console_output while in trace screen
#endif


/*******************/
/* Local variables */
/*******************/
static int out_to_screen;  /* stdout is going to screen */
static int err_to_screen;  /* stderr is going to screen (always TRUE) */
#ifdef EWINDOWS
static CHAR_INFO* line_buffer = 0;
static int line_buffer_size = 0;

static COORD buff_size;
static COORD buff_start;
static SMALL_RECT screen_loc;
#endif
static char *expanded_string = 0;
static char *expanded_ptr;
static char *expanded_end;
static int must_flush = TRUE; /* flush output to screen or not */
static int collect_next;   /* place to store next collect output */
static int collect_free;   /* number of chars of empty space remaining */
#ifdef EUNIX
// we need to record everything written to the screen
struct char_cell screen_image[MAX_LINES][MAX_COLS];
// plus have two alternate screens for interactive trace
struct char_cell alt_image_main[MAX_LINES][MAX_COLS];
struct char_cell alt_image_debug[MAX_LINES][MAX_COLS];
#endif

/**********************/
/* Declared functions */
/**********************/
#include "be_alloc.h"
static void expand_tabs();
void SetPosition();


/*********************/
/* Defined functions */
/*********************/

static int _has_console = 1;

#if defined(EWINDOWS)
#include <windows.h>

typedef int (WINAPI *GCPLA)(LPDWORD, DWORD);

void check_has_console() {
	GCPLA gCPLA;
	HMODULE kernel32;

	kernel32 = LoadLibrary("kernel32.dll");
	gCPLA = (GCPLA) GetProcAddress(kernel32, "GetConsoleProcessList");

	if (gCPLA == NULL) {
		_has_console = 0;
		FreeLibrary(kernel32);
	} 
	else {
		DWORD count, processList[3];

		count = gCPLA( (LPDWORD) &processList, 3);
		FreeLibrary(kernel32);
		_has_console = (count > 1);
	}
}

#else

void check_has_console() {}

#endif

int has_console() {
	return _has_console;
}

struct rccoord GetTextPositionP()
{
        struct rccoord p;

        p.row = screen_line;
        p.col = screen_col;
        return p;
}


#ifdef EUNIX
void screen_copy(struct char_cell a[MAX_LINES][MAX_COLS],
                 struct char_cell b[MAX_LINES][MAX_COLS])
// copy a screen to another area
{
    int i, j;

    for (i = 0; i < line_max; i++) {
        for (j = 0; j < col_max; j++) {
            b[i][j] = a[i][j];  // structure copy
        }
    }
}

void screen_show()
// display a screen
{
    int i, j;

    for (i = 0; i < line_max; i++) {
        SetPosition(i+1, 1);
        for (j = 0; j < col_max; j++) {
            SetTColor(screen_image[i][j].fg_color);
            SetBColor(screen_image[i][j].bg_color);
            iputc(screen_image[i][j].ascii, stdout);
        }
    }
    iflush(stdout);
}
#endif

#if defined (EUNIX)
void Set_Image(struct char_cell image[MAX_LINES][MAX_COLS], char vch, char fg, char bg)
{
  int i, j;
  
    for (i = 0; i < line_max; i++) {
        for (j = 0; j < col_max; j++) {
            image[i][j].ascii = vch;
            image[i][j].fg_color = fg;
            image[i][j].bg_color = bg;
        }
    }
}
#endif

void InitInOut()
/* Set up stdout and stderr. In EWINDOWS some stuff
   is initialized right away. The rest is done later if necesssary on first
   use of the console - see show_console() below. */
{
    struct rccoord position;
#ifdef EWINDOWS
    position.col = 1;   // should do these 2 properly
    position.row = 1;
    screen_line = position.row;
    screen_col = position.col;

    buff_size.Y = 1;
    buff_start.X = 0;
    buff_start.Y = 0;
#endif
#if defined(EUNIX)
    position.col = 1;
    position.row = 1;
    in_from_keyb  = isatty(0);
    out_to_screen = isatty(1);
    err_to_screen = isatty(2);
    screen_line = position.row;
    screen_col = position.col;

	Set_Image(screen_image, ' ', 15, 0);
#endif
}

int console_application() {
#if defined(EWINDOWS)
	if (!have_console)
			show_console();
		
	return already_had_console;
#else
	return 1;
#endif
}


#if defined(EWINDOWS)
void show_console()
/* set up a console window if not done yet */
{
    CONSOLE_SCREEN_BUFFER_INFO info;
    CONSOLE_CURSOR_INFO c;
    INPUT_RECORD pbuffer;
    DWORD junk;
    int alloc_ret;
    HANDLE stderr_cons;

    if (have_console)
        return;

    have_console = TRUE;
    alloc_ret = !AllocConsole();
    if (already_had_console < 0) {
        // this effectively tells us if we were started as a GUI app or a CONSOLE app (euiw.exe or eui.exe)
        already_had_console = alloc_ret;
    }

    console_output = GetStdHandle(STD_OUTPUT_HANDLE);

    console_trace = CreateConsoleScreenBuffer(GENERIC_READ | GENERIC_WRITE,
                                      FILE_SHARE_READ | FILE_SHARE_WRITE,
                                      NULL,
                                      CONSOLE_TEXTMODE_BUFFER,
                                      NULL);

    console_var_display = CreateConsoleScreenBuffer(GENERIC_READ | GENERIC_WRITE,
                                      FILE_SHARE_READ | FILE_SHARE_WRITE,
                                      NULL,
                                      CONSOLE_TEXTMODE_BUFFER,
                                      NULL);

    c.dwSize = 12;
    c.bVisible = FALSE;
    SetConsoleCursorInfo(console_trace, &c);

    out_to_screen = GetConsoleScreenBufferInfo(console_output, &info);

    if (!out_to_screen) {
        console_output = CreateFile("CONOUT$",
                                GENERIC_READ | GENERIC_WRITE,
                                FILE_SHARE_WRITE,
                                NULL,
                                OPEN_EXISTING,
                                0,
                                NULL);
    }

    if (EuConsole){
	/* when this is set, allow stderr to be redirected so rxvt (which redirects it to a pipe) will work */
    	stderr_cons = GetStdHandle(STD_ERROR_HANDLE);
    	err_to_screen = GetConsoleScreenBufferInfo(stderr_cons, &info);
    } else {
    	err_to_screen = TRUE;  /* stderr always goes to screen in WIN32 */
    }

    console_input = GetStdHandle(STD_INPUT_HANDLE);

    in_from_keyb = PeekConsoleInput(console_input, &pbuffer, 1, &junk);

    // This stops the mouse cursor from appearing in full screen
    SetConsoleMode(console_input, ENABLE_LINE_INPUT |
                            ENABLE_ECHO_INPUT |
                            ENABLE_PROCESSED_INPUT);  // no mouse please

    NewConfig(TRUE); // update line_max and col_max
}
#endif

#ifdef EWINDOWS
static void end_of_line(int c)
// handle \n or \r in Windows console
{
    CONSOLE_SCREEN_BUFFER_INFO console_info;

    GetConsoleScreenBufferInfo(console_output, &console_info); // not always necessary?
    console_info.dwCursorPosition.X = 0;
    if (c == '\n') {
//         if (console_info.dwCursorPosition.Y < console_info.dwMaximumWindowSize.Y - 1)
        if (console_info.dwCursorPosition.Y < console_info.dwSize.Y - 1)
            console_info.dwCursorPosition.Y++;
        else {
            // scroll screen up one line
            SMALL_RECT src, clip;
            COORD dest;
            COORD pos;
            CHAR_INFO fill_char;

            if (EuConsole){
                pos.X = 0;
                pos.Y = console_info.dwSize.Y-1;
                SetConsoleCursorPosition(console_output, pos);
            }

            src.Left = 0;
//             src.Right = console_info.dwMaximumWindowSize.X - 1;
            src.Right = console_info.dwSize.X - 1;
            src.Top = 0;
            src.Bottom = console_info.dwSize.Y-1; // -1 ???
            clip = src;
            dest.X = 0;
            dest.Y = src.Top - 1; // for now - ok???
            fill_char.Char.AsciiChar = ' ';
            fill_char.Attributes = console_info.wAttributes;
            ScrollConsoleScreenBuffer(console_output,
                                      &src,
                                      &clip,
                                      dest,
                                      &fill_char);
        }
    }
    SetConsoleCursorPosition(console_output, console_info.dwCursorPosition);
}

#ifdef EWINDOWS
int MyReadConsoleChar()
// Read the next character typed by the user on the console
{
    DWORD nread;
    char buff[4];

    ReadConsole(console_input, buff, 1, &nread, NULL);
    return buff[0];
}
#endif
static char *old_string = 0;
static int  oldstr_len = 0;
static void MyWriteConsole(char *string, int nchars)
// write a string of plain characters to the console and
// update the cursor position
{
    unsigned long i;
    static int first = 0;
    CONSOLE_SCREEN_BUFFER_INFO console_info;

    COORD ch;

    show_console();
    /* hack - if we are eui, output something to avoid data appearing on the
     last line of the console which we later on will not be able to see */
    GetConsoleScreenBufferInfo(console_output, &console_info); // not always necessary?
    if ( EuConsole && (already_had_console==1) && !first) {
        if (!(console_info.dwCursorPosition.Y < console_info.dwSize.Y - 1))
        {
            end_of_line('\n');
        }
        first = 1;
    }

    buff_size.X = nchars;

    screen_loc.Top = console_info.dwCursorPosition.Y;
    screen_loc.Bottom = screen_loc.Top;
    screen_loc.Left = console_info.dwCursorPosition.X; //screen_col-1;
//     screen_loc.Right = console_info.dwMaximumWindowSize.X - 1;
    screen_loc.Right = console_info.dwSize.X - 1;

    if (EuConsole){

	    ch.X = screen_loc.Left;
	    ch.Y = screen_loc.Top;
		if (old_string == 0) {
			oldstr_len = max(nchars + 3, 256);
			old_string = (char *)EMalloc(oldstr_len);
			if (old_string == 0) return;
		}
	
		if (nchars > oldstr_len) {
			oldstr_len = nchars + 3;
			old_string = (char *)ERealloc(old_string, oldstr_len);
			if (old_string == 0) return;
		}
	
	    charcopy(old_string, oldstr_len, string, nchars);
	
		// Blank out any EOL characters
	    for (i = 0; i < nchars; i++)
	    {
	        if (old_string[i] == '\n')
	            old_string[i] = ' ';
	        else if (old_string[i] == '\r')
	            old_string[i] = ' ';
	    }
	
	    SetConsoleCursorPosition(console_output, ch);
	    WriteConsole(console_output, old_string, nchars, &i, NULL);
	    SetConsoleCursorPosition(console_output, ch);

    } else {

	    i = 0;
// 	    if( line_buffer_size < console_info.dwMaximumWindowSize.X || line_buffer == NULL){
	    if( line_buffer_size < console_info.dwSize.X || line_buffer == NULL){
	        if (line_buffer != 0) {
	            EFree((char *)line_buffer);
	        }
//	        line_buffer_size = console_info.dwMaximumWindowSize.X;
	        line_buffer_size = console_info.dwSize.X;
	        line_buffer = (CHAR_INFO*) EMalloc( sizeof( CHAR_INFO ) * line_buffer_size );
	    }
	
	    while (*string != '\0' && i < line_buffer_size) {
		    // Avoid outputing newline characters.
		    char ch;
		    
		    ch = *string;
		    if ( ch != '\n' && ch != '\r')
	        	line_buffer[i].Char.AsciiChar = ch;
	        else
	        	line_buffer[i].Char.AsciiChar = ' ';
	        line_buffer[i].Attributes = console_info.wAttributes;
	        string++;
	        i++;
	    }
	    WriteConsoleOutput(console_output,
	                       line_buffer, // was:  &line_buffer ?
	                       buff_size,
	                       buff_start,
	                       &screen_loc);
    }

    console_info.dwCursorPosition.X += nchars; // what if becomes 80? (i.e 1 too big)
    SetConsoleCursorPosition(console_output, console_info.dwCursorPosition);
    //screen_col += nchars;
}
#endif

void buffer_screen()
/* start buffering the screen output on each line */
{
    must_flush = FALSE;
}

void flush_screen()
/* flush any left over characters */
{
    must_flush = TRUE;
    expand_tabs("");
}


#ifdef EUNIX
void update_screen_string(char *s)
// record that a string of characters was written to the screen
{
    int i, col, line;
#define USS_len (60)
    char buff[USS_len];

    i = 0;
    line = screen_line - 1;
    col = screen_col - 1;
    if (line < 0 || line >= line_max) {
        snprintf(buff, USS_len, "line corrupted (%d), s is %s, col is %d",
				 line, s, col);
		buff[USS_len - 1] = 0; // ensure NULL
        debug_msg(buff);
    }
    // we shouldn't get any \n's or \r's, but just in case:
    while (s[i] != 0 && s[i] != '\n' && s[i] != '\r' && col < col_max) {
        screen_image[line][col].ascii = s[i];
        screen_image[line][col].fg_color = current_fg_color;
        screen_image[line][col].bg_color = current_bg_color;
        col += 1;
        if (col < 0 || col > col_max) {
			snprintf(buff, USS_len, "col corrupted (%d)", col);
			buff[USS_len - 1] = 0; // ensure NULL
            debug_msg(buff);
        }
        i += 1;
    }
}
#endif

static void expand_tabs(char *raw_string)
/* Expand tabs and truncate long lines.
 * Still needed to avoid a WATCOM bug that misprints lines that
 * are too long for the screen width. Debug/Trace screen still uses
 * tab expansion feature. Flush feature is used for better performance.
 * Note: screen_col is the column based on what we have actually written
 * to the screen so far, not what we have buffered.
 */
{
    int c, i, nblanks, true_screen_col;
	static int screen_width;
	int colpos;

    if (expanded_string == 0) {
	    screen_width = 200;
	    expanded_string = (char *)EMalloc(screen_width + 3); // Extra 3 for \n\r\0
	    expanded_ptr = expanded_string;
	    expanded_end = expanded_string + screen_width;
    }
    
    while ((c = *raw_string++) != 0) {

        if (screen_col + (expanded_ptr - expanded_string) > col_max) {
            // going past right margin
            if (wrap_around) {
                /* what if 0 chars to write? */
                *expanded_ptr = '\0';
#ifdef EWINDOWS
                MyWriteConsole(expanded_string,
                               expanded_ptr - expanded_string);
                end_of_line('\n');
#endif // EWINDOWS
#ifdef EUNIX
                iputs(expanded_string, stdout);
                iflush(stdout);
                update_screen_string(expanded_string);
#endif // EUNIX

                screen_col = 1;
                expanded_ptr = expanded_string; // make it empty
            }
            else {
                if (c != '\n' && c != '\r')
                    continue; // ignore stuff past right margin
            }
        }

        if (c == '\t') {
            true_screen_col = screen_col + expanded_ptr - expanded_string;
            /* expand with blanks */
            nblanks = ((true_screen_col - 1) & ~(TAB_WIDTH - 1)) +
                      (TAB_WIDTH + 1) - true_screen_col;
            if (true_screen_col + nblanks > col_max)
                nblanks = col_max - true_screen_col + 1;
            for (i = 1; i <= nblanks; i++) {
	            if (expanded_ptr >= expanded_end) {
		            colpos = expanded_ptr - expanded_string;
		            screen_width += 100;
		            expanded_string = (char *)ERealloc(expanded_string, screen_width + 3);
		            expanded_ptr = expanded_string + colpos;
		            expanded_end = expanded_string + screen_width;
	            }
                *expanded_ptr++ = ' ';
            }
        }

        else if (c == '\n' || c == '\r') {
#ifdef EWINDOWS
            MyWriteConsole(expanded_string, expanded_ptr - expanded_string);
            end_of_line(c);
#endif

#ifdef EUNIX
            // curses advances to next line if given \r or \n beyond 80
            *expanded_ptr = '\0';
            iputs(expanded_string, stdout);
            iflush(stdout);
            update_screen_string(expanded_string);
            iputc(c, stdout);
            iflush(stdout);
#endif

            screen_col = 1;
            if (c == '\n' && screen_line < config.numtextrows-1)
                screen_line += 1;

            expanded_ptr = expanded_string;
        }

        else if (screen_col <= col_max) {
//             if (expanded_ptr >= expanded_end) {
// 	            colpos = expanded_ptr - expanded_string;
// 	            screen_width += 100;
// 	            expanded_string = (char *)ERealloc(expanded_string, screen_width + 3);
// 	            expanded_ptr = expanded_string + colpos;
// 	            expanded_end = expanded_string + screen_width;
//             }
	        
            // normal characters
            *expanded_ptr++ = c;
        }
    } // end while

    /* left over characters - flush? */
    if (expanded_ptr != expanded_string && must_flush) {

        *expanded_ptr = '\0';
#ifdef EWINDOWS
        MyWriteConsole(expanded_string, expanded_ptr - expanded_string);
#endif
#ifdef EUNIX
        iputs(expanded_string, stdout);
        iflush(stdout);
        update_screen_string(expanded_string);
#endif
        screen_col += expanded_ptr - expanded_string;
        expanded_ptr = expanded_string;
    }
}


void screen_output(IFILE f, char *out_string)
/* All output from the compiler, interpreter or user program
   comes here (except for some EPuts() output). It is then directed to the
   appropriate window or passed to a file. */
/* f is output file, or NULL if debug screen, or DOING_SPRINTF */
/* out_string is null-terminated string of characters to write out */
{
    int len, collect_len;

    if ((intptr_t)f == DOING_SPRINTF) {
        /* save characters as a C string in memory */
        len = strlen(out_string);
        if (collect == NULL) {
			collect_free = 80;
			collect_len = len + collect_free;
            collect = EMalloc(collect_len + 1);
			copy_string(collect, out_string, collect_len);
            collect_next = len;
        }
        else {
            if (len > collect_free) {
				collect_free = len + 200;
				collect_len = collect_next + collect_free;
                collect = ERealloc(collect, collect_len + 1);
			} else {
				collect_len = len;
			}

			copy_string(collect+collect_next, out_string, len+1);
            collect_free -= len;
            collect_next += len;
        }
    }

    else if (f == NULL) {
        /* send to debug screen */
        expand_tabs(out_string);
    }

    else {
#ifdef EUNIX
        if ((f == stdout && out_to_screen) ||
            (f == stderr && err_to_screen && (!low_on_space || have_console))) {
            if (current_screen != MAIN_SCREEN)
                MainScreen();
            expand_tabs(out_string);
            return;
        }
#else
        if (f == stdout || f == stderr) {
#ifdef EWINDOWS
            show_console();  // needed to initialize out_to_screen in WIN32
#endif
            if (current_screen != MAIN_SCREEN)
                MainScreen();
            if (out_to_screen || ((f == stderr) && err_to_screen)) {  //stderr always goes to screen if stdout is not being redirected
                expand_tabs(out_string);
                return;
            }
        }
#endif
        else {
            /* file/device output - should flush some devices ? */
            if (current_screen != MAIN_SCREEN && con_was_opened)
                MainScreen();
        }

        iputs(out_string, f);
        if ((f == stdout || f == stderr) &&	EuConsole) {
		// for rxvt
		iflush(f);
        }
    }
}

void screen_output_va(IFILE f, char *out_string, va_list ap)
{
	int nsize;
	char * buf;

	// figure out how long the string will be
	nsize = vsnprintf(0, 0, out_string, ap);

	buf = EMalloc(nsize+1); // add one for the trailing '\0'
	vsnprintf(buf, nsize+1, out_string, ap);

	screen_output(f, buf);
	EFree(buf);
}

void screen_output_vararg(IFILE f, char *out_string, ...)
{
	va_list ap;

	va_start(ap, out_string);
	screen_output_va(f, out_string, ap);
	va_end(ap);
}

#ifdef EWINDOWS
void EClearLines(int first_line, int last_line, int len, WORD attributes)
{
    int i, n;
    COORD origin;

    origin.X = 0;
    for (i = first_line; i <= last_line; i++) {
         origin.Y = i - 1;
         FillConsoleOutputCharacter(console_output, ' ', len, origin, (LPDWORD)&n);
         FillConsoleOutputAttribute(console_output, attributes, len, origin, (LPDWORD)&n);
    }
}
#endif

void ClearScreen()
{
#ifdef EWINDOWS
    CONSOLE_SCREEN_BUFFER_INFO info;

    show_console();
    GetConsoleScreenBufferInfo(console_output, &info);
    EClearLines(1, info.dwSize.Y, info.dwSize.X, info.wAttributes);
    SetPosition(1,1);
#endif

#ifdef EUNIX
    // ANSI code
    SetTColor(current_fg_color);
    SetBColor(current_bg_color);
    iputs("\E[2J", stdout);  // clear screen
    iflush(stdout);
    SetPosition(1,1);
    Set_Image(screen_image, ' ', current_fg_color, current_bg_color);
#endif

    screen_line = 1;
    screen_col = 1;
}

void SetPosition(int line, int col)
{
#ifdef EUNIX
#define SP_buflen (20)
    char buff[SP_buflen];
#endif

#ifdef EUNIX
    snprintf(buff, SP_buflen, "\E[%d;%dH", line, col);
    iputs(buff, stdout);
    iflush(stdout);
#endif

#ifdef EWINDOWS
    COORD pos;

    pos.X = col-1;
    pos.Y = line-1;
    show_console();
    SetConsoleCursorPosition(console_output, pos);
#endif
    screen_col = col;
    screen_line = line;
}

#ifdef EWINDOWS

void ReadInto(WORD * buf, LPTSTR str, int size, unsigned long * n, unsigned long * m, WORD * saved, struct rccoord * pos)
{
    COORD ch;

    CONSOLE_SCREEN_BUFFER_INFO console_info;
    GetConsoleScreenBufferInfo(console_output, &console_info);

    *saved = console_info.wAttributes;
    *pos = GetTextPositionP();

    ch.X = 0;
    ch.Y = 0;
    ReadConsoleOutputCharacter(console_output, str, size, ch, n);
    ReadConsoleOutputAttribute(console_output, buf, size, ch, m);
}

void WriteOutFrom(WORD * buf, LPTSTR str, unsigned long n, unsigned long m, WORD * saved, struct rccoord * pos)
{
    unsigned long size1, size2;
    COORD ch;
    ch.X = 0;
    ch.Y = 0;
    WriteConsoleOutputCharacter(console_output, str, n, ch, &size1);
    WriteConsoleOutputAttribute(console_output, buf, m, ch, &size2);

    if (*saved != (WORD)-1)
    {
        SetConsoleTextAttribute(console_output, *saved);
        *saved = (WORD)-1;
    }
    SetPosition(pos->row, pos->col);
}

TCHAR console_save_str[65536];
unsigned long console_save_str_n = 0;
WORD console_save_buf[65536];
unsigned long console_save_buf_n = 0;
WORD console_save_saved = (WORD)-1;
struct rccoord console_save_pos;

TCHAR console_trace_str[65536];
unsigned long console_trace_str_n = 0;
WORD console_trace_buf[65536];
unsigned long console_trace_buf_n = 0;
WORD console_trace_saved = (WORD)-1;
struct rccoord console_trace_pos;

void SaveNormal()
{
    unsigned long size = 65536;
    if (EuConsole){
        ReadInto(console_save_buf, console_save_str, size, &console_save_buf_n, &console_save_str_n, &console_save_saved, &console_save_pos);
    } else {
        console_save = console_output;
    }
}

void SaveTrace()
{
    int size = 65536;
    if (EuConsole){
        ReadInto(console_trace_buf, console_trace_str, size, &console_save_buf_n, &console_save_str_n, &console_trace_saved, &console_trace_pos);
    } else {
        SetConsoleActiveScreenBuffer(console_var_display);
        console_output = console_var_display;
    }
}

void RestoreTrace()
{
    if (EuConsole){
        WriteOutFrom(console_trace_buf, console_trace_str, console_save_buf_n, console_save_str_n, &console_trace_saved, &console_trace_pos);
    } else {
        SetConsoleActiveScreenBuffer(console_trace);
        console_output = console_trace;
    }
}

void RestoreNormal()
{
    if (EuConsole){
        WriteOutFrom(console_save_buf, console_save_str, console_save_buf_n, console_save_str_n, &console_save_saved, &console_save_pos);
    } else {
        console_output = console_save;
        SetConsoleActiveScreenBuffer(console_output);
    }
}

void DisableControlCHandling()
{
	// SetConsoleMode(console_input, ENABLE_MOUSE_INPUT);
	SetConsoleMode(console_input, FALSE);
}

#endif
