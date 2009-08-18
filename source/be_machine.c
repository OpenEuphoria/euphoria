/*****************************************************************************/
/*      (c) Copyright - See License.txt       */
/*****************************************************************************/
/*                                                                           */
/*                        C INTERFACE / MACHINE FUNCTION                     */
/*                                                                           */
/*****************************************************************************/

/* It's ok to assume that a machine_func/machine_proc call
   is coming from a standard .e file, as far as arguments being sequences
   versus atoms, but don't assume integers will be in 31-bit
   machine integer format just because of the integer type
   check conversion. We must allow the user to call machine_func/
   machine_proc directly, even if he passes integers in f.p. format */

#include <stdio.h>
#include <stdlib.h>

#ifdef EUNIX

#include <strings.h>
#define stricmp strcasecmp

#ifdef EBSD
#define NAME_MAX 255
#else
#include <sys/mman.h>
#endif
#ifdef EGPM
#include <gpm.h>
#endif
#include <dirent.h>
#include <sys/stat.h>
#include <sys/file.h>
#include <dlfcn.h>
#include <sys/times.h>
#include <unistd.h>
#include <termios.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/utsname.h>
#include "global.h"

#ifndef LOCK_SH
#define LOCK_SH  1 /* shared lock */
#define LOCK_EX  2 /* exclusive lock */
#define LOCK_NB  4 /* don't block when locking */
#define LOCK_UN  8 /* unlock */
#endif

#ifdef ESUNOS
#include <fcntl.h>

int emul_flock(fd, cmd)
	int fd, cmd;
{
	struct flock f;

	memset(&f, 0, sizeof(f));
	
	if (cmd & LOCK_UN)
		f.l_type = F_UNLCK;
	if (cmd & LOCK_SH)
		f.l_type = F_RDLCK;
	if (cmd & LOCK_EX)
		f.l_type = F_WRLCK;

	return fcntl(fd, (cmd & LOCK_NB) ? F_SETLK : F_SETLKW, &f);
}

#define flock(f,c) emul_flock(f,c)
#endif // ESUNOS

#else // EUNIX

#include <direct.h>

#ifdef EWATCOM
#  include <graph.h>
#  include <i86.h>
#endif

#include <dos.h>
#endif  // not EUNIX

#include <time.h>
#include <string.h>

#ifdef EXTRA_CHECK
#include <malloc.h>
#endif

#ifdef EWINDOWS
#include <windows.h>
#endif

#ifdef EMINGW
#include <sys/stat.h>
#include <dirent.h>
#endif

#include <signal.h>

#include "alldefs.h"
#include "alloc.h"

#include "version.h"
#include "be_runtime.h"

extern char* get_svn_revision(); /* from rev.c */

/*****************/
/* Local defines */
/*****************/
#define C_UNDERLINE    0x0607 /* normal underline cursor */
/* 30-bit magic #s for old Complete & PD Edition binds */
#define COMPLETE_MAGIC ('1' + ('2'<< 8) + ('3' << 16) + ('O' << 24))

/* timer and profile interrupt handler stuff: */
#define TIMERINTR  8
#define MASTER_FREQUENCY 1193181.667

/**********************/
/* Exported variables */
/**********************/
#ifdef EWINDOWS
HINSTANCE winInstance;
#endif

int is_batch = 0; /* batch mode? Should press enter be displayed? 1=no, 0=yes */
unsigned char TempBuff[TEMP_SIZE]; /* buffer for error messages */

int c_routine_next = 0;       /* index of next available element */
int c_routine_size = 0;       /* number of c_routine structs allocated */
struct arg_info *c_routine = NULL; /* array of c_routine structs */

int allow_break = TRUE;       /* allow control-c/control-break to kill prog */
int control_c_count = 0;      /* number of control-c/control-break since
								 last call */
int *profile_sample = NULL;
volatile int sample_next = 0;

int first_mouse = 1;  /* indicates if mouse function has been set up yet */
int line_max; /* current number of text lines on screen */
int col_max;  /* current number of text columns on screen */
#ifdef EUNIX
int consize_ioctl = 0;	/* 1 if line_max or col_max came from ioctl */
#endif

struct videoconfig config;
struct videoconfigEx configEx;

int screen_lin_addr; /* screen segment */
#ifdef EXTRA_STATS
int mouse_ints = 0;  /* number of unused mouse interrupts */
#endif
char *crash_msg = NULL;  /* user's crash message or NULL */
volatile int our_clock_ticks = 0; /* number of ticks at current rate */
double clock_frequency = 0.0;    /* current clock interrupt rate. 0.0
									means no interrupt handler installed */
double base_time = 0.0;          /* current base for time() */
double clock_adjust = 0.0;       /* adjustment to clock() value */
unsigned current_fg_color = 7;
unsigned current_bg_color = 0;

extern char **Argv;
extern int Argc;

/**********************/
/* Imported variables */
/**********************/
#ifdef EUNIX
extern int pagesize;
extern struct char_cell screen_image[MAX_LINES][MAX_COLS];
#endif
extern double clock_period;
extern symtab_ptr TopLevelSub;
extern int eu_dll_exists;
extern struct exe_routines backpointers;
extern int clocks_per_sec;
extern int clk_tck;
extern char *TempErrName;
extern char *TempWarningName;
extern int display_warnings;
extern int allow_break;
extern int control_c_count;
#ifndef ERUNTIME
extern int sample_size;
extern int Executing;
extern int ProfileOn;
extern int *tpc;
#endif
extern int current_screen;
extern int screen_line, screen_col;
extern int wrap_around;
extern struct file_info user_file[];
extern long seed1, seed2;
extern int rand_was_set;
extern int e_routine_next;
extern symtab_ptr *e_routine;

#ifdef EWINDOWS
extern HANDLE console_output;
extern unsigned default_heap;
#endif

extern int have_console;
extern symtab_ptr cb_routine[];
extern object last_w_file_no;
extern IFILE last_w_file_ptr;

/********************/
/* Local variables */
/*******************/
#ifndef EWINDOWS
static unsigned int long_buff = 0;
static unsigned int short_buff = 0;
#endif

/* In DOS, this mouse data is locked in memory */
static struct locked_data {
	int lock;  /* = 0  semaphore */
	int code;
	int x;
	int y;
} mouse = {0,0,0,0};

char *version_name =
#ifdef EWINDOWS
"WIN32";
#endif

#ifdef EUNIX
"Linux";
#endif

/**********************/
/* Declared Functions */
/**********************/
#ifndef ESIMPLE_MALLOC
char *EMalloc();
#endif
IFILE which_file();
void NewConfig();
s1_ptr NewS1();
char *getcwd();
struct rccoord GetTextPositionP();
void do_exec(int *);
void AfterExecute(void);
void Machine_Handler();
object SetTColor();
object SetBColor();

object compile_pcre();
object exec_pcre();

/* cdecl callback - one size fits all */
LRESULT __cdecl cdecl_call_back();

/* stdcall callbacks for each number of args */
LRESULT CALLBACK call_back0();
LRESULT CALLBACK call_back1(unsigned);
LRESULT CALLBACK call_back2(unsigned, unsigned);
LRESULT CALLBACK call_back3(unsigned, unsigned, unsigned);
LRESULT CALLBACK call_back4(unsigned, unsigned, unsigned, unsigned);
LRESULT CALLBACK call_back5(unsigned, unsigned, unsigned, unsigned, unsigned);
LRESULT CALLBACK call_back6(unsigned, unsigned, unsigned, unsigned, unsigned,
							unsigned);
LRESULT CALLBACK call_back7(unsigned, unsigned, unsigned, unsigned, unsigned,
							unsigned, unsigned);
LRESULT CALLBACK call_back8(unsigned, unsigned, unsigned, unsigned, unsigned,
							unsigned, unsigned, unsigned);
LRESULT CALLBACK call_back9(unsigned, unsigned, unsigned, unsigned, unsigned,
							unsigned, unsigned, unsigned, unsigned);

#ifdef EMINGW
#define setenv MySetEnv
static int MySetEnv(const char *name, const char *value, const int overwrite) {
	int len;
	int real_len;
	char *str;
	
	if (!overwrite && (getenv(name) != NULL))
		return 0;
		
	len = strlen(name) + 1 + strlen(value);
	str = malloc(len + 1); // NOTE: This is deliberately never freed until the application ends.
	if (! str)
		return 0;
	real_len = snprintf(str, len+1, "%s=%s", name, value);
	str[len] = '\0'; // ensure NULL
	len = putenv(str);
	return len;
}
#endif

unsigned long get_pos_int(char *where, object x)
/* return a positive integer value if possible */
{
	if (IS_ATOM_INT(x))
		return INT_VAL(x);
	else if (IS_ATOM(x))
		return (unsigned long)(DBL_PTR(x)->dbl);
	else {
		RTFatal("%s: an integer was expected, not a sequence", where);
	}
}

unsigned IOFF get_pos_off(char *where, object x)
/* return a positive integer value if possible */
{
	if (IS_ATOM_INT(x))
		return (unsigned IOFF) INT_VAL(x);
	else if (IS_ATOM(x))
		return (unsigned IOFF)(DBL_PTR(x)->dbl);
	else {
		RTFatal("%s: an integer was expected, not a sequence", where);
	}
}

IFILE long_iopen(char *name, char *mode)
/* iopen a file. Has support for Windows 95 long filenames */
{
	return iopen(name, mode);
}

int long_open(char *name, int mode)
/* open a file. Has support for Windows 95 long filenames */
{
	return open(name, mode);
}


char *name_ext(char *s)
/* returns a pointer to the 8.3 file name & extension part of a path */
/* Note - forward slash is also legal on DOS/Windows - fix? */
{
	int i;

	i = strlen(s);
	while (i >= 0 && s[i] != '\\' && s[i] != '/') // check for ':' too? ok as used so far
		i--;
	if (i >= 0)
		return s + i + 1;
	else
		return s;
}

extern long get_int(object x)
/* return an integer value if possible */
/* Note: uses (long) conversion of doubles
   - NOT CORRECT for 32-bit addresses */
{
	if (IS_ATOM_INT(x))
		return x;
	else if (IS_ATOM(x))
		return (long)(DBL_PTR(x)->dbl);
	else {
		RTFatal("an integer was expected, not a sequence");
	}
}

/* Note: side effects could happen from double eval of x */
#define Get_Int(x) (IS_ATOM_INT(x) ? INT_VAL(x) : get_int(x))

#ifdef EUNIX
struct termios savetty; // initial tty state for STDIN
struct termios newtty;  // current tty state for STDIN

void echo_wait()
// sets tty to wait for input and echo keystrokes
{
	newtty.c_lflag |= ICANON;
	newtty.c_lflag |= ECHO;   // turns on echo
	newtty.c_cc[VMIN] = 1;    // wait for input
	tcsetattr(STDIN_FILENO, TCSANOW, &newtty);
}

void noecho(int wait)
// sets tty to not echo keystrokes, and either wait for input or not
{
	newtty.c_lflag &= ~ICANON;
	newtty.c_lflag &= ~ECHO;   // turns off echo
	newtty.c_cc[VMIN] = wait;  // wait for input, if wait = 1
	tcsetattr(STDIN_FILENO, TCSANOW, &newtty);
}
#endif

void InitGraphics()
/* initialize for graphics */
{
#ifdef EUNIX
	// save initial tty state
	tcgetattr(STDIN_FILENO, &savetty);

	// set up tty for no echo
	newtty = savetty;
	newtty.c_cc[VTIME] = 0;
	//noecho(0); // necessary?
#endif

	NewConfig(FALSE);

}

void EndGraphics()
{
#ifdef EWINDOWS
	SetConsoleMode(console_output,
					ENABLE_PROCESSED_OUTPUT | ENABLE_WRAP_AT_EOL_OUTPUT); // back to normal
#endif
#ifdef EUNIX
	tcsetattr(STDIN_FILENO, TCSANOW, &savetty);
#endif
}

void not_supported(char *feature)
/* Report that a feature isn't supported on this platform */
{
	RTFatal("%s is not supported in Euphoria for %s", feature, version_name);
}


#define MODE_19_BASE ((unsigned)0xA0000)
#define MODE_19_WIDTH 320
#define MODE_19_HEIGHT 200


void RestoreConfig()
/* put graphics mode etc back the way it is supposed to be
   e.g. after system call */
{
}

void NewConfig(int raise_console)
/* note new video configuration - this doesn't work
   after a system call that changes modes - could be out of sync */
{
#ifdef EWINDOWS
	CONSOLE_SCREEN_BUFFER_INFO info;
	if (raise_console) {
		// properly initializes the console when running in eui mode
		show_console();

		GetConsoleScreenBufferInfo(console_output, &info);
 		configEx.screenrows = info.srWindow.Bottom - info.srWindow.Top + 1;
 		configEx.screencols = info.srWindow.Right - info.srWindow.Left + 1;
		line_max = info.dwSize.Y;
		col_max = info.dwSize.X;
	} else {
		// don't care on startup - this will be initialized later.
		line_max = 25;
		col_max = 80;
		configEx.screenrows = 25;
		configEx.screencols = 80;
	}

	config.numtextrows = line_max;
	config.numtextcols = col_max;

	config.mode = 3;
	config.monitor = _COLOR;
	config.numcolors = 32;
	config.numxpixels = 0;
	config.numypixels = 0;
	config.numvideopages = 1;
#endif

#ifdef EUNIX
	char *env_lines;
	char *env_cols;
	int x;
	struct winsize ws;

	config.mode = 3;
	config.numxpixels = 0;
	config.numypixels = 0;
	config.numvideopages = 1;
	line_max = 0;
	col_max = 0;
	consize_ioctl = 0;

	env_lines = getenv("LINES");
	if (env_lines != NULL) {
		x = atoi(env_lines);
		if (x > 0 && x < 9999) {
			// value looks reasonable
			line_max = x;
		}
	}
	env_cols = getenv("COLUMNS");
	if (env_cols != NULL) {
		x = atoi(env_cols);
		if (x > 0 && x < 99999) {
			// value looks reasonable
			col_max = x;
		}
	}

	if ( ((col_max == 0) || (line_max == 0)) && !ioctl(STDIN_FILENO, TIOCGWINSZ, &ws))  {
		line_max = ws.ws_row;
		col_max = ws.ws_col;
		consize_ioctl = 1;
	}

	if (line_max < 5 || line_max > 9999 ||
		col_max < 10 || col_max > 99999) {
		// something is wrong - use default pessimistic values
		line_max = 24;  // default value
		col_max = 80;   // default value
		consize_ioctl = 0;
	}

	if (line_max > MAX_LINES)
		line_max = MAX_LINES;
	if (col_max > MAX_COLS)
		col_max = MAX_COLS;

	config.monitor = _COLOR;
	config.numcolors = 16;
	config.numtextrows = line_max;
	config.numtextcols = col_max;
	configEx.screenrows = line_max;
	configEx.screencols = col_max;
#endif

	screen_col = 1;
	if (config.monitor == _MONO ||
		config.monitor == _ANALOGMONO ||
		config.mode == 7)
		screen_lin_addr = (0xb000 << 4);
	else
		screen_lin_addr = (0xb800 << 4);
}

static object Graphics_Mode(object x)
/* x is the graphics mode */
{
#if defined(EWINDOWS)
	NewConfig(TRUE);
#endif
	return ATOM_0;
}

static object Video_config()
/* video_config built-in */
{
	object_ptr obj_ptr;
	s1_ptr result;
#if defined(EWINDOWS)
	NewConfig(TRUE); // Windows size might have changed since last call.
#endif
	result = NewS1((long)10);
	obj_ptr = result->base;

	obj_ptr[1] = (config.monitor != _MONO) &&
				 (config.monitor != _ANALOGMONO);
	obj_ptr[2] = config.mode;
	obj_ptr[3] = config.numtextrows;
	obj_ptr[4] = config.numtextcols;
	obj_ptr[5] = config.numxpixels;
	obj_ptr[6] = config.numypixels;
	obj_ptr[7] = config.numcolors;
	obj_ptr[8] = config.numvideopages;
	obj_ptr[9] = configEx.screenrows;
	obj_ptr[10] = configEx.screencols;
	return MAKE_SEQ(result);
}

static object Cursor(object x)
/* set style of cursor */
{
	short style;
#ifdef EWINDOWS
	CONSOLE_CURSOR_INFO c;
#endif
	style = get_int(x);
#ifdef EWINDOWS
	c.dwSize = (style == 0x0607) ? 12 :
			   (style == 0x0507) ? 25 :
			   (style == 0x0407) ? 50 :
								  100;
	c.bVisible = (style != 0x02000);
	SetConsoleCursorInfo(console_output, &c);
#endif
#ifdef EUNIX
	// leaveok(stdscr, style != 0x02000); doesn't work very well
#endif
	return ATOM_1;
}

static object TextRows(object x)
/* text_rows built-in */
{
	int rows, new_rows;

#ifdef EWINDOWS
	COORD newsize;

	new_rows = get_int(x);
	NewConfig(TRUE);
	newsize.X = config.numtextcols;
	newsize.Y = new_rows;
	SetConsoleScreenBufferSize(console_output, newsize);
	NewConfig(TRUE);
#endif
	NewConfig(TRUE);
	return MAKE_INT(line_max);
}

object Wrap(object x)
/* set line wrap mode */
{
	wrap_around = get_int(x);
#if defined(EWINDOWS)
	show_console();
#endif
	return ATOM_1;
}

#ifdef EUNIX
static char *bl20 = "                    ";

void blank_lines(int line, int n)
// Write n blank lines at the specified line (origin 0).
// The cursor is moved.
{
	int b;
	int j;

	for (j = 1; j <= n; j++) {
		b = config.numtextcols;
		SetPosition(++line, 1);
		while (b >= 20) {
			iputs(bl20, stdout); // 20 blanks
			update_screen_string(bl20);
			screen_col += 20;
			b -= 20;
		}
		while (b >= 1) {
			iputs(" ", stdout); // 1 blank
			update_screen_string(" ");
			screen_col += 1;
			b -= 1;
		}
	}
	if (n)
	  iflush(stdout);
}
#endif

void do_scroll(int top, int bottom, int amount)
// scroll the screen from top line to bottom line by amount
// amount is positive => text moves up
{
	short r1, c1, r2, c2;
	int i, j;
	int fg, bg, b, t, prev_t, prev_b;
#ifdef EWINDOWS
	SMALL_RECT src, clip;
	COORD dest;
	CHAR_INFO fill_char;
	CONSOLE_SCREEN_BUFFER_INFO info;

	show_console();
	GetConsoleScreenBufferInfo(console_output, &info);
	src.Left = 0;
//	src.Right = info.dwMaximumWindowSize.X - 1;
	src.Right = info.dwSize.X - 1;
	src.Top = top - 1;
	src.Bottom = bottom - 1;
	clip = src;
	dest.X = 0;
	dest.Y = src.Top - amount; // for now
//	GetConsoleScreenBufferInfo(console_output, &info);
	fill_char.Char.AsciiChar = ' ';
	fill_char.Attributes = info.wAttributes;
	if (abs(amount) > abs(bottom - top)) {
//		EClearLines(top, bottom, info.dwMaximumWindowSize.X - 1, fill_char.Attributes);
		EClearLines(top, bottom, info.dwSize.X - 1, fill_char.Attributes);
	}
	else {
		ScrollConsoleScreenBuffer(console_output,
							  &src,
							  &clip,
							  dest,
							  &fill_char);
	}
#endif

#ifdef EUNIX
	// save the current position
	r1 = screen_line;
	c1 = screen_col;
	fg = current_fg_color;
	bg = current_bg_color;
	prev_t = -1;
	prev_b = -1;
	if (abs(amount) > abs(bottom - top)) {
		// clear the window
		blank_lines(top-1, bottom-top+1);
	}
	else if (amount > 0) {
		// copy some lines up
		for (i = top; i <= bottom - amount; i++) {
			SetPosition(i, 1);
			for (j = 0; j < col_max; j++) {
				screen_image[i-1][j] = screen_image[i+amount-1][j];
				t = screen_image[i+amount-1][j].fg_color;
				b = screen_image[i+amount-1][j].bg_color;
				if (t != prev_t) {
					SetTColor(t);
					prev_t = t;
				}
				if (b != prev_b) {
					SetBColor(b);
					prev_b = b;
				}
				iputc(screen_image[i+amount-1][j].ascii, stdout);
			}
			//screen_line++;
		}
		// put blank lines at bottom
		SetBColor(bg);
		blank_lines(bottom-amount, amount);
		iflush(stdout);
	}
	else if (amount < 0) {
		// copy some lines down
		for (i = bottom; i >= top-amount; i--) {
			SetPosition(i, 1);
			for (j = 0; j < col_max; j++) {
				screen_image[i-1][j] = screen_image[i+amount-1][j];
				t = screen_image[i+amount-1][j].fg_color;
				b = screen_image[i+amount-1][j].bg_color;
				if (t != prev_t) {
					SetTColor(t);
					prev_t = t;
				}
				if (b != prev_b) {
					SetBColor(b);
					prev_b = b;
				}
				iputc(screen_image[i+amount-1][j].ascii, stdout);
			}
			//screen_line--;
		}
		// put blanks lines at top
		SetBColor(bg);
		blank_lines(top-1, -amount);
		iflush(stdout);
	}
	// restore the current position
	SetPosition(r1, c1);
	SetTColor(fg); // bg will be restored already
	current_fg_color = fg;
	current_bg_color = bg;
#endif

}

static object Scroll(object x)
{
	int amount, top, bottom;
	int i;

	x = (object)SEQ_PTR(x);
	amount = get_int(*(((s1_ptr)x)->base+1));
	top =    get_int(*(((s1_ptr)x)->base+2));
	// top is higher on the screen, i.e. with a lower line number
	bottom = get_int(*(((s1_ptr)x)->base+3));
	do_scroll(top, bottom, amount);
	return ATOM_1;
}

object SetTColor(object x)
/* SET TEXT COLOR */
{
	short c;
	char digits[20];
#ifdef EWINDOWS
	WORD attribute;
	CONSOLE_SCREEN_BUFFER_INFO con_info;
#endif

	c = get_int(x);
#if defined(EWINDOWS)
	show_console();
#endif
#ifdef EWINDOWS
	GetConsoleScreenBufferInfo(console_output, &con_info);
	attribute = (c & 0x0f) | (con_info.wAttributes & 0xf0);
	SetConsoleTextAttribute(console_output, attribute);
#endif
#ifdef EUNIX
	current_fg_color = c & 15;
	if (current_fg_color > 7)
		iputs("\033[1m", stdout); // BOLD ON (BRIGHT)
	else
		iputs("\033[22m", stdout); // BOLD OFF
	iputs("\033[3", stdout);
	iputc('0' + (current_fg_color & 7), stdout);
	iputc('m', stdout);
#endif

	return ATOM_1;
}

#if defined(EMINGW)
// temporary
static long colors[16];
#endif

#if !defined(EUNIX) && !defined(EMINGW)
static long colors[16] = {
	_BLACK, _BLUE, _GREEN, _CYAN,
	_RED, _MAGENTA, _BROWN, _WHITE,
	_GRAY, _LIGHTBLUE, _LIGHTGREEN, _LIGHTCYAN,
	_LIGHTRED, _LIGHTMAGENTA, _YELLOW, _BRIGHTWHITE
};
#endif

object SetBColor(object x)
/* SET BACKGROUND COLOR */
{
	int c;
#ifdef EWINDOWS
	WORD attribute;
	CONSOLE_SCREEN_BUFFER_INFO con_info;
#endif

	c = get_int(x);
#if defined(EWINDOWS)
	show_console();
#endif
#ifdef EWINDOWS
	GetConsoleScreenBufferInfo(console_output, &con_info);
	attribute = ((c & 0x0f) << 4) | (con_info.wAttributes & 0x0f);
	SetConsoleTextAttribute(console_output, attribute);
#endif
#ifdef EUNIX
	current_bg_color = c & 7;
	// ANSI code
	iputs("\033[4", stdout);
	iputc('0' + current_bg_color, stdout);
	iputc('m', stdout);
#endif

	return ATOM_1;
}


static object MousePointer(object x)
{
	return ATOM_1;
}
static object MouseEvents(int interrupts)
{
	return ATOM_1;
}
int mouse_installed()
{
	return 0;
}
static void show_mouse_cursor(int x)
{
}
static void lock_mouse_pages()
{
}

#ifdef EUNIX
#ifdef EGPM  // if GPM package is desired, - not available on FreeBSD
/* Text Mode Mouse in Linux
 Codes:
	buttons:
		left = 4
		middle = 2
		right = 1

	clicks:
		0: single click
		1: double click
		2: triple click

	vc always 1?

	type:
		move = 1
		drag = 2   146?
		down = 4   20?
		up = 8     152?

	xterm:
		left-down: 409 32 x y
		middle-down: 409 33 x y
		right-down: 409 34 x y
		*any* button-up: 409 35 x y
		(can I report all 3 buttons went up?)

		no move events are reported

	x and y are origin (33,33) at top left of window
*/

int Mouse_Handler(Gpm_Event *event, void *clientdata) {
// handles mouse events
	mouse.lock = 1;
	mouse.code = event->buttons; //FOR NOW
	if (mouse.code == 32)
		mouse.code = 4;
	else if (mouse.code == 33)
		mouse.code = 2;
	else if (mouse.code == 34)
		mouse.code = 1;
	mouse.x = event->x;
	mouse.y = event->y;
	return -1;
}

static Gpm_Connect conn;
extern char key_buff[];
extern int key_write;

void save_key(int key)
// store a key in the buffer
{
	key_buff[key_write++] = key;
	if (key_write >= KEYBUFF_SIZE)
		key_write = 0;
}

int EscapeKey()
// process Escape sequences (these only occur in xterm)
// some keys are pushed back into key_buff
{
	int key;

	nodelay(stdscr, TRUE); // don't get stuck waiting for next key
	key = Gpm_Getch();
	if (key == 91) {
		key = Gpm_Getch();
		if (key == 49) {
			key = Gpm_Getch();
			if (key >= 49 && key <= 52) {
				Gpm_Getch();    // 126
				key = 265+key-49; // F1..F4
			}
			else {
				save_key(91);
				save_key(49);
				save_key(key);
				key = 27;
			}
		}
		else {
			save_key(91);
			save_key(49);
			key = 27;
		}
	}
	else {
		save_key(key);
		key = 27;
	}
	return key;
}


static object GetMouse()
// Return the next mouse event, or -1
// Linux version using GPM
{
	object final_result;
	object_ptr obj_ptr;
	s1_ptr result;
	int key, action;

	if (first_mouse) {
		/* initialize GPM */
		first_mouse = FALSE;
		conn.eventMask = 0xFFFF; // unsigned short
		conn.defaultMask = 0;
		conn.minMod = 0;
		conn.maxMod = ~0;
		gpm_visiblepointer = 1;
		//gpm_zerobased = 1;
		gpm_handler = Mouse_Handler;
		gpm_data = NULL;
		Gpm_Open(&conn, 0);
		final_result = ATOM_M1;
	}
	else if (mouse.lock) {
		/* we picked up a mouse event via Mouse_Handler() */
		mouse.lock = 0;
		result = NewS1((long)3);
		obj_ptr = result->base;

		obj_ptr[1] = MAKE_INT(mouse.code);
		obj_ptr[2] = MAKE_INT((mouse.y > 32) ? mouse.x-32 : mouse.x);
		obj_ptr[3] = MAKE_INT((mouse.y > 32) ? mouse.y-32 : mouse.y);

#ifdef EXTRA_STATS
		mouse_ints--;
#endif
		mouse.code = 0;
		final_result = MAKE_SEQ(result);
	}
	else {
		/* check for a mouse event (or a key) */
		nodelay(stdscr, TRUE);
		noecho();
		key = Gpm_Getch();
		if (key == -1) {
			final_result = ATOM_M1;
		}
		else if (key == 409) {
			result = NewS1((long)3);
			obj_ptr = result->base;
			action = Gpm_Getch();
			if (action == 32)
				action = 4;
			else if (action == 33)
				action = 2;
			else if (action == 34)
				action = 1;
			obj_ptr[1] = MAKE_INT(action);
			obj_ptr[2] = MAKE_INT(Gpm_Getch()-32);
			obj_ptr[3] = MAKE_INT(Gpm_Getch()-32);
#ifdef EXTRA_STATS
			mouse_ints--;
#endif
			mouse.code = 0;
			final_result = MAKE_SEQ(result);
		}
		else if (key == 27) {
			key = EscapeKey();
			final_result = ATOM_M1;
		}
		else {
			/* we picked up a character */
			save_key(key);
			final_result = ATOM_M1;
		}
		echo();
		nodelay(stdscr, FALSE); // go back to normal setup
	}
	return final_result;
}
#endif // EGPM

#else
// not LINUX
static object GetMouse()
/* GET_MOUSE event built-in WIN32 */
{
	object_ptr obj_ptr;
	s1_ptr result;

	if (first_mouse) {
		lock_mouse_pages();
		first_mouse = 0;
		if (mouse_installed()) {
			show_mouse_cursor(0x1);
			MouseEvents(MAKE_INT(0x0000FFFF));
		}
	}
	if (mouse.lock) {
		/* there's something in the queue */

		result = NewS1((long)3);
		obj_ptr = result->base;

		mouse.lock = 2; /* critical section */
		obj_ptr[1] = mouse.code;
		obj_ptr[2] = mouse.x;
		obj_ptr[3] = mouse.y;
		mouse.lock = 0;

#ifdef EXTRA_STATS
		mouse_ints--;
#endif
		return MAKE_SEQ(result);
	}
	else
		return ATOM_M1;
}
#endif

static object user_allocate(object x)
/* x is number of bytes to allocate */
{
	int nbytes;
	char *addr;
#ifdef EUNIX
	unsigned first, last, gp1;
#endif

	nbytes = get_int(x);
	addr = malloc(nbytes);
#ifdef EUNIX
#ifndef EBSD
	// make it executable
	gp1 = pagesize-1;
	first = (unsigned)addr & (~gp1); // start of page
	last = (unsigned)addr+nbytes-1; // last address
	last = last | gp1; // end of page
	mprotect((void *)first, last - first + 1,
			 PROT_READ+PROT_WRITE+PROT_EXEC);
#endif
#endif

	// we don't allow -ve addresses, so can't use -ve Euphoria ints
	if ((unsigned long)addr <= (unsigned)MAXINT_VAL)
		return (unsigned long)addr;
	else
		return NewDouble((double)(unsigned long)addr);
}

static struct ss {
	unsigned short int segment;
	unsigned short int selector;
} *ss_list = NULL;
static int ss_next = 0;
static int ss_size;

static void save_selector(unsigned short segment, unsigned short selector)
/* save segment and selector combination for lookup later */
{
	int i;

	if (ss_list == NULL) {
		ss_size = 10;
		ss_list = (struct ss *)EMalloc(ss_size * sizeof(struct ss));
	}
	else if (ss_next >= ss_size) {
		ss_size = ss_size * 2;
		ss_list = (struct ss *)ERealloc((char *)ss_list,
											 ss_size * sizeof(struct ss));
	}
	for (i = 0; i < ss_next; i++) {
		if (ss_list[i].segment == 0) {
			/* fill empty slot */
			ss_list[i].segment = segment;
			ss_list[i].selector = selector;
			return;
		}
	}
	ss_list[ss_next].segment = segment;
	ss_list[ss_next].selector = selector;
	ss_next++;
}

static int get_selector(int segment)
/* find the selector to free, given the segment */
{
	int i;

	for (i = 0; i < ss_next; i++) {
		if (ss_list[i].segment == segment) {
			ss_list[i].segment = 0;
			return (unsigned int)ss_list[i].selector;
		}
	}
	return -1;
}

static object Where(object x)
/* x is the file number. return current byte position */
{
	int file_no;
	IOFF result;
	IFILE f;

	file_no = CheckFileNumber(x);
	if (user_file[file_no].mode == EF_CLOSED)
		RTFatal("file must be open for where()");
	f = user_file[file_no].fptr;
#ifdef EWATCOM
	if (user_file[file_no].mode & EF_APPEND)
		iflush(f);  // This fixes a bug in Watcom 10.6 that is fixed in 11.0
#endif
	result = itell(f);
	if (result == (IOFF)-1)
	{
		RTFatal("where() failed on this file");
	}
	if (result > (IOFF)MAXINT || result < (IOFF)MININT)
		result = NewDouble((double)result);  // maximum 2 billion
#if defined(ELINUX) || defined(EWATCOM)
	else
		result = iitell(f); // for better accuracy
#endif
	return result;
}

static object Seek(object x)
/* x is {file number, new position} */
{
	int file_no;
	IOFF pos, result;
	IFILE f;
	object x1, x2;

	x = (object)SEQ_PTR(x);
	x1 = *(((s1_ptr)x)->base+1);
	x2 = *(((s1_ptr)x)->base+2);
	file_no = CheckFileNumber(x1);
	if (user_file[file_no].mode == EF_CLOSED)
		RTFatal("file must be open for seek()");
	f = user_file[file_no].fptr;
	pos = get_pos_off("seek", x2);
	if (pos == -1)
#if defined(EMINGW)
		result = iseek(f, 0L, SEEK_END);
#else
		result = iiseek(f, 0L, SEEK_END);
#endif
#if defined(ELINUX) || defined(EWATCOM)
	else if (!(pos > (IOFF)MAXINT || pos < (IOFF)MININT))
		result = iiseek(f, pos, SEEK_SET);
#endif
	else
		result = iseek(f, pos, SEEK_SET);
	if (result > (IOFF)MAXINT || result < (IOFF)MININT) {
		result = NewDouble((double)result);  // maximum 2 billion
		return result;
	} else
		return MAKE_INT(result);
}

// 2 implementations of dir()

#ifdef EWATCOM
	// 2 of 3: WATCOM method

static object Dir(object x)
/* x is the name of a directory or file */
{
	char path[MAX_FILE_NAME+1];
	s1_ptr result, row;
	struct dirent *direntp;
	object_ptr obj_ptr, temp;
	int last;
	DIR *dirp;

	/* x will be sequence if called via dir() */

	if (SEQ_PTR(x)->length > MAX_FILE_NAME)
		RTFatal("name for dir() is too long");

	MakeCString(path, x, MAX_FILE_NAME+1);

	last = strlen(path)-1;
	while (last > 0 &&
		   (path[last] == '\\' || path[last] == ' ' || path[last] == '\t')) {
		last--;
	}

	if (last >= 1 && path[last-1] == '*' && path[last] == '.')
		last--; // work around WATCOM bug when we have "*." at end

	if (path[last] != ':')
		path[last+1] = 0; // delete any trailing backslash - Watcom has problems
						  // with wildcards and trailing backslashes together

	dirp = opendir(path);
	if (dirp == NULL) {
		return ATOM_M1; /* couldn't open directory (or file) */
	}

	/* start with empty sequence as result */
	result = (s1_ptr)NewString("");

	for (;;) {
		direntp = readdir(dirp);
		if (direntp == NULL)
			break; /* end of list */

		/* create a length-9 sequence */
		row = NewS1((long)9);
		obj_ptr = row->base;
		obj_ptr[1] = NewString(direntp->d_name);
		obj_ptr[2] = NewString("");
		temp = &obj_ptr[2];

		if (direntp->d_attr & _A_RDONLY)
			Append(temp, *temp, MAKE_INT('r'));
		if (direntp->d_attr & _A_HIDDEN)
			Append(temp, *temp, MAKE_INT('h'));
		if (direntp->d_attr & _A_SYSTEM)
			Append(temp, *temp, MAKE_INT('s'));
		if (direntp->d_attr & _A_VOLID)
			Append(temp, *temp, MAKE_INT('v'));
		if (direntp->d_attr & _A_SUBDIR)
			Append(temp, *temp, MAKE_INT('d'));
		if (direntp->d_attr & _A_ARCH)
			Append(temp, *temp, MAKE_INT('a'));

		obj_ptr[3] = MAKE_INT(direntp->d_size);
		if ((unsigned)obj_ptr[3] > (unsigned)MAXINT) {
			// file size over 1Gb
			obj_ptr[3] = NewDouble((double)(unsigned)obj_ptr[3]);
		}

		obj_ptr[4] = 1980 + direntp->d_date/512;
		obj_ptr[5] = (direntp->d_date/32) & 0x0F;
		obj_ptr[6] = direntp->d_date & 0x01F;

		obj_ptr[7] = direntp->d_time/2048;
		obj_ptr[8] = (direntp->d_time/32) & 0x03F;
		obj_ptr[9] = (direntp->d_time & 0x01F) << 1;

		/* append row to overall result (ref count 1)*/
		Append((object_ptr)&result, (object)result, MAKE_SEQ(row));
	}
	closedir(dirp);

	return (object)result;
}
#endif

#if defined(EUNIX) || defined(EMINGW)
	// 3 of 3: Unix style with stat()
static object Dir(object x)
/* x is the name of a directory or file */
{
	char path[MAX_FILE_NAME+1];
	s1_ptr result, row;
	struct dirent *direntp;
	object_ptr obj_ptr, temp;

	DIR *dirp;
	int r;
	struct stat stbuf;
	struct tm *date_time;
#if defined(EMINGW)
#define full_name_size (MAX_FILE_NAME + 257)
#else
#define full_name_size (MAX_FILE_NAME + NAME_MAX + 1)
#endif

	char full_name[full_name_size + 1];
	/* x will be sequence if called via dir() */

	if (SEQ_PTR(x)->length > MAX_FILE_NAME)
		RTFatal("name for dir() is too long");

	MakeCString(path, x, MAX_FILE_NAME+1);

	dirp = opendir(path); // on Linux, path *must* be a directory

	if (dirp == NULL) {
		r = stat(path, &stbuf);  // should be a file
		if (r == -1)
			return ATOM_M1;
	}

	/* start with empty sequence as result */
	result = (s1_ptr)NewString("");

	for (;;) {
		if (dirp != NULL) {
			direntp = readdir(dirp);
			if (direntp == NULL)
				break; /* end of list */
		}

		/* create a length-9 sequence */
		row = NewS1((long)9);
		obj_ptr = row->base;
		if (dirp == NULL)
			obj_ptr[1] = NewString(name_ext(path)); // just the name
		else
			obj_ptr[1] = NewString(direntp->d_name);
		obj_ptr[2] = NewString("");
		temp = &obj_ptr[2];

		// opendir/readdir with stat method
		if (dirp != NULL) {
			snprintf(full_name, full_name_size, "%s/%s", path, direntp->d_name);
			full_name[full_name_size] = 0; // ensure NULL
			r = stat(full_name, &stbuf);
		}
		if (r == -1) {
			obj_ptr[3] = 0;
			obj_ptr[4] = 0;
			obj_ptr[5] = 0;
			obj_ptr[6] = 0;
			obj_ptr[7] = 0;
			obj_ptr[8] = 0;
			obj_ptr[9] = 0;
		}
		else {
			if ((stbuf.st_mode & S_IFMT) == S_IFDIR)
				Append(temp, *temp, MAKE_INT('d'));

			obj_ptr[3] = stbuf.st_size;
			if ((unsigned)obj_ptr[3] > (unsigned)MAXINT) {
				// file size over 1Gb
				obj_ptr[3] = NewDouble((double)(unsigned)obj_ptr[3]);
			}

			date_time = localtime(&stbuf.st_mtime);
			obj_ptr[4] = date_time->tm_year+1900;
			obj_ptr[5] = date_time->tm_mon+1;
			obj_ptr[6] = date_time->tm_mday;
			obj_ptr[7] = date_time->tm_hour;
			obj_ptr[8] = date_time->tm_min;
			obj_ptr[9] = date_time->tm_sec;
		}

		/* append row to overall result (ref count 1)*/
		Append((object_ptr)&result, (object)result, MAKE_SEQ(row));
		if (dirp == NULL)
			return (object)result;
	}
	closedir(dirp);

	return (object)result;
}
#endif

static object CurrentDir()
/* return name of current directory */
{
	char *cwd;
	object result;
	char *buff;

	buff = malloc(MAX_FILE_NAME+1);
	cwd = getcwd(buff, MAX_FILE_NAME+1);
	if (cwd == NULL)
		RTFatal("current directory not available");
	else {
		result = NewString(cwd);
		free(buff);
	}
	return result;
}

static object PutScreenChar(object x)
/* x is {line, col, {c1, a1, c2, a2, ...}} */
{
	unsigned c, attr, len;
	unsigned cur_line, cur_column, line, column;
	s1_ptr args;
	object_ptr p;
#ifdef EUNIX
	char s1[2];
	int save_line, save_col;
#endif
#ifdef EWINDOWS
	COORD coords;
	int temp;
	char cc[4];
#endif

#if defined(EWINDOWS)
	show_console();
#endif
	args = SEQ_PTR(x);
	line =   get_int(*(args->base+1));
	column = get_int(*(args->base+2));
	x = *(args->base+3);
	args = SEQ_PTR(x);
	len = args->length;
	if (!IS_SEQUENCE(x) || (len & 1) != 0)
		RTFatal("third argument to put_screen_char() must be a sequence of even length");
	p = args->base+1;

#ifdef EUNIX
	save_line = screen_line;
	save_col = screen_col;
	SetPosition(line, column);
	while (len > 0) {
		c = get_pos_int("put_screen_char()", *p);
		attr = get_pos_int("put_screen_char()", *(p+1));
		SetTColor(attr & 15);
		SetBColor(attr >> 4);
		iputc(c, stdout);
		s1[0] = c;
		s1[1] = 0;
		update_screen_string(s1);
		screen_col++;
		p += 2;
		len -= 2;
	}
	SetPosition(save_line, save_col); // restore cursor location
	iflush(stdout);
#endif

#ifdef EWINDOWS
	while (len > 0) {
		cc[0] = get_pos_int("put_screen_char()", *p);
		attr  = get_pos_int("put_screen_char()", *(p+1));
		coords.X = column-1;
		coords.Y = line-1;
		column++;
		WriteConsoleOutputCharacter(console_output, (LPTSTR)&cc, 1, coords, (LPDWORD)&temp);
		WriteConsoleOutputAttribute(console_output, (LPWORD)&attr, 1, coords, (LPDWORD)&temp);
		p += 2;
		len -= 2;
	}
#endif
	return ATOM_1;
}

static object GetScreenChar(object x)
/* return {character, attributes} at given (line, col) location */
{
	struct rccoord pos;
	object_ptr obj_ptr;
	s1_ptr result, x1;
	unsigned c, cur_line, cur_column, line, column;
	struct rccoord p;
#ifdef EWINDOWS
	CONSOLE_SCREEN_BUFFER_INFO console_info;
	int temp, att;
	char ch[4];
	COORD coords;
#endif

	x1 = SEQ_PTR(x);
	line =   get_int(*(x1->base+1));
	column = get_int(*(x1->base+2));
	result = NewS1((long)2);
	obj_ptr = result->base;

#ifdef EWINDOWS
	show_console();

	coords.X = column-1;
	coords.Y = line-1;

	att = 0;
	ReadConsoleOutputCharacter(console_output, (LPTSTR)&ch, 1, coords, (LPDWORD)&temp);
	ReadConsoleOutputAttribute(console_output, (LPWORD)&att, 1, coords, (LPDWORD)&temp);

	obj_ptr[1] = ch[0];
	if ((unsigned)att <= (unsigned)MAXINT)
		obj_ptr[2] = att;
	else
		obj_ptr[2] = NewDouble((double)(unsigned)att);

#endif

#ifdef EUNIX
	if (line >= 1 && line <= line_max &&
		column >= 1 && column <= col_max) {
		obj_ptr[1] = screen_image[line-1][column-1].ascii;
		obj_ptr[2] = (screen_image[line-1][column-1].fg_color & 15) |
					 (screen_image[line-1][column-1].bg_color << 4);
	}
	else {
		obj_ptr[1] = ' ';
		obj_ptr[2] = 0;
	}
#endif
	return MAKE_SEQ(result);
}

static object GetPosition()
/* return {line, column} for cursor */
{
	struct rccoord pos;
	object_ptr obj_ptr;
	s1_ptr result;
#ifdef EWINDOWS
	CONSOLE_SCREEN_BUFFER_INFO console_info;
#endif

	result = NewS1((long)2);
	obj_ptr = result->base;
#ifdef EWINDOWS
	show_console();
	GetConsoleScreenBufferInfo(console_output, &console_info);
	obj_ptr[1] = MAKE_INT(console_info.dwCursorPosition.Y+1);
	obj_ptr[2] = MAKE_INT(console_info.dwCursorPosition.X+1);
#else
	pos = GetTextPositionP();
	obj_ptr[1] = MAKE_INT(pos.row);
	obj_ptr[2] = MAKE_INT(pos.col);
#endif
	return MAKE_SEQ(result);
}

static object flush_file(object x)
/* flush an open user file */
{
	if (x != last_w_file_no) {
		last_w_file_ptr = which_file(x, EF_WRITE);
		if (IS_ATOM_INT(x))
			last_w_file_no = x;
		else
			last_w_file_no = NOVALUE;
	}
	iflush(last_w_file_ptr);
	return ATOM_1;
}

static object lock_file(object x)
/* lock a file. x is {fn, t, {first-byte, last-byte}} */
{
	IFILE f;
	int fd;
	int r, t;
	unsigned long first, last;
	object fn, s;

	// get 1st element of x - file number - assume x is a sequence of length 3
	x = (object)SEQ_PTR(x);
	fn = *(((s1_ptr)x)->base+1);
	f = which_file(fn, EF_READ | EF_WRITE);
	fd = ifileno(f);

#ifdef EUNIX
	// get 2nd element of x - lock type
	t = get_int(*(((s1_ptr)x)->base+2));
	if (t == 1)
		r = flock(fd, LOCK_SH | LOCK_NB);
	else
		r = flock(fd, LOCK_EX | LOCK_NB);
#else // EUNIX
	// get 3rd element of x - range - assume it's a sequence
	s = *(((s1_ptr)x)->base+3);
	s = (object)SEQ_PTR(s);
	if (((s1_ptr)s)->length == 0) {
		first = 0;
		last = 0xFFFFFFFE;
	}
	else if (((s1_ptr)s)->length == 2) {
		first = get_int(*(((s1_ptr)s)->base+1));
		last =  get_int(*(((s1_ptr)s)->base+2));
	}
	else {
		RTFatal("3rd argument to lock_file must be a sequence of length 0 or 2");
	}
	if (last < first)
		return ATOM_0;
#if defined(EMINGW)
	r = 0;  // TODO: FOR NOW!
#else // defined EMINGW
	r = lock(fd, first, last - first + 1);
#endif // defined EMINGW
#endif // EUNIX
	if (r == 0)
		return ATOM_1; // success
	else
		return ATOM_0; // fail
}

static object unlock_file(object x)
/* unlock a file */
{
	IFILE f;
	int fd;
	unsigned long first, last;
	object fn, s;

	// get 1st element of x - can assume x is a sequence of length 2
	x = (object)SEQ_PTR(x);
	fn = *(((s1_ptr)x)->base+1);
	f = which_file(fn, EF_READ | EF_WRITE);
	fd = ifileno(f);
#ifdef EUNIX
	flock(fd, LOCK_UN);
#else // EUNIX
	// get 2nd element of x - range - assume it's a sequence
	s = *(((s1_ptr)x)->base+2);
	s = (object)SEQ_PTR(s);
	if (((s1_ptr)s)->length == 0) {
		first = 0;
		last = 0xFFFFFFFE;
	}
	else if (((s1_ptr)s)->length == 2) {
		first = get_int(*(((s1_ptr)s)->base+1));
		last =  get_int(*(((s1_ptr)s)->base+2));
	}
	else {
		RTFatal("2nd argument to unlock_file must be a sequence of length 0 or 2");
	}
#if defined(EMINGW)
	/* do nothing */
#else // defined EMINGW
	if (last >= first)
		unlock(fd, first, last - first + 1);
#endif // EMINGW
#endif // EUNIX
	return ATOM_1; // ignored
}

static object set_rand(object x)
/* set random number generator */
{
	int r;

	r = get_int(x);

	seed1 = INT_VAL(r)+1;
	seed2 = ~(INT_VAL(r)) + 999;

	rand_was_set = TRUE;

	if (seed1 == 0)
		seed1 = 1;
	if (seed2 == 0)
		seed2 = 1;

	return ATOM_1;
}

static object use_vesa(object x)
/* turn on/off vesa flag */
{
	not_supported("use_vesa()");
	return ATOM_1;
}

static object crash_message(object x)
/* record user's message in case of a crash */
{
	if (crash_msg != NULL)
		EFree(crash_msg);

	if (!IS_SEQUENCE(x) || SEQ_PTR(x)->length == 0) {
		crash_msg = NULL;
	}
	else {
		crash_msg = EMalloc(SEQ_PTR(x)->length + 1);
		MakeCString(crash_msg, x, SEQ_PTR(x)->length + 1);
	}
	return ATOM_1;
}

static object crash_file(object x)
/* record user's alternate path for ex.err */
/* assume x is a sequence */
{
	// use malloc/free
	free(TempErrName);
	TempErrName = malloc(SEQ_PTR(x)->length + 1);
	MakeCString(TempErrName, x, SEQ_PTR(x)->length + 1);
	return ATOM_1;
}

static object warning_file(object x)
/* record user's alternate path for a warning file log */
{
	// use malloc/free
	if (TempWarningName != NULL) free(TempWarningName);
	if IS_ATOM(x) {
		TempWarningName = NULL;
		if (!IS_ATOM_INT(x)) x = (long)(DBL_PTR(x)->dbl);
		display_warnings = (INT_VAL(x) >= 0)?1:0;
	}
	else {
		TempWarningName = malloc(SEQ_PTR(x)->length + 1);
		MakeCString(TempWarningName, x, SEQ_PTR(x)->length + 1);
	}
	return ATOM_1;
}

static object do_crash(object x)
{
	char *message;

	message = malloc(SEQ_PTR(x)->length + 1);
	MakeCString(message, x, SEQ_PTR(x)->length + 1);
	RTFatal(message);
	free(message);

	return ATOM_1;
}

static object change_dir(object x)
/* change to a new current directory */
/* assume x is a sequence */
{
	char *new_dir;
	int r;

	new_dir = malloc(SEQ_PTR(x)->length + 1);
	MakeCString(new_dir, x, SEQ_PTR(x)->length + 1);
	r = chdir(new_dir);
	free(new_dir);
	if (r == 0)
		return ATOM_1;
	else
		return ATOM_0;
}

extern double Wait(double);
static object e_sleep(object x)
/* sleep for x seconds */
{
	double t;

	if IS_ATOM(x) {
		if (IS_ATOM_INT(x)) {
			t = (double)INT_VAL(x);
		} else {
			t = DBL_PTR(x)->dbl;
		}
	}
	Wait(t);
	return ATOM_1;
}

double current_time()
/* return value for time() function */
{
#ifdef EUNIX
	struct tms buf;
#endif
	if (clock_frequency == 0.0) {
		/* no handler */
		return (double)
#ifdef EUNIX
		times(&buf) / clk_tck
#else
		clock() / (double)clocks_per_sec
#endif
		 + clock_adjust;
	}
	else {
		/* our handler is installed */
		return base_time + our_clock_ticks / clock_frequency;
	}
}


#ifndef ERUNTIME
#ifdef EWINDOWS
DWORD WINAPI WinTimer(LPVOID lpParameter)
{
	LARGE_INTEGER freq,lcount,ncount;
	QueryPerformanceFrequency(&freq);
	QueryPerformanceCounter(&lcount);
	while(sample_next < sample_size){
		lcount.QuadPart=((double)lcount.QuadPart)+((double)freq.QuadPart)*0.001;
		QueryPerformanceCounter(&ncount);
		if(ncount.QuadPart<lcount.QuadPart){
			Sleep((((double)(lcount.QuadPart-ncount.QuadPart))/((double)freq.QuadPart))*1000.0);
		}
		if (Executing && ProfileOn) {
			profile_sample[sample_next++] = (int)tpc;
		}
	}
	return 0;
}
#endif
#endif


//void ESetTimer(void (__interrupt __far *handler)())
///* Do some initialization */
//{
//}

object tick_rate(object x)
/* Set new system clock tick (interrupt) rate.
   x may be int or double, >= 0. 0 means restore 18.2 rate. */
{
	return ATOM_1;
}

static object float_to_atom(object x, int flen)
/* convert a sequence of 4 or 8 bytes in IEEE format to an atom */
{
	int len, i;
	object_ptr obj_ptr;
	char fbuff[8];
	double d;

	x = (object)SEQ_PTR(x);
	len = ((s1_ptr)x)->length;
	if (len != flen)
		RTFatal("sequence has wrong length");
	obj_ptr = ((s1_ptr)x)->base+1;
	for (i = 0; i < len; i++) {
		fbuff[i] = (char)obj_ptr[i];
	}
	if (flen == 4)
		d = (double)*((float *)&fbuff);
	else
		d = *((double *)&fbuff);
	return NewDouble(d);
}

static object fpsequence(unsigned char *fp, int len)
/* return a sequence of bytes for a floating-point number */
{
	s1_ptr result;
	object_ptr obj_ptr;
	int i;

	if (len == 0)
		RTFatal("in machine_func an atom was expected, not a sequence");
	result = NewS1(len);
	obj_ptr = result->base+1;

	for (i = 0; i < len; i++) {
		obj_ptr[i] = fp[i];
	}
	return MAKE_SEQ(result);
}

static object atom_to_float64(object x)
/* convert an atom to a sequence of 8 bytes IEEE format */
{
	double d;
	int len;

	len = 8;
	if (IS_ATOM_INT(x)) {
		d = (double)INT_VAL(x);
	}
	else if (IS_ATOM(x)) {
		d = DBL_PTR(x)->dbl;
	}
	else
		len = 0;
	return fpsequence((char *)&d, len);
}

static object atom_to_float32(object x)
/* convert an atom to a sequence of 4 bytes in IEEE format */
{
	float f;
	int len;

	len = 4;
	if (IS_ATOM_INT(x)) {
		f = (float)INT_VAL(x);
	}
	else if (IS_ATOM(x)) {
		f = (float)(DBL_PTR(x)->dbl);
	}
	else
		len = 0;
	return fpsequence((char *)&f, len);
}

object memory_copy(object d, object s, object n)
/* Fast memory to memory copy - called from x.c or machine.c */
{
	char *dest;
	char *src;
	unsigned nbytes;

	dest   = (char *)get_pos_int("mem_copy", d);
	src    = (char *)get_pos_int("mem_copy", s);
	nbytes = get_pos_int("mem_copy", n);

	memmove(dest, src, nbytes); /* overlapping regions handled correctly */
	return ATOM_1;
}

object memory_set(object d, object v, object n)
/* Fast memory set - called from x.c or machine.c */
{
	char *dest;
	int value;
	unsigned nbytes;

	dest   = (char *)get_pos_int("mem_set", d);
	value  = (int)get_pos_int("mem_set", v);
	nbytes = get_pos_int("mem_set", n);
	memset(dest, value, nbytes);
	return ATOM_1;
}

#ifdef EWINDOWS
HINSTANCE *open_dll_list = NULL;
int open_dll_size = 0;
int open_dll_count = 0;
#endif

object OpenDll(object x)
{
	void (FAR WINAPI *proc_address)();
	s1_ptr dll_ptr;
	static unsigned char message[81];
	unsigned char *dll_string;
	HINSTANCE lib;
	int message_len;

	/* x will be a sequence if called via open_dll() */

	dll_ptr = SEQ_PTR(x);
	dll_string = TempBuff;
	message_len = strlen("name for open_dll() is too long."
			"  The name started with \"\".")+1;
	MakeCString(dll_string, (object)x, TEMP_SIZE);
	if (dll_ptr->length >= TEMP_SIZE) {
		dll_string[80 - message_len]='\0';
		snprintf(message,80,"name for open_dll() is too long."
			"  The name started with \"%s\".", dll_string);
		RTFatal(message);
		/*RTFatal("name for open_dll() is too long."
			"  The name started with \"%s\".", dll_string);*/
	}
#ifdef EWINDOWS
	lib = (HINSTANCE)LoadLibrary(dll_string);
	// add to dll list so we can close it at end of execution
	if (lib != NULL) {
		if (open_dll_count >= open_dll_size) {
			size_t newsize;
			
			open_dll_size += 20;
			newsize = open_dll_size * sizeof(HINSTANCE);
			if (open_dll_list == NULL) {
				open_dll_list = (HINSTANCE *)malloc(newsize);
			}
			else {
				open_dll_list = (HINSTANCE *)realloc(open_dll_list, newsize);
			}
			if (open_dll_list == NULL) {
				RTFatal("Cannot allocate RAM (%d bytes) for dll list to add %s", newsize, dll_string);
			}
		}
		open_dll_list[open_dll_count++] = lib;
	}
#else
	// Linux

	lib = (HINSTANCE)dlopen(dll_string, RTLD_LAZY | RTLD_GLOBAL);

#endif
	if ((unsigned)lib <= (unsigned)MAXINT_VAL){
			return MAKE_INT((unsigned long)lib);
	}
	else{
		return NewDouble((double)(unsigned long)lib);
	}
}

object DefineCVar(object x)
/* Get the address of a C variable, or return -1 */
{
	HINSTANCE lib;
	object variable_name;
	s1_ptr variable_ptr;
	unsigned char *variable_string;
	char *variable_address;
	object arg_size, return_size;
	unsigned addr;

	// x will be a sequence if called from define_c_func/define_c_proc
	x = (object)SEQ_PTR(x);

	lib = (HINSTANCE)*(((s1_ptr)x)->base+1);
	lib = (HINSTANCE)get_pos_int("define_c_proc/func", (object)lib);

	variable_name =  *(((s1_ptr)x)->base+2);
	if (IS_ATOM(variable_name))
		RTFatal("variable name must be a sequence");

	variable_ptr = SEQ_PTR(variable_name);
	if (variable_ptr->length >= TEMP_SIZE)
		RTFatal("variable name is too long");
	variable_string = TempBuff;
	MakeCString(variable_string, variable_name, TEMP_SIZE);
#ifdef EWINDOWS
	//Ray Smith says this works.
	variable_address = (char *)(int (*)())GetProcAddress((void *)lib, variable_string);
	if (variable_address == NULL)
		return ATOM_M1;
#else
	// Linux
	variable_address = (char *)dlsym((void *)lib, variable_string);
	if (dlerror() != NULL)
		return ATOM_M1;
#endif
	addr = (unsigned)variable_address;
	if (addr <= (unsigned)MAXINT_VAL)
		return MAKE_INT(addr);
	else
		return NewDouble((double)addr);
}


object DefineC(object x)
/* define a C routine: x is {lib, name, arg_sizes, return_type or 0}
   alternatively, x is {"", address or {'+', address}, arg_sizes, return_type or 0}
   Return -1 on failure. */
{
	HINSTANCE lib;
	object routine_name;
	s1_ptr routine_ptr;
	unsigned char *routine_string;
	int (*proc_address)();
	object arg_size, return_size;
	object_ptr arg;
	int convention, t, raw_addr;

	// x will be a sequence if called from define_c_func/define_c_proc
	x = (object)SEQ_PTR(x);

	lib = (HINSTANCE)*(((s1_ptr)x)->base+1);
	raw_addr = FALSE;

	if (IS_SEQUENCE(lib)) {
		/* machine code: must be length-0, implies 2nd arg is
		   address or {'+', address} */
		if (SEQ_PTR(lib)->length != 0)
			RTFatal("first argument of define_c_proc/func must be an atom or an empty sequence");
		raw_addr = TRUE;
	}
	else {
		/* 32-bit address of lib was supplied */
		lib = (HINSTANCE)get_pos_int("define_c_proc/func", (object)lib);
	}

	routine_name = *(((s1_ptr)x)->base+2);
	convention = C_STDCALL;

	if (raw_addr) {
		/* machine code routine */
		if (IS_ATOM(routine_name)) {
			/* addr */
			proc_address = (int (*)())get_pos_int("define_c_proc/func",
										(object)routine_name);
		}
		else {
			/* {'+', addr} */
			if (SEQ_PTR(routine_name)->length != 2)
				RTFatal("expected {'+', address} as second argument of define_c_proc/func");
			proc_address = (int (*)())*(SEQ_PTR(routine_name)->base+2);
			proc_address = (int (*)())get_pos_int("define_c_proc/func", (object)proc_address);
#ifdef EWINDOWS
			t = (int)*(SEQ_PTR(routine_name)->base+1);
			t = get_pos_int("define_c_proc/func", (object)t);
			if (t == '+')
				convention = C_CDECL;
			else
				RTFatal("unsupported calling convention - use '+' for CDECL");
#endif
		}
		/* assign a sequence value to routine_ptr */
		snprintf(TempBuff, TEMP_SIZE, "machine code routine at %x", proc_address);
		TempBuff[TEMP_SIZE-1] = 0; // ensure NULL
		routine_name = NewString(TempBuff);
		routine_ptr = SEQ_PTR(routine_name);
	}

	else {
		/* C .dll routine */
		if (IS_ATOM(routine_name))
			RTFatal("routine name must be a sequence");
		routine_ptr = SEQ_PTR(routine_name);
		Ref(routine_name);
		if (routine_ptr->length >= TEMP_SIZE)
			RTFatal("routine name is too long");
		routine_string = TempBuff;
		MakeCString(routine_string, routine_name, TEMP_SIZE);
#ifdef EWINDOWS
		if (routine_string[0] == '+') {
			routine_string++;
			convention = C_CDECL;
		}
		proc_address = (int (*)())GetProcAddress((void *)lib, routine_string);
		if (proc_address == NULL)
			return ATOM_M1;
		
#else
#ifdef EUNIX
		proc_address = (int (*)())dlsym((void *)lib, routine_string);
		if (dlerror() != NULL)
			return ATOM_M1;
#endif
#endif
	}

	if (c_routine_next >= c_routine_size) {
		if (c_routine == NULL) {
			c_routine_size = 20;
			c_routine = (struct arg_info *)EMalloc(c_routine_size * sizeof(struct arg_info));
		}
		else {
			c_routine_size *= 2;
			c_routine = (struct arg_info *)ERealloc((char *)c_routine,
								 c_routine_size * sizeof(struct arg_info));
		}
	}

	arg_size = *(((s1_ptr)x)->base+3);
	if (IS_ATOM(arg_size))
		RTFatal("argument size list must be a sequence");
	RefDS(arg_size);

	arg = SEQ_PTR(arg_size)->base+1;
	while (*arg != NOVALUE) {
		if (IS_ATOM_INT(*arg)) {
			t = *arg;
		}
		else if (IS_ATOM(*arg)) {
			t = (unsigned long)DBL_PTR(*arg)->dbl;
		}
		else
			RTFatal("argument type may not be a sequence");

		if (t >= E_INTEGER && t <= E_OBJECT)
			eu_dll_exists = TRUE;
		else if (t < C_CHAR || t > C_DOUBLE)
			RTFatal("Invalid argument type");

		arg++;
	}

	return_size = *(((s1_ptr)x)->base+4);

	if (IS_ATOM_INT(return_size)) {
		t = return_size;
	}
	else if (IS_ATOM(return_size)) {
		t = (unsigned long)DBL_PTR(return_size)->dbl;
	}
	else
		RTFatal("return type must be an atom");

	if (t >= E_INTEGER && t <= E_OBJECT)
		eu_dll_exists = TRUE;
	else if (t != 0 && (t < C_CHAR || t > C_DOUBLE))
		RTFatal("Invalid return type");

	c_routine[c_routine_next].address = proc_address;
	c_routine[c_routine_next].name = routine_ptr;
	c_routine[c_routine_next].arg_size = SEQ_PTR(arg_size);
	c_routine[c_routine_next].return_size = t;
	c_routine[c_routine_next].convention = convention;
	return c_routine_next++;
}

#if __GNUC__ == 4
#define CALLBACK_SIZE 92
#else
#define CALLBACK_SIZE 80
#endif
extern struct routine_list *rt00;

#ifdef EWINDOWS
typedef void * (__stdcall *VirtualAlloc_t)(void *, unsigned int size, unsigned int flags, unsigned int protection);
#endif
object CallBack(object x)
/* return either a call-back address for routine id x
   x can be the routine id for stdcall, or {'+', routine_id} for cdecl 
   
   or return a three element sequence containing a Read-Only machine address, the replace value
   needed (sym tab pointer), and the call_back size respectively so the caller can make its *own*
   call-back address.  In this case x must be a sequence containing only a routine_id:   
   {routine_id} or a sequence containing a two element sequence {{'+',routine_id}} for cdecl.   And
   the caller must search for the bytes {#78,#56,#34,#12}, allocate enough memory (call_back size)
   and to copy what is pointed to by the said address and then replace the searched for bytes with
   the replace value in the allocated memory. 
   */
{
	unsigned addr;
	int routine_id, i, num_args;
	unsigned char *copy_addr;
	symtab_ptr routine;
	int bare_flag = 0;
	object_ptr obj_ptr;
	void * replace_value;
    s1_ptr result;
	s1_ptr x_ptr;
	int convention;
	convention = C_CDECL;
	
	/* Handle {{'+', routine_id} and {routine_id} case:
	 *    Set a flag and take the first element of the argument
	 * to the new value of the argument. */
	if (IS_SEQUENCE(x) && (x_ptr = SEQ_PTR(x))->length == 1) {
			bare_flag = 1;
			obj_ptr = x_ptr->base + 1;
			x = *obj_ptr;
	}
	
	/* Handle whether it is {'+', routine_id} or {routine_id}:
	 * Set flags and extract routine id value. */
	if (IS_SEQUENCE(x)) {
		x_ptr = SEQ_PTR(x);
		/*printf( "x_ptr->length=%d, IS_SEQUENCE(*(obj_ptr=x_ptr->base+1))=%d, "
			"SEQ_PTR(*obj_ptr)->length=%d\n",
		   x_ptr->length, IS_SEQUENCE(*(obj_ptr=(x_ptr->base+1))),SEQ_PTR(obj_ptr)->length );
		fflush(stdout);*/
		if (x_ptr->length != 2){
			RTFatal("call_back() argument must be routine_id, or {'+', routine_id}, {routine_id},"
				"or {{'+', routine_id}}");
		}
		if (get_int( x_ptr->base[1] ) != '+')
			RTFatal("for cdecl, use call_back({'+', routine_id}) or "
				    "call_back({{'+', routine_id}})");
		routine_id = get_int( x_ptr->base[2] );
	}
	else {
		routine_id = get_int(x);
#if defined(EWINDOWS)
		convention = C_STDCALL;
#endif
	}
	
	/* Check routine_id value and get the number of arguments */
#ifdef ERUNTIME
	num_args = rt00[routine_id].num_args;
#else
	if ((unsigned)routine_id >= e_routine_next)
		RTFatal("call_back: bad routine id\n");
	routine = e_routine[routine_id];

	if (routine->token == PROC)
		RTFatal("call-back routine must be a function or type");
	num_args = routine->u.subp.num_args;
#endif

	/* Get the address of the template to be modified. */
	if (convention == C_CDECL) {
		// cdecl allows var args - only one template needed
		addr = (unsigned)&cdecl_call_back;
	}
	else {
		switch (num_args) {
			case 0: addr = (unsigned)&call_back0;
					break;
			case 1: addr = (unsigned)&call_back1;
					break;
			case 2: addr = (unsigned)&call_back2;
					break;
			case 3: addr = (unsigned)&call_back3;
					break;
			case 4: addr = (unsigned)&call_back4;
					break;
			case 5: addr = (unsigned)&call_back5;
					break;
			case 6: addr = (unsigned)&call_back6;
					break;
			case 7: addr = (unsigned)&call_back7;
					break;
			case 8: addr = (unsigned)&call_back8;
					break;
			case 9: addr = (unsigned)&call_back9;
					break;
			default:
					RTFatal("routine has too many parameters for call-back");
		}
	}
	
	/* Now if the arguments were originally {{'+', routine_id}} or {routine_id} we return the 
	 * address of the template; a handle for the routine routine_id, which may be the same as 
	 * the routine id passed in; and the call back size. */
	if (bare_flag) {
#ifdef ERUNTIME
		replace_value = routine_id;
#else
		replace_value = e_routine[routine_id];
#endif
		result = NewS1(3);
		obj_ptr = result->base+1;
		obj_ptr[0] = NewDouble((double)(unsigned long)addr);
		obj_ptr[1] = NewDouble((double)(unsigned long)replace_value);
		obj_ptr[2] = NewDouble((double)(unsigned long)CALLBACK_SIZE);
		return MAKE_SEQ(result);
	}
	
	/* Now allocate memory that is executable or at least can be made to be ... */
#ifdef EWINDOWS
	copy_addr = VirtualAlloc( NULL, CALLBACK_SIZE, MEM_RESERVE | MEM_COMMIT,
		PAGE_EXECUTE_READWRITE );
	if (copy_addr == NULL)
		copy_addr = (unsigned char *)EMalloc(CALLBACK_SIZE);
#else /* ndef EWNIDOWS */
	copy_addr = (unsigned char *)EMalloc(CALLBACK_SIZE);
#endif /* ndef EWINDOWS */


	/* Check if the memory allocation worked. */
	if (copy_addr == NULL) {
		RTFatal("Your program has run out of memory.\nOne moment please...");
	}

	/* copy memory of the template to the newly allocated memory */
	memcpy(copy_addr, (char *)addr, CALLBACK_SIZE);
	
	// Plug in the symtab pointer
	// Find 78 56 34 12
	for (i = 4; i < CALLBACK_SIZE-4; i++) {
		if (copy_addr[i]   == 0x078 &&
			copy_addr[i+1] == 0x056) {
#ifdef ERUNTIME
			*(int *)(copy_addr+i) = routine_id;
#else
			*(symtab_ptr *)(copy_addr+i) = e_routine[routine_id];
#endif
			break;
		}
	}

	/* Make memory executable. */
#ifdef EUNIX
#ifndef EBSD
	mprotect((unsigned)copy_addr & ~(pagesize-1),  // start of page
			 pagesize,  // one page
			 PROT_READ+PROT_WRITE+PROT_EXEC);
#endif
#endif
	addr = (unsigned)copy_addr;

	/* Return new address. */
	if (addr <= (unsigned)MAXINT_VAL)
		return addr;
	else
		return NewDouble((double)addr);
}

int *crash_list = NULL;    // list of routines to call when there's a crash
int crash_routines = 0;    // number of routines
int crash_size = 0;        // space allocated for crash_list

static object crash_routine(object x)
/* add a new routine id to the list to be called if there's a crash */
{
	int r;

	r = get_int(x);
	if (r < 0 || r >=
#ifdef ERUNTIME
	1000000
#else
	e_routine_next
#endif
	   )
		RTFatal("invalid routine id passed to crash_routine()");

#ifndef ERUNTIME
	if (e_routine[r]->token == PROC)
	{
		RTFatal("procedure's routine id passed to crash_routine()");
	}
#endif

	if (crash_list == NULL) {
#ifdef ERUNTIME
		// Interpreter does this in InitExecute()
#ifndef EDEBUG
		signal(SIGILL,  Machine_Handler);
		signal(SIGSEGV, Machine_Handler);
#endif
#endif
		crash_size = 5;
		crash_list = (int *)EMalloc(sizeof(int) * crash_size);
	}
	else if (crash_routines >= crash_size) {
		crash_size += 10;
		crash_list = (int *)ERealloc(crash_list, sizeof(int) * crash_size);
	}
	crash_list[crash_routines++] = r;

	return ATOM_1;
}

object eu_info()
{
	s1_ptr s1;
	s1 = NewS1(5);
	s1->base[1] = MAJ_VER;
	s1->base[2] = MIN_VER;
	s1->base[3] = PAT_VER;
	s1->base[4] = NewString(REL_TYPE);
	s1->base[5] = NewString(get_svn_revision());
	return MAKE_SEQ(s1);
}

object eu_uname()
{
#ifdef EUNIX
	int ret;
	struct utsname buf;
	s1_ptr s1;

	ret = uname(&buf);
	if (ret < 0)
		return ATOM_M1;

#ifdef _GNU_SOURCE
	s1 = NewS1(6);
#else
	s1 = NewS1(5);
#endif
	s1->base[1] = NewString(buf.sysname);
	s1->base[2] = NewString(buf.nodename);
	s1->base[3] = NewString(buf.release);
	s1->base[4] = NewString(buf.version);
	s1->base[5] = NewString(buf.machine);
#ifdef _GNU_SOURCE
	s1->base[6] = NewString(buf.domainname);
#endif
	return MAKE_SEQ(s1);
#else
	return ATOM_0;
#endif
}

#ifdef ERUNTIME
void Machine_Handler(int sig_no)
/* illegal instruction, segmentation violation */
{
	RTFatal("A machine-level exception occurred during execution of your program");
}
#else
void Machine_Handler(int sig_no)
/* illegal instruction, segmentation violation */
{
	RTFatal("A machine-level exception occurred during execution of this statement");
}
#endif

#ifndef ERUNTIME
extern struct IL fe;

object start_backend(object x)
/* called by Euphoria-written front-end to run the back-end
 *
 * x is {symtab, topcode, subcode, names, line_table, miscellaneous}
 */
{
	long switch_len, i;
	s1_ptr x_ptr;
	char *w;
	char **argv;


	w = "backend";

	x_ptr = SEQ_PTR(x);

	if (IS_ATOM(x) || x_ptr->length != 7)
		RTFatal("BACKEND requires a sequence of length 7");

	fe.st = (symtab_ptr)     get_pos_int(w, *(x_ptr->base+1));
	fe.sl = (struct sline *) get_pos_int(w, *(x_ptr->base+2));
	fe.misc = (int *)        get_pos_int(w, *(x_ptr->base+3));
	fe.lit = (char *)        get_pos_int(w, *(x_ptr->base+4));
	fe.includes = (unsigned char **) get_pos_int(w, *(x_ptr->base+5));
	fe.switches = x_ptr->base[6];
	fe.argv = x_ptr->base[7];

#if defined(EUNIX) || defined(EMINGW)
	do_exec(NULL);  // init jumptable
#endif

	fe_set_pointers(); /* change some fe indexes into pointers */

	/* Look at the switches for any information pertient to the backend */
	switch_len = SEQ_PTR(fe.switches)->length;

	for (i=1; i <= switch_len; i++) {
		x_ptr = SEQ_PTR(fe.switches)->base[i];
		w = (char *)EMalloc(SEQ_PTR(x_ptr)->length + 1);
		MakeCString(w, (object) x_ptr, SEQ_PTR(x_ptr)->length + 1);

		if (stricmp(w, "-batch") == 0) {
			is_batch = 1;
		}

		EFree(w);
	}

	be_init(); //earlier for DJGPP

	Execute(TopLevelSub->u.subp.code);

	return ATOM_1;
}
#endif

object machine(object opcode, object x)
/* Machine-specific function "machine". It is passed an opcode and
   a general Euphoria object as its parameters and it returns a
   Euphoria object as a result. */
{
	unsigned addr;
	int temp;
	char *dest;
	char *src;
	unsigned long nbytes;
	int bval;
	double d;

	while (TRUE) {
		switch(opcode) {  /* tricky - could be atom or sequence */
			case M_COMPLETE:
				return MAKE_INT(COMPLETE_MAGIC);
				break;
			case M_SET_T_COLOR:
				if (current_screen != MAIN_SCREEN)
					MainScreen();
				return SetTColor(x);
				break;
			case M_SET_B_COLOR:
				if (current_screen != MAIN_SCREEN)
					MainScreen();
				return SetBColor(x);
				break;
			case M_GRAPHICS_MODE:
				if (current_screen != MAIN_SCREEN)
					MainScreen();
				return Graphics_Mode(x);
				break;
			case M_VIDEO_CONFIG:
				return Video_config(); /* 0 args */
				break;
			case M_CURSOR:
				if (current_screen != MAIN_SCREEN)
					MainScreen();
				return Cursor(x);
				break;
			case M_TEXTROWS:
				if (current_screen != MAIN_SCREEN)
					MainScreen();
				return TextRows(x);
				break;
			case M_WRAP:
				if (current_screen != MAIN_SCREEN)
					MainScreen();
				return Wrap(x);
				break;
			case M_SCROLL:
				if (current_screen != MAIN_SCREEN)
					MainScreen();
				return Scroll(x);
				break;
			case M_WAIT_KEY:
#if defined(EWINDOWS)
				show_console();
#endif
				if (current_screen != MAIN_SCREEN)
					MainScreen();
				return ATOM_0 + get_key(TRUE);
				break;
			case M_GET_MOUSE:
				if (current_screen != MAIN_SCREEN)
					MainScreen();
#ifdef EUNIX
#ifdef EGPM
				return GetMouse();
#else
				return ATOM_M1;
#endif
#else
				return GetMouse();
#endif
				break;
			case M_MOUSE_EVENTS:
				if (current_screen != MAIN_SCREEN)
					MainScreen();
				return MouseEvents(x);
				break;
			case M_MOUSE_POINTER:
				if (current_screen != MAIN_SCREEN)
					MainScreen();
				return MousePointer(x);
				break;
			case M_ALLOC:
				return user_allocate(x);
				break;
			case M_FREE:
				addr = get_pos_int("free", x);
				if (addr != NULL) free((char *)addr);
				return ATOM_0;
				break;
			case M_SEEK:
				return Seek(x);
				break;
			case M_WHERE:
				return Where(x);
				break;
			case M_DIR:
				return Dir(x);
				break;
			case M_CURRENT_DIR:
				return CurrentDir();
				break;
			case M_GET_POSITION:
				if (current_screen != MAIN_SCREEN)
					MainScreen();
				return GetPosition();
				break;
			case M_GET_SCREEN_CHAR:
				if (current_screen != MAIN_SCREEN)
					MainScreen();
				return GetScreenChar(x);
				break;
			case M_PUT_SCREEN_CHAR:
				if (current_screen != MAIN_SCREEN)
					MainScreen();
				return PutScreenChar(x);
				break;
			case M_SET_RAND:
				return set_rand(x);
				break;
			case M_USE_VESA:
				return use_vesa(x);
				break;
			case M_CRASH_MESSAGE:
				return crash_message(x);
				break;
			case M_TICK_RATE:
				return tick_rate(x);
				break;
			case M_ALLOW_BREAK:
				allow_break = get_int(x);
				return ATOM_1;
				break;
			case M_CHECK_BREAK:
				temp = control_c_count;
				control_c_count = 0;
				return MAKE_INT(temp);
				break;
			case M_MEM_COPY:
				/* obsolete, but keep it */
				x = (object)SEQ_PTR(x);
				return memory_copy(*(((s1_ptr)x)->base+1),
								   *(((s1_ptr)x)->base+2),
								   *(((s1_ptr)x)->base+3));
				break;
			case M_MEM_SET:
				/* obsolete, but keep it */
				x = (object)SEQ_PTR(x);
				return memory_set(*(((s1_ptr)x)->base+1),
								  *(((s1_ptr)x)->base+2),
								  *(((s1_ptr)x)->base+3));
				break;
			case M_A_TO_F64:
				return atom_to_float64(x);
				break;
			case M_A_TO_F32:
				return atom_to_float32(x);
				break;
			case M_F64_TO_A:
				return float_to_atom(x, 8);
				break;
			case M_F32_TO_A:
				return float_to_atom(x, 4);
				break;

			case M_OPEN_DLL:
				return OpenDll(x);
				break;

			case M_DEFINE_C:
				return DefineC(x);
				break;

			case M_CALLBACK:
				return CallBack(x);
				break;

			case M_PLATFORM:
				/* obsolete, but keep it */
#ifdef ENETBSD
				return 7;
#else
#ifdef EOPENBSD
				return 6;
#else
#ifdef ESUNOS
				return 5;
#else
#ifdef EOSX
				return 4;
#else
#ifdef EBSD // FreeBSD by this point
				return 8;
#else
#ifdef ELINUX
				return 3;  // (UNIX, called Linux for backwards compatibility)
#else
#ifdef EWINDOWS
				return 2;  // WIN32
#else
				return 1; // Unknown platform
#endif
#endif
#endif
#endif
#endif
#endif
#endif

				break;

			case M_INSTANCE:
#ifdef EUNIX
				if ((unsigned)getpid() <= (unsigned)MAXINT)
					return (unsigned)getpid();
				else
					return NewDouble((double)(unsigned)getpid());
#else
#ifdef EWINDOWS
				if ((unsigned)winInstance <= (unsigned)MAXINT)
					return (unsigned)winInstance;
				else
					return NewDouble((double)(unsigned)winInstance);
#else
				return 0;
#endif //EWINDOWS
#endif //EUNIX
				break;

			case M_FREE_CONSOLE:
				if (current_screen != MAIN_SCREEN)
					MainScreen();
				if (have_console) {
#ifndef EUNIX
					FreeConsole();
#endif
					have_console = FALSE;
				}
				// no-op in DOS
				return ATOM_1;
				break;

			case M_DEFINE_VAR:
				return DefineCVar(x);
				break;

			case M_CRASH_FILE:
				return crash_file(x);
				break;

			case M_WARNING_FILE:
				return warning_file(x);
				break;

			case M_FLUSH:
				return flush_file(x);
				break;

			case M_LOCK_FILE:
				return lock_file(x);
				break;

			case M_UNLOCK_FILE:
				return unlock_file(x);
				break;

			case M_CRASH:
				return do_crash(x);
				break;

			case M_CHDIR:
				return change_dir(x);
				break;

			case M_SLEEP:
				return e_sleep(x);
				break;

#ifndef ERUNTIME
			case M_BACKEND:
				return start_backend(x);
				break;
#endif
			case M_CRASH_ROUTINE:
				return crash_routine(x);
				break;

			case M_SET_ENV:
				x = (object)SEQ_PTR(x);
				src = EMalloc(SEQ_PTR(((s1_ptr) x)->base[1])->length + 1);
				dest = EMalloc(SEQ_PTR(((s1_ptr) x)->base[2])->length + 1);
				MakeCString(src, (object) *(((s1_ptr)x)->base+1), 
							SEQ_PTR(((s1_ptr) x)->base[1])->length + 1);
				MakeCString(dest, (object) *(((s1_ptr)x)->base+2), 
							SEQ_PTR(((s1_ptr) x)->base[2])->length + 1);
				temp = setenv(src, dest, *(((s1_ptr)x)->base+3));
				EFree(dest);
				EFree(src);
				return !temp;
				break;

			case M_UNSET_ENV:
				x = (object) SEQ_PTR(x);
				src = EMalloc(SEQ_PTR(((s1_ptr) x)->base[1])->length + 1);
				MakeCString(src, (object) *(((s1_ptr)x)->base+1), 
							SEQ_PTR(((s1_ptr) x)->base[1])->length + 1);
#ifdef EWATCOM
				temp = setenv(src, NULL, 1);
#else
#ifdef EUNIX
#ifdef ELINUX
				temp = unsetenv(src);
#else
				unsetenv(src);
				temp = 0;
#endif /* ELINUX */
#endif /* EUNIX */
#endif /* EWATCOM */

				EFree(src);
				return !temp;
				break;

			case M_PCRE_COMPILE:
				x = (object)SEQ_PTR(x);
				return compile_pcre(*(((s1_ptr)x)->base+1),
							 *(((s1_ptr)x)->base+2));
				break;

			case M_PCRE_EXEC:
				return exec_pcre(x);
				break;

			case M_PCRE_REPLACE:
				return find_replace_pcre(x);

			case M_EU_INFO:
				return eu_info();

			case M_UNAME:
				return eu_uname();

			case M_SOCK_GETSERVBYNAME:
				return eusock_getservbyname(x);

			case M_SOCK_GETSERVBYPORT:
				return eusock_getservbyport(x);

			case M_SOCK_GETHOSTBYNAME:
				return eusock_gethostbyname(x);

			case M_SOCK_GETHOSTBYADDR:
				return eusock_gethostbyaddr(x);

			case M_SOCK_SOCKET:
				return eusock_socket(x);

			case M_SOCK_CLOSE:
				return eusock_close(x);

			case M_SOCK_SHUTDOWN:
				return eusock_shutdown(x);

			case M_SOCK_CONNECT:
				return eusock_connect(x);

			case M_SOCK_SEND:
				return eusock_send(x);

			case M_SOCK_RECV:
				return eusock_recv(x);

			case M_SOCK_BIND:
				return eusock_bind(x);

			case M_SOCK_LISTEN:
				return eusock_listen(x);

			case M_SOCK_ACCEPT:
				return eusock_accept(x);
			
			case M_SOCK_GETSOCKOPT:
				return eusock_getsockopt(x);

			case M_SOCK_SETSOCKOPT:
				return eusock_setsockopt(x);

			case M_SOCK_SELECT:
				return eusock_select(x);

			/* remember to check for MAIN_SCREEN wherever appropriate ! */
			default:
				/* could be out-of-range int, or double, or sequence */
				if (IS_ATOM_INT(opcode)) {
					RTFatal("machine_proc/func(%d,...) not supported", opcode);
				}
				else if (IS_ATOM(opcode)) {
					d = DBL_PTR(opcode)->dbl;
					if (d < 0.0 || d >= MAXINT_DBL)
						RTFatal("the first argument of machine_proc/func must be a small positive integer");
					opcode = (long)d;
				}
				else {
					RTFatal("the first argument of machine_proc/func must be an integer");
				}
				/* try again at top of while loop */
		}
	}
}
