/*****************************************************************************/
/*      (c) Copyright 2007 Rapid Deployment Software - See License.txt       */
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
#endif

#else

#include <direct.h>

#ifdef EDJGPP
#include <dpmi.h>
#include <go32.h>
#include <dirent.h>
#include <sys/stat.h>
#include <allegro.h>

BEGIN_GFX_DRIVER_LIST
GFX_DRIVER_VBEAF
GFX_DRIVER_VGA
GFX_DRIVER_VESA3
GFX_DRIVER_VESA2L
GFX_DRIVER_VESA2B
GFX_DRIVER_VESA1
END_GFX_DRIVER_LIST

BEGIN_COLOR_DEPTH_LIST
COLOR_DEPTH_8
END_COLOR_DEPTH_LIST

// Actually made .exe bigger???
//BEGIN_DIGI_DRIVER_LIST
//END_DIGI_DRIVER_LIST
//BEGIN_MIDI_DRIVER_LIST
//END_MIDI_DRIVER_LIST
//BEGIN_JOYSTICK_DRIVER_LIST
//END_JOYSTICK_DRIVER_LIST
#endif

#ifdef EBORLAND
#include <io.h>
#include <dos.h>
#include <dir.h>
#endif

#ifdef ELCC
#include <io.h>
#endif

#ifdef EWATCOM
#include <graph.h>
#include <i86.h>
#endif

#ifndef ELCC
#include <dos.h>
#endif

#endif  //EUNIX

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

#include "alldefs.h"
#include "alloc.h"
#include <signal.h>

#include "version.h"

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
struct videoconfig config;
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
#ifndef EDOS
#ifdef EWINDOWS
extern HANDLE console_output;
extern unsigned default_heap;
#endif
extern int have_console;
#endif
#ifdef EDOS
extern short _SVGAType;
#endif
extern symtab_ptr cb_routine[];
extern object last_w_file_no;
extern IFILE last_w_file_ptr;

/********************/
/* Local variables */
/*******************/
#ifdef EDOS
#ifndef EDJGPP
static int page_was_set = 0;
#endif
#endif
static int win95 = UNKNOWN;   /* TRUE if long filenames are supported in DOS */

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

#ifdef EDOS
static unsigned char correct256[] = {4,0,1,0,8,0,1,1,1,1};
static unsigned char correct16[]  = {4,0,1,0,4,0,0,0,0,240};
static unsigned char correct4[]   = {4,0,1,0,2,0,85};
static unsigned char correct2[]   = {4,0,1,0,1,0,240};

static void (__interrupt __far *BIOSTimerHandler)();
static volatile int interval;
static volatile int clock_ticks;

static int image_ok = FALSE; /* is it ok to use _putimage/_getimage ? */
static int abs_rows;         /* for CauseWay NT bug */
static short original_vesa;  /* original setting of _SVGAType */
#endif

char *version_name =
#ifdef EDOS
#ifdef EDJGPP
"DOS32 built for DJGPP";
#else
"DOS32";
#endif
#endif

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

#ifndef EDOS
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
#endif

#ifdef EMINGW
#define setenv MySetEnv
static int MySetEnv(const char *name, const char *value, const int overwrite) {
	int len = strlen(name)+1+strlen(value)+1;
	char * str = malloc(len);
	if (!overwrite && (getenv(name) != NULL))
		return 0;
	sprintf(str, "%s=%s", name, value);
	return putenv(str);
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
		sprintf(TempBuff,
		"%s: an integer was expected, not a sequence", where);
		RTFatal(TempBuff);
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
		sprintf(TempBuff,
		"%s: an integer was expected, not a sequence", where);
		RTFatal(TempBuff);
	}
}

#ifdef EDOS

// OBSOLETE, FOLD some of this into long_to_short() below
#ifdef OLDLFN
int IsWin95()
/* returns TRUE if long filenames are supported in DOS
  (not pure DOS 7 on win95) */
{
	char *wd;
	char path[260];
	union REGS regs;
	IFILE f;

	// Look for windir
	wd = getenv("windir");     // can't get "windir" var on XP
	if (wd == NULL)
		wd = "C:\\WINDOWS";

	// Look for explorer.exe
	strcpy(path, wd);
	strcat(path, "\\explorer.exe");
	f = iopen(path, "r");
	if (f == NULL)
		return FALSE;
	iclose(f);

	// check DOS version >= 5  -was: >= 7
	regs.h.ah=0x30;
	int386(0x21, &regs, &regs);

	return regs.h.al >= 5;
}
#endif

char *long_to_short(char *long_name)
/* Map long filename to short DOS 8.3 filename - needed for WATCOM */
{
	int i, size;
	char *long_buff_ptr;
	char *short_buff_ptr;
	union REGS regs;
	struct SREGS seg_regs;
	// register list for Causeway IntXX
	struct xx {
		unsigned int edi;
		unsigned int esi;
		unsigned int ebp;
		unsigned int z0;
		unsigned int ebx;
		unsigned int edx;
		unsigned int ecx;
		unsigned int eax;
		unsigned short flags;
		unsigned short es;
		unsigned short ds;
		unsigned short fs;
		unsigned short gs;
		unsigned short z1;
		unsigned short z2;
		unsigned short z3;
		unsigned short z4;
	} reglist;

#ifndef EDJGPP
	if (!win95)
		return long_name;

	if (long_buff == 0) {
		// first time only: allocate two buffers in low DOS memory

		// long name buffer:
		segread(&seg_regs);
		regs.w.ax = 0x0ff21;
		size = 300;
		regs.w.bx = size; // add 1 - Dave said there was a bug on NT
		int386x(0x31, &regs, &regs, &seg_regs);
		if (regs.x.cflag != 0)
			return long_name; // GetMemDOS failed!
		long_buff = (unsigned int)regs.w.ax;

		// short name buffer:
		segread(&seg_regs);
		regs.w.ax = 0x0ff21;
		regs.w.bx = size;
		int386x(0x31, &regs, &regs, &seg_regs);
		if (regs.x.cflag != 0)
			return long_name; // GetMemDOS failed!
		short_buff = (unsigned int)regs.w.ax;
	}

	long_buff_ptr = (char *) (long_buff << 4);
	short_buff_ptr = (char *) (short_buff << 4);

	if (win95 == UNKNOWN) {
		// check if the filesystem supports long filenames for DOS programs

		strcpy(long_buff_ptr, "C:\\");
		short_buff_ptr[0] = 0;

		reglist.eax = 0x71A0; //w95 long to short
		reglist.ecx = 300; // size of short buff es/edi

		reglist.ds = long_buff;  reglist.edx = 0;
		reglist.es = short_buff; reglist.edi = 0;

		segread(&seg_regs);

		regs.x.edi = (unsigned int)&reglist;
		regs.x.ebx = (unsigned int)0x21;
		regs.x.eax = 0x0ff01;

		int386x(0x31, &regs, &regs, &seg_regs);

		if ((reglist.flags & 1) ||
			short_buff_ptr[0] == 0 ||
			(reglist.ebx & 0x4000) == 0) {
			win95 = FALSE;  // can't handle long names, don't try again
			return long_name;
		}
		else {
			win95 = TRUE;
		}
	}

	// convert long filename to DOS 8.3 short filename
	strcpy(long_buff_ptr, long_name);
	short_buff_ptr[0] = 0;

	reglist.eax = 0x7160; // major code
	reglist.ecx = 0x0001; // minor code: convert long to short

	reglist.ds = long_buff;  reglist.esi = 0;
	reglist.es = short_buff; reglist.edi = 0;

	segread(&seg_regs);

	regs.x.edi = (unsigned int)&reglist;
	regs.x.ebx = (unsigned int)0x21;
	regs.x.eax = 0x0ff01;

	int386x(0x31, &regs, &regs, &seg_regs);

	if ((reglist.flags & 1) || short_buff_ptr[0] == 0) {
		return long_name; // failure - file might not exist
	}
	else {
		return short_buff_ptr;
	}
#endif
}
#endif

IFILE long_iopen(char *name, char *mode)
/* iopen a file. Has support for Windows 95 long filenames */
{
#if defined(EDOS) && !defined(EDJGPP)
	return iopen(long_to_short(name), mode);
#endif
	return iopen(name, mode);
}

int long_open(char *name, int mode)
/* open a file. Has support for Windows 95 long filenames */
{
#if defined(EDOS) && !defined(EDJGPP)
	return open(long_to_short(name), mode);
#else
	return open(name, mode);
#endif
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

/* Warning: side effects could happen from double eval of x */
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
#ifdef EDOS
#ifdef EDJGPP
	allegro_init();
	allegro_404_char = ' ';
	install_timer();
	// set_uformat(U_ASCII);
#else
	extern unsigned short _BiosSeg;
	extern unsigned long _BiosOff;
	union REGS regs;
	int rows, seg_rows;
	int peekaboo;

	abs_rows = (*(int *)0x484) & 0xff; // for Causeway NT text-rows bug
	abs_rows++;
	original_vesa = _SVGAType;
#endif
#endif

#ifdef EUNIX
	// save initial tty state
	tcgetattr(STDIN_FILENO, &savetty);

	// set up tty for no echo
	newtty = savetty;
	newtty.c_cc[VTIME] = 0;
	//noecho(0); // necessary?
#endif

	NewConfig(FALSE);

#if defined(EDOS) && !defined(EDJGPP)
if (!(getenv("EUVISTA")!=NULL && atoi(getenv("EUVISTA"))==1))
{
	if (config.numtextcols > 80 || config.mode > 10 ||
		(config.mode >= 4 && config.mode <= 6)) {
		/* something doesn't work if starting in graphics mode */
		_setvideomode(3);
		NewConfig(TRUE);
	}
	else {
		memset(&regs, 0, sizeof(regs));
		regs.w.ax = 0xff08;       // GetSelDet32
		regs.w.bx = _BiosSeg;
		int386(0x31, &regs, &regs);
		peekaboo = regs.x.edx;    // base of selector
		peekaboo += _BiosOff;
		peekaboo += 0x84;
		seg_rows = (*(int *)peekaboo) & 0xff;
		seg_rows++;

		rows = abs_rows;
		if (abs_rows != seg_rows || abs_rows != config.numtextrows) {
			// looks like NT/XP text-rows bug.
			// on NT & XP, in a new >25-line DOS window, the
			// Virtual DOS machine (VDM) initially has some confusion
			// about the number of lines available on the screen.
			// This can cause VDM to crash if the first DOS program is run
			// near the bottom of the screen.
			// By explicitly setting the number of lines, we clear up the
			// confusion, but the screen must clear.

#ifdef EXTRA_CHECK
			iprintf(stdout,
			"\n\nlooks like Causeway/NT bug: abs_rows=%d, seg_rows=%d\n\n");
#endif

			if (seg_rows > 43)
				rows = _settextrows(50);
			if ((seg_rows > 28  && seg_rows <= 43) || rows != 50)
				rows = _settextrows(43);
			if ((seg_rows > 25 && seg_rows < 28) || rows < 43)
				rows = _settextrows(28);
			if (seg_rows <= 25 || rows < 28)
				rows = _settextrows(25);
		}
		if (rows) {
			config.numtextrows = rows;
			line_max = rows;
		}
	}
/* _settextwindow(1,1,25,80); ?*/
} //endif EUVISTA
#endif
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
#ifdef EDOS
#ifdef EDJGPP
	allegro_exit();
#else
/*    (void)Cursor(C_UNDERLINE); */

	if (page_was_set) {
	_setactivepage(0);
	_setvisualpage(0);
	}

#endif
#endif
}

void not_supported(char *feature)
/* Report that a feature isn't supported on this platform */
{
	char buff[100];

	sprintf(buff, "%s is not supported in Euphoria for %s",
				  feature, version_name);
	RTFatal(buff);
}

static object SetSound(object x)
/* set speaker sound */
{
#ifndef EDOS
	//not_supported("sound()"); CAN I DO ANYTHING IN WINDOWS FOR THIS?
#else
	unsigned f;

	f = get_int(x);
	if (f == 0)
		nosound();
	else
		sound(f);
#endif
	return ATOM_1;
}


#ifdef EDJGPP
struct xycoord {
	int xcoord;   // with WATCOM these are short ints
	int ycoord;
};
#endif

#ifdef EDOS
static int is_rectangle(struct xycoord *xyarray)
/* is a 4-vertex polygon a rectangle? */
{
	if (xyarray[0].xcoord == xyarray[1].xcoord) {
		if (xyarray[0].ycoord == xyarray[3].ycoord)
			if (xyarray[1].ycoord == xyarray[2].ycoord)
				if (xyarray[2].xcoord == xyarray[3].xcoord)
					return TRUE;
	}

	else if (xyarray[0].ycoord == xyarray[1].ycoord) {
		if (xyarray[0].xcoord == xyarray[3].xcoord)
			if (xyarray[1].xcoord == xyarray[2].xcoord)
				if (xyarray[2].ycoord == xyarray[3].ycoord)
					return TRUE;
	}

	return FALSE;
}
#endif

static object Line(object x, int style)
/* draw a line or polygon, x is {colour, fill, {{x,y}, ...}} */
/* style is LINE or POLYGON */
{
#ifndef EDOS
	not_supported("draw_line()");
#else
	int colour, fill, length;
	s1_ptr xy_sequence, s1_pair;
	object_ptr pair;
	register int i;
	int size;
	struct xycoord *xyarray;

	x = (object)SEQ_PTR(x);
	colour = get_int(*(((s1_ptr)x)->base+1));
	xy_sequence = SEQ_PTR(*(((s1_ptr)x)->base+3));
	length = xy_sequence->length;
	pair = xy_sequence->base+1;
	if (length > TEMP_SIZE / sizeof(struct xycoord))
		xyarray = (struct xycoord *)EMalloc(sizeof(struct xycoord) * length);
	else
		xyarray = (struct xycoord *)TempBuff;
	for (i = 0; i < length ; i++) {
		s1_pair = SEQ_PTR(*pair);
		if (!IS_SEQUENCE(*pair) || s1_pair->length != 2)
			RTFatal("machine_proc() expected to see {x,y} point");
		xyarray[i].xcoord = get_int(*(s1_pair->base+1));
		xyarray[i].ycoord = get_int(*(s1_pair->base+2));
		pair++;
	}
#ifndef EDJGPP
	_setcolor((short)colour);
#endif
	if (style == M_LINE) {
#ifdef EDJGPP
		for (i = 0; i < length-1; i++)
			line(screen, xyarray[i  ].xcoord, xyarray[i  ].ycoord,
						 xyarray[i+1].xcoord, xyarray[i+1].ycoord,
						 colour);
#else
		_moveto(xyarray[0].xcoord, xyarray[0].ycoord);
		for (i = 1; i < length; i++)
			_lineto(xyarray[i].xcoord, xyarray[i].ycoord);
#endif
	}
	else {
		fill = get_int(*(((s1_ptr)x)->base+2));
#ifdef EDJGPP
		if (fill) {
			if (length == 4 && is_rectangle(xyarray)) {
				/* not faster, but makes it more compatible with Watcom,
				   otherwise it seems to drop last row and last column */
				rectfill(screen, xyarray[0].xcoord, xyarray[0].ycoord,
								 xyarray[2].xcoord, xyarray[2].ycoord, colour);
			}
			else {
				polygon(screen, length, (int *)xyarray, colour);
			}
		}
		else {
			for (i = 0; i < length-1; i++) {
				line(screen, xyarray[i  ].xcoord, xyarray[i  ].ycoord,
							 xyarray[i+1].xcoord, xyarray[i+1].ycoord,
							 colour);
			}
			// connect last point to first
			line(screen, xyarray[length-1].xcoord, xyarray[length-1].ycoord,
						 xyarray[0].xcoord, xyarray[0].ycoord, colour);
		}
#else
		fill = fill ? (short)_GFILLINTERIOR : (short)_GBORDER;
		if (length == 4 && is_rectangle(xyarray)) {
			/* faster */
			_rectangle((short)fill, (short)xyarray[0].xcoord,
									(short)xyarray[0].ycoord,
									(short)xyarray[2].xcoord,
									(short)xyarray[2].ycoord);
		}
		else {
			_polygon((short)fill, (short)length, xyarray);
		}
#endif
	}
	if (length > TEMP_SIZE / sizeof(struct xycoord))
		EFree((char *)xyarray);
#endif
	return ATOM_1;
}

#define MODE_19_BASE ((unsigned)0xA0000)
#define MODE_19_WIDTH 320
#define MODE_19_HEIGHT 200


object Pixel(object pixels, object hv_sequence)
/* set a pixel or sequence of pixels */
/* pixels can be atom or sequence, hv_sequence should be {x, y} */
{
#ifndef EDOS
	not_supported("pixel()");
#else
	int shift, i, h, v, c, len, firstb, p, mask;
	char *first_ptr;
	char *second_ptr;
	char *third_ptr;
	char *fourth_ptr;
	int step1, step2, step3;
	object pix;
	object_ptr pixel_ptr;
	s1_ptr hv_s;

	if (current_screen != MAIN_SCREEN)
		MainScreen();
	hv_s = SEQ_PTR(hv_sequence);
	if (!IS_SEQUENCE(hv_sequence) || hv_s->length != 2)
		RTFatal("second argument to pixel must be a sequence of length 2");

	h = *(hv_s->base+1);
	if (!IS_ATOM_INT(h))
		h = get_int(h);

	v = *(hv_s->base+2);
	if (!IS_ATOM_INT(v))
		v = get_int(v);

	if (IS_ATOM(pixels)) {
		c = get_int(pixels);
		if (config.mode == 19) {
			/* faster code for mode 19 */
			if ((unsigned)h < MODE_19_WIDTH &&
				(unsigned)v < MODE_19_HEIGHT) {
				first_ptr = (char *)MODE_19_BASE + h + (v << 8) + (v << 6);
#ifdef EDJGPP
				_farpokeb(_go32_info_block.selector_for_linear_memory,
						  (unsigned long)first_ptr,
						  (unsigned char)c);
#else
				*first_ptr = c;
#endif
			}
		}
		else {
			/* 2/3 of atom pixel time spent in next two routines:
			only 1/3 in Euphoria overhead */
#ifdef EDJGPP
			putpixel(screen, h, v, c & config.mask);
#else
			_setcolor((short)c);
			_setpixel((short)h, (short)v);
#endif
		}
	}

	else {
		/* sequence of pixels */
		pixels = (object)SEQ_PTR(pixels);
		len = ((s1_ptr)pixels)->length;
		pixel_ptr = ((s1_ptr)pixels)->base+1;

		if (config.mode == 19) {
			/* fast code for mode 19 */
			if ((unsigned)v < MODE_19_HEIGHT &&
				h < MODE_19_WIDTH && (h + len) > 0) {
				/* there's something to plot */
				if (h + len > MODE_19_WIDTH)
					len = MODE_19_WIDTH - h;
				if (h < 0) {
					len = len + h;  // reduce len
					pixel_ptr -= h; // increase pixel_ptr
					h = 0;
				}
				first_ptr = (char *)MODE_19_BASE + h + (v << 8) + (v << 6);
				while (len-- > 0) {   // sentinel didn't help much at all
					pix = *pixel_ptr++;
					if (IS_ATOM_INT(pix)) {
#ifdef EDJGPP
						_farpokeb(_go32_info_block.selector_for_linear_memory,
								  (unsigned long)first_ptr,
								  (unsigned char)pix);

#else
						*first_ptr = pix;
#endif
					}
					else {
						if (pix == NOVALUE)
							break;
#ifdef EDJGPP
						_farpokeb(_go32_info_block.selector_for_linear_memory,
								  (unsigned long)first_ptr,
								  (unsigned char)get_int(pix));
#else
						*first_ptr = get_int(pix); // might have fatal error
#endif
					}
					first_ptr++;
				}
			}
		}

#ifndef EDJGPP
		else if (image_ok && len >= 3 && len <= 1024) {
			TempBuff[0] = len & 255;
			TempBuff[1] = len >> 8;
			TempBuff[2] = 1;
			TempBuff[3] = 0;
			TempBuff[5] = 0;

			/* must be one of these #colors since image_ok = TRUE */
			if (config.numcolors == 256) {
				TempBuff[4] = 8;
				i = 6;
				while (TRUE) {
					pix = *pixel_ptr++;
					if (IS_ATOM_INT(pix))
						TempBuff[i++] = pix;
					else {
						if (pix == NOVALUE)
							break;
						TempBuff[i++] = get_int(pix);
					}
				}
			}
			else if (config.numcolors == 16) {
				TempBuff[4] = 4;
				step1 = 1 + ((len-1) >> 3);
				step2 = step1 + step1;
				step3 = step2 + step1;
				firstb = step1 << 2;
				mask = 128;
				first_ptr = TempBuff + 6;
				second_ptr = first_ptr + step1;
				third_ptr = first_ptr + step2;
				fourth_ptr = first_ptr + step3;
				if (firstb > 16)
					memset(first_ptr, 0, firstb);
				else {
					*(int *)first_ptr = 0;
					*(int *)(first_ptr+4) = 0;
					*(int *)(first_ptr+8) = 0;
					*(int *)(first_ptr+12) = 0;
				}
				while (--len >= 0) {
					pix = *pixel_ptr++;
					p = Get_Int(pix);
					switch(p & 15) {
						case 3:
							*third_ptr |= mask;   // 2
						case 1:
							*fourth_ptr |= mask;  // 1
							break;

						case 7:
							*fourth_ptr |= mask;  // 1
						case 6:
							*third_ptr |= mask;   // 2
						case 4:
							*second_ptr |= mask;  // 4
							break;

						case 9:
							*first_ptr |= mask;   // 8
							*fourth_ptr |= mask;  // 1
							break;

						case 13:
							*first_ptr |= mask;   // 8
						case 5:
							*second_ptr |= mask;  // 4
							*fourth_ptr |= mask;  // 1
							break;

						case 11:
							*fourth_ptr |= mask;  // 1
						case 10:
							*first_ptr |= mask;   // 8
						case 2:
							*third_ptr |= mask;   // 2
							break;

						default: /* case 15: faster this way :-) */
							*fourth_ptr |= mask;  // 1
						case 14:
							*third_ptr |= mask;   // 2
						case 12:
							*second_ptr |= mask;  // 4
						case 8:
							*first_ptr |= mask;   // 8
						case 0:
							break;
					}
					mask >>= 1;
					if (mask == 0) {
						first_ptr++;
						second_ptr++;
						third_ptr++;
						fourth_ptr++;
						mask = 128;
					}
				}
			}
			else if (config.numcolors == 4 ) { // mode 15 uses slow code
				TempBuff[4] = 2;
				firstb = 5;
				for (i = 0; i < len; i++) {
					pix = *pixel_ptr++;
					p = Get_Int(pix) & 3;
					if ((i & 3) == 0) {
						firstb++;
						TempBuff[firstb] = 0;
						shift = 6;
					}
					TempBuff[firstb] |= (p << shift);
					shift -= 2;
				}
			}
			else /* 2 */ {
				TempBuff[4] = 1;
				firstb = 5;
				for (i = 0; i < len; i++) {
					pix = *pixel_ptr++;
					p = Get_Int(pix) & 1;
					if ((i & 7) == 0) {
						firstb++;
						TempBuff[firstb] = 0;
						shift = 7;
					}
					TempBuff[firstb] |= (p << shift);
					shift -= 1;
				}
			}
			_putimage(h, v, TempBuff, _GPSET);
		}
#endif
		else {
			/* slow code: we can't use _putimage */
			for (i = 0; i < len; i++) {
				pix = *pixel_ptr++;
				c = Get_Int(pix);
#ifdef EDJGPP
				putpixel(screen, h, v, c & config.mask);
#else

				_setcolor((short)c);
				_setpixel((short)h, (short)v);
#endif
				h++;
			}
		}
	}
#endif
	return ATOM_1;  //move this up to avoid branch inside loop?
}

object Get_Pixel(object x)
/* read value of a pixel or series of pixels */
/* x should be {h, v} or {h, v, len} */
/* mode 19 code for sequence not implemented - a bit tricky */
{
#ifndef EDOS
	not_supported("get_pixel()");
	return 0;
#else
	int mask, firstb, p, h, v, i, c, arg_len, len, step1, step2, step3;
	int shift, prefill, postfill;
	char *first_ptr;
	object_ptr obj_ptr;
	s1_ptr result;
	s1_ptr x1;

	if (current_screen != MAIN_SCREEN)
		MainScreen();
	x1 = SEQ_PTR(x);
	if (!IS_SEQUENCE(x) || (x1->length != 2 && x1->length != 3))
		RTFatal("argument to get_pixel() must be a sequence of length 2 or 3");
	arg_len = x1->length;
	h = get_int(*(x1->base+1));
	v = get_int(*(x1->base+2));
	if (arg_len == 2) {
		/* read single pixel */
		if (config.mode == 19) {
			/* fast code for mode 19 reading one pixel */
			if ((unsigned)h < MODE_19_WIDTH &&
				(unsigned)v < MODE_19_HEIGHT) {
				first_ptr = (char *)MODE_19_BASE + h + (v << 8) + (v << 6);
				return (unsigned char)
#ifdef EDJGPP
				_farpeekb(_go32_info_block.selector_for_linear_memory,
						 (unsigned)first_ptr);
#else
				*first_ptr;
#endif
			}
			else
				return ATOM_0;
		}
		else {
#ifdef EDJGPP
			return MAKE_INT(getpixel(screen, h, v));
#else
			return MAKE_INT(_getpixel((short)h, (short)v));
#endif
		}
	}

	else {
		/* read multiple pixels */
		len = get_int(*(x1->base+3));
		if (len < 0)
			RTFatal("3rd argument of get_pixel() must be >= 0");

		result = NewS1((long)len);
		obj_ptr = result->base+1;
		prefill = 0;
		postfill = 0;

#ifndef EDJGPP
		if (image_ok && len >= 3 && len <= 1024) {
			/* use fast getimage into TempBuff */
			if (h < config.numxpixels && h+len > config.numxpixels) {
				if (h < 0) {
					// straddling both sides
					_getimage(0, v, config.numxpixels-1, v, TempBuff);
					prefill = -h;
					postfill = h+len-config.numxpixels;
					len = config.numxpixels;
				}
				else {
					// straddling on the right
					_getimage(h, v, config.numxpixels-1, v, TempBuff);
					postfill = h+len-config.numxpixels;
					len -= postfill;
				}
			}
			else if (h < 0 && h+len >= 1) {
				// straddling on the left
				_getimage(0, v, h+len-1, v, TempBuff);
				prefill = -h;
				len -= prefill;
			}
			else {
				// totally on or off the screen
				_getimage(h, v, h+len-1, v, TempBuff);
			}

			while (prefill-- > 0)
				*obj_ptr++ = ATOM_0;

			/* must be one of these #colors since image_ok is TRUE */

			if (config.numcolors == 256) {
				len += 6;
				for (i = 6; i < len; i++)
					*obj_ptr++ = MAKE_INT((unsigned char)TempBuff[i]);
			}
			else if (config.numcolors == 16) {
				step1 = 1 + ((len-1) >> 3);
				step2 = step1 + step1;
				step3 = step2 + step1;
				mask = 128;
				first_ptr = TempBuff + 6;
				while (--len >= 0) {
					p = 0;
					if (*first_ptr & mask)
						p += 8;
					if (*(first_ptr + step1) & mask)
						p += 4;
					if (*(first_ptr + step2) & mask)
						p += 2;
					if (*(first_ptr + step3) & mask)
						p += 1;
					*obj_ptr++ = MAKE_INT(p);
					mask >>= 1;
					if (mask == 0) {
						first_ptr++;
						mask = 128;
					}
				}
			}
			else if (config.numcolors == 4 ) { // mode 15 uses slow code
				firstb = 5;
				for (i = 0; i < len; i++) {
					if ((i & 3) == 0) {
						firstb++;
						shift = 6;
					}
					*obj_ptr++ = MAKE_INT((TempBuff[firstb] >> shift) & 3);
					shift -= 2;
				}
			}
			else /* 2 */ { /* must be true */
				firstb = 5;
				for (i = 0; i < len; i++) {
					if ((i & 7) == 0) {
						firstb++;
						shift = 7;
					}
					*obj_ptr++ = MAKE_INT((TempBuff[firstb] >> shift) & 1);
					shift -= 1;
				}
			}
			while(postfill-- > 0)
				*obj_ptr++ = ATOM_0;
		}

		else {
			/* slow code: we can't use _getimage */
#endif
			for (i = 0; i < len; i++) {
#ifdef EDJGPP
				c = getpixel(screen, h, v);
#else
				c = _getpixel((short)h, (short)v);
#endif
				h++;
				*obj_ptr++ = MAKE_INT(c);
			}
#ifndef EDJGPP
		}
#endif
		return MAKE_SEQ(result);
	}
#endif
}

static object E_Ellipse(object x)
/* x is {fill, {x1, y1}, {x2, y2}} */
{
#ifndef EDOS
	not_supported("ellipse()");
	return 0;
#else
	int fill, colour, x1, y1, x2, y2;
	int cx, cy, rx, ry;
	s1_ptr hv_sequence1, hv_sequence2;

	x = (object)SEQ_PTR(x);
	colour = get_int(*(((s1_ptr)x)->base+1));
	fill =   get_int(*(((s1_ptr)x)->base+2));
	hv_sequence1 = SEQ_PTR(*(((s1_ptr)x)->base+3));
	x1 = get_int(*(hv_sequence1->base+1));
	y1 = get_int(*(hv_sequence1->base+2));

	hv_sequence2 = SEQ_PTR(*(((s1_ptr)x)->base+4));
	x2 = get_int(*(hv_sequence2->base+1));
	y2 = get_int(*(hv_sequence2->base+2));
#ifdef EDJGPP
	cx = (x1 + x2) >> 1;
	cy = (y1 + y2) >> 1;
	rx = cx - x1;
	ry = cy - y1;
	if (fill)
		ellipsefill(screen, cx, cy, rx, ry, colour);
	else
		ellipse(screen, cx, cy, rx, ry, colour);
#else
	_setcolor((short)colour);
	_ellipse(fill ? (short)_GFILLINTERIOR : (short)_GBORDER,
			(short)x1, (short)y1, (short)x2, (short)y2);
#endif
#endif
	return ATOM_1;
}


static object Palette(object x)
/* select a red-green-blue color mixture for a given color number */
/* x is {c, {red, green, blue}} */
{
#ifndef EDOS
	not_supported("palette()");
	return 0;
#else
	int c, red, green, blue, new_color, old_color;
	object_ptr obj_ptr;
	s1_ptr result, rgb_sequence;

	x = (object)SEQ_PTR(x);
	c = get_int(*(((s1_ptr)x)->base+1));
	rgb_sequence = SEQ_PTR(*(((s1_ptr)x)->base+2));

	red   = get_int(*(rgb_sequence->base+1));
	green = get_int(*(rgb_sequence->base+2));
	blue  = get_int(*(rgb_sequence->base+3));
	new_color = red + (green << 8) + (blue << 16);

#ifdef EDJGPP
	get_color(c, (RGB *)&old_color);
	set_color(c, (RGB *)&new_color);
#else
	old_color = _remappalette((short)c, new_color);
	if (old_color == -1)
		return (object)ATOM_M1;
#endif

	result = NewS1((long)3);
	obj_ptr = result->base;

	obj_ptr[1] = MAKE_INT(old_color & 0x000000FF);
	obj_ptr[2] = MAKE_INT((old_color & 0x0000FF00) >> 8);
	obj_ptr[3] = MAKE_INT((old_color & 0x00FF0000) >> 16);
	return MAKE_SEQ(result);
#endif
}

static object AllPalette(object x)
/* reset the entire color palette */
/* x is {{r,g,b}, {r,g,b}, ...} */
{
#ifndef EDOS
	not_supported("all_palette()");
#else
	int red, green, blue, len, i;
	object_ptr rgb_ptr;
	s1_ptr rgb_sequence;
	long *long_buff;

	/* we know x is a sequence since sequence
	   type check is never off */
	x = (object)SEQ_PTR(x);
	len = ((s1_ptr)x)->length;
	if (len > 256)
		len = 256;
	long_buff = (long *)TempBuff;  /* 1040/4 = 260 longs */
	rgb_ptr = ((s1_ptr)x)->base+1;
	for (i = 0; i < len; i++) {
		rgb_sequence = (s1_ptr)*rgb_ptr;
		if (IS_ATOM(rgb_sequence) || SEQ_PTR(rgb_sequence)->length != 3)
			RTFatal(
"argument to all_palette must be a sequence containing sequences of length 3");
		rgb_sequence = SEQ_PTR(rgb_sequence);
		red   = get_int(*(rgb_sequence->base+1));
		green = get_int(*(rgb_sequence->base+2));
		blue  = get_int(*(rgb_sequence->base+3));
		long_buff[i] = red + (green << 8) + (blue << 16);
		rgb_ptr++;
	}
#ifdef EDJGPP
	set_palette_range((RGB *)long_buff, 0, len, 0);
#else
	_remapallpalette(long_buff); /* always returns -1, contrary to docs */
#endif
#endif
	return ATOM_1;
}

void RestoreConfig()
/* put graphics mode etc back the way it is supposed to be
   e.g. after system call */
{
#if defined(EDOS) && !defined(EDJGPP)
	_setvideomoderows(config.mode, config.numtextrows);
	ClearScreen();
	_wrapon(wrap_around);
	/*_settextposition(1,1)*/;
#endif
}

static void fast_image_check()
/* see if we can use the fast pixel display method */
{
#if defined(EDOS) && !defined(EDJGPP)
	image_ok = FALSE;
	if (TEXT_MODE)
		return;

	_setcolor(1);
	if (_setpixel(0,0) != 0)
		return;
	_setpixel(1,0);
	_setpixel(2,0);
	_setpixel(3,0);

	_getimage(0, 0, 3, 0, TempBuff);

	_setcolor(0);
	_setpixel(0,0);
	_setpixel(1,0);
	_setpixel(2,0);
	_setpixel(3,0);

	if (config.numcolors == 256) {
		if (memcmp(TempBuff, correct256, 10) != 0)
			return;
	}
	else if (config.numcolors == 16) {
		if (memcmp(TempBuff, correct16, 10) != 0)
			return;
	}
	else if (config.numcolors == 4) {
		if (memcmp(TempBuff, correct4, 7) != 0)
			return;
	}
	else if (config.numcolors == 2) {
		if (memcmp(TempBuff, correct2, 7) != 0)
			return;
	}
	else {
		return;
	}
	image_ok = TRUE;
#endif
}

void NewConfig(int raise_console)
/* note new video configuration - this doesn't work
   after a system call that changes modes - could be out of sync */
{
#ifdef EWINDOWS
	CONSOLE_SCREEN_BUFFER_INFO info;
	if (raise_console) {
		// properly initializes the console when running in exwc mode
	show_console();

	GetConsoleScreenBufferInfo(console_output, &info);
	line_max = info.dwMaximumWindowSize.Y;
	col_max = info.dwMaximumWindowSize.X;
	} else {
		// don't care on startup - this will be initialized later.
	line_max = 80;
	col_max = 25;
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

	if ((line_max == 0 || col_max == 0) &&
		!ioctl(STDIN_FILENO, TIOCGWINSZ, &ws)) {
		line_max = ws.ws_row;
		col_max = ws.ws_col;
	}

	if (line_max < 5 || line_max > 9999 ||
		col_max < 10 || col_max > 99999) {
		// something is wrong - use default pessimistic values
		line_max = 24;  // default value
		col_max = 80;   // default value
	}

	if (line_max > MAX_LINES)
		line_max = MAX_LINES;
	if (col_max > MAX_COLS)
		col_max = MAX_COLS;

	config.monitor = _COLOR;
	config.numcolors = 16;
	config.numtextrows = line_max;
	config.numtextcols = col_max;
#endif

#ifdef EDOS
	/* Things don't seem to work properly after a system call that
	   flips into graphics mode. */
#ifdef EDJGPP
	config.numvideopages = 1;
	line_max = ScreenRows(); // maybe use env var
	col_max = ScreenCols();  // maybe use env var
	config.monitor = _COLOR;
	config.numtextrows = line_max;
	config.numtextcols = col_max;
	image_ok = FALSE;
#else

if (getenv("EUVISTA")!=NULL && atoi(getenv("EUVISTA"))==1)
{
	config.numvideopages = 1;
	line_max = 24; // maybe use env var
	col_max = 80;  // maybe use env var
	config.monitor = _COLOR;
	config.numtextrows = line_max;
	config.numtextcols = col_max;
	image_ok = FALSE;
}
else
{
	_getvideoconfig(&config); // causes win95 to go full-screen, first time

	line_max = config.numtextrows;
	col_max = config.numtextcols;
	fast_image_check();
} // endif EUVISTA
#endif
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
	int mode, status, colors;
	int width, height;

	mode = get_int(x);
#ifdef EDOS
#ifdef EDJGPP
	switch (mode) {
		case -1:
		case 0:
		case 1:
		case 2:
		case 3:
		case 7:
			/* TEXT MODES */
			config.mode = 3;
			config.numcolors = 16;
			config.numxpixels = 0;
			config.numypixels = 0;
			config.numtextrows = 25;
			config.numtextcols = 80;
			set_gfx_mode(GFX_TEXT, 25, 80, 0, 0);
			ScreenSetCursor(0, 0);
			return 0;
		case 4:
			width = 320; height = 200; colors = 4;
			break;
		case 5:
			width = 320; height = 200; colors = 4;
			break;
		case 6:
			width = 640; height = 200; colors = 2;
			break;
		case 11:
			width = 720; height = 350; colors = 2;
			break;
		case 13:
			width = 320; height = 200; colors = 16;
			break;
		case 14:
			width = 640; height = 200; colors = 16;
			break;
		case 15:
			width = 640; height = 350; colors = 2;
			break;
		case 16:
			width = 640; height = 350; colors = 4;
			break;
		case 17:
			width = 640; height = 480; colors = 2;
			break;
		case 18:
			width = 640; height = 480; colors = 16;
			break;
		case 19:
			width = 320; height = 200; colors = 256;
			break;
		case 256:
			width = 640; height = 400; colors = 256;
			break;
		case 257:
			width = 640; height = 480; colors = 256;
			break;
		case 258:
			width = 800; height = 600; colors = 16;
			break;
		case 259:
			width = 800; height = 600; colors = 256;
			break;
		case 260:
			width = 1024; height = 768; colors = 16;
			break;
		case 261:
			width = 1024; height = 768; colors = 256;
			break;
		default:
			return 1; // failure
	}
	status = set_gfx_mode(GFX_AUTODETECT, width, height, 0, 0) != 0;
	if (status == 0) {
		set_clip(screen, 0, 0, width-1, height-1);
		config.mode = mode;
		config.numxpixels = width;
		config.numypixels = height;
		config.numcolors = colors;
		config.mask = 0xFFFFFFFF;
		if (colors == 16)
			config.mask = 0x000F;
		else if (colors == 4)
			config.mask = 0x0003;
		else if (colors == 2)
			config.mask = 0x0001;
		config.x = 0;
		config.y = 0;
		text_mode(0);
	}
	return status;
#else
	_setvideomode((short)mode);
	status = _grstatus();
	NewConfig(TRUE);
	return (status != 0);
#endif
#else
#if defined(EWINDOWS)
	NewConfig(TRUE);
#endif
	return ATOM_0;
#endif
}

static object Video_config()
/* video_config built-in */
{
	object_ptr obj_ptr;
	s1_ptr result;
#if defined(EWINDOWS)
	NewConfig(TRUE); // Windows size might have changed since last call.
#endif
	result = NewS1((long)8);
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
#ifdef EDOS
#ifndef EDJGPP
	_settextcursor(style);
#endif
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
#ifdef EDOS
	new_rows = get_int(x);
#ifdef EDJGPP
	_set_screen_lines(new_rows);
#else
	rows = _settextrows(new_rows);
#endif
#endif
	NewConfig(TRUE);
	return MAKE_INT(line_max);
}

object Wrap(object x)
/* set line wrap mode */
{
	wrap_around = get_int(x);
#ifdef EDOS
#ifndef EDJGPP
	_wrapon(wrap_around ? _GWRAPON : _GWRAPOFF);
#endif
#else
#if defined(EWINDOWS)
	show_console();
#endif
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

#ifdef EDJGPP
void blank_lines(int line, int n)
// Write n blank lines at the current cursor position.
// The cursor is moved. Note: screen_output() is bypassed.
{
	int b;
	int j;

	for (j = 1; j <= n; j++) {
		ScreenSetCursor(line++, 0);
		b = config.numtextcols;
		while (b >= 20) {
			mem_cputs("                    "); // 20 blanks
			b -= 20;
		}
		while (b >= 1) {
			mem_cputs(" ");
			b -= 1;
		}
	}
}
#endif

void do_scroll(int top, int bottom, int amount)
// scroll the screen from top line to bottom line by amount
// amount is positive => text moves up
{
#ifdef EDJGPP
	int r1, c1, r2, c2;
#else
	short r1, c1, r2, c2;
#endif
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
	src.Right = info.dwMaximumWindowSize.X - 1;
	src.Top = top - 1;
	src.Bottom = bottom - 1;
	clip = src;
	dest.X = 0;
	dest.Y = src.Top - amount; // for now
//	GetConsoleScreenBufferInfo(console_output, &info);
	fill_char.Char.AsciiChar = ' ';
	fill_char.Attributes = info.wAttributes;
	if (abs(amount) > abs(bottom - top)) {
		EClearLines(top, bottom, info.dwMaximumWindowSize.X - 1, fill_char.Attributes);
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

#ifdef EDJGPP
	// save the current position
	ScreenGetCursor(&r1, &c1);

	if (abs(amount) > abs(bottom - top)) {
		// clear the window
		blank_lines(top-1, bottom-top+1);
	}
	else if (amount > 0) {
		// scroll some lines up
		ScreenSetCursor(top-1, 0);
		// delete some lines
		for (i = 1; i <= amount; i++)
			delline();
		ScreenSetCursor(bottom-amount, 0);
		// insert some empty lines
		for (i = 1; i <= amount; i++)
			insline();
		//blank_lines(bottom-amount, amount);
	}
	else if (amount < 0) {
		// scroll some lines down
		ScreenSetCursor(bottom + amount, 0);
		// delete lines
		for (i = 1; i <= -amount; i++)
			delline();
		ScreenSetCursor(top-1, 0);
		// insert empty lines
		for (i = 1; i <= -amount; i++)
			insline();
		//blank_lines(top-1, -amount);
	}

	// restore the current position
	ScreenSetCursor(r1, c1);
#endif

#if defined(EDOS) && !defined(EDJGPP)
	_gettextwindow(&r1, &c1, &r2, &c2);
	_settextwindow(top, c1, bottom, c2);
	if (abs(amount) > abs(bottom - top))
		_clearscreen(_GWINDOW);
	else
		_scrolltextwindow(amount);
	_settextwindow(r1, c1, r2, c2);
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

#ifdef EDOS
#ifdef EDJGPP
	textcolor(c);
#else
	_settextcolor(c);
#endif
#endif
	return ATOM_1;
}

#if defined(EDJGPP) || defined(ELCC) || defined(EMINGW)
// temporary
static long colors[16];
#endif

#if !defined(EUNIX) && !defined(EDJGPP) && !defined(ELCC) && !defined(EBORLAND) && !defined(EMINGW)
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

#ifdef EDOS
	if (c >= 0 && c < 16)
#ifdef EDJGPP
		current_bg_color = c;
		if (!TEXT_MODE)
			text_mode(c);
		textbackground(c);
#else
		_setbkcolor(colors[c]);
#endif
#endif
	return ATOM_1;
}

#ifdef EDOS

#ifdef EWATCOM
#pragma off (check_stack)
static void _loadds far click_handler(int max, int mcx, int mdx)
{
#pragma aux click_handler parm [EAX] [ECX] [EDX]
#endif
#ifdef EDJGPP
static void click_handler(int max, int mcx, int mdx)
{
#endif
	/* add event to queue */
	if (mouse.lock != 2) {
		mouse.lock = 1;
		mouse.code = max;
		mouse.x = mcx;
		mouse.y = mdx;
#ifdef EXTRA_STATS
		mouse_ints++; // not locked!
#endif
	}
}
//void cbc_end (void) /* Dummy function so we can */
//{                   /* calculate size of code to lock */
//}                   /* (cbc_end - click_handler) */

#endif

#ifndef EDOS
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

#else

#ifdef EDJGPP
static object MousePointer(object x)
/* show or hide mouse pointer */
{
	int show_it;

	show_it = get_int(x);
	if (show_it == 0)
		scare_mouse();
	else
		unscare_mouse();
	return ATOM_1;
}

static object MouseEvents(int interrupts)
{
	return ATOM_1;
}

static int mouse_is_installed = FALSE;
int mouse_installed()
{
	if (mouse_is_installed) {
		//remove_mouse();  Allegro exit will do this
		return 0;
	}
	else {
		mouse.code = -1;
		mouse.x = -1;
		mouse.y = -1;
		mouse_is_installed = install_mouse() != -1;
		position_mouse(0,0);
	}
	return mouse_is_installed;
}

static void show_mouse_cursor(int x)
{
	if (x == 1)
		show_mouse(screen);
	else
		show_mouse(NULL);
}

static void lock_mouse_pages()
{
}

static int current_b = -1;
static int mouse_changed()
/* reports if DJGPP mouse pointer moved or button was clicked */
{
	int prev_b, prev_left, prev_right, prev_middle;

	if (mouse_x != mouse.x ||
		mouse_y != mouse.y ||
		mouse_b != current_b) {

		/* might help to grab all the values early, since they could change
		   via an interrupt while we are in here */
		prev_b = current_b;
		current_b = mouse_b;

		/* check for movement */
		mouse.code = (mouse.x != mouse_x ||
					  mouse.y != mouse_y);
		mouse.x = mouse_x;
		mouse.y = mouse_y;

		/* check left button */
		prev_left = (prev_b & 1);
		if ((current_b & 1) == 1) {
			mouse.code |= ((prev_left == 0) << 1); // left went down
		}
		else {
			mouse.code |= ((prev_left == 1) << 2); // left went up
		}

		/* check right button */
		prev_right = (prev_b & 2);
		if ((current_b & 2) == 2) {
			mouse.code |= ((prev_right == 0) << 3); // right went down
		}
		else {
			mouse.code |= ((prev_right == 2) << 4); // right went up
		}

		/* check middle button */
		prev_middle = (prev_b & 4);
		if ((current_b & 4) == 4) {
			mouse.code |= ((prev_middle == 0) << 5); // middle went down
		}
		else {
			mouse.code |= ((prev_middle == 4) << 6); // middle went up
		}

		if (mouse.code == 0)  // could happen due to interrupt
			mouse.code = 1;

		return TRUE;
	}
	else {
		return FALSE;
	}
}

#else

static void lock_mouse_pages()
/* lock callback code and data (essential under VMM!)
   note that click_handler, although it does a far return and
   is installed using a full 48-bit pointer, is really linked
   into the flat model code segment -- so we can use a regular
   (near) pointer in the lock_region() call.
*/
{
		if ((! lock_region (&mouse, sizeof(mouse))) ||
			(! lock_region ((void near *) click_handler,
				512))) {

/*              (char *) cbc_end - (char near *) click_handler))) { */
#ifdef EXTRA_CHECK
					RTFatal ("mouse locks failed");
#endif
		}
}

static object MouseEvents(int interrupts)
/* select the mouse interrupts that are to be reported */
{
	struct SREGS sregs;
	union REGS inregs, outregs;
	int (far *function_ptr)();

	if (first_mouse) {
		lock_mouse_pages();
		first_mouse = 0;
		if (mouse_installed())
			show_mouse_cursor(0x1);
	}
	/* install click watcher */
	segread(&sregs);

	memset(&inregs, 0, sizeof(inregs));
	inregs.w.ax = 0xC;
	inregs.w.cx = get_int(interrupts);
	function_ptr = click_handler;
	inregs.x.edx = FP_OFF(function_ptr);
	sregs.es = FP_SEG(function_ptr);
	int386x(0x33, &inregs, &outregs, &sregs);
	return ATOM_1;
}

int mouse_installed()
/* check if mouse driver is installed */
{
	union REGS inregs, outregs;

	memset(&inregs, 0, sizeof(inregs));
	inregs.w.ax = 0;
	int386(0x33, &inregs, &outregs);
	return outregs.w.ax == (unsigned short)-1;
}

static show_mouse_cursor(int x)
/* set up to catch mouse interrupts */
{
	union REGS inregs, outregs;

	/* show mouse cursor */
	memset(&inregs, 0, sizeof(inregs));
	inregs.w.ax = x;
	int386(0x33, &inregs, &outregs);
}

static object MousePointer(object x)
/* show or hide mouse pointer */
{
	int show_it;

	show_it = get_int(x);
	if (show_it == 0)
		show_mouse_cursor(0x2);
	else
		show_mouse_cursor(0x1);
	return ATOM_1;
}
#endif
#endif

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
	//sprintf(buff, "x=%d, y=%d, buttons=%x, modifiers=%x, clicks=%x\n",
		   //event->x, event->y, event->buttons, event->modifiers, event->clicks);
	//sprintf(buff, "vc=%x, type=%d\n", event->vc, event->type);
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
/* GET_MOUSE event built-in DOS (and WIN32) */
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
#ifdef EDJGPP
	if (mouse_changed()) {
#else
	if (mouse.lock) {
#endif
		/* there's something in the queue */

		result = NewS1((long)3);
		obj_ptr = result->base;

		mouse.lock = 2; /* critical section */
		obj_ptr[1] = mouse.code;
#ifdef EDJGPP
		if (TEXT_MODE)
			obj_ptr[1] = (mouse.x << 1);
		else
			obj_ptr[1] = mouse.x;
#else
		obj_ptr[2] = mouse.x;
#endif
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

#ifdef EDJGPP
#define WASTE_SIZE 25
#define WASTE_CHUNK 50000
static char *waste[WASTE_SIZE];
static int waste_num = 0;
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

#ifdef EDJGPP
	/* we must not let allocate() return an address less than a million */
	/* we assume that those are low memory addresses */
	while ((unsigned)addr <= LOW_MEMORY_MAX) {
		if (waste_num < WASTE_SIZE)
			waste[waste_num++] = addr;
		if (nbytes < WASTE_CHUNK)
			nbytes = WASTE_CHUNK;
		addr = malloc(nbytes);
	}
	if (waste_num > 0)
		free(waste[--waste_num]);  // can use it for sequence memory etc.
#endif
	// we don't allow -ve addresses, so can't use -ve Euphoria ints
	if ((unsigned long)addr <= (unsigned)MAXINT_VAL)
		return (unsigned long)addr;
	else
		return NewDouble((double)(unsigned long)addr);
}

#if defined(EDOS)
int lock_region (void *address, unsigned length)
{
		union REGS regs;
		unsigned linear;

		/* Thanks to DOS/4GW's zero-based flat memory model, converting
				a pointer of any type to a linear address is trivial.
		*/
		linear = (unsigned) address;

		memset(&regs, 0, sizeof(regs));
		regs.w.ax = 0x600;             /* DPMI Lock Linear Region */
		regs.w.bx = (linear >> 16);    /* Linear address in BX:CX */
		regs.w.cx = (linear & 0xFFFF);
		regs.w.si = (length >> 16);    /* Length in SI:DI */
		regs.w.di = (length & 0xFFFF);
		int386 (0x31, &regs, &regs);
		return (! regs.w.cflag);       /* Return 0 if can't lock */
}

static object lock_memory(object x)
/* user lock memory. x is {addr, nbytes} */
{
	void *addr;
	unsigned int nbytes;

	x = (object)SEQ_PTR(x); // can assume length-2 sequence
							// if called from machine.e
	addr = (void *)get_pos_int("lock_memory", *(((s1_ptr)x)->base+1));
	nbytes =       get_pos_int("lock_memory", *(((s1_ptr)x)->base+2));
	lock_region(addr, nbytes);
	return ATOM_1;
}

static object set_vector(object x)
/* x is (int_num, {seg, offset}} */
{
	int intnum, a_int;
	object a;
	unsigned seg, offs;
#ifdef EDJGPP
	__dpmi_paddr address;
#endif

	x = (object)SEQ_PTR(x); // can assume length-2 sequence
							// if called from machine.e
	intnum = get_int(*(((s1_ptr)x)->base+1));
	a =              *(((s1_ptr)x)->base+2); //can assume sequence
	a = (object)SEQ_PTR(a);
	seg = get_int(*(((s1_ptr)a)->base+1)); // ok to use get_int - 16 bit value
	offs =        *(((s1_ptr)a)->base+2);
	offs = get_pos_int("set_vector", offs);
#ifdef EDJGPP
	address.selector = seg;
	address.offset32 = offs;
	__dpmi_set_protected_mode_interrupt_vector(intnum, &address);
#else
	_dos_setvect(intnum, (void (__interrupt __far *)())MK_FP(seg,offs));
#endif
	return ATOM_1;
}

static object get_vector(object x)
/* returns current {seg, offset} address for interrupt vector x */
{
	void (__interrupt __far *addr)();
	int intnum;
	object offs, seg;
	s1_ptr result;
	object_ptr obj_ptr;
#ifdef EDJGPP
	__dpmi_paddr address;
#endif

	intnum = get_int(x);
#ifdef EDJGPP
	__dpmi_get_protected_mode_interrupt_vector(intnum, &address);
	seg = address.selector;
	offs = address.offset32;
#else
	addr = _dos_getvect(intnum);
	seg  = FP_SEG(addr);  //16-bit value
	offs = FP_OFF(addr);  //32-bit value
#endif
	if ((unsigned)offs <= (unsigned)MAXINT_VAL)
		offs = MAKE_INT((unsigned long)offs);
	else
		offs = NewDouble((double)(unsigned long)offs);
	result = NewS1((long)2);
	obj_ptr = result->base;
	obj_ptr[1] = seg;
	obj_ptr[2] = offs;
	return MAKE_SEQ(result);
}
#endif

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

static object user_allocate_low(object x)
/* user allocate low memory */
{
#ifndef EDOS
	not_supported("allocate_low()");
	return 0;
#else
	unsigned int nbytes, nparagraphs;
	unsigned short segment;
#ifdef EDJGPP
	int selector;
#else
	unsigned short selector;
#endif
	unsigned int wider;
	union REGS regs;

	nbytes = (unsigned int)get_pos_int("allocate_low", x);
	nparagraphs = (nbytes >> 4) + 2;
#ifdef EDJGPP
	 segment = __dpmi_allocate_dos_memory(nparagraphs, &selector);
#else
	memset(&regs, 0, sizeof(regs));
	regs.w.ax = 0x0ff21;
	regs.w.bx = nparagraphs;
	int386(0x31, &regs, &regs);

	if (regs.x.cflag) {
		return ATOM_0;
	}
	segment = (unsigned int)regs.w.ax;
	selector = regs.w.dx;
#endif
#ifdef EXTRA_CHECK
	//iprintf(stderr, "selector allocated is %x\n", selector);
#endif
	save_selector(segment, selector);
	wider = (unsigned int)segment;
	wider = wider << 4;
	return MAKE_INT(wider);
#endif
}

static object user_free_low(object x)
/* user free low memory */
{
#ifndef EDOS
	not_supported("free_low()");
#else
	unsigned int addr;
	union REGS regs;
	int selector;

	addr = get_int(x);
	if ((addr == 0) || (addr & 0x0f) != 0)
		return ATOM_1; // bad address
	addr = addr >> 4; // get segment
	selector = get_selector(addr);
	if (selector == -1)
		return ATOM_1; // can't find selector
#ifdef EDJGPP
	if (__dpmi_free_dos_memory(selector)) {
#ifdef EXTRA_CHECK
		RTInternal("dpmi_free_dos_memory failed!")
#endif
		;
	}
#else
	memset(&regs, 0, sizeof(regs));
	regs.w.ax = 0x0ff23;
	regs.w.dx = selector;
#ifdef EXTRA_CHECK
	//iprintf(stderr, "selector to free is %x\n", regs.w.dx);
	//iflush(stderr);
#endif
	int386(0x31, &regs, &regs);
#ifdef EXTRA_CHECK
	if (regs.x.cflag != 0)
		RTInternal("RelMemDOS failed!");
#endif
#endif
#endif
	return ATOM_1;
}

static object dos_interrupt(object x)
/* Perform a DOS software interrupt.
   x is {interrupt number, {register values}},
   result is {register values} */
{
#ifndef EDOS
	not_supported("dos_interrupt()");
	return 0;
#else
	int int_no;
	s1_ptr result, reg_sequence;
	object_ptr obj_ptr;

#ifdef EDJGPP
	__dpmi_regs reglist;
#else
	// register list for Causeway IntXX
	struct xx {
		unsigned int edi;
		unsigned int esi;
		unsigned int ebp;
		unsigned int z0;
		unsigned int ebx;
		unsigned int edx;
		unsigned int ecx;
		unsigned int eax;
		unsigned short flags;
		unsigned short es;
		unsigned short ds;
		unsigned short fs;
		unsigned short gs;
		unsigned short z1;
		unsigned short z2;
		unsigned short z3;
		unsigned short z4;
	} reglist;
	union REGS regs;
	struct SREGS seg_regs;
#endif

	x = (object)SEQ_PTR(x);
	int_no =       get_int(*(((s1_ptr)x)->base+1));
	reg_sequence = SEQ_PTR(*(((s1_ptr)x)->base+2));

	// fill up reglist based on 16-bit values in Euphoria sequence
#ifdef EDJGPP
	reglist.x.di = get_int(*(reg_sequence->base+1));
	reglist.x.si = get_int(*(reg_sequence->base+2));
	reglist.x.bp = get_int(*(reg_sequence->base+3));
	reglist.x.bx = get_int(*(reg_sequence->base+4));
	reglist.x.dx = get_int(*(reg_sequence->base+5));
	reglist.x.cx = get_int(*(reg_sequence->base+6));
	reglist.x.ax = get_int(*(reg_sequence->base+7));
	reglist.x.flags = get_int(*(reg_sequence->base+8));
	reglist.x.es = get_int(*(reg_sequence->base+9));
	reglist.x.ds = get_int(*(reg_sequence->base+10));

	__dpmi_int(int_no, &reglist);

#else
	reglist.edi = get_int(*(reg_sequence->base+1));
	reglist.esi = get_int(*(reg_sequence->base+2));
	reglist.ebp = get_int(*(reg_sequence->base+3));
	reglist.z0 = 0;
	reglist.ebx = get_int(*(reg_sequence->base+4));
	reglist.edx = get_int(*(reg_sequence->base+5));
	reglist.ecx = get_int(*(reg_sequence->base+6));
	reglist.eax = get_int(*(reg_sequence->base+7));
	reglist.flags = get_int(*(reg_sequence->base+8));
	reglist.es = get_int(*(reg_sequence->base+9));
	reglist.ds = get_int(*(reg_sequence->base+10));

	reglist.fs = 0;
	reglist.gs = 0;
	reglist.z1 = 0;
	reglist.z2 = 0;
	reglist.z3 = 0;
	reglist.z4 = 0;

	segread(&seg_regs);
	memset(&regs, 0, sizeof(regs));
	regs.x.edi = (unsigned int)&reglist;
	regs.x.ebx = (unsigned int)int_no; // The user's interrupt number
	regs.x.eax = 0x0ff01; // Causeway Simulate real mode interrupt

	int386x(0x31, &regs, &regs, &seg_regs);
#endif

	// fill up result sequence based on values in reglist
	result = NewS1((long)10);
	obj_ptr = result->base;

#ifdef EDJGPP
	obj_ptr[1] = MAKE_INT(reglist.x.di);
	obj_ptr[2] = MAKE_INT(reglist.x.si);
	obj_ptr[3] = MAKE_INT(reglist.x.bp);
	obj_ptr[4] = MAKE_INT(reglist.x.bx);
	obj_ptr[5] = MAKE_INT(reglist.x.dx);
	obj_ptr[6] = MAKE_INT(reglist.x.cx);
	obj_ptr[7] = MAKE_INT(reglist.x.ax);
	obj_ptr[8] = MAKE_INT(reglist.x.flags);
	obj_ptr[9] = MAKE_INT(reglist.x.es);
	obj_ptr[10] = MAKE_INT(reglist.x.ds);
#else
	obj_ptr[1] = MAKE_INT(reglist.edi);
	obj_ptr[2] = MAKE_INT(reglist.esi);
	obj_ptr[3] = MAKE_INT(reglist.ebp);
	obj_ptr[4] = MAKE_INT(reglist.ebx);
	obj_ptr[5] = MAKE_INT(reglist.edx);
	obj_ptr[6] = MAKE_INT(reglist.ecx);
	obj_ptr[7] = MAKE_INT(reglist.eax);
	obj_ptr[8] = MAKE_INT(reglist.flags);
	obj_ptr[9] = MAKE_INT(reglist.es);
	obj_ptr[10] = MAKE_INT(reglist.ds);
#endif
	return MAKE_SEQ(result);
#endif
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
#if defined(ELINUX) | defined(EWATCOM)
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
#if defined(EMINGW) || defined(EDJGPP)
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

// 3 implementations of dir()

#if defined(ELCC) || defined(EBORLAND)
	// 1 of 3: findfirst method

static object Dir(object x)
/* x is the name of a directory or file */
{
	char path[MAX_FILE_NAME+1+4];
	s1_ptr result, row;
#ifdef EBORLAND
	struct ffblk direntp;
#else
	struct _finddata_t direntp;
#endif
	object_ptr obj_ptr, temp;
	int dirp, last, bits;
	unsigned date, time, attrib;

	/* x will be sequence if called via dir() */

	if (SEQ_PTR(x)->length > MAX_FILE_NAME)
		RTFatal("name for dir() is too long");

	MakeCString(path, x);

	bits = _A_SUBDIR | _A_HIDDEN | _A_SYSTEM;

		   //FA_RDONLY | FA_HIDDEN |
		   //FA_SYSTEM | FA_LABEL |
		   //FA_DIREC | FA_ARCH; // everything

	last = strlen(path)-1;
	while (last > 0 &&
		   (path[last] == '\\' || path[last] == ' ' || path[last] == '\t')) {
		last--;
	}
	path[last+1] = 0; // delete any trailing backslash - Borland won't accept it
#ifdef EBORLAND
	dirp = findfirst(path, &direntp, bits);
#else
	dirp = _findfirst(path, &direntp);
#endif
	if (path[last] == ':' ||
		(dirp != -1 && (
#ifdef EBORLAND
		direntp.ff_attrib
#else
		direntp.attrib
#endif
		/* BUG FIX by EUMAN 2002
		   Borland and LCC-Win would not show sub-directories/files
		   of a given directory if attributes element was an or'd value,
		   e.g. READ_ONLY | SUBDIR. */

		&   /* THE FIX: use bitwise AND, not == _A_SUBDIR */

		_A_SUBDIR) &&

		strchr(path, '*') == NULL &&
		strchr(path, '?') == NULL)) {
		// it's a single directory entry - add *.*
		strcat(path, "\\*.*");
#ifdef EBORLAND
		dirp = findfirst(path, &direntp, bits);
#else
		dirp = _findfirst(path, &direntp);
#endif
	}
	if (dirp == -1)
		return ATOM_M1; /* couldn't open directory (or file) */

	/* start with empty sequence as result */
	result = (s1_ptr)NewString("");

	for (;;) {
		/* create a length-9 sequence */
		row = NewS1((long)9);

		obj_ptr = row->base;
		obj_ptr[1] = NewString(
#ifdef EBORLAND
		direntp.ff_name
#else
		direntp.name
#endif
		);
		obj_ptr[2] = NewString("");
		temp = &obj_ptr[2];
#ifdef EBORLAND
		attrib = direntp.ff_attrib;
#else
		attrib = direntp.attrib;
#endif
		if (attrib & _A_RDONLY)
			Append(temp, *temp, MAKE_INT('r'));
		if (attrib & _A_HIDDEN)
			Append(temp, *temp, MAKE_INT('h'));
		if (attrib & _A_SYSTEM)
			Append(temp, *temp, MAKE_INT('s'));
		if (attrib & _A_SUBDIR)
			Append(temp, *temp, MAKE_INT('d'));
		if (attrib & _A_ARCH)
			Append(temp, *temp, MAKE_INT('a'));
#ifdef EBORLAND
		if (attrib & FA_LABEL)
			Append(temp, *temp, MAKE_INT('v'));
		obj_ptr[3] = direntp.ff_fsize;
		date = direntp.ff_fdate;
		time = direntp.ff_ftime;
		obj_ptr[4] = 1980 + date/512;
		obj_ptr[5] = (date/32) & 0x0F;
		obj_ptr[6] = date & 0x01F;

		obj_ptr[7] = time/2048;
		obj_ptr[8] = (time/32) & 0x03F;
		obj_ptr[9] = (time & 0x01F) << 1;
#else
		obj_ptr[3] = direntp.size;
		{
		struct tm *now;

		now = localtime(&direntp.time_write);

		obj_ptr[4] = now->tm_year+1900;
		obj_ptr[5] = now->tm_mon+1;
		obj_ptr[6] = now->tm_mday;

		obj_ptr[7] = now->tm_hour;
		obj_ptr[8] = now->tm_min;
		obj_ptr[9] = now->tm_sec;
		}
#endif
		if ((unsigned)obj_ptr[3] > (unsigned)MAXINT) {
			// file size over 1Gb
			obj_ptr[3] = NewDouble((double)(unsigned)obj_ptr[3]);
		}
		/* append row to overall result (ref count 1) */
		Append((object_ptr)&result, (object)result, MAKE_SEQ(row));
#ifdef EBORLAND
		dirp = findnext(&direntp);
		if (dirp == -1)
			break; /* end of list */
#else
		if (_findnext(dirp, &direntp)) {
			_findclose(dirp);
			break; /* end of list */
		}
#endif
	}

	return (object)result;
}
#endif

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

	MakeCString(path, x);

	last = strlen(path)-1;
	while (last > 0 &&
		   (path[last] == '\\' || path[last] == ' ' || path[last] == '\t')) {
		last--;
	}

	if (last >= 1 && path[last-1] == '*' && path[last] == '.')
		last--; // work around WATCOM bug when we have "*." at end
#if defined(EDOS)
	else if ((path[last] == '*') && ((last == 0) || (path[last-1] != '.')))
	/* watcom bug fix - turn dir("*") into dir("*.*") */
	{
		path[last+1] = '.';
		path[last+2] = '*';
		last += 2;
	}
#endif

	if (path[last] != ':')
		path[last+1] = 0; // delete any trailing backslash - Watcom has problems
						  // with wildcards and trailing backslashes together

#if defined(EDOS)
	dirp = opendir(long_to_short(path));
#else
	dirp = opendir(path);
#endif
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

#ifdef EDJGPP
// this speeds things up quite a bit, but dir() is still much
// slower than with WATCOM
unsigned short _djstat_flags =
					_STAT_INODE | _STAT_EXEC_EXT | _STAT_EXEC_MAGIC |
					_STAT_DIRSIZE | _STAT_ROOT_TIME | _STAT_WRITEBIT;
#endif

#if defined(EUNIX) || defined(EDJGPP) || defined(EMINGW)
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
#if defined(EDJGPP) || defined(EMINGW)
	char full_name[MAX_FILE_NAME+1+257];
#else
	char full_name[MAX_FILE_NAME+1+NAME_MAX+1];
#endif

	/* x will be sequence if called via dir() */

	if (SEQ_PTR(x)->length > MAX_FILE_NAME)
		RTFatal("name for dir() is too long");

	MakeCString(path, x);

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
			strcpy(full_name, path);  // trailing blanks?
			strcat(full_name, "/");
			strcat(full_name, direntp->d_name);
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

#ifdef EDOS
	// it's done in Euphoria code in image.e
	not_supported("machine_func(59)");
#else
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

#endif //not EDOS

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

#ifdef EDOS
// it's done in Euphoria code in image.e
	not_supported("machine_func(58)");
#else

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

#endif // not EDOS
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
#ifdef EDJGPP
	if (TEXT_MODE) {
		ScreenGetCursor((int *)&obj_ptr[1], (int *)&obj_ptr[2]);
	}
	else {
		obj_ptr[1] = config.y / text_height(font);
		obj_ptr[2] = config.x / text_length(font, "m");
	}
	obj_ptr[1] += 1;
	obj_ptr[2] += 1;
#else
	pos = GetTextPositionP();
	obj_ptr[1] = MAKE_INT(pos.row);
	obj_ptr[2] = MAKE_INT(pos.col);
#endif
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
#else
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
#if defined(ELCC) || defined(EMINGW)
	r = 0;  // FOR NOW!
#else
	r = lock(fd, first, last - first + 1);
#endif
#endif
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
#else
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
#if defined(ELCC) || defined(EMINGW)
	/* do nothing */
#else
	if (last >= first)
		unlock(fd, first, last - first + 1);
#endif
#endif
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
	extern short _SVGAType;
	int c;

#ifndef EDOS
	not_supported("use_vesa()");
#else
#ifndef EDJGPP
	c = get_int(x);

	if (c)
		_SVGAType = c;
	else
		_SVGAType = original_vesa;
#endif
#endif
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
		MakeCString(crash_msg, x);
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
	MakeCString(TempErrName, x);
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
		MakeCString(TempWarningName, x);
	}
	return ATOM_1;
}

static object do_crash(object x)
{
	char *message;
	int r;

	message = malloc(SEQ_PTR(x)->length + 1);
	MakeCString(message, x);
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
	MakeCString(new_dir, x);
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


#ifdef EDJGPP
static void TickHandler()
{
	our_clock_ticks++;
}
END_OF_FUNCTION(TickHandler)

#else

static void __interrupt __far TickHandler()
/* handles clock-tick interrupts */
{
#ifdef EDOS
	int dummy[1];
	unsigned int pc_off, pc_seg;
	unsigned int do_exec_off, do_exec_seg;

	our_clock_ticks++;

#ifndef ERUNTIME
	if (Executing && ProfileOn && sample_next < sample_size) {
		/* record profile sample */
		pc_off = dummy[16];
		pc_seg = dummy[17];

		do_exec_seg = (int)FP_SEG(&do_exec);

		if (pc_seg == do_exec_seg &&
			pc_off > (unsigned)&do_exec &&
			pc_off < (unsigned)&AfterExecute) {
			profile_sample[sample_next++] = dummy[6]; // or [11]; ECX vs ESI register as pc
		}
		else {
			profile_sample[sample_next++] = (int)tpc;
		}
	}
#endif
	/* Adjust the count of clock ticks */
	clock_ticks += interval;

	/* Is it time for the BIOS handler to do it's thing? */
	if (clock_ticks >= 0x010000) {
		/* Yes. So adjust the count and call the BIOS handler */
		clock_ticks -= 0x010000;
		/*asm pushf end;*/
		_chain_intr(BIOSTimerHandler);
	}
	else {
		/* If not then just acknowledge the interrupt */
		outp(0x0020, 0x20);
	}
#endif
}

#endif

void ESetTimer(void (__interrupt __far *handler)())
/* Do some initialization */
{
#ifdef EDOS
	lock_region((int *)handler, 4096);
#ifndef EDJGPP
	/* Store the current BIOS handler and set up our own */
	BIOSTimerHandler = _dos_getvect(TIMERINTR);
	_dos_setvect(TIMERINTR, handler);

	/* Set the PIT channel 0 frequency */
	outp(0x0043, 0x34);
	outp(0x0040, interval % 256);
	outp(0x0040, interval / 256);
#endif
#endif
}

static void CleanUpTimer()
/* Restore the normal clock frequency */
{
#ifdef EDOS
#ifdef EDJGPP
	remove_int(TickHandler);
#else
	outp(0x0043, 0x34);
	outp(0x0040, 0);
	outp(0x0040, 0);

	/* Restore the normal ticker handler */
	_dos_setvect(TIMERINTR, BIOSTimerHandler);
#endif
#endif
}

object tick_rate(object x)
/* Set new system clock tick (interrupt) rate.
   x may be int or double, >= 0. 0 means restore 18.2 rate. */
{
	double rate;

#ifdef EDOS
	if (IS_ATOM_INT(x))
		rate = (double)INT_VAL(x);
	else if (IS_ATOM(x)) {
		rate = DBL_PTR(x)->dbl;
	}
	else
		rate = -1.0;
	if (rate == 0.0) {
		/* remove our handler, use normal DOS clock() at 18.2/sec */
		/* no more profiling */
		if (clock_frequency != 0.0) {
			CleanUpTimer();
			clock_adjust = (double)
#ifdef EUNIX
			times(&buf) / CLK_TCK;  //N.B. DOS-only section right now
#else
			clock()/clocks_per_sec;
#endif
			clock_adjust = current_time() - clock_adjust;
			clock_frequency = 0.0;
		}
		clock_period = 1.0/18.2;
		return ATOM_1;
	}

	if (rate < 18.3 || rate > MASTER_FREQUENCY)
		RTFatal("bad argument to tick_rate()");

	clock_period = 1.0/rate;

	if (clock_frequency != 0.0)
		CleanUpTimer();
	base_time = current_time();
	our_clock_ticks = 0;
	clock_ticks = 0;
	interval = (int) (MASTER_FREQUENCY / rate + 0.5);
	clock_frequency = MASTER_FREQUENCY / (double)interval;
#ifdef EDJGPP
	LOCK_VARIABLE(our_clock_ticks);
	LOCK_FUNCTION(TickHandler);
	install_int_ex(TickHandler, BPS_TO_TIMER((int)rate));
#else
	ESetTimer(TickHandler);
#endif

#endif
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
#ifdef EDJGPP
	char *start;
	char *targ;
	int step;
	long ss;
#endif

#ifdef EDOS
	/* flip to main screen in case of video write */
	if (current_screen != MAIN_SCREEN)
		MainScreen();
#endif
	dest   = (char *)get_pos_int("mem_copy", d);
	src    = (char *)get_pos_int("mem_copy", s);
	nbytes = get_pos_int("mem_copy", n);
#ifdef EDJGPP
	if ((unsigned)dest <= LOW_MEMORY_MAX ||
		(unsigned) src <= LOW_MEMORY_MAX) {

		if ((unsigned)src > LOW_MEMORY_MAX) {
			/* then dest is low memory - no overlap, important for video writes */
			start = src;
			step = 4;
			targ = dest;
			while (nbytes >= 4) {
				_farpokel(_go32_info_block.selector_for_linear_memory,
						(unsigned long)targ,
						*(unsigned *)start);
				nbytes -= 4;
				start += 4;
				targ += 4;
			}
		}

		else if ((unsigned)dest > LOW_MEMORY_MAX) {
			/* then src is low memory - no overlap */
			start = src;
			step = 4;
			targ = dest;
			while (nbytes >= 4) {
				*(unsigned *)targ = _farpeekl(_go32_info_block.selector_for_linear_memory,
											 (unsigned)start);
				nbytes -= 4;
				start += 4;
				targ += 4;
			}
		}

		else {
			/* both are low memory - be careful about overlap */
			if ((unsigned)dest <= (unsigned)src) {
				/* start from the front */
				start = src;
				targ = dest;
				step = +4;
			}
			else {
				/* start from the end */
				start = src + nbytes;
				targ = dest + nbytes;
				if (nbytes >= 4) {
					start -= 4;
					targ -= 4;
				}
				else {
					start -= 1;
					targ -= 1;
				}
				step = -4;
			}
			while (nbytes >= 4) {
				ss = _farpeekl(_go32_info_block.selector_for_linear_memory,
							  (unsigned)start);
				_farpokel(_go32_info_block.selector_for_linear_memory,
						(unsigned long)targ,
						ss);
				nbytes -= 4;
				start += step;
				targ += step;
			}
			if (step < 0) {
				start += 3;
				targ += 3;
			}
		}

		if (step > 0)
			step = +1;
		else
			step = -1;

		while (nbytes >= 1) {
			/* do the last few bytes, if any */
			if ((unsigned)start <= LOW_MEMORY_MAX) {
				ss = _farpeekb(_go32_info_block.selector_for_linear_memory,
							  (unsigned)start);
			}
			else {
				ss = *start;
			}
			if ((unsigned)targ <= LOW_MEMORY_MAX) {
				_farpokeb(_go32_info_block.selector_for_linear_memory,
						  (unsigned long)targ,
						  (char)ss);
			}
			else {
				*targ = (unsigned char)ss;
			}
			nbytes -= 1;
			start += step;
			targ += step;
		}
	}
	else
#endif
	memmove(dest, src, nbytes); /* overlapping regions handled correctly */
	return ATOM_1;
}

object memory_set(object d, object v, object n)
/* Fast memory set - called from x.c or machine.c */
{
	char *dest;
	int value;
	unsigned nbytes;

#ifdef EDOS
	if (current_screen != MAIN_SCREEN)
		MainScreen(); // in DOS the guy might be writing to the screen
#endif
	dest   = (char *)get_pos_int("mem_set", d);
	value  = (int)get_pos_int("mem_set", v);
	nbytes = get_pos_int("mem_set", n);
#ifdef EDJGPP
	if ((unsigned)dest <= LOW_MEMORY_MAX) {
		/* low memory */
		while (nbytes) {
			_farpokeb(_go32_info_block.selector_for_linear_memory,
					  (unsigned long)dest,
					  (unsigned char)value);
			dest++;
			nbytes--;
		}
	}
	else
#endif
	memset(dest, value, nbytes);
	return ATOM_1;
}

#ifdef EWINDOWS
HINSTANCE *open_dll_list = NULL;
int open_dll_size = 20;
int open_dll_count = 0;
#endif

object OpenDll(object x)
{
#ifdef EDOS
	not_supported("open_dll()");
	return 0;
#else
	void (FAR WINAPI *proc_address)();
	s1_ptr dll_ptr;
	unsigned char *dll_string;
	HINSTANCE lib;

	/* x will be a sequence if called via open_dll() */

	dll_ptr = SEQ_PTR(x);
	if (dll_ptr->length >= TEMP_SIZE)
		RTFatal("name for open_dll() is too long");
	dll_string = TempBuff;
	MakeCString(dll_string, (object)x);
#ifdef EWINDOWS
	lib = (HINSTANCE)LoadLibrary(dll_string);
	// add to dll list so we can close it at end of execution
	if (open_dll_list == NULL) {
		open_dll_list = (HINSTANCE *)malloc(open_dll_size * sizeof(HINSTANCE));
	}
	else if (open_dll_count >= open_dll_size) {
		open_dll_size *= 2;
		open_dll_list = (HINSTANCE *)realloc(open_dll_list,
											 open_dll_size * sizeof(HINSTANCE));
	}
	open_dll_list[open_dll_count++] = lib;
#else
	// Linux

	lib = (HINSTANCE)dlopen(dll_string, RTLD_LAZY | RTLD_GLOBAL);

#endif
	if ((unsigned)lib <= (unsigned)MAXINT_VAL)
		return MAKE_INT((unsigned long)lib);
	else
		return NewDouble((double)(unsigned long)lib);
#endif
}

object DefineCVar(object x)
/* Get the address of a C variable, or return -1 */
{
#ifdef EDOS
	not_supported("define_c_var()");
	return 0;
#else
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
	MakeCString(variable_string, variable_name);
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
#endif
}


object DefineC(object x)
/* define a C routine: x is {lib, name, arg_sizes, return_type or 0}
   alternatively, x is {"", address or {'+', address}, arg_sizes, return_type or 0}
   Return -1 on failure. */
{
#ifdef EDOS
#define HINSTANCE object
#endif
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
#ifdef EDOS
		RTFatal("Euphoria for DOS does not support .DLL's, only machine-code routines");
#endif
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
		sprintf(TempBuff, "machine code routine at %x", proc_address);
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
		MakeCString(routine_string, routine_name);
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
/* return a call-back address for routine id x
   x can be the routine id for stdcall, or {'+', routine_id} for cdecl */
{
	unsigned addr;
	int routine_id, i, num_args;
	unsigned char *copy_addr;
	symtab_ptr routine;
#ifdef EWINDOWS
	int bare_flag = 0;
#endif
	s1_ptr x_ptr;
	int convention;
#ifdef EWINDOWS
	VirtualAlloc_t VirtualAlloc_ptr;
	HINSTANCE hinstLib;
	BOOL fFreeResult, fRunTimeLinkSuccess = FALSE;
	// Get a handle to the DLL module.

	void * replace_value;
        s1_ptr result;
	object_ptr obj_ptr;
	hinstLib = LoadLibrary(TEXT("kernel32"));
#endif


#ifdef EDOS
	not_supported("call_back()");
	return 0;
#else
	convention = C_CDECL;
start:
	if (IS_SEQUENCE(x)) {
		x_ptr = SEQ_PTR(x);
		/*printf( "x_ptr->length=%d, IS_SEQUENCE(*(obj_ptr=x_ptr->base+1))=%d, SEQ_PTR(*obj_ptr)->length=%d\n",
		   x_ptr->length, IS_SEQUENCE(*(obj_ptr=(x_ptr->base+1))),SEQ_PTR(obj_ptr)->length );
		fflush(stdout);*/
#ifdef EWINDOWS
		obj_ptr = x_ptr->base + 1;
		if ((x_ptr->length == 1) && (!IS_SEQUENCE(*obj_ptr)
			|| (SEQ_PTR(*obj_ptr)->length == 2))) {
			bare_flag = 1;
			x = *obj_ptr;
			goto start;
		}
#endif
		if (x_ptr->length != 2){
			RTFatal("call_back() argument must be routine_id, or {'+', routine_id}");
		}
		if (get_int( x_ptr->base[1] ) != '+')
			RTFatal("for cdecl, use call_back({'+', routine_id})");
		routine_id = get_int( x_ptr->base[2] );
	}
	else {
		routine_id = get_int(x);
#ifdef EWINDOWS
		convention = C_STDCALL;
#endif
	}
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
#ifdef EWINDOWS
	if (bare_flag) goto bare;
#endif
#ifdef EWINDOWS
	// If the handle is valid, try to get the function address.
	copy_addr = NULL;
	if (hinstLib != NULL)
	    {
		VirtualAlloc_ptr = (VirtualAlloc_t) GetProcAddress(hinstLib, "VirtualAlloc");

		// If the function address is valid, call the function.

		if (NULL != VirtualAlloc_ptr)
		{
		    copy_addr = (VirtualAlloc_ptr)( NULL, CALLBACK_SIZE, MEM_RESERVE | MEM_COMMIT,
			PAGE_EXECUTE_READWRITE );
		    fRunTimeLinkSuccess = TRUE;
		}

		// Free the DLL module.

		fFreeResult = FreeLibrary(hinstLib);
	    }
	else
	    VirtualAlloc_ptr = 0;

	if (copy_addr == NULL) {
		RTFatal("Your program has run out of memory.\nOne moment please...");
	}
	if (!fRunTimeLinkSuccess)
	copy_addr = (unsigned char *)EMalloc(CALLBACK_SIZE);
#else /* ndef EWNIDOWS */
	copy_addr = (unsigned char *)EMalloc(CALLBACK_SIZE);
#endif /* ndef EWINDOWS */
#ifdef EUNIX
#ifndef EBSD
	mprotect((unsigned)copy_addr & ~(pagesize-1),  // start of page
			 pagesize,  // one page
			 PROT_READ+PROT_WRITE+PROT_EXEC);
#endif
#endif
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
#ifdef EWINDOWS
        if (
	    (
		    addr = (unsigned) VirtualAlloc( copy_addr, CALLBACK_SIZE,
			    MEM_RESERVE | MEM_COMMIT, PAGE_EXECUTE )
	    )
	    ==
	    0 )
#endif
	addr = (unsigned)copy_addr;

	if (addr <= (unsigned)MAXINT_VAL)
		return addr;
	else
		return NewDouble((double)addr);

#endif
#ifdef EWINDOWS
bare:
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
#endif
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
	s1 = NewS1(4);
	s1->base[1] = MAJ_VER;
	s1->base[2] = MIN_VER;
	s1->base[3] = PAT_VER;
	s1->base[4] = NewString(REL_TYPE);
	return MAKE_SEQ(s1);
}

object eu_uname()
{
#ifdef EUNIX
	int ret;
	struct utsname buf;
	s1_ptr s1;

	ret = uname(&buf);
	if (ret != 0)
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

#if defined(EUNIX) || defined(EDJGPP) || defined(EMINGW)
	do_exec(NULL);  // init jumptable
#endif

	fe_set_pointers(); /* change some fe indexes into pointers */

	/* Look at the switches for any information pertient to the backend */
	switch_len = SEQ_PTR(fe.switches)->length;

	for (i=1; i <= switch_len; i++) {
		x_ptr = SEQ_PTR(fe.switches)->base[i];
		w = (char *)EMalloc(SEQ_PTR(x_ptr)->length + 1);
		MakeCString(w, (object) x_ptr);

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
			case M_SOUND:
				return SetSound(x);
				break;
			case M_LINE:
				if (current_screen != MAIN_SCREEN)
					MainScreen();
				return Line(x, M_LINE);
				break;
			case M_POLYGON:
				if (current_screen != MAIN_SCREEN)
					MainScreen();
				return Line(x, M_POLYGON);
				break;
			case M_PIXEL:  // obsolete, but keep it
				x = (object)SEQ_PTR(x);
				return Pixel(*(((s1_ptr)x)->base+1),
							 *(((s1_ptr)x)->base+2));
				break;
			case M_GET_PIXEL: // obsolete, but keep it
				return Get_Pixel(x);
				break;
			case M_ELLIPSE:
				if (current_screen != MAIN_SCREEN)
					MainScreen();
				return E_Ellipse(x);
				break;
			case M_PALETTE:
				return Palette(x);
				break;
			case M_ALL_PALETTE:
				return AllPalette(x);
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
				free((char *)addr);
				return ATOM_1;
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
			case M_GET_DISPLAY_PAGE:
#if !defined(EDOS) || defined(EDJGPP)
				not_supported("get_display_page()");
#else
				return MAKE_INT(_getvisualpage());
#endif
				break;
			case M_SET_DISPLAY_PAGE:
#if !defined(EDOS) || defined(EDJGPP)
				not_supported("set_display_page()");
#else
				page_was_set = 1;
				_setvisualpage(get_int(x));  // x will be an integer, but might
#endif                                   // be in f.p. form
				return ATOM_1;
				break;
			case M_GET_ACTIVE_PAGE:
#if !defined(EDOS) || defined(EDJGPP)
				return 0;
#else
				return MAKE_INT(_getactivepage());
#endif
				break;
			case M_SET_ACTIVE_PAGE:
#if !defined(EDOS) || defined(EDJGPP)
				if (get_int(x) != 0)
					not_supported("set_active_page");
#else
				page_was_set = 1;
				_setactivepage(get_int(x));
#endif
				return ATOM_1;
				break;
			case M_ALLOC_LOW:
				return user_allocate_low(x);
				break;
			case M_FREE_LOW:
				return user_free_low(x);
				break;
			case M_INTERRUPT:
				if (current_screen != MAIN_SCREEN)
					MainScreen();
				return dos_interrupt(x);
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
#ifdef EDOS
			case M_GET_VECTOR:
				return get_vector(x);
				break;
			case M_SET_VECTOR:
				return set_vector(x);
				break;
			case M_LOCK_MEMORY:
				return lock_memory(x);
				break;
#endif
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
#ifdef ESUNOS
				return 5;
#endif
#ifdef EOSX
				return 4;
#endif
#ifdef EUNIX
				return 3;  // (UNIX, called Linux for backwards compatibility)
#endif
#ifdef EWINDOWS
				return 2;  // WIN32
#endif
#ifdef EDOS
				return 1;  // DOS32
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
#ifndef EDOS
				if (current_screen != MAIN_SCREEN)
					MainScreen();
				if (have_console) {
#ifndef EUNIX
					FreeConsole();
#endif
					have_console = FALSE;
				}
#endif
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
				MakeCString(src, (object) *(((s1_ptr)x)->base+1));
				MakeCString(dest, (object) *(((s1_ptr)x)->base+2));
				temp = setenv(src, dest, *(((s1_ptr)x)->base+3));
				EFree(dest);
				EFree(src);
				return !temp;
				break;

			case M_UNSET_ENV:
				x = (object) SEQ_PTR(x);
				src = EMalloc(SEQ_PTR(((s1_ptr) x)->base[1])->length + 1);
				MakeCString(src, (object) *(((s1_ptr)x)->base+1));
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

			case M_PCRE_FREE:
				free_pcre(x);
				return 1;
				break;

			case M_EU_INFO:
				return eu_info();

			case M_UNAME:
				return eu_uname();

#ifndef EDOS
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

#endif // ifndef EDOS

			/* remember to check for MAIN_SCREEN wherever appropriate ! */
			default:
				/* could be out-of-range int, or double, or sequence */
				if (IS_ATOM_INT(opcode)) {
					sprintf(TempBuff, "machine_proc/func(%d,...) not supported", opcode);
					RTFatal(TempBuff);
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
