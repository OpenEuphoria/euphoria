#ifndef BE_W_H
#define BE_W_H
void screen_show();

#ifdef EUNIX
void screen_copy(struct char_cell a[MAX_LINES][MAX_COLS],
                 struct char_cell b[MAX_LINES][MAX_COLS]);
#endif

#endif
