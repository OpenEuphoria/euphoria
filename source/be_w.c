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

// Some MinGW headers don't define these:
#ifndef ENABLE_EXTENDED_FLAGS
#define ENABLE_EXTENDED_FLAGS 0x0080
#endif

#ifndef ENABLE_PROCESSED_INPUT
#define ENABLE_PROCESSED_INPUT 0x0001
#endif

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
DWORD orig_console_mode; // console modes in effect when program starts.

#endif

int VK_to_EuKBCode[256] = {
-1,
0xF8010, // VK_LBUTTON  (0x01) Left mouse button
0xF8020, // VK_RBUTTON  (0x02) Right mouse button
0xF8030, // VK_CANCEL  (0x03) Control-break processing
0xF8040, // VK_MBUTTON  (0x04) Middle mouse button (three-button mouse)
0xF8050, // VK_XBUTTON1  (0x05) Windows 2000/XP: X1 mouse button
0xF8060, // VK_XBUTTON2  (0x06) Windows 2000/XP: X2 mouse button
-1, // -  (0x07) Undefined
0xF8070, // VK_BACK  (0x08) BACKSPACE key
0xF8080, // VK_TAB  (0x09) TAB key
-1,-1, // -  (0x0A-0B) Reserved
0xF8090, // VK_CLEAR  (0x0C) CLEAR key NUMPAD-5
0xF80A0, // VK_RETURN  (0x0D) ENTER key NUMPAD-ENTER
-1,-1, // -  (0x0E-0F) Undefined
0xF80B0, // VK_SHIFT  (0x10) SHIFT key
0xF80C0, // VK_CONTROL  (0x11) CTRL key
0xF80D0, // VK_MENU  (0x12) ALT key
0xF80E0, // VK_PAUSE  (0x13) PAUSE key
0xF80F0, // VK_CAPITAL  (0x14) CAPS LOCK key
0xF8100, // VK_KANA  (0x15) Input Method Editor (IME) Kana mode
-1, // -  (0x16) Undefined
0xF8110, // VK_JUNJA  (0x17) IME Junja mode
0xF8120, // , // VK_FINAL  (0x18) IME final mode
0xF8130, // VK_HANJA  (0x19) IME Hanja mode
-1, // -  (0x1A) Undefined
0xF8140, // VK_ESCAPE  (0x1B) ESC key
0xF8150, // VK_CONVERT  (0x1C) IME convert
0xF8160, // VK_NONCONVERT  (0x1D) IME nonconvert
0xF8170, // VK_ACCEPT  (0x1E) IME accept
0xF8180, // VK_MODECHANGE  (0x1F) IME mode change request
0xF8190, // VK_SPACE  (0x20) SPACEBAR
0xF8200, // VK_PRIOR  (0x21) PAGE UP key
0xF8210, // VK_NEXT  (0x22) PAGE DOWN key
0xF8220, // VK_END  (0x23) END key
0xF8230, // VK_HOME  (0x24) HOME key
0xF8240, // VK_LEFT  (0x25) LEFT ARROW key
0xF8250, // VK_UP  (0x26) UP ARROW key
0xF8260, // VK_RIGHT  (0x27) RIGHT ARROW key
0xF8270, // VK_DOWN  (0x28) DOWN ARROW key
0xF81A0, // VK_SELECT  (0x29) SELECT key
0xF81B0, // VK_PRINT  (0x2A) PRINT key
0xF81C0, // VK_EXECUTE  (0x2B) EXECUTE key
0xF81D0, // VK_SNAPSHOT  (0x2C) PRINT SCREEN key
0xF81E0, // VK_INSERT  (0x2D) INS key
0xF81F0, // VK_DELETE  (0x2E) DEL key
0xF8280, // VK_HELP  (0x2F) HELP key
0xF8300, //  (0x30) 0 key 
0xF8310, //  (0x31) 1 key
0xF8320, //  (0x32) 2 key
0xF8330, //  (0x33) 3 key
0xF8340, //  (0x34) 4 key
0xF8350, //  (0x35) 5 key
0xF8360, //  (0x36) 6 key
0xF8370, //  (0x37) 7 key
0xF8380, //  (0x38) 8 key
0xF8390, //  (0x39) 9 key
-1,-1,-1,-1,-1,-1,-1, // -  (0x3A-40) Undefined
0xF8410, //  (0x41) A key
0xF8420, //  (0x42) B key
0xF8430, //  (0x43) C key
0xF8440, //  (0x44) D key
0xF8450, //  (0x45) E key
0xF8460, //  (0x46) F key
0xF8470, //  (0x47) G key
0xF8480, //  (0x48) H key
0xF8490, //  (0x49) I key
0xF84A0, //  (0x4A) J key
0xF84B0, //  (0x4B) K key
0xF84C0, //  (0x4C) L key
0xF84D0, //  (0x4D) M key
0xF84E0, //  (0x4E) N key
0xF84F0, //  (0x4F) O key
0xF8500, //  (0x50) P key
0xF8510, //  (0x51) Q key
0xF8520, //  (0x52) R key
0xF8530, //  (0x53) S key
0xF8540, //  (0x54) T key
0xF8550, //  (0x55) U key
0xF8560, //  (0x56) V key
0xF8570, //  (0x57) W key
0xF8580, //  (0x58) X key
0xF8590, //  (0x59) Y key
0xF85A0, //  (0x5A) Z key
0xF8290, // VK_LWIN  (0x5B) Left Windows key (Microsoft Natural keyboard) 
0xF82A0, // VK_RWIN  (0x5C) Right Windows key (Natural keyboard)
0xF82B0, // VK_APPS  (0x5D) Applications key (Natural keyboard)
-1, // -  (0x5E) Reserved
0xF82C0, // VK_SLEEP  (0x5F) Computer Sleep key
0xF8600, // VK_NUMPAD0  (0x60) Numeric keypad 0 key
0xF8610, // VK_NUMPAD1  (0x61) Numeric keypad 1 key
0xF8620, // VK_NUMPAD2  (0x62) Numeric keypad 2 key
0xF8630, // VK_NUMPAD3  (0x63) Numeric keypad 3 key
0xF8640, // VK_NUMPAD4  (0x64) Numeric keypad 4 key
0xF8650, // VK_NUMPAD5  (0x65) Numeric keypad 5 key
0xF8660, // VK_NUMPAD6  (0x66) Numeric keypad 6 key
0xF8670, // VK_NUMPAD7  (0x67) Numeric keypad 7 key
0xF8680, // VK_NUMPAD8  (0x68) Numeric keypad 8 key
0xF8690, // VK_NUMPAD9  (0x69) Numeric keypad 9 key
0xF86A0, // VK_MULTIPLY  (0x6A) Multiply key NUMPAD
0xF86B0, // VK_ADD  (0x6B) Add key NUMPAD
0xF82D0, // VK_SEPARATOR  (0x6C) Separator key
0xF86C0, // VK_SUBTRACT  (0x6D) Subtract key NUMPAD
0xF86D0, // VK_DECIMAL  (0x6E) Decimal key NUMPAD
0xF86E0, // VK_DIVIDE  (0x6F) Divide key NUMPAD
0xF8700, // VK_F1  (0x70) F1 key
0xF8710, // VK_F2  (0x71) F2 key
0xF8720, // VK_F3  (0x72) F3 key
0xF8730, // VK_F4  (0x73) F4 key
0xF8740, // VK_F5  (0x74) F5 key
0xF8750, // VK_F6  (0x75) F6 key
0xF8760, // VK_F7  (0x76) F7 key
0xF8770, // VK_F8  (0x77) F8 key
0xF8780, // VK_F9  (0x78) F9 key
0xF8790, // VK_F10  (0x79) F10 key
0xF87A0, // VK_F11  (0x7A) F11 key
0xF87B0, // VK_F12  (0x7B) F12 key
0xF87C0, // VK_F13  (0x7C) F13 key
0xF87D0, // VK_F14  (0x7D) F14 key
0xF87E0, // VK_F15  (0x7E) F15 key
0xF87F0, // VK_F16  (0x7F) F16 key
0xF8800, // VK_F17  (0x80H) F17 key
0xF8810, // VK_F18  (0x81H) F18 key
0xF8820, // VK_F19  (0x82H) F19 key
0xF8830, // VK_F20  (0x83H) F20 key
0xF8840, // VK_F21  (0x84H) F21 key
0xF8850, // VK_F22  (0x85H) F22 key
0xF8860, // VK_F23  (0x86H) F23 key
0xF8870, // VK_F24  (0x87H) F24 key
-1,-1,-1,-1,-1,-1,-1,-1, // -  (0x88-8F) Unassigned
0xF82E0, // VK_NUMLOCK  (0x90) NUM LOCK key
0xF82F0, // VK_SCROLL  (0x91) SCROLL LOCK key
0xF85B0,0xF85C0,0xF85D0,0xF85E0,0xF85F0, //  (0x92-96) OEM specific
-1,-1,-1,-1,-1,-1,-1,-1,-1, // -  (0x97-9F) Unassigned
0xF83A0, // VK_LSHIFT  (0xA0) Left SHIFT key
0xF83B0, // VK_RSHIFT  (0xA1) Right SHIFT key
0xF83C0, // VK_LCONTROL  (0xA2) Left CONTROL key
0xF83D0, // VK_RCONTROL  (0xA3) Right CONTROL key
0xF83E0, // VK_LMENU  (0xA4) Left MENU key
0xF83F0, // VK_RMENU  (0xA5) Right MENU key
0xF8880, // VK_BROWSER_BACK  (0xA6) Windows 2000/XP: Browser Back key
0xF8890, // VK_BROWSER_FORWARD  (0xA7) Windows 2000/XP: Browser Forward key
0xF88A0, // VK_BROWSER_REFRESH  (0xA8) Windows 2000/XP: Browser Refresh key
0xF88B0, // VK_BROWSER_STOP  (0xA9) Windows 2000/XP: Browser Stop key
0xF88C0, // VK_BROWSER_SEARCH  (0xAA) Windows 2000/XP: Browser Search key 
0xF88D0, // VK_BROWSER_FAVORITES  (0xAB) Windows 2000/XP: Browser Favorites key
0xF88E0, // VK_BROWSER_HOME  (0xAC) Windows 2000/XP: Browser Start and Home key
0xF88F0, // VK_VOLUME_MUTE  (0xAD) Windows 2000/XP: Volume Mute key
0xF8900, // VK_VOLUME_DOWN  (0xAE) Windows 2000/XP: Volume Down key
0xF8910, // VK_VOLUME_UP  (0xAF) Windows 2000/XP: Volume Up key
0xF8920, // VK_MEDIA_NEXT_TRACK  (0xB0) Windows 2000/XP: Next Track key
0xF8930, // VK_MEDIA_PREV_TRACK  (0xB1) Windows 2000/XP: Previous Track key
0xF8940, // VK_MEDIA_STOP  (0xB2) Windows 2000/XP: Stop Media key
0xF8950, // VK_MEDIA_PLAY_PAUSE  (0xB3) Windows 2000/XP: Play/Pause Media key
0xF8960, // VK_LAUNCH_MAIL  (0xB4) Windows 2000/XP: Start Mail key
0xF8970, // VK_LAUNCH_MEDIA_SELECT  (0xB5) Windows 2000/XP: Select Media key
0xF8980, // VK_LAUNCH_APP1  (0xB6) Windows 2000/XP: Start Application 1 key
0xF8990, // VK_LAUNCH_APP2  (0xB7) Windows 2000/XP: Start Application 2 key
-1,-1, // -  (0xB8-B9) Reserved
0xF89A0, // VK_OEM_1  (0xBA) Used for miscellaneous characters; it can vary by keyboard. Windows 2000/XP: For the US standard keyboard, the ';:' key 
0xF89B0, // VK_OEM_PLUS  (0xBB) Windows 2000/XP: For any country/region, the '+' key
0xF89C0, // VK_OEM_COMMA  (0xBC) Windows 2000/XP: For any country/region, the ',' key
0xF89D0, // VK_OEM_MINUS  (0xBD) Windows 2000/XP: For any country/region, the '-' key
0xF89E0, // VK_OEM_PERIOD  (0xBE) Windows 2000/XP: For any country/region, the '.' key
0xF89F0, // VK_OEM_2  (0xBF) Used for miscellaneous characters; it can vary by keyboard. Windows 2000/XP: For the US standard keyboard, the '/-1' key 
0xF8A00, // VK_OEM_3  (0xC0) Used for miscellaneous characters; it can vary by keyboard. Windows 2000/XP: For the US standard keyboard, the '`~' key 
-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1, // -  (0xC1-D7) Reserved
-1,-1,-1, // -  (0xD8-DA) Unassigned
0xF8A10, // VK_OEM_4  (0xDB) Used for miscellaneous characters; it can vary by keyboard. Windows 2000/XP: For the US standard keyboard, the '[{' key
0xF8A20, // VK_OEM_5  (0xDC) Used for miscellaneous characters; it can vary by keyboard. Windows 2000/XP: For the US standard keyboard, the '\|' key
0xF8A30, // VK_OEM_6  (0xDD) Used for miscellaneous characters; it can vary by keyboard. Windows 2000/XP: For the US standard keyboard, the ']}' key
0xF8A40, // VK_OEM_7  (0xDE) Used for miscellaneous characters; it can vary by keyboard. Windows 2000/XP: For the US standard keyboard, the 'single-quote/double-quote' key
0xF8A50, // VK_OEM_8  (0xDF) Used for miscellaneous characters; it can vary by keyboard.
-1, // -  (0xE0) Reserved
0xF8A60, // (0xE1) OEM specific
0xF8A70, // VK_OEM_102  (0xE2) Windows 2000/XP: Either the angle bracket key or the backslash key on the RT 102-key keyboard
0xF8A80,0xF8A90, //  (0xE3-E4) OEM specific
0xF8AA0, // VK_PROCESSKEY  (0xE5) Windows 95/98/Me, Windows NT 4.0, Windows 2000/XP: IME PROCESS key
0xF8AB0, //  (0xE6) OEM specific
0xF8AC0, // VK_PACKET  (0xE7) Windows 2000/XP: Used to pass Unicode characters as if they were keystrokes. The VK_PACKET key is the low word of a 32-bit Virtual Key value used for non-keyboard input methods. For more information, see Remark in KEYBDINPUT, SendInput, WM_KEYDOWN, and WM_KEYUP
-1, // -  (0xE8) Unassigned
0xF8AD0,0xF8AE0,0xF8AF0,0xF8B00,0xF8B10,0xF8B20,0xF8B30,0xF8B40,0xF8B50,0xF8B60,0xF8B70,0xF8B80,0xF8B90, //  (0xE9-F5) OEM specific
0xF8BA0, // VK_ATTN  (0xF6) Attn key
0xF8BB0, // VK_CRSEL  (0xF7) CrSel key
0xF8BC0, // VK_EXSEL  (0xF8) ExSel key
0xF8BD0, // VK_EREOF  (0xF9) Erase EOF key
0xF8BE0, // VK_PLAY  (0xFA) Play key
0xF8BF0, // VK_ZOOM  (0xFB) Zoom key
0xF8C00, // VK_NONAME  (0xFC) Reserved 
0xF86F0, // VK_PA1  (0xFD) PA1 key
0xF8400, // VK_OEM_CLEAR  (0xFE) Clear key
-1
};



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

/* sets _has_console appropriately. 
 * Windows XP, 2003 and newer: 1 if there is another process attached (that is, run from a shell)
 * Windows earlier than XP or earlier than 2003: always returns 0.  As if it is never run from  a
   shell.
 * Unix : always returns 1 as if always run from a shell.(This may not be the case if run via KDE)
 */
void check_has_console() {
	GCPLA gCPLA;
	HMODULE kernel32;

	kernel32 = LoadLibrary("kernel32.dll");
	/* Windows XP and newer and Windows 2003 and newer is required for this
	 * to work. */
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

void GetTextPositionP(struct eu_rccoord *p)
{
#ifdef EWINDOWS
	CONSOLE_SCREEN_BUFFER_INFO console_info;
	
	show_console();
	
	GetConsoleScreenBufferInfo(console_output, &console_info);
	p->row = console_info.dwCursorPosition.Y+1;
	p->col = console_info.dwCursorPosition.X+1;
	p->winheight = console_info.dwMaximumWindowSize.Y;
	p->winwidth  = console_info.dwMaximumWindowSize.X;
	p->bufheight = console_info.dwSize.Y;
	p->bufwidth  = console_info.dwSize.X;
	p->attrs  = console_info.wAttributes;
#else

	p->row = screen_line;
	p->col = screen_col;
	
	// I don't know how to get these dimensions dynamically.
	p->winwidth = 80;
	p->winheight = 24;
	p->bufwidth = 80;
	p->bufheight = 24;
	p->attrs = (WORD)-1;
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
    struct eu_rccoord position;
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

    console_input = GetStdHandle(STD_INPUT_HANDLE);	// get console keyboard handle
    GetConsoleMode(console_input, &orig_console_mode);	// save initial modes.

    in_from_keyb = PeekConsoleInput(console_input, &pbuffer, 1, &junk);

    // This stops the mouse cursor from appearing in full screen
    SetConsoleMode(console_input, ENABLE_EXTENDED_FLAGS | ENABLE_PROCESSED_INPUT);
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
int getKBcode()
// Get the next keyboard code used by the user on the console
{
    BOOL success;
    DWORD nread;
    DWORD state;
    int vkey;
    INPUT_RECORD buff[4];
    int EuChar = -2;

    while (1) {
        success = ReadConsoleInput(
                    console_input,
                    &buff[0],
                    1,
                    &nread
                    );
        if (! success) {
            EuChar = -1;
            break;
        }
    
        if (buff[0].EventType != KEY_EVENT) { // only interested in keyboard events.
            continue;
        }

        if (! buff[0].Event.KeyEvent.bKeyDown) { // only interested in key DOWN events
            continue;
        }

        EuChar = buff[0].Event.KeyEvent.uChar.UnicodeChar;
        state  = buff[0].Event.KeyEvent.dwControlKeyState;
        vkey   = buff[0].Event.KeyEvent.wVirtualKeyCode;

        //printf("DEBUG %d %d %d\n", (int)EuChar, (int)state, (int)vkey);
        /* Special handling of keypad keys ...
            When NUMLOCK is on, keys should report digits etc
            When NUMLOCK is off, keys should report NUMKEYPAD keys
        */
        if (vkey == 111) { // keypad DIVIDE
            state = state & (~ENHANCED_KEY);    // Not really an enhanced key.
            EuChar = 47;
        }
        if (vkey == 111 ||  // DIVIDE
            vkey == 106 ||  // MULTIPLY
            vkey == 109 ||  // MINUS
            vkey == 107 ||  // PLUS
            vkey == 110 ) { // PERIOD
                if (!(state & NUMLOCK_ON)) {
                    EuChar = 0;
                }
        }

        if (vkey == 13 ) { // ENTER
                if ((state & NUMLOCK_ON)) {
                    state = state & (~ENHANCED_KEY);    // Not really an enhanced key.
                }
        }

        if ( EuChar == 0 || // extended key pressed
            (EuChar == 9 && vkey != 73) || // TAB key but not CTRL-I
            (ENHANCED_KEY & state)) // enhanced key pressed
        {
            EuChar = VK_to_EuKBCode[vkey];
            if (EuChar < 0) {
                continue;	// Unsupported code so ignore it.
            }

            // Adjust code for Ctrl/Alt/Shift combinations.
            if ( (LEFT_CTRL_PRESSED | RIGHT_CTRL_PRESSED) & state) {
                EuChar |= 0x1000;
            }
            if ( SHIFT_PRESSED & state) {
                EuChar |= 0x2000;
            }
            if ( (LEFT_ALT_PRESSED | RIGHT_ALT_PRESSED) & state) {
                EuChar |= 0x4000;
            }
        }
        break;
        
    }
    return EuChar;
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

static void ReadInto(WORD * buf, LPTSTR str, int size, unsigned long * n, unsigned long * m, struct eu_rccoord * pos)
{
    COORD ch;

    GetTextPositionP(pos);

    ch.X = 0;
    ch.Y = 0;
    ReadConsoleOutputCharacter(console_output, str, size, ch, n);
    ReadConsoleOutputAttribute(console_output, buf, size, ch, m);
}

void WriteOutFrom(WORD * buf, LPTSTR str, unsigned long n, unsigned long m, struct eu_rccoord * pos)
{
    unsigned long size1, size2;
    COORD ch;
    ch.X = 0;
    ch.Y = 0;
    WriteConsoleOutputCharacter(console_output, str, n, ch, &size1);
    WriteConsoleOutputAttribute(console_output, buf, m, ch, &size2);

    if (pos->attrs != (WORD)-1)
    {
        SetConsoleTextAttribute(console_output, pos->attrs);
        pos->attrs = (WORD)-1;
    }
    SetPosition(pos->row, pos->col);
}

TCHAR console_save_str[65536];
unsigned long console_save_str_n = 0;
WORD console_save_buf[65536];
unsigned long console_save_buf_n = 0;
struct eu_rccoord console_save_pos;

TCHAR console_trace_str[65536];
unsigned long console_trace_str_n = 0;
WORD console_trace_buf[65536];
unsigned long console_trace_buf_n = 0;
struct eu_rccoord console_trace_pos;

void SaveNormal()
{
    unsigned long size = 65536;
    if (EuConsole){
        ReadInto(console_save_buf, console_save_str, size, &console_save_buf_n, &console_save_str_n, &console_save_pos);
    } else {
        console_save = console_output;
    }
}

void SaveTrace()
{
    int size = 65536;
    if (EuConsole){
        ReadInto(console_trace_buf, console_trace_str, size, &console_save_buf_n, &console_save_str_n, &console_trace_pos);
    } else {
        SetConsoleActiveScreenBuffer(console_var_display);
        console_output = console_var_display;
    }
}

void RestoreTrace()
{
    if (EuConsole){
        WriteOutFrom(console_trace_buf, console_trace_str, console_save_buf_n, console_save_str_n, &console_trace_pos);
    } else {
        SetConsoleActiveScreenBuffer(console_trace);
        console_output = console_trace;
    }
}

void RestoreNormal()
{
    if (EuConsole){
        WriteOutFrom(console_save_buf, console_save_str, console_save_buf_n, console_save_str_n, &console_save_pos);
    } else {
        console_output = console_save;
        SetConsoleActiveScreenBuffer(console_output);
    }
}

void DisableControlCHandling()
{
	SetConsoleMode(console_input, ENABLE_LINE_INPUT | ENABLE_ECHO_INPUT);
}

#endif
