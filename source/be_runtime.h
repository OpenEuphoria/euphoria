#ifndef BE_RUNTIME_H
#define BE_RUNTIME_H

extern void RTFatal(char *, ...);
extern void RTInternal(char *msg, ...);
extern int charcopy(char *, int, char *, int);
#define CUE_bufflen (1000)

#endif /* BE_RUNTIME_H */
