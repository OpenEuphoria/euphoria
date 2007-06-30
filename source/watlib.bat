@echo off
REM          MAKE THE TRANSLATOR LIBRARY EC.LIB FOR DOS32 (WATCOM)

REM to build other runtime libraries use: gmake.bat, lccmake.bat, bormake.bat,
REM or watlibw.bat

REM for software f.p. use /fpc
REM for hardware f.p. use /fp5 /fpi87

SET COMMON_FLAGS=/w0 /zq /j /zp4 /5r %1 %2 %3 /dEDOS /dEWATCOM

SET OPTIMIZE_FLAGS=/oi /ol /om /or /oa /ot /s

SET DEBUG_FLAGS=/d2 /dEXTRA_CHECK /dEXTRA_STATS /dINT_CODES

SET CFLAGS=%COMMON_FLAGS% %OPTIMIZE_FLAGS% /dERUNTIME

del *.obj

wcc386 %CFLAGS% be_machine.c 
wcc386 %CFLAGS% be_w.c  
wcc386 %CFLAGS% be_alloc.c  
wcc386 /oe=40 /ot %CFLAGS% be_inline.c 
wcc386 %CFLAGS% be_runtime.c 
wcc386 %CFLAGS% be_task.c 
wcc386 %CFLAGS% be_callc.c 

del ec.lib
wlib -q ec.lib be_machine.obj be_task.obj be_inline.obj be_w.obj be_alloc.obj be_runtime.obj be_callc.obj
dir ec.lib
pause

