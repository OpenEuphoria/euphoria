#ifndef BE_W_H
#define BE_W_H

#include "global.h"
#include "execute.h"

void screen_show(void);
void InitInOut(void);
int has_console(void);

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

extern void check_has_console(void);
extern int console_application(void);

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
extern DWORD orig_console_mode; // Console modes in effect when program starts.
void EClearLines(int first_line, int last_line, int len, WORD attributes);

#endif

extern int screen_line;     /* only used by ANSI code Linux */
extern int screen_col;      /* column on screen, needed by expand_tabs below
                         initialized in InitGraphics, then again in InitOutput */
extern int wrap_around;
extern int in_from_keyb;        /* stdin appears to be from keyboard */
extern char *collect;    /* to collect sprintf/sprint output */
extern int have_console;  // is there a console window yet?
extern int already_had_console; /* were we created with a console window or did we have to allocate our own? */

void ClearScreen(void);
void SetPosition(int line, int col);
void GetTextPositionP(struct eu_rccoord *p);
void screen_output(IFILE f, char *out_string);
void screen_output_va(IFILE f, char *out_string, va_list ap);
void screen_output_vararg(IFILE f, char *out_string, ...);
void buffer_screen(void);
void flush_screen(void);


#ifdef EWINDOWS
	void EClearLines(int first_line, int last_line, int len, WORD attributes);
#endif

int getKBcode();
extern int VK_to_EuKBCode[256];

#ifdef EUNIX
#define  VK_LBUTTON  (0x01) /*  Left mouse button */
#define  VK_RBUTTON  (0x02) /*  Right mouse button */
#define  VK_CANCEL  (0x03) /*  Control-break processing */
#define  VK_MBUTTON  (0x04) /*  Middle mouse button (three-button mouse) */
#define  VK_XBUTTON1  (0x05) /*  Windows 2000/XP: X1 mouse button */
#define  VK_XBUTTON2  (0x06) /*  Windows 2000/XP: X2 mouse button */
#define  VK_BACK  (0x08) /*  BACKSPACE key */
#define  VK_TAB  (0x09) /*  TAB key */
#define  VK_CLEAR  (0x0C) /*  CLEAR key NUMPAD-5 */ */ */ */
#define  VK_RETURN  (0x0D) /*  ENTER key NUMPAD-ENTER */
#define  VK_SHIFT  (0x10) /*  SHIFT key */
#define  VK_CONTROL  (0x11) /*  CTRL key */
#define  VK_MENU  (0x12) /*  ALT key */
#define  VK_PAUSE  (0x13) /*  PAUSE key */
#define  VK_CAPITAL  (0x14) /*  CAPS LOCK key */
#define  VK_KANA  (0x15) /*  Input Method Editor (IME)  Kana mode */
#define  VK_JUNJA  (0x17) /*  IME Junja mode */
#define  VK_FINAL  (0x18) /*  IME final mode */
#define  VK_HANJA  (0x19) /*  IME Hanja mode */
#define  VK_ESCAPE  (0x1B) /*  ESC key */
#define  VK_CONVERT  (0x1C) /*  IME convert */
#define  VK_NONCONVERT  (0x1D) /*  IME nonconvert */
#define  VK_ACCEPT  (0x1E) /*  IME accept */
#define  VK_MODECHANGE  (0x1F) /*  IME mode change request */
#define  VK_SPACE  (0x20) /*  SPACEBAR */
#define  VK_PRIOR  (0x21) /*  PAGE UP key */ */
#define  VK_NEXT  (0x22) /*  PAGE DOWN key */
#define  VK_END  (0x23) /*  END key */
#define  VK_HOME  (0x24) /*  HOME key */
#define  VK_LEFT  (0x25) /*  LEFT ARROW key */
#define  VK_UP  (0x26) /*  UP ARROW key */
#define  VK_RIGHT  (0x27) /*  RIGHT ARROW key */
#define  VK_DOWN  (0x28) /*  DOWN ARROW key */
#define  VK_SELECT  (0x29) /*  SELECT key */
#define  VK_PRINT  (0x2A) /*  PRINT key */
#define  VK_EXECUTE  (0x2B) /*  EXECUTE key */
#define  VK_SNAPSHOT  (0x2C) /*  PRINT SCREEN key */
#define  VK_INSERT  (0x2D) /*  INS key */
#define  VK_DELETE  (0x2E) /*  DEL key */
#define  VK_HELP  (0x2F) /*  HELP key */
#define  VK_LWIN  (0x5B) /*  Left Windows key (Microsoft Natural keyboard)   */
#define  VK_RWIN  (0x5C) /*  Right Windows key (Natural keyboard) */ 
#define  VK_APPS  (0x5D) /*  Applications key (Natural keyboard) */ 
#define  VK_SLEEP  (0x5F) /*  Computer Sleep key */
#define  VK_NUMPAD0  (0x60) /*  Numeric keypad 0 key */
#define  VK_NUMPAD1  (0x61) /*  Numeric keypad 1 key */
#define  VK_NUMPAD2  (0x62) /*  Numeric keypad 2 key */
#define  VK_NUMPAD3  (0x63) /*  Numeric keypad 3 key */
#define  VK_NUMPAD4  (0x64) /*  Numeric keypad 4 key */
#define  VK_NUMPAD5  (0x65) /*  Numeric keypad 5 key */
#define  VK_NUMPAD6  (0x66) /*  Numeric keypad 6 key */
#define  VK_NUMPAD7  (0x67) /*  Numeric keypad 7 key */
#define  VK_NUMPAD8  (0x68) /*  Numeric keypad 8 key */
#define  VK_NUMPAD9  (0x69) /*  Numeric keypad 9 key */
#define  VK_MULTIPLY  (0x6A) /*  Multiply key NUMPAD */
#define  VK_ADD  (0x6B) /*  Add key NUMPAD */
#define  VK_SEPARATOR  (0x6C) /*  Separator key */
#define  VK_SUBTRACT  (0x6D) /*  Subtract key NUMPAD */
#define  VK_DECIMAL  (0x6E) /*  Decimal key NUMPAD */
#define  VK_DIVIDE  (0x6F) /*  Divide key NUMPAD */
#define  VK_F1  (0x70) /*  F1 key */
#define  VK_F2  (0x71) /*  F2 key */
#define  VK_F3  (0x72) /*  F3 key */
#define  VK_F4  (0x73) /*  F4 key */
#define  VK_F5  (0x74) /*  F5 key */
#define  VK_F6  (0x75) /*  F6 key */
#define  VK_F7  (0x76) /*  F7 key */
#define  VK_F8  (0x77) /*  F8 key */
#define  VK_F9  (0x78) /*  F9 key */
#define  VK_F10  (0x79) /*  F10 key */
#define  VK_F11  (0x7A) /*  F11 key */
#define  VK_F12  (0x7B) /*  F12 key */
#define  VK_F13  (0x7C) /*  F13 key */
#define  VK_F14  (0x7D) /*  F14 key */
#define  VK_F15  (0x7E) /*  F15 key */
#define  VK_F16  (0x7F) /*  F16 key */
#define  VK_F17  (0x80) /*  F17 key */
#define  VK_F18  (0x81) /*  F18 key */
#define  VK_F19  (0x82) /*  F19 key */
#define  VK_F20  (0x83) /*  F20 key */
#define  VK_F21  (0x84) /*  F21 key */
#define  VK_F22  (0x85) /*  F22 key */
#define  VK_F23  (0x86) /*  F23 key */
#define  VK_F24  (0x87) /*  F24 key */
#define  VK_NUMLOCK  (0x90) /*  NUM LOCK key */
#define  VK_SCROLL  (0x91) /*  SCROLL LOCK key */
#define  VK_LSHIFT  (0xA0) /*  Left SHIFT key */
#define  VK_RSHIFT  (0xA1) /*  Right SHIFT key */
#define  VK_LCONTROL  (0xA2) /*  Left CONTROL key */
#define  VK_RCONTROL  (0xA3) /*  Right CONTROL key */
#define  VK_LMENU  (0xA4) /*  Left MENU key */
#define  VK_RMENU  (0xA5) /*  Right MENU key */
#define  VK_BROWSER_BACK  (0xA6) /*  Windows 2000/XP: Browser Back key */
#define  VK_BROWSER_FORWARD  (0xA7) /*  Windows 2000/XP: Browser Forward key */
#define  VK_BROWSER_REFRESH  (0xA8) /*  Windows 2000/XP: Browser Refresh key */
#define  VK_BROWSER_STOP  (0xA9) /*  Windows 2000/XP: Browser Stop key */
#define  VK_BROWSER_SEARCH  (0xAA) /*  Windows 2000/XP: Browser Search key  */
#define  VK_BROWSER_FAVORITES  (0xAB) /*  Windows 2000/XP: Browser Favorites key */
#define  VK_BROWSER_HOME  (0xAC) /*  Windows 2000/XP: Browser Start and Home key */
#define  VK_VOLUME_MUTE  (0xAD) /*  Windows 2000/XP: Volume Mute key */
#define  VK_VOLUME_DOWN  (0xAE) /*  Windows 2000/XP: Volume Down key */
#define  VK_VOLUME_UP  (0xAF) /*  Windows 2000/XP: Volume Up key */
#define  VK_MEDIA_NEXT_TRACK  (0xB0) /*  Windows 2000/XP: Next Track key */
#define  VK_MEDIA_PREV_TRACK  (0xB1) /*  Windows 2000/XP: Previous Track key */
#define  VK_MEDIA_STOP  (0xB2) /*  Windows 2000/XP: Stop Media key */
#define  VK_MEDIA_PLAY_PAUSE  (0xB3) /*  Windows 2000/XP: Play/Pause Media key */
#define  VK_LAUNCH_MAIL  (0xB4) /*  Windows 2000/XP: Start Mail key */
#define  VK_LAUNCH_MEDIA_SELECT  (0xB5) /*  Windows 2000/XP: Select Media key */
#define  VK_LAUNCH_APP1  (0xB6) /*  Windows 2000/XP: Start Application 1 key */
#define  VK_LAUNCH_APP2  (0xB7) /*  Windows 2000/XP: Start Application 2 key */
#define  VK_OEM_1  (0xBA) /*  Used for miscellaneous characters it can vary by keyboard. Windows 2000/XP: For the US standard keyboard, the ':' key  */
#define  VK_OEM_PLUS  (0xBB) /*  Windows 2000/XP: For any country/region, the '+' key */
#define  VK_OEM_COMMA  (0xBC) /*  Windows 2000/XP: For any country/region, the ',' key */
#define  VK_OEM_MINUS  (0xBD) /*  Windows 2000/XP: For any country/region, the '-' key */
#define  VK_OEM_PERIOD  (0xBE) /*  Windows 2000/XP: For any country/region, the '.' key */
#define  VK_OEM_2  (0xBF) /*  Used for miscellaneous characters it can vary by keyboard. Windows 2000/XP: For the US standard keyboard, the '/-1' key  */
#define  VK_OEM_3  (0xC0) /*  Used for miscellaneous characters it can vary by keyboard. Windows 2000/XP: For the US standard keyboard, the '`~' key */ 
#define  VK_OEM_4  (0xDB) /*  Used for miscellaneous characters it can vary by keyboard. Windows 2000/XP: For the US standard keyboard, the '[{' key */
#define  VK_OEM_5  (0xDC) /*  Used for miscellaneous characters it can vary by keyboard. Windows 2000/XP: For the US standard keyboard, the '\|' key */
#define  VK_OEM_6  (0xDD) /*  Used for miscellaneous characters it can vary by keyboard. Windows 2000/XP: For the US standard keyboard, the ']}' key */
#define  VK_OEM_7  (0xDE) /*  Used for miscellaneous characters it can vary by keyboard. Windows 2000/XP: For the US standard keyboard, the 'single-quote/double-quote' key */
#define  VK_OEM_8  (0xDF) /*  Used for miscellaneous characters it can vary by keyboard. */
#define  VK_OEM_102  (0xE2) /*  Windows 2000/XP: Either the angle bracket key or the backslash key on the RT 102-key keyboard */
#define  VK_PROCESSKEY  (0xE5) /*  Windows 95/98/Me, Windows NT 4.0, Windows 2000/XP: IME PROCESS key */
#define  VK_PACKET  (0xE7) /*  Windows 2000/XP: Used to pass Unicode characters as if they were keystrokes. The VK_PACKET key is the low word of a 32-bit Virtual Key value used for non-keyboard input methods. For more information, see Remark in KEYBDINPUT, SendInput, WM_KEYDOWN, and WM_KEYUP */
#define  VK_ATTN  (0xF6) /*  Attn key */
#define  VK_CRSEL  (0xF7) /*  CrSel key */
#define  VK_EXSEL  (0xF8) /*  ExSel key */
#define  VK_EREOF  (0xF9) /*  Erase EOF key */
#define  VK_PLAY  (0xFA) /*  Play key */
#define  VK_ZOOM  (0xFB) /*  Zoom key */
#define  VK_NONAME  (0xFC) /*  Reserved */ 
#define  VK_PA1  (0xFD) /*  PA1 key */
#define  VK_OEM_CLEAR  (0xFE) /*  Clear key */
#endif

#endif
