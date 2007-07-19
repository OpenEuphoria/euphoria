@echo off
rem     Build Euphoria for DOS32 using DJGPP
rem
rem     you can add: -DEXTRA_CHECK -DEXTRA_STATS 
rem              or: -DHEAP_CHECK
rem     to gopts file to build a debug version
del *.o

echo translating the front end...
\euphoria\bin\ec -djg int.ex

rem don't compile with emake.bat, use this instead...

echo compiling the front-end files...
SET FEFLAGS=-c -w -fsigned-char -O2 -ffast-math -fomit-frame-pointer

@gcc %FEFLAGS% main-.c
@gcc %FEFLAGS% main-0.c
@gcc %FEFLAGS% init-.c
@gcc %FEFLAGS% int.c
@gcc %FEFLAGS% error.c
@gcc %FEFLAGS% machine.c
@gcc %FEFLAGS% symtab.c
@gcc %FEFLAGS% scanner.c
@gcc %FEFLAGS% scanne_0.c
@gcc %FEFLAGS% emit.c
@gcc %FEFLAGS% emit_0.c
@gcc %FEFLAGS% emit_1.c
@gcc %FEFLAGS% parser.c
@gcc %FEFLAGS% parser_0.c
@gcc %FEFLAGS% parser_1.c
@gcc %FEFLAGS% compress.c
@gcc %FEFLAGS% backend.c
@gcc %FEFLAGS% main.c
@gcc %FEFLAGS% pathopen.c

echo compiling the back-end files...
gcc -c @gopts -fomit-frame-pointer be_main.c
gcc -c @gopts -fomit-frame-pointer -finline-functions be_inline.c
gcc -c @gopts -fomit-frame-pointer be_w.c
gcc -c @gopts -fomit-frame-pointer be_symtab.c
gcc -c @gopts -fomit-frame-pointer be_rterror.c
gcc -c @gopts -fomit-frame-pointer be_syncolor.c
gcc -c @gopts -fomit-frame-pointer be_execute.c
gcc -c @gopts -fomit-frame-pointer be_alloc.c
gcc -c @gopts -fomit-frame-pointer be_machine.c
gcc -c @gopts -fomit-frame-pointer be_runtime.c
gcc -c @gopts be_callc.c
gcc -oex.exe @djgfiles.lnk
set LFN=n
strip ex.exe
set LFN=
@dir ex.exe


