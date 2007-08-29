@echo off
REM          MAKE THE TRANSLATOR LIBRARY ECW.LIB FOR WIN32 (WATCOM)

REM to build other runtime libraries use: gmake.bat, lccmake.bat, bormake.bat,
REM or the WATCOM IDE for Windows

REM Translator for Windows: 
REM    (no runtime option)
REM    compiler switches:  COMPILE INT_CODES
REM    linker switch:      NT
REM Interpreter for Windows: 
REM    runtime windows=4.0
REM    compiler switches:  
REM    linker switch:      NT_WIN

REM no in-lining is slightly better & saves 2K bytes:
REM other optimizations: 
REM    oe: in-lining: oe, 
REM    ot: favour time
REM    on: don't use (replace divide by possibly inaccurate multiply)

REM Major modes:
REM /dEDOS for DOS compile
REM /dECOMPILE to build Translator
REM /dERUNTIME to build runtime library

SET COMMON_FLAGS=/w0 /zq /j /zp4 /5r /fp5 /fpi87 /bt=nt /mf /dEWINDOWS /dEWATCOM 
REM /dEOW
SET OPTIMIZE_FLAGS=/ot /oi /ol /om /or /oa /s
SET CFLAGS=%COMMON_FLAGS% %OPTIMIZE_FLAGS% /dERUNTIME

del *.obj

wcc386 %CFLAGS% be_machine.c 
wcc386 %CFLAGS% be_w.c  
wcc386 %CFLAGS% be_alloc.c  
wcc386 /oe=40 %CFLAGS% be_inline.c 
wcc386 %CFLAGS% be_runtime.c 
wcc386 %CFLAGS% be_task.c 
wcc386 %CFLAGS% be_callc.c 

del ecw.lib
wlib -q ecw.lib be_machine.obj be_inline.obj be_w.obj be_alloc.obj be_runtime.obj be_task.obj be_callc.obj
dir ecw.lib
pause
