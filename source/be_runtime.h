#ifndef BE_RUNTIME_H
#define BE_RUNTIME_H

extern void RTFatal(char *, ...)
#ifdef EUNIX
__attribute__ ((noreturn))
#endif
;
extern void RTInternal(char *msg, ...)
#ifdef EUNIX
__attribute__ ((noreturn))
#endif
;
void RTFatal_va(char *msg, va_list ap)
#ifdef EUNIX
__attribute__ ((noreturn))
#endif
;

extern int charcopy(char *, int, char *, int);

#endif /* BE_RUNTIME_H */
