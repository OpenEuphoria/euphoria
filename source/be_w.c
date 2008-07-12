/*****************************************************************************/
/*      (c) Copyright 2007 Rapid Deployment Software - See License.txt       */
/*****************************************************************************/
/*                                                                           */
/*                       SCREEN OUTPUT HANDLER                               */
/*                                                                           */
/*****************************************************************************/

/******************/
/* Included files */
/******************/
#include <stdio.h>
#include <time.h>
#ifdef EUNIX
#include <sys/stat.h>
#include <unistd.h>
#else
#include <sys\types.h>
#include <sys\stat.h>
#ifdef EDJGPP
#include <pc.h>
#include <sys/farptr.h>
#include <go32.h>
#include <allegro.h>
#else
#if !defined(ELCC) && !defined(EBORLAND)
#include <graph.h>
#endif
#endif
#endif
#include <string.h>
#ifdef EWINDOWS
#include <windows.h>
#endif
#include "alldefs.h"

/******************/
/* Local defines  */
/******************/
#define MAX_SCREEN_WIDTH 200 /* what if resolutions get really high? >1280 */
#define TAB_WIDTH 8    /* power of 2 assumed */

/**********************/
/* Imported variables */
/**********************/
extern int current_screen;
extern int line_max, col_max;
extern int con_was_opened;
extern struct videoconfig config;
extern int low_on_space;
extern unsigned current_bg_color;
extern unsigned current_fg_color;

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
static CHAR_INFO line_buffer[80]; // need more if we support graphics modes
static COORD buff_size;
static COORD buff_start;
static SMALL_RECT screen_loc;
#endif
static char expanded_string[MAX_SCREEN_WIDTH];
static char *expanded_ptr = expanded_string;
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
#ifndef ESIMPLE_MALLOC
char *EMalloc();
char *ERealloc();
#else
#include "alloc.h"
#ifdef EWINDOWS
extern unsigned default_heap;
#endif
#endif
static void expand_tabs();
void SetPosition();
void RTInternal();

/*********************/
/* Defined functions */
/*********************/
struct rccoord GetTextPositionP()
{
#if defined(EDOS) && !defined(EDJGPP)
if (getenv("EUVISTA")!=NULL && atoi(getenv("EUVISTA"))==1)
{
#endif
		struct rccoord p;
		
		p.row = screen_line;
		p.col = screen_col;
		return p;
#if defined(EDOS) && !defined(EDJGPP)
} else {
		return _gettextposition();
} //endif EUVISTA
#endif
}
void OutTextP(const char * c)
{
#if defined(EDOS) && !defined(EDJGPP)
if (getenv("EUVISTA")!=NULL && atoi(getenv("EUVISTA"))==1)
{
#endif
	printf(c);
#if defined(EDOS) && !defined(EDJGPP)
} else {
	_outtext(c);
} //endif EUVISTA
#endif
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

void InitInOut()
/* Set up stdout and stderr. In EWINDOWS some stuff
   is initialized right away. The rest is done later if necesssary on first
   use of the console - see show_console() below. */
{
	struct rccoord position;
	int i, j;
#ifdef EDOS    
	struct stat buf;
	int rc;
#endif
	
#ifdef EWINDOWS  
	position.col = 1;   // should do these 2 properly
	position.row = 1;
	screen_line = position.row;
	screen_col = position.col; 

	buff_size.Y = 1;
	buff_start.X = 0;
	buff_start.Y = 0;
#else
#if defined(EUNIX) || defined(EDJGPP)
	position.col = 1;
	position.row = 1;
	in_from_keyb  = isatty(0);
	out_to_screen = isatty(1);
	err_to_screen = isatty(2);
	screen_line = position.row;
	screen_col = position.col; 
#ifdef EUNIX
	for (i = 0; i < line_max; i++) {
		for (j = 0; j < col_max; j++) {
			screen_image[i][j].ascii = ' ';
			screen_image[i][j].fg_color = 15;
			screen_image[i][j].bg_color = 0;
		}
	}
#endif  

#else
	//DOS
	position = GetTextPositionP();  // causes OpenWatcom 1.4 to go full-screen

	screen_col = position.col;   
	err_to_screen = TRUE;  /* stderr always goes to screen in DOS & WIN32 */
	rc = fstat(1, &buf);
	if (rc == -1 || ((buf.st_atime == 0 || buf.st_mtime == 0)
					 && (buf.st_dev < 0 || buf.st_dev > 9))) 
		out_to_screen = TRUE; /* what about printer ? */
	else
		out_to_screen = FALSE;
	
	rc = fstat(0, &buf);
	if (rc == -1 || ((buf.st_atime == 0 || buf.st_mtime == 0)
					 && (buf.st_dev < 0 || buf.st_dev > 9))) 
		in_from_keyb = TRUE; 
	else
		in_from_keyb = FALSE;
#endif
#endif
}

#if defined(EWINDOWS)
void show_console()
/* set up a console window if not done yet */
{
#ifdef EWINDOWS
	CONSOLE_SCREEN_BUFFER_INFO info;
	CONSOLE_CURSOR_INFO c;
	INPUT_RECORD pbuffer;
	DWORD junk;
	int alloc_ret;
#else
	int f, b;
#endif
	if (!have_console) {
		have_console = TRUE;
#ifdef EUNIX
		initscr();  // maybe use newterm() to avoid screen clearing
		ESCDELAY=0;
		if (has_colors())
			start_color();
		cbreak();  // chars are immediately available without CR
		//noecho();
		//nonl();
		scrollok(stdscr, FALSE);
		intrflush(stdscr, FALSE);
		keypad(stdscr, TRUE);
		for (f = 0; f < config.numcolors; f++) {
			for (b = 0; b < config.numcolors; b++) {
				if (f != 0 || b != 0)
					init_pair((f << 3) + b, f, b);
			}
		}
		NewConfig();
#else   
		alloc_ret = !AllocConsole();
		if (already_had_console < 0) {
			// this effectively tells us if we were started as a GUI app or a CONSOLE app (exw.exe or exwc.exe)
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
	
		console_input = GetStdHandle(STD_INPUT_HANDLE);

		in_from_keyb = PeekConsoleInput(console_input, &pbuffer, 1, &junk);  

		// This stops the mouse cursor from appearing in full screen
		SetConsoleMode(console_input, ENABLE_LINE_INPUT |
								ENABLE_ECHO_INPUT |
								ENABLE_PROCESSED_INPUT);  // no mouse please 
#endif
	}
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
		if (console_info.dwCursorPosition.Y < console_info.dwSize.Y - 1)
			console_info.dwCursorPosition.Y++;
		else {
			// scroll screen up one line
			SMALL_RECT src, clip;
			COORD dest;
			COORD pos;
			CHAR_INFO fill_char;

			if (getenv("EUCONS")!=NULL&&atoi(getenv("EUCONS"))==1){
				pos.X = 0;
				//pos.Y = console_info.dwSize.Y;
				pos.Y = console_info.dwSize.Y-1;
				SetConsoleCursorPosition(console_output, pos);
			}

			src.Left = 0;
			src.Right = console_info.dwSize.X; //79;  // assume 80-char screen for now
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

#if defined(ELCC) || defined(EBORLAND)
int MyReadConsoleChar()
// Read the next character typed by the user on the console
{
	DWORD nread;
	char buff[4];
	
	ReadConsole(console_input, buff, 1, &nread, NULL);
	return buff[0];
}
#endif

static void MyWriteConsole(char *string, int nchars)
// write a string of plain characters to the console and
// update the cursor position
{
	int i;
	static int first = 0;
	CONSOLE_SCREEN_BUFFER_INFO console_info;
	char old_string[82];
	COORD ch;
	
	show_console();
	/* hack - if we are exwc, output something to avoid data appearing on the last line of the console which we later on will not be able to see */
	GetConsoleScreenBufferInfo(console_output, &console_info); // not always necessary?
	if ( (getenv("EUCONS")!=NULL&&atoi(getenv("EUCONS"))==1) &&
	(already_had_console==1) && !first) {
		if (!(console_info.dwCursorPosition.Y < console_info.dwSize.Y - 1))
		{
			//WriteConsole(console_output, "\n", 1, &i, NULL);
			end_of_line('\n');
		}
		first = 1;
	}
 
	buff_size.X = nchars;

	screen_loc.Top = console_info.dwCursorPosition.Y;
	screen_loc.Bottom = screen_loc.Top;
	screen_loc.Left = console_info.dwCursorPosition.X; //screen_col-1;
	screen_loc.Right = 79;

	if (getenv("EUCONS")!=NULL&&atoi(getenv("EUCONS"))==1){

	ch.X = screen_loc.Left;
	ch.Y = screen_loc.Top;
		
	strncpy(old_string, string, 80);
	old_string[81] = '\0';

	for (i = 0; i < nchars; i++)
	{
		if (old_string[i] == '\n')
			old_string[i] = ' ';
		if (old_string[i] == '\r')
			old_string[i] = ' ';
	}

	SetConsoleCursorPosition(console_output, ch);
	WriteConsole(console_output, string, nchars, &i, NULL);
	SetConsoleCursorPosition(console_output, ch);

	} else {

	i = 0;
	while (*string != '\0') {
		line_buffer[i].Char.AsciiChar = *string;
		line_buffer[i].Attributes = console_info.wAttributes;
		string++;
		i++;
	}
	WriteConsoleOutput(console_output,
					   line_buffer, // was:  &line_buffer ?
					   buff_size,
					   buff_start,
					   &screen_loc);
	} // EUCONS

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


#ifdef EDJGPP

#define COLOR_TEXT_MEMORY 0x000B8000
#define MONO_TEXT_MEMORY 0x000B0000

static void graphic_puts(char *text)
// use Allegro to write text in graphics modes
{
	int n, last;
	
	n = strlen(text);
	if (n == 0)
		return;
	last = text[n-1];
	textout(screen, font, text, config.x, config.y, current_fg_color);
	config.x += text_length(font, text);
	if (last == '\n') {
		config.x = 0;
		config.y += text_height(font);
	}
	else if (last == '\r') {
		config.x = 0;
	}
}

static char *DOS_scr_addr(int line, int col)
// calculate address in DOS screen memory for a given line, column
{
	char *screen_memory;
	int page_size;
	
	if (config.mode == 7) 
		screen_memory = (char *)MONO_TEXT_MEMORY;
	else
		screen_memory = (char *)COLOR_TEXT_MEMORY;
	// take out until we support pages:
	// page_size = config.numtextrows * config.numtextcols * 2;
	// page_size = 1024 * ((page_size + 1023) / 1024);
	// screen_memory = screen_memory + get_active_page() * page_size;
	return screen_memory + (line * config.numtextcols + col) * 2;
}

mem_cputs(char *text)
/* write a string directly to screen memory */
{
	char *screen_memory;
	int line, col, c;
	
	if (TEXT_MODE) {
		if (wrap_around) {
			cputs(text);            
		}
		else {
			/* do it this way to avoid the scroll when the 
			   last line is written */
			ScreenGetCursor(&line, &col);
			while ((c = *text++) != 0) {
				if (c == '\n') {
					if (line < config.numtextrows-1)
						line++;
					else {
						ScreenSetCursor(line, col);
						cputs("\n"); // only time we want to scroll
					}
					col = 0;
				}
				else if (c == '\r') {
					col = 0;
				}
				else if (col < config.numtextcols) {
					screen_memory = DOS_scr_addr(line, col);
					_farpokeb(_go32_info_block.selector_for_linear_memory, 
							(unsigned)screen_memory++, 
							c);
					_farpokeb(_go32_info_block.selector_for_linear_memory,
							(unsigned)screen_memory, 
							ScreenAttrib);
					col++;
				}
			}
			ScreenSetCursor(line, col);
		}
	}
	else {
		graphic_puts(text); // graphics modes
	}
}
#endif

#ifdef EUNIX
void update_screen_string(char *s)
// record that a string of characters was written to the screen
{
	int i, col, line;
	char buff[60];

	i = 0;
	line = screen_line - 1;
	col = screen_col - 1;
	if (line < 0 || line >= line_max) {
		sprintf(buff, "line corrupted (%d), s is %s, col is %d", 
		line, s, col); 
		debug_msg(buff); 
	}
	// we shouldn't get any \n's or \r's, but just in case:
	while (s[i] != 0 && s[i] != '\n' && s[i] != '\r' && col < col_max) {
		screen_image[line][col].ascii = s[i];
		screen_image[line][col].fg_color = current_fg_color;
		screen_image[line][col].bg_color = current_bg_color;
		col += 1;
		if (col < 0 || col > col_max) {
			sprintf(buff, "col corrupted (%d)", col); 
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
#else
#ifdef EUNIX
				iputs(expanded_string, stdout);
				iflush(stdout);
				update_screen_string(expanded_string);
#else
//DOS
#ifdef EDJGPP
				mem_cputs(expanded_string); //critical function
#else
				OutTextP(expanded_string); //critical function
#endif
#endif // EUNIX

#endif // EWINDOWS
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

#ifdef EDOS
#ifdef EDJGPP
			if (c == '\n')
				*expanded_ptr++ = '\r';
			*expanded_ptr++ = c;
			*expanded_ptr = '\0';
			mem_cputs(expanded_string);
#else           
			*expanded_ptr++ = c;
			*expanded_ptr = '\0';
			OutTextP(expanded_string);
#endif
#endif
			screen_col = 1;
			if (c == '\n' && screen_line < config.numtextrows-1)
				screen_line += 1;
			
			expanded_ptr = expanded_string;
		}

		else if (screen_col <= col_max) {
			// normal characters
			*expanded_ptr++ = c;
		}
	} // end while

	/* left over characters - flush? */
	if (expanded_ptr != expanded_string && must_flush) {

		*expanded_ptr = '\0'; 
#ifdef EWINDOWS
		MyWriteConsole(expanded_string, expanded_ptr - expanded_string);
#else
#ifdef EUNIX
		iputs(expanded_string, stdout);
		iflush(stdout);
		update_screen_string(expanded_string);
#else
// DOS
#ifdef EDJGPP
		mem_cputs(expanded_string);
#else       
		OutTextP(expanded_string);
#endif
#endif
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
	int len;

	if ((int)f == DOING_SPRINTF) {
		/* save characters as a C string in memory */
		len = strlen(out_string);
		if (collect == NULL) {
			collect_free = 80;
			collect = EMalloc(len+1+collect_free);
			strcpy(collect, out_string);
			collect_next = len;
		}
		else {
			if (len > collect_free) {
				collect_free = len + 200;
				collect = ERealloc(collect, collect_next + 1 + collect_free);  
			}
			strcpy(collect+collect_next, out_string);
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
			if (out_to_screen || f == stderr) {  //stderr always goes to screen
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
	}
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
	iputs("\033[2J", stdout);  // clear screen
	SetPosition(1,1);
#endif

#ifdef EDOS
#ifdef EDJGPP
	if (TEXT_MODE)  
		ScreenClear(); // text modes
	else
		clear_to_color(screen, current_bg_color);
	SetPosition(1,1);
#else
if (getenv("EUVISTA")!=NULL && atoi(getenv("EUVISTA"))==1)
{
	printf("\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n");
} else {
	_clearscreen(_GCLEARSCREEN);
} //endif EUVISTA
#endif
#endif
	screen_line = 1;
	screen_col = 1;
}

void SetPosition(int line, int col)
{
#ifdef EUNIX
	char lbuff[20];
	char cbuff[20];
#endif

#ifdef EDOS
#ifdef EDJGPP
	if (TEXT_MODE)
		ScreenSetCursor(line-1, col-1);
	else {
		config.x = (col-1) * text_length(font, "m");
		config.y = (line-1) * text_height(font);
	}
		
#else   
if (getenv("EUVISTA")!=NULL && atoi(getenv("EUVISTA"))==1)
{
	// no known workaround yet
} else {
	_settextposition(line, col);
} //endif EUVISTA
#endif
#endif

#ifdef EUNIX
	sprintf(lbuff, "%d", line);
	sprintf(cbuff, "%d", col);
	// ANSI code
	iputs("\033[", stdout);
	iputs(lbuff, stdout);
	iputc(';', stdout);
	iputs(cbuff, stdout);
	iputc('H', stdout);
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

